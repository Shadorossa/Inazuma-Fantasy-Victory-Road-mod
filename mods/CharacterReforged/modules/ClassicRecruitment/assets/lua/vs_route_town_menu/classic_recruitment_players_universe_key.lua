if VRFW.host ~= nil and type(ClassicRecruitment) == "table" then
  local STEM = "vs_route_town_menu"
  local BUTTONS_LAYER = 1423637364        -- the bottom-left Tab / Alt buttons
  local UNIVERSE_BUTTON = 0               -- the Tab button (OpenUniverse)
  local SET_LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE     -- (layer, instance, visible)

  local function removed()
    return ClassicRecruitment.holds(ClassicRecruitment.gacha_removed)
  end

  VRFW.host.on(STEM, "OpenUniverse", {
    id = "ClassicRecruitment.universe_key", phase = "around",
    fn = function(nxt, ...)
      if removed() then
        return
      end
      return nxt(...)
    end,
  })

  for _, point in ipairs({"OnSetupLayer", "OnOpenLayer"}) do
    VRFW.host.on(STEM, point, {
      id = "ClassicRecruitment.universe_button_" .. point, phase = "after",
      fn = function(_, layer, instance)
        if layer == BUTTONS_LAYER and instance == UNIVERSE_BUTTON and removed() then
          VRFW.host.menu_command(SET_LAYER_VISIBLE, layer, instance, false)
        end
      end,
    })
  end
end
