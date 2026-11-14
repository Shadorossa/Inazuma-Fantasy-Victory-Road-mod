-- The HUD skins: the retail look each declared part of the match HUD takes (content\hud_skins, VRFW.hud_skin/1).
VRFW.hud_skins = VRFW.hud_skins or {}

local D = VRFW.declarations
local info, warn = VRFW.logger("hud_skins")

-- part -> { look, key } of the declaration in force.
local LOOKS = {}

local function start()
  local schema, why = D.schema("hud_skin")
  if not schema then
    warn(why .. ": every HUD part keeps its own look")
    return
  end
  local decls, skipped = D.load(schema, warn)
  local parts = {}
  for _, d in ipairs(decls) do
    local v = d.v
    local held = LOOKS[v.part]
    if held == nil then
      LOOKS[v.part] = { look = v.look, key = d.key }
      parts[#parts + 1] = string.format("%s = %s (%s)", v.part, v.look, d.key)
    elseif held.look ~= v.look then
      warn(string.format("%s: part %s already takes look %s from %s: left out", d.where, v.part, held.look, held.key))
    end
  end
  if #parts == 0 then
    info(string.format("off: no HUD skin in force (%d declaration(s) left out by `when`)", skipped or 0))
  else
    info("on: " .. table.concat(parts, ", "))
  end
end

-- CMND_VRFW_HUD_SKIN(part) -> the look of `part` ("" when no mod declares one).
function VRFW.hud_skins.look(part)
  local held = LOOKS[tostring(part)]
  return held and held.look or ""
end

start()
