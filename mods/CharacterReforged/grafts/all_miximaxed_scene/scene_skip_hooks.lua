do
  AllMiximaxed_SceneSkip = AllMiximaxed_SceneSkip or {}
  local Skip = AllMiximaxed_SceneSkip
  Skip.STATE = 1383320350
  Skip.LOG = 519897777                              -- CMND_VRFW_LOG
  Skip.INPUT = 4265778440                            -- CMND_CHECK_INPUT_CMD (group, command)
  Skip.GROUPS = {2917185202 --[[EVENT_CTRL_VISUAL]], 3237690481 --[[EVENT_CTRL_TALK]]}
  Skip.KEYS = {1981080283 --[[CMD_ENTER]], 2598206728 --[[CMD_EVENT_SKIP_HOLD]]}
  Skip.EVENT_SKIP = 2872569508                       -- CMND_EVENT_SKIP
  Skip.done = false

  function Skip.pressed()
    for _, group in ipairs(Skip.GROUPS) do
      for _, key in ipairs(Skip.KEYS) do
        local ok, v = pcall(funcLuaCommand, Skip.INPUT, group, key)
        if ok and v == true then
          return true
        end
      end
    end
    return false
  end

  if Skip.previous_step == nil and type(Step) == "function" then
    Skip.previous_step = Step
    function Step(...)
      if not Skip.done and type(funcLuaCommand) == "function" then
        local ok, pending = pcall(funcLuaCommand, Skip.STATE)
        if ok and pending == true and Skip.pressed() then
          Skip.done = true
          local okSkip, r = pcall(funcLuaMenuCommand, Skip.EVENT_SKIP)
          pcall(funcLuaCommand, Skip.LOG, "all_miximaxed scene", "A pressed: skip", tostring(okSkip), tostring(r))
        end
      end
      return Skip.previous_step(...)
    end
  end
end
