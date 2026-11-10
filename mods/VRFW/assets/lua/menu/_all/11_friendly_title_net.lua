-- friendly way back (VRFW, match engine friendlies).
do
  local NET = VRFW.commands.VRFW_FRIENDLY_TITLE_NET
  local MENU_BACK = VRFW.commands.VRFW_FRIENDLY_MENU_BACK
  local BACK = VRFW.commands.VRFW_FRIENDLY_BACK
  local GAME_RESET = VRFW.commands.GAME_RESET
  local FADE = 609722083          -- (on, seconds): screen fade to black
  local TITLE = {title_menu_2 = true, title_main = true}
  local STATE = VRFW.commands.VRFW_FRIENDLY_STATE       -- crc32("CMND_VRFW_FRIENDLY_STATE") -> phase, id, …, return
  local IS_SOCCER = VRFW.commands.IS_SOCCER_MODE
  local PARAM_WAY_BACK_MENU = 3244649355          -- crc32("vrfw_match_way_back_menu"), set by 12_match_start.lua
  local PARAM_WAY_BACK_FRIENDLY = 1563930864
  local PLAYED, RETURN_MENUS = 3, 3               -- STATE: phase Played, return 3 = menus

  local script = type(VRFW.patch) == "table" and VRFW.patch.script or "?"
  local stem = type(script) == "string" and (script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "")) or "?"
  local checked = false
  local net_co, has_step = nil, false

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("VRFW friendly_way_back")
    logger(tostring(stem), ...)
  end

  local function way_back_clear()
    for _, k in ipairs({PARAM_WAY_BACK_MENU, PARAM_WAY_BACK_FRIENDLY}) do
      if VRFW.param.has(k) then VRFW.param.clear(k) end
    end
  end

  local function menu_back()
    local ok, go, id, _, mode = pcall(funcLuaCommand, MENU_BACK, stem)
    if not ok or go ~= true then
      return false
    end
    way_back_clear()
    if type(mode) == "number" and mode >= 0 then
      pcall(funcLuaCommand, 3718253404 --[[set play mode]], mode)
    end
    local P = VRFW.friendly_match
    if type(P) == "table" and type(P.back) == "function" then
      local info = P.back(3)
      log("friendly " .. tostring(id) .. ": back in its hub, closed (no game reset)", tostring(info and info.closed))
      return true
    end
    local okb, closed, _, _, _, team_swapped = pcall(funcLuaCommand, BACK, 3)
    if okb and closed == true and team_swapped == true then
      local okv, had, vs = pcall(funcLuaCommand, VRFW.commands.VRFW_FRIENDLY_VS, 0)
      if okv and had == true and type(vs) == "number" and vs >= 0 then
        pcall(funcLuaCommand, VRFW.commands.SET_VS_USE_TEAM_SET, vs)
      end
    end
    log("friendly " .. tostring(id) .. ": back in its hub, closed without VRFW.friendly_match (no rewards rolled)",
      tostring(okb and closed))
    return true
  end

  local function title_net()
    if TITLE[stem] then
      return
    end
    local ok, go, id, try = pcall(funcLuaCommand, NET)
    if not ok or go ~= true then
      return
    end
    log("friendly " .. tostring(id) ..
      ": its way back to the title was lost after the match; going to the title now (try " .. tostring(try) .. ")")
    pcall(funcLuaCommand, FADE, 1, 0)                 -- black at once: no frame of the wiped menus
    pcall(funcLuaMenuCommand, 3479138216, 0)          -- the same calls as the top bar's reset to the title
    pcall(funcLuaCommand, 937976662, true)
    pcall(funcLuaCommand, 419468738, false)
    pcall(funcLuaCommand, 1507811093, false)
    pcall(funcLuaCommand, GAME_RESET)
  end

  local function menus_net(where)
    if TITLE[stem] or stem == "?" or not has_step then
      return false
    end
    local target = VRFW.ids.unsigned_or(VRFW.param.get(PARAM_WAY_BACK_MENU), nil)
    if target == nil or target == 0 or target == VRFW.crc32(stem) then
      return false
    end
    local oks, phase, id, _, _, _, _, ret = pcall(funcLuaCommand, STATE)
    if not oks or phase ~= PLAYED or ret ~= RETURN_MENUS or type(id) ~= "string" then
      return false
    end
    if VRFW.ids.unsigned_or(VRFW.param.get(PARAM_WAY_BACK_FRIENDLY), nil) ~= VRFW.crc32(id) then
      return false
    end
    local okm, soccer = pcall(funcLuaCommand, IS_SOCCER)
    if okm and soccer == true then
      return false
    end
    pcall(funcLuaCommand, FADE, 1, 0)                 -- black at once: no frame of the field
    log("friendly " .. id .. ": the match's way back did not reopen its hub " .. tostring(target) ..
      " (this VM opened instead, " .. where .. "): straight reset into it")
    net_co = coroutine.create(function()
      if VRFW.reset.wait_save() then
        log("friendly " .. id .. ": menus net: the save job is over")
      end
      if VRFW.ids.unsigned_or(VRFW.param.get(PARAM_WAY_BACK_MENU), nil) ~= target then
        log("friendly " .. id .. ": menus net: the way back was taken by another menu")
        return
      end
      way_back_clear()
      local how = VRFW.reset.straight({ menu = target, bgm_stop = true, need_carry = true,
        log = function(text) log("menus net: " .. text) end })
      log("friendly " .. id .. ": menus net: " .. tostring(how))
      if how == "refused" then
        log("friendly " .. id .. ": menus net: no kept game, the retail reset to the title instead")
        VRFW.reset.to_title()
      end
    end)
    return true
  end

  local function check(where)
    if checked then
      return
    end
    checked = true
    if not menu_back() then
      title_net()
      if not menus_net(where) then
        net_co = nil
      elseif net_co ~= nil then
        local okr, err = coroutine.resume(net_co)           -- at once: no frame of the field when no save job runs
        if not okr then log("menus net: error " .. tostring(err)) end
        if not okr or coroutine.status(net_co) == "dead" then net_co = nil end
      end
    end
  end

  local init = OnInit
  if type(init) == "function" then
    OnInit = function(...)
      local r = table.pack(init(...))
      pcall(check, "OnInit")
      return table.unpack(r, 1, r.n)
    end
  end
  local function resume()
    if net_co == nil then
      return
    end
    local okr, err = coroutine.resume(net_co)
    if not okr then
      log("menus net: error " .. tostring(err))
    end
    if not okr or coroutine.status(net_co) == "dead" then
      net_co = nil
    end
  end
  for _, name in ipairs({ "Step", "OnSetupLayer", "OnOpenLayer" }) do
    local f = rawget(_ENV, name)
    if type(f) == "function" then
      has_step = true
      rawset(_ENV, name, function(...)
        local r = table.pack(f(...))
        if not checked then
          pcall(check, "first " .. name)
        end
        resume()
        return table.unpack(r, 1, r.n)
      end)
    end
  end
  local VH = VRFW.host
  if stem ~= "?" and type(VH) == "table" and type(VH.on) == "function" then
    pcall(VH.on, stem, "OnInit", {id = "VRFW.friendly_way_back", phase = "around", fn = function(nxt, ...)
      local r = table.pack(nxt(...))
      pcall(check, "OnInit")
      return table.unpack(r, 1, r.n)
    end})
  end
end
