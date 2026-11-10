BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.top_bar = type(BetterQoL.top_bar) == "table" and BetterQoL.top_bar or {}
BetterQoL.top_bar.READY_KEY = 1915179208 --[[crc32 betterqol_title_ready]]

do
  local wait = SwitchCaseTitleInputWait
  if type(wait) == "function" then
    function SwitchCaseTitleInputWait(...)
      pcall(function()
        if VRFW.param.has(BetterQoL.top_bar.READY_KEY) then
          VRFW.param.clear(BetterQoL.top_bar.READY_KEY)
        end
        VRFW.param.set(BetterQoL.top_bar.READY_KEY, 1)
      end)
      return wait(...)
    end
  end
end

-- Returns whether the title is black, since the engine has one full-screen fade.
function BetterQoL.top_bar.title_is_black()
  return funcLuaCommand(2259183189) == true and funcLuaCommand(3249777136, 0) == true
end

do
  local fade = SwitchCaseTitleFade
  if type(fade) == "function" then
    function SwitchCaseTitleFade(...)
      local ok, black = pcall(BetterQoL.top_bar.title_is_black)
      if not ok or not black then
        return fade(...)
      end
      local cmd = funcLuaCommand
      funcLuaCommand = function(id, ...)
        if id == 4011714927 --[[white fade]] then
          return cmd(609722083 --[[black fade]], ...)
        end
        return cmd(id, ...)
      end
      local r = table.pack(pcall(fade, ...))
      funcLuaCommand = cmd
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end
  end
end

BetterQoL.top_bar.FAST = {BUSY = 2173683199 --[[crc32 vrfw_top_bar_busy]], noted = false}

function BetterQoL.top_bar.fast_log(...)
  BetterQoL.top_bar.fast_logger = BetterQoL.top_bar.fast_logger or VRFW.logger.new("BetterQoL top_bar fast title")
  BetterQoL.top_bar.fast_logger(...)
end

function BetterQoL.top_bar.fast_l()
  local F = BetterQoL.top_bar.FAST
  if not VRFW.param.has(F.BUSY) then
    return nil
  end
  local h = type(VRFW.host) == "table" and type(VRFW.host.hosts) == "table" and VRFW.host.hosts.title_main or nil
  local L = h ~= nil and h.L or nil
  local ok, n = false, nil
  if L ~= nil then
    ok, n = pcall(function() return L.n16 end)
  end
  if not ok or type(n) ~= "number" then
    if not F.noted then
      F.noted = true
      BetterQoL.top_bar.fast_log("locals not reachable (no VRFW.host title_main L / VRFW.debug): retail waits kept")
    end
    return nil
  end
  return L, n
end

do
  local function skip(name, expect, to)
    local f = _G[name]
    if type(f) ~= "function" then
      return
    end
    _G[name] = function(...)
      local L, n = BetterQoL.top_bar.fast_l()
      if L ~= nil then
        if n == expect then
          local ok = pcall(function() L.n16 = to end)
          if ok then
            BetterQoL.top_bar.fast_log(name, "skipped", "state", expect, "->", to)
            return false
          end
          BetterQoL.top_bar.fast_log(name, "could not write the state: retail")
        else
          BetterQoL.top_bar.fast_log(name, "state", n, "not", expect, ": retail")
        end
      end
      return f(...)
    end
  end
  skip("SwitchCaseTitleWaitFade", 3, 4)
  skip("SwitchCaseTitleEndFadeInit", 7, 8)
end
