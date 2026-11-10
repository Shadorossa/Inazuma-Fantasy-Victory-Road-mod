-- Skill table vrfw_skill_slot_menu

local HYPER_BUTTON_SLOT = 8                -- board slot of the Hiper row
local SPECIAL_TEAM_AURA = true
local SPECIAL_LABEL = ""            -- prefix of the special row (none, the row is purple instead)
-- the Hiper row's base is the mod's purple sprite (HYPER_BUTTON_TEXTURE below)
local GUIDE_TEXT = 2021430145 --[[skill_table_guide]]   -- bottom guide line (text id)
local BUTTON_TEXT = 276599986
local DESC_LINE_BYTES = 34

local ROW_NUM = 7               -- 1 special + 6 normal
local NORMAL_NUM = 6
local EVT_MENU = 2221030314           -- this menu
local PICK_MENU = 2897322950        -- the game's hissatsu list with tabs/filters/sort
-- Parameter-store handoff with the picker.
local KEY_PICK = 790447113          -- param: pick mode 1 normal / 2 special
local KEY_RESULT = 2321280994      -- param: chosen move id
local KEY_INV = 331123112            -- param: its invSkill handle
local KEY_USED = {621880403, 3155719657, 3407824255, 1434177756, 578609226, 3145052656}
local KEY_DEBUG_INIT = 1463482560       -- picker debug: mode it saw at OnInit
local KEY_DEBUG_ENTER = 1978530279     -- picker debug: layer of the last confirm callback
local KEY_DEBUG_CODE = 3864734764       -- picker debug: 3 rejected, 4 chosen, 9 Lua error
local KEY_DEBUG_BITS = 3833368827
local KEY_OPEN_BOARD = 3646488081   -- param: team dock must open the original board
local L_ROW = 4251697490      -- soccer11_08_equip_list_item (7 instances = 7 rows)
local L_BTN = 503674375       -- cmn03_07_cmn_button_equip ("Mejor equipamiento" -> original board)
local L_BASE = 3560167285
local L_INFO = 3239909435     -- team05_02_equip_info_easy (right info window)
local L_CURSOR = 2296367164   -- cmn05_01_cursor
-- Row base sprite.
local HYPER_BUTTON_TEXTURE = "#/menu/00_soccer/soccer11/cr_soccer11_08_hiper/cr_item_list_base_hiper01.g4tx"
local HYPER_BUTTON_TEXTURE_CRC = 3302332138
local HYPER_BUTTON_SPRITE = 2519790334      -- cr_item_list_base_hiper01
local ROW_TEXTURE = 1676671618
local ROW_BASE = 2417687399          -- item_list_base01 (retail white sprite = node of _item_list_base01)
local C = {
  GET_SKILL = 903078840,      -- 0x35D3E3B8 (charaStHdl, slot0..5) -> skill id (save skill_list)
  SET_SKILL = @crc:CMND_SET_SKILL@,
  REMOVE_SKILL = @crc:CMND_REMOVE_SKILL@,  -- 0xBBB97857 CMND_REMOVE_SKILL (charaStHdl, slot)
  LEARNABLE = 3475351727,
  CHARA_GET = 1131797651,     -- 0x4375DC93 (charaStHdl, 0 level | 4 chara id)
  SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@,
  NAME_TEXT = 720417636,      -- 0x2AF0B364 (name id) -> string
  DESC_TEXT = 4113915188,
  TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,          -- CMND_SET_MENU_TEXT_STRING (layer, node, string, idx)
  TEXT_ALPHA = @crc:CMND_SET_MENU_TEXT_ALPHA@,    -- CMND_SET_MENU_TEXT_ALPHA (layer, idx, node, alpha)
  MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@,  -- CMND_SET_MESH_VISIBLE (layer, mesh, bool, idx)
  ITEM_ICON = 3508889864,
  FOCUS_IDX = 2603265800,     -- (layer) -> focused instance
  CURSOR_LOC = @crc:CMND_SET_CURSOR_LOCATOR@,
  SE = @crc:CMND_SND_PLAY_SE@,
  MENU_ACTIVE = 1558704558,   -- (menu, bool) input on/off
  MENU_SUSPEND = 1129326309,
  MENU_RESUME = 1453710531,   -- (menu)
  LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@,
  OPEN_MENU = @crc:CMND_OPEN_MENU_OBJECT@,      -- CMND_OPEN_MENU_OBJECT (menu, group)
  EXIST_MENU = @crc:CMND_IS_EXIST_MENU_OBJECT@,    -- CMND_IS_EXIST_MENU_OBJECT (menu cmd)
  CLOSING_MENU = @crc:CMND_IS_CLOSING_MENU_OBJECT@,  -- CMND_IS_CLOSING_MENU_OBJECT 0x472111B3
  CLOSED_MENU = @crc:CMND_IS_CLOSE_MENU_OBJECT@,   -- CMND_IS_CLOSE_MENU_OBJECT 0x5AB5813A
  CLOSE_MENU = @crc:CMND_CLOSE_MENU_OBJECT@,     -- CMND_CLOSE_MENU_OBJECT
  MSG_OPEN = 2289627655,                                                               -- general (system) window
  -- ability board
  BOARD_INV = 632801955,
  INV_ITEM = 2662166687,      -- 0x9EAD709F (invHdl, 0) -> item (= move) id
  BOARD_PIECES = 1535890305,
  BOARD_EQUIP = 203046535,
  SKILL_POS = 26437624,
  -- Team aura slots (retail equip_aura_skill_menu).
  TEAM_INFO = @crc:CMND_GET_TEAM_SET_INFO@,
  TEAM_AURA_SET = @crc:CMND_SET_TEAM_SET_INFO@, -- 0x59CAEAD5 (dockNo, dockType, 6, slot, charaStHdl, skillId)
  -- The skill board's writes.
  BOARD_PLACE = @crc:CMND_CHARACTERREFORGED_BOARD_PLACE@,
  BOARD_CLEAR = @crc:CMND_CHARACTERREFORGED_BOARD_CLEAR@,
  LOG = @crc:CMND_VRFW_LOG@,                  -- (...) -> writes to vrfw_loader\loader.log
  BOARD_PIECE = @crc:CMND_CHARACTERREFORGED_BOARD_PIECE@,
  ADD_ITEM = @crc:CMND_ADD_ITEM_ONLY@,
  DEL_ITEM = @crc:CMND_DELETE_ITEM@,
  ITEM_NUM = @crc:CMND_GET_ITEM_NUM@,      -- CMND_GET_ITEM_NUM (itemId) -> copies owned
  EQUIPPED_NUM = 556568075,                -- (invHdl) -> copies equipped
  -- Menu textures (save-slot menu and kizuna_town_menu_inc).
  SPRITE = 558735651,         -- (layer, textureCrc, spriteCrc, nodeCrc, 0, idx)
  LOAD_TEX = @crc:CMND_LOAD_MENU_RES_TEXTURE@,       -- CMND_LOAD_MENU_RES_TEXTURE (path)
  TEX_LOADING = 1506186496,   -- (textureCrc) -> true while still loading
}
local SE_OK, SE_DECIDE, SE_BACK, SE_NG, SE_REMOVE = 3848881948, 4235359837, 202039849, 2086672038, 2339718859

local PL = {
  AURA_CLEAR_NATIVE = 2,          -- keepOpen 2 of the board clear command: an aura's placed item goes off and its slot stays open
  LOCK_TEX = "#/menu/00_soccer/soccer11/cr_soccer11_08_lock/cr_item_list_base_lock01.g4tx",
  LOCK_TEX_CRC = 2527340925,
  LOCK_SPRITE = 3751509889,       -- cr_item_list_base_lock01
  TEX_S11_20 = 4021797290,        -- #/menu/00_soccer/soccer11/soccer11_20/soccer11_20.g4tx
  ICON_LOCK = 1502905245,         -- icon_lock_passive01 (36 x 40 grey lock)
  ICON_EQUIP_NODE = 2346103015,   -- icon_equip01 (texture slot of the mesh _icon_equip01)
  LOCK_COLOR = "[CGRAYOUT04]",    -- font_color GRAYOUT04 (light grey, readable on the navy base)
  IDOL_GUIDE = 2800973629 --[[skill_table_idol_guide]],
  lock_tex = 0,                   -- 0 not requested, 1 loading, 2 ready
  lock_pending = {},              -- rows waiting for the texture
  prime = {hdl = -1},
  -- Move panel parts and clean lock.
  PARTS_TEX = 2283256341,
  BAND = {583760226, 3150063832, 3435468878, 1386319341, 631684475, 3165646017},
  WLV = {[2861188530] = 3598379871, [864228360] = 1332984549, [1149510814] = 947161715},
  LOCK_LIGHT = 1290944817,
  LOCK_DARK = 3465246201,
  -- ability_list_menu filter / tab parameter keys (bluebg OnInit t3 + 773844157 start tab)
  LIST_KEYS = {1498333934, 3225916244, 3074466754, 690239073, 1579353847, 3341440845, 2552568759, 19679757, 773844157},
}

local vrfw_co = nil
local character_reforged_back_frames = -1
character_reforged_back_seen = false
local character_reforged_hiper_tex = 0          -- purple base texture: 0 not requested, 1 loading, 2 ready
local character_reforged_hiper_pending = false  -- row 0 still waits for it (applied from Step)
local character_reforged_shown = nil               -- player whose layout/mirror ran last (charaStHdl)
local character_reforged_layout_done = {}       -- players whose layout the loader checked during this visit

-- Request the purple base texture once
local function HyperTexReady()
  if character_reforged_hiper_tex == 0 then
    funcLuaMenuCommand(C.LOAD_TEX, HYPER_BUTTON_TEXTURE)
    character_reforged_hiper_tex = 1
  end
  if character_reforged_hiper_tex == 1 and not funcLuaCommand(C.TEX_LOADING, HYPER_BUTTON_TEXTURE_CRC) then
    character_reforged_hiper_tex = 2
  end
  return character_reforged_hiper_tex == 2
end

function PL.lock_tex_ready()
  if PL.lock_tex == 0 then
    funcLuaMenuCommand(C.LOAD_TEX, PL.LOCK_TEX)
    PL.lock_tex = 1
  end
  if PL.lock_tex == 1 and not funcLuaCommand(C.TEX_LOADING, PL.LOCK_TEX_CRC) then
    PL.lock_tex = 2
  end
  return PL.lock_tex == 2
end

-- Sets the row base.
local function SetRowBase(a1, locked)
  if locked then
    if PL.lock_tex_ready() then
      funcLuaMenuCommand(C.SPRITE, L_ROW, PL.LOCK_TEX_CRC, PL.LOCK_SPRITE, ROW_BASE, 0, a1)
      PL.lock_pending[a1] = nil
    else
      PL.lock_pending[a1] = true
    end
    return
  end
  PL.lock_pending[a1] = nil
  if a1 == 0 then
    if HyperTexReady() then
      funcLuaMenuCommand(C.SPRITE, L_ROW, HYPER_BUTTON_TEXTURE_CRC, HYPER_BUTTON_SPRITE, ROW_BASE, 0, 0)
      character_reforged_hiper_pending = false
    else
      character_reforged_hiper_pending = true
    end
  else
    funcLuaMenuCommand(C.SPRITE, L_ROW, ROW_TEXTURE, ROW_BASE, ROW_BASE, 0, a1)
  end
end

local RetailOnInit = OnInit
function OnInit()
  RetailOnInit()
  HyperTexReady()   -- start loading early; the rows are set up later
  PL.lock_tex_ready()
end

local function P_Set(key, v)
  VRFW.param.clear(key)
  VRFW.param.set(key, v)
end

-- Ids are unsigned 32-bit.
local function to_u32(id)
  return VRFW.ids.unsigned(id)
end

local function IsSpecial(skill)
  return CharacterReforged.player_sets.is_special(skill)
end

local function Call(cmd, ...)
  local ok, a, b, c, d = pcall(funcLuaCommand, cmd, ...)
  if not ok then
    return nil
  end
  return a, b, c, d
end

-- Capability checks of the services an action uses (an undeclared command answers a single false).
PL.SERVICE_PROBE = {six_sense = {@crc:CMND_CHARACTERREFORGED_SIX_SENSE@, 0, 0, 0, -1},
  player_sets = {@crc:CMND_CHARACTERREFORGED_PLAYER_SET_GET@, 0, 0}}
PL.service_logged = {}
PL.service_present = {}
function PL.has_service(name)
  if PL.service_present[name] ~= nil then
    return PL.service_present[name]
  end
  local probe = PL.SERVICE_PROBE[name]
  local answer, second = nil, nil
  if probe ~= nil then
    local okp
    okp, answer, second = pcall(funcLuaCommand, table.unpack(probe))
    if not okp then
      answer, second = nil, nil
    end
  end
  local present = type(answer) == "number" or second ~= nil   -- PLAYER_SET_GET(0, 0) answers false, ""
  if not present and not PL.service_logged[name] then
    PL.service_logged[name] = true
    Call(C.LOG, "skill_slots", "loader check", name, "service missing")
  end
  PL.service_present[name] = present
  return present
end

-- Row r is list position r - 1, always, with that position's level lock (positions 5-6 have none).
function PL.proj_pos(row)
  return row - 1
end
function PL.is_special_cached(id)
  return CharacterReforged.player_sets.is_special_cached(id)
end
-- the move on board cell `p` (placed item, else native), 0 for none
function PL.board_move_at(p)
  return CharacterReforged.player_sets.board_move_at(n, p)
end
-- Returns the move an empty position `p` (0-5) takes.
function PL.fill_move_at(p)
  return CharacterReforged.player_sets.fill_move_at(n, p)
end
-- Returns the technique that board cell `p` adds to the rows, 0 for none.
function PL.board_technique_at(p)
  return CharacterReforged.player_sets.board_technique_at(n, p)
end

-- Maps a row to a board skill slot.
local function BoardSlot(row)
  if row == 0 then
    return HYPER_BUTTON_SLOT
  end
  return PL.proj_pos(row)
end

local function ListPos(row)
  if row == 0 then
    return nil
  end
  return PL.proj_pos(row)
end

local function BoardSkill(bslot)
  return CharacterReforged.player_sets.board_skill(n, bslot)
end

local function ListSkill(pos)
  return CharacterReforged.player_sets.list_skill(n, pos)
end

-- the team and screen state the shared set write path reads (one table, refreshed per call)
PL.ctx = {}
function PL.set_ctx()
  local c = PL.ctx
  c.dock, c.kind, c.readonly, c.hs_half = n3, n17, PL.readonly, PL.hs_half
  c.se = PL.ctx_se
  c.after_change = CharacterReforged.skill_table_after_change
  return c
end
function PL.ctx_se(id)
  funcLuaCommand(C.SE, id)
end

-- Prime card of the shown player (cached per player)
function CharacterReforgedSkillTablePrimeInfo()
  if PL.prime.hdl == n then
    return PL.prime
  end
  PL.prime = {hdl = n, on = CharacterReforged.player_sets.is_prime(n)}
  if PL.prime.on then
    Call(C.LOG, "skill_slots", "prime", n)
  end
  return PL.prime
end

function CharacterReforged.skill_table_is_prime()
  return CharacterReforgedSkillTablePrimeInfo().on
end

-- Returns the skill of the Hiper row.
local function Skill(row)
  return CharacterReforged.player_sets.skill(n, row, PL.set_ctx())
end

-- Reads the shown player's learnset (see PL above).
function PL.read_learnset()
  return CharacterReforged.player_sets.read_learnset(n)
end

-- Returns whether the card is a custom Idol card.
function PL.is_idol()
  return CharacterReforged.player_sets.is_idol(n)
end

-- Returns the learnset slot of a row.
function PL.row_slot(row)
  return CharacterReforged.player_sets.row_slot(row)
end

-- The move a row shows
function PL.row_move(row)
  local s = Skill(row)
  if s ~= 0 then
    return s
  end
  local ls = PL.read_learnset()
  local m = ls.skill[PL.row_slot(row)] or 0
  if row == 0 then
    return (PL.is_idol() and IsSpecial(m)) and m or 0
  end
  local locked = CharacterReforged.skill_table_is_locked(row)
  -- A move the match list already holds is not learned again at this row, so the row names no move.
  return (locked and not CharacterReforged.player_sets.active(n, m)) and m or 0
end

-- Applies the Idol rule.
function PL.idol_fixed(row)
  return CharacterReforged.player_sets.idol_fixed(n, row)
end

-- true when the move is in the match list (save skill_list)
local function Active(skill)
  return CharacterReforged.player_sets.active(n, skill)
end

local function Name(skill)
  return CharacterReforged.player_sets.name(skill)
end

-- Level at which a row unlocks
function CharacterReforged.skill_table_unlock_level(row)
  return CharacterReforged.player_sets.unlock_level(n, row)
end

function CharacterReforged.skill_table_is_locked(row)
  return CharacterReforged.player_sets.is_locked(n, row)
end

function CreateEquipTypeTable()
  t = {0, 0, 0, 0, 0, 0, 0}
end
function GetEquipTypeNum()
  return ROW_NUM
end
function GetEquipType(a1)
  if a1 == nil or a1 < 0 or a1 >= ROW_NUM then
    return -1
  end
  return 0
end
function GetEquipListItemInfo(a1)
  return t3[a1] or t3[0]
end
function GetEquipItemIdByLayerIdx(a1)
  return Skill(a1)
end
function UpdateEquippedVisibleCheck(a1)
end

-- Draws one row.
function UpdateEquipListItem(a1)
  if a1 == nil or a1 < 0 or a1 >= ROW_NUM then
    return
  end
  if a1 == 0 then
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, true)
    -- Runs once per shown player (row 0 is drawn first on open or L-R change).
    if character_reforged_shown ~= n and n ~= nil and n ~= 0 then
      character_reforged_shown = n
      PL.prime = {hdl = -1}             -- re-read the Prime data
      CharacterReforged.player_sets.forget()
    end
  end
  local info = GetEquipListItemInfo(GetEquipType(a1))
  local icon_tex = 1875672568 --[[icon_item_dmy01: retail uses it for every row skin, incl. the outfit one]]
  funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, 3515732558 --[[_icon_equip01]], false, a1)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, 3830297508 --[[_gtxt_item01]], false, a1)
  local locked, need = CharacterReforged.skill_table_is_locked(a1)
  local skill = PL.row_move(a1)          -- a locked row shows the move it will learn (name + icon)
  local text
  if locked then
    -- Writes the "off" row text.
    text = PL.LOCK_COLOR .. string.format("Nv. %d", need)
    if skill ~= 0 then
      text = text .. "   " .. Name(skill)
    end
    text = text .. "[C]"
  elseif skill ~= 0 then
    text = Name(skill)
    if a1 > 0 and not Active(skill) then
      text = PL.LOCK_COLOR .. text .. "[C]"
    end
  else
    text = ""                                     -- an empty row: the plate alone
  end
  if a1 == 0 and SPECIAL_LABEL ~= "" then
    text = SPECIAL_LABEL .. "   " .. text
  end
  funcLuaMenuCommand(C.TEXT, L_ROW, info.itemTextName, text, a1)
  funcLuaMenuCommand(C.TEXT_ALPHA, L_ROW, a1, info.itemTextName, 1)
  -- Draws the Hiper row.
  SetRowBase(a1, locked)
  -- Shows the lock icon on the row's left icon node (retail equip-type icon, unused here).
  local lock_icon = locked or PL.idol_fixed(a1)
  if lock_icon then
    -- the mod's clean 48 x 52 lock sprite
    local spr = (locked or a1 == 0) and PL.LOCK_LIGHT or PL.LOCK_DARK
    funcLuaMenuCommand(C.SPRITE, L_ROW, PL.PARTS_TEX, spr, PL.ICON_EQUIP_NODE, 0, a1)
  end
  -- Rows 1-6 are move plates (PL.row_plate on layer character_reforged_ss_row_plate).
  local on = false
  if a1 > 0 and PL.row_plate ~= nil then
    local inactive = skill ~= 0 and not locked and not Active(skill)
    local okp, r = pcall(PL.row_plate, a1, skill, locked, need, lock_icon and not locked, inactive)
    if not okp then
      pcall(Call, C.LOG, "skill_slots", "row plate error", a1, tostring(r))
    end
    on = okp and r == true
    funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, PL.RP.ROW_BASE, not on, a1)
    funcLuaMenuCommand(2735666188 --[[text visible]], L_ROW, info.itemTextName, not on, a1)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, 3515732558 --[[_icon_equip01]], lock_icon and not on, a1)
  if skill ~= 0 and not on and not (a1 == 0 and not locked) then
    funcLuaMenuCommand(C.ITEM_ICON, L_ROW, a1, info.itemIconMeshName, icon_tex, skill)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, info.itemIconMeshName, true, a1)
  else
    funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, info.itemIconMeshName, false, a1)
  end
end

local function RefreshRows()
  for i = 0, ROW_NUM - 1 do
    UpdateEquipListItem(i)
  end
end

-- Cut a UTF-8 string to at most n bytes without splitting a character.
local function Cut(s, n)
  if #s <= n then
    return s
  end
  local k = n
  while k > 0 do
    local b = string.byte(s, k + 1)
    if b == nil or b < 128 or b >= 192 then
      break
    end
    k = k - 1
  end
  return string.sub(s, 1, k) .. "…"
end

function CharacterReforged.skill_table_info_text(skill)
  local okp, power = funcLuaCommand(C.SKILL_INFO, skill, 6)
  if okp and type(power) == "number" and power > 0 then
    return PL.txt(3124093148 --[[skill_table_move_power]], power)
  end
  return ""
end

-- Right info window (the accessory "info easy" window)
local function SetupSkillInfo(skill)
  funcLuaMenuCommand(C.ITEM_ICON, L_INFO, 0, 303536660 --[[_icon_item_dmy01]], 1875672568 --[[icon_item_dmy01]], skill)
  funcLuaMenuCommand(C.ITEM_ICON, L_INFO, 0, 2334051246 --[[_icon_item_dmy02]], 4140117058 --[[icon_item_dmy02]], skill)
  funcLuaMenuCommand(C.TEXT, L_INFO, 456522680 --[[_text_item01]], Name(skill), 0)
  funcLuaMenuCommand(C.TEXT, L_INFO, 3138144965 --[[_text_parameter01]], CharacterReforged.skill_table_info_text(skill), 0)
  SetVisibleEquipmentNum(L_INFO, 0, false)
  SetVisibleStockNum(L_INFO, 0, false)
  funcLuaMenuCommand(1233047821, L_INFO, 0, 3974820126, false)
  funcLuaMenuCommand(1233047821, L_INFO, 0, 3334923667 --[[num_have01]], false)
  -- Handles special moves.
  local aura_chara = 0
  if IsSpecial(skill) then
    local ok, cid = funcLuaCommand(C.SKILL_INFO, skill, 17)
    if ok and cid ~= nil then
      aura_chara = cid
    end
  end
  if aura_chara ~= 0 then
    -- Keshin, armour and totem characters have no list face icon.
    pcall(funcLuaMenuCommand, 4176779611 --[[ResetFaceIcon]], L_INFO, 0, 2052777044 --[[item_chr_dmy01]])
    local okd, drawn = pcall(PL.aura_portrait, L_INFO, 0, 2787359195 --[[_item_chr_dmy01]], 2052777044, skill)
    aura_chara = (okd and drawn) and aura_chara or 0
  end
  if aura_chara ~= 0 then
    funcLuaMenuCommand(C.MESH_VISIBLE, L_INFO, 2634282032 --[[_item_chr_base01]], true, 0)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_INFO, 2787359195 --[[_item_chr_dmy01]], true, 0)
  else
    funcLuaMenuCommand(C.MESH_VISIBLE, L_INFO, 2634282032 --[[_item_chr_base01]], false, 0)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_INFO, 2787359195 --[[_item_chr_dmy01]], false, 0)
  end
  ClearItemPositionIcon(L_INFO, 0)
end

local L_DETAIL = 2628045944      -- team02_02_skill_detail_info
local L_DETAIL_LV = 3654556750   -- team13_26b_open_level_lock
local Detail = true
local DETAIL_LEVEL_TAB = true
local DETAIL_HIDE_GRAPH = false
local DETAIL_LEVEL_NUMS = {2772869257, 4268123864}   -- team13_26b number settings (MenuNumberSettingName)
local GRAPH_LAYERS = {{2334590304, 1}, {32151736, 1}, {732343773, 7},   -- soccer11_07 radar, its base, 7 numbers
  {3665300474, 1}}                                 -- soccer11_16 rpg attack / defence param (the dark stat box)
local character_reforged_detail_on = false


PL.L_SET_PREVIEW_BASE = 3701978455             -- cr_psp_base (graft pset_preview)
function CharacterReforged.player_page_skill_table_radar_wanted()
  local parts = type(CharacterReforged) == "table" and CharacterReforged.parts or nil
  local training = type(parts) == "table" and parts.training_mode or nil
  if type(training) == "table" and training.on == true then
    return true
  end
  local L = PL.L_SET_PREVIEW_BASE
  return funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) == true
    and funcLuaMenuCommand(@crc:CMND_IS_LAYER_VISIBLE@, L, 0) == true
end

function CharacterReforged.skill_table_detail_graph_sync()
  -- The Hiper panel spans the page to x 1890, over the stat radar.
  local hide = (DETAIL_HIDE_GRAPH and character_reforged_detail_on) or PL.hiper_wide == true or not CharacterReforged.player_page_skill_table_radar_wanted()
  if not DETAIL_HIDE_GRAPH and PL.graph_hidden ~= true and not hide then
    return
  end
  -- Hiding remembers each instance's visibility (CMND_IS_LAYER_VISIBLE) and showing restores it.
  if hide and PL.graph_hidden ~= true then
    PL.graph_prev = {}
    for _, g in ipairs(GRAPH_LAYERS) do
      for i = 0, g[2] - 1 do
        PL.graph_prev[g[1] * 16 + i] = funcLuaMenuCommand(@crc:CMND_IS_LAYER_VISIBLE@, g[1], i) ~= false
      end
    end
  end
  for _, g in ipairs(GRAPH_LAYERS) do
    for i = 0, g[2] - 1 do
      local back = PL.graph_prev == nil or PL.graph_prev[g[1] * 16 + i] ~= false
      funcLuaMenuCommand(C.LAYER_VISIBLE, g[1], i, (not hide) and back)
    end
  end
  -- the grey page base _sixth_base01 of soccer11_05 is never shown (the player page's white card replaces it)
  funcLuaMenuCommand(C.MESH_VISIBLE, 2917320188 --[[soccer11_05_equip_status_base]], 2682382918 --[[_sixth_base01]],
    false, 0)
  PL.sixth_hidden = true
  PL.graph_hidden = hide
end

function CharacterReforged.skill_table_detail_hide()
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_DETAIL, 0, false)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_DETAIL_LV, 0, false)
  if PL.detail_hide_all ~= nil then
    pcall(PL.detail_hide_all)                       -- the passive window and the Hiper panel too
  end
  character_reforged_detail_on = false
end

local function DetailLevelTab(row)
  if not DETAIL_LEVEL_TAB or row == nil then
    return false
  end
  local locked, need = CharacterReforged.skill_table_is_locked(row)
  if need == nil or need <= 1 then
    return false
  end
  funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL_LV, 1517329426 --[[_pos_base01]], locked, 0)
  funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL_LV, 3279539624 --[[_pos_base02]], not locked, 0)
  funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL_LV, 3335603165 --[[_pos_num01]], true, 0)
  for _, num in ipairs(DETAIL_LEVEL_NUMS) do
    local idx = funcLuaMenuCommand(@crc:CMND_SEARCH_PRIM_INDEX@, L_DETAIL_LV, 0, num)
    if type(idx) == "number" and idx >= 0 then
      funcLuaMenuCommand(3609943765 --[[set number]], L_DETAIL_LV, 0, idx, need)
      funcLuaMenuCommand(1233047821 --[[number visible]], L_DETAIL_LV, 0, num, true)
    end
    -- The badge of a row is logged once per level: a number that is not found keeps the layout's placeholder digits.
    if PL.detail_level_logged ~= need * 8 + row then
      pcall(Call, C.LOG, "skill_slots", "detail level badge", row, "level", need, "locked", tostring(locked), "number", num, "index", tostring(idx))
    end
  end
  PL.detail_level_logged = need * 8 + row
  return true
end

-- Fill and show the panel for `skill` on `row`
PL.TYPE_TAG_MESH, PL.TYPE_TAG_TEXT, PL.TYPE_TAG_POS = 3516146179 --[[_area_base01]], 1899787537 --[[_text_area01]],
  2313134961 --[[_pos_area01]]
function PL.type_tag_off()
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, PL.TYPE_TAG_MESH, false, 0)
  funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, PL.TYPE_TAG_TEXT, false, 0)
  funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL, PL.TYPE_TAG_POS, false, 0)
end

function PL.detail_polish(skill, pos)
  local ok, kind = funcLuaCommand(C.SKILL_INFO, skill, 7)
  if ok and kind == 5 then
    local ok2, common = funcLuaCommand(800895612, skill)
    if ok2 and common then
      kind = 6
    end
  end
  if ok and PL.BAND[kind] ~= nil then
    funcLuaMenuCommand(C.SPRITE, L_DETAIL, PL.PARTS_TEX, PL.BAND[kind], 243934124 --[[sp_base01]], 0, 0)
  end
  if pos ~= nil then
    local okw, wl = pcall(function()
      return GetPersonalPlateSkillEvoBaseTextureName(GetSkillEvoLevelByCharaStHdl(n, pos))
    end)
    if okw and PL.WLV[wl] ~= nil then
      funcLuaMenuCommand(C.SPRITE, L_DETAIL, PL.PARTS_TEX, PL.WLV[wl], 2861188530 --[[wlv_base01]], 0, 0)
    end
  end
  PL.type_tag_off()
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 2164615260 --[[_icon_sp_area_dmy01]], false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 3543352325 --[[_icon_sp_area01_off]], false, 0)
  funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, 691026122 --[[_text_flavor01]], false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, CALC_CRC("_item_win_line01"), false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 3303013605 --[[_sp_win_base01]], false, 0)
end

-- Shows a custom passive in the same panel (see PL.passive_detail).
PL.DETAIL_MOVE_POS = {2313134961 --[[_pos_area01]], 923022909 --[[_pos_tension01]], 4081284803 --[[_pos_at01]]}
PL.DETAIL_MOVE_MESH = {563708378 --[[_gtxt_cmd_at01]], 1013569271 --[[_ai_use01]], 3384915402 --[[_wlv_base01]],
  559600405 --[[_icon_sp_sub_dmy01]], 1220252763 --[[_gtxt_longshoot01]], 1252573939 --[[_gtxt_override01]],
  2164615260 --[[_icon_sp_area_dmy01]], 3543352325 --[[_icon_sp_area01_off]], 3303013605 --[[_sp_win_base01]],
  3516146179 --[[_area_base01]]}
PL.DETAIL_MOVE_TEXT = {1899787537 --[[_text_area01]]}
PL.DETAIL_MOVE_PRIM = {2223127589 --[[AT power]], 3424269865 --[[tension cost]]}
function PL.detail_restore()
  for _, m in ipairs(PL.MOVE_ROW_HIDE_MESH or {}) do      -- PL.move_as_row hid them on the last move
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, m, true, 0)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 3303013605 --[[_sp_win_base01: off]], false, 0)
  for _, pos in ipairs(PL.DETAIL_MOVE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL, pos, true, 0)
  end
  for _, t in ipairs(PL.DETAIL_MOVE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, t, true, 0)
  end
end

PL.L_PV_DETAIL = 1593383077                      -- team00_26_passive_slot_detail_info
PL.L_PV_BUILD = 1308983228                       -- team00_25_p1_build_name (2 plates, attached by the window)
PL.L_HIPER = 1928252705           -- the Hiper panel (team02_02 clone, ss2_build 8c)
PL.L_HROW = 1981802733                -- the spirit's move row (shared objbin of the plate Hiper page)
PL.BANDS_TEX = 1083407727
PL.PV_BAND = {[3317336303 --[[sixth_base01]]] = 520419153,
  [893157544 --[[sixth_base01_blank]]] = 332205308}
PL.DETAIL_PRIO = {[1593383077 --[[team00_26 passive window]]] = 656, [1308983228 --[[team00_25 build plates]]] = 657,
  [1928252705] = 657, [1981802733] = 658,
  [2651268807] = 656, [395833588] = 656, [3679282495] = 656, [576015315] = 656, [3635526425] = 656, [1305553269] = 656,
  [3131422953] = 656, [1281343292] = 656}
function PL.open(L, idx)
  idx = idx or 0
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L)
      and not funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, L, idx) then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, L, idx)
  end
end

function PL.detail_hide_all()
  PL.hiper_wide = false
  if PL.set_detail_layout ~= nil then
    pcall(PL.set_detail_layout, nil)                -- back to the layout's own positions (passive windows, card)
  end
  local all = {L_DETAIL, L_DETAIL_LV, PL.L_PV_DETAIL, PL.L_HIPER, PL.L_HROW, 1281343292}
  for _, A in pairs(PL.AURA_LAYER or {}) do
    all[#all + 1] = A
  end
  for _, L in ipairs(all) do
    if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
      funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, false)
    end
  end
  for i = 0, 1 do
    funcLuaMenuCommand(C.LAYER_VISIBLE, PL.L_PV_BUILD, i, false)
    funcLuaMenuCommand(C.LAYER_VISIBLE, PL.L_HROW, i, false)
  end
  PL.pool_peg = nil                               -- the aura pool gauge (PL.pool_gauge)
  if PL.POOL ~= nil and funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, PL.L_HIPER) then
    funcLuaMenuCommand(C.LAYER_VISIBLE, PL.L_HIPER, PL.POOL.INST, false)
  end
  pcall(CharacterReforged.skill_table_detail_graph_sync)
end

-- Compact detail layout.
PL.LAYOUT_NODE_POS = 2575768773                  -- CMND set node translation (layer, idx, node, axis, value; y up)
PL.LAYOUT_LOCS = {                               -- L_BASE locators: {node, default x, y, compact x, y[, move x, y]}
  {@crc:_pos_cr_detail01@, 1235, -735, 1235, -838, 1235, -794},
  {@crc:_pos_cr_detail_lv01@, 1485, -949, 1279, -840, 1279, -796}}
PL.LAYOUT_LV_SCALE = 36 / 52
PL.LAYOUT_MOVE_NODES = {                         -- L_DETAIL (character_reforged_team02_02_detail joints, relative to the locator)
  {559600405 --[[_icon_sp_sub_dmy01]], -261, 230, -242, 146},
  {1220252763 --[[_gtxt_longshoot01]], -211, 229, -192, 145},
  {1252573939 --[[_gtxt_override01]], -78, 240, -59, 156},
  {1013569271 --[[_ai_use01]], -248, -196, -233, 16}}
-- ONE card for every state, 985..1920 x 640..880 (1080p)
PL.CARD_ONE = {985, 640, 1920, 880}
PL.LAYOUT_CARD = {move = PL.CARD_ONE, empty = PL.CARD_ONE, aura = PL.CARD_ONE, training = PL.CARD_ONE}
PL.LAYOUT_AURA_DY = -20       -- 8 px lower, 658..746
-- Training view.
PL.LAYOUT_TRN_NODES = {
  {1125548721 --[[_sp_base01]], -275, 200, 525, 128, -250, 188, 930, 88},
  {3384915402 --[[_wlv_base01]], -275, 200, 525, 128, -250, 188, 930, 88},
  {2164615260 --[[_icon_sp_area_dmy01]], 78, 214, 170, 170, -240, 176, 64, 64},
  {1704438437 --[[_text_name01]], -261, 176, 497, 36, -164, 162, 600, 36}}
PL.LAYOUT_TRN_PANEL = 3417105372               -- cr_trn_panel
PL.LAYOUT_TRN_CELLS = {{1535596773 --[[_atc_trncell00]], 1135, -826, 1080, -795},
  {746612851 --[[_atc_trncell01]], 1355, -826, 1250, -795}}
PL.LAYOUT_CARD_TRAINING = true
-- The plain panel (PL.panel_plain with opts.banner) uses the training view's banner and the description right.
PL.LAYOUT_PLAIN_FLAVOR = {691026122 --[[_text_flavor01]], -335, 96, 911, 112}
-- The role panel's own compact card.
PL.CARD_PLAIN = PL.CARD_ONE                      -- the screen's one card, full width
PL.LAYOUT_CARD.plain = PL.CARD_PLAIN
PL.PLAIN = {pad = 12, icon = 64, gap = 10, name_x = -261, loc_y = 846, band_y = 196, band_h = 88, icon_y = 184,
  inset = 5, line_units = 64, lines = 3, quote_line = CALC_CRC("_item_win_line01")}
-- Moves every aura window (and character_reforged_ss_aura2) right by its _pos_base01 so the banner's left edge is the card's.
PL.LAYOUT_AURA_DX = 25
PL.LAYOUT_BASE_NODE = 1517329426
PL.LAYOUT_AURA2_Y = -205                         -- cr_team00_30_aura2's own _pos_base01 y (under the move row)
-- The custom passive's window (PL.L_PV_DETAIL, character_reforged_team00_26_detail) inside the one card.
PL.LAYOUT_PV = {dx = 25, dy = -12, flavor = 691026122 --[[_text_flavor01]], flavor_w = 650, flavor_h = 96,
  flavor_h_compact = 96, builds = {3683526994 --[[_pos_atc_build01]], 1116174568 --[[_pos_atc_build02]]},
  build_x = {-248, -86}, build_y = -150, build_x_compact = {270, 432}, build_y_compact = 80}
-- The layer (content/menus/skill_table.toml, character_reforged_team00_26_detail joints = ss2_build.py T26_JOINTS) holds the custom passive card rect.
PL.LAYOUT_CARD.passive_custom = {985, 640, 1920, 835}
PL.LAYOUT_PV.name = 1704438437 --[[_text_name01]]
PL.layout_mode = nil
PL.LAYOUT_FRAMES = 60
PL.layout_frames = 0

function PL.layout_loc(i)
  local l = PL.LAYOUT_LOCS[i]
  if l == nil then
    return nil
  end
  local mode = PL.layout_mode or nil
  if mode == "move" and l[6] ~= nil then
    return l[6], l[7]
  elseif mode ~= nil then
    return l[4], l[5]
  end
  return l[2], l[3]
end

function PL.apply_detail_layout()
  local mode = PL.layout_mode or nil
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_BASE) then
    for i, l in ipairs(PL.LAYOUT_LOCS) do
      local x, y = PL.layout_loc(i)
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_BASE, 0, l[1], 0, x)
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_BASE, 0, l[1], 1, y)
    end
  end
  local mv = mode == "move"
  local tr = mode == "training"
  local PP = PL.PLAIN
  local plx = PL.CARD_PLAIN[1] + PP.pad + PP.icon + PP.gap - PP.name_x      -- locator x that puts the name right of the icon
  if mode == "plain" and PL.LAYOUT_LOCS[1] ~= nil and funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_BASE) then
    funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_BASE, 0, PL.LAYOUT_LOCS[1][1], 0, plx)
    funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_BASE, 0, PL.LAYOUT_LOCS[1][1], 1, -PP.loc_y)
  end
  local banner = tr or mode == "plain"            -- the band as the card's banner, the icon 64 px on its left
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_DETAIL) then
    for _, j in ipairs(PL.LAYOUT_TRN_NODES) do
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, j[1], 0, banner and j[6] or j[2])
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, j[1], 1, banner and j[7] or j[3])
      funcLuaMenuCommand(2885415772 --[[node scale]], L_DETAIL, 0, j[1], banner and j[8] or j[4], banner and j[9] or j[5])
    end
    local f = PL.LAYOUT_PLAIN_FLAVOR
    funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, f[1], 0, f[2])         -- the description keeps its retail rect
    funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, f[1], 1, f[3])
    funcLuaMenuCommand(2885415772 --[[node scale]], L_DETAIL, 0, f[1], f[4], f[5])
    if mode == "plain" then
      local x0, x1 = PL.CARD_PLAIN[1], PL.CARD_PLAIN[3]
      for _, band in ipairs({1125548721 --[[_sp_base01]], 3384915402 --[[_wlv_base01]]}) do
        funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, band, 0, x0 - plx)
        funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, band, 1, PP.band_y)
        funcLuaMenuCommand(2885415772 --[[node scale]], L_DETAIL, 0, band, x1 - x0 - PP.inset, PP.band_h)
      end
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, 2164615260 --[[_icon_sp_area_dmy01]], 0, x0 + PP.pad - plx)
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, 2164615260, 1, PP.icon_y)
      funcLuaMenuCommand(2885415772 --[[node scale]], L_DETAIL, 0, 2164615260, PP.icon, PP.icon)
      funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, PP.quote_line, false, 0)    -- the retail grey quote bar
    end
  end
  -- the left column's dark backing (L_BASE _list_base01) stays behind the training stat rows as on the move rows
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, PL.LAYOUT_TRN_PANEL) then
    for _, c in ipairs(PL.LAYOUT_TRN_CELLS) do
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, PL.LAYOUT_TRN_PANEL, 0, c[1], 0, tr and c[4] or c[2])
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, PL.LAYOUT_TRN_PANEL, 0, c[1], 1, tr and c[5] or c[3])
    end
  end
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_DETAIL_LV) then
    local k = mv and PL.LAYOUT_LV_SCALE or 1
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, L_DETAIL_LV, k, k, 1, 0)
  end
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_DETAIL) then
    for _, j in ipairs(PL.LAYOUT_MOVE_NODES) do
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, j[1], 0, mv and j[4] or j[2])
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, L_DETAIL, 0, j[1], 1, mv and j[5] or j[3])
    end
  end
  local au = mode == "aura" or mode == "mx"
  local wins = {PL.L_AURA2}
  for _, A in pairs(PL.AURA_LAYER or {}) do
    wins[#wins + 1] = A
  end
  for _, A in ipairs(wins) do
    if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, A) then
      local y = 0
      if A == PL.L_AURA2 then
        y = PL.LAYOUT_AURA2_Y
      elseif au then
        y = PL.LAYOUT_AURA_DY
      end
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, A, 0, PL.LAYOUT_BASE_NODE, 0, au and PL.LAYOUT_AURA_DX or 0)
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, A, 0, PL.LAYOUT_BASE_NODE, 1, y)
    end
  end
  -- Handles an aura with a PEG or SP pool.
  if PL.POOL ~= nil and funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, PL.L_HIPER) then
    local P = PL.POOL
    local pool = au and PL.pool_peg ~= nil
    for _, g in ipairs({{0, pool and P.MOVE_X or P.X, pool and P.K or 1}, {P.INST, P.POOL_X, P.K}}) do
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, PL.L_HIPER, g[1], P.NODE, 0, g[2])
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, PL.L_HIPER, g[1], P.NODE, 1, P.Y)
      funcLuaMenuCommand(2885415772 --[[node scale]], PL.L_HIPER, g[1], P.NODE, g[3], g[3])
    end
  end
  local pv = PL.LAYOUT_PV
  local pc = mode == "passive_custom"
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, PL.L_PV_DETAIL) then
    local P = PL.L_PV_DETAIL
    funcLuaMenuCommand(PL.LAYOUT_NODE_POS, P, 0, PL.LAYOUT_BASE_NODE, 0, pc and pv.dx or 0)
    funcLuaMenuCommand(PL.LAYOUT_NODE_POS, P, 0, PL.LAYOUT_BASE_NODE, 1, pc and pv.dy or 0)
    funcLuaMenuCommand(2885415772 --[[node scale]], P, 0, pv.flavor, pv.flavor_w, pc and pv.flavor_h_compact or pv.flavor_h)
    for k, b in ipairs(pv.builds) do
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, P, 0, b, 0, pc and pv.build_x_compact[k] or pv.build_x[k])
      funcLuaMenuCommand(PL.LAYOUT_NODE_POS, P, 0, b, 1, pc and pv.build_y_compact or pv.build_y)
    end
  end
  local H = CharacterReforged.PLAYER_PAGE_HOST
  if type(H) == "table" then
    if PL.card_default == nil and type(H.card) == "table" then
      PL.card_default = H.card
    end
    local key = mode == "mx" and "aura" or mode    -- one view at a time (R3), one row
    H.card = key ~= nil and PL.LAYOUT_CARD[key] or PL.card_default
  end
end

-- Sets the detail layout for a mode.
function PL.set_detail_layout(mode)
  PL.layout_mode = mode
  PL.layout_frames = mode ~= nil and PL.LAYOUT_FRAMES or 0
  PL.apply_detail_layout()
end

function PL.passive_board(item, name, effect)
  local L = PL.L_PV_DETAIL
  if item == nil or item == 0 or UpdateSixSenseDetailInfo == nil
      or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
    return false
  end
  PL.detail_hide_all()
  PL.open(L)
  PL.open(PL.L_PV_BUILD, 0)
  PL.open(PL.L_PV_BUILD, 1)
  local info = funcLuaCommand(@crc:CMND_GET_PASSIVE_SKILL_INFO@, 0, item)
  UpdateSixSenseDetailInfo(0, item, info, n)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 738777627, false, 0)   -- the card frame / shadow
  if type(name) == "string" and name ~= "" then   -- the passive's own name, not the slot label
    funcLuaMenuCommand(C.TEXT, L, PL.LAYOUT_PV.name, name, 0)
  end
  if type(effect) == "string" then                -- the effect lines alone (a signature passive's text holds its name)
    funcLuaMenuCommand(C.TEXT, L, PL.LAYOUT_PV.flavor, effect, 0)
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_VISIBLE@, L, PL.LAYOUT_PV.flavor, true, 0)
  end
  local card = type(CharacterReforged.player_page) == "table" and type(CharacterReforged.player_page.passive_card_fill) == "function"
  if not card then
    -- Handles the case without the player page's block (the card's look).
    local band = PL.PV_BAND[3317336303]
    funcLuaMenuCommand(C.SPRITE, L, PL.BANDS_TEX, band, 3317336303 --[[sixth_base01]], 0, 0)
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, true)
  character_reforged_detail_on = true
  pcall(PL.set_detail_layout, "passive_custom")    -- the compact block as the moves
  if card then
    local lx, ly = PL.layout_loc(1)
    local pv = PL.LAYOUT_PV
    local display = {passive = item, name = name, effect = effect}
    local okc, err = pcall(CharacterReforged.player_page.passive_card_fill, L, 0, n, display, lx + pv.dx, -ly - pv.dy)
    if not okc then
      pcall(Call, C.LOG, "skill_slots", "own passive card failed", tostring(err))
    end
    for i = 0, 1 do
      funcLuaMenuCommand(C.LAYER_VISIBLE, PL.L_PV_BUILD, i, false)
    end
  end
  return true
end

-- Draws the passive detail with its effect.
function PL.passive_detail(name, desc, item, effect)
  local okb, shown = pcall(PL.passive_board, item, name, effect)
  if okb and shown then
    return
  end
  if not okb then
    pcall(Call, C.LOG, "skill_slots", "passive detail (board window) failed", tostring(shown))
  end
  -- Fallback when the layer does not exist.
  if not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_DETAIL) then
    error("no detail layer")
  end
  PL.detail_hide_all()
  for _, pos in ipairs(PL.DETAIL_MOVE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL, pos, false, 0)
  end
  for _, mesh in ipairs(PL.DETAIL_MOVE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, mesh, false, 0)
  end
  for _, t in ipairs(PL.DETAIL_MOVE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, t, false, 0)
  end
  for _, pr in ipairs(PL.DETAIL_MOVE_PRIM) do
    funcLuaMenuCommand(1233047821 --[[number visible]], L_DETAIL, 0, pr, false)
  end
  for i = 1, 10 do
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, CALC_CRC(string.format("_tension_on%02d", i)), false, 0)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 1125548721 --[[_sp_base01]], true, 0)
  funcLuaMenuCommand(C.SPRITE, L_DETAIL, PL.PARTS_TEX, PL.BAND[2], 243934124 --[[sp_base01]], 0, 0)
  funcLuaMenuCommand(C.TEXT, L_DETAIL, 1704438437 --[[_text_name01]], name, 0)
  funcLuaMenuCommand(C.TEXT, L_DETAIL, 691026122 --[[_text_flavor01]], desc, 0)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_DETAIL, 0, true)
  character_reforged_detail_on = true
end

-- Initialises the Hiper panel.
function CharacterReforged.hyper_card_init()
@HIPER_CARD@
end
CharacterReforged.hyper_card_init()
CharacterReforged.hyper_card_init = nil
PL.HIPER_PANEL = true
PL.AURA_LAYER = {[0] = 2651268807 --[[keshin]], 395833588 --[[keshin armed]], 3679282495 --[[mixi max]],
  576015315 --[[soul / totem]], 3635526425 --[[kizuna trans]], 1305553269 --[[awakening power]], 3131422953 --[[mode change]]}
-- the retail page that holds the description (_pos_page03 / _text_flavor02) for each aura type
PL.AURA_DESC_PAGE = {[0] = 2, 0, 1, 1, 0, 0, 0}
PL.AURA_HIDE_POS = {3407216458 --[[_pos_page01]], 1377611504 --[[_pos_page02]], 3145665477 --[[_pos_page04]],
  3430431571 --[[_pos_page05]], 1307475940 --[[_pos_list01]], 3571920478 --[[_pos_list02]]}
PL.AURA_HIDE_TEXT = {1179414078 --[[_text_fsp01]], 691026122 --[[_text_flavor01]], 1899787537 --[[_text_area01]],
  3542179801 --[[_text_page_title01]], 1244139107 --[[_text_page_title02]], 2739645270 --[[_text_page_title04]],
  3561790400 --[[_text_page_title05]], 777911507 --[[_text_flavor05]], 325360264 --[[_text_scr_btn01]],
  1757105749}
PL.AURA_HIDE_MESH = {3032210235, 206240291, 563708378 --[[_gtxt_cmd_at01]],
  3516146179 --[[_area_base01]], 811580556 --[[_gtxt_armed01]], 1013569271 --[[_ai_use01]], 4122450641,
  2992676399, 508629071, 4147295610, 2150991340,
  2269285990, 2408672862, 869298536, 4217713136,
  658945009, 905124895, 2370796410, 1956062673, 859266817,
  240613041, 380545388, 68880002, 3165086183, 561011038,
  4195885618, 3182975202, 2161668434, 855158082}
-- Clears both portrait slots of an aura window on every show.
function PL.face_reset(A)
  funcLuaMenuCommand(4176779611 --[[clear face icon]], A, 0, 1051570875 --[[icon_fs_dmy01]])
  funcLuaMenuCommand(4176779611 --[[clear face icon]], A, 0, 3237726902 --[[icon_chr_dmy01]])
end

function PL.aura_clean(A)
  for _, p in ipairs(PL.AURA_HIDE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], A, p, false, 0)
  end
  for _, x in ipairs(PL.AURA_HIDE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], A, x, false, 0)
  end
  for _, m in ipairs(PL.AURA_HIDE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, A, m, false, 0)
  end
  funcLuaMenuCommand(1233047821 --[[number visible]], A, 0, 2223127589, false)
  funcLuaMenuCommand(2158717427, A, 636603611, false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, A, 443104220, false, 0)
end
PL.HIPER_HIDE_MESH = {3303013605 --[[_sp_win_base01]], 1125548721 --[[_sp_base01]], 3543352325 --[[_icon_sp_area01_off]],
  3384915402 --[[_wlv_base01]], 1013569271 --[[_ai_use01]], 559600405 --[[_icon_sp_sub_dmy01]],
  1220252763 --[[_gtxt_longshoot01]], 1252573939 --[[_gtxt_override01]], 563708378 --[[_gtxt_cmd_at01]],
  2164615260 --[[_icon_sp_area_dmy01]], 3516146179 --[[_area_base01]], 656425078}
PL.HIPER_HIDE_POS = {4081284803 --[[_pos_at01]], 1417578953, 3447183475}
PL.HIPER_HIDE_TEXT = {1704438437 --[[_text_name01]], 691026122 --[[_text_flavor01]]}

function PL.hiper_move(L, skill, team_info)
  local R = PL.L_HROW
  local ok, move = CharacterReforged.hyper_card.aura_move(skill)
  if not ok or type(move) ~= "number" or move == 0 or SetupCharaSkillItem == nil
      or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, R) then
    funcLuaMenuCommand(C.LAYER_VISIBLE, R, 0, false)
    PL.tension_off(L)
    pcall(Call, C.LOG, "skill_slots", "hiper move row", "none", tostring(ok), tostring(move))
    return
  end
  PL.move_row(L, move, team_info, 0, false, nil, CharacterReforged.hyper_card.peg_info(skill))
  pcall(Call, C.LOG, "skill_slots", "hiper move row", string.format("%08X", to_u32(skill)),
    string.format("%08X", to_u32(move)))
end

function PL.tension_off(L)
  VRFW.ui_plates.move_plate.tension_off(L, 0)             -- the shared gauge (VRFW.ui_plates.move_plate, 66_ui_plates.lua)
end

function PL.move_row(L, move, team_info, idx, no_tension, owner, peg)
  local R = PL.L_HROW
  idx = idx or 0
  if move == nil or move == 0 or SetupCharaSkillItem == nil or type(VRFW.ui_plates) ~= "table"
      or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, R) then
    funcLuaMenuCommand(C.LAYER_VISIBLE, R, idx, false)
    PL.tension_off(L)
    return
  end
  local o = {page = L, open = PL.open, restore = {nil, L_DETAIL, 0, nil, nil}}
  local chara = (owner ~= nil and owner ~= 0) and owner or n
  local okf, err = VRFW.ui_plates.move_plate.fill(R, idx, chara, move, o)
  if not okf and chara ~= n then
    pcall(Call, C.LOG, "skill_slots", "move row with the partner failed", tostring(err), "retry with the base")
    okf, err = VRFW.ui_plates.move_plate.fill(R, idx, n, move, o)
  end
  if not okf then
    pcall(Call, C.LOG, "skill_slots", "hiper move row failed", string.format("%08X", to_u32(move)), tostring(err))
    return
  end
  if no_tension then
    PL.tension_off(L)
    return
  end
  local okc, cost = funcLuaCommand(C.SKILL_INFO, move, 11)
  local o = {teams = table.pack(team_info, 255)}
  if peg ~= nil then
    okc, cost, o.scale = true, peg.cost, peg.pool
  end
  o.look = function(l, i)
    pcall(CharacterReforged.hyper_card.peg_look, l, i, peg ~= nil, peg and peg.kind)
  end
  VRFW.ui_plates.move_plate.tension(L, 0, (okc and type(cost) == "number") and cost or nil, o)
end

-- Draws the aura part.
function PL.hiper_aura(skill, team_info)
  local okt, t = funcLuaCommand(C.SKILL_INFO, skill, 13)
  local A = okt and PL.AURA_LAYER[t] or nil
  if A == nil or UpdateAuraSkillDetailInfo == nil or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, A) then
    pcall(Call, C.LOG, "skill_slots", "hiper aura window", "type", tostring(t), "missing")
    return false
  end
  PL.open(A)
  local page = PL.AURA_DESC_PAGE[t] or 0
  if WarpAuraSkillDetailInfoPageIdx ~= nil then
    local okw, p = pcall(WarpAuraSkillDetailInfoPageIdx, page, t, skill)
    if okw and type(p) == "number" then
      page = p
    end
  end
  pcall(PL.face_reset, A)
  UpdateAuraSkillDetailInfo(skill, n, nil, team_info, page, true)
  funcLuaMenuCommand(C.MESH_VISIBLE, A, 443104220, false, 0)       -- the card frame / shadow
  funcLuaMenuCommand(C.MESH_VISIBLE, A, 1013569271 --[[_ai_use01]], false, 0)   -- "IA activada": not for auras here
  funcLuaMenuCommand(2158717427 --[[locator visible]], A, 636603611, false, 0)   -- the type + cost line is there
  for _, p in ipairs(PL.AURA_HIDE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], A, p, false, 0)
  end
  for _, x in ipairs(PL.AURA_HIDE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], A, x, false, 0)
  end
  funcLuaMenuCommand(1233047821 --[[number visible]], A, 0, 2223127589, false)
  pcall(PL.aura_clean, A)
  -- no description page on the aura card (its plate + text)
  funcLuaMenuCommand(2158717427 --[[locator visible]], A, 622567014 --[[_pos_page03]], false, 0)
  funcLuaMenuCommand(2735666188 --[[text visible]], A, 2956552560 --[[_text_flavor02]], false, 0)
  -- the band stays the retail sprite the fill chose (aura type + element), drawn at its own aspect (930 x 88)
  local oke, el = funcLuaCommand(C.SKILL_INFO, skill, 7)
  funcLuaMenuCommand(C.LAYER_VISIBLE, 1921826160 --[[team00_40_change_page_guide]], 0, false)
  funcLuaMenuCommand(C.LAYER_VISIBLE, A, 0, true)
  local okc, cid = funcLuaCommand(C.SKILL_INFO, skill, 17)
  pcall(Call, C.LOG, "skill_slots", "hiper aura window", string.format("%08X", to_u32(skill)), "type", t,
    "element", tostring(el), "page", page, "info17", tostring(okc), tostring(cid))
  return true
end

function PL.hiper_card(skill)
  local t = CharacterReforged.hyper_card.aura_type(skill)
  local A = t ~= nil and PL.AURA_LAYER[t] or nil
  if A == nil then
    return
  end
  local mc = CharacterReforged.hyper_card.mc_get(n, skill)
  local okn, nameId = funcLuaCommand(C.SKILL_INFO, skill, 4)
  local name = okn and nameId ~= nil and funcLuaCommand(C.NAME_TEXT, nameId) or nil
  local title = CharacterReforged.hyper_card.title(type(name) == "string" and name or nil, nil, mc)
  CharacterReforged.hyper_card.header(A, skill, title, 0)
  local okp, ep = pcall(CharacterReforged.hyper_card.portrait, A, skill, nil, mc, "skill_panel", 0)
  if not okp then
    pcall(Call, C.LOG, "skill_slots", "portrait failed", tostring(ep))
  end
  local d = ""
  funcLuaMenuCommand(2735666188 --[[text visible]], A, 2956552560 --[[_text_flavor02]], false, 0)
  funcLuaMenuCommand(2158717427 --[[locator visible]], A, 622567014 --[[_pos_page03]], false, 0)
  pcall(Call, C.LOG, "skill_slots", "hiper card", string.format("%08X", to_u32(skill)), tostring(t),
    tostring(title), "partner", tostring(mc ~= nil), "desc", #d)
end

-- MOVE_X, the pool at POOL_X (ss2_build.py HIPER_JOINTS).
PL.POOL = {INST = 1, NODE = 923022909 --[[_pos_tension01]], X = 423, Y = 70, K = 0.75, MOVE_X = 289, POOL_X = 478}

function PL.pool_gauge(L, peg)
  local P = PL.POOL
  local i = P.INST
  PL.pool_peg = nil
  if peg == nil or type(peg.pool) ~= "number" or peg.pool <= 0 then
    funcLuaMenuCommand(C.LAYER_VISIBLE, L, i, false)
    return false
  end
  PL.open(L, i)
  for _, m in ipairs(PL.HIPER_HIDE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, i)
  end
  for _, q in ipairs(PL.HIPER_HIDE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], L, q, false, i)
  end
  for _, x in ipairs(PL.HIPER_HIDE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], L, x, false, i)
  end
  funcLuaMenuCommand(2735666188, L, 1899787537 --[[_text_area01]], false, i)
  funcLuaMenuCommand(2158717427, L, 2313134961 --[[_pos_area01]], false, i)
  funcLuaMenuCommand(1233047821 --[[number visible]], L, i, 2223127589 --[[AT power]], false)
  VRFW.ui_plates.move_plate.tension(L, i, peg.pool, {scale = peg.pool, look = function(l, k)
    pcall(CharacterReforged.hyper_card.peg_look, l, k, true, peg.kind)
  end})
  funcLuaMenuCommand(C.LAYER_VISIBLE, L, i, true)
  PL.pool_peg = peg
  return true
end

function PL.hiper_show(skill, team_info)
  if skill == PL.MX_FUSION and PL.mx_detail ~= nil then
    local okf, f = pcall(PL.mx_get)
    if okf and f ~= nil then
      return PL.mx_detail(f, team_info)
    end
  end
  local L = PL.L_HIPER
  if not PL.HIPER_PANEL or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
    return false
  end
  PL.detail_hide_all()
  PL.open(L)
  if not PL.hiper_aura(skill, team_info) then
    return false
  end
  for _, m in ipairs(PL.HIPER_HIDE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, 0)
  end
  for _, p in ipairs(PL.HIPER_HIDE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], L, p, false, 0)
  end
  for _, x in ipairs(PL.HIPER_HIDE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], L, x, false, 0)
  end
  funcLuaMenuCommand(1233047821 --[[number visible]], L, 0, 2223127589 --[[AT power]], false)
  -- Header (as the player page's Hiper page)
  funcLuaMenuCommand(C.TEXT, L, 1899787537 --[[_text_area01]], "", 0)
  funcLuaMenuCommand(2735666188 --[[text visible]], L, 1899787537, false, 0)
  pcall(PL.hiper_card, skill)
  PL.hiper_move(L, skill, team_info)
  local peg = CharacterReforged.hyper_card.peg_info(skill)
  pcall(CharacterReforged.hyper_card.peg_pool, L, peg)
  local okg, eg = pcall(PL.pool_gauge, L, peg)          -- the spirit's PEG / SP pool as a gauge
  if not okg then
    pcall(Call, C.LOG, "skill_slots", "pool gauge failed", tostring(eg))
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, true)
  character_reforged_detail_on = true
  PL.hiper_wide = true
  pcall(CharacterReforged.skill_table_detail_graph_sync)
  pcall(PL.set_detail_layout, "aura")              -- banner on a card sized to the row
  return true
end

PL.MOVE_AS_ROW = true
PL.MOVE_ROW_HIDE_MESH = {1125548721 --[[_sp_base01]], 3384915402 --[[_wlv_base01]], 563708378 --[[_gtxt_cmd_at01]],
  3303013605 --[[_sp_win_base01]]}
function PL.move_as_row(skill, team_info)
  local L = PL.L_HIPER
  if not PL.MOVE_AS_ROW or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
    return false
  end
  PL.open(L)
  for _, m in ipairs(PL.HIPER_HIDE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, 0)
  end
  for _, q in ipairs(PL.HIPER_HIDE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], L, q, false, 0)
  end
  for _, x in ipairs(PL.HIPER_HIDE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], L, x, false, 0)
  end
  funcLuaMenuCommand(2735666188, L, 1899787537 --[[_text_area01]], false, 0)
  funcLuaMenuCommand(2158717427, L, 2313134961 --[[_pos_area01]], false, 0)
  funcLuaMenuCommand(1233047821 --[[number visible]], L, 0, 2223127589 --[[AT power]], false)
  PL.move_row(L, skill, team_info, 0, false, nil, nil)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, true)
  -- Hides the parts of the retail window.
  for _, m in ipairs(PL.MOVE_ROW_HIDE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, m, false, 0)
  end
  funcLuaMenuCommand(2735666188, L_DETAIL, 1704438437 --[[_text_name01]], false, 0)
  funcLuaMenuCommand(2158717427, L_DETAIL, 923022909 --[[_pos_tension01]], false, 0)
  funcLuaMenuCommand(2158717427, L_DETAIL, 4081284803 --[[_pos_at01]], false, 0)
  funcLuaMenuCommand(1233047821, L_DETAIL, 0, 2223127589, false)
  funcLuaMenuCommand(1233047821, L_DETAIL, 0, 3424269865 --[[tension cost]], false)
  pcall(Call, C.LOG, "skill_slots", "move as row", string.format("%08X", to_u32(skill)))
  return true
end

function CharacterReforged.skill_table_detail_show(skill, row)
  if not Detail or skill == 0 then
    return false
  end
  if not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_DETAIL) then
    return false
  end
  local _, team_info = GetSoccerTeamInfo(0)            -- tension gauge scale (board: GetSoccerTeamInfo(0))
  if IsSpecial(skill) then                         -- the Hiper has its own panel
    local okh, shown = pcall(PL.hiper_show, skill, team_info)
    if okh and shown then
      return true
    end
    pcall(Call, C.LOG, "skill_slots", "hiper panel", tostring(okh), tostring(shown))
    return false
  end
  PL.detail_hide_all()
  SetSkillItemLayerName(nil, L_DETAIL, 0, nil, nil)
  -- Reads the grade.
  local pos = funcLuaCommand(C.SKILL_POS, n, skill)
  if type(pos) ~= "number" or pos < 0 or pos >= 6 then
    pos = nil
  end
  pcall(PL.detail_restore)                         -- a passive may have hidden the move-only parts
  SetupPersonalPlateSkillDetailInfo(skill, n, nil, team_info, pos, true)
  -- Part of the player panel, not a card on top of it.
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 3303013605 --[[_sp_win_base01]], false, 0)
  pcall(PL.detail_polish, skill, pos)
  -- A level-locked row plays nothing.
  if row ~= nil and row > 0 and CharacterReforged.skill_table_is_locked(row) then
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 1013569271 --[[_ai_use01]], false, 0)
  end
  local okr, er = pcall(PL.move_as_row, skill, team_info)
  if not okr then
    pcall(Call, C.LOG, "skill_slots", "move as row failed", tostring(er))
  end
  -- the retail fill shows the layer itself at its end (it stays hidden if the move data is missing)
  local lv = DetailLevelTab(row)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_DETAIL_LV, 0, lv)
  character_reforged_detail_on = true
  pcall(PL.set_detail_layout, "move")              -- label on the card, row + IA / Nv. line in it
  return true
end

function UpdateEquipItemInfo()
  local skill, removable, row = 0, false, nil
  local fixed = false                     -- row cannot be edited (level-locked or Prime)
  if n14 ~= L_BTN then
    local ret = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
    funcLuaMenuCommand(C.CURSOR_LOC, L_ROW, 3313461902 --[[cursor]], ret, ROW_NUM + 1)
    row = ret
    local locked = CharacterReforged.skill_table_is_locked(ret)
    local prime = CharacterReforged.skill_table_is_prime()
    skill = PL.row_move(ret)                -- a still-locked move is shown too when it is known (learnset)
    fixed = locked or prime or PL.idol_fixed(ret)
    removable = skill ~= 0 and not fixed
  end
  local okd, shown = false, false
  if skill ~= 0 then
    okd, shown = pcall(CharacterReforged.skill_table_detail_show, skill, row)
  end
  if okd and shown then
    SetVisibleEquipInfoWindow(false)
  else
    pcall(CharacterReforged.skill_table_detail_hide)
    if skill ~= 0 then
      SetVisibleEquipInfoWindow(true)
      SetupSkillInfo(skill)
    else
      SetVisibleEquipInfoWindow(false)
      pcall(PL.set_detail_layout, "empty")         -- an empty row keeps the compact card, not a tall blank one
    end
  end
  if fixed then
    VRFW.footer_prompts.set(nil, n12, {}, {guide = 1138543975 --[[mainmenu01_06_base_button_guide]], declared = false})
  elseif n14 ~= L_BTN then
    PL.guide_redo = function() PL.row_guide() end   -- Aceptar, Y Restablecer
    PL.guide_redo()
  else
    UpdateEquipButtonGuide(n12, removable)   -- bottom buttons: Aceptar
  end
  if n14 ~= L_BTN and PL.idol_fixed(row) then
    funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]], PL.txt(PL.IDOL_GUIDE), 0)
  end
  pcall(CharacterReforged.skill_table_detail_graph_sync)
end

function UpdateEquipCondition(a1, a2)
  RefreshRows()
  UpdateCharaStatus()
  UpdateEquipItemInfo()
end

local RetailOnSetupLayer = OnSetupLayer
function OnSetupLayer(a1, a2)
  local prio = PL.DETAIL_PRIO ~= nil and PL.DETAIL_PRIO[a1] or nil
  if prio ~= nil then
    -- Sets the draw priority of the detail windows.
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, a1, a2, prio, true)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  end
  if a1 == L_DETAIL or a1 == L_DETAIL_LV then
    -- Sets the draw priority of the move detail panel and level badge.
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, a1, a2, a1 == L_DETAIL and 656 or 657, true)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  end
  if a1 == L_BASE then
    -- retail team05_01 branch without the equip01..05 / equipNN_rpg / eye-check trace switches
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, a1, a2, 450, true)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, a1, a2, 4168479935 --[[chara02]], false)
    funcLuaMenuCommand(C.LAYER_VISIBLE, 508919562 --[[team00_02_chara_card]], 0, false)
    funcLuaMenuCommand(3252599449 --[[set list item count]], L_ROW, ROW_NUM)
    funcLuaMenuCommand(C.MESH_VISIBLE, a1, 2728862193 --[[_gtxt_equipment01 "Equipamiento" label]], false, a2)
    if n15 > 1 then
      funcLuaMenuCommand(C.MESH_VISIBLE, a1, 1821189452 --[[_arrow01_l01]], true, a2)
      funcLuaMenuCommand(C.MESH_VISIBLE, a1, 2050337590 --[[_arrow01_r01]], true, a2)
      local text_get = funcLuaCommand(@crc:CMND_TEXT_GET@, 1406349308)
      funcLuaMenuCommand(C.TEXT, a1, 3853210161 --[[_text_btn01_l]], text_get, a2)
      funcLuaMenuCommand(2333948100, a1, a2, 3853210161 --[[_text_btn01_l]], 1155652271)
      local text_get2 = funcLuaCommand(@crc:CMND_TEXT_GET@, 1681049711)
      funcLuaMenuCommand(C.TEXT, a1, 530870098 --[[_text_btn01_r]], text_get2, a2)
      funcLuaMenuCommand(2333948100, a1, a2, 530870098 --[[_text_btn01_r]], 1155652271)
    end
    if flag7 then
      UpdateEquipButtonGuide(n12, true)
      funcLuaMenuCommand(1432240275, n12, 1138543975 --[[mainmenu01_06_base_button_guide]], false)
    end
    return
  end
  RetailOnSetupLayer(a1, a2)
  if a1 == L_BTN then
    funcLuaMenuCommand(C.TEXT, a1, 625330766 --[[_text_cmd01]], PL.txt(BUTTON_TEXT), a2)
  end
end

local RetailOnOpenLayer = OnOpenLayer
function OnOpenLayer(a1, a2)
  RetailOnOpenLayer(a1, a2)
  if a1 == 3078308064 --[[mainmenu90_05_content_guide_line01]] then
    funcLuaMenuCommand(C.TEXT, a1, 378156699 --[[_text_guide01]], PL.txt(GUIDE_TEXT), a2)
  end
end

function OnEnter(a1, a2)
  -- Retail stored list-group parameters here.
end

function OnDecideFocus(a1, a2)
  if vrfw_co ~= nil then
    return
  end
  if a1 == L_ROW then
    local locked = CharacterReforged.skill_table_is_locked(a2)
    if locked or CharacterReforged.skill_table_is_prime() or PL.idol_fixed(a2) then
      funcLuaCommand(C.SE, SE_NG)
      return
    end
    vrfw_co = coroutine.create(function()
      CharacterReforgedSkillTablePickCoroutine(a2)
    end)
  elseif a1 == L_BTN then
    CharacterReforgedSkillTableOpenOriginalBoard()
  end
end

local RetailOnFunction = OnFunction
function OnFunction(a1, a2)
  if vrfw_co ~= nil then
    return
  end
  if a1 == 3918588344 then          -- CMD_FUNC1 (retail "best equipment") -> original ability board
    CharacterReforgedSkillTableOpenOriginalBoard()
  elseif a1 == 4109882573 or a1 == 1141890006 then
    local row = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
    local ok_row = row ~= nil and row >= 0 and row < ROW_NUM and n14 ~= L_BTN and not CharacterReforged.skill_table_is_locked(row)
    if a1 == 1141890006 then
    elseif ok_row and not CharacterReforged.skill_table_is_prime() and not PL.idol_fixed(row) then
      vrfw_co = coroutine.create(function()
        CharacterReforged.skill_table_reset_coroutine(row)
      end)
    else
      funcLuaCommand(C.SE, SE_NG)
    end
  else
    RetailOnFunction(a1, a2)    -- L/R: previous/next player (ChangeChara uses the overrides above)
  end
end

local RetailOnBack = OnBack
function OnBack(a1)
  -- every back logs what it does
  local st = vrfw_co ~= nil and coroutine.status(vrfw_co) or "none"
  if vrfw_co ~= nil and st == "dead" then
    vrfw_co = nil                          -- a finished action must never keep the screen from closing
  end
  pcall(funcLuaCommand, C.LOG, "skill_slots", "back", tostring(a1), "action", st,
    vrfw_co ~= nil and "swallowed (an action runs)" or "closing")
  if vrfw_co ~= nil then
    return
  end
  PL.closeLog = 60                        -- the next 60 frames log the close state (Step)
  PL.board_closing = true                 -- the close starts: no panel redraw until the screen opens again
  pcall(funcLuaCommand, C.LOG, "skill_slots", "back: retail OnBack", "closing before",
    tostring(funcLuaCommand(C.CLOSING_MENU, EVT_MENU)), "closed before", tostring(funcLuaCommand(C.CLOSED_MENU, EVT_MENU)))
  RetailOnBack(a1)
  funcLuaCommand(C.SE, SE_BACK)
  character_reforged_back_frames = 2
end

local character_reforged_cursor_idx = -1
local RetailOnChangeFocus = OnChangeFocus
function OnChangeFocus(a1, a2)
  -- Retail returns early unless CMND_IS_CTRL_FOCUS_ACTIVE, which can stay off after the picker.
  if a1 == L_ROW or a1 == L_BTN then
    n14 = a1
    UpdateEquipItemInfo()
    return
  end
  RetailOnChangeFocus(a1, a2)
end

function Step()
  if character_reforged_hiper_pending and HyperTexReady() then
    SetRowBase(0)
  end
  if next(PL.lock_pending) ~= nil and PL.lock_tex_ready() then   -- navy "off" base finished loading
    for r in pairs(PL.lock_pending) do
      SetRowBase(r, true)
    end
  end
  if vrfw_co == nil and n14 ~= L_BTN then   -- keep the arrow cursor on the focused row
    local i = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
    if i ~= nil and i ~= character_reforged_cursor_idx and i >= 0 and i < ROW_NUM then
      character_reforged_cursor_idx = i
      funcLuaMenuCommand(C.CURSOR_LOC, L_ROW, 3313461902 --[[cursor]], i, ROW_NUM + 1)
    end
  end
  if vrfw_co ~= nil then
    local ok, err = coroutine.resume(vrfw_co)
    if not ok then
      PRINT("vrfw_skill_slot_menu: " .. tostring(err))
      vrfw_co = nil
      local text = "ERROR Lua: " .. tostring(err)
      vrfw_co = coroutine.create(function()
        VRFW.question.notice(text)
        funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
      end)
    elseif coroutine.status(vrfw_co) == "dead" then
      vrfw_co = nil
    end
  end
  if character_reforged_back_frames >= 0 then
    character_reforged_back_frames = character_reforged_back_frames - 1
    if character_reforged_back_frames < 0 and not funcLuaCommand(C.CLOSING_MENU, EVT_MENU) and not funcLuaCommand(C.CLOSED_MENU, EVT_MENU) then
      pcall(funcLuaCommand, C.LOG, "skill_slots", "back: close requested")
      funcLuaCommand(C.CLOSE_MENU, EVT_MENU)
    end
  end
  -- Logs a diagnostic.
  if (PL.closeLog or 0) > 0 then
    PL.closeLog = PL.closeLog - 1
    if PL.closeLog % 5 == 0 then
      local open = {}
      local watch = {L_ROW, L_BTN, L_BASE, L_INFO, L_DETAIL, L_DETAIL_LV, PL.L_PV_DETAIL, PL.L_HIPER, PL.L_HROW,
          PL.L_BTN_ROLE, PL.L_ROLE_OPT, PL.L_SSLIST, PL.L_LISTBG, 1281343292}
      -- the plate_pages host block's added layers too (band, slant, tag, bars, line, chart, numbers)
      if type(CharacterReforged.player_page) == "table" and type(CharacterReforged.player_page.HOST_LAYERS) == "table" then
        for _, l in ipairs(CharacterReforged.player_page.HOST_LAYERS) do
          watch[#watch + 1] = l
        end
      end
      for _, l in ipairs(watch) do
        if l ~= nil and funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, l) == true and funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, l, 0) == true then
          open[#open + 1] = string.format("%08X%s", l, funcLuaMenuCommand(@crc:CMND_IS_LOADING_LAYER@, l) == true and "(loading)" or "")
        end
      end
      local okc, cing = pcall(funcLuaCommand, C.CLOSING_MENU, EVT_MENU)
      local okd, cd = pcall(funcLuaCommand, C.CLOSED_MENU, EVT_MENU)
      -- one string (the loader's lua log keeps only the first few values)
      pcall(funcLuaCommand, C.LOG, string.format("skill_slots close watch %d closing %s closed %s action %s back %s open [%s]",
        PL.closeLog, tostring(cing), tostring(cd), vrfw_co ~= nil and coroutine.status(vrfw_co) or "none",
        tostring(character_reforged_back_frames), table.concat(open, " ")))
    end
  end
  -- Logs a diagnostic of the back key.
  local okk, bk = pcall(PL.key, PL.K_BACK)
  local down = okk and bk == true
  if down and not character_reforged_back_seen then
    pcall(funcLuaCommand, C.LOG, "skill_slots", "back key seen", "action",
      vrfw_co ~= nil and coroutine.status(vrfw_co) or "none", "back frames", tostring(character_reforged_back_frames),
      "pv open", tostring(character_reforged_pv_open))
  end
  character_reforged_back_seen = down
end


function CharacterReforged.skill_table_after_change()
  CharacterReforged.skill_table_sync_board()
  RefreshRows()
  UpdateCharaStatus()
  UpdateEquipItemInfo()
end

-- Status 1 means done and verified (the slot is re-read too).
local function BoardPut(bslot, skill, inv)
  return CharacterReforged.player_sets.board_put(n, bslot, skill, inv)
end

-- Clears a board slot; keep_open ends a slot without a native move open and empty instead of refusing it (-6), only used right before a PLACE on the same slot or for the Hiper slot 8, which must stay open.
local function BoardClear(bslot, keep_open)
  return CharacterReforged.player_sets.board_clear(n, bslot, keep_open)
end

local function ListPut(slot, skill)
  return CharacterReforged.player_sets.list_put(n, slot, skill)
end

local function Log(...)
  Call(C.LOG, "skill_slots", ...)
end



-- Put `skill` (0 = remove) into this player's team aura slot
local function TeamAuraPut(skill)
  return CharacterReforged.player_sets.team_aura_put(n, skill, PL.set_ctx())
end

local function Report(text, row)
  Log("report", row, (string.gsub(text, "\n", " / ")))
end

local function Snapshot()
  return CharacterReforged.player_sets.board_snapshot(n)
end

local function Diff(before, after)
  return CharacterReforged.player_sets.board_diff(before, after)
end

-- Real invSkill handle for `skill`
local function HandleFor(skill, pool)
  return CharacterReforged.player_sets.handle_for(n, skill, pool)
end

-- Handle for the Hiper slot 8.
local function HyperHandle(skill)
  return CharacterReforged.player_sets.hyper_handle(n, skill)
end

function CharacterReforged.skill_table_team_aura_get()
  return CharacterReforged.player_sets.team_aura_get(n, PL.set_ctx())
end

-- The board mirrors the match list
function CharacterReforged.skill_table_sync_board()
  return CharacterReforged.player_sets.sync_board(n, PL.set_ctx())
end

-- Put `skill` on `row`.
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  CharacterReforged.player_sets.equip_base(n, row, skill, PL.set_ctx())
end

local function CurrentWithInv()
  local cur = {inv = {}}
  for r = 0, ROW_NUM - 1 do
    cur[r] = Skill(r)
    local b, h = BoardSkill(BoardSlot(r))
    cur.inv[r] = (b == cur[r]) and h or 0
  end
  return cur
end

function CharacterReforged.skill_table_focus_row(row)
  if row == nil or row < 0 or row >= ROW_NUM then
    return
  end
  local before = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
  funcLuaMenuCommand(3466097042, L_ROW, row)
  -- 306610847 (list index) is not called
  Call(@crc:CMND_VRFW_LOG@, "skill_slots", "focus", row, "before", before, "after",
    funcLuaMenuCommand(C.FOCUS_IDX, L_ROW))
  character_reforged_cursor_idx = row
  funcLuaMenuCommand(C.CURSOR_LOC, L_ROW, 3313461902 --[[cursor]], row, ROW_NUM + 1)
  -- The focus is the row list again, whatever focus event came in between.
  n14 = L_ROW
  if PL.fs_wait ~= nil then
    PL.fs_wait = PL.FS_WINDOW
  end
end

function CharacterReforgedSkillTablePickCoroutine(row)
  if CharacterReforged.skill_table_is_prime() then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local cur = CurrentWithInv()
  P_Set(KEY_PICK, row == 0 and 2 or 1)
  for k = 1, ROW_NUM - 1 do
    P_Set(KEY_USED[k], (k ~= row and cur[k] ~= 0) and cur[k] or 0)
  end
  for _, key in ipairs({KEY_RESULT, KEY_INV, KEY_DEBUG_INIT, KEY_DEBUG_ENTER, KEY_DEBUG_CODE, KEY_DEBUG_BITS}) do
    VRFW.param.clear(key)
  end
  for _, key in ipairs(PL.LIST_KEYS) do            -- no stale six-sense / board filter tabs
    VRFW.param.clear(key)
  end
  P_Set(3357163798, n3)                          -- dock number, as the team dock sets it for this list
  -- Plays no SE_OK.
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, false)
  -- Stores the focus the layer gets when it is reopened or resumed (not the current one) before suspending.
  funcLuaMenuCommand(3466097042, L_ROW, row)
  funcLuaMenuCommand(C.MENU_SUSPEND, EVT_MENU)
  funcLuaCommand(C.OPEN_MENU, PICK_MENU, PICK_MENU)
  coroutine.yield()
  while funcLuaMenuCommand(C.EXIST_MENU, PICK_MENU) do
    coroutine.yield()
  end
  funcLuaMenuCommand(C.MENU_RESUME, EVT_MENU)
  coroutine.yield()
  CharacterReforged.skill_table_focus_row(row)                            -- resume puts the focus back on row 0 (Hiper)
  VRFW.param.clear(KEY_PICK)
  for k = 1, ROW_NUM - 1 do
    VRFW.param.clear(KEY_USED[k])
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, true)
  local function take(key)
    if VRFW.param.has(key) then
      local v = VRFW.param.get(key)
      VRFW.param.clear(key)
      return v
    end
    return nil
  end
  local skill = to_u32(take(KEY_RESULT))
  local inv = to_u32(take(KEY_INV))
  take(KEY_DEBUG_INIT)   -- the picker's debug keys: cleared, not read
  take(KEY_DEBUG_ENTER)
  take(KEY_DEBUG_CODE)
  take(KEY_DEBUG_BITS)
  if skill ~= 0 and skill ~= cur[row] then
    if (row == 0) ~= IsSpecial(skill) then   -- the picker already refuses these
      funcLuaCommand(C.SE, SE_NG)                  -- error sound only
      Log("pick refused", row, Name(skill), "special row mismatch")
    else
      -- Plays no SE here.
      local ok, err = pcall(CharacterReforged.skill_table_equip, row, skill, inv, cur)
      if not ok then
        Log("equip error", row, tostring(err))   -- no text on screen, error sound only
        funcLuaCommand(C.SE, SE_NG)
      end
    end
  end
  CharacterReforged.skill_table_focus_row(row)
  CharacterReforged.skill_table_after_change()
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end

-- keepOpen 3 takes the placed and the native item off; the piece stays open and empty.
function CharacterReforged.skill_table_restore_coroutine(row)
  if CharacterReforged.skill_table_is_prime() then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  if row == 0 then
    local before = Snapshot()
    local old = Skill(0)
    local r = Call(C.BOARD_CLEAR, n, HYPER_BUTTON_SLOT, 3 --[[keepOpen 3: everything off]])
    local okA, txt = TeamAuraPut(0)
    funcLuaCommand(C.SE, old ~= 0 and SE_REMOVE or SE_NG)
    Report(string.format("Delete Hiper: %s, slot %d (state %s), %s.\n%s", Name(old), HYPER_BUTTON_SLOT + 1,
      tostring(r), txt, Diff(before, Snapshot())), 0)
  else
    local before = Snapshot()
    local bslot, pos = BoardSlot(row), ListPos(row)
    local old = Skill(row)
    local r = Call(C.BOARD_CLEAR, n, bslot, 3 --[[keepOpen 3: everything off]])
    if ListSkill(pos) ~= 0 then
      funcLuaCommand(C.REMOVE_SKILL, n, pos)       -- the match position emptied too
    end
    local now = Skill(row)
    funcLuaCommand(C.SE, old ~= 0 and SE_REMOVE or SE_NG)
    Report(string.format("Delete slot %d: %s -> %s (state %s).\n%s", bslot + 1, Name(old), Name(now),
      tostring(r), Diff(before, Snapshot())), row)
  end
  CharacterReforged.skill_table_after_change()
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end

local SetPreview = {
  PASSIVE = @crc:CMND_GET_PASSIVE_SKILL_INFO@,
  TEAM_PASSIVE = @crc:CMND_GET_TEAM_PASSIVE_INFO@,   -- CMND_GET_TEAM_PASSIVE_INFO (id, 0) -> ok, text
  TEXT_VALUE = 910683996,      -- (textId or string, "VALUE", value, ...) -> string
}
local STAT_TITLE = {[0] = 3905596903, 1084668705, 1047492482, 2352972234, 2604963209, 614355554, 2718198818}

local function SetPreviewCall(cmd, ...)
  local r = {pcall(funcLuaCommand, cmd, ...)}
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2)
end

-- The list panel.
local L_PV_PANEL = 3303957920
local L_PV_ROW = 811691761
local L_BLACKBG = 3801549073
local L_BTN_ICON = 1221220500      -- an unused button layer, kept hidden (setting layer)
local L_BTN_SS = 2729134238          -- "Pasiva personalizada" button
local SET_PREVIEW_ROWS = 9                              -- panel rows = row-layer instances 0..8
local BG_COUNT = 2                             -- 2 stacked cmn02_01_blackbg dims
local ROW_ICON_SKILL_SLOT, ROW_ICON_PREVIEW = 9, 10     -- row-layer instances drawn as the icons of the two square buttons
local POSITION_VISIBLE = 2158717427                 -- (layer, node, bool, idx): show / hide a locator subtree
local Priority = @crc:CMND_SET_DRAW_PRIORITY@                    -- (layer, idx, prio, bool)
local PRIME_INDEX, PRIME_NUM, PRIME_VISIBLE = @crc:CMND_SEARCH_PRIM_INDEX@, 3609943765, 1233047821
local NUM_LEVEL = 2330185550                   -- num_passive_lock01 (number node of the row)
local MENU_CTRL = 1332654303
local COMMAND_BACK, COMMAND_ENTER, COMMAND_UP, COMMAND_DOWN = 3011112225, 1981080283, 1197218715, 3259546669
local TEXTURE_SOCCER11_20 = 4021797290             -- #/menu/00_soccer/soccer11/soccer11_20/soccer11_20.g4tx
local TEXTURE_ICON_COMMON = 2320109963             -- #/menu/200_icon/15_icon_common/icon_common.g4tx
local TEXTURE_TEAMBUFF = 2301895383                -- #/menu/200_icon/08_icon_teambuff/<LG>/icon_teambuff.g4tx
local SKILL_SLOT_CATEGORY = 200                        -- ability list category filter of six-sense items (board picker)
local character_reforged_pv_open = false
local character_reforged_icon_frames = 0                          -- frames left to re-apply the static button icons

local function SetPreviewTeamText(id, eff, count)
  local okE, textId = SetPreviewCall(@crc:CMND_GET_PASSIVE_EFFECT_INFO@, eff, 0)
  local t
  if okE == true and textId ~= nil then
    t = SetPreviewCall(720417636, textId)
    t = SetPreviewCall(@crc:CMND_TEXT_CONVERT@, t, 0, 1140121255, "[CPASSIVE01]") or t
    t = SetPreviewCall(@crc:CMND_TEXT_CONVERT@, t, 0, 2769827636, "") or t
    local value = SetPreviewCall(SetPreview.PASSIVE, 1, id, 0)
    local okc, digits, disp = pcall(MENU_DEF.CalcPassiveEffectNeedDecimalDigitAndDisplayValue, eff, value)
    if okc and disp ~= nil then
      t = SetPreviewCall(SetPreview.TEXT_VALUE, t, "VALUE", disp, 0, 2, false, digits) or t
    end
  end
  if type(t) ~= "string" or t == "" then
    t = string.format("%08X", to_u32(id))
  end
  t = string.gsub(t, "%s+", " ")
  return t                                         -- never cut (long texts wrap to 2 lines)
end

local function RowReset(k)
  local L = L_PV_ROW
  for _, pos in ipairs({1559050359 --[[_pos_icon01]], 397052763, 3320080845 --[[_pos_icon02]], 3448691050 --[[_pos_build01]],
                        3453619769 --[[_pos_type01]], 2497436533 --[[_pos_position01]]}) do
    funcLuaMenuCommand(POSITION_VISIBLE, L, pos, false, k)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 2336867556 --[[_build_ef01]], false, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 27565530 --[[_icon_inheritance01]], false, k)
end

local ALBUM_ICON_ON = {
  [2] = 3528670446, [3] = 3236336384, [4] = 2019226725, [12] = 3851275484, [27] = 1563536313, [22] = 1469018683,
  [16] = 4013102430, [18] = 4253465264, [11] = 1161485781, [10] = 3639469420, [19] = 1615954441, [21] = 1927556583,
  [29] = 3394783874, [30] = 2453363412, [0] = 713506225, [1] = 271517931, [8] = 2828234638, [9] = 3123101792,
  [17] = 43689733, [20] = 2672664508, [23] = 670169305, [24] = 893671223, [25] = 2381852754, [26] = 3583713284,
  [28] = 1831290721, [37] = 760160603, [6] = 2515748414, [13] = 2269571536, [31] = 136609415, [32] = 2962758114,
  [38] = 3908766132
}
local TEXTURE_ABILEAR = 3315424508                -- #/menu/200_icon/18_icon_abilearboard/<LG>/icon_abilearboard.g4tx
local ICON_SIXTH = 487860482                   -- icon_abilear_sixth01 (retail board six-sense piece, icon_common)

-- Draws a row-layer instance used only as a static icon on a square button.
local function ButtonIcon(k, tex, sprite)
  local L = L_PV_ROW
  RowReset(k)
  for _, mesh in ipairs({3143733656 --[[_passive_base01]], 2061463723 --[[_passive_base01_ol01]],
                         3822461201 --[[_passive_base01_ol02]], 3877027080, 2336867556 --[[_build_ef01]],
                         2299070650 --[[_icon_teambuff_tgt_dmy01]], 27565530 --[[_icon_inheritance01]],
                         22927936, 97947090, 106573771,
                         2673049201, 3895971012, 918292019,
                         2203859798, 3016059238, 744788874}) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, mesh, false, k)
  end
  funcLuaMenuCommand(C.TEXT, L, 1868134834 --[[_text_passive01]], "", k)
  funcLuaMenuCommand(POSITION_VISIBLE, L, 1559050359 --[[_pos_icon01]], true, k)
  for _, mesh in ipairs({3877027080, 2336867556 --[[_build_ef01]], 2299070650 --[[_icon_teambuff_tgt_dmy01]]}) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, mesh, false, k)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 3165767436, true, k)
  funcLuaMenuCommand(C.SPRITE, L, tex, sprite, 3234721532 --[[icon_teambuff_dmy01]], 0, k)
end

-- Returns the board icon of the equipped six-sense item (as the original board draws the piece), else the generic one.
local function SkillSlotIcon(item)
  if item ~= 0 then
    local eff = SetPreviewCall(SetPreview.PASSIVE, 0, item)
    if eff ~= nil then
      local ok, cat = SetPreviewCall(@crc:CMND_GET_PASSIVE_EFFECT_INFO@, eff, 2, 0)
      local spr = ok and ALBUM_ICON_ON[tonumber(cat) or -1] or nil
      if spr ~= nil then
        return TEXTURE_ABILEAR, spr
      end
    end
  end
  return TEXTURE_ICON_COMMON, ICON_SIXTH
end

local function SkillSlotGet()
  return CharacterReforged.player_sets.six_get(n)
end

-- Returns locked, needLevel and pieceIdx of the custom passive slot, which is locked while no mod declares CMND_CHARACTERREFORGED_SIX_SENSE (scripts\board_slots.lua); no board piece is read.
local function SkillSlotLock()
  return not PL.has_service("six_sense"), 0, nil
end

-- The signature passive cannot be changed.
function PL.signature()
  local ok, passive = pcall(funcLuaCommand, @crc:CMND_PASSIVESSYNERGIES_OWN_PASSIVE@, n)
  if ok and type(passive) == "number" then
    return to_u32(passive)
  end
  return nil
end

local function SkillSlotButtonRefresh()
  local _, item = SkillSlotGet()
  item = PL.signature() or item
  ButtonIcon(ROW_ICON_SKILL_SLOT, SkillSlotIcon(item))
  local locked = SkillSlotLock()
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_PV_ROW, ROW_ICON_SKILL_SLOT, not character_reforged_pv_open)
  funcLuaMenuCommand(C.TEXT, L_BTN_SS, 950238781 --[[_text_btn01]], "", 0)
  funcLuaMenuCommand(C.TEXT, L_BTN_SS, 625330766 --[[_text_cmd01]], "", 0)
  return locked
end

-- Shows the info card while the six-sense button has the focus.
local function SkillSlotInfo()
  local signature = PL.signature()
  if signature ~= nil then                        -- read only: the own passive's detail, or nothing without one
    local shown = false
    if signature ~= 0 and PL.passive_detail ~= nil then
      local parts = type(CharacterReforged) == "table" and CharacterReforged.parts or nil
      local passive_display = type(parts) == "table" and parts.passive_display or nil
      local display = type(passive_display) == "table" and passive_display.of(n, signature) or nil
      if type(display) == "table" then
        shown = pcall(PL.passive_detail, display.name, display.effect, signature, display.effect)
      else
        shown = pcall(PL.passive_detail, "", "", signature)
      end
    end
    SetVisibleEquipInfoWindow(false)
    if not shown then
      pcall(CharacterReforged.skill_table_detail_hide)
    end
    funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]],
      PL.txt(signature ~= 0 and PL.TX.SIG_GUIDE or PL.TX.SIG_NONE), 0)
    return
  end
  local _, item = SkillSlotGet()
  local locked, need = SkillSlotLock()
  if item ~= 0 and PL.passive_detail ~= nil then
    local name = SetPreviewCall(@crc:CMND_GET_ITEM_PARAM@, item, 0)
    local eff = SetPreviewCall(SetPreview.PASSIVE, 0, item)
    local desc = eff ~= nil and SetPreviewTeamText(item, eff, 1) or ""
    if pcall(PL.passive_detail, type(name) == "string" and name or PL.txt(PL.TX.PASSIVE), desc, item) then
      SetVisibleEquipInfoWindow(false)
      item = -1                                   -- shown in the panel: skip the card below
    end
  end
  if item == -1 then
  elseif item ~= 0 then
    SetVisibleEquipInfoWindow(true)
    funcLuaMenuCommand(C.ITEM_ICON, L_INFO, 0, 303536660 --[[_icon_item_dmy01]], 1875672568 --[[icon_item_dmy01]], item)
    funcLuaMenuCommand(C.ITEM_ICON, L_INFO, 0, 2334051246 --[[_icon_item_dmy02]], 4140117058 --[[icon_item_dmy02]], item)
    local name = SetPreviewCall(@crc:CMND_GET_ITEM_PARAM@, item, 0)
    funcLuaMenuCommand(C.TEXT, L_INFO, 456522680 --[[_text_item01]], type(name) == "string" and name or PL.txt(PL.TX.PASSIVE), 0)
    local eff = SetPreviewCall(SetPreview.PASSIVE, 0, item)
    local desc = eff ~= nil and SetPreviewTeamText(item, eff, 1) or ""
    funcLuaMenuCommand(C.TEXT, L_INFO, 3138144965 --[[_text_parameter01]], desc, 0)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_INFO, 2634282032 --[[_item_chr_base01]], false, 0)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_INFO, 2787359195 --[[_item_chr_dmy01]], false, 0)
  else
    SetVisibleEquipInfoWindow(false)
  end
  local guide = PL.txt(locked and PL.TX.LOADER or (item ~= 0 and PL.TX.SS_BTN_EQUIPPED or PL.TX.SS_BTN_GUIDE))
  funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]], guide, 0)
end

--@lib vrfw_menu_kit.lua#Pointer
PL.PTR_PV = {-414, 828, 92}
PL.PTR_SS = {-98, 845, 72}
function PL.ptr_start()
  PL.ptr = PL.ptr or VRFW.pointer.new()
  pcall(PL.ptr.reset)
  return PL.ptr
end
function PL.ptr_zones(P, L, nrows, rect, first, total)
  P.begin()
  local top, bottom = nil, nil
  for k = 0, nrows - 1 do
    if first + k < total then
      local ok, x, y = pcall(funcLuaMenuCommand, 4002164178, L, k)
      local split = type(PL.ptr_split) == "function" and PL.ptr_split(k) or nil
      if ok and type(x) == "number" and type(y) == "number" and split ~= nil then
        -- Handles a split row (two halves of one entry).
        for h, r in ipairs(split) do
          P.rect(x + r[1], -y - r[3] / 2, r[2], r[3], h == 1 and k or k + 0.5)
        end
        local rx, ry = x + rect[1], -y - rect[3] / 2
        top = top or {rx, ry}
        bottom = {rx, ry + rect[3]}
      elseif ok and type(x) == "number" and type(y) == "number" then
        local rx, ry = x + rect[1], -y - rect[3] / 2
        P.rect(rx, ry, rect[2], rect[3], k)
        top = top or {rx, ry}
        bottom = {rx, ry + rect[3]}
      end
    end
  end
  if top ~= nil and first > 0 then
    P.rect(top[1], top[2] - 40, rect[2], 40, "up", -1)
  end
  if bottom ~= nil and first + nrows < total then
    P.rect(bottom[1], bottom[2], rect[2], 40, "down", 1)
  end
  return P.poll()
end
function PL.ptr_step(P, L, nrows, rect, first, sel, total)
  local ok, ev = pcall(PL.ptr_zones, P, L, nrows, rect, first, total)
  if not ok or type(ev) ~= "table" then
    return nil, first, sel, false
  end
  local okO, owns = pcall(P.owns)
  owns = okO and owns == true
  -- Returns a split row's halves (PL.ptr_zones).
  local function half(id)
    if type(id) == "number" and id % 1 ~= 0 then
      return math.floor(id), 1
    end
    if type(id) == "number" and PL.row_split ~= nil and PL.row_split[id] then
      return id, 0
    end
    return id, nil
  end
  local cid, ch = half(ev.click)
  local hid, hh = half(ev.hot)
  ev.click, ev.hot = cid, hid
  if ch ~= nil and ch ~= PL.vrm_half then
    PL.vrm_half = ch
    PL.ptr_resync = true
  end
  if hh ~= nil and hh ~= PL.vrm_half and ch == nil then
    PL.vrm_half = hh
    return "moved", first, first + hid, owns
  end
  if type(ev.click) == "number" and first + ev.click < total then
    return "pick", first, first + ev.click, owns
  end
  local d = ev.wheel or ev.edge
  if d ~= nil then
    local f2 = math.max(0, math.min(first + d, total - nrows))
    if f2 ~= first then
      if type(ev.hot) == "number" and f2 + ev.hot < total then
        sel = f2 + ev.hot
      else
        sel = math.max(f2, math.min(sel, f2 + nrows - 1))
      end
      return "moved", f2, sel, owns
    end
  end
  if ev.changed and type(ev.hot) == "number" and first + ev.hot ~= sel and first + ev.hot < total then
    return "moved", first, first + ev.hot, owns
  end
  return nil, first, sel, owns
end

local function OpenSixSense()
  if vrfw_co ~= nil then
    return
  end
  vrfw_co = coroutine.create(function()
    CharacterReforged.skill_slot_pick_coroutine()
  end)
end

local ENABLE_COMMAND = 2559269762
local COMMAND_FCS_NEXT = 2734193315

local SetPreviewPrevSetupLayer = OnSetupLayer
function OnSetupLayer(a1, a2)
  if a1 == L_BTN_ICON then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == L_BTN_SS then
    funcLuaMenuCommand(C.TEXT, a1, 625330766 --[[_text_cmd01]], "", a2)
    funcLuaMenuCommand(C.TEXT, a1, 950238781 --[[_text_btn01]], "", a2)   -- no key glyph (no key is bound)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, a1, a2, 3313461902 --[[cursor]], false)
    return
  elseif a1 == L_PV_PANEL then
    funcLuaMenuCommand(Priority, a1, a2, 900, true)
    for _, pos in ipairs({3448691050, 1839509013, 1437140403, 2946906320,
                          2513278738, 214222504}) do
      funcLuaMenuCommand(POSITION_VISIBLE, a1, pos, false, a2)
    end
    funcLuaMenuCommand(C.MESH_VISIBLE, a1, 3926830396, false, a2)
    funcLuaMenuCommand(C.TEXT, a1, 355816102, "", a2)
    funcLuaMenuCommand(C.TEXT, a1, 59628764, "", a2)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == L_BLACKBG then
    funcLuaMenuCommand(Priority, a1, a2, 880, true)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == L_PV_ROW then
    if a2 == ROW_ICON_PREVIEW then                    -- the unused passive button's icon: never shown
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    elseif a2 == ROW_ICON_SKILL_SLOT then                -- static icons: no Active anime (it animates the row band)
      funcLuaMenuCommand(Priority, a1, a2, 560, true)
      ButtonIcon(a2, TEXTURE_ICON_COMMON, ICON_SIXTH)
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, true)       -- SkillSlotButtonRefresh sets the equipped icon
    else
      funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, a1, a2, 1286797620 --[[Active]], 0, 753088835 --[[Default]])
      funcLuaMenuCommand(Priority, a1, a2, 901, true)
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    end
    return
  end
  SetPreviewPrevSetupLayer(a1, a2)
  if a1 == L_BTN then
    funcLuaMenuCommand(ENABLE_COMMAND, a1, COMMAND_FCS_NEXT, true)       -- right -> the square buttons
  end
end

local SetPreviewPrevOpenLayer = OnOpenLayer
function OnOpenLayer(a1, a2)
  if a1 == L_BTN_ICON then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == L_BTN_SS then
    funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, a1, a2, 2734777837 --[[Focus]], 2, 973515837 --[[button]])
    return
  elseif a1 == L_PV_PANEL or a1 == L_BLACKBG then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, character_reforged_pv_open)
    return
  elseif a1 == L_PV_ROW then
    if a2 < SET_PREVIEW_ROWS then
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, character_reforged_pv_open)
    elseif a2 == ROW_ICON_PREVIEW then
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    else
      character_reforged_icon_frames = 10                         -- the open resets mesh visibility; re-apply a few frames
    end
    return
  end
  SetPreviewPrevOpenLayer(a1, a2)
end

local character_reforged_focus_layer = nil
local SetPreviewPrevChangeFocus = OnChangeFocus
function OnChangeFocus(a1, a2)
  character_reforged_focus_layer = a1
  if a1 == L_BTN_SS then
    n14 = L_BTN
    UpdateEquipItemInfo()
    pcall(SkillSlotInfo)
    return
  end
  SetPreviewPrevChangeFocus(a1, a2)
  if a1 == L_ROW or a1 == L_BTN then
    funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]], PL.txt(GUIDE_TEXT), 0)
  end
end

local SetPreviewPrevDecide = OnDecideFocus
function OnDecideFocus(a1, a2)
  Call(C.LOG, "skill_slots", "decide", a1, a2, "row layer", L_ROW, "ss button", L_BTN_SS)
  if a1 == L_BTN_SS then
    OpenSixSense()
    return
  end
  SetPreviewPrevDecide(a1, a2)
end

-- "Eliminar" on the six-sense button takes the item off
local SetPreviewPrevFunction = OnFunction
function OnFunction(a1, a2)
  if a1 == 4109882573 and character_reforged_focus_layer == L_BTN_SS and vrfw_co == nil and PL.signature() == nil then
    local _, item = SkillSlotGet()
    if item ~= 0 then
      SetPreviewCall(@crc:CMND_CHARACTERREFORGED_SIX_SENSE@, n, 1, 0, -1)
      funcLuaCommand(C.SE, SE_REMOVE)
      SkillSlotButtonRefresh()
      pcall(SkillSlotInfo)
    else
      funcLuaCommand(C.SE, SE_NG)
    end
    return
  end
  SetPreviewPrevFunction(a1, a2)
end

-- The six-sense icon follows the shown player.
local character_reforged_ss_shown = nil
local SetPreviewPrevStep = Step
function Step()
  SetPreviewPrevStep()
  if n ~= nil and n ~= character_reforged_ss_shown and vrfw_co == nil then
    character_reforged_ss_shown = n
    character_reforged_icon_frames = math.max(character_reforged_icon_frames, 3)
  end
  if character_reforged_icon_frames > 0 and vrfw_co == nil and not character_reforged_pv_open then
    character_reforged_icon_frames = character_reforged_icon_frames - 1
    if n ~= nil then
      pcall(SkillSlotButtonRefresh)
    end
  end
end
