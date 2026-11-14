
--- Advanced: Namespace of the free match difficulty extension.
VRFW.free_match = VRFW.free_match or {}
local FM = VRFW.free_match
--- Internal: set of bypassed difficulty locks.
FM.bypassed = FM.bypassed or {}

local K = {
  RULES = VRFW.commands.VRFW_FM_RULES,        -- CMND_VRFW_FM_RULES
  DIFFS = VRFW.commands.VRFW_FM_DIFFICULTIES,        -- CMND_VRFW_FM_DIFFICULTIES
  TXT_ASK = 4268189860,      -- crc32("vrfw_fm_ask_team"): "Play against %s?"
  TXT_LOCKED = 2350615877,
  TEXT_GET = VRFW.commands.TEXT_GET,     -- CMND_TEXT_GET
  CLEAR = VRFW.commands.GET_SOCCER_GAME_CLEAR_FLAG,         -- CMND_GET_SOCCER_GAME_CLEAR_FLAG
  LIST = 1107559438,         -- team05_03_soccer_cpu_opponent_list
  ITEM = 1074924810,         -- mainmenu90_19_vs_cpu_list_item
  MENU = 1970579282,         -- soccer_vs_cpu_list_menu
  ORB_LAYER = 4088477286,    -- vsroute01_06b_town_map_piece_clear_icon
  POS = {[6] = 1611754387, [7] = 4179114537, [8] = 2384399039, [9] = 276537116},   -- _pos_clear01..04
  POS_BASE01 = 1517329426, POS_BASE02 = 3279539624, CLEAR_BASE01 = 1003654013, POS_CLEAR05 = 1736224650,
  SAVED_TAB = 3683890655,    -- the temp byte the screen keeps its tab in (retail n6)
  logs = 0,
}

local capped_logger = VRFW.logger.new("VRFW fm_difficulty")
local function Log(...)
  if K.logs >= 20 then
    return
  end
  K.logs = K.logs + 1
  capped_logger(...)
end

-- Internal: the rules (nil = the DLL did not answer: retail)
function FM.rules()
  if FM.rules_cache == nil then
    local r = {VRFW.host.command(K.RULES)}
    if r[1] == true then
      FM.rules_cache = {ticks = r[2] ~= false, best = r[3] == true, direct = r[4] == true, together = r[5] == true, top = r[6] == true,
                  cls = r[7] ~= false}
    else
      FM.rules_cache = false
    end
  end
  return FM.rules_cache or nil
end

-- Internal: true while a mod uses the list for something else
function FM.bypass(id, on)
  FM.bypassed[id] = on and true or nil
end
--- Advanced: Restores the retail difficulty locks; no args; answers nothing.
function FM.off()
  for _, v in pairs(FM.bypassed) do
    if v then
      return true
    end
  end
  return false
end

-- Advanced: the classes `game` offers, ascending (cached per open); nil = the DLL did not answer
function FM.diffs(game)
  --- Internal: cached difficulty lists by game.
  FM.cache = FM.cache or {}
  local t = FM.cache[game]
  if t == nil then
    t = {}
    local r = {VRFW.host.command(K.DIFFS, game)}
    if r[1] == true and type(r[2]) == "number" then
      for i = 1, r[2] do
        if type(r[2 + i]) == "number" then
          t[#t + 1] = r[2 + i]
        end
      end
    end
    FM.cache[game] = t
  end
  if #t == 0 then
    return nil
  end
  return t
end

-- Internal: the preview class of `game`: its lowest offered class, or the highest with Preview = "top"
function FM.preview(game)
  local R, t = FM.rules(), FM.diffs(game)
  if R == nil or t == nil then
    return nil
  end
  return R.top and t[#t] or t[1]
end

-- True when class `d` of `game` was won in a free match (the retail clear flag).
local function retail_cleared(game, d)
  return funcLuaCommand(K.CLEAR, game, d) == true
end

--- Advanced: The highest offered class of `game` that cleared(game, d) answers true for (default: the retail clear flag); 0 = none.
function FM.best(game, cleared)
  cleared = cleared or retail_cleared
  local best = 0
  for _, d in ipairs(FM.diffs(game) or {}) do
    if d > best and cleared(game, d) then
      best = d
    end
  end
  return best
end

--- Advanced: Paints the orb of list row `instance` for `game` as the Orb rule says, with cleared(game, d) (default: the retail clear flag).
function FM.draw_orb(instance, game, cleared)
  cleared = cleared or retail_cleared
  local R = FM.rules()
  if R == nil or not R.best then
    for d = 6, 9 do
      funcLuaMenuCommand(2158717427, K.ORB_LAYER, K.POS[d], cleared(game, d), instance)
    end
    return
  end
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, K.ORB_LAYER, instance, true)
  funcLuaMenuCommand(2158717427, K.ORB_LAYER, K.POS_BASE01, true, instance)
  funcLuaMenuCommand(2158717427, K.ORB_LAYER, K.POS_BASE02, true, instance)
  funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, K.ORB_LAYER, K.CLEAR_BASE01, false, instance)
  funcLuaMenuCommand(2158717427, K.ORB_LAYER, K.POS_CLEAR05, false, instance)
  local best = FM.best(game, cleared)
  for d = 6, 9 do
    funcLuaMenuCommand(2158717427, K.ORB_LAYER, K.POS[d], d == best, instance)
  end
end

--- Internal: text for a text id; answers the string.
function FM.text(id)
  local s = VRFW.host.command(K.TEXT_GET, id)
  if type(s) == "string" and s ~= "" then
    return s
  end
  return nil
end

--- Advanced: Answers true when the difficulty is locked for game and story.
function FM.locked(game, story)
  local t = FM.diffs(game) or {9}
  return VRFW.free_match_lock.retail_locked(game, story, t[#t] - 6) and VRFW.free_match_lock.retail_locked(game, story, t[1] - 6)
end

-- Internal: the opponent `game` decided on the list; true = handled here (locked, or the one-class match)
function FM.decide(game, story)
  local R = FM.rules()
  if R.together and FM.locked(game, story) then
    local locked = FM.text(K.TXT_LOCKED)
    if locked ~= nil then
      funcLuaMenuCommand(1558704558, K.MENU, false)
      funcLuaCommand(2599933690, 0, 2086672038 --[[sy0003]])
      VRFW.question.notice(locked)
      funcLuaMenuCommand(1558704558, K.MENU, true)
    else
      funcLuaCommand(VRFW.commands.SND_PLAY_SE, 2086672038 --[[sy0003]])
    end
    return true
  end
  local diffs = FM.diffs(game)
  if not R.direct or diffs == nil or #diffs ~= 1 then
    return false
  end
  local text = 2509321689 --[[¿Empezar partido?]]
  local ok, team = funcLuaCommand(2204933160, game)
  if ok then
    local ok2, name = funcLuaCommand(2151743654, team, 2)
    local ask = FM.text(K.TXT_ASK)
    if ok2 and name ~= nil and name ~= "" and ask ~= nil and string.find(ask, "%s", 1, true) then
      text = string.gsub(ask, "%%s", function() return name end, 1)
    end
  end
  funcLuaMenuCommand(1558704558, K.MENU, false)
  if not VRFW.question.ask(text, {on_open = function() funcLuaCommand(2529383714, 0, 1, 0) end}) then
    funcLuaMenuCommand(1558704558, K.MENU, true)
    return true
  end
  -- the steps of soccer_vs_cpu_class_select_menu OnDecideFocus, at the opponent's only class
  local diff = diffs[1]
  if funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, 811496143 --[[soccer_top_menu]]) then
    if VRFW.param.has(570346750) then
      VRFW.param.clear(570346750)
    end
    VRFW.param.set(570346750, 1)          -- tells soccer_top_menu.OpenList a match starts
  end
  BrightFadeAllMenu(2721617045 --[[fade_menu_encount]], true)
  local ret, ret2 = funcLuaCommand(634509816, game, 4)
  if not ret then
    ret2 = 3468355528 --[[s90g001]]
  end
  funcLuaCommand(VRFW.commands.SET_PRE_MATCH_SOCCER_GAME_ID, game)
  funcLuaCommand(1104380539, diff)
  local okr = funcLuaCommand(VRFW.commands.RESERVE_SOCCER, game, ret2, diff)
  Log("reserve", game, ret2, diff, okr)
  funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, K.MENU)
  return true
end

-- the focused opponent's game (0 = none)
local function Focused()
  local ok, g = funcLuaMenuCommand(1666448199, 0)
  if ok and type(g) == "number" then
    return g
  end
  return 0
end

-- Advanced: the team of `game`'s row of class `d` (nil = no answer)
function FM.team(game, d)
  local has, team = VRFW.host.command(2204933160, game, d)
  if has and type(team) == "number" and team ~= 0 then
    return team
  end
  return nil
end

-- the retail chunk's locals (the host's map; nil without VRFW.debug)
local function HostL()
  local h = VRFW.host ~= nil and VRFW.host.hosts ~= nil and VRFW.host.hosts.soccer_vs_cpu_list_menu or nil
  return h ~= nil and h.L or nil
end

-- the preview's team name and emblem for `team` (the retail OnChangeFocus steps)
local function TeamHeader(team)
  local has, name = VRFW.host.command(2151743654, team, 2)
  if has then
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 1835074715 --[[mainmenu90_34_cpu_team_formation]], 3778687894 --[[_text_team_name01]], name or "", 0)
  end
  local has2, emblem = VRFW.host.command(2151743654, team, 6, 0)
  if has2 then
    funcLuaMenuCommand(3190452549, 1835074715 --[[mainmenu90_34_cpu_team_formation]], 0, 574244154 --[[_cpu_icon_emblem_dmy01]], 1949581463 --[[cpu_icon_emblem_dmy01]], emblem)
    local L = HostL()
    if L ~= nil then
      pcall(function() L.n10 = emblem end)
    end
  end
end

local function RePreview()
  local g = Focused()
  local d = g ~= 0 and FM.preview(g) or nil
  if d == nil or UpdateDifficult == nil then
    return
  end
  local team = FM.team(g, d)
  local L = HostL()
  local set = false
  if team ~= nil and L ~= nil then
    local ok, cur = pcall(function() return L.n2 end)
    if ok and cur ~= team then
      set = pcall(function() L.n2 = team end)
      if set then
        TeamHeader(team)
      end
    elseif ok then
      set = true
    end
  end
  UpdateDifficult(d)
  if team ~= nil and not set and UpdateFormation ~= nil then
    TeamHeader(team)
    UpdateFormation(team, g)             -- no access to the chunk's locals: draw the class's team once
  end
end

--- Advanced: Listeners called when the shown team changes.
FM.shown_team_listeners = FM.shown_team_listeners or {}
--- Internal: key of the shown team, or nil.
FM.shown = nil
--- Internal: handles a shown-team change for game, d, team.
function FM.shown_team_changed(game, d, team)
  local key = tostring(game) .. ":" .. tostring(d) .. ":" .. tostring(team)
  if FM.shown == key then
    return
  end
  FM.shown = key
  for id, fn in pairs(FM.shown_team_listeners) do
    local ok, why = pcall(fn, game, d, team)
    if not ok then
      Log("shown team listener", id, tostring(why))
    end
  end
end

-- PreviewClass = false: the preview's "Lv." label, level number and class badge hidden
local function HideClass()
  local R = FM.rules()
  if R == nil or R.cls or FM.off() then
    return
  end
  funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, 1835074715 --[[mainmenu90_34_cpu_team_formation]], 2841109264 --[[_chronicle_gtxt_lv01]], false, 0)
  funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, 1835074715 --[[mainmenu90_34_cpu_team_formation]], 2839039721 --[[_chronicle_lv_num_dmy01]], false, 0)
  funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, 1835074715 --[[mainmenu90_34_cpu_team_formation]], 126765991 --[[_cpu_icon_class_dmy01]], false, 0)
  funcLuaMenuCommand(1233047821, 1835074715 --[[mainmenu90_34_cpu_team_formation]], 0, 51927332 --[[the "Nv." number]], false)
end

if VRFW.host ~= nil then
  VRFW.host.on("soccer_vs_cpu_list_menu", "OnInit", {
    id = "menu_engine.free_match_difficulty", phase = "before",
    fn = function()
      FM.cache = nil                 -- the table may change between opens (a reload)
      FM.shown = nil
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateDifficult", {
    id = "menu_engine.free_match_difficulty.shown_team", phase = "around",
    fn = function(nxt, d, ...)
      local L = HostL()
      local game, team = nil, nil
      if L ~= nil and type(d) == "number" and not FM.off() then
        local ok, g = pcall(function() return L.n5 end)
        if ok and type(g) == "number" and g ~= 0 then
          game = g
          team = FM.team(g, d)
        end
      end
      if team ~= nil then
        local ok, cur = pcall(function() return L.n2 end)
        if ok and cur ~= team and pcall(function() L.n2 = team end) then
          local n = VRFW.host.menu_command(VRFW.commands.GET_CREATE_LAYER_NUM --[[created instances]], 1835074715 --[[mainmenu90_34_cpu_team_formation]])
          if type(n) == "number" and n >= 1 then
            TeamHeader(team)
          end
        end
      end
      local r = table.pack(nxt(d, ...))
      if team ~= nil then
        FM.shown_team_changed(game, d, team)
      end
      return table.unpack(r, 1, r.n)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnDecideFocus", {
    id = "menu_engine.free_match_difficulty", phase = "around",
    fn = function(nxt, a1, a2, ...)
      local R = FM.rules()
      if a1 ~= K.LIST or R == nil or not (R.together or R.direct) or FM.off() then
        return nxt(a1, a2, ...)
      end
      local game = Focused()
      if game == 0 then
        return nxt(a1, a2, ...)
      end
      local ok, ret5 = funcLuaMenuCommand(1666448199, 3)
      if not ok then
        ret5 = 0
      end
      local tab = funcLuaCommand(VRFW.commands.GET_TEMP_BYTE_FLAG, K.SAVED_TAB)
      local story = 1
      if IsStory ~= nil and IsStory(tab) and ret5 == 0 then
        story = 0
      end
      if FM.decide(game, story) then
        return
      end
      return nxt(a1, a2, ...)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateItem", {
    id = "menu_engine.free_match_difficulty", phase = "after",
    fn = function(r, a1, a2, a3)
      local R = FM.rules()
      if R == nil or not R.best or a3 == nil or a3 == 0 or FM.off() then
        return
      end
      FM.draw_orb(a2, a3)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", {
    id = "menu_engine.free_match_difficulty.first_draw", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= K.ITEM or FM.rules() == nil or FM.off() then
        return nxt(a1, ...)
      end
      local raw = funcLuaCommand
      funcLuaCommand = function(id, ...)
        if id == 2204933160 and select("#", ...) == 1 then
          local game = ...
          local d = type(game) == "number" and game ~= 0 and FM.preview(game) or nil
          local team = d ~= nil and FM.team(game, d) or nil
          if team ~= nil then
            local L = HostL()
            if L ~= nil then
              pcall(function() L.n8 = d end)
            end
            return true, team
          end
        end
        return raw(id, ...)
      end
      local r = table.pack(pcall(nxt, a1, ...))
      funcLuaCommand = raw
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", {
    id = "menu_engine.free_match_difficulty", phase = "after",
    fn = function(r, a1)
      if a1 == K.ITEM and FM.rules() ~= nil and not FM.off() then
        RePreview()
      end
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateFormation", {
    id = "menu_engine.free_match_difficulty", phase = "after",
    fn = function(r, a1)
      if a1 ~= nil and a1 ~= 0 then
        HideClass()
      end
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OpenClassSelect", {
    id = "menu_engine.free_match_difficulty", phase = "around",
    fn = function(nxt, ...)
      local r = table.pack(nxt(...))
      if FM.rules() ~= nil and not FM.off() then
        RePreview()                  -- the retail code put the preview back on class 6
      end
      return table.unpack(r, 1, r.n)
    end,
  })
end
