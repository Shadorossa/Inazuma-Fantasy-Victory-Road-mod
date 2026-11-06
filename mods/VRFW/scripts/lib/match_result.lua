-- The result of the last finished match, readable from any mod's script (docs/framework/match-result.md).
-- scripts\match_result.lua writes it at the final whistle, then sends the signal `vrfw.match_result`; every script runs
-- in its own VM, so the result travels in game_state keys (vrfw.match_result.*, content\game\match_result.toml).
--
--   local MatchResults = require "VRFW/lib/match_result"
--   VRFW.on("signal:vrfw.match_result", function()
--     local r = MatchResults.last()   -- nil when no match has finished this session
--     ...
--   end)
--
-- MatchResults.last() -> table:
--   seq             results published this session (1, 2, …)
--   home_score, away_score            the goals of the match, extra time included, the shoot-out left out
--   user_side       0 = the player plays at home, 1 = away
--   score_for, score_against          the same goals from the player's side
--   shootout        true when a penalty shoot-out was played
--   shootout_home, shootout_away, shootout_for, shootout_against   its goals (nil without a shoot-out)
--   extra_time      true when extra time was played
--   winner_side     0 = home won, 1 = away won, nil = a draw
--   won             true when the player's side won (the game's own judge when it ran, a shoot-out included)
--   outcome         "win" | "draw" | "loss" (the player's side)
--   game, difficulty                  the match's game id and difficulty row
--   home_team, away_team              the teams' ids (0 when the match request named none)
--   mode_id         crc32 of the mode key the match was started in (VRFW.mode() at kick-off), mode = that key
--                   when it is still the current mode
--   source          "result_builder" (the game's result builder ran) | "full_time" (only the full-time state was seen)

local M = {}

local PREFIX = "vrfw.match_result."

-- the keys and their kinds: "int", "bool" (0 / 1), "side" (0 / 1, absent = none)
M.KEYS = {
  seq = "int", home_score = "int", away_score = "int", user_side = "int", shootout = "bool",
  shootout_home = "int", shootout_away = "int", extra_time = "bool", winner_side = "int", won = "bool",
  outcome = "int", game = "int", difficulty = "int", home_team = "int", away_team = "int", mode_id = "int",
  source = "int",
}

-- outcome and source as numbers in the keys
local OUTCOMES = { "win", "draw", "loss" }
local SOURCES = { "result_builder", "full_time" }

local function index_of(list, word)
  for i, w in ipairs(list) do
    if w == word then return i end
  end
  return nil
end

local function get(key)
  local ok, v = pcall(VRFW.state.get, PREFIX .. key)
  if ok and type(v) == "number" then return v end
  return nil
end

-- the last published result, nil when none
function M.last()
  local seq = get("seq")
  if not seq then return nil end
  local r = { seq = seq }
  for key, kind in pairs(M.KEYS) do
    local v = get(key)
    if kind == "bool" then
      r[key] = v == 1
    else
      r[key] = v
    end
  end
  r.outcome = OUTCOMES[r.outcome or 0]
  r.source = SOURCES[r.source or 0]
  local side = r.user_side or 0
  if side == 1 then
    r.score_for, r.score_against = r.away_score, r.home_score
  else
    r.score_for, r.score_against = r.home_score, r.away_score
  end
  if r.shootout then
    if side == 1 then
      r.shootout_for, r.shootout_against = r.shootout_away, r.shootout_home
    else
      r.shootout_for, r.shootout_against = r.shootout_home, r.shootout_away
    end
  else
    r.shootout_home, r.shootout_away = nil, nil
  end
  local okm, mode = pcall(VRFW.mode)
  if okm and type(mode) == "string" and r.mode_id and VRFW.crc32(mode) == r.mode_id then
    r.mode = mode
  end
  return r
end

-- framework only (the keys are VRFW's): writes `r` (the fields above, outcome / source as words), seq last
function M.write(r)
  for key, kind in pairs(M.KEYS) do
    if key ~= "seq" then
      local v = r[key]
      if key == "outcome" then
        v = index_of(OUTCOMES, v)
      elseif key == "source" then
        v = index_of(SOURCES, v)
      elseif kind == "bool" then
        v = v and 1 or 0
      end
      pcall(VRFW.state.set, PREFIX .. key, v)
    end
  end
  pcall(VRFW.state.set, PREFIX .. "seq", r.seq)
end

return M
