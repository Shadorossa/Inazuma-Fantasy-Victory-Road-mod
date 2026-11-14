-- lua_patch.scope: used
-- Character Reforged's team loadout field: a player's moves, Hiper (aura), mix, sixth sense, configured passives and role, kept per team.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.team_loadout == nil then
  local T = {
    KEY = "CharacterReforged.player_set",
    -- the menus that switch teams or edit a player's moves (named so the loader runs this file there)
    MENUS = {"soccer_team_dock_menu", "soccer_battle_setting_flow_formation_menu", "vrfw_skill_slot_menu"},
    ROWS = 6,
    PASSIVE_SLOTS = 5,
  }
  CharacterReforged.team_loadout = T

  local function hex(v)
    return string.format("%X", VRFW.ids.unsigned_or(v, 0))
  end

  local function hex_list(t, count)
    local out = {}
    for k = 1, count do
      out[k] = hex(type(t) == "table" and t[k] or 0)
    end
    return table.concat(out, ",")
  end

  local function number_list(text, count)
    local out = {}
    local k = 0
    for w in tostring(text or ""):gmatch("[^,]+") do
      k = k + 1
      out[k] = tonumber(w, 16) or 0
    end
    for i = k + 1, count do
      out[i] = 0
    end
    return out
  end

  --- A set (the table of CharacterReforged.player_sets) as one line: m:moves;h:Hiper;x:mix;s:sixth sense;c:passives;r:role.
  function T.encode(p)
    local parts = {"m:" .. hex_list(p.moves, T.ROWS), "h:" .. hex(p.hiper), "x:" .. hex(p.mix), "s:" .. hex(p.sixsense)}
    if p.pcfg ~= nil then
      parts[#parts + 1] = "c:" .. hex_list(p.pcfg, T.PASSIVE_SLOTS)
    end
    if type(p.role) == "number" and p.role >= 0 then
      parts[#parts + 1] = "r:" .. tostring(p.role)
    end
    return table.concat(parts, ";")
  end

  --- The set a line of T.encode holds; nil when the line is no set.
  function T.decode(text)
    if type(text) ~= "string" or not text:find("m:", 1, true) then
      return nil
    end
    local p = {name = "", equip = {0, 0, 0, 0, 0}}
    for tag, value in text:gmatch("(%a):([^;]*)") do
      if tag == "m" then
        p.moves = number_list(value, T.ROWS)
      elseif tag == "h" then
        p.hiper = tonumber(value, 16) or 0
      elseif tag == "x" then
        p.mix = tonumber(value, 16) or 0
      elseif tag == "s" then
        p.sixsense = tonumber(value, 16) or 0
      elseif tag == "c" then
        p.pcfg = number_list(value, T.PASSIVE_SLOTS)
      elseif tag == "r" then
        p.role = tonumber(value)
      end
    end
    p.moves = p.moves or number_list("", T.ROWS)
    p.hiper, p.mix, p.sixsense = p.hiper or 0, p.mix or 0, p.sixsense or 0
    return p
  end

  local function writer()
    local S = CharacterReforged.player_sets
    return (type(S) == "table" and type(S.apply) == "function") and S or nil
  end

  local function log(...)
    if VRFW.team_loadout ~= nil then
      VRFW.team_loadout.log("CharacterReforged", ...)
    end
  end

  -- The write context: the team's aura slots, and an exact write (what the set holds empty ends empty).
  local function context(handle, team)
    return {dock = type(team) == "table" and team.set or nil, kind = 0, exact = true,
      skip = function(reason, kind, value)
        log(string.format("%08X", VRFW.ids.unsigned_or(handle, 0)), "left out:", reason, kind or "",
          type(value) == "number" and string.format("%08X", value) or "")
      end}
  end

  --- The line of player `handle`'s current build; nil when Character Reforged's set writer is not loaded.
  function T.collect(handle, team)
    local S = writer()
    return S ~= nil and T.encode(S.current(handle, context(handle, team))) or nil
  end

  local function register(TL)
    local ok, why = TL.field(T.KEY, {
      collect = function(member, team)
        return T.collect(member.handle, team)
      end,
      apply = function(_, member, value, team)
        local S, p = writer(), T.decode(value)
        if S ~= nil and p ~= nil then
          S.apply(member.handle, p, context(member.handle, team))
        end
      end,
      default = function(member, team)
        local S = writer()
        if S ~= nil then
          S.apply(member.handle, S.default_set(member.handle), context(member.handle, team))
        end
      end,
    })
    if not ok then
      log("field not registered:", tostring(why))
    end
  end
  if VRFW.team_loadout ~= nil then
    register(VRFW.team_loadout)
  else
    VRFW.team_loadout_queue = VRFW.team_loadout_queue or {}
    table.insert(VRFW.team_loadout_queue, register)
  end
end
