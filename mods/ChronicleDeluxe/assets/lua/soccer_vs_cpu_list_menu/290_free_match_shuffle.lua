if VRFW.host ~= nil then
  local SHUFFLE = VRFW.commands.ChronicleDeluxe_FreeMatchShuffle
  local ITEM = VRFW.ids.crc32("mainmenu90_19_vs_cpu_list_item")

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
