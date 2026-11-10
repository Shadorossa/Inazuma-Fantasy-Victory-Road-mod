
local SA = {
  TABS = VRFW.commands.VRFW_SCENE_ARCHIVE_TABS,         -- CMND_VRFW_SCENE_ARCHIVE_TABS () -> tabs the engine has
  SECTION = VRFW.commands.VRFW_SCENE_ARCHIVE_SECTION,
  ROW_GET = 4199163761,      -- scene archive row field getter (row index, field)
  MOVIE_INFO = VRFW.commands.GET_MOVIE_INFO,     -- CMND_GET_MOVIE_INFO (movie id)
  LANG_CODE = VRFW.commands.GET_LANGUAGE_CODE,     -- CMND_GET_LANGUAGE_CODE: nie.exe language table index
  LIST_LAYER = 1887158505,   -- the list layer (attaches one tab button per tab)
  RETAIL = 3,
  LG = {[0] = "ja", [1] = "en", [2] = "fr", [3] = "es", [4] = "pt", [6] = "de", [7] = "it", [16] = "zh_hant",
    [17] = "zh_hans"},
  tabs = nil,
  logs = 0,
}

local capped_logger = VRFW.logger.new("VRFW scene_archive")
local function SA_Log(...)
  if SA.logs >= 20 then
    return
  end
  SA.logs = SA.logs + 1
  capped_logger(...)
end

local function SA_Tabs()
  if SA.tabs ~= nil then
    return SA.tabs
  end
  SA.tabs = {}
  local n = VRFW.host.command(SA.TABS)
  if type(n) ~= "number" then
    return SA.tabs
  end
  for i = 1, n - SA.RETAIL do
    local cat, text, icon = VRFW.host.command(SA.SECTION, i)
    if type(cat) == "number" then
      SA.tabs[#SA.tabs + 1] = {cat = cat, text = text, icon = icon or 10}
    else
      break
    end
  end
  SA_Log("tabs", n, #SA.tabs)
  return SA.tabs
end


-- the movie id to play for archive row `row` whose event crc is `ev`
local function SA_Variant(cmd, row, ev)
  local okn, name = pcall(cmd, SA.ROW_GET, row, 7)
  local okl, code = pcall(cmd, SA.LANG_CODE)
  local lg = okl and SA.LG[code] or nil
  if not okn or type(name) ~= "string" or name == "" or lg == nil then
    return ev
  end
  local id = VRFW.ids.crc32(name .. "_" .. lg)
  if id ~= nil then
    local ok, info = pcall(cmd, SA.MOVIE_INFO, id)
    if ok and info ~= nil and info ~= false then
      SA_Log("play", name, lg)
      return id
    end
  end
  return ev
end

if VRFW.host ~= nil then
  VRFW.host.on("scene_archive_menu", "GetTabInfo", {
    id = "menu_engine.scene_archive_sections", phase = "around",
    fn = function(nxt, a1, ...)
      local r = nxt(a1, ...)
      if r ~= nil or type(a1) ~= "number" or a1 < SA.RETAIL then
        return r
      end
      local base = nxt(1)   -- the retail Competition tab: its focus icons
      for _, t in ipairs(SA_Tabs()) do
        if t.cat == a1 and base ~= nil then
          return {slotCategory = a1, tabTextId = t.text, tabIconType = t.icon,
            iconFocusOn = base.iconFocusOn, iconFocusOff = base.iconFocusOff}
        end
      end
      return r
    end,
  })

  VRFW.host.on("scene_archive_menu", "OnSetupLayer", {
    id = "menu_engine.scene_archive_sections", phase = "around",
    fn = function(nxt, a0, ...)
      local n = a0 == SA.LIST_LAYER and #SA_Tabs() or 0
      if n == 0 or LISTVIEW == nil or LISTVIEW.UpdateAttachTabNum == nil then
        return nxt(a0, ...)
      end
      local orig = LISTVIEW.UpdateAttachTabNum
      LISTVIEW.UpdateAttachTabNum = function(k, ...)
        if k == SA.RETAIL then
          k = SA.RETAIL + n
        end
        return orig(k, ...)
      end
      local r = table.pack(pcall(nxt, a0, ...))
      LISTVIEW.UpdateAttachTabNum = orig
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  VRFW.host.on("scene_archive_menu", "PlayMovieCoroutine", {
    id = "menu_engine.scene_archive_variants", phase = "around",
    fn = function(nxt, ...)
      local cmd = funcLuaCommand
      funcLuaCommand = function(...)
        local id, a, b = ...
        if id == SA.ROW_GET and b == 6 then
          funcLuaCommand = cmd
          local ev = cmd(...)
          if ev == nil then
            return ev
          end
          return SA_Variant(cmd, a, ev)
        end
        return cmd(...)
      end
      return nxt(...)
    end,
  })
end
