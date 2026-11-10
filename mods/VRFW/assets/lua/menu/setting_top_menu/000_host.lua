if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      flag = {"OnOpenLayer", 2, 3, "boolean"},
      flag3 = {"Step", 1, 3, "boolean"},
      flag4 = {"OnInit", 2, 3, "boolean"},
      n = {"OnSetupLayer", 2, 3, "number"},
      n2 = {"OnSetupLayer", 3, 3, "number"},
      n3 = {"SelectListItem", 4, 4, "number"},
      n4 = {"OnOpenEndLayer", 3, 3, "number"},
      n5 = {"BackToTitle", 2, 2, "number"},
      t = {"OnInit", 3, 3, "table"},
      t2 = {"GetLitItemInfo", 2, 2, "table"},
      t3 = {"SetupListItemTexture", 1, 2, "table"},
    },
  })
end
