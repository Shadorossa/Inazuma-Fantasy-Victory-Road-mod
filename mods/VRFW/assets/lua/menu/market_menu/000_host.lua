if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      flag = {"OnChangeFocus", 9, 10, "boolean"},
      flag2 = {"OnChangeFocus", 10, 10, "boolean"},
      flag3 = {"OnChangeFocus", 6, 10, "boolean"},
      n = {"OnSetupLayer", 8, 8, "number"},
      n2 = {"OnDecideFocus", 1, 10, "number"},
      n3 = {"OnChangeFocus", 2, 10, "number"},
      n4 = {"OnChangeFocus", 3, 10, "number"},
      n5 = {"OnChangeFocus", 5, 10, "number"},
      n6 = {"OnOpenEndLayer", 2, 2, "number"},
      n7 = {"BackToTitle", 2, 2, "number"},
      n8 = {"UpdateTokenItem", 1, 3, "number"},
      t = {"IsCheckNoTokenShopIdx", 1, 2, "table"},
      t2 = {"OnDecideFocus", 3, 10, "table"},
      t3 = {"OnChangeFocus", 7, 10, "table"},
      t4 = {"OnSetupLayer", 7, 8, "table"},
      t5 = {"OnSetupLayer", 2, 8, "table"},
      t6 = {"OnSetupLayer", 4, 8, "table"},
      t7 = {"OnSetupLayer", 5, 8, "table"},
      t8 = {"OnSetupLayer", 6, 8, "table"},
    },
  })
end
