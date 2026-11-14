-- Inazuma Fantasy level orbs
InazumaFantasy = InazumaFantasy or {}
InazumaFantasy.LevelOrb = { levels = 0 }

function InazumaFantasy.LevelOrb.set_window_params(from, per_orb, cap)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_from@)
  funcLuaCommand(3860611758, @crc:InazumaFantasy.level_orb_from@, 0, from, 1)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_per_orb@)
  funcLuaCommand(3860611758, @crc:InazumaFantasy.level_orb_per_orb@, 0, per_orb, 1)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_cap@)
  funcLuaCommand(3860611758, @crc:InazumaFantasy.level_orb_cap@, 0, cap, 1)
end

function InazumaFantasy.LevelOrb.clear_window_params()
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_from@)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_per_orb@)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_cap@)
end

-- Previews one orb on the menu's gauge.
function InazumaFantasy.LevelOrb.preview_one_orb(chara)
  local level = funcLuaCommand(1131797651, chara, 0)
  local cap = funcLuaCommand(1131797651, chara, 29)
  local target = math.min(level + InazumaFantasy.LevelOrb.levels, cap)
  if target >= cap then
    return target, 0
  end
  return target, funcLuaMenuCommand(2018907327, chara, target)
end

-- Handles OnDecideFocus.
function InazumaFantasy.LevelOrb.open_amount_window()
  local level = funcLuaCommand(1131797651, n5, 0)
  local cap = funcLuaCommand(1131797651, n5, 29)
  local per_orb = InazumaFantasy.LevelOrb.levels
  local most = math.min(n8, math.ceil((cap - level) / per_orb))
  InazumaFantasy.LevelOrb.set_window_params(level, per_orb, cap)
  MENU_DEF.OpenNumWindow("InazumaFantasyLevelOrbAmountDone", "", 1, most, @crc:InazumaFantasy.level_orb_result@, 1, 1956876983 --[[num_shop_window]])
  funcLuaCommand(3694408893, l2, 0, n8, false)
end

-- Receives the amount window's answer.
function InazumaFantasyLevelOrbAmountDone(count)
  funcLuaCommand(320421347 --[[CMND_CLOSE_MENU_OBJECT]], 1956876983 --[[num_shop_window]])
  InazumaFantasy.LevelOrb.clear_window_params()
  if count == -1 then
    funcLuaMenuCommand(1558704558, 2384748956 --[[item_use_menu]], true)
    SetListItemCollisionEnable(true)
    return
  end
  funcLuaCommand(1917805374, 3848881948 --[[sy0000]])
  CloseLevelupPopup()
  n9 = n9 + count
  n8 = n8 - count
  SetupNumPrimitive(4016282723 --[[item02_04_chara_list_locator]], 0, 3334923667 --[[num_have01]], n8)
  local level = funcLuaCommand(1131797651, n5, 0)
  local cap = funcLuaCommand(1131797651, n5, 29)
  local target = math.min(level + count * InazumaFantasy.LevelOrb.levels, cap)
  local exp = -funcLuaCommand(1131797651, n5, 5)
  for walked = level, target - 1 do
    exp = exp + funcLuaMenuCommand(2018907327, n5, walked)
  end
  waitFalse(function()
    return funcLuaMenuCommand(2640875187 --[[CMND_IS_OPEN_LAYER]], 3263009971 --[[soccer22_06_level_up]], n)
  end)
  n11 = n
  funcLuaMenuCommand(629267548 --[[CMND_OPEN_LAYER]], 3263009971 --[[soccer22_06_level_up]], n)
  funcLuaMenuCommand(3781155141 --[[CMND_PLAY_ANIME_TYPE]], 2361088253 --[[item02_05_attach_gauge]], n, 1133833840 --[[up]], 0, 3059782130 --[[effect]])
  funcLuaMenuCommand(3781155141 --[[CMND_PLAY_ANIME_TYPE]], 2528819118 --[[item02_03_p1_gauge_effect]], n, 71445658 --[[Open]], 0)
  funcLuaCommand(3105653211, n5, exp)
  UpdateCharaPersonalPlate(n4)
  UpdateListItemGauge(2361088253 --[[item02_05_attach_gauge]], n, n5, true, CheckIsEnableUseItem())
  UpdateParentMenuHeaderTeamDock()
end
