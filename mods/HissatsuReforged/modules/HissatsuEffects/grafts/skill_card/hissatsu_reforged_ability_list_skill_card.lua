-- ===== EVT skill_card BEGIN =====
do
  local SKC = {
    CMD = @crc:CMND_VRFW_TECHNIQUE_BALL_EFFECT@,
    MINI_CMD = @crc:CMND_VRFW_TECHNIQUE_MINI_FX@,
    FAM_CMD = @crc:CMND_HISSATSUREFORGED_MOVE_FAMILIES@,
    RULE_CMD = @crc:CMND_HISSATSUEFFECTS_MOVE_RULE_TEXTS@,
    TEXT_ID = @crc:CMND_VRFW_TEXT_ID@,
    TEXT_GET = @crc:CMND_TEXT_GET@,
    NAME_TEXT = 720417636,            -- (name text id) -> the move's name
    SE = @crc:CMND_SND_PLAY_SE@,
    SE_PAGE = 1228648509,             -- sy0027 (the retail detail page switch)
    SE_MOVE = 3848881948,             -- the retail cursor move
    CHECK = @crc:CMND_CHECK_INPUT_CMD@,               -- CMND_CHECK_INPUT_CMD (ctrl, key)
    CTRLS = {1332654303 --[[MENU_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]]},
    K_Y = @crc:CMD_FUNC3@,
    YPAGE = @crc:hissatsu_reforged_skc_ypage@,
    K_UP = @crc:CMD_HISSATSUEFFECTS_SCROLL_UP@,
    K_DOWN = @crc:CMD_HISSATSUEFFECTS_SCROLL_DOWN@,
    GUIDE = 1138543975,               -- mainmenu01_06_base_button_guide
    CARD = 2628045944,                -- team02_02_skill_detail_info
    FLAVOR = 691026122,
    SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,            -- CMND_SET_MENU_TEXT_STRING (layer, node, text, instance)
    CURSOR = 2296367164,              -- cmn05_01_cursor (hidden while the sort / filter windows are open)
    VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@,             -- CMND_IS_LAYER_VISIBLE
    T = {
      guide_effect = @crc:hissatsu_reforged_skc_guide_effect@,
      guide_desc = @crc:hissatsu_reforged_skc_guide_desc@,
      guide_family = @crc:hissatsu_reforged_skc_guide_family@,
      sentence = @crc:hissatsu_reforged_skc_sentence@,
      dist_short = @crc:hissatsu_reforged_skc_dist_short@,
      dist_mid = @crc:hissatsu_reforged_skc_dist_mid@,
      dist_long = @crc:hissatsu_reforged_skc_dist_long@,
      height_high = @crc:hissatsu_reforged_skc_height_high@,
      height_low = @crc:hissatsu_reforged_skc_height_low@,
      dir_forward = @crc:hissatsu_reforged_skc_dir_forward@,
      generic = @crc:hissatsu_reforged_skc_generic@,
      title = @crc:hissatsu_reforged_skc_title@,
      fx_distance = @crc:hissatsu_reforged_skc_fx_distance@,
      fx_lock = @crc:hissatsu_reforged_skc_fx_lock@,
      fx_pe = @crc:hissatsu_reforged_skc_fx_pe@,
      fx_participants = @crc:hissatsu_reforged_skc_fx_participants@,
      fx_participants_any = @crc:hissatsu_reforged_skc_fx_participants_any@,
      fx_steal = @crc:hissatsu_reforged_skc_fx_steal@,
      fx_unblockable = @crc:hissatsu_reforged_skc_fx_unblockable@,
      el_wind = @crc:hissatsu_reforged_skc_elem_1@,
      el_forest = @crc:hissatsu_reforged_skc_elem_2@,
      el_fire = @crc:hissatsu_reforged_skc_elem_3@,
      el_mountain = @crc:hissatsu_reforged_skc_elem_4@,
    },
    -- Style command; both sentence lines are centred.
    STYLE_CMD = 2333948100,           -- (layer, instance, node, style crc)
    STYLE_LEFT = 1038337842,          -- fs_32_k_lu_2d0_001 (retail _text_flavor01)
    STYLE_CENTRE = 3437796543,        -- fs_32_k_cu_2d0_001
    TITLE_TAG = "[CB]",
    centred = false,
    DOTS = @crc:hissatsu_reforged_skc_dots@,
    DOT_N = 6,                        -- most pages a move shows (description, effect, families)
    EXIST = @crc:CMND_IS_EXIST_LAYER@,                -- CMND_IS_EXIST_LAYER
    OPEN = @crc:CMND_OPEN_LAYER@,                 -- CMND_OPEN_LAYER
    IS_OPEN = @crc:CMND_IS_OPEN_LAYER@,             -- CMND_IS_OPEN_LAYER
    LOADING = @crc:CMND_IS_LOADING_LAYER@,
    LVIS = @crc:CMND_SET_LAYER_VISIBLE@,                 -- CMND_SET_LAYER_VISIBLE
    POS = @crc:CMND_SET_LAYER_LOCAL_POS@,                 -- layer local position (layer, x, y, z, instance)
    MESH = @crc:CMND_SET_MESH_VISIBLE@,                -- CMND_SET_MESH_VISIBLE
    NODE_VIS = 2158717427,
    TEXT_VIS = @crc:CMND_SET_MENU_TEXT_VISIBLE@,
    CENTRE = {0, -150},
    TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@,               -- (host layer, host instance, trace name, on)
    TRACES = {[0] = @crc:hissatsu_reforged_skc_dots0@, @crc:hissatsu_reforged_skc_dots1@, @crc:hissatsu_reforged_skc_dots2@, @crc:hissatsu_reforged_skc_dots3@,
      @crc:hissatsu_reforged_skc_dots4@, @crc:hissatsu_reforged_skc_dots5@, @crc:hissatsu_reforged_skc_dots6@, @crc:hissatsu_reforged_skc_dots7@},
    PRIO_CMD = @crc:CMND_SET_DRAW_PRIORITY@,            -- CMND_SET_DRAW_PRIORITY (layer, instance, priority, children)
    PRIO = 580,                       -- the card object draws at 570, the status base copy at 301
    -- Layers of the family page.
    PLATE = @crc:hissatsu_reforged_skc_plate@,
    PLATE_N = 13,
    NAME_K = 12,
    GRID_N = 12,
    PLATE_TRACES = {[0] = @crc:hissatsu_reforged_skc_plate0@, @crc:hissatsu_reforged_skc_plate1@, @crc:hissatsu_reforged_skc_plate2@, @crc:hissatsu_reforged_skc_plate3@,
      @crc:hissatsu_reforged_skc_plate4@, @crc:hissatsu_reforged_skc_plate5@, @crc:hissatsu_reforged_skc_plate6@,
      @crc:hissatsu_reforged_skc_plate7@, @crc:hissatsu_reforged_skc_plate8@, @crc:hissatsu_reforged_skc_plate9@, @crc:hissatsu_reforged_skc_plate10@, @crc:hissatsu_reforged_skc_plate11@,
      @crc:hissatsu_reforged_skc_plate12@},
    FAM_ROWS_MAX = 4,
    FAM_COLS = 3,
    -- Layout in card pixels from the card's centre, x right and y up.
    FAM_LAYOUT = {rows = 4, row_y = -2, pitch = 30, col_x = {-290, 0, 290}, scale = 0.42, plate_dx = -9, plate_dy = 18.6,
      name_x = -335, name_cy = 46, name_scale = 0.44, name_max = 18},
    -- the move row's parts (VRFW.ui_plates.move_plate's constants)
    TX09 = 868271091,                 -- #/menu/00_soccer/soccer11/soccer11_09/<LG>/soccer11_09.g4tx
    SP_SLOT = 1349513506,             -- cmd_base_sp01 (the plate's texture slot)
    SP = {1349513506, 3378946200, 3194064910, 537200045, 1459762491, 3456853121},   -- cmd_base_sp01..06
    ICON_ATLAS = 2320109963,          -- #/menu/200_icon/15_icon_common/icon_common.g4tx
    AREA = 2164615260,
    AREA_SLOT = 566439826,            -- icon_sp_area_dmy01 (its texture slot)
    CAT_ICON = {1801331933, 4065817959, 2236630513, 456446034},   -- icon_sp_area01..04 (shot, dribble, block, keeper)
    SPRITE = 558735651,               -- CMND_SWAP_SPRITE (layer, atlas, sprite, slot, 0, instance)
    SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@,               -- (layer, sx, sy, sz, instance)
    PRIM_VIS = 1233047821,            -- (layer, instance, prim, on)
    COMMON_SKILL = 800895612,
    POS_BASE1 = 1517329426, POS_BASE2 = 3279539624,
    POS_AT = 4081284803, POS_LOCK = 2244819350,
    PRIM_AT = 2467766246, PRIM_LOCK = 2330185550,
    TEXT_SP = 3359986143,
    FOCUS = 148027488,
    ARMED = 1206374040,
    SUB = 559600405,
    AT_DMY = 365666709,
    TEXT_BY_KEY = @crc:CMND_VRFW_TEXT_GET@,
    TX_BADGES = 715273984,
    LINE = 656425078,                  -- the grey quote bar left of the description (not on a family page)
    NAME_BASE = @crc:hr_area_pill05@,
    BADGE_SLOT = 1144424366,          -- area_base01_atl (the badge's texture slot)
    BADGE = {[1] = @crc:hr_area_rect01@, @crc:hr_area_rect02@, @crc:hr_area_rect03@, @crc:hr_area_rect04@},
    skill = nil,       -- the move of the last UpdateSkillDetailWindow
    args = nil,
    want_page = 0,
    page = 0,          -- index (0-based) into the move's pages
    cache = {},
    fams = {},         -- move -> its families (list) or false
    fam_asked = {},
    pages = {},        -- move -> its pages
    items = {},        -- family key -> its rows (move, name, element, power)
    fam_at = nil,
    fam_for = 0,
    fam_off = 0,       -- first row shown of the family list
    held = 0,          -- frames the scroll stick has been held
    frame = 0,
    npages = 1,
    ONE_PAGE = {{kind = "desc"}},
    focus = 0,
    SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@,
    LIST = 571205469,                 -- team05_03_ability_list
    TAB = 4044286600,                 -- cmn06_20_list_tab_item
    LIST_COUNT = 2389020234,          -- the list layer's item count
    PAGE_GUIDE = 1921826160,          -- team00_40_change_page_guide
    AURA_WIN = {[0] = 2651268807 --[[keshin]], 395833588 --[[keshin armed]], 3679282495 --[[mixi max]],
      576015315 --[[soul]], 3635526425 --[[kizuna trans]], 1305553269 --[[awakening power]], 3131422953 --[[mode change]]},
    F_SORT = 1361375778,              -- OnFunction: the sort window
    F_FILTER = 2143575837,            -- OnFunction: the filter window
    pending = false,
  }
  -- State of the two attached layers.
  local ROW = nil
  local PLATES = {id = SKC.PLATE, n = SKC.PLATE_N, name = "family plates", opened = {}, set = {}, gone = false,
    shown = false, plate = true, move = {}, icon = {}, labels = {}}

  -- the card shows a move and it is the one of the last fill
  function SKC.focused()
    return SKC.focus ~= 0 and SKC.focus == SKC.skill
  end

  local function Text(key, subs)
    local ok, s = pcall(funcLuaCommand, SKC.TEXT_GET, SKC.T[key])
    if not ok or type(s) ~= "string" then
      s = ""
    end
    for k, v in pairs(subs or {}) do
      s = string.gsub(s, "{" .. k .. "}", (string.gsub(tostring(v), "%%", "%%%%")))
    end
    return s
  end

  -- the card's text for a move (defined below)
  local EffectText

  local function RuleText(skill)
    local ok, r = pcall(funcLuaCommand, SKC.RULE_CMD, skill)
    if not ok or type(r) ~= "table" then
      return nil
    end
    local parts = {}
    for i = 1, tonumber(r.count) or 0 do
      if type(r[i]) == "string" and r[i] ~= "" then
        parts[#parts + 1] = r[i]
      end
    end
    return table.concat(parts, " ")
  end

  -- the move's mini-effect, or false (also false when none of its mini-effects has a gameplay sentence)
  local function Effect(skill)
    if type(skill) ~= "number" or skill == 0 then
      return false
    end
    local e = SKC.cache[skill]
    if e ~= nil then
      return e
    end
    e = false
    local ok, present, dist, launch, dir, dword, lword = pcall(funcLuaCommand, SKC.CMD, skill)
    if ok and present == true then
      e = {ball = true, dist = tonumber(dist) or 0, launch = tonumber(launch) or 0, dir = tostring(dir or "keep"),
           dword = tostring(dword or ""), lword = tostring(lword or "")}
    end
    local mok, mpresent, mask, _, _, frac, _, _, pel, ppct, spct, _, dunb = pcall(funcLuaCommand, SKC.MINI_CMD, skill)
    if mok and mpresent == true and (tonumber(mask) or 0) > 0 then
      e = e or {}
      e.mini = tonumber(mask) or 0
      e.frac = tonumber(frac) or 0
      e.pel = tostring(pel or "")
      e.ppct = tonumber(ppct) or 0
      e.spct = tonumber(spct) or 0
      e.dunb = tonumber(dunb) or 0
    end
    -- the technique effects written as behaviour rules (Hissatsu Effects' technique_effects_*.toml, any mod's rule)
    local rule = RuleText(skill)
    if rule ~= nil and rule ~= "" then
      e = e or {}
      e.rule = rule
    end
    if e and EffectText(e) == "" then
      e = false
    end
    if rule ~= nil then
      SKC.cache[skill] = e
    end
    return e
  end

  -- Returns the move's technique families.
  local function Families(skill)
    if type(skill) ~= "number" or skill == 0 then
      return false
    end
    local f = SKC.fams[skill]
    if f ~= nil then
      return f
    end
    local asked = SKC.fam_asked[skill]
    if asked ~= nil and asked.frame == SKC.frame then
      return nil
    end
    local ok, r = pcall(funcLuaCommand, SKC.FAM_CMD, skill)
    if not ok or type(r) ~= "table" then
      asked = asked or {tries = 0}
      asked.frame, asked.tries = SKC.frame, asked.tries + 1
      SKC.fam_asked[skill] = asked
      if asked.tries >= 3 then
        SKC.fams[skill] = false
        return false
      end
      return nil
    end
    f = {}
    for i = 1, tonumber(r.count) or 0 do
      local e = r[i]
      if type(e) == "table" and type(e.moves) == "table" then
        local moves = {}
        for k = 1, tonumber(e.count) or 0 do
          if e.moves[k] ~= nil then
            moves[#moves + 1] = VRFW.ids.unsigned(e.moves[k])
          end
        end
        if #moves > 0 then
          f[#f + 1] = {key = tostring(e.key or ""), text = tostring(e.text or ""), icon = tostring(e.icon or ""),
            moves = moves}
        end
      end
    end
    if #f == 0 then
      f = false
    end
    SKC.fams[skill] = f
    return f
  end

  -- Returns the move's pages.
  local function Pages(skill)
    if type(skill) ~= "number" or skill == 0 then
      return SKC.ONE_PAGE
    end
    local p = SKC.pages[skill]
    if p ~= nil then
      return p
    end
    local fams = Families(skill)
    p = {{kind = "desc"}}
    if Effect(skill) then
      p[#p + 1] = {kind = "effect"}
    end
    for _, fam in ipairs(fams or {}) do
      if #p < SKC.DOT_N then
        p[#p + 1] = {kind = "family", fam = fam}
      end
    end
    if fams ~= nil and SKC.cache[skill] ~= nil then
      SKC.pages[skill] = p
    end
    return p
  end

  local function FocusPages()
    return SKC.focused() and Pages(SKC.focus) or SKC.ONE_PAGE
  end

  local function BallText(e)
    local dist, height, dir = "", "", ""
    local d = (e.dword == "low" and 15) or (e.dword == "mid" and 25) or (e.dword == "high" and 40) or e.dist
    if d > 0 then
      dist = Text(d <= 18 and "dist_short" or (d <= 30 and "dist_mid" or "dist_long"))
    end
    local a = (e.lword == "flat" and 10) or (e.lword == "low" and 25) or (e.lword == "lob" and 45)
      or (e.lword == "high" and 60) or e.launch
    if a >= 40 then
      height = Text("height_high")
    elseif a > 0 and a <= 15 then
      height = Text("height_low")
    end
    if e.dir == "forward" then
      dir = Text("dir_forward")
    end
    if dist == "" and height == "" and dir == "" then
      return ""                                   -- a rule with no part of its own is no effect: no second page
    end
    return Text("sentence", {dist = dist, height = height, dir = dir})
  end

  EffectText = function(e)
    local parts = {}
    if e.ball then
      local ball = BallText(e)
      if ball ~= "" then
        parts[#parts + 1] = ball
      end
    end
    local m = e.mini or 0
    local function Bit(b)
      return math.floor(m / b) % 2 == 1
    end
    if Bit(1) then
      parts[#parts + 1] = Text("fx_distance")
    end
    if Bit(2) then
      parts[#parts + 1] = Text("fx_lock")
    end
    if Bit(4) then
      parts[#parts + 1] = Text("fx_pe", {pct = math.floor((e.frac or 0) * 100 + 0.5)})
    end
    if Bit(8) then
      local pct = math.floor((e.ppct or 0) + 0.5)
      if SKC.T["el_" .. (e.pel or "")] ~= nil then
        parts[#parts + 1] = Text("fx_participants", {pct = pct, element = Text("el_" .. e.pel)})
      else
        parts[#parts + 1] = Text("fx_participants_any", {pct = pct})
      end
    end
    if Bit(16) then
      parts[#parts + 1] = Text("fx_steal", {pct = math.floor((e.spct or 0) + 0.5)})
    end
    if Bit(32) and e.dunb == 1 then
      parts[#parts + 1] = Text("fx_unblockable")
    end
    if e.rule ~= nil and e.rule ~= "" then
      parts[#parts + 1] = e.rule
    end
    return table.concat(parts, " ")
  end

  local function SetStyle(centre)
    if SKC.centred ~= centre then
      SKC.centred = centre
      pcall(funcLuaMenuCommand, SKC.STYLE_CMD, SKC.CARD, 0, SKC.FLAVOR, centre and SKC.STYLE_CENTRE or SKC.STYLE_LEFT)
    end
  end

  local function TitleTag()
    return (type(SKILL_CARD_TITLE_TAG) == "string") and SKILL_CARD_TITLE_TAG or SKC.TITLE_TAG
  end

  local function ShowEffect(e)
    local tag = TitleTag()
    local title = Text("title")
    if tag ~= "" then
      title = tag .. title .. "[C]"
    end
    SetStyle(true)
    funcLuaMenuCommand(SKC.SET_TEXT, SKC.CARD, SKC.FLAVOR, title .. "\n" .. EffectText(e), 0)
  end

  -- Computes the family page's places.
  local function FamLayout()
    local L = {}
    for k, v in pairs(SKC.FAM_LAYOUT) do
      L[k] = v
    end
    if type(SKILL_CARD_FAMILY_LAYOUT) == "table" then
      for k, v in pairs(SKILL_CARD_FAMILY_LAYOUT) do
        L[k] = v
      end
    end
    L.rows = math.max(1, math.min(SKC.FAM_ROWS_MAX, math.floor(tonumber(L.rows) or SKC.FAM_ROWS_MAX)))
    return L
  end

  -- Returns the family's rows.
  local function FamilyItems(fam)
    local items = SKC.items[fam.key]
    if items ~= nil then
      return items
    end
    items = {}
    local seen = {}
    for _, m in ipairs(fam.moves) do
      local okn, found, nameId = pcall(funcLuaCommand, SKC.SKILL_INFO, m, 4)
      if okn and found and type(nameId) == "number" and nameId ~= 0 then
        local okt, name = pcall(funcLuaCommand, SKC.NAME_TEXT, nameId)
        if okt and type(name) == "string" and name ~= "" then
          local oke, eok, el = pcall(funcLuaCommand, SKC.SKILL_INFO, m, 7)
          local okc, cok, cat = pcall(funcLuaCommand, SKC.SKILL_INFO, m, 9)
          local okp, pok, power = pcall(funcLuaCommand, SKC.SKILL_INFO, m, 6)
          local okm, mok, common = pcall(funcLuaCommand, SKC.COMMON_SKILL, m)
          local twin = seen[name]
          if twin ~= nil then
            twin.alt[m] = true                      -- a variant of the same move: shown once
          else
          seen[name] = {move = m, alt = {[m] = true}}
          items[#items + 1] = {move = m, name = name, el = (oke and eok and tonumber(el)) or 0,
            cat = (okc and cok and tonumber(cat)) or 0, power = (okp and pok and tonumber(power)) or 0,
            common = okm and mok and common == true, alt = seen[name].alt}
          end
        end
      end
    end
    table.sort(items, function(a, b)
      if a.power ~= b.power then
        return a.power < b.power
      end
      return a.move < b.move
    end)
    SKC.items[fam.key] = items
    return items
  end

  local function FamilyTitle(fam)
    if fam.title ~= nil then
      return fam.title
    end
    local s = ""
    if fam.text ~= "" then
      local oki, id = pcall(funcLuaCommand, SKC.TEXT_ID, fam.text)
      if oki and type(id) == "number" and id ~= 0 then
        local okg, t = pcall(funcLuaCommand, SKC.TEXT_GET, id)
        if okg and type(t) == "string" then
          s = t
        end
      end
      if s == "" then
        local okv, t = pcall(funcLuaCommand, SKC.TEXT_BY_KEY, fam.text)
        if okv and type(t) == "string" then
          s = t
        end
      end
    end
    if s == "" then
      s = string.match(fam.key, "([^%.]+)$") or fam.key
    end
    if string.sub(fam.icon, 1, 6) == "gaiji_" then
      s = "[$" .. fam.icon .. "] " .. s
    elseif string.sub(fam.icon, 1, 2) == "[$" then
      s = fam.icon .. " " .. s
    end
    fam.title = s
    return s
  end

  local function FamilyMaxOffset(fam, L)
    return math.max(0, math.ceil(#FamilyItems(fam) / SKC.FAM_COLS) - L.rows)
  end

  -- Shows the family page's card body.
  local function ShowFamily(fam)
    SetStyle(false)
    funcLuaMenuCommand(SKC.SET_TEXT, SKC.CARD, SKC.FLAVOR, "", 0)
    if SKC.fam_at ~= fam or SKC.fam_for ~= SKC.focus then
      SKC.fam_at, SKC.fam_for = fam, SKC.focus
      local L = FamLayout()
      local cur, row = VRFW.ids.unsigned(SKC.focus), 0
      for i, it in ipairs(FamilyItems(fam)) do
        if (it.move == cur or it.alt[cur] == true) then
          row = math.floor((i - 1) / SKC.FAM_COLS)
          break
        end
      end
      SKC.fam_off = math.max(0, math.min(FamilyMaxOffset(fam, L), row - math.floor((L.rows - 1) / 2)))
    end
  end

  -- A tab whose list is empty shows no move (retail OnChangeFocus).
  local SKC_RetailOnChangeFocus = OnChangeFocus
  function OnChangeFocus(a1, ...)
    local r = table.pack(SKC_RetailOnChangeFocus(a1, ...))
    if a1 == SKC.TAB then
      local count = funcLuaMenuCommand(SKC.LIST_COUNT, SKC.LIST)
      if type(count) ~= "number" or count <= 0 then
        SKC.focus = 0
      end
    end
    return table.unpack(r, 1, r.n)
  end

  local SKC_RetailOnAfterReceiveFilterParam = OnAfterReceiveFilterParam
  function OnAfterReceiveFilterParam(...)
    SKC.focus = 0
    SKC.page, SKC.want_page = 0, 0
    local r = table.pack(SKC_RetailOnAfterReceiveFilterParam(...))
    if SKC.apply then
      pcall(SKC.apply)
    end
    return table.unpack(r, 1, r.n)
  end

  local SKC_RetailUpdateSkillDetailWindow = UpdateSkillDetailWindow
  function UpdateSkillDetailWindow(...)
    local skill = ...
    SKC.skill, SKC.args = skill, table.pack(...)
    local okInfo = type(skill) == "number" and funcLuaCommand(SKC.SKILL_INFO, skill, 9)
    SKC.focus = okInfo and skill or 0
    pcall(SKC.reset_aura_guide, skill)
    local r = table.pack(SKC_RetailUpdateSkillDetailWindow(...))
    local okCat, cat = funcLuaCommand(SKC.SKILL_INFO, type(skill) == "number" and skill or 0, 9)
    if okCat and SKC.BADGE[cat] ~= nil then
      pcall(funcLuaMenuCommand, SKC.SPRITE, SKC.CARD, SKC.TX_BADGES, SKC.BADGE[cat], SKC.BADGE_SLOT, 0, 0)
    end
    -- Reads the page shown.
    local pages = FocusPages()
    SKC.page = math.max(0, math.min(SKC.want_page, #pages - 1))
    local page = pages[SKC.page + 1]
    if page.kind ~= "effect" then
      pcall(SetStyle, false)
    end
    if page.kind == "effect" then
      local e = Effect(skill)
      if e then
        pcall(ShowEffect, e)
      else
        SKC.page = 0
        page = pages[1]
      end
    elseif page.kind == "family" then
      pcall(ShowFamily, page.fam)
    end
    SKC.npages = #pages
    if SKC.apply then
      pcall(SKC.apply)
    end
    return table.unpack(r, 1, r.n)
  end

  -- the retail aura windows' page guide off and every aura window but the focused aura's type off
  function SKC.reset_aura_guide(skill)
    local keep = nil
    local ok, cat = funcLuaCommand(SKC.SKILL_INFO, skill, 9)
    if ok and cat == 8 then
      local okt, t = funcLuaCommand(SKC.SKILL_INFO, skill, 13)
      keep = okt and SKC.AURA_WIN[t] or nil
    end
    if funcLuaMenuCommand(SKC.EXIST, SKC.PAGE_GUIDE) then
      funcLuaMenuCommand(SKC.LVIS, SKC.PAGE_GUIDE, 0, false)
    end
    for _, L in pairs(SKC.AURA_WIN) do
      if L ~= keep and funcLuaMenuCommand(SKC.EXIST, L) then
        funcLuaMenuCommand(SKC.LVIS, L, 0, false)
      end
    end
  end

  local function Pressed(k)
    for _, ctrl in ipairs(SKC.CTRLS) do
      local ok, hit = pcall(funcLuaCommand, SKC.CHECK, ctrl, k)
      if ok and hit == true then
        return true
      end
    end
    return false
  end

  local Cmd = VRFW.host.menu_command
  local Log = VRFW.logger.new("EVT skill_card")

  -- Returns whether an instance of an attached layer is ready.
  local function Ready(Lo, k, want)
    if Cmd(SKC.IS_OPEN, Lo.id, k) == true then
      return Cmd(SKC.LOADING, Lo.id) ~= true
    end
    if Lo.opened[k] then
      if not Lo.gone then
        Lo.gone = true
        Log(Lo.name .. " layer closed by the menu: not reopened", k)
      end
      return false
    end
    if want and not Lo.gone then
      Lo.opened[k] = true
      Cmd(SKC.OPEN, Lo.id, k)
    end
    return false
  end

  -- Keeps every instance of the layer open, loaded and set up once (setup(k)).
  local function EnsureLayer(Lo, setup)
    local ready = true
    for k = 0, Lo.n - 1 do
      if not Ready(Lo, k, true) then
        ready = false
      elseif not Lo.set[k] then
        Lo.set[k] = true
        setup(k)
      end
    end
    if ready and not Lo.logged_open then
      Lo.logged_open = true
      Log(Lo.name .. " layer opened", Lo.n)
    end
    return ready and not Lo.gone
  end

  -- Hides every instance of the plate layer that is still open (the layer and its whole plate node).
  local function HideLayer(Lo)
    -- Covers every instance that is open, whoever opened it.
    for k = 0, Lo.n - 1 do
      if Cmd(SKC.IS_OPEN, Lo.id, k) == true then
        Cmd(SKC.LVIS, Lo.id, k, false)
        Cmd(SKC.NODE_VIS, Lo.id, SKC.POS_BASE1, false, k)
        Cmd(SKC.NODE_VIS, Lo.id, SKC.POS_BASE2, false, k)
        Cmd(SKC.TEXT_VIS, Lo.id, SKC.TEXT_SP, false, k)
        Cmd(SKC.MESH, Lo.id, SKC.AREA, false, k)
        Cmd(SKC.MESH, Lo.id, SKC.FOCUS, false, k)
        Lo.labels = {}
        Lo.move[k] = nil                            -- refilled (and the texts shown again) on the next family page
      end
    end
    Lo.shown = false
  end

  -- Returns the row (nil without the framework's pager).
  local function Row()
    if ROW == nil and type(VRFW.pager) == "table" and type(VRFW.pager.new) == "function" then
      ROW = VRFW.pager.new({layer = SKC.DOTS, name = "skill card", prio = SKC.PRIO, style = "ycycle", guide = SKC.YPAGE,
        key = "<CMD_FUNC3>", setup = function(k)
        Cmd(SKC.TRACE, SKC.CARD, 0, SKC.TRACES[k], true)
      end})
    end
    return ROW
  end

  local function RowCentre()
    local c = (type(SKILL_CARD_DOTS_XY) == "table") and SKILL_CARD_DOTS_XY or SKC.CENTRE
    return tonumber(c[1]) or SKC.CENTRE[1], tonumber(c[2]) or SKC.CENTRE[2]
  end

  local function HideRow()
    if ROW ~= nil then
      ROW:hide()
    end
  end

  -- the name text cut to `max` characters with an ellipsis
  local function Ellipsize(s, max)
    local n, i = 0, 1
    while i <= #s do
      local b = string.byte(s, i)
      i = i + ((b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1)
      n = n + 1
      if n == max and i <= #s then
        return string.sub(s, 1, i - 1) .. "..."
      end
    end
    return s
  end

  -- Sets up plate instance k.
  local function PlateSetup(k)
    Cmd(SKC.TRACE, SKC.CARD, 0, SKC.PLATE_TRACES[k], true)
    Cmd(SKC.PRIO_CMD, SKC.PLATE, k, SKC.PRIO, true)
    local L = FamLayout()
    -- The retail row's visual centre sits plate_dy layout pixels above its origin.
    local dx, dy = tonumber(L.plate_dx) or 0, tonumber(L.plate_dy) or 0
    if k == SKC.NAME_K then
      -- the family's name badge (the plate's own text node and font, no squeeze) on the type badge's line
      local s = tonumber(L.name_scale) or 0.44
      local cx, cy = L.name_x + 300 * s, L.name_cy
      Cmd(SKC.SCALE, SKC.PLATE, s, s, 1, k)
      Cmd(SKC.POS, SKC.PLATE, cx - dx * s, cy - dy * s, 0, k)
      Cmd(SKC.LVIS, SKC.PLATE, k, false)
      return
    end
    local row, col = math.floor(k / SKC.FAM_COLS), k % SKC.FAM_COLS
    local s = tonumber(L.scale) or 0.52
    Cmd(SKC.SCALE, SKC.PLATE, s, s, 1, k)
    Cmd(SKC.POS, SKC.PLATE, L.col_x[col + 1] - dx * s, L.row_y - row * L.pitch - dy * s, 0, k)
    Cmd(SKC.LVIS, SKC.PLATE, k, false)
  end

  -- Fills the plate of a move.
  local function PlateFill(k, it, current)
    local key = tostring(it.move) .. (current and "*" or "")
    if PLATES.move[k] ~= key then
      PLATES.move[k] = key
      local el = it.el
      if el == 5 and it.common then
        el = 6
      end
      Cmd(SKC.SPRITE, SKC.PLATE, SKC.TX09, SKC.SP[el] or SKC.SP[6], SKC.SP_SLOT, 0, k)
      local icon = SKC.CAT_ICON[it.cat]
      if type(GetSkillCategoryIcon) == "function" then
        local ok, i = pcall(GetSkillCategoryIcon, it.cat, it.move, 0)
        if ok and type(i) == "number" and i ~= 0 then
          icon = i
        end
      end
      if icon ~= nil then
        Cmd(SKC.SPRITE, SKC.PLATE, SKC.ICON_ATLAS, icon, SKC.AREA_SLOT, 0, k)
      end
      Cmd(SKC.SET_TEXT, SKC.PLATE, SKC.TEXT_SP, it.name, k)
      PLATES.icon[k] = icon ~= nil
    end
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_BASE1, true, k)
    Cmd(SKC.TEXT_VIS, SKC.PLATE, SKC.TEXT_SP, true, k)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_BASE2, false, k)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_AT, false, k)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_LOCK, false, k)
    Cmd(SKC.PRIM_VIS, SKC.PLATE, k, SKC.PRIM_AT, false)
    Cmd(SKC.PRIM_VIS, SKC.PLATE, k, SKC.PRIM_LOCK, false)
    Cmd(SKC.MESH, SKC.PLATE, SKC.ARMED, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.SUB, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.AT_DMY, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.AREA, PLATES.icon[k] == true, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.FOCUS, current, k)
    Cmd(SKC.LVIS, SKC.PLATE, k, true)
  end

  -- Shows the family's name on the name instance.
  local function LabelShow(k, text)
    if PLATES.labels[k] ~= text then
      PLATES.labels[k] = text
      Cmd(SKC.SPRITE, SKC.PLATE, SKC.TX_BADGES, SKC.NAME_BASE, SKC.SP_SLOT, 0, k)
      Cmd(SKC.SET_TEXT, SKC.PLATE, SKC.TEXT_SP, text, k)
      Log("family label", k, text)
    end
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_BASE1, true, k)
    Cmd(SKC.TEXT_VIS, SKC.PLATE, SKC.TEXT_SP, true, k)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_BASE2, false, k)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_AT, false, k)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_LOCK, false, k)
    Cmd(SKC.PRIM_VIS, SKC.PLATE, k, SKC.PRIM_AT, false)
    Cmd(SKC.PRIM_VIS, SKC.PLATE, k, SKC.PRIM_LOCK, false)
    Cmd(SKC.MESH, SKC.PLATE, SKC.ARMED, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.SUB, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.AT_DMY, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.AREA, false, k)
    Cmd(SKC.MESH, SKC.PLATE, SKC.FOCUS, false, k)
    Cmd(SKC.LVIS, SKC.PLATE, k, true)
  end

  local function PlateOff(k)
    Cmd(SKC.LVIS, SKC.PLATE, k, false)
    Cmd(SKC.NODE_VIS, SKC.PLATE, SKC.POS_BASE1, false, k)
  end

  -- Draws the family list from row SKC.fam_off.
  local function DrawFamily(fam)
    local L = FamLayout()
    local items = FamilyItems(fam)
    local maxOff = FamilyMaxOffset(fam, L)
    SKC.fam_off = math.max(0, math.min(maxOff, SKC.fam_off))
    local cur = VRFW.ids.unsigned(SKC.focus)
    for k = 0, SKC.GRID_N - 1 do
      local r, c = math.floor(k / SKC.FAM_COLS), k % SKC.FAM_COLS
      local it = (r < L.rows) and items[(SKC.fam_off + r) * SKC.FAM_COLS + c + 1] or nil
      if it ~= nil then
        PlateFill(k, it, (it.move == cur or it.alt[cur] == true))
      else
        PlateOff(k)
      end
    end
    PLATES.shown = true
    local icon, plain = string.match(FamilyTitle(fam), "^(%[%$[^%]]*%] )(.*)$")
    local title = (icon or "") .. Ellipsize(plain or FamilyTitle(fam), tonumber(L.name_max) or 18)
    LabelShow(SKC.NAME_K, title)
  end

  -- the move on the card has more than one page and the card is up
  local function CardUp()
    return Cmd(SKC.VISIBLE, SKC.CARD, 0) ~= false and Cmd(SKC.VISIBLE, SKC.CURSOR, 0) ~= false
  end

  -- Brings one family layer to its state.
  local function FamilyLayer(Lo, setup, wantFam)
    if not wantFam then
      HideLayer(Lo)                               -- every page but a family's: no family part stays drawn
      return false
    end
    if Lo.gone then
      return false
    end
    if Cmd(SKC.EXIST, Lo.id) ~= true then
      return false
    end
    if not EnsureLayer(Lo, setup) then
      if not Lo.gone then
        SKC.pending = true
      end
      return false
    end
    Lo.ready = true
    return true
  end

  local function Apply()
    SKC.pending = false
    local pages = FocusPages()
    local cardUp = CardUp()
    local want = SKC.focused() and #pages >= 2 and cardUp
    local page = pages[SKC.page + 1]
    local wantFam = want and page ~= nil and page.kind == "family"
    -- the row
    local R = Row()
    if R == nil then
      SKC.pending = false
    elseif R.gone then
      if R.shown then
        R:hide()
      end
    elseif Cmd(SKC.EXIST, SKC.DOTS) == true then
      if not R:opened() and not cardUp then
        SKC.pending = true                        -- the instances open with the card (Hissatsu Effects 1.1.1)
      elseif R:ready() then
        if want then
          local x, y = RowCentre()
          local nextPage = pages[(SKC.page + 1) % #pages + 1]
          R:show(math.min(#pages, SKC.DOT_N), SKC.page + 1, x, y, Text("guide_" .. nextPage.kind))
        else
          R:hide()
        end
      elseif not R.gone then
        SKC.pending = true
      end
    end
    -- the description's grey quote bar belongs to the description / effect pages only
    Cmd(SKC.MESH, SKC.CARD, SKC.LINE, not wantFam, 0)
    -- the family plates and the family's name
    if FamilyLayer(PLATES, PlateSetup, wantFam) and wantFam then
      DrawFamily(page.fam)
    end
    local state = want and (tostring(SKC.page) .. "/" .. tostring(#pages)) or ""
    if state ~= SKC.logged then
      SKC.logged = state
      Log("row", state == "" and "hidden" or ("page " .. state))
    end
  end
  SKC.apply = Apply

  -- Handles leaving, filter and sort.
  local SKC_RetailOnBack = OnBack
  function OnBack(...)
    local r = table.pack(SKC_RetailOnBack(...))
    Log("back")
    SKC.pending = false
    pcall(HideRow)
    pcall(HideLayer, PLATES)
    return table.unpack(r, 1, r.n)
  end

  -- The sort and filter windows: the layers go before they open (the retail hides the cursor with them) and follow the card again when the retail returns.
  local SKC_RetailOnFunction = OnFunction
  function OnFunction(...)
    local f = ...
    if f == SKC.F_SORT or f == SKC.F_FILTER then
      pcall(HideRow)
        pcall(HideLayer, PLATES)
    end
    local r = table.pack(SKC_RetailOnFunction(...))
    pcall(Apply)
    return table.unpack(r, 1, r.n)
  end

  local SKC_RetailCallBackSort = CallBackSort
  function CallBackSort(...)
    local r = table.pack(SKC_RetailCallBackSort(...))
    pcall(Apply)
    return table.unpack(r, 1, r.n)
  end

  -- Turns to page p (0-based) of the move.
  local function TurnTo(p, pages)
    local page = pages[p + 1]
    SKC.page, SKC.want_page = p, p
    if page.kind == "desc" then
      local a = SKC.args
      UpdateSkillDetailWindow(table.unpack(a, 1, a.n))   -- the retail fill (and its UpdateButtonGuide)
      return
    end
    if page.kind == "effect" then
      ShowEffect(Effect(SKC.focus))
    else
      ShowFamily(page.fam)
    end
    Apply()
  end

  -- Handles the right stick on a family page whose list is longer than the card.
  local function Scroll(fam)
    local dir = (Pressed(SKC.K_UP) and -1) or (Pressed(SKC.K_DOWN) and 1) or 0
    if dir == 0 then
      SKC.held = 0
      return
    end
    SKC.held = SKC.held + 1
    local h = SKC.held
    if h ~= 1 and (h < 18 or (h - 18) % 5 ~= 0) then
      return
    end
    local maxOff = FamilyMaxOffset(fam, FamLayout())
    local off = math.max(0, math.min(maxOff, SKC.fam_off + dir))
    if off == SKC.fam_off then
      return
    end
    SKC.fam_off = off
    funcLuaCommand(SKC.SE, SKC.SE_MOVE)
    if PLATES.shown then
      DrawFamily(fam)
    else
      Apply()
    end
  end

  local function Poll()
    if not SKC.focused() then
      return
    end
    local pages = Pages(SKC.focus)
    if #pages ~= SKC.npages then
      SKC.npages = #pages                         -- the families answered after the fill: the row follows
      local p = math.max(0, math.min(SKC.want_page, #pages - 1))
      if p ~= SKC.page then
        TurnTo(p, pages)
      else
        Apply()
      end
    end
    if #pages < 2 then
      return
    end
    if funcLuaMenuCommand(SKC.VISIBLE, SKC.CURSOR, 0) == false then
      return                                      -- the sort / filter window is open
    end
    local page = pages[SKC.page + 1]
    if page ~= nil and page.kind == "family" then
      Scroll(page.fam)
    end
    local dir = Pressed(SKC.K_Y) and 1 or 0
    if dir == 0 then
      return
    end
    funcLuaCommand(SKC.SE, SKC.SE_PAGE)
    SKC.held = 0
    TurnTo((SKC.page + dir) % #pages, pages)
  end

  local SKC_RetailStep = Step
  function Step(...)
    local r = nil
    if SKC_RetailStep ~= nil then
      r = table.pack(SKC_RetailStep(...))
    end
    SKC.frame = SKC.frame + 1
    pcall(Poll)
    if SKC.pending then
      pcall(Apply)
    end
    if r ~= nil then
      return table.unpack(r, 1, r.n)
    end
  end
end
-- ===== EVT skill_card END =====
