-- Advanced: List of providers that add badges to a move plate.
if VRFW.ui_plates == nil then
  local U = {
    LOG = 519897777,
    C = {
      EXIST = 262659071, OPEN = 629267548, IS_OPEN = 2640875187, VIS = 711242136, MESH = 3405944500,
      SPRITE = 558735651, NODE_VIS = 2158717427, NODE_POS = 2575768773, NODE_SCALE = 2885415772,
      GET_TRANS = 2491463760, SET_TRANS = 1856671416, TEXT = 1083631230, TEXT_VIS = 1505208242,
      PRIM_VIS = 1233047821, PRIM_INDEX = 1927054058, PRIM_SET = 3609943765, SCALE = 3778714801, POS = 1389957207,
      FONT = 2333948100, ANIME = 3781155141,
      CHARA = 1131797651, SKILL_INFO = 2580586398, SKILL_POS = 26437624, COMMON_SKILL = 800895612,
      NAME_TEXT = 720417636,
    },
  }
  --- Advanced: Namespace of the UI plate helpers shared by the framework menus.
  VRFW.ui_plates = U
  local C = U.C

  local logger
  --- Internal: Logs through the ui logger.
  function U.log(...)
    logger = logger or VRFW.logger.new("vrfw.ui")
    logger(...)
  end

  --- Advanced: The layout table `name`; an empty table when it is not declared.
  function U.layout(name)
    local t = type(VRFW.ui_plates_layout) == "table" and VRFW.ui_plates_layout[name] or nil
    return type(t) == "table" and t or {}
  end

  local HR = {
    POS = 1445889390,              -- _icon_position_status_dmy01 (the position badge)
    ROLE = 260772049,
    SUPPORT = 3892654168,          -- _icon_mark_dmy01 (the supporter mark)
    TX_ICON2 = 2058213660,         -- #/menu/200_icon/15_icon_common2/<LG>/icon_common2.g4tx
    SLOT_POS = 255392163,          -- icon_position_status_dmy01 (the badge's texture slot)
    FRAME = 2273809808,            -- _seasonal_frame01
    LV_NUM = 3434305008,           -- num_status_lv01
    -- the "Lv." label, its lock and the digits' node; the rarity banner's node and mesh
    LV_PARTS = {MESH = 1034363700 --[[_gtxt_status_lv01]], LOCK = 4071435007 --[[_icon_lock_lv01]],
      NODE = 2976428572 --[[_num_status_lv01]]},
    RARITY = {NODE = 1457835367 --[[_pos_rarity01]], MESH = 1052197874 --[[_player_rarity01]]},
    PORTRAIT = 2531809341,         -- _icon_chr_status01 (the portrait icon)
    -- the band strip (a soccer11_04 plate showing only its two band sprites and / or its description box)
    BAND = {263290134, 2528652460},                                  -- _status_chr_base_s01 / _s02
    LOCS = {44923504, 1457835367, 2488990471, 606505850, 16246407, 2641657029},
    -- _pos_basara_offset01, _pos_title01, _pos_back01, _pos_name01
    MESHES = {3562698908, 2531809341, 1670039012, 260772049, 1445889390, 859963845, 893160232, 2606302476,
      3892654168, 2273809808, 1271316493},
    -- seasonal frame, nickname box
    TEXTS = {1704438437, 4238277407, 1006587362, 1768688116},       -- _text_name01 / 02, _text_grade01, _text_title01
    NUMS = {3434305008, 2189811683, 1894841872, 3984446132, 1372193137, 3589359157},   -- its 6 number settings
    OFF = {2531809341, 3562698908, 3892654168},                     -- portrait icon / base, mark: off screen
    EXPLAIN_POS = 3145402165,      -- _pos_explain01
    EXPLAIN_TEXT = 499981750,      -- _text_explain01
    -- the archetype box (a btl06_13 gauge frame copy)
    TX_BTL0613 = 1191797350, SP_FRAME = 538967808,
    BOX_HIDE = {1257514352, 2609329121, 2043683848},   -- _gtxt_stamina01, _hp_empty01, _hp_bar02
    posvis = {},                   -- "layer:inst" -> last visibility of the position badge
    rolevis = {},
    moved = {},
    home = {},                     -- "layer:inst" -> {x, y, z} layout translation of the glyph
  }
  --- Advanced: Header row plate helper: draws the header row of a plate list.
  U.header_row = HR

  --- The state key of (layer, inst).
  function HR.key(layer, inst)
    return tostring(layer) .. ":" .. tostring(inst or 0)
  end

  --- a mesh-visibility call on a row (a menu-command filter forwards them).
  function HR.track(layer, mesh, on, inst)
    if mesh == HR.ROLE then
      HR.rolevis[HR.key(layer, inst)] = on == true
    elseif mesh == HR.POS then
      HR.posvis[HR.key(layer, inst)] = on == true
    end
  end

  HR.POS_TYPE_ICON = {[1] = 0, [2] = 3, [3] = 2, [4] = 1}
  C.CHARA_INFO = 4060384944

  --- The position-type icon of a player param; nil when unknown.
  function HR.param_type(param)
    if type(param) ~= "number" or param == 0 then
      return nil
    end
    local okc, ok, t = pcall(funcLuaCommand, C.CHARA_INFO, param, 11)
    if not okc or ok == false or type(t) ~= "number" then
      return nil
    end
    return HR.POS_TYPE_ICON[t]
  end

  --- The natural position type of a handle: t, or nil, true when it has no type yet.
  function HR.natural_type(hdl)
    if type(hdl) ~= "number" or hdl == 0 then
      return nil
    end
    local ok9, t9 = pcall(funcLuaCommand, C.CHARA, hdl, 9)
    if ok9 and type(t9) == "number" and (t9 < 0 or t9 > 3) then
      return nil, true
    end
    local okp, param = pcall(funcLuaCommand, C.CHARA, hdl, 4)
    local t = okp and HR.param_type(param) or nil
    if t ~= nil then
      return t
    end
    if ok9 and type(t9) == "number" then
      return t9
    end
    return nil
  end

  --- Whether the handle plays in its natural position; nil when unknown, otherwise false, icon or true.
  function HR.natural(hdl)
    if type(GetSoccerCharaPositionIconByPosIconType) ~= "function" then
      return nil
    end
    local t, staff = HR.natural_type(hdl)
    if staff then
      return true
    end
    if t == nil then
      return nil
    end
    local oki, icon = pcall(GetSoccerCharaPositionIconByPosIconType, t)
    if oki and type(icon) == "number" and icon ~= 0 then
      return false, icon
    end
    return nil
  end

  --- Sets the row's badge to `icon`; answers the command's result, false for no icon.
  function HR.badge(layer, inst, icon)
    if icon == nil then
      return false
    end
    return VRFW.host.menu_command(C.SPRITE, layer, HR.TX_ICON2, icon, HR.SLOT_POS, 0, inst or 0)
  end

  --- Fills a row after the retail fill; answers staff, icon.
  function HR.after_fill(layer, inst, hdl, o)
    o = o or {}
    inst = inst or 0
    local staff, icon = o.staff, o.icon
    if o.staff == nil and o.known ~= true then          -- o.known: staff / icon given (nil = unknown character)
      staff, icon = HR.natural(hdl)
    end
    local k = HR.key(layer, inst)
    if o.natural ~= false and staff == false and icon ~= nil and HR.posvis[k] ~= false then
      HR.badge(layer, inst, icon)
    end
    if o.role == false then
      return staff, icon
    end
    HR.moved[k] = false
    VRFW.host.menu_command(C.MESH, layer, HR.SUPPORT, false, inst)
    local home = HR.home[k]
    if home == nil then
      local x, y, z = VRFW.host.menu_command(C.GET_TRANS, layer, inst, HR.ROLE)
      if type(x) ~= "number" or type(y) ~= "number" then
        return staff, icon
      end
      home = {x, y, z or 0}
      HR.home[k] = home
    end
    local L = U.layout("header_row")
    local pw, ph = (L.pos_badge or {68, 46})[1], (L.pos_badge or {68, 46})[2]
    local rw = L.role_glyph or 40
    if HR.posvis[k] == false and staff == false and icon ~= nil then
      HR.badge(layer, inst, icon)
      VRFW.host.menu_command(C.MESH, layer, HR.POS, true, inst)
      VRFW.host.menu_command(C.SET_TRANS, layer, inst, HR.ROLE, home[1], home[2], home[3])
    elseif HR.posvis[k] == false and staff == true then
      HR.moved[k] = true
      local x, y, z = VRFW.host.menu_command(C.GET_TRANS, layer, inst, HR.POS)
      if type(x) == "number" and type(y) == "number" then
        VRFW.host.menu_command(C.SET_TRANS, layer, inst, HR.ROLE, x + (pw - rw) / 2, y - (ph - rw) / 2, z or home[3])
      end
    else
      VRFW.host.menu_command(C.SET_TRANS, layer, inst, HR.ROLE, home[1], home[2], home[3])
    end
    return staff, icon
  end

  --- False when the archetype box of a row is hidden.
  function HR.arch_box_shown(layer, inst)
    local k = HR.key(layer, inst)
    if HR.moved[k] == true then
      return false
    end
    return HR.rolevis[k] ~= false
  end

  --- a dual archetype: the pair command `cmd` (the caller's own command) answers got, _, a, b.
  function HR.dual(hdl, cmd)
    if hdl == nil or cmd == nil then
      return false
    end
    local ok, got, _, a, b = pcall(funcLuaCommand, cmd, hdl)
    return ok and got == true and type(a) == "number" and type(b) == "number" and a >= 0 and a <= 5 and b >= 0
      and b <= 5 and a ~= b
  end

  --- Shows or hides a row's archetype box; answers true when shown.
  function HR.arch_box(tag, layer, inst, hdl, st, o)
    o = o or {}
    if HR.arch_box_shown(layer, inst) == false then
      VRFW.host.menu_command(C.VIS, tag, 0, false)
      return false
    end
    local dual = HR.dual(hdl, o.dual_cmd)
    if st.dual ~= dual then
      st.dual = dual
      local L = U.layout("header_row").arch_box or {}
      local b = (dual and L.box_dual or L.box) or {1042, 175, 81, 40}
      local g = L.gauge or {94, 816, 476, 44}
      VRFW.host.menu_command(C.SPRITE, tag, o.atlas or HR.TX_BTL0613, dual and o.sprite_dual or o.sprite, HR.SP_FRAME, 0, 0)
      local sx, sy = b[3] / g[3], b[4] / g[4]
      VRFW.host.menu_command(C.SCALE, tag, sx, sy, 1, 0)
      VRFW.host.menu_command(C.POS, tag, b[1] - g[1] * sx, -b[2] + g[2] * sy, 0, 0)
    end
    VRFW.host.menu_command(C.VIS, tag, 0, true)
    return true
  end

  --- The box layer's own setup (once per open): only the frame mesh, the box sprite.
  function HR.arch_box_setup(tag, o)
    for _, m in ipairs(HR.BOX_HIDE) do
      VRFW.host.menu_command(C.MESH, tag, m, false, 0)
    end
    VRFW.host.menu_command(C.SPRITE, tag, (o or {}).atlas or HR.TX_BTL0613, (o or {}).sprite, HR.SP_FRAME, 0, 0)
  end

  --- a status plate stripped to keep.band (its two band sprites) / keep.explain (the description box and text).
  function HR.band(layer, inst, keep)
    inst, keep = inst or 0, keep or {}
    for _, n in ipairs(HR.LOCS) do
      VRFW.host.menu_command(C.NODE_VIS, layer, n, false, inst)
    end
    for _, m in ipairs(HR.MESHES) do
      VRFW.host.menu_command(C.MESH, layer, m, false, inst)
    end
    for _, t in ipairs(HR.TEXTS) do
      VRFW.host.menu_command(C.TEXT, layer, t, "", inst)
      VRFW.host.menu_command(C.TEXT_VIS, layer, t, false, inst)
      VRFW.host.menu_command(C.NODE_VIS, layer, t, false, inst)
    end
    for _, n in ipairs(HR.NUMS) do
      VRFW.host.menu_command(C.PRIM_VIS, layer, inst, n, false)
    end
    for _, n in ipairs(HR.OFF) do
      VRFW.host.menu_command(C.NODE_POS, layer, inst, n, 0, -5000)
    end
    for _, m in ipairs(HR.BAND) do
      VRFW.host.menu_command(C.MESH, layer, m, keep.band == true, inst)
    end
    VRFW.host.menu_command(C.NODE_VIS, layer, HR.EXPLAIN_POS, keep.explain == true, inst)
    if keep.explain ~= true then
      VRFW.host.menu_command(C.TEXT, layer, HR.EXPLAIN_TEXT, "", inst)
      VRFW.host.menu_command(C.NODE_VIS, layer, HR.EXPLAIN_TEXT, false, inst)
    end
    VRFW.host.menu_command(C.TEXT_VIS, layer, HR.EXPLAIN_TEXT, keep.explain == true, inst)
  end

  HR.TITLE_REQUEST = 2881088748
  --- Runs fill(...) under pcall with the title commands suppressed; answers pcall's results.
  function HR.without_title(fill, ...)
    local original = funcLuaMenuCommand
    if type(original) ~= "function" then
      return pcall(fill, ...)
    end
    local function filtered(id, ...)
      if id == HR.TITLE_REQUEST and select(3, ...) == HR.RARITY.MESH then
        local args = {n = select("#", ...), ...}
        if args.n < 7 then
          args.n = 7
        end
        if args[7] == nil then
          args[7] = true
        end
        args[6] = false
        return original(id, table.unpack(args, 1, args.n))
      end
      if select(3, ...) == true and ((id == C.MESH and select(2, ...) == HR.RARITY.MESH)
          or (id == C.NODE_VIS and select(2, ...) == HR.RARITY.NODE)) then
        return nil
      end
      return original(id, ...)
    end
    funcLuaMenuCommand = filtered
    local packed = {n = 0}
    local function keep(...)
      packed.n = select("#", ...)
      for i = 1, packed.n do
        packed[i] = (select(i, ...))
      end
    end
    keep(pcall(fill, ...))
    if rawget(_ENV, "funcLuaMenuCommand") == filtered then
      funcLuaMenuCommand = original
    end
    return table.unpack(packed, 1, packed.n)
  end

  --- Fills a status band; answers true, or false when it could not.
  function HR.band_fill(band, inst, hdl, o)
    o = o or {}
    inst = inst or 0
    if hdl == nil or type(UpdateCharaStatusPlateInfoByCharaStHdl) ~= "function" then
      return false
    end
    HR.without_title(UpdateCharaStatusPlateInfoByCharaStHdl, band, inst, hdl)
    local colour = o.colour or rawget(_ENV, "EVT_PC_ColorStatusPlate")
    if type(colour) == "function" then
      pcall(colour, band, inst, hdl)
    end
    HR.band(band, inst, {band = true})
    return true
  end

  -- a row at scale s with its top-left at screen (x, y) (defaults: its layout place at scale 1)
  local function RowAt(s, x, y)
    local L = U.layout("header_row")
    local o = L.row_origin or {957, 163}
    s = s or 1
    x, y = x or o[1], y or o[2]
    return s, x - o[1] * s, y - o[2] * s, x, y
  end

  --- Places a row by scale and position.
  function HR.place(layer, inst, s, x, y)
    local k, dx, dy = RowAt(s, x, y)
    VRFW.host.menu_command(C.SCALE, layer, k, k, 1, inst or 0)
    VRFW.host.menu_command(C.POS, layer, dx, -dy, 0, inst or 0)
  end

  --- Places a band under its row.
  function HR.place_band(band, inst, s, x, y)
    local k, dx, _, _, ry = RowAt(s, x, y)
    local B = U.layout("header_row").band or {}
    local sx, sy = B.sx or 1, B.sy or 1 / 3
    VRFW.host.menu_command(C.SCALE, band, k * sx, k * sy, 1, inst or 0)
    VRFW.host.menu_command(C.POS, band, dx + (B.dx or 46) * k, -(ry - (B.y0 or 164) * sy * k), 0, inst or 0)
  end

  --- a named placement of [header_row.variants.<name>]: s, x, y.
  function HR.variant(name)
    local v = (U.layout("header_row").variants or {})[name] or {}
    return v.s, v.x, v.y
  end

  --- Shows the level digits of a row; answers true, or false without a level.
  function HR.level(layer, inst, level)
    if type(level) ~= "number" or level <= 0 then
      return false
    end
    local prim = VRFW.host.menu_command(C.PRIM_INDEX, layer, inst or 0, HR.LV_NUM)
    if type(prim) == "number" then
      VRFW.host.menu_command(C.PRIM_SET, layer, inst or 0, prim, math.floor(level))
      VRFW.host.menu_command(C.PRIM_VIS, layer, inst or 0, HR.LV_NUM, true)
      VRFW.host.menu_command(C.NODE_VIS, layer, HR.LV_PARTS.NODE, true, inst or 0)
      VRFW.host.menu_command(C.MESH, layer, HR.LV_PARTS.MESH, true, inst or 0)
      VRFW.host.menu_command(C.MESH, layer, HR.LV_PARTS.LOCK, false, inst or 0)
      return true
    end
    return false
  end

  --- a row without a level: the "Lv." label, its lock and the digits off.
  function HR.level_off(layer, inst)
    VRFW.host.menu_command(C.MESH, layer, HR.LV_PARTS.MESH, false, inst or 0)
    VRFW.host.menu_command(C.MESH, layer, HR.LV_PARTS.LOCK, false, inst or 0)
    VRFW.host.menu_command(C.NODE_VIS, layer, HR.LV_PARTS.NODE, false, inst or 0)
    VRFW.host.menu_command(C.PRIM_VIS, layer, inst or 0, HR.LV_NUM, false)
  end

  --- a plate without its rarity banner: the banner's node and mesh off (the node holds only the banner).
  function HR.rarity_off(layer, inst)
    VRFW.host.menu_command(C.NODE_VIS, layer, HR.RARITY.NODE, false, inst or 0)
    VRFW.host.menu_command(C.MESH, layer, HR.RARITY.MESH, false, inst or 0)
  end

  HR.LEVEL_GROUP = 44923504        -- _pos_lv01
  HR.EXP_GROUP = 1469422130        -- _pos_exp01
  --- Hides a row's rarity, level and level group.
  function HR.bare(layer, inst)
    HR.rarity_off(layer, inst)
    HR.level_off(layer, inst)
    VRFW.host.menu_command(C.NODE_VIS, layer, HR.LEVEL_GROUP, false, inst or 0)
    VRFW.host.menu_command(C.NODE_VIS, layer, HR.EXP_GROUP, false, inst or 0)
  end

  HR.noTitle = {}
  --- False when the handle's title is hidden, true otherwise.
  function HR.shows_title(hdl)
    if hdl ~= nil and HR.noTitle[hdl] then
      return false
    end
    return true
  end

  --- Moves a row's portrait out of the way.
  function HR.portrait_off(layer, inst)
    VRFW.host.menu_command(C.NODE_POS, layer, inst or 0, HR.PORTRAIT, 0, -5000)
  end

  local MP = {
    TX09 = 868271091,              -- #/menu/00_soccer/soccer11/soccer11_09/<LG>/soccer11_09.g4tx
    GREY = 3456853121,             -- cmd_base_sp06 (the neutral plate)
    SP1 = 1349513506,
    AT = 2395587060, DF = 2796898008,   -- gtxt_cmd_at01 / gtxt_cmd_df01
    FOCUS = 148027488,             -- _sp_list_focus01 (the plate's own focus frame)
    ARMED = 1206374040,            -- _gtxt_cmd_armed01
    AT_DMY = 365666709,
    LOADING = 3057768039,          -- CMND_IS_LOADING_LAYER
    pending = {},
    kept = {},
    IS_MESH_VIS = 2277921386,      -- CMND_IS_MESH_VISIBLE (layer, mesh, inst)
    SUB = 559600405,
    POS_BASE1 = 1517329426, POS_BASE2 = 3279539624,   -- _pos_base01 / _pos_base02 (plate / blank plate)
    POS_AT = 4081284803, POS_LOCK = 2244819350,       -- _pos_at01 / _pos_lock01
    PRIM_AT = 2467766246, PRIM_LOCK = 2330185550,
    TEXT = 3359986143,             -- _text_sp01
    FONT_DEFAULT = 368140940,
    AREA = 2164615260,             -- _icon_sp_area_dmy01 (the category icon)
    ICONS = {2164615260, 559600405, 1206374040},      -- category icon, sub icon, armed badge
    LOCK_ANIME = 908051707, ANIME_SET = 753088835,
    SLOT_ARG = 1803124851,         -- SetSkillItemLayerName's 4th argument (every caller's)
    -- The meshes a lock badge hides: the plate, category icon, sub icon, armed badge and focus frame.
    BADGE_HIDDEN = {4282364172 --[[_cmd_base_sp01]], 2164615260, 559600405, 1206374040, 148027488},
  }
  --- Advanced: Move plate helper: draws a move's plate and its badges.
  U.move_plate = MP
  --- List of providers that add badges to a move plate.
  VRFW.move_badge_providers = VRFW.move_badge_providers or {}

  --- The move's place in the chara's match list (0..5), nil = not in it.
  function MP.position(chara, move)
    if chara == nil or chara == 0 or move == nil or move == 0 then
      return nil
    end
    local ok, pos = pcall(funcLuaCommand, C.SKILL_POS, chara, move)
    if not ok or type(pos) ~= "number" or pos < 0 or pos >= 6 then
      return nil
    end
    return pos
  end

  --- Pcall(f, ...) with the retail evolution lookup answering, for (chara, inst), the grade at the move's OWN place.
  function MP.graded(chara, move, inst, f, ...)
    local prev = GetSkillEvoLevelByCharaStHdl
    if type(prev) ~= "function" or move == nil or move == 0 then
      return pcall(f, ...)
    end
    local pos = MP.position(chara, move)
    GetSkillEvoLevelByCharaStHdl = function(h, p)
      if h == chara and p == inst then
        if pos == nil then
          return 0
        end
        return prev(h, pos)
      end
      return prev(h, p)
    end
    local r = table.pack(pcall(f, ...))
    GetSkillEvoLevelByCharaStHdl = prev
    return table.unpack(r, 1, r.n)
  end

  -- point the retail row fill at (row, page, ai) through o.set (default the global SetSkillItemLayerName)
  local function Point(o, row)
    local set = o.set or SetSkillItemLayerName
    local a = o.point                                   -- the screen's own 4th / 5th arguments (a recorded setting)
    set(row, o.page or 0, o.page_inst or 0, a and a[4] or MP.SLOT_ARG, a and a[5] or 0, o.blank or 0, o.ai or 0)
  end

  local function Restore(o)
    local set = o.set or SetSkillItemLayerName
    local r = o.restore or {nil, 0, 0, nil, nil, 0, 0}
    set(r[1], r[2], r[3], r[4], r[5], r[6], r[7])
  end

  -- opens the instance; true when it is not drawable yet (opened by this call, or its layer still loading)
  local function Open(o, row, inst)
    local fresh = funcLuaMenuCommand(C.IS_OPEN, row, inst) ~= true
    if type(o.open) == "function" then
      o.open(row, inst)
    elseif fresh then
      funcLuaMenuCommand(C.OPEN, row, inst)
    end
    return fresh or funcLuaMenuCommand(MP.LOADING, row) == true
  end

  local function Queue(fn, row, inst, chara, move, o)
    local q = {}
    for k, v in pairs(o) do
      q[k] = v
    end
    q.redo = true
    MP.pending[tostring(row) .. ":" .. tostring(inst)] = {fn = fn, row = row, inst = inst, chara = chara, move = move,
      o = q, frame = MP.frame, tries = 0}
  end

  MP.frame = 0
  --- Advances the plate pump; with step = true, one frame.
  function MP.pump(step)
    if step == true then
      MP.frame = MP.frame + 1
      if not MP.pumpSaid then
        MP.pumpSaid = true
        U.log("move plate pump running", tostring(VRFW.patch and VRFW.patch.script or "?"))
      end
      pcall(MP.keep)
    end
    for k, p in pairs(MP.pending) do
      if step == true then
        p.tries = p.tries + 1
      end
      if funcLuaMenuCommand(C.EXIST, p.row) ~= true or p.tries > 120 then
        MP.pending[k] = nil
      elseif p.frame < MP.frame and funcLuaMenuCommand(C.IS_OPEN, p.row, p.inst) == true
          and funcLuaMenuCommand(MP.LOADING, p.row) ~= true then
        MP.pending[k] = nil
        U.log("move plate refill", p.row, p.inst, string.format("%08X", (p.move or 0) % 4294967296), "after", p.tries)
        pcall(p.fn, p.row, p.inst, p.chara, p.move, p.o)
      end
    end
  end

  --- Keeps the plates asked for in MP.kept and drops the rest.
  function MP.keep()
    local exists = {}
    for k, e in pairs(MP.kept) do
      local present = exists[e.row]
      if present == nil then
        present = funcLuaMenuCommand(C.EXIST, e.row) == true
        exists[e.row] = present
      end
      if not present or funcLuaMenuCommand(C.IS_OPEN, e.row, e.inst) ~= true then
        MP.kept[k] = nil
      else
        local armed = e.badge_spot ~= false and (e.armed == true or MP.second_badge(e.row, e.inst))
        local a = funcLuaMenuCommand(MP.IS_MESH_VIS, e.row, MP.ARMED, e.inst) == true
        local d = funcLuaMenuCommand(MP.IS_MESH_VIS, e.row, MP.AT_DMY, e.inst) == true
        local b = funcLuaMenuCommand(MP.IS_MESH_VIS, e.row, MP.SUB, e.inst) == true
        local sub = e.sub == true
        if not e.said and (a ~= armed or d or b ~= sub) then
          e.said = true
          U.log("move plate keep", e.row, e.inst, string.format("%08X", (e.move or 0) % 4294967296),
            "armed shown", tostring(a), "want", tostring(e.armed), "dmy shown", tostring(d), "badge shown", tostring(b),
            "want", tostring(e.sub))
        end
        if a ~= armed then
          funcLuaMenuCommand(C.MESH, e.row, MP.ARMED, armed, e.inst)
        end
        if d then
          funcLuaMenuCommand(C.MESH, e.row, MP.AT_DMY, false, e.inst)
        end
        if b ~= sub then
          funcLuaMenuCommand(C.MESH, e.row, MP.SUB, sub, e.inst)
        end
      end
    end
  end

  --- True when a provider draws a second badge on (row, inst).
  function MP.second_badge(row, inst)
    for _, p in ipairs(VRFW.move_badge_providers) do
      if type(p.second_badge) == "function" and p.second_badge(row, inst) == true then
        return true
      end
    end
    return false
  end

  --- True when the move is armed.
  function MP.armed(move)
    if move == nil or move == 0 then
      return false
    end
    return tonumber(MP.details(move, 9)) == 8 and tonumber(MP.details(move, 13)) == 1
  end

  --- Fills a move plate; answers true, or false, why.
  function MP.fill(row, inst, chara, move, o)
    o = o or {}
    inst = inst or 0
    if type(SetupCharaSkillItem) ~= "function" or funcLuaMenuCommand(C.EXIST, row) ~= true then
      return false, "no row"
    end
    local key = tostring(row) .. ":" .. tostring(inst)
    if o.redo ~= true and o.queued ~= true then
      MP.pending[key] = nil
    end
    if Open(o, row, inst) and o.redo ~= true and o.queued ~= true then
      Queue(MP.fill, row, inst, chara, move, o)
    end
    if o.badge_geom ~= false then
      for _, p in ipairs(VRFW.move_badge_providers) do
        if type(p.use_layer) == "function" then
          p.use_layer(row, type(o.badge_geom) == "string" and o.badge_geom or "b")
        end
      end
    end
    Point(o, row)
    local ok, err
    if o.grade == false then
      ok, err = pcall(SetupCharaSkillItem, chara, move or 0, inst, false)
    else
      ok, err = MP.graded(chara, move, inst, SetupCharaSkillItem, chara, move or 0, inst, false)
    end
    Restore(o)
    if not ok then
      funcLuaMenuCommand(C.VIS, row, inst, false)
      return false, err
    end
    -- The plate base node shows its whole subtree again, so it is set before the parts below (lock, badges, dummies).
    if o.full_base == true then
      funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_BASE1, true, inst)
      funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_BASE2, false, inst)
    end
    if o.focus ~= true then
      funcLuaMenuCommand(C.MESH, row, MP.FOCUS, false, inst)
    end
    local armed = o.armed
    if armed == nil then
      armed = MP.armed(move)
    end
    -- The lock of a locked or fixed row sits on the AT spot that the armed badge shares, so that row shows no badge there.
    local badge_spot = o.locked ~= true and o.fixed ~= true
    funcLuaMenuCommand(C.MESH, row, MP.ARMED, badge_spot and (armed == true or MP.second_badge(row, inst)), inst)
    funcLuaMenuCommand(C.MESH, row, MP.AT_DMY, false, inst)
    -- The lock and its learn level follow the caller's rule only: a learned move never keeps the retail fill's lock.
    MP.lock(row, inst, o.locked == true or o.fixed == true, o.locked == true and o.need or 0)
    local sub = move ~= nil and move ~= 0 and funcLuaMenuCommand(MP.IS_MESH_VIS, row, MP.SUB, inst) == true
    if move ~= nil and move ~= 0 then
      local asked = false
      for _, p in ipairs(VRFW.move_badge_providers) do
        if type(p.has_badge) == "function" then
          if not asked then
            asked, sub = true, false
          end
          sub = sub or p.has_badge(move, chara) == true
        end
      end
    end
    MP.kept[key] = {row = row, inst = inst, move = move, armed = armed == true, sub = sub, badge_spot = badge_spot}
    if o.redo == true or o.log == true then
      U.log("move plate fill", row, inst, string.format("%08X", (move or 0) % 4294967296), "armed", tostring(armed == true),
        "redo", tostring(o.redo == true), "badge", tostring(sub))
    end
    if o.show ~= false then
      funcLuaMenuCommand(C.VIS, row, inst, true)
    end
    return true
  end

  --- a list row's move plate: MP.fill (shown by the caller) plus the row states; answers true, or false, why.
  function MP.row(row, inst, chara, move, o)
    o = o or {}
    move = move or 0
    if type(SetupCharaSkillItem) ~= "function" or funcLuaMenuCommand(C.EXIST, row) ~= true then
      return false, "no row"
    end
    if o.redo ~= true then
      MP.pending[tostring(row) .. ":" .. tostring(inst)] = nil
    end
    if Open(o, row, inst) and o.redo ~= true then
      Queue(MP.row, row, inst, chara, move, o)
    end
    -- the neutral plate first: the retail fill only sets an element plate for a move with an element
    funcLuaMenuCommand(C.SPRITE, row, MP.TX09, MP.GREY, MP.SP1, 0, inst)
    local f = {}
    for k, v in pairs(o) do
      f[k] = v
    end
    f.show = false
    f.queued = true                                     -- the Row queues itself (not its inner Fill)
    f.redo = o.redo
    f.full_base = true
    local ok, err = MP.fill(row, inst, chara, move, f)
    if not ok then
      return false, err
    end
    local empty = move == 0
    if empty or o.locked then
      funcLuaMenuCommand(C.SPRITE, row, MP.TX09, MP.GREY, MP.SP1, 0, inst)
    end
    if empty then
      for _, m in ipairs(MP.ICONS) do
        funcLuaMenuCommand(C.MESH, row, m, false, inst)
      end
      local kept = MP.kept[tostring(row) .. ":" .. tostring(inst)]
      if kept ~= nil then
        kept.sub = false
      end
      funcLuaMenuCommand(C.TEXT, row, MP.TEXT, o.empty_text or "---", inst)
      funcLuaMenuCommand(C.FONT, row, inst, MP.TEXT, MP.FONT_DEFAULT)
      funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_AT, false, inst)
      funcLuaMenuCommand(C.PRIM_VIS, row, inst, MP.PRIM_AT, false)
    else
      funcLuaMenuCommand(C.MESH, row, MP.AREA, true, inst)
      local name = o.name or MP.name(move)
      if o.locked then
        funcLuaMenuCommand(C.TEXT, row, MP.TEXT, (o.lock_color or "") .. name .. (o.lock_color and "[C]" or ""), inst)
      elseif o.suffix ~= nil then
        funcLuaMenuCommand(C.TEXT, row, MP.TEXT, name .. o.suffix, inst)
      end
    end
    funcLuaMenuCommand(C.MESH, row, MP.FOCUS, false, inst)
    return true
  end

  --- Shows or hides the lock part of plate (row, inst), with learn level `level` drawn inside the lock when above 0.
  function MP.lock(row, inst, lock, level)
    local lv = lock and (tonumber(level) or 0) or 0
    if lock then
      funcLuaMenuCommand(C.ANIME, row, inst, MP.LOCK_ANIME, 0, MP.ANIME_SET)
      funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_AT, false, inst)
      funcLuaMenuCommand(C.PRIM_VIS, row, inst, MP.PRIM_AT, false)
    end
    funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_LOCK, lock, inst)
    if lv > 0 then
      local idx = funcLuaMenuCommand(C.PRIM_INDEX, row, inst, MP.PRIM_LOCK)
      if type(idx) == "number" and idx >= 0 then
        funcLuaMenuCommand(C.PRIM_SET, row, inst, idx, lv)
      end
    end
    funcLuaMenuCommand(C.PRIM_VIS, row, inst, MP.PRIM_LOCK, lock and lv > 0)
  end

  --- Shows plate (row, inst) as its lock part alone at node position (x, y) with `level` inside; answers true, or false, why.
  function MP.lock_badge(row, inst, level, x, y)
    if funcLuaMenuCommand(C.EXIST, row) ~= true then
      return false, "no row"
    end
    funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_BASE1, true, inst)
    funcLuaMenuCommand(C.NODE_VIS, row, MP.POS_BASE2, false, inst)
    MP.lock(row, inst, true, level)
    for _, mesh in ipairs(MP.BADGE_HIDDEN) do
      funcLuaMenuCommand(C.MESH, row, mesh, false, inst)
    end
    funcLuaMenuCommand(C.TEXT, row, MP.TEXT, "", inst)
    funcLuaMenuCommand(C.NODE_POS, row, inst, MP.POS_LOCK, 0, x)
    funcLuaMenuCommand(C.NODE_POS, row, inst, MP.POS_LOCK, 1, y)
    return true
  end

  --- Skill info field `field` of `move`; nil when it cannot be read.
  function MP.details(move, field, ...)
    local okc, ok, v = pcall(funcLuaCommand, C.SKILL_INFO, move, field, ...)
    if okc and ok then
      return v
    end
    return nil
  end

  --- The move's name; "" when it cannot be read.
  function MP.name(move)
    local id = MP.details(move, 4)
    if id ~= nil then
      local ok, s = pcall(funcLuaCommand, C.NAME_TEXT, id)
      if ok and type(s) == "string" and s ~= "" then
        return s
      end
    end
    return ""
  end

  --- The plate sprite of the move.
  function MP.plate_sprite(move)
    local el = tonumber(MP.details(move, 7)) or 0
    local okc, ok, common = pcall(funcLuaCommand, C.COMMON_SKILL, move)
    if el == 5 and okc and ok and common then
      el = 6
    end
    if el < 1 or el > 6 then
      el = 6
    end
    if type(GetSkillCommandElementIcon) == "function" then
      local okg, spr = pcall(GetSkillCommandElementIcon, el)
      if okg and type(spr) == "number" and spr ~= 0 then
        return spr
      end
    end
    return MP.SP1
  end

  MP.TENS = {
    ON = {3023202814, 758855748, 1513883858, 3294141809, 3009392103, 710343773, 1565641931, 3454980442, 3135889868,
      3660474409},                 -- _tension_on01..10
    LOC = 923022909,               -- _pos_tension01
    PRIM = 3424269865,             -- the cost number's setting
    DMY = 661115862,
    SCALE = 3413028567,            -- (team info, true) -> ok, the team's tension scale
  }

  --- The retail formula: lit squares = cost / scale x 10 (at least 1, at most 10); no scale = none.
  function MP.steps(cost, scale)
    if type(cost) ~= "number" or type(scale) ~= "number" or scale <= 0 then
      return 0
    end
    return math.min(10, math.max(1, math.floor(cost / scale * 10 + 0.5)))
  end

  --- The first tension scale the given teams answer (a table.pack: nil entries are skipped).
  function MP.tension_scale(teams)
    teams = teams or {255, n = 1}
    for i = 1, teams.n or #teams do
      local ti = teams[i]
      if ti ~= nil then
        local okc, ok, sc = pcall(funcLuaCommand, MP.TENS.SCALE, ti, true)
        if okc and ok and type(sc) == "number" and sc > 0 then
          return sc
        end
      end
    end
    return nil
  end

  --- Draws the tension gauge of a cost; answers steps, scale, or nil without one.
  function MP.tension(L, inst, cost, o)
    o = o or {}
    inst = inst or 0
    local T = MP.TENS
    if type(cost) ~= "number" then
      funcLuaMenuCommand(C.NODE_VIS, L, T.LOC, false, inst)
      return nil
    end
    local scale = o.scale or MP.tension_scale(o.teams)
    local steps = o.steps or MP.steps(cost, scale)
    for i = 1, 10 do
      funcLuaMenuCommand(C.MESH, L, T.ON[i], i <= steps, inst)
    end
    local idx = funcLuaMenuCommand(C.PRIM_INDEX, L, inst, T.PRIM)
    funcLuaMenuCommand(C.PRIM_SET, L, inst, idx, math.floor(cost + 0.5))
    funcLuaMenuCommand(C.PRIM_VIS, L, inst, T.PRIM, true)
    funcLuaMenuCommand(C.NODE_VIS, L, T.LOC, true, inst)
    if type(o.look) == "function" then
      pcall(o.look, L, inst)
    end
    funcLuaMenuCommand(C.MESH, L, T.DMY, false, inst)
    return steps, scale
  end

  --- No gauge at all: squares and number off too (they outlive a hidden locator).
  function MP.tension_off(L, inst)
    inst = inst or 0
    for i = 1, 10 do
      funcLuaMenuCommand(C.MESH, L, MP.TENS.ON[i], false, inst)
    end
    funcLuaMenuCommand(C.PRIM_VIS, L, inst, MP.TENS.PRIM, false)
    funcLuaMenuCommand(C.NODE_VIS, L, MP.TENS.LOC, false, inst)
  end

  --- The look of a move plate as a table (plate, category, ...).
  function MP.look(move, chara)
    local cat = tonumber(MP.details(move, 9)) or 0
    local catSprite = nil
    if type(GetSkillCategoryIcon) == "function" then
      local ok, spr = pcall(GetSkillCategoryIcon, cat, move, chara)
      if ok and type(spr) == "number" and spr ~= 0 then
        catSprite = spr
      end
    end
    local grade = 0
    local pos = MP.position(chara, move)
    if pos ~= nil and type(GetSkillEvoLevelByCharaStHdl) == "function" then
      local ok, g = pcall(GetSkillEvoLevelByCharaStHdl, chara, pos)
      grade = (ok and type(g) == "number") and g or 0
    end
    local power = nil
    if chara ~= nil and chara ~= 0 then
      power = tonumber(MP.details(move, 6, chara, grade))
    end
    if power == nil then
      power = tonumber(MP.details(move, 6))
    end
    local label = nil
    if cat == 1 or cat == 2 then
      label = MP.AT
    elseif cat == 3 or cat == 4 then
      label = MP.DF
    end
    return {plate = MP.plate_sprite(move), category = catSprite, label = label, name = MP.name(move), power = power,
      grade = grade}
  end
end
