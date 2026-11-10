

local CLT = {
  PENDING = VRFW.commands.VRFW_CHANGELOG_PENDING,   -- () -> the automatic sheet is due
  OPEN = VRFW.commands.VRFW_CHANGELOG_OPEN,         -- (0 auto, languageCode) -> pages
  CLOSE = VRFW.commands.VRFW_CHANGELOG_CLOSE,       -- () -> marks the versions seen
  LANG = VRFW.commands.GET_LANGUAGE_CODE,                                  -- CMND_GET_LANGUAGE_CODE
  TITLE = 3874253475,                                -- title_menu_2
  SHEET = 3492314538,                                -- title_tutorial_menu
  CURSOR = 24113234,                                 -- cmn05_01_coursor
}

local CLT_Call = VRFW.host.command

local function CLT_Pending()
  return CLT_Call(CLT.PENDING) == true
end

local function CLT_WaitWhile(f)
  while f() do
    coroutine.yield()
  end
end

-- the mods sheet, opened like retail UpdateTitleMenuFirstOpen (minus the welcome flag and the autosave)
local function CLT_Sheet()
  local pages = CLT_Call(CLT.OPEN, 0, CLT_Call(CLT.LANG) or 1)
  if type(pages) ~= "number" or pages < 1 then
    return
  end
  CLT_WaitWhile(function() return funcLuaMenuCommand(VRFW.commands.IS_OPEN_LAYER, CLT.CURSOR) == false end)   -- cursor open
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, CLT.CURSOR, 0, false)
  CLT_WaitWhile(function() return funcLuaCommand(667479479, CLT.TITLE) end)                 -- title loading
  funcLuaMenuCommand(1558704558, CLT.TITLE, false)                                          -- title input off
  funcLuaMenuCommand(1951894516, false)
  funcLuaCommand(VRFW.commands.OPEN_MENU_OBJECT, CLT.SHEET)                                                      -- CMND_OPEN_MENU_OBJECT
  CLT_WaitWhile(function() return funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, CLT.SHEET) end)             -- until it is closed
  CLT_Call(CLT.CLOSE)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, CLT.CURSOR, 0, true)
  funcLuaMenuCommand(1951894516, true)
end

-- handlers of the framework's title_menu_2 host (VRFW.host)
if VRFW.host ~= nil then
  local clt_retail_need = VRFW.host.original("title_menu_2", "IsNeedToDisplaySystemUpdateMess")
  local clt_has_need = type(IsNeedToDisplaySystemUpdateMess) == "function"

  VRFW.host.on("title_menu_2", "IsNeedToDisplaySystemUpdateMess", {
    id = "changelog.title_sheet", phase = "around",
    fn = function(nxt, ...)
      if nxt(...) == true then
        return true
      end
      return CLT_Pending()
    end,
  })

  VRFW.host.on("title_menu_2", "UpdateTitleMenuFirstOpen", {
    id = "changelog.title_sheet", phase = "around",
    fn = function(nxt, ...)
      if not clt_has_need or clt_retail_need() == true then
        nxt(...)
      end
      if CLT_Pending() then
        CLT_Sheet()
      end
    end,
  })
end
