if VRFW.host ~= nil then
  local CH = {
    KEY_HUB = 3979190066,       -- crc32("vrfw_contact_hub"): parameter in, the set
    KEY_SET = 1128821923,
    KEY_PARENT = 2740862541,
    KEY_GAME = 3811836272,
    HUB = VRFW.commands.VRFW_CONTACT_HUB,           -- CMND_VRFW_CONTACT_HUB (set) -> { menu, title }
    FIND = VRFW.commands.VRFW_CONTACT_FIND,            -- CMND_VRFW_CONTACT_FIND (set, game) -> { map, zone }
    FILTER = VRFW.commands.VRFW_CONTACT_HUB_FILTER,
    ORB = 4088477286,
    YIELD_CALL = 830228314,     -- (menu, "global function", args...) in another menu's VM
    LIST = 1107559438,          -- team05_03_soccer_cpu_opponent_list
    ITEM = 1074924810,          -- mainmenu90_19_vs_cpu_list_item
    MENU = 1970579282,          -- soccer_vs_cpu_list_menu
    SCREEN = 1355292071,        -- vrfw_contact_map_menu
    CURSOR = 2296367164,        -- cmn05_01_cursor
    HEADER = 575058101, HEADER_TEXT = 1220590795,   -- mainmenu90_01_header, _text_sub_title02
    GUIDE = 3078308064, GUIDE_MESH = 378156699,      -- mainmenu90_05_content_guide_line01, _text_guide01
    BANNER = 1835074715,        -- mainmenu90_34_cpu_team_formation (the team banner)
    LEVEL_TEXT = 2841109264,    -- _chronicle_gtxt_lv01 (its "Nv.")
    LEVEL_NUMBER = 51927332,    -- the banner's level number primitive
    NUMBER_VISIBLE = 1233047821, -- (layer, index, primitive, visible)
    HELP = 415711628,
    EMPTY = 1404656913,
    OPEN = VRFW.commands.OPEN_MENU_OBJECT, EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT, ACTIVE = 1558704558, VISIBLE = 2171393651, HIDE = 369172623,
    SHOW = 66378409, SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING, TEXT_GET = VRFW.commands.TEXT_GET, FOCUS_DATA = 1666448199, SE = VRFW.commands.SND_PLAY_SE, SE_NG = 2086672038, MSG = 2289627655, MSG_WAIT = 2351835063,
    set = nil, title = "",
  }
  --- Internal: state of the contact hub screen.
  VRFW.contact_hub = CH

  local log = VRFW.logger.new("vrfw.ContactHub")

  local function text(id)
    local s = VRFW.host.command(CH.TEXT_GET, id)
    return (type(s) == "string") and s or ""
  end

  -- Internal: the header and the help line of the office (after every redraw of the list's own)
  function CH.dress()
    if CH.set == nil then
      return
    end
    if CH.title ~= "" then
      VRFW.host.menu_command(CH.SET_TEXT, CH.HEADER, CH.HEADER_TEXT, CH.title, 0)
    end
    VRFW.host.menu_command(CH.SET_TEXT, CH.GUIDE, CH.GUIDE_MESH, text(CH.HELP), 0)
  end

  --- Internal: opens the contact hub; no args.
  function CH.open()
    local okd, game = VRFW.host.menu_command(CH.FOCUS_DATA, 0)
    if not okd or type(game) ~= "number" or game == 0 then
      return
    end
    local found = VRFW.host.command(CH.FIND, CH.set, game)
    if type(found) ~= "table" then
      log("no team page for game", game)
      funcLuaCommand(CH.SE, CH.SE_NG)
      funcLuaCommand(CH.MSG, text(CH.EMPTY), 0, 0, 0, 0, 0, false)
      funcLuaCommand(CH.MSG_WAIT, 1, 0)        -- a notice: one button
      return
    end
    log("open", game, tostring(found.map), tostring(found.zone))
    for _, k in ipairs({CH.KEY_SET, CH.KEY_PARENT, CH.KEY_GAME}) do
      VRFW.param.clear(k)
    end
    VRFW.param.set(CH.KEY_SET, CH.set)
    VRFW.param.set(CH.KEY_PARENT, CH.MENU)
    VRFW.param.set(CH.KEY_GAME, game)
    funcLuaMenuCommand(CH.ACTIVE, CH.MENU, false)
    funcLuaMenuCommand(CH.VISIBLE, CH.CURSOR, false)
    local okp, parent = pcall(function() return MENU_DEF.GetParentMenuID(CH.MENU) end)
    --- Internal: parent menu id of the contact hub, or nil.
    CH.parent = (okp and type(parent) == "number" and parent ~= 0) and parent or nil
    if vrfw_hub_yield ~= nil then
      pcall(vrfw_hub_yield, true, CH.SCREEN)
    end
    if CH.parent ~= nil then
      VRFW.host.command(CH.YIELD_CALL, CH.parent, "vrfw_hub_yield", true, CH.SCREEN)
    end
    funcLuaMenuCommand(CH.HIDE, CH.MENU)
    funcLuaCommand(CH.OPEN, CH.SCREEN)
    coroutine.yield()
    while funcLuaMenuCommand(CH.EXISTS, CH.SCREEN) do
      coroutine.yield()
    end
    funcLuaMenuCommand(CH.SHOW, CH.MENU)
    if vrfw_hub_yield ~= nil then
      pcall(vrfw_hub_yield, false, CH.SCREEN)
    end
    if CH.parent ~= nil then
      VRFW.host.command(CH.YIELD_CALL, CH.parent, "vrfw_hub_yield", false, CH.SCREEN)
    end
    if type(UpdateButtonGuideFromTopMenu) == "function" then
      pcall(UpdateButtonGuideFromTopMenu, 11)
    end
    CH.dress()
    funcLuaMenuCommand(CH.ACTIVE, CH.MENU, true)
    funcLuaMenuCommand(CH.VISIBLE, CH.CURSOR, true)
  end

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnInit", {
    id = "menu_engine.contact_hub", phase = "before",
    fn = function()
      CH.set, CH.title = nil, ""
      if VRFW.param.has(CH.KEY_HUB) then
        CH.set = VRFW.param.get(CH.KEY_HUB)
        VRFW.param.clear(CH.KEY_HUB)
        if type(CH.set) ~= "number" or CH.set == 0 then
          CH.set = nil
        end
      end
      if VRFW.free_match ~= nil and VRFW.free_match.bypass ~= nil then   -- the free-match rules stand aside in the hub
        pcall(VRFW.free_match.bypass, "VRFW.contact_hub", CH.set ~= nil)
      end
      VRFW.host.command(CH.FILTER, CH.set or 0)
      if CH.set ~= nil then
        local hub = VRFW.host.command(CH.HUB, CH.set)
        if type(hub) == "table" and hub.title then
          CH.title = text(hub.title)
        end
        log("on", CH.set, CH.title)
      end
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnInit", {
    id = "menu_engine.contact_hub.dress", phase = "after",
    fn = function() CH.dress() end,
  })

  -- the list's own team check (a valid team dock for a match) does not apply: nothing is played here
  VRFW.host.on("soccer_vs_cpu_list_menu", "OnEnter", {
    id = "menu_engine.contact_hub", phase = "around", priority = -300,
    fn = function(nxt, a1, ...)
      if CH.set ~= nil and a1 == CH.LIST then
        return nil
      end
      return nxt(a1, ...)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnDecideFocus", {
    id = "menu_engine.contact_hub", phase = "around", priority = -300,
    fn = function(nxt, a1, ...)
      if CH.set ~= nil and a1 == CH.LIST then
        CH.open()
        return nil
      end
      return nxt(a1, ...)
    end,
  })

  -- no difficulty / clear capsule on a row of the hub (nothing is played here)
  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateItem", {
    id = "menu_engine.contact_hub", phase = "after", priority = 300,
    fn = function(r, a1, a2)
      if CH.set ~= nil and type(a2) == "number" then
        VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, CH.ORB, a2, false)
      end
    end,
  })

  -- no team level on the hub's team banner: the retail "Lv." mesh and its number primitive off after each fill
  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateFormation", {
    id = "menu_engine.contact_hub.no_level", phase = "after", priority = 300,
    fn = function()
      if CH.set ~= nil then
        VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, CH.BANNER, CH.LEVEL_TEXT, false, 0)
        VRFW.host.menu_command(CH.NUMBER_VISIBLE, CH.BANNER, 0, CH.LEVEL_NUMBER, false)
      end
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", {
    id = "menu_engine.contact_hub", phase = "after", priority = 300,
    fn = function(r, a1)
      if CH.set ~= nil and a1 == CH.ITEM then
        CH.dress()
      end
    end,
  })
end
