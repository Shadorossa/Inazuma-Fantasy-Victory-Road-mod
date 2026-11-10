BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.passive_session = type(BetterQoL.passive_session) == "table" and BetterQoL.passive_session or {}
do
  local S = BetterQoL.passive_session
  S.KEY_REQUEST = 2803176173 --[[betterqol_pc_edit_req: the player handle the plate takes]]
  S.KEY_PARENT = 61168796 --[[betterqol_pc_edit_parent: the menu that owns the button guide]]
  S.KEY_DONE = 2222551686 --[[betterqol_pc_edit_done: the plate ended the session]]
  S.FRAMES_TO_TAKE = 90
  S.SOUND_REFUSED = 2086672038 --[[sy0003]]
  S.MAX_INSTANCES = 128
  S.CMD_LAYER_COUNT = 1175615627 --[[the created instance count of a layer]]
  S.CMD_LAYER_VISIBLE = 1262717583 --[[CMND_IS_LAYER_VISIBLE]]
  S.CMD_SET_LAYER_VISIBLE = 711242136 --[[CMND_SET_LAYER_VISIBLE]]
  S.CMD_SUSPEND_MENU = 369172623
  S.CMD_RESUME_MENU = 66378409   -- (menu, 1): undoes CMD_SUSPEND_MENU
  S.CMD_LOG = 519897777 --[[CMND_VRFW_LOG]]
  S.layers = S.layers or {}          -- layer crcs of this menu in setup order
  S.instances = S.instances or {}    -- layer crc -> highest noted instance + 1

  -- from the calling menu's OnSetupLayer(layer, instance)
  function S.note_layer(layer, instance)
    if type(layer) ~= "number" then
      return
    end
    local count = (type(instance) == "number" and instance >= 0) and instance + 1 or 1
    local known = S.instances[layer]
    if known == nil then
      S.layers[#S.layers + 1] = layer
      S.instances[layer] = count
    elseif count > known then
      S.instances[layer] = count
    end
  end

  function S.hide_menu_layers(hidden)
    for i = 1, #S.layers do
      local layer = S.layers[i]
      local count = S.instances[layer] or 1
      local created = VRFW.host.menu_command(S.CMD_LAYER_COUNT, layer)
      if type(created) == "number" and created > count then
        count = created
      end
      for instance = 0, math.min(count, S.MAX_INSTANCES) - 1 do
        local visible = VRFW.host.menu_command(S.CMD_LAYER_VISIBLE, layer, instance)
        if visible == true then
          VRFW.host.menu_command(S.CMD_SET_LAYER_VISIBLE, layer, instance, false)
          hidden[layer * 4096 + instance] = {layer, instance}
        end
      end
    end
    return hidden
  end

  function S.show_menu_layers(hidden)
    for _, entry in pairs(hidden or {}) do
      VRFW.host.menu_command(S.CMD_SET_LAYER_VISIBLE, entry[1], entry[2], true)
    end
  end

  function S.log(...)
    VRFW.host.command(S.CMD_LOG, "BetterQoL passive session", ...)
  end

  function S.count_hidden(hidden)
    local n = 0
    for _ in pairs(hidden) do
      n = n + 1
    end
    return n
  end

  function S.run(h, parent, rules)
    rules = rules or {}
    local menu = type(rules.hide_menu) == "number" and rules.hide_menu or nil
    local hidden = {}
    if menu ~= nil then
      VRFW.host.menu_command(S.CMD_SUSPEND_MENU, menu, 1)
      S.log("open: menu hidden", menu)
    else
      S.hide_menu_layers(hidden)
      S.log("open: layer instances hidden", S.count_hidden(hidden))
    end
    VRFW.param.clear(S.KEY_DONE)
    VRFW.param.clear(S.KEY_PARENT)
    VRFW.param.set(S.KEY_PARENT, parent or 0)
    VRFW.param.clear(S.KEY_REQUEST)
    VRFW.param.set(S.KEY_REQUEST, h)
    local taken = true
    local wait = 0
    while true do
      coroutine.yield()
      if menu == nil and rules.keep_hidden == true then
        S.hide_menu_layers(hidden)
      end
      if VRFW.param.has(S.KEY_DONE) then
        VRFW.param.clear(S.KEY_DONE)
        break
      end
      if VRFW.param.has(S.KEY_REQUEST) then
        wait = wait + 1
        if wait > S.FRAMES_TO_TAKE then
          VRFW.param.clear(S.KEY_REQUEST)
          VRFW.param.clear(S.KEY_PARENT)
          VRFW.host.command(1917805374 --[[play sound]], S.SOUND_REFUSED)
          taken = false
          break
        end
      end
    end
    coroutine.yield()
    if menu ~= nil then
      VRFW.host.menu_command(S.CMD_RESUME_MENU, menu, 1)
      S.log("close: menu shown", menu, "taken", tostring(taken))
    else
      S.log("close: layer instances shown", S.count_hidden(hidden), "taken", tostring(taken))
      S.show_menu_layers(hidden)
    end
    return taken
  end
end
