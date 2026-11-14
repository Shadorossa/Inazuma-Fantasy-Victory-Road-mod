-- Match players (actors): list, find by character, read fields. Call: in a handler (not while the script loads).
--- Library: match player actors, units and their fields.
local Memory = VRFW.memory

local M = {}

local ACTOR_TABLE = "Match.SoccerActors.ViaSkillUsed"
local ACTOR_UNIT = "Match.ActorUnit"                    -- the framework's shared function binding

local LAYOUT = nil
local LAYOUT_WHY = nil

local function profile_value(name)
  local ok, v = pcall(VRFW.game.field, name)
  if ok and type(v) == "number" then
    return v
  end
  return nil
end

--- Internal: The match actor layout from the game profile; nil, why when a field is missing.
function M.layout()
  if LAYOUT ~= nil or LAYOUT_WHY ~= nil then
    return LAYOUT, LAYOUT_WHY
  end
  local names = {
    count = "Match.ActorCount", stride = "Actor", handle = "Actor.Handle", team = "Actor.Team",
    unit_chara = "MatchUnit.Chara",
  }
  local out, missing = VRFW.game.fields(names)
  if out == nil then
    LAYOUT_WHY = "the game profile has no " .. tostring(missing)
    VRFW.warn("actors: " .. LAYOUT_WHY)
    return nil, LAYOUT_WHY
  end
  LAYOUT = out
  return LAYOUT
end

--- VRFW.players.base(): the address of the actor table, or nil when no match runs. Call: in a handler (not while the script loads).
function M.base()
  return VRFW.game.global(ACTOR_TABLE)
end

--- VRFW.players.unit_of(address): the match unit of an actor, or nil. Call: in a handler (not while the script loads).
function M.unit_of(address)
  if not Memory.is_pointer(address) then
    return nil
  end
  local ok, unit = pcall(VRFW.call, ACTOR_UNIT, address)
  if ok and Memory.is_pointer(unit) then
    return unit
  end
  return nil
end

--- VRFW.players.chara(address): the character handle of an actor (0 when none). Call: in a handler (not while the script loads).
function M.chara(address)
  local L = M.layout()
  local unit = L and M.unit_of(address)
  if unit == nil then
    return 0
  end
  return Memory.read("u32", unit + L.unit_chara) or 0
end

-- MatchUnit.Attr: false = the profile lacks it (asked once)
local AURA_BITS = nil

--- VRFW.players.aura_flags(address): the aura bits of an actor, or nil. Call: in a handler (not while the script loads).
function M.aura_flags(address)
  if AURA_BITS == nil then
    AURA_BITS = profile_value("MatchUnit.Attr") or false
    if not AURA_BITS then
      VRFW.warn("actors: the game profile has no MatchUnit.Attr")
    end
  end
  local unit = AURA_BITS and M.unit_of(address)
  if not unit then
    return nil
  end
  return Memory.read("u8", unit + AURA_BITS)
end

--- VRFW.players.list([opts]): the actors on the pitch that match opts (team, ...), as a list. Call: in a handler (not while the script loads).
function M.list(opts)
  opts = opts or {}
  local out = {}
  local L = M.layout()
  local base = L and M.base()
  if base == nil then
    return out
  end
  local handles = VRFW.memory.read_array("u32", base + L.handle, L.count, L.stride)
  local okh = handles ~= nil
  local teams = VRFW.memory.read_array("u8", base + L.team, L.count, L.stride)
  local okt = teams ~= nil
  if not okh or type(handles) ~= "table" or not okt or type(teams) ~= "table" then
    return out
  end
  for i = 0, L.count - 1 do
    local handle = handles[i + 1] or 0
    if handle ~= 0 or opts.empty then
      local address = base + i * L.stride
      local a = { index = i, address = address, handle = handle, team = teams[i + 1] or 0xFF }
      if opts.chara then
        a.chara = M.chara(address)
      end
      out[#out + 1] = a
    end
  end
  return out
end

local FRAME_LIST, FRAME_ENTRIES, FRAME_N = {}, {}, 0

--- VRFW.players.frame(): every actor of this frame (a list reused by the next call) and the table address. Call: in a handler (not while the script loads).
function M.frame()
  local out = FRAME_LIST
  for i = FRAME_N, 1, -1 do out[i] = nil end
  FRAME_N = 0
  local L = M.layout()
  local base = L and M.base()
  if base == nil then
    return out, nil
  end
  local handles = VRFW.memory.read_array("u32", base + L.handle, L.count, L.stride)
  local okh = handles ~= nil
  local teams = VRFW.memory.read_array("u8", base + L.team, L.count, L.stride)
  local okt = teams ~= nil
  if not okh or type(handles) ~= "table" or not okt or type(teams) ~= "table" then
    return out, base
  end
  local n = 0
  for i = 0, L.count - 1 do
    local handle = handles[i + 1] or 0
    if handle ~= 0 then
      n = n + 1
      local a = FRAME_ENTRIES[n]
      if a == nil then
        a = {}
        FRAME_ENTRIES[n] = a
      end
      a.index, a.address, a.handle, a.team = i, base + i * L.stride, handle, teams[i + 1] or 0xFF
      out[n] = a
    end
  end
  FRAME_N = n
  return out, base
end

-- [struct .. "." .. field] = { at, type } (false = unknown): asked once
local FIELDS = {}

--- VRFW.players.field(struct, field[, base]): one profile field of every actor, as a list, or nil. Call: in a handler (not while the script loads).
function M.field(struct, field, base)
  local key = struct .. "." .. field
  local f = FIELDS[key]
  if f == nil then
    f = false
    if type(VRFW.memory.field_of) == "function" then
      local ok, at, ty = pcall(VRFW.memory.field_of, struct, field)
      if ok and type(at) == "number" and type(ty) == "string" then f = { at = at, type = ty } end
    end
    FIELDS[key] = f
  end
  if not f then
    return nil
  end
  local L = M.layout()
  base = base or (L and M.base())
  if L == nil or base == nil then
    return nil
  end
  local values = VRFW.memory.read_array(f.type, base + f.at, L.count, L.stride)
  local ok = values ~= nil
  if ok and type(values) == "table" then
    return values
  end
  return nil
end

--- VRFW.players.each([opts]): an iterator over the actors that match opts. Call: in a handler (not while the script loads).
function M.each(opts)
  local list = M.list(opts)
  local i = 0
  return function()
    i = i + 1
    local a = list[i]
    if a == nil then
      return nil
    end
    return i, a
  end
end

--- VRFW.players.of(handle[, opts]): the actor of a character handle, or nil. Call: in a handler (not while the script loads).
function M.of(handle, opts)
  local L = M.layout()
  local base = L and M.base()
  if base == nil or type(handle) ~= "number" or handle == 0 then
    return nil
  end
  local i = handle % 256
  if i >= L.count then
    return nil
  end
  local address = base + i * L.stride
  local h = VRFW.memory.read("u32", address + L.handle)
  local okh = h ~= nil
  if not okh or h ~= handle then
    return nil
  end
  local team = VRFW.memory.read("u8", address + L.team)
  local okt = team ~= nil
  local a = { index = i, address = address, handle = h, team = okt and team or 0xFF }
  if opts and opts.chara then
    a.chara = M.chara(address)
  end
  return a
end

return M
