-- The Tournament league's scorers: the card stats, the scorer pool and the drawn goals.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local Tn = Shared.Tn
local warn = Shared.warn
local CFG = Shared.CFG

local STATS = nil
local SQUADS = {}

local function card_stats()
  if STATS then
    return STATS
  end
  STATS = {}
  local ok, cards = pcall(VRFW.character.cards, { columns = { "stat_kick" } })
  if ok and type(cards) == "table" then
    for _, c in ipairs(cards) do
      STATS[VRFW.ids.unsigned(c.id)] = { pos = U.int(c.position, 0), kick = tonumber(c.cols and c.cols.stat_kick) or 0 }
    end
  else
    warn("top scorers: chara_param not readable (" .. tostring(cards) .. ")")
  end
  return STATS
end

local function scorer_pool(team)
  if SQUADS[team] then
    return SQUADS[team]
  end
  local list = {}
  local rows = nil
  if Tn.roster then
    local ok, r = pcall(Tn.roster, team)
    rows = ok and r or nil
  end
  local st = card_stats()
  for _, m in ipairs(type(rows) == "table" and rows or {}) do
    local slot, card = U.int(m[1], 99), VRFW.ids.unsigned(m[2] or 0)
    local x = st[card]
    local w = x and (CFG.scorer_weight[x.pos] or 0) * math.max(1, x.kick) or 0
    if slot < 11 and card ~= 0 and w > 0 then
      list[#list + 1] = { card = card, w = w }
    end
  end
  SQUADS[team] = list
  return list
end

local function add_goal(run, e, card)
  run.scorers = run.scorers or {}
  for _, x in ipairs(run.scorers) do
    if x.e == e and x.c == card then
      x.g = x.g + 1
      return
    end
  end
  run.scorers[#run.scorers + 1] = { e = e, c = card, g = 1 }
end

local function drawn_goals(run, e, n, r)
  local pool = scorer_pool(run.teams[e] or 0)
  local total = 0
  for _, x in ipairs(pool) do
    total = total + x.w
  end
  if total <= 0 then
    return
  end
  for _ = 1, n do
    local pick = r:below(1000000) / 1000000 * total
    for _, x in ipairs(pool) do
      pick = pick - x.w
      if pick < 0 then
        add_goal(run, e, x.card)
        break
      end
    end
  end
end

function Tn.league_scorers(run, md, live)
  local p = run.player
  for i, m in ipairs(run.gm[1]) do
    if m.md == md and m.done then
      local mine = m.a == p or m.b == p
      for side = 1, 2 do
        local e = side == 1 and m.a or m.b
        local goals = side == 1 and m.ga or m.gb
        local given = 0
        if mine then
          local want = e == p and "user" or "rival"
          for _, x in ipairs(live or {}) do
            if x.side == want and given < goals then
              add_goal(run, e, x.card)
              given = given + 1
            end
          end
        end
        if goals > given then
          local r = U.rng((run.seed[1] + 0x53434F52 + md * 977) % 4294967296, (run.seed[2] + i * 7919 + side) % 4294967296)
          r:next()
          drawn_goals(run, e, goals - given, r)
        end
      end
    end
  end
end

-- The names the later parts of the Tournament read.
Shared.card_stats = card_stats
