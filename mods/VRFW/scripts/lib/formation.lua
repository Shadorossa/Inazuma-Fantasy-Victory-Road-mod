--- Advanced: Library: formation places and classes from formation_config.

local C = VRFW.teams.random
local _, warn = VRFW.logger("formation_places")

local M = {}
local FORMS = nil         -- formation id -> classes, every formation of formation_config (built once per VM)
local UNREADABLE_WARNED = false

-- every formation's position classes: [formation id] = { [position no] = class, n = places }
local function build_all()
  local key = VRFW.table_files.file_name(VRFW.table_files.FORMATION_CONFIG)
  local forms = VRFW.table.raw(key, "m_SoccerFormationInfoList")
  local places = VRFW.table.raw(key, "m_SoccerFormPlacementInfoList")
  if type(forms) ~= "table" or type(places) ~= "table" then error("formation_config lists not tables") end
  local all = {}
  for _, r in ipairs(forms) do
    local s = r.placementInfo
    if type(r.formId) == "number" and type(s) == "table" and type(s.start) == "number" and type(s.count) == "number" then
      local out, n = {}, 0
      for k = s.start + 1, s.start + s.count do
        local p = places[k]
        if p and type(p.positionNo) == "number" then
          out[math.floor(p.positionNo) % 256] = C.placement_class(type(p.positionId) == "number" and p.positionId or 0)
          n = n + 1
        end
      end
      out.n = n
      local id = C.u32(r.formId)
      if all[id] == nil then all[id] = out end
    end
  end
  return all
end

--- Internal: Builds (or reads from the start cache) every formation's classes; a script calls it at load so a match call stays short.
function M.prepare()
  if FORMS then return FORMS end
  local ok, all = pcall(VRFW.derived, "formation_classes", nil, build_all)
  if ok and type(all) == "table" then
    FORMS = all
  else
    FORMS = {}
    if not UNREADABLE_WARNED then
      UNREADABLE_WARNED = true
      warn("formation_config not readable (" .. tostring(all) .. ")")
    end
  end
  return FORMS
end

--- Advanced: The position classes of formation `id`; nil when unknown.
function M.classes(id)
  return M.prepare()[id]
end

return M
