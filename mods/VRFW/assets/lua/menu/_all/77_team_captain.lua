-- lua_patch.scope: used
-- VRFW team, game Lua side (every menu VM; docs/framework/team-captain.md).
if VRFW.team == nil then
  local T = {
    VS_SET = VRFW.commands.GET_VS_USE_TEAM_SET,        -- CMND_GET_VS_USE_TEAM_SET
    TEAM_SET_INFO = VRFW.commands.GET_TEAM_SET_INFO, -- CMND_GET_TEAM_SET_INFO (set, team, kind[, handle])
    MEMBER = 1720957768,
    STATUS = 1131797651,        -- (handle, 4) -> chara_param
    CAPTAIN = 11,               -- kind: the team's captain handle
    IS_CAPTAIN = 8,             -- kind: (handle) -> is the captain
    LEADER = 19,
    MEMBERS = 20,
    MEMBER_SLOTS = 29,          -- the entries a team of the set holds
    FIRST_MANAGER = 16, LAST_MANAGER = 18,  -- positions of the managers
    TEAM_INFO = 2151743654,     -- (team, 2) -> has, name; (team, 6, 0) -> has, crest icon
    ICON_REQUEST = 3190452549,
    ICON_RESET = 4176779611,
    EMBLEM_MESH = 3281704751,   -- _icon_emblem_dmy01: the crest quad of the list plates
    EMBLEM_TEXTURE = 255812047, -- icon_emblem_dmy01
  }
  VRFW.team = T

  local function card_of(h)
    if type(h) ~= "number" or h == 0 then return nil end
    local p = VRFW.host.command(T.STATUS, h, 4)
    if type(p) == "number" and p ~= 0 then return p end
    return nil
  end

  --- The captain of `team` in the active set; nil when there is none.
  function T.captain(team)
    team = math.floor(tonumber(team) or 0)
    local set = VRFW.host.command(T.VS_SET)
    if type(set) ~= "number" then return nil end
    local ok, h = VRFW.host.command(T.TEAM_SET_INFO, set, team, T.CAPTAIN)
    if ok == true and card_of(h) ~= nil then return card_of(h), h end
    local first = nil
    for i = 0, T.MEMBERS - 1 do
      local okh, hm = VRFW.host.command(T.MEMBER, set, team, i, 0)
      local okp, pos = VRFW.host.command(T.MEMBER, set, team, i, 1)
      if okh == true and card_of(hm) ~= nil and not (okp == true and pos == T.LEADER) then
        local okc, is = VRFW.host.command(T.TEAM_SET_INFO, set, team, T.IS_CAPTAIN, hm)
        if okc == true and is == true then return card_of(hm), hm end
        first = first or hm
      end
    end
    if first ~= nil then return card_of(first), first end
    return nil
  end

  --- The manager of `team` in the active set; nil when there is none.
  function T.manager(team)
    team = math.floor(tonumber(team) or 0)
    local set = VRFW.host.command(T.VS_SET)
    if type(set) ~= "number" then return nil end
    local best, best_position = nil, nil
    for i = 0, T.MEMBER_SLOTS - 1 do
      local okp, pos = VRFW.host.command(T.MEMBER, set, team, i, 1)
      if okp == true and type(pos) == "number" and pos >= T.FIRST_MANAGER and pos <= T.LAST_MANAGER
        and (best_position == nil or pos < best_position) then
        local okh, h = VRFW.host.command(T.MEMBER, set, team, i, 0)
        if okh == true and card_of(h) ~= nil then
          best, best_position = h, pos
        end
      end
    end
    if best ~= nil then return card_of(best), best end
    return nil
  end

  local function expand_tags(text)
    if not text:find("<", 1, true) then return text end
    local okl, code = pcall(funcLuaCommand, VRFW.commands.GET_LANGUAGE_CODE)
    local ok, out = pcall(funcLuaCommand, VRFW.commands.VRFW_TEXT_EXPAND_TAGS, text, okl and tonumber(code) or -1)
    if ok and type(out) == "string" and out ~= "" then return out end
    return (text:gsub("%s*<%u%u%u:[^>]*>%s*", " "):gsub("^%s+", ""):gsub("%s+$", ""))
  end

  --- The name of `team`; "" when unknown.
  function T.name(team)
    if team == nil or team == 0 then return "" end
    local _, name = VRFW.host.command(T.TEAM_INFO, team, 2)
    if type(name) == "string" then return expand_tags(name) end
    return ""
  end

  local function emblem_key(layer, idx)
    return tostring(layer) .. ":" .. tostring(idx)
  end

  --- Shows the emblem of `team` on (layer, idx), once while it stays in `shown`.
  function T.emblem(layer, idx, team, shown)
    local key = emblem_key(layer, idx)
    if shown ~= nil then
      if shown[key] == team then return end
      if shown[key] ~= nil then pcall(funcLuaMenuCommand, T.ICON_RESET, layer, idx, T.EMBLEM_TEXTURE) end
      shown[key] = team
    end
    local ok, has, icon = pcall(funcLuaCommand, T.TEAM_INFO, team, 6, 0)
    if ok and has then pcall(funcLuaMenuCommand, T.ICON_REQUEST, layer, idx, T.EMBLEM_MESH, T.EMBLEM_TEXTURE, icon) end
  end

  --- Shows crest `emblem` on (layer, idx), once while it stays in `shown`.
  function T.crest(layer, idx, emblem, shown, mesh, texture)
    local key = emblem_key(layer, idx)
    texture = texture or T.EMBLEM_TEXTURE
    if shown ~= nil then
      if shown[key] == emblem then return end
      if shown[key] ~= nil then pcall(funcLuaMenuCommand, T.ICON_RESET, layer, idx, texture) end
      shown[key] = emblem
    end
    if (emblem or 0) ~= 0 then pcall(funcLuaMenuCommand, T.ICON_REQUEST, layer, idx, mesh or T.EMBLEM_MESH, texture, emblem, 0) end
  end

  --- Resets the emblem of (layer, idx) and clears it from `shown`.
  function T.emblem_reset(layer, idx, shown)
    local key = emblem_key(layer, idx)
    if shown ~= nil and shown[key] ~= nil then
      pcall(funcLuaMenuCommand, T.ICON_RESET, layer, idx, T.EMBLEM_TEXTURE)
      shown[key] = nil
    end
  end

  --- Clears (layer, idx) from `shown`.
  function T.emblem_forget(layer, idx, shown)
    if shown ~= nil then shown[emblem_key(layer, idx)] = nil end
  end
end
