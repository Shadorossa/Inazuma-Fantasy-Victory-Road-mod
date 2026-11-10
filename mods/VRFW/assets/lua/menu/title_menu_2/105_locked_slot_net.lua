-- locked slot net (VRFW): the mode row is the door to every game mode.
if VRFW.host ~= nil then
  local TITLE_MENU = 3874253475 --[[title_menu_2]]
  local co = nil

  local Log = VRFW.logger.new("save_slots")

  VRFW.host.on("title_menu_2", "OnInit", {
    id = "save_engine.locked_slot_net",
    phase = "after",
    fn = function()
      co = nil
      if VRFW.slots.available() and VRFW.slots.on_locked() then
        Log("ERROR the mode row opened on the locked slot: back to the EMPEZAR title")
        co = coroutine.create(function()
          VRFW.slots.to_title(TITLE_MENU, Log)
        end)
      end
    end,
  })

  VRFW.host.on("title_menu_2", "Step", {
    id = "save_engine.locked_slot_net_step",
    phase = "after",
    fn = function()
      if co == nil then
        return
      end
      local ok, err = coroutine.resume(co)
      if not ok then
        Log("locked slot net failed:", tostring(err))
        co = nil
      end
    end,
  })
end
