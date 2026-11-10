-- Player page block (plate_pages.lua)
  G.PR = 811691761                       -- soccer11_20_formation_team_passive
  G.PR_PLATE, G.PR_OL = 3143733656, {2061463723, 3822461201}
  G.PR_TEXT = 1868134834
  G.PR_NODES = {3453619769, 2497436533}
  G.PR_BUILD, G.PR_ICONBASE = 3448691050, 3877027080
  G.PT = @crc:cr_pp_ptile@
  G.PT_TRACE = {[0] = @crc:cr_pp_ptile0@, @crc:cr_pp_ptile1@, @crc:cr_pp_ptile2@, @crc:cr_pp_ptile3@, @crc:cr_pp_ptile4@}
  G.PT_SPRITE = {[0] = @crc:cr_pp_tile_orange@, @crc:cr_pp_tile_grey@, @crc:cr_pp_tile_grey@, @crc:cr_pp_tile_blue@,
    @crc:cr_pp_tile_blue@}                  -- special orange, general grey, archetype blue
  G.PT_W, G.PT_H = 90, 54
  G.PT_SPRITE_HL = {[0] = @crc:cr_pp_tile_orange_hl@, @crc:cr_pp_tile_grey_hl@, @crc:cr_pp_tile_grey_hl@,
    @crc:cr_pp_tile_blue_hl@, @crc:cr_pp_tile_blue_hl@}    -- the focused passive's tile (white rim)
  G.ptHl = {}
  G.PR_EF = @crc:_build_ef01@
  G.PR_INHERIT = 27565530
  G.PR_TILE = {-371, 40, 96, 80}
  G.PR_FULL = {-414, 46, 828, 92}
  G.PR_TEXT_BOX = {622, 72}              -- the text node's retail box (width, height; left edge -243)
  G.PR_TAB_Y = 770
  G.pcur = G.pcur or nil                 -- focused passive (cursor mode) or nil
  G.pexit = 0
  G.PARENTS = {935586083, 2049316981, 937147172}   -- team_dock_formation_menu, soccer_formation_menu, soccer_team_dock
  function G.parent_cursor(on)
    for _, m in ipairs(G.PARENTS) do
      pcall(funcLuaCommand, 830228314, m, "CharacterReforgedPlayerPageSetCursor", on)
    end
  end

  function G.tile(i, on, hl)
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

  G.PSUB = {[0] = {0, 1, 2}, {3, 4}}
  G.PSUB_N = 2                                       -- sub-page count (dots, R3 / click cycle)
  G.PSUB_Y = {[1] = {815}, [2] = {770, 862}, [3] = {742, 808, 874}}   -- strip centre rows (screen y) per strip count
  G.PSUB_SCALE = {[3] = 0.7}                         -- strip scale per strip count (default 1)
  G.PSUB_WIDE = {[3] = 790}
  G.PSUB_X = 1452                                    -- strip centre (screen x)
  G.PSUB_KEYS = {[0] = @crc:cr_pp_psub_2@, @crc:cr_pp_psub_3@}
  G.SP_TILE_EMPTY = @crc:cr_pp_tile_empty@
  G.EMPTY_BOX = {600, 66}                            -- the empty special's box (screen px)
  G.psub = G.psub or 0
  if G.psub >= G.PSUB_N then
    G.psub = 0
  end
  function G.next_passive_sub_page()
    return (G.psub + 1) % G.PSUB_N
  end
  -- sub-page n on the player page, with the key's sound (a session's page follows its focused row instead)
  function G.show_passive_sub_page(n)
    G.psub = n
    G.plast = G.ptick or 0
    pcall(funcLuaCommand, @crc:CMND_SND_PLAY_SE@, 2500047763)
  end
  G.noSpecial = false
  -- With no special there is no title.
  G.PTITLE = @crc:cr_pp_ptitle@
  -- Draws the title text in the special's dark orange from the strip's left edge (G.PTITLE_X), with a thin rule under it.
  G.PTITLE_K, G.PTITLE_DY = 0.8, 66          -- text scale; its centre this far above the strip's centre
  G.PTITLE_X = 1038
  G.PTITLE_BOX = 330 * 0.8
  G.PTITLE_RGB = {0.80, 0.30, 0.04}
  G.PTRULE, G.SP_PTRULE = @crc:cr_pp_ptrule@, @crc:cr_pp_ptrule@
  G.PTRULE_R = {1038, 772, 1866, 775}        -- the rule's screen rect (3 px, over the strip's top)
  G.CMD_SPECIAL, G.CMD_TEXT = @crc:CMND_BETTERQOL_PC_SPECIAL@, @crc:CMND_VRFW_TEXT_GET@

  -- how far the slot-0 strip's top sits below a lone strip's top on sub-page 1 (title and rule move with it)
  function G.p_title_dy()
    local n = #G.PSUB[0]
    local k = G.PSUB_SCALE[n] or 1
    return (G.PSUB_Y[n][1] - 46 * k) - (G.PSUB_Y[1][1] - 46)
  end

  function G.passive_display()
    local parts = type(CharacterReforged) == "table" and CharacterReforged.parts or nil
    return type(parts) == "table" and parts.passive_display or nil
  end

  function G.p_title(on)
    local T = G.PTITLE
    if not Exists(T) then
      return
    end
    local text = ""
    if on and G.hdl ~= nil then
      local ok, yes, key = pcall(funcLuaCommand, G.CMD_SPECIAL, G.hdl)
      if ok and yes == true and type(key) == "string" and key ~= "" then
        local id = "cr_pp_" .. string.gsub(key, "^inazuma_fantasy%.", "")
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
      local r, dy = G.PTRULE_R, G.p_title_dy()
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
    Cmd(C.POS, T, G.PTITLE_X + G.PTITLE_BOX / 2, -(G.PSUB_Y[1][1] + G.p_title_dy() - G.PTITLE_DY), 0, 0)
    if G.ptitleText ~= text then
      G.ptitleText = text
      Cmd(C.SET_TEXT, T, 1899787537 --[[_text_area01]], "[CR]" .. text .. "[C]", 0)
      Cmd(2735666188 --[[text visible]], T, 1899787537, true, 0)
    end
    Cmd(C.VIS, T, 0, true)
  end

  -- the empty special passive's box (tile layer instance 0, light orange), centred where its strip would be
  function G.empty_box(on)
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

  -- The strips' slanted plate (_passive_base01) is pre-coloured by kind.
  G.CARD_TEX, G.CARD_SLOT = 4021797290 --[[soccer11_20.g4tx]], 1729678359 --[[passive_base01]]
  G.CARD_SPR = {[3] = @crc:cr_pp_card_blue@, [4] = @crc:cr_pp_card_blue@}
  G.cardOn = G.cardOn or {}
  function G.card_tint(L, i, on)
    local spr = on and G.CARD_SPR[i] or nil
    if spr ~= nil then
      G.cardOn[L * 16 + i] = true
      pcall(funcLuaMenuCommand, C.SPRITE, L, G.CARD_TEX, spr, G.CARD_SLOT, 0, i)
    elseif G.cardOn[L * 16 + i] then
      G.cardOn[L * 16 + i] = nil
      pcall(funcLuaMenuCommand, C.SPRITE, L, G.CARD_TEX, G.CARD_SLOT, G.CARD_SLOT, 0, i)
    end
  end

  -- Hides the passive rows when no player is focused (empty slot, G.empty).
  function G.passive_rows_hide()
    local L = G.PR
    if Exists(L) then
      for i = 0, 4 do
        if Cmd(C.IS_OPEN, L, i) == true then
          Cmd(C.VIS, L, i, false)
        end
      end
    end
    G.empty_box(false)
    pcall(G.p_title, false)
  end

  -- Draws the passives in `slots` as whole strips, centred in the card, one under the other, on a soccer11_20 row layer whose instances 0..4 hang on the page's tile locators; the other strips are hidden.
  function G.passive_strips(L, slots, sess, noSpecial)
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
        G.card_tint(L, i, true)
        local y = row[i]
        if y == nil then
          Cmd(C.VIS, L, i, false)
          if i == 0 then
            Cmd(C.MESH, L, G.PR_PLATE, false, i)
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
          local wide = G.PSUB_WIDE[#shown]
          local plateW = wide and wide / scale or f[3]    -- right of the icon (layout units), the layer shifts to re-centre
          Cmd(C.NODE_SCALE, L, i, G.PR_PLATE, plateW, f[4])
          Cmd(C.NODE_SCALE, L, i, G.PR_TEXT, G.PR_TEXT_BOX[1] + plateW - f[3], G.PR_TEXT_BOX[2])
          Cmd(C.MESH, L, G.PR_PLATE, true, i)
          Cmd(C.MESH, L, G.PR_ICONBASE, true, i)      -- the icon always
          Cmd(C.MESH, L, G.PR_EF, false, i)
          Cmd(C.NODE_VIS, L, G.PR_BUILD, false, i)
          for _, m in ipairs(G.PR_OL) do
            Cmd(C.MESH, L, m, i == sess and m == G.PR_OL[1], i)
          end
          Cmd(C.MESH, L, G.PR_INHERIT, false, i)
          Cmd(C.NODE_VIS, L, G.PR_TEXT, true, i)
          Cmd(C.TEXT_VIS, L, G.PR_TEXT, true, i)
          for _, n in ipairs(G.PR_NODES) do
            Cmd(C.NODE_VIS, L, n, false, i)              -- the white boxes
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
  function G.passive_strips_off(L)
    for i = 0, 4 do
      if Cmd(C.IS_OPEN, L, i) == true then
        G.card_tint(L, i, false)
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

  function G.passive_rows()
    local L = G.PR
    if not Exists(L) then
      return
    end
    if G.emptyHidden then
      return
    end
    local mine = On() and G.ptype == 2 and not G.in_office()
    if not mine then
      if G.pcur ~= nil then
        G.pcur = nil
        G.parent_cursor(false)
      end
      G.empty_box(false)
      pcall(G.p_title, false)
      if G.prOn then
        G.prOn = false
        G.passive_strips_off(L)
      end
      return
    end
    G.prOn = true
    local sess = nil
    local plate_config = type(BetterQoL) == "table" and BetterQoL.passive_config_plate or nil
    if type(plate_config) == "table" and plate_config.co ~= nil and type(plate_config.slot) == "number" and plate_config.slot >= 0 then
      sess = plate_config.slot
      local want = sess <= 2 and 0 or 1
      if G.psub ~= want then
        G.psub = want
      end
    end
    G.passive_strips(L, G.PSUB[G.psub], sess, G.noSpecial)
    G.empty_box(false)
    pcall(G.p_title, G.psub == 0 and not G.noSpecial)
    -- Handles R3.
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
      G.show_passive_sub_page(G.next_passive_sub_page())
    end
  end

  G.CARD = {band_sprite = @crc:cr_pp_sxbar@, plate_sprite = @crc:cr_pp_sxplate@, band_w = 860, band_h = 62,
    plate_w = 860, plate_h = 106, plate_dx = 30, gap = 10}

  function G.passive_card_rects(x, y)
    local k = G.CARD
    local py = y + k.band_h + k.gap
    return {x, y, x + k.band_w, y + k.band_h}, {x + k.plate_dx, py, x + k.plate_dx + k.plate_w, py + k.plate_h}
  end

  G.PC = {
    LAYER = 1593383077,                                   -- team00_26_passive_slot_detail_info
    FACE = @crc:cr_pp_card_face@,
    LOOK = @crc:CMND_PASSIVESSYNERGIES_CARD_LOOK@,        -- (charaStHdl) -> card, chara, element, crest
    TOP_LEFT = {-275, 210},                               -- the card's top-left in window units (y up)
    FACE_AT = {84, 104}, FACE_SIZE = 182,
                                                          -- the bust on the card's bottom edge, the card's full height
    BAND = 1632359140, BAND_SLOT = 3317336303,
    BAND_TEX = 71954599, BAND_SPRITE = "character_reforged_card_band",   -- character_reforged_card.g4tx, + the element (0 = neutral)
    FRAME = 738777627, FRAME_SLOT = 1804582091,
    RIM = 572914009, RIM_SLOT = 4267484374,
    -- The slanted card (character_reforged_card.toml texture character_reforged_card_face).
    PLATE_SPRITE = "character_reforged_card_plate", PLATE_DEFAULT = 1, RIM_SPRITE = @crc:character_reforged_card_rim@,
    FACE_MASK = @crc:character_reforged_card_face_mask@, FACE_CLEAR = @crc:character_reforged_card_clear@,
    FACE_MASK_SLOT = @crc:icon_chr_msk_l01@, FACE_TINT_SLOT = @crc:icon_chr_color01_l01@, FACE_MASK_TRIES = 30,
    RARITY = 1131797651,                                  -- CMND_GET_CHARA (hdl, 12) = the status' rarity
    ELEMENT = 2782988477, ELEMENT_SLOT = 4002291610,
    CREST = 1605611365, CREST_SLOT = 4285917355, CREST_ALPHA = 1.0,
    TILE = 2366589118, TILE_SLOT = 818857611,
    TILE_TEX = 3582673743, TILE_SPRITE = 1971896313,      -- team00_26.g4tx passive_teambuff_base02
    ICON = 2408672862, ICON_SLOT = 1780336175,
    NAME = 1704438437, TEXT = 691026122,
    BLANK = 2020757070, PASSIVE = 3387908913,
    HIDE = {1896097465 --[[_icon_buff_dmy01]], 1021860103 --[[_passive_icon_build_dmy02]]},
    EMBLEM = 3190452549,                                  -- (layer, idx, mesh, slot, item_emblem, 0)
    PRIM_ALPHA = @crc:CMND_SET_PRIM_ALPHA@,               -- (layer, idx, mesh, alpha)
    LOADING = 1277042906,                                 -- (layer, idx) -> true while the instance loads a texture
    ICON_RESET = 4176779611,                              -- (layer, idx, texture slot): the slot back to the object's
                                                          -- own texture (drops a sprite swapped in by a retail fill)
    CREST_SETTLE = 2,
    CREST_STEPS = 2000,                                   -- steps a crest may take; past them it stays hidden
    NODE_TEXT_VIS = 2735666188, TEXT_VIS = 1505208242,
    TEXT_STYLE = 2333948100,                              -- (layer, idx, textCrc, styleCrc)
    -- Fit of the effect text (G.passive_card_fit_text).
    FIT = {width = 540, min_squeeze = 0.8, base_size = 32, unit_px = 16, style = "fs_28_b_cc_2d0_001_sclw",
      sizes = {{28, "fs_28_b_cc_2d0_001_sclw"}, {22, "fs_22_b_cc_2d0_001_sclw"}}},
    CURRENT = {LAYER = @crc:cr_pp_card_current@, TEXT = @crc:_text_bonus01@, OTHER = @crc:_text_exp01@,
      AT = {257, 30}, CELL_CENTRE = {0, 30}, OVER_WINDOW = 1},
  }
  G.pcard = G.pcard or nil

  -- Fits the effect text of a card on two balanced lines.
  function G.passive_card_fit_text(L, idx, effect)
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
    local function Units(t) return type(VRFW.text_fold) == "table" and VRFW.text_fold.units(Plain(t)) or #Plain(t) end
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
      local m = type(VRFW.text_fold) == "table" and VRFW.text_fold.measure(L, idx, P.TEXT, Plain(t)) or nil
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

  -- Returns the card frame number of player hdl's card.
  function G.passive_card_frame(hdl)
    local P = G.PC
    local NMR = type(CharacterReforged) == "table" and type(CharacterReforged.parts) == "table"
      and CharacterReforged.parts.card_look or nil
    if NMR ~= nil and type(NMR.position_colour) == "function" then
      local ok, look = pcall(NMR.position_colour, hdl)
      if ok and type(look) == "table" and type(look.card_frame) == "number" then
        return look.card_frame
      end
    end
    local ok, rarity = pcall(funcLuaCommand, P.RARITY, hdl, 12)
    if not ok or type(rarity) ~= "number" then
      return P.PLATE_DEFAULT
    end
    if NMR ~= nil and type(NMR.frame_of_rarity) == "function" then
      local okf, frame = pcall(NMR.frame_of_rarity, rarity)
      if okf and type(frame) == "number" then
        return frame
      end
    end
    return rarity + 1
  end

  -- Draws the passive's icon on its tile.
  function G.passive_card_icon(L, idx, display)
    local P = G.PC
    Cmd(C.SPRITE, L, P.TILE_TEX, P.TILE_SPRITE, P.TILE_SLOT, 0, idx)
    local tex, sprite, tex2, sprite2
    if type(G.passive_display()) == "table" and type(G.passive_display().icon) == "function" then
      local ok, t, s, t2, s2 = pcall(G.passive_display().icon, display)
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

  function G.passive_card_fill(L, idx, hdl, display, ox, oy)
    local P = G.PC
    if type(display) ~= "table" or not Exists(L) then
      return false
    end
    local ok, card, chara, element, crest = pcall(funcLuaCommand, P.LOOK, hdl)
    if not ok then
      card, chara, element, crest = 0, 0, 0, 0
    end
    card, chara, element, crest = VRFW.ids.unsigned(card), VRFW.ids.unsigned(chara), VRFW.ids.unsigned(element), VRFW.ids.unsigned(crest)
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
    local base = CALC_CRC(P.FIT.style)
    pcall(funcLuaMenuCommand, P.TEXT_STYLE, L, idx, P.TEXT, base)
    if type(display.effect) == "string" then
      local fitted, style = display.effect, nil
      local okf, f1, f2 = pcall(G.passive_card_fit_text, L, idx, display.effect)
      if okf and type(f1) == "string" then fitted, style = f1, f2 end
      Cmd(C.SET_TEXT, L, P.TEXT, fitted, idx)
      if style ~= nil and style ~= base then
        pcall(funcLuaMenuCommand, P.TEXT_STYLE, L, idx, P.TEXT, style)
      end
      Cmd(P.TEXT_VIS, L, P.TEXT, true, idx)
    end
    local band = (element >= 1 and element <= 4) and element or 0
    Cmd(C.MESH, L, P.BAND, Cmd(C.SPRITE, L, P.BAND_TEX, CALC_CRC(P.BAND_SPRITE .. band), P.BAND_SLOT, 0, idx) == true,
      idx)
    -- Draws the slanted card.
    local plate = Cmd(C.SPRITE, L, P.BAND_TEX, CALC_CRC(string.format("%s%02d", P.PLATE_SPRITE, G.passive_card_frame(hdl))),
      P.FRAME_SLOT, 0, idx) == true
    if not plate then
      plate = Cmd(C.SPRITE, L, P.BAND_TEX, CALC_CRC(string.format("%s%02d", P.PLATE_SPRITE, P.PLATE_DEFAULT)),
        P.FRAME_SLOT, 0, idx) == true
    end
    Cmd(C.MESH, L, P.FRAME, plate, idx)
    Cmd(C.MESH, L, P.RIM, Cmd(C.SPRITE, L, P.BAND_TEX, P.RIM_SPRITE, P.RIM_SLOT, 0, idx) == true, idx)
    local icon = (card ~= 0 and type(VRFW.chara_icons) == "table") and VRFW.chara_icons.element(card) or nil
    Cmd(C.MESH, L, P.ELEMENT, type(icon) == "table"
      and Cmd(C.SPRITE, L, icon.tex, icon.sprite, P.ELEMENT_SLOT, 0, idx) == true, idx)
    -- Hides the crest.
    Cmd(C.MESH, L, P.CREST, false, idx)
    G.passive_card_icon(L, idx, display)
    -- Handles another player.
    local prev = G.pcard
    if G.pcardShown and (prev == nil or prev.card ~= card) and Exists(P.FACE) and Cmd(C.IS_OPEN, P.FACE, 0) == true then
      Cmd(C.VIS, P.FACE, 0, false)
      G.pcardShown = false
    end
    local x0, y0 = ox + P.TOP_LEFT[1], oy - P.TOP_LEFT[2]
    G.pcard = {L = L, idx = idx, card = card, who = chara ~= 0 and chara or {card = card}, x = x0 + P.FACE_AT[1],
      y = y0 + P.FACE_AT[2], drawn = false, face = false, masked = false, mask_tries = 0,
      crest = crest, crest_phase = crest ~= 0 and "settle" or nil, crest_quiet = 0, crest_steps = 0}
    local okc, current = false, nil
    local okv, universe = false, false
    if type(G.view_mode) == "function" then
      okv, universe = pcall(G.view_mode)
    end
    if not (okv and universe == true) and type(G.passive_display()) == "table"
        and type(G.passive_display().current) == "function" then
      okc, current = pcall(G.passive_display().current, hdl, display.passive)
    end
    G.pcard.current = (okc and type(current) == "string" and current ~= "") and current or nil
    G.pcard.current_x, G.pcard.current_y = ox + P.CURRENT.AT[1], oy - P.CURRENT.AT[2]
    G.pcard.current_set = false
    return true
  end

  -- Draws the card's crest from the screen's frame while a filled card waits for it.
  function G.passive_card_crest_step(w)
    local P = G.PC
    if w.crest_phase == nil then
      return
    end
    w.crest_steps = w.crest_steps + 1
    Cmd(C.MESH, w.L, P.CREST, false, w.idx)
    if w.crest_steps > P.CREST_STEPS then
      w.crest_phase = nil
      pcall(funcLuaCommand, C.LOG, "PlayerPage own card crest not loaded", string.format("%08X", w.crest))
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
        pcall(funcLuaCommand, C.LOG, "PlayerPage own card crest shown", string.format("%08X %08X", w.L, w.crest), w.crest_steps)
      end
    end
  end

  -- Draws the card's face from the screen's frame.
  function G.passive_card_current_step(w)
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

  function G.passive_card_step()
    local P, w = G.PC, G.pcard
    local F = P.FACE
    if w ~= nil and w.crest_phase ~= nil and Cmd(C.IS_OPEN, w.L, w.idx) == true then
      G.passive_card_crest_step(w)
    end
    G.passive_card_current_step(w)
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
    -- Draws the portrait cut to the card.
    if not w.masked and w.mask_tries < P.FACE_MASK_TRIES then
      w.mask_tries = w.mask_tries + 1
      w.masked = Cmd(C.SPRITE, F, P.BAND_TEX, P.FACE_MASK, P.FACE_MASK_SLOT, 0, 0) ~= false
      if w.masked then
        Cmd(C.SPRITE, F, P.BAND_TEX, P.FACE_CLEAR, P.FACE_TINT_SLOT, 0, 0)
      end
    end
    if not w.drawn and type(VRFW.face_icon) == "table" then
      w.drawn = true
      w.face = VRFW.face_icon.card(F, 0, w.who, w.x, w.y, P.FACE_SIZE) ~= false
    end
    if VRFW.face_icon ~= nil and VRFW.face_icon.pending() then
      VRFW.face_icon.settle()
    end
    if G.pcardShown ~= w.face then
      Cmd(C.VIS, F, 0, w.face)
      G.pcardShown = w.face
    end
  end

  G.SX = 3764752959                      -- team00_28_six_sense_detail_info
  G.SX_HIDE = {@crc:_sixth_win_base01@, @crc:_sixth_win_focus01@, @crc:_sixth_win_blank01@}
  G.SX_DECO = @crc:_sixth_base01@        -- status base: the six-sense page's decoration
  G.SXBAR, G.SXPLATE = @crc:cr_pp_sxbar@, @crc:cr_pp_sxplate@
  G.SX_DY = 70
  G.SX_AT = {1000, 718}                  -- the passive card's band top-left (screen): G.passive_card_rects
  G.SX_PRIO = 322                        -- the panel over the band (321) and the plate (320)
  -- A player with an own passive gets the own passive card (G.passive_card_fill) on the page's custom passive.
  G.SX_CARD_ORIGIN = {1260, 922}
  G.SX_OFF = -4000

  -- The card window and its face are drawn just over the page (team11_01_personal_plate).
  G.SX_CARD_OVER_PAGE = 2                -- the window this far over the page; the face one more
  function G.sixth_own_card_priority(L)
    local ok, page = pcall(funcLuaMenuCommand, @crc:CMND_GET_DRAW_PRIORITY@, G.PAGE, 0)
    page = ok and tonumber(page) or nil
    local prio = page ~= nil and math.max(G.SX_PRIO, page + G.SX_CARD_OVER_PAGE) or G.SX_PRIO
    pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, L, 0, prio, true)
    G.pcardFacePrio = prio + 1           -- set on the face when it opens (G.passive_card_step)
    pcall(funcLuaCommand, C.LOG, "PlayerPage own card priority", tostring(page), prio)
  end

  -- Draws the own passive card of the page's player.
  function G.sixth_own_card()
    local L = G.PC.LAYER
    local hdl = G.hdl
    if hdl == nil or not Exists(L) or type(G.passive_display()) ~= "table" then
      return false
    end
    if G.pcardHdl ~= hdl then
      G.pcardHdl = hdl
      G.pcardDisplay = G.passive_display().of(hdl) or false
      G.pcardFilled = false
    end
    if not G.pcardDisplay then
      G.sixth_own_card_hide()
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
      G.sixth_own_card_priority(L)
      G.pcardFilled = false
    end
    if not G.pcardFilled then
      G.pcardFilled = G.passive_card_fill(L, 0, hdl, G.pcardDisplay, G.SX_CARD_ORIGIN[1], G.SX_CARD_ORIGIN[2])
      Cmd(C.VIS, L, 0, true)
    end
    G.pcardOwn = true
    return true
  end

  function G.sixth_own_card_hide()
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

  function G.sixth()
    local mine = On() and G.ptype == 3 and not G.in_office() and Exists(G.SX) and Cmd(C.IS_OPEN, G.SX, 0) == true
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
      G.sixth_own_card_hide()
      return
    end
    if G.sixth_own_card() then
      return
    end
    if not G.sxOn then
      G.sxOn = true
      pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, G.SX, 0, G.SX_PRIO, true)
      pcall(funcLuaCommand, C.LOG, "PlayerPage sixth panel on")
    end
    for _, m in ipairs(G.SX_HIDE) do
      Cmd(C.MESH, G.SX, m, false, 0)
    end
    Cmd(C.MESH, G.STATUS, G.SX_DECO, false, 0)
    Cmd(C.POS, G.SX, 0, G.SX_DY, 0, 0)
    local band, plate = G.passive_card_rects(G.SX_AT[1], G.SX_AT[2])
    SxPiece(G.SXPLATE, G.CARD.plate_sprite, plate, G.SX_PRIO - 2)
    SxPiece(G.SXBAR, G.CARD.band_sprite, band, G.SX_PRIO - 1)
    if not G.sxLogged then
      G.sxLogged = true
      local function St(l)
        return string.format("%s/%s/%s", tostring(Exists(l)), tostring(Cmd(C.IS_OPEN, l, 0)), tostring(Cmd(C.IS_VIS, l, 0)))
      end
      pcall(funcLuaCommand, C.LOG, "PlayerPage sixth state", "panel " .. St(G.SX), "bar " .. St(G.SXBAR),
        "plate " .. St(G.SXPLATE), "band " .. St(G.BAND), "page " .. St(G.PAGE))
    end
  end

  function G.passives()
    local L = 811691761                    -- soccer11_20_formation_team_passive
    if not On() or G.ptype ~= 2 or G.hdl == nil or not Exists(L) or Cmd(C.IS_OPEN, L, 0) ~= true then
      return
    end
    local ok, has, pid = pcall(funcLuaCommand, @crc:CMND_GET_CHARA_TEAM_PASSIVE_INFO@, G.hdl, 0, 0, false, false)   -- team passive info (slot 0)
    -- no special = the retail empty special strip, shown by PassiveRows like a filled one
    G.noSpecial = ok and (has ~= true or type(pid) ~= "number" or pid == 0)
  end
