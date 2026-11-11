-- Disabled rows (docs/framework/equip-list-disabled-rows.md): the equipment picker lists the items a mod declares
-- although the player fails their equip test, draws them grey and refuses to equip them.
if VRFW.host ~= nil then
  local STEM = "equip_menu_list"
  local CMD = {
    OPEN = VRFW.commands.VRFW_EQUIP_LIST_OPEN,     -- CMND_VRFW_EQUIP_LIST_OPEN(menu name) -> kept item kinds
    CLOSE = VRFW.commands.VRFW_EQUIP_LIST_CLOSE,   -- CMND_VRFW_EQUIP_LIST_CLOSE() -> true
    ROW = VRFW.commands.VRFW_EQUIP_LIST_ROW,       -- CMND_VRFW_EQUIP_LIST_ROW(character, inventory) -> disabled, reason
    PLAY_SE = VRFW.commands.SND_PLAY_SE,
    TEXT_SHADE = 2484004035,                       -- (layer, instance, text node, shade): the shop list's grey-out of a text
  }
  local SE_CANNOT = 2086672038                     -- sy0003
  local TAB_LAYER = 4044286600                     -- cmn06_20_list_tab_item
  local EQUIP = 4067673008                         -- OnFunction "equip"
  local NAME_NODES = { 931545948, 3705682548 }     -- _text_list01_on, _text_list01_off
  local SHADE = 0.5                                -- the game's shade of a row that cannot be chosen
  local NO_ROW = 2                                 -- CheckEnableEquip: nothing to equip (refusal sound, no window)

  local DR = {
    on = false,       -- This menu has declared item kinds.
    character = 0,    -- This is the player whose equipment is shown.
    focused = 0,      -- This is the inventory handle of the focused row.
    reasons = {},     -- [inventory handle] = the reason's menu_text row, or false for a row the player may equip
    shaded = {},      -- [row instance] = true while its name is drawn grey
  }
  VRFW.equip_list_disabled_rows = DR

  local Log = VRFW.logger.new("vrfw.EquipListDisabledRows")

  --- The reason (a menu_text row id) the player may not equip inventory row `inv`, or nil; asked once per row.
  function DR.reason(inv)
    if not DR.on or type(inv) ~= "number" or inv == 0 or DR.character == 0 then return nil end
    local known = DR.reasons[inv]
    if known == nil then
      local disabled, reason = VRFW.host.command(CMD.ROW, DR.character, inv)
      known = disabled == true and type(reason) == "string" and reason or false
      DR.reasons[inv] = known
    end
    return known or nil
  end

  --- Draws the name of row `instance` grey or as the game draws it.
  function DR.shade(layer, instance, on)
    for _, node in ipairs(NAME_NODES) do
      VRFW.host.menu_command(CMD.TEXT_SHADE, layer, instance, node, on and SHADE or 0)
    end
    DR.shaded[instance] = on or nil
  end

  local function wrap(name, make)
    VRFW.host.wrap(name, make, { stem = STEM, id = "VRFW.equip_list_disabled_rows_" .. name })
  end

  wrap("OnInit", function(game_init)
    return function(...)
      DR.character, DR.focused, DR.reasons, DR.shaded = 0, 0, {}, {}
      local kinds = VRFW.host.command(CMD.OPEN, STEM)
      DR.on = type(kinds) == "number" and kinds > 0
      return game_init(...)
    end
  end)

  wrap("FinalizeMenu", function(game_finalize)
    return function(...)
      if DR.on then
        DR.on = false
        VRFW.host.command(CMD.CLOSE)
      end
      return game_finalize(...)
    end
  end)

  wrap("SetStartMenu", function(game_start)
    return function(character, ...)
      DR.character = type(character) == "number" and character or 0
      DR.focused, DR.reasons = 0, {}
      return game_start(character, ...)
    end
  end)

  wrap("UpdateItemEquipMenu", function(game_focus)
    return function(inv, ...)
      DR.focused = type(inv) == "number" and inv or 0
      return game_focus(inv, ...)
    end
  end)

  -- A tab change leaves no focused row, as the game's own state.
  wrap("OnChangeFocus", function(game_change)
    return function(layer, ...)
      if layer == TAB_LAYER then DR.focused = 0 end
      return game_change(layer, ...)
    end
  end)

  wrap("UpdateItemEquipLine", function(game_line)
    return function(layer, instance, inv, ...)
      local results = table.pack(game_line(layer, instance, inv, ...))
      local disabled = DR.reason(inv) ~= nil
      if disabled or DR.shaded[instance] then DR.shade(layer, instance, disabled) end
      return table.unpack(results, 1, results.n)
    end
  end)

  wrap("CheckEnableEquip", function(game_check)
    return function(...)
      if DR.reason(DR.focused) ~= nil then return NO_ROW end
      return game_check(...)
    end
  end)

  wrap("OnFunction", function(game_function)
    return function(key, ...)
      local reason = key == EQUIP and DR.reason(DR.focused) or nil
      if reason == nil then return game_function(key, ...) end
      VRFW.host.command(CMD.PLAY_SE, SE_CANNOT)
      Log("refused", string.format("%08X", DR.character), string.format("%08X", DR.focused), reason)
      OpenGeneralWindow(VRFW.crc32(reason), true)
    end
  end)
end
