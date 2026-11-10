
-- EVT ------------------------------------------------------------------------------------------ The match
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
local HyperButtonLayer = 444446249 --[[soccer08_10_cmd_act_hiper_slot]]
-- The attach row of each plate instance on the ring (content\menus\hyper_plates.toml).
local PLATE_ATTACH = {@crc:cr_transform_plate01@, @crc:cr_transform_plate02@, @crc:cr_transform_plate03@, @crc:cr_transform_plate04@}
-- Each entry of the transformation cross (in the order the mod declares its direct entries) has a plate instance.
local ENTRY_COUNT = 4
local ENTRY_LAST = ENTRY_COUNT - 1
local COMMAND_ENTRIES = @crc:CMND_VRFW_XSLOT_ENTRIES@  -- The direct entries of the plates slot running the match.
local SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@ --[[CMND_GET_SOCCER_SKILL_INFO: 4 name id, 7 element, 13 aura type]]
local HyperCubes = {931753331, 2927639753, 3649506399, 1206098428, 820291946} --[[_cmd_tp_cube01..05]]
local hyperButtonLast = {}
local hyperButtonPos = -1
local character_reforged_ho_set = {}       -- LOCAL_POS applied to each plate instance ("dx,dy")
local character_reforged_ho_slide = {}
local character_reforged_ho_want = false   -- last corner placement (the list-open transition starts the slide)
-- Per-instance state.
local character_reforged_cd = {swapped = false, shown = nil, geo = nil, total = 0, logs = 0, inst = 1}
local character_reforged_fold = {
  full_width = 436, input_x = -184, name_left = -163, logo_left = -103,
  quad_right = 185, band_margin = 19, visible_right = 172, icon_x = -246, icon_size = 43,
  quads = {
    {4282364172 --[[_cmd_base_sp01]], -251, 436, 68},
    {1851880983 --[[_cmd_base_sp_add01]], -251, 436, 68},
    {4150798253 --[[_cmd_base_sp_add02]], -251, 436, 68},
    {3742978053 --[[_cmd_base_sp_grayout01]], -251, 436, 68},
    {1213120893 --[[_sp_ring02]], -279, 480, 112},
    {3077712952 --[[_cmd_base_sp_effect01]], -232, 464, 64},
    {738647743 --[[_cmd_base_sp_blank01]], -244, 488, 80},
  },
  progress = 0, input_shift = 0, width = nil, band = {}, shift = {}, icon = {}, logo = {},
}

-- The transformation cross at the bottom left of the match HUD: a ring like the super-tactics widget beside it, with the
-- modifier's glyph in the centre and the type icon of each entry at its arrow's place, and one plate per existing entry
-- while the modifier is held.
-- Its places are the mod's config.toml [transform_cross], read through CMND_CHARACTERREFORGED_TRANSFORM_CROSS (nil until then).
CharacterReforged.TRANSFORM_CROSS = nil
local CROSS_DIRECTION_NAME = {[1] = "up", [2] = "left", [3] = "right", [4] = "down"}
local character_reforged_cross = {held = false, reasons = nil, labels = nil, logged = {}, ring = {}, fit = {}, rows = {}, row_count = 0, config_failed = false, rects_logged = false, measure_logged = false}
-- The ring, a copy of the retail super-tactics widget (content\menus\hyper_plates.toml).
local RingLayer = @crc:cr_transform_ring@
local RING_NATIVE_SIZE = 144
-- The ring's centre in its layout: the layer's origin is the bottom right corner of the 1920 x 1080 screen (x right, y up).
local RING_LAYOUT_X, RING_LAYOUT_Y = -130, 429
local SCREEN_WIDTH, SCREEN_HEIGHT = 1920, 1080
local RING_BAND = 1881008211 --[[_tactics_guide_base01]]
local RING_GLYPH = 950238781 --[[_text_btn01]]
local RING_PULSE_GROUP = 801776940 --[[_pos_sp_tactics01: the retail special tactic's pulsing base, never shown]]
local RING_ICON_ATLAS = 502529699 --[[#/menu/200_icon/15_icon_common/<LG>/icon_common.g4tx]]
-- The icon of each arrow by direction code: its mesh, its texture slot and its colour row.
local RING_ICONS = {
  [1] = {1457127177 --[[_icon_tactics_g_dmy01]], 3944247612 --[[icon_tactics_g_dmy01]], 249618010 --[[tactics_dmy01]]},
  [2] = {3486559923 --[[_icon_tactics_g_dmy02]], 1913725062 --[[icon_tactics_g_dmy02]], 2548666336 --[[tactics_dmy02]]},
  [3] = {2487205043 --[[_icon_sp_tactics_dmy01]], 3258038558 --[[icon_sp_tactics_dmy01]], @crc:tactics_dmy04@},
  [4] = {3101138469 --[[_icon_tactics_g_dmy03]], 85331984 --[[icon_tactics_g_dmy03]], 3773742966 --[[tactics_dmy03]]},
}
-- The three text layers of a plate (_tools\transform_cross_build.py): layer, attach row on the plate, the text node it shows.
local CAPTION_LEFT_TEXT, CAPTION_PILL_TEXT = 950238781 --[[_text_btn01]], 2712285063 --[[_text_btn02]]
local CAPTION_PILL_BAND = 2605774483 --[[_pw_guide01]]
local CAPTION_TEXTS = {CAPTION_LEFT_TEXT, CAPTION_PILL_TEXT}
local TypeLayer, PillLayer, NameLayer = @crc:cr_transform_type@, @crc:cr_transform_pill@, @crc:cr_transform_name@
local CAPTION_LAYERS = {
  {layer = TypeLayer, attach = @crc:cr_transform_type01@, text = CAPTION_LEFT_TEXT},
  {layer = PillLayer, attach = @crc:cr_transform_pill01@, text = CAPTION_PILL_TEXT},
  {layer = NameLayer, attach = @crc:cr_transform_name01@, text = CAPTION_LEFT_TEXT},
}
local COMMAND_TEXT_SIZE = 3549540977 --[[CMND_GET_MENU_TEXT_RECT_SIZE(layer, instance, text node) -> width, height of the node's text]]
-- The type label over the name: the menu_text row by the entry's page (0 aura, 1 armour, 2 mix, 3 group, 4 inherited).
local CROSS_TYPE_ROWS = {[0] = @crc:character_reforged_cross_type_spirit@, [1] = @crc:character_reforged_cross_type_armour@,
  [2] = @crc:character_reforged_cross_type_mix@, [3] = @crc:character_reforged_cross_type_group@, [4] = @crc:character_reforged_cross_type_inherited@}
local CROSS_TYPE_TECHNIQUE_ROWS = {mix = @crc:character_reforged_cross_type_mix_technique@, spirit = @crc:character_reforged_cross_type_spirit_technique@}
-- Returns the type label of an entry on page `page` that shows the form's technique (`technique`) or its transformation.
local function HyperButtonTypeLabel(page, technique)
  local row = CROSS_TYPE_ROWS[page]
  if technique then
    row = page == 2 and CROSS_TYPE_TECHNIQUE_ROWS.mix or CROSS_TYPE_TECHNIQUE_ROWS.spirit
  end
  if row == nil then
    return ""
  end
  if character_reforged_cross.labels == nil then
    character_reforged_cross.labels = {}
  end
  local label = character_reforged_cross.labels[row]
  if label == nil then
    local ok, text = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@, row)
    label = (ok and type(text) == "string") and text or ""
    character_reforged_cross.labels[row] = label
  end
  return label
end
-- The one-word reason of a greyed entry: the reason code of the entries command, then the menu_text row.
local CROSS_REASON_ROWS = {
  [2] = "character_reforged_cross_why_not_now", [3] = "character_reforged_cross_why_not_now", [4] = "character_reforged_cross_why_tension",
  [5] = "character_reforged_cross_why_cost", [6] = "character_reforged_cross_why_wait", [7] = "character_reforged_cross_why_active",
  [8] = "character_reforged_cross_why_locked", [9] = "character_reforged_cross_why_group", [10] = "character_reforged_cross_why_limit",
  [12] = "character_reforged_cross_why_limit", [13] = "character_reforged_cross_why_limit", [14] = "character_reforged_cross_why_armour",
  [15] = "character_reforged_cross_why_locked", [16] = "character_reforged_cross_why_locked", [17] = "character_reforged_cross_why_duel",
}
local CROSS_REASON_IDS = {
  character_reforged_cross_why_not_now = @crc:character_reforged_cross_why_not_now@, character_reforged_cross_why_tension = @crc:character_reforged_cross_why_tension@,
  character_reforged_cross_why_cost = @crc:character_reforged_cross_why_cost@, character_reforged_cross_why_wait = @crc:character_reforged_cross_why_wait@,
  character_reforged_cross_why_active = @crc:character_reforged_cross_why_active@, character_reforged_cross_why_locked = @crc:character_reforged_cross_why_locked@,
  character_reforged_cross_why_group = @crc:character_reforged_cross_why_group@, character_reforged_cross_why_limit = @crc:character_reforged_cross_why_limit@,
  character_reforged_cross_why_armour = @crc:character_reforged_cross_why_armour@, character_reforged_cross_why_duel = @crc:character_reforged_cross_why_duel@,
  character_reforged_cross_why_no_spirit = @crc:character_reforged_cross_why_no_spirit@, character_reforged_cross_why_no_miximax = @crc:character_reforged_cross_why_no_miximax@,
}
-- Returns the reason word of a greyed entry on page `page` ("" when the text is missing).
local function HyperButtonReasonWord(reason, page)
  local row = CROSS_REASON_ROWS[reason]
  if reason == 18 then
    -- The form the entry comes from is not out: the armour's keshin, the inherited spirit's Mix-Max.
    row = page == 4 and "character_reforged_cross_why_no_miximax" or "character_reforged_cross_why_no_spirit"
  end
  if row == nil then
    return ""
  end
  if character_reforged_cross.reasons == nil then
    character_reforged_cross.reasons = {}
  end
  local word = character_reforged_cross.reasons[row]
  if word == nil then
    local ok, text = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@, CROSS_REASON_IDS[row])
    word = (ok and type(text) == "string") and text or ""
    character_reforged_cross.reasons[row] = word
  end
  return word
end


local function HyperButtonReset()
  hyperButtonLast = {}
  for entry = 1, ENTRY_COUNT do
    hyperButtonLast[entry] = {st = -1, skill = 0, ring = false, glyph = ""}
  end
  hyperButtonPos = -1
  character_reforged_ho_set = {}
  character_reforged_ho_slide = {}
end
HyperButtonReset()

function CharacterReforged.hyper_button_init()
  HyperButtonReset()
  character_reforged_cross.held = false
  character_reforged_cross.ring, character_reforged_cross.rows, character_reforged_cross.row_count = {}, {}, 0
  character_reforged_cross.fit = {}
  character_reforged_cross.rects_logged = false
end

function CharacterReforged.hyper_button_setup_layer(a1, a2)
  if a1 == HyperButtonLayer then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, HyperButtonLayer, a2, false)
    if hyperButtonLast[a2 + 1] ~= nil then
      hyperButtonLast[a2 + 1].st = -1
      hyperButtonLast[a2 + 1].shown = false
    end
    character_reforged_ho_set[a2 + 1] = nil
    if a2 == character_reforged_cd.inst then
      character_reforged_cd.swapped, character_reforged_cd.shown, character_reforged_cd.geo = false, nil, nil   -- a set-up layer has its retail sprite back
    end
  elseif a1 == 1501547018 --[[cr_hiper_chr_icon: the plate portrait, shown by CharacterReforged.HyperButtonPlateFace]]
    or a1 == 2183681184 --[[cr_hiper_input: the input column, shown by CharacterReforged.HyperButtonInputDraw]] then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
  elseif a1 == TypeLayer or a1 == PillLayer or a1 == NameLayer then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
  elseif a1 == RingLayer then
    -- The ring starts like the retail widget (its «active» animation), hidden until the first entry is known.
    pcall(funcLuaMenuCommand, @crc:CMND_PLAY_ANIME_TYPE@, a1, a2, 1260321794 --[[active]], 0, 365840886)
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
    character_reforged_cross.ring = {}
    hyperButtonPos = -1
  end
end

-- Hangs every plate instance on its attach row of the ring.
local function HyperButtonSetPos()
  for i = 1, #PLATE_ATTACH do
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, RingLayer, 0, PLATE_ATTACH[i], true)
  end
end

local function HyperButtonInfo(skill, what)
  local ok, v = funcLuaCommand(SKILL_INFO, skill, what)
  if ok and type(v) == "number" then
    return v
  end
  return nil
end

local COMMAND_MXP = @crc:CMND_CHARACTERREFORGED_FUSION_PARTNER@
local COMMAND_LOG = @crc:CMND_VRFW_LOG@
local COMMAND_APPEARANCE = @crc:CMND_VRFW_APPEARANCE@
local HYPER_SUB_MESH = 559600405 --[[_icon_sp_sub_dmy01]]
local HYPER_SUB_TEXTURE = 3992937973 --[[icon_sp_sub_dmy01]]
-- The widget's placeholder meshes at the plate's right end, white boxes when left visible
local function HyperButtonHideDummies(L, inst, face)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, HYPER_SUB_MESH, false, inst)   -- face: own layer
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 365666709 --[[_num_at_cmd_dmy01]], false, inst)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 563708378 --[[_gtxt_cmd_at01]], false, inst)
end
-- The card's portrait at the band's right end, inside the band
local HyperChara = 1501547018 --[[cr_hiper_chr_icon]]
local HYPER_CHARA_ATTACH = 3531792463 --[[cr_hiper_chr01_r: its attach row on the plate]]
local HYPER_CHARA_HIDE = {734954092 --[[_fs_base01]], 1605611365 --[[_icon_fs_area_dmy01]]}
local HYPER_CHARA_TEXT = 2915321899 --[[_text_fs01]]
CharacterReforged.HYPER_BUTTON_FACE_H = 52
CharacterReforged.HYPER_BUTTON_FACE_DX, CharacterReforged.HYPER_BUTTON_FACE_DY = 0, 0   -- extra shift of the card's band corner (plate layer units)
local HYPER_CHARA_BAND_R, HYPER_CHARA_BAND_TOP, HYPER_CHARA_BAND_H = 457, 160, 88.15
local character_reforged_chr_logs = 0
-- Plate band constants: the band quad (layout top 160, 88.15 high) is scaled to the plate's painted band (_cmd_base_sp01).
local PLATE_BASE, PLATE_BASE_Y, PLATE_BAND = 4282364172 --[[_cmd_base_sp01]], 28, 26
local HYPER_CHARA_BASE = 734954092 --[[_fs_base01]]
local POSITION_BASE = 1517329426 --[[_pos_base01]]
local character_reforged_face = {{fix = 1, dy = 0}, {fix = 1, dy = 0}}

function CharacterReforged.hyper_button_plate_face_hide(inst)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, HyperChara, inst, false)
  if character_reforged_face ~= nil and character_reforged_face[inst + 1] ~= nil then
    character_reforged_face[inst + 1].key, character_reforged_face[inst + 1].ok = nil, false
  end
end

local function HyperButtonPlateFacePlace(inst)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, HyperButtonLayer, inst, HYPER_CHARA_ATTACH, true)
  local fc = character_reforged_face[inst + 1]
  local k = CharacterReforged.HYPER_BUTTON_FACE_H / HYPER_CHARA_BAND_H * (CharacterReforged.HYPER_BUTTON_PLATE_SCALE or 1) * fc.fix
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, HyperChara, k, k, 1, inst)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, HyperChara, CharacterReforged.HYPER_BUTTON_FACE_DX - HYPER_CHARA_BAND_R * k,
    CharacterReforged.HYPER_BUTTON_FACE_DY - HYPER_CHARA_BAND_TOP * k + fc.dy, 0, inst)
  for i = 1, #HYPER_CHARA_HIDE do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, HyperChara, HYPER_CHARA_HIDE[i], false, inst)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, HyperChara, HYPER_CHARA_TEXT, "", inst)
  funcLuaMenuCommand(2735666188 --[[CMND_SET_MENU_TEXT_VISIBLE]], HyperChara, HYPER_CHARA_TEXT, false, inst)
end

-- Fits the card's band onto the plate's painted band (global units, both layers measured).
function CharacterReforged.hyper_button_face_fit(inst)
  local fc = character_reforged_face[inst + 1]
  local function g(L, node)
    local ok, x, y = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_GLOBAL_POSITION@, L, inst, node)
    if ok and type(x) == "number" and type(y) == "number" then
      return x, y
    end
    return nil
  end
  local _, pby = g(HyperButtonLayer, POSITION_BASE)
  local _, pty = g(HyperButtonLayer, PLATE_BASE)
  local _, fby = g(HyperChara, POSITION_BASE)
  local _, fty = g(HyperChara, HYPER_CHARA_BASE)
  if pby == nil or pty == nil or fby == nil or fty == nil then
    return
  end
  local kp = (pty - pby) / PLATE_BASE_Y          -- global per plate layer unit (y)
  local kf = (fty - fby) / HYPER_CHARA_BAND_TOP          -- global per card layer unit (y)
  if math.abs(kp) < 0.001 or math.abs(kf) < 0.001 then
    return
  end
  local want_h = 2 * PLATE_BAND * math.abs(kp)   -- the painted band's height
  local have_h = HYPER_CHARA_BAND_H * math.abs(kf)       -- the card band's height
  local want_top = pby + PLATE_BAND * kp         -- the painted band's top
  local ratio = want_h / have_h
  local dtop = (want_top - fty) / kf                 -- card layer units
  if math.abs(ratio - 1) < 0.005 and math.abs(dtop * math.abs(kf)) < 0.5 then
    return
  end
  if math.abs(ratio - 1) >= 0.005 then
    fc.fix = fc.fix * ratio
  else
    local k = CharacterReforged.HYPER_BUTTON_FACE_H / HYPER_CHARA_BAND_H * (CharacterReforged.HYPER_BUTTON_PLATE_SCALE or 1) * fc.fix
    fc.dy = fc.dy + dtop * k
  end
  HyperButtonPlateFacePlace(inst)
  if character_reforged_chr_logs < 24 then
    character_reforged_chr_logs = character_reforged_chr_logs + 1
    pcall(funcLuaCommand, @crc:CMND_VRFW_LOG_DEBUG@, "hiper_btn", "face fit", tostring(inst),
      string.format("band %.1f / card %.1f, fix %.3f, dy %.1f", want_h, have_h, fc.fix, fc.dy))
  end
end

-- Returns true when it drew a portrait.
function CharacterReforged.hyper_button_plate_face(L, inst, hdl, retry, pover, skill)
  if type(CharacterReforged.hyper_card) ~= "table" or type(CharacterReforged.hyper_card.portrait) ~= "function" then
    CharacterReforged.hyper_button_plate_face_hide(inst)
    return false
  end
  local t = nil
  if skill ~= nil and skill ~= 0 then
    t = CharacterReforged.hyper_card.aura_type(skill)
  end
  local fusion, mc, own = nil, nil, skill
  local function key(param)
    local okk, k = pcall(funcLuaCommand, 347353059, param)
    if okk and type(k) == "number" and k ~= 0 then
      return k
    end
    return param
  end
  if pover ~= nil and pover ~= 0 then
    mc = {face = key(pover)}
  elseif t == 2 or t == nil or t == 255 then
    local okf, partner, spirit = pcall(funcLuaCommand, COMMAND_MXP, hdl, skill or 0)
    if okf and type(partner) == "number" and partner ~= 0 then
      fusion = {face = key(partner)}
    elseif okf and t == nil and type(spirit) == "number" and spirit ~= 0 then
      own = spirit
      t = CharacterReforged.hyper_card.aura_type(spirit)
    end
  end
  if fusion == nil and mc == nil and (t == nil or CharacterReforged.hyper_card.FACE_BY_TYPE[t] == nil) then
    CharacterReforged.hyper_button_plate_face_hide(inst)
    return false
  end
  local fc = character_reforged_face[inst + 1]
  local key = tostring(own or 0) .. ":" .. tostring(fusion and fusion.face or 0) .. ":" .. tostring(mc and mc.face or 0)
  if fc.key == key and fc.ok then
    -- The same face is on screen.
    if retry then
      pcall(CharacterReforged.hyper_button_face_fit, inst)
    end
    return true
  end
  HyperButtonPlateFacePlace(inst)
  local okp, shown = pcall(CharacterReforged.hyper_card.portrait, HyperChara, own or 0, fusion, mc, "hiper_plates", inst)
  local ok = okp and shown ~= nil and shown ~= 0
  fc.key, fc.ok = key, ok
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, HyperChara, inst, ok)
  if not retry or character_reforged_chr_logs < 12 then
    character_reforged_chr_logs = character_reforged_chr_logs + 1
    local what = "own"
    if fusion ~= nil then
      what = "partner"
    elseif mc ~= nil then
      what = "mode change"
    elseif own ~= skill then
      what = string.format("spirit %08X", own or 0)
    end
    pcall(funcLuaCommand, @crc:CMND_VRFW_LOG_DEBUG@, "hiper_btn", "plate portrait", tostring(inst), tostring(hdl),
      string.format("%08X", skill or 0), "type " .. tostring(t), what,
      okp and tostring(shown) or ("error " .. tostring(shown)), retry and "retry" or "")
  end
  return ok
end

-- The name text of a miximax / soul aura as retail UpdateSkillCmdSkillName builds it
function CharacterReforged.hyper_button_aura_name(skill, name, auraType)
  local mixi = IsAuraSkillMixiMax(auraType)
  local soul = IsAuraSkillSoul(auraType)
  if not (mixi or soul) then
    return name
  end
  local s = ""
  local _, chara = funcLuaCommand(SKILL_INFO, skill, 17)
  if type(chara) == "number" and chara ~= 0 then
    local _, n = funcLuaCommand(@crc:CMND_GET_CHARA_INFO@, chara, mixi and 10 or 0)
    if type(n) == "string" then
      s = n
    end
  end
  local conv = funcLuaCommand(@crc:CMND_TEXT_CONVERT@, name, 0, 2508554842, s)
  if type(conv) == "string" then
    return conv
  end
  return name
end

local HyperInput = 2183681184 --[[cr_hiper_input]]
local HYPER_INPUT_ATTACH = 222334746 --[[cr_hiper_input01: its attach row on the plate]]
local HYPER_INPUT_TOP = 950238781 --[[_text_btn01]]
local HYPER_INPUT_BOTTOM = 2712285063 --[[_text_btn02]]
CharacterReforged.HYPER_INPUT_K = 0.8
CharacterReforged.HYPER_INPUT_DX, CharacterReforged.HYPER_INPUT_DY = 0, 0  -- extra shift of the column (plate layer units)
local character_reforged_glyph_logs, character_reforged_glyph_last = 0, {}
-- The loader's face-button tags are the move cross's commands (<CMD_DECIDE_CMD_R_DOWN> and so on).
CharacterReforged.HYPER_INPUT_TAGS = {["<CMD_DECIDE_CMD_R_DOWN>"] = "<CMD_ENTER>", ["<CMD_DECIDE_CMD_R_RIGHT>"] = "<CMD_BACK>",
  ["<CMD_DECIDE_CMD_R_LEFT>"] = "<CMD_FUNC4>", ["<CMD_DECIDE_CMD_R_UP>"] = "<CMD_FUNC3>"}

function CharacterReforged.hyper_button_input_hide(inst)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, HyperInput, inst, false)
end

function CharacterReforged.hyper_button_input_draw(inst, top, bottom)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, HyperButtonLayer, inst, HYPER_INPUT_ATTACH, true)
  local k = CharacterReforged.HYPER_INPUT_K * (CharacterReforged.HYPER_BUTTON_PLATE_SCALE or 1)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, HyperInput, k, k, 1, inst)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, HyperInput, CharacterReforged.HYPER_INPUT_DX + character_reforged_fold.input_shift, CharacterReforged.HYPER_INPUT_DY, 0, inst)
  local r1 = funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, HyperInput, HYPER_INPUT_TOP, top, inst)
  local r2 = funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, HyperInput, HYPER_INPUT_BOTTOM, bottom, inst)
  funcLuaMenuCommand(2735666188 --[[CMND_SET_MENU_TEXT_VISIBLE]], HyperInput, HYPER_INPUT_TOP, top ~= "", inst)
  funcLuaMenuCommand(2735666188, HyperInput, HYPER_INPUT_BOTTOM, bottom ~= "", inst)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, HyperInput, inst, top ~= "" or bottom ~= "")
  return r1, r2
end

function CharacterReforged.hyper_button_caption_hide(inst)
  for i = 1, #CAPTION_LAYERS do
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, CAPTION_LAYERS[i].layer, inst, false)
  end
end

-- Shows `text` on one text layer of plate `inst` at `scale` against the plate, `dx`, `dy` from the input column.
local function HyperButtonCaptionLayer(index, inst, text, scale, dx, dy, red, green, blue)
  local caption = CAPTION_LAYERS[index]
  local layer = caption.layer
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, HyperButtonLayer, inst, caption.attach, true)
  local k = scale * (CharacterReforged.HYPER_BUTTON_PLATE_SCALE or 1)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, layer, k, k, 1, inst)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, dx + character_reforged_fold.input_shift, dy, 0, inst)
  for i = 1, #CAPTION_TEXTS do
    funcLuaMenuCommand(2735666188 --[[CMND_SET_MENU_TEXT_VISIBLE]], layer, CAPTION_TEXTS[i], CAPTION_TEXTS[i] == caption.text and text ~= "", inst)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, CAPTION_PILL_BAND, caption.text == CAPTION_PILL_TEXT and text ~= "", inst)
  local set = funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, layer, caption.text, text, inst)
  funcLuaMenuCommand(2771105252 --[[text colour]], layer, inst, caption.text, red, green, blue)
  if text ~= "" and not character_reforged_cross.logged["text" .. index] then
    character_reforged_cross.logged["text" .. index] = true
    pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross text layer " .. index .. " plate " .. inst, text, "set " .. tostring(set), "scale " .. k, "at " .. dx .. "," .. dy)
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, inst, text ~= "")
end

-- Draws the texts of plate `inst`: the type label over the name, the name shrunk to its room, the cost or reason pill.
function CharacterReforged.hyper_button_caption_draw(inst, name, caption, usable)
  local place = CharacterReforged.TRANSFORM_CROSS
  local shade = usable and 1 or 0.5
  HyperButtonCaptionLayer(1, inst, caption.label, place.text_scale, place.type_offset_x, place.type_offset_y, shade, shade, shade)
  if caption.reason then
    HyperButtonCaptionLayer(2, inst, caption.pill, place.text_scale, place.pill_offset_x, place.pill_offset_y, 1, 0.5, 0.45)
  else
    HyperButtonCaptionLayer(2, inst, caption.pill, place.text_scale, place.pill_offset_x, place.pill_offset_y, 1, 1, 1)
  end
  -- The name is drawn at its full size; the next step measures it and shrinks it to its room.
  HyperButtonCaptionLayer(3, inst, name, place.name_scale, place.name_offset_x, place.name_offset_y, shade, shade, shade)
  character_reforged_cross.fit[inst + 1] = name
end

-- Shrinks the name layer of plate `inst` as a whole until the drawn name fits its room: a name is never cut.
local function HyperButtonNameFit(inst, face)
  local name = character_reforged_cross.fit[inst + 1]
  character_reforged_cross.fit[inst + 1] = nil
  local place = CharacterReforged.TRANSFORM_CROSS
  local room = face and place.name_room_face or place.name_room
  local ok, width = pcall(funcLuaMenuCommand, COMMAND_TEXT_SIZE, NameLayer, inst, CAPTION_LEFT_TEXT)
  if not ok or type(width) ~= "number" or width <= 0 then
    if not character_reforged_cross.measure_logged then
      character_reforged_cross.measure_logged = true
      pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "ERROR: the name's width cannot be measured: long names are not fitted", name, tostring(ok), tostring(width))
    end
    return
  end
  local scale = place.name_scale
  if width * scale > room then
    scale = room / width
  end
  local k = scale * (CharacterReforged.HYPER_BUTTON_PLATE_SCALE or 1)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, NameLayer, k, k, 1, inst)
  if character_reforged_cross.logged["fit" .. inst] ~= name then
    character_reforged_cross.logged["fit" .. inst] = name
    pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross name plate " .. inst, name, "width " .. width, "room " .. room, "scale " .. scale)
  end
end

function CharacterReforged.hyper_button_draw(slot, st, hdl, skill, ring, appear, glyph, armour, caption, pover)
  local L, inst = HyperButtonLayer, slot
  if st == 0 or skill == 0 then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, L, inst, false)
    CharacterReforged.hyper_button_plate_face_hide(inst)
    CharacterReforged.hyper_button_input_hide(inst)
    CharacterReforged.hyper_button_caption_hide(inst)
    return
  end
  local usable = st == 1
  local element = HyperButtonInfo(skill, 7) or 1
  local nameId = HyperButtonInfo(skill, 4) or 0
  local auraType = HyperButtonInfo(skill, 13)
  local isAura = auraType ~= nil and auraType ~= 255
  local category = isAura and 8 or (HyperButtonInfo(skill, 9) or 1)
  local armed = isAura and IsAuraSkillKeshinArmed(auraType) or false
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, L, inst, true)
  -- plate, name (same calls as a move row of SetupSkillCmdInfo)
  local tex = GetSkillElementBaseTextureName(inst, hdl, skill, element, category)
  if tex ~= 0 then
    SwapTextureSkillCmd(L, inst, tex)
  end
  UpdateSkillCmdSkillName(L, inst, hdl, skill, nameId, category)
  character_reforged_fold.icon[slot + 1] = pcall(SetupCommandActionSkillInfoCategoryIcon, L, inst, skill)
  if not character_reforged_fold.icon[slot + 1] then
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 2164615260 --[[_icon_sp_area_dmy01]], false, inst)
  end
  do
    local buttons = {}
    for tag in string.gmatch(glyph or "", "<[^>]+>") do buttons[#buttons + 1] = CharacterReforged.HYPER_INPUT_TAGS[tag] or tag end
    -- The modifier is the ring's centre: the column shows the entry's own button alone.
    local top, bottom = "", buttons[#buttons] or glyph or ""
    local okg, r1, r2 = pcall(CharacterReforged.hyper_button_input_draw, inst, top, bottom)
    local gkey = top .. "|" .. bottom
    if character_reforged_glyph_last[inst + 1] ~= gkey and character_reforged_glyph_logs < 40 then
      character_reforged_glyph_last[inst + 1] = gkey
      character_reforged_glyph_logs = character_reforged_glyph_logs + 1
      pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn glyph", "inst=" .. tostring(inst), "top=" .. top, "bottom=" .. bottom,
        "raw=" .. tostring(glyph), okg and ("set " .. tostring(r1) .. "/" .. tostring(r2)) or ("error " .. tostring(r1)))
    end
  end
  funcLuaMenuCommand(1284929827, L, inst, usable)
  SetVisibleCmdButton(L, inst, true)
  -- The name is drawn by its own text layer, which can shrink.
  SetVisibleSkillCmdName(L, inst, false)
  -- Hides the placeholder boxes at the plate's right end.
  local okf, drawn = pcall(CharacterReforged.hyper_button_plate_face, L, inst, hdl, false, pover, skill)
  local face = okf and drawn == true
  if glyph ~= "" and nameId ~= 0 then
    local name = funcLuaCommand(720417636, nameId)
    if isAura and type(name) == "string" then
      local okn, conv = pcall(CharacterReforged.hyper_button_aura_name, skill, name, auraType)
      if okn and type(conv) == "string" then
        name = conv
      end
    end
    if armour then
      -- Handles the armour plate.
      name = ""
    end
    if type(name) == "string" then
      local okc, errc = pcall(CharacterReforged.hyper_button_caption_draw, inst, name, caption, usable)
      if not okc and character_reforged_cross.logged["caption"] ~= tostring(errc) then
        character_reforged_cross.logged["caption"] = tostring(errc)
        pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross texts error", tostring(errc))
      end
    end
  else
    CharacterReforged.hyper_button_caption_hide(inst)
  end
  HyperButtonHideDummies(L, inst, face)
  for i = 1, #HyperCubes do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, HyperCubes[i], false, inst)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 1621112166 --[[_cmd_pw_cube01]], false, inst)
  character_reforged_fold.logo[slot + 1] = armour == true
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 1206374040 --[[_gtxt_cmd_armed01]], character_reforged_fold.logo[slot + 1], inst)
  funcLuaMenuCommand(2158717427, L, 4081284803 --[[_pos_at01]], false, inst)
  funcLuaMenuCommand(1233047821, L, inst, 2467766246, false)
  funcLuaMenuCommand(1233047821, L, inst, 875648615, false)
  -- lit / greyed (as SetSkillCmdGrayout)
  local gray = 2300007848 --[[cmd_base_sp_grayout01]]
  local ringTex = 97673312 --[[sp_ring02]]
  if isAura then
    gray = armed and 1729705092 --[[cmd_base_sp_grayout03]] or 270402578 --[[cmd_base_sp_grayout02]]
    ringTex = armed and 3183539200 --[[sp_ring02_03]] or 3402089622 --[[sp_ring02_02]]
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 3742978053 --[[_cmd_base_sp_grayout01]], not usable, inst)
  funcLuaMenuCommand(558735651, L, 2804251149 --[[soccer08_10.g4tx]], gray, 2300007848 --[[cmd_base_sp_grayout01]], 0, inst)
  funcLuaMenuCommand(558735651, L, 2804251149 --[[soccer08_10.g4tx]], ringTex, 97673312 --[[sp_ring02]], 0, inst)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 1213120893 --[[_sp_ring02]], ring, inst)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, L, inst, 1633223871, usable and 2 or 0)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, L, inst, 846750395, 2)
  if ring and usable then
    funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, L, inst, 1286797620 --[[Active]], 0, 4054903817)
  else
    funcLuaMenuCommand(1380315136, L, inst, 1286797620 --[[Active]], 2, 4054903817)
  end
  if appear then
    funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, L, inst, 71445658 --[[Open]], 0, 2181236453)
  end
  HyperButtonHideDummies(L, inst, face)
  return face
end

local function HyperButtonNum(v)
  if type(v) == "number" then
    return v
  end
  return 0
end

local function HyperButtonStr(v)
  if type(v) == "string" then
    return v
  end
  return ""
end

local hyperButtonTick = 0

-- The plate stays greyed until the charge bar fills again.
CharacterReforged.HYPER_BUTTON_CHARGE_BAR = true
CharacterReforged.HYPER_BUTTON_CHARGE_BAR_L = -226
CharacterReforged.HYPER_BUTTON_CHARGE_BAR_R = 166            -- right end (the plate's visible right edge is ~172)
CharacterReforged.HYPER_BUTTON_CHARGE_BAR_BOTTOM = -21       -- bottom of the line (the plate's visible bottom is -27)
CharacterReforged.HYPER_BUTTON_CHARGE_BAR_H = 6              -- thickness (x 0.72: ~4 px)
local HYPER_CHARGE_MESH = 1621112166 --[[_cmd_pw_cube01]]
local HYPER_CHARGE_SLOT = 3488642376 --[[its sprite slot (40 x 40 power cube)]]
local HYPER_CHARGE_TEXTURE_PATH = "#/menu/00_soccer/soccer00/soccer00_54/soccer00_54.g4tx"
local HYPER_CHARGE_TEXTURE = 3000726149 --[[crc32 of HYPER_CHARGE_TEXTURE_PATH]]
local HYPER_CHARGE_SPRITE = 4200959402 --[[gauge_recast_aura01]]
local HYPER_CHARGE_ROWS, HYPER_CHARGE_OPAQUE = 12, 7

local function HyperButtonChargeLog(...)
  if character_reforged_cd.logs < 8 then
    character_reforged_cd.logs = character_reforged_cd.logs + 1
    character_reforged_cd.logger = character_reforged_cd.logger or VRFW.logger.new("hiper_btn")
    character_reforged_cd.logger.debug("cooldown bar", ...)
  end
end

local function HyperButtonChargeShow(on)
  if character_reforged_cd.shown ~= on then
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, HyperButtonLayer, HYPER_CHARGE_MESH, on, character_reforged_cd.inst)
    character_reforged_cd.shown = on
  end
end

-- Draws the charge bar for the fraction `frac`.
local function HyperButtonChargeBar(frac)
  if frac == nil or not CharacterReforged.HYPER_BUTTON_CHARGE_BAR or frac >= 1 then
    HyperButtonChargeShow(false)
    return
  end
  if not VRFW.textures.poll(HYPER_CHARGE_TEXTURE_PATH, VRFW.textures.SETTLED) then
    HyperButtonChargeShow(false)
    return
  end
  if not character_reforged_cd.swapped then
    funcLuaMenuCommand(558735651 --[[swap texture]], HyperButtonLayer, HYPER_CHARGE_TEXTURE, HYPER_CHARGE_SPRITE, HYPER_CHARGE_SLOT, 0, character_reforged_cd.inst)
    character_reforged_cd.swapped, character_reforged_cd.geo = true, nil
  end
  local span = (CharacterReforged.HYPER_BUTTON_CHARGE_BAR_R - CharacterReforged.HYPER_BUTTON_CHARGE_BAR_L) * (character_reforged_fold.width or character_reforged_fold.full_width) / character_reforged_fold.full_width
  local left = CharacterReforged.HYPER_BUTTON_CHARGE_BAR_R - span
  local w = span * math.max(0, frac)
  if w < 1 then
    HyperButtonChargeShow(false)
    return
  end
  local h = CharacterReforged.HYPER_BUTTON_CHARGE_BAR_H
  local quad_h = h * HYPER_CHARGE_ROWS / HYPER_CHARGE_OPAQUE
  local top = CharacterReforged.HYPER_BUTTON_CHARGE_BAR_BOTTOM + h * 9 / HYPER_CHARGE_OPAQUE   -- opaque rows 2..8 of the quad end on the bottom
  local g = character_reforged_cd.geo
  if g == nil or math.abs(g[1] - w) > 0.05 or g[2] ~= top or g[3] ~= quad_h or math.abs(g[4] - left) > 0.05 then
    funcLuaMenuCommand(2885415772 --[[node size]], HyperButtonLayer, character_reforged_cd.inst, HYPER_CHARGE_MESH, w, quad_h)
    funcLuaMenuCommand(2575768773 --[[node translation]], HyperButtonLayer, character_reforged_cd.inst, HYPER_CHARGE_MESH, 0, left)
    funcLuaMenuCommand(2575768773 --[[node translation]], HyperButtonLayer, character_reforged_cd.inst, HYPER_CHARGE_MESH, 1, top)
    character_reforged_cd.geo = {w, top, quad_h, left}
  end
  HyperButtonChargeShow(true)
end

local function HyperButtonUpdate(inst, st, hdl, skill, ring, glyph, armour, caption, pover)
  local last = hyperButtonLast[inst + 1]
  local caption_key = caption.label .. "|" .. caption.pill .. "|" .. tostring(caption.reason)
  pover = pover or 0
  if pover == 0 and (last.pover or 0) ~= 0 and skill == last.skill and hdl == last.hdl and st == last.st then
    pover = last.pover
  end
  if st == last.st and skill == last.skill and ring == last.ring and glyph == last.glyph and hdl == last.hdl and armour == last.armour
    and caption_key == (last.caption_key or "") and pover == (last.pover or 0) then
    return
  end
  local appear = last.st ~= 1 and last.st ~= 2
  last.st = st
  last.skill = skill
  last.ring = ring
  last.glyph = glyph
  last.hdl = hdl
  last.armour = armour
  last.caption_key = caption_key
  last.pover = pover
  local ok, face = pcall(CharacterReforged.hyper_button_draw, inst, st, hdl, skill, ring, appear, glyph, armour, caption, pover)
  last.face = ok and face == true
  if inst == character_reforged_cd.inst then
    character_reforged_cd.shown = nil
  end
  last.drawTick = hyperButtonTick
  last.hasFace = false
  if ok and st ~= 0 and skill ~= 0 then
    local okp, partner, spirit = pcall(funcLuaCommand, COMMAND_MXP, hdl, skill)
    last.hasFace = (okp and ((type(partner) == "number" and partner ~= 0) or (type(spirit) == "number" and spirit ~= 0)))
      or pover ~= 0
  end
  last.shown = ok and st ~= 0 and skill ~= 0
  if appear and last.shown then
    character_reforged_ho_slide[inst + 1] = hyperButtonTick
  end
  if not ok then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, HyperButtonLayer, inst, false)
    CharacterReforged.hyper_button_plate_face_hide(inst)
    CharacterReforged.hyper_button_input_hide(inst)
    CharacterReforged.hyper_button_caption_hide(inst)
  end
end

-- The plates slide in from the left screen edge when they appear.
CharacterReforged.HYPER_BUTTON_SLIDE_FRAMES = 9
CharacterReforged.HYPER_BUTTON_SLIDE_DX = 380            -- start offset: the whole plate past its place
-- The plate's scale is the cross's config value (set with it): the portrait and the input column follow it.

local RELEASE_GUIDE = 3063505148 --[[soccer08_17b_aura_release_button_guide]]
CharacterReforged.MODE_CHANGE_NO_RELEASE = false
local character_reforged_mc_prevVis = rawget(_ENV, "UpdateVisibleAttachButtonGuide")
if type(character_reforged_mc_prevVis) == "function" then
  rawset(_ENV, "UpdateVisibleAttachButtonGuide", function(a1, a2, ...)
    local r = character_reforged_mc_prevVis(a1, a2, ...)
    if a1 == RELEASE_GUIDE and CharacterReforged.MODE_CHANGE_NO_RELEASE then
      pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
    end
    return r
  end)
end

-- Returns the visible band of a plate at band quad width `width`.
local function HyperButtonBandEnds(width)
  local f = width / character_reforged_fold.full_width
  return character_reforged_fold.quad_right - width + character_reforged_fold.band_margin * f, character_reforged_fold.visible_right
end

local function HyperButtonSlideDx(inst)
  local start = character_reforged_ho_slide[inst + 1]
  if start == nil then
    return 0
  end
  local n = CharacterReforged.HYPER_BUTTON_SLIDE_FRAMES or 0
  local t = n > 0 and (hyperButtonTick - start) / n or 1
  if t >= 1 or t < 0 then
    character_reforged_ho_slide[inst + 1] = nil
    return 0
  end
  local r = 1 - t
  return math.floor(CharacterReforged.HYPER_BUTTON_SLIDE_DX * r * r * r + 0.5)
end

-- The numbers of the config command, in the order scripts\transform_cross.lua returns them.
local CROSS_CONFIG_KEYS = {
  "centre_x", "centre_y", "ring_size", "dim_brightness", "plate_left", "plate_scale", "row_pitch", "text_scale", "name_scale", "name_room",
  "name_room_face", "type_offset_x", "type_offset_y", "name_offset_x", "name_offset_y", "pill_offset_x", "pill_offset_y",
}
-- Reads the cross's places from the mod's config once; answers whether they are known.
local function HyperButtonCrossConfig()
  if CharacterReforged.TRANSFORM_CROSS ~= nil then
    return true
  end
  if character_reforged_cross.config_failed then
    return false
  end
  local r = {pcall(funcLuaCommand, @crc:CMND_CHARACTERREFORGED_TRANSFORM_CROSS@)}
  local place = {directions = {}}
  for i = 1, #CROSS_CONFIG_KEYS do
    place[CROSS_CONFIG_KEYS[i]] = r[i + 1]
  end
  for entry = 1, ENTRY_COUNT do
    place.directions[entry] = r[#CROSS_CONFIG_KEYS + 1 + entry]
  end
  if r[1] ~= true or type(place.centre_x) ~= "number" or type(place.directions[ENTRY_COUNT]) ~= "number" then
    character_reforged_cross.config_failed = true
    pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "ERROR: no transform cross layout (config.toml [transform_cross]): the cross is not drawn", tostring(r[2]))
    return false
  end
  CharacterReforged.TRANSFORM_CROSS = place
  CharacterReforged.HYPER_BUTTON_PLATE_SCALE = place.plate_scale
  return true
end

-- Shows or hides the ring; a shown ring sits at its place with the modifier's glyph `modifier_tag` in the centre.
local function HyperButtonRingShow(visible, modifier_tag)
  local ring = character_reforged_cross.ring
  local seen = tostring(visible) .. modifier_tag
  if ring.shown == seen then
    return
  end
  ring.shown = seen
  if visible then
    local place = CharacterReforged.TRANSFORM_CROSS
    local scale = place.ring_size / RING_NATIVE_SIZE
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, RingLayer, scale, scale, 1, 0)
    -- The layer moves from its layout place to the configured screen place (layer y grows upwards).
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, RingLayer, place.centre_x - SCREEN_WIDTH - RING_LAYOUT_X, SCREEN_HEIGHT - place.centre_y - RING_LAYOUT_Y, 0, 0)
    funcLuaMenuCommand(2158717427 --[[node group visible]], RingLayer, RING_PULSE_GROUP, false)
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, RingLayer, RING_GLYPH, modifier_tag, 0)
    funcLuaMenuCommand(2735666188 --[[CMND_SET_MENU_TEXT_VISIBLE]], RingLayer, RING_GLYPH, modifier_tag ~= "", 0)
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, RingLayer, 0, visible)
end

-- Draws the type icon of entry `entry` on the ring: lit (state 1), dim (2) or absent (0).
local function HyperButtonRingIcon(entry, slot_skill, state)
  local ring = character_reforged_cross.ring
  local seen = slot_skill .. ":" .. state
  if ring[entry + 1] == seen then
    return
  end
  ring[entry + 1] = seen
  local place = CharacterReforged.TRANSFORM_CROSS
  local icon = RING_ICONS[place.directions[entry + 1]]
  local sprite = 0
  if state ~= 0 and slot_skill ~= 0 then
    local aura_type = HyperButtonInfo(slot_skill, 13)
    local category = (aura_type ~= nil and aura_type ~= 255) and 8 or (HyperButtonInfo(slot_skill, 9) or 0)
    sprite = GetSkillCategoryIcon(category, slot_skill, 0)
  end
  if sprite ~= 0 then
    funcLuaMenuCommand(558735651 --[[swap texture]], RingLayer, RING_ICON_ATLAS, sprite, icon[2], 0)
    local shade = state == 1 and 1 or place.dim_brightness
    funcLuaMenuCommand(3676296427 --[[material colour]], RingLayer, 0, icon[3], shade, shade, shade)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, RingLayer, icon[1], sprite ~= 0)
end

-- Returns the layout y of the row of entry `entry` (the rows of the existing entries, centred on the cross).
local function HyperButtonRowY(entry)
  local place = CharacterReforged.TRANSFORM_CROSS
  local row = character_reforged_cross.rows[entry + 1] or 0
  return place.centre_y + (row - (character_reforged_cross.row_count - 1) / 2) * place.row_pitch
end

-- Places the plates of the existing entries as rows right of the ring: each plate hangs on the ring's centre.
function CharacterReforged.hyper_button_open_place()
  local place = CharacterReforged.TRANSFORM_CROSS
  local scale = place.plate_scale
  local unit = 0.72 * scale
  local left_now, right_end = HyperButtonBandEnds(character_reforged_fold.full_width)
  -- The screen x of the plate's origin, then its place from the ring's centre (layer y grows upwards).
  local origin_x = place.plate_left - left_now * unit
  for inst = 0, ENTRY_LAST do
    local dx = math.floor(origin_x - place.centre_x + 0.5) - HyperButtonSlideDx(inst)
    local dy = math.floor(place.centre_y - HyperButtonRowY(inst) + 0.5)
    local key = dx .. "," .. dy .. "," .. scale
    if character_reforged_ho_set[inst + 1] ~= key then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, HyperButtonLayer, scale, scale, 1, inst)
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, HyperButtonLayer, dx, dy, 0, inst)
      character_reforged_ho_set[inst + 1] = key
    end
  end
  -- One line with the resolved screen places for the first in-game check (layout units, x from the left, y from the top).
  if not character_reforged_cross.rects_logged and character_reforged_cross.row_count > 0 then
    character_reforged_cross.rects_logged = true
    local band_width, band_half_height = (right_end - left_now) * unit, 26 * unit
    local half = place.ring_size / 2
    local okg, ring_x, ring_y = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_GLOBAL_POSITION@, RingLayer, 0, RING_BAND)
    local parts = {"ring x " .. (place.centre_x - half) .. "-" .. (place.centre_x + half) .. " y " .. (place.centre_y - half) .. "-" .. (place.centre_y + half)
      .. " (its band's corner measured at " .. tostring(okg and ring_x) .. "," .. tostring(okg and ring_y) .. ")"}
    for entry = 0, ENTRY_LAST do
      local line = "entry " .. entry .. " " .. tostring(CROSS_DIRECTION_NAME[place.directions[entry + 1]])
      if character_reforged_cross.rows[entry + 1] ~= nil then
        local row_y = HyperButtonRowY(entry)
        local okp, plate_x, plate_y = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_GLOBAL_POSITION@, HyperButtonLayer, entry, POSITION_BASE)
        line = line .. " (origin measured at " .. tostring(okp and plate_x) .. "," .. tostring(okp and plate_y) .. ")"
        line = line .. " plate x " .. place.plate_left .. "-" .. math.floor(place.plate_left + band_width + 0.5) .. " y " .. math.floor(row_y - band_half_height + 0.5) .. "-" .. math.floor(row_y + band_half_height + 0.5)
      end
      parts[#parts + 1] = line
    end
    pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross layout (1920 x 1080): " .. table.concat(parts, "; "))
  end
end

CharacterReforged.HYPER_BUTTON_HIDE_IN_TACTICS = true     -- no Hiper / armour plate while the LB tactics menu is up
CharacterReforged.HYPER_BUTTON_FACE_RETRY = {10, 30, 60, 120, 240}   -- frames after a draw when the partner face is issued again

-- Values of the entries command: after `hdl, held, device, count, release refused`, twelve per entry.
local ENTRY_FIRST_VALUE, ENTRY_VALUE_COUNT = 6, 12

function CharacterReforged.hyper_button_step()
  if not HyperButtonCrossConfig() then
    return
  end
  local r = {pcall(funcLuaCommand, COMMAND_ENTRIES)}
  if r[1] ~= true then
    r = {}
  end
  hyperButtonTick = hyperButtonTick + 1
  local hdl = HyperButtonNum(r[2])
  -- The keyboard has no modifier to hold: its plates stay open.
  local held = r[3] == true or (hdl ~= 0 and HyperButtonNum(r[4]) == 1)
  local count = math.min(HyperButtonNum(r[5]), ENTRY_COUNT)
  if CharacterReforged.HYPER_BUTTON_HIDE_IN_TACTICS then
    local okt, tac = pcall(funcLuaCommand, @crc:CMND_IS_SPECIAL_TACTICS_CMD_MODE@)
    if okt and tac == true then
      count = 0
    end
  end
  if hyperButtonPos ~= 0 then
    HyperButtonSetPos()
    hyperButtonPos = 0
  end
  character_reforged_cross.held = held
  -- The rows: one per existing entry, in the entries' order.
  local rows, row_count = {}, 0
  for entry = 0, ENTRY_LAST do
    local base = ENTRY_FIRST_VALUE + entry * ENTRY_VALUE_COUNT
    if entry < count and hdl ~= 0 and HyperButtonNum(r[base + 3]) ~= 0 and HyperButtonNum(r[base + 2]) ~= 0 then
      rows[entry + 1] = row_count
      row_count = row_count + 1
    end
  end
  character_reforged_cross.rows, character_reforged_cross.row_count = rows, row_count
  local swap_entry, swap_fraction = nil, nil
  local modifier_tag = ""
  for entry = 0, ENTRY_LAST do
    local base = ENTRY_FIRST_VALUE + entry * ENTRY_VALUE_COUNT
    local page, skill, state = HyperButtonNum(r[base + 1]), HyperButtonNum(r[base + 2]), HyperButtonNum(r[base + 3])
    local reason, cost = HyperButtonNum(r[base + 4]), HyperButtonNum(r[base + 6])
    local cooldown_per_mille = HyperButtonNum(r[base + 8])
    local glyph, action = HyperButtonStr(r[base + 9]), HyperButtonNum(r[base + 10])
    if rows[entry + 1] == nil then
      state, skill = 0, 0
    end
    -- The icon of the entry's kind stays on the ring; its plate shows only while the modifier is held.
    local okt, errt = pcall(HyperButtonRingIcon, entry, state ~= 0 and HyperButtonNum(r[base + 12]) or 0, state)
    if not okt and character_reforged_cross.logged["ring" .. entry] ~= tostring(errt) then
      character_reforged_cross.logged["ring" .. entry] = tostring(errt)
      pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross icon " .. entry .. " error", tostring(errt))
    end
    -- The first tag of a two-button chord is the modifier, the ring's centre.
    if state ~= 0 and modifier_tag == "" then
      local first, second = string.match(glyph, "^(<[^>]+>)(<[^>]+>)")
      if second ~= nil then
        modifier_tag = first
      end
    end
    -- The plate's texts: the type label, and in the pill a greyed entry's reason or the technique's cost when the mod declares one.
    local caption = {label = state ~= 0 and HyperButtonTypeLabel(page, r[base + 5] == true) or "", pill = "", reason = false}
    if state == 2 then
      caption.pill, caption.reason = HyperButtonReasonWord(reason, page), true
    elseif state == 1 and r[base + 5] == true and cost > 0 then
      caption.pill = tostring(cost)
    end
    -- The swap (action 8) carries the other form's face and the cooldown bar.
    if state ~= 0 and action == 8 then
      swap_entry = entry
      if cooldown_per_mille < 1000 then
        swap_fraction = cooldown_per_mille / 1000
      end
    end
    HyperButtonUpdate(entry, held and state or 0, hdl, held and skill or 0, held, glyph, false, caption, HyperButtonNum(r[base + 11]))
    local seen = state .. ":" .. skill .. ":" .. reason
    if state ~= 0 and character_reforged_cross.logged[entry + 1] ~= seen then
      character_reforged_cross.logged[entry + 1] = seen
      pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross entry " .. entry, "page " .. page, "move " .. skill, "state " .. state, "reason " .. reason, "glyph " .. glyph)
    end
  end
  local okr, errr = pcall(HyperButtonRingShow, row_count > 0, modifier_tag)
  if not okr and character_reforged_cross.logged["ring"] ~= tostring(errr) then
    character_reforged_cross.logged["ring"] = tostring(errr)
    pcall(funcLuaCommand, COMMAND_LOG, "hiper_btn", "cross ring error", tostring(errr))
  end
  -- A running form that refuses the retail release button hides its guide.
  local no_release = r[6] == true
  if no_release then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, RELEASE_GUIDE, 0, false)
  end
  CharacterReforged.MODE_CHANGE_NO_RELEASE = no_release
  if swap_entry ~= nil and swap_entry ~= character_reforged_cd.inst then
    pcall(HyperButtonChargeShow, false)                   -- the bar leaves the other plate
    character_reforged_cd.inst = swap_entry
    character_reforged_cd.swapped, character_reforged_cd.shown, character_reforged_cd.geo = false, nil, nil
  end
  if swap_entry == nil or not hyperButtonLast[character_reforged_cd.inst + 1].shown then
    swap_fraction = nil
  end
  local okc, errc = pcall(HyperButtonChargeBar, swap_fraction)
  if not okc then
    HyperButtonChargeLog("error", tostring(errc))
  end
  -- Keeps the placeholder boxes hidden between two draws (anything that re-shows the plate's meshes).
  for inst = 0, ENTRY_LAST do
    local last = hyperButtonLast[inst + 1]
    if last.shown then
      if last.hasFace and last.drawTick then
        local age = hyperButtonTick - last.drawTick
        for i = 1, #CharacterReforged.HYPER_BUTTON_FACE_RETRY do
          if age == CharacterReforged.HYPER_BUTTON_FACE_RETRY[i] then
            local okf, face = pcall(CharacterReforged.hyper_button_plate_face, HyperButtonLayer, inst, last.hdl, true, last.pover, last.skill)
            last.face = okf and face == true
          end
        end
      end
      pcall(HyperButtonHideDummies, HyperButtonLayer, inst, last.face)
      if character_reforged_cross.fit[inst + 1] ~= nil and last.drawTick ~= hyperButtonTick then
        pcall(HyperButtonNameFit, inst, last.face)
      end
    end
  end
  pcall(CharacterReforged.hyper_button_open_place)
end