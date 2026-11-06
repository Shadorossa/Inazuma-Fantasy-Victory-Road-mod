-- VRFW_Host: the HOST patch of post_menu (common/script/lua/menu/post_menu.lua.bin). The locals map is empty (no
-- handler reads L); `research/scripts/menu_assemble.py locals post_menu.lua.bin --write <lua root>` writes it.
-- Its place in the patch chain is where the dispatchers go: every global function of the script that a mod hooks
-- (VRFW_Host.on) is replaced here, on top of what the patches before it (lua_early roots, earlier roots) made of it.
-- The stem is this file's folder; the hook points come from the handlers; the map below is the retail main-chunk
-- locals (VRFW_Host.hosts.post_menu.L). No engine call at load time.
if VRFW_Host ~= nil then
  VRFW_Host.host({
    locals = {   -- menu_assemble.py locals post_menu: local = {retail global, upvalue index, its upvalue count, type}
    },
  })
end
