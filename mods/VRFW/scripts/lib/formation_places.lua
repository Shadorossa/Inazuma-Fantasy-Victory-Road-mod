-- VRFW › formation places: which position each place of a formation is (formation_config), for the scripts that need a
-- player's position in his team's formation instead of his card's.
--   local Places = require "VRFW/lib/formation_places"
--   Places.classes(formation id) -> { [place = roster slot 0..] = 1 GK, 2 FW, 3 MF, 4 DF, n = places }, nil when not found
-- The table is read at the first ask of each formation.

local C = require "VRFW/lib/random_team_core"
require "VRFW/lib/basics"
local _, warn = VRFW.logger("formation_places")

local M = {}
local STEM = "data/common/gamedata/formation/formation_config"
local FORMS = {}          -- formation id -> classes (false = not found)

local function table_key()
  local plain = STEM .. ".cfg.bin"
  local ok, k = pcall(VRFW.table.keys, plain)
  if ok and type(k) == "table" and #k > 0 then return plain end
  return STEM .. "_*.cfg.bin"
end

function M.classes(id)
  local f = FORMS[id]
  if f ~= nil then return f or nil end
  FORMS[id] = false
  local key = table_key()
  local okf, forms = pcall(VRFW.table.raw, key, "m_SoccerFormationInfoList")
  local okp, places = pcall(VRFW.table.raw, key, "m_SoccerFormPlacementInfoList")
  if not okf or not okp or type(forms) ~= "table" or type(places) ~= "table" then
    warn("formation_config not readable")
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
  return nil
end

return M
