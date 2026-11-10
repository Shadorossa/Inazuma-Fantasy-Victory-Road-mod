BetterUI = type(BetterUI) == "table" and BetterUI or {}
if BetterUI.page_keys == nil then
  local Crc = VRFW.ids.crc32

  local K = {
    LAYER = Crc("better_ui_page_keys"),
    TRACES = {[0] = Crc("better_ui_page_keys0"), Crc("better_ui_page_keys1")},
    TEXTS = {[0] = "_text_btn_l01", "_text_btn_r01"},
    AT_X = {[0] = 1039, 1811},
    AT_Y = 496,
    GAP_L = 40,                  -- Q: its left edge this far left of the first dot's
    GAP_R = 40,                  -- E: its left edge this far right of the last dot's
    RAISE = 8,                   -- the glyphs this much higher than the dots
    C = {IS_OPEN = VRFW.commands.IS_OPEN_LAYER, VIS = VRFW.commands.SET_LAYER_VISIBLE, POS = VRFW.commands.SET_LAYER_LOCAL_POS},
    drawn = nil,
  }
  BetterUI.page_keys = K

  local Cmd = VRFW.host.menu_command

  local function Hide()
    for k = 0, 1 do
      if Cmd(K.C.IS_OPEN, K.LAYER, k) == true then
        Cmd(K.C.VIS, K.LAYER, k, false)
      end
    end
  end

  function K.frame()
    local P = VRFW.player_pages
    if P == nil or type(P.dot_row) ~= "function" or type(P.status_copy) ~= "function" or P.row == nil then
      return
    end
    local row = P.dot_row()
    if row == nil or row.keys == false then
      if K.drawn ~= "" then
        K.drawn = ""
        Hide()
      end
      return
    end
    local all = true
    for k = 0, 1 do
      local ready, fresh = P.status_copy(K.LAYER, k, K.TRACES[k], {[K.TEXTS[k]] = true})
      if not ready then
        all = false
      elseif fresh then
        K.drawn = nil
      end
    end
    if not all then
      return
    end
    local state = row.count .. ":" .. row.x0 .. ":" .. row.y
    if state == K.drawn then
      return
    end
    K.drawn = state
    local x = {[0] = row.x0 - K.GAP_L, row.x0 + (row.count - 1) * row.pitch + K.GAP_R}
    local y = row.y - K.RAISE
    for k = 0, 1 do
      -- a copy's part lands at its layout place + the layer position + the status base's _pos_base01 (x right, y up)
      Cmd(K.C.POS, K.LAYER, x[k] - K.AT_X[k] - P.row.BASE_X, P.row.BASE_Y + K.AT_Y - y, 0, k)
      Cmd(K.C.VIS, K.LAYER, k, true)
    end
  end

  BetterUI.wrap_global(_ENV, "PageKeys", "PostStep", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      pcall(K.frame)
      return table.unpack(r, 1, r.n)
    end
  end)

  BetterUI.wrap_global(_ENV, "PageKeys", "OnCloseLayer", function(orig)
    return function(a1, a2, ...)
      local r = table.pack(orig(a1, a2, ...))
      if VRFW.player_pages ~= nil and VRFW.player_pages.row ~= nil and a1 == VRFW.player_pages.row.L_STATUS then
        K.drawn = nil
      end
      return table.unpack(r, 1, r.n)
    end
  end)
end
