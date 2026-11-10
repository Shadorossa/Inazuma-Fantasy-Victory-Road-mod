
BetterQoL = BetterQoL or {}
BetterQoL.ViewForms = BetterQoL.ViewForms or {}
local ViewForms = BetterQoL.ViewForms

-- defaults match config.toml [view_forms] and the graft's fallbacks
local settings = {
  badge_x = 1720,
  badge_y = 230,         -- the row's vertical centre (screen px, y down)
  badge_scale = 1,       -- the whole row's scale
  badge_priority = 690,  -- tiles' draw priority; the glyph draws one above
  tile_size = 52,        -- a tile's side (screen px at scale 1)
  tile_gap = 6,          -- the gap between the two tiles
  key_scale = 0.9,       -- the key glyph's text scale
  key_dx = 0,            -- key glyph nudge inside the light tile (screen px)
  key_dy = 0,            -- y down
}

do
  local c = VRFW.config("view_forms")
  if type(c) == "table" then
    for k, v in pairs(c) do
      if settings[k] ~= nil and type(v) == "number" then settings[k] = v end
    end
  end
end

-- CMND_BETTERQOL_VIEW_FORMS_CFG() -> a copy of the settings
function ViewForms.Config()
  local answer = {}
  for k, v in pairs(settings) do
    answer[k] = v
  end
  return answer
end

VRFW.log("view_forms: indicator at " .. tostring(settings.badge_x) .. "," .. tostring(settings.badge_y)
  .. " scale " .. tostring(settings.badge_scale) .. " priority " .. tostring(settings.badge_priority)
  .. " tiles " .. tostring(settings.tile_size) .. "+" .. tostring(settings.tile_gap))
