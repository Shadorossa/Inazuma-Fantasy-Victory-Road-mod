-- lua_patch.scope: used
-- menu_engine: the EQUIP PICKER GRID (VRFW UI piece `VRFW.equip_grid`): a retail equip list drawn as a honeycomb of tiles under a series tab bar.
-- Defines functions only: no engine call at load time.
if VRFW.equip_grid == nil then
  local Grid = {
    C = {
      ITEM_ID = 2662166687,          -- (inventory handle, 0) -> item id
      MESH_VISIBLE = 3405944500, LAYER_VISIBLE = 711242136, TEXT_VISIBLE = 2735666188,
      LIST_COUNT = 2389020234,       -- (list layer) -> rows in the list
      SPRITE = 558735651,            -- (layer, atlas, sprite, texture slot, 0, instance)
      FOCUS_NUM = 3252599449,        -- (layer, focus slots)
      FOCUSED = 2603265800,          -- (layer) -> focused instance
      MATERIAL_COLOUR = 801406373,   -- (layer, instance, colour preset, r, g, b)
      THEME_COLOUR = 1215391656,     -- CMND_VRFW_THEME_COLOR (name) -> r, g, b
    },
    -- the retail tab bar every equip list has: its bar, its tabs and the tab name under the bar
    TAB_BAR = 1887158505,            -- cmn06_01_list_tab_attach
    TAB = 4044286600,                -- cmn06_20_list_tab_item
    TAB_NAME = 3029561990,           -- _text_list_tab01
    -- retail tab icon types: 74 all, 42 + series type for a series (chara_bank_menu)
    ICON_ALL = 74, ICON_SERIES = 42,
    -- The tab icon atlas, the tab's two icon slots (as the retail LISTVIEW.SetupTabIcon names them) and its plate.
    ICON_ATLAS = 1395458492, ICON_SLOT_ON = 3229351341, ICON_SLOT_OFF = 380437824,
    TAB_PLATE = 4013273506,          -- _icon_base01
    -- the glyphs of the page prompts
    GLYPH_L2 = 619948187, GLYPH_R2 = 3487556099,
    -- The retail filter array is an allow list of (listItemType, value, option): type 1 is one series box, its value the
    -- series type 1..9 (item_filter_menu UpdateItem indexes its series table with it); type 8 with value 1 stands for
    -- every series box at once (item_filter_menu_inc CreateDefaultFilerParamArray, the same for kits and emblems).
    FILTER_SERIES = 1, FILTER_WHOLE_GROUP = 8,
    -- The bar's fourth retail background has the widest band (805 px): 10 tabs (792 px) fit between its end caps.
    BAR_WIDE_BAND = 4,
    -- the tile's two plates (vs01_43): the retail one for the worn item, the second one for every other item
    PLATE_WORN = 2668225226,         -- _enjoy_list_p1_base01
    PLATE_OTHER = 294053161,         -- _enjoy_list_p2_base01
    PLATE_OTHER_SLOT = 2890361628,   -- enjoy_list_p2_base01
    -- the honeycomb layout's two spare quads carry the fade bands over the grid's top and bottom edges
    FADE_TOP = { mesh = 3350943237, slot = 1736249803 },      -- _spirit_list_base01
    FADE_BOTTOM = { mesh = 458268027, slot = 3019955541 },    -- _gtxt_spirit01
  }
  --- The equip picker grid: `new(rules)` gives the picker a screen's retail callbacks are handed to (docs/framework/emblem-grid.md).
  VRFW.equip_grid = Grid

  local Picker = {}
  Picker.__index = Picker

  --- A picker for `rules`; nil when the series of its tabs cannot be read (the caller then leaves the screen retail).
  --- rules: log_tag, stem (the menu script), menu, list, item (layer ids), tabs_command (-> array of { id, ty }),
  --- item_word (for the log), art (atlas id), fade_top, fade_bottom, plate_other (sprite ids), fade_colour (colour
  --- preset of the list object), hidden_layers (array of layer ids hidden when they open), draw_icon(layer, instance,
  --- item), is_worn(item), keep_icons (true: a tile's icon is drawn again only when its item changes),
  --- preview_rest_frames, is_ready() (true once the screen takes previews), and for a bar with the mods' tabs on more pages: mod_tabs = { list_command (-> array of
  --- { key, mod, icon, icon_off }), select_command (key or "") } and pages = { previous, next (function key and text
  --- ids), previous_prompt, next_prompt (footer prompt names) }.
  function Grid.new(rules)
    local series_list = VRFW.host.command(rules.tabs_command)
    if type(series_list) ~= "table" then
      return nil
    end
    local picker = setmetatable({}, Picker)
    picker.rules = rules
    picker.log = VRFW.logger.new(rules.log_tag)
    -- Every tab in bar order, the tabs of the shown page, the tab whose items the list shows, and the tab pager.
    picker.entries = { { id = 0, icon = Grid.ICON_ALL } }
    for _, series in ipairs(series_list) do
      picker.entries[#picker.entries + 1] = { id = series.id, series_type = series.ty, icon = Grid.ICON_SERIES + series.ty }
    end
    local game_tabs = #picker.entries
    local mod_tabs = rules.mod_tabs
    if mod_tabs ~= nil then
      -- The mods' tabs follow the game's series tabs: they fill the next pages.
      local declared = VRFW.host.command(mod_tabs.list_command)
      for _, tab in ipairs(type(declared) == "table" and declared or {}) do
        picker.entries[#picker.entries + 1] = { key = tab.key, mod = tab.mod, sprite = tab.icon, sprite_off = tab.icon_off }
      end
      funcLuaCommand(mod_tabs.select_command, "")
    end
    picker.tabs, picker.current, picker.pager = picker.entries, picker.entries[1], nil
    picker.focused = -1
    picker.shown = {}
    picker.hidden = {}
    for _, layer in ipairs(rules.hidden_layers or {}) do
      picker.hidden[layer] = true
    end
    picker.frame, picker.moved_at, picker.pending, picker.previewed = 0, -1000, nil, nil
    picker.ready, picker.acting = false, nil
    if #picker.entries > game_tabs then
      picker.pager = VRFW.tab_pager.new({
        name = rules.stem, layer = Grid.TAB, per_page = game_tabs, pinned = 0, entries = picker.entries,
        show = function(list)
          picker.tabs = list
        end,
        icon = function(slot, tab)
          picker:tab_icon(Grid.TAB, slot, tab)
        end,
        bar = function(count)
          LISTVIEW.UpdateAttachTabNum(count, Grid.TAB_BAR)
          LISTVIEW.SetBgTextureListTab(Grid.BAR_WIDE_BAND, Grid.TAB_BAR)
        end,
        changed = function()
          picker:show_tab(picker.pager.slot or 0)
        end,
      })
      picker.pager:reset()
      picker:page_prompts()
    end
    picker.log("tabs: " .. tostring(game_tabs) .. " of the game, " .. tostring(#picker.entries - game_tabs)
      .. " of mods, " .. tostring(picker.pager and picker.pager:pages() or 1) .. " page(s)")
    return picker
  end

  --- The footer shows the L2 / R2 page prompts while the bar has more than one page.
  function Picker:page_prompts()
    local rules, pages = self.rules, self.rules.pages
    local function paged()
      return self.pager ~= nil
    end
    VRFW.footer_prompts.add({ name = pages.previous_prompt, menu = rules.stem, text = pages.previous,
      icon = Grid.GLYPH_L2, command = pages.previous, order = 10, when = paged })
    VRFW.footer_prompts.add({ name = pages.next_prompt, menu = rules.stem, text = pages.next,
      icon = Grid.GLYPH_R2, command = pages.next, order = 11, when = paged })
    VRFW.footer_prompts.attach(rules.stem, "UpdateButtonGuide")
  end

  --- The icon of `tab` on tab slot (layer, slot): a mod tab shows its own two sprites, a game tab its retail type.
  function Picker:tab_icon(layer, slot, tab)
    if tab.key == nil then
      -- The tab keeps its plate (the selected tab's highlight), as in the character bank.
      LISTVIEW.SetupTabIcon(layer, slot, tab.icon, true)
      return
    end
    funcLuaMenuCommand(Grid.C.SPRITE, layer, Grid.ICON_ATLAS, tab.sprite, Grid.ICON_SLOT_ON, 0, slot)
    funcLuaMenuCommand(Grid.C.SPRITE, layer, Grid.ICON_ATLAS, tab.sprite_off, Grid.ICON_SLOT_OFF, 0, slot)
    funcLuaMenuCommand(Grid.C.MESH_VISIBLE, layer, Grid.TAB_PLATE, true, slot)
  end

  --- The list shows the items of the tab on `slot` of the shown page: a mod tab's set is kept by the framework's
  --- list filter (rules.mod_tabs.select_command), a series tab narrows the retail filter (Picker:filter).
  function Picker:show_tab(slot)
    local rules = self.rules
    local tab = self.tabs[slot + 1]
    if tab == nil then
      return
    end
    self.current = tab
    self.focused = -1
    self.worn_tiles = {}
    if rules.mod_tabs ~= nil then
      funcLuaCommand(rules.mod_tabs.select_command, tab.key or "")
    end
    ApplyItemFilter(rules.menu, 1, rules.list, rules.item)
    self.log("tab slot " .. tostring(slot) .. " of page " .. tostring(self.pager and self.pager.page or 1)
      .. " (" .. tostring(tab.key or ("series type " .. tostring(tab.series_type))) .. "): "
      .. tostring(funcLuaMenuCommand(Grid.C.LIST_COUNT, rules.list)) .. " " .. tostring(rules.item_word))
  end

  --- The fade bands in the theme's background colour; without a theme there is no colour to fade into: no bands.
  function Picker:setup_fades(layer)
    local rules = self.rules
    local r, g, b = funcLuaCommand(Grid.C.THEME_COLOUR, "bg")
    local themed = type(r) == "number"
    for _, band in ipairs({ { quad = Grid.FADE_TOP, sprite = rules.fade_top }, { quad = Grid.FADE_BOTTOM, sprite = rules.fade_bottom } }) do
      funcLuaMenuCommand(Grid.C.MESH_VISIBLE, layer, band.quad.mesh, themed)
      if themed then
        funcLuaMenuCommand(Grid.C.SPRITE, layer, rules.art, band.sprite, band.quad.slot, 0, 0)
      end
    end
    if themed then
      funcLuaMenuCommand(Grid.C.MATERIAL_COLOUR, layer, 0, rules.fade_colour, r / 255, g / 255, b / 255)
    end
  end

  --- After the retail OnSetupLayer: the bar sized for the tabs, each tab's icon, the fade bands and the tile's dress.
  function Picker:setup_layer(layer, instance)
    local rules = self.rules
    if layer == Grid.TAB_BAR then
      LISTVIEW.UpdateAttachTabNum(#self.tabs)
      LISTVIEW.SetBgTextureListTab(Grid.BAR_WIDE_BAND, layer)
      funcLuaMenuCommand(Grid.C.TEXT_VISIBLE, layer, Grid.TAB_NAME, false, 0)
    elseif layer == Grid.TAB then
      local tab = self.tabs[instance + 1]
      funcLuaMenuCommand(Grid.C.LAYER_VISIBLE, layer, instance, tab ~= nil)
      if tab ~= nil then
        self:tab_icon(layer, instance, tab)
      end
    elseif layer == rules.list then
      self:setup_fades(layer)
    elseif layer == rules.item then
      VRFW.emblem_grid.dress_tile(layer, instance)
      funcLuaMenuCommand(Grid.C.SPRITE, layer, rules.art, rules.plate_other, Grid.PLATE_OTHER_SLOT, 0, instance)
    end
  end

  --- After the retail OnOpenLayer: the LB / RB prompts in the bar, one focus slot per tab, the rules' hidden layers.
  function Picker:open_layer(layer, instance)
    if layer == Grid.TAB_BAR then
      LISTVIEW.ChangeListTabLRGaiji(layer, instance, false)
    elseif layer == Grid.TAB and instance == 0 then
      -- The retail screen has one tab and one focus slot: like the character bank, the tab layer gets one slot per tab.
      funcLuaMenuCommand(Grid.C.FOCUS_NUM, layer, #self.tabs)
    elseif layer == self.rules.item then
      self.shown[instance] = nil
    elseif self.hidden[layer] then
      funcLuaMenuCommand(Grid.C.LAYER_VISIBLE, layer, instance, false)
    end
  end

  --- The player's filter `params` narrowed to the series of the shown tab: every other series box and the whole-group
  --- entry are left out, and the tab's box stays only when the player's filter allows that series. A tab without a
  --- series (the «all» tab, a mod tab) changes nothing.
  function Picker:filter(params)
    local tab = self.current
    if tab == nil or tab.series_type == nil then
      return params
    end
    local narrowed, allowed = {}, nil
    for _, param in ipairs(params or {}) do
      local whole_group = param.listItemType == Grid.FILTER_WHOLE_GROUP and param.value == Grid.FILTER_SERIES
      local series_box = param.listItemType == Grid.FILTER_SERIES
      if whole_group or (series_box and param.value == tab.series_type) then
        allowed = param.option
      elseif not series_box then
        narrowed[#narrowed + 1] = param
      end
    end
    if allowed ~= nil then
      narrowed[#narrowed + 1] = { listItemType = Grid.FILTER_SERIES, value = tab.series_type, option = allowed }
    end
    return narrowed
  end

  --- After the retail OnChangeFocus: LB / RB moved the tab layer's focus, the list follows the focused tab.
  function Picker:change_focus(layer, instance)
    if layer ~= Grid.TAB then
      return
    end
    -- The focused tab is read from the layer, as the retail tab screens do (equip_synergy_menu_list, chara_bank_menu).
    local focused = funcLuaMenuCommand(Grid.C.FOCUSED, layer)
    local tab = type(focused) == "number" and self.tabs[focused + 1] or nil
    if self.pager ~= nil and tab ~= nil then
      -- A page turn moves the focus itself: the pager learns that the screen showed the tab, as in the character bank.
      if self.pager.turning then
        self.pager:focus(focused)
      else
        self.pager.slot = focused
      end
    end
    if tab == nil or tab == self.current then
      self.log("tab focus: callback instance " .. tostring(instance) .. ", focused " .. tostring(focused) .. ", no change")
      return
    end
    self:show_tab(focused)
  end

  --- A function key of the screen: true when it was a page key (rules.pages) and the bar turned to that page.
  function Picker:function_key(command)
    local pages = self.rules.pages
    if self.pager == nil or pages == nil or (command ~= pages.previous and command ~= pages.next) then
      return false
    end
    local count = self.pager:pages()
    local page = command == pages.next and self.pager.page % count + 1 or (self.pager.page - 2) % count + 1
    self.pager:show(page, 0, true)
    return true
  end

  --- The retail OnEnter equips the focused item whatever layer the decide came from, because the retail screen has
  --- one tab. With several tabs a decide on the tab layer (a click on a tab) only chooses the tab: true when the
  --- decide of (layer, instance) is on an item, so the caller equips; false on the tab bar, nothing is equipped.
  function Picker:accepts(layer, instance)
    local on_tab = layer == Grid.TAB or layer == Grid.TAB_BAR
    self.log("accept asked by OnEnter: layer " .. tostring(layer) .. ", instance " .. tostring(instance)
      .. (on_tab and ": a tab, nothing is equipped" or ": the focused item is equipped"))
    return not on_tab
  end

  --- The screen ends: the framework's list filter is released, so no other picker's list is kept to a mod tab.
  function Picker:finalize()
    if self.rules.mod_tabs ~= nil then
      funcLuaCommand(self.rules.mod_tabs.select_command, "")
    end
  end

  --- In place of the retail UpdateItemEquipLine: tile `instance` shows the item of `handle`, its plate, tick and cursor.
  function Picker:update_line(layer, instance, handle, focused)
    local rules = self.rules
    local item = funcLuaCommand(Grid.C.ITEM_ID, handle, 0)
    if not item then
      return
    end
    local tiles = VRFW.emblem_grid
    if not rules.keep_icons or self.shown[instance] ~= item then
      self.shown[instance] = item
      rules.draw_icon(layer, instance, item)
    end
    local worn = rules.is_worn(item) == true
    self.worn_tiles = self.worn_tiles or {}
    if worn and self.worn_tiles[instance] ~= item then
      -- The worn mark follows the item the team wears, read per item: the log names the tile that shows it.
      self.worn_tiles[instance] = item
      self.log("worn: item " .. tostring(item) .. ", handle " .. tostring(handle) .. ", on tile " .. tostring(instance)
        .. " of the shown list")
    elseif not worn then
      self.worn_tiles[instance] = nil
    end
    funcLuaMenuCommand(Grid.C.MESH_VISIBLE, layer, Grid.PLATE_WORN, worn, instance)
    funcLuaMenuCommand(Grid.C.MESH_VISIBLE, layer, Grid.PLATE_OTHER, not worn, instance)
    tiles.mark_tile(layer, instance, worn)
    if focused and instance ~= self.focused then
      if self.focused >= 0 then
        tiles.highlight_tile(layer, self.focused, false)
      end
      self.focused = instance
    end
    tiles.highlight_tile(layer, instance, focused == true)
  end

  --- Runs `load(handle)`, the screen's preview of the focused item, and logs who asked for it.
  function Picker:load_preview(handle, load, asked_by)
    local waited = self.pending ~= nil and self.frame - self.moved_at or 0
    self.pending, self.previewed = nil, handle
    load(handle)
    local item = handle ~= 0 and funcLuaCommand(Grid.C.ITEM_ID, handle, 0) or 0
    self.log("preview: handle " .. tostring(handle) .. ", item " .. tostring(item) .. ", asked by " .. tostring(asked_by)
      .. ", after " .. tostring(waited) .. " frame(s) of rest")
  end

  --- The engine names the focused `handle`, and names it again on every frame the focus stays there. Only a change of
  --- handle counts: its preview loads at once when the focus had rested, and otherwise when it rests again
  --- (rules.preview_rest_frames), so a moving cursor asks for one preview and not one per tile it crosses. The same
  --- handle loads again only while the screen acts on it (Picker:act). Nothing loads before rules.is_ready() is true.
  function Picker:preview(handle, load, asked_by)
    if handle ~= 0 and not self.ready then
      return
    end
    local focused = self.pending
    if focused == nil then
      focused = self.previewed
    end
    if handle == focused then
      if self.acting ~= nil and self.pending == nil then
        self:load_preview(handle, load, asked_by .. " during " .. self.acting)
      end
      return
    end
    local rested = self.frame - self.moved_at >= (self.rules.preview_rest_frames or 0)
    self.moved_at = self.frame
    if handle == 0 or rested then
      self.pending = nil
      return self:load_preview(handle, load, asked_by)
    end
    self.pending = handle
  end

  --- The waiting preview loads now for `asked_by`; a focus that came back to the loaded item has nothing to load.
  function Picker:load_pending(load, asked_by)
    if self.pending == self.previewed then
      self.pending = nil
    elseif self.pending ~= nil then
      self:load_preview(self.pending, load, asked_by)
    end
  end

  --- One frame, after the retail Step: the screen's readiness is read until it is true, and the waiting preview loads
  --- once the focus has rested.
  function Picker:step(load)
    self.frame = self.frame + 1
    if not self.ready then
      self.ready = self.rules.is_ready == nil or self.rules.is_ready() == true
    end
    if self.pending ~= nil and self.frame - self.moved_at >= (self.rules.preview_rest_frames or 0) then
      self:load_pending(load, "rest")
    end
  end

  --- The screen acts on the focused item through `action` (accept, a function key), named `name` in the log: the
  --- waiting preview loads first, and the action may ask for the same item's preview again.
  function Picker:act(load, name, action, ...)
    self:load_pending(load, name)
    self.acting = name
    local results = table.pack(pcall(action, ...))
    self.acting = nil
    if not results[1] then
      error(results[2], 0)
    end
    return table.unpack(results, 2, results.n)
  end
end
