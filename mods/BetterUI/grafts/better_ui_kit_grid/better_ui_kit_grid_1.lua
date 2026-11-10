-- EVT better_ui_kit_grid BEGIN
do
  BetterUI = BetterUI or {}
  BetterUI.kit_grid = BetterUI.kit_grid or {}
  local Screen = BetterUI.kit_grid
  Screen.picker = nil
  Screen.dock = 0
  Screen.named = 0

  Screen.DOCK_KEY = 3357163798
  -- the name plate under the four models: the retail kit detail card (hidden by the retail screen) with its text only
  Screen.NAME_PLATE = @crc:team07_03_uniform_info@
  Screen.NAME_TEXT = @crc:_text_detail01@
  Screen.NAME_ICONS = { @crc:_icon_uniform_dmy01@, @crc:_icon_uniform_dmy02@ }
  Screen.C = { EXISTS = 2947612279, GET = 3522198769, LAYER_VISIBLE = 711242136, MESH_VISIBLE = 3405944500,
    ITEM_ID = 2662166687, ITEM_NAME = 1883585771, ITEM_UNIFORM = 845816129, SET_TEXT = 1083631230,
    ITEM_ICON = 3508889864, LIST_BUILT = 2787787510 }

  -- The rules of the shared picker grid (VRFW.equip_grid): this screen's layers, art and what a tile shows.
  Screen.RULES = {
    log_tag = "BETTERUI_KG",
    item_word = "kits",
    stem = "equip_uniform_menu_list",
    menu = @crc:equip_uniform_menu@,
    list = @crc:team06_01_uniform_list@,
    item = @crc:team07_02_uniform_list_item@,
    tabs_command = @crc:CMND_BETTERUI_KIT_TABS@,
    -- the pickers' atlas: the grey hex and the fade bands (BetterUI content/images/menu/102_team/betterui_emblem_art.toml)
    art = 1142043709 --[[#/menu/102_team/betterui_emblem_art/betterui_emblem_art.g4tx]],
    fade_top = @crc:betterui_emblem_fade_top@,
    fade_bottom = @crc:betterui_emblem_fade_bottom@,
    -- the colour preset of the grid object (content/menus/equip_uniform_menu.toml)
    fade_colour = @crc:betterui_emblem_fade@,
    plate_other = @crc:betterui_emblem_hex_grey@,
    -- The retail help line («Cambia la equipación.») is not part of this screen: the grid runs under the footer prompts.
    hidden_layers = { @crc:mainmenu90_05_content_guide_line01@ },
    -- A tile's kit icon is drawn again only when its kit changes, as the retail row does.
    keep_icons = true,
    -- The four models load when the cursor has stayed this many frames on a kit: a moving cursor loads none on its way.
    preview_rest_frames = 10,
  }

  --- The retail screen takes a kit's models once its list is built (its own Step reads the same answer).
  function Screen.RULES.is_ready()
    return funcLuaMenuCommand(Screen.C.LIST_BUILT, Screen.RULES.list, 0) == true
  end

  function Screen.RULES.draw_icon(layer, instance, kit_item)
    local tiles = VRFW.emblem_grid
    funcLuaMenuCommand(Screen.C.ITEM_ICON, layer, instance, tiles.ICON_MESH, tiles.ICON_TEX, kit_item)
  end

  function Screen.RULES.is_worn(kit_item)
    local _, uniform = funcLuaCommand(Screen.C.ITEM_UNIFORM, kit_item)
    return CheckTeamDockUniformEquip(Screen.dock, uniform)
  end

  --- The name plate shows the name of the kit of `handle`; an empty list has no plate.
  function Screen.show_name(handle)
    Screen.named = handle
    local kit_item = handle ~= 0 and funcLuaCommand(Screen.C.ITEM_ID, handle, 0) or nil
    local name = kit_item and funcLuaCommand(Screen.C.ITEM_NAME, kit_item, 0) or nil
    funcLuaMenuCommand(Screen.C.LAYER_VISIBLE, Screen.NAME_PLATE, 0, name ~= nil)
    if name ~= nil then
      funcLuaMenuCommand(Screen.C.SET_TEXT, Screen.NAME_PLATE, Screen.NAME_TEXT, name, 0)
    end
  end

  -- Every wrapper runs the retail function (and the other mods' wrappers under it) and hands the call to the picker.
  local OWNER = "BetterUI.kit_grid"

  VRFW.host.wrap_once("OnInit", OWNER, function(retail, ...)
    if funcLuaCommand(Screen.C.EXISTS, Screen.DOCK_KEY) then
      Screen.dock = funcLuaCommand(Screen.C.GET, Screen.DOCK_KEY)
    end
    Screen.named, Screen.load_models = 0, nil
    retail(...)
    Screen.picker = VRFW.equip_grid.new(Screen.RULES)
  end)

  VRFW.host.wrap_once("OnSetupLayer", OWNER, function(retail, layer, instance)
    retail(layer, instance)
    if Screen.picker ~= nil then
      Screen.picker:setup_layer(layer, instance)
    end
  end)

  VRFW.host.wrap_once("OnOpenLayer", OWNER, function(retail, layer, instance)
    retail(layer, instance)
    if Screen.picker == nil then
      return
    end
    Screen.picker:open_layer(layer, instance)
    if layer == Screen.NAME_PLATE then
      for _, icon in ipairs(Screen.NAME_ICONS) do
        funcLuaMenuCommand(Screen.C.MESH_VISIBLE, layer, icon, false, instance)
      end
      -- The retail screen hides the card when it opens: the focused kit's name is shown again.
      Screen.show_name(Screen.named)
    end
  end)

  -- The tab narrows the player's own filter on its way to the engine; the stored filter is never changed.
  VRFW.host.wrap_once("SetEquipListFilter", OWNER, function(retail, params, ...)
    if Screen.picker ~= nil then
      params = Screen.picker:filter(params)
    end
    return retail(params, ...)
  end)

  -- LB / RB move the tab layer's focus (the engine wraps it and plays the retail move sound); the list follows the tab.
  VRFW.host.wrap_once("OnChangeFocus", OWNER, function(retail, layer, instance)
    retail(layer, instance)
    if Screen.picker ~= nil then
      Screen.picker:change_focus(layer, instance)
    end
  end)

  -- The retail function loads the four models of the focused kit: the name follows the cursor at once, the models
  -- load through the picker, when the cursor rests.
  VRFW.host.wrap_once("UpdateItemEquipMenu", OWNER, function(retail, handle)
    if Screen.picker == nil then
      return retail(handle)
    end
    Screen.load_models = retail
    -- The engine calls this on every frame with the focused kit: the plate is written only when the kit changes.
    if handle ~= Screen.named then
      Screen.show_name(handle)
    end
    Screen.picker:preview(handle, retail, "UpdateItemEquipMenu")
  end)

  VRFW.host.wrap_once("Step", OWNER, function(retail, ...)
    retail(...)
    if Screen.picker ~= nil then
      Screen.picker:step(Screen.load_models)
    end
  end)

  -- Accept and the function keys act on the kit the retail screen loaded last: a waiting kit is loaded first.
  -- A decide on a tab only chooses the tab: the retail function, which equips the focused kit, is not run for it.
  VRFW.host.wrap_once("OnEnter", OWNER, function(retail, layer, instance, ...)
    if Screen.picker == nil then
      return retail(layer, instance, ...)
    end
    if not Screen.picker:accepts(layer, instance) then
      return
    end
    return Screen.picker:act(Screen.load_models, "OnEnter", retail, layer, instance, ...)
  end)

  VRFW.host.wrap_once("OnFunction", OWNER, function(retail, ...)
    if Screen.picker == nil then
      return retail(...)
    end
    return Screen.picker:act(Screen.load_models, "OnFunction", retail, ...)
  end)

  VRFW.host.wrap_once("UpdateItemEquipLine", OWNER, function(retail, layer, instance, handle, a4, focused, ...)
    if Screen.picker == nil then
      return retail(layer, instance, handle, a4, focused, ...)
    end
    Screen.picker:update_line(layer, instance, handle, focused)
  end)
end
-- EVT better_ui_kit_grid END
