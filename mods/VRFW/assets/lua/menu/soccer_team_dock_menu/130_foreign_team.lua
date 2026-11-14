-- menu_engine: The dock shows a team that is not one of the player's (a league team, a tournament team).
if VRFW.host ~= nil then
  local STEM = "soccer_team_dock_menu"
  local K = {
    LIST = 3367997069,               -- team01_02_list_item
    CARDS = 1973487846,              -- team00_01_chara_card_for_soccer (the team's players)
    FORMATION_BOX = 3286546665,      -- team00_12_formation_style
    ATTACH_FORMATION = 2141963976,   -- team01_03_attach_formation
    DOCK = 937147172,                -- soccer_team_dock_menu
    DOCK_NUMBER = 1308042914,        -- team01_05_team_dock_no
    ACTIVE_MARK = 8591637,           -- team01_06_team_dock_active_team_mark
    BANK_COUNT = 3925006528,
    CHANGE_GUIDE = 255314328,
    KEEP_ROWS = { [0] = true },      -- when the caller offers none
    BLOCKED_FUNCTIONS = { [2294853123] = true, [4219711668] = true, [3620553157] = true, [2237843578] = true },
    BLOCKED_INPUTS = { [3966226594] = true, [942075773] = true, [3421673595] = true, [3147328756] = true },
    PAGE_INPUT = 3421673595,
    PAGE_TEXT = "vrfw_team_editor_player_page",
    MENU_INPUT = 1558704558,         -- (menu, on)
    CONTROL_FOCUS = VRFW.commands.SET_ENABLE_CTRL_FOCUS,      -- (layer, on)
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,             -- CMND_SET_LAYER_VISIBLE (layer, index, on)
    SOUND = VRFW.commands.SND_PLAY_SE, SE_NO = 2086672038,   -- sy0003
    NEXT_DOCK = 2294853123,          -- OnFunction: L1 / R1 (a2 = left / right)
    LEFT = 2053629800,               -- its a2 for L1
    PAGE_INPUTS = { [3966226594] = true, [942075773] = true },   -- CMD_FUNCL1 / CMD_FUNCR1: kept in the team page mode
    -- the team page's layout
    HEADER_LAYERS = { 1044086265, 1922851874, 3926241346, 2781487712, 2280287248 },   -- team01_04_team_name_bar, its
                                     -- team name and player plates (p1 / p2 frames), the user name and title
    BAR = 1044086265,
    BAR_BASE = 1517329426,           -- its _pos_base01 locator
    LIST_ROOT = 2411076261,          -- team01_01_list_item_locator (the rows hang on its locators)
    LIST_ROW0 = 4265378441,          -- its locator of row 0
    ATDF = 859123864,                -- mainmenu04_06_team_atdf (a root layer of its own)
    ZONE = 855005857,                -- (layer, index, on): an instance's pointer zone
    GET_POS = VRFW.commands.GET_LAYER_LOCAL_POS,          -- (layer, index) -> x, y, z (root: screen px, y up)
    SET_POS = VRFW.commands.SET_LAYER_LOCAL_POS,          -- (layer, x, y, z, index)
    MESH_POS = VRFW.commands.GET_MESH_GLOBAL_POSITION,    -- (layer, index, node) -> x, y (screen px, y up)
    -- the team screen background (retail SetActiveDockBackground, soccer_formation_menu_inc)
    BG = 367379312,                  -- mainmenu90_00_background (a layer of the dock's parent menu)
    BG_LOOK = 692638191,
    BG_ANIMATION = 3903979878,
    IS_OPEN_LAYER = VRFW.commands.IS_OPEN_LAYER,          -- (layer, index[, menu]) -> open
    BG_PARENTS = { 3902542018, 91676902, 811496143, 3653404168, 1385239856, 1917973090 },
    LIST_OFF_X = -4000,
    ICON = 330027688,                -- vrfw_team_icon
    ICON_ATLAS = 4153539961,
    ICON_SLOT = 1248982129,          -- icon_synergy_dmy01 (the icon mesh's sprite slot)
    ICON_MESH = 3937907647,          -- _icon_synergy_dmy01
    FOCUS_RANGE = 3252599449,
    ICON_HIDE = { 3439741810, 2904004604, 3541433305, 3788460933 },
                                     -- _synergy_icon_base01 and its _sdw (the synergy item's own art)
    SWAP = 558735651,                -- (layer, atlas, sprite, slot sprite, 0, index)
    MESH_VISIBLE = 3405944500,       -- CMND_SET_MESH_VISIBLE (layer, mesh, on, index)
    NODE_POS = 2575768773,           -- (layer, index, node, axis 0 x / 1 y, value)
    NODE_SIZE = 2885415772,          -- (layer, index, node, w, h): a mesh node's size
    CURSOR_TRACE = 1774843228,       -- (layer, index, locator, on)
    CURSOR = 3313461902, CARD_CURSOR = 945715707,   -- the cursor locators (rows / cards)
    FOCUS_MARK = 1778826357,         -- (layer, index, on)
    FOCUS_IDX = 2603265800,          -- (layer) -> focused index
    TEXT_GET = 4074371074,           -- CMND_TEXT_GET (text id) -> string
    SE_DECIDE = 3848881948,          -- sy0000
    TEAM_GET = VRFW.commands.GET_TEAM_SET_INFO,           -- (set, team, field[, slot]) -> ok, value: 5 emblem, 7 kit
    TEAM_SET = VRFW.commands.SET_TEAM_SET_INFO,           -- (set, team, field, value): 1 emblem
    TEAM_SET_KIT = VRFW.commands.VRFW_TEAM_SET_KIT,
    ITEM_COUNT = VRFW.commands.GET_ITEM_NUM, ITEM_ADD = VRFW.commands.ADD_ITEM_ONLY,
    FOCUS_ACTIVE = 102308320,        -- (layer) -> the layer has the control focus
    ENTER_INPUT = 1981080283,        -- CMD_ENTER: the guide's decide entry
    -- the guide's decide entry while a crest / kit with choices has focus (text/rows/team_editor.toml)
    CHOICE_TEXTS = { emblems = "vrfw_team_editor_next_crest", kits = "vrfw_team_editor_next_kit" },
  }
  local DECIDE_LAYERS = { [K.LIST] = true, [K.CARDS] = true, [K.FORMATION_BOX] = true, [K.ATTACH_FORMATION] = true }
  local IDENTITY_LAYERS = { [1044086265] = true, [1922851874] = true, [3822105360] = true }
  local CHOICE_LAYERS = { [1044086265] = "emblems", [3822105360] = "kits" }
  local S = { choices = {}, guide_kind = nil, on = false, tab = false, opened = false, rows = nil, banks = nil, keep = K.KEEP_ROWS, layout = nil, moved = {},
    icons = {}, row_co = nil }

  local log = VRFW.logger.new("VRFW team editor, dock")

  local function locals()
    local host = VRFW.host.hosts ~= nil and VRFW.host.hosts[STEM] or nil
    return host ~= nil and host.L or nil
  end

  local function local_table(name)
    local L = locals()
    if L == nil then
      return nil
    end
    local ok, v = pcall(function()
      return L[name]
    end)
    return ok and type(v) == "table" and v or nil
  end

  local function refill(list, values)
    for i = #list, 1, -1 do
      list[i] = nil
    end
    for i, v in ipairs(values) do
      list[i] = v
    end
  end

  local function restore_rows()
    if S.rows == nil then
      return
    end
    local kinds = local_table("t")
    if kinds then
      refill(kinds, S.rows)
    end
    S.rows = nil
  end

  local function leave(why)
    if not S.on then
      return
    end
    S.on = false
    S.tab, S.kept_dock, S.lock_identity, S.page_guide, S.no_pager = false, false, false, false, false
    S.choices, S.guide_kind = {}, nil
    S.layout, S.moved, S.bg_logged = nil, {}, nil
    S.icons, S.row_co, S.icon_busy = {}, nil, false
    restore_rows()
    log("foreign team mode off (" .. why .. ")")
  end

  -- a root layer at its retail place + (dx, dy) (screen px, right / down), once per position the retail setup gives it
  local function move_root(layer, dy, why, dx)
    dx = dx or 0
    local x, y, z = VRFW.host.menu_command(K.GET_POS, layer, 0)
    if type(x) ~= "number" or type(y) ~= "number" then
      log("layout:", why, "position not readable")
      return
    end
    local done = S.moved[layer]
    if done ~= nil and math.abs(y - done[2]) < 0.5 and math.abs(x - done[1]) < 0.5 then
      return
    end
    VRFW.host.menu_command(K.SET_POS, layer, x + dx, y - dy, z or 0, 0)
    S.moved[layer] = { x + dx, y - dy }
    log(string.format("layout: %s moved %d px right, %d px down (x %.0f -> %.0f, y %.0f -> %.0f)", why, dx, dy, x,
      x + dx, y, y - dy))
  end

  -- the host's layout for a root layer just opened (team page mode only)
  local function apply_layout(layer)
    local lay = S.layout
    if lay == nil then
      return
    end
    if not lay.header then
      for _, l in ipairs(K.HEADER_LAYERS) do
        if l == layer then
          VRFW.host.menu_command(K.VISIBLE, l, 0, false)
          VRFW.host.menu_command(K.ZONE, l, 0, false)
        end
      end
    end
    if lay.header and lay.header_top ~= nil and layer == K.BAR then
      -- the bar's base locator's screen y (y up) against the wanted y
      local _, by = VRFW.host.menu_command(K.MESH_POS, K.BAR, 0, K.BAR_BASE)
      if type(by) == "number" then
        move_root(layer, by + lay.header_top, "team name bar", lay.header_dx or 0)
      else
        log("layout: team name bar not measurable")
      end
    end
    if (lay.field_dy or 0) ~= 0 and (layer == K.ATTACH_FORMATION or layer == K.ATDF) then
      move_root(layer, lay.field_dy, layer == K.ATDF and "AT / DF" or "pitch")
    end
    if (lay.list_top ~= nil or lay.hide_list) and layer == K.LIST_ROOT then
      local dx = lay.hide_list and K.LIST_OFF_X or 0
      if lay.list_top == nil then
        move_root(layer, 0, "list (hidden)", dx)
      else
        -- the row 0 locator's screen y (y up) against the wanted top
        local _, ry = VRFW.host.menu_command(K.MESH_POS, K.LIST_ROOT, 0, K.LIST_ROW0)
        if type(ry) == "number" then
          move_root(layer, ry + lay.list_top, "list", dx)   -- from the row's screen y (-ry) down to list_top
        else
          log("layout: list row 0 not measurable")
        end
      end
    end
  end

  local function refuse()
    VRFW.host.command(K.SOUND, K.SE_NO)
  end

  -- the choice kind of an identity layer whose decide steps through the caller's list (2 or more), else nil
  local function choice_kind(layer)
    local kind = S.on and S.tab and CHOICE_LAYERS[layer] or nil
    return kind ~= nil and #(S.choices[kind] or {}) >= 2 and kind or nil
  end

  -- the team set on screen (the dock's n5)
  local function shown_set()
    local L = locals()
    local ok, set = pcall(function()
      return L and L.n5
    end)
    return ok and type(set) == "number" and set or nil
  end

  local function next_identity(layer, kind)
    local set = shown_set()
    if set == nil then
      refuse()
      log("identity choice: no team set on screen")
      return
    end
    local list = S.choices[kind]
    local has, now
    if kind == "emblems" then
      has, now = VRFW.host.command(K.TEAM_GET, set, 0, 5, 0)
    else
      has, now = VRFW.host.command(K.TEAM_GET, set, 0, 7)
    end
    now = has == true and now or 0
    local at = 0
    for i, id in ipairs(list) do
      if id == now then at = i end
    end
    local pick = list[at % #list + 1]
    if kind == "emblems" then
      local count = VRFW.host.command(K.ITEM_COUNT, pick)
      if (tonumber(count) or 0) < 1 then VRFW.host.command(K.ITEM_ADD, pick, 1) end
      VRFW.host.command(K.TEAM_SET, set, 0, 1, pick)
      local redraw = rawget(_ENV, "SetupTeamDockTeamNameBar")
      if type(redraw) == "function" then pcall(redraw) end
    else
      for team = 0, 1 do VRFW.host.command(K.TEAM_SET_KIT, set, team, pick) end
      local redraw = rawget(_ENV, "SetupUniformIcom")
      if type(redraw) == "function" then pcall(redraw, layer, 0) end
    end
    VRFW.host.command(K.SOUND, K.SE_DECIDE)
    log(string.format("identity choice: %s 0x%08X (%d of %d)", kind, pick, at % #list + 1, #list))
  end

  local function hide_dock_marks()
    VRFW.host.menu_command(K.VISIBLE, K.DOCK_NUMBER, 0, false)
    VRFW.host.menu_command(K.VISIBLE, K.ACTIVE_MARK, 0, false)
    VRFW.host.menu_command(K.VISIBLE, K.BANK_COUNT, 0, false)
    VRFW.host.menu_command(K.VISIBLE, K.CHANGE_GUIDE, 0, false)
    if S.no_pager then
      VRFW.host.menu_command(K.ZONE, K.DOCK_NUMBER, 0, false)
      VRFW.host.menu_command(K.ZONE, K.CHANGE_GUIDE, 0, false)
    end
  end

  local function allowed(layer, row)
    if layer == K.ICON then
      local icon = type(row) == "number" and S.icons[row + 1] or nil
      return icon ~= nil and S.keep[icon.row] == true
    end
    if choice_kind(layer) then
      return true
    end
    if S.tab and S.lock_identity and IDENTITY_LAYERS[layer] then
      return false
    end
    if S.tab and layer ~= K.LIST then
      return true
    end
    if not DECIDE_LAYERS[layer] then
      return false
    end
    if layer == K.LIST then
      local kinds = local_table("t")
      return kinds ~= nil and type(row) == "number" and S.keep[kinds[row + 1]] == true
    end
    return true
  end

  local function setup_icon(idx)
    local icon = S.icons[idx + 1]
    if icon == nil then
      return
    end
    local atlas = (icon.atlas or 0) ~= 0 and icon.atlas or K.ICON_ATLAS
    VRFW.host.menu_command(K.SWAP, K.ICON, atlas, icon.sprite, K.ICON_SLOT, 0, idx)
    for _, mesh in ipairs(K.ICON_HIDE) do
      VRFW.host.menu_command(K.MESH_VISIBLE, K.ICON, mesh, false, idx)
    end
    local w, h = icon.w > 0 and icon.w or 46, icon.h > 0 and icon.h or 46
    VRFW.host.menu_command(K.NODE_POS, K.ICON, idx, K.ICON_MESH, 0, -w / 2)
    VRFW.host.menu_command(K.NODE_POS, K.ICON, idx, K.ICON_MESH, 1, h / 2)
    VRFW.host.menu_command(K.NODE_SIZE, K.ICON, idx, K.ICON_MESH, w, h)
  end

  -- the list index (0-based) of a row kind in this open's list, nil when it is not there
  local function row_index(kind)
    for i, k in ipairs(local_table("t") or {}) do
      if k == kind then
        return i - 1
      end
    end
    return nil
  end

  local function run_icon(idx)
    local icon = S.icons[idx + 1]
    local row = icon ~= nil and row_index(icon.row) or nil
    local lock = icon ~= nil and (local_table("t3") or {})[icon.row + 1] or nil
    if row == nil or lock == 2 or lock == 3 or type(OnDecideFocus) ~= "function" then
      refuse()
      return
    end
    S.icon_busy = true
    log("icon", idx, "opens list row", row, "(kind " .. tostring(icon.row) .. ")")
    VRFW.host.command(K.SOUND, K.SE_DECIDE)
    pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, false)
    VRFW.host.menu_command(K.CONTROL_FOCUS, K.ICON, false)
    local ok, err = pcall(OnDecideFocus, K.LIST, row)
    if not ok then
      log("icon", idx, "row error", tostring(err))
    end
    local li = VRFW.host.menu_command(K.FOCUS_IDX, K.LIST)
    li = type(li) == "number" and li or 0
    VRFW.host.menu_command(K.CONTROL_FOCUS, K.LIST, false)
    VRFW.host.menu_command(K.CURSOR_TRACE, K.LIST, li, K.CURSOR, false)
    VRFW.host.menu_command(K.CURSOR_TRACE, K.LIST, li, K.CARD_CURSOR, false)
    VRFW.host.menu_command(K.FOCUS_MARK, K.LIST, li, false)
    VRFW.host.menu_command(K.CONTROL_FOCUS, K.ICON, true)
    VRFW.host.menu_command(K.FOCUS_MARK, K.ICON, idx, true)
    VRFW.host.menu_command(K.CURSOR_TRACE, K.ICON, idx, K.CURSOR, true)
    pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
    S.icon_busy = false
  end

  local function decide_icon(idx)
    if S.icon_busy or S.row_co ~= nil then
      return
    end
    if not allowed(K.ICON, idx) then
      refuse()
      return
    end
    local _, main = coroutine.running()
    if main == false then
      run_icon(idx)
    else
      S.row_co = coroutine.create(function() run_icon(idx) end)
    end
  end

  if type(VRFW.team_editor) == "table" then
    --- Advanced: Reads the help line of the icon at idx; answers "name - help" text, or nil when none.
    function VRFW.team_editor.icon_help(idx)
      local icon = S.on and S.icons[(idx or 0) + 1] or nil
      local item = icon ~= nil and (local_table("t2") or {})[icon.row + 1] or nil
      if type(item) ~= "table" then
        return nil
      end
      local name = VRFW.host.command(K.TEXT_GET, item.itemName or 0)
      local help = VRFW.host.command(K.TEXT_GET, item.itemExplation or 0)
      name, help = type(name) == "string" and name or "", type(help) == "string" and help or ""
      if name ~= "" and help ~= "" then
        return name .. " · " .. help
      end
      return name ~= "" and name or (help ~= "" and help or nil)
    end
  end

  VRFW.host.on(STEM, "Step", {
    id = "menu_engine.team_editor_icons", phase = "after",
    fn = function()
      if S.row_co == nil then
        return
      end
      local ok, err = coroutine.resume(S.row_co)
      if not ok then
        log("icon screen error", tostring(err))
        S.icon_busy = false
        pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
      end
      if not ok or coroutine.status(S.row_co) == "dead" then
        S.row_co = nil
      end
    end,
  })

  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_foreign", phase = "before", priority = -1000,
    fn = function()
      leave("a new open")
      local foreign = type(VRFW.team_editor) == "table" and VRFW.team_editor.foreign and VRFW.team_editor.foreign()
      if foreign == nil then
        return
      end
      S.on = true
      S.tab = foreign.tab == true
      S.kept_dock = S.tab and foreign.keep == true
      S.opened = false
      S.moved = {}
      S.layout = (S.tab or foreign.hide_list) and { header = foreign.header ~= false, list_top = foreign.list_top,
        field_dy = foreign.field_dy or 0, header_top = foreign.header_top,
        header_dx = foreign.header_dx or 0, hide_list = foreign.hide_list == true }
        or nil
      S.icons = type(foreign.icons) == "table" and foreign.icons or {}
      S.lock_identity = S.tab and foreign.lock_identity == true
      S.choices = S.tab and type(foreign.identity_choices) == "table" and foreign.identity_choices or {}
      S.page_guide = foreign.inline_card_actions == true
      S.no_pager = foreign.hide_pager == true
      S.keep = type(foreign.rows) == "table" and next(foreign.rows) ~= nil and foreign.rows or K.KEEP_ROWS
      log(string.format("%s mode on (stadium 0x%08X)", S.tab and "team page" or "foreign team", foreign.stadium or 0))
    end,
  })

  -- the team screen background once the retail OnInit ran (it sets it on the shown set, the copy's dock)
  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_foreign_background", phase = "after",
    fn = function()
      if S.on and type(SetActiveDockBackground) == "function" then
        pcall(SetActiveDockBackground, true)
      end
    end,
  })

  VRFW.host.on(STEM, "OnSetupLayer", {
    id = "menu_engine.team_editor_foreign", phase = "before", priority = 1000,
    fn = function(layer, row)
      if not S.on or layer ~= K.LIST or row ~= 0 then
        return
      end
      local kinds = local_table("t")
      if kinds == nil then
        log("the list's row table was not found (no VRFW.debug?): rows kept")
        return
      end
      local all, keep = {}, {}
      for i, kind in ipairs(kinds) do
        all[i] = kind
        if S.keep[kind] then
          keep[#keep + 1] = kind
        end
      end
      if S.rows == nil then
        S.rows = all
      end
      refill(kinds, keep)
      log("list:", #keep, "of", #all, "row(s) kept")
    end,
  })

  VRFW.host.on(STEM, "OnFunction", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, a2, ...)
      if S.on and S.tab and a1 == K.NEXT_DOCK then
        if not S.opened then
          log("team page: L1 / R1 ignored while the dock still opens")
          return
        end
        local editor = VRFW.team_editor
        if type(editor) == "table" and editor.DIRECTION_KEY then
          VRFW.param.set(editor.DIRECTION_KEY, a2 == K.LEFT and 1 or 2)
        end
        log("team page: L1 / R1 hands the page change to the host")
        if S.kept_dock then
          return
        end
        local back = rawget(_ENV, "FuncOnBack")
        if type(back) == "function" then
          back(true)
        end
        return
      end
      if S.on and K.BLOCKED_FUNCTIONS[a1] then
        refuse()
        return
      end
      return nxt(a1, a2, ...)
    end,
  })

  VRFW.host.on(STEM, "OnEnter", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, layer, row, ...)
      if S.on and layer == K.ICON then
        decide_icon(row)
        return 1
      end
      local kind = choice_kind(layer)
      if kind then
        next_identity(layer, kind)
        return 1
      end
      if S.on and not allowed(layer, row) then
        refuse()
        return 1
      end
      return nxt(layer, row, ...)
    end,
  })

  VRFW.host.on(STEM, "OnDecideFocus", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, layer, row, ...)
      if S.on and layer == K.ICON then
        decide_icon(row)
        return
      end
      local kind = choice_kind(layer)
      if kind then
        next_identity(layer, kind)
        pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
        VRFW.host.menu_command(K.CONTROL_FOCUS, layer, true)
        return
      end
      if S.on and not allowed(layer, row) then
        refuse()
        pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
        VRFW.host.menu_command(K.CONTROL_FOCUS, layer, true)
        return
      end
      return nxt(layer, row, ...)
    end,
  })

  VRFW.host.on(STEM, "SwapChara", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on and type(VRFW.team_editor) == "table" and VRFW.team_editor.guard_swap then
        return VRFW.team_editor.guard_swap(nxt, ...)
      end
      return nxt(...)
    end,
  })

  VRFW.host.on(STEM, "StartMoveTeamDock", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on then
        return
      end
      return nxt(...)
    end,
  })

  -- the guide without the inputs of the player's own docks (the entries table is put back right after)
  VRFW.host.on(STEM, "SetupButtonGuideText", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = 1000,
    fn = function(nxt, ...)
      local entries = S.on and local_table("t4") or nil
      if entries == nil then
        return nxt(...)
      end
      local all, keep = {}, {}
      for i, e in ipairs(entries) do
        all[i] = e
        local blocked = type(e) == "table" and K.BLOCKED_INPUTS[e.inputCmd] and not (S.tab and K.PAGE_INPUTS[e.inputCmd])
        if blocked and S.page_guide and e.inputCmd == K.PAGE_INPUT then
          local page = {}
          for k, v in pairs(e) do page[k] = v end
          page.textId = VRFW.crc32(K.PAGE_TEXT)
          keep[#keep + 1] = page
        elseif not blocked and S.guide_kind and e.inputCmd == K.ENTER_INPUT then
          local step = {}
          for k, v in pairs(e) do step[k] = v end
          step.textId = VRFW.crc32(K.CHOICE_TEXTS[S.guide_kind])
          keep[#keep + 1] = step
        elseif not blocked then
          keep[#keep + 1] = e
        end
      end
      refill(entries, keep)
      local r = table.pack(pcall(nxt, ...))
      refill(entries, all)
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  -- the header's dock line (dock number of the player's docks) stays hidden
  VRFW.host.on(STEM, "SetVisibleHeaderTeamDoc", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, visible, ...)
      if S.on then
        return nxt(false, ...)
      end
      return nxt(visible, ...)
    end,
  })

  VRFW.host.on(STEM, "SetActiveDockBackground", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, on, ...)
      if not S.on then
        return nxt(on, ...)
      end
      local r = table.pack(pcall(nxt, true, ...))
      local parent = type(g_parentMenuId) == "number" and g_parentMenuId or nil
      local listed = false
      for _, menu in ipairs(K.BG_PARENTS) do
        if menu == parent then
          listed = true
        end
      end
      local open = false
      if parent and not listed then
        open = VRFW.host.menu_command(K.IS_OPEN_LAYER, K.BG, 0, parent)
      end
      if open == true then
        VRFW.host.menu_command(K.BG_LOOK, parent, K.BG, 0, K.BG_ANIMATION)
        if S.bg_logged ~= parent then
          S.bg_logged = parent
          log("team screen background set on the host", parent)
        end
      end
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  -- the dock's other modes and pages stay off while this mode is on (VRFW.team_dock, lua/_all/16_team_dock.lua)
  VRFW.team_dock.claim("vrfw_team_editor", function()
    return S.on
  end)

  for _, point in ipairs({ "UpdateTeamDockChangeGuideNo", "UpdateTeamDockNoCommon", "UpdateTeamDockNo" }) do
    VRFW.host.on(STEM, point, {
      id = "menu_engine.team_editor_foreign", phase = "after",
      fn = function()
        if S.on then
          hide_dock_marks()
        end
      end,
    })
  end

  VRFW.host.on(STEM, "UpdateViewTeamDockNo", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function()
      if S.on then
        hide_dock_marks()
      end
    end,
  })

  VRFW.host.on(STEM, "OnOpenLayer", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function(_, layer, index)
      if S.on and (layer == K.DOCK_NUMBER or layer == K.ACTIVE_MARK or layer == K.CHANGE_GUIDE
          or layer == K.BANK_COUNT) then
        hide_dock_marks()
      end
      if S.on and S.layout then
        apply_layout(layer)
      end
      if S.on and layer == K.ICON then
        setup_icon(index or 0)
        if (index or 0) == 0 and #S.icons > 1 then
          -- the pad and the pointer reach every icon of the row (the menu data gives a new layer no focus range)
          VRFW.host.menu_command(K.FOCUS_RANGE, K.ICON, #S.icons)
          log("icons: focus range " .. #S.icons)
        end
      end
      if S.on and S.lock_identity and IDENTITY_LAYERS[layer] and not choice_kind(layer) then
        VRFW.host.menu_command(K.ZONE, layer, 0, false)   -- no pointer on the fixed identity
      end
    end,
  })

  VRFW.host.on(STEM, "OnChangeFocus", {
    id = "menu_engine.team_editor_foreign_identity_choices", phase = "after",
    fn = function()
      if not (S.on and S.tab and next(S.choices) ~= nil) then
        return
      end
      local focused = nil
      for layer in pairs(CHOICE_LAYERS) do
        local kind = choice_kind(layer)
        if kind then
          local active = VRFW.host.menu_command(K.FOCUS_ACTIVE, layer)
          if active == true then focused = kind end
        end
      end
      if focused ~= S.guide_kind then
        S.guide_kind = focused
        local guide = rawget(_ENV, "SetupButtonGuideText")
        if type(guide) == "function" then pcall(guide) end
      end
    end,
  })

  VRFW.host.on(STEM, "OnOpenEndLayer", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function(_, layer)
      if S.on and S.tab and not S.opened and layer == K.BAR then
        S.opened = true
        log("team page: dock open")
      end
    end,
  })

  VRFW.host.on(STEM, "OnBack", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, layer, ...)
      if S.on and S.tab and not S.opened then
        log("team page: back ignored while the dock still opens")
        return 1
      end
      return nxt(layer, ...)
    end,
  })

  VRFW.host.on(STEM, "FuncOnBack", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function()
      leave("dock closed")
    end,
  })

  VRFW.host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_foreign", phase = "before", create = true,
    fn = function()
      leave("dock finalized")
    end,
  })
end
