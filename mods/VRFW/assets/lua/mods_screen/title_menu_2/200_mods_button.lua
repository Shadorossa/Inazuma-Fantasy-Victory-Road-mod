

local MM = {
  STATE = VRFW.commands.VRFW_MM_STATE,
                                          -- menu (crc32 of the menu the screen is opened as), where the button is, the tile's sprite names
  TEXT = VRFW.commands.VRFW_MM_TEXT,     -- (name, language code) -> text of the mod's text.toml
  LANG = VRFW.commands.GET_LANGUAGE_CODE,                       -- CMND_GET_LANGUAGE_CODE
  SCREEN = false,
  BUZZER = 2086672038,                    -- sy0003
  MENU = VRFW.ids.crc32("vrfw_mods_menu"),        -- until the plugin says otherwise (MM_Mode)
  TITLE = 3874253475,                     -- title_menu_2
  CURSOR = 24113234,                      -- cmn05_01_coursor
  L_LOWER = 3873872512,                   -- title00_07_item_button_lower
  POS = 3,
  NAME = 11,                              -- its label's name instance (6th value; 11 = retail)
  ABOVE = 6,                              -- the upper button "up" goes to (7th value)
  DOWN = {[6] = true, [7] = true},        -- upper buttons whose "down" comes here (8th value "6,7")
  IDX = 40,                               -- its item list index (retail uses 1..11, mods up to ~14)
  ID = VRFW.ids.crc32("vrfw_title_menu_mods_item"),
  SPRITES = {},
  GAIJI_1P = 3337686268,                  -- "1 player" mark after the label, like Opciones
  EXPLAIN = 499981750,                    -- _text_explain01 of the flavour balloon
}

local mm_mode = nil         -- nil = not asked yet; 0 off; 1 own button
local mm_co = nil           -- the coroutine that opens the screen and waits

local MM_Call = VRFW.host.command

local function MM_Mode()
  if mm_mode == nil then
    local title, screen, _, menu, pos, name, above, down, tile = MM_Call(MM.STATE)
    if type(tile) == "string" then
      local k = 0
      for n in string.gmatch(tile .. ",", "([^,]*),") do
        k = k + 1
        MM.SPRITES[k] = n ~= "" and VRFW.ids.crc32(n) or nil
      end
    end
    if type(pos) == "number" and type(name) == "number" and name > 0 then
      MM.POS, MM.NAME = pos, name
      if type(above) == "number" then
        MM.ABOVE = above
      end
      if type(down) == "string" then
        MM.DOWN = {}
        for d in string.gmatch(down, "%d+") do
          MM.DOWN[tonumber(d)] = true
        end
      end
    end
    if type(menu) == "number" and menu ~= 0 then
      MM.MENU = menu
    end
    MM.SCREEN = screen == true
    mm_mode = title == 1 and 1 or 0
  end
  return mm_mode
end

local function MM_Own()
  return MM_Mode() == 1 and type(GetItemButtonNum) == "function" and GetItemButtonNum(false) > MM.POS
end

local function MM_IsOurs(idx, upper)
  return upper ~= true and idx == MM.POS and MM_Own()
end

local function MM_Text(name)
  local s = MM_Call(MM.TEXT, name, MM_Call(MM.LANG) or 1)
  if type(s) ~= "string" or s == "" then
    return name == "title_button" and "Mods" or ""
  end
  return s
end

local function MM_Coroutine()
  MM_Mode()                                                     -- MM.MENU from the plugin
  funcLuaMenuCommand(1558704558, MM.TITLE, false)               -- title input off
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, MM.CURSOR, 0, false)            -- CMND_SET_LAYER_VISIBLE: cursor
  coroutine.yield()
  funcLuaCommand(VRFW.commands.OPEN_MENU_OBJECT, MM.MENU)                            -- CMND_OPEN_MENU_OBJECT
  funcLuaCommand(2039986631, false)
  coroutine.yield()
  while funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, MM.MENU) do              -- CMND_IS_EXIST_MENU_OBJECT
    coroutine.yield()
  end
  funcLuaCommand(2039986631, true)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, MM.CURSOR, 0, true)
  funcLuaMenuCommand(1558704558, MM.TITLE, true)
  mm_co = nil
end

function VRFW.mods_menu_open_screen()
  if mm_co ~= nil then
    return 1
  end
  MM_Mode()
  if not MM.SCREEN then
    funcLuaCommand(VRFW.commands.SND_PLAY_SE, MM.BUZZER)
    return 1
  end
  funcLuaCommand(VRFW.commands.SND_PLAY_SE, 766561556)                         -- sy0080
  mm_co = coroutine.create(MM_Coroutine)
end

local function MM_Busy()
  return mm_co ~= nil
end

-- Every handler has the id "mods_menu.title_button" (other mods order against it: after = "mods_menu.title_button").
local T, ID = "title_menu_2", "mods_menu.title_button"

local function on(point, phase, fn)
  if type(_ENV[point]) == "function" then
    VRFW.host.on(T, point, { id = ID, phase = phase, fn = fn })
  end
end

if VRFW.host ~= nil and type(GetItemListIdx) == "function" and type(OnEnter) == "function" and type(Step) == "function" then
  on("GetItemListIdx", "around", function(nxt, a1, a2)
    if MM_IsOurs(a1, a2) then
      return MM.IDX
    end
    return nxt(a1, a2)
  end)

  on("IsEnableMenuItemButton", "around", function(nxt, a1, a2)
    if MM_IsOurs(a1, a2) then
      return MM.SCREEN
    end
    return nxt(a1, a2)
  end)

  on("GetTextureNameItemButton", "around", function(nxt, a1, a2, a3)
    if MM_IsOurs(a1, a3) then
      return MM.SPRITES[a2] or 0
    end
    return nxt(a1, a2, a3)
  end)

  -- a1 = name instance (upper 0..n-1, then the lower ones), a2 = upper
  on("GetTextItemName", "around", function(nxt, a1, a2)
    if a2 ~= true and MM_Own() and a1 == MM.NAME then
      local s = MM_Text("title_button")
      local g = funcLuaCommand(VRFW.commands.TEXT_GET, MM.GAIJI_1P)          -- CMND_TEXT_GET
      if type(g) == "string" and g ~= "" then
        s = s .. "  " .. g
      end
      return s
    end
    return nxt(a1, a2)
  end)

  on("GetTextNameItemName", "around", function(nxt, a1, a2)
    if MM_IsOurs(a1, a2) then
      return 0
    end
    return nxt(a1, a2)
  end)

  on("GetPlayableModeGaiji", "around", function(nxt, a1, a2)
    if MM_IsOurs(a1, a2) then
      return MM.GAIJI_1P
    end
    return nxt(a1, a2)
  end)

  on("GetTitleMenuItemId", "around", function(nxt, a1, a2)
    if MM_IsOurs(a1, a2) then
      return MM.ID
    end
    return nxt(a1, a2)
  end)

  -- no slide animation for "Mods" (the last lower button: nothing right of it to slide)
  on("GetOffsetAnimeItemAttachLocator", "around", function(nxt, a1, a2)
    if MM_IsOurs(a1, a2) then
      return 0
    end
    return nxt(a1, a2)
  end)

  on("GetLayerNameFromItemListIdx", "around", function(nxt, a1)
    if a1 == MM.IDX and MM_Own() then
      return MM.L_LOWER
    end
    return nxt(a1)
  end)

  on("GetLayerIndexFromItemListIdx", "around", function(nxt, a1)
    if a1 == MM.IDX and MM_Own() then
      return MM.POS
    end
    return nxt(a1)
  end)

  on("GetItemButtonNextFocusIdx", "around", function(nxt, a1, a2)
    if MM_Own() then
      if a2 == true and a1 == MM.POS then
        local nu = GetItemButtonNum(true)
        return math.max(0, math.min(MM.ABOVE, nu - 1))
      elseif a2 ~= true and MM.DOWN[a1] then
        return MM.POS
      end
    end
    return nxt(a1, a2)
  end)

  on("SetFlavorBalloonText", "around", function(nxt)
    if MM_Own() and GetSelectItemLayerName and GetSelectItemLayerName() == MM.L_LOWER and GetSelectItemIdx() == MM.POS then
      local s = MM_Text(MM.SCREEN and "title_flavor" or "title_flavor_unavailable")
      if s ~= "" and GetCurrentVisibleFlavorLayer then
        funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, GetCurrentVisibleFlavorLayer(), MM.EXPLAIN, s, 0)
      end
      return
    end
    return nxt()
  end)

  on("OnEnter", "around", function(nxt, a1, a2)
    if MM_Busy() then
      return 1
    end
    if a1 == MM.L_LOWER and MM_IsOurs(a2, false) then
      return VRFW.mods_menu_open_screen()
    end
    return nxt(a1, a2)
  end)

  on("OnBack", "around", function(nxt, a1)
    if MM_Busy() then
      return 1
    end
    return nxt(a1)
  end)

  on("OnFunction", "around", function(nxt, a1, a2)
    if MM_Busy() then
      return
    end
    return nxt(a1, a2)
  end)

  -- after the title's own Step: one step of the screen's coroutine
  on("Step", "after", function()
    if mm_co ~= nil then
      local ok, err = coroutine.resume(mm_co)
      if not ok then
        VRFW.logger.new("mods_menu")("title coroutine", tostring(err))
        mm_co = nil
        funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, MM.CURSOR, 0, true)
        funcLuaMenuCommand(1558704558, MM.TITLE, true)
      end
    end
  end)
end

