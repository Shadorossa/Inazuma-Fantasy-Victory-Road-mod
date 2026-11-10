-- VRFW › Help screen: the Mods tab, shown like the game's own tabs (rows: the help_entry content type).
if VRFW.host ~= nil then
  local MODS_TAB = VRFW.commands.VRFW_HELP_MODS_TAB

  -- GetCategoryInfo(category, field): field 0 = the tab icon, 1 = the tab title text id.
  VRFW.host.wrap_once("GetCategoryInfo", "VRFW.help_mods_tab", function(next, category, field, ...)
    local mods_category, icon, title = funcLuaCommand(MODS_TAB)
    if mods_category ~= 0 and category == mods_category then
      if field == 0 then
        return icon
      elseif field == 1 then
        return title
      end
    end
    return next(category, field, ...)
  end)
end
