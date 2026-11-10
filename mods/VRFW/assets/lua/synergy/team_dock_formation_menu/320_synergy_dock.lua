if VRFW.host ~= nil then
  local STEM = "team_dock_formation_menu"
  local DETAIL = 1473585342              -- team16_02_synergy_item_detail
  -- the game's two draws of this detail: (layer, item, team) on the own team, (layer, item, team) on a viewed one
  local DRAW = { [1150348853] = true, [2887296767] = true }

  local function synergy()
    return VRFW.synergy
  end

  VRFW.host.on(STEM, "ChangeFocusToSynergyAttachmentButton", {
    id = "menu_engine.synergy_dock", phase = "around",
    fn = function(nxt, ...)
      local real = funcLuaMenuCommand
      local item = 0
      funcLuaMenuCommand = function(cmd, layer, a, ...)
        if DRAW[cmd] and layer == DETAIL and type(a) == "number" then item = a end
        return real(cmd, layer, a, ...)
      end
      local r = table.pack(pcall(nxt, ...))
      funcLuaMenuCommand = real
      if not r[1] then error(r[2], 0) end
      local S = synergy()
      if S ~= nil and S.apply_panel ~= nil then
        local ok, e = pcall(S.apply_panel, item)
        if not ok and S.err == nil then
          S.err = tostring(e)
          VRFW.logger.new("VRFW synergy dock panel")("error", S.err)
        end
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  -- the detail hidden (focus left the synergy buttons): the rows' extra pieces off
  VRFW.host.on(STEM, "UnsetFocusSynergyAttachmentButton", {
    id = "menu_engine.synergy_dock", phase = "after",
    fn = function()
      local S = synergy()
      if S ~= nil and S.hide_extras ~= nil then pcall(S.hide_extras) end
    end,
  })

  -- the synergy rows' extra layers: an instance built is placed and shown
  VRFW.host.on(STEM, "OnOpenLayer", {
    id = "menu_engine.synergy_dock", phase = "after", create = true,
    fn = function(r, a1, a2)
      local S = synergy()
      if S ~= nil and S.built ~= nil then pcall(S.built, a1, a2) end
    end,
  })
end
