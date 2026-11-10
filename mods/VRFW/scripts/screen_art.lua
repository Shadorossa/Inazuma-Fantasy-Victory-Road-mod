-- VRFW › screen art (docs/framework/screen-art.md, VRFW 2.4.51; the framework ships no other mod's content).
-- Merged per screen and role in load order (a later mod's role wins).

ScreenArt = ScreenArt or {}

local info, warn = VRFW.logger("screen_art")

local SCHEMA = "VRFW.screen_art/1"
local ART = nil   -- screen -> role -> { atlas, sprite, mod }

local function name_ok(s)
  return type(s) == "string" and s:match("^[%w_%.%-]+$") ~= nil
end

local function atlas_ok(s)
  return type(s) == "string" and s:match("^#/menu/.+%.g4tx$") ~= nil
end

local function load()
  ART = {}
  local ok, files = pcall(VRFW.files.declarations, "content/screen_art")
  if not ok or type(files) ~= "table" then
    return
  end
  for _, f in ipairs(files) do
    local d = f.data or {}
    local where = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    if d.schema ~= SCHEMA then
      warn(string.format("%s: schema %q is not %s: file left out", where, tostring(d.schema), SCHEMA))
    else
      local v = type(d.VRFW) == "table" and d.VRFW or {}
      for i, a in ipairs(v.ScreenArt or {}) do
        local at = string.format("%s: [[VRFW.ScreenArt]] #%d", where, i)
        if not name_ok(a.Screen) then
          warn(at .. ": Screen = \"<a framework screen>\" is required: left out")
        elseif a.Atlas ~= nil and not atlas_ok(a.Atlas) then
          warn(at .. ": Atlas must be a \"#/menu/...g4tx\" path: left out")
        else
          local screen = ART[a.Screen] or {}
          ART[a.Screen] = screen
          local n = 0
          for role, s in pairs(type(a.Sprites) == "table" and a.Sprites or {}) do
            local atlas, sprite = a.Atlas, s
            if type(s) == "table" then
              atlas, sprite = s.Atlas or a.Atlas, s.Sprite
            end
            if not name_ok(role) or not name_ok(sprite) or not atlas_ok(atlas) then
              warn(string.format("%s: role %q: a sprite name of an Atlas is required: left out", at, tostring(role)))
            else
              screen[role] = { atlas = atlas, sprite = sprite, mod = f.mod }
              n = n + 1
            end
          end
          info(string.format("%s: %s, %d role(s) from %s", a.Screen, tostring(f.mod), n, where))
        end
      end
    end
  end
end

function ScreenArt.Get(screen)
  if ART == nil then
    load()
  end
  local out = {}
  for role, a in pairs(ART[tostring(screen)] or {}) do
    out[role] = { atlas = a.atlas, sprite = a.sprite, mod = a.mod }
  end
  if next(out) == nil then
    info(tostring(screen) .. ": no mod declares its art: the plain fallback")
  end
  return out
end
