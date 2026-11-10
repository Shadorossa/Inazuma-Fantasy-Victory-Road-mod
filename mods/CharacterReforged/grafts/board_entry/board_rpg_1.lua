
-- ===== EVT board removal BEGIN (research/scripts/board_entry_build.py) =====
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.SKILL_SLOT_MENU = 2221030314
function CharacterReforged.skill_table_open_skill_slots_from_rpg_dock()
  local ret = funcLuaMenuCommand(2603265800, n23)
  local h = GetMaiMemberStCharaHdl(ret)
  if h == 0 then
    return -1
  end
  n2 = 1
  local function p(key, v, num)
    VRFW.param.clear(key)
    if num then
      VRFW.param.set(key, v)
    else
      VRFW.param.set(key, v, "plain")
    end
  end
  p(2029825652, true)        -- flag5: member list (L/R)
  p(363718978, true)
  p(4145209998, 0, true)     -- card type
  p(3308763177, true)
  p(2719720834, true)
  p(4081600465, 2, true)     -- dock type 2 = RPG field party
  p(1038144478, h, true)     -- the character
  p(622145442, ret, true)    -- selected index
  VRFW.param.clear(156152477)   -- never read-only here
  funcLuaMenuCommand(972795058, false)
  funcLuaCommand(@crc:CMND_OPEN_MENU_OBJECT@, CharacterReforged.SKILL_SLOT_MENU)
  funcLuaMenuCommand(1129326309, 1730641026 --[[team_dock_menu]])
  funcLuaMenuCommand(1558704558, 1730641026 --[[team_dock_menu]], false)
  funcLuaCommand(830228314, 2645952753 --[[main_menu]], "ChangeHeaderMode", 12)
  coroutine.yield()
  waitFalse(function()
    return funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, CharacterReforged.SKILL_SLOT_MENU)
  end)
  funcLuaMenuCommand(1453710531, 1730641026 --[[team_dock_menu]])
  ReturnCharacterInstant()
  ClosePersonalPlate()
  coroutine.yield()
  SetVisibleNotRequiredLayers(true)
  funcLuaMenuCommand(1558704558, 1730641026 --[[team_dock_menu]], true)
  funcLuaMenuCommand(1558704558, 2645952753 --[[main_menu]], true)
  funcLuaCommand(830228314, 2645952753 --[[main_menu]], "ChangeHeaderMode", 0)
  if VRFW.param.has(622145442) then
    n = VRFW.param.get(622145442)
    VRFW.param.clear(622145442)
  end
end
function ExecAbilityBoardMenu(a1, a2)
  return CharacterReforged.skill_table_open_skill_slots_from_rpg_dock()
end
-- ===== EVT board removal END =====
