if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      flag = {"OnInit", 3, 4, "boolean"},
      flag2 = {"OnInit", 4, 4, "boolean"},
      n = {"OnInit", 2, 4, "number"},
      n2 = {"OnChangeFocus", 2, 2, "number"},
      n3 = {"OnOpenLayer", 1, 2, "number"},
      n4 = {"SetupFilterGroupInfoArray", 4, 4, "number"},
      t = {"SetupFilterGroupInfoArray", 3, 4, "table"},
      t2 = {"UpdateItem", 1, 7, "table"},
      t3 = {"UpdateItem", 3, 7, "table"},
      t4 = {"UpdateItem", 4, 7, "table"},
      t5 = {"UpdateItem", 5, 7, "table"},
      t6 = {"UpdateItem", 6, 7, "table"},
      t7 = {"UpdateItem", 7, 7, "table"},
      t8 = {"UpdateButtonFocusAnim", 1, 2, "table"},
      t9 = {"SetDefaultFilterParams", 2, 2, "table"},
      t10 = {"SetupFilterGroupInfoArray", 1, 4, "table"},
    },
  })
end
