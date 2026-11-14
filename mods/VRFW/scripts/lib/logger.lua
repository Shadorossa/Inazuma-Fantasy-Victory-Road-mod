-- VRFW.logger(tag): makes a logger whose lines start with `tag`. Returns info and warn functions. Call: at load or in a handler.
--- Library: makes a tagged logger; answers info and warn functions.

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
