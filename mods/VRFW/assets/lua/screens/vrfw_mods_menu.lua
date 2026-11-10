-- vrfw_mods_menu: the script of the "Mods" screen (mod mods_menu, VRFW).
INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_SAVEDATA_MANAGEMENT_MENU_INC")

-- fingerprint of this script for the ModLoader's Lua patch runner (lua\_fingerprints.json)
function vrfw_mods_menu_stub()
  return 1
end

function OnInit()
end

function Step()
  funcLuaMenuCommand(1558704558, 4051526990 --[[crc32("vrfw_mods_menu")]], false)
  funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, 4051526990)
end
