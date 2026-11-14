--- Advanced: Library: move level rules of the running match.

local ME = VRFW.match.equipment
local MatchRules = VRFW.match.rules
local _, warn = VRFW.logger("match_move_level")

local M = {}

local RULES = nil   -- { { play_mode, difficulty, side, grade, source } }
local GRADE_FIELDS = { "grade" }

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

--- Advanced: The move level rule answer of `side` for match info `info`.
function M.for_match_info(info, side)
  return MatchRules.answer(load(), info, side, GRADE_FIELDS)
end

--- Advanced: The move level rule answer of `side` for the running match.
function M.running(side)
  local g = VRFW.game and VRFW.game.match_equipment_info
  if type(g) ~= "function" then return nil end
  local ok, info = pcall(g)
  if not ok or type(info) ~= "number" then return nil end
  return M.for_match_info(info, side)
end

return M
