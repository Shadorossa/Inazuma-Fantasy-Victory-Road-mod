FootballReforged = FootballReforged or {}
  if type(FootballReforged.bonus5) ~= "function" then
    function FootballReforged.bonus5(dock, tag, open, ...)
      local SWAP = @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_TEAMSWAP@
      local PARAM_MENU = 2197290544 --[[soccer_parameter_menu]]
      local log = VRFW.logger.new("EVT pachanga bonus")
      local n = 0
      for i = 0, 28 do
        local ok, h = funcLuaCommand(1720957768, dock, 1, i, 0)
        if ok and type(h) == "number" and h ~= 0 then
          n = n + 1
        end
      end
      if n == 0 then
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
        log(tag, "dock", dock, "empty 5v5 team: refused")
        return false
      end
      local ok = VRFW.host.command(SWAP, dock, 1)
      log(tag, "dock", dock, "5v5 members", n,
        "swap", tostring(ok))
      if not ok then
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
        return false
      end
      local swapped = true
      local function back()
        if swapped then
          swapped = false
          VRFW.host.command(SWAP, dock, 0)
        end
      end
      local wf = waitFalse
      if type(wf) == "function" then
        waitFalse = function(...)
          local r = table.pack(wf(...))
          if swapped and not funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, PARAM_MENU) then
            back()
          end
          return table.unpack(r, 1, r.n)
        end
      end
      local r = table.pack(pcall(open, ...))
      waitFalse = wf
      back()
      if not r[1] then
        error(r[2], 0)
      end
      return true, table.unpack(r, 2, r.n)
    end
  end
