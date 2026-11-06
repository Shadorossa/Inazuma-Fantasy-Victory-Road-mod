-- menu_engine: the FOREIGN TEAM mode of the team dock (soccer_team_dock_menu), for VRFW_TeamEditor.Run with
-- spec.foreign (lua\_all\81_team_editor.lua, docs/framework/team-editor.md). Definitions only; no engine call at load.
--
-- The dock shows a team that is not one of the player's (a league team, a tournament team). Nothing that reads or
-- writes the player's own team docks is offered while it is up:
--   * the list keeps the rows the caller offers (spec.rows, VRFW_TeamEditor.ROW: the lineup, bonds, hyper commands;
--     they open on the dock's team, the bonds and hyper commands screens view only); the others (bank, abilities,
--     the 11v11 / 5v5 rows, other mods' rows) are left out for this open and come back when the dock closes;
--   * L1 / R1 (team switching), «Establecer como equipo activo», the tournament team, the player's name plate and
--     moving the dock are refused, and their entries leave the button guide;
--   * the team's identity is view only: only the list, the player cards and the formation box take a decide (the
--     coach card, tactics, kit, emblem (the team name bar), synergies, the team name and other mods' panel buttons are
--     refused: their pickers list the player's own cards and items);
--   * a card swap on the pitch only among the team's own players (VRFW_TeamEditor.GuardSwap);
--   * the dock number, its L1 / R1 change guide («5 / 5»), the active team mark and the header's dock line are hidden;
--     the background always has the team screen look (the edited team is the one shown, never the grey look of
--     another dock); over a host the retail background function does not list, the host's own background gets it;
--   * with spec.identity_choices (2 or more crests / kits) a decide on the crest (the team name bar) or the kit shows
--     the next one of the list, lock_identity or not; the guide's decide entry names it while one of them has focus.
-- The TEAM PAGE mode (spec.tab, foreign.tab) is the same team with the retail screen whole: every list row but the
-- hidden ones, every decide and edit; L1 / R1 close the dock and hand the direction to the host (the host's next
-- page; with spec.keep they only hand the direction: the editor hides the dock and keeps it for the next visit); the
-- active team, the tournament team, the name plate and the club's bank pages stay off.
--   * the dock is claimed (VRFW_TeamDock.Claim): other mods' dock pages (team banks) and modes (Pachangas' format
--     rows and active teams line) stay off;
--     the help line is the retail description of the focused row.
--   * the host's layout of the page (spec.header / list_top / field_dy, VRFW_TeamEditor.Foreign()): the team name bar
--     and its plates hidden with their pointer zones; the list's root moved so its first row is at list_top; the
--     pitch's root (team01_03_attach_formation: the pitch, bench, coach, tactics, formation, kit and the dock's other
--     attached layers ride on it, with their pointer zones) and AT / DF moved field_dy px lower. Each root is moved
--     when it opens, from the position the retail setup gave it.
--   * with spec.hide_pager the dock's team-slot pager (the change guide: arrows, team icon, number, L1 / R1 / Z / C glyphs) is
--     also hidden with its pointer zones after every dock number update, and L1 / R1 never switch team slots (the
--     team page hands them to the host; the foreign mode refuses them).
-- The mode is read once per open at OnInit (VRFW_TeamEditor.Foreign(): cross-menu parameters the editor writes
-- before it opens the dock and removes after) and ends when the dock closes.
if VRFW_Host ~= nil then
  local STEM = "soccer_team_dock_menu"
  local K = {
    LIST = 3367997069,               -- team01_02_list_item
    CARDS = 1973487846,              -- team00_01_chara_card_for_soccer (the team's players)
    FORMATION_BOX = 3286546665,      -- team00_12_formation_style
    ATTACH_FORMATION = 2141963976,   -- team01_03_attach_formation
    DOCK = 937147172,                -- soccer_team_dock_menu
    DOCK_NUMBER = 1308042914,        -- team01_05_team_dock_no
    ACTIVE_MARK = 8591637,           -- team01_06_team_dock_active_team_mark
    BANK_COUNT = 3925006528,         -- team14_05_chara_bank_count (the club bank row's count; that row is left out, so
                                     -- the count stays at the list's origin, top left)
    CHANGE_GUIDE = 255314328,        -- team14_04_team_dock_change_guide (L1 / R1 and the dock number, opened by
                                     -- OpenCommonSoccerFormationUI)
    -- list row kinds kept (retail kinds: 0 the lineup screen; the rest open screens of the player's club)
    KEEP_ROWS = { [0] = true },      -- when the caller offers none
    -- OnFunction commands of the player's own docks: L1 / R1 team switch, set as active team, tournament team, the
    -- player's name plate
    BLOCKED_FUNCTIONS = { [2294853123] = true, [4219711668] = true, [3620553157] = true, [2237843578] = true },
    -- their button guide inputs: CMD_FUNCL1, CMD_FUNCR1, CMD_FUNC3, and CMD_FUNC6 (R3: the club's team bank pages)
    BLOCKED_INPUTS = { [3966226594] = true, [942075773] = true, [3421673595] = true, [3147328756] = true },
    PAGE_INPUT = 3421673595,         -- CMD_FUNC3 (Y): with spec.inline_card_actions the player page (137_inline_card_actions.lua)
    PAGE_TEXT = "vrfw_team_editor_player_page",   -- its guide text (text/rows/team_editor.toml, menu_text: crc32 of the id)
    MENU_INPUT = 1558704558,         -- (menu, on)
    CONTROL_FOCUS = VRFW_Cmd.SET_ENABLE_CTRL_FOCUS,      -- (layer, on)
    VISIBLE = VRFW_Cmd.SET_LAYER_VISIBLE,             -- CMND_SET_LAYER_VISIBLE (layer, index, on)
    SOUND = VRFW_Cmd.SND_PLAY_SE, SE_NO = 2086672038,   -- sy0003
    LOG = VRFW_Cmd.EVT_LOG,                -- CMND_EVT_LOG
    NEXT_DOCK = 2294853123,          -- OnFunction: L1 / R1 (a2 = left / right)
    LEFT = 2053629800,               -- its a2 for L1
    PAGE_INPUTS = { [3966226594] = true, [942075773] = true },   -- CMD_FUNCL1 / CMD_FUNCR1: kept in the team page mode
    -- the team page's layout
    HEADER_LAYERS = { 1044086265, 1922851874, 3926241346, 2781487712, 2280287248 },   -- team01_04_team_name_bar, its
                                     -- team name and player plates (p1 / p2 frames), the user name and title
    BAR = 1044086265,                -- team01_04_team_name_bar (a root layer; its plates and the kit hang on it)
    BAR_BASE = 1517329426,           -- its _pos_base01 locator
    LIST_ROOT = 2411076261,          -- team01_01_list_item_locator (the rows hang on its locators)
    LIST_ROW0 = 4265378441,          -- its locator of row 0
    ATDF = 859123864,                -- mainmenu04_06_team_atdf (a root layer of its own)
    ZONE = 855005857,                -- (layer, index, on): an instance's pointer zone
    GET_POS = VRFW_Cmd.GET_LAYER_LOCAL_POS,          -- (layer, index) -> x, y, z (root: screen px, y up)
    SET_POS = VRFW_Cmd.SET_LAYER_LOCAL_POS,          -- (layer, x, y, z, index)
    MESH_POS = VRFW_Cmd.GET_MESH_GLOBAL_POSITION,    -- (layer, index, node) -> x, y (screen px, y up)
    -- the team screen background (retail SetActiveDockBackground, soccer_formation_menu_inc)
    BG = 367379312,                  -- mainmenu90_00_background (a layer of the dock's parent menu)
    BG_LOOK = 692638191,             -- (menu, layer, index, animation[, 1, 1, 1]): its look (grey: the trailing 1s)
    BG_ANIMATION = 3903979878,
    IS_OPEN_LAYER = VRFW_Cmd.IS_OPEN_LAYER,          -- (layer, index[, menu]) -> open
    -- the parents the retail function looks for (its own list: chronicle_mode_top_menu, team_dock_common_top_menu,
    -- soccer_top_menu, victory_road_top_menu and two more)
    BG_PARENTS = { 3902542018, 91676902, 811496143, 3653404168, 1385239856, 1917973090 },
    -- the list hidden (spec.hide_list): its root this many px to the left, off screen with its pointer zones
    LIST_OFF_X = -4000,
    -- the icon buttons (spec.icons): vrfw_team_icon (content\menus\team_icons.toml, a copy of the synergy button)
    ICON = 330027688,                -- vrfw_team_icon
    ICON_ATLAS = 4153539961,         -- #/menu/100_mainmenu/mainmenu90/mainmenu90_01/<LG>/mainmenu90_01.g4tx (spec
                                     -- icon without its own atlas)
    ICON_SLOT = 1248982129,          -- icon_synergy_dmy01 (the icon mesh's sprite slot)
    ICON_MESH = 3937907647,          -- _icon_synergy_dmy01
    FOCUS_RANGE = 3252599449,        -- (layer, count): the instances the focus may reach (a new layer: only the first)
    ICON_HIDE = { 3439741810, 2904004604, 3541433305, 3788460933 },   -- _synergy_top_blank01, _synergy_active01,
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
    TEAM_GET = VRFW_Cmd.GET_TEAM_SET_INFO,           -- (set, team, field[, slot]) -> ok, value: 5 emblem, 7 kit
    TEAM_SET = VRFW_Cmd.SET_TEAM_SET_INFO,           -- (set, team, field, value): 1 emblem
    TEAM_SET_KIT = VRFW_Cmd.VRFW_TEAM_SET_KIT,       -- (set, team, uniform) -> ok, uniform now
    ITEM_COUNT = VRFW_Cmd.GET_ITEM_NUM, ITEM_ADD = VRFW_Cmd.ADD_ITEM_ONLY,   -- the crest item held before it is set
    FOCUS_ACTIVE = 102308320,        -- (layer) -> the layer has the control focus
    ENTER_INPUT = 1981080283,        -- CMD_ENTER: the guide's decide entry
    -- the guide's decide entry while a crest / kit with choices has focus (text/rows/team_editor.toml)
    CHOICE_TEXTS = { emblems = "vrfw_team_editor_next_crest", kits = "vrfw_team_editor_next_kit" },
  }
  local DECIDE_LAYERS = { [K.LIST] = true, [K.CARDS] = true, [K.FORMATION_BOX] = true, [K.ATTACH_FORMATION] = true }
  -- the team's identity in the team page with spec.lock_identity: the team name bar (its emblem), the team name plate,
  -- the kit (team00_13_uniform_icon)
  local IDENTITY_LAYERS = { [1044086265] = true, [1922851874] = true, [3822105360] = true }
  -- the identity layers a decide steps through spec.identity_choices: the crest (team name bar) and the kit
  local CHOICE_LAYERS = { [1044086265] = "emblems", [3822105360] = "kits" }
  local S = { choices = {}, guide_kind = nil, on = false, tab = false, opened = false, rows = nil, banks = nil, keep = K.KEEP_ROWS, layout = nil, moved = {},
    icons = {}, row_co = nil }

  local function log(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    pcall(funcLuaCommand, K.LOG, "VRFW team editor", "dock: " .. table.concat(parts, " "))
  end

  local function locals()
    local host = VRFW_Host.hosts ~= nil and VRFW_Host.hosts[STEM] or nil
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

  -- a list's contents replaced in place (the retail functions hold the table itself)
  local function refill(list, values)
    for i = #list, 1, -1 do
      list[i] = nil
    end
    for i, v in ipairs(values) do
      list[i] = v
    end
  end

  -- the list rows of this open back as they were
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
    local ok, x, y, z = pcall(funcLuaMenuCommand, K.GET_POS, layer, 0)
    if not ok or type(x) ~= "number" or type(y) ~= "number" then
      log("layout:", why, "position not readable")
      return
    end
    local done = S.moved[layer]
    if done ~= nil and math.abs(y - done[2]) < 0.5 and math.abs(x - done[1]) < 0.5 then
      return
    end
    pcall(funcLuaMenuCommand, K.SET_POS, layer, x + dx, y - dy, z or 0, 0)
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
          pcall(funcLuaMenuCommand, K.VISIBLE, l, 0, false)
          pcall(funcLuaMenuCommand, K.ZONE, l, 0, false)
        end
      end
    end
    if lay.header and lay.header_top ~= nil and layer == K.BAR then
      -- the bar's base locator's screen y (y up) against the wanted y
      local ok, _, by = pcall(funcLuaMenuCommand, K.MESH_POS, K.BAR, 0, K.BAR_BASE)
      if ok and type(by) == "number" then
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
        local ok, _, ry = pcall(funcLuaMenuCommand, K.MESH_POS, K.LIST_ROOT, 0, K.LIST_ROW0)
        if ok and type(ry) == "number" then
          move_root(layer, ry + lay.list_top, "list", dx)   -- from the row's screen y (-ry) down to list_top
        else
          log("layout: list row 0 not measurable")
        end
      end
    end
  end

  local function refuse()
    pcall(funcLuaCommand, K.SOUND, K.SE_NO)
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

  -- a decide on the crest / the kit with choices: the next one of the list on the dock's team, its header redrawn
  local function next_identity(layer, kind)
    local set = shown_set()
    if set == nil then
      refuse()
      log("identity choice: no team set on screen")
      return
    end
    local list = S.choices[kind]
    local ok, has, now
    if kind == "emblems" then
      ok, has, now = pcall(funcLuaCommand, K.TEAM_GET, set, 0, 5, 0)
    else
      ok, has, now = pcall(funcLuaCommand, K.TEAM_GET, set, 0, 7)
    end
    now = ok and has == true and now or 0
    local at = 0
    for i, id in ipairs(list) do
      if id == now then at = i end
    end
    local pick = list[at % #list + 1]
    if kind == "emblems" then
      local okc, count = pcall(funcLuaCommand, K.ITEM_COUNT, pick)
      if not okc or (tonumber(count) or 0) < 1 then pcall(funcLuaCommand, K.ITEM_ADD, pick, 1) end
      pcall(funcLuaCommand, K.TEAM_SET, set, 0, 1, pick)
      local redraw = rawget(_ENV, "SetupTeamDockTeamNameBar")
      if type(redraw) == "function" then pcall(redraw) end
    else
      for team = 0, 1 do pcall(funcLuaCommand, K.TEAM_SET_KIT, set, team, pick) end
      local redraw = rawget(_ENV, "SetupUniformIcom")
      if type(redraw) == "function" then pcall(redraw, layer, 0) end
    end
    pcall(funcLuaCommand, K.SOUND, K.SE_DECIDE)
    log(string.format("identity choice: %s 0x%08X (%d of %d)", kind, pick, at % #list + 1, #list))
  end

  local function hide_dock_marks()
    pcall(funcLuaMenuCommand, K.VISIBLE, K.DOCK_NUMBER, 0, false)
    pcall(funcLuaMenuCommand, K.VISIBLE, K.ACTIVE_MARK, 0, false)
    pcall(funcLuaMenuCommand, K.VISIBLE, K.BANK_COUNT, 0, false)
    pcall(funcLuaMenuCommand, K.VISIBLE, K.CHANGE_GUIDE, 0, false)
    if S.no_pager then
      pcall(funcLuaMenuCommand, K.ZONE, K.DOCK_NUMBER, 0, false)
      pcall(funcLuaMenuCommand, K.ZONE, K.CHANGE_GUIDE, 0, false)
    end
  end

  -- a decide the mode allows: the list's kept rows, the team's player cards, the formation box
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

  -- ---- the icon buttons (spec.icons): instance i of vrfw_team_icon opens the screen of its list row ---------------------
  -- an icon instance as it opens: its sprite, its size on the button's centre, the synergy item's own art off
  local function setup_icon(idx)
    local icon = S.icons[idx + 1]
    if icon == nil then
      return
    end
    local atlas = (icon.atlas or 0) ~= 0 and icon.atlas or K.ICON_ATLAS
    pcall(funcLuaMenuCommand, K.SWAP, K.ICON, atlas, icon.sprite, K.ICON_SLOT, 0, idx)
    for _, mesh in ipairs(K.ICON_HIDE) do
      pcall(funcLuaMenuCommand, K.MESH_VISIBLE, K.ICON, mesh, false, idx)
    end
    local w, h = icon.w > 0 and icon.w or 46, icon.h > 0 and icon.h or 46
    pcall(funcLuaMenuCommand, K.NODE_POS, K.ICON, idx, K.ICON_MESH, 0, -w / 2)
    pcall(funcLuaMenuCommand, K.NODE_POS, K.ICON, idx, K.ICON_MESH, 1, h / 2)
    pcall(funcLuaMenuCommand, K.NODE_SIZE, K.ICON, idx, K.ICON_MESH, w, h)
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

  -- the row's screen, as a decide on that list row (the retail OnDecideFocus), then the focus back on the icon (the
  -- retail gives it to the list). Runs in the engine's decide coroutine, or in its own one resumed by Step
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
    pcall(funcLuaCommand, K.SOUND, K.SE_DECIDE)
    pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, false)
    pcall(funcLuaMenuCommand, K.CONTROL_FOCUS, K.ICON, false)
    local ok, err = pcall(OnDecideFocus, K.LIST, row)
    if not ok then
      log("icon", idx, "row error", tostring(err))
    end
    local li = select(2, pcall(funcLuaMenuCommand, K.FOCUS_IDX, K.LIST))
    li = type(li) == "number" and li or 0
    pcall(funcLuaMenuCommand, K.CONTROL_FOCUS, K.LIST, false)
    pcall(funcLuaMenuCommand, K.CURSOR_TRACE, K.LIST, li, K.CURSOR, false)
    pcall(funcLuaMenuCommand, K.CURSOR_TRACE, K.LIST, li, K.CARD_CURSOR, false)
    pcall(funcLuaMenuCommand, K.FOCUS_MARK, K.LIST, li, false)
    pcall(funcLuaMenuCommand, K.CONTROL_FOCUS, K.ICON, true)
    pcall(funcLuaMenuCommand, K.FOCUS_MARK, K.ICON, idx, true)
    pcall(funcLuaMenuCommand, K.CURSOR_TRACE, K.ICON, idx, K.CURSOR, true)
    pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
    S.icon_busy = false
  end

  -- a decide on an icon: at once inside a coroutine (the engine's decide), else in one of its own (Step)
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

  -- the help line of icon idx: the list row's name and description (nil when it has none)
  if type(VRFW_TeamEditor) == "table" then
    function VRFW_TeamEditor.IconHelp(idx)
      local icon = S.on and S.icons[(idx or 0) + 1] or nil
      local item = icon ~= nil and (local_table("t2") or {})[icon.row + 1] or nil
      if type(item) ~= "table" then
        return nil
      end
      local okn, name = pcall(funcLuaCommand, K.TEXT_GET, item.itemName or 0)
      local okh, help = pcall(funcLuaCommand, K.TEXT_GET, item.itemExplation or 0)
      name, help = okn and type(name) == "string" and name or "", okh and type(help) == "string" and help or ""
      if name ~= "" and help ~= "" then
        return name .. " · " .. help
      end
      return name ~= "" and name or (help ~= "" and help or nil)
    end
  end

  VRFW_Host.on(STEM, "Step", {
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

  VRFW_Host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_foreign", phase = "before", priority = -1000,
    fn = function()
      leave("a new open")
      local foreign = type(VRFW_TeamEditor) == "table" and VRFW_TeamEditor.Foreign and VRFW_TeamEditor.Foreign()
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
  VRFW_Host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_foreign_background", phase = "after",
    fn = function()
      if S.on and type(SetActiveDockBackground) == "function" then
        pcall(SetActiveDockBackground, true)
      end
    end,
  })

  -- the kept rows, after every other mod added or removed its own (lowest in the order: runs last)
  VRFW_Host.on(STEM, "OnSetupLayer", {
    id = "menu_engine.team_editor_foreign", phase = "before", priority = 1000,
    fn = function(layer, row)
      if not S.on or layer ~= K.LIST or row ~= 0 then
        return
      end
      local kinds = local_table("t")
      if kinds == nil then
        log("the list's row table was not found (no EVT_DEBUG?): rows kept")
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

  VRFW_Host.on(STEM, "OnFunction", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, a1, a2, ...)
      if S.on and S.tab and a1 == K.NEXT_DOCK then
        -- the team page: L1 / R1 leave the dock towards the host's previous / next page, once its open has ended (a
        -- close while it still opens leaves its layers half drawn and the dock open)
        if not S.opened then
          log("team page: L1 / R1 ignored while the dock still opens")
          return
        end
        local editor = VRFW_TeamEditor
        if type(editor) == "table" and editor.DIRECTION_KEY then
          VRFW_Param.Set(editor.DIRECTION_KEY, a2 == K.LEFT and 1 or 2)
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

  VRFW_Host.on(STEM, "OnEnter", {
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

  -- a decide that reaches the dock without OnEnter (a click): refused the same way, the dock's control back
  VRFW_Host.on(STEM, "OnDecideFocus", {
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
        pcall(funcLuaMenuCommand, K.CONTROL_FOCUS, layer, true)
        return
      end
      if S.on and not allowed(layer, row) then
        refuse()
        pcall(funcLuaMenuCommand, K.MENU_INPUT, K.DOCK, true)
        pcall(funcLuaMenuCommand, K.CONTROL_FOCUS, layer, true)
        return
      end
      return nxt(layer, row, ...)
    end,
  })

  -- a card swap on the dock's own pitch: only among the team's players (VRFW_TeamEditor.GuardSwap)
  VRFW_Host.on(STEM, "SwapChara", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on and type(VRFW_TeamEditor) == "table" and VRFW_TeamEditor.GuardSwap then
        return VRFW_TeamEditor.GuardSwap(nxt, ...)
      end
      return nxt(...)
    end,
  })

  VRFW_Host.on(STEM, "StartMoveTeamDock", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, ...)
      if S.on then
        return
      end
      return nxt(...)
    end,
  })

  -- the guide without the inputs of the player's own docks (the entries table is put back right after)
  VRFW_Host.on(STEM, "SetupButtonGuideText", {
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
          -- Y opens the player page: the entry kept with its own text (a copy: the retail entry stays as it is)
          local page = {}
          for k, v in pairs(e) do page[k] = v end
          page.textId = VRFW_Crc32(K.PAGE_TEXT)
          keep[#keep + 1] = page
        elseif not blocked and S.guide_kind and e.inputCmd == K.ENTER_INPUT then
          -- a crest / kit with choices has focus: the decide entry names the next one
          local step = {}
          for k, v in pairs(e) do step[k] = v end
          step.textId = VRFW_Crc32(K.CHOICE_TEXTS[S.guide_kind])
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
  VRFW_Host.on(STEM, "SetVisibleHeaderTeamDoc", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, visible, ...)
      if S.on then
        return nxt(false, ...)
      end
      return nxt(visible, ...)
    end,
  })

  -- the dock's background is the team screen look (the retail active dock look, K.BG_LOOK without the trailing 1s:
  -- with them it is the plain grey look of a dock that is not the shown team). The retail function sets it only on the
  -- parents it lists; over any other host (the dock's parent g_parentMenuId: a mode's own menu) the same look is set
  -- on that parent's background, so the dock shows the retail team screen background there too.
  VRFW_Host.on(STEM, "SetActiveDockBackground", {
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
      local okb, open = false, false
      if parent and not listed then
        okb, open = pcall(funcLuaMenuCommand, K.IS_OPEN_LAYER, K.BG, 0, parent)
      end
      if okb and open == true then
        pcall(funcLuaMenuCommand, K.BG_LOOK, parent, K.BG, 0, K.BG_ANIMATION)
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

  -- the dock's other modes and pages stay off while this mode is on (VRFW_TeamDock, lua/_all/16_team_dock.lua)
  VRFW_TeamDock.Claim("vrfw_team_editor", function()
    return S.on
  end)

  -- the dock change guide's number written (its open, a dock change): the guide stays hidden
  for _, point in ipairs({ "UpdateTeamDockChangeGuideNo", "UpdateTeamDockNoCommon", "UpdateTeamDockNo" }) do
    VRFW_Host.on(STEM, point, {
      id = "menu_engine.team_editor_foreign", phase = "after",
      fn = function()
        if S.on then
          hide_dock_marks()
        end
      end,
    })
  end

  VRFW_Host.on(STEM, "UpdateViewTeamDockNo", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function()
      if S.on then
        hide_dock_marks()
      end
    end,
  })

  VRFW_Host.on(STEM, "OnOpenLayer", {
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
          pcall(funcLuaMenuCommand, K.FOCUS_RANGE, K.ICON, #S.icons)
          log("icons: focus range " .. #S.icons)
        end
      end
      if S.on and S.lock_identity and IDENTITY_LAYERS[layer] and not choice_kind(layer) then
        pcall(funcLuaMenuCommand, K.ZONE, layer, 0, false)   -- no pointer on the fixed identity
      end
    end,
  })

  -- a focus change: the guide's decide entry names the next crest / kit while one with choices has focus (the guide
  -- set again only when that changes)
  VRFW_Host.on(STEM, "OnChangeFocus", {
    id = "menu_engine.team_editor_foreign_identity_choices", phase = "after",
    fn = function()
      if not (S.on and S.tab and next(S.choices) ~= nil) then
        return
      end
      local focused = nil
      for layer in pairs(CHOICE_LAYERS) do
        local kind = choice_kind(layer)
        if kind then
          local ok, active = pcall(funcLuaMenuCommand, K.FOCUS_ACTIVE, layer)
          if ok and active == true then focused = kind end
        end
      end
      if focused ~= S.guide_kind then
        S.guide_kind = focused
        local guide = rawget(_ENV, "SetupButtonGuideText")
        if type(guide) == "function" then pcall(guide) end
      end
    end,
  })

  -- the team page's open ends with the team name bar (the retail Step opens it last, once the dock is up): from here
  -- L1 / R1 and back may close the dock
  VRFW_Host.on(STEM, "OnOpenEndLayer", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function(_, layer)
      if S.on and S.tab and not S.opened and layer == K.BAR then
        S.opened = true
        log("team page: dock open")
      end
    end,
  })

  -- back while the team page still opens: the dock stays (its close is asked again once it is open)
  VRFW_Host.on(STEM, "OnBack", {
    id = "menu_engine.team_editor_foreign", phase = "around", priority = -1000,
    fn = function(nxt, layer, ...)
      if S.on and S.tab and not S.opened then
        log("team page: back ignored while the dock still opens")
        return 1
      end
      return nxt(layer, ...)
    end,
  })

  VRFW_Host.on(STEM, "FuncOnBack", {
    id = "menu_engine.team_editor_foreign", phase = "after",
    fn = function()
      leave("dock closed")
    end,
  })

  VRFW_Host.on(STEM, "FinalizeMenu", {
    id = "menu_engine.team_editor_foreign", phase = "before", create = true,
    fn = function()
      leave("dock finalized")
    end,
  })
end
