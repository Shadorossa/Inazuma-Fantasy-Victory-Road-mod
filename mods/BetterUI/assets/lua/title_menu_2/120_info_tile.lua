if VRFW.host ~= nil then
  local Tile = {
    log = VRFW.logger.new("BetterUI info_tile"),
    STATE = VRFW.ids.crc32("CMND_VRFW_MM_STATE"),
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    NEW_ICON = 1538377437,            -- cmn01_13_new_icon_middle
    INFO_ITEM = 8,
    INFO_INSTANCE = 2,                -- its lower instance, where the retail code opens the "!"
    SAVE_POSITION = 2,
    removed = false,
  }

  local function Served()
    local title, _, _, _, _, _, _, _, _, pos = VRFW.host.command(Tile.STATE)
    return title == 1 and pos == Tile.SAVE_POSITION
  end

  VRFW.host.on("title_menu_2", "@edit", {
    id = "BetterUI.info_tile",
    fn = function(L)
      local t4 = L.t4
      if type(t4) ~= "table" or not Served() then
        Tile.log("lower row kept as served (no Guardar on the freed place or no VRFW.debug)")
        return
      end
      for i = #t4, 1, -1 do
        if t4[i] == Tile.INFO_ITEM then
          table.remove(t4, i)
          Tile.removed = true
        end
      end
      Tile.log("Información out of the lower row,", #t4, "retail tiles left")
    end,
  })

  VRFW.host.on("title_menu_2", "OnOpenLayer", {
    id = "BetterUI.info_tile.new_icon",
    phase = "after",
    fn = function(r, a1, a2)
      if Tile.removed and a1 == Tile.NEW_ICON and a2 == Tile.INFO_INSTANCE then
        VRFW.host.menu_command(Tile.VISIBLE, a1, a2, false)
      end
    end,
  })
end
