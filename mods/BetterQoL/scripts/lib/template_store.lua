-- Team templates of one save slot: the list 1..count, the 11 game docks holding 11 of them, the others stored (format, pure helpers).
local B = VRFW.bytes

local S = {}

local band, bor, lshift = bit32.band, bit32.bor, bit32.lshift
local SQUAD_LAYOUT = VRFW.squads.layout()

S.DEFAULT_COUNT = 999
S.MAX_COUNT = 999
S.DOCKS = 11
S.MIN_COUNT = S.DOCKS
S.FIRST_DOCK = 2
S.LAST_DOCK = 12
S.SET_SIZE = SQUAD_LAYOUT.set_size
S.TEAM_SIZE = SQUAD_LAYOUT.team_size
S.TEAMS = 3
S.MEMBERS = SQUAD_LAYOUT.member_count
S.MEMBER_LIST = SQUAD_LAYOUT.members
S.MEMBER_STRIDE = SQUAD_LAYOUT.member_size
S.NAME_LEN = 0x80
S.TEAM_FIELDS = { 0x250, 0x2C8 }
S.COUNTERS = 0x2C8
S.ACTIVE_OFF = SQUAD_LAYOUT.active
S.PARTY_SET_DATA = SQUAD_LAYOUT.sets
-- teams of a template whose members carry the dock's organizedTeamFlag bit (11v11 and 5v5 teams)
S.FLAG_TEAMS = 2
-- words of one team set / of the 3 TeamInfo a swap copies (isREStory at 0x870 stays)
S.WPD = S.SET_SIZE / 4
S.TEAM_WORDS = S.TEAMS * S.TEAM_SIZE / 4
S.IDENT_LEN = S.TEAMS * S.MEMBERS * 8

S.MAGIC = "BQTMPLS\0"
S.VERSION = 1
S.HEADER_LEN = 40 + S.DOCKS * 2
S.ZERO_SHA1 = string.rep("\0", 20)

-- result codes of the CMND_BETTERQOL_TEMPLATE_* commands
S.code = {
  OK = 0, BAD_ARGS = 1, NOT_READY = 2, STORY = 3, BUSY = 4, ONLINE = 6, EXCEPTION = 7, SLOT1 = 8, NO_FREE_DOCK = 11,
}

S.crc32 = function(s) return VRFW.crc32(s) end

function S.clamp_count(n)
  n = math.floor(tonumber(n) or S.DEFAULT_COUNT)
  if n < S.MIN_COUNT then return S.MIN_COUNT end
  if n > S.MAX_COUNT then return S.MAX_COUNT end
  return n
end

-- templates 1..11 in docks 1..11, the others empty
function S.fresh(slot, count)
  local st = { slot = slot, docks = {}, templates = {}, fingerprint = 0 }
  for i = 1, S.clamp_count(count) do
    st.templates[i] = { content = "empty" }
  end
  for d = 0, S.DOCKS - 1 do
    st.docks[d] = d + 1
    st.templates[d + 1].content = "docked"
  end
  return st
end

-- grows to `count`; only trailing empty templates are removed
function S.resize(st, count)
  local want = S.clamp_count(count)
  while #st.templates < want do
    st.templates[#st.templates + 1] = { content = "empty" }
  end
  while #st.templates > want and st.templates[#st.templates].content == "empty" do
    st.templates[#st.templates] = nil
  end
  return #st.templates
end

-- a copy whose templates can change without touching `st` (byte strings shared)
function S.copy(st)
  local c = { slot = st.slot, docks = {}, templates = {}, fingerprint = st.fingerprint, sha1 = st.sha1 }
  for d = 0, S.DOCKS - 1 do c.docks[d] = st.docks[d] end
  for i, t in ipairs(st.templates) do
    c.templates[i] = { content = t.content, set = t.set, idents = t.idents }
  end
  return c
end

function S.stored_count(st)
  local n = 0
  for _, t in ipairs(st.templates) do
    if t.content == "stored" then n = n + 1 end
  end
  return n
end

-- the dock (0-based) holding template `n`, nil when it is stored or empty
function S.dock_of(st, n)
  for d = 0, S.DOCKS - 1 do
    if st.docks[d] == n then return d end
  end
  return nil
end

-- every dock holds a different template marked docked, and no other template is marked docked
function S.is_consistent(st)
  local n = #st.templates
  if n < S.MIN_COUNT or n > S.MAX_COUNT then return false end
  local seen = {}
  for d = 0, S.DOCKS - 1 do
    local t = st.docks[d]
    if type(t) ~= "number" or t < 1 or t > n or seen[t] or st.templates[t].content ~= "docked" then return false end
    seen[t] = true
  end
  for i, t in ipairs(st.templates) do
    if t.content == "docked" and not seen[i] then return false end
  end
  return true
end

-- byte offset of member k of team t inside a set
function S.member_off(t, k)
  return t * S.TEAM_SIZE + S.MEMBER_LIST + k * S.MEMBER_STRIDE
end

-- word index (1-based) of byte offset `off` of set d of the words `w`
local function wi(d, off)
  return d * S.WPD + off / 4 + 1
end
S.wi = wi

function S.member_handle(w, d, t, k)
  return w[wi(d, S.member_off(t, k))]
end

function S.replace_team_field(w, d, t, from, to)
  local any = false
  for off = t * S.TEAM_SIZE + S.TEAM_FIELDS[1], t * S.TEAM_SIZE + S.TEAM_FIELDS[2] - 4, 4 do
    if w[wi(d, off)] == from then
      w[wi(d, off)] = to
      any = true
    end
  end
  return any
end

function S.clear_member(w, d, t, k)
  local i = wi(d, S.member_off(t, k))
  local h = w[i]
  w[i] = 0
  w[i + 1] = 0
  if h ~= 0 then S.replace_team_field(w, d, t, h, 0) end
  return h
end

function S.recount(w, d)
  for t = 0, S.TEAMS - 1 do
    local c = { 0, 0, 0, 0, 0 }
    for k = 0, S.MEMBERS - 1 do
      local i = wi(d, S.member_off(t, k))
      if w[i] ~= 0 then
        c[1] = c[1] + 1
        local pos = B.byte_of_word(w[i + 3], 2) -- byte +0xE
        local slot
        if pos == 0x13 then
          slot = 2
        elseif band(pos - 0x10, 0xFF) <= 2 then
          slot = 3
        elseif band(pos - 0x14, 0xFF) <= 8 then
          slot = 4
        else
          slot = 1
        end
        c[slot + 1] = c[slot + 1] + 1
      end
    end
    local cw = wi(d, t * S.TEAM_SIZE + S.COUNTERS)
    w[cw] = bor(band(c[1], 0xFF), lshift(band(c[2], 0xFF), 8), lshift(band(c[3], 0xFF), 16), lshift(band(c[4], 0xFF), 24))
    w[cw + 1] = bor(band(w[cw + 1], 0x00FFFF00), band(c[5], 0xFF), lshift(t, 24))
  end
end

-- members of team 0 (the 11v11 team) of set d
function S.team0_count(w, d)
  local n = 0
  for k = 0, S.MEMBERS - 1 do
    if S.member_handle(w, d, 0, k) ~= 0 then n = n + 1 end
  end
  return n
end

-- {team, slot, handle} of every member of the flag teams of set d
function S.flag_members(w, d)
  local v = {}
  for t = 0, S.FLAG_TEAMS - 1 do
    for k = 0, S.MEMBERS - 1 do
      local h = S.member_handle(w, d, t, k)
      if h ~= 0 then v[#v + 1] = { t, k, h } end
    end
  end
  return v
end

function S.copy_words(w)
  local c = {}
  for i = 1, #w do c[i] = w[i] end
  return c
end

-- no character in any team of set d
local function set_has_no_members(w, d)
  for t = 0, S.TEAMS - 1 do
    for k = 0, S.MEMBERS - 1 do
      if S.member_handle(w, d, t, k) ~= 0 then return false end
    end
  end
  return true
end

-- set d was never used: no member and no name
function S.unused_set(w, d)
  if not set_has_no_members(w, d) then return false end
  for i = 0, S.NAME_LEN / 4 - 1 do
    if w[wi(d, 0) + i] ~= 0 then return false end
  end
  return true
end

-- the first unused set of the `n` sets of `w` (0-based), nil when every set is used
function S.find_unused_set(w, n)
  for d = 0, n - 1 do
    if S.unused_set(w, d) then return d end
  end
  return nil
end

-- the words of a new template: the TeamInfo of an unused set (`from`, set `from_d`), or `w` without names and members
function S.new_template(w, from, from_d)
  local v = S.copy_words(w)
  if from then
    for i = 0, S.TEAM_WORDS - 1 do
      v[wi(0, 0) + i] = from[wi(from_d, 0) + i]
    end
  else
    for t = 0, S.TEAMS - 1 do
      for k = 0, S.MEMBERS - 1 do
        S.clear_member(v, 0, t, k)
      end
      for i = 0, S.NAME_LEN / 4 - 1 do
        v[wi(0, t * S.TEAM_SIZE) + i] = 0
      end
    end
  end
  S.recount(v, 0)
  return v
end

-- crc32 over every team name and member handle of the 11 docks (a consistency hint for the log, never an identity)
function S.fingerprint(w)
  local p, n = {}, 0
  for d = 0, S.DOCKS - 1 do
    for t = 0, S.TEAMS - 1 do
      local base = wi(d, t * S.TEAM_SIZE)
      n = n + 1
      p[n] = B.text_of_words(w, base, base + S.NAME_LEN / 4 - 1)
      for k = 0, S.MEMBERS - 1 do
        n = n + 1
        p[n] = B.word_text(S.member_handle(w, d, t, k))
      end
    end
  end
  return S.crc32(table.concat(p))
end

-- { param, get_order } of handle h through `resolve` (false = no live record), once per handle
local function cached_ident(cache, resolve, h)
  local c = cache[h]
  if c == nil then
    local a, b = resolve(h)
    c = a and { a, b or 0 } or false
    cache[h] = c
  end
  return c
end

-- the param / get_order of every member slot of the `n` sets of `w`, and how many members have no live record
function S.idents_of(w, resolve, n)
  local p, i, missing, cache = {}, 0, 0, {}
  for d = 0, n - 1 do
    for t = 0, S.TEAMS - 1 do
      for k = 0, S.MEMBERS - 1 do
        local h = S.member_handle(w, d, t, k)
        local par, ord = 0, 0
        if h ~= 0 then
          local c = cached_ident(cache, resolve, h)
          if c then par, ord = c[1], c[2] else missing = missing + 1 end
        end
        i = i + 1
        p[i] = B.word_text(par) .. B.word_text(ord)
      end
    end
  end
  return table.concat(p), missing
end

-- empties every member of the `n` sets of `w` that is no longer the character `idents` recorded -> the dropped members
function S.validate(w, idents, resolve, n)
  local dropped, cache = {}, {}
  for d = 0, n - 1 do
    for t = 0, S.TEAMS - 1 do
      for k = 0, S.MEMBERS - 1 do
        local h = S.member_handle(w, d, t, k)
        if h ~= 0 then
          local off = ((d * S.TEAMS + t) * S.MEMBERS + k) * 8
          local wp, wo = B.read_word(idents, off) or 0, B.read_word(idents, off + 4) or 0
          local ok = false
          if wp ~= 0 or wo ~= 0 then
            local c = cached_ident(cache, resolve, h)
            ok = c and c[1] == wp and c[2] == wo or false
          end
          if not ok then
            S.clear_member(w, d, t, k)
            dropped[#dropped + 1] = { set = d, team = t, slot = k, handle = h, param = wp, order = wo }
          end
        end
      end
    end
    S.recount(w, d)
  end
  return dropped
end

function S.check_fence(f)
  if f.slot < 2 then return S.code.SLOT1 end
  if f.blocked_mode == nil then return S.code.NOT_READY end
  if f.blocked_mode then return S.code.STORY end
  if f.job_pending == nil then return S.code.NOT_READY end
  if f.job_pending then return S.code.BUSY end
  if f.online then return S.code.ONLINE end
  return nil
end

local function u16_text(v)
  return string.char(band(v, 0xFF), band(math.floor(v / 256), 0xFF))
end

local function read_u16(s, off)
  local a, b = s:byte(off + 1, off + 2)
  return a + b * 256
end

-- the file bytes of `st` (`sha1` = 20 bytes, `fp` = fingerprint of the docks)
function S.encode(st, sha1, fp)
  local p = {
    S.MAGIC, B.word_text(S.VERSION), B.padded(sha1 or "", 20),
    string.char(st.slot, 0), u16_text(#st.templates), B.word_text(fp or 0),
  }
  for d = 0, S.DOCKS - 1 do p[#p + 1] = u16_text(st.docks[d]) end
  for _, t in ipairs(st.templates) do
    if t.content == "stored" then
      p[#p + 1] = "\1"
      p[#p + 1] = t.set
      p[#p + 1] = t.idents
    elseif t.content == "docked" then
      p[#p + 1] = "\2"
    else
      p[#p + 1] = "\0"
    end
  end
  local body = table.concat(p)
  return body .. B.word_text(S.crc32(body))
end

-- the body (without its crc) of a file with `magic`, or nil and why
local function checked_body(data, magic, header_len)
  if type(data) ~= "string" or #data < header_len + 4 or data:sub(1, 8) ~= magic then
    return nil, "not a team template file (magic)"
  end
  local body = data:sub(1, #data - 4)
  if S.crc32(body) ~= B.read_word(data, #data - 4) then
    return nil, "crc mismatch (file damaged)"
  end
  return body
end

-- the slot and build checks every file passes
local function owner_problem(fsha, fslot, slot, sha1)
  if sha1 and fsha ~= sha1 and fsha ~= S.ZERO_SHA1 then
    return "written for another nie.exe (SHA-1 differs)"
  end
  if slot and fslot ~= slot then
    return string.format("belongs to slot %d, not %d", fslot, slot)
  end
  return nil
end

function S.decode(data, slot, sha1)
  local body, bad = checked_body(data, S.MAGIC, S.HEADER_LEN)
  if not body then return nil, bad end
  local ver = B.read_word(data, 8)
  if ver ~= S.VERSION then return nil, "unknown version " .. tostring(ver) end
  local fsha, fslot = data:sub(13, 32), data:byte(33)
  local problem = owner_problem(fsha, fslot, slot, sha1)
  if problem then return nil, problem end
  local count = read_u16(data, 34)
  if count < S.MIN_COUNT or count > S.MAX_COUNT then return nil, "template count " .. count .. " not supported" end
  local st = { slot = fslot, docks = {}, templates = {}, fingerprint = B.read_word(data, 36), sha1 = fsha }
  for d = 0, S.DOCKS - 1 do st.docks[d] = read_u16(data, 40 + d * 2) end
  local p, blen = S.HEADER_LEN, #body
  for i = 1, count do
    if p + 1 > blen then return nil, "truncated" end
    local tag = body:byte(p + 1)
    p = p + 1
    if tag == 0 then
      st.templates[i] = { content = "empty" }
    elseif tag == 2 then
      st.templates[i] = { content = "docked" }
    elseif tag == 1 then
      if p + S.SET_SIZE + S.IDENT_LEN > blen then return nil, "truncated" end
      st.templates[i] = { content = "stored", set = body:sub(p + 1, p + S.SET_SIZE), idents = body:sub(p + S.SET_SIZE + 1, p + S.SET_SIZE + S.IDENT_LEN) }
      p = p + S.SET_SIZE + S.IDENT_LEN
    else
      return nil, "bad template tag " .. tostring(tag)
    end
  end
  if p ~= blen then return nil, "trailing bytes" end
  if not S.is_consistent(st) then return nil, "inconsistent (docked templates)" end
  return st
end

-- templates stored in `old` that `new` neither stores nor docks (a list of numbers)
function S.lost(old, new)
  local out = {}
  for i, t in ipairs(old.templates) do
    local n = new.templates[i]
    if t.content == "stored" and (n == nil or n.content == "empty") then out[#out + 1] = i end
  end
  return out
end

-- puts the templates of `disk` that the running state lost back into it (same docks only) -> their numbers
function S.heal(st, disk)
  local restored = {}
  for d = 0, S.DOCKS - 1 do
    if st.docks[d] ~= disk.docks[d] then return restored end
  end
  for _, i in ipairs(S.lost(disk, st)) do
    while #st.templates < i do st.templates[#st.templates + 1] = { content = "empty" } end
    local t = disk.templates[i]
    st.templates[i] = { content = "stored", set = t.set, idents = t.idents }
    restored[#restored + 1] = i
  end
  return restored
end

-- a list of template numbers as text ("2, 15")
function S.numbers_text(list)
  local v = {}
  for i, n in ipairs(list) do v[i] = tostring(n) end
  return table.concat(v, ", ")
end

return S
