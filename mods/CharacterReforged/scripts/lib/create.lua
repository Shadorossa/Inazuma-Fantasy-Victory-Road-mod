
CharacterReforged = CharacterReforged or {}
local A = CharacterReforged
A.Create = A.Create or {}
local K = A.Create

local Id = VRFW.ids
local u32 = Id.unsigned

local hex = Id.hex_text
local info = VRFW.logger("create")

local MOD = "CharacterReforged"
local PLACE_FAILED = -2
-- refusal of a partner without a learned non-grey move (rule partner_needs_learned_move)
local NO_LEARNED_MOVE = -5
-- the partner refusals of the bank that are not a system's check code -> their text keys (the bank's B.REASON)
local BANK_REASONS = {
  [NO_LEARNED_MOVE] = "create_refused_no_learned_move",
  [-6] = "create_refused_only_grey",
  [-7] = "create_refused_in_use",
  [-8] = "create_refused_no_move_for_base",
  [-9] = "create_refused_3",
  [-10] = "create_refused_other",
  [-11] = "create_refused_in_team",
}

local function id_of(k) return Id.parse(k, { hash_names = true }) or 0 end

local SYSTEMS = nil

local function load_systems()
  if SYSTEMS then return SYSTEMS end
  local merged, from = {}, {}
  for _, f in ipairs(A.PairingDeclarations()) do
    local d = type(f) == "table" and f.data or nil
    local root = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.Create or nil
    if type(root) == "table" then
      for system, keys in pairs(root) do
        if type(system) == "string" and type(keys) == "table" then
          local s = merged[system] or { refusals = {} }
          for k, v in pairs(keys) do
            if k == "refusals" and type(v) == "table" then
              for code, key in pairs(v) do s.refusals[tostring(code)] = key end
            else
              s[k] = v
            end
          end
          merged[system] = s
          from[system] = tostring(f.mod or "?")
        end
      end
    end
  end
  local list = {}
  for system, s in pairs(merged) do
    local item, store = id_of(s.item), tostring(s.store or "")
    if s.off == true then
      info(string.format("system %s: off (%s)", system, from[system]))
    elseif item == 0 or store == "" then
      VRFW.warn("create:", string.format("system %s (%s): no `item` or no `store`: no row", system, from[system]))
    else
      list[#list + 1] = {
        system = system, pair_system = tostring(s.system or system), mod = from[system],
        item = item, item_key = tostring(s.item), label = s.label and tostring(s.label) or nil,
        store_name = store, store = id_of(store), carrier = s.carrier, pair_codes = math.floor(tonumber(s.pair_codes) or -1),
        order = tonumber(s.order) or 100, refusals = s.refusals, confirm = s.confirm and tostring(s.confirm) or nil,
        confirm_icon = s.confirm_icon and tostring(s.confirm_icon) or nil, preview = s.preview and tostring(s.preview) or nil,
        scene = s.scene == true, check = s.check and tostring(s.check) or nil,
        prohibited_codes = type(s.prohibited_codes) == "table" and s.prohibited_codes or {},
      }
    end
  end
  table.sort(list, function(x, y)
    if x.order ~= y.order then return x.order < y.order end
    return x.system < y.system
  end)
  for i, s in ipairs(list) do
    info(string.format("row %d: system %s (%s): item %s %s, store %s, carrier %s, pair codes %d", i, s.system, s.mod, s.item_key, hex(s.item), s.store_name, tostring(s.carrier), s.pair_codes))
  end
  SYSTEMS = list
  for _, s in ipairs(list) do A.PairRules(s.pair_system) end
  return list
end

local PROHIBITED_BADGE = nil
local NO_MOVE_BADGE = 0

local function prohibited_badge()
  if PROHIBITED_BADGE then return PROHIBITED_BADGE end
  PROHIBITED_BADGE = 0
  for _, f in ipairs(A.PairingDeclarations()) do
    local d = type(f) == "table" and f.data or nil
    local root = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.PartnerStatus or nil
    if type(root) == "table" and root.prohibited_badge ~= nil then
      PROHIBITED_BADGE = id_of(tostring(root.prohibited_badge))
    end
    if type(root) == "table" and root.no_move_badge ~= nil then
      NO_MOVE_BADGE = id_of(tostring(root.no_move_badge))
    end
  end
  return PROHIBITED_BADGE
end

local SNAP = {}

-- (charaHdl) -> n, create item 1 ..
function CharacterReforged.Create.Begin(hdl)
  hdl = u32(hdl)
  local list = load_systems()
  if #list == 0 then
    info(string.format("begin %s: no system declared: no create row", hex(hdl)))
    return 0
  end
  local b = A.BoardItems(hdl)
  if not b then
    info(string.format("begin %s: not an owned card: no create row", hex(hdl)))
    return 0
  end
  SNAP[hdl] = b
  local out, names = { #list }, {}
  for _, s in ipairs(list) do
    out[#out + 1] = s.item
    names[#names + 1] = s.system
  end
  info(string.format("begin %s: aura piece list with %d create row(s) (%s), board slots remembered", hex(hdl), #list, table.concat(names, ", ")))
  return table.unpack(out)
end

-- () -> n, create item 1 ..
function CharacterReforged.Create.Items()
  local out = { 0 }
  for _, s in ipairs(load_systems()) do out[#out + 1] = s.item end
  out[1] = #out - 1
  return table.unpack(out)
end

-- (item) -> row (0 = not a create item), store command id, scene, check command id, partner needs a learned move
function CharacterReforged.Create.Row(item)
  item = u32(item)
  for i, s in ipairs(load_systems()) do
    if s.item == item then
      info(string.format("row of %s: %d (%s, store %s)", hex(item), i, s.system, s.store_name))
      return i, s.store, s.scene == true, id_of(s.check),
        A.PairRules(s.pair_system).partner_needs_learned_move == true
    end
  end
  return 0, 0, false, 0
end

function CharacterReforged.Create.Picked(hdl)
  hdl = u32(hdl)
  local list = load_systems()
  local now, before = A.BoardItems(hdl), SNAP[hdl]
  if not now then return 0, -1, 0 end
  local function row_of(item)
    for i, s in ipairs(list) do
      if s.item == item then return i end
    end
    return 0
  end
  for slot = 0, 8 do
    local cur = now[slot]
    local prev = before and before[slot] or nil
    if cur and cur.inv ~= 0 and (not prev or prev.inv ~= cur.inv) then
      local i = row_of(cur.item)
      if i > 0 then
        info(string.format("picked %s: row %d (%s) on board slot %d", hex(hdl), i, list[i].system, slot))
        return i, slot, list[i].store
      end
    end
  end
  if before then
    for i, s in ipairs(list) do
      local slot = A.BoardSlotOf(hdl, s.item)
      if slot >= 0 and before[slot] and before[slot].item ~= s.item then
        info(string.format("picked %s: row %d (%s) on board slot %d", hex(hdl), i, s.system, slot))
        return i, slot, s.store
      end
    end
  end
  SNAP[hdl] = nil
  info(string.format("picked %s: no create row picked (the list closed with another aura or none)", hex(hdl)))
  return 0, -1, 0
end

function CharacterReforged.Create.Carrier(i, k)
  local s = load_systems()[math.floor(tonumber(i) or 0)]
  if not s then return 0 end
  local c = s.carrier
  if type(c) == "string" then c = c:gsub("{k}", tostring(math.floor(tonumber(k) or 0))) end
  local id = id_of(c)
  info(string.format("carrier of row %d (%s), k %s: %s %s", i, s.system, tostring(k), tostring(c), hex(id)))
  return id
end

function CharacterReforged.Create.Place(hdl, slot, inv)
  hdl = u32(hdl)
  local ok, why = A.BoardPlace(hdl, slot, inv)
  info(string.format("place %s slot %s: carrier inv %s %s", hex(hdl), tostring(slot), hex(inv), ok and "placed" or ("NOT placed (" .. tostring(why) .. ")")))
  if ok then SNAP[hdl] = nil end
  return ok == true
end

function CharacterReforged.Create.Restore(hdl, slot)
  hdl, slot = u32(hdl), math.floor(tonumber(slot) or -1)
  local prev = SNAP[hdl] and SNAP[hdl][slot]
  SNAP[hdl] = nil
  if not prev or u32(prev.inv) == 0 then
    info(string.format("restore %s slot %d: it held nothing before: the create item stays (a carrier without a pair keeps him himself)", hex(hdl), slot))
    return false
  end
  local ok, why = A.BoardPlace(hdl, slot, u32(prev.inv))
  info(string.format("restore %s slot %d: %s back (%s)", hex(hdl), slot, hex(prev.item), ok and "ok" or tostring(why)))
  return ok == true
end

local function text_of(key)
  local ok, s = pcall(VRFW.text, key)
  if ok and type(s) == "string" then return s end
  return ""
end

-- the most partner moves a pair carries (the framework's miximax keeps 1 or 2)
local MAX_MOVES = 2

function CharacterReforged.Create.Moves(i)
  local s = load_systems()[math.floor(tonumber(i) or 0)]
  if not s then return 0, 0, "", 0, 0, 0, {}, prohibited_badge(), false, 0, true end
  local n = math.floor(tonumber(A.PairRules(s.pair_system).moves) or 0)
  n = math.max(0, math.min(MAX_MOVES, n))
  local key = s.confirm or (MOD .. ".create_confirm")
  info(string.format("moves of row %s (%s): %d, confirmation %s", tostring(i), s.system, n, key))
  return n, id_of(key), text_of(key), id_of(s.confirm_icon), id_of(s.preview),
    id_of(s.check), s.prohibited_codes, prohibited_badge(), A.PairRules(s.pair_system).partner_needs_learned_move == true,
    NO_MOVE_BADGE, A.PairRules(s.pair_system).partner_may_be_in_team ~= false
end

function CharacterReforged.Create.Refusal(i, code)
  local s = load_systems()[math.floor(tonumber(i) or 0)]
  code = math.floor(tonumber(code) or -1)
  if code == 0 then return 0, 0, "", "" end
  local reason
  if code == PLACE_FAILED then
    reason = MOD .. ".create_refused_place"
  elseif BANK_REASONS[code] then
    reason = MOD .. "." .. BANK_REASONS[code]
  elseif s and s.refusals[tostring(code)] then
    reason = tostring(s.refusals[tostring(code)])
  elseif s and s.pair_codes >= 0 and code > s.pair_codes and code <= s.pair_codes + 9 then
    reason = string.format("%s.create_refused_%d", MOD, code - s.pair_codes)
  else
    reason = MOD .. ".create_refused_other"
  end
  local label = s and s.label or nil
  local label_id = label and id_of(label) or 0
  local label_text = label and text_of(label) or ""
  info(string.format("refusal row %s (%s): code %d -> %s (window: «%s» / «%s»)", tostring(i), s and s.system or "?", code, reason, label_text, text_of(reason)))
  return label_id, id_of(reason), label_text, text_of(reason)
end

function CharacterReforged.Create.Log(step, ...)
  local parts = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "number" and v == math.floor(v) and (v > 0xFFFF or v < 0) then
      parts[#parts + 1] = hex(v)
    else
      parts[#parts + 1] = tostring(v)
    end
  end
  info(string.format("board %s: %s", tostring(step), table.concat(parts, " ")))
  return true
end

-- the systems are read again after a hot reload of the mods' files
VRFW.on("game_reset", function()
  SYSTEMS = nil
  PROHIBITED_BADGE = nil
  SNAP = {}
end)

return K
