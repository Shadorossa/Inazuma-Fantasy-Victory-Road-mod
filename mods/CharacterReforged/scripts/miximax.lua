
CharacterReforged = CharacterReforged or {}
CharacterReforged.Miximaxed = CharacterReforged.Miximaxed or {}
local M = CharacterReforged.Miximaxed
local SYSTEM = "miximax"
local BLOB = "miximax.json"
local StatTransfer = require "lib/miximax_stat_transfer"
local Scene = require "lib/miximax_scene"

local Id = VRFW.ids
local Actors = VRFW.players
local u32 = Id.unsigned

local hex = Id.hex_text
local info, warn = VRFW.logger("CharacterReforged miximax")

local function mx(op)
  local ok, r = pcall(VRFW.miximax.call, op)
  if ok then return r end
  return nil
end

-- the active slot's fusion store { version, fusions = { … } }
local function store()
  local s = mx { op = "store" }
  if type(s) == "table" and type(s[2]) == "table" then return s[2] end
  return { version = 1, fusions = {} }
end

local function pairs_of(fusions)
  local out = {}
  for i, f in ipairs(type(fusions) == "table" and fusions or {}) do
    out[i] = { base = u32(f.base_hdl), partner = u32(f.partner_hdl), partner_chara = u32(f.partner_chara) }
  end
  return out
end

local function publish_locks(fusions)
  local list = {}
  for _, f in ipairs(type(fusions) == "table" and fusions or {}) do
    local partner, base = u32(f.partner_hdl), u32(f.base_hdl)
    if partner ~= 0 then list[#list + 1] = { partner, base } end
  end
  local api = rawget(_G, "CharacterReforged")
  if type(api) == "table" and api.PartnerLockSet then pcall(api.PartnerLockSet, SYSTEM, list) end
end

local LAST = {}
function CharacterReforged.Miximaxed.Validity(fusions)
  local codes = CharacterReforged.PairValidity(SYSTEM, pairs_of(fusions))
  publish_locks(fusions)
  for i, f in ipairs(type(fusions) == "table" and fusions or {}) do
    local b, v = u32(f.base_hdl), codes[i] or 0
    if LAST[b] ~= v then
      LAST[b] = v
      info(string.format("fusion %s + %s: %s", hex(b), hex(f.partner_hdl), v == 0 and "ON" or ("OFF (code " .. v .. ")")))
    end
  end
  return codes
end

local function without_empty_lists(record)
  local out = {}
  for k, v in pairs(type(record) == "table" and record or {}) do
    if not (type(v) == "table" and next(v) == nil) then out[k] = v end
  end
  return out
end

local CHECK = nil   -- { base, others }

-- the reason of each Set code, in words (one loader.log line per refusal)
local REFUSAL_WORDS = {
  [1] = "the VRFW's miximax look is not running",
  [11] = "the base is not an owned card", [12] = "the partner is not an owned card", [13] = "the base and the partner are the same card",
  [14] = "the base and the partner are the same character", [15] = "the base's rarity may not be fused",
  [16] = "the partner's rarity may not be a partner", [17] = "the partner is already the partner of another player",
  [18] = "the partner is the base of another miximax", [19] = "the base is already the partner of another miximax",
  [20] = "not a retail / declared pair and no mod turns the any-pair generator on",
  [21] = "the framework could not make the fusion record", [22] = "the framework did not store the fusion",
  [23] = "no saved card can be his partner", [24] = "the base's model has no head",
}

local function refused(code, base, partner, detail)
  local words = REFUSAL_WORDS[code] or "unknown reason"
  warn(string.format("set %s + %s refused (code %d): %s%s", hex(base), hex(partner), code, words, detail and (" - " .. detail) or ""))
  return code
end

local SLOW_SET_MS = 20

-- the pair (base, partner) stored as a fusion with the partner moves `move1` / `move2` the player picked (0 = none).
function CharacterReforged.Miximaxed.Set(base, partner, move1, move2)
  base, partner = u32(base), u32(partner)
  local moves = {}
  for _, m in ipairs({ u32(move1), u32(move2) }) do
    if m ~= 0 then moves[#moves + 1] = m end
  end
  local started = VRFW.now_ms()
  local steps = {}
  local function step(name) steps[#steps + 1] = string.format("%s %d ms", name, VRFW.now_ms() - started) end
  if mx { op = "status" } == nil then return refused(1, base, partner) end
  local st = store()
  step("store")
  local others = {}
  for _, p in ipairs(pairs_of(st.fusions)) do
    if p.base ~= base then others[#others + 1] = p end
  end
  local code, other = CharacterReforged.PairCheck(SYSTEM, base, partner, others)
  step("pair check")
  if code ~= 0 then
    return refused(10 + code, base, partner, u32(other) ~= 0 and ("other base " .. hex(other)) or nil)
  end
  local b, p = CharacterReforged.Card(base), CharacterReforged.Card(partner)
  step("cards")
  if type(b) ~= "table" or type(p) ~= "table" then
    return refused(type(b) ~= "table" and 11 or 12, base, partner, "no card record")
  end
  if mx { op = "allowed", base_param = b.param, base_chara = b.chara, partner_chara = p.chara } == false then
    return refused(20, base, partner)
  end
  local r = mx { op = "make", base_hdl = base, base_param = b.param, partner_hdl = partner, partner_param = p.param, moves = #moves > 0 and moves or { 0 } }
  step("make")
  if type(r) ~= "table" or type(r.Ok) ~= "table" then
    return refused(21, base, partner, type(r) == "table" and ("framework code " .. tostring(r.Err)) or "no answer")
  end
  local fusion = r.Ok.f or r.Ok
  local w = mx { op = "put", fusion = without_empty_lists(fusion) }
  pcall(Scene.ended, "new fusion")
  step("put")
  if VRFW.now_ms() - started >= SLOW_SET_MS then
    info(string.format("set %s + %s slow: %s", hex(base), hex(partner), table.concat(steps, ", ")))
  end
  if type(w) ~= "table" or w.Err then
    return refused(22, base, partner, type(w) == "table" and ("framework code " .. tostring(w.Err) .. " (5 same card, 7 write error)") or "the framework did not read the record")
  end
  publish_locks(store().fusions)
  CHECK = nil
  local kept = {}
  for _, m in ipairs(type(fusion.moves) == "table" and fusion.moves or {}) do kept[#kept + 1] = hex(m) end
  info(string.format("fusion %s (%s) + %s (%s) stored, partner moves [%s]", hex(base), tostring(fusion.base), hex(partner), tostring(fusion.partner), table.concat(kept, ", ")))
  return 0
end

local function check_pairs(base)
  if CHECK and CHECK.base == base then return CHECK.others end
  local others = {}
  for _, p in ipairs(pairs_of(store().fusions)) do
    if p.base ~= base then others[#others + 1] = p end
  end
  CHECK = { base = base, others = others }
  return others
end

local function pair_code(base, partner, others)
  local code = CharacterReforged.PairCheck(SYSTEM, base, partner, others)
  if code ~= 0 then return 10 + code end
  local b, p = CharacterReforged.Card(base), CharacterReforged.Card(partner)
  if type(b) ~= "table" then return 11 end
  if type(p) ~= "table" then return 12 end
  if mx { op = "allowed", base_param = b.param, base_chara = b.chara, partner_chara = p.chara } == false then return 20 end
  return 0
end

-- CMND_CHARACTERREFORGED_MIXIMAX_CHECK(base, partner) -> code (0 = a miximax can be made).
function CharacterReforged.Miximaxed.Check(base, partner)
  base, partner = u32(base), u32(partner)
  if mx { op = "status" } == nil then return 1 end
  if partner ~= 0 then return pair_code(base, partner, check_pairs(base)) end
  CHECK = nil
  local card = CharacterReforged.Card(base)
  if type(card) == "table" and mx { op = "has_head", chara = card.chara } == false then return 24 end
  local others = check_pairs(base)
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle" })
  local first = 12
  for _, handle in ipairs(ok and type(columns) == "table" and columns.handle or {}) do
    local h = u32(handle)
    if h ~= 0 and h ~= base then
      local code = pair_code(base, h, others)
      if code == 0 then return 0 end
      -- a refusal of the base himself ends the scan (it is the same for every partner)
      if code == 11 or code == 15 or code == 19 then
        info(string.format("check %s: no miximax (code %d)", hex(base), code))
        return code
      end
      first = code
    end
  end
  info(string.format("check %s: no saved card can be his partner (last code %d)", hex(base), first))
  return 23
end

function CharacterReforged.Miximaxed.Get(base)
  local l = mx { op = "fusion_of", hdl = u32(base) }
  local f = type(l) == "table" and (l.f or l) or nil
  if type(f) ~= "table" then return 0, 0 end
  return u32(f.partner_hdl), u32(f.partner_chara)
end

function CharacterReforged.Miximaxed.Clear(base)
  local ok = mx { op = "clear", hdl = u32(base) } == true
  publish_locks(store().fusions)
  CHECK = nil
  return ok
end

-- the running fusion record of a card ({ f, overdrive }), nil = none
local function record_of(card)
  local l = mx { op = "fusion_of", hdl = u32(card) }
  if type(l) == "table" and type(l.f) == "table" then return l end
  return nil
end

local function record_or_owner(card)
  if card == 0 then return nil end
  local l = record_of(card)
  if l then return l end
  local owner = VRFW.character.copy_owner(card)
  return owner and record_of(owner) or nil
end

-- The text key that says why a stored fusion is off, by its validity code (pairing.lua PairValidity).
local OFF_TEXT = { [2] = "create_refused_2", [4] = "create_refused_7", [6] = "create_refused_6" }

local function text_of(key)
  local ok, s = pcall(VRFW.text, "CharacterReforged." .. key)
  return ok and type(s) == "string" and s or ""
end

-- The stored fusion of a base card, running or off.
local function stored_of(card)
  for _, f in ipairs(store().fusions or {}) do
    if u32(f.base_hdl) == card then return f end
  end
  return nil
end

-- (card) -> exists, partner param, move 1, move 2, partner chara, best match, partner handle, off reason, inactive label, partner-in-team reason
function CharacterReforged.Miximaxed.FusionGet(card)
  card = u32(card)
  local l = record_or_owner(card)
  local f = l and l.f or stored_of(card)
  if not f then return false, 0, 0, 0, 0, false, 0 end
  local mv = type(f.moves) == "table" and f.moves or {}
  local best = f.best_match == true or (l ~= nil and u32(l.overdrive) ~= 0)
  local code = LAST[u32(f.base_hdl)] or 0
  local off = code ~= 0 and text_of(OFF_TEXT[code] or "create_refused_other") or ""
  local label, in_team = CharacterReforged.PartnerInTeamTexts(SYSTEM)
  return true, u32(f.partner_param), u32(mv[1]), u32(mv[2]), u32(f.partner_chara), best, u32(f.partner_hdl),
    off, label ~= "" and label or text_of("pair_inactive_label"), in_team
end

function CharacterReforged.Miximaxed.Gains(card)
  if not StatTransfer.Owned() then return false end
  local okm, adds = pcall(CharacterReforged.MixAddsStats, card)
  if okm and adds == false then return false end
  local l = record_of(card)
  if not l then return false end
  local mask, g = StatTransfer.Gains(l)
  if not mask then return false end
  local okp, pe, pe_favoured = pcall(StatTransfer.PeGain, l)
  pe = okp and tonumber(pe) or 0
  return true, mask, g[1], g[2], g[3], g[4], g[5], g[6], g[7], g[8], g[9], StatTransfer.Kind(l), pe or 0,
    (okp and pe_favoured == true) and 1 or 0
end

function CharacterReforged.Miximaxed.Preview(base, partner, move)
  if not StatTransfer.Owned() then return false end
  base, partner = u32(base), u32(partner)
  local b, p = CharacterReforged.Card(base), CharacterReforged.Card(partner)
  if type(b) ~= "table" or type(p) ~= "table" then return false end
  local r = mx { op = "make", base_hdl = base, base_param = b.param, partner_hdl = partner, partner_param = p.param, moves = { u32(move) } }
  local l = type(r) == "table" and type(r.Ok) == "table" and r.Ok or nil
  if not l or type(l.f) ~= "table" then
    info(string.format("preview %s + %s: no fusion record (%s)", hex(base), hex(partner), type(r) == "table" and tostring(r.Err) or "no answer"))
    return false
  end
  local mask, g = StatTransfer.Gains(l)
  if not mask then return false end
  local okp, pe, pe_favoured = pcall(StatTransfer.PeGain, l)
  pe = okp and tonumber(pe) or 0
  local pe_base = (pe or 0) > 0 and StatTransfer.PeBase(l) or 0
  info(string.format("preview %s + %s move %s: kind %d mask %d, PE %d +%d", hex(base), hex(partner), hex(move), StatTransfer.Kind(l), mask, pe_base, pe or 0))
  return true, mask, g[1], g[2], g[3], g[4], g[5], g[6], g[7], g[8], g[9], StatTransfer.Kind(l), pe or 0,
    (okp and pe_favoured == true) and 1 or 0, pe_base
end

local SKILL_SET_SLOT = "CharacterReforged.skill_set"
local ACTOR_CHARA = "Actor.Chara"                   -- the player's own card on his actor record (game profile)
local PE_SOURCE = "miximax"
local PE_ON = {}                                     -- actor handle -> PE added this fusion

local function own_card(hdl)
  local e = Actors.of(hdl)
  local okf, at = pcall(VRFW.game.field, ACTOR_CHARA)
  if not e or not okf or type(at) ~= "number" then return 0 end
  return u32(VRFW.memory.read("u32", e.address + at))
end

VRFW.on("extra_slot:" .. SKILL_SET_SLOT .. ":fusion_start", function(ev)
  local a = ev and ev.actor
  if not a or not a.handle or not StatTransfer.Owned() then return end
  local chara = own_card(a.handle)
  local l = record_or_owner(chara)
  if not l then
    chara = u32(a.chara or 0)
    l = record_or_owner(chara)
  end
  local mask, g = nil, nil
  if l then mask, g = StatTransfer.Gains(l) end
  if not mask then
    info(string.format("match: actor %s chara %s: fusion stats: no stored pair / partner stats (retail stats, no PE)", hex(a.handle), hex(chara)))
    return
  end
  local gains = {}
  for i = 1, 8 do gains[i] = g[i] or 0 end
  local ok = VRFW.extra_slot.fusion_stats(a.handle, gains)
  local okp, pe = pcall(StatTransfer.PeGain, l)
  pe = okp and math.max(0, math.floor(tonumber(pe) or 0)) or 0
  local pe_given, code = false, nil
  local key = StatTransfer.Rules().pe_resource
  if pe > 0 and key and type(VRFW.resource) == "table" and type(VRFW.resource.set_max_add) == "function" then
    local okc, done, c = pcall(VRFW.resource.set_max_add, key, a.handle, PE_SOURCE, pe)
    pe_given, code = okc and done == true, okc and c or done
    if pe_given then PE_ON[a.handle] = pe end
  end
  info(string.format("match: actor %s chara %s: fusion stats %s (%s, kind %d), max PE +%d (%s)", hex(a.handle), hex(chara),
    table.concat(gains, ","), ok and "given" or "refused", StatTransfer.Kind(l), pe,
    pe == 0 and "none" or (pe_given and "given" or ("not given: " .. tostring(code)))))
end)

VRFW.on("extra_slot:" .. SKILL_SET_SLOT .. ":fusion_end", function(ev)
  local a = ev and ev.actor
  if not a or not a.handle or not PE_ON[a.handle] then return end
  local pe = PE_ON[a.handle]
  PE_ON[a.handle] = nil
  local okc, done = pcall(VRFW.resource.set_max_add, StatTransfer.Rules().pe_resource, a.handle, PE_SOURCE, 0)
  info(string.format("match: actor %s: fusion over: max PE -%d (%s)", hex(a.handle), pe, (okc and done == true) and "taken off" or "not taken off"))
end)

VRFW.on("match_start", function() PE_ON = {} end)

-- CMND_CHARACTERREFORGED_MIXIMAX_SCENE(base) -> ok, event, map, partnerHdl, finalEvent, effectsOk | false, why
function CharacterReforged.Miximaxed.Scene(b)
  local base = u32(b)
  local l = record_of(base)
  if not l then
    warn(string.format("scene: base %s: no valid fusion for this card", hex(base)))
    return false, "no valid fusion for this card"
  end
  local ok, final, effects = Scene.prepare(base, l.f)
  if not ok then
    warn(string.format("scene: base %s: %s", hex(base), tostring(final)))
    return false, final
  end
  return true, Scene.EVENT, Scene.MAP, u32(l.f.partner_hdl), final, effects
end

-- CMND_CHARACTERREFORGED_MIXIMAX_SCENE_STATE() -> pending, base, seconds
function CharacterReforged.Miximaxed.SceneState() return Scene.state() end

function CharacterReforged.Miximaxed.SceneEnd(why) Scene.ended(tostring(why or "")) end

Scene.load()

-- the stored fusions of the active slot (a copy)
function CharacterReforged.Miximaxed.Fusions() return store().fusions or {} end

-- the store's saved text of save slot `slot` (nil = none)
function CharacterReforged.Miximaxed.StoreBlob(slot)
  local ok, data = pcall(VRFW.save.get_blob, tonumber(slot) or 1, BLOB)
  if ok and type(data) == "string" then return data end
  return nil
end

CharacterReforged.MixFusions = CharacterReforged.Miximaxed.Fusions
CharacterReforged.MixStoreBlob = CharacterReforged.Miximaxed.StoreBlob

VRFW.on("slot_load", function()
  pcall(StatTransfer.Owned)
  pcall(StatTransfer.Rules)
  publish_locks(store().fusions)
end)
