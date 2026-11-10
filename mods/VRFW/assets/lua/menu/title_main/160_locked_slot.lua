-- locked slot (VRFW): the locked slot (the vanilla save) is never played.
if VRFW.host ~= nil then
  VRFW.host.on("title_main", "TitleStart", {
    id = "save_engine.locked_slot_title",
    phase = "around",
    fn = function(nxt, ...)
      local ok, err = pcall(VRFW.slots.title_guard)
      if not ok then
        VRFW.logger.new("save_slots")("ERROR locked slot guard failed:", tostring(err))
      end
      return nxt(...)
    end,
  })
end
