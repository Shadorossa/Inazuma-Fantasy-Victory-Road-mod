-- ===== EVT plate_pages plate BEGIN =====
;(function()
@HOST@
@COMMON@
end)()
;(function()
  for _, fname in ipairs((CharacterReforged.PLAYER_PAGE_HOST == nil or CharacterReforged.PLAYER_PAGE_HOST.pages ~= false)
      and {"ChangePersonalPlatePageByCharaHdl", "ChangePersonalPlatePageByCharaParamId"} or {}) do
    -- This wrap chains the page_change of every declared page, so a page does not wrap the page change itself.
    if VRFW.player_pages ~= nil then
      VRFW.player_pages.set_page_change_owner("CharacterReforged")
    end
    VRFW.host.wrap(fname, function(cur)
      return function(a1, a2, ...)
        local call = cur
        local P = VRFW.player_pages
        if type(P) == "table" and type(P.resolve) == "function" then
          for _, d in ipairs(P.resolve()) do
            if type(d.page_change) == "function" then
              local under, change = call, d.page_change
              call = function(b1, b2, ...)
                return change(fname, under, b1, b2, ...)
              end
            end
          end
        end
        return call(a1, a2, ...)
      end
    end)
  end
end)()
CharacterReforged.player_page = CharacterReforged.player_page or {}
;(function()
  local G = CharacterReforged.player_page
  G.PAGE = 878737202                     -- team11_01_personal_plate (drawType 1 in this screen)
  G.BAND = @crc:cr_pp_band@
  G.BAR = @crc:cr_pp_stat_bar@
  -- The host's own layer names (host_plate.lua and host_equip.lua).
  G.H = CharacterReforged.PLAYER_PAGE_HOST or {plate = 1844915256, status = 730911947, graph = 1572892955, radar = 3868632847, pages = true}
  local item_only_points = G.H.item_only and {SetupItemPositionIcon = true, ClearItemPositionIcon = true, OnSetupLayer = true,
    OnOpenLayer = true, OnBack = true, FuncOnBack = true, PostStep = true, [G.H.frame_hook or "Step"] = true} or nil
  local function PlayerPageWrap(name, make)
    if item_only_points ~= nil and not item_only_points[name] then
      return false
    end
    return VRFW.host.wrap(name, make, {level = 2})
  end
  G.PLATE = G.H.plate
  G.STATUS = G.H.status                  -- the status base
  G.GRAPH = G.H.graph                    -- the radar base (the 8-axis copy: object redirected on every host)
  G.RADAR = G.H.radar                    -- the radar polygon layer
  G.EXTRA = 1008264200                   -- cr_soccer11_06_9x_formation_status_graph_extra (Suerte)
  G.NUM = 732343773                      -- soccer11_06_p1_formation_status_graph_param_num
  if G.H.pages == false then
    -- The chart is the added layer cr_pp_graph_host (placed by G.host_chart).
    G.GRAPH = @crc:cr_pp_graph_host@
    G.RETAIL_GRAPH = G.H.graph
    G.EXTRA = @crc:cr_pp_graph_hostx@    -- Suerte's label layer (host copy)
    G.NUM = @crc:cr_pp_num_host@         -- our 8 numbers (the retail param_num 732343773 stays, hidden)
    G.RETAIL_NUM = 732343773
    G.CHART_AT = G.H.chart_at or {1452, 746}  -- the chart's centre on the card (screen; the added layers are unattached)
  end
  G.N_ATC_NUM = {@crc:_atc_num01@, @crc:_atc_num02@, @crc:_atc_num03@, @crc:_atc_num04@, @crc:_atc_num05@,
    @crc:_atc_num06@, @crc:_atc_num07@, @crc:_atc_num07@}       -- group g's value locator (g 8 on the extra layer)
  G.N_EXPLAIN = 499981750
  G.M_PAGE = 2757749471
  G.M_PORTRAIT = 3562698908
  G.M_BAND = 2233169001
  G.M_FLAVOR = 698230623
  G.M_PARAM = {62066836, 2595897646}
  G.M_POLY = {3874402962, 2948969189}    -- soccer11_07: _graph01, _parameter_base_icon01
  G.M_T_PARAM = {254458604, 2518936406}
  G.M_T_SIXTH = 1621221814
  G.TX_S1105 = 1156047165                -- #/menu/00_soccer/soccer11/soccer11_05/<LG>/soccer11_05.g4tx
  G.SP_SIXTH = 2885965654                -- gtxt_sixthsense01 (swap node of the title mesh)
  G.SP_MOVES = 3208790837                -- cr_gtxt_psmoves01 (Character Reforged images soccer11_05.toml)
  G.SLANT = @crc:cr_pp_slant@
  -- (Character Reforged's header layout)
  G.SLANT_RARITY = 1052197874
  -- The rarity banner is kept out of reach.
  G.SLANT_RARITY_NODE = 1457835367
  G.HIDDEN_SCALE = 0.01
  G.DOTS = @crc:cr_pp_dots@
  G.DOT_TRACE = {[0] = @crc:cr_pp_dots0@, @crc:cr_pp_dots1@, @crc:cr_pp_dots2@, @crc:cr_pp_dots3@,
    @crc:cr_pp_dots4@, @crc:cr_pp_dots5@}
  -- Dot positions per sub-page (instances 2.., the current one lit).
  G.PSUB_DOT_X = {[2] = 1622, [3] = 1650, [4] = 1678}
  G.PSUB_KEY_X = 1584
  G.N_BTN_R = 59628764
  G.DOT_OFF = {3784855471, 2788701567, 2606243023, 695779551, 1007698216, 2986517796}
  G.DOT_ON = {2540064569, 2996782795, 2245255383, 1030719410, 2696462091, 4121092084}
  G.DOTS_MAX = 8
  G.DOT_X = {1489, 1517}                 -- slots 7 / 8 (layout: x0 1321, pitch 28)
  G.DOT_PITCH = G.DOT_X[2] - G.DOT_X[1]
  -- The Q and E glyphs' joints (_text_btn_l01 and _text_btn_r01) and their layout x (player_page_layout.toml).
  G.KEY_NODES = {355816102, 59628764}
  G.KEY_X = {-77, 195}
  G.DOTS_LOCS = {3407216458, 1377611504, 622567014, 3145665477, 1753514051, 790952595, 442049775, 1056264686,
    2946906320, 1437140403}              -- every _pos_page* / _pos_equip* / arrow locator of the copies
  G.M_DOT_OFF1, G.M_DOT_ON1 = 3784855471, 2540064569
  G.DOTS_HIDE = {2788701567, 2606243023, 695779551}
  G.hdl = G.hdl or nil
  G.rateInit = {}
  -- Equipamiento (type 0).
  G.EQUIP = 2994084190                   -- soccer11_08_formation_chara_equip_item
  -- the content band (page copy body, sprite swapped), the bars' sprite, the arrows
  G.TX_T1101, G.SP_BODY = 3044635609, 228499307
  G.SP_BAND = @crc:cr_pp_band_fixed@
  G.BAND_ON = {[9] = true, [5] = true, [0] = true, [1] = true, [2] = true, [3] = true, [6] = true}
  G.STAT_FILL = {"fw", "fw_mf", "df_mf", "gk", "gk_df", "gk_df", "fw_mf", "all"}
  G.N_FRONT, G.N_SIDE, G.N_TOP = 1837325853, 2609329121, 1257514352
  G.TAG = @crc:cr_pp_tag@
  G.SP_SLANTBOX = @crc:cr_pp_slantbox@
  G.SP_SLANTBOX2 = @crc:cr_pp_slantbox_wide@
  G.BUILD_GUIDE = 634073741              -- mainmenu01_19_show_common_drop_chara_build_type_guide
  -- over the transfer office (its own model and description) none of ours
  G.SHOP_MENU = 3170360552               -- shop_menu
  G.SKILL, G.SKILL_BLANK = 1580043721, 3216046680                  -- soccer11_09 (+ _p1 blank) x 6
  G.SLOT_NODES = {1833019645, 4098423111, 2203044305}
  G.SLOT_RETAIL = {{-18, -79}, {-18, -203}, {-18, -327}}
  G.SK_HIDE_MESH = {4282364172, 559600405, 1206374040, 148027488}
  G.SK_SHOW_MESH = {4282364172, 559600405, 148027488}
  G.SK_HIDE_NODE = {4081284803, 2244819350}
  G.SK_TEXT = 3359986143
  G.FOCUS_ACTIVE, G.FOCUS_IDX = @crc:CMND_IS_CTRL_FOCUS_ACTIVE@, 2603265800
  G.TX_BTL0613, G.SP_FRAME, G.SP_BAR = 1191797350, 538967808, @crc:cr_pp_bar01@
  -- Character Reforged's own atlas character_reforged_page
  G.TX_OWN = 168065525
  G.M_ARROWS = {1811606789, 2448805990}
  G.EQUIP_SCALE = 0.72                   -- 409 px wide (inside the white card)
  G.L3 = {CHECK = @crc:CMND_CHECK_INPUT_CMD@, CTRL = 1332654303, CTRL_AN = 2748927068, CMD = 579943758}
  G.frame, G.l3last = 0, -100
  -- Every page title mesh of the status base (all hidden).
  G.M_TITLES = {254458604, 2518936406, 301770119, 1621221814}
  G.M_SLOTS = {@crc:_cmd_slot01@, @crc:_cmd_slot02@, @crc:_cmd_slot03@, @crc:_cmd_slot01_rpg@, @crc:_cmd_slot02_rpg@,
    @crc:_cmd_slot03_rpg@}
  G.GROUP_ROW = {0, 1, 3, 5, 6, 4, 2, 7}
  G.STAT = {0, 2, 5, 6, 4, 3, 1, 8}
  local C = {EXIST = @crc:CMND_IS_EXIST_LAYER@, OPEN = @crc:CMND_OPEN_LAYER@, IS_OPEN = @crc:CMND_IS_OPEN_LAYER@, LOADING = @crc:CMND_IS_LOADING_LAYER@, VIS = @crc:CMND_SET_LAYER_VISIBLE@,
    IS_VIS = @crc:CMND_IS_LAYER_VISIBLE@, POS = @crc:CMND_SET_LAYER_LOCAL_POS@, SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@, MESH = @crc:CMND_SET_MESH_VISIBLE@, TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@,
    RATE_INIT = 541357333, RATE = 1595998683, SPRITE = 558735651, TEXT_VIS = @crc:CMND_SET_MENU_TEXT_VISIBLE@, NODE_VIS = 2158717427,
    SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@, PRIM_VIS = 1233047821, NODE_POS = 2575768773, NODE_SCALE = 2885415772,
    CHARA = 1131797651,
    LOG = @crc:CMND_VRFW_LOG@}
  local G_X, G_Y, G_W, G_H = 94, -816, 476, 44          -- btl06_13 gauge frame _hp_base01
  local RATE_BAR, RATE_RED = 3060237847, 2546116024
  local MESH_LABEL, MESH_EMPTY = 1257514352, 2609329121
  local MESH_FRAME, MESH_FILL = 1837325853, 2043683848
  G.ptype = G.ptype or nil
  G.vals = G.vals or nil
  G.ready = G.ready or {}
  G.busy = false

  --@lib vrfw_menu_kit.lua#Pack,Cmd

  local function On()
    return CharacterReforged.PLATE_PAGES == true
  end

  local function Exists(l)
    return Cmd(C.EXIST, l) == true
  end

  -- Calls a per-frame or event piece by name.
  G.tryLogged, G.tryOff = G.tryLogged or {}, G.tryOff or {}
  function G.try(name, ...)
    if G.tryOff[name] then
      return nil
    end
    local f = G[name]
    if type(f) ~= "function" then
      if not G.tryLogged[name] then
        G.tryLogged[name] = true
        pcall(funcLuaCommand, C.LOG, "PlayerPage call " .. name .. ": no such function")
      end
      return nil
    end
    local ok, a, b = pcall(f, ...)
    if not ok then
      if not G.tryLogged[name] then
        G.tryLogged[name] = true
        pcall(funcLuaCommand, C.LOG, "PlayerPage call " .. name .. " failed: " .. tostring(a))
      end
      if string.sub(name, 1, 9) == "item_card" then
        G.tryOff[name] = true
      end
      return nil
    end
    return a, b
  end

  -- Returns whether a layer that this block opens is ready.
  local function Ready(l, k)
    if G.hostShut then
      return false                         -- the host menu is closing, nothing of ours (re)opened
    end
    if Cmd(C.IS_OPEN, l, k) ~= true then
      G.ready[l * 16 + k] = false
      Cmd(C.OPEN, l, k)
      return false
    end
    return Cmd(C.LOADING, l) ~= true
  end

@PP_BAND@

@PP_DOTS@

@PP_MOVES@

@PP_PASSIVES@

@PP_MOD_PAGES@

@PP_HOST_CHART@

@PP_EMPTY_EQUIPMENT_HIPER@

@PP_STAT_ROWS@

@PP_FORMS@

@PP_GAUGE_COPIES@

@PP_POINTER@

  local function Description(on)
    on = on and not G.in_office()           -- over the transfer office: its own description only
    Cmd(C.NODE_VIS, G.PLATE, G.N_EXPLAIN, on, 0)
    Cmd(C.TEXT_VIS, G.PLATE, G.N_EXPLAIN, on, 0)
    if Cmd(C.IS_OPEN, G.BAND, 0) == true then
      Cmd(C.MESH, G.BAND, G.M_FLAVOR, on, 0)
    end
  end

  function G.apply(ptype)
    -- A form look belongs to the page that chose it.
    if G.ptype ~= nil and ptype ~= G.ptype and type(CharacterReforged.page_model) == "table" and type(CharacterReforged.page_model.reset_form) == "function" then
      pcall(CharacterReforged.page_model.reset_form, "page " .. tostring(G.ptype) .. " -> " .. tostring(ptype), true)
    end
    G.ptype = ptype
    CharacterReforged.PAGE_MODEL_PAGE_OK = true                -- the model on every page, behind the content
    CharacterReforged.PAGE_MODEL_PAGE_FORMS = (ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE)   -- R3 cycles the forms on PERFIL
    local desc, stats, moves = ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE, ptype == CharacterReforged.PLAYER_PAGE_STATS_TYPE, ptype == 1
    if desc or stats then
      pcall(SetVisibleSkillItemLayer, false)
    end
    if not stats then                      -- the chart only on ATRIBUTOS (the equipment pages showed the radar)
      pcall(SetVisibleGraphLayer, false)
      if type(CharacterReforged.stat_radar) == "table" and type(CharacterReforged.stat_radar.visible) == "function" then
        pcall(CharacterReforged.stat_radar.visible, false)
      end
      BarsVisible(false)
    end
    for _, m in ipairs(G.M_PARAM) do
      Cmd(C.MESH, G.PAGE, m, false, 0)
    end
    HidePoly()
    Decor(ptype)
    Description(desc)
    if ptype ~= 5 then
      CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW = false
    end
    G.equip()
    G.bars()
    G.dots()
    pcall(G.moves)
  end

  -- Page types 8 and 9 are type 1 adjusted.
  PlayerPageWrap("ChangePersonalPlatePageByCharaHdl", function(orig)
    return function(a1, a2, ...)
      if not On() or not G.H.pages then
        return orig(a1, a2, ...)
      end
      local base = (a2 == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE or a2 == CharacterReforged.PLAYER_PAGE_STATS_TYPE) and 1 or a2
      local r = Pack(orig(a1, base, ...))
      local ok, err = pcall(G.apply, a2)
      if not ok then
        pcall(funcLuaCommand, C.LOG, "plate_pages apply error", tostring(err))
      end
      return table.unpack(r, 1, r.n)
    end
  end)
  PlayerPageWrap("ChangePersonalPlatePageByCharaParamId", function(orig)
    return function(a1, a2, ...)
      if not On() or not G.H.pages then
        return orig(a1, a2, ...)
      end
      local base = (a2 == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE or a2 == CharacterReforged.PLAYER_PAGE_STATS_TYPE) and 1 or a2
      local r = Pack(orig(a1, base, ...))
      pcall(G.apply, a2)
      return table.unpack(r, 1, r.n)
    end
  end)

  -- the radar's values -> the bars (whichever page shows the radar)
  PlayerPageWrap("UpdateCharaParameterGraphByCharaStHdl", function(orig)
    return function(a1, a2, a3, ...)
      local r = Pack(orig(a1, a2, a3, ...))
      if On() and a1 == G.RADAR and not G.hostShut then
        -- Draws the chart for hosts.
        if not G.H.pages and (G.H.chart ~= false or G.override ~= nil) and Exists(G.GRAPH) and Exists(G.NUM)
            and not G.filling then
          G.filling = true
          pcall(orig, a1, G.NUM, a3, G.GRAPH)
          G.filling = false
          G.overrideDrawn = false
          G.rowMarkKey = {}
        end
        local rest = Pack(...)
        local okv, v = pcall(G.values, a3, rest[5])
        if okv then
          G.vals = G.override or v
          pcall(G.read_tops, a3)
          pcall(G.mx_gains, a3)
        end
        pcall(HidePoly)
        pcall(G.bars)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  -- Runs on every refresh of the header plate.
  PlayerPageWrap("UpdateCharaStatusPlateInfoByCharaStHdl", function(orig)
    return function(a1, a2, a3, ...)
      local r = Pack(orig(a1, a2, a3, ...))
      if not G.busy and a1 == G.PLATE and (a2 == nil or a2 == 0) then
        G.hdl = a3
        pcall(G.player_refresh, a3)
        pcall(G.slant_fill)
        if G.H.pages and On() then
          G.try("sixth")             -- the own passive card follows the player at once, as the header does
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  -- Runs every frame.
  G.IDLE_MENUS = {449578137 --[[general_window]], 1810526795 --[[ability_learning_board_menu]],
    @crc:ability_list_menu@, @crc:chara_bank_menu_for_search@}
  function G.host_idle()
    if CharacterReforged.PLAYER_PAGE_HOST_OFF == true then
      return "off"
    end
    for _, m in ipairs(G.IDLE_MENUS) do
      local ok, v = pcall(funcLuaCommand, @crc:CMND_IS_EXIST_MENU@, m)
      if ok and v == true then
        return string.format("menu %08X", m)
      end
    end
    return nil
  end
  -- Handles the host menu closing.
  G.HOST_LAYERS = {G.BAND, G.SLANT, G.TAG, G.BAR, G.EXTRA, G.GRAPH, G.NUM}
  local CMD_IS_CLOSING_MENU, CMD_IS_CLOSED_MENU = @crc:CMND_IS_CLOSING_MENU_OBJECT@, @crc:CMND_IS_CLOSE_MENU_OBJECT@   -- CMND_IS_CLOSING / CLOSE_MENU_OBJECT
  function G.host_closing()
    local m = G.H.menu
    if type(m) == "function" then
      m = m()
    end
    if m == nil then
      return false
    end
    local ok1, c1 = pcall(funcLuaCommand, CMD_IS_CLOSING_MENU, m)
    local ok2, c2 = pcall(funcLuaCommand, CMD_IS_CLOSED_MENU, m)
    return (ok1 and c1 == true) or (ok2 and c2 == true)
  end
  -- CMND_CLOSE_LAYER(layer, instance) closes one instance (default 0)
  function G.host_close_ours(why)
    local n, inst = 0, 0
    for _, l in ipairs(G.HOST_LAYERS) do
      if Exists(l) then
        local open = false
        for k = 0, 63 do
          if Cmd(C.IS_OPEN, l, k) == true then
            Cmd(C.VIS, l, k, false)
            Cmd(@crc:CMND_CLOSE_LAYER@ --[[CMND_CLOSE_LAYER]], l, k)
            open = true
            inst = inst + 1
          end
        end
        if open then
          n = n + 1
        end
      end
    end
    G.ready = {}
    G.rateInit = {}
    pcall(funcLuaCommand, C.LOG, "PlayerPage host closed ours", tostring(why), n, "layers", inst, "instances")
  end
  -- Shuts the block down when the host menu closes.
  function G.host_shut(why)
    if G.hostShut then
      return
    end
    G.hostShut = true
    pcall(funcLuaCommand, C.LOG, "PlayerPage host shut", tostring(why))
    pcall(G.host_close_ours, why)
  end
  function G.host_hide()
    for _, l in ipairs({G.BAND, G.SLANT, G.TAG}) do
      if Exists(l) and Cmd(C.IS_OPEN, l, 0) == true then
        Cmd(C.VIS, l, 0, false)
      end
    end
    BarsVisible(false)
  end

  -- The per-frame body runs after the screen's PostStep.
  function G.frame_wrap(orig)
    return function(...)
      local r = Pack(orig(...))
      G.frameSteps = (G.frameSteps or 0) + 1
      if not G.H.pages and CharacterReforged.PLAYER_PAGE_HOST_OFF == true then
        return table.unpack(r, 1, r.n)          -- the block off on this host: the screen exactly as retail
      end
      -- Applies to every host, the paged player page too.
      local okC, closing = pcall(G.host_closing)
      if okC and closing then
        G.try("host_shut", "closing")            -- never Ready() / reopen anything while the host menu closes
        return table.unpack(r, 1, r.n)
      elseif G.hostShut then
        G.hostShut = false                      -- the close did not happen (a back swallowed): drawn again
        pcall(funcLuaCommand, C.LOG, "PlayerPage host reopened")
      end
      if not G.H.pages then
        local okI, why = pcall(G.host_idle)
        why = okI and why or nil
        if why ~= G.hostIdle then
          G.hostIdle = why
          pcall(funcLuaCommand, C.LOG, why and ("PlayerPage host idle " .. why) or "PlayerPage host active")
          -- A dialog (general_window) only pauses this block (the added layers stay under its dimmer).
          if why and why ~= string.format("menu %08X", 449578137 --[[general_window]]) then
            G.try("host_hide")
          end
        end
        if why then
          return table.unpack(r, 1, r.n)
        end
      end
      if G.H.item_only then
        -- Handles a screen with only the item card (inventory, shop).
        if G.itemCardPending then
          G.try("item_card_pending")
        end
        G.try("item_card_input")
        return table.unpack(r, 1, r.n)
      end
      if G.H.pages then
        G.try("empty")
        -- the six-sense decoration _sixth_base01 off on every page
        if On() and Exists(G.STATUS) and Cmd(C.IS_OPEN, G.STATUS, 0) == true then
          Cmd(C.MESH, G.STATUS, @crc:_sixth_base01@, false, 0)
        end
      else
        if G.ptype == nil then
          G.ptype = G.H.fixed              -- a host without pages: the chart page's look
        end
        -- the same decoration off on the hosts' status base
        if On() and Exists(G.STATUS) and Cmd(C.IS_OPEN, G.STATUS, 0) == true then
          Cmd(C.MESH, G.STATUS, @crc:_sixth_base01@, false, 0)
        end
      end
      G.try("band")
      G.try("slant")
      G.try("tag")
      G.try("hide_unplaced_gauge_copies")
      if On() and Exists(G.BUILD_GUIDE) and Cmd(C.IS_OPEN, G.BUILD_GUIDE, 0) == true then
        Cmd(C.VIS, G.BUILD_GUIDE, 0, false)
      end
      if On() then
        if G.ptype ~= nil and G.H.pages then
          pcall(Decor, G.ptype)
        end
        G.try("bars")
        G.try("passive_card_step")     -- the own passive card's face (skill table and player page)
        if G.H.pages then
          G.try("dots")
          G.try("mx_step")
          G.try("hiper_form_step")
          G.try("equip")
          G.try("hiper_l3")
          G.try("moves")
          G.try("moves_nav")
          G.try("hint")
          G.try("form_badge")
          G.try("passives")
          G.try("passive_rows")
          G.try("mod_pages")          -- pages other mods declare and draw (parts/mod_pages.lua)
          G.try("sixth")
          local okP, errP = pcall(G.pointer)
          if not okP and not G.ptrErr then
            G.ptrErr = true
            pcall(funcLuaCommand, C.LOG, "PlayerPage pointer error", tostring(errP))
          end
        else
          G.try("host_numbers")
          if G.itemCardPending then
            G.try("item_card_pending") -- the item card's layout when its layer opened after the last fill
          end
          G.try("item_card_input")     -- L2 / R2 on a paged item card
        end
        if not G.keep_radar() then
          pcall(HidePoly)
        end
        if G.ptype ~= nil then
          pcall(Description, G.ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE)
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end
  G.FRAME_HOOK = "PostStep"
  if not G.H.pages and type(G.H.frame_hook) == "string" and type(rawget(_ENV, "PostStep")) ~= "function" then
    G.FRAME_HOOK = G.H.frame_hook
  end
  PlayerPageWrap(G.FRAME_HOOK, G.frame_wrap)
  if not G.H.pages then
    for _, fname in ipairs({"OnBack", "FuncOnBack"}) do
      PlayerPageWrap(fname, function(orig)
        return function(...)
          local r = Pack(orig(...))             -- the original first
          pcall(funcLuaCommand, C.LOG, "PlayerPage host " .. fname, tostring((...)))
          local okC, closing = pcall(G.host_closing)
          if G.H.menu == nil or (okC and closing) then
            pcall(G.host_shut, fname)
          end
          return table.unpack(r, 1, r.n)
        end
      end)
    end
  end

  PlayerPageWrap("OnOpenLayer", function(orig)
    return function(a1, a2, ...)
      if a1 == G.SLANT then
        pcall(G.slant_opened, a2)
      end
      local r = Pack(orig(a1, a2, ...))       -- the original first
      if G.H.pages and (a1 == G.SKILL or a1 == G.SKILL_BLANK) and On() and G.ptype == 1 then
        pcall(G.moves)
      end
      pcall(G.forget_gauge_copy, a1, a2)
      if G.item_card_layer ~= nil and a1 == G.item_card_layer then
        G.itemCardPending = true             -- laid out by the next frame (the layer is open by then)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  local IC = not G.H.pages and type(G.H.item_card) == "table" and G.H.item_card or nil
  if IC ~= nil then
@PP_ITEM_CARD@

@PP_ITEM_CARD_LAYERS@

@PP_ITEM_CARD_EFFECT@

@PP_ITEM_CARD_STAT_ROWS@

@PP_ITEM_CARD_SHOW@
  end

  if G.H.pages then
    PlayerPageWrap("OnChangeFocus", function(orig)
      return function(a1, a2, ...)
        local ok, handled = pcall(G.nav_on_change, a1, a2)
        if ok and handled then
          return
        end
        return orig(a1, a2, ...)
      end
    end)
    for _, name in ipairs({"SetSkillCollisionEnable", "UpdateSkillItemHitCollision"}) do
      PlayerPageWrap(name, function(orig)
        return function(a1, ...)
          local r = Pack(orig(a1, ...))         -- the original first
          if name ~= "SetSkillCollisionEnable" or a1 == true then
            pcall(G.nav_zones)
          end
          return table.unpack(r, 1, r.n)
        end
      end)
    end
  end

  PlayerPageWrap("OnCloseLayer", function(orig)
    return function(a1, ...)
      local r = Pack(orig(a1, ...))
      if a1 == G.PAGE then
        G.ready = {}
        G.rateInit = {}
        G.vals = nil
        CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW = false
        BarsVisible(false)
        G.movesOn = true                    -- next page: the slot nodes back to retail
        pcall(G.fb_hide)
        for _, l in ipairs({G.BAND, G.SLANT, G.TAG, G.FLABEL}) do
          if Cmd(C.IS_OPEN, l, 0) == true then
            Cmd(C.VIS, l, 0, false)
          end
        end
      end

      return table.unpack(r, 1, r.n)
    end
  end)

  if G.H.pages then
    function G.dock_offset(l, i)
      local OFS, DEF = 902337421, 753088835       -- offset01, Default
      local id = Cmd(1352645570, l, OFS, i)
      if Cmd(@crc:CMND_IS_END_ANIME@, l, id, DEF, 0, i) ~= true then   -- CMND_IS_END_ANIME of the state-0 clip
        Cmd(1380315136, l, i, OFS, 0, DEF)
        Cmd(@crc:CMND_STOP_ANIME@, l, id, DEF, i)                      -- CMND_STOP_ANIME
      end
      Cmd(@crc:CMND_PLAY_ANIME_TYPE@, l, i, OFS, 2, DEF)                   -- CMND_PLAY_ANIME_TYPE offset01 state 2
      pcall(funcLuaCommand, C.LOG, "PlayerPage match offset", tostring(i))
    end
    PlayerPageWrap("SetPersonalPlateType", function(orig)
      return function(a1, ...)
        G.plateType = a1
        return orig(a1, ...)
      end
    end)
    PlayerPageWrap("OnSetupPersonalPlateLayer", function(orig)
      return function(a1, a2, ...)
        local r = Pack(orig(a1, a2, ...))      -- the original first
        if a1 == G.PAGE and G.plateType == 1 and CharacterReforged.PLAYER_PAGE_MATCH_OFFSET ~= false then
          pcall(G.dock_offset, a1, a2 or 0)
        end
        return table.unpack(r, 1, r.n)
      end
    end)
  end
end)()
-- ===== EVT plate_pages plate END =====
