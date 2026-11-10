if VRFW.host ~= nil then
  local STEM = "personal_plate_menu"
  local K = {
    PLATE = 1427722143,              -- personal_plate_menu
    CLOSE_MENU = 320421347,          -- CMND_CLOSE_MENU_OBJECT (menu)
    CALL_IN_MENU = 830228314,        -- (menu, "global function", ...)
    SOUND = VRFW.commands.SND_PLAY_SE,    -- (sound)
    SE_BACK = 202039849,             -- the retail back sound
    -- OnFunction ids the retail plate sends to OnFunctionCommonLeftAndRight (the previous / next player of its list)
    SWITCH = { [3033167124] = true, [2053629800] = true },
  }
  local S = { host = nil, closing = false }

  local log = VRFW.logger.new("VRFW team editor, card page")

  local function call_host(name)
    if S.host ~= nil then
      VRFW.host.command(K.CALL_IN_MENU, S.host, name)
    end
  end

  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_card_page", phase = "after",
    fn = function()
      local E = VRFW.team_editor
      S.host, S.closing, S.switch_logged = nil, false, false
      if type(E) == "table" and type(E.page_host) == "function" then
        S.host = E.page_host()
      end
      if S.host ~= nil then
        log(string.format("the plate is the page of host 0x%08X", S.host))
        call_host(E.PAGE_OPENED_CALL)
      end
    end,
  })

  VRFW.host.on(STEM, "OnBack", {
    id = "menu_engine.team_editor_card_page", phase = "around", create = true,
    fn = function(nxt, ...)
      if S.host == nil then
        if type(nxt) == "function" then
          return nxt(...)
        end
        return nil
      end
      if not S.closing then
        S.closing = true
        VRFW.host.command(K.SOUND, K.SE_BACK)
        VRFW.host.command(K.CLOSE_MENU, K.PLATE)
        log("B: the page closes")
      end
      return 1
    end,
  })

  VRFW.host.on(STEM, "OnFunction", {
    id = "menu_engine.team_editor_card_page", phase = "around",
    fn = function(nxt, fid, ...)
      if S.host ~= nil and K.SWITCH[fid] then
        if not S.switch_logged then
          S.switch_logged = true
          log("L1 / R1: no player switch on a card page")
        end
        return 1
      end
      return nxt(fid, ...)
    end,
  })

  VRFW.host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_card_page", phase = "before", create = true,
    fn = function()
      if S.host ~= nil then
        local E = VRFW.team_editor
        call_host(type(E) == "table" and E.PAGE_CLOSED_CALL or "vrfw_team_editor_card_page_closed")
        log("closed: the host is called back")
      end
      S.host, S.closing = nil, false
    end,
  })
end
