-- Hero style selector: the game's rarity window (type 27) sized to every style and drawing one banner per style.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.hero_style_window == nil and type(SetupWindowParams) == "function" then
  local W = {
    RARITY_WINDOW = 27,               -- the window type of the game's avatar rarity window
    LAST_SIZE_CODE = 8,               -- the highest size code SetupWindowParams lays out (getMaxParamNum also answers 9)
    ROW_LAYER = 3415005896,           -- win05_02_sub_list_item_basic15, its rows
    BANNER_MESH = 3466937483,         -- the row's banner mesh (the game's type 27 setup)
    BANNER_SLOT = 33616491,           -- gtxt_rarity_dmy01
    GRAY_MESH = 1409068817,           -- _list_base01_gray
    CHECK_MESH = 1920218598,          -- the row's check mark mesh (the game's check rows)
    CMD_SET_MESH_VISIBLE = 3405944500,
    CMD_SET_NODE_VISIBLE = 2158717427, -- the game's per-row check switch (layer, mesh, on, row)
    CMD_RARITY_BANNER = 2881088748,   -- (layer, row, mesh, slot, card rarity): the rarity banner sprite
  }
  CharacterReforged.hero_style_window = W

  -- The size code whose layout shows the fewest rows that still hold `count` (the game's getMaxParamNum), nil if none.
  function W.size_for(count)
    if type(getMaxParamNum) ~= "function" then
      return nil
    end
    local best, best_rows = nil, nil
    for code = 0, W.LAST_SIZE_CODE do
      local ok, rows = pcall(getMaxParamNum, count, code)
      if ok and type(rows) == "number" and rows >= count and (best_rows == nil or rows < best_rows) then
        best, best_rows = code, rows
      end
    end
    return best
  end

  -- A type 27 window opened for a hero style card gets the size of all its styles and one banner per style.
  local setup_window = SetupWindowParams
  SetupWindowParams = function(count, texts, size, a4, a5, a6, a7, a8, window_type, a10, a11, a12, a13, a14, handle, checks, ...)
    local S = CharacterReforged.HeroStyle
    local mine = window_type == W.RARITY_WINDOW and S ~= nil and S.style_of(handle) ~= nil
    if mine then
      size = W.size_for(count) or size
    end
    local results = table.pack(setup_window(count, texts, size, a4, a5, a6, a7, a8, window_type, a10, a11, a12, a13, a14,
      handle, checks, ...))
    if mine then
      local styles = S.styles()
      for i, style in ipairs(styles) do
        local row = i - 1
        funcLuaMenuCommand(W.CMD_SET_MESH_VISIBLE, W.ROW_LAYER, W.BANNER_MESH, true, row)
        funcLuaMenuCommand(W.CMD_RARITY_BANNER, W.ROW_LAYER, row, W.BANNER_MESH, W.BANNER_SLOT, style)
        funcLuaMenuCommand(W.CMD_SET_MESH_VISIBLE, W.ROW_LAYER, W.GRAY_MESH, false, row)
        local checked = type(checks) == "table" and checks[i] == 1
        funcLuaMenuCommand(W.CMD_SET_NODE_VISIBLE, W.ROW_LAYER, W.CHECK_MESH, checked, row)
      end
      S.log("window rows", #styles, "of", tostring(count), "size code", tostring(size), "handle", tostring(handle))
    end
    return table.unpack(results, 1, results.n)
  end
end
