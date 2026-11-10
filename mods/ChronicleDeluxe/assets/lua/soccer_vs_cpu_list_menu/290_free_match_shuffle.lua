if VRFW.host ~= nil then
  local SHUFFLE = 4142888348
  local ITEM = 1074924810           -- mainmenu90_19_vs_cpu_list_item

  local function deal()
    pcall(funcLuaCommand, SHUFFLE)
  end

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnInit", {
    id = "ChronicleDeluxe.FreeMatchShuffle", phase = "before",
    fn = function()
      deal()
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", {
    id = "ChronicleDeluxe.FreeMatchShuffle", phase = "before",
    fn = function(a1)
      if a1 == ITEM then
        deal()
      end
    end,
  })
end
