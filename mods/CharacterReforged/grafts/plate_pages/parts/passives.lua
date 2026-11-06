-- Player page block (plate_pages.lua): the Pasivas page, its sub-pages and the custom-passive panel
  -- ---- Pasivas (round 9): a row of 5 icon tiles (layout: icons at x 1172..1732, y 880); each strip collapsed to its
  -- icon on its own plate (orange special / blue, passive_config's tint) squashed into a slanted tile; R3 = cursor
  -- mode (left / right, R3 or B leaves): the focused passive opens as its whole strip ABOVE the row (y 770)
  G.PR = 811691761                       -- soccer11_20_formation_team_passive
  G.PR_PLATE, G.PR_OL = 3143733656, {2061463723, 3822461201}   -- _passive_base01, _ol01 / _ol02
  G.PR_TEXT = 1868134834                 -- _text_passive01
  G.PR_NODES = {3453619769, 2497436533}            -- _pos_type01, _pos_position01 (round 10: _pos_build01 never:
  -- its two retail build icons are the white boxes)
  G.PR_BUILD, G.PR_ICONBASE = 3448691050, 3877027080                -- _pos_build01, _teambuff_base01
  G.PT = @crc:evt_pp_ptile@
  G.PT_TRACE = {[0] = @crc:evt_pp_ptile0@, @crc:evt_pp_ptile1@, @crc:evt_pp_ptile2@, @crc:evt_pp_ptile3@, @crc:evt_pp_ptile4@}
  G.PT_SPRITE = {[0] = @crc:evt_pp_tile_orange@, @crc:evt_pp_tile_grey@, @crc:evt_pp_tile_grey@, @crc:evt_pp_tile_blue@,
    @crc:evt_pp_tile_blue@}                  -- special orange, general grey, archetype blue
  G.PT_W, G.PT_H = 90, 54               -- round 12: small tiles (if_plate_row_build.py TILE_TOP 48 + slant 42, 54 high)
  G.PT_SPRITE_HL = {[0] = @crc:evt_pp_tile_orange_hl@, @crc:evt_pp_tile_grey_hl@, @crc:evt_pp_tile_grey_hl@,
    @crc:evt_pp_tile_blue_hl@, @crc:evt_pp_tile_blue_hl@}    -- the focused passive's tile (white rim)
  G.ptHl = {}
  G.PR_EF = @crc:_build_ef01@                 -- _build_ef01 (a build effect quad over the icon)
  G.PR_INHERIT = 27565530
  G.PR_TILE = {-371, 40, 96, 80}         -- collapsed plate node (x, y top, w, h; layer units, icon centre -323, 0)
  G.PR_FULL = {-414, 46, 828, 92}
  G.PR_TEXT_BOX = {622, 72}              -- the text node's retail box (width, height; left edge -243)
  G.PR_TAB_Y = 770
  G.pcur = G.pcur or nil                 -- focused passive (cursor mode) or nil
  G.pexit = 0
  G.PARENTS = {935586083, 2049316981, 937147172}   -- team_dock_formation_menu, soccer_formation_menu, soccer_team_dock
  function G.ParentCursor(on)
    for _, m in ipairs(G.PARENTS) do
      pcall(funcLuaCommand, 830228314, m, "EVT_PPG_SetCursor", on)
    end
  end

  -- the slanted tile behind passive i's icon (screen: centred on the icon at (1172 + 140 i, 880))
  function G.Tile(i, on, hl)
    if not Exists(G.PT) then
      return
    end
    if not on then
      if Cmd(C.IS_OPEN, G.PT, i) == true then
        Cmd(C.VIS, G.PT, i, false)
      end
      return
    end
    if not Ready(G.PT, i) then
      return
    end
    if not G.ready[G.PT * 16 + i] then
      G.ready[G.PT * 16 + i] = true
      Cmd(C.TRACE, G.PAGE, 0, G.PT_TRACE[i], true)
      for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
        Cmd(C.MESH, G.PT, m, false, i)
      end
      G.ptHl[i] = false
      Cmd(C.SPRITE, G.PT, G.TX_OWN, G.PT_SPRITE[i], G.SP_FRAME, 0, i)
      local sx, sy = G.PT_W / 476, G.PT_H / 44
      local x, y = 1172 + 140 * i - G.PT_W / 2, 880 - G.PT_H / 2
      Cmd(C.SCALE, G.PT, sx, sy, 1, i)
      Cmd(C.POS, G.PT, x - 94 * sx, -y + 816 * sy, 0, i)
    end
    if G.ptHl[i] ~= (hl == true) then
      G.ptHl[i] = hl == true
      Cmd(C.SPRITE, G.PT, G.TX_OWN, hl and G.PT_SPRITE_HL[i] or G.PT_SPRITE[i], G.SP_FRAME, 0, i)
    end
    Cmd(C.VIS, G.PT, i, true)
  end

  -- ---- Pasivas in 2 sub-pages, R3 (CMD_FUNC6) = next sub-page (1 -> 2 -> 1):
  --   1 = the first three passives (slots 0, 1, 2), 2 = the two archetype ones (slots 3, 4).
  -- Each sub-page shows its passives as WHOLE strips (icon, name, description = the detail) centred in the card, one
  -- under the other; the other strips hidden. Three strips are drawn smaller (G.PSUB_SCALE, around each strip's
  -- centre) so they fit the card. Kept: the passive's own icon always, no white boxes (_pos_type01 /
  -- _pos_position01 / _pos_build01 / _build_ef01 hidden).
  G.PSUB = {[0] = {0, 1, 2}, {3, 4}}
  G.PSUB_N = 2                                       -- sub-page count (dots, R3 / click cycle)
  G.PSUB_Y = {[1] = {815}, [2] = {770, 862}, [3] = {742, 808, 874}}   -- strip centre rows (screen y) per strip count
  G.PSUB_SCALE = {[3] = 0.7}                         -- strip scale per strip count (default 1)
  G.PSUB_WIDE = {[3] = 790}                          -- strip screen width per strip count (default: the plate's own
                                                     -- width x scale): three strips are wide so each text fits one line
  G.PSUB_X = 1452                                    -- strip centre (screen x)
  G.PSUB_KEYS = {[0] = @crc:evt_pp_psub_2@, @crc:evt_pp_psub_3@}
  G.SP_TILE_EMPTY = @crc:evt_pp_tile_empty@
  G.EMPTY_BOX = {600, 66}                            -- the empty special's box (screen px)
  G.psub = G.psub or 0
  if G.psub >= G.PSUB_N then
    G.psub = 0
  end
  -- the sub-page key's rule, one place for its callers (RS on a pad, N on a keyboard = CMD_FUNC6, a click on its
  -- glyph, the configurator session UTIL_PPC.NextSubPageRow): the sub-page after the shown one
  function G.NextPassiveSubPage()
    return (G.psub + 1) % G.PSUB_N
  end
  -- sub-page n on the player page, with the key's sound (a session's page follows its focused row instead)
  function G.ShowPassiveSubPage(n)
    G.psub = n
    G.plast = G.ptick or 0
    pcall(funcLuaCommand, @crc:CMND_SND_PLAY_SE@, 2500047763)
  end
  G.noSpecial = false
  -- round 13 (Nacho): the special passive's title («Limitador activo», CMND_BETTERQOL_PC_SPECIAL's text key) on a pill
  -- (layer evt_pp_ptitle, object evt_ph_peg_pill) centred over the special's strip on sub-page 1, tinted the special
  -- orange; no special (the empty box) = no title. Page frame: local (x, -y) = screen (x, y) (pill centred on origin).
  G.PTITLE = @crc:evt_pp_ptitle@
  -- round 14 (Nacho: a title with a line under it, not a pill): the pill mesh hidden, the text in the special's
  -- dark orange, its box's left edge on the strip's left edge (G.PTITLE_X), a thin orange rule (gauge copy
  -- evt_pp_ptrule) the strip's width under it; the text from menu_text evt_pp_<title key> (per language: the loader's
  -- own text command answered English), the loader's text as the fallback
  G.PTITLE_K, G.PTITLE_DY = 0.8, 66          -- text scale; its centre this far above the strip's centre
  G.PTITLE_X = 1038                          -- the strip's left edge (screen x); the text box (330 x 0.8) starts here
  G.PTITLE_BOX = 330 * 0.8
  G.PTITLE_RGB = {0.80, 0.30, 0.04}
  G.PTRULE, G.SP_PTRULE = @crc:evt_pp_ptrule@, @crc:evt_pp_ptrule@
  G.PTRULE_R = {1038, 772, 1866, 775}        -- the rule's screen rect (3 px, over the strip's top)
  G.CMD_SPECIAL, G.CMD_TEXT = @crc:CMND_BETTERQOL_PC_SPECIAL@, @crc:CMND_VRFW_TEXT_GET@

  -- how far the slot-0 strip's top sits below a lone strip's top on sub-page 1 (title and rule move with it)
  function G.PTitleDy()
    local n = #G.PSUB[0]
    local k = G.PSUB_SCALE[n] or 1
    return (G.PSUB_Y[n][1] - 46 * k) - (G.PSUB_Y[1][1] - 46)
  end

  -- the passive display table a module hands to the pages (CharacterReforged.Parts.PassiveDisplay), nil = none
  function G.PassiveDisplay()
    local parts = type(CharacterReforged) == "table" and CharacterReforged.Parts or nil
    return type(parts) == "table" and parts.PassiveDisplay or nil
  end

  function G.PTitle(on)
    local T = G.PTITLE
    if not Exists(T) then
      return
    end
    local text = ""
    if on and G.hdl ~= nil then
      local ok, yes, key = pcall(funcLuaCommand, G.CMD_SPECIAL, G.hdl)
      if ok and yes == true and type(key) == "string" and key ~= "" then
        local id = "evt_pp_" .. string.gsub(key, "^inazuma_fantasy%.", "")   -- legacy keys under the former id
        local okm, tm = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@, CALC_CRC(id))
        if okm and type(tm) == "string" and tm ~= "" then
          text = tm
        else
          local okt, t = pcall(funcLuaCommand, G.CMD_TEXT, key)
          text = (okt and type(t) == "string") and t or ""
        end
      end
    end
    if text == "" then
      if Cmd(C.IS_OPEN, T, 0) == true then
        Cmd(C.VIS, T, 0, false)
      end
      if Exists(G.PTRULE) and Cmd(C.IS_OPEN, G.PTRULE, 0) == true then
        Cmd(C.VIS, G.PTRULE, 0, false)
      end
      G.ptitleText = nil
      return
    end
    if Exists(G.PTRULE) and Ready(G.PTRULE, 0) then
      local l = G.PTRULE
      if not G.ready[l * 16] then
        G.ready[l * 16] = true
        Cmd(C.TRACE, G.PAGE, 0, l, true)
        for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
          Cmd(C.MESH, l, m, false, 0)
        end
        Cmd(C.SPRITE, l, G.TX_OWN, G.SP_PTRULE, G.SP_FRAME, 0, 0)
      end
      local r, dy = G.PTRULE_R, G.PTitleDy()
      local sx, sy = (r[3] - r[1]) / 476, (r[4] - r[2]) / 44
      Cmd(C.SCALE, l, sx, sy, 1, 0)
      Cmd(C.POS, l, r[1] - 94 * sx, -(r[2] + dy) + 816 * sy, 0, 0)
      Cmd(C.VIS, l, 0, true)
    end
    if not Ready(T, 0) then
      return
    end
    if not G.ready[T * 16] then
      G.ready[T * 16] = true
      Cmd(C.TRACE, G.PAGE, 0, T, true)
      Cmd(C.SCALE, T, G.PTITLE_K, G.PTITLE_K, 1, 0)
      Cmd(C.MESH, T, 3516146179 --[[_area_base01: the pill]], false, 0)
      pcall(funcLuaMenuCommand, @crc:CMND_SET_PRIM_COLOR@, T, 0, 1899787537 --[[_text_area01]],
        G.PTITLE_RGB[1], G.PTITLE_RGB[2], G.PTITLE_RGB[3])
    end
    Cmd(C.POS, T, G.PTITLE_X + G.PTITLE_BOX / 2, -(G.PSUB_Y[1][1] + G.PTitleDy() - G.PTITLE_DY), 0, 0)
    if G.ptitleText ~= text then
      G.ptitleText = text
      -- round 14g (in game: white on the card): red through the game's own text markup [CR] … [C]
      -- (font_color.cfg.bin colour «R»: the colour of the descriptions' negative values)
      Cmd(C.SET_TEXT, T, 1899787537 --[[_text_area01]], "[CR]" .. text .. "[C]", 0)
      Cmd(2735666188 --[[text visible]], T, 1899787537, true, 0)
    end
    Cmd(C.VIS, T, 0, true)
  end

  -- the empty special passive's box (tile layer instance 0, light orange), centred where its strip would be
  function G.EmptyBox(on)
    if not Exists(G.PT) then
      return
    end
    if not on then
      if G.emptyOn then
        G.emptyOn = false
        if Cmd(C.IS_OPEN, G.PT, 0) == true then
          Cmd(C.VIS, G.PT, 0, false)
        end
      end
      return
    end
    if not Ready(G.PT, 0) then
      return
    end
    if not G.emptyOn then
      G.emptyOn = true
      Cmd(C.TRACE, G.PAGE, 0, G.PT_TRACE[0], true)
      for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
        Cmd(C.MESH, G.PT, m, false, 0)
      end
      Cmd(C.SPRITE, G.PT, G.TX_OWN, G.SP_TILE_EMPTY, G.SP_FRAME, 0, 0)
      local w, h = G.EMPTY_BOX[1], G.EMPTY_BOX[2]
      local sx, sy = w / 476, h / 44
      local x, y = G.PSUB_X - w / 2, G.PSUB_Y[1][1] - h / 2
      Cmd(C.SCALE, G.PT, sx, sy, 1, 0)
      Cmd(C.POS, G.PT, x - 94 * sx, -y + 816 * sy, 0, 0)
    end
    Cmd(C.VIS, G.PT, 0, true)
  end

  -- the strips' slanted plate (_passive_base01) pre-coloured by kind: the archetype passives (slots 3 / 4) light blue,
  -- every other one the retail white.
  -- CMND_SET_PRIM_COLOR never tints this quad, so the colour is in the pixels: sprite evt_pp_card_blue of the
  -- retail atlas soccer11_20, made at boot from the retail passive_base01 (content/images/menu/00_soccer/soccer11/
  -- evt_passive_plates.toml, no Level-5 pixel ships), swapped into the plate's texture slot (the sprite the retail row
  -- drawer put there) of each open instance every frame the page shows the rows; the retail sprite back when it leaves.
  G.CARD_TEX, G.CARD_SLOT = 4021797290 --[[soccer11_20.g4tx]], 1729678359 --[[passive_base01]]
  G.CARD_SPR = {[3] = @crc:evt_pp_card_blue@, [4] = @crc:evt_pp_card_blue@}
  G.cardOn = G.cardOn or {}
  function G.CardTint(L, i, on)
    local spr = on and G.CARD_SPR[i] or nil
    if spr ~= nil then
      G.cardOn[L * 16 + i] = true
      pcall(funcLuaMenuCommand, C.SPRITE, L, G.CARD_TEX, spr, G.CARD_SLOT, 0, i)
    elseif G.cardOn[L * 16 + i] then
      G.cardOn[L * 16 + i] = nil
      pcall(funcLuaMenuCommand, C.SPRITE, L, G.CARD_TEX, G.CARD_SLOT, G.CARD_SLOT, 0, i)
    end
  end

  -- no player focused (empty slot, G.Empty): the 5 passive rows, the special's title and rule hidden with the rest of
  -- the page; the layout and the sub-page are kept, so the rows come back on the same sub-page when a player is focused
  function G.PassiveRowsHide()
    local L = G.PR
    if Exists(L) then
      for i = 0, 4 do
        if Cmd(C.IS_OPEN, L, i) == true then
          Cmd(C.VIS, L, i, false)
        end
      end
    end
    G.EmptyBox(false)
    pcall(G.PTitle, false)
  end

  -- the passive strips of a soccer11_20 row layer whose instances 0..4 hang on the page's tile locators
  -- (_atc_passive01..05): the passives in `slots` as whole strips centred in the card, one under the other, the others
  -- hidden; sess = the configurator's focused row (its frame kept) or nil; noSpecial = slot 0 unfilled (no text).
  -- The player page's Pasivas and the skill table's set preview (graft pset_preview) draw the same strips
  function G.PassiveStrips(L, slots, sess, noSpecial)
    local shown = {}
    for _, i in ipairs(slots) do
      shown[#shown + 1] = i
    end
    local rows = G.PSUB_Y[math.max(1, #shown)]
    local scale = G.PSUB_SCALE[#shown] or 1
    local row = {}
    for n, i in ipairs(shown) do
      row[i] = rows[n]
    end
    for i = 0, 4 do
      if Cmd(C.IS_OPEN, L, i) == true then
        G.CardTint(L, i, true)
        local y = row[i]
        if y == nil then
          Cmd(C.VIS, L, i, false)
          if i == 0 then                   -- round 14: nothing of the special's strip under the empty box (a thin
            Cmd(C.MESH, L, G.PR_PLATE, false, i)   -- grey line showed at its bottom-left)
            Cmd(C.MESH, L, G.PR_ICONBASE, false, i)
            Cmd(C.MESH, L, G.PR_INHERIT, false, i)
            for _, m in ipairs(G.PR_OL) do
              Cmd(C.MESH, L, m, false, i)
            end
          end
        else
          local f = G.PR_FULL
          Cmd(C.NODE_POS, L, i, G.PR_PLATE, 0, f[1])
          Cmd(C.NODE_POS, L, i, G.PR_PLATE, 1, f[2])
          local wide = G.PSUB_WIDE[#shown]                -- widened strip: the plate and the text box grow to the
          local plateW = wide and wide / scale or f[3]    -- right of the icon (layout units), the layer shifts to re-centre
          Cmd(C.NODE_SCALE, L, i, G.PR_PLATE, plateW, f[4])
          Cmd(C.NODE_SCALE, L, i, G.PR_TEXT, G.PR_TEXT_BOX[1] + plateW - f[3], G.PR_TEXT_BOX[2])
          Cmd(C.MESH, L, G.PR_PLATE, true, i)
          Cmd(C.MESH, L, G.PR_ICONBASE, true, i)      -- round 12: the icon always
          Cmd(C.MESH, L, G.PR_EF, false, i)
          Cmd(C.NODE_VIS, L, G.PR_BUILD, false, i)
          for _, m in ipairs(G.PR_OL) do
            Cmd(C.MESH, L, m, i == sess and m == G.PR_OL[1], i)
          end
          Cmd(C.MESH, L, G.PR_INHERIT, false, i)
          Cmd(C.NODE_VIS, L, G.PR_TEXT, true, i)
          Cmd(C.TEXT_VIS, L, G.PR_TEXT, true, i)
          for _, n in ipairs(G.PR_NODES) do
            Cmd(C.NODE_VIS, L, n, false, i)              -- round 12: the white boxes
          end
          local ax = 1172 + 140 * i + 323                -- the strip's attach x (layout PASSIVE_X)
          Cmd(C.SCALE, L, scale, scale, 1, i)            -- around the attach point = the strip's centre
          local shiftX = (plateW - f[3]) / 2 * scale     -- the strip grows to the right: move it back to the centre
          Cmd(C.POS, L, G.PSUB_X - ax - shiftX, 880 - y, 0, i)
          Cmd(C.VIS, L, i, true)
        end
      end
    end
    if noSpecial and Cmd(C.IS_OPEN, L, 0) == true then        -- the unfilled slot: no text on it
      Cmd(C.TEXT_VIS, L, G.PR_TEXT, false, 0)
    end
  end

  -- the retail rows back (plate, text box, nodes, place) on every open instance of L
  function G.PassiveStripsOff(L)
    for i = 0, 4 do
      if Cmd(C.IS_OPEN, L, i) == true then
        G.CardTint(L, i, false)
        local f = G.PR_FULL
        Cmd(C.NODE_POS, L, i, G.PR_PLATE, 0, f[1])
        Cmd(C.NODE_POS, L, i, G.PR_PLATE, 1, f[2])
        Cmd(C.NODE_SCALE, L, i, G.PR_PLATE, f[3], f[4])
        Cmd(C.NODE_SCALE, L, i, G.PR_TEXT, G.PR_TEXT_BOX[1], G.PR_TEXT_BOX[2])
        Cmd(C.MESH, L, G.PR_PLATE, true, i)
        Cmd(C.SCALE, L, 1, 1, 1, i)
        Cmd(C.POS, L, 0, 0, 0, i)
        Cmd(C.NODE_VIS, L, G.PR_TEXT, true, i)
        Cmd(C.TEXT_VIS, L, G.PR_TEXT, true, i)
        for _, n in ipairs(G.PR_NODES) do
          Cmd(C.NODE_VIS, L, n, true, i)
        end
      end
    end
  end

  function G.PassiveRows()
    local L = G.PR
    if not Exists(L) then
      return
    end
    if G.emptyHidden then
      return                               -- no player focused: hidden by G.Empty until one is
    end
    local mine = On() and G.ptype == 2 and not G.InOffice()
    if not mine then
      if G.pcur ~= nil then
        G.pcur = nil
        G.ParentCursor(false)
      end
      G.EmptyBox(false)
      pcall(G.PTitle, false)
      if G.prOn then
        G.prOn = false
        G.PassiveStripsOff(L)
      end
      return
    end
    G.prOn = true
    -- 2026-10-12 (owner, Utilities' passive configurator on this page: no blue frame on the selected passive, and the
    -- selected one could be on a hidden sub-page): while its session runs (UTIL_PPC.co, the focused row UTIL_PPC.slot)
    -- the sub-page is the one holding the focused row (the session's up / down walk all 5 rows and its RS / N moves
    -- the focus to the next sub-page: UTIL_PPC.NextSubPageRow; the sub-page follows), and the row's focus frame (_passive_base01_ol01, drawn by UTIL_PPC.Mark) is never hidden
    -- here: it is shown on that row every frame. Outside a session nothing changes.
    local sess = nil
    if type(UTIL_PPC) == "table" and UTIL_PPC.co ~= nil and type(UTIL_PPC.slot) == "number" and UTIL_PPC.slot >= 0 then
      sess = UTIL_PPC.slot
      local want = sess <= 2 and 0 or 1
      if G.psub ~= want then
        G.psub = want
      end
    end
    G.PassiveStrips(L, G.PSUB[G.psub], sess, G.noSpecial)
    G.EmptyBox(false)
    pcall(G.PTitle, G.psub == 0 and not G.noSpecial)
    -- R3: the next sub-page
    local key = function(cmd)
      local ok1, a = pcall(funcLuaCommand, @crc:CMND_CHECK_INPUT_CMD@, 1332654303, cmd)
      local ok2, b = pcall(funcLuaCommand, @crc:CMND_CHECK_INPUT_CMD@, 2748927068, cmd)
      return (ok1 and a == true) or (ok2 and b == true)
    end
    G.ptick = (G.ptick or 0) + 1
    if G.ptick - (G.plast or -100) < 6 then
      return
    end
    if sess == nil and key(3147328756) then   -- CMD_FUNC6 (R3); in a session the session reads it (its focused row)
      G.ShowPassiveSubPage(G.NextPassiveSubPage())
    end
  end

  -- ---- the six-sense page's blue band and light plate (a custom passive item that is no own passive) ---------------
  -- A blue slanted title band over a light blue slanted description plate, sprites evt_pp_sxbar / evt_pp_sxplate of
  -- the atlas evt_cr_page (if_plate_row_build.py SX_BAND / SX_PLATE), drawn by G.Sixth under the retail panel.
  G.CARD = {band_sprite = @crc:evt_pp_sxbar@, plate_sprite = @crc:evt_pp_sxplate@, band_w = 860, band_h = 62,
    plate_w = 860, plate_h = 106, plate_dx = 30, gap = 10}

  -- band and plate rects (screen x0, y0, x1, y1; y down) of a card whose band's top-left is (x, y)
  function G.PassiveCardRects(x, y)
    local k = G.CARD
    local py = y + k.band_h + k.gap
    return {x, y, x + k.band_w, y + k.band_h}, {x + k.plate_dx, py, x + k.plate_dx + k.plate_w, py + k.plate_h}
  end

  -- ---- the own passive card: one look for a player's signature passive on every screen ---------------------------
  -- The owner's sketch C (previews/skilltable_passive/sketch_c.png): the player's miniface on a slanted plate with a
  -- blue rim, a band in the colour of his element with the element icon and the passive's name, his team's crest at the
  -- band's right end, the passive's icon on its tile before the description. Drawn on the custom passive window
  -- team00_26_passive_slot_detail_info (object evt_team00_26_passive_slot_detail_info, layout evt_team00_26_detail:
  -- every part's place is a joint of Character Reforged content/menus/skill_table.toml; the card is 935 x 195, its
  -- top-left at the window's local (-275, 210)) on the skill table (ss2_menus PL.PassiveBoard) and on the player
  -- page's custom passive page (G.Sixth); the face on its own layer evt_pp_card_face
  -- (content/menus/passive_card.toml). The player's card, element and crest come from Signature Passives'
  -- CMND_CHARACTERREFORGED_CARD_LOOK, the passive's icon from the passive display's Icon.
  G.PC = {
    LAYER = 1593383077,                                   -- team00_26_passive_slot_detail_info
    FACE = @crc:evt_pp_card_face@,
    LOOK = @crc:CMND_CHARACTERREFORGED_CARD_LOOK@,        -- (charaStHdl) -> card, chara, element, crest
    TOP_LEFT = {-275, 210},                               -- the card's top-left in window units (y up)
    FACE_AT = {84, 104}, FACE_SIZE = 182,                 -- the face quad's centre from that corner (screen px), side:
                                                          -- the bust on the card's bottom edge, the card's full height
    BAND = 1632359140, BAND_SLOT = 3317336303,            -- _orb_base01 / sixth_base01
    BAND_TEX = 2391436690, BAND_SPRITE = "evt_cr_card_band",   -- evt_cr_card.g4tx, + the element (0 = neutral)
    FRAME = 738777627, FRAME_SLOT = 1804582091,           -- _win_base01 / sp_win_base01: the face's plate
    RIM = 572914009, RIM_SLOT = 4267484374,               -- _icon_orb01_off / icon_orb01_off: its rim
    -- the slanted card (evt_cr_card.toml texture evt_cr_card_face): the face of the player's card frame
    -- (evt_cr_card_plate<NN>), the thin rim, the portrait's mask and a transparent cell for its side tint
    PLATE_SPRITE = "evt_cr_card_plate", PLATE_DEFAULT = 1, RIM_SPRITE = @crc:evt_cr_card_rim@,
    FACE_MASK = @crc:evt_cr_card_face_mask@, FACE_CLEAR = @crc:evt_cr_card_clear@,
    FACE_MASK_SLOT = @crc:icon_chr_msk_l01@, FACE_TINT_SLOT = @crc:icon_chr_color01_l01@, FACE_MASK_TRIES = 30,
    RARITY = 1131797651,                                  -- CMND_GET_CHARA (hdl, 12) = the status' rarity
    ELEMENT = 2782988477, ELEMENT_SLOT = 4002291610,      -- _passive_icon_build_dmy01 / passive_icon_build_dmy01
    CREST = 1605611365, CREST_SLOT = 4285917355, CREST_ALPHA = 1.0,   -- _icon_fs_area_dmy01 / icon_fs_area_dmy01
    TILE = 2366589118, TILE_SLOT = 818857611,             -- _passive_sixth_base01 / passive_sixth_base01
    TILE_TEX = 3582673743, TILE_SPRITE = 1971896313,      -- team00_26.g4tx passive_teambuff_base02
    ICON = 2408672862, ICON_SLOT = 1780336175,            -- _passive_teambuff_icon_dmy01 / passive_teambuff_icon_dmy01
    NAME = 1704438437, TEXT = 691026122,                  -- _text_name01, _text_flavor01
    BLANK = 2020757070, PASSIVE = 3387908913,             -- _pos_blank01 (the empty slot's parts), _pos_passive01
    HIDE = {1896097465 --[[_icon_buff_dmy01]], 1021860103 --[[_passive_icon_build_dmy02]]},
    EMBLEM = 3190452549,                                  -- (layer, idx, mesh, slot, item_emblem, 0)
    PRIM_ALPHA = @crc:CMND_SET_PRIM_ALPHA@,               -- (layer, idx, mesh, alpha)
    LOADING = 1277042906,                                 -- (layer, idx) -> true while the instance loads a texture
    ICON_RESET = 4176779611,                              -- (layer, idx, texture slot): the slot back to the object's
                                                          -- own texture (drops a sprite swapped in by a retail fill)
    CREST_SETTLE = 2,                                     -- quiet (not loading) steps before each crest phase ends
    CREST_STEPS = 2000,                                   -- steps a crest may take; past them it stays hidden
    NODE_TEXT_VIS = 2735666188, TEXT_VIS = 1505208242,
    TEXT_STYLE = 2333948100,                              -- (layer, idx, textCrc, styleCrc)
    -- the effect text's fit (G.PassiveCardFitText): the text is one flow re-wrapped into two balanced lines across the
    -- box; width = the box (px, _text_flavor01 in skill_table.toml); min_squeeze = the most the game may squeeze a
    -- line horizontally (1 = never); past it the font shrinks uniformly through `sizes` (largest first: {size, style}).
    -- Every card's description takes one style family: blue ink (readable on the light card; the theme maps the `b`
    -- ink with the card's atlas), centred, squeezed to the box (sclw: never past its right edge); [Cxx] tags colour values
    FIT = {width = 540, min_squeeze = 0.8, base_size = 32, unit_px = 16, style = "fs_28_b_cc_2d0_001_sclw",
      sizes = {{28, "fs_28_b_cc_2d0_001_sclw"}, {22, "fs_22_b_cc_2d0_001_sclw"}}},
    -- a stacking passive's value now («Actual: 12 %», the passive display's Current): its own small text cell
    -- under the description (layer evt_pp_card_current, content/menus/passive_card.toml: the cell's _text_bonus01 in
    -- a 22 px style); the description keeps its place. AT = the line's centre in window units (x right, y up: the
    -- description box _text_flavor01 is x -13..527, y 130..34), CELL_CENTRE = the text's centre in the cell's units
    CURRENT = {LAYER = @crc:evt_pp_card_current@, TEXT = @crc:_text_bonus01@, OTHER = @crc:_text_exp01@,
      AT = {257, 30}, CELL_CENTRE = {0, 30}, OVER_WINDOW = 1},
  }
  G.pcard = G.pcard or nil

  -- the effect text of a card as two balanced lines: the lines are one flow of words (CJK: characters), the leading
  -- «<stat> <value>» (the first original line) stays on line 1, the break is the one minimising the longer line, a colour
  -- tag open at the break is closed and reopened. Returns the text and the style crc to set (nil = the node's own).
  function G.PassiveCardFitText(L, idx, effect)
    local P = G.PC
    local literal = string.find(effect, "\\n", 1, true) ~= nil      -- the rows spell a line break as backslash + n
    local brk = literal and "\\n" or "\n"
    local lines, from = {}, 1
    while true do
      local at = string.find(effect, brk, from, true)
      local part = string.sub(effect, from, at and at - 1 or #effect)
      if part:match("%S") then
        lines[#lines + 1] = part
      end
      if at == nil then break end
      from = at + #brk
    end
    local toks, lead = {}, 0
    for li, line in ipairs(lines) do
      local cur, pos = nil, 1
      local sep = (li > 1 and not line:match("^[\224-\244]")) and " " or ""
      local function Flush()
        if cur ~= nil then
          toks[#toks + 1] = cur
          cur = nil
        end
      end
      while pos <= #line do
        local tag = line:match("^%[C%w*%]", pos)
        local b = line:byte(pos)
        if tag ~= nil then
          if cur == nil then cur, sep = {text = "", sep = sep}, "" end
          cur.text = cur.text .. tag
          pos = pos + #tag
        elseif b == 32 then
          Flush()
          sep = sep .. " "
          pos = pos + 1
        else
          local n = b >= 240 and 4 or b >= 224 and 3 or b >= 192 and 2 or 1
          local ch = line:sub(pos, pos + n - 1)
          if b >= 224 then                         -- CJK: a break may fall after every character
            if cur ~= nil and cur.text:gsub("%[C%w*%]", "") ~= "" then Flush() end
            if cur == nil then cur, sep = {text = "", sep = sep}, "" end
            cur.text = cur.text .. ch
            Flush()
          else
            if cur == nil then cur, sep = {text = "", sep = sep}, "" end
            cur.text = cur.text .. ch
          end
          pos = pos + n
        end
      end
      Flush()
      if li == 1 then lead = #lines > 1 and #toks or 1 end
    end
    if #toks < 2 then
      return effect, nil
    end
    local function Plain(t) return (t:gsub("%[C%w*%]", "")) end
    local function Units(t) return type(VRFW_Text) == "table" and VRFW_Text.Units(Plain(t)) or #Plain(t) end
    local function Build(k)
      local a, b, active = {}, {}, nil
      for i, t in ipairs(toks) do
        local dst = i <= k and a or b
        dst[#dst + 1] = (#dst > 0 and t.sep or "") .. t.text
        if i <= k then
          for tg in t.text:gmatch("%[C%w*%]") do active = tg ~= "[C]" and tg or nil end
        end
      end
      local l1, l2 = table.concat(a), table.concat(b)
      if active ~= nil then l1, l2 = l1 .. "[C]", active .. l2 end
      return l1, l2
    end
    local bestK, bestW = nil, nil
    for k = math.max(1, lead), #toks - 1 do
      local l1, l2 = Build(k)
      local w = math.max(Units(l1), Units(l2))
      if bestW == nil or w < bestW then bestK, bestW = k, w end
    end
    if bestK == nil then return effect, nil end
    local l1, l2 = Build(bestK)
    local F = P.FIT
    local function Wide(t)
      local m = type(VRFW_Text) == "table" and VRFW_Text.Measure(L, idx, P.TEXT, Plain(t)) or nil
      return m or Units(t) * F.unit_px
    end
    local widest = math.max(Wide(l1), Wide(l2))
    local style = nil
    local need = widest > 0 and F.width / widest or 1
    if need < F.min_squeeze then
      for _, sz in ipairs(F.sizes) do
        style = CALC_CRC(sz[2])
        if need * F.base_size / sz[1] >= F.min_squeeze then break end
      end
    end
    return l1 .. brk .. l2, style
  end

  -- the card frame number of player hdl's card: No More Rarities' position look when it applies, else the frame of
  -- his rarity (the retail list card's icon_chr_base01_l<NN>)
  function G.PassiveCardFrame(hdl)
    local P = G.PC
    local NMR = type(CharacterReforged) == "table" and type(CharacterReforged.Parts) == "table"
      and CharacterReforged.Parts.CardLook or nil
    if NMR ~= nil and type(NMR.PositionColour) == "function" then
      local ok, look = pcall(NMR.PositionColour, hdl)
      if ok and type(look) == "table" and type(look.card_frame) == "number" then
        return look.card_frame
      end
    end
    local ok, rarity = pcall(funcLuaCommand, P.RARITY, hdl, 12)
    if not ok or type(rarity) ~= "number" then
      return P.PLATE_DEFAULT
    end
    if NMR ~= nil and type(NMR.FrameOfRarity) == "function" then
      local okf, frame = pcall(NMR.FrameOfRarity, rarity)
      if okf and type(frame) == "number" then
        return frame
      end
    end
    return rarity + 1
  end

  -- the passive's icon on its tile: the passive display's Icon (one function for every card) -> texture, sprite
  function G.PassiveCardIcon(L, idx, display)
    local P = G.PC
    Cmd(C.SPRITE, L, P.TILE_TEX, P.TILE_SPRITE, P.TILE_SLOT, 0, idx)
    local tex, sprite, tex2, sprite2
    if type(G.PassiveDisplay()) == "table" and type(G.PassiveDisplay().Icon) == "function" then
      local ok, t, s, t2, s2 = pcall(G.PassiveDisplay().Icon, display)
      if ok then
        tex, sprite, tex2, sprite2 = t, s, t2, s2
      end
    end
    local drawn = tex ~= nil and sprite ~= nil and Cmd(C.SPRITE, L, tex, sprite, P.ICON_SLOT, 0, idx) == true
    if not drawn and tex2 ~= nil and sprite2 ~= nil then   -- the icon's sheet not in: its fallback
      drawn = Cmd(C.SPRITE, L, tex2, sprite2, P.ICON_SLOT, 0, idx) == true
    end
    Cmd(C.MESH, L, P.TILE, drawn, idx)
    Cmd(C.MESH, L, P.ICON, drawn, idx)
  end

  -- player hdl's passive `display` ({passive, name, effect[, effect_id]}) as the card on instance idx of the window L,
  -- whose local origin is at screen (ox, oy); called when the window is filled (the face follows in
  -- G.PassiveCardStep, the screen's frame)
  function G.PassiveCardFill(L, idx, hdl, display, ox, oy)
    local P = G.PC
    if type(display) ~= "table" or not Exists(L) then
      return false
    end
    local ok, card, chara, element, crest = pcall(funcLuaCommand, P.LOOK, hdl)
    if not ok then
      card, chara, element, crest = 0, 0, 0, 0
    end
    card, chara, element, crest = VRFW_Id.u32(card), VRFW_Id.u32(chara), VRFW_Id.u32(element), VRFW_Id.u32(crest)
    -- the window's passive group on, its empty-slot group off (as the game's own fill does)
    Cmd(C.NODE_VIS, L, P.BLANK, false, idx)
    Cmd(P.NODE_TEXT_VIS, L, P.BLANK, false, idx)
    Cmd(C.NODE_VIS, L, P.PASSIVE, true, idx)
    Cmd(P.NODE_TEXT_VIS, L, P.PASSIVE, true, idx)
    for _, m in ipairs(P.HIDE) do
      Cmd(C.MESH, L, m, false, idx)
    end
    if type(display.name) == "string" and display.name ~= "" then
      Cmd(C.SET_TEXT, L, P.NAME, display.name, idx)
    end
    -- the description's style first (every card, every passive type: one look), then the fit measured in it
    local base = CALC_CRC(P.FIT.style)
    pcall(funcLuaMenuCommand, P.TEXT_STYLE, L, idx, P.TEXT, base)
    if type(display.effect) == "string" then    -- nil = the game's own fill's text stays
      local fitted, style = display.effect, nil
      local okf, f1, f2 = pcall(G.PassiveCardFitText, L, idx, display.effect)
      if okf and type(f1) == "string" then fitted, style = f1, f2 end
      Cmd(C.SET_TEXT, L, P.TEXT, fitted, idx)
      if style ~= nil and style ~= base then
        pcall(funcLuaMenuCommand, P.TEXT_STYLE, L, idx, P.TEXT, style)
      end
      Cmd(P.TEXT_VIS, L, P.TEXT, true, idx)
    end
    -- the band of his element (1 wind, 2 forest, 3 fire, 4 mountain; any other = the neutral band)
    local band = (element >= 1 and element <= 4) and element or 0
    Cmd(C.MESH, L, P.BAND, Cmd(C.SPRITE, L, P.BAND_TEX, CALC_CRC(P.BAND_SPRITE .. band), P.BAND_SLOT, 0, idx) == true,
      idx)
    -- the slanted card: the face of his card frame (the default frame when the atlas has no face for it) and the rim
    local plate = Cmd(C.SPRITE, L, P.BAND_TEX, CALC_CRC(string.format("%s%02d", P.PLATE_SPRITE, G.PassiveCardFrame(hdl))),
      P.FRAME_SLOT, 0, idx) == true
    if not plate then
      plate = Cmd(C.SPRITE, L, P.BAND_TEX, CALC_CRC(string.format("%s%02d", P.PLATE_SPRITE, P.PLATE_DEFAULT)),
        P.FRAME_SLOT, 0, idx) == true
    end
    Cmd(C.MESH, L, P.FRAME, plate, idx)
    Cmd(C.MESH, L, P.RIM, Cmd(C.SPRITE, L, P.BAND_TEX, P.RIM_SPRITE, P.RIM_SLOT, 0, idx) == true, idx)
    local icon = (card ~= 0 and type(VRFW_CharaIcons) == "table") and VRFW_CharaIcons.Element(card) or nil
    Cmd(C.MESH, L, P.ELEMENT, type(icon) == "table"
      and Cmd(C.SPRITE, L, icon.tex, icon.sprite, P.ELEMENT_SLOT, 0, idx) == true, idx)
    -- the crest: hidden here, asked and shown by G.PassiveCardCrestStep once the window's textures are in
    Cmd(C.MESH, L, P.CREST, false, idx)
    G.PassiveCardIcon(L, idx, display)
    -- another player: the previous face off until this card's face is drawn (G.PassiveCardStep)
    local prev = G.pcard
    if G.pcardShown and (prev == nil or prev.card ~= card) and Exists(P.FACE) and Cmd(C.IS_OPEN, P.FACE, 0) == true then
      Cmd(C.VIS, P.FACE, 0, false)
      G.pcardShown = false
    end
    local x0, y0 = ox + P.TOP_LEFT[1], oy - P.TOP_LEFT[2]
    G.pcard = {L = L, idx = idx, card = card, who = chara ~= 0 and chara or {card = card}, x = x0 + P.FACE_AT[1],
      y = y0 + P.FACE_AT[2], drawn = false, face = false, masked = false, mask_tries = 0,
      crest = crest, crest_phase = crest ~= 0 and "settle" or nil, crest_quiet = 0, crest_steps = 0}
    -- the small «Actual» line (G.PassiveCardCurrentStep shows it): its text and its centre on the screen; none for a
    -- card shown in the players-universe mode (the album, an office candidate: not in the club's lineup)
    local okc, current = false, nil
    local okv, universe = false, false
    if type(G.ViewMode) == "function" then
      okv, universe = pcall(G.ViewMode)
    end
    if not (okv and universe == true) and type(G.PassiveDisplay()) == "table"
        and type(G.PassiveDisplay().Current) == "function" then
      okc, current = pcall(G.PassiveDisplay().Current, hdl, display.passive)
    end
    G.pcard.current = (okc and type(current) == "string" and current ~= "") and current or nil
    G.pcard.current_x, G.pcard.current_y = ox + P.CURRENT.AT[1], oy - P.CURRENT.AT[2]
    G.pcard.current_set = false
    return true
  end

  -- the card's crest, from the screen's frame while a filled card waits for it: first the window's own textures in
  -- (the retail fill on the skill table swaps its six-sense stone into the crest's slot, and a swapped sprite outlives
  -- an emblem request: the slot is reset to the object's own texture first), then the game's emblem request on the
  -- quad, opaque, and the quad shown once the emblem is in; never the bare quad (a white box)
  function G.PassiveCardCrestStep(w)
    local P = G.PC
    if w.crest_phase == nil then
      return
    end
    w.crest_steps = w.crest_steps + 1
    Cmd(C.MESH, w.L, P.CREST, false, w.idx)   -- held hidden: the retail fill's own icon may show the quad on its load
    if w.crest_steps > P.CREST_STEPS then
      w.crest_phase = nil
      pcall(funcLuaCommand, C.LOG, "EVT_PPG own card crest not loaded", string.format("%08X", w.crest))
      return
    end
    if Cmd(P.LOADING, w.L, w.idx) == true then
      w.crest_quiet = 0
      return
    end
    w.crest_quiet = w.crest_quiet + 1
    if w.crest_quiet < P.CREST_SETTLE then
      return
    end
    w.crest_quiet = 0
    if w.crest_phase == "settle" then
      w.crest_phase = "load"
      Cmd(P.ICON_RESET, w.L, w.idx, P.CREST_SLOT)
      Cmd(P.EMBLEM, w.L, w.idx, P.CREST, P.CREST_SLOT, w.crest, 0)
      Cmd(P.PRIM_ALPHA, w.L, w.idx, P.CREST, P.CREST_ALPHA)
    else
      w.crest_phase = nil
      Cmd(C.MESH, w.L, P.CREST, true, w.idx)
      if G.pcardCrestLogged ~= w.L * 0x100000000 + w.crest then
        G.pcardCrestLogged = w.L * 0x100000000 + w.crest
        pcall(funcLuaCommand, C.LOG, "EVT_PPG own card crest shown", string.format("%08X %08X", w.L, w.crest), w.crest_steps)
      end
    end
  end

  -- the card's face, from the screen's frame: shown while its window shows, drawn once per filled card
  -- the card's small «Actual» line on its own cell layer: shown only while the card's window is up and the passive has
  -- a value now; placed once per card at the line's centre, just over the window
  function G.PassiveCardCurrentStep(w)
    local K = G.PC.CURRENT
    local CL = K.LAYER
    if not Exists(CL) then
      return
    end
    local up = w ~= nil and w.current ~= nil and Cmd(C.IS_OPEN, w.L, w.idx) == true
      and Cmd(C.IS_VIS, w.L, w.idx) == true
    if not up then
      if G.pcardCurrentShown and Cmd(C.IS_OPEN, CL, 0) == true then
        Cmd(C.VIS, CL, 0, false)
      end
      G.pcardCurrentShown = false
      return
    end
    if not Ready(CL, 0) then
      return
    end
    if not w.current_set then
      w.current_set = true
      if G.H.pages and not G.ready[CL * 16] then
        G.ready[CL * 16] = true
        Cmd(C.TRACE, G.PAGE, 0, CL, true)    -- the player page: in the page's frame, as the window
      end
      Cmd(C.SET_TEXT, CL, K.TEXT, w.current, 0)
      Cmd(C.SET_TEXT, CL, K.OTHER, "", 0)
      Cmd(C.POS, CL, w.current_x - K.CELL_CENTRE[1], -(w.current_y + K.CELL_CENTRE[2]), 0, 0)   -- (screen x, -screen y)
      local ok, prio = pcall(funcLuaMenuCommand, @crc:CMND_GET_DRAW_PRIORITY@, w.L, 0)
      prio = ok and tonumber(prio) or nil
      if prio ~= nil then
        pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, CL, 0, prio + K.OVER_WINDOW, true)
      end
    end
    if not G.pcardCurrentShown then
      Cmd(C.VIS, CL, 0, true)
      G.pcardCurrentShown = true
    end
  end

  function G.PassiveCardStep()
    local P, w = G.PC, G.pcard
    local F = P.FACE
    if w ~= nil and w.crest_phase ~= nil and Cmd(C.IS_OPEN, w.L, w.idx) == true then
      G.PassiveCardCrestStep(w)
    end
    G.PassiveCardCurrentStep(w)
    if not Exists(F) then
      return
    end
    local up = w ~= nil and Cmd(C.IS_OPEN, w.L, w.idx) == true and Cmd(C.IS_VIS, w.L, w.idx) == true
    if not up then
      if G.pcardShown and Cmd(C.IS_OPEN, F, 0) == true then
        Cmd(C.VIS, F, 0, false)
      end
      G.pcardShown = false
      return
    end
    if not Ready(F, 0) then
      return
    end
    if G.H.pages and not G.ready[F * 16] then
      G.ready[F * 16] = true
      Cmd(C.TRACE, G.PAGE, 0, F, true)       -- the player page: the face in the page's frame, as its other parts
      G.pcardFacePrioSet = nil
    end
    if G.H.pages and G.pcardFacePrio ~= nil and G.pcardFacePrioSet ~= G.pcardFacePrio then
      G.pcardFacePrioSet = G.pcardFacePrio   -- the player page: the face just over its card, under any window
      pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, F, 0, G.pcardFacePrio, true)
    end
    -- the portrait cut to the card: the slanted mask in its mask slot, its side tint off (once per card; a swap that
    -- answers false, the atlas not in yet, is tried again on the next frames, FACE_MASK_TRIES at most)
    if not w.masked and w.mask_tries < P.FACE_MASK_TRIES then
      w.mask_tries = w.mask_tries + 1
      w.masked = Cmd(C.SPRITE, F, P.BAND_TEX, P.FACE_MASK, P.FACE_MASK_SLOT, 0, 0) ~= false
      if w.masked then
        Cmd(C.SPRITE, F, P.BAND_TEX, P.FACE_CLEAR, P.FACE_TINT_SLOT, 0, 0)
      end
    end
    if not w.drawn and type(VRFW_FaceIcon) == "table" then
      w.drawn = true
      w.face = VRFW_FaceIcon.Card(F, 0, w.who, w.x, w.y, P.FACE_SIZE) ~= false
    end
    if VRFW_FaceIcon ~= nil and VRFW_FaceIcon.Pending() then
      VRFW_FaceIcon.Settle()
    end
    if G.pcardShown ~= w.face then
      Cmd(C.VIS, F, 0, w.face)
      G.pcardShown = w.face
    end
  end

  -- ---- the custom-passive page (six-sense panel, type 3) inside the white card --------------------------------
  -- round 12: the panel's own frame / focus / blank meshes hidden. Round 13 (Nacho: title white on white, the bar not
  -- drawn, the retail hexagon art over the card, the 2nd line into the dots): the status base's _sixth_base01 (the
  -- 700 x 464 decoration) hidden; the panel lifted SX_DY so icon + title sit on a slanted blue band and the
  -- description on a light slanted plate, both attached to the page (gauge copies evt_pp_sxbar / evt_pp_sxplate,
  -- page frame: local = (screen x, -screen y)) at the passive card's rects (G.PassiveCardRects)
  G.SX = 3764752959                      -- team00_28_six_sense_detail_info
  G.SX_HIDE = {@crc:_sixth_win_base01@, @crc:_sixth_win_focus01@, @crc:_sixth_win_blank01@}
  G.SX_DECO = @crc:_sixth_base01@        -- status base: the six-sense page's decoration
  G.SXBAR, G.SXPLATE = @crc:evt_pp_sxbar@, @crc:evt_pp_sxplate@
  G.SX_DY = 70                           -- the panel this much higher (its title 718..782, text 806..876 on screen)
  G.SX_AT = {1000, 718}                  -- the passive card's band top-left (screen): G.PassiveCardRects
  G.SX_PRIO = 322                        -- the panel over the band (321) and the plate (320)
  -- 2026-11-01 (owner: sketch C): a player with an own passive gets the own passive card (G.PassiveCardFill) on the
  -- page's custom passive window (layer team00_26_passive_slot_detail_info, attached to the page) instead of the
  -- panel, which the game keeps filling off the screen (SX_OFF)
  G.SX_CARD_ORIGIN = {1260, 922}         -- the window's local origin on screen: the card at 985..1920 x 712..907
  G.SX_OFF = -4000

  -- the card window and its face drawn just over the page (team11_01_personal_plate): over its white card on every
  -- host (the character bank draws the page higher than the team screens), under any window opened over the page
  G.SX_CARD_OVER_PAGE = 2                -- the window this far over the page; the face one more
  function G.SixthOwnCardPriority(L)
    local ok, page = pcall(funcLuaMenuCommand, @crc:CMND_GET_DRAW_PRIORITY@, G.PAGE, 0)
    page = ok and tonumber(page) or nil
    local prio = page ~= nil and math.max(G.SX_PRIO, page + G.SX_CARD_OVER_PAGE) or G.SX_PRIO
    pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, L, 0, prio, true)
    G.pcardFacePrio = prio + 1           -- set on the face when it opens (G.PassiveCardStep)
    pcall(funcLuaCommand, C.LOG, "EVT_PPG own card priority", tostring(page), prio)
  end

  -- the own passive card of the page's player: true while it shows (display cached per player)
  function G.SixthOwnCard()
    local L = G.PC.LAYER
    local hdl = G.hdl
    if hdl == nil or not Exists(L) or type(G.PassiveDisplay()) ~= "table" then
      return false
    end
    if G.pcardHdl ~= hdl then
      G.pcardHdl = hdl
      G.pcardDisplay = G.PassiveDisplay().Of(hdl) or false
      G.pcardFilled = false
    end
    if not G.pcardDisplay then
      G.SixthOwnCardHide()
      return false
    end
    Cmd(C.POS, G.SX, 0, G.SX_OFF, 0, 0)
    for _, l in ipairs({G.SXBAR, G.SXPLATE}) do
      if Exists(l) and Cmd(C.IS_OPEN, l, 0) == true then
        Cmd(C.VIS, l, 0, false)
      end
    end
    if not Ready(L, 0) then
      return true
    end
    if not G.ready[L * 16] then
      G.ready[L * 16] = true
      Cmd(C.TRACE, G.PAGE, 0, L, true)
      Cmd(C.POS, L, G.SX_CARD_ORIGIN[1], -G.SX_CARD_ORIGIN[2], 0, 0)
      G.SixthOwnCardPriority(L)
      G.pcardFilled = false
    end
    if not G.pcardFilled then
      G.pcardFilled = G.PassiveCardFill(L, 0, hdl, G.pcardDisplay, G.SX_CARD_ORIGIN[1], G.SX_CARD_ORIGIN[2])
      Cmd(C.VIS, L, 0, true)
    end
    G.pcardOwn = true
    return true
  end

  function G.SixthOwnCardHide()
    local L = G.PC.LAYER
    if G.pcardOwn then
      G.pcardOwn = false
      G.pcardFilled = false
      if Exists(L) and Cmd(C.IS_OPEN, L, 0) == true then
        Cmd(C.VIS, L, 0, false)
      end
    end
  end

  local function SxPiece(l, sp, r, prio)
    if not Exists(l) or not Ready(l, 0) then
      return
    end
    if not G.ready[l * 16] then
      G.ready[l * 16] = true
      Cmd(C.TRACE, G.PAGE, 0, l, true)
      for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
        Cmd(C.MESH, l, m, false, 0)
      end
      Cmd(C.SPRITE, l, G.TX_OWN, sp, G.SP_FRAME, 0, 0)
      local sx, sy = (r[3] - r[1]) / 476, (r[4] - r[2]) / 44
      Cmd(C.SCALE, l, sx, sy, 1, 0)
      Cmd(C.POS, l, r[1] - 94 * sx, -r[2] + 816 * sy, 0, 0)
      pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, l, 0, prio, true)
    end
    Cmd(C.VIS, l, 0, true)
  end

  function G.Sixth()
    local mine = On() and G.ptype == 3 and not G.InOffice() and Exists(G.SX) and Cmd(C.IS_OPEN, G.SX, 0) == true
      and Cmd(C.IS_VIS, G.SX, 0) == true
    if not mine then
      if G.sxOn then
        G.sxOn = false
        G.sxLogged = false
        if Exists(G.SX) and Cmd(C.IS_OPEN, G.SX, 0) == true then
          for _, m in ipairs(G.SX_HIDE) do
            Cmd(C.MESH, G.SX, m, true, 0)
          end
          Cmd(C.POS, G.SX, 0, 0, 0, 0)
        end
      end
      for _, l in ipairs({G.SXBAR, G.SXPLATE}) do
        if Exists(l) and Cmd(C.IS_OPEN, l, 0) == true then
          Cmd(C.VIS, l, 0, false)
        end
      end
      G.SixthOwnCardHide()
      return
    end
    if G.SixthOwnCard() then
      return
    end
    if not G.sxOn then
      G.sxOn = true
      pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, G.SX, 0, G.SX_PRIO, true)
      pcall(funcLuaCommand, C.LOG, "EVT_PPG sixth panel on")
    end
    for _, m in ipairs(G.SX_HIDE) do
      Cmd(C.MESH, G.SX, m, false, 0)
    end
    Cmd(C.MESH, G.STATUS, G.SX_DECO, false, 0)
    Cmd(C.POS, G.SX, 0, G.SX_DY, 0, 0)
    local band, plate = G.PassiveCardRects(G.SX_AT[1], G.SX_AT[2])
    SxPiece(G.SXPLATE, G.CARD.plate_sprite, plate, G.SX_PRIO - 2)
    SxPiece(G.SXBAR, G.CARD.band_sprite, band, G.SX_PRIO - 1)
    -- 2026-10-06 (shot 357: the page empty): the state of every piece once per visit, «EVT_PPG sixth state»
    if not G.sxLogged then
      G.sxLogged = true
      local function St(l)
        return string.format("%s/%s/%s", tostring(Exists(l)), tostring(Cmd(C.IS_OPEN, l, 0)), tostring(Cmd(C.IS_VIS, l, 0)))
      end
      pcall(funcLuaCommand, C.LOG, "EVT_PPG sixth state", "panel " .. St(G.SX), "bar " .. St(G.SXBAR),
        "plate " .. St(G.SXPLATE), "band " .. St(G.BAND), "page " .. St(G.PAGE))
    end
  end

  -- ---- Pasivas: the special slot's strip (orange, empty) hidden when the player has no special passive ------------
  function G.Passives()
    local L = 811691761                    -- soccer11_20_formation_team_passive
    if not On() or G.ptype ~= 2 or G.hdl == nil or not Exists(L) or Cmd(C.IS_OPEN, L, 0) ~= true then
      return
    end
    local ok, has, pid = pcall(funcLuaCommand, @crc:CMND_GET_CHARA_TEAM_PASSIVE_INFO@, G.hdl, 0, 0, false, false)   -- team passive info (slot 0)
    -- round 14 (Nacho): no special = the retail empty special strip itself (an unfilled slot: its plate, the empty
    -- icon square, no text), shown by PassiveRows like a filled one; no light-orange box
    G.noSpecial = ok and (has ~= true or type(pid) ~= "number" or pid == 0)
  end
