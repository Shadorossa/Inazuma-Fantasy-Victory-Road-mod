
-- ===== EVT board removal BEGIN (research/scripts/board_entry_build.py) =====
-- RPG-battle team dock (story field): "Tabla de habilidades" opens the Supertécnicas screen (evt_skill_slot_menu,
-- a clone of equip_menu_select) with the parameters retail ExecEquipMenu gives equip_menu (dock type 2 = the field
-- party, L/R through the party); the return path is ExecEquipMenu's.
EVT_SKILL_SLOT_MENU = 1041963128
-- The skill table is Character Reforged's and always replaces the game's ability board.
function EVT_OpenSkillSlotsFromRpgDock()
  local ret = funcLuaMenuCommand(2603265800, n23)
  local h = GetMaiMemberStCharaHdl(ret)
  if h == 0 then
    return -1
  end
  n2 = 1
  local function p(key, v, num)
    VRFW_Param.Clear(key)
    if num then
      VRFW_Param.Set(key, v)
    else
      VRFW_Param.Set(key, v, "plain")
    end
  end
  p(2029825652, true)        -- flag5: member list (L/R)
  p(363718978, true)         -- flag6: field / main-menu mode
  p(4145209998, 0, true)     -- card type
  p(3308763177, true)
  p(2719720834, true)
  p(4081600465, 2, true)     -- dock type 2 = RPG field party
  p(1038144478, h, true)     -- the character
  p(622145442, ret, true)    -- selected index
  VRFW_Param.Clear(239878988)   -- never read-only here
  funcLuaMenuCommand(972795058, false)
  funcLuaCommand(@crc:CMND_OPEN_MENU_OBJECT@, EVT_SKILL_SLOT_MENU)
  funcLuaMenuCommand(1129326309, 1730641026 --[[team_dock_menu]])
  funcLuaMenuCommand(1558704558, 1730641026 --[[team_dock_menu]], false)
  funcLuaCommand(830228314, 2645952753 --[[main_menu]], "ChangeHeaderMode", 12)
  coroutine.yield()
  waitFalse(function()
    return funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, EVT_SKILL_SLOT_MENU)
  end)
  funcLuaMenuCommand(1453710531, 1730641026 --[[team_dock_menu]])
  ReturnCharacterInstant()
  ClosePersonalPlate()
  coroutine.yield()
  SetVisibleNotRequiredLayers(true)
  funcLuaMenuCommand(1558704558, 1730641026 --[[team_dock_menu]], true)
  funcLuaMenuCommand(1558704558, 2645952753 --[[main_menu]], true)
  funcLuaCommand(830228314, 2645952753 --[[main_menu]], "ChangeHeaderMode", 0)
  if VRFW_Param.Has(622145442) then
    n = VRFW_Param.Get(622145442)
    VRFW_Param.Clear(622145442)
  end
end
function ExecAbilityBoardMenu(a1, a2)
  return EVT_OpenSkillSlotsFromRpgDock()
end
-- ===== EVT board removal END =====
