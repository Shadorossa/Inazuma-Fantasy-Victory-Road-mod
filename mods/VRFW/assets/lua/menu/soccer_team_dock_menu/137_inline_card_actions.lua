if VRFW.host ~= nil then
  local STEM = "soccer_team_dock_menu"
  local K = {
    CARDS = 1973487846,              -- team00_01_chara_card_for_soccer
    COACH_CARD = 1658289671,         -- team00_01_chara_card_for_leader
    DOCK = 937147172,                -- soccer_team_dock_menu
    PAGE_FUNCTION = 4219711668,
    HAS_FOCUS = 102308320,           -- (layer[, index]) -> the layer (instance) has the focus
    FOCUS_IDX = 2603265800,          -- (layer) -> focused index
    MENU_INPUT = 1558704558,         -- (menu, on)
    MENU_RESUME = 66378409,          -- (menu, 1): the retail ResumeTeamDock
    SOUND = VRFW.commands.SND_PLAY_SE, SE_CANCEL = 202039849,   -- sy0001
  }
  local S = { on = false, opening = nil, next_mode = nil, co = nil }

  local log = VRFW.logger.new("VRFW team editor, dock")

  local function retail(name, ...)
    local f = rawget(_ENV, name)
    if type(f) == "function" then
      return f(...)
    end
    return nil
  end

  local function editor()
    local E = VRFW.team_editor
    return type(E) == "table" and type(E.set_card_action) == "function" and E or nil
  end

  local function card_layer(layer)
    return layer == K.CARDS or layer == K.COACH_CARD
  end

  -- the player card layer that has the focus and its index, nil when none
  local function focused_card()
    for _, layer in ipairs({ K.CARDS, K.COACH_CARD }) do
      local has = VRFW.host.menu_command(K.HAS_FOCUS, layer)
      if has == true then
        local idx = VRFW.host.menu_command(K.FOCUS_IDX, layer)
        return layer, (type(idx) == "number") and idx or 0
      end
    end
    return nil
  end

  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_card_actions", phase = "before",
    fn = function()
      local E = editor()
      local foreign = E ~= nil and E.foreign() or nil
      S.on = foreign ~= nil and foreign.inline_card_actions == true
      S.opening, S.next_mode, S.co = nil, nil, nil
      if S.on then
        E.set_card_action(nil)
        E.take_card_move()
        log("inline card actions on (A: the card's popup on the dock, Y: the player page)")
      end
    end,
  })

  local function open(nxt, mode, layer, row, ...)
    local E = editor()
    S.opening = mode
    E.set_card_action(mode)
    E.take_card_move()
    log(string.format("card %d: lineup screen hidden, %s", row or -1,
      mode == E.CARD_ACTION.PAGE and "player page" or "popup"))
    local r = table.pack(pcall(nxt, layer, row, ...))
    S.opening = nil
    E.set_card_action(nil)
    if not r[1] then
      log("card action error " .. tostring(r[2]))
      return
    end
    if E.take_card_move() then
      log(string.format("card %d: move started on the dock", row or -1))
      retail("OnEnterCommon", layer, row, true)
    end
    return table.unpack(r, 2, r.n)
  end

  VRFW.host.on(STEM, "OnEnter", {
    id = "menu_engine.team_editor_card_actions", phase = "around", priority = -900,
    fn = function(nxt, layer, row, ...)
      if not S.on or not card_layer(layer) or editor() == nil then
        return nxt(layer, row, ...)
      end
      if retail("IsChangeMemberMode") == true then
        return retail("OnEnterCommon", layer, row, true)
      end
      local E = editor()
      local mode = S.next_mode or E.CARD_ACTION.POPUP
      S.next_mode = nil
      return open(nxt, mode, layer, row, ...)
    end,
  })

  VRFW.host.on(STEM, "SetIsTeamDockTop", {
    id = "menu_engine.team_editor_card_actions", phase = "after",
    fn = function(_, top)
      if S.opening ~= nil and top == false then
        VRFW.host.menu_command(K.MENU_RESUME, K.DOCK, 1)
        pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, false)
      end
    end,
  })

  VRFW.host.on(STEM, "OnBack", {
    id = "menu_engine.team_editor_card_actions", phase = "around", priority = -900,
    fn = function(nxt, layer, ...)
      if S.on and card_layer(layer) and retail("IsChangeMemberMode") == true then
        VRFW.host.command(K.SOUND, K.SE_CANCEL)
        retail("TerminateMemberChangeMode", rawget(_ENV, "_teamDockTop"))
        return 1
      end
      return nxt(layer, ...)
    end,
  })

  VRFW.host.on(STEM, "OnFunction", {
    id = "menu_engine.team_editor_card_actions", phase = "around", priority = -1100,
    fn = function(nxt, a1, ...)
      if not S.on or a1 ~= K.PAGE_FUNCTION or editor() == nil then
        return nxt(a1, ...)
      end
      local layer, row = focused_card()
      if layer == nil then
        return nxt(a1, ...)
      end
      if S.co ~= nil or S.opening ~= nil or retail("IsChangeMemberMode") == true then
        return
      end
      S.co = coroutine.create(function()
        S.next_mode = editor().CARD_ACTION.PAGE
        local onenter = rawget(_ENV, "OnEnter")
        if type(onenter) == "function" then
          onenter(layer, row)
        end
        S.next_mode = nil
      end)
    end,
  })

  VRFW.host.on(STEM, "Step", {
    id = "menu_engine.team_editor_card_actions", phase = "after",
    fn = function()
      if S.co == nil then
        return
      end
      local ok, err = coroutine.resume(S.co)
      if not ok then
        log("player page error " .. tostring(err))
        S.next_mode = nil
        pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
      end
      if not ok or coroutine.status(S.co) == "dead" then
        S.co = nil
      end
    end,
  })

  VRFW.host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_card_actions", phase = "before", create = true,
    fn = function()
      if S.on and editor() ~= nil then
        editor().set_card_action(nil)
        editor().take_card_move()
      end
      S.on, S.opening, S.next_mode, S.co = false, nil, nil, nil
    end,
  })
end
