local SLOT_ACTIVE = 4245285902       -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
local SLOT_RESERVED = 1380583127
local OPTION_GET = 4082322029        -- CMND_VRFW_OPTION_GET (row key) -> the value in force
local REMOVE_GACHA_ROW = "ClassicRecruitment.remove_gacha"
local REMOVE_GACHA_DEFAULT = 1       -- options.toml default
local CLASSIC_RECRUITMENT_ROW = "ClassicRecruitment.classic_recruitment"

-- the rule of ClassicRecruitment.gacha_removed (assets\lua\_all\classic_recruitment_lib.lua), for a VM without it
local function gacha_removed()
  if type(ClassicRecruitment) == "table" and type(ClassicRecruitment.gacha_removed) == "function" then
    return (select(2, pcall(ClassicRecruitment.gacha_removed))) == true
  end
  local ok_on, on = pcall(funcLuaCommand, OPTION_GET, CLASSIC_RECRUITMENT_ROW)
  if ok_on and on == 0 then
    return false
  end
  local ok_active, active = pcall(funcLuaCommand, SLOT_ACTIVE)
  if ok_active and type(active) == "number" and active > 0 then
    local ok_reserved, reserved = pcall(funcLuaCommand, SLOT_RESERVED, active)
    if ok_reserved and reserved == true then
      return false
    end
  end
  local ok, value = pcall(funcLuaCommand, OPTION_GET, REMOVE_GACHA_ROW)
  return (ok and type(value) == "number" and value or REMOVE_GACHA_DEFAULT) ~= 0
end

function RunCmd_Map1()
  RunVsRouteTownMenu()
end
function RunCmd_Map2()
  if gacha_removed() then
    return
  end
  RunPlayersUniverseMenu()
end
function RunCmd_Map3()
  funcLuaCommand(3625806653, 3549406257, 0, 0, 1)
end
function RunCmd_Map4()
  funcLuaCommand(3625806653, 1907350810, 0, 0, 1)
end
