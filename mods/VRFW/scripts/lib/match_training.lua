-- VRFW › match training: the players of one side of a match a mod declares trained to the full, for that match only
-- (nothing is written to a save). Data: every active mod's content\match_training\*.toml (schema VRFW.match_training/1,
-- content\types\match_training.toml): one [match] rule per file (play_mode, difficulty = a [MatchDifficulty.<Id>] key
-- or its number, side = "rival") and its [training] (positions = main positions, level = the level they play at). The
-- mod that owns the training (Player Training) applies it; nothing happens while it is not active.
--   local MT = require "VRFW/lib/match_training"
--   MT.of_info(info, side) -> { positions = { [1 GK | 2 FW | 3 MF | 4 DF] = true }, level = n, source = "<mod>" } for
--                             that side of the match whose match info is at `info`, nil when no rule holds (later mods
--                             win key by key)
-- The caller's mod declares the globals "match_equipment_info" and "match_equipment_play_data" (VRFW/lib/match_equipment).

local ME = require "VRFW/lib/match_equipment"
require "VRFW/lib/basics"
local _, warn = VRFW.logger("match_training")

local M = {}

local POSITION = { GK = 1, FW = 2, MF = 3, DF = 4 }

local RULES = nil   -- { { play_mode, difficulty, side, positions, level, source } }
local LAST = nil    -- { key, answer }

local function positions_of(list, source)
  if type(list) ~= "table" then return nil end
  local out, any = {}, false
  for _, p in ipairs(list) do
    local code = POSITION[tostring(p):upper()]
    if code then
      out[code], any = true, true
    else
      warn(source .. ": unknown position " .. tostring(p) .. " (skipped)")
    end
  end
  return any and out or nil
end

local function load()
  if RULES then return RULES end
  RULES = {}
  local ok, files = pcall(VRFW.files.declarations, "content/match_training")
  if not ok or type(files) ~= "table" then return RULES end
  for _, f in ipairs(files) do
    local d = f.data or {}
    local m, t = d.match, d.training
    if type(m) == "table" and type(t) == "table" then
      local source = tostring(f.mod)
      local diff = ME.difficulty(m.difficulty)
      if diff then
        RULES[#RULES + 1] = { play_mode = tonumber(m.play_mode), difficulty = diff, side = m.side or "rival",
          positions = positions_of(t.positions, source), level = tonumber(t.level), source = source }
      else
        warn(source .. ": unknown difficulty " .. tostring(m.difficulty) .. " (rule off)")
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
    if r.difficulty == diff and (r.play_mode == nil or r.play_mode == mode) and r.side == side then
      answer = answer or {}
      if r.positions then answer.positions = r.positions end
      if r.level then answer.level = r.level end
      answer.source = r.source
    end
  end
  if answer and not (answer.positions and answer.level) then answer = nil end
  LAST = { key = key, answer = answer }
  return answer
end

return M
