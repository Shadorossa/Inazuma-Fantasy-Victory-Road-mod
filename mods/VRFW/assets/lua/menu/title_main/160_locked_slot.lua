-- locked slot (VRFW): the locked slot (the vanilla save) is never played. Every title passes through TitleStart before it
-- opens a menu, so the rule sits there: VRFW_Slots.title_guard (lua\menu\_all\04_slots.lua). A title with the vanilla
-- save's avatar stays as it is: EMPEZAR opens the slot screen. No engine call at load time.
if VRFW_Host ~= nil then
  VRFW_Host.on("title_main", "TitleStart", {
    id = "save_engine.locked_slot_title",
    phase = "around",
    fn = function(nxt, ...)
      local ok, err = pcall(VRFW_Slots.title_guard)
      if not ok then
        pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "save_slots", "ERROR locked slot guard failed:", tostring(err))
      end
      return nxt(...)
    end,
  })
end
