-- Player page block (plate_pages.lua)
  function G.slot_pages()
    local P = VRFW.player_pages
    return P ~= nil and P.slots() or {}
  end
  function G.slot(ptype)
    local P = VRFW.player_pages
    return P ~= nil and P.slot_of_type(ptype) or nil
  end
  -- the row's shift right when only `used` of the G.DOTS_MAX slots carry a dot (the row stays centred)
  function G.dot_shift(used)
    return (G.DOTS_MAX - math.min(used, G.DOTS_MAX)) * G.DOT_PITCH / 2
  end

  -- Places the 6 dot meshes and the two key glyphs of a status base copy (instance 0 of `status`) at the row's places.
  function G.dot_place(status, shift)
    for i = 1, 6 do
      local x = G.DOT_X[1] - (7 - i) * G.DOT_PITCH - 1358 + shift
      Cmd(C.NODE_POS, status, 0, G.DOT_OFF[i], 0, x)
      Cmd(C.NODE_POS, status, 0, G.DOT_ON[i], 0, x)
    end
    Cmd(C.NODE_POS, status, 0, G.KEY_NODES[1], 0, G.KEY_X[1] + shift)
    Cmd(C.NODE_POS, status, 0, G.KEY_NODES[2], 0, G.KEY_X[2] - shift)
  end

  function G.dots()
    if not On() or G.ptype == nil or not Exists(G.STATUS) then
      return
    end
    local lit = G.slot(G.ptype)
    local pages = G.slot_pages()
    for i = 1, 6 do
      local on = pages[i] ~= nil
      Cmd(C.MESH, G.STATUS, G.DOT_OFF[i], on, 0)
      Cmd(C.MESH, G.STATUS, G.DOT_ON[i], on and lit == i, 0)
    end
    -- Centres the row on the slots this page has.
    local used = 1
    for s in pairs(pages) do
      if type(s) == "number" and s > used then
        used = s
      end
    end
    local shift = G.dot_shift(used)
    local up = Cmd(C.IS_VIS, G.STATUS, 0) == true
    if not up then
      G.dotShift = nil                     -- a status base shown again starts from its layout
    elseif G.dotShift ~= shift then
      G.dotShift = shift
      G.dot_place(G.STATUS, shift)
      for k = 0, 1 do
        if Exists(G.DOTS) and G.ready[G.DOTS * 16 + k] and Cmd(C.IS_OPEN, G.DOTS, k) == true then
          Cmd(C.POS, G.DOTS, G.DOT_X[k + 1] + shift - 1362 - 1358, 540 + 34, 0, k)
        end
      end
    end
    if not Exists(G.DOTS) then
      return
    end
    local psub = up and G.ptype == 2 and not G.in_office()
    for k = 2, 5 do
      if not psub then
        if Cmd(C.IS_OPEN, G.DOTS, k) == true then
          Cmd(C.VIS, G.DOTS, k, false)
        end
      elseif Ready(G.DOTS, k) then
        if not G.ready[G.DOTS * 16 + k] then
          G.ready[G.DOTS * 16 + k] = true
          Cmd(C.TRACE, G.STATUS, 0, G.DOT_TRACE[k], true)
          for _, n in ipairs(G.DOTS_LOCS) do
            Cmd(C.NODE_VIS, G.DOTS, n, false, k)
          end
          for _, m in ipairs(G.DOTS_HIDE) do
            Cmd(C.MESH, G.DOTS, m, false, k)
          end
          Cmd(C.TEXT_VIS, G.DOTS, 355816102, false, k)
          local x = k == 5 and G.PSUB_KEY_X or G.PSUB_DOT_X[k]
          Cmd(C.POS, G.DOTS, x - 1362 - 1358, 540 + 34, 0, k)
          Cmd(C.TEXT_VIS, G.DOTS, G.N_BTN_R, false, k)   -- the glyph is G.hint's text node
        end
        local dot = k ~= 5 and k - 2 < G.PSUB_N
        Cmd(C.MESH, G.DOTS, G.M_DOT_OFF1, dot, k)
        Cmd(C.MESH, G.DOTS, G.M_DOT_ON1, dot and (G.psub or 0) == k - 2, k)
        Cmd(C.VIS, G.DOTS, k, dot)
      end
    end
    for k = 0, 1 do
      if not up then
        if Cmd(C.IS_OPEN, G.DOTS, k) == true then
          Cmd(C.VIS, G.DOTS, k, false)
        end
      elseif Ready(G.DOTS, k) then
        if not G.ready[G.DOTS * 16 + k] then
          G.ready[G.DOTS * 16 + k] = true
          Cmd(C.TRACE, G.STATUS, 0, G.DOT_TRACE[k], true)
          for _, n in ipairs(G.DOTS_LOCS) do
            Cmd(C.NODE_VIS, G.DOTS, n, false, k)
          end
          for _, m in ipairs(G.DOTS_HIDE) do
            Cmd(C.MESH, G.DOTS, m, false, k)
          end
          Cmd(C.TEXT_VIS, G.DOTS, 355816102, false, k)
          Cmd(C.TEXT_VIS, G.DOTS, 59628764, false, k)
          -- Places the copy's _page01_off at copy-local (1362, -949) from the status base root.
          Cmd(C.POS, G.DOTS, G.DOT_X[k + 1] + shift - 1362 - 1358, 540 + 34, 0, k)   -- y 915
        end
        Cmd(C.MESH, G.DOTS, G.M_DOT_OFF1, true, k)
        Cmd(C.MESH, G.DOTS, G.M_DOT_ON1, lit == k + 7, k)
        Cmd(C.VIS, G.DOTS, k, pages[k + 7] ~= nil)
      end
    end
  end

  -- Universe mode (a temp chara of the office or album) shows the full player page.
  function G.view_mode()
    if CharacterReforged.PLAYER_PAGE_HOST == nil or CharacterReforged.PLAYER_PAGE_HOST.universe ~= true then
      return false
    end
    local ok, v = pcall(IsUniverseCharaMode)
    return ok and v == true
  end
  function G.in_office()
    if type(funcLuaCommand) ~= "function" or G.view_mode() then
      return false
    end
    local ok, v = pcall(funcLuaCommand, @crc:CMND_IS_EXIST_MENU@, G.SHOP_MENU)   -- CMND_IS_EXIST_MENU
    return ok and v == true
  end

  -- the archetype icon's slanted box
  function G.tag()
    if not Exists(G.TAG) or not Exists(G.PAGE) or type(VRFW.ui_plates) ~= "table" then
      return
    end
    local up = Cmd(C.IS_VIS, G.PAGE, 0) == true and Cmd(C.IS_OPEN, G.PAGE, 0) == true
    if not up then
      if Cmd(C.IS_OPEN, G.TAG, 0) == true then
        Cmd(C.VIS, G.TAG, 0, false)
      end
      return
    end
    if not Ready(G.TAG, 0) then
      return
    end
    if not G.ready[G.TAG * 16] then
      G.ready[G.TAG * 16] = true
      G.tagSt = {}
      Cmd(C.TRACE, G.PAGE, 0, G.TAG, true)
      VRFW.ui_plates.header_row.arch_box_setup(G.TAG, {sprite = G.SP_SLANTBOX, atlas = G.TX_OWN})
    end
    -- The slanted box is the archetype glyph's backdrop, shown while the header shows the glyph.
    VRFW.ui_plates.header_row.arch_box(G.TAG, G.PLATE, 0, G.hdl, G.tagSt or {}, {sprite = G.SP_SLANTBOX, atlas = G.TX_OWN,
      sprite_dual = G.SP_SLANTBOX2, dual_cmd = type(BetterQoL) == "table" and type(BetterQoL.passive_icons) == "table" and BetterQoL.passive_icons.CMD_INFO or nil})
  end
