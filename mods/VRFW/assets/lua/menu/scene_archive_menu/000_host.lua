if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      flag = {"UpdateListItem", 3, 5, "boolean"},
      flag2 = {"OnBack", 3, 3, "boolean"},
      flag3 = {"OnInit", 2, 3, "boolean"},
      flag4 = {"OnInit", 3, 3, "boolean"},
      l1 = {"Step", 3, 3},
      l2 = {"OnOpenLayer", 4, 4},
      n = {"OnEnter", 4, 6, "number"},
      n2 = {"UpdateListItem", 4, 5, "number"},
      n3 = {"UpdateListItem", 5, 5, "number"},
      n4 = {"OnOpenLayer", 2, 4, "number"},
      n5 = {"OnEnter", 3, 6, "number"},
      n6 = {"OnEnter", 5, 6, "number"},
      n7 = {"UpdateTabCategoryName", 2, 4, "number"},
      n8 = {"PlayMovieCoroutine", 5, 6, "number"},
      n9 = {"OnEnter", 2, 6, "number"},
      t = {"GetTabInfo", 1, 1, "table"},
    },
  })
end
