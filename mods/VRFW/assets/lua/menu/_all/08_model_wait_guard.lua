-- lua_patch.scope: used
local MWG_READY = 1583438030   -- menu model component complete? (layer, idx)
local MWG_LOG = VRFW.commands.VRFW_LOG
local MWG_SLOW = 30            -- frames from which a wait is logged

--- Advanced: Wraps model-wait global `name` so it waits for layer o.layer's model at most o.max frames, then goes on; answers true, or false, why.
function VRFW.model_wait_guard(name, o)
  local orig = rawget(_ENV, name)
  if type(orig) ~= "function" or type(o) ~= "table" or type(o.layer) ~= "number" then
    return false, "no such global, or no options with a layer"
  end
  local max, command = o.max or 300, o.ready or MWG_READY
  local function ready(idx)
    local r = VRFW.host.menu_command(command, o.layer, idx)
    return r == true
  end
  local function log(idx, n, done)
    if n >= MWG_SLOW or not done then
      pcall(funcLuaCommand, MWG_LOG, "model_wait_guard " .. name .. (done and " model ready after " or
        " model not ready, going on after ") .. tostring(n) .. " frame(s), layer " .. tostring(o.layer) ..
        " instance " .. tostring(idx))
    end
  end
  _ENV[name] = function(...)
    local a1, a2 = ...
    local idx = o.idx or 0
    if o.layer_arg then
      local _, main = coroutine.running()
      if a1 ~= o.layer or main then
        return orig(...)                  -- Another layer, or no coroutine to wait in.
      end
      idx = type(a2) == "number" and a2 or idx
    end
    if o.skip ~= nil and select("#", ...) > 0 and a1 == o.skip then
      return orig(...)                    -- the caller asked for no wait
    end
    if o.first_yield then
      coroutine.yield()
    end
    local n = 0
    while n < max and not ready(idx) do
      n = n + 1
      coroutine.yield()
    end
    local done = n < max or ready(idx)
    log(idx, n, done)
    if o.skip ~= nil then
      return orig(o.skip, select(2, ...))
    end
    if done then
      return orig(...)
    end
    local real = funcLuaMenuCommand
    funcLuaMenuCommand = function(c, l, i, ...)
      if c == command and l == o.layer then
        return true
      end
      return real(c, l, i, ...)
    end
    local r = table.pack(pcall(orig, ...))
    funcLuaMenuCommand = real
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end
  return true
end
