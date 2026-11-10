-- VRFW story_start, title_menu_2 side.
if VRFW.host ~= nil then
  VRFW.host.on("title_menu_2", "OnInit", {
    id = "save_engine.story_start",
    phase = "before",
    priority = -900,
    fn = function()
      if (VRFW.story_start ~= nil and type(VRFW.story_start.on_title) == "function") then
        VRFW.story_start.on_title()
      end
    end,
  })
else
  local init = OnInit
  function OnInit(...)
    if (VRFW.save_slots ~= nil and type(VRFW.save_slots.commit_pending) == "function") then
      pcall(VRFW.save_slots.commit_pending)
    end
    if (VRFW.story_start ~= nil and type(VRFW.story_start.on_title) == "function") then
      pcall(VRFW.story_start.on_title)
    end
    return init(...)
  end
end
