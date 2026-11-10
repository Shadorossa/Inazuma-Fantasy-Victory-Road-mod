if VRFW.host ~= nil then
  local STEM = "personal_plate_menu"
  local K = {
    PLATE = 1427722143,              -- personal_plate_menu
    MENU_HIDE = 1670867360,          -- (1, menu): the whole menu not drawn
    LOG = VRFW.commands.VRFW_LOG,          -- CMND_VRFW_LOG
  }
  local S = { hides = 0 }

  local function popup()
    local E = VRFW.team_editor
    if type(E) ~= "table" or type(E.card_action) ~= "function" then
      return false
    end
    return E.card_action() == E.CARD_ACTION.POPUP
  end

  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_card_actions", phase = "after",
    fn = function()
      S.hides = 0
      if popup() then
        VRFW.host.menu_command(K.MENU_HIDE, 1, K.PLATE)
        S.hides = 1
        VRFW.host.command(K.LOG, "VRFW team editor", "plate: hidden under the card's popup")
      end
    end,
  })

  VRFW.host.on(STEM, "OnOpenLayer", {
    id = "menu_engine.team_editor_card_actions", phase = "before",
    fn = function()
      if S.hides == 1 and popup() then
        VRFW.host.menu_command(K.MENU_HIDE, 1, K.PLATE)
        S.hides = 2
      end
    end,
  })
end
