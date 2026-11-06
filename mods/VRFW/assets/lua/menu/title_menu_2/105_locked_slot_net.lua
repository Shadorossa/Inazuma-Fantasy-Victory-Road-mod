-- locked slot net (VRFW): the mode row is the door to every game mode. It opening on the locked slot is a bug the title
-- guard (title_main\160_locked_slot.lua) should have prevented: the game goes back to the EMPEZAR title at once, so the
-- player picks a slot before playing. Handlers of the framework's title_menu_2 host. No engine call at load time.
if VRFW_Host ~= nil then
  local TITLE_MENU = 3874253475 --[[title_menu_2]]
  local co = nil

  local function Log(...)
    pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "save_slots", ...)
  end

  VRFW_Host.on("title_menu_2", "OnInit", {
    id = "save_engine.locked_slot_net",
    phase = "after",
    fn = function()
      co = nil
      if VRFW_Slots.available() and VRFW_Slots.on_locked() then
        Log("ERROR the mode row opened on the locked slot: back to the EMPEZAR title")
        co = coroutine.create(function()
          VRFW_Slots.to_title(TITLE_MENU, Log)
        end)
      end
    end,
  })

  VRFW_Host.on("title_menu_2", "Step", {
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
