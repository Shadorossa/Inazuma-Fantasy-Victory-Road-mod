-- Team templates: one list 1..count; the game's 11 docks hold 11 of them, the others are stored with the save slot.
local B = VRFW.bytes
local S = require "lib/template_store"

BetterQoL = BetterQoL or {}
BetterQoL.TeamTemplates = BetterQoL.TeamTemplates or {}
local TT = BetterQoL.TeamTemplates

local band, lshift = bit32.band, bit32.lshift
local C = S.code

local BLOB, BEST = "team_templates.bin", "team_templates.best.bin"
local DECL_FILE = "BetterQoL/team_templates.toml"
local KEY_COUNT, KEY_ACTIVE = "BetterQoL.team_templates.count", "BetterQoL.team_templates.active"
local KEY_LOADS = "vrfw.party.loads" -- the framework's party service counts every Party.Load
local RIVAL_DOC = "team_templates.rival" -- the words of the team set a one-match rival replaced
local RIVAL_SET = S.LAST_DOCK + 1 -- the first team set after the docks
local REC_TEAM_FLAG = 0x1EC

local info, warn, err = VRFW.logger("team_templates")

local Memory = VRFW.memory
local read_memory, game_global = Memory.read, VRFW.game.global

local int = VRFW.value.integer

local CFG = { count = S.DEFAULT_COUNT, verify = false, blocked = { "story" }, decl_mods = {} }

do
  local function cfg(path) return VRFW.config("team_templates." .. path) end
  local count = cfg("count")
  if type(count) == "number" then CFG.count = count end
  local vf = cfg("verify")
  if type(vf) == "boolean" then CFG.verify = vf end
  local bm = cfg("blocked_modes")
  if type(bm) == "table" then
    CFG.blocked = {}
    for _, m in ipairs(bm) do
      if type(m) == "string" then CFG.blocked[#CFG.blocked + 1] = m end
    end
  end
  local ok, decls = pcall(VRFW.files.declarations, DECL_FILE)
  if ok and type(decls) == "table" then
    for _, e in ipairs(decls) do
      local d = type(e.data) == "table" and e.data or {}
      local mc, modes = d.min_count, d.blocked_modes
      if (mc ~= nil and type(mc) ~= "number") or (modes ~= nil and type(modes) ~= "table") then
        warn(DECL_FILE .. " of mod " .. tostring(e.mod) .. " ignored: min_count must be a number, blocked_modes a list")
      else
        if mc and mc > CFG.count then CFG.count = mc end
        for _, m in ipairs(modes or {}) do
          local seen = false
          for _, x in ipairs(CFG.blocked) do
            if x == m then seen = true end
          end
          if not seen and type(m) == "string" then CFG.blocked[#CFG.blocked + 1] = m end
        end
        CFG.decl_mods[#CFG.decl_mods + 1] = tostring(e.mod)
      end
    end
  end
  CFG.count = S.clamp_count(CFG.count)
end

local remap -- logical -> physical team set

local function table_ok()
  if remap then return remap end
  local t, seen = {}, {}
  for l = 0, 15 do
    local p = VRFW.squads.physical_index(l)
    if p == nil or seen[p] then
      return nil
    end
    seen[p] = true
    t[l] = p
  end
  remap = t
  return t
end

local function party_ptr()
  if not table_ok() then return nil end
  return game_global("team_template_party")
end

local function active_slot()
  local ok, s = pcall(VRFW.slots.active)
  if ok and type(s) == "number" then return s end
  return 1
end

local function blocked_mode()
  local known = false
  for _, m in ipairs(CFG.blocked) do
    local ok, v = pcall(VRFW.state, "mode.is." .. m)
    if ok and type(v) == "number" then
      if v == 1 then return true end
      known = true
    end
  end
  if known or #CFG.blocked == 0 then return false end
  return nil
end

local function usable(slot)
  return slot >= 2 and blocked_mode() == false
end

local function job_pending()
  local gdb = game_global("team_template_game_data_backup")
  if not gdb then return nil end
  local ok, r = pcall(VRFW.call, "TT_IsJobPending", gdb)
  if not ok or type(r) ~= "number" then return nil end
  return band(r, 0xFF) ~= 0
end

local function set_base(party)
  local t = table_ok()
  local data = party and read_memory("ptr", party + S.PARTY_SET_DATA)
  if not t or not data then return nil end
  return data, t
end

-- the words of one logical team set (nil when not readable)
local function read_set(data, t, logical)
  local a = VRFW.memory.read_array("u32", data + t[logical] * S.SET_SIZE, S.WPD)
  return type(a) == "table" and a or nil
end

-- the 11 live docks as words (nil when not readable), one read_array per dock
local function live_docks(party)
  local data, t = set_base(party)
  if not data then return nil end
  local w, n = {}, 0
  for d = 0, S.DOCKS - 1 do
    local a = read_set(data, t, S.FIRST_DOCK + d)
    if not a then return nil end
    for i = 1, S.WPD do
      n = n + 1
      w[n] = a[i]
    end
  end
  return w
end

local function record(h)
  local ok, r = pcall(VRFW.character.record, h)
  if ok and type(r) == "table" then return r end
  return nil
end

-- param, get_order of a live character handle (nil when stale)
local function ident(h)
  local r = record(h)
  if r then return r.param or 0, r.get_order or 0 end
  return nil
end

local function team_flag(h)
  local r = record(h)
  if not r or not r.addr then return nil end
  return read_memory("u16", r.addr + REC_TEAM_FLAG)
end

-- Returns the docks (0-based) that the vs, esports and tournament active team sets point at.
local function active_docks(party)
  local out = {}
  for i = 0, 2 do
    local v = read_memory("u8", party + S.ACTIVE_OFF + i)
    if v == nil then return nil end
    if v >= S.FIRST_DOCK and v <= S.LAST_DOCK then out[v - S.FIRST_DOCK] = true end
  end
  return out
end

-- writes logical set `l` from the words of `w` after `base`, with the Re-Story swap recipe
local function write_set(data, t, l, w, base)
  local set = data + t[l] * S.SET_SIZE
  -- the dock bit belongs to the members of teams 0 and 1
  local function bits(on)
    for tm = 0, S.FLAG_TEAMS - 1 do
      for k = 0, S.MEMBERS - 1 do
        local ok, e = VRFW.squads.set_organized(set + S.member_off(tm, k), l, on)
        if not ok then
          return string.format("SetOrganizedFlagBit set %d team %d: %s", l, tm, tostring(e))
        end
      end
    end
    return nil
  end
  local e = bits(false)
  if e then return false, e end
  local ok, e2 = pcall(function()
    -- only the words that differ are written
    local cur = VRFW.memory.read_array("u32", set, S.TEAM_WORDS)
    if type(cur) ~= "table" then error("TeamInfo not readable") end
    for i = 0, S.TEAM_WORDS - 1 do
      local v = w[base + i + 1]
      if cur[i + 1] ~= v then
        VRFW.memory.write("u32", set + i * 4, v)
      end
    end
  end)
  if not ok then return false, string.format("TeamInfo copy set %d: %s", l, tostring(e2)) end
  e = bits(true)
  if e then return false, e end
  for tm = 0, S.TEAMS - 1 do
    local ok3, e3 = VRFW.squads.recount(set + tm * S.TEAM_SIZE)
    if not ok3 then return false, string.format("RecountTeamInfo set %d team %d: %s", l, tm, tostring(e3)) end
  end
  return true
end

-- per-dock report (log) -> crc32 of the 11 docks, flag errors, team-0 members
local function verify_docks(party, why)
  local w = live_docks(party)
  if not w then return nil end
  local flag_errors, members, line = 0, 0, {}
  for d = 0, S.DOCKS - 1 do
    local l = S.FIRST_DOCK + d
    local n = S.team0_count(w, d)
    members = members + n
    for _, m in ipairs(S.flag_members(w, d)) do
      local f = team_flag(m[3])
      local bit = f and band(f, lshift(1, l)) ~= 0
      if bit ~= true then
        flag_errors = flag_errors + 1
        warn(string.format("[%s] dock %02d team %d slot %d: handle 0x%s flag bit %d = %s", why, d + 1, m[1], m[2], B.word_hex_text(m[3]), l, tostring(f and bit)))
      end
    end
    line[#line + 1] = string.format(" %02d:%s/%d", d + 1, B.word_hex_text(S.crc32(B.text_of_words(w, d * S.WPD + 1, (d + 1) * S.WPD))), n)
  end
  local crc = S.crc32(B.text_of_words(w))
  info(string.format("[%s] docks crc %s, team-0 members %d, flag errors %d |%s", why, B.word_hex_text(crc), members, flag_errors, table.concat(line)))
  return crc, flag_errors, members
end

local store_key_bytes
local function store_key()
  if store_key_bytes ~= nil then return store_key_bytes or nil end
  local ok, hex = false, nil
  if type(VRFW.build) == "table" and type(VRFW.build.store_key) == "function" then
    ok, hex = pcall(VRFW.build.store_key)
  end
  store_key_bytes = (ok and type(hex) == "string" and #hex == 40) and B.from_hex_text(hex) or false
  if not store_key_bytes then
    warn("the build's store key is not available (VRFW.build.store_key): template files are read whatever build wrote them")
  end
  return store_key_bytes or nil
end

local SS = {
  state = nil,        -- template state of the running game (lib/template_store)
  gen = 0,
  dirty = false,      -- `state` differs from the file on disk
  restage = false,
  new_game = {},      -- [slot] = a new_game event not handled yet
  cleared = {},       -- [slot] = a new game cleared every stored template (the next stage may drop them)
  ev_seen = 0,        -- slot events read
  loads_seen = nil,
  came_back = false,
  committed = nil,
  best = {},          -- [slot] = stored templates of team_templates.best.bin (-1 = none)
  staged = nil,       -- { slot, bytes, st, cleared, gen, best }
  pins = {},          -- [owner] = template a screen or mode keeps in its dock
  rival_pending = false,  -- a rival is in its team set and its match has not started
  rival_playing = false,  -- the match of a rival is running
  rival_checked = nil,    -- the slot whose rival record was checked after a load
}

do
  local ok, seq = pcall(VRFW.slots.event_seq)
  if ok and type(seq) == "number" then SS.ev_seen = math.max(0, seq - 64) end
end

local loads_warned = false
local function loads_now()
  local ok, v = pcall(VRFW.state, KEY_LOADS)
  if ok and type(v) == "number" then return v end
  if not loads_warned then
    loads_warned = true
    warn("game_state " .. KEY_LOADS .. " is not answered (hook VRFW.PartyLoad off): a switch back into a slot is taken as a load")
  end
  return nil
end

local reset_loads = nil
VRFW.on("game_reset", function()
  reset_loads = loads_now()
  return nil
end)
-- the docks are the ones a reset left until the next Party.Load
local function docks_from_reset()
  if reset_loads == nil then return false end
  if loads_now() ~= reset_loads then
    reset_loads = nil
    return false
  end
  return true
end

local function changed()
  SS.gen = SS.gen + 1
  SS.dirty = true
end

local function forget_slot(slot)
  if SS.state and SS.state.slot == slot then
    SS.state, SS.dirty, SS.restage = nil, false, false
  end
  if SS.committed and SS.committed.slot == slot then SS.committed = nil end
  if SS.staged and SS.staged.slot == slot then SS.staged = nil end
  SS.best[slot] = nil
end

local function on_saved(slot)
  local s = SS.staged
  if not s or s.slot ~= slot then return end
  SS.committed = { slot = slot, bytes = s.bytes, st = s.st, strict = true }
  if s.best then SS.best[slot] = s.best end
  if s.cleared then SS.cleared[slot] = nil end
  if SS.state and SS.state.slot == slot and SS.gen == s.gen then SS.dirty = false end
  SS.staged = nil
  info(string.format("templates of slot %d committed with the game's save (%d bytes, stored %d)", slot, #s.bytes, S.stored_count(s.st)))
end

-- read the slot events not seen yet
local function poll()
  local okq, seq = pcall(VRFW.slots.event_seq)
  if not okq or type(seq) ~= "number" then return end
  while SS.ev_seen < seq do
    SS.ev_seen = SS.ev_seen + 1
    local ok, kind, a, b = pcall(VRFW.slots.event, SS.ev_seen)
    if not ok or not kind then
      warn("slot event #" .. SS.ev_seen .. " is gone (ring full): ignored, templates kept")
    elseif kind == "new_game" then
      info("the slot service reports a new game in slot " .. a .. ": its next use starts with the 11 docks only")
      forget_slot(a)
      SS.new_game[a] = true
    elseif kind == "saved" then
      on_saved(a)
    elseif kind == "switched" then
      if SS.staged and SS.staged.slot == b then
        SS.staged = nil
        if SS.state and SS.state.slot == b and SS.dirty then SS.restage = true end
      end
      if SS.state and SS.state.slot == a then SS.came_back = true end
    elseif kind == "deleted" or kind == "reset" then
      forget_slot(a)
    elseif kind == "copied" then
      forget_slot(b)
    end
  end
end

local NO_FILE_LOGGED = {}
local function read_file(slot, party, unloaded)
  SS.best[slot] = nil
  if slot < 2 then return S.fresh(slot, CFG.count) end
  local best = VRFW.save.doc.read_text(BEST, slot)
  local bst = type(best) == "string" and S.decode(best) or nil
  SS.best[slot] = bst and S.stored_count(bst) or -1
  local bytes, why = VRFW.save.doc.read_text(BLOB, slot)
  if bytes == nil then
    SS.committed = nil
    if why then
      err("cannot read the templates of slot " .. slot .. " (" .. tostring(why) .. "): starting with the 11 docks only; the file is left as it is")
    elseif not NO_FILE_LOGGED[slot] then
      NO_FILE_LOGGED[slot] = true
      info(string.format("slot %d has no stored templates yet: templates 1-11 are the save's docks", slot))
    end
    return S.fresh(slot, CFG.count)
  end
  local st, bad = S.decode(bytes, slot, store_key())
  SS.committed = { slot = slot, bytes = bytes, st = st or S.decode(bytes), strict = st ~= nil }
  if not st then
    err("the templates of slot " .. slot .. " were rejected: " .. tostring(bad) .. ": starting with the 11 docks only (the file stays until a template change replaces it)")
    return S.fresh(slot, CFG.count)
  end
  local before = #st.templates
  local now = S.resize(st, CFG.count)
  if now ~= before then
    info(string.format("slot %d: %d templates, config %d: now %d (used templates are never dropped)", slot, before, CFG.count, now))
  end
  local w = party and live_docks(party)
  if not w then
    warn("docks not readable: templates used without check")
  else
    local fp = S.fingerprint(w)
    if fp == st.fingerprint then
      info("templates of slot " .. slot .. " match the loaded docks (fp " .. B.word_hex_text(fp) .. ")")
    elseif unloaded then
      info(string.format("templates of slot %d: the save is not loaded yet (fp %s, live %s): checked again when it loads", slot, B.word_hex_text(st.fingerprint), B.word_hex_text(fp)))
    else
      warn(string.format("templates of slot %d were written with other docks (fp %s, live %s): an older / restored save, or docks changed since the last template change. The stored templates are used; the docks keep what the save holds", slot, B.word_hex_text(st.fingerprint), B.word_hex_text(fp)))
    end
  end
  info(string.format("slot %d: %d templates, stored %d, docks hold %s", slot, #st.templates, S.stored_count(st), TT.docks_text(st)))
  return st
end

function TT.docks_text(st)
  local v = {}
  for d = 0, S.DOCKS - 1 do v[d + 1] = tostring(st.docks[d]) end
  return table.concat(v, " ")
end

local function sha1_for(st)
  local k = store_key()
  if k then return k end
  if st.sha1 then return st.sha1 end
  local c = SS.committed
  if c and c.st and c.st.sha1 then return c.st.sha1 end
  return S.ZERO_SHA1
end

local function stage(why)
  local st = SS.state
  if not st or st.slot < 2 then return false end
  local slot = st.slot
  local party = party_ptr()
  local w = party and live_docks(party)
  if not w then
    err("cannot read the party docks: templates not staged (" .. why .. ")")
    return false
  end
  local fp = S.fingerprint(w)
  local old = SS.committed
  if old and old.slot ~= slot then old = nil end
  if old and old.st and old.strict and not SS.cleared[slot] then
    local back = S.heal(st, old.st)
    if #back > 0 then
      changed()
      warn("slot " .. slot .. ": the running state had lost template(s) " .. S.numbers_text(back) .. " that the file on disk still stores: put back")
    end
  end
  local bytes = S.encode(st, sha1_for(st), fp)
  local best
  if old and old.st then
    local lost = S.lost(old.st, st)
    if #lost > 0 and not SS.cleared[slot] then
      err(string.format("templates of slot %d NOT staged: they would lose stored template(s) %s; the file on disk keeps them (report this log)", slot, S.numbers_text(lost)))
      return false
    end
    local bc = SS.best[slot]
    local oc = S.stored_count(old.st)
    if (bc == nil or oc >= bc) and old.bytes ~= bytes then best = oc end
  elseif old and old.bytes and not old.asided then
    local ok, where = VRFW.save.doc.set_aside(BLOB, slot)
    warn("slot " .. slot .. ": unreadable template file " .. (ok and tostring(where) or "not set aside"))
    old.asided = true
  end
  local ok, okst, where = pcall(VRFW.save.blob_stage, BLOB, bytes, slot)
  if not ok or not okst then
    err("templates of slot " .. slot .. " not staged: " .. tostring(ok and where or okst))
    return false
  end
  if best then
    local okb, okbs, whereb = pcall(VRFW.save.blob_stage, BEST, old.bytes, slot)
    if not okb or not okbs then
      warn("best copy of slot " .. slot .. " not staged: " .. tostring(okb and whereb or okbs))
      best = nil
    end
  end
  st.fingerprint = fp
  SS.staged = { slot = slot, bytes = bytes, st = S.copy(st), cleared = SS.cleared[slot], gen = SS.gen, best = best }
  SS.restage = false
  info(string.format("templates of slot %d staged (%s): %d bytes, stored %d, fp %s; written with the game's next save", slot, why, #bytes, S.stored_count(st), B.word_hex_text(fp)))
  return true
end

-- the template state of the running game for `slot`
local function resolve(slot, party)
  poll()
  local loads = loads_now()
  if SS.new_game[slot] then
    SS.new_game[slot] = nil
    SS.state = S.fresh(slot, CFG.count)
    SS.pins, SS.cleared[slot] = {}, true
    SS.came_back, SS.loads_seen = false, loads
    changed()
    info("slot " .. slot .. ": new game: templates 1-11 only (the save engine moved the old slot data to its trash)")
    return SS.state
  end
  local reread = SS.state == nil or SS.state.slot ~= slot
  if not reread then
    if loads ~= nil then
      reread = SS.loads_seen ~= nil and loads ~= SS.loads_seen
    else
      reread = SS.came_back
    end
    if reread then info("slot " .. slot .. ": the save was loaded: its template file is the state") end
  end
  SS.came_back = false
  SS.loads_seen = loads
  if reread then
    local stale = SS.staged ~= nil and SS.staged.slot == slot
    SS.staged = nil
    SS.state = read_file(slot, party, loads == 0 or docks_from_reset())
    SS.pins, SS.cleared[slot] = {}, nil
    SS.gen, SS.dirty, SS.restage = SS.gen + 1, false, false
    if stale and slot >= 2 then stage("the loaded save's templates back on the stage") end
  elseif SS.restage and SS.dirty and slot >= 2 then
    info("slot " .. slot .. ": the switch was not completed (the game in memory is unchanged): template changes staged again")
    stage("restage after an aborted switch")
  end
  return SS.state
end

local function publish()
  local function set(k, v) pcall(VRFW.state.set, k, v) end
  if not party_ptr() then
    set(KEY_COUNT, 0)
    set(KEY_ACTIVE, 0)
    return
  end
  set(KEY_COUNT, CFG.count)
  set(KEY_ACTIVE, usable(active_slot()) and 1 or 0)
end

local function rival_kept(slot)
  local text = VRFW.save.doc.read_text(RIVAL_DOC, slot)
  return type(text) == "string" and #text > 0 and text or nil
end

-- puts back the team set a rival replaced; false when it could not
local function rival_end(slot, party)
  local kept = rival_kept(slot)
  SS.rival_pending, SS.rival_playing = false, false
  if not kept then return true end
  local data, t = set_base(party)
  if not data then return false end
  local ok, e = write_set(data, t, RIVAL_SET, B.read_words(kept, 0, S.WPD), 0)
  if not ok then
    err("team set of the rival not put back: " .. tostring(e))
    return false
  end
  local aside, where = VRFW.save.doc.set_aside(RIVAL_DOC, slot)
  if not aside then warn("the kept team set of slot " .. slot .. " stays on record after it was put back: " .. tostring(where)) end
  info("slot " .. slot .. ": team set " .. RIVAL_SET .. " put back after the rival's match")
  return true
end

-- a game closed during a rival's match left its record: the set goes back once the save is loaded
local function rival_after_load(slot)
  if SS.rival_checked == slot or slot < 2 or SS.rival_pending or SS.rival_playing then return end
  if loads_now() == 0 or docks_from_reset() then return end
  SS.rival_checked = slot
  rival_end(slot, party_ptr())
end

local function touch(why)
  if not party_ptr() then return end
  local slot = active_slot()
  rival_after_load(slot)
  if SS.state == nil or SS.state.slot == slot then
    resolve(slot, party_ptr())
    if SS.dirty and slot >= 2 and (SS.restage or not SS.staged) then stage(why) end
  else
    poll()
  end
  publish()
end

local function before_save()
  local party = party_ptr()
  if not party then return end
  local slot = active_slot()
  local st = SS.state
  if slot < 2 or not st or st.slot ~= slot then return end
  if SS.dirty and (SS.restage or not SS.staged) then
    stage("before save")
  elseif (st.fingerprint or 0) ~= 0 and loads_now() ~= 0 and not docks_from_reset() then
    local w = live_docks(party)
    local fp = w and S.fingerprint(w)
    if fp and fp ~= st.fingerprint then stage("before save, docks edited") end
  end
end

-- the TeamInfo of an unused set (a dock or a stored template) for a new template, else nil
local function unused_source(st, cur)
  local d = S.find_unused_set(cur, S.DOCKS)
  if d then return cur, d end
  for _, t in ipairs(st.templates) do
    if t.content == "stored" then
      local w = B.read_words(t.set, 0, S.WPD)
      if S.unused_set(w, 0) then return w, 0 end
    end
  end
  return nil
end

-- the dock template `n` goes into: not an active team, not kept by a screen; a dock holding a template above 11 first
local function free_dock(st, party)
  local busy = active_docks(party)
  if not busy then return nil end
  for _, n in pairs(SS.pins) do
    local d = S.dock_of(st, n)
    if d then busy[d] = true end
  end
  local pick
  for d = S.DOCKS - 1, 0, -1 do
    if not busy[d] then
      if st.docks[d] ~= d + 1 then return d end
      pick = pick or d
    end
  end
  return pick
end

-- puts template `n` into a dock (when it is not in one) -> the dock (0-based), or nil and the refusal code; `online` refuses
local function dock_template(n, online)
  local slot = active_slot()
  local fence = { slot = slot, blocked_mode = blocked_mode(), job_pending = job_pending(), online = online }
  local refused = S.check_fence(fence)
  if refused then return nil, refused end
  local party = party_ptr()
  if not party then return nil, C.NOT_READY end
  local st = resolve(slot, party)
  if n < 1 or n > #st.templates then return nil, C.BAD_ARGS end
  local at = S.dock_of(st, n)
  if at then return at end
  local d = free_dock(st, party)
  if not d then return nil, C.NO_FREE_DOCK end
  local data, t = set_base(party)
  local cur = data and read_set(data, t, S.FIRST_DOCK + d)
  local docks = live_docks(party)
  if not cur or not docks then return nil, C.NOT_READY end
  local cur_idents, unresolved = S.idents_of(cur, ident, 1)
  local out = st.docks[d]
  if unresolved > 0 then
    warn(string.format("%d member(s) of template %d have no live record now (they are emptied when it is used again)", unresolved, out))
  end
  local tpl = st.templates[n]
  local new_w, dropped
  if tpl.content == "stored" then
    new_w = B.read_words(tpl.set, 0, S.WPD)
    dropped = S.validate(new_w, tpl.idents, ident, 1)
  else
    new_w = S.new_template(cur, unused_source(st, docks))
    dropped = {}
  end
  for _, x in ipairs(dropped) do
    warn(string.format("template %d team %d slot %d: handle 0x%s is no longer the stored character (param %s, order %d) -> slot emptied", n, x.team, x.slot, B.word_hex_text(x.handle), B.word_hex_text(x.param), x.order))
  end
  local ok, e = write_set(data, t, S.FIRST_DOCK + d, new_w, 0)
  if not ok then
    err("template " .. n .. " not put into dock " .. (d + 1) .. ": " .. tostring(e) .. "; restoring template " .. out)
    local ok2, e2 = write_set(data, t, S.FIRST_DOCK + d, cur, 0)
    if not ok2 then err("RESTORE FAILED too: " .. tostring(e2) .. " (do not save; restart the game)") end
    return nil, C.EXCEPTION
  end
  st.templates[out] = { content = "stored", set = B.text_of_words(cur), idents = cur_idents }
  st.templates[n] = { content = "docked" }
  st.docks[d] = n
  changed()
  info(string.format("slot %d: template %d in dock %d (%s), template %d stored; %d player slot(s) emptied; saved with the next game save", slot, n, d + 1,
    tpl.content == "stored" and "stored" or "new", out, #dropped))
  if CFG.verify then verify_docks(party, "after swap") end
  SS.staged = nil -- the next game save stages this state (before_save)
  return d
end

-- a template's words with the members that are no longer their characters emptied (a copy), nil when it is empty
local function template_words(st, n, party)
  local tpl = st.templates[n]
  if tpl == nil or tpl.content == "empty" then return nil end
  if tpl.content == "docked" then
    local data, t = set_base(party)
    return data and read_set(data, t, S.FIRST_DOCK + S.dock_of(st, n)) or nil
  end
  local w = B.read_words(tpl.set, 0, S.WPD)
  S.validate(w, tpl.idents, ident, 1)
  return w
end

-- CMND_BETTERQOL_TEMPLATE_INFO -> usable, template count, slot
function TT.Info()
  local party = party_ptr()
  if not party then
    publish()
    return false
  end
  local slot = active_slot()
  local st = resolve(slot, party)
  publish()
  return usable(slot), #st.templates, slot
end

-- CMND_BETTERQOL_TEMPLATE_OF_DOCK (team set) -> the template number that dock holds, nil when it is no dock
function TT.OfDock(set)
  set = int(set, -1)
  local party = party_ptr()
  if not party or set < S.FIRST_DOCK or set > S.LAST_DOCK then return nil end
  local slot = active_slot()
  if slot < 2 then return set - S.FIRST_DOCK + 1 end
  return resolve(slot, party).docks[set - S.FIRST_DOCK]
end

-- CMND_BETTERQOL_TEMPLATE_STATE (template) -> "docked" / "stored" / "empty", the team set holding it (docked only)
function TT.State(n)
  n = int(n, -1)
  local party = party_ptr()
  if not party then return nil end
  local st = resolve(active_slot(), party)
  local tpl = st.templates[n]
  if tpl == nil then return nil end
  local d = S.dock_of(st, n)
  return tpl.content, d and (S.FIRST_DOCK + d) or nil
end

-- CMND_BETTERQOL_TEMPLATE_LIST returns the numbers of the templates that are not empty as "1,2,..." and their count.
function TT.List()
  local party = party_ptr()
  if not party then return nil end
  local st = resolve(active_slot(), party)
  local numbers = {}
  for n, tpl in ipairs(st.templates) do
    if tpl.content ~= "empty" then numbers[#numbers + 1] = n end
  end
  return table.concat(numbers, ","), #numbers
end

-- CMND_BETTERQOL_TEMPLATE_WORDS (template) -> the template's team set as bytes (members that left emptied), nil when empty
function TT.Words(n)
  n = int(n, -1)
  local party = party_ptr()
  if not party then return nil end
  local w = template_words(resolve(active_slot(), party), n, party)
  return w and B.text_of_words(w) or nil
end

-- TeamInfo fields of team 0 (docs/game/ui/pachanga-templates.md 9.1; member position = byte +0xE, the game's member command)
local CARD = { FORMATION = 0x28C, UNIFORM = 0x290, EMBLEM = 0x298, CAPTAIN = 0x2A4, TACTICS = 0x2A8, POSITION = 0xE, LAST_POSITION = 18 }

-- CMND_BETTERQOL_TEMPLATE_CARD (template) -> captain chara_param, lineup "position:chara_param,...", team set (-1 = stored),
-- emblem, uniform, name, formation, tactic 1..3 of team 0, every member "position:handle,..." (in slot order), the
-- captain's handle; nil when the template is empty. Same values as the game's CMND_GET_TEAM_SET_INFO and team member
-- command on a dock.
function TT.Card(n)
  n = int(n, -1)
  local party = party_ptr()
  if not party then return nil end
  local st = resolve(active_slot(), party)
  local w = template_words(st, n, party)
  if not w then return nil end
  local function word(off) return w[S.wi(0, off)] end
  local captain_handle, captain, parts, members = word(CARD.CAPTAIN), 0, {}, {}
  for k = 0, S.MEMBERS - 1 do
    local h = S.member_handle(w, 0, 0, k)
    if h ~= 0 then
      local pos = B.byte_of_word(w[S.wi(0, S.member_off(0, k) + 12)], CARD.POSITION - 12)
      members[#members + 1] = string.format("%d:%.0f", pos, h)
      local param = ident(h)
      if param and param ~= 0 and pos <= CARD.LAST_POSITION then
        parts[#parts + 1] = string.format("%d:%.0f", pos, param)
        if h == captain_handle then captain = param end
      end
    end
  end
  local d = S.dock_of(st, n)
  local name = B.before_zero(B.text_of_words(w, 1, S.NAME_LEN / 4))
  return captain, table.concat(parts, ","), d and (S.FIRST_DOCK + d) or -1, word(CARD.EMBLEM), word(CARD.UNIFORM), name,
    word(CARD.FORMATION), word(CARD.TACTICS), word(CARD.TACTICS + 4), word(CARD.TACTICS + 8), table.concat(members, ","),
    captain_handle
end

-- CMND_BETTERQOL_TEMPLATE_USE (template, owner, 1 = the online squad is shown) -> the team set holding it, kept for `owner`
-- until it lets go; nil, code when refused
function TT.Use(n, owner, online)
  n = int(n, -1)
  if type(owner) ~= "string" or owner == "" then return nil, C.BAD_ARGS end
  local prev = SS.pins[owner]
  SS.pins[owner] = nil
  local d, code = dock_template(n, int(online, 0) ~= 0)
  if d == nil then
    SS.pins[owner] = prev
    publish()
    return nil, code
  end
  SS.pins[owner] = n
  publish()
  return S.FIRST_DOCK + d
end

-- CMND_BETTERQOL_TEMPLATE_LET_GO (owner) -> ok: the template `owner` kept may leave its dock again
function TT.LetGo(owner)
  if type(owner) ~= "string" then return false end
  SS.pins[owner] = nil
  return true
end

-- CMND_BETTERQOL_TEMPLATE_RIVAL_FREE -> a menu that plays against templates may use the rival team set: nothing is in it
function TT.RivalFree()
  local party = party_ptr()
  if not party or SS.rival_playing then return false end
  local slot = active_slot()
  if not usable(slot) then return false end
  if not rival_end(slot, party) then return false end
  local data, t = set_base(party)
  local w = data and read_set(data, t, RIVAL_SET)
  if not w or #S.flag_members(w, 0) > 0 then
    info("team set " .. RIVAL_SET .. " is in use: rivals of stored templates are off")
    return false
  end
  return true
end

-- CMND_BETTERQOL_TEMPLATE_RIVAL (template) -> the team set holding its copy for one match, nil = refused
function TT.Rival(n)
  n = int(n, -1)
  local party = party_ptr()
  if not party then return nil end
  local slot = active_slot()
  local st = resolve(slot, party)
  local data, t = set_base(party)
  local spare = data and read_set(data, t, RIVAL_SET)
  local source = template_words(st, n, party)
  if not spare or not source or #S.flag_members(spare, 0) > 0 then return nil end
  local stored, where = VRFW.save.doc.write_text(RIVAL_DOC, B.text_of_words(spare), slot)
  if not stored then
    warn("rival not copied, its record was not written: " .. tostring(where))
    return nil
  end
  local ok, e = write_set(data, t, RIVAL_SET, source, 0)
  if not ok then
    err("rival not copied: " .. tostring(e))
    rival_end(slot, party)
    return nil
  end
  SS.rival_pending = true
  info(string.format("slot %d: template %d copied to team set %d for one match", slot, n, RIVAL_SET))
  return RIVAL_SET
end

-- CMND_BETTERQOL_TEMPLATE_MENU (1 = the team dock opened, 0 = it closed) -> the feature is ready
function TT.Menu(open)
  local ready = party_ptr() ~= nil
  if ready and int(open, 0) == 0 then
    SS.pins.team_dock = nil
    local ok, e = pcall(touch, "team dock closed")
    if not ok then warn("menu close: " .. tostring(e)) end
  end
  return ready
end

-- CMND_BETTERQOL_TEMPLATE_DUMP -> crc32 of the 11 live docks, dock-bit errors, team-0 members (and a log block)
function TT.Dump()
  local party = party_ptr()
  local crc, errs, members
  if party then crc, errs, members = verify_docks(party, "dump") end
  if not crc then return -1, -1, -1 end
  return crc, errs, members
end

-- the template number of team set `set` for the scripts of this mod (the dock's number without stored templates)
-- The words of dock team set `set` for the team file script; nil when it is no dock or cannot be read.
function TT.DockWords(set)
  set = int(set, -1)
  local party = party_ptr()
  if not party or set < S.FIRST_DOCK or set > S.LAST_DOCK then return nil end
  local data, t = set_base(party)
  return data and read_set(data, t, set) or nil
end

-- Writes `words` into dock team set `set` (the team file import) -> true; false, why (the dock keeps its team).
function TT.WriteDock(set, words)
  set = int(set, -1)
  local slot = active_slot()
  local refused = S.check_fence({ slot = slot, blocked_mode = blocked_mode(), job_pending = job_pending(), online = false })
  if refused then return false, "refused, code " .. tostring(refused) end
  local party = party_ptr()
  local data, t = set_base(party)
  local cur = data and set >= S.FIRST_DOCK and set <= S.LAST_DOCK and read_set(data, t, set) or nil
  if not cur or type(words) ~= "table" or #words ~= S.WPD then return false, "the dock cannot be read" end
  local ok, why = write_set(data, t, set, words, 0)
  if not ok then
    err("team file not put into team set " .. set .. ": " .. tostring(why) .. "; restoring the dock")
    local restored, restore_why = write_set(data, t, set, cur, 0)
    if not restored then err("RESTORE FAILED too: " .. tostring(restore_why) .. " (do not save; restart the game)") end
    return false, tostring(why)
  end
  info(string.format("slot %d: team set %d rewritten from a team file; saved with the next game save", slot, set))
  return true
end

function BetterQoL.TemplateOfDock(set)
  return TT.OfDock(set)
end

VRFW.on("match_start", function()
  if SS.rival_pending then
    SS.rival_pending, SS.rival_playing = false, true
  end
end)

VRFW.on("match_end", function()
  if SS.rival_playing then
    local party = party_ptr()
    local ok, e = pcall(rival_end, active_slot(), party)
    if not ok then warn("match_end: " .. tostring(e)) end
  end
end)

VRFW.on("save:before", function()
  local ok, e = pcall(before_save)
  if not ok then warn("save:before: " .. tostring(e)) end
end)

-- boot and title rebuild the party (also on the retail reload that skips GameReset): its docks are the save's only after the next Party.Load
local function party_was_rebuilt()
  return VRFW.state("mode.is.boot") == 1 or VRFW.state("mode.is.title") == 1
end

for _, trig in ipairs({ "mode_enter", "mode_leave" }) do
  VRFW.on(trig, function()
    if trig == "mode_enter" and party_was_rebuilt() then reset_loads = loads_now() end
    local ok, e = pcall(touch, trig)
    if not ok then warn(trig .. ": " .. tostring(e)) end
  end)
end

pcall(VRFW.state.set, KEY_COUNT, CFG.count)
pcall(VRFW.state.set, KEY_ACTIVE, 0)

info(string.format("active: %d templates (docks = team sets %d..%d), blocked modes {%s}%s, stored as blob %s per slot (staged with the game's save)",
  CFG.count, S.FIRST_DOCK, S.LAST_DOCK, table.concat(CFG.blocked, ", "),
  #CFG.decl_mods > 0 and (" (declarations of " .. table.concat(CFG.decl_mods, ", ") .. ")") or "", BLOB))

-- The team file commands run in this script: they read and write docks through the functions above.
require "lib/team_file"
