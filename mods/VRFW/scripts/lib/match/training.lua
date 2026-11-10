
local ME = VRFW.match.equipment
local MatchRules = VRFW.match.rules
local _, warn = VRFW.logger("match_training")

local M = {}

local POSITION = { GK = 1, FW = 2, MF = 3, DF = 4 }

local RULES = nil
local TRAINING_FIELDS = { "positions", "level" }

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

--- The training rule answer of `side` for match info `info`.
function M.for_match_info(info, side)
  return MatchRules.answer(load(), info, side, TRAINING_FIELDS)
end

return M
