
VRFW.archetype = VRFW.archetype or {}
local A = VRFW.archetype
A.CMD_TEAM = A.CMD_TEAM or VRFW.commands.VRFW_ARCHETYPE_TEAM
A.CMD_MATCH = A.CMD_MATCH or VRFW.commands.VRFW_ARCHETYPE_MATCH
A.CMD_INFO = A.CMD_INFO or VRFW.commands.VRFW_ARCHETYPE_INFO

local LIST_BASE = 862546245     -- soccer11_21_formation_team_passive_list_base
local ICON_COMMON_LG = 502529699
local ICON_DMY = 2789893477     -- icon_build_dmy01
local TEXT_BUILD = 2160352228   -- _text_build01

local function current_build()
  local soccer = VRFW.host.command(VRFW.commands.IS_SOCCER_MODE) -- CMND_IS_SOCCER_MODE
  if soccer == true then
    local has, side = VRFW.host.command(VRFW.commands.GET_SOCCER_TEAM_INFO, 0) -- CMND_GET_SOCCER_TEAM_INFO(0): the user's side
    if not (has == true and (side == 0 or side == 1)) then return nil end
    local b = VRFW.host.command(A.CMD_MATCH, side)
    if type(b) == "number" and b >= 7 then return b end
    return nil
  end
  local b = VRFW.host.command(A.CMD_TEAM)
  if type(b) == "number" and b >= 7 then return b end
  return nil
end

A.parameter = A.parameter or {}
local W = A.parameter

if type(OnSetupLayer) == "function" and OnSetupLayer ~= W.OnSetupLayer then
  local orig = OnSetupLayer
  W.OnSetupLayer = function(a1, a2, ...)
    local r = orig(a1, a2, ...)
    if a1 == LIST_BASE then
      local b = current_build()
      if b then
        local has, name, _, _, large = VRFW.host.command(A.CMD_INFO, b)
        if has == true then
          if type(large) == "number" and large ~= 0 then
            VRFW.host.menu_command(558735651, a1, ICON_COMMON_LG, large, ICON_DMY, 0, a2)
          end
          local s = VRFW.host.command(VRFW.commands.TEXT_GET, name) -- CMND_TEXT_GET
          if type(s) == "string" then
            VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_STRING, a1, TEXT_BUILD, s, a2)
            VRFW.host.menu_command(VRFW.commands.UPDATE_TEXT_PLATE, a1, a2, TEXT_BUILD) -- CMND_UPDATE_TEXT_PLATE
          end
        end
      end
    end
    return r
  end
  OnSetupLayer = W.OnSetupLayer
end
