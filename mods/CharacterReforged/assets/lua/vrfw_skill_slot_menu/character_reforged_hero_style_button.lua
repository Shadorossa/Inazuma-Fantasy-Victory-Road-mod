-- Idol button of the skill table: right of «Entrenar», shown for a card of several styles; A opens the style window.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.hero_style_button == nil and type(rawget(_ENV, "OnInit")) == "function" then
  local B = {
    LAYER = 1221220500,               -- cr_cmn03_07_btn_icon (content\menus\skill_table.toml: on _pos_btn_atc04)
    ICON_ROW = 12,                    -- soccer11_20_formation_team_passive instance drawn as its icon (on _pos_btn_ico04)
    TRAIN = 3123242707,               -- cr_cmn03_07_btn_train («Entrenar», left of the button)
    ICON_SPRITE = 423577364,          -- icon_abilear_title02 (#/menu/200_icon/15_icon_common/icon_common.g4tx)
    ICON_PRIORITY = 560,              -- as the icons of the other square buttons
    GUIDE = 1524405318,               -- character_reforged_hero_style_guide (text\rows\skill_table.toml)
    TEXT_CMD = 625330766,             -- _text_cmd01
    TEXT_KEY = 950238781,             -- _text_btn01
    CURSOR_LABEL = 3313461902,        -- cursor
    CMD_ATTACH_TRACE = 1774843228,    -- CMND_SET_LAYER_ATTACH_LOCATOR_TRACE (layer, idx, label, on)
    CMD_PLAY_ANIME = 3781155141,      -- CMND_PLAY_ANIME_TYPE (layer, idx, anime, type, group)
    ANIME_FOCUS = 2734777837,         -- Focus
    ANIME_GROUP = 973515837,          -- button
    CMD_ENABLE_COMMAND = 2559269762,  -- (layer, command, on)
    COMMAND_FCS_NEXT = 2734193315,    -- CMD_FCS_NEXT («Entrenar» -> this button)
    CMD_FOCUS_COUNT = 3252599449,     -- (layer, n): the focusable instances of the layer
    CMD_SET_CHARA_RARITY = 1641888398,
    CMD_IS_OPEN_MENU_OBJECT = 3693934564,
    CMD_IS_EXIST_MENU_OBJECT = 2231168902,
    CMD_CLOSE_MENU_OBJECT = 320421347,
    CMD_WINDOW_POSITION = 63483614,   -- (x, y) of the sub-window
    SUB_WINDOW = 968210065,           -- sub_window
    CURSOR = 2296367164,              -- cmn05_01_cursor
    RARITY_WINDOW = 27,               -- the game's avatar rarity window type
    WINDOW_SIZE = 5,                  -- its size code (the window widens it to every style)
    WINDOW_X = 500,                   -- its position (the game's avatar rarity window)
    WINDOW_Y = -318,
    REAPPLY_FRAMES = 10,              -- the layer open resets mesh visibility: the icon is drawn again after it
    shown_for = false,                -- the player the button was laid out for (false = lay out again)
    visible = false,
    covers = {},                      -- the screen modes that hide the bottom buttons
    frames = 0,
    picked = nil,
  }
  CharacterReforged.hero_style_button = B

  -- The skill table's locals (CharacterReforged.skill_table), nil outside the screen.
  local function screen()
    local host = CharacterReforged.skill_table
    return type(host) == "table" and host.L or nil
  end

  -- Whether the shown player's card is one of the styles.
  function B.wanted(L)
    local S = CharacterReforged.HeroStyle
    return S ~= nil and S.style_of(L.n) ~= nil
  end

  -- Returns the layer instance the idol button uses: 1 while the element cell takes instance 0, else 0.
  function B.slot()
    local E = CharacterReforged.element_cell
    return (type(E) == "table" and E.shown) and 1 or 0
  end

  -- Draws the star on the icon instance of the button's slot.
  function B.draw_icon(L)
    pcall(L.ButtonIcon, B.ICON_ROW + B.slot(), L.TEXTURE_ICON_COMMON, B.ICON_SPRITE)
  end

  -- Shows the button and its icon for a styled card while no mode covers the bottom buttons; Right of «Entrenar» follows.
  function B.apply(L)
    local show = B.wanted(L) and next(B.covers) == nil
    local slot = B.slot()
    B.visible = show
    funcLuaMenuCommand(L.C.LAYER_VISIBLE, B.LAYER, slot, show)
    funcLuaMenuCommand(L.C.LAYER_VISIBLE, L.L_PV_ROW, B.ICON_ROW + slot, show)
    if show then
      B.draw_icon(L)
    end
    local count = slot + (show and 1 or 0)
    if count > 0 then
      funcLuaMenuCommand(B.CMD_FOCUS_COUNT, B.LAYER, count)
    end
    funcLuaMenuCommand(B.CMD_ENABLE_COMMAND, B.TRAIN, B.COMMAND_FCS_NEXT, count > 0)
  end

  -- A screen mode hides (on) or gives back (off) the bottom buttons.
  function B.cover(key, on)
    B.covers[key] = on and true or nil
    local L = screen()
    if L ~= nil then
      B.apply(L)
    end
  end

  -- Wraps the covers of the training mode and the move list once per screen.
  function B.wrap_covers(L)
    local T = CharacterReforged.training_mode
    if type(T) == "table" and type(T.cover) == "function" and T.cover ~= B.training_cover then
      local cover = T.cover
      B.training_cover = function(on, ...)
        local results = table.pack(cover(on, ...))
        B.cover("training", on)
        return table.unpack(results, 1, results.n)
      end
      T.cover = B.training_cover
    end
    local PL = L.PL
    if type(PL) == "table" and type(PL.list_cover) == "function" and PL.list_cover ~= B.list_cover then
      local cover = PL.list_cover
      B.list_cover = function(show, ...)
        local results = table.pack(cover(show, ...))
        B.cover("list", show)
        return table.unpack(results, 1, results.n)
      end
      PL.list_cover = B.list_cover
    end
  end

  -- The window's pick: the chosen row is kept and the window closes.
  function CharacterReforged_HeroStyleClose(position)
    if type(position) == "number" and position >= 0 then
      B.picked = position
    end
    funcLuaCommand(B.CMD_CLOSE_MENU_OBJECT, B.SUB_WINDOW)
  end

  -- The window's focus: nothing to preview (the banner is the row itself).
  function CharacterReforged_HeroStyleFocus()
  end

  -- Runs in the screen's coroutine: the window, then the chosen style on the card.
  function B.run()
    local S, L = CharacterReforged.HeroStyle, screen()
    local handle = L ~= nil and L.n or nil
    local current = S ~= nil and S.style_of(handle) or nil
    if current == nil then
      return
    end
    local styles = S.styles()
    local enabled, checks = {}, {}
    for i = 1, #styles do
      enabled[i] = 1
      checks[i] = i == current and 1 or 0
    end
    B.picked = nil
    MENU_DEF.OpenSubWindow("CharacterReforged_HeroStyleClose", "CharacterReforged_HeroStyleFocus", #styles, {},
      B.WINDOW_SIZE, 0, enabled, current - 1, false, false, B.RARITY_WINDOW, 0, {}, -1, {}, {}, handle, checks)
    waitTrue(function()
      return funcLuaCommand(B.CMD_IS_OPEN_MENU_OBJECT, B.SUB_WINDOW, B.CURSOR)
    end)
    funcLuaCommand(B.CMD_WINDOW_POSITION, B.WINDOW_X, B.WINDOW_Y)
    waitTrue(function()
      return not funcLuaMenuCommand(B.CMD_IS_EXIST_MENU_OBJECT, B.SUB_WINDOW)
    end)
    funcLuaMenuCommand(L.C.LAYER_VISIBLE, B.CURSOR, 0, true)
    local picked = B.picked
    B.picked = nil
    local style = picked ~= nil and styles[picked + 1] or nil
    local before = S.rarity(handle)
    if style == nil or style == before then
      return
    end
    funcLuaCommand(B.CMD_SET_CHARA_RARITY, handle, style)
    S.log("style", before, "->", S.rarity(handle), "handle", handle)
    CharacterReforged.skill_table.sound("decide")
    CharacterReforged.skill_table.refresh()
  end

  local init = OnInit
  function OnInit(...)
    B.shown_for = false
    B.covers = {}
    local results = table.pack(init(...))
    local L = screen()
    if L ~= nil then
      B.wrap_covers(L)
    end
    return table.unpack(results, 1, results.n)
  end

  local setup_layer = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == B.LAYER then
      funcLuaMenuCommand(L.C.TEXT, a1, B.TEXT_CMD, "", a2)
      funcLuaMenuCommand(L.C.TEXT, a1, B.TEXT_KEY, "", a2)
      funcLuaMenuCommand(B.CMD_ATTACH_TRACE, a1, a2, B.CURSOR_LABEL, false)
      funcLuaMenuCommand(L.C.LAYER_VISIBLE, a1, a2, false)
      B.shown_for = false
      return
    elseif L ~= nil and a1 == L.L_PV_ROW and a2 == B.ICON_ROW + B.slot() then
      funcLuaMenuCommand(L.Priority, a1, a2, B.ICON_PRIORITY, true)
      B.draw_icon(L)
      funcLuaMenuCommand(L.C.LAYER_VISIBLE, a1, a2, false)
      B.shown_for = false
      return
    end
    return setup_layer(a1, a2, ...)
  end

  local open_layer = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == B.LAYER then
      funcLuaMenuCommand(B.CMD_PLAY_ANIME, a1, a2, B.ANIME_FOCUS, 2, B.ANIME_GROUP)
      B.frames = B.REAPPLY_FRAMES
      return
    elseif L ~= nil and a1 == L.L_PV_ROW and a2 == B.ICON_ROW + B.slot() then
      B.frames = B.REAPPLY_FRAMES
      return
    end
    return open_layer(a1, a2, ...)
  end

  local change_focus = OnChangeFocus
  function OnChangeFocus(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == B.LAYER and a2 == B.slot() then
      L.n14 = L.L_BTN                 -- the rows' arrow cursor leaves the rows, as for the other square buttons
      pcall(UpdateEquipItemInfo)
      pcall(L.PL.guide, L.PL.txt(B.GUIDE))
      return
    end
    return change_focus(a1, a2, ...)
  end

  local decide_focus = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == B.LAYER and a2 == B.slot() then
      if L.vrfw_co == nil and B.visible then
        L.vrfw_co = coroutine.create(B.run)
      end
      return
    end
    return decide_focus(a1, a2, ...)
  end

  local step = Step
  function Step(...)
    local results = table.pack(step(...))
    local L = screen()
    if L ~= nil and L.n ~= nil then
      if B.frames > 0 then
        B.frames = B.frames - 1
        if B.frames == 0 then
          B.draw_icon(L)
          B.shown_for = false
        end
      end
      if B.shown_for ~= L.n then        -- laid out once per shown player
        B.shown_for = L.n
        B.apply(L)
      end
    end
    return table.unpack(results, 1, results.n)
  end
end
