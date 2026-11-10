
local C = VRFW.teams.random
local _, warn = VRFW.logger("formation_places")

local M = {}
local FORMS = {}          -- formation id -> classes (false = not in the readable table)
local UNREADABLE_WARNED = false

--- The position classes of formation `id`; nil when unknown.
function M.classes(id)
  local f = FORMS[id]
  if f ~= nil then return f or nil end
  local key = VRFW.table_files.file_name(VRFW.table_files.FORMATION_CONFIG)
  local okf, forms = pcall(VRFW.table.raw, key, "m_SoccerFormationInfoList")
  local okp, places = pcall(VRFW.table.raw, key, "m_SoccerFormPlacementInfoList")
  if not okf or not okp or type(forms) ~= "table" or type(places) ~= "table" then
    if not UNREADABLE_WARNED then
      UNREADABLE_WARNED = true
      warn("formation_config not readable")
    end
    return nil
  end
  for _, r in ipairs(forms) do
    if type(r.formId) == "number" and C.u32(r.formId) == id then
      local s = r.placementInfo
      if type(s) ~= "table" or type(s.start) ~= "number" or type(s.count) ~= "number" then break end
      local out, n = {}, 0
      for k = s.start + 1, s.start + s.count do
        local p = places[k]
        if p and type(p.positionNo) == "number" then
          out[math.floor(p.positionNo) % 256] = C.placement_class(type(p.positionId) == "number" and p.positionId or 0)
          n = n + 1
        end
      end
      out.n = n
      FORMS[id] = out
      return out
    end
  end
  FORMS[id] = false
  return nil
end

return M
