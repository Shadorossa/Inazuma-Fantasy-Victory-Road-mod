-- VRFW.host: the HOST patch of title_tutorial_menu (common/script/lua/menu/title_tutorial_menu_3.00.26.00.lua.bin).
if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      l1 = {"OnSetupLayer", 2, 3},
      l2 = {"OnSetupLayer", 3, 3},
      n = {"OnDecideFocus", 1, 5, "number"},
      n2 = {"OnOpenLayer", 4, 4, "number"},
      n3 = {"OnInit", 2, 2, "number"},
      n4 = {"OnDecideFocus", 4, 5, "number"},
      n5 = {"OnDecideFocus", 5, 5, "number"},
      t = {"OnOpenLayer", 3, 4, "table"},
      t2 = {"SetupUpdateNoticeInfo", 3, 6, "table"},
    },
  })
end
