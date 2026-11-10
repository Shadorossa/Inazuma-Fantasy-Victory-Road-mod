if BetterUI_WindowSize == nil and type(SetupWindowParams) == "function" and type(OnOpenLayer) == "function" then
  local W = {
    NODE_SIZE = 2885415772,          -- (layer, instance, node, width, height): a quad's size in px
    LAYER_NAME = "win05_13_sub_list_locator",   -- the window layer of sub window type 0
    PANEL_NODES = {"_list_sub_base01", "_list_sub_ring01"},
    PANEL_WIDTH = 488,               -- the quads' layout size
    PANEL_HEIGHT = 804,
    MASK_HEIGHT = 268,
    LAYOUT_ROWS = 2,
    ROW_STEP = 70,                   -- px per row (the _listNN anchors)
    PANEL_TOP_TO_ROWS = 119,
    MAX_ROWS = 9,
    rows = nil,
  }
  BetterUI_WindowSize = W

  local function log(...)
    if PRINT ~= nil then
      pcall(PRINT, "BetterUI window_size", ...)
    end
  end

  -- the quads' height that shows a panel of this many rows
  function W.panel_height(rows)
    local shown = math.min(W.MAX_ROWS, rows)
    if shown <= W.LAYOUT_ROWS then
      return W.PANEL_HEIGHT, W.MASK_HEIGHT
    end
    local wanted = W.PANEL_TOP_TO_ROWS + W.ROW_STEP * shown          -- 34 px under the last button
    local clip = W.MASK_HEIGHT + W.ROW_STEP * (shown - W.LAYOUT_ROWS) -- the panel the size clip gives at the layout height
    return math.floor(W.PANEL_HEIGHT * wanted / clip + 0.5), wanted
  end

  local setup = SetupWindowParams
  SetupWindowParams = function(count, texts, size, ...)
    local r = table.pack(setup(count, texts, size, ...))
    local ok, rows = pcall(getMaxParamNum, count, size)
    W.rows = (ok and type(rows) == "number") and rows or nil
    return table.unpack(r, 1, r.n)
  end

  local open_layer = OnOpenLayer
  OnOpenLayer = function(layer, idx, ...)
    local r = table.pack(open_layer(layer, idx, ...))
    if W.rows ~= nil and (idx or 0) == 0 and type(VRFW.crc32) == "function" and type(GetWindowLayerName) == "function" then
      local ok, window = pcall(GetWindowLayerName)
      if ok and layer == window and layer == VRFW.crc32(W.LAYER_NAME) then
        local height, visible = W.panel_height(W.rows)
        for _, node in ipairs(W.PANEL_NODES) do
          VRFW.host.menu_command(W.NODE_SIZE, layer, 0, VRFW.crc32(node), W.PANEL_WIDTH, height)
        end
        log("rows " .. W.rows .. ", panel " .. visible .. " px (quads " .. height .. ")")
        W.rows = nil
      end
    end
    return table.unpack(r, 1, r.n)
  end
end
