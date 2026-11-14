if VRFW.story == nil then
  local DATA_COMMAND = VRFW.commands.VRFW_STORY_START_DATA
  local cached = nil

  local S = {}

  --- Advanced: The story data (read once); nil when it cannot be read.
  function S.data()
    if cached ~= nil then
      return cached
    end
    local f = _ENV.funcLuaCommand
    if type(f) ~= "function" then
      return nil
    end
    local ok, d = pcall(f, DATA_COMMAND)
    if ok and type(d) == "table" and type(d.BITS) == "table" and #d.BITS > 0 then
      cached = d
    end
    return cached
  end

  --- Advanced: The complete-story flags: on, off; nil when there are none.
  function S.complete_flags()
    local d = S.data()
    if d == nil then
      return nil
    end
    local on, off = {}, {}
    for i, v in ipairs(d.BITS) do
      on[i] = v
    end
    for i, v in ipairs(d.BITS_OFF or {}) do
      off[i] = v
    end
    return on, off
  end

  --- Advanced: Namespace: the story state helpers of the menu VM.
  VRFW.story = S
end
