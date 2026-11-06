-- Menu icons by meaning: a series' icon and a staff role's icon as a texture sheet + sprite pair (content/defaults/menu_icons.toml, every mod's, load order).
-- A menu script draws the pair on any quad with the sprite command 558735651(layer, sheet, sprite, texture node, 0, instance).
--   CMND_VRFW_SERIES_ICON(series name, alias or number[, style "on"]) -> ok, sheet hash, sprite hash
--   CMND_VRFW_ROLE_ICON(role "manager" / "coach") -> ok, sheet hash, sprite hash

MenuIcons = MenuIcons or {}

require "VRFW/lib/basics"
local _, warn = VRFW.logger("menu_icons")

local Id = require "lib/ids"
local u32 = Id.u32
local crc = VRFW.crc32

local SERIES = { sheet = nil, sprite = nil, sprite_on = nil }  -- sprite_on: the white «on» look (style "on")
local BY_NAME = {}                                              -- series name / alias -> { sheet, sprite }
local ROLES = { sheet = nil }                                   -- sheet + [role] = sprite name

local function read()
  local ok, files = pcall(VRFW.files.declarations, { "content/defaults/menu_icons.toml" })
  if not ok or type(files) ~= "table" then
    warn("menu_icons.toml not read (" .. tostring(files) .. "): no series / role icons")
    return
  end
  -- the framework's file first, then the mods' in load order (a later key wins)
  local ordered = {}
  for _, f in ipairs(files) do if f.mod == VRFW.mod then ordered[#ordered + 1] = f end end
  for _, f in ipairs(files) do if f.mod ~= VRFW.mod then ordered[#ordered + 1] = f end end
  for _, f in ipairs(ordered) do
    local d = type(f.data) == "table" and f.data or {}
    local s = d.series_icons
    if type(s) == "table" then
      if type(s.sheet) == "string" then SERIES.sheet = s.sheet end
      if type(s.sprite) == "string" then SERIES.sprite = s.sprite end
      if type(s.sprite_on) == "string" then SERIES.sprite_on = s.sprite_on end
      if type(s.by_series) == "table" then
        for name, one in pairs(s.by_series) do
          if type(one) == "table" and type(one.sheet) == "string" and type(one.sprite) == "string" then
            BY_NAME[tostring(name)] = { sheet = one.sheet, sprite = one.sprite }
          else
            warn(string.format("mods/%s: series_icons.by_series.%s needs sheet and sprite (text)", tostring(f.mod), tostring(name)))
          end
        end
      end
    end
    local r = d.role_icons
    if type(r) == "table" then
      for k, v in pairs(r) do
        if type(v) == "string" then ROLES[k] = v end
      end
    end
  end
end

read()

-- a series name / alias / number -> its number, nil when unknown
local function series_number(v)
  if type(v) == "number" then return math.floor(v) end
  local n = tonumber(v)
  if n then return math.floor(n) end
  local ok, t = pcall(VRFW.character.series_of, v)
  if ok and type(t) == "number" then return math.floor(t) end
  return nil
end

local CACHE = {}         -- "<series number>:<style>" -> { sheet hash, sprite hash } | false

local function series_icon(v, style)
  local t = series_number(v)
  if not t or t < 1 then return nil end
  local on = style == "on"
  local key = string.format("%d:%s", t, on and "on" or "")
  local c = CACHE[key]
  if c ~= nil then return c or nil end
  -- an icon declared by name for this series (any of its names)
  for name, one in pairs(BY_NAME) do
    if series_number(name) == t then
      c = { crc(one.sheet), crc(one.sprite) }
      break
    end
  end
  local pattern = (on and SERIES.sprite_on) or SERIES.sprite
  if not c and SERIES.sheet and pattern then
    local okn, names = pcall(VRFW.character.series_names)
    -- the sheet's numbered icons cover the game's series only (the index names them)
    if okn and type(names) == "table" and names[t] ~= nil then
      local sprite = pattern:gsub("{type}", function() return string.format("%02d", t) end)
      c = { crc(SERIES.sheet), crc(sprite) }
    end
  end
  CACHE[key] = c or false
  return c
end

function MenuIcons.CmdSeries(v, style)
  local c = series_icon(v, style)
  if not c then return false, 0, 0 end
  return true, c[1], c[2]
end

function MenuIcons.CmdRole(role)
  local sprite = type(role) == "string" and role ~= "sheet" and ROLES[role] or nil
  if not sprite or not ROLES.sheet then return false, 0, 0 end
  return true, crc(ROLES.sheet), crc(sprite)
end
