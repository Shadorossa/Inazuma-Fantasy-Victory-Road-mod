-- Internal: list of extra buttons the mods menu adds for the changelog (fn, icon, cmd, key).


local CLM = {
  SESSION = VRFW.commands.VRFW_CHANGELOG_SESSION,
  OPEN = VRFW.commands.VRFW_CHANGELOG_OPEN,       -- (1 on demand, languageCode) -> pages
  CLOSE = VRFW.commands.VRFW_CHANGELOG_CLOSE,
  LANG = VRFW.commands.GET_LANGUAGE_CODE,                                -- CMND_GET_LANGUAGE_CODE
  SHEET = 3492314538,                              -- title_tutorial_menu
}

local CLM_Call = VRFW.host.command

--- Internal: list of extra buttons the mods menu adds for the changelog (fn, icon, cmd, key).
VRFW.mods_menu_changelog = VRFW.mods_menu_changelog or {}
VRFW.mods_menu_changelog[#VRFW.mods_menu_changelog + 1] = {
  fn = VRFW.ids.crc32("vrfw_mm_extra3"),
  icon = 3876168952,                  -- retail button guide icon of CMD_FUNC3
  cmd = VRFW.ids.crc32("CMD_FUNC3"),
  key = "changelog.news",             -- What's New (text.toml of the part, served by the text part)
  available = function()
    return CLM_Call(CLM.SESSION) ~= nil   -- the part answers
  end,
  flow = function(menu)
    local pages = CLM_Call(CLM.OPEN, 1, CLM_Call(CLM.LANG) or 1)
    if type(pages) ~= "number" or pages < 1 then
      return false
    end
    funcLuaMenuCommand(1558704558, menu, false)                                -- the screen's input off
    funcLuaCommand(VRFW.commands.OPEN_MENU_OBJECT, CLM.SHEET)                                      -- CMND_OPEN_MENU_OBJECT
    while funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, CLM.SHEET) do                        -- until the sheet is closed
      coroutine.yield()
    end
    CLM_Call(CLM.CLOSE)
    return true
  end,
}
