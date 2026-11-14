
VRFW.archetype = VRFW.archetype or {}
local A = VRFW.archetype
A.CMD_TEAM = A.CMD_TEAM or 3704961242    -- CMND_VRFW_ARCHETYPE_TEAM
A.CMD_MATCH = A.CMD_MATCH or 2854479468  -- CMND_VRFW_ARCHETYPE_MATCH
A.CMD_INFO = A.CMD_INFO or 3552358290    -- CMND_VRFW_ARCHETYPE_INFO

local ICON_COMMON = 2320109963      -- #/menu/200_icon/15_icon_common/icon_common.g4tx
local ICON_COMMON_LG = 502529699    -- #/menu/200_icon/15_icon_common/<LG>/icon_common.g4tx
local ICON_DMY = 2789893477         -- icon_build_dmy01
local MESH_DMY = 260772049          -- _icon_build_dmy01
local TEXT_BUILD = 2160352228       -- _text_build01
local TEXT_FLAVOR = 691026122       -- _text_flavor01
local L_ICON = 721367678            -- team00_14_build_type_icon
local L_BALLOON = 2914643032        -- team00_15_build_type_balloon

local function info(n)
  if type(n) ~= "number" or n < 7 then return nil end
  local has, name, desc, icon, large, gauge = VRFW.host.command(A.CMD_INFO, n)
  if has == true then return { name = name, desc = desc, icon = icon, large = large, gauge = gauge } end
  return nil
end

local function team_info(dock, party)
  local b = VRFW.host.command(A.CMD_TEAM, dock or 0, party or 0)
  if type(b) == "number" and b >= 7 then return info(b) end
  return nil
end

local function match_info(side)
  if side ~= 0 and side ~= 1 then return nil end
  local b = VRFW.host.command(A.CMD_MATCH, side)
  if type(b) == "number" and b >= 7 then return info(b) end
  return nil
end

local function text(id)
  local s = VRFW.host.command(VRFW.commands.TEXT_GET, id) -- CMND_TEXT_GET
  if type(s) == "string" then return s end
  return nil
end

--- Internal: archetype table of the formation menu.
A.formation = A.formation or {}
local W = A.formation

local function wrap(name, make)
  local cur = _G[name]
  if type(cur) ~= "function" or cur == W[name] then return end
  W[name] = make(cur)
  _G[name] = W[name]
end

wrap("UpdateTeamBuildTypeInfo", function(orig)
  return function(a1, a2, a3, a4, ...)
    local r = orig(a1, a2, a3, a4, ...)
    local x = team_info(a1, a2 or 0)
    if x then
      local l9, l10 = a3 or L_ICON, a4 or L_BALLOON
      if x.large ~= 0 then VRFW.host.menu_command(558735651, l9, ICON_COMMON, x.large, ICON_DMY, 0, 0) end
      local name = text(x.name)
      if name then VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_STRING, l9, TEXT_BUILD, name, 0) end
      local desc = text(x.desc)
      if desc then VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_STRING, l10, TEXT_FLAVOR, desc, 0) end
    end
    return r
  end
end)

local function field_of(x, f)
  if f == 0 then return x.large elseif f == 1 then return x.name elseif f == 2 then return x.desc end
  return nil
end

wrap("GetTeamBuildTypeInfoByTeamSetNo", function(orig)
  return function(a1, a2, a3, ...)
    local r = orig(a1, a2, a3, ...)
    local x = team_info(a1, a2)
    local v = x and field_of(x, a3)
    if v ~= nil and v ~= 0 then return v end
    return r
  end
end)

wrap("GetTeamBuildTypeInfoByTeamNo", function(orig)
  return function(a1, a2, ...)
    local r = orig(a1, a2, ...)
    local x = match_info(a1)
    local v = x and field_of(x, a2)
    if v ~= nil and v ~= 0 then return v end
    return r
  end
end)

wrap("UpdateTeamParameterButtonGuideByTeamDockNo", function(orig)
  return function(a1, a2, a3, a4, ...)
    local r = orig(a1, a2, a3, a4, ...)
    local vis = VRFW.host.menu_command(VRFW.commands.IS_MESH_VISIBLE, a1, MESH_DMY, a2) -- CMND_IS_MESH_VISIBLE
    if vis == true then
      local x = team_info(a3, a4)
      if x and x.large ~= 0 then VRFW.host.menu_command(558735651, a1, ICON_COMMON_LG, x.large, ICON_DMY, 0, a2) end
    end
    return r
  end
end)
