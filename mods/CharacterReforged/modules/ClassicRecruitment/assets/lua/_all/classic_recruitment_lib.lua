ClassicRecruitment = type(ClassicRecruitment) == "table" and ClassicRecruitment or {}

if ClassicRecruitment.applies == nil then
  local SLOT_ACTIVE = 4245285902       -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
  local SLOT_RESERVED = 1380583127
  local OPTION_GET = 4082322029        -- CMND_VRFW_OPTION_GET (row key) -> the value in force
  local PLAYERS_UNIVERSE_ROW = "ClassicRecruitment.players_universe"
  local PLAYERS_UNIVERSE_DEFAULT = 0   -- options.toml default
  local SPIRIT_SECTION_ROW = "ClassicRecruitment.spirit_section"
  local SPIRIT_SECTION_DEFAULT = 1     -- options.toml default
  local CLASSIC_RECRUITMENT_ROW = "ClassicRecruitment.classic_recruitment"
  local CLASSIC_RECRUITMENT_DEFAULT = 1  -- options.toml default

  function ClassicRecruitment.applies()
    if type(funcLuaCommand) ~= "function" then
      return true
    end
    -- The row is restart = true: the answer is the value the game started with, as for the gated files.
    local on = VRFW.host.command(OPTION_GET, CLASSIC_RECRUITMENT_ROW)
    if (type(on) == "number" and on or CLASSIC_RECRUITMENT_DEFAULT) == 0 then
      return false
    end
    local active = VRFW.host.command(SLOT_ACTIVE)
    if type(active) ~= "number" or active <= 0 then
      return true
    end
    local reserved = VRFW.host.command(SLOT_RESERVED, active)
    return reserved ~= true
  end

  -- The module applies and the option row players_universe is off.
  function ClassicRecruitment.gacha_removed()
    if not ClassicRecruitment.applies() then
      return false
    end
    local value = VRFW.host.command(OPTION_GET, PLAYERS_UNIVERSE_ROW)
    return (type(value) == "number" and value or PLAYERS_UNIVERSE_DEFAULT) == 0
  end

  -- The module applies and the option row spirit_section is off: every place that shows spirits stays hidden and duplicate players are off (restart row, the start value).
  function ClassicRecruitment.spirits_hidden()
    if not ClassicRecruitment.applies() then
      return false
    end
    local value = VRFW.host.command(OPTION_GET, SPIRIT_SECTION_ROW)
    return (type(value) == "number" and value or SPIRIT_SECTION_DEFAULT) == 0
  end

  function ClassicRecruitment.holds(rule)
    local ok, yes = pcall(rule)
    return ok and yes == true
  end
end
