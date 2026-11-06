-- Aura Reworked › All Keshin Armed › only the keshin's own move while it is out: while a player's keshin runs, every
-- other move of his is refused and drawn greyed; his transforms are not touched. Read from the game, nothing named here:
--   * the keshin running: at each move check, his summon machine (content\game\keshin_moves.toml: the aura it runs,
--     state 2 = out) and the unit's aura bits (keshin 1, armour 2). A totem has no keshin bit; an armour ends the rule
--     (armoured moves keep their own rules); the moves come back with the state's change, nothing to undo;
--   * the keshin's own move: its row of the served aura_skill_config (lib/auras.lua, col 6). A keshin without a move
--     keeps the player's moves;
--   * the refusal: the rule trigger `move_check` answered { block = true }. The game's own availability check asks it
--     for the move list, the presses, the duels, the auto-use and the AI, and the extra slot plates ask it too. A refused
--     move is the game's «cannot pay» state, so a duel with nothing selectable resolves as one with an empty gauge.

AuraOverhaul = AuraOverhaul or {}
AuraOverhaul.KeshinMoves = AuraOverhaul.KeshinMoves or {}
-- the part's switch (Mods options › All Keshin Armed, applied after a restart): off = nothing of this part runs
if VRFW.option("all_keshin_armed") == 0 then return end

local A = require "lib/auras"

require "VRFW/lib/basics"
local info = VRFW.logger("AuraOverhaul keshin")

local band = bit32.band
local Id = require "VRFW/lib/ids"
local hex = Id.hex
local u32 = Id.u32
local Actors = require "VRFW/lib/actors"

-- game layout: the soccer actors and the summon machine
local SUMMON_ACTIVE = 2
local ATTR_KESHIN, ATTR_ARMOUR = 1, 2

local said = {}           -- hdl -> the keshin already logged

VRFW.on("match_start", function(ev)
  said = {}
  return nil
end)

-- the keshin player `h` has out now (0 = none)
local function keshin_out(h)
  local entry = Actors.of(h)
  if not entry then return 0 end
  local a = VRFW.mem.read_struct("KmActor", entry.address)
  if not a or u32(a.hdl) ~= h or a.team > 1 or a.summon_state ~= SUMMON_ACTIVE then return 0 end
  local ok, unit = pcall(VRFW.call, "Match.ActorUnit", entry.address)
  if not ok or type(unit) ~= "number" or unit < 0x10000 then return 0 end
  local okr, bits = pcall(VRFW.mem.read, "u8", unit + 0x2B4)
  if not okr or type(bits) ~= "number" then return 0 end
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
  local own = A.move(keshin)
  if own == 0 or skill == own then return nil end
  if said[h] ~= keshin then
    said[h] = keshin
    info(string.format("actor %s: keshin %s out: only its move %s (move %s greyed)", hex(h), A.key(keshin), hex(own), hex(skill)))
  end
  return { block = true }
end)
