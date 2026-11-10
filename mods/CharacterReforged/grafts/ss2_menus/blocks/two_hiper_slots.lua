-- Two Hiper slots
PL.HS_CMD = {SLOT_OF = @crc:CMND_CHARACTERREFORGED_SLOT_OF@, MIX_GET = @crc:CMND_CHARACTERREFORGED_MIX_GET@,
  MIX_SET = @crc:CMND_CHARACTERREFORGED_MIX_SET@}
PL.HS_TX = {ARMOUR = 713087699 --[[character_reforged_hs_armour_alone]], VIEW_MIX = 2210380019 --[[character_reforged_hs_view_mix]],
  MIX_FAIL = 1920236092 --[[character_reforged_hs_mix_fail]], ASK_MX = 1022201251 --[[character_reforged_hs_ask_mx]]}
PL.hs_view = "aura"
PL.hs_half = 0
PL.HS_ROW = {BASE1 = 970690259 --[[_item_list_base01]], BASE2 = 2583835390 --[[_title_list_base01]],
  POS2 = 3571920478 --[[_pos_list02]], FOCUS2 = 2420990283 --[[_item_list_focus02]],
  TEXT1 = 456522680 --[[_text_item01]], TEXT2 = 2185013762 --[[_text_item02]], ICON1 = 303536660 --[[_icon_item_dmy01]],
  ICON2 = 4025646555 --[[_icon_title01]], TRANSLATE = 2575768773 --[[node translation (layer, idx, node, axis, value)]],
  SCALE = 2885415772 --[[node scale (layer, idx, node, sx, sy)]],
  SLOT2 = 1453818910 --[[title_list_base01 (the mesh's sprite slot)]],
  STYLE = 516729530 --[[fs_32_w_lc_2d2_001_nr_sclw: white, outlined, squeezed to its box]],
  -- A quad's node scale is its size in layout units
  BASE1_SIZE = {568, 80}, BASE2_SIZE = {568, 76}, HALF_W = 282, SHIFT2 = 288,
  -- Icon nodes are left and top anchored, size is the node scale (54 units at plate left + 2, top at plate centre + 27); plates span -283..-1 and 5..287, 80 tall at y 36.
  AURA_ICON_X = -281, ICON1_X = 203, MIX_ICON_X = -281, BASE1_Y = 36, BASE2_Y = 38,
  ICON_SIZE = 54, ICON_Y = 23, ICON_RETAIL_SIZE = 64, ICON_RETAIL_Y = 28,
  -- The aura half's short name on this menu.
  TOTEM_SHORT = 3938180986 --[[crc32(character_reforged_hs_totem_short)]],
  PAD1 = "", PAD2 = "", CUT = 14,
  POS1 = 1307475940 --[[_pos_list01]], TEXT_SHIFT1 = 57, TEXT_SHIFT2 = 38,
  BASE_X = -283, FOCUS_X = -286,
  -- Portrait layout.
  FACE_SIZE = 54, FACE_Y = 27, AURA_FACE_X = -7, MIX_FACE_X = -26,
  TEXT1_SPLIT_W = 188, TEXT2_SPLIT_W = 188,
  RESET_FACE = 4176779611 --[[ResetFaceIcon (layer, idx, texture slot)]],
  ICON_SLOT1 = 1875672568 --[[icon_item_dmy01]], ICON_SLOT2 = 3047759730 --[[icon_title01 (the slot _icon_title01 draws)]],
  TEXT1_BOX = {410, 54}, TEXT2_BOX = {408, 54}, TEXT1_W = 205, TEXT2_W = 224,
  FOCUS1 = 155463921 --[[_item_list_focus01]], FOCUS_SIZE = {572, 88}, FOCUS_HALF_W = 286,
  FOCUS_SPRITE = 3319891473 --[[item_list_focus01: the plain frame]], FOCUS2_SLOT = 1558763435 --[[item_list_focus02]],
  CTRLS = {1332654303 --[[MENU_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]],
    3526778166 --[[MENU_CTRL_SEPARATE_CROSS_KEY]]},
  PAD = @crc:CMND_VRFW_INPUT_PAD@, VKEY = @crc:CMND_VRFW_INPUT_KEY@,
  PAD_LEFT = 0x80, PAD_RIGHT = 0x20, VK_LEFT = 0x25, VK_RIGHT = 0x27,
  CTRL_FOCUS = @crc:CMND_IS_CTRL_FOCUS_ACTIVE@ --[[CMND_IS_CTRL_FOCUS_ACTIVE (layer)]],
  -- The row's touch quad _touch_list01 covers both plates (570 x 80 at (-283, 36)).
  TOUCH = 688754292 --[[_touch_list01]], TOUCH_RETAIL = {544, 54, -272, 27}, TOUCH_SPLIT = {570, 80, -283, 36},
  PTR_POS = 558229292 --[[pointer (screen px, y down)]], PTR_GPOS = 4002164178 --[[instance global position, y up]],
  PTR_MOVED = 3272825600 --[[mouse moved]], PTR_CLICK = {749879980 --[[CMD_VRFW_MOUSE_LEFT]],
    1651523701 --[[CMD_ENTER_CLICK]]},
  HIT_X = {{-283, -1}, {5, 287}}, HIT_Y = {-44, 36},
  PLATE_TEX = "#/menu/00_soccer/soccer11/character_reforged_soccer11_08_hs/cr_hs_plates.g4tx",
  PLATE_TEX_CRC = 589490458 --[[crc32(PLATE_TEX)]], PLATE_AURA = 2466971650 --[[cr_hs_plate_aura]],
  PLATE_MIX = 36545261 --[[cr_hs_plate_mix]],
  K_LEFT = 2765147006 --[[CMD_LEFT]], K_RIGHT = 2075023265 --[[CMD_RIGHT]]}

-- Makes one row again (a level-locked Hiper row, never split).
function PL.hs_unsplit_row()
  local R, L = PL.HS_ROW, L_ROW
  funcLuaMenuCommand(R.SCALE, L, 0, R.BASE1, R.BASE1_SIZE[1], R.BASE1_SIZE[2])
  funcLuaMenuCommand(R.SCALE, L, 0, R.FOCUS1, R.FOCUS_SIZE[1], R.FOCUS_SIZE[2])
  funcLuaMenuCommand(C.MESH_VISIBLE, L, R.FOCUS1, true, 0)
  funcLuaMenuCommand(R.SCALE, L, 0, R.TEXT1, R.TEXT1_BOX[1], R.TEXT1_BOX[2])
  funcLuaMenuCommand(C.TEXT_ALPHA, L, 0, R.TEXT1, 1)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.POS2, 0, 0)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.BASE2, 1, R.BASE2_Y)
  funcLuaMenuCommand(R.SCALE, L, 0, R.BASE2, R.BASE2_SIZE[1], R.BASE2_SIZE[2])
  funcLuaMenuCommand(R.SCALE, L, 0, R.FOCUS2, R.FOCUS_SIZE[1], R.FOCUS_SIZE[2])
  funcLuaMenuCommand(R.SCALE, L, 0, R.TEXT2, R.TEXT2_BOX[1], R.TEXT2_BOX[2])
  funcLuaMenuCommand(POSITION_VISIBLE, L, R.POS2, false, 0)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.ICON1, 0, R.ICON1_X)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.ICON1, 1, R.ICON_RETAIL_Y)
  funcLuaMenuCommand(R.SCALE, L, 0, R.ICON1, R.ICON_RETAIL_SIZE, R.ICON_RETAIL_SIZE)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.POS1, 0, 0)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.BASE1, 0, R.BASE_X)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.FOCUS1, 0, R.FOCUS_X)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.BASE2, 0, R.BASE_X)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.FOCUS2, 0, R.FOCUS_X)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.ICON2, 0, R.ICON1_X)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.ICON2, 1, R.ICON_RETAIL_Y)
  funcLuaMenuCommand(R.SCALE, L, 0, R.ICON2, R.ICON_RETAIL_SIZE, R.ICON_RETAIL_SIZE)
  if PL.hs_faces then
    -- The portraits leave the icon slots.
    PL.hs_faces = false
    PL.hs_face_key = {}
    funcLuaMenuCommand(R.RESET_FACE, L, 0, R.ICON_SLOT1)
    funcLuaMenuCommand(R.RESET_FACE, L, 0, R.ICON_SLOT2)
    local skill = PL.row_move(0)
    if skill ~= 0 then
      funcLuaMenuCommand(C.ITEM_ICON, L, 0, R.ICON1, R.ICON_SLOT1, skill)
    end
  end
  PL.hs_touch(R.TOUCH_RETAIL)
  local info = GetEquipListItemInfo(GetEquipType(0))
  if info ~= nil and info.fontStyle ~= nil then
    funcLuaMenuCommand(2333948100 --[[text style]], L, 0, R.TEXT1, info.fontStyle)
  end
end

function PL.hs_first_upper(t)
  local b1, b2 = string.byte(t, 1, 2)
  if b1 ~= nil and b1 >= 97 and b1 <= 122 then
    return string.char(b1 - 32) .. string.sub(t, 2)
  end
  if b1 == 195 and b2 ~= nil and b2 >= 160 and b2 <= 190 and b2 ~= 183 then
    return string.char(195, b2 - 32) .. string.sub(t, 3)
  end
  return t
end

function PL.hs_short_name(name)
  if type(name) ~= "string" or name == "" then
    return name
  end
  local fmts = PL.txt(PL.HS_ROW.TOTEM_SHORT)
  for fmt in string.gmatch(fmts, "[^|]+") do
    local i, j = string.find(fmt, "<VALUE>", 1, true)
    if i ~= nil then
      local pre, post = string.sub(fmt, 1, i - 1), string.sub(fmt, j + 1)
      local n_name = #name
      if n_name > #pre + #post and string.sub(name, 1, #pre) == pre
          and (#post == 0 or string.sub(name, n_name - #post + 1) == post) then
        return PL.hs_first_upper(string.sub(name, #pre + 1, n_name - #post))
      end
    end
  end
  return name
end

-- Splits the Hiper row (instance 0).
function PL.hs_split_row()
  local R, L = PL.HS_ROW, L_ROW
  local aura, mix = PL.shown_skill_set_slots()
  local mix_partner = mix ~= 0 and PL.hs_mix_partner(mix) or nil
  local function label(id, half)
    if id == 0 then
      return ""                                    -- an empty slot: the plate alone
    end
    local t = half == 1 and PL.hs_mix_name(id, mix_partner) or PL.hs_short_name(Name(id))
    -- The limit counts display units, so a name in wide characters is not cut after a third of its bytes.
    return (half == 1 and R.PAD2 or R.PAD1) .. VRFW.text_fold.cut(t, R.CUT)
  end
  local tinted = PL.hs_plates_ready()
  PL.hs_plates_wait = not tinted
  -- Moves the left set (the aura slot).
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.POS1, 0, -R.TEXT_SHIFT1)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.BASE1, 0, R.BASE_X + R.TEXT_SHIFT1)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.FOCUS1, 0, R.FOCUS_X + R.TEXT_SHIFT1)
  -- Handles the left plate.
  if tinted then
    funcLuaMenuCommand(C.SPRITE, L, R.PLATE_TEX_CRC, R.PLATE_AURA, ROW_BASE, 0, 0)
  else
    funcLuaMenuCommand(C.SPRITE, L, ROW_TEXTURE, ROW_BASE, ROW_BASE, 0, 0)
  end
  funcLuaMenuCommand(R.SCALE, L, 0, R.BASE1, R.HALF_W, R.BASE1_SIZE[2])
  funcLuaMenuCommand(R.SCALE, L, 0, R.FOCUS1, R.FOCUS_HALF_W, R.FOCUS_SIZE[2])
  funcLuaMenuCommand(C.MESH_VISIBLE, L, R.FOCUS1, PL.hs_half == 0, 0)
  funcLuaMenuCommand(2333948100 --[[text style]], L, 0, R.TEXT1, R.STYLE)
  funcLuaMenuCommand(R.SCALE, L, 0, R.TEXT1, R.TEXT1_SPLIT_W, R.TEXT1_BOX[2])
  funcLuaMenuCommand(C.TEXT, L, R.TEXT1, label(aura, 0), 0)
  funcLuaMenuCommand(C.TEXT_ALPHA, L, 0, R.TEXT1, 1)
  PL.hs_face(R.ICON1, R.ICON_SLOT1, R.AURA_FACE_X, aura ~= 0 and function(L1, m, s)
    return PL.aura_portrait(L1, 0, m, s, aura)
  end or nil, string.format("%s:%08X", tostring(n), to_u32(aura)))
  -- Sets the right half of the row, as tall as the left one and on its line (the spare title set, its base is the same plate in orange: the mix slot, Mix-Max or "Mode change").
  funcLuaMenuCommand(POSITION_VISIBLE, L, R.POS2, true, 0)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.POS2, 0, R.SHIFT2 - R.TEXT_SHIFT2)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.BASE2, 0, R.BASE_X + R.TEXT_SHIFT2)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.FOCUS2, 0, R.FOCUS_X + R.TEXT_SHIFT2)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, R.BASE2, true, 0)
  if tinted then
    funcLuaMenuCommand(C.SPRITE, L, R.PLATE_TEX_CRC, R.PLATE_MIX, R.SLOT2, 0, 0)
  else
    funcLuaMenuCommand(C.SPRITE, L, ROW_TEXTURE, ROW_BASE, R.SLOT2, 0, 0)
  end
  funcLuaMenuCommand(R.SCALE, L, 0, R.BASE2, R.HALF_W, R.BASE1_SIZE[2])
  funcLuaMenuCommand(R.TRANSLATE, L, 0, R.BASE2, 1, R.BASE1_Y)
  PL.hs_touch(R.TOUCH_SPLIT)
  funcLuaMenuCommand(C.SPRITE, L, ROW_TEXTURE, R.FOCUS_SPRITE, R.FOCUS2_SLOT, 0, 0)
  funcLuaMenuCommand(R.SCALE, L, 0, R.FOCUS2, R.FOCUS_HALF_W, R.FOCUS_SIZE[2])
  funcLuaMenuCommand(C.MESH_VISIBLE, L, R.FOCUS2, PL.hs_half == 1, 0)
  funcLuaMenuCommand(2333948100 --[[text style]], L, 0, R.TEXT2, R.STYLE)
  funcLuaMenuCommand(R.SCALE, L, 0, R.TEXT2, R.TEXT2_SPLIT_W, R.TEXT2_BOX[2])
  funcLuaMenuCommand(C.TEXT, L, R.TEXT2, label(mix, 1), 0)
  funcLuaMenuCommand(C.TEXT_ALPHA, L, 0, R.TEXT2, 1)
  PL.hs_face(R.ICON2, R.ICON_SLOT2, R.MIX_FACE_X, mix ~= 0 and function(L1, m, s)
    if mix_partner == nil then
      return false
    end
    if mix_partner.skill ~= nil then
      return PL.aura_portrait(L1, 0, m, s, mix_partner.skill)
    end
    return PL.list_face(L1, 0, m, s, mix_partner.face)
  end or nil, string.format("%s:%08X:%s:%s", tostring(n), to_u32(mix), mix_partner and tostring(mix_partner.skill) or "-",
    mix_partner and tostring(mix_partner.face) or "-"))
end

-- Draws a plate's portrait on icon quad `mesh` (texture slot `slot`).
PL.hs_faces = false
PL.hs_face_key = {}                            -- texture slot -> key of the portrait drawn on it
function PL.hs_face(mesh, slot, x, draw, key)
  local R, L = PL.HS_ROW, L_ROW
  funcLuaMenuCommand(R.TRANSLATE, L, 0, mesh, 0, x)
  funcLuaMenuCommand(R.TRANSLATE, L, 0, mesh, 1, R.FACE_Y)
  funcLuaMenuCommand(R.SCALE, L, 0, mesh, R.FACE_SIZE, R.FACE_SIZE)
  if draw ~= nil and key ~= nil and PL.hs_faces and PL.hs_face_key[slot] == key then
    funcLuaMenuCommand(C.MESH_VISIBLE, L, mesh, true, 0)   -- the row refresh hid the icon mesh: the same portrait again
    return
  end
  PL.hs_face_key[slot] = nil
  funcLuaMenuCommand(R.RESET_FACE, L, 0, slot)
  if draw == nil then
    funcLuaMenuCommand(C.MESH_VISIBLE, L, mesh, false, 0)
    return
  end
  PL.hs_faces = true
  local okd, drawn = pcall(draw, L, mesh, slot)
  if not (okd and drawn == true) then
    funcLuaMenuCommand(R.RESET_FACE, L, 0, slot)
    okd, drawn = pcall(PL.owner_face, L, 0, mesh, slot)
  end
  local shown = okd and drawn == true
  funcLuaMenuCommand(C.MESH_VISIBLE, L, mesh, shown, 0)
  if shown then
    PL.hs_face_key[slot] = key
  end
end

-- Draws a character's list face icon (VRFW.face_icon, as the bank and dock lists draw it) on (mesh, slot).
function PL.list_face(L, idx, mesh, slot, key)
  if type(key) ~= "number" or key == 0 then
    return false
  end
  return VRFW.face_icon.request(L, idx, key, mesh, slot)
end

-- Draws the shown player's own face icon on (mesh, slot).
function PL.owner_face(L, idx, mesh, slot)
  local key = funcLuaCommand(C.CHARA_GET, n, 1) or 0
  if key == 0 then
    return false
  end
  local param = funcLuaCommand(C.CHARA_GET, n, 4) or 0
  local okk, keeper = pcall(MENU_DEF.IsKeeper, param)
  return VRFW.face_icon.request(L, idx, {handle = n, kind = 255, chara = key}, mesh, slot,
    {kit = 0, keeper = okk and keeper == true})
end

-- Draws an aura skill's portrait on (mesh, slot) by the retail aura windows' rule.
function PL.aura_portrait(L, idx, mesh, slot, skill)
  local ok, cid = funcLuaCommand(C.SKILL_INFO, skill, 17)
  if not ok or type(cid) ~= "number" or cid == 0 then
    return false
  end
  local _, t = funcLuaCommand(C.SKILL_INFO, skill, 13)
  local art = PL.AURA_FACE_TYPE[t]
  if art == 12 and funcLuaMenuCommand(2208175668 --[[has Mix-Max face art]], cid) ~= true then
    art = nil
  end
  if art == nil then
    return PL.list_face(L, idx, mesh, slot, cid)
  end
  local okr, r = pcall(funcLuaMenuCommand, 346643487 --[[SwapLayerFaceIconTex]], L, idx, mesh, slot, cid, 0, art, true,
    true, true, 5)
  return okr and r ~= false
end

function PL.hs_mix_partner(mix)
  if mix == PL.MX_FUSION then
    local okf, f = pcall(PL.mx_get)
    if okf and f ~= nil and ((f.face or 0) ~= 0 or (f.chara or 0) ~= 0) then
      local face = (f.face ~= nil and f.face ~= 0) and f.face or f.chara
      return {face = face, name = (f.chara or 0) ~= 0 and PL.mx_chara_name(f.chara) or nil}
    end
  end
  if type(CharacterReforged.hyper_card) == "table" and type(CharacterReforged.hyper_card.mc_get) == "function" then
    local okm, m = pcall(CharacterReforged.hyper_card.mc_get, n, mix)
    if okm and m ~= nil and (m.face or 0) ~= 0 then
      return {face = m.face, name = m.name}
    end
  end
  local ok, cid = funcLuaCommand(C.SKILL_INFO, mix, 17)
  if ok and type(cid) == "number" and cid ~= 0 then
    return {face = cid, name = PL.mx_chara_name(cid), skill = mix}
  end
  return nil
end

-- The pre-tinted plates (atlas cr_hs_plates).
PL.hs_plates = 0
function PL.hs_plates_ready()
  local R = PL.HS_ROW
  if PL.hs_plates == 0 then
    funcLuaMenuCommand(C.LOAD_TEX, R.PLATE_TEX)
    PL.hs_plates = 1
  end
  if PL.hs_plates == 1 and not funcLuaCommand(C.TEX_LOADING, R.PLATE_TEX_CRC) then
    PL.hs_plates = 2
  end
  return PL.hs_plates == 2
end

PL.TAB_GROUP = {[1] = "moves", [2] = "aura", [3] = "mix"}   -- picker kind -> group name (0 / other: the whole list)
PL.VRFW_SKILL_TABS = @crc:CMND_VRFW_SKILL_TABS@
PL.VRFW_SKILL_TAB_WINDOW = @crc:CMND_VRFW_SKILL_TAB_WINDOW@            -- crc32("CMND_VRFW_SKILL_TAB_WINDOW") (group) -> start, count
function PL.tab_window(kind)
  local okt, tabs = pcall(funcLuaCommand, PL.VRFW_SKILL_TABS)
  if okt and type(tabs) == "number" and tabs > 0 then
    local okw, start, count = pcall(funcLuaCommand, PL.VRFW_SKILL_TAB_WINDOW, PL.TAB_GROUP[kind] or "")
    pcall(Call, C.LOG, "skill_slots", "picker tab window", PL.TAB_GROUP[kind] or "all",
      okw and tostring(start) or "?", okw and tostring(count) or tostring(start))
  end
end

PL.hs_prev_pick = CharacterReforgedSkillTablePickCoroutine
function CharacterReforgedSkillTablePickCoroutine(row)
  if row == 0 then
    pcall(PL.hs_pointer_pick)                        -- a click on a plate acts on that plate's half
  end
  local kind = 1
  if row == 0 then
    kind = 0
    if not CharacterReforged.skill_table_is_locked(0) then
      kind = PL.hs_half == 1 and 3 or 2
    end
  end
  PL.tab_window(kind)
  pcall(Call, C.LOG, "skill_slots", "picker tabs", row, kind)
  local ok, err = pcall(PL.hs_prev_pick, row)
  PL.tab_window(0)
  if not ok then
    error(err, 0)
  end
end

-- Sets the selected half (Left or Right on the Hiper row, R3).
function PL.hs_set_half(half)
  if half == PL.hs_half then
    return
  end
  PL.hs_half = half
  PL.hs_view = half == 1 and "mix" or "aura"
  funcLuaCommand(C.SE, 2500047763 --[[sy0005 cursor]])
  pcall(PL.hs_split_row)
  local ok, err = pcall(UpdateEquipItemInfo)
  pcall(Call, C.LOG, "skill_slots", "hiper half", half == 1 and "mix" or "aura", ok and "" or tostring(err))
end

-- Returns the slot of a Hiper move.
function PL.hs_kind(id)
  return CharacterReforged.player_sets.hs_kind(id)
end

-- the shown player's mix-slot move (0 = empty)
function PL.hs_mix()
  return CharacterReforged.player_sets.hs_mix(n)
end

function PL.hs_mix_put(id)
  return CharacterReforged.player_sets.hs_mix_put(n, id, PL.set_ctx())
end

function PL.hs_mix_name(mix, partner)
  if mix == nil or mix == 0 then
    return ""
  end
  if partner == nil then
    partner = PL.hs_mix_partner(mix)
  end
  if partner ~= nil and type(partner.name) == "string" and partner.name ~= "" then
    return partner.name
  end
  return Name(mix)
end

-- The base equip of the Hiper row (under the miximax and mode change wrappers, which call PL.mx_prev_equip).
PL.hs_base_equip = PL.mx_prev_equip
function PL.mx_prev_equip(row, skill, inv_hint, cur)
  if row == 0 then
    local kind = PL.hs_kind(skill)
    if kind == 1 then
      if not PL.hs_mix_put(skill) then
        funcLuaCommand(C.SE, SE_NG)
        VRFW.question.notice(PL.txt(PL.HS_TX.MIX_FAIL))
      end
      return
    elseif kind == 2 then
      funcLuaCommand(C.SE, SE_NG)
      VRFW.question.notice(PL.txt(PL.HS_TX.ARMOUR))
      pcall(Call, C.LOG, "skill_slots", "hiper armour alone refused", string.format("%08X", to_u32(skill)))
      return
    end
  end
  return PL.hs_base_equip(row, skill, inv_hint, cur)
end

-- Eliminar on the fusion entry
PL.hs_prev_equip = CharacterReforged.skill_table_equip
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  if row == 0 then
    if skill == PL.MX_FUSION and VRFW.param.has(PL.MX_KEY_DEL) then
      VRFW.param.clear(PL.MX_KEY_DEL)
      PL.mx_clear()
      if PL.hs_mix() == PL.MX_FUSION then
        PL.hs_mix_put(0)
      end
      return
    end
  end
  return PL.hs_prev_equip(row, skill, inv_hint, cur)
end

-- Removes the mix slot.
function PL.hs_remove_mix(mix)
  if mix == PL.MX_FUSION then
    local f = PL.mx_get()
    if f ~= nil then
      funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
      if not VRFW.question.ask(PL.txt(PL.HS_TX.ASK_MX, PL.mx_chara_name(f.chara))) then
        funcLuaCommand(C.SE, SE_BACK)
        return
      end
      PL.mx_clear()
    end
    PL.hs_mix_put(0)
    funcLuaCommand(C.SE, SE_REMOVE)
  else
    PL.hs_mix_put(0)
    funcLuaCommand(C.SE, SE_REMOVE)
  end
  PL.hs_view = "aura"
end

PL.hs_prev_restore = CharacterReforged.skill_table_restore_coroutine
function CharacterReforged.skill_table_restore_coroutine(row)
  if row ~= 0 or PL.mx_removing then
    return PL.hs_prev_restore(row)
  end
  local mix = PL.hs_mix()
  if mix == 0 then
    return PL.hs_prev_restore(0)
  end
  local aura = Skill(0)
  if aura ~= 0 and PL.hs_half == 0 then
    return PL.hs_prev_restore(0)                     -- the aura half selected: its slot
  end
  PL.hs_remove_mix(mix)
  RefreshRows()
  UpdateEquipItemInfo()
  CharacterReforged.skill_table_focus_row(0)
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end

PL.hs_prev_reset_kit = PL.reset_kit
function PL.reset_kit(row)
  local m = PL.hs_prev_reset_kit(row)
  if row == 0 and m ~= 0 then
    local kind = PL.hs_kind(m)
    if kind ~= nil and kind ~= 0 then
      return 0
    end
  end
  return m
end

PL.hs_prev_row = UpdateEquipListItem
function UpdateEquipListItem(a1)
  PL.hs_prev_row(a1)
  if a1 ~= 0 then
    return
  end
  if CharacterReforged.skill_table_is_locked(0) then                          -- a level-locked Hiper row: one row
    pcall(PL.hs_unsplit_row)
    return
  end
  local ok, err = pcall(PL.hs_split_row)
  if not ok then
    pcall(Call, C.LOG, "skill_slots", "hiper split row error", tostring(err))
  end
end

-- Shows the panel of the Hiper row.
function PL.hs_show_mix(mix)
  local _, team_info = GetSoccerTeamInfo(0)
  local ok, shown = false, false
  if mix == PL.MX_FUSION then
    local okf, f = pcall(PL.mx_get)
    if okf and f ~= nil then
      ok, shown = pcall(PL.mx_detail, f, team_info)
    end
  else
    ok, shown = pcall(PL.hiper_show, mix, team_info)
  end
  if ok and shown then
    SetVisibleEquipInfoWindow(false)
  end
  pcall(Call, C.LOG, "skill_slots", "hiper panel: mix slot", string.format("%08X", to_u32(mix)), tostring(ok),
    tostring(shown))
end

PL.hs_prev_item_info = UpdateEquipItemInfo
function UpdateEquipItemInfo()
  local row = (n14 ~= L_BTN) and funcLuaMenuCommand(C.FOCUS_IDX, L_ROW) or -1
  local mix = row == 0 and PL.hs_mix() or 0
  local aura = mix ~= 0 and PL.row_move(0) or 0
  PL.hs_both = mix ~= 0 and aura ~= 0
  PL.hs_view = PL.hs_half == 1 and "mix" or "aura"
  if mix == 0 then
    PL.hs_view = "aura"
  end
  PL.hs_prev_item_info()
  if mix == 0 then
    return
  end
  if aura ~= 0 and PL.hs_view ~= "mix" then
    return                                       -- the aura slot's panel, as drawn
  end
  PL.hs_show_mix(mix)
  if PL.guide_redo ~= nil then
    pcall(PL.guide_redo)                         -- a mix-only row is removable (Y)
  end
end

PL.hs_prev_function = OnFunction
function OnFunction(a1, a2)
  if vrfw_co == nil and a1 == 4109882573 and n14 ~= L_BTN
      and funcLuaMenuCommand(C.FOCUS_IDX, L_ROW) == 0 and (Skill(0) == 0 or PL.hs_half == 1) and PL.hs_mix() ~= 0
      and not CharacterReforged.skill_table_is_prime() and not PL.idol_fixed(0) then
    vrfw_co = coroutine.create(function()
      CharacterReforged.skill_table_reset_coroutine(0)
    end)
    return
  end
  return PL.hs_prev_function(a1, a2)
end

-- Left / Right on the Hiper row select the half (press edge, every menu controller, then the pad / arrow keys)
function PL.hs_lr()
  local R = PL.HS_ROW
  local left, right = false, false
  for _, c in ipairs(R.CTRLS) do
    left = left or funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, c, R.K_LEFT) == true
    right = right or funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, c, R.K_RIGHT) == true
  end
  if not left and not right and funcLuaMenuCommand(R.CTRL_FOCUS, L_ROW) == true then
    local ok, held = pcall(funcLuaCommand, R.PAD)
    if ok and type(held) == "number" and held > 0 then
      left = math.floor(held / R.PAD_LEFT) % 2 == 1
      right = math.floor(held / R.PAD_RIGHT) % 2 == 1
    end
    local okl, kl = pcall(funcLuaCommand, R.VKEY, R.VK_LEFT)
    local okr, kr = pcall(funcLuaCommand, R.VKEY, R.VK_RIGHT)
    left = left or (okl and kl == true)
    right = right or (okr and kr == true)
  end
  if left == right then
    return 0
  end
  return left and -1 or 1
end

-- Returns the row's native touch quad (instance 0).
function PL.hs_touch(b)
  local R = PL.HS_ROW
  funcLuaMenuCommand(R.SCALE, L_ROW, 0, R.TOUCH, b[1], b[2])
  funcLuaMenuCommand(R.TRANSLATE, L_ROW, 0, R.TOUCH, 0, b[3])
  funcLuaMenuCommand(R.TRANSLATE, L_ROW, 0, R.TOUCH, 1, b[4])
end

-- the half under the pointer (0 aura, 1 mix), nil = not over a plate of the Hiper row
function PL.hs_pointer_half()
  local R = PL.HS_ROW
  local x, y = funcLuaMenuCommand(R.PTR_POS)
  local gx, gy = funcLuaMenuCommand(R.PTR_GPOS, L_ROW, 0)
  if type(x) ~= "number" or type(y) ~= "number" or type(gx) ~= "number" or type(gy) ~= "number" then
    return nil
  end
  local lx, ly = x - gx, -y - gy
  if ly < R.HIT_Y[1] or ly > R.HIT_Y[2] then
    return nil
  end
  for h = 0, 1 do
    if lx >= R.HIT_X[h + 1][1] and lx <= R.HIT_X[h + 1][2] then
      return h
    end
  end
  return nil
end

-- Polls the hover.
function PL.hs_poll_pointer()
  local R = PL.HS_ROW
  local x, y = funcLuaMenuCommand(R.PTR_POS)
  if type(x) ~= "number" or type(y) ~= "number" then
    return
  end
  local moved = funcLuaMenuCommand(R.PTR_MOVED) == true
  if PL.hs_ptr ~= nil and (math.abs(x - PL.hs_ptr[1]) > 1 or math.abs(y - PL.hs_ptr[2]) > 1) then
    moved = true
  end
  PL.hs_ptr = {x, y}
  if not moved or CharacterReforged.skill_table_is_locked(0) then
    return
  end
  local h = PL.hs_pointer_half()
  if h ~= nil then
    PL.hs_set_half(h)
  end
end

-- Handles a click (mouse button or Accept on the pointer) that opens the Hiper picker.
function PL.hs_pointer_pick()
  local R = PL.HS_ROW
  local clicked = false
  for _, k in ipairs(R.PTR_CLICK) do
    clicked = clicked or funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 1332654303 --[[MENU_CTRL]], k) == true
  end
  if not clicked or CharacterReforged.skill_table_is_locked(0) then
    return
  end
  local h = PL.hs_pointer_half()
  if h ~= nil and h ~= PL.hs_half then
    PL.hs_half = h
    PL.hs_view = h == 1 and "mix" or "aura"
    pcall(PL.hs_split_row)
  end
end

-- the selected half follows Left / Right (R3 does nothing here)
function PL.hs_poll_r3()
  PL.hs_r3_wait = math.max(0, (PL.hs_r3_wait or 0) - 1)
  if vrfw_co ~= nil then
    PL.hs_lr_prev = 2                              -- a key still held when a coroutine ends is not a new press
    return
  end
  if n14 == L_BTN or funcLuaMenuCommand(C.FOCUS_IDX, L_ROW) ~= 0 then
    PL.hs_lr_prev = 2
    if PL.hs_half ~= 0 then                        -- off the row: the aura half again, quietly
      PL.hs_half = 0
      PL.hs_view = "aura"
      if not CharacterReforged.skill_table_is_locked(0) then
        pcall(PL.hs_split_row)
      end
    end
    return
  end
  pcall(PL.hs_poll_pointer)
  local dir = PL.hs_lr()
  local prev = PL.hs_lr_prev
  PL.hs_lr_prev = dir
  if dir ~= 0 and dir ~= prev then
    if prev ~= 2 then
      PL.hs_set_half(dir > 0 and 1 or 0)
    end
    return
  end
end

PL.hs_prev_step = Step
function Step(...)
  local r = PL.hs_prev_step ~= nil and PL.hs_prev_step(...) or nil
  pcall(PL.hs_poll_r3)
  if PL.hs_plates_wait and PL.hs_plates_ready() then   -- the tinted plates came in: redraw the split row
    PL.hs_plates_wait = false
    if not CharacterReforged.skill_table_is_locked(0) then
      pcall(PL.hs_split_row)
    end
  end
  return r
end
-- ===== Two Hiper slots END =====
