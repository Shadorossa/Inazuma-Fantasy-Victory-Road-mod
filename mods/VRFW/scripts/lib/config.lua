
-- config paths already warned about a value of the wrong type (bounded; one warning per path and VM)
local WRONG_TYPE_WARNED = {}
local WRONG_TYPE_WARNED_COUNT = 0
local WRONG_TYPE_WARN_LIMIT = 256

local function warn_wrong_type(path, v, default)
  local key = tostring(path)
  if WRONG_TYPE_WARNED[key] or WRONG_TYPE_WARNED_COUNT >= WRONG_TYPE_WARN_LIMIT then
    return
  end
  WRONG_TYPE_WARNED[key] = true
  WRONG_TYPE_WARNED_COUNT = WRONG_TYPE_WARNED_COUNT + 1
  if type(VRFW.warn) == "function" then
    pcall(VRFW.warn, "config:", key .. " is a " .. type(v) .. ", expected a " .. type(default)
      .. "; the default " .. tostring(default) .. " is used")
  end
end

-- mod: read another mod's config (default: the calling mod)
local function config(path, default, min, max, mod)
  local files = VRFW.files
  local v = nil
  if type(files) == "table" then
    local ok, got = pcall(files.config, path, mod)
    if ok then
      v = got
    end
  end
  if v ~= nil and default ~= nil and type(v) ~= type(default) then
    warn_wrong_type(path, v, default)
    return default
  end
  if min ~= nil or max ~= nil then
    return VRFW.value.clamp(v, default, min, max)
  end
  if v ~= nil then
    return v
  end
  return default
end

return config
