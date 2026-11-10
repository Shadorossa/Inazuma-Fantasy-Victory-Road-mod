-- The lineup shows a team that is not one of the player's: only that team's own players move.
if VRFW.host ~= nil then
  local STEM = "team_dock_formation_menu"
  local K = {
    NEXT_DOCK = 2294853123,          -- OnFunction: L1 / R1, the next dock
    TEAM_COMMANDS = 3462361874,
    TEAM_COMMANDS_INPUT = 3170216173,   -- CMD_FUNC2: its button guide entry
    CARDS = 1973487846,              -- team00_01_chara_card_for_soccer
    COACH_CARD = 1658289671,         -- team00_01_chara_card_for_leader
    FORMATION_MENU = 2049316981,
    CURSOR = 2296367164,             -- cmn05_01_cursor
    CHANGE_GUIDE = 255314328,
    ZONE = 855005857,                -- (layer, index, on[, menu]): an instance's pointer zone
    MENU_INPUT = 1558704558, CONTROL_FOCUS = VRFW.commands.SET_ENABLE_CTRL_FOCUS, VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    KEEP_ROWS = { [0] = true },      -- card command kinds kept (retail kind 0: move the card)
    SOUND = VRFW.commands.SND_PLAY_SE, SE_NO = 2086672038,   -- sy0003
    EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT,  -- (menu) -> the menu object exists
    OPENING = 667479479,
    SUB_WINDOW = 968210065,          -- sub_window (the card's PERSONAJE window)
    MODEL_COMP = 3685122053,         -- menu_chara_model_comp (a 3D model view)
  }
  local S = { on = false, tab = false, hidden = {}, no_pager = false }

  -- the pager hidden with its pointer zone (it belongs to soccer_formation_menu)
  local function hide_pager()
    VRFW.host.menu_command(K.VISIBLE, K.CHANGE_GUIDE, 0, false, K.FORMATION_MENU)
    VRFW.host.menu_command(K.ZONE, K.CHANGE_GUIDE, 0, false, K.FORMATION_MENU)
  end

  local log = VRFW.logger.new("VRFW team editor, lineup")

  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_foreign", phase = "before", priority = -1000,
    fn = function()
      local editor = VRFW.team_editor
      local foreign = type(editor) == "table" and type(editor.foreign) == "function" and editor.foreign() or nil
      S.on = foreign ~= nil
      S.tab = foreign ~= nil and foreign.tab == true
      S.hidden = foreign ~= nil and type(foreign.hidden_card_rows) == "table" and foreign.hidden_card_rows or {}
      S.no_pager = foreign ~= nil and foreign.hide_pager == true
      if S.on then
        log(S.tab and "team page mode on" or "foreign team mode on")
      end
    end,
  })

  VRFW.host.on(STEM, "SwapChara", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on and type(VRFW.team_editor) == "table" and VRFW.team_editor.guard_swap then
        return VRFW.team_editor.guard_swap(nxt, ...)
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
  VRFW.host.on(STEM, "OnEnter", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, ...)
      if S.on and not S.tab and a1 == K.COACH_CARD then
        VRFW.host.command(K.SOUND, K.SE_NO)
        return 1
      end
      return nxt(a1, ...)
    end,
  })

  VRFW.host.on(STEM, "OnDecideFocus", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, a2, ...)
      if not S.on or S.tab or a1 ~= K.CARDS or retail("IsChangeMemberMode") == true then
        return nxt(a1, a2, ...)
      end
      retail("OnDecideFocusCommon", a1, a2)
      pcall(funcLuaMenuCommand, K.MENU_INPUT, K.FORMATION_MENU, true)
      VRFW.host.menu_command(K.CONTROL_FOCUS, a1, true)
      VRFW.host.menu_command(K.VISIBLE, K.CURSOR, 0, true)
      local handle = retail("GetFormationSelectCharaStHdl")
      if type(handle) ~= "number" or handle == 0 then
        return
      end
      retail("OnEnterCommon", a1, a2)
    end,
  })

  VRFW.host.on(STEM, "OnFunction", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, ...)
      if S.on and (a1 == K.NEXT_DOCK or (a1 == K.TEAM_COMMANDS and not S.tab)) then
        VRFW.host.command(K.SOUND, K.SE_NO)
        return
      end
      return nxt(a1, ...)
    end,
  })

  local function menu_state(menu)
    local up = VRFW.host.menu_command(K.EXISTS, menu)
    local opening = VRFW.host.command(K.OPENING, menu)
    return "up " .. tostring(up) .. ", opening " .. tostring(opening)
  end

  -- team page: the card's PERSONAJE window, its request and its end logged (the retail opener returns once it is open)
  VRFW.host.on(STEM, "OpenSubWinSelectCharaSetting", {
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
  VRFW.host.on(STEM, "AddButtonGuideInfo", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on and not S.tab and select(6, ...) == K.TEAM_COMMANDS_INPUT then
        return
      end
      return nxt(...)
    end,
  })

  VRFW.host.on(STEM, "SetVisibleTeamDockArrow", {
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
  VRFW.host.on(STEM, "OnOpenEndLayer", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function()
      if S.on and S.no_pager then hide_pager() end
    end,
  })

  -- the card's command list (after every other mod's rows: highest priority runs last), as a copy
  VRFW.host.on(STEM, "GetSelectSettingTypeOrderList", {
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

  VRFW.host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_foreign", phase = "before", create = true,
    fn = function()
      S.on = false
    end,
  })
end
