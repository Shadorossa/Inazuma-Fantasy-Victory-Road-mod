
CharacterReforged = CharacterReforged or {}
CharacterReforged.KeshinMoves = CharacterReforged.KeshinMoves or {}

local A = VRFW.auras

local info = VRFW.logger("CharacterReforged keshin")

local band = bit32.band
local Id = VRFW.ids
local hex = Id.hex_text
local u32 = Id.unsigned
local Actors = VRFW.players

local SUMMON_ACTIVE = 2
local ATTR_KESHIN, ATTR_ARMOUR = 1, 2

local said = {}           -- hdl -> the keshin already logged

VRFW.on("match_start", function(ev)
  said = {}
  return nil
end)

local function keshin_out(h)
  local entry = Actors.of(h)
  if not entry then return 0 end
  local a = VRFW.memory.read_struct("KmActor", entry.address)
  if not a or u32(a.hdl) ~= h or a.team > 1 or a.summon_state ~= SUMMON_ACTIVE then return 0 end
  local bits = Actors.aura_flags(entry.address)
  if not bits then return 0 end
  if band(bits, ATTR_KESHIN) == 0 or band(bits, ATTR_ARMOUR) ~= 0 then return 0 end
  return u32(a.summon_skill)
end

VRFW.on("move_check", function(ev)
  local h = ev.actor and ev.actor.handle and u32(ev.actor.handle)
  if not h or not ev.skill or ev.skill == 0 then return nil end
  local keshin = keshin_out(h)
  if keshin == 0 then return nil end
  A.load()
  local skill = u32(ev.skill)
  -- a transform (armour, miximax, another aura) stays allowed
  if A.type(skill) then return nil end
  local own = A.aura_move(keshin)
  if own == 0 or skill == own then return nil end
  if said[h] ~= keshin then
    said[h] = keshin
    info(string.format("actor %s: keshin %s out: only its move %s (move %s greyed)", hex(h), A.key(keshin), hex(own), hex(skill)))
  end
  return { block = true }
end)
