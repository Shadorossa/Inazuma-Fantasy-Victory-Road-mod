
local function logger(tag)
  local prefix = tostring(tag) .. ":"
  local function info(...)
    VRFW.log(prefix, ...)
  end
  local function warn(...)
    VRFW.warn(prefix, ...)
  end
  local function err(...)
    VRFW.error(prefix, ...)
  end
  local function debug(...)
    VRFW.debug(prefix, ...)
  end
  return info, warn, err, debug
end

return logger
