-- VRFW story_provider
function VRFW.story_provider()
  local _, _, cleared = VRFW.host.command(@crc:CMND_VRFW_STORY_START_GET@)
  if cleared == nil then
    return nil
  end
  return cleared == true or cleared == 1
end
