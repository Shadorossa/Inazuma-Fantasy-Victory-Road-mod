  -- [1] move A  move B [2] move C  move D [3] move E  move F the slot badge at the row's left, the pair's two
  G.GROUP_AT = {{995, 732}, {995, 789}, {995, 846}}
  G.MOVE_K = 0.68
  -- the badge is 36 x 46, its node BADGE_CY below the row top (mesh centre = node), its left edge at BADGE_X
  G.BADGE = {36, 46}
  G.BADGE_X, G.BADGE_CY = 1004, 25
  G.PLATE_DX, G.PLATE_DX2 = 52, 385
  G.M_BADGE = {4182803106, 1616499480, 392094606}
  G.SK_AT_DMY = 365666709
  G.GRAPH_NUM = 732343773                -- soccer11_06_p1_formation_status_graph_param_num
  function G.moves_layout(status, rows)
    local s = G.MOVE_K
    for k = 1, 3 do
      local gx, gy = G.GROUP_AT[k][1], G.GROUP_AT[k][2]
      -- Places the badge.
      local X0, Y0 = G.BADGE_X, -(gy + G.BADGE_CY)
      Cmd(C.NODE_POS, status, 0, G.SLOT_NODES[k], 0, X0 - 1358)
      Cmd(C.NODE_POS, status, 0, G.SLOT_NODES[k], 1, Y0 + 540)
      Cmd(C.NODE_SCALE, status, 0, G.M_BADGE[k], G.BADGE[1], G.BADGE[2])
      Cmd(C.NODE_POS, status, 0, G.M_BADGE[k], 1, G.BADGE[2] / 2)
      for j = 0, 1 do
        local i = (k - 1) * 2 + j
        local Ax, Ay = X0 + 302, Y0 + (j == 0 and 31 or -31)        -- the row's attach locator (world, y up)
        local tx, ty = gx + G.PLATE_DX + G.PLATE_DX2 * j, -(gy + 2)   -- the plate's top-left (world, y up)
        local px, py = tx - Ax - s * (-267), ty - Ay - s * 34
        for _, l in ipairs(rows) do
          if Exists(l) and Cmd(C.IS_OPEN, l, i) == true then
            Cmd(C.SCALE, l, s, s, 1, i)
            Cmd(C.POS, l, px, py, 0, i)
          end
        end
        if Exists(rows[1]) and Cmd(C.IS_OPEN, rows[1], i) == true then
          Cmd(C.MESH, rows[1], G.SK_AT_DMY, false, i)
        end
      end
    end
  end

  -- the retail column back (the status base's slot nodes and badges, the plates at their locators)
  function G.moves_retail(status, rows)
    for k = 1, 3 do
      Cmd(C.NODE_POS, status, 0, G.SLOT_NODES[k], 0, G.SLOT_RETAIL[k][1])
      Cmd(C.NODE_POS, status, 0, G.SLOT_NODES[k], 1, G.SLOT_RETAIL[k][2])
      Cmd(C.NODE_SCALE, status, 0, G.M_BADGE[k], 64, 84)
      Cmd(C.NODE_POS, status, 0, G.M_BADGE[k], 1, 42)
    end
    for i = 0, 5 do
      for _, l in ipairs(rows) do
        if Exists(l) and Cmd(C.IS_OPEN, l, i) == true then
          Cmd(C.POS, l, 0, 0, 0, i)
          Cmd(C.SCALE, l, 1, 1, 1, i)
        end
      end
    end
  end

  function G.moves()
    if not Exists(G.SKILL) or not Exists(G.STATUS) then
      return
    end
    local mine = On() and G.ptype == 1
    if not mine then
      if G.movesOn then
        G.movesOn = false
        G.moves_retail(G.STATUS, {G.SKILL, G.SKILL_BLANK})
      end
      return
    end
    if not G.movesOn then                  -- earlier states undone once
      for i = 0, 5 do
        if Cmd(C.IS_OPEN, G.SKILL, i) == true then
          Cmd(C.NODE_POS, G.SKILL, i, G.SK_HIDE_NODE[1], 0, 0)
          Cmd(C.NODE_POS, G.SKILL, i, G.SK_HIDE_NODE[2], 0, 203)
          Cmd(C.TEXT_VIS, G.SKILL, G.SK_TEXT, true, i)
          Cmd(C.MESH, G.SKILL, G.SK_HIDE_MESH[1], true, i)
        end
      end
    end
    G.movesOn = true
    G.moves_layout(G.STATUS, {G.SKILL, G.SKILL_BLANK})
    -- The move-detail mode (N) re-shows the radar layers.
    if Cmd(C.IS_VIS, G.GRAPH, 0) == true then
      pcall(SetVisibleGraphLayer, false)
      if type(CharacterReforged.stat_radar) == "table" and type(CharacterReforged.stat_radar.visible) == "function" then
        pcall(CharacterReforged.stat_radar.visible, false)
      end
    end
    if type(G.bars_visible) == "function" then
      G.bars_visible(false)
    end
  end

  -- On this page (instance 2r = left plate, 2r + 1 = right plate) LEFT / RIGHT = the other plate of the row, UP
  G.NAV = {FOCUS_MARK = 1778826357, FOCUS_SET = 3466097042, PLAY_ANIME = @crc:CMND_PLAY_ANIME_TYPE@, FOCUS_ANIME = 2734777837,
    ANIME_KIND = 973515837, ZONE = 855005857, GET_SKILL = 903078840, SOUND = @crc:CMND_SND_PLAY_SE@, CURSOR_SOUND = 2500047763,
    GHOST_FRAMES = 3, COLUMNS = 2, ROWS = 3,
    DIRECTION_TOKENS = {[3483715641] = "up", [906909014] = "up", [49409691] = "down", [2207386753] = "down",
      [1684642248] = "left", [3842669522] = "left", [1644353666] = "right", [2682339866] = "right"}}
  G.nav = {index = nil, pending = nil, handled = false, busy = false, echo = false, lastDir = nil, ghost = nil,
    expect = nil}

  function G.nav_active()
    return G.H.pages and On() and G.ptype == 1 and Exists(G.SKILL) and Cmd(G.FOCUS_ACTIVE, G.SKILL) == true
  end

  -- Returns the direction stepped this frame.
  function G.nav_direction()
    local K = VRFW.keys
    for _, d in ipairs({{"up", K.UP}, {"down", K.DOWN}, {"left", K.LEFT}, {"right", K.RIGHT}}) do
      if K.held(d[2]) then
        return d[1]
      end
    end
    return nil
  end

  function G.nav_filled(i)
    if i < 0 or i >= G.NAV.COLUMNS * G.NAV.ROWS or Cmd(C.IS_OPEN, G.SKILL, i) ~= true then
      return false
    end
    local F = CharacterReforged.PLAYER_PAGE_FANTASY_MOVES
    if type(F) == "table" and type(F.shown) == "table" and F.shown[i] ~= nil then
      return F.shown[i].move ~= 0
    end
    if type(GetPersonalPlateSelectCharaStHdlAuto) ~= "function" then
      return true
    end
    local okH, hdl = pcall(GetPersonalPlateSelectCharaStHdlAuto)
    if not okH or type(hdl) ~= "number" or hdl == 0 then
      return true
    end
    local okS, move = pcall(funcLuaCommand, G.NAV.GET_SKILL, hdl, i)
    return okS and move ~= nil and move ~= 0
  end

  function G.nav_target(from, dir)
    local columns, rows = G.NAV.COLUMNS, G.NAV.ROWS
    local row, column = math.floor(from / columns), from % columns
    if dir == "left" or dir == "right" then
      local step = dir == "left" and -1 or 1
      local c = column + step
      while c >= 0 and c < columns do
        if G.nav_filled(row * columns + c) then
          return row * columns + c
        end
        c = c + step
      end
      return from
    end
    local step = dir == "up" and -1 or 1
    local r = row + step
    while r >= 0 and r < rows do
      for distance = 0, columns - 1 do
        for _, c in ipairs({column - distance, column + distance}) do
          if c >= 0 and c < columns and G.nav_filled(r * columns + c) then
            return r * columns + c
          end
        end
      end
      r = r + step
    end
    return from
  end

  function G.nav_unfocus(i)
    local N = G.NAV
    Cmd(N.PLAY_ANIME, G.SKILL, i, N.FOCUS_ANIME, 2, N.ANIME_KIND)
  end

  function G.nav_set_focus(to, left)
    local N, S = G.NAV, G.nav
    S.busy, S.echo = true, false
    Cmd(N.FOCUS_MARK, G.SKILL, to, true)
    if Cmd(G.FOCUS_IDX, G.SKILL) ~= to then
      Cmd(N.FOCUS_SET, G.SKILL, to)
    end
    if not S.echo and type(OnChangeFocus) == "function" then
      pcall(OnChangeFocus, G.SKILL, to)
    end
    S.busy = false
    if left ~= nil and left ~= to then
      G.nav_unfocus(left)
      S.ghost = {left, N.GHOST_FRAMES}
    end
    S.index = to
  end

  -- OnChangeFocus of the move layer
  function G.nav_on_change(layer, token)
    local S = G.nav
    if S.busy then
      S.echo = true
      return false
    end
    if layer ~= G.SKILL or not G.nav_active() then
      return false
    end
    local index = Cmd(G.FOCUS_IDX, G.SKILL)
    local dir = G.NAV.DIRECTION_TOKENS[token]
    if dir == nil then
      dir = G.nav_direction()
    end
    if dir == nil or S.index == nil or type(index) ~= "number" then
      S.index = type(index) == "number" and index or nil   -- the pointer or the screen moved it
      S.pending, S.expect = nil, nil
      return false
    end
    local target = G.nav_target(S.index, dir)
    S.pending, S.handled = nil, true
    if target == index then
      S.index, S.expect = index, nil
      return false
    end
    G.nav_set_focus(target, index)
    S.expect = target
    return true
  end

  function G.moves_nav()
    local S = G.nav
    if S.ghost ~= nil then
      local g = S.ghost
      g[2] = g[2] - 1
      if g[2] <= 0 then
        S.ghost = nil
      end
      if Cmd(G.FOCUS_IDX, G.SKILL) ~= g[1] then
        G.nav_unfocus(g[1])
      else
        S.ghost = nil
      end
    end
    if not G.nav_active() then
      S.index, S.pending, S.handled, S.lastDir, S.expect = nil, nil, false, nil, nil
      return
    end
    local current = Cmd(G.FOCUS_IDX, G.SKILL)
    if type(current) ~= "number" then
      return
    end
    local dir = G.nav_direction()
    local lastDir = S.lastDir
    S.lastDir = dir
    if S.handled then
      -- Handles a redirected step that the engine put back on its own target after OnChangeFocus.
      local expect = S.expect
      S.handled, S.pending, S.expect = false, nil, nil
      if expect ~= nil and current ~= expect then
        G.nav_set_focus(expect, current)
        current = expect
      end
      S.index = current
      return
    end
    local p = S.pending
    S.pending = nil
    if p ~= nil and current == p.from then
      local target = G.nav_target(p.from, p.dir)
      if target ~= current then
        G.nav_set_focus(target, current)
        pcall(funcLuaCommand, G.NAV.SOUND, G.NAV.CURSOR_SOUND)
        current = target
      end
    end
    S.index = current
    if dir ~= nil and dir ~= lastDir then
      S.pending = {from = current, dir = dir}
    end
  end

  -- Declares the pointer zones of the move plates on the extra move rows.
  function G.nav_zones()
    local F = CharacterReforged.PLAYER_PAGE_FANTASY_MOVES
    if not G.H.pages or not On() or G.ptype ~= 1 or not Exists(G.SKILL) or type(F) ~= "table"
        or type(F.shown) ~= "table" then
      return
    end
    for i = 0, 5 do
      local shown = F.shown[i]
      if shown ~= nil and Cmd(C.IS_OPEN, G.SKILL, i) == true then
        Cmd(G.NAV.ZONE, G.SKILL, i, shown.move ~= 0)
      end
    end
  end
