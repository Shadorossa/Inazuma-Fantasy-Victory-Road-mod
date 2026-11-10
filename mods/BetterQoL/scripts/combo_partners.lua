local Memory = VRFW.memory
local BLOB = "skill_partners.json"
local FILE_VERSION = 2
local MAX_PARTNERS = 3
local HELD_STALE_MS = 250
-- record attribute byte and its staff role bits
local REC_ROLE, ROLE_COACH, ROLE_MANAGER = 0x20, 0x10, 0x20

local Id = VRFW.ids
local Actors = VRFW.players
local u32 = Id.unsigned

local function arg_u32(v)
  if type(v) ~= "number" then
    return 0
  end
  return u32(v)
end

local function key(v)
  return string.format("%08X", u32(v))
end

-- trailing zeros (engine picks) dropped
local function trim_zeros(v)
  while #v > 0 and v[#v] == 0 do
    v[#v] = nil
  end
  return v
end

local function is_staff(hdl)
  if hdl == 0 then
    return false
  end
  local r = VRFW.character.record(hdl)
  if not r or not r.addr then
    return false
  end
  local role = Memory.read("u8", r.addr + REC_ROLE)
  return type(role) == "number" and bit32.band(role, ROLE_COACH + ROLE_MANAGER) ~= 0
end

local function partners_of(info)
  local ok, p = pcall(function()
    return { info.partner_type, info.partner1, info.partner2, info.partner3 }
  end)
  if not ok then
    return nil
  end
  local performers = math.min(math.max(p[1], 1), 4)
  local slots = math.min(performers - 1, MAX_PARTNERS)
  local named = {}
  for k = 2, 4 do
    local n = p[k]
    local dup = false
    for _, x in ipairs(named) do
      dup = dup or x == n
    end
    if n ~= 0 and not dup and #named < slots then
      named[#named + 1] = n
    end
  end
  return { performers = performers, slots = slots, named = named, free = slots - #named }
end

-- SKILL_INFO partners of a move through the engine's own table
local function skill_partners(skill)
  if skill == 0 or not VRFW.is_on("Technique.SkillInfoFind") then
    return nil
  end
  local tbl = VRFW.game.skill_table()
  if not tbl then
    return nil
  end
  local out, id = VRFW.memory.buffer("info_out", 8), VRFW.memory.buffer("info_id", 4)
  VRFW.memory.write("ptr", out, 0)
  VRFW.memory.write("u32", id, skill)
  if not pcall(VRFW.call, "Technique.SkillInfoFind", tbl, out, id) then
    return nil
  end
  local info = VRFW.memory.read("ptr", out)
  if not info or info < 0x10000 then
    return nil
  end
  local rec = VRFW.memory.struct("SkillInfo", info)
  local ok = rec ~= nil
  return ok and partners_of(rec) or nil
end

local DOC = VRFW.save.doc.new(BLOB, {
  aside = false,
  pretty = true,
  log = "combo partners",
  default = function() return { version = FILE_VERSION, players = {} } end,
  decode = function(f)
    f.players = f.players or {}
    f.version = FILE_VERSION
    return f
  end,
})

local function load_fresh()
  DOC:forget()
  return (DOC:get())
end

local function write(f, what)
  local ok, where = DOC:put(f, nil, true)
  if ok then
    VRFW.log(what .. " -> " .. tostring(where))
  else
    VRFW.error("write: " .. tostring(where))
  end
  return ok and true or false
end

local function choices(f, hdl, param, skill)
  local e = f.players[key(hdl)]
  if not e or e.param_id ~= param then
    return {}
  end
  return (e.moves or {})[key(skill)] or {}
end

-- at most MAX_PARTNERS, no executor, no duplicate (a repeat becomes 0 = random)
local function clean(exec, partners)
  local v = {}
  for i = 1, math.min(#partners, MAX_PARTNERS) do
    local p = partners[i]
    local dup = false
    for _, x in ipairs(v) do
      dup = dup or (p ~= 0 and x == p)
    end
    v[#v + 1] = (p == exec or dup) and 0 or p
  end
  return v
end

local function set_choices(f, hdl, param, skill, partners)
  local v = clean(hdl, partners)
  for i, p in ipairs(v) do
    if is_staff(p) then
      VRFW.log(string.format("0x%08X skill 0x%08X: partner 0x%08X is a coach / manager -> random", hdl, skill, p))
      v[i] = 0
    end
  end
  trim_zeros(v)
  local k = key(hdl)
  local e = f.players[k]
  if not e or e.param_id ~= param then
    e = { param_id = param, moves = {} }
    f.players[k] = e
  end
  e.moves = e.moves or {}
  e.moves[key(skill)] = (#v > 0) and v or nil
  if next(e.moves) == nil then
    f.players[k] = nil
  end
end

local function param_of(hdl)
  local r = VRFW.character.record(hdl)
  return r and r.param or nil
end

local function actor_record(address)
  local a = VRFW.memory.struct("Actor", address)
  local ok = a ~= nil
  return ok and a or nil
end

local function actor_of_handle(hdl)
  local e = Actors.of(hdl)
  return e and actor_record(e.address) or nil
end

local function owner_of_actor(a)
  local ch = a.chara
  if ch == 0 then
    return nil
  end
  return VRFW.character.owner(ch)
end

local function teammates(team, exec)
  local v = {}
  for _, e in ipairs(Actors.list()) do
    local hdl = e.handle
    if hdl ~= exec and bit32.band(hdl, 0xFF) == e.index and e.team == team then
      local ok, on = pcall(VRFW.call, "IsActorOnPitch", e.address, 0)
      local a = ok and bit32.band(on or 0, 0xFF) ~= 0 and actor_record(e.address)
      if a then
        local o = owner_of_actor(a)
        if o then
          v[#v + 1] = { hdl, o }
        end
      end
    end
  end
  return v
end

local function apply(cast, slots, wants)
  local out, placed = {}, {}
  for slot = 1, slots do
    local w = wants[slot]
    if not w then
      out[#out + 1] = string.format("slot %d random 0x%X", slot, cast[slot])
    elseif not w[2] then
      out[#out + 1] = string.format("slot %d 0x%08X not on the pitch -> engine pick 0x%X", slot, w[1], cast[slot])
    else
      local a = w[2]
      local src
      for j = 0, #cast do
        if cast[j] == a and src == nil then
          src = j
        end
      end
      local bad = a == 0 or placed[a] or src == 0
      if bad then
        out[#out + 1] = string.format("slot %d 0x%08X fallback -> engine pick 0x%X", slot, w[1], cast[slot])
      else
        if src ~= nil and src ~= slot then
          cast[slot], cast[src] = cast[src], cast[slot]
        elseif src == nil then
          cast[slot] = a
        end
        placed[a] = true
        out[#out + 1] = string.format("slot %d chosen 0x%08X (actor 0x%X)", slot, w[1], a)
      end
    end
  end
  return table.concat(out, ", ")
end

local last_none = ""

local function on_cast(cast_at, len, rec_at)
  local rec = VRFW.memory.struct("SkillInfo", rec_at)
  local ok = rec ~= nil
  if not ok then
    return
  end
  local sp = partners_of(rec)
  if not sp or sp.slots == 0 then
    return
  end
  local skill = rec.skill
  local cast = {}
  for k = 0, len - 1 do
    cast[k] = VRFW.memory.read("u32", cast_at + 4 * k)
  end
  local exec = cast[0]
  local ea = actor_of_handle(exec)
  if not ea then
    return
  end
  local owner = owner_of_actor(ea)
  local pid = owner and param_of(owner)
  if not pid then
    return
  end
  local chosen = choices((DOC:get()), owner, pid, skill)
  if #chosen == 0 then
    local tag = key(skill) .. key(owner)
    if tag ~= last_none then
      last_none = tag
      VRFW.log(string.format("skill 0x%08X (%d performers) by 0x%08X (actor 0x%X): no choice saved", skill, sp.performers, owner, exec))
    end
    return
  end
  local slots = math.min(sp.slots, len - 1)
  local team = ea.team
  local mates = teammates(team, exec)
  local wants = {}
  for i, o in ipairs(chosen) do
    if o == 0 or is_staff(o) then          -- a staff partner of an older save: the engine's pick
      wants[i] = false
    else
      local actor
      for _, m in ipairs(mates) do
        if m[2] == o and actor == nil then
          actor = m[1]
        end
      end
      wants[i] = { o, actor }
    end
  end
  local before = {}
  for k = 1, slots do
    before[k] = string.format("%X", cast[k])
  end
  local what = apply(cast, slots, wants)
  local after = {}
  for k = 1, slots do
    after[k] = string.format("%X", cast[k])
    VRFW.memory.write("u32", cast_at + 4 * k, cast[k])
  end
  VRFW.log(string.format("skill 0x%08X (%d performers) by 0x%08X (actor 0x%X, team %d, %d on-pitch mates): %s; cast [%s] -> [%s]", skill, sp.performers, owner, exec, team, #mates, what, table.concat(before, " "), table.concat(after, " ")))
end

VRFW.on("hook:BuildEventCast:post", function(ev)
  local a = ev.args
  local cast, n, rec, acting = a[2], a[3], a[4], a[6]
  if cast == 0 or rec == 0 or acting == 0 or n < 2 or n > 32 then
    return nil
  end
  on_cast(cast, n, rec)
  return nil
end)

-- skill -> performers, free, named1, named2, named3 (performers 0 = unknown move)
function BetterQoL.ComboInfo(skill)
  local sp = skill_partners(arg_u32(skill))
  if not sp then
    return 0, 0, 0, 0, 0
  end
  return sp.performers, sp.free, sp.named[1] or 0, sp.named[2] or 0, sp.named[3] or 0
end

-- charaStHdl, skill -> ok, p1, p2, p3 (0 = random)
function BetterQoL.ComboGet(hdl, skill)
  hdl, skill = arg_u32(hdl), arg_u32(skill)
  local pid = param_of(hdl)
  if not pid then
    return false
  end
  local v = choices(load_fresh(), hdl, pid, skill)
  return true, v[1] or 0, v[2] or 0, v[3] or 0
end

function BetterQoL.ComboSet(hdl, skill, p1, p2, p3)
  hdl, skill = arg_u32(hdl), arg_u32(skill)
  local v = { arg_u32(p1), arg_u32(p2), arg_u32(p3) }
  local sp = skill_partners(skill)
  if sp then
    for k = #v, sp.slots + 1, -1 do
      v[k] = nil
    end
  end
  local pid = param_of(hdl)
  if not pid or skill == 0 then
    return false
  end
  local f = load_fresh()
  set_choices(f, hdl, pid, skill, v)
  local saved = choices(f, hdl, pid, skill)
  return write(f, string.format("0x%08X skill 0x%08X partners %s", hdl, skill, table.concat(saved, ",")))
end

-- charaStHdl[, skill] -> ok (no skill = every move of the player)
function BetterQoL.ComboClear(hdl, skill)
  hdl, skill = arg_u32(hdl), arg_u32(skill)
  local pid = param_of(hdl)
  if not pid then
    return false
  end
  local f = load_fresh()
  if skill == 0 then
    if not f.players[key(hdl)] then
      return true
    end
    f.players[key(hdl)] = nil
    return write(f, string.format("0x%08X every move cleared", hdl))
  end
  if #choices(f, hdl, pid, skill) == 0 then
    return true
  end
  set_choices(f, hdl, pid, skill, {})
  return write(f, string.format("0x%08X skill 0x%08X cleared", hdl, skill))
end

local holds = {}

function BetterQoL.PadHeld(mask, ...)
  mask = arg_u32(mask)
  local vks = {}
  for _, k in ipairs({ ... }) do
    if type(k) == "number" then
      vks[#vks + 1] = math.floor(k)
    end
  end
  local pad = (mask ~= 0) and VRFW.input.pad() or nil
  local key_held = (#vks > 0) and VRFW.input.key(table.unpack(vks)) or nil
  if pad == nil and key_held == nil then
    return -1
  end
  local held = (pad ~= nil and bit32.band(pad, mask) == mask) or key_held == true
  local id = tostring(mask) .. ":" .. table.concat(vks, ",")
  local now = VRFW.now_ms()
  local e = holds[id]
  if not held then
    holds[id] = nil
    return 0
  end
  if e and now - e[2] <= HELD_STALE_MS then
    e[2] = now
    return (now - e[1]) / 1000
  end
  holds[id] = { now, now }
  return 0.001
end
