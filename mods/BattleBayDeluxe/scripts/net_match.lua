
local U = require "lib/util"
local G = require "lib/game"
local Block = require "lib/campaign_block"

local N = {}

local BLOB = "bb_net_campaign.json"

local info, warn = VRFW.logger("net")

local CFG = {
  game = U.u32(tonumber(U.config("net.game", 0x8F85B173)) or 0x8F85B173),
  difficulty = math.max(0, math.min(3, U.int(tonumber(U.config("net.difficulty", 1)), 1))),
}

local PICK = { armed = false, team = 0 }

function BattleBayDeluxe.NetPickArm(on)
  PICK.armed = U.int(on, 0) ~= 0
  if PICK.armed then
    PICK.team = 0
  end
  info("room pick " .. (PICK.armed and "armed" or "off"))
  return true
end

function BattleBayDeluxe.NetPicked()
  return PICK.team
end

function N.decide(menu, btn, idx)
  if not PICK.armed or U.rd("u32", btn) ~= G.GRID_LAYER then
    return nil
  end
  local s = U.struct("GridSlot", G.slot_addr(menu, idx))
  local team, unlocked = U.get(s, "team"), U.get(s, "unlocked")
  if not team or team == 0 or unlocked == 0 then
    info("room pick: slot " .. tostring(idx) .. " has no playable team")
    return { skip = true, ret = 0 }
  end
  local ok, r = pcall(VRFW.net.pick, team)
  if not ok or type(r) ~= "table" or not r.ok then
    warn("room pick: not sent (" .. tostring(ok and r and r.error or r) .. ")")
    return { skip = true, ret = 0 }
  end
  PICK.team, PICK.armed = team, false
  info("room pick: " .. U.hex(team) .. " (slot " .. tostring(idx) .. ")")
  return { skip = true, ret = 0 }
end

function BattleBayDeluxe.NetRestore()
  return Block.restore(BLOB)
end

function BattleBayDeluxe.NetPrepare(host_team, guest_team)
  host_team, guest_team = U.u32(host_team), U.u32(guest_team)
  if host_team == 0 or guest_team == 0 then
    warn("match not prepared: a team is missing (host " .. U.hex(host_team) .. ", guest " .. U.hex(guest_team) .. ")")
    return false
  end
  if not Block.session() then
    warn("match not prepared: the session block is not readable")
    return false
  end
  if not Block.kept(BLOB) and not Block.snapshot(BLOB) then
    return false
  end
  if not Block.write(CFG.game, CFG.difficulty, host_team, { guest_team }, 0) then
    warn("the room's match was not written into the Campaña's block")
    BattleBayDeluxe.NetRestore()
    return false
  end
  info(string.format("room match: %s (host, team 0) vs %s (guest, team 1), game %s, difficulty %d", U.hex(host_team),
    U.hex(guest_team), U.hex(CFG.game), CFG.difficulty))
  return true
end

function BattleBayDeluxe.NetTeam(team)
  team = U.u32(team)
  if team == 0 then
    return 0, 0, 0
  end
  local rows = G.enjoy_rows and G.enjoy_rows() or nil
  for _, r in ipairs(type(rows) == "table" and rows or {}) do
    if r.team == team then
      local er = U.struct("EnjoyRow", r.addr)
      return U.get(er, "leader") or 0, 0, 0
    end
  end
  return 0, 0, 0
end

VRFW.on("slot_load", function()
  if Block.kept(BLOB) then
    pcall(BattleBayDeluxe.NetRestore)
  end
  return nil
end)

return N
