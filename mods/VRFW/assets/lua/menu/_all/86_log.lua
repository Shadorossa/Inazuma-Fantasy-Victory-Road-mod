-- VRFW.logger: the one logger of the menu scripts (lines go to the loader's log through CMND_VRFW_LOG).
if VRFW.logger == nil then
  local LOG = VRFW.commands.VRFW_LOG
  local LOG_DEBUG = VRFW.commands.VRFW_LOG_DEBUG
  local NONE = {}                    -- the "no value yet" mark of log.changed

  local L = {}

  --- VRFW.logger.new(tag): a log function whose lines start with tag; it also has debug, once and changed. Call only from OnInit, Step or another callback.
  function L.new(tag)
    tag = tostring(tag or "log")
    local once_seen = {}
    local last_value = {}
    local logger = { tag = tag }

    local function write(...)
      local f = _ENV.funcLuaCommand
      if type(f) == "function" then
        pcall(f, LOG, tag, ...)
      end
    end

    --- Logs the arguments at debug level.
    function logger.debug(...)
      local f = _ENV.funcLuaCommand
      if type(f) == "function" then
        pcall(f, LOG_DEBUG, tag, ...)
      end
    end

    --- Logs once per key; answers true when it logged.
    function logger.once(key, ...)
      if once_seen[key] then
        return false
      end
      once_seen[key] = true
      write(...)
      return true
    end

    --- Logs when the value of `key` changed; answers true when it logged.
    function logger.changed(key, value, ...)
      local stored = last_value[key]
      local now = value
      if now == nil then
        now = NONE
      end
      if stored ~= nil and stored == now then
        return false
      end
      last_value[key] = now
      write(...)
      return true
    end

    return setmetatable(logger, { __call = function(_, ...) write(...) end })
  end

  --- Menu logging: VRFW.logger.new(tag). Safe at load.
  VRFW.logger = L
end
