
local ME = VRFW.match.equipment

local M = {}

local LAST = setmetatable({}, { __mode = "k" })   -- [rules] = { key, answer }

--- The `fields` of the first of `rules` matching match info `info` and `side`; nil when none.
function M.answer(rules, info, side, fields)
  if type(rules) ~= "table" or #rules == 0 then return nil end
  local game, diff, mode = ME.match_of(info)
  if not game then return nil end
  local key = string.format("%d:%d:%s:%s", game, diff, tostring(mode), tostring(side))
  local last = LAST[rules]
  if last and last.key == key then return last.answer end
  local answer = nil
  for _, r in ipairs(rules) do
    if r.difficulty == diff and (r.play_mode == nil or r.play_mode == mode) and r.side == side then
      for _, name in ipairs(fields) do
        if r[name] ~= nil then
          answer = answer or {}
          answer[name], answer.source = r[name], r.source
        end
      end
    end
  end
  if answer then
    for _, name in ipairs(fields) do
      if answer[name] == nil then
        answer = nil
        break
      end
    end
  end
  LAST[rules] = { key = key, answer = answer }
  return answer
end

return M
