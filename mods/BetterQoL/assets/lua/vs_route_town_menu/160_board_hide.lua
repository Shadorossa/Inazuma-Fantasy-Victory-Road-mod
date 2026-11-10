if VRFW.host ~= nil then
  BetterQoL = BetterQoL or {}
  local H = {
    STEM = "vs_route_town_menu",
    FUNCTION = 2195666057,        -- crc32("betterqol_board_hide"): the input row's function
    KEY = 1435897304,             -- CMD_FUNC4
    GLYPH = 2085238077,           -- <CMD_FUNC4>
    HIDE = 1663200964,
    SHOW = 3439609244,
    GUIDE = 1138543975,           -- mainmenu01_06_base_button_guide
    SE = VRFW.commands.SND_PLAY_SE, SE_OK = 3848881948,
  }
  BetterQoL.board_hide = H

  local function available()
    return (VRFW.route_nodes ~= nil and VRFW.route_nodes.hideable_count ~= nil) and VRFW.route_nodes.hideable_count() > 0
  end

  local function hidden()
    return (VRFW.route_nodes ~= nil and VRFW.route_nodes.hide_on ~= nil) and VRFW.route_nodes.hide_on()
  end

  local function prompts()
    if VRFW.footer_prompts == nil then
      return
    end
    VRFW.footer_prompts.add({name = "BetterQoL.BoardHide", menu = H.STEM, text = H.HIDE, icon = H.GLYPH, command = H.KEY,
      order = 50, when = function() return available() and not hidden() end})
    VRFW.footer_prompts.add({name = "BetterQoL.BoardShow", menu = H.STEM, text = H.SHOW, icon = H.GLYPH, command = H.KEY,
      order = 50, when = function() return available() and hidden() end})
  end

  VRFW.host.on(H.STEM, "OnInit", {id = "BetterQoL.board_hide", phase = "before", fn = function() prompts() end})

  VRFW.host.on(H.STEM, "OnFunction", {
    id = "BetterQoL.board_hide", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= H.FUNCTION then
        return nxt(a1, ...)
      end
      if not available() or (VRFW.route_nodes == nil or VRFW.route_nodes.set_hide == nil) then
        return
      end
      VRFW.route_nodes.set_hide(not hidden())
      VRFW.host.command(H.SE, H.SE_OK)
      if SetupButtonGuideInfo ~= nil then
        pcall(SetupButtonGuideInfo, H.GUIDE, 0)    -- the guide again: Hide <-> Show
      end
    end,
  })
end
