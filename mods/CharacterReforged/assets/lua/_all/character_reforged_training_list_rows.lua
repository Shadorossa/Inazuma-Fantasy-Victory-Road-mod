-- Hides the bean rows (equip, remove, auto-equip) of the team "COMMANDS" window through the framework's list rows.
local function hide_bean_rows(Rows)
  Rows.hide(Rows.TEAM_COMMANDS, { id = "CharacterReforged.beans_equip", row = Rows.TEAM_COMMAND.EQUIP_BEANS })
  Rows.hide(Rows.TEAM_COMMANDS, { id = "CharacterReforged.beans_remove", row = Rows.TEAM_COMMAND.REMOVE_BEANS })
  Rows.hide(Rows.TEAM_COMMANDS, { id = "CharacterReforged.beans_auto_equip", row = Rows.TEAM_COMMAND.AUTO_EQUIP_BEANS })
end

if VRFW.list_rows ~= nil and VRFW.list_rows.hide ~= nil then
  hide_bean_rows(VRFW.list_rows)
else
  VRFW.list_rows_queue = VRFW.list_rows_queue or {}
  table.insert(VRFW.list_rows_queue, hide_bean_rows)
end
