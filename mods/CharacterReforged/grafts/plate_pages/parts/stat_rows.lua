-- Player page block (plate_pages.lua)
  G.ROW_X0 = {[0] = 993 - 1435, 1445 - 1435}                       -- column left edges
  G.ROW_Y = {[0] = 746 - 740, 746 - 785, 746 - 830, 746 - 875}     -- row centres
  G.GAUGE = {X = 124, W = 180, H = 28}                             -- track: x from the column's left, width, height
  -- team13_16 layout.
  G.GG = {NODE = 3407907417 --[[_pos_bar01]], TRACK_X = -64, TRACK_Y = -13, TRACK_W = 176, TRACK_H = 16,
    FILL_X = -59, FILL_W = 166,
    HIDE = {3653430537 --[[_icon_parameter_dmy01]], 156590433 --[[_num_param_dmy01]], 2421960923 --[[_num_param_dmy02]],
      501779097 --[[_beans_bar01: the masked fill]]},
    PRIMS = {3484572139, 1455097937, 1533119290},
    TRACK_QUAD = 3904782638 --[[_beans_param_base01]], GAIN_QUAD = 3341153111 --[[_beans_bar_slash01]],
    FILL_QUAD = 720708095 --[[_beans_bar_base01]],
    -- sprite slots of those three meshes and the retail track sprite (team13_16 atlas)
    SLOT_TRACK_QUAD = 1215825632 --[[beans_param_base01]], SLOT_GAIN_QUAD = 192955831 --[[beans_bar_slash01]],
    SLOT_FILL_QUAD = 2201244747 --[[beans_bar_base01]], SP_TRACK = 2201244747 --[[beans_bar_base01]],
    TX_GAUGE = 995892987 --[[#/menu/102_team/team13/team13_16/team13_16.g4tx]],
    MIN_W = 0.5,                                                   -- narrower quads are hidden (gauge units)
    PRIM_VIS = 1233047821}

  local function BarsVisible(on)
    if not Exists(G.BAR) then
      return
    end
    for k = 0, 7 do
      if Cmd(C.IS_OPEN, G.BAR, k) == true then
        Cmd(C.VIS, G.BAR, k, on)
      end
    end
  end
  G.bars_visible = BarsVisible

  G.SP_GAIN = @crc:cr_pp_gfill_gain@
  function G.row_mark(k)
    local R = type(G.H.item_card) == "table" and G.H.item_card.row_mark or nil
    if R == nil or G.rowFrame == nil then
      return nil, R
    end
    for g = 1, 8 do
      if G.GROUP_ROW[g] == k and G.rowFrame[g] ~= nil then
        return G.rowFrame[g], R
      end
    end
    return nil, R
  end
  -- Returns the gain quad's sprite and its atlas.
  function G.gain_sprite(k)
    local mark, R = G.row_mark(k)
    if mark ~= nil then
      return R.sprite[mark], R.atlas or G.TX_OWN
    end
    return G.SP_GAIN, G.TX_OWN
  end
  function G.gain(g)
    local t = G.gains
    local IC = G.H.item_card
    if type(IC) == "table" and IC.rows ~= false then
      return 0
    end
    return t ~= nil and (tonumber(t[G.STAT[g] + 1]) or 0) or 0
  end

  function G.read_tops(hdl)
    G.tops = nil
    local page = type(CharacterReforged) == "table" and CharacterReforged.page or nil
    if type(hdl) ~= "number" or type(page) ~= "table" or type(page.stat_top) ~= "function" then
      return
    end
    local t = {}
    for g = 1, 8 do
      local top = page.stat_top(hdl, G.STAT[g])
      if top == nil then
        return
      end
      t[g] = top
    end
    G.tops = t
  end

  function G.bar_quads(k, r, r2, sx, sy)
    local GG = G.GG
    for _, m in ipairs(GG.HIDE) do
      Cmd(C.MESH, G.BAR, m, false, k)
    end
    Cmd(C.NODE_POS, G.BAR, k, GG.TRACK_QUAD, 0, 0)
    Cmd(C.NODE_POS, G.BAR, k, GG.TRACK_QUAD, 1, 0)
    Cmd(C.NODE_SCALE, G.BAR, k, GG.TRACK_QUAD, GG.TRACK_W * sx, GG.TRACK_H * sy)
    Cmd(C.MESH, G.BAR, GG.TRACK_QUAD, true, k)
    local gain_w = GG.FILL_W * r2 * sx
    Cmd(C.NODE_POS, G.BAR, k, GG.GAIN_QUAD, 0, (GG.FILL_X - GG.TRACK_X) * sx)
    Cmd(C.NODE_POS, G.BAR, k, GG.GAIN_QUAD, 1, 0)
    Cmd(C.NODE_SCALE, G.BAR, k, GG.GAIN_QUAD, math.max(gain_w, GG.MIN_W), GG.TRACK_H * sy)
    Cmd(C.MESH, G.BAR, GG.GAIN_QUAD, r2 > r and gain_w >= GG.MIN_W, k)
    local mark, R = G.row_mark(k)
    if mark ~= nil then
      local m, Q = R.margin or 0, G.GAUGE
      Cmd(C.NODE_POS, G.BAR, k, GG.GAIN_QUAD, 0, -m)
      Cmd(C.NODE_POS, G.BAR, k, GG.GAIN_QUAD, 1, m)
      Cmd(C.NODE_SCALE, G.BAR, k, GG.GAIN_QUAD, Q.W + 2 * m, Q.H + 2 * m)
      Cmd(C.MESH, G.BAR, GG.GAIN_QUAD, true, k)
    end
    local fill_w = GG.FILL_W * r
    Cmd(C.NODE_POS, G.BAR, k, GG.FILL_QUAD, 0, GG.FILL_X)
    Cmd(C.NODE_POS, G.BAR, k, GG.FILL_QUAD, 1, GG.TRACK_Y)
    Cmd(C.NODE_SCALE, G.BAR, k, GG.FILL_QUAD, math.max(fill_w, GG.MIN_W), GG.TRACK_H)
    Cmd(C.MESH, G.BAR, GG.FILL_QUAD, fill_w * sx >= GG.MIN_W, k)
  end

  function G.bars()
    if not On() or not Exists(G.BAR) or not Exists(G.GRAPH) then
      return
    end
    local up = G.vals ~= nil and G.ptype == CharacterReforged.PLAYER_PAGE_STATS_TYPE and Cmd(C.IS_VIS, G.GRAPH, 0) == true
    if not up then
      BarsVisible(false)
      if G.delta_segment ~= nil then
        pcall(G.delta_segment, nil)
      end
      if G.item_card_delta_labels ~= nil then
        pcall(G.item_card_delta_labels, nil)
      end
      if G.item_card_stat_boxes ~= nil then
        pcall(G.item_card_stat_boxes, nil)
      end
      G.rowMarkKey = {}
      return
    end
    local all = true
    for k = 0, 7 do
      -- an instance set up and still open draws whatever else this menu loads (a window over it)
      if not (G.ready[G.BAR * 16 + k] and not G.hostShut and Cmd(C.IS_OPEN, G.BAR, k) == true) and not Ready(G.BAR, k) then
        all = false
      end
    end
    if not all then
      G.rowMarkKey = {}
      return
    end
    -- Reads each row's state under the focused equipment item (G.row_state).
    local other, change, shown = {}, nil, nil
    if G.row_state ~= nil then
      local frame = nil
      for g = 1, 8 do
        local old, new, c = G.row_state(g, G.vals[g] or 0)
        if c ~= nil then
          other[g] = G.rowOwn and old or new
          change, shown, frame = change or {}, shown or {}, frame or {}
          change[g], shown[g], frame[g] = c, new, c > 0 and "raise" or "lower"
        end
      end
      G.rowFrame, G.rowShown = frame, shown
    end
    -- Handles the case with no training data.
    local scale = 0
    for g = 1, 8 do
      scale = math.max(scale, (G.vals[g] or 0) + G.gain(g), other[g] or 0)
    end
    scale = math.max(100, math.ceil(scale * 1.15 / 50) * 50)
    local GG, Q = G.GG, G.GAUGE
    local sx, sy = Q.W / GG.TRACK_W, Q.H / GG.TRACK_H
    local segs = nil
    for g = 1, 8 do
      local k = G.GROUP_ROW[g]
      if not G.ready[G.BAR * 16 + k] then
        G.ready[G.BAR * 16 + k] = true
        Cmd(C.TRACE, G.GRAPH, 0, G.TRACE[k], true)
        for _, m in ipairs(GG.HIDE) do
          Cmd(C.MESH, G.BAR, m, false, k)
        end
        for _, p in ipairs(GG.PRIMS) do
          Cmd(GG.PRIM_VIS, G.BAR, k, p, false)
        end
        Cmd(C.SPRITE, G.BAR, GG.TX_GAUGE, GG.SP_TRACK, GG.SLOT_TRACK_QUAD, 0, k)
        Cmd(C.SPRITE, G.BAR, G.TX_OWN, CALC_CRC("cr_pp_gfill_" .. G.STAT_FILL[g]), GG.SLOT_FILL_QUAD, 0, k)
        local gs, ga = G.gain_sprite(k)
        Cmd(C.SPRITE, G.BAR, ga, gs, GG.SLOT_GAIN_QUAD, 0, k)
        Cmd(C.SCALE, G.BAR, 1, 1, 1, k)
        -- the bar node scaled to the row's track size, the track's top-left on the layer's origin
        Cmd(C.NODE_POS, G.BAR, k, GG.NODE, 0, -GG.TRACK_X * sx)
        Cmd(C.NODE_POS, G.BAR, k, GG.NODE, 1, -GG.TRACK_Y * sy)
        Cmd(C.NODE_SCALE, G.BAR, k, GG.NODE, sx, sy)
      end
      local col, row = math.floor(k / 4), k % 4
      Cmd(C.POS, G.BAR, G.ROW_X0[col] + Q.X, G.ROW_Y[row] + Q.H / 2, 0, k)
      local gain = G.gain(g)
      local top = math.max((G.tops ~= nil and G.tops[g] or scale) + gain, 1)
      local v = G.vals[g] or 0
      local r = math.max(0, math.min(1, v / top))
      local r2 = math.max(0, math.min(1, (v + gain) / top))
      -- Handles a row with a change.
      local lo, hi = nil, nil
      if other[g] ~= nil and change ~= nil and change[g] ~= nil and G.delta_segment ~= nil then
        local D = G.H.item_card.row_mark.delta
        local ro = math.max(0, math.min(1, other[g] / top))
        local width = D.min_width / (GG.FILL_W * sx)
        lo, hi = math.min(r, ro), math.max(r, ro)
        if hi - lo < width then
          if change[g] > 0 then
            hi = math.min(1, lo + width)
            lo = math.max(0, hi - width)
          else
            lo = math.max(0, hi - width)
            hi = math.min(1, lo + width)
          end
        end
        r = math.max(0, lo - D.gap / (GG.FILL_W * sx))
        r2 = r
      end
      G.bar_quads(k, r, r2, sx, sy)
      Cmd(C.VIS, G.BAR, k, true)
      -- Draws a host's delta segment (the focused equipment item's change, G.row_state) as a screen rect over the bar.
      if lo ~= nil then
        -- The bars hang on the chart's base, placed at G.CHART_AT.
        local fx = G.CHART_AT[1] + G.ROW_X0[col] + Q.X + (GG.FILL_X - GG.TRACK_X) * sx
        local ty = G.CHART_AT[2] - (G.ROW_Y[row] + Q.H / 2)
        segs = segs or {}
        segs[#segs + 1] = {fx + GG.FILL_W * sx * lo, ty, GG.FILL_W * sx * (hi - lo), Q.H, change[g] > 0}
      end
    end
    if G.delta_segment ~= nil then
      pcall(G.delta_segment, segs)
    end
    if G.item_card_delta_labels ~= nil then
      pcall(G.item_card_delta_labels, change)
    end
    if G.item_card_stat_boxes ~= nil then
      pcall(G.item_card_stat_boxes, G.rowTotal)
    end
    if G.item_card_row_marks ~= nil then
      pcall(G.item_card_row_marks, change, shown)
    end
  end

  G.TRACE = {}
  for k = 0, 7 do
    G.TRACE[k] = nil
  end
  G.TRACE[0], G.TRACE[1], G.TRACE[2], G.TRACE[3] = @crc:cr_pp_stat_bar0@, @crc:cr_pp_stat_bar1@,
    @crc:cr_pp_stat_bar2@, @crc:cr_pp_stat_bar3@
  G.TRACE[4], G.TRACE[5], G.TRACE[6], G.TRACE[7] = @crc:cr_pp_stat_bar4@, @crc:cr_pp_stat_bar5@,
    @crc:cr_pp_stat_bar6@, @crc:cr_pp_stat_bar7@

  local function GameValues(hdl, l5)
    if type(CharacterReforged.stat_radar) == "table" and type(CharacterReforged.stat_radar.values) == "function" then
      local ok, v = pcall(CharacterReforged.stat_radar.values, hdl, l5)
      if ok and type(v) == "table" then
        return v
      end
    end
    local v = {}
    for g = 1, 8 do
      local si = G.STAT[g]
      local val = 0
      if si <= 6 and type(funcLuaCommand) == "function" then
        local ok, x = pcall(funcLuaCommand, C.CHARA, hdl, 14 + si, true, l5)
        val = ok and type(x) == "number" and x or 0
      end
      v[g] = val
    end
    local page = type(CharacterReforged) == "table" and CharacterReforged.page or nil
    if type(page) == "table" and type(page.stat) == "function" then
      v[8] = page.stat(hdl, 8) or 0
    end
    return v
  end

  function G.values(hdl, l5)
    local v = GameValues(hdl, l5)
    -- A host that writes its own row numbers shows the stats the match uses (the page_stat_bonus points added).
    local IC = type(G.H.item_card) == "table" and G.H.item_card or nil
    local page = type(CharacterReforged) == "table" and CharacterReforged.page or nil
    if IC ~= nil and IC.row_mark ~= nil and type(page) == "table" and type(page.stat_bonus) == "function" then
      local b = page.stat_bonus(hdl)
      for g = 1, 8 do
        v[g] = (v[g] or 0) + G.signed_stat(b[G.STAT[g] + 1])
      end
    end
    return v
  end
