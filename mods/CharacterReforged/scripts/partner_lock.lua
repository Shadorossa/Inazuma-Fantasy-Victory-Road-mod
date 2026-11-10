
CharacterReforged = CharacterReforged or {}
local A = CharacterReforged
A.PartnerLock = A.PartnerLock or {}

local Id = VRFW.ids
local u32 = Id.unsigned

local hex = Id.hex_text
local info = VRFW.logger("partner lock")

local BANK_SET = 16
-- the second value the place check answers for a refused partner (any non-zero code refuses)
local PLACE_REFUSED = 77
local DEFAULT_ORDER = 100

local function id_of(k) return Id.parse(k, { hash_names = true }) or 0 end

local function text_of(key)
  if type(key) ~= "string" or key == "" then return "" end
  local ok, s = pcall(VRFW.text, key)
  if ok and type(s) == "string" then return s end
  return ""
end

local SYSTEMS = nil

local function declarations()
  local ok, decl = pcall(VRFW.files.declarations, "content/pairing")
  return ok and type(decl) == "table" and decl or {}
end

local function read_systems()
  local merged = {}
  for _, f in ipairs(declarations()) do
    local d = type(f) == "table" and f.data or nil
    local root = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.PartnerLock or nil
    if type(root) == "table" then
      for system, keys in pairs(root) do
        if type(system) == "string" and type(keys) == "table" then
          local s = merged[system] or { from = "?" }
          for k, v in pairs(keys) do s[k] = v end
          s.from = tostring(f.mod or "?")
          merged[system] = s
        end
      end
    end
  end
  local out = {}
  for system, s in pairs(merged) do
    local e = {
      system = system, mod = s.from, off = s.off == true, order = tonumber(s.order) or DEFAULT_ORDER,
      sprite_name = s.badge_sprite and tostring(s.badge_sprite) or nil, text_key = s.badge_text and tostring(s.badge_text) or nil,
      status_name = s.status_badge and tostring(s.status_badge) or nil,
      status_team_name = s.status_badge_in_team and tostring(s.status_badge_in_team) or nil,
      status_aura_type = tonumber(s.status_aura_type),
    }
    e.sprite, e.text_id, e.status = id_of(e.sprite_name), id_of(e.text_key), id_of(e.status_name)
    e.status_team = id_of(e.status_team_name)
    out[system] = e
  end
  return out
end

-- read once and kept between starts (VRFW.derived)
local function systems()
  if SYSTEMS then return SYSTEMS end
  SYSTEMS = VRFW.derived("partner_lock_systems", nil, read_systems)
  for system, e in pairs(SYSTEMS) do
    info(string.format("system %s (%s): %s, plate %s, text %s, order %d", system, e.mod, e.off and "off" or "on",
      tostring(e.sprite_name), tostring(e.text_key), e.order))
  end
  return SYSTEMS
end

local function system_of(name)
  local s = systems()[name]
  if s then return s end
  s = { system = name, mod = "?", off = false, order = DEFAULT_ORDER, sprite = 0, text_id = 0, status = 0 }
  SYSTEMS[name] = s
  info(string.format("system %s: pairs without a [CharacterReforged.PartnerLock.%s] declaration: locked, no plate", name, name))
  return s
end

local PAIRS = {}      -- system -> { [partner] = base }
local LOCKED = nil

local function rebuild()
  LOCKED = {}
  for name, map in pairs(PAIRS) do
    local s = system_of(name)
    if not s.off then
      for partner, base in pairs(map) do
        local cur = LOCKED[partner]
        if not cur or s.order < cur.s.order or (s.order == cur.s.order and s.system < cur.s.system) then
          LOCKED[partner] = { base = base, s = s }
        end
      end
    end
  end
  return LOCKED
end

local function locked() return LOCKED or rebuild() end

function CharacterReforged.PartnerLockSet(system, list)
  system = tostring(system or "")
  if system == "" then return false end
  local map, n, changed = {}, 0, false
  for _, p in ipairs(type(list) == "table" and list or {}) do
    if type(p) == "table" then
      local partner, base = u32(p.partner or p[1]), u32(p.base or p[2])
      if partner ~= 0 and partner ~= base then
        if not map[partner] then n = n + 1 end
        map[partner] = base
      end
    end
  end
  local old = PAIRS[system] or {}
  for k, v in pairs(map) do if old[k] ~= v then changed = true end end
  for k in pairs(old) do if map[k] == nil then changed = true end end
  if not changed and PAIRS[system] then return true end
  PAIRS[system] = map
  LOCKED = nil
  local shown = {}
  for partner, base in pairs(map) do
    if #shown < 8 then shown[#shown + 1] = hex(partner) .. " (of " .. hex(base) .. ")" end
  end
  info(string.format("system %s: %d partner(s) kept in the bank%s%s", system, n, n > 0 and ": " or "",
    table.concat(shown, ", ") .. (n > #shown and ", …" or "")))
  return true
end

-- (card) -> base, system entry (nil = free)
function A.PartnerLock.Of(card)
  local e = locked()[u32(card)]
  if e then return e.base, e.s end
  return nil
end

-- CMND_CHARACTERREFORGED_PARTNER_LOCK(card) -> base (0 = free), sprite, textId, text
function CharacterReforged.PartnerLock.Get(card)
  local base, s = A.PartnerLock.Of(card)
  if not base then return 0, 0, 0, "" end
  return base, s.sprite or 0, s.text_id or 0, text_of(s.text_key)
end

-- CMND_CHARACTERREFORGED_PARTNER_LOCKS() -> { { card, base, sprite, textId, text }, … }
function CharacterReforged.PartnerLock.List()
  local out, texts = {}, {}
  for card, e in pairs(locked()) do
    local key = e.s.text_key or ""
    if texts[key] == nil then texts[key] = text_of(key) end
    out[#out + 1] = { card, e.base, e.s.sprite or 0, e.s.text_id or 0, texts[key] }
  end
  return out
end

-- CMND_CHARACTERREFORGED_PARTNER_USES() -> { { card, statusSprite, order, isPartner, system }, … } of every paired card
function CharacterReforged.PartnerLock.Uses()
  local best = {}
  local function put(card, s, partner)
    if card == 0 then return end
    local cur = best[card]
    if not cur or s.order < cur.s.order or (s.order == cur.s.order and partner and not cur.partner) then
      best[card] = { s = s, partner = partner }
    end
  end
  for name, map in pairs(PAIRS) do
    local s = system_of(name)
    if not s.off then
      for partner, base in pairs(map) do
        put(partner, s, true)
        put(base, s, false)
      end
    end
  end
  local out = {}
  for card, e in pairs(best) do
    out[#out + 1] = { card, e.s.status or 0, e.s.order, e.partner, e.s.system, e.s.status_team or 0 }
  end
  return out
end

function CharacterReforged.PartnerLock.MixBadge(card)
  local ok, set = pcall(VRFW.skill_set.of, u32(card))
  local move = ok and type(set) == "table" and u32(set.mix or 0) or 0
  if move == 0 then return 0, 0 end
  local okt, aura_type = pcall(VRFW.extra_slot.aura_type, move)
  if not okt or aura_type == nil then return 0, 0 end
  for _, s in pairs(systems()) do
    if not s.off and s.status_aura_type == aura_type then return s.status or 0, s.status_team or 0 end
  end
  return 0, 0
end

local function refused(card, to_set, from_set)
  to_set, from_set = tonumber(to_set) or -1, tonumber(from_set) or -1
  if to_set < 0 or to_set >= BANK_SET or from_set < BANK_SET then return nil end
  local base, s = A.PartnerLock.Of(card)
  if not base then return nil end
  return base, s
end

-- place check 1730898405(hdl, toSet, pos, fromSet, team) -> ok, code
function CharacterReforged.PartnerLock.PlaceCheck(hdl, to_set, pos, from_set)
  local base, s = refused(hdl, to_set, from_set)
  if not base then return false end
  info(string.format("place check %s: bank -> team set %s REFUSED: %s partner of %s", hex(hdl), tostring(to_set), s.system, hex(base)))
  return true, false, PLACE_REFUSED
end

function CharacterReforged.PartnerLock.MoveChara(to_set, pos, from_set, hdl)
  local base, s = refused(hdl, to_set, from_set)
  if not base then return false end
  info(string.format("place %s: bank -> team set %s REFUSED: %s partner of %s", hex(hdl), tostring(to_set), s.system, hex(base)))
  return true, false
end

VRFW.on("game_reset", function()
  PAIRS, LOCKED = {}, nil
end)

do
  local ok, e = pcall(systems)
  if not ok then VRFW.warn("partner lock systems not read at load: " .. tostring(e)) end
end
