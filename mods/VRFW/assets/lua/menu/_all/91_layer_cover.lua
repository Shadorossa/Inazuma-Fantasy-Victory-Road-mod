-- lua_patch.scope: used
-- VRFW layer cover: a menu under another screen hides its own visible layers while that screen asks (a menu event)
-- and shows the same layers back afterwards. Used when the screen above draws its background in the background pass.
if VRFW.layer_cover == nil then
  local C = {layers = {}, hidden = nil}
  --- Advanced: Namespace: records layer instances so a layer can be covered or hidden.
  VRFW.layer_cover = C

  --- Advanced: Records a layer instance the menu set up (called from the menu's OnSetupLayer).
  function C.record(layer, instance)
    local last = C.layers[layer]
    if last == nil or instance > last then
      C.layers[layer] = instance
    end
  end

  --- Internal: Hides every visible recorded layer instance (on) or shows back the ones it hid (off).
  function C.set(on)
    if on and C.hidden == nil then
      C.hidden = {}
      for layer, last in pairs(C.layers) do
        for instance = 0, last do
          if VRFW.host.menu_command(VRFW.commands.IS_LAYER_VISIBLE, layer, instance) == true then
            VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, layer, instance, false)
            C.hidden[#C.hidden + 1] = {layer, instance}
          end
        end
      end
    elseif not on and C.hidden ~= nil then
      for _, row in ipairs(C.hidden) do
        VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, row[1], row[2], true)
      end
      C.hidden = nil
    end
  end

  --- Advanced: Covers this menu on menu event `event` (payload: on) while `menu` (this menu's crc) exists.
  function C.listen(event, menu, owner)
    VRFW.menu_event.on(event, menu, owner, C.set)
  end
end
