-- BetterQoL › team planner («Planificador de equipo»): ghost cards in the team dock's squads, like the squad planners
-- of FIFA Ultimate Team.
--
-- * The menu side (graft research/grafts/util_team_planner): A on an empty slot of a squad («Formación» of the team
--   dock) offers «Añadir del banco» (the game's bank) and «Planificar equipo»: the same game bank, whose list also holds
--   every character of the game and of the mods the save does not own (his normal card, drawn at the display rarity,
--   semi-transparent); an owned pick goes into the slot, one not owned becomes a GHOST in the slot (drawn
--   semi-transparent over the empty slot; never a card, never in the bank, never playable).
-- * This script: the catalogue (the original-names catalogue of series / teams / characters + each character's card
--   param from chara_param), the rule (config.toml [team_planner] + other mods' content\team_planner\*.toml), the owned
--   copies (VRFW.character.saved / record), the plans (blob team_planner.json per save slot), the bank's plan list
--   (hook BetterQoL.TpBankSort on the bank list's sort) and the commands below.
-- * Automatic assignment: the menu side asks the qualifying copies of a ghost's character (CMND_BETTERQOL_TP_CANDIDATES)
--   when the dock opens, places one with the game's own placement and reports it (CMND_BETTERQOL_TP_ASSIGNED).
--
-- Commands (content\game\team_planner.toml): CMND_BETTERQOL_TP_INFO / _LIST / _SET / _MOVE / _CANDIDATES / _ASSIGNED / _PENDING /
-- _BANK_PLAN / _BANK_ENTRY.

local C = require "lib/tp_core"
local Cat = require "lib/original_names_catalogue"

BetterQoL = BetterQoL or {}
BetterQoL.TeamPlanner = BetterQoL.TeamPlanner or {}
local TP = BetterQoL.TeamPlanner

-- other mods' rule (schema BetterQoL.team_planner/1): content\team_planner\*.toml of each mod
local DECL_PATHS = { "content/team_planner", "team_planner" }
local KEY_MOUNTED = "BetterQoL.team_banks.mounted"
local OWNED_TTL_MS = 2000

require "VRFW/lib/basics"
require "VRFW/lib/save_doc"
local info, warn = VRFW.logger("team_planner")

local int, u32 = C.int, C.u32

-- ---------------------------------------------------------------------------------------- settings

local cfg = {
  enabled = true,
  ghost_alpha = 0.45,
}
local rule = nil
local catalogue = nil     -- { cat = original-names catalogue, card = { [chara_base] = param }, rows = { [series] = … } }

local function load_cfg()
  local ok, c = pcall(VRFW.files.config, "team_planner")
  if not ok or type(c) ~= "table" then
    c = nil
  end
  if c then
    if type(c.enabled) == "boolean" then
      cfg.enabled = c.enabled
    end
    if type(c.ghost_alpha) == "number" and c.ghost_alpha > 0 and c.ghost_alpha <= 1 then
      cfg.ghost_alpha = c.ghost_alpha
    end
  end
  local okd, decls = pcall(VRFW.files.declarations, DECL_PATHS)
  local notes = {}
  rule = C.rule(c, okd and decls or {}, notes)
  for _, n in ipairs(notes) do
    warn(n)
  end
  info("rule (" .. rule.source .. "): " .. C.rule_sig(rule))
end

-- ---------------------------------------------------------------------------------------- the catalogue

local function build_catalogue()
  local ok, err = pcall(function()
    -- built once and kept between starts (VRFW.derived), keyed on the rule too
    catalogue = VRFW.derived("team_planner_catalogue", C.rule_sig(rule), function()
      local cat = Cat.build(Cat.series_rows(), Cat.belong_rows(), Cat.charas(), Cat.declarations())
      local rows = {}
      for _, r in ipairs(VRFW.table.rows("character/chara_param")) do
        local p, b, s = r[1], r[2], r[42]
        if type(p) == "number" and type(b) == "number" then
          rows[#rows + 1] = { u32(p), u32(b), type(s) == "number" and s or 0 }
        end
      end
      local card, n = C.card_params(rows, rule.card_values)
      info(string.format("catalogue: %d series, %d character(s), %d with a card (of %d chara_param rows)", #cat.series,
        #cat.charas, n, #rows))
      return { cat = cat, card = card, rows = {} }
    end)
  end)
  if not ok then
    catalogue = nil
    warn("no catalogue (" .. tostring(err) .. "): the plan bank lists only owned players")
  end
end

-- the team rows of series index `si` with only the characters that have a card: { { team, players = { ci … } } }
local function series_rows(si)
  local K = catalogue
  local s = K and K.cat.series[si]
  if not s then
    return {}
  end
  local cached = K.rows[si]
  if cached then
    return cached
  end
  local out = {}
  for _, r in ipairs(Cat.rows(K.cat, s)) do
    local pl = {}
    for _, ci in ipairs(r.players) do
      local c = K.cat.charas[ci]
      if K.card[c[8]] then
        pl[#pl + 1] = ci
      end
    end
    if #pl > 0 then
      out[#out + 1] = { team = r.team, players = pl }
    end
  end
  K.rows[si] = out
  return out
end

-- the series that have at least one team row (their indices in the catalogue)
local pages = nil
local function page_list()
  if pages then
    return pages
  end
  pages = {}
  if catalogue then
    for si = 1, #catalogue.cat.series do
      if #series_rows(si) > 0 then
        pages[#pages + 1] = si
      end
    end
  end
  return pages
end

-- ---------------------------------------------------------------------------------------- owned copies

local owned_cache, owned_at = nil, nil

-- param -> { { h, rarity, level } … } of the saved characters (cached OWNED_TTL_MS)
local function owned_index()
  local now = VRFW.now()
  if owned_cache and owned_at and now - owned_at < OWNED_TTL_MS then
    return owned_cache
  end
  local idx = {}
  local ok, list = pcall(VRFW.character.saved)
  if ok and type(list) == "table" then
    for _, c in ipairs(list) do
      local h = int(c.handle)
      local p = u32(c.param)
      if h and h ~= 0 and p ~= 0 then
        local okr, rec = pcall(VRFW.character.record, h)
        local rar = (okr and type(rec) == "table" and int(rec.rarity)) or 0
        local l = idx[p]
        if not l then
          l = {}
          idx[p] = l
        end
        l[#l + 1] = { h = h, rarity = rar, level = int(c.level) or 0 }
      end
    end
  else
    warn("saved characters not read (" .. tostring(list) .. ")")
  end
  owned_cache, owned_at = idx, now
  return idx
end

-- ---------------------------------------------------------------------------------------- the store

-- the plans of a slot: read again after a load, copy, delete, new game or reset of that slot (the slot events);
-- staged with the game's save of the slot (written at once without the slot service)
local DOC = VRFW.save.doc(C.BLOB, {
  decode = C.decode_doc,
  encode = C.encode_doc,
  default = C.new_file,
  pretty = true,
  stage = true,
  log = "team_planner",
  loaded = function(f, slot, state)
    if state ~= "bad" then info("slot " .. slot .. ": " .. C.count(f) .. " planned slot(s)") end
  end,
})

local store = nil

local function current_slot()
  local ok, s = pcall(VRFW.slots.active)
  return ok and s or 0
end

local function ensure_store()
  local slot = current_slot()
  if not slot or slot == 0 then
    return nil
  end
  local okr, reserved = pcall(VRFW.slots.reserved, slot)
  if okr and reserved then
    return nil
  end
  store = DOC:get(slot)
  return store
end

local function commit(why)
  if not store or not store.dirty then
    return
  end
  local ok, where = DOC:write(store, store.slot)
  if ok then
    store.dirty = false
  else
    VRFW.error("team_planner: cannot write slot " .. store.slot .. ": " .. tostring(where) .. " (" .. why .. ")")
  end
end

-- the mounted team-bank page (0 without pages)
local function page()
  local ok, v = pcall(VRFW.state, KEY_MOUNTED)
  v = ok and int(v) or nil
  if not v or v < 0 then
    return 0
  end
  return v
end

-- ---------------------------------------------------------------------------------------- commands: the plans

-- CMND_BETTERQOL_TP_INFO() -> on, ghost alpha, display rarity
function BetterQoL.TeamPlanner.Info()
  return cfg.enabled and ensure_store() ~= nil, cfg.ghost_alpha, rule.display_rarity
end

-- CMND_BETTERQOL_TP_LIST(set, type) -> "slot:param,…" of the squad on the mounted page ("" = none), display rarity
function BetterQoL.TeamPlanner.List(set, ty)
  local f = cfg.enabled and ensure_store() or nil
  set, ty = int(set), int(ty) or 0
  if not f or not set then
    return "", rule.display_rarity
  end
  return C.list_text(f, C.squad_key(page(), set, ty)), rule.display_rarity
end

-- CMND_BETTERQOL_TP_SET(set, type, slot, param) -> ok (param 0 = clear the slot's plan)
function BetterQoL.TeamPlanner.Set(set, ty, slot, param)
  local f = cfg.enabled and ensure_store() or nil
  set, ty, slot, param = int(set), int(ty) or 0, int(slot), u32(param or 0)
  if not f or not set or not C.valid_slot(slot) then
    return false
  end
  local key = C.squad_key(page(), set, ty)
  if C.set(f, key, slot, param) then
    info(string.format("squad %s slot %d: %s", key, slot, param == 0 and "plan removed" or string.format("planned 0x%08X", param)))
    commit("plan")
  end
  return true
end

-- CMND_BETTERQOL_TP_MOVE(from set, from type, from slot, to set, to type, to slot) -> ok: a plan moved, swapping with a
-- plan on the other slot, written as one change
function BetterQoL.TeamPlanner.Move(fs, ft, from, ts, tt, to)
  local f = cfg.enabled and ensure_store() or nil
  fs, ft, from, ts, tt, to = int(fs), int(ft) or 0, int(from), int(ts), int(tt) or 0, int(to)
  if not f or not fs or not ts or not C.valid_slot(from) or not C.valid_slot(to) then
    return false
  end
  local p = page()
  if not C.move(f, C.squad_key(p, fs, ft), from, C.squad_key(p, ts, tt), to) then
    return false
  end
  info(string.format("squad %d:%d slot %d -> squad %d:%d slot %d: plan moved", fs, ft, from, ts, tt, to))
  commit("move")
  return true
end

-- CMND_BETTERQOL_TP_CANDIDATES(param) -> "h,h,…" the qualifying owned copies of a card, best first ("" = none)
function BetterQoL.TeamPlanner.Candidates(param)
  param = u32(param or 0)
  if param == 0 then
    return ""
  end
  local l = C.candidates(rule, owned_index()[param])
  local parts = {}
  for _, c in ipairs(l) do
    parts[#parts + 1] = tostring(c.h)
  end
  return table.concat(parts, ",")
end

-- CMND_BETTERQOL_TP_ASSIGNED(set, type, slot, handle) -> ok: the menu placed a real copy in a ghost's slot
function BetterQoL.TeamPlanner.Assigned(set, ty, slot, h)
  local f = ensure_store()
  set, ty, slot = int(set), int(ty) or 0, int(slot)
  if not f or not set or not C.valid_slot(slot) then
    return false
  end
  local key = C.squad_key(page(), set, ty)
  local sq = f.plans[key]
  local p = sq and sq[slot] or 0
  C.set(f, key, slot, 0)
  info(string.format("squad %s slot %d: 0x%08X assigned (handle 0x%X)", key, slot, p, int(h) or 0))
  owned_cache = nil
  commit("assigned")
  return true
end

-- CMND_BETTERQOL_TP_PENDING() -> "set:type,…" the squads of the mounted page that hold plans ("" = none)
function BetterQoL.TeamPlanner.Pending()
  local f = cfg.enabled and ensure_store() or nil
  if not f then
    return ""
  end
  return C.pending_text(f, page())
end

-- ---------------------------------------------------------------------------------------- the plan bank

-- «Planificar equipo» opens the game's bank (chara_bank_menu) with the plan rule: after the game has built and sorted
-- the bank's list (its owned cards, the bank's tab, filter and search applied), the hook on the list's sort appends one
-- row per character of the catalogue the save does not own, the way the game's own param list (list kind 0x1000)
-- writes them: handle 0 and the character's card param, each one asked to the bank's own filter first (so the tabs,
-- the filter window and the name search apply to them too). Before a later sort of the same list they are taken off
-- (a sort keeps them out; the post hook appends them again). The menu side draws a row without a handle from its param.
local KEY_PLAN_STATE = "BetterQoL.tp_bank_plan"
-- the bank's list (CharaBankList, the bank list object + 0x1E0): count, row pointers, row storage (8 bytes a row:
-- handle, param), the game's row cap; its filter is the object's + 0x4678C (= the list + 0x465AC)
local LIST_COUNT, LIST_ROWS, LIST_STORE, LIST_CAP, LIST_FILTER = 0x8, 0x10, 0xBBAC, 0x1772, 0x465AC
local CHUNK = 2048
local plan = { on = false, list = nil, owned = 0, total = 0, params = nil, logged = nil }

local base_of = nil   -- chara_param id -> chara_base (static game data, read once)
local function param_bases()
  if base_of then
    return base_of
  end
  base_of = {}
  for _, r in ipairs(VRFW.table.rows("character/chara_param")) do
    if type(r[1]) == "number" and type(r[2]) == "number" then
      base_of[u32(r[1])] = u32(r[2])
    end
  end
  return base_of
end

-- the card params of every character of the catalogue the save has no copy of (any card), in catalogue order
local function not_owned_params()
  if not catalogue then
    return {}
  end
  local bases = param_bases()
  local have = {}
  for p in pairs(owned_index()) do
    local b = bases[p]
    if b then
      have[b] = true
    end
  end
  local out, seen = {}, {}
  for _, si in ipairs(page_list()) do
    for _, r in ipairs(series_rows(si)) do
      for _, ci in ipairs(r.players) do
        local b = catalogue.cat.charas[ci][8]
        if not seen[b] then
          seen[b] = true
          local p = catalogue.card[b]
          if p and not have[b] then
            out[#out + 1] = p
          end
        end
      end
    end
  end
  return out
end

local function rd(ty, a)
  local ok, v = pcall(VRFW.mem.read, ty, a)
  if ok then
    return v
  end
  return nil
end

-- the handle of row i of a list (nil = unreadable)
local function row_handle(list, i)
  local row = rd("ptr", list + LIST_ROWS + i * 8)
  return row and row >= 0x10000 and rd("u32", row) or nil
end

-- before the game sorts the plan list: the rows this script appended go (they are appended again after the sort)
VRFW.on("hook:BetterQoL.TpBankSort", function(ev)
  local list = ev.args[1]
  if not plan.on or plan.list ~= list or plan.total <= plan.owned then
    return nil
  end
  if rd("u32", list + LIST_COUNT) == plan.total and row_handle(list, plan.owned) == 0 then
    pcall(VRFW.mem.write, "u32", list + LIST_COUNT, plan.owned)
  end
  plan.total = 0
  return nil
end)

-- after the game sorted the plan list: one row per character not owned that the bank's filter accepts
VRFW.on("hook:BetterQoL.TpBankSort:post", function(ev)
  local list = ev.args[1]
  if not plan.on or not plan.params then
    return nil
  end
  if plan.list == nil then
    plan.list = list   -- the first list the open bank sorts is its list
  elseif plan.list ~= list then
    return nil
  end
  local n = rd("u32", list + LIST_COUNT)
  local okb, buf = pcall(VRFW.mem.buffer, "tp_bank_param", 8)
  if not n or n >= LIST_CAP or not okb then
    return nil
  end
  local owned, filter = n, list + LIST_FILTER
  local rows, ptrs = {}, {}
  local function flush()
    if #ptrs == 0 then
      return true
    end
    local first = n - #ptrs
    local ok1 = pcall(VRFW.mem.write_array, "u32", list + LIST_STORE + first * 8, rows)
    local ok2 = ok1 and pcall(VRFW.mem.write_array, "u64", list + LIST_ROWS + first * 8, ptrs)
    rows, ptrs = {}, {}
    return ok2
  end
  for _, p in ipairs(plan.params) do
    if n >= LIST_CAP then
      break
    end
    VRFW.mem.write("u32", buf, p)
    local okc, pass = pcall(VRFW.call, "BetterQoL.TpBankFilter", list, 0, buf, filter)
    if okc and (pass == true or pass == 1) then
      rows[#rows + 1] = 0
      rows[#rows + 1] = p
      ptrs[#ptrs + 1] = list + LIST_STORE + n * 8
      n = n + 1
      if #ptrs >= CHUNK and not flush() then
        warn("plan bank: rows not written: the list keeps its owned cards")
        return nil
      end
    end
  end
  if not flush() then
    warn("plan bank: rows not written: the list keeps its owned cards")
    return nil
  end
  pcall(VRFW.mem.write, "u32", list + LIST_COUNT, n)
  plan.owned, plan.total = owned, n
  local sig = owned .. ":" .. (n - owned)
  if plan.logged ~= sig then
    plan.logged = sig
    info(string.format("plan bank: %d owned card(s) + %d character(s) not owned listed (of %d)%s", owned, n - owned,
      #plan.params, n >= LIST_CAP and ", the list is full" or ""))
  end
  return nil
end)

-- CMND_BETTERQOL_TP_BANK_PLAN(on) -> on: the characters not owned the bank will list (the list's next build lists
-- them); off: the bank lists only owned cards again
function BetterQoL.TeamPlanner.BankPlan(on)
  if on ~= true then
    if plan.on then
      plan.on = false
      pcall(VRFW.state.set, KEY_PLAN_STATE, 0)
      info("plan bank: off")
    end
    plan.list, plan.owned, plan.total, plan.params, plan.logged = nil, 0, 0, nil, nil
    return 0
  end
  if not cfg.enabled then
    return false
  end
  owned_cache = nil
  plan.params = not_owned_params()
  plan.list, plan.owned, plan.total, plan.logged = nil, 0, 0, nil
  plan.on = true
  pcall(VRFW.state.set, KEY_PLAN_STATE, 1)
  if not VRFW.is_on("BetterQoL.TpBankSort") or not VRFW.is_on("BetterQoL.TpBankFilter") then
    warn("plan bank: hook BetterQoL.TpBankSort / function BetterQoL.TpBankFilter off: the bank lists only owned cards")
  end
  info(string.format("plan bank: on, %d character(s) not owned", #plan.params))
  return #plan.params
end

-- CMND_BETTERQOL_TP_BANK_ENTRY(i) -> the card param of row i (0-based) of the plan list when it is a character not
-- owned, else 0
function BetterQoL.TeamPlanner.BankEntry(i)
  i = int(i)
  local list = plan.list
  if not plan.on or not list or not i or i < plan.owned or i >= plan.total then
    return 0
  end
  local row = rd("ptr", list + LIST_ROWS + i * 8)
  if not row or row < 0x10000 or rd("u32", row) ~= 0 then
    return 0
  end
  return rd("u32", row + 4) or 0
end

-- ---------------------------------------------------------------------------------------- start

load_cfg()
if cfg.enabled then
  build_catalogue()
else
  info("off ([team_planner] enabled = false)")
end
