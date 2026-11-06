-- model_wait_guard (VRFW, retail bug fix): a cap on the retail
-- coroutines that wait, frame after frame, for a menu 3D model component to be ready (by default «complete», CMND
-- 1583438030 (layer, idx)) with no way out. When the model never gets ready (after closing the shop opened from
-- Modo Crónica's START box: chronicle_mode_top_menu's WaitCaravanModelLoad waited for the caravan forever: no fade-in,
-- no menu input, no HANG) the menu stays frozen. With the guard the wait ends after `max` frames and the retail goes
-- on as if the model were ready (the model shows up by itself when it gets ready later).
--
--   VRFW_ModelWaitGuard(name, { layer = <model layer>, idx = 0, max = 300,
--                              first_yield = true,   -- the retail yields once before its first read
--                              skip = false,         -- argument that makes the retail skip its wait (nil = none)
--                              ready = 2787787510,   -- the read the retail waits on (default 1583438030 «complete»)
--                              layer_arg = true })   -- the function is a layer callback (layer, idx, ...): only a
--                                                    -- call for `layer` inside a coroutine is guarded, idx = its 2nd
--                                                    -- argument; every other call goes straight to the retail
--
-- `name` is the global function of the calling script. Without `skip` the retail is called with the ready read
-- answered true for that layer only while it runs (it must not yield before its loop). Only defines functions: no
-- engine call at load time. Log (CMND_EVT_LOG): «model_wait_guard <name> ...» when the wait took 30+ frames or hit
-- the cap.
local MWG_READY = 1583438030   -- menu model component complete? (layer, idx)
local MWG_LOG = VRFW_Cmd.EVT_LOG
local MWG_SLOW = 30            -- frames from which a wait is logged

function VRFW_ModelWaitGuard(name, o)
  local orig = rawget(_ENV, name)
  if type(orig) ~= "function" or type(o) ~= "table" or type(o.layer) ~= "number" then
    return false
  end
  local max, command = o.max or 300, o.ready or MWG_READY
  local function ready(idx)
    local ok, r = pcall(funcLuaMenuCommand, command, o.layer, idx)
    return ok and r == true
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
        return orig(...)                  -- another layer, or no coroutine to wait in
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
    -- no skip argument: answer «ready» for this layer while the retail runs its (non-yielding) rest
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
