-- EVT better_ui_skill_screen BEGIN
do
  BetterUI = BetterUI or {}
  BetterUI.skill_screen = BetterUI.skill_screen or {}
  local S = BetterUI.skill_screen
  local OWNER = "BetterUI.skill_screen"

  S.C = {
    LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@, IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@,
    MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@, TEXT_VISIBLE = 2735666188,
    LOCAL_POS = @crc:CMND_SET_LAYER_LOCAL_POS@, GET_LOCAL_POS = @crc:CMND_GET_LAYER_LOCAL_POS@,
    LOCAL_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@, OPEN = @crc:CMND_OPEN_LAYER@, SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,
    TEXT_BY_KEY = @crc:CMND_VRFW_TEXT_GET@, TEXT_GET = @crc:CMND_TEXT_GET@, LOG = @crc:CMND_VRFW_LOG@,
    DESC_TEXT = 4113915188,          -- (description text id, SKILL_INFO field 5) -> the card's description (personal_plate_inc)
    SET_FOCUS = 1778826357,          -- (item layer, row, true): the list's focus on that row (retail OnAfterReceiveFilterParam)
    POINTER = VRFW.emblem_grid.C.POINTER,
    LIST_COUNT = 2389020234,         -- (list) -> rows
    FOCUS_INDEX = 2603265800,        -- (item layer) -> the focused row (retail OnAfterReceiveFilterParam)
    LIST_ITEMS = @crc:CMND_VRFW_ABILITY_LIST_ITEMS@,
    ITEM_TO_SKILL = 901208644, SKILL_INFO = 2580586398, NAME_TEXT = 720417636, TEXT_CONVERT = 820766113, CHARA_INFO = 4060384944,
    RULE_TEXTS = @crc:CMND_HISSATSUEFFECTS_MOVE_RULE_TEXTS@,
    LEVEL_EFFECTS = @crc:CMND_HISSATSUREFORGED_MOVE_LEVEL_EFFECTS@,
    TOTEM_EFFECTS = @crc:CMND_CHARACTERREFORGED_SOULS_TOTEM_EFFECTS@,   -- (aura) -> the rows of a totem's levels
    GRADE_TEXTS = @crc:CMND_HISSATSUEFFECTS_MOVE_GRADE_TEXTS@,
  }
  S.L = {
    LIST = @crc:team05_03_ability_list@, ITEM = @crc:team08_02_ability_list_item@, TAB = @crc:cmn06_20_list_tab_item@,
    CARD = @crc:team02_02_skill_detail_info@, TAB_ATTACH = @crc:cmn06_01_list_tab_attach@, TAG = @crc:betterui_skill_tag@, BOOK = @crc:betterui_skill_book@, LABEL = @crc:betterui_skill_label@,
    EFFECT = @crc:betterui_skill_effect@, EFFECT_TITLE = @crc:betterui_skill_effect_title@, VALUE = @crc:betterui_skill_value@,
    ART = @crc:betterui_skill_art@, FACE = @crc:betterui_skill_face@,
  }
  -- the screen's own sprites (content\images\...\skill_screen_art.toml, made by _tools/betterui_skill_screen_art.py)
  S.ART_ATLAS = "#/menu/200_icon/better_ui_own/better_ui_skill_screen_art.g4tx"
  S.ART_COUNT = 32
  S.A = {
    FRAME = @crc:better_ui_skill_frame@, RS = @crc:better_ui_skill_rs_badge@, LINE = @crc:better_ui_skill_line@,
    CHIP = @crc:better_ui_skill_chip@, SLOT = @crc:better_ui_skill_slot@, TRACK = @crc:better_ui_skill_track@,
    THUMB = @crc:better_ui_skill_thumb@, ARROW_LEFT = @crc:better_ui_skill_arrow_l@, ARROW_RIGHT = @crc:better_ui_skill_arrow_r@,
    UNDERLINE = @crc:better_ui_skill_underline@, GLOW = @crc:better_ui_skill_glow@,
  }
  -- the parts of betterui_skill_book (layout team08_02_bui_book) each instance role shows
  S.M = {
    underline = { @crc:_list_base_xs01_on@ }, book = { @crc:_icon_sp_area_dmy01@ },
    element = { @crc:_icon_cmd_type_base01@, @crc:_icon_cmd_type_dmy01@ },
    -- never shown: the row's other plates (its focus animation sets their size, so no own size holds) and the sixth
    -- sense dummy (a white quad the retail object hides: CSetupMeshVisible _icon_sixth_dmy01)
    hidden = { @crc:_list_base_xs01_off@, @crc:_list_base_xs01_ol@, @crc:_icon_sixth_dmy01@ },
  }
  S.NAME_TEXTS = { @crc:_text_list01_on@, @crc:_text_list01_off@ }
  -- the card's window plate, side line and type pill, and its TENSIÓN gauge squares after the first (the sketch keeps
  -- «TENSIÓN ■ … 40T» only)
  S.CARD_HIDE_MESHES = { @crc:_sp_win_base01@, @crc:_item_win_line01@, @crc:_area_base01@, @crc:_tension_off01@,
    @crc:_tension_on02@, @crc:_tension_on03@, @crc:_tension_on04@, @crc:_tension_on05@, @crc:_tension_on06@,
    @crc:_tension_on07@, @crc:_tension_on08@, @crc:_tension_on09@, @crc:_tension_on10@ }
  S.CARD_TEXT_AREA = @crc:_text_area01@
  S.EFFECT_TEXT = @crc:_text_guide01@
  S.RS_KEY = @crc:betterqol_tech_preview_key@

  -- Layout of the owner's sketch (screen px from the top left, y down; drawn at (x, -y)). Left column: the thumbnail,
  -- under it the card's plate and TENSIÓN row (their joints in the card's layout copy team02_02_bui_card). Right
  -- column: the card's description from the thumbnail's top, then the effects block: its first line at DESC_TOP,
  -- DESC_LINE px a line, the lines its text takes in the retail box (DESC_BOX px of fs_32 glyphs DESC_GLYPH px wide on
  -- average, up to DESC_MAX_LINES). The underline quad of the book layout is 212 x 4 at (-106, -138) from its origin,
  -- the plate / outline quads 1 x 1 centred on it.
  S.G = {
    SLOT_X = { 0, 254, 426, 599, 772 }, BOOK_BASE = 832, FOCUS_RAISE = 24,
    SLOT_SCALE = { 1, 0.62, 0.58, 0.5, 0.4 }, SLOT_SHADE = { 1, 0.85, 0.75, 0.6, 0.45 },
    CX = 960, UNDERLINE = { 106, 138, 212, 4 }, FACE_SIDE = 125,
    FRAME = { 461, 372.5, 614, 345 }, THUMB_BOOK_SCALE = 2, RS = { 728, 504 },
    BAR = { 480, 950, 960, 4 }, BAR_THUMB = { 32, 8 }, COUNTER = { 959, 972 },
    ARROW_LEFT = { 60, 787 }, ARROW_RIGHT = { 1860, 787 }, ARROW = { 40, 68 }, RS_BADGE = 56,
    NAME_GAP = { 30, 22 }, NAME_SCALE = { 1.3, 0.9 }, NAME_ROOM = { 320, 160 }, NAME_MIN = 0.8, UNDERLINE_GAP = 28,
    GLOW = { 200, 44, 0.5 }, GLOW_DY = -6, SLOT_SIDE = 32, CHIP = { 48, 56, 28 },
    COLUMN = { { 845, 1291 }, { 1336, 1786 } }, LINE_H = 4,
    CARD_DX = -127, CARD_DY = 458,
    DESC_TOP = 222, DESC_LINE = 54, DESC_BOX = 832, DESC_GLYPH = 15.4, DESC_MAX_LINES = 3, TITLE_GAP = 30,
    TITLE_X = 845, TITLE_LINE = { 1416.5, 567, 2 },
    -- Hissatsu Effects' card page dots (skill_card, SKILL_CARD_DOTS_XY): its default place {0, -150} shows at screen
    -- DOTS_SCREEN on this card; they go to the right end of the effects header, DOTS_X
    DOTS_DEFAULT = { 0, -150 }, DOTS_SCREEN = { 1284, 344 }, DOTS_X = 1750,
    -- Effect rows: a row is ROW_H px high, each line past the first EFFECT_LINE px more (its fs_24 text box is centred
    -- on the row); the first row's top ROW_FIRST px under the title. An effect whose text fits one line of its column
    -- takes one cell (two a line, left to right); a longer one takes both columns and wraps into as many lines as it
    -- needs. VALUE_GLYPH: the average glyph of the fs2_26 value («+12 %» is 88 px in game).
    EFFECT_GLYPH = 13, VALUE_GLYPH = 18, EFFECT_GAP = 12, ROW_H = 48, EFFECT_LINE = 28, ROW_FIRST = 13,
    ICON_X = { 857, 1352 }, ICON_CENTRE = { 38, -36 },
    -- GRADE_SCALE: the level tag's scale when it shows the game's grade glyph (its square is about 40 px at scale 1: at
    -- 2 it took 80 px and overran the 48 px rows in install 727)
    GRADE_SCALE = 1,
    TAG_RIGHT = 70, TEXT_DX = 32, TEXT_TAG_DX = 82, TAB_DX = 491, TAB_DY = 88,
    VALUE_RIGHT = { 1291, 1786 },
  }
  -- betterui_skill_book instances: 0-8 the carousel (slot d at 4 + d), then these (9, 12, 13, 14: retired, kept
  -- hidden); labels: these, the carousel names at NAME + 4 + d
  S.B = { FRAME = 9, THUMB_BOOK = 11, BAR = 12, BAR_THUMB = 13, TITLE_LINE = 14, ICON = 15 }
  S.T = { COUNTER = 0, LEFT = 1, RIGHT = 2, RS = 3, NAME = 4 }

  S.items, S.inst_item, S.inst_skill, S.open, S.labels_open, S.card_base, S.warned = {}, {}, {}, {}, {}, nil, {}
  S.art_list = {}

  -- The redesign is off unless BetterUI's config.toml says [skill_screen] redesign = true (read once, at the screen's
  -- first callback): off, every wrap below hands the call to the retail function and the screen stays the game's.
  function S.on()
    if S.enabled == nil then
      local ok, on = pcall(funcLuaCommand, @crc:CMND_BETTERUI_SKILL_SCREEN_REDESIGN@)
      S.enabled = ok and on == true
      -- The redesign lists the move's rule texts under the card, so the card's effect page leaves them out (skill_card).
      SKILL_CARD_RULES_SHOWN = S.enabled or nil
    end
    return S.enabled
  end

  -- Wraps the retail callback `name` with fn while the redesign is on.
  function S.wrap(name, fn)
    VRFW.host.wrap_once(name, OWNER, function(retail, ...)
      if not S.on() then
        return retail(...)
      end
      return fn(retail, ...)
    end)
  end

  local function menu(...)
    return funcLuaMenuCommand(...)
  end

  local function text_by_key(key)
    local ok, s = pcall(funcLuaCommand, S.C.TEXT_BY_KEY, key)
    return ok and type(s) == "string" and s or ""
  end

  local function opened(layer, j)
    local key = layer .. ":" .. j
    if not S.open[key] then
      menu(S.C.OPEN, layer, j)
      S.open[key] = true
    end
  end

  local function log(...)
    pcall(funcLuaCommand, S.C.LOG, "BetterUI skill_screen", ...)
  end

  local function hide(layer, j)
    if S.open[layer .. ":" .. j] then
      menu(S.C.LAYER_VISIBLE, layer, j, false)
    end
  end

  -- The move name the retail row shows (UpdateListItem's rule: an aura row names its keshin / partner).
  function S.skill_name(skill)
    local ok, name_id = funcLuaCommand(S.C.SKILL_INFO, skill, 4)
    if ok ~= true then
      return ""
    end
    local kind_ok, kind = funcLuaCommand(S.C.SKILL_INFO, skill, 9)
    local variant, partner = 0, ""
    if kind_ok and kind == 8 then
      local _, aura = funcLuaCommand(S.C.SKILL_INFO, skill, 13)
      local _, chara = funcLuaCommand(S.C.SKILL_INFO, skill, 17)
      if chara ~= nil and chara ~= 0 then
        if IsAuraSkillMixiMax(aura) then
          _, partner = funcLuaCommand(S.C.CHARA_INFO, chara, 10)
        elseif IsAuraSkillSoul(aura) then
          _, partner = funcLuaCommand(S.C.CHARA_INFO, chara, 0)
        elseif IsAuraSkillKeshinOrKeshinArmed(aura) then
          variant = 11
        end
      end
    end
    local text_id = funcLuaCommand(S.C.NAME_TEXT, name_id, variant)
    -- A plain label draws this name and its width is counted in glyphs: the text's markup tags are left out.
    local name = funcLuaCommand(S.C.TEXT_CONVERT, text_id, 0, 2508554842, partner or "") or ""
    return (name:gsub("</?%u[^<>]*>", ""))
  end

  -- A miximax move with a card of its own: the character its player turns into and the partner's name alone (the
  -- retail name is a prefix plus that name); nil for any other move and without the framework's face icons.
  function S.mix_face(skill)
    if VRFW.face_icon == nil or skill == nil or skill == 0 then
      return nil
    end
    local ok, kind = funcLuaCommand(S.C.SKILL_INFO, skill, 9)
    local _, aura = funcLuaCommand(S.C.SKILL_INFO, skill, 13)
    if ok ~= true or kind ~= 8 or not IsAuraSkillMixiMax(aura) then
      return nil
    end
    local okv, variant = pcall(funcLuaCommand, @crc:CMND_VRFW_AURA_VARIANT_CHARA@, skill)
    local _, chara = funcLuaCommand(S.C.SKILL_INFO, skill, 17)
    if not okv or type(variant) ~= "number" or variant == 0 or chara == nil or chara == 0 then
      return nil
    end
    local _, partner = funcLuaCommand(S.C.CHARA_INFO, chara, 10)
    if type(partner) ~= "string" or partner == "" then
      return nil
    end
    return variant, (partner:gsub("</?%u[^<>]*>", ""))
  end

  -- Face instance j: the retail mini-face of character `chara` centred on screen (x, y), `size` px; nil hides it.
  -- Answers whether a face is drawn or loading there.
  function S.draw_face(j, chara, x, y, size)
    if chara == nil then
      hide(S.L.FACE, j)
      return false
    end
    opened(S.L.FACE, j)
    menu(S.C.LAYER_VISIBLE, S.L.FACE, j, true)
    if VRFW.face_icon.card(S.L.FACE, j, chara, x, y, size) == false then
      hide(S.L.FACE, j)
      return false
    end
    return true
  end

  -- Book instance j as `role` ({part list = true}), scaled (sx, sy), at layer place (x, y); skill = its icons and name.
  function S.draw_book(j, x, y, sx, sy, shown, skill, shade)
    local L = S.L.BOOK
    opened(L, j)
    if skill ~= nil then
      SetupCommandActionSkillInfoCategoryIcon(L, j, skill)
      SetupSpecialSkillInfoElementIcon(L, j, skill)
      local ok, kind = funcLuaCommand(S.C.SKILL_INFO, skill, 9)
      if shown.book and (not ok or GetSkillCategoryIcon(kind, skill, 0) == 0) and not S.warned[skill] then
        S.warned[skill] = true
        log("no book sprite for move", string.format("%08X", skill), "kind", tostring(kind))
      end
    end
    for part, meshes in pairs(S.M) do
      for _, m in ipairs(meshes) do
        menu(S.C.MESH_VISIBLE, L, m, shown[part] == true, j)
      end
    end
    local name = shown.name and skill ~= nil and S.skill_name(skill) or nil
    for _, t in ipairs(S.NAME_TEXTS) do
      menu(S.C.TEXT_VISIBLE, L, t, name ~= nil, j)
      if name ~= nil then
        menu(S.C.SET_TEXT, L, t, name, j)
      end
    end
    local v = shade or 1
    menu(VRFW.emblem_grid.C.COLOR, L, j, VRFW.emblem_grid.GRAY, v, v, v)
    menu(S.C.LOCAL_SCALE, L, sx, sy, 1, j)
    menu(S.C.LOCAL_POS, L, x, y, 0, j)
    menu(S.C.LAYER_VISIBLE, L, j, true)
  end

  local function label(j, x, y, s, scale, room)
    VRFW.emblem_grid.show_label(S.L.LABEL, j, x, -y, s, S.labels_open, room, nil, scale)
  end

  -- Own sprite `sprite` as a w x h quad centred at screen (x, y), queued for the next S.flush_art.
  function S.art(sprite, x, y, w, h, alpha)
    S.art_list[#S.art_list + 1] = { sprite, x, y, w, h, alpha or 1 }
  end

  -- Draws the queued own sprites under the books (their layer's draw priority - 1); the unused instances hide.
  -- While the atlas loads nothing shows and Step calls this again.
  function S.flush_art()
    S.kit = S.kit or VRFW.screen_kit.new({ log = log, caps = { [S.L.ART] = S.ART_COUNT } })
    local K, L = S.kit, S.L.ART
    K.begin()
    local tex = K.texture(S.ART_ATLAS)
    if tex == nil and not S.warned.atlas then
      S.warned.atlas = true
      log("INFO own atlas not loaded", S.ART_ATLAS)
    end
    if tex and S.art_prio == nil then
      local p = menu(VRFW.screen_kit.C.GET_PRIO, S.L.BOOK, 4)   -- the focused book, open while the list has rows
      S.art_prio = type(p) == "number" and p or false
    end
    local base = tex and S.art_prio or nil
    if tex and not S.warned.prio then
      S.warned.prio = true
      log("INFO own art draw priority", tostring(base and base - 1), "book layer", tostring(base))
    end
    for _, a in ipairs(tex and S.art_list or {}) do
      local i = K.slot(L)
      if i == nil then
        break
      end
      K.show(L, i)
      if K.textured_quad(L, i, tex, a[1], a[2], a[3], a[4], a[5]) == false and not S.warned[a[1]] then
        S.warned[a[1]] = true
        log("INFO own sprite did not resolve", string.format("%08X", a[1]), S.ART_ATLAS)
      end
      K.set(L, i, "a", VRFW.screen_kit.C.ALPHA, L, i, 0, a[6])
      if base then
        K.set(L, i, "prio", VRFW.screen_kit.C.SET_PRIO, L, i, base - 1, true)
      end
    end
    K.finish()
    S.art_waiting = tex == false
  end

  -- Which rows the hidden list holds: row instance k sits on locator k, so its row is the focused row + (k - the
  -- focused instance). The focused instance is the one whose filled move is the card's.
  function S.learn_rows(focus, skill)
    local count = tonumber(menu(@crc:CMND_GET_CREATE_LAYER_NUM@, S.L.ITEM)) or 0
    local focused = nil
    for k = 0, count - 1 do
      if S.inst_skill[k] == skill then
        focused = k
      end
    end
    S.items[focus] = skill
    if focused == nil then
      if not S.warned.rows then
        S.warned.rows = true
        log("focused move not among the filled rows", string.format("%08X", skill), "instances", count)
      end
    else
      for k = 0, count - 1 do
        if S.inst_skill[k] ~= nil and menu(S.C.IS_VISIBLE, S.L.ITEM, k) == true then
          S.items[focus + k - focused] = S.inst_skill[k]
        end
      end
    end
    S.read_list(focus, skill, focused ~= nil and S.inst_item[focused] or nil)
  end

  -- Rows focus - 4 .. focus + 4 of the list the game built (the hidden list's 11 row locators hold one page of it), so
  -- the side books continue across its pages. The focused row says whether the built list holds moves or items; when it
  -- holds neither, the list is another one and only the page's rows show.
  function S.read_list(focus, skill, item)
    local ids = VRFW.ids
    local r = table.pack(pcall(funcLuaCommand, S.C.LIST_ITEMS, focus - 4, 9))
    local mid = r[1] == true and ids.unsigned(r[6]) or 0
    local as_item = item ~= nil and mid ~= 0 and mid == ids.unsigned(item)
    if mid == 0 or not (as_item or mid == ids.unsigned(skill)) then
      if not S.warned.list then
        S.warned.list = true
        local got, known = {}, {}
        for d = -4, 4 do
          got[#got + 1] = string.format("%d=%08X", focus + d, ids.unsigned(r[6 + d]))
        end
        for k, sk in pairs(S.inst_skill) do
          known[#known + 1] = string.format("i%d=%08X", k, ids.unsigned(sk))
        end
        -- where the built list holds the focused move (a bounded walk of 16-row reads over its first 512 rows, once)
        local at = "none of the first 512"
        for first = 0, 511, 16 do
          local w = table.pack(pcall(funcLuaCommand, S.C.LIST_ITEMS, first, 16))
          for i = 2, w.n do
            if ids.unsigned(w[i]) == ids.unsigned(skill) then
              at = tostring(first + i - 2)
            end
          end
          if at ~= "none of the first 512" or w.n < 17 then
            break
          end
        end
        log("built list does not hold the focused row", "focus " .. focus .. ", move " .. string.format("%08X", skill) ..
          ", item " .. tostring(item) .. ", the move at built row " .. at .. ", rows shown " ..
          tostring(menu(S.C.LIST_COUNT, S.L.LIST)) .. "; built " .. table.concat(got, " ") .. "; page " .. table.concat(known, " "))
      end
      return
    end
    local form = as_item and ((item < 0) and ids.signed or ids.unsigned) or ((skill < 0) and ids.signed or ids.unsigned)
    for d = -4, 4 do
      local id = ids.unsigned(r[6 + d])
      local move = id ~= 0 and (as_item and funcLuaCommand(S.C.ITEM_TO_SKILL, form(id)) or form(id)) or 0
      if move ~= nil and move ~= 0 then
        S.items[focus + d] = move
      end
    end
  end

  -- Carousel slot d: its centre x, its book's centre y and bottom (side books on one baseline, the focused one raised).
  function S.slot_place(d)
    local G = S.G
    local a = math.abs(d) + 1
    local bottom = G.BOOK_BASE - (d == 0 and G.FOCUS_RAISE or 0)
    return G.CX + (d < 0 and -G.SLOT_X[a] or G.SLOT_X[a]), bottom - 62.5 * G.SLOT_SCALE[a], bottom
  end

  -- s cut to at most `units` glyph units, «...» included
  local function cut_units(s, units)
    local EG = VRFW.emblem_grid
    local out, n = {}, EG.glyph_units(EG.CUT_MARK)
    for ch in s:gmatch("[\1-\127\194-\244][\128-\191]*") do
      local w = EG.glyph_units(ch)
      if n + w > units then
        break
      end
      out[#out + 1] = ch
      n = n + w
    end
    return (table.concat(out):gsub("%s+$", "")) .. EG.CUT_MARK
  end

  -- Name s fitted into a slot `room` px wide at text scale `scale`: shrunk down to NAME_MIN of it, then cut with «...».
  function S.fit_name(s, scale, room)
    local G, EG = S.G, VRFW.emblem_grid
    local width = EG.glyph_units(s) * EG.GLYPH_W * scale
    if width <= room then
      return s, scale
    end
    local fit = scale * room / width
    if fit >= scale * G.NAME_MIN then
      return s, fit
    end
    fit = scale * G.NAME_MIN
    return cut_units(s, math.floor(room / (EG.GLYPH_W * fit))), fit
  end

  -- The carousel: the 9 rows around the focused one, the focused book in the centre.
  function S.draw_carousel(focus, n)
    local G = S.G
    local B, T, A = S.B, S.T, S.A
    for d = -4, 4 do
      local a = math.abs(d) + 1
      local skill = (focus + d >= 0 and focus + d < n) and S.items[focus + d] or nil
      if skill == nil then
        hide(S.L.BOOK, 4 + d)
        hide(S.L.FACE, 4 + d)
        label(T.NAME + 4 + d, 0, 0, nil)
      else
        local x, y, bottom = S.slot_place(d)
        local s = G.SLOT_SCALE[a]
        local k = d == 0 and 1 or 2
        local name_y = G.BOOK_BASE + G.NAME_GAP[k]
        if d == 0 then
          S.art(A.GLOW, x, bottom + G.GLOW_DY, G.GLOW[1], G.GLOW[2], G.GLOW[3])
          S.art(A.UNDERLINE, x, name_y + G.UNDERLINE_GAP, G.UNDERLINE[3], G.LINE_H)
        end
        -- a miximax with a card of its own: that card's mini-face in place of the book icon, the partner's name alone
        local face, partner = S.mix_face(skill)
        local faced = S.draw_face(4 + d, face, x, y, G.FACE_SIDE * s)
        S.draw_book(4 + d, x, -y, s, s, { book = not faced, element = true }, skill, G.SLOT_SHADE[a])
        -- the names: one text size for every side book, the focused one larger, each fitted into its slot
        local name, scale = S.fit_name(faced and partner or S.skill_name(skill), G.NAME_SCALE[k], G.NAME_ROOM[k])
        label(T.NAME + 4 + d, x, name_y, name, scale)
      end
    end
    hide(S.L.BOOK, B.BAR)
    hide(S.L.BOOK, B.BAR_THUMB)
    S.art(A.TRACK, G.BAR[1] + G.BAR[3] / 2, G.BAR[2], G.BAR[3], G.BAR[4])
    local t = n > 1 and focus / (n - 1) or 0
    S.art(A.THUMB, G.BAR[1] + G.BAR_THUMB[1] / 2 + t * (G.BAR[3] - G.BAR_THUMB[1]), G.BAR[2], G.BAR_THUMB[1], G.BAR_THUMB[2])
    label(T.COUNTER, G.COUNTER[1], G.COUNTER[2], string.format("%d / %d", focus + 1, n))
    label(T.LEFT, 0, 0, nil)
    label(T.RIGHT, 0, 0, nil)
    if focus > 0 then
      S.art(A.ARROW_LEFT, G.ARROW_LEFT[1], G.ARROW_LEFT[2], G.ARROW[1], G.ARROW[2])
    end
    if focus < n - 1 then
      S.art(A.ARROW_RIGHT, G.ARROW_RIGHT[1], G.ARROW_RIGHT[2], G.ARROW[1], G.ARROW[2])
    end
  end

  -- The thumbnail frame (16:9) with the focused move's book until its still exists; the RS glyph when Better QoL
  -- plays the move's cut-in from this screen (its prompt is up).
  function S.draw_thumbnail(skill)
    local G, B = S.G, S.B
    local F = G.FRAME
    hide(S.L.BOOK, B.FRAME)
    if S.model_shows(skill) then
      hide(S.L.BOOK, B.THUMB_BOOK)
      label(S.T.RS, G.RS[1], G.RS[2], nil)
      return
    end
    S.art(S.A.FRAME, F[1], F[2], F[3], F[4])
    S.draw_book(B.THUMB_BOOK, F[1], -F[2], G.THUMB_BOOK_SCALE, G.THUMB_BOOK_SCALE, { book = true, element = true }, skill)
    local preview = BetterQoL ~= nil and type(BetterQoL.tech_preview) == "table" and BetterQoL.tech_preview.shown == true
    local glyph = preview and funcLuaCommand(S.C.TEXT_GET, S.RS_KEY) or nil
    glyph = type(glyph) == "string" and glyph ~= "" and glyph or nil
    if glyph ~= nil then
      S.art(S.A.RS, G.RS[1], G.RS[2], G.RS_BADGE, G.RS_BADGE)
    end
    label(S.T.RS, G.RS[1], G.RS[2], glyph)
  end

  -- The effects title's line (screen y): under the lines the move's description takes in the card.
  function S.effects_top(skill)
    local G = S.G
    local lines = 1
    local ok, desc_id = funcLuaCommand(S.C.SKILL_INFO, skill, 5)
    local desc = ok == true and funcLuaCommand(S.C.DESC_TEXT, desc_id) or nil
    if type(desc) == "string" and desc ~= "" then
      lines = 0
      for part in (desc .. "\n"):gmatch("([^\n]*)\n") do
        lines = lines + math.max(1, math.ceil(VRFW.emblem_grid.glyph_units(part) * G.DESC_GLYPH / G.DESC_BOX))
      end
      lines = math.min(lines, G.DESC_MAX_LINES)
    end
    return G.DESC_TOP + lines * G.DESC_LINE + G.TITLE_GAP
  end

  -- A left click on a carousel book: the list's focus moves to its row (the path the arrows take: the list's own
  -- focus, its OnChangeFocus / UpdateSkillDetailWindow). Read on the button's press only.
  -- True while Better QoL's cut-in preview is offered for the card's move (its prompt is up).
  function S.preview_shown()
    return BetterQoL ~= nil and type(BetterQoL.tech_preview) == "table" and BetterQoL.tech_preview.shown == true
      and type(BetterQoL.tech_preview.request) == "function"
  end

  function S.click(focus, n)
    local down = VRFW.emblem_grid.key_down("click")
    local pressed = down and not S.click_held
    S.click_held = down
    if not pressed or n <= 0 then
      return
    end
    local x, y = menu(S.C.POINTER)
    if type(x) ~= "number" or type(y) ~= "number" then
      return
    end
    local G = S.G
    -- the thumbnail plays the move's cut-in full screen: Better QoL's preview (the same path as its R3 / RS key)
    local F = G.FRAME
    if math.abs(x - F[1]) <= F[3] / 2 and math.abs(y - F[2]) <= F[4] / 2 then
      if S.preview_shown() then
        BetterQoL.tech_preview.request()
      end
      return
    end
    for d = -4, 4 do
      local a = math.abs(d) + 1
      local cx, cy = S.slot_place(d)
      local half = 62.5 * G.SLOT_SCALE[a]
      local row = focus + d
      if d ~= 0 and row >= 0 and row < n and S.items[row] ~= nil and math.abs(x - cx) <= math.max(half, 60)
        and y >= cy - half and y <= G.BOOK_BASE + G.NAME_GAP[2] + 20 then
        menu(S.C.SET_FOCUS, S.L.ITEM, row, true)
        return
      end
    end
  end

  -- Text s broken at spaces into lines of at most `room` px (fs_24 glyphs) and the number of lines; a word wider
  -- than the room keeps its own line (the text box squeezes only what still overflows).
  function S.wrap(s, room)
    local G, EG = S.G, VRFW.emblem_grid
    local units = math.max(1, math.floor(room / G.EFFECT_GLYPH))
    local lines, cur = {}, nil
    for word in s:gmatch("%S+") do
      local joined = cur and (cur .. " " .. word) or word
      if cur ~= nil and EG.glyph_units(joined) > units then
        lines[#lines + 1] = cur
        cur = word
      else
        cur = joined
      end
    end
    lines[#lines + 1] = cur or ""
    return table.concat(lines, "\n"), #lines
  end

  -- Places the effect rows from screen y `top` down (S.G effect rules): { col = 1 / 2, or nil for both columns, y = the
  -- row's centre, h, text, lines } each.
  function S.effect_cells(slots, top)
    local G, EG = S.G, VRFW.emblem_grid
    local cells, y, col = {}, top + G.ROW_FIRST, 1
    local function room(e, c, right)
      local value_w = e.value ~= nil and EG.glyph_units(e.value) * G.VALUE_GLYPH or 0
      return right - value_w - G.EFFECT_GAP - (G.ICON_X[c] + (e.level ~= nil and G.TEXT_TAG_DX or G.TEXT_DX))
    end
    for _, e in ipairs(slots) do
      if EG.glyph_units(e.text) * G.EFFECT_GLYPH <= room(e, col, G.VALUE_RIGHT[col]) then
        cells[#cells + 1] = { e = e, col = col, y = y + G.ROW_H / 2, h = G.ROW_H, text = e.text }
        if col == 2 then
          y = y + G.ROW_H
        end
        col = 3 - col
      else
        if col == 2 then
          y, col = y + G.ROW_H, 1
        end
        local text, lines = S.wrap(e.text, room(e, 1, G.VALUE_RIGHT[2]))
        local h = G.ROW_H + (lines - 1) * G.EFFECT_LINE
        cells[#cells + 1] = { e = e, y = y + h / 2, h = h, text = text }
        y = y + h
      end
    end
    return cells
  end

  -- The move's effects: the rules that name it (Hissatsu Effects; their value apart, in green), then what each of its
  -- levels changes (Hissatsu Reforged, «Nv N» tag, by level); placed by S.effect_cells, up to 6. Nothing without
  -- those mods.
  -- The game's grade glyph of `skill` at effect level `level` (grade level - 1, by the move's growth type, as the move
  -- lists draw it after the name: AppendEvoCodeToSkillName); "" when the move's growth type has none.
  function S.grade_text(skill, level)
    local ok, growth = funcLuaCommand(S.C.SKILL_INFO, skill, 16)
    if ok ~= true or type(growth) ~= "number" or type(AppendEvoCodeToSkillName) ~= "function" then
      return ""
    end
    local okg, s = pcall(AppendEvoCodeToSkillName, "", (tonumber(level) or 1) - 1, growth)
    return okg and type(s) == "string" and s or ""
  end

  function S.draw_effects(skill)
    local rows = {}
    local ok, r = pcall(funcLuaCommand, S.C.RULE_TEXTS, skill)
    if skill ~= 0 and ok and type(r) == "table" then
      local values, rests = type(r.value) == "table" and r.value or {}, type(r.rest) == "table" and r.rest or {}
      for i = 1, tonumber(r.count) or 0 do
        if type(r[i]) == "string" and r[i] ~= "" then
          local value = values[i]
          rows[#rows + 1] = { text = value ~= nil and rests[i] or r[i], value = rests[i] ~= nil and value or nil }
        end
      end
    end
    local levels = {}
    -- the rows of one level command: { count, [i] = { level, text, shown } }
    local function level_rows(command)
      local okl, lv = pcall(funcLuaCommand, command, skill)
      if skill ~= 0 and okl and type(lv) == "table" then
        for i = 1, tonumber(lv.count) or 0 do
          local e = lv[i]
          if type(e) == "table" and type(e.text) == "string" and e.text ~= "" then
            levels[#levels + 1] = { text = e.text, value = e.shown, level = e.level, plain = e.plain }
          end
        end
      end
    end
    level_rows(S.C.LEVEL_EFFECTS)
    level_rows(S.C.GRADE_TEXTS)
    level_rows(S.C.TOTEM_EFFECTS)
    table.sort(levels, function(p, q) return (tonumber(p.level) or 0) < (tonumber(q.level) or 0) end)
    local slots = {}
    for _, e in ipairs(rows) do slots[#slots + 1] = e end
    for _, e in ipairs(levels) do slots[#slots + 1] = e end
    local G, B = S.G, S.B
    local top = S.effects_top(skill)
    if #rows + #levels > 0 then
      opened(S.L.EFFECT_TITLE, 0)
      menu(S.C.LOCAL_POS, S.L.EFFECT_TITLE, G.TITLE_X, -top, 0, 0)
      menu(S.C.LAYER_VISIBLE, S.L.EFFECT_TITLE, 0, true)
      menu(S.C.SET_TEXT, S.L.EFFECT_TITLE, S.EFFECT_TEXT, text_by_key("BetterUI.skill_effects"), 0)
      S.art(S.A.LINE, G.TITLE_LINE[1], top, G.TITLE_LINE[2], G.LINE_H)
    else
      hide(S.L.EFFECT_TITLE, 0)
    end
    hide(S.L.BOOK, B.TITLE_LINE)
    local tag = text_by_key("BetterUI.skill_effect_level")
    local cells = S.effect_cells(slots, top)
    for j = 0, 5 do
      local cell = cells[j + 1]
      local e = cell and cell.e
      local col = cell and cell.col or 1
      local left, right = G.COLUMN[col][1], G.COLUMN[cell and cell.col or 2][2]
      local ix, y = G.ICON_X[col], cell and cell.y or 0
      if cell ~= nil then
        S.art(S.A.LINE, (left + right) / 2, y + cell.h / 2, right - left, G.LINE_H)
      end
      if e == nil then
        hide(S.L.BOOK, B.ICON + j)
        hide(S.L.TAG, j)
        hide(S.L.EFFECT, j)
        hide(S.L.VALUE, j)
      else
        S.art(S.A.SLOT, ix, y, G.SLOT_SIDE, G.SLOT_SIDE)
        S.draw_book(B.ICON + j, ix - G.ICON_CENTRE[1], -y - G.ICON_CENTRE[2], 1, 1, { element = true }, skill)
        if e.level ~= nil then
          -- the level: the game's grade glyph; the «Nv N» chip for a move whose growth type has no glyph
          local grade = e.plain and "" or S.grade_text(skill, e.level)
          local scale = grade ~= "" and G.GRADE_SCALE or 1
          if grade == "" then
            S.art(S.A.CHIP, ix + G.CHIP[1], y, G.CHIP[2], G.CHIP[3])
          end
          opened(S.L.TAG, j)
          menu(S.C.LOCAL_SCALE, S.L.TAG, scale, scale, 1, j)
          menu(S.C.LOCAL_POS, S.L.TAG, ix + G.TAG_RIGHT, -y, 0, j)
          menu(S.C.LAYER_VISIBLE, S.L.TAG, j, true)
          menu(S.C.SET_TEXT, S.L.TAG, S.EFFECT_TEXT, grade ~= "" and grade or (tag:gsub("{n}", tostring(e.level))), j)
        else
          hide(S.L.TAG, j)
        end
        opened(S.L.EFFECT, j)
        local tx = ix + (e.level ~= nil and G.TEXT_TAG_DX or G.TEXT_DX)
        menu(S.C.LOCAL_POS, S.L.EFFECT, tx, -y, 0, j)
        menu(S.C.LAYER_VISIBLE, S.L.EFFECT, j, true)
        menu(S.C.SET_TEXT, S.L.EFFECT, S.EFFECT_TEXT, cell.text, j)
        if e.value ~= nil then
          opened(S.L.VALUE, j)
          menu(S.C.LOCAL_POS, S.L.VALUE, right, -y, 0, j)
          menu(S.C.LAYER_VISIBLE, S.L.VALUE, j, true)
          menu(S.C.SET_TEXT, S.L.VALUE, S.EFFECT_TEXT, e.value, j)
        else
          hide(S.L.VALUE, j)
        end
      end
    end
  end

  -- The card on the right half without its window plate, side line and type pill.
  function S.dress_card()
    local L, G = S.L.CARD, S.G
    if S.card_base == nil then
      local x, y = menu(S.C.GET_LOCAL_POS, L, 0)
      S.card_base = { tonumber(x) or 0, tonumber(y) or 0 }
      menu(S.C.LOCAL_POS, L, S.card_base[1] + G.CARD_DX, S.card_base[2] + G.CARD_DY, 0, 0)
    end
    for _, m in ipairs(S.CARD_HIDE_MESHES) do
      menu(S.C.MESH_VISIBLE, L, m, false, 0)
    end
    menu(S.C.TEXT_VISIBLE, L, S.CARD_TEXT_AREA, false, 0)
  end

  -- An empty tab: nothing but the tab bar and the retail «no moves» text.
  function S.clear()
    S.focus = nil
    for j = 0, 26 do
      hide(S.L.BOOK, j)
    end
    for j = 0, 8 do
      hide(S.L.FACE, j)
    end
    for j = 0, S.T.NAME + 8 do
      label(j, 0, 0, nil)
    end
    S.art_list = {}
    S.draw_effects(0)
    S.flush_art()
    S.model_focus(0)
  end

  function S.forget_rows()
    S.items = {}
  end

  -- The focused aura's 3D model (Keshin, Totem and Miximax tabs): it stands free in the whole left area, facing the camera,
  -- in place of the thumbnail box (layer betterui_skill_model: skill_list_carousel.toml). Built once the focus rests
  -- MODEL.SETTLE Steps on a move, released on a tab change and on leave. BOX: the screen px it may take (left, top,
  -- right, bottom); PX_PER_M and EYE_Y: the layer's camera at the model's depth (935586083: eye (0, 1.5, 10.5),
  -- FOV 20). STAND: the keshin stand clip of a keshin's own motion pack; STAND_BODY: the stand clip of the body packs.
  -- VARIANT: (aura) -> the character its player turns into; MODEL_H: (model handle) -> a built character's height.
  S.L.MODEL = @crc:betterui_skill_model@
  S.MODEL = { SETTLE = 12, STAND = 1652922282 --[[化身立ち1L]], STAND_BODY = 2263925137 --[[立ち1L]], HANDLE = 3895705890,
    SCALE_SET = 2982269573, MODEL_H = 740963128, VARIANT = @crc:CMND_VRFW_AURA_VARIANT_CHARA@,
    POS = @crc:CMND_SET_CHARA_MODEL_POS@, BOUNDS = @crc:CMND_VRFW_MODEL_BOUNDS@,
    BOX = { 12, 190, 788, 912 }, PX_PER_M = 291.7, EYE_Y = 1.5 }
  --@lib vrfw_menu_kit.lua#CharaModel

  -- The character an aura move shows, its stand clip and the bounds of its model file (lower corner, upper corner):
  -- a keshin or a totem is a model of its own; a miximax shows the character its player turns into, built from body
  -- parts (no bounds: fitted by its height). nil for any other move and for an aura without such a model.
  function S.spirit_chara(skill)
    if skill == nil or skill == 0 then
      return nil
    end
    local ok, kind = funcLuaCommand(S.C.SKILL_INFO, skill, 9)
    if ok ~= true or kind ~= 8 then
      return nil
    end
    local _, aura = funcLuaCommand(S.C.SKILL_INFO, skill, 13)
    if IsAuraSkillMixiMax(aura) then
      local okv, variant = pcall(funcLuaCommand, S.MODEL.VARIANT, skill)
      if not okv or type(variant) ~= "number" or variant == 0 then
        return nil
      end
      return variant, S.MODEL.STAND_BODY, nil
    end
    local _, chara = funcLuaCommand(S.C.SKILL_INFO, skill, 17)
    if type(chara) ~= "number" or chara == 0 or not (IsAuraSkillKeshin(aura) or IsAuraSkillSoul(aura)) then
      return nil
    end
    local okb, found, lx, ly, lz, hx, hy, hz = pcall(funcLuaCommand, S.MODEL.BOUNDS, chara)
    if not okb or found ~= true or type(hz) ~= "number" then
      return nil
    end
    return chara, IsAuraSkillKeshin(aura) and S.MODEL.STAND or nil, { lx, ly, lz, hx, hy, hz }
  end

  -- True while the model stands in for the thumbnail box of this move.
  function S.model_shows(skill)
    return (S.model == nil or S.model.ok()) and S.spirit_chara(skill) ~= nil
  end

  -- The focus is on this move: its model is asked for after the settle time; any other move releases the model.
  function S.model_focus(skill)
    local chara, stand, bounds = S.spirit_chara(skill)
    if chara == nil then
      S.model_want = nil
      if S.model ~= nil then
        S.model.release()
      end
      return
    end
    local W = S.model_want
    if W == nil or W.chara ~= chara then
      S.model_want = { chara = chara, stand = stand, bounds = bounds, wait = S.MODEL.SETTLE, fitted = false }
      if S.model ~= nil then
        S.model.hide()
      end
    end
  end

  -- Fits the built model into MODEL.BOX by height and by width: centred, its lowest point on the box's bottom.
  function S.model_fit(W)
    local D, b = S.MODEL, W.bounds
    local box = D.BOX
    local handle = menu(D.HANDLE, S.L.MODEL, 0, 0)
    if b == nil then
      -- a character built from body parts stands on its origin: only its height counts
      if type(handle) == "number" and handle ~= 0 then
        funcLuaCommand(D.SCALE_SET, handle, 1, 1, 1)   -- The height is read at scale 1, whatever an earlier fit left.
      end
      local height = type(handle) == "number" and handle ~= 0 and funcLuaCommand(D.MODEL_H, handle) or nil
      if type(height) ~= "number" or height <= 0 then
        log("model without a height", tostring(W.chara), tostring(height))
        return
      end
      b = { 0, 0, 0, 0, height, 0 }
    end
    local width, height = math.max(b[4] - b[1], 0.01), math.max(b[5] - b[2], 0.01)
    local scale = math.min((box[3] - box[1]) / width, (box[4] - box[2]) / height) / D.PX_PER_M
    if type(handle) == "number" and handle ~= 0 then
      funcLuaCommand(D.SCALE_SET, handle, scale, scale, scale)
    end
    local x = ((box[1] + box[3]) / 2 - 960) / D.PX_PER_M - scale * (b[1] + b[4]) / 2
    local y = D.EYE_Y - (box[4] - 540) / D.PX_PER_M - scale * b[2]
    menu(D.POS, S.L.MODEL, 0, x, y, 0, 0)
  end

  -- One Step of the model: the settle count, the build and the fit of a model just shown.
  function S.model_step()
    local W = S.model_want
    if W ~= nil and W.wait > 0 then
      W.wait = W.wait - 1
      if W.wait == 0 then
        if S.model == nil then
          menu(S.C.OPEN, S.L.MODEL, 0)
          S.model = VRFW.chara_model.new(S.L.MODEL, { log = log })
        end
        S.model.show_chara(W.chara, W.stand)
      end
    end
    if S.model == nil then
      return
    end
    S.model.step()
    if W ~= nil and W.wait == 0 and not W.fitted and S.model.pend == nil and S.model.pid == W.chara then
      W.fitted = true
      S.model_fit(W)
    end
  end

  S.wrap("OnSetupLayer", function(retail, layer, instance, ...)
    local r = table.pack(retail(layer, instance, ...))
    if layer == S.L.CARD then
      S.card_base = nil
      S.dress_card()
    elseif layer == S.L.TAB_ATTACH then
      -- the tab bar with its Z / C prompts and title: top centre (the attach layer places them, not the list's locator)
      local x, y = menu(S.C.GET_LOCAL_POS, layer, instance)
      menu(S.C.LOCAL_POS, layer, (tonumber(x) or 0) + S.G.TAB_DX, (tonumber(y) or 0) + S.G.TAB_DY, 0, instance)
    end
    return table.unpack(r, 1, r.n)
  end)

  -- every row the hidden list fills: its move, for the carousel
  S.wrap("UpdateListItem", function(retail, layer, instance, item, ...)
    local r = table.pack(retail(layer, instance, item, ...))
    local skill = funcLuaCommand(S.C.ITEM_TO_SKILL, item)
    S.inst_item[instance], S.inst_skill[instance] = item, (skill ~= nil and skill ~= 0) and skill or nil
    return table.unpack(r, 1, r.n)
  end)

  -- another tab, filter or sort: other rows
  S.wrap("OnChangeFocus", function(retail, layer, instance, ...)
    if layer == S.L.TAB then
      S.forget_rows()
      S.model_focus(0)
    end
    local r = table.pack(retail(layer, instance, ...))
    if layer == S.L.TAB and (tonumber(menu(S.C.LIST_COUNT, S.L.LIST)) or 0) <= 0 then
      S.clear()
    end
    return table.unpack(r, 1, r.n)
  end)

  -- Open sequence (install 728 log): the card's first fill comes before the card, the aura windows and their page guide
  -- receive OnOpenLayer, and a layer is shown when it opens, so the screen's look is set again once the list is open
  -- (first Step after its OnOpenLayer) and once every layer opened since has ended its opening (OnOpenEndLayer).
  S.opens, S.ends = 0, 0
  S.wrap("OnOpenLayer", function(retail, layer, ...)
    S.opens = S.opens + 1
    if layer == S.L.LIST then
      S.list_opened = true
    end
    return retail(layer, ...)
  end)

  S.wrap("OnOpenEndLayer", function(retail, layer, ...)
    local r = table.pack(retail(layer, ...))
    S.ends = S.ends + 1
    if S.ends == S.opens and S.list_seen then
      S.repaint("all layers opened")
    end
    return table.unpack(r, 1, r.n)
  end)

  -- The last fill run again (every mod's part of it, as on a focus change).
  function S.repaint(why)
    if S.fill == nil then
      S.diag(why .. ": no fill yet")
      return
    end
    S.diag(why .. " before: " .. S.diag_state())
    UpdateSkillDetailWindow(table.unpack(S.fill, 1, S.fill.n))
    S.diag(why .. " after: " .. S.diag_state())
  end

  -- Diagnostics of the open sequence: at most DIAG_MAX lines a screen VM, each one string (the log keeps 8 arguments).
  S.DIAG_MAX, S.step_n, S.diag_n = 24, 0, 0
  S.DIAG_AURA = { 1921826160, 2651268807, 395833588, 3679282495, 576015315, 3635526425, 1305553269, 3131422953 }
  function S.diag(text)
    if S.diag_n < S.DIAG_MAX then
      S.diag_n = S.diag_n + 1
      log("DIAG open", "step " .. S.step_n .. ", opens " .. S.opens .. ", ends " .. S.ends .. ": " .. text)
    end
  end

  -- "aura guide/keshin/armed/mix/soul/kizuna/awake/mode" as 1 (shown), 0 (hidden) or - (no layer), the rows shown, the card
  function S.diag_state()
    local out = {}
    for _, L in ipairs(S.DIAG_AURA) do
      local exists = menu(@crc:CMND_IS_EXIST_LAYER@, L)
      out[#out + 1] = exists and (menu(S.C.IS_VISIBLE, L, 0) == true and "1" or "0") or "-"
    end
    local rows = 0
    for k = 0, (tonumber(menu(@crc:CMND_GET_CREATE_LAYER_NUM@, S.L.ITEM)) or 0) - 1 do
      if menu(S.C.IS_VISIBLE, S.L.ITEM, k) == true then
        rows = rows + 1
      end
    end
    return "aura " .. table.concat(out) .. ", rows shown " .. rows .. ", card " .. tostring(menu(S.C.IS_VISIBLE, S.L.CARD, 0))
  end

  S.wrap("OnAfterReceiveFilterParam", function(retail, ...)
    S.forget_rows()
    return retail(...)
  end)

  S.wrap("CallBackSort", function(retail, ...)
    S.forget_rows()
    return retail(...)
  end)

  S.wrap("Step", function(retail, ...)
    local r = table.pack(retail(...))
    S.step_n = S.step_n + 1
    S.model_step()
    if S.list_opened then
      S.list_opened, S.list_seen = false, true
      S.repaint("list open")
    end
    local playing = BetterQoL ~= nil and type(BetterQoL.tech_preview) == "table" and BetterQoL.tech_preview.busy == true
    if S.focus ~= nil and not playing then
      S.click(S.focus, S.count or 0)
    end
    if S.art_waiting then
      S.kit.settle()
      S.flush_art()
    end
    return table.unpack(r, 1, r.n)
  end)

  S.wrap("UpdateSkillDetailWindow", function(retail, skill, ...)
    S.fill = table.pack(skill, ...)
    S.diag(string.format("fill %08X", VRFW.ids.unsigned(skill)))
    if skill ~= nil and skill ~= 0 then
      local G = S.G
      local top = S.effects_top(skill)
      SKILL_CARD_DOTS_XY = { G.DOTS_DEFAULT[1] + G.DOTS_X - G.DOTS_SCREEN[1], G.DOTS_DEFAULT[2] - (top - G.DOTS_SCREEN[2]) }
    end
    local r = table.pack(retail(skill, ...))
    local n = tonumber(menu(S.C.LIST_COUNT, S.L.LIST)) or 0
    if skill == nil or skill == 0 or n <= 0 then
      S.clear()
      return table.unpack(r, 1, r.n)
    end
    local focus = tonumber(menu(S.C.FOCUS_INDEX, S.L.ITEM)) or 0
    S.focus, S.count = focus, n
    S.dress_card()
    S.learn_rows(focus, skill)
    S.art_list = {}
    S.draw_carousel(focus, n)
    S.draw_thumbnail(skill)
    S.draw_effects(skill)
    S.flush_art()
    S.model_focus(skill)
    return table.unpack(r, 1, r.n)
  end)

  -- Leaving the screen frees the model.
  S.wrap("OnBack", function(retail, ...)
    S.model_want = nil
    if S.model ~= nil then
      S.model.release()
      S.model = nil
    end
    return retail(...)
  end)
end
-- EVT better_ui_skill_screen END
