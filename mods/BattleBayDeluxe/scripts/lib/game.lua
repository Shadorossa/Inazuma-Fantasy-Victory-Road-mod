
local U = require "lib/util"

local G = {}

-- the grid menu (EnjoySelectTeamMenu)
G.GRID_LAYER = 0x065471F6
G.BTN_CAMPAIGN_START = 0x140980D9
G.SLOTS = 28
G.SLOT_STRIDE = 0x38
G.RIVALS = 7
G.S_RIVALS = 0x2CA6F0

-- Match.StartRequest request fields (+0x88 = match info +0x20, the stadium)
G.REQUEST_EXPLICIT, G.REQUEST_PLAYER, G.REQUEST_RIVAL = 0xA0, 0xA4, 0xA8
G.REQUEST_STADIUM = 0x88

local slot_base
function G.slot_base()
  if not slot_base then
    local ok, v = pcall(VRFW.game.field, "GridMenu.Slots")
    if ok and type(v) == "number" and v > 0 then
      slot_base = v
    end
  end
  return slot_base
end

function G.slot_addr(menu, i)
  local base = G.slot_base()
  if not base then
    return nil
  end
  return menu + base + i * G.SLOT_STRIDE
end

function G.enjoy_rows()
  local tblp = U.global("enjoy")
  if not tblp then
    return nil, "enjoy table not readable"
  end
  local tbl = U.struct("EnjoyTable", tblp)
  local rows, n = U.get(tbl, "rows"), U.get(tbl, "count")
  if not rows or rows < 0x10000 then
    return nil, "enjoy rows not readable"
  end
  if not n or n < 1 or n > 4096 then
    return nil, "enjoy row count not readable"
  end
  local out = {}
  for i = 0, n - 1 do
    local a = rows + i * 0x40
    local r = U.struct("EnjoyRow", a)
    local team, cond = U.get(r, "team"), U.get(r, "cond")
    if team == nil or cond == nil then
      return nil, "enjoy row " .. i .. " not readable"
    end
    out[#out + 1] = { team = team, cond = cond, addr = a }
  end
  return out
end

-- the enjoy row of `team` (its address), nil when none
function G.enjoy_row(team)
  local rows = G.enjoy_rows()
  if not rows then
    return nil
  end
  for _, r in ipairs(rows) do
    if r.team == team then
      return r.addr
    end
  end
  return nil
end

function G.eval(cond)
  if not VRFW.is_on("EvalCondition") then
    return nil
  end
  local ok, v = U.call("EvalCondition", cond)
  if not ok then
    return nil
  end
  return U.truthy(v)
end

function G.unlock_rule(team)
  local ok, r = pcall(VRFW.battle_bay.unlock_rule, team)
  if ok and type(r) == "number" then
    return r
  end
  return nil
end

return G
