
CharacterReforged = CharacterReforged or {}
CharacterReforged.BoardRole = CharacterReforged.BoardRole or {}
local R = CharacterReforged.BoardRole

local info, warn = VRFW.logger("board_role")

local ST_OK, ST_REFUSED = 1, 0
local ST_BAD_ARGS, ST_NOT_READY, ST_EXCEPTION, ST_NO_RECORD, ST_NEED_MATCHES = -1, -2, -4, -5, -10

local BADGE_COACH, BADGE_MANAGER = 0x9B6947D9, 0xEC6E774F -- abl_000002 / abl_000003
local ATTR_NATIVE_COACH, ATTR_NATIVE_MANAGER = 0x10, 0x20

local ON = false
local HANDLE_BUFFER, ITEM_BUFFER
local LAYOUT = nil

local Id = VRFW.ids
local u32 = Id.unsigned

local function int(v) return VRFW.value.integer(v, nil) end

local hex = Id.hex_text

local read = VRFW.memory.read

local function write(kind, addr, v)
  return (VRFW.memory.write(kind, addr, v))
end

local band = bit32.band

-- the game profile's value of a name (lib/profile.lua)
local profile_field = require("lib/profile").field

local function layout()
  local l = {
    handle = profile_field("CharaData.Handle"), attribute = profile_field("CharaData.Attribute"),
    badge = profile_field("CharaData.Badge"), play_count = profile_field("CharaData.PlayCount"),
    item = profile_field("InventoryRecord.Item"), equipped = profile_field("InventoryRecord.Equipped"),
  }
  for _, name in ipairs({ "handle", "attribute", "badge", "play_count", "item", "equipped" }) do
    if l[name] == nil then return nil end
  end
  return l
end

local function inv_record(inv)
  if inv == 0 then return nil end
  local items = VRFW.game.character_reforged_items()
  if not items then return nil end
  local ok, p = pcall(VRFW.call, "Board.InvRecord", items, inv)
  if not ok or not p or p < 0x10000 then return nil end
  return p
end

local function item_of(inv)
  local p = inv_record(inv)
  return p and read("u32", p + LAYOUT.item) or 0
end

-- rec8 of a character handle, checked against the handle
local function record_of(hdl)
  local kind = math.floor(hdl / 4096) % 16
  if hdl == 0 or kind >= 0xD then return nil end
  local ok, r = pcall(VRFW.character.record, hdl)
  if not ok or not r or not r.addr or r.addr < 0x10000 then return nil end
  if read("u32", r.addr + LAYOUT.handle) ~= hdl then return nil end
  return r.addr
end

-- rec8, badge, item, plays, attr of a saved character
local function state(hdl)
  local rec8 = record_of(hdl)
  if not rec8 then return nil end
  local badge = read("u32", rec8 + LAYOUT.badge)
  if badge == nil then return nil end
  local item = badge ~= 0 and item_of(badge) or 0
  return rec8, badge, item, read("u16", rec8 + LAYOUT.play_count) or 0, read("u32", rec8 + LAYOUT.attribute) or 0
end

local function role_of_item(item)
  if item == BADGE_COACH then return 1 end
  if item == BADGE_MANAGER then return 2 end
  if item == 0 then return 0 end
  return 3
end

local function current_role(badge, item)
  if badge == 0 then return 0 end
  if item == 0 then return 3 end
  return role_of_item(item)
end

local function native_role(attr)
  if band(attr, ATTR_NATIVE_COACH) ~= 0 then return 1 end
  if band(attr, ATTR_NATIVE_MANAGER) ~= 0 then return 2 end
  return 0
end

local function plan(role, badge, item, attr)
  if not role or role < 0 or role > 2 then return nil, ST_BAD_ARGS end
  local native = band(attr, ATTR_NATIVE_COACH + ATTR_NATIVE_MANAGER) ~= 0
  if role == 0 then
    return { unequip = badge ~= 0, clear_native = native }
  end
  if current_role(badge, item) == role then return { unequip = false, clear_native = false } end
  return { unequip = badge ~= 0, equip = role == 1 and BADGE_COACH or BADGE_MANAGER, clear_native = native }
end

local THRESHOLDS = { 0, 0 }
local function thresholds() return THRESHOLDS[1], THRESHOLDS[2] end

function CharacterReforged.SetRoleMedalThresholds(required, created)
  local function clamp(v) return math.max(0, math.min(65535, math.floor(tonumber(v) or 0))) end
  THRESHOLDS = { clamp(required), clamp(created) }
end

local function matches_missing(p, badge, plays, attr)
  if not p.equip or badge ~= 0 then return 0 end
  local need, need_created = thresholds()
  if need == 0 and need_created == 0 then return 0 end
  local n = band(attr, ATTR_NATIVE_COACH + ATTR_NATIVE_MANAGER) ~= 0 and need_created or need
  return math.max(0, n - plays)
end

local function engine(fn, hdl, value)
  write("u32", HANDLE_BUFFER, hdl)
  write("u32", ITEM_BUFFER, value)
  return (pcall(VRFW.call, fn, HANDLE_BUFFER, ITEM_BUFFER))
end

local function release_by_hand(rec8, badge)
  local p = inv_record(badge)
  if p then
    local item, equipped = read("u32", p + LAYOUT.item), read("u32", p + LAYOUT.equipped)
    if (item == BADGE_COACH or item == BADGE_MANAGER) and equipped and equipped > 0 then
      write("u32", p + LAYOUT.equipped, equipped - 1)
    end
  end
  write("u32", rec8 + LAYOUT.badge, 0)
end

-- without_matches = the match requirement is not checked
local function set_role(hdl, role, without_matches)
  local missing = 0
  local function run()
    if not ON then return nil, ST_NOT_READY end
    local _, badge, item, plays, attr = state(hdl)
    if badge == nil then return nil, ST_NO_RECORD end
    local p, why = plan(role, badge, item, attr)
    if not p then return nil, why end
    missing = without_matches and 0 or matches_missing(p, badge, plays, attr)
    if missing > 0 then return nil, ST_NEED_MATCHES end
    if p.unequip then
      if not engine("CharacterReforged.BadgeUnequip", hdl, badge) then return nil, ST_EXCEPTION end
      local rec8, left = state(hdl)
      if not rec8 then return nil, ST_NO_RECORD end
      if left ~= 0 then
        warn(string.format("SET_ROLE(%s): the engine left badge %s (item %s); released by hand", hex(hdl), hex(left), hex(item)))
        release_by_hand(rec8, left)
      end
    end
    if p.clear_native then
      local rec8, _, _, _, a = state(hdl)
      if not rec8 then return nil, ST_NO_RECORD end
      local cleared = a - band(a, ATTR_NATIVE_COACH + ATTR_NATIVE_MANAGER)
      write("u32", rec8 + LAYOUT.attribute, cleared)
      info(string.format("SET_ROLE(%s): creation-time staff bits cleared (attribute 0x%X -> 0x%X)", hex(hdl), a, cleared))
    end
    if p.equip then
      if not engine("CharacterReforged.BadgeEquip", hdl, p.equip) then return nil, ST_EXCEPTION end
    end
    local _, b, now = state(hdl)
    if b == nil then return nil, ST_NO_RECORD end
    return current_role(b, now)
  end
  local r, e = run()
  local status, after
  if r ~= nil then
    status, after = (r == role) and ST_OK or ST_REFUSED, r
  elseif e == ST_NEED_MATCHES then
    status, after = e, missing
  else
    status, after = e, -1
  end
  info(string.format("SET_ROLE(%s, %s) -> status %d, role now %d", hex(hdl), tostring(role), status, after))
  return status, after
end

function R.GetRole(hdl)
  if not ON then return false end
  hdl = u32(hdl)
  local _, badge, item, plays, attr = state(hdl)
  if badge == nil then return ST_NO_RECORD, 0, 0, 0, 0 end
  return current_role(badge, item), badge, plays, native_role(attr), 0
end

function R.SetRole(hdl, role)
  if not ON then return false end
  return set_role(u32(hdl), int(role) or -1)
end

-- { role (0 none, 1 coach, 2 manager, 3 unknown badge), attribute (the record's attribute word) }, nil = no record / off
function CharacterReforged.BoardRoleState(hdl)
  if not ON then return nil end
  hdl = u32(hdl)
  local _, badge, item, _, attr = state(hdl)
  if badge == nil then return nil end
  return { role = current_role(badge, item), attribute = attr }
end

function CharacterReforged.BoardRoleSetWithoutMatches(hdl, role)
  if not ON then return { status = ST_NOT_READY, role = -1 } end
  local status, after = set_role(u32(hdl), int(role) or -1, true)
  return { status = status, role = after }
end

-- the status codes and the creation-time staff bits of the attribute word
function CharacterReforged.BoardRoleCodes()
  return { ok = ST_OK, no_record = ST_NO_RECORD, native_staff = ATTR_NATIVE_COACH + ATTR_NATIVE_MANAGER }
end

HANDLE_BUFFER = VRFW.memory.buffer("character_reforged_role_hdl", 8)
ITEM_BUFFER = VRFW.memory.buffer("character_reforged_role_item", 8)
LAYOUT = layout()
ON = VRFW.is_on("CharacterReforged.BadgeEquip") and VRFW.is_on("CharacterReforged.BadgeUnequip") and LAYOUT ~= nil
if ON then
  info("role commands active (CMND_CHARACTERREFORGED_GET_ROLE / _SET_ROLE)")
elseif LAYOUT == nil then
  VRFW.error("board_role: the game profile has no CharaData / InventoryRecord role fields: the role slot cannot change roles")
else
  VRFW.error("board_role: badge signatures not resolved: the role slot cannot change roles")
end
