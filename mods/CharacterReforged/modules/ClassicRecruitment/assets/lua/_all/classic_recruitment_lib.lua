ClassicRecruitment = type(ClassicRecruitment) == "table" and ClassicRecruitment or {}

if ClassicRecruitment.applies == nil then
  local SLOT_ACTIVE = 4245285902       -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
  local SLOT_RESERVED = 1380583127
  local OPTION_GET = 4082322029        -- CMND_VRFW_OPTION_GET (row key) -> the value in force
  local REMOVE_GACHA_ROW = "ClassicRecruitment.remove_gacha"
  local REMOVE_GACHA_DEFAULT = 1       -- options.toml default

  function ClassicRecruitment.applies()
    if type(funcLuaCommand) ~= "function" then
      return true
    end
    local active = VRFW.host.command(SLOT_ACTIVE)
    if type(active) ~= "number" or active <= 0 then
      return true
    end
    local reserved = VRFW.host.command(SLOT_RESERVED, active)
    return reserved ~= true
  end

  -- The module applies and the option row remove_gacha is on.
  function ClassicRecruitment.gacha_removed()
    if not ClassicRecruitment.applies() then
      return false
    end
    local value = VRFW.host.command(OPTION_GET, REMOVE_GACHA_ROW)
    return (type(value) == "number" and value or REMOVE_GACHA_DEFAULT) ~= 0
  end

  function ClassicRecruitment.holds(rule)
    local ok, yes = pcall(rule)
    return ok and yes == true
  end
end
