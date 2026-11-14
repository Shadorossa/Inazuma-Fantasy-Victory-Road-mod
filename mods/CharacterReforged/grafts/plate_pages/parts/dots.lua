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

  -- The player's type tag: one icon per archetype tag of his character (CMND_VRFW_CHARACTER_TAGS, the icon sprite of
  -- each [[VRFW.Tag]], in declared order) on one slanted box right of the header's rarity title, vertically centred on
  -- the title, at a fixed place (also without a title); no icon = hidden. Box = gauge copy cr_pp_ttag showing
  -- cr_pp_typetag<n> (n = icon count); icons = the gauge copy instances cr_pp_ticon 0..G.TT_BOX.max - 1. The icons are
  -- read when the shown player changes (G.type_tag_fill from the header fill); the step follows the page's visibility.
  G.TTAG, G.TICON = @crc:cr_pp_ttag@, @crc:cr_pp_ticon@
  G.TICON_TRACE = {[0] = @crc:cr_pp_ticon0@, @crc:cr_pp_ticon1@, @crc:cr_pp_ticon2@}
  G.SP_TYPETAG = {@crc:cr_pp_typetag1@, @crc:cr_pp_typetag2@, @crc:cr_pp_typetag3@}
  G.TT_BOX = {h = 21, icon = 17, gap = 4, pad = 9, slant = 0.3226, k = 4, shadow = 3, max = 3}
  G.TT_RECT = {1520, 143, 175, 28}           -- the header's rarity title rect (player_header.toml _player_rarity01)
  G.TT_CENTRE = 0.4805                       -- the title's visible rows' centre (icon_rarity rows 9..114 of 128)
  G.TT_X = 1688                              -- the box's left corner: 5 px right of the title band's bottom-right end
  G.CMD_TAGS = @crc:CMND_VRFW_CHARACTER_TAGS@
  G.CMD_TAG_SCALE = @crc:CMND_CHARACTERREFORGED_TYPE_TAG_SCALE@

  -- The size factor of the whole type tag (config.toml [player_page] type_tag_scale), kept once answered; 1 while the
  -- command does not answer. The tag grows from its bottom-left corner, so it keeps sitting on the header plate.
  function G.type_tag_scale()
    if G.ttScale == nil then
      local ok, v = pcall(funcLuaCommand, G.CMD_TAG_SCALE)
      if ok and type(v) == "number" and v > 0 then
        G.ttScale = v
      else
        return 1
      end
    end
    return G.ttScale
  end

  -- Lays gauge copy instance i of layer L over the screen rect (left, top, w, h) showing sprite sp of team11_01.
  function G.type_tag_place(L, i, sp, left, top, w, h)
    local sx, sy = w / 476, h / 44
    Cmd(C.SPRITE, L, G.TX_T1101, sp, G.SP_FRAME, 0, i)
    Cmd(C.SCALE, L, sx, sy, 1, i)
    Cmd(C.POS, L, left - 94 * sx, -top + 816 * sy, 0, i)
  end

  function G.type_tag_hide()
    if Exists(G.TTAG) and Cmd(C.IS_OPEN, G.TTAG, 0) == true then
      Cmd(C.VIS, G.TTAG, 0, false)
    end
    if Exists(G.TICON) then
      for i = 0, G.TT_BOX.max - 1 do
        if Cmd(C.IS_OPEN, G.TICON, i) == true then
          Cmd(C.VIS, G.TICON, i, false)
        end
      end
    end
  end

  -- The shown player changed: the sprite hashes of his tag icons (empty = none).
  function G.type_tag_fill(hdl)
    local icons = {}
    if type(hdl) == "number" and hdl ~= 0 then
      local r = table.pack(pcall(funcLuaCommand, G.CMD_TAGS, hdl))
      if r[1] and type(r[2]) == "number" then
        for k = 1, r[2] do
          local sprite = r[2 + 2 * k]
          if type(sprite) == "string" and sprite ~= "" and #icons < G.TT_BOX.max then
            icons[#icons + 1] = VRFW.crc32(sprite)
          end
        end
      end
    end
    local key = table.concat(icons, ",")
    if G.ttKey ~= key then
      G.ttKey, G.ttIcons, G.ttShown = key, icons, nil
    end
  end

  function G.type_tag()
    local L, I = G.TTAG, G.TICON
    if not On() or not Exists(L) or not Exists(I) or not Exists(G.PAGE) then
      return
    end
    local up = Cmd(C.IS_VIS, G.PAGE, 0) == true and Cmd(C.IS_OPEN, G.PAGE, 0) == true
    local icons = G.ttIcons or {}
    if not up or #icons == 0 or G.in_office() then
      G.type_tag_hide()
      return
    end
    if not Ready(L, 0) then
      return
    end
    for i = 0, #icons - 1 do
      if not Ready(I, i) then
        return
      end
    end
    if not G.ready[L * 16] then
      G.ready[L * 16] = true
      Cmd(C.TRACE, G.PAGE, 0, L, true)
      for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
        Cmd(C.MESH, L, m, false, 0)
      end
    end
    for i = 0, G.TT_BOX.max - 1 do
      if not G.ready[I * 16 + i] and Cmd(C.IS_OPEN, I, i) == true then
        G.ready[I * 16 + i] = true
        Cmd(C.TRACE, G.PAGE, 0, G.TICON_TRACE[i], true)
        for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
          Cmd(C.MESH, I, m, false, i)
        end
      end
    end
    if G.ttShown ~= G.ttKey then
      G.ttShown = G.ttKey
      -- the box: its image covers the band plus its shadow (image sides rounded up to multiples of 4 px); every length
      -- is scaled about the box's bottom-left corner (G.TT_X, the bottom of the unscaled box)
      local b, n, sc = G.TT_BOX, #icons, G.type_tag_scale()
      local run = b.slant * b.h
      local bw = 2 * b.pad + run + n * b.icon + (n - 1) * b.gap
      local iw = math.ceil((bw + b.shadow) * b.k / 4) * 4 / b.k
      local ih = math.ceil((b.h + 1) * b.k / 4) * 4 / b.k
      local cy = G.TT_RECT[2] + G.TT_CENTRE * G.TT_RECT[4]
      local bottom = cy + b.h / 2
      G.type_tag_place(L, 0, G.SP_TYPETAG[n], G.TT_X, bottom - b.h * sc, iw * sc, ih * sc)
      for i = 0, b.max - 1 do
        if i < n then
          local x = G.TT_X + (b.pad + run / 2 + i * (b.icon + b.gap)) * sc
          G.type_tag_place(I, i, icons[i + 1], x, bottom - (b.h + b.icon) / 2 * sc, b.icon * sc, b.icon * sc)
        elseif Cmd(C.IS_OPEN, I, i) == true then
          Cmd(C.VIS, I, i, false)
        end
      end
    end
    Cmd(C.VIS, L, 0, true)
    for i = 0, #icons - 1 do
      Cmd(C.VIS, I, i, true)
    end
  end
