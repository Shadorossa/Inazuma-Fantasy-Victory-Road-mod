-- menu_engine: the CARD PAGE of the team editor, the player plate's part (VRFW_TeamEditor.ShowCard,
-- lua\_all\81_team_editor.lua, docs/framework/team-editor.md). Definitions only; no engine call at load.
--
-- A host opened this plate on its own for one card (the parameter VRFW_team_editor_card_page_host names the host
-- menu while its page is up). Then the plate is the player page:
--   * its OnInit calls the host VM's VRFW_TeamEditor_CardPageOpened (the host's coroutine goes on);
--   * B closes it (no parent screen closes it here) with the retail back sound;
--   * L1 / R1 switch no player (the page has no team list): the retail previous / next player functions are taken;
--   * its FinalizeMenu calls the host VM's VRFW_TeamEditor_CardPageClosed (the host comes back).
-- A plate opened by a dock, a bank or any other screen reads no host and nothing changes.
if VRFW_Host ~= nil then
  local STEM = "personal_plate_menu"
  local K = {
    PLATE = 1427722143,              -- personal_plate_menu
    CLOSE_MENU = 320421347,          -- CMND_CLOSE_MENU_OBJECT (menu)
    CALL_IN_MENU = 830228314,        -- (menu, "global function", ...)
    SOUND = VRFW_Cmd.SND_PLAY_SE,    -- (sound)
    SE_BACK = 202039849,             -- the retail back sound
    LOG = VRFW_Cmd.EVT_LOG,          -- CMND_EVT_LOG
    -- OnFunction ids the retail plate sends to OnFunctionCommonLeftAndRight (the previous / next player of its list)
    SWITCH = { [3033167124] = true, [2053629800] = true },
  }
  local S = { host = nil, closing = false }

  local function log(text)
    pcall(funcLuaCommand, K.LOG, "VRFW team editor", "card page: " .. text)
  end

  local function call_host(name)
    if S.host ~= nil then
      pcall(funcLuaCommand, K.CALL_IN_MENU, S.host, name)
    end
  end

  VRFW_Host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_card_page", phase = "after",
    fn = function()
      local E = VRFW_TeamEditor
      S.host, S.closing, S.switch_logged = nil, false, false
      if type(E) == "table" and type(E.PageHost) == "function" then
        S.host = E.PageHost()
      end
      if S.host ~= nil then
        log(string.format("the plate is the page of host 0x%08X", S.host))
        call_host(E.PAGE_OPENED_CALL)
      end
    end,
  })

  VRFW_Host.on(STEM, "OnBack", {
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
        pcall(funcLuaCommand, K.SOUND, K.SE_BACK)
        pcall(funcLuaCommand, K.CLOSE_MENU, K.PLATE)
        log("B: the page closes")
      end
      return 1
    end,
  })

  VRFW_Host.on(STEM, "OnFunction", {
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

  VRFW_Host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_card_page", phase = "before", create = true,
    fn = function()
      if S.host ~= nil then
        local E = VRFW_TeamEditor
        call_host(type(E) == "table" and E.PAGE_CLOSED_CALL or "VRFW_TeamEditor_CardPageClosed")
        log("closed: the host is called back")
      end
      S.host, S.closing = nil, false
    end,
  })
end
