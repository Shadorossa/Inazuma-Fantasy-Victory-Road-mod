-- ===== EVT pset_preview BEGIN ===== (research/grafts/pset_preview, docs/game/skill-slots.md "Set preview: plate pages")
do
  CharacterReforged.set_preview_screen = CharacterReforged.set_preview_screen or {}
  function CharacterReforged.set_preview_screen.install()
    local P = CharacterReforged.set_preview_screen
    if P.installed or PL == nil then
      return
    end
    P.installed = true
    P.CMD_FULL = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_FULL@
    P.CMD_SET2 = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_SAVE_FULL@
    P.CMD_PC_INFO = @crc:CMND_BETTERQOL_PC_INFO@
    P.CMD_PC_SLOT = @crc:CMND_BETTERQOL_PC_SLOT@
    P.CMD_PC_SET = @crc:CMND_BETTERQOL_PC_SET@
    P.CMD_ROLE_SET = @crc:CMND_CHARACTERREFORGED_SET_ROLE@
    P.L_BASE = @crc:cr_psp_base@
    P.L_MOVE = @crc:character_reforged_psp_move@
    P.L_EQUIP = @crc:character_reforged_psp_equip@
    P.L_PV = @crc:character_reforged_psp_pv@
    P.L_SIX = @crc:character_reforged_psp_six@
    P.L_AI = @crc:character_reforged_psp_ai@
    P.COUNT = {[P.L_MOVE] = 7, [P.L_AI] = 7, [P.L_EQUIP] = 6, [P.L_PV] = 5, [P.L_SIX] = 1}
    P.PG = {STATS = 1, MOVES = 2, HIPER = 3, EQUIP = 4, PASSIVES = 5, SIX = 6}
    P.PAGES = 6
    P.page = 1
    -- Page base (the player page's status base layout).
    P.M_TITLE = @crc:_gtxt_sixthsense01@
    P.M_TITLES_OFF = {@crc:_gtxt_parameters01@, @crc:_gtxt_parameters02@, @crc:_gtxt_parameters01_rpg@,
      @crc:_gtxt_parameters02_rpg@, @crc:_gtxt_teampassives01@, @crc:_cmd_slot01_rpg@, @crc:_cmd_slot02_rpg@,
      @crc:_cmd_slot03_rpg@}
    P.M_SLOTS = {@crc:_cmd_slot01@, @crc:_cmd_slot02@, @crc:_cmd_slot03@}     -- the 1 / 2 / 3 badges (page 2)
    -- The screen's radar stays on the screen's status base.
    P.RADAR_MINE = {@crc:character_reforged_psp_graph_base@, @crc:character_reforged_psp_graph@}
    P.ATTACH = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@                          -- (layer, idx, name, on)
    P.K_R3 = 3147328756                            -- CMD_FUNC6
    P.psub = 0
    P.strips = nil                                 -- the strips last drawn: {slots, noSpecial} (re-applied on open)
    -- Laurel plate (instance 5) is centred in the card's free band above the grid.
    P.ROLE_AT = {1435 - 1617, 916 - 680}
    P.M_ARROWS = {@crc:_arrow01_l@, @crc:_arrow01_r@}
    P.T_KEYS = {@crc:_text_btn_l01@, @crc:_text_btn_r01@}
    P.M_SIXTH_BASE = @crc:_sixth_base01@
    -- L2 / R2 (the page base's own key glyphs) page the preview
    P.K_L1 = 1970176280                            -- CMD_FUNCL2
    P.K_R1 = 2704260807                            -- CMD_FUNCR2
    P.K_LEFT = 2765147006                          -- CMD_LEFT
    P.K_RIGHT = 2075023265                         -- CMD_RIGHT
    P.EQUIP_PARAM = @crc:CMND_GET_EQUIP_PARAM@                     -- (item, stat type 0..6) -> ok, value
    -- Equipment plates (soccer11_08).
    P.TX_S1108 = 1676671618                        -- #/menu/00_soccer/soccer11/soccer11_08/<LG>/soccer11_08.g4tx
    P.S_EQ_CAT = 2346103015                        -- icon_equip01 (slot)
    P.S_EQ_GTXT = 1537316010                       -- gtxt_shoes01 (slot)
    P.M_EQ_CAT = @crc:_icon_equip01@
    P.M_EQ_GTXT = @crc:_gtxt_item01@
    P.M_EQ_FOCUS = {@crc:_item_list_focus01@, @crc:_item_list_focus02@, @crc:_item_list_focus03@, @crc:_icon_title01@}
    P.EQ_POS = {1307475940 --[[_pos_list01]], 3571920478 --[[_pos_list02]], 2749374152 --[[_pos_list03]]}
    P.EQ = {
      [0] = {pos = 1307475940, style = 1254616204, text = 456522680, mesh = 303536660, cat = 2346103015, gtxt = 1537316010},
      [1] = {pos = 1307475940, style = 1254616204, text = 456522680, mesh = 303536660, cat = 316662109, gtxt = 1570380768},
      [2] = {pos = 1307475940, style = 1254616204, text = 456522680, mesh = 303536660, cat = 1708708299, gtxt = 3838541556},
      [3] = {pos = 1307475940, style = 1254616204, text = 456522680, mesh = 303536660, cat = 4223419496, gtxt = 2352590947},
      [4] = {pos = 2749374152, style = 1281522442, text = 4114324116, mesh = 2334051246},
      [5] = {pos = 3571920478, style = 263147399, text = 2185013762, mesh = 4025646555,       -- role: laurel plate, medal on _icon_title01
        base = 1453818910 --[[title_list_base01]], slot = 3047759730 --[[icon_title01]]},
    }
    -- passive rows (soccer11_20) and the six-sense window (team00_28)
    P.T_PASSIVE = @crc:_text_passive01@
    P.POS_ICON = @crc:_pos_icon01@
    P.POS_ICON2 = 397052763                        -- second icon locator (two-icon effects)
    P.POS_BUILD = @crc:_pos_build01@
    P.POS_TYPE = @crc:_pos_type01@
    P.POS_POSITION = @crc:_pos_position01@
    P.POS_LOCK = @crc:_pos_icon02@
    P.M_INHERIT = @crc:_icon_inheritance01@
    P.M_SIX_FOCUS = @crc:_sixth_win_focus01@
    P.T_SIXTH = @crc:_text_sixth01@
    P.T_FLAVOR = @crc:_text_flavor01@
    P.GREY_ON, P.GREY_OFF = "[CGRAYOUT04]", "[C]"
    P.shown = false

    function P.log(...)
      P.logger = P.logger or VRFW.logger.new("pset_preview")
      P.logger(...)
    end

    function P.exists()
      local ok, e = pcall(funcLuaMenuCommand, @crc:CMND_IS_EXIST_LAYER@, P.L_BASE)
      return ok and e == true
    end

    function P.probe()
      return CharacterReforged.player_sets.has_full(n)
    end

    function P.ids(t, count)
      local out = {}
      for k = 1, count do
        out[k] = to_u32(type(t) == "table" and t[k] or 0)
      end
      return out
    end

    -- Reads the player's 5 passives.
    function P.read_passives()
      local ok, got = pcall(funcLuaCommand, P.CMD_PC_INFO, n)
      if not ok or got ~= true then
        return nil, nil
      end
      local pv, cf = {}, {}
      for s = 0, 4 do
        local okS, id, conf = pcall(funcLuaCommand, P.CMD_PC_SLOT, n, s)
        id = (okS and type(id) == "number") and to_u32(id) or 0
        pv[s + 1] = id
        cf[s + 1] = (okS and conf == true) and id or 0
      end
      return pv, cf
    end

    P.prevCurrent = PL.set_current
    function PL.set_current()
      local cur = P.prevCurrent()
      local okp, pv, cf = pcall(P.read_passives)
      if okp then
        cur.passives, cur.pcfg = pv, cf
      end
      local okr, r = pcall(PL.role)
      if okr and type(r) == "number" and r >= 0 then
        cur.role = r
      end
      return cur
    end

    P.prevSame = PL.set_same
    function PL.set_same(p, cur)
      if not P.prevSame(p, cur) then
        return false
      end
      if p.pcfg ~= nil and cur.pcfg ~= nil then
        for k = 1, 5 do
          if (p.pcfg[k] or 0) ~= (cur.pcfg[k] or 0) then
            return false
          end
        end
      end
      return p.role == nil or cur.role == nil or p.role == cur.role
    end

    P.prevWrite = PL.set_write
    function PL.set_write(i, p, name)
      if not P.probe() then
        return P.prevWrite(i, p, name)
      end
      if p == nil then
        local cur = PL.set_current()
        local first = 0
        for r = 1, 6 do
          if first == 0 and cur.moves[r] ~= 0 then
            first = cur.moves[r]
          end
        end
        p = cur
        name = name or (first ~= 0 and Name(first) or PL.txt(PL.TX.SET_N, i + 1))
      end
      local m, e, pv, cf = p.moves, p.equip, p.passives, p.pcfg
      local function at(t, k)
        if t == nil then
          return nil
        end
        return t[k] or 0
      end
      local ok = Call(P.CMD_SET2, n, i, Cut(name or "", 26), m[1], m[2], m[3], m[4], m[5], m[6], p.hiper,
        e[1], e[2], e[3], e[4], e[5], p.sixsense or 0,
        at(pv, 1), at(pv, 2), at(pv, 3), at(pv, 4), at(pv, 5),
        at(pv and (cf or {}) or nil, 1), at(pv and (cf or {}) or nil, 2), at(pv and (cf or {}) or nil, 3),
        at(pv and (cf or {}) or nil, 4), at(pv and (cf or {}) or nil, 5),
        p.role or -1, p.kit or 0, p.mix or 0)
      P.log("save", i, name, ok, "kit", tostring(p.kit), "passives", tostring(pv ~= nil), "role", tostring(p.role))
      return ok
    end

    function P.player_page()
      return type(CharacterReforged.player_page) == "table" and CharacterReforged.player_page or nil
    end

    -- the screen's radar off while the preview shows (the gauge rows replace it)
    function P.no_radar()
      PL.hiper_wide = true
      pcall(CharacterReforged.skill_table_detail_graph_sync)
    end

    function P.hide()
      for L, cnt in pairs(P.COUNT) do
        for k = 0, cnt - 1 do
          funcLuaMenuCommand(C.LAYER_VISIBLE, L, k, false)
        end
      end
      funcLuaMenuCommand(C.LAYER_VISIBLE, P.L_BASE, 0, false)
      local G = P.player_page()
      if G ~= nil and type(G.show_values) == "function" then
        pcall(G.show_values, nil)
      end
      P.shown = false
    end

    -- Draws the page base.
    function P.frame(show)
      local L = P.L_BASE
      PL.open(L, 0)
      for _, m in ipairs(P.M_TITLES_OFF) do
        funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, 0)
      end
      funcLuaMenuCommand(C.MESH_VISIBLE, L, P.M_TITLE, false, 0)
      funcLuaMenuCommand(C.MESH_VISIBLE, L, P.M_SIXTH_BASE, false, 0)
      for _, m in ipairs(P.M_ARROWS) do
        funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, 0)
      end
      for _, m in ipairs(P.M_SLOTS) do
        funcLuaMenuCommand(C.MESH_VISIBLE, L, m, show and P.page == P.PG.MOVES, 0)
      end
      local G = P.player_page()
      if G ~= nil and type(G.dot_place) == "function" then
        G.dot_place(L, G.dot_shift(P.PAGES))
        for i = 1, 6 do
          funcLuaMenuCommand(C.MESH_VISIBLE, L, G.DOT_OFF[i], show and i <= P.PAGES, 0)
          funcLuaMenuCommand(C.MESH_VISIBLE, L, G.DOT_ON[i], show and i == P.page, 0)
        end
      end
      for _, t in ipairs(P.T_KEYS) do
        funcLuaMenuCommand(2735666188 --[[text visible]], L, t, show, 0)
      end
      funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, true)
    end

    -- hide every row layer except those in `keep` (set of layers)
    function P.only(keep)
      for L, cnt in pairs(P.COUNT) do
        if not keep[L] then
          for k = 0, cnt - 1 do
            funcLuaMenuCommand(C.LAYER_VISIBLE, L, k, false)
          end
        end
      end
    end

    function P.move_row(k, skill)
      local R = P.L_MOVE
      PL.open(R, k)
      PL.open(P.L_AI, k)
      funcLuaMenuCommand(C.LAYER_VISIBLE, P.L_AI, k, (skill or 0) ~= 0)
      local ok, err = VRFW.ui_plates.move_plate.fill(R, k, n, skill or 0, {page = P.L_BASE, ai = P.L_AI, open = PL.open,
        restore = {nil, L_DETAIL, 0, nil, nil}})
      if not ok then
        P.log("move row", k, tostring(err))
      end
    end

    -- Draws page 3.
    function P.equip_row(k, kind, item, text)
      local L = P.L_EQUIP
      local d = P.EQ[kind] or P.EQ[5]
      PL.open(L, k)
      for _, pos in ipairs(P.EQ_POS) do
        funcLuaMenuCommand(POSITION_VISIBLE, L, pos, pos == d.pos, k)
      end
      if d.base ~= nil then
        funcLuaMenuCommand(C.SPRITE, L, P.TX_S1108, d.base, d.base, 0, k)
      end
      local cat = d.cat ~= nil
      if cat then
        funcLuaMenuCommand(C.SPRITE, L, P.TX_S1108, d.cat, P.S_EQ_CAT, 0, k)
        funcLuaMenuCommand(C.SPRITE, L, P.TX_S1108, d.gtxt, P.S_EQ_GTXT, 0, k)
      end
      funcLuaMenuCommand(C.MESH_VISIBLE, L, P.M_EQ_CAT, cat, k)
      funcLuaMenuCommand(C.MESH_VISIBLE, L, P.M_EQ_GTXT, cat, k)
      for _, m in ipairs(P.M_EQ_FOCUS) do
        if m ~= d.mesh then
          funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, k)
        end
      end
      funcLuaMenuCommand(2333948100 --[[text style]], L, k, d.text, d.style)
      if item ~= nil and item ~= 0 then
        funcLuaMenuCommand(C.ITEM_ICON, L, k, d.mesh, d.slot or 1875672568 --[[icon_item_dmy01]], item)
        funcLuaMenuCommand(C.MESH_VISIBLE, L, d.mesh, true, k)
      else
        funcLuaMenuCommand(C.MESH_VISIBLE, L, d.mesh, false, k)
      end
      funcLuaMenuCommand(C.TEXT, L, d.text, text or "", k)
      funcLuaMenuCommand(C.LAYER_VISIBLE, L, k, true)
    end

    -- Draws page 4.
    function P.passive_row(k, id, text, grey)
      local L = P.L_PV
      PL.open(L, k)
      for _, pos in ipairs({P.POS_ICON, P.POS_ICON2, P.POS_BUILD, P.POS_TYPE, P.POS_POSITION, P.POS_LOCK}) do
        funcLuaMenuCommand(POSITION_VISIBLE, L, pos, false, k)
      end
      funcLuaMenuCommand(C.MESH_VISIBLE, L, P.M_INHERIT, false, k)
      funcLuaMenuCommand(1233047821 --[[number visible]], L, k, 2330185550, false)
      local t = text or ""
      if id ~= nil and id ~= 0 then
        local eff = SetPreviewCall(SetPreview.PASSIVE, 0, id)
        if type(eff) ~= "number" or eff == 0 then
          local ok, has, e2 = pcall(funcLuaCommand, 4054311845, id)
          eff = (ok and has and type(e2) == "number") and e2 or 0
        end
        local okt, s = pcall(SetPreviewTeamText, id, eff, 1)
        t = okt and s or string.format("%08X", to_u32(id))
        pcall(SwapPassiveSkillEffectIcon, L, k, eff)         -- retail icon + archetype icon(s)
      end
      if grey then
        t = P.GREY_ON .. t .. P.GREY_OFF
      end
      funcLuaMenuCommand(C.TEXT, L, P.T_PASSIVE, t, k)
      funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_VISIBLE@ --[[text visible]], L, P.T_PASSIVE, true, k)
      funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, L, k, 2274335502 --[[lock]], 0)
      funcLuaMenuCommand(C.LAYER_VISIBLE, L, k, true)
    end

    -- Draws page 5.
    function P.six_row(item)
      local L = P.L_SIX
      PL.open(L, 0)
      local has = item ~= nil and item ~= 0
      funcLuaMenuCommand(POSITION_VISIBLE, L, 1517329426 --[[_pos_base01]], has, 0)
      funcLuaMenuCommand(POSITION_VISIBLE, L, 2020757070 --[[_pos_blank01]], not has, 0)
      funcLuaMenuCommand(C.MESH_VISIBLE, L, P.M_SIX_FOCUS, false, 0)
      if has then
        pcall(UpdateSixSenseLayerInfoForItemId, L, 0, item, true)
      else
        funcLuaMenuCommand(C.TEXT, L, P.T_SIXTH, "", 0)
        funcLuaMenuCommand(C.TEXT, L, P.T_FLAVOR, "", 0)
      end
      funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, true)
    end

    -- Returns the stats the player would have with set p.
    function P.set_stats(p)
      local cur = PL.equip_ids()
      local out = {}
      for t = 0, 6 do
        local shown = funcLuaCommand(C.CHARA_GET, n, 14 + t, true)
        shown = type(shown) == "number" and shown or 0
        local bonus = 0
        for k = 1, 5 do
          for sign, id in pairs({[-1] = cur[k] or 0, [1] = (p.equip or {})[k] or 0}) do
            if id ~= 0 then
              local ok, has, v = pcall(funcLuaCommand, P.EQUIP_PARAM, id, t)
              if ok and has and type(v) == "number" then
                bonus = bonus + sign * v
              end
            end
          end
        end
        out[t] = {shown = shown, set = math.max(0, shown + bonus)}
      end
      return out
    end

    -- Returns the 8 values of the player page's gauge rows (its group order) with set p.
    function P.set_values(p, G)
      local ok, v = pcall(G.values, n)
      if not ok or type(v) ~= "table" then
        return nil
      end
      local stats = P.set_stats(p)
      local out = {}
      for g = 1, 8 do
        local si = G.STAT[g]
        local s = si ~= nil and stats[si] or nil
        out[g] = (v[g] or 0) + (s ~= nil and (s.set - s.shown) or 0)
      end
      return out
    end

    function P.moves_place()
      local G = P.player_page()
      if G ~= nil and type(G.moves_layout) == "function" then
        G.moves_layout(P.L_BASE, {P.L_MOVE})
      end
    end

    -- the passive rows as the player page's strips (slots shown, slot 0 unfilled = no text on it)
    function P.draw_strips(slots, noSpecial)
      P.strips = {slots, noSpecial}
      local G = P.player_page()
      if G ~= nil and type(G.passive_strips) == "function" then
        G.passive_strips(P.L_PV, slots, nil, noSpecial)
      end
    end

    -- the equipment rows in the player page's grid, the role plate above it
    function P.grid()
      local G = P.player_page()
      if G == nil or type(G.equip_grid) ~= "function" then
        return
      end
      G.equip_grid(P.L_EQUIP, true)
      funcLuaMenuCommand(C.POS, P.L_EQUIP, P.ROLE_AT[1], P.ROLE_AT[2], 0, 5)
      funcLuaMenuCommand(C.SCALE, P.L_EQUIP, G.EQUIP_SCALE, G.EQUIP_SCALE, 1, 5)
    end

    function P.draw_page(p)
      local old = PL.txt(PL.TX.SET_OLD)
      local G = P.player_page()
      P.no_radar()
      if G ~= nil and type(G.show_values) == "function" then
        local vals = P.page == P.PG.STATS and P.set_values(p, G) or nil
        pcall(G.show_values, vals, vals ~= nil and n or nil)
      end
      if P.page == P.PG.STATS then
        P.only({})
      elseif P.page == P.PG.MOVES then
        P.only({[P.L_MOVE] = true, [P.L_AI] = true})
        for k = 0, 5 do
          P.move_row(k, p.moves[k + 1] or 0)
        end
        funcLuaMenuCommand(C.LAYER_VISIBLE, P.L_MOVE, 6, false)
        funcLuaMenuCommand(C.LAYER_VISIBLE, P.L_AI, 6, false)
        P.moves_place()
      elseif P.page == P.PG.HIPER then
        P.only({})
        local h, shown = p.hiper or 0, false
        if h ~= 0 then
          local _, ti = GetSoccerTeamInfo(0)
          local okh, r = pcall(PL.hiper_show, h, ti)   -- the plate Hiper page's recipe
          shown = okh and r == true
          if not okh then
            P.log("hiper page", tostring(r))
          end
        end
        if not shown then
          P.move_row(6, 0)                             -- no Hiper: the retail blank row
        end
      elseif P.page == P.PG.EQUIP then
        P.only({[P.L_EQUIP] = true})
        for k = 1, 4 do
          local it = p.equip[k] or 0
          P.equip_row(k - 1, k - 1, it, it ~= 0 and PL.item_name(it) or "")
        end
        if p.role ~= nil then
          P.equip_row(5, 5, PL.ROLE_ITEM[p.role], PL.txt(PL.TX.ROLE_NOW, PL.role_name(p.role)))
        else
          P.equip_row(5, 5, 0, P.GREY_ON .. PL.txt(PL.TX.ROLE_NOW, old) .. P.GREY_OFF)
        end
        P.grid()
      elseif P.page == P.PG.PASSIVES then
        P.only({[P.L_PV] = true})
        if p.passives == nil then
          P.passive_row(0, nil, PL.txt(PL.TX.PV_TITLE, old), true)
          for k = 1, 4 do
            funcLuaMenuCommand(C.LAYER_VISIBLE, P.L_PV, k, false)
          end
          P.draw_strips({0}, false)
        else
          for k = 1, 5 do
            local id = p.passives[k] or 0
            P.passive_row(k - 1, id, "---", id == 0)
          end
          local G = P.player_page()
          if G ~= nil and type(G.PSUB) == "table" then
            P.psub = G.PSUB[P.psub] ~= nil and P.psub or 0
            P.draw_strips(G.PSUB[P.psub], (p.passives[1] or 0) == 0)
          end
        end
      else
        P.only({[P.L_SIX] = true})
        P.six_row(p.sixsense or 0)
      end
    end

    -- Draws entry e (P.drawing).
    function P.draw(e)
      P.drawing = true
      local ok, r = pcall(P.draw_now, e)
      P.drawing = false
      if not ok then
        error(r, 0)
      end
      return r
    end

    function P.draw_now(e)
      PL.detail_hide_all()                            -- the other panels (and ours, reset)
      P.focus = e
      if e.p == nil then
        -- Handles an empty set.
        P.frame(false)
        P.only({[P.L_PV] = true})
        P.no_radar()
        local G = P.player_page()
        if G ~= nil and type(G.show_values) == "function" then
          pcall(G.show_values, nil)
        end
        P.passive_row(1, nil, PL.txt(PL.TX.SET_HINT_1))
        P.passive_row(2, nil, PL.txt(PL.TX.SET_HINT_2))
        for _, k in ipairs({0, 3, 4}) do
          funcLuaMenuCommand(C.LAYER_VISIBLE, P.L_PV, k, false)
        end
        P.draw_strips({1, 2}, false)
      else
        P.frame(true)
        P.draw_page(e.p)
      end
      P.shown = true
      return true
    end

    -- L2 / R2 and left / right
    function P.step(e)
      if e == nil or e.p == nil then
        return false
      end
      local G = P.player_page()
      if P.page == P.PG.PASSIVES and PL.key(P.K_R3) and G ~= nil and type(G.PSUB_N) == "number" then
        P.psub = (P.psub + 1) % G.PSUB_N
        funcLuaCommand(C.SE, 2500047763 --[[sy0005 cursor]])
        local ok, err = pcall(P.draw, e)
        if not ok then
          P.log("sub-page draw error", tostring(err))
        end
        return true
      end
      local dir = 0
      if PL.key(P.K_L1) or PL.key(P.K_LEFT) then
        dir = -1
      elseif PL.key(P.K_R1) or PL.key(P.K_RIGHT) then
        dir = 1
      end
      if dir == 0 then
        return false
      end
      P.page = (P.page - 1 + dir) % P.PAGES + 1
      funcLuaCommand(C.SE, 2500047763 --[[sy0005 cursor]])
      local ok, err = pcall(P.draw, e)
      if not ok then
        P.log("page draw error", tostring(err))
      end
      return true
    end

    -- Runs one redraw of the focused set, asked by OnOpenLayer of an instance of ours.
    function P.flush_redraw()
      if not P.redraw then
        return
      end
      P.redraw = false
      if P.shown and P.focus ~= nil then
        local ok, err = pcall(P.draw, P.focus)
        if not ok then
          P.log("draw on open error", tostring(err))
        end
      end
    end

    P.prevPopList = PL.pop_list
    function PL.pop_list(list, init, mode)
      if mode ~= nil and mode.focus == PL.set_focus and mode.step == nil and P.exists() then
        mode.step = P.step
        local tick = mode.tick
        mode.tick = function()
          P.flush_redraw()
          if tick ~= nil then
            tick()
          end
        end
      end
      return P.prevPopList(list, init, mode)
    end

    P.prevFocus = PL.set_focus
    function PL.set_focus(e)
      if P.exists() and e.kind == nil then
        local ok, err = pcall(P.draw, e)
        if ok then
          return
        end
        P.log("draw error", tostring(err))
        pcall(P.hide)
      end
      return P.prevFocus(e)
    end

    -- Every other panel starts with PL.detail_hide_all.
    P.prevHideAll = PL.detail_hide_all
    function PL.detail_hide_all(...)
      if P.shown then
        pcall(P.hide)
      end
      return P.prevHideAll(...)
    end

    -- Handles the list closing without another panel being drawn.
    P.prevSets = PL.sets_coroutine
    function PL.sets_coroutine(...)
      P.page = 1
      P.redraw = false
      local r = P.prevSets(...)
      P.redraw = false
      if P.shown then
        pcall(P.hide)
        PL.hiper_wide = false
        pcall(CharacterReforged.skill_table_detail_graph_sync)
        pcall(UpdateEquipItemInfo)
      end
      return r
    end

    -- The mod's layers stay hidden until the list draws them.
    P.prevSetup = OnSetupLayer
    OnSetupLayer = function(a1, a2, ...)
      if a1 == P.L_BASE or P.COUNT[a1] ~= nil then
        if a1 == P.L_BASE then
          for _, a in ipairs(P.RADAR_MINE) do           -- the radar stays on the screen's status base until a page
            funcLuaMenuCommand(P.ATTACH, a1, a2, a, false)
          end
        end
        funcLuaMenuCommand(Priority, a1, a2, a1 == P.L_BASE and 656 or (a1 == P.L_AI and 659 or 658), true)
        funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
        return
      end
      return P.prevSetup(a1, a2, ...)
    end

    -- The mod's layers open on their first draw (PL.open) and the open resets their look.
    P.prevOpen = OnOpenLayer
    OnOpenLayer = function(a1, a2, ...)
      local r = table.pack(P.prevOpen(a1, a2, ...))
      if P.shown and P.focus ~= nil and (a1 == P.L_BASE or P.COUNT[a1] ~= nil) then
        funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
        P.redraw = true
      end
      return table.unpack(r, 1, r.n)
    end
  end
  CharacterReforged.set_preview_screen.install()
end
-- ===== EVT pset_preview END =====
