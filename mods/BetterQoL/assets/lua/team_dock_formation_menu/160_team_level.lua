-- Team COMANDOS window: «Ajustar nivel del equipo» (option BetterQoL.team_level_cheat) sets every player of the shown team to one level.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if VRFW.host ~= nil and BetterQoL.team_level == nil then
  local STEM = "team_dock_formation_menu"
  local C = VRFW.commands
  local Crc = VRFW.crc32
  local K = {
    OPTION = "BetterQoL.team_level_cheat",
    ROW = 102,                                  -- the entry's row id in the team COMANDOS window
    AFTER_ROW = 101,                            -- BetterUI's «Ajustes de IA» row (BetterUI.team_ai)
    TEXT_ROW = Crc("better_qol_team_level_cmd"),
    TEXT_PICK = Crc("better_qol_team_level_pick"),
    PARAM_TEAM_SET = 3357163798,                -- the team set the screen shows, read and cleared by the retail OnInit
    PARAM_TEAM_TYPE = 4081600465,               -- the team of that set (0 or 1), read and cleared by the retail OnInit
    SET_LEVEL = 4204922749,                     -- 0xFAA2E77D (handle, level): the game's Lua level setter, nie.exe 0xC46130
    CHARA_INFO = 1131797651,                    -- (handle, field) -> a value of the player's status
    FIELD_CAP = 29,                             -- CHARA_INFO field: the level cap in force for that player
    IS_OPENING = 667479479,                     -- (menu object) -> true while it opens
    NUM_WINDOW = Crc("num_shop_window"),        -- the game's amount window (MENU_DEF.OpenNumWindow)
    SE_DECIDE = Crc("sy0000"),
    SE_BEEP = Crc("sy0003"),
    DONE = "BetterQoL_TeamLevelDone",           -- the global BetterQoL_TeamLevelDone below: the amount window calls it by name
  }
  local T = { set = nil, type = 0, picked = nil }
  BetterQoL.team_level = T

  local function log(...)
    T.log = T.log or VRFW.logger.new("BetterQoL team level")
    T.log(...)
  end

  local function on()
    return VRFW.host.command(C.VRFW_OPTION_GET, K.OPTION) == 1
  end

  -- The member handles of the shown team; nil when the game does not answer.
  local function members()
    local TL = VRFW.team_loadout
    if TL == nil or T.set == nil then return nil end
    return TL.members(T.set, T.type)
  end

  -- The highest level cap in force among `handles` (the level cap the active mods gave the game, else the game's own).
  local function cap_of(handles)
    local cap = nil
    for _, h in ipairs(handles) do
      local v = tonumber(VRFW.host.command(K.CHARA_INFO, h, K.FIELD_CAP))
      if v ~= nil and v >= 1 and (cap == nil or v > cap) then cap = math.floor(v) end
    end
    return cap
  end

  -- Receives the amount window's answer (-1 = cancelled) and closes the window.
  function BetterQoL_TeamLevelDone(count)
    T.picked = count
    VRFW.host.command(C.CLOSE_MENU_OBJECT, K.NUM_WINDOW)
  end

  -- Opens the amount window from 1 to the cap and sets every member to the confirmed level; runs in the window's callback coroutine.
  local function run()
    local handles = members()
    local cap = handles ~= nil and cap_of(handles) or nil
    if cap == nil then
      log("team set", tostring(T.set), "type", T.type, ": no member or no level cap read: nothing done")
      VRFW.host.command(C.SND_PLAY_SE, K.SE_BEEP)
      return nil
    end
    T.picked = nil
    VRFW.host.command(C.SND_PLAY_SE, K.SE_DECIDE)
    MENU_DEF.OpenNumWindow(K.DONE, "", 1, cap, K.TEXT_PICK, 1, K.NUM_WINDOW)
    waitFalse(function() return VRFW.host.command(K.IS_OPENING, K.NUM_WINDOW) == true end)
    waitTrue(function() return VRFW.host.command(C.IS_CLOSE_MENU_OBJECT, K.NUM_WINDOW) == true end)
    local level = tonumber(T.picked)
    if level == nil or level < 1 then
      log("cancelled")
      return nil
    end
    level = math.min(math.floor(level), cap)
    local done = 0
    for _, h in ipairs(handles) do
      if VRFW.host.command(K.SET_LEVEL, h, level) ~= false then done = done + 1 end
    end
    log("team set", T.set, "type", T.type, ": level", level, "set on", done, "of", #handles, "member(s), cap", cap)
    return nil
  end

  VRFW.host.on(STEM, "OnInit", { id = "BetterQoL.team_level_team", phase = "before", fn = function()
    T.set = VRFW.param.has(K.PARAM_TEAM_SET) and VRFW.param.get(K.PARAM_TEAM_SET) or nil
    T.type = VRFW.param.has(K.PARAM_TEAM_TYPE) and (VRFW.param.get(K.PARAM_TEAM_TYPE) or 0) or 0
  end })

  -- Adds the entry to the team COMANDOS window through the framework's list rows.
  local function add_row(Rows)
    Rows.add(Rows.TEAM_COMMANDS, { id = "BetterQoL.team_level", row = K.ROW, text = K.TEXT_ROW, after = K.AFTER_ROW,
      when = function() return on() end,
      run = function() return run() end })
  end

  if VRFW.list_rows ~= nil and VRFW.list_rows.add ~= nil then
    add_row(VRFW.list_rows)
  else
    VRFW.list_rows_queue = VRFW.list_rows_queue or {}
    table.insert(VRFW.list_rows_queue, add_row)
  end
end
