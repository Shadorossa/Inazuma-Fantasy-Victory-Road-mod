if VRFW.host ~= nil then
  VRFW.host.host({
    locals = {
      flag = {"OnOpenEndLayer", 1, 1, "boolean"},
      l1 = {"Step", 1, 2},
      n = {"OnSetupLayer", 1, 5, "number"},
      n2 = {"OnOpenLayer", 2, 3, "number"},
      n3 = {"OnOpenLayer", 3, 3, "number"},
      n4 = {"UpdateSelectedBannerDataId", 1, 1, "number"},
      n5 = {"ChangeFocusNoticeBannerEnabled", 2, 2, "number"},
      t = {"OnSetupLayer", 2, 5, "table"},
      t2 = {"OnSetupLayer", 4, 5, "table"},
      t3 = {"OnChangeFocus", 3, 3, "table"},
      t4 = {"OnSetupLayer", 5, 5, "table"},
      t5 = {"UpdateListItem", 2, 3, "table"},
      t6 = {"UpdateListItem", 3, 3, "table"},
    },
  })
end
