
-- ===== EVT board removal BEGIN (research/scripts/board_entry_build.py) =====
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.SKILL_SLOT_MENU = 2221030314
function OpenAbilityLearningBoard()
  local function p(key, v, num)
    VRFW.param.clear(key)
    if num then
      VRFW.param.set(key, v)
    else
      VRFW.param.set(key, v, "plain")
    end
  end
  p(2029825652, false)       -- flag5: no member list (single player)
  p(363718978, true)         -- flag6: field mode
  p(4145209998, 0, true)
  p(3308763177, false)
  p(2719720834, true)
  p(1038144478, n5, true)    -- the scout
  p(156152477, true)                -- read-only
  VRFW.footer_prompts.set(nil, 1026683731 --[[rpg_select_scout_chara_menu]], {},
    {guide = 1138543975 --[[mainmenu01_06_base_button_guide]], declared = false})
  SetVisibleLayerAll(false)
  funcLuaCommand(@crc:CMND_OPEN_MENU_OBJECT@, CharacterReforged.SKILL_SLOT_MENU)
  funcLuaMenuCommand(1558704558, 1026683731 --[[rpg_select_scout_chara_menu]], false)
  coroutine.yield()
  waitFalse(function()
    return funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, CharacterReforged.SKILL_SLOT_MENU)
  end)
  VRFW.param.clear(156152477)
  SetVisibleLayerAll(true)
  funcLuaMenuCommand(1558704558, 1026683731 --[[rpg_select_scout_chara_menu]], true)
  UpdateAppealEventCheck()
  ChangeViewMode(2, true)
end
-- ===== EVT board removal END =====
