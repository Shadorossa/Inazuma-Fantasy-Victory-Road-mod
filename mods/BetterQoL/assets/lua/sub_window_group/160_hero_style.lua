-- Hero style selector: the game's rarity window (type 27) shows the hero style banners of the team dock's picker.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.hero_style_window == nil and type(SetupWindowParams) == "function" then
  local W = {
    RARITY_WINDOW = 27,               -- the window type of the game's avatar rarity window
    ROW_LAYER = 3415005896,           -- win05_02_sub_list_item_basic15, its rows
    BANNER_MESH = 3466937483,         -- the row's banner mesh (the game's type 27 setup)
    BANNER_SLOT = 33616491,           -- gtxt_rarity_dmy01
    GRAY_MESH = 1409068817,           -- _list_base01_gray
    CHECK_MESH = 1920218598,          -- the row's check mark mesh (the game's check rows)
    CMD_SET_MESH_VISIBLE = 3405944500,
    CMD_SET_NODE_VISIBLE = 2158717427, -- the game's per-row check switch (layer, mesh, on, row)
    CMD_RARITY_BANNER = 2881088748,   -- (layer, row, mesh, slot, card rarity): the rarity banner sprite
  }
  BetterQoL.hero_style_window = W

  -- After the game's setup: a type 27 window opened for a hero style card draws one banner per style.
  local setup_window = SetupWindowParams
  SetupWindowParams = function(count, texts, size, a4, a5, a6, a7, a8, window_type, a10, a11, a12, a13, a14, handle, checks, ...)
    local results = table.pack(setup_window(count, texts, size, a4, a5, a6, a7, a8, window_type, a10, a11, a12, a13, a14,
      handle, checks, ...))
    if window_type == W.RARITY_WINDOW and BetterQoL.HeroStyle ~= nil and BetterQoL.HeroStyle.style_of(handle) ~= nil then
      local styles = BetterQoL.HeroStyle.styles()
      for i, style in ipairs(styles) do
        local row = i - 1
        funcLuaMenuCommand(W.CMD_SET_MESH_VISIBLE, W.ROW_LAYER, W.BANNER_MESH, true, row)
        funcLuaMenuCommand(W.CMD_RARITY_BANNER, W.ROW_LAYER, row, W.BANNER_MESH, W.BANNER_SLOT, style)
        funcLuaMenuCommand(W.CMD_SET_MESH_VISIBLE, W.ROW_LAYER, W.GRAY_MESH, false, row)
        local checked = type(checks) == "table" and checks[i] == 1
        funcLuaMenuCommand(W.CMD_SET_NODE_VISIBLE, W.ROW_LAYER, W.CHECK_MESH, checked, row)
      end
      BetterQoL.HeroStyle.log("window rows", #styles, "of", tostring(count), "handle", tostring(handle))
    end
    return table.unpack(results, 1, results.n)
  end
end
