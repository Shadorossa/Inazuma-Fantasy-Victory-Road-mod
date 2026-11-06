-- BetterQoL: the one way another menu opens the passive configurator's session on the player page
-- (personal_plate_menu, graft passive_config, util_pc_plate.lua). Used by the team dock's «Configuración de pasivas»
-- row (util_pc_dock.lua) and the bank's command list (graft util_bank_commands).
-- * The calling menu notes its own layers from its OnSetupLayer (NoteLayer).
-- * Run hides every visible instance of those layers (the configurator's list window draws on the left half and a
--   menu's own layers can draw over it), hands the player over through the parameter store, waits in the caller's
--   coroutine until the plate says the session ended and shows again exactly the instances it hid.
-- * rules.hide_menu = a menu crc: that whole menu is hidden instead (the retail suspend / resume of a menu's layer
--   group, as the bank does under its skill table and equipment screens). For a menu whose grid is a list view: the
--   list re-shows its own rows, so hiding them one by one does not hold.
-- * Input: the caller turns its own menu's input off before Run and back on after it.
-- Defines functions and tables; no engine call at chunk load.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.PassiveSession = type(BetterQoL.PassiveSession) == "table" and BetterQoL.PassiveSession or {}
do
  local S = BetterQoL.PassiveSession
  S.KEY_REQUEST = 1800965173 --[[util_pc_edit_req: the player handle the plate takes]]
  S.KEY_PARENT = 1737532001 --[[util_pc_edit_parent: the menu that owns the button guide]]
  S.KEY_DONE = 213739006 --[[util_pc_edit_done: the plate ended the session]]
  S.FRAMES_TO_TAKE = 90 -- frames the plate has to take the request (no plate patch: give up)
  S.SOUND_REFUSED = 2086672038 --[[sy0003]]
  S.MAX_INSTANCES = 128
  S.CMD_LAYER_COUNT = 1175615627 --[[the created instance count of a layer]]
  S.CMD_LAYER_VISIBLE = 1262717583 --[[CMND_IS_LAYER_VISIBLE]]
  S.CMD_SET_LAYER_VISIBLE = 711242136 --[[CMND_SET_LAYER_VISIBLE]]
  S.CMD_SUSPEND_MENU = 369172623 -- (menu, 1): the menu's layers stop drawing; its coroutines go on
  S.CMD_RESUME_MENU = 66378409   -- (menu, 1): undoes CMD_SUSPEND_MENU
  S.CMD_LOG = 3661580131 --[[CMND_EVT_LOG]]
  S.layers = S.layers or {}          -- layer crcs of this menu in setup order
  S.instances = S.instances or {}    -- layer crc -> highest noted instance + 1

  -- from the calling menu's OnSetupLayer(layer, instance)
  function S.NoteLayer(layer, instance)
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

  -- hide every visible instance of the noted layers; hidden = {key -> {layer, instance}} collects them
  function S.HideMenuLayers(hidden)
    for i = 1, #S.layers do
      local layer = S.layers[i]
      local count = S.instances[layer] or 1
      local ok, created = pcall(funcLuaMenuCommand, S.CMD_LAYER_COUNT, layer)
      if ok and type(created) == "number" and created > count then
        count = created
      end
      for instance = 0, math.min(count, S.MAX_INSTANCES) - 1 do
        local okVisible, visible = pcall(funcLuaMenuCommand, S.CMD_LAYER_VISIBLE, layer, instance)
        if okVisible and visible == true then
          pcall(funcLuaMenuCommand, S.CMD_SET_LAYER_VISIBLE, layer, instance, false)
          hidden[layer * 4096 + instance] = {layer, instance}
        end
      end
    end
    return hidden
  end

  function S.ShowMenuLayers(hidden)
    for _, entry in pairs(hidden or {}) do
      pcall(funcLuaMenuCommand, S.CMD_SET_LAYER_VISIBLE, entry[1], entry[2], true)
    end
  end

  function S.Log(...)
    pcall(funcLuaCommand, S.CMD_LOG, "BetterQoL passive session", ...)
  end

  function S.CountHidden(hidden)
    local n = 0
    for _ in pairs(hidden) do
      n = n + 1
    end
    return n
  end

  -- run a session for player handle h from the caller's coroutine; parent = the button guide's owner menu;
  -- rules.keep_hidden = hide again each waited frame (a menu whose own Step shows its layers again);
  -- rules.hide_menu = hide that whole menu instead of its layers one by one.
  -- Returns true when the plate took the session (it has ended), false when nobody took it.
  function S.Run(h, parent, rules)
    rules = rules or {}
    local menu = type(rules.hide_menu) == "number" and rules.hide_menu or nil
    local hidden = {}
    if menu ~= nil then
      pcall(funcLuaMenuCommand, S.CMD_SUSPEND_MENU, menu, 1)
      S.Log("open: menu hidden", menu)
    else
      S.HideMenuLayers(hidden)
      S.Log("open: layer instances hidden", S.CountHidden(hidden))
    end
    VRFW_Param.Clear(S.KEY_DONE)
    VRFW_Param.Clear(S.KEY_PARENT)
    VRFW_Param.Set(S.KEY_PARENT, parent or 0)
    VRFW_Param.Clear(S.KEY_REQUEST)
    VRFW_Param.Set(S.KEY_REQUEST, h)
    local taken = true
    local wait = 0
    while true do
      coroutine.yield()
      if menu == nil and rules.keep_hidden == true then
        S.HideMenuLayers(hidden)
      end
      if VRFW_Param.Has(S.KEY_DONE) then
        VRFW_Param.Clear(S.KEY_DONE)
        break
      end
      if VRFW_Param.Has(S.KEY_REQUEST) then
        wait = wait + 1
        if wait > S.FRAMES_TO_TAKE then
          VRFW_Param.Clear(S.KEY_REQUEST)
          VRFW_Param.Clear(S.KEY_PARENT)
          pcall(funcLuaCommand, 1917805374 --[[play sound]], S.SOUND_REFUSED)
          taken = false
          break
        end
      end
    end
    coroutine.yield()
    if menu ~= nil then
      pcall(funcLuaMenuCommand, S.CMD_RESUME_MENU, menu, 1)
      S.Log("close: menu shown", menu, "taken", tostring(taken))
    else
      S.Log("close: layer instances shown", S.CountHidden(hidden), "taken", tostring(taken))
      S.ShowMenuLayers(hidden)
    end
    return taken
  end
end
