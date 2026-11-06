-- VRFW › match move level: the level a mod declares for the special moves of one side of a match, for that match
-- only (nothing is written to a save). Data: every active mod's content\match_move_level\*.toml (schema
-- VRFW.match_move_level/1, content\types\match_move_level.toml): one [match] rule per file (play_mode, difficulty = a
-- [MatchDifficulty.<Id>] key or its number, side = "rival") and its [moves] levels (grade = "max" or a number). The
-- mod that owns the level a key names applies it when it installs a move in a match (grade: the mod that owns move grades); a key
-- whose owner is not active is not applied.
--   local MML = require "VRFW/lib/match_move_level"
--   MML.of_info(info, side) -> { grade = "max" | n, source = "<mod>" } for that side of the match whose match info is
--                              at `info`, nil when no rule holds (later mods win key by key)
--   MML.running(side)       -> the same for the running match
-- The caller's mod declares the globals "match_equipment_info" and "match_equipment_play_data" (VRFW/lib/match_equipment).

local ME = require "VRFW/lib/match_equipment"
require "VRFW/lib/basics"
local _, warn = VRFW.logger("match_move_level")

local M = {}

local RULES = nil   -- { { play_mode, difficulty, side, grade, source } }
local LAST = nil    -- { key, answer }

local function load()
  if RULES then return RULES end
  RULES = {}
  local ok, files = pcall(VRFW.files.declarations, "content/match_move_level")
  if not ok or type(files) ~= "table" then return RULES end
  for _, f in ipairs(files) do
    local d = f.data or {}
    local m, mv = d.match, d.moves
    if type(m) == "table" and type(mv) == "table" then
      local diff = ME.difficulty(m.difficulty)
      local grade = mv.grade
      if grade ~= nil and grade ~= "max" and not tonumber(grade) then
        warn(tostring(f.mod) .. ": grade " .. tostring(grade) .. " is neither \"max\" nor a number (key off)")
        grade = nil
      end
      if diff then
        RULES[#RULES + 1] = { play_mode = tonumber(m.play_mode), difficulty = diff, side = m.side or "rival",
          grade = tonumber(grade) or grade, source = tostring(f.mod) }
      else
        warn(tostring(f.mod) .. ": unknown difficulty " .. tostring(m.difficulty) .. " (rule off)")
      end
    end
  end
  return RULES
end

function M.of_info(info, side)
  local rules = load()
  if #rules == 0 then return nil end
  local game, diff, mode = ME.match_of(info)
  if not game then return nil end
  local key = string.format("%d:%d:%s:%s", game, diff, tostring(mode), tostring(side))
  if LAST and LAST.key == key then return LAST.answer end
  local answer = nil
  for _, r in ipairs(rules) do
    if r.difficulty == diff and (r.play_mode == nil or r.play_mode == mode) and r.side == side and r.grade ~= nil then
      answer = answer or {}
      answer.grade, answer.source = r.grade, r.source
    end
  end
  LAST = { key = key, answer = answer }
  return answer
end

function M.running(side)
  local g = VRFW.game and VRFW.game.match_equipment_info
  if type(g) ~= "function" then return nil end
  local ok, info = pcall(g)
  if not ok or type(info) ~= "number" then return nil end
  return M.of_info(info, side)
end

return M
