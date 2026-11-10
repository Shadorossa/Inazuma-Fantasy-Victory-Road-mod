if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      l1 = {"OnInit", 1, 4},
      n2 = {"OnChangeFocus", 7, 8, "number"},
      n5 = {"OnChangeFocus", 6, 8, "number"},
      n6 = {"OnInit", 3, 4, "number"},
      n7 = {"OnInit", 4, 4, "number"},
      n8 = {"UpdateDifficult", 1, 4, "number"},
      n9 = {"OnChangeFocus", 2, 8, "number"},
      n10 = {"OnChangeFocus", 8, 8, "number"},
      n11 = {"UpdateFormation", 2, 6, "number"},
      n12 = {"UpdateFormation", 3, 6, "number"},
      n13 = {"UpdateFormation", 5, 6, "number"},
      t = {"UpdateFormation", 6, 6, "table"},
      t4 = {"OnChangeFocus", 3, 8, "table"},
      t5 = {"UpdateItem", 2, 2, "table"},
      -- not reachable from a global function: t2, t3, n, n3, n4
    },
  })
end
