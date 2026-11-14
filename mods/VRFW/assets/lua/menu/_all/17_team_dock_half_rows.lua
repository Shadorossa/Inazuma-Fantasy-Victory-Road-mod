-- lua_patch.scope: used
-- menu_engine: TEAM DOCK HALF ROWS, VRFW.team_dock.half_rows.
-- A mod adds rows to the list of the team dock; two cells declared as a pair share one row, each half as wide.
if VRFW.team_dock ~= nil and VRFW.team_dock.half_rows == nil then
  local STEM = "soccer_team_dock_menu"
  local K = {
    DOCK = 937147172,                -- soccer_team_dock_menu
    LIST = 3367997069,               -- team01_02_list_item
    LOCATOR = 2411076261,            -- team01_01_list_item_locator
    -- The slot joints of content/menus/team_dock_half_rows.toml, one per list instance.
    SLOTS = {
      4146892993,                    -- _atc_half_row_slot01
      1847968123,                    -- _atc_half_row_slot02
      421720557,                      -- _atc_half_row_slot03
      2269537358,                    -- _atc_half_row_slot04
      4030813400,                    -- _atc_half_row_slot05
      1766327650,                    -- _atc_half_row_slot06
      508507636,                     -- _atc_half_row_slot07
      2398103653,                    -- _atc_half_row_slot08
      4193720563,                    -- _atc_half_row_slot09
      2570096918,                    -- _atc_half_row_slot10
      3996623232,                    -- _atc_half_row_slot11
    },
    RETAIL_JOINTS = 9,               -- the retail row joints `_atc_list01..09`; the later slots hang from the last one
    ATLAS = 4262264508,              -- #/menu/102_team/team01/team01_02/team01_02.g4tx
    SWAP_SPRITE = 558735651,         -- (layer, atlas, sprite, retail sprite, 0, instance)
    -- Each plate: its mesh node, the retail sprite, the sprite of the left cell and of the right cell.
    PLATES = {
      {1525181930, 2257662053, 112794074, 2492874148},   -- The lit base sprites are _list_base01_on, list_base01_on, half_row_cell_left_on and half_row_cell_right_on.
      {4270801635, 2203362575, 3624543035, 1864716324},   -- _list_base01_off, list_base01_off, half_row_cell_left_off, half_row_cell_right_off
      {713202021, 4143695082, 1993600341, 3841771819},    -- _list_base01_ok, list_base01_ok, half_row_cell_left_ok, half_row_cell_right_ok
      {3034975430, 1755271497, 3904338166, 2056805512},   -- _list_base01_ol, list_base01_ol, half_row_cell_left_ol, half_row_cell_right_ol
    },
    ROW_LEFT = -97, ROW_WIDTH = 568, ROW_HEIGHT = 72, PITCH = 66,
    -- Cells (index 1 is left, 2 is right) in row units, where the sprites cut the full row: they span the full row's plate.
    -- The seam is centred on the row's part on screen (row x 0..456 at mid-height), so both cells show the same width.
    CELL_QUAD = 388,
    CELL_X = {-97, 83},
    CELL_SHOWN = {{-83, 222}, {234, 456}},
    SCREEN_X = 0,                    -- the row x of the screen's left edge (the slots' origin)
    ROW_GAP = 12,                    -- the rows' own spacing (pitch 66 - plate 54), also the seam's gap
    PLATE_SLANT = 1 / 6,
    ZONE_STRIPS = 9,
    TEXT_X = 47, CURSOR_X = -19,     -- the label's left edge and the cursor's left edge (instance units)
    TEXT_ON = 931545948,             -- The lit text layer is _text_list01_on.
    TEXT_OFF = 3705682548,           -- _text_list01_off
    GREYED_ALPHA = 0.5,
    MODEL_ALPHA = 4231609516,        -- CMND_SET_LAYER_MODEL_ALPHA (layer, instance, 0, alpha)
    TEXT_ALPHA = 1126837159,         -- CMND_SET_MENU_TEXT_ALPHA (layer, instance, text node, alpha)
    HIT_ZONE = 855005857,            -- (layer, instance, off): an instance's engine pointer zone
    PLAY_ANIME = 3781155141,         -- CMND_PLAY_ANIME_TYPE
    ACTIVE = 1286797620,             -- Active
    ANIME_OUT = 2,
    BUTTON_SET = 973515837,          -- button
    NODE_POSITION = 2575768773,      -- (layer, instance, node, axis 0 x / 1 y, value): node local translation
    NODE_SCALE = 2885415772,         -- (layer, instance, node, sx, sy): a mesh node's scale = its size
    LAYER_GLOBAL_POSITION = 4002164178,   -- (layer, instance) -> a layer instance's global x, y (screen px, y up)
    FOCUS_ACTIVE = 102308320,        -- (layer) -> the layer has the control focus
    FOCUS_INDEX = 2603265800,        -- (layer) -> focused instance
    FOCUS_SET = 3466097042,
    FOCUS_MARK = 1778826357,
    FOCUS_ENABLE = 3518307824,       -- CMND_SET_ENABLE_CTRL_FOCUS (layer, on)
    CURSOR_LOCATOR = 381797568,
    CURSOR = 3313461902,             -- cursor
    IS_OPEN_LAYER = 2640875187,      -- CMND_IS_OPEN_LAYER
    MENU_INPUT = 1558704558,         -- (menu, on)
    SUSPEND_GROUP = 369172623,       -- (group, 1): a child menu takes the dock's layer group
    RESUME_GROUP = 66378409,         -- (group, 1): the retail ResumeTeamDock
    FUNCTION_LEFT = 155578975,      -- team_dock_half_row_left, the CMD_FUNCTION of CMD_LEFT on the list
    ARGUMENT_RIGHT = 2682339866,     -- OnChangeFocus argument of CMD_RIGHT on the list
    TEXT_GET = 4074371074,           -- CMND_TEXT_GET
    SOUND = 1917805374,              -- CMND_SND_PLAY_SE
    SOUND_MOVE = 2500047763,         -- sy0005
    SOUND_ACCEPT = 3848881948,       -- sy0000
    SOUND_REFUSED = 2086672038,      -- sy0003
  }
  local HR = { groups = {}, by_id = {}, cells_by_kind = {}, next_kind = nil, hooked = {}, attached = false }
  --- Advanced: State of the half-height rows of the team dock list.
  VRFW.team_dock.half_rows = HR
  -- The state of the open dock: what is laid on screen and who has the focus.
  local S = { laid = {}, shift = {}, label_widths = {}, pointer = nil, decide = nil, logged = {} }

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("VRFW.team_dock.half_rows")
    logger(...)
  end

  local function log_once(key, ...)
    if not S.logged[key] then
      S.logged[key] = true
      log(...)
    end
  end

  -- The retail script's locals (VRFW.host).
  local function locals()
    local host = VRFW.host.hosts ~= nil and VRFW.host.hosts[STEM] or nil
    return host ~= nil and host.L or nil
  end

  local function menu(...)
    return VRFW.host.menu_command(...)
  end

  local function global(name)
    local value = rawget(_ENV, name)
    return type(value) == "function" and value or nil
  end

  -- Asks a rule of a group; a rule that fails is logged and answers nil.
  local function ask(group, rule, ...)
    local fn = group[rule]
    if type(fn) ~= "function" then
      return nil
    end
    local ok, answer = pcall(fn, ...)
    if not ok then
      log_once(group.id .. "." .. rule, "rule", rule, "of", group.id, "failed:", tostring(answer))
      return nil
    end
    return answer
  end

  --- Advanced: Declares rows of the team dock list; answers the group, or false, why.
  -- spec.id is "<Mod>.<name>"; spec.cells is a list of {name = text id, help = text id, label = function(cell) -> text, value = anything}.
  -- spec.place is "head", "end" (default) or {after = retail kind}; spec.pair = true puts its two cells on one row.
  -- spec.remove lists the retail kinds the group takes out; spec.when() says each time the dock opens whether the rows exist.
  -- A group with no cells and a spec.remove only takes those retail rows out while spec.when() holds.
  -- spec.greyed(cell) draws a cell greyed; spec.busy() blocks the cells' keys and pointer; spec.focused(cell) runs after a step onto a cell.
  -- spec.decide(cell) runs inside the dock's decide coroutine when the cell is accepted; without it the caller hooks OnDecideFocus itself.
  function HR.add(spec)
    if type(spec) ~= "table" or type(spec.id) ~= "string" then
      return false, "VRFW.team_dock.half_rows.add: an id is required"
    end
    spec.cells = spec.cells or {}
    if type(spec.cells) ~= "table" or (#spec.cells == 0 and (type(spec.remove) ~= "table" or #spec.remove == 0)) then
      return false, "VRFW.team_dock.half_rows.add: " .. spec.id .. ": at least one cell or one removed kind is required"
    end
    if spec.pair == true and #spec.cells ~= 2 then
      return false, "VRFW.team_dock.half_rows.add: " .. spec.id .. ": a pair has exactly two cells"
    end
    local group = HR.by_id[spec.id]
    if group == nil then
      group = { id = spec.id, cells = {} }
      HR.by_id[spec.id] = group
      HR.groups[#HR.groups + 1] = group
    end
    group.place, group.pair, group.remove = spec.place or "end", spec.pair == true, spec.remove or {}
    group.when, group.greyed, group.busy = spec.when, spec.greyed, spec.busy
    group.focused, group.decide = spec.focused, spec.decide
    for index, declared in ipairs(spec.cells) do
      local cell = group.cells[index] or { group = group, index = index }
      cell.name, cell.help, cell.label, cell.value = declared.name, declared.help, declared.label, declared.value
      group.cells[index] = cell
    end
    for index = #spec.cells + 1, #group.cells do
      group.cells[index] = nil
    end
    return group
  end

  --- Advanced: The cell of list kind `kind`; nil when the kind is no declared cell.
  function HR.cell_of_kind(kind)
    return HR.cells_by_kind[kind]
  end

  --- Internal: The cell at list instance `instance` (0-based); nil when that row is no declared cell.
  function HR.cell_at(instance)
    local L = locals()
    if L == nil or type(instance) ~= "number" or instance < 0 or instance >= (L.n or 0) then
      return nil
    end
    return HR.cells_by_kind[L.t[instance + 1]]
  end

  --- Internal: The text a cell shows.
  function HR.cell_text(cell)
    local text = nil
    if type(cell.label) == "function" then
      local ok, answer = pcall(cell.label, cell)
      text = ok and answer or nil
    end
    if type(text) ~= "string" and type(cell.name) == "number" then
      text = VRFW.host.command(K.TEXT_GET, cell.name)
    end
    return type(text) == "string" and text or ""
  end

  -- Writes the declared rows into the retail kind list and its text table (the list is set up).
  local function apply()
    local L = locals()
    if L == nil or type(L.t) ~= "table" or type(L.t2) ~= "table" then
      log_once("locals", "the list locals of the dock are not served: no rows added")
      return
    end
    local list, texts = L.t, L.t2
    if S.list ~= list then
      S.list, S.retail_kinds = list, {}
      for index, kind in ipairs(list) do
        S.retail_kinds[index] = kind
      end
    end
    if HR.next_kind == nil then
      local free = 0
      for key in pairs(texts) do
        if type(key) == "number" and key > free then
          free = key
        end
      end
      for _, kind in ipairs(list) do
        free = math.max(free, kind + 1)
      end
      HR.next_kind = free
    end
    local removed, head, tail, after = {}, {}, {}, {}
    for _, group in ipairs(HR.groups) do
      group.on = group.when == nil or ask(group, "when") == true
      group.last_side = 1
      if group.on then
        for _, kind in ipairs(group.remove) do
          removed[kind] = true
        end
        local target = tail
        if group.place == "head" then
          target = head
        elseif type(group.place) == "table" and group.place.after ~= nil then
          after[group.place.after] = after[group.place.after] or {}
          target = after[group.place.after]
        end
        for _, cell in ipairs(group.cells) do
          if cell.kind == nil then
            cell.kind = HR.next_kind
            HR.next_kind = HR.next_kind + 1
            HR.cells_by_kind[cell.kind] = cell
          end
          texts[cell.kind + 1] = { itemName = cell.name or 0, itemExplation = cell.help or 0 }
          target[#target + 1] = cell.kind
        end
      end
    end
    local rows = {}
    for _, kind in ipairs(head) do
      rows[#rows + 1] = kind
    end
    for _, kind in ipairs(S.retail_kinds) do
      if not removed[kind] then
        rows[#rows + 1] = kind
        for _, added in ipairs(after[kind] or {}) do
          rows[#rows + 1] = added
        end
        after[kind] = nil
      end
    end
    for _, kinds in pairs(after) do
      for _, kind in ipairs(kinds) do
        tail[#tail + 1] = kind
      end
    end
    for _, kind in ipairs(tail) do
      rows[#rows + 1] = kind
    end
    for index = #list, 1, -1 do
      list[index] = nil
    end
    for index, kind in ipairs(rows) do
      list[index] = kind
    end
    log("rows", table.concat(rows, " "))
  end

  -- The pairs the list shows now: instance -> {left = left instance, side = 1 | 2, cell = cell}.
  local function shown_pairs()
    local found = {}
    local L = locals()
    if L == nil then
      return found
    end
    local count = math.min(L.n or 0, #K.SLOTS)
    for instance = 0, count - 2 do
      local cell = HR.cells_by_kind[L.t[instance + 1]]
      local other = HR.cells_by_kind[L.t[instance + 2]]
      if cell ~= nil and other ~= nil and cell.group == other.group and cell.group.pair and cell.index == 1 and other.index == 2 then
        found[instance] = { left = instance, side = 1, cell = cell }
        found[instance + 1] = { left = instance, side = 2, cell = other }
      end
    end
    return found
  end

  -- The laid cell at `instance`, when the list still shows that pair there.
  local function laid_cell(instance)
    local laid = type(instance) == "number" and S.laid[instance] or nil
    if laid == nil then
      return nil
    end
    local now = shown_pairs()[instance]
    return now ~= nil and now.left == laid.left and laid or nil
  end

  local function any_laid()
    return next(S.laid) ~= nil
  end

  --- Internal: True while a caller's rule or a decide of the pointer keeps the cells from moving.
  function HR.blocked()
    if S.decide ~= nil then
      return true
    end
    for _, group in ipairs(HR.groups) do
      if group.on and ask(group, "busy") == true then
        return true
      end
    end
    return false
  end

  --- Advanced: True while the pointer's click on a cell runs its decide.
  function HR.deciding()
    return S.decide ~= nil
  end

  -- Keeps the Active animation of the cells at its end, so a cell never plays the full row's highlight.
  local function hold_cells()
    if HR.hooked.cells then
      return
    end
    --- Internal: true once the cell animation hook is installed.
    HR.hooked.cells = true
    VRFW.host.hook_command(K.PLAY_ANIME, function(nxt, id, layer, index, kind, mode, ...)
      if layer == K.LIST and S.laid[index] ~= nil and kind == K.ACTIVE and mode ~= K.ANIME_OUT then
        return nxt(id, layer, index, kind, K.ANIME_OUT, ...)
      end
      return nxt(id, layer, index, kind, mode, ...)
    end, "VRFW.team_dock_half_rows_still", {menu = true})
  end

  -- Watches every retail open of a child menu, which suspends the dock's layer group until ResumeTeamDock gives it back; Step goes on meanwhile, so this state says the cells are not on screen.
  local function watch_suspend()
    if HR.hooked.suspend then
      return
    end
    --- Internal: true once the suspend and resume hook is installed.
    HR.hooked.suspend = true
    VRFW.host.hook_command({K.SUSPEND_GROUP, K.RESUME_GROUP}, function(nxt, id, group, ...)
      if group == K.DOCK then
        S.suspended = id == K.SUSPEND_GROUP
      end
      return nxt(id, group, ...)
    end, "VRFW.team_dock_half_rows_suspended", {menu = true})
  end

  -- Returns a label's width in row units.
  local function label_width(instance, text)
    if S.label_widths[text] ~= nil then
      return S.label_widths[text]
    end
    local width = VRFW.text_fold.measure(K.LIST, instance, K.TEXT_ON, text)
    if width == nil then
      width = 0
      for position = 1, #text do
        local byte = text:byte(position)
        if byte < 0x80 or (byte >= 0xC0 and byte < 0xE0) then
          width = width + 19
        elseif byte >= 0xE0 then
          width = width + 34
        end
      end
    end
    S.label_widths[text] = width
    return width
  end

  -- Returns the slot x of a cell, which centres its label on the cell's part on screen and keeps the cursor inside the slanted edge.
  local function cell_shift(found, instance)
    local shown = K.CELL_SHOWN[found.side]
    local left, right = math.max(shown[1], K.SCREEN_X), shown[2]
    local width = label_width(instance, HR.cell_text(found.cell))
    local x = (left + right) / 2 - width / 2 - K.TEXT_X
    return math.max(x, left - K.CURSOR_X)
  end

  -- Returns row x `row_x` in the units of the cell's own instance (the plates and the pointer zones are both placed with it).
  local function on_cell(instance, row_x)
    return row_x - (S.shift[instance] or 0)
  end

  -- Switches the engine's own pointer zones of the cells.
  local function cell_zones(cells_on)
    for instance in pairs(S.laid) do
      menu(K.HIT_ZONE, K.LIST, instance, not cells_on)
    end
  end

  -- Draws one instance as a cell of a pair, or as the retail full row.
  local function draw_plates(instance, found)
    local left, width = K.ROW_LEFT, K.ROW_WIDTH
    if found ~= nil then
      left, width = on_cell(instance, K.CELL_X[found.side]), K.CELL_QUAD
      menu(K.PLAY_ANIME, K.LIST, instance, K.ACTIVE, K.ANIME_OUT, K.BUTTON_SET)
    end
    for _, plate in ipairs(K.PLATES) do
      local sprite = found ~= nil and plate[2 + found.side] or plate[2]
      local drawn = menu(K.SWAP_SPRITE, K.LIST, K.ATLAS, sprite, plate[2], 0, instance)
      if drawn == false then
        log_once("sprite", "plate sprite not drawn", instance, tostring(drawn))
      end
      menu(K.NODE_POSITION, K.LIST, instance, plate[1], 0, left)
      menu(K.NODE_SCALE, K.LIST, instance, plate[1], width, K.ROW_HEIGHT)
    end
  end

  -- Places every slot joint and draws the cells of the shown pairs; rows that stopped being cells go back to the retail row.
  local function layout()
    local L = locals()
    if L == nil then
      return
    end
    local found = shown_pairs()
    local some = next(found) ~= nil
    if not some and not any_laid() and (L.n or 0) <= K.RETAIL_JOINTS then
      return
    end
    if some then
      hold_cells()
    end
    S.shift = {}
    for instance, cell in pairs(found) do
      S.shift[instance] = cell_shift(cell, instance)
    end
    local row = 0
    for slot = 1, #K.SLOTS do
      local instance = slot - 1
      local here = found[instance]
      if here ~= nil and here.side == 2 then
        row = row - 1
      end
      local joint_row = math.min(instance, K.RETAIL_JOINTS - 1)
      local wrote = menu(K.NODE_POSITION, K.LOCATOR, 0, K.SLOTS[slot], 0, S.shift[instance] or 0)
      menu(K.NODE_POSITION, K.LOCATOR, 0, K.SLOTS[slot], 1, K.PITCH * (joint_row - row))
      if wrote == false then
        log_once("slot", "slot joint not written (layout without the half row slots?)", slot, tostring(wrote))
      end
      row = row + 1
    end
    for instance in pairs(S.laid) do
      if found[instance] == nil then
        menu(K.HIT_ZONE, K.LIST, instance, true)
        draw_plates(instance, nil)
      end
    end
    local was = any_laid()
    S.laid = found
    cell_zones(true)
    for instance, cell in pairs(found) do
      draw_plates(instance, cell)
    end
    if some ~= was then
      local places = {}
      for instance, cell in pairs(found) do
        places[#places + 1] = instance .. "=" .. math.floor(S.shift[instance] + 0.5) .. (cell.side == 1 and "L" or "R")
      end
      table.sort(places)
      log("half rows", some and "on" or "off", "rows", L.n, "cells", table.concat(places, " "))
    end
  end

  -- Draws greyed every declared row whose group says so.
  local function grey_rows()
    local L = locals()
    if L == nil then
      return
    end
    for instance = 0, (L.n or 0) - 1 do
      local cell = HR.cells_by_kind[L.t[instance + 1]]
      if cell ~= nil and ask(cell.group, "greyed", cell) == true then
        menu(K.MODEL_ALPHA, K.LIST, instance, 0, K.GREYED_ALPHA)
        menu(K.TEXT_ALPHA, K.LIST, instance, K.TEXT_ON, K.GREYED_ALPHA)
        menu(K.TEXT_ALPHA, K.LIST, instance, K.TEXT_OFF, K.GREYED_ALPHA)
      end
    end
  end

  local function list_index()
    local index = menu(K.FOCUS_INDEX, K.LIST)
    return index or nil
  end

  local function list_active()
    return menu(K.FOCUS_ACTIVE, K.LIST) == true
  end

  local function pointer()
    if S.pointer == nil and VRFW.pointer ~= nil then
      S.pointer = VRFW.pointer.new()
      S.pointer.reset()
    end
    if S.pointer == nil then
      log_once("pointer", "VRFW.pointer is not loaded in this script: the cells take no pointer")
    end
    return S.pointer
  end

  -- Gives the list the control focus, the way the dock moves it between its layers.
  local function take_focus(to)
    if list_active() then
      return
    end
    local L = locals()
    local from = L ~= nil and L.n6 or nil
    local shift = global("OnFocusLayerShift")
    if type(from) ~= "number" or from == 0 or from == K.LIST or shift == nil then
      menu(K.FOCUS_ENABLE, K.LIST, true)
      return
    end
    local from_index = menu(K.FOCUS_INDEX, from)
    if type(from_index) ~= "number" then
      from_index = 0
    end
    pcall(shift, from, from_index, K.LIST, to)
    if not list_active() then
      menu(K.FOCUS_ENABLE, from, false)
      menu(K.FOCUS_ENABLE, K.LIST, true)
    end
  end

  -- Remembers the side of a pair the focus last had, for the way back from a neighbour row.
  local function remember(instance)
    local laid = type(instance) == "number" and S.laid[instance] or nil
    if laid ~= nil then
      laid.cell.group.last_side = laid.side
    end
  end

  --- Internal: Moves the list's focus onto instance `to`, as the engine's own step does; `quiet` leaves the pointer and the sound alone.
  function HR.step_to(to, quiet)
    local L = locals()
    local mouse = pointer()
    if not quiet and mouse ~= nil then
      mouse.key_step()
    end
    if list_index() == to and list_active() then
      return
    end
    S.stepping, S.echo = true, false
    take_focus(to)
    menu(K.CURSOR_LOCATOR, K.LIST, K.CURSOR, to, L ~= nil and L.n or 0)
    menu(K.FOCUS_MARK, K.LIST, to, true)
    if list_index() ~= to then
      menu(K.FOCUS_SET, K.LIST, to)
    end
    local changed = global("OnChangeFocus")
    if not S.echo and changed ~= nil then
      pcall(changed, K.LIST, to)
    end
    S.stepping = false
    remember(to)
    local laid = S.laid[to]
    if laid ~= nil then
      ask(laid.cell.group, "focused", laid.cell)
    end
    if not quiet then
      funcLuaCommand(K.SOUND, K.SOUND_MOVE)
    end
  end

  -- The instance a step onto row instance `to` lands on: the last focused side when that row is a pair.
  local function landing(to)
    local laid = laid_cell(to)
    if laid == nil then
      return to
    end
    return laid.left + (laid.cell.group.last_side or 1) - 1
  end

  -- Handles up (-1) and down (1) around the pairs; answers true when the key is taken.
  local function vertical_key(direction)
    if not any_laid() or not list_active() or HR.blocked() then
      return false
    end
    local L = locals()
    local index = list_index()
    if L == nil or type(index) ~= "number" then
      return false
    end
    local here = laid_cell(index)
    if here ~= nil then
      local to = direction > 0 and here.left + 2 or here.left - 1
      if to >= 0 and to < (L.n or 0) then
        HR.step_to(landing(to))
      end
      return true
    end
    local to = index + direction
    if laid_cell(to) ~= nil then
      HR.step_to(landing(to))
      return true
    end
    return false
  end

  -- Returns where a pair is on screen: the scale and the global position of its two instances.
  local function pair_on_screen(left)
    local left_x, left_y = menu(K.LAYER_GLOBAL_POSITION, K.LIST, left)
    local right_x, right_y = menu(K.LAYER_GLOBAL_POSITION, K.LIST, left + 1)
    if type(left_x) ~= "number" or type(left_y) ~= "number" or type(right_x) ~= "number" or type(right_y) ~= "number" then
      return nil
    end
    local apart = (S.shift[left + 1] or 0) - (S.shift[left] or 0)
    local scale = apart ~= 0 and (right_x - left_x) / apart or 0
    if scale < 0.05 or scale > 20 then
      return nil
    end
    return { scale = scale, x = { left_x, right_x }, y = { left_y, right_y } }
  end

  -- Runs the dock's accept of a cell for the pointer: OnEnter with its refusals, then the decide sound and OnDecideFocus in a coroutine.
  local function pointer_decide(instance)
    HR.step_to(instance, true)
    local enter, decide = global("OnEnter"), global("OnDecideFocus")
    if enter == nil or decide == nil then
      return
    end
    S.pointer_accept = true
    local ok, refused = pcall(enter, K.LIST, instance)
    S.pointer_accept = false
    if not ok then
      log("cell click: OnEnter error", tostring(refused))
      return
    end
    if refused == 1 then
      return
    end
    funcLuaCommand(K.SOUND, K.SOUND_ACCEPT)
    S.decide = coroutine.create(function()
      decide(K.LIST, instance)
    end)
  end

  -- Steps the cells' pointer zones: a hover moves the focus, a click accepts the cell.
  local function pointer_step()
    if not any_laid() or S.child or S.suspended or HR.blocked() then
      return
    end
    local mouse = pointer()
    if mouse == nil then
      return
    end
    local height = K.PITCH - K.ROW_GAP
    local strip = height / K.ZONE_STRIPS
    local zones = 0
    mouse.begin()
    for instance, laid in pairs(S.laid) do
      local place = laid.side == 1 and laid_cell(instance) ~= nil and pair_on_screen(instance) or nil
      if place ~= nil then
        for side = 1, 2 do
          local cell_instance = instance + side - 1
          local shown = K.CELL_SHOWN[side]
          local left, right = on_cell(cell_instance, shown[1]), on_cell(cell_instance, shown[2])
          for index = 0, K.ZONE_STRIPS - 1 do
            local top = height / 2 - index * strip
            local slant = (top - strip / 2) * K.PLATE_SLANT
            mouse.rect(place.x[side] + (left + slant) * place.scale, -place.y[side] - top * place.scale,
              (right - left) * place.scale, strip * place.scale, cell_instance)
            zones = zones + 1
          end
        end
      end
    end
    if zones == 0 then
      return
    end
    local event = mouse.poll()
    if event.click ~= nil then
      pointer_decide(event.click)
    elseif event.hover ~= nil and (event.hover ~= list_index() or not list_active()) then
      HR.step_to(event.hover, true)
    end
  end

  -- Resumes the decide the pointer started.
  local function decide_step()
    if S.decide == nil then
      return
    end
    local ok, problem = coroutine.resume(S.decide)
    if not ok then
      log("cell click: decide error", tostring(problem))
      menu(K.MENU_INPUT, K.DOCK, true)
    end
    if not ok or coroutine.status(S.decide) == "dead" then
      S.decide = nil
    end
  end

  --- Internal: True when the accept press on that list instance belongs to the pointer's own click on a cell.
  function HR.pointer_owns_accept(layer, index)
    if S.pointer_accept or layer ~= K.LIST or S.laid[index] == nil or S.pointer == nil then
      return false
    end
    return S.pointer.owns()
  end

  --- Internal: Hooks the team dock; called once from the dock's own Lua folder.
  function HR.attach()
    if HR.attached then
      return
    end
    --- Internal: true once the dock hooks are attached.
    HR.attached = true
    local function on(point, phase, fn, create)
      VRFW.host.on(STEM, point, { id = "VRFW.team_dock_half_rows", phase = phase, fn = fn, create = create })
    end

    on("OnInit", "before", function()
      S.laid, S.shift, S.label_widths, S.pointer, S.decide = {}, {}, {}, nil, nil
      S.child, S.suspended, S.stepping, S.pointer_accept = false, false, false, false
      watch_suspend()
    end)

    -- The rows are written when the list is set up, after every mod's OnInit said what the dock is.
    on("OnSetupLayer", "before", function(layer, instance)
      if layer == K.LIST and instance == 0 then
        apply()
      end
    end)

    on("OnOpenLayer", "after", function(_, layer, instance)
      if layer == K.LOCATOR or (layer == K.LIST and (instance == 0 or shown_pairs()[instance] ~= nil)) then
        layout()
      end
    end)

    on("SetupTeamDockListItemText", "around", function(retail, instance, kind, ...)
      local cell = HR.cells_by_kind[kind]
      local write = global("SetTeamDockListItemText")
      if cell ~= nil and write ~= nil and cell.label ~= nil then
        write(instance, HR.cell_text(cell))
        return
      end
      return retail(instance, kind, ...)
    end)

    on("UpdateViewTeamDockListItem", "after", function(_, instance)
      grey_rows()
      if S.laid[instance] ~= nil or shown_pairs()[instance] ~= nil then
        layout()
      end
    end)

    -- The retail turns every list row's pointer zone on here, after each list redraw.
    on("UpdateViewMenuByLock", "after", function()
      cell_zones(true)
      grey_rows()
    end)

    on("MoveFocusInc", "around", function(retail, argument, layer, ...)
      if layer == K.LIST and vertical_key(1) then
        return 1
      end
      return retail(argument, layer, ...)
    end)

    on("MoveFocusDec", "around", function(retail, argument, layer, ...)
      if layer == K.LIST and vertical_key(-1) then
        return 1
      end
      return retail(argument, layer, ...)
    end, true)

    -- Retail RIGHT on a list row measures the list's own instances first, so the cell to the right of the rows wins the cone and MoveToOtherLayer then moves the control focus without drawing the target; the list's instances are no candidates while it looks for another layer.
    on("MoveToOtherLayer", "around", function(retail, direction, from, index, to, ...)
      if not (any_laid() and from == K.LIST and to ~= K.LIST) then
        return retail(direction, from, index, to, ...)
      end
      return VRFW.host.with_commands({ menu = { [K.IS_OPEN_LAYER] = function(command, id, layer, ...)
        if layer == K.LIST then
          return false
        end
        return command(id, layer, ...)
      end } }, retail, direction, from, index, to, ...)
    end)

    on("OnChangeFocus", "around", function(retail, layer, index, ...)
      if layer == K.LIST and S.stepping then
        S.echo = true
        return retail(layer, index, ...)
      end
      if layer == K.LIST and index == K.ARGUMENT_RIGHT and any_laid() and list_active() and not HR.blocked() then
        local here = laid_cell(list_index())
        if here ~= nil and here.side == 1 then
          HR.step_to(here.left + 1)
          return
        end
      end
      local results = table.pack(retail(layer, index, ...))
      local L = locals()
      if any_laid() and L ~= nil and (L.n6 == 0 or L.n6 == K.LIST) then
        remember(list_index())
      end
      return table.unpack(results, 1, results.n)
    end)

    on("Step", "after", function()
      pointer_step()
      decide_step()
    end)

    on("OnEnter", "around", function(retail, layer, index, ...)
      if HR.pointer_owns_accept(layer, index) then
        return 1
      end
      local cell = layer == K.LIST and HR.cell_at(index) or nil
      if cell ~= nil and cell.group.decide ~= nil and (HR.blocked() or ask(cell.group, "greyed", cell) == true) then
        funcLuaCommand(K.SOUND, K.SOUND_REFUSED)
        return 1
      end
      return retail(layer, index, ...)
    end)

    -- The dock waits for a child menu or a caller's decide here: Step reads no pointer meanwhile.
    on("OnDecideFocus", "around", function(retail, layer, index, ...)
      local cell = layer == K.LIST and HR.cell_at(index) or nil
      S.child = true
      local results
      if cell ~= nil and cell.group.decide ~= nil then
        results = table.pack(pcall(cell.group.decide, cell))
        menu(K.MENU_INPUT, K.DOCK, true)
        menu(K.FOCUS_ENABLE, K.LIST, true)
      else
        results = table.pack(pcall(retail, layer, index, ...))
      end
      S.child = false
      if not results[1] then
        error(results[2], 0)
      end
      return table.unpack(results, 2, results.n)
    end)

    on("OnFunction", "around", function(retail, id, ...)
      if id ~= K.FUNCTION_LEFT then
        return retail(id, ...)
      end
      if any_laid() and list_active() and not HR.blocked() then
        local here = laid_cell(list_index())
        if here ~= nil and here.side == 2 then
          HR.step_to(here.left)
        end
      end
    end)
  end
end
