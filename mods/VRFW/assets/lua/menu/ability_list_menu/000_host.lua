-- VRFW.host: the HOST patch of ability_list_menu (common/script/lua/menu/ability_list_menu_5.00.29.00.lua.bin).
if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      flag = {"UpdateFilterData", 1, 5, "boolean"},
      n = {"OnInit", 1, 4, "number"},
      n2 = {"OnChangeFocus", 3, 3, "number"},
      n3 = {"UpdateSkillDetailWindow", 3, 3, "number"},
      n4 = {"OnBack", 1, 3, "number"},
      n5 = {"OnInit", 4, 4, "number"},
      t = {"OnSetupLayer", 2, 2, "table"},
      t2 = {"OpenSortSubWindow", 1, 3, "table"},
      t3 = {"OnInit", 3, 4, "table"},
      t4 = {"OnFunction", 4, 4, "table"},
      t5 = {"OnBack", 2, 3, "table"},
    },
  })
end
