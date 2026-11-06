-- menu_engine: the FOREIGN TEAM mode of the team dock's lineup screen (team_dock_formation_menu), for
-- VRFW_TeamEditor.Run with spec.foreign (lua\_all\81_team_editor.lua, docs/framework/team-editor.md; the dock's own
-- part: soccer_team_dock_menu\130_foreign_team.lua). Definitions only; no engine call at load.
--
-- The lineup shows a team that is not one of the player's: only that team's own players move.
--   * a swap only among the team's players (VRFW_TeamEditor.GuardSwap: a player of the club bank or of another dock
--     is refused by the retail place check);
--   * L1 / R1 (the next dock) is refused and its arrows are hidden;
--   * the team COMANDOS window («Equipar todo»: the player's own items and beans on the team) is refused and its
--     guide entry (CMD_FUNC2) left out;
--   * a card's command list keeps only the rows kept in KEEP_ROWS (moving the card); the others (ability board,
--     equipment, passives, captain, spirit, kit number...) would edit the team's players. Nothing else is left, so the
--     card's PERSONAJE window never opens: a decide on a player card starts the move at once (the retail kind 0 row's
--     own action); the coach card takes no decide.
-- In the TEAM PAGE mode (foreign.tab) only the swap guard, the refused L1 / R1 and the hidden arrows apply: the
-- coach, the COMANDOS window and the card's whole command list stay as in the retail screen.
-- With spec.hide_pager the lineup's team-slot pager (soccer_formation_menu's change guide: arrows, team icon, number,
-- L1 / R1) stays hidden: the retail shows it again after each card action (SetVisibleTeamDockArrow follows every show).
-- The mode is read once per open at OnInit (VRFW_TeamEditor.Foreign()).
if VRFW_Host ~= nil then
  local STEM = "team_dock_formation_menu"
  local K = {
    NEXT_DOCK = 2294853123,          -- OnFunction: L1 / R1, the next dock
    TEAM_COMMANDS = 3462361874,      -- OnFunction: the team COMANDOS window («Equipar todo», soccer_formation_menu_inc)
    TEAM_COMMANDS_INPUT = 3170216173,   -- CMD_FUNC2: its button guide entry
    CARDS = 1973487846,              -- team00_01_chara_card_for_soccer
    COACH_CARD = 1658289671,         -- team00_01_chara_card_for_leader
    FORMATION_MENU = 2049316981,     -- soccer_formation_menu (the lineup's input owner)
    CURSOR = 2296367164,             -- cmn05_01_cursor
    CHANGE_GUIDE = 255314328,        -- team14_04_team_dock_change_guide (soccer_formation_menu's team-slot pager)
    ZONE = 855005857,                -- (layer, index, on[, menu]): an instance's pointer zone
    MENU_INPUT = 1558704558, CONTROL_FOCUS = VRFW_Cmd.SET_ENABLE_CTRL_FOCUS, VISIBLE = VRFW_Cmd.SET_LAYER_VISIBLE,
    KEEP_ROWS = { [0] = true },      -- card command kinds kept (retail kind 0: move the card)
    SOUND = VRFW_Cmd.SND_PLAY_SE, SE_NO = 2086672038,   -- sy0003
    LOG = VRFW_Cmd.EVT_LOG,                -- CMND_EVT_LOG
    EXISTS = VRFW_Cmd.IS_EXIST_MENU_OBJECT,  -- (menu) -> the menu object exists
    OPENING = 667479479,             -- (menu) -> the menu object is still opening (the retail opener waits on it)
    SUB_WINDOW = 968210065,          -- sub_window (the card's PERSONAJE window)
    MODEL_COMP = 3685122053,         -- menu_chara_model_comp (a 3D model view)
  }
  local S = { on = false, tab = false, hidden = {}, no_pager = false }

  -- the pager hidden with its pointer zone (it belongs to soccer_formation_menu)
  local function hide_pager()
    pcall(funcLuaMenuCommand, K.VISIBLE, K.CHANGE_GUIDE, 0, false, K.FORMATION_MENU)
    pcall(funcLuaMenuCommand, K.ZONE, K.CHANGE_GUIDE, 0, false, K.FORMATION_MENU)
  end

  local function log(text)
    pcall(funcLuaCommand, K.LOG, "VRFW team editor", "lineup: " .. text)
  end

  VRFW_Host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_foreign", phase = "before", priority = -1000,
    fn = function()
      local editor = VRFW_TeamEditor
      local foreign = type(editor) == "table" and type(editor.Foreign) == "function" and editor.Foreign() or nil
      S.on = foreign ~= nil
      S.tab = foreign ~= nil and foreign.tab == true
      S.hidden = foreign ~= nil and type(foreign.hidden_card_rows) == "table" and foreign.hidden_card_rows or {}
      S.no_pager = foreign ~= nil and foreign.hide_pager == true
      if S.on then
        log(S.tab and "team page mode on" or "foreign team mode on")
      end
    end,
  })

  VRFW_Host.on(STEM, "SwapChara", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on and type(VRFW_TeamEditor) == "table" and VRFW_TeamEditor.GuardSwap then
        return VRFW_TeamEditor.GuardSwap(nxt, ...)
      end
      return nxt(...)
    end,
  })

  local function retail(name, ...)
    local f = rawget(_ENV, name)
    if type(f) == "function" then
      return f(...)
    end
    return nil
  end

  -- the coach card: view only
  VRFW_Host.on(STEM, "OnEnter", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, ...)
      if S.on and not S.tab and a1 == K.COACH_CARD then
        pcall(funcLuaCommand, K.SOUND, K.SE_NO)
        return 1
      end
      return nxt(a1, ...)
    end,
  })

  -- a player card: the move at once, as the retail command window's kind 0 row does after it closes (the card's focus
  -- and the lineup's input back, OnEnterCommon), with no window
  VRFW_Host.on(STEM, "OnDecideFocus", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, a2, ...)
      if not S.on or S.tab or a1 ~= K.CARDS or retail("IsChangeMemberMode") == true then
        return nxt(a1, a2, ...)
      end
      retail("OnDecideFocusCommon", a1, a2)
      pcall(funcLuaMenuCommand, K.MENU_INPUT, K.FORMATION_MENU, true)
      pcall(funcLuaMenuCommand, K.CONTROL_FOCUS, a1, true)
      pcall(funcLuaMenuCommand, K.VISIBLE, K.CURSOR, 0, true)
      local handle = retail("GetFormationSelectCharaStHdl")
      if type(handle) ~= "number" or handle == 0 then
        return
      end
      retail("OnEnterCommon", a1, a2)
    end,
  })

  VRFW_Host.on(STEM, "OnFunction", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, ...)
      if S.on and (a1 == K.NEXT_DOCK or (a1 == K.TEAM_COMMANDS and not S.tab)) then
        pcall(funcLuaCommand, K.SOUND, K.SE_NO)
        return
      end
      return nxt(a1, ...)
    end,
  })

  local function menu_state(menu)
    local ok, up = pcall(funcLuaMenuCommand, K.EXISTS, menu)
    local ok2, opening = pcall(funcLuaCommand, K.OPENING, menu)
    return "up " .. tostring(ok and up) .. ", opening " .. tostring(ok2 and opening)
  end

  -- team page: the card's PERSONAJE window, its request and its end logged (the retail opener returns once it is open)
  VRFW_Host.on(STEM, "OpenSubWinSelectCharaSetting", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if not S.on then
        return nxt(...)
      end
      log("player menu requested: sub window " .. menu_state(K.SUB_WINDOW) .. "; model view " .. menu_state(K.MODEL_COMP))
      local r = table.pack(nxt(...))
      log("player menu opened: sub window " .. menu_state(K.SUB_WINDOW))
      return table.unpack(r, 1, r.n)
    end,
  })

  -- the lineup's guide entries (text, glyph, offset, 0, enable, input) without the COMANDOS one
  VRFW_Host.on(STEM, "AddButtonGuideInfo", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on and not S.tab and select(6, ...) == K.TEAM_COMMANDS_INPUT then
        return
      end
      return nxt(...)
    end,
  })

  VRFW_Host.on(STEM, "SetVisibleTeamDockArrow", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, visible, ...)
      if S.on then
        local r = nxt(false, ...)
        if S.no_pager then hide_pager() end
        return r
      end
      return nxt(visible, ...)
    end,
  })

  -- the pager as the lineup opens (soccer_formation_menu shows it with its own layers)
  VRFW_Host.on(STEM, "OnOpenEndLayer", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function()
      if S.on and S.no_pager then hide_pager() end
    end,
  })

  -- the card's command list (after every other mod's rows: highest priority runs last), as a copy
  VRFW_Host.on(STEM, "GetSelectSettingTypeOrderList", {
    id = "menu_engine.team_editor_foreign", phase = "after", priority = 1000,
    fn = function(r)
      if not S.on or type(r[1]) ~= "table" then
        return
      end
      -- the team page keeps every row but the ones its caller hides (spec.hide_card_rows); a foreign team only KEEP_ROWS
      local keep = {}
      for _, kind in ipairs(r[1]) do
        if (S.tab and not S.hidden[kind]) or (not S.tab and K.KEEP_ROWS[kind]) then
          keep[#keep + 1] = kind
        end
      end
      r[1] = keep
    end,
  })

  VRFW_Host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_foreign", phase = "before", create = true,
    fn = function()
      S.on = false
    end,
  })
end
