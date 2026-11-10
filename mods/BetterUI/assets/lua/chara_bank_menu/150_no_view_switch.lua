if VRFW.host ~= nil then
  local STEM = "chara_bank_menu"
  local SWITCH_FUNCTION = 3959000859
  local GUIDE = 3026610789               -- team14_06_active_ui_change_guide
  local LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE        -- (layer, instance, visible)

  -- a player page is open (the menu's local `flag`)
  local function plate_open()
    local h = VRFW.host.hosts ~= nil and VRFW.host.hosts[STEM] or nil
    local l = h ~= nil and h.L or nil
    local ok, v = pcall(function() return l.flag end)
    return ok and v == true
  end

  VRFW.host.on(STEM, "OnFunction", {
    id = "BetterUI.bank_no_view_switch", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 == SWITCH_FUNCTION and not plate_open() then
        return
      end
      return nxt(a1, ...)
    end,
  })

  local function hide(r, a1, a2)
    if a1 == GUIDE then
      VRFW.host.menu_command(LAYER_VISIBLE, GUIDE, a2 or 0, false)
    end
  end
  VRFW.host.on(STEM, "OnSetupLayer", { id = "BetterUI.bank_no_view_switch", phase = "after", fn = hide })
  VRFW.host.on(STEM, "OnOpenLayer", { id = "BetterUI.bank_no_view_switch", phase = "after", fn = hide })
end
