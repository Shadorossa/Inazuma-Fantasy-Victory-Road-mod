-- Inazuma Fantasy level orbs: the item use menu's side (graft.toml). The amount window reads what it shows from three
-- menu params (num_shop_window_level_orbs.lua) set only while the window of an orb is open.
InazumaFantasyLevelOrb = { levels = 0 }

function InazumaFantasyLevelOrb.SetWindowParams(from, per_orb, cap)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_from@)
  funcLuaCommand(3860611758, @crc:InazumaFantasy.level_orb_from@, 0, from, 1)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_per_orb@)
  funcLuaCommand(3860611758, @crc:InazumaFantasy.level_orb_per_orb@, 0, per_orb, 1)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_cap@)
  funcLuaCommand(3860611758, @crc:InazumaFantasy.level_orb_cap@, 0, cap, 1)
end

function InazumaFantasyLevelOrb.ClearWindowParams()
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_from@)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_per_orb@)
  funcLuaCommand(3363400568, @crc:InazumaFantasy.level_orb_cap@)
end

-- the menu's gauge: one orb lands at the start of the target level
function InazumaFantasyLevelOrb.PreviewOneOrb(chara)
  local level = funcLuaCommand(1131797651, chara, 0)
  local cap = funcLuaCommand(1131797651, chara, 29)
  local target = math.min(level + InazumaFantasyLevelOrb.levels, cap)
  if target >= cap then
    return target, 0
  end
  return target, funcLuaMenuCommand(2018907327, chara, target)
end

-- OnDecideFocus: CheckIsEnableUseItem (OnEnter) already refused a player at his cap and an empty stock
function InazumaFantasyLevelOrb.OpenAmountWindow()
  local level = funcLuaCommand(1131797651, n5, 0)
  local cap = funcLuaCommand(1131797651, n5, 29)
  local per_orb = InazumaFantasyLevelOrb.levels
  local most = math.min(n8, math.ceil((cap - level) / per_orb))
  InazumaFantasyLevelOrb.SetWindowParams(level, per_orb, cap)
  MENU_DEF.OpenNumWindow("InazumaFantasyLevelOrbAmountDone", "", 1, most, @crc:InazumaFantasy.level_orb_result@, 1, 1956876983 --[[num_shop_window]])
  funcLuaCommand(3694408893, l2, 0, n8, false)
end

-- the amount window's answer: -1 = cancelled. The rest is OnDecideFocus's retail use with `count` orbs.
function InazumaFantasyLevelOrbAmountDone(count)
  funcLuaCommand(320421347 --[[CMND_CLOSE_MENU_OBJECT]], 1956876983 --[[num_shop_window]])
  InazumaFantasyLevelOrb.ClearWindowParams()
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
  local target = math.min(level + count * InazumaFantasyLevelOrb.levels, cap)
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
