-- menu_engine: LIST ROWS, VRFW.ListRows.
if VRFW.list_rows == nil then
  local R = {
    menus = {},                       -- menu name -> declaration (adapter data)
    rules = {},
    SUBWINDOW_CALLBACK_PREFIX = "vrfw_list_rows_pick_",
    SUBWINDOW_FOCUS_PREFIX = "vrfw_list_rows_focus_",
    PLAYER_COMMAND = {
      MOVE = 0,                       -- Move (swap the player on the field)
      EQUIPMENT = 1,                  -- Equipment (equip_menu)
      RARITY_UP = 2,                  -- Upgrade (soccer_spirit_menu: rarity up)
      CAPTAIN = 3,
      VIEW_MODEL = 4,                 -- the 3D model view
      SKILL_TABLE = 5,                -- Skill Table (ability_learning_board_menu)
      SHIRT_NUMBER = 6,
      AI_ROLE = 7,
      BUILD = 8,                      -- build change (OpenSubWinChangeBuild)
      INHERITED_PASSIVES = 9,         -- Inherited Passives (soccer_passsive_inherit_menu)
      CLEAR_INHERITED_PASSIVE = 10,
      AVATAR_RARITY = 11,             -- avatar rarity change (OpenSubWinChangeAvatarRarity)
    },
    -- retail rows of the formation's team COMANDOS window (CallbackCloseCondTeamCommandSubWin cases)
    TEAM_COMMAND = {
      AUTO_EQUIP = 0,                 -- Auto-Equip Team
      REMOVE_EQUIPMENT = 1,           -- Remove Equipment
      EQUIP_BEANS = 2,
      REMOVE_BEANS = 3,
      GOAL_CELEBRATION = 4,
      AUTO_EQUIP_BEANS = 5,
    },
    PLAYER_COMMANDS = "team_dock.player_commands",
    TEAM_COMMANDS = "formation.team_commands",
    PLAY_GUIDE = "play_guide.rows",   -- the row kinds of play_guide_top_menu (the retail chunk's list local t)
  }
  --- Advanced: Namespace: the declared list rows of menus and their sub window hooks.
  VRFW.list_rows = R

  local logger
  --- Internal: Logs through the list-rows logger.
  function R.log(...)
    logger = logger or VRFW.logger.new("vrfw.ListRows")
    logger(...)
  end

  local function rules_of(menu)
    local r = R.rules[menu]
    if r == nil then
      r = {hide = {}, add = {}, handle = {}, order = {}}
      R.rules[menu] = r
    end
    return r
  end

  local function put(list, spec)
    for i, x in ipairs(list) do
      if x.id == spec.id then
        list[i] = spec
        return spec
      end
    end
    list[#list + 1] = spec
    return spec
  end

  local function refuse(why)
    VRFW.host.note("list_rows", why)
    return false, why
  end

  local function check(menu, spec, what, needs_run)
    if what == "Order" then
      if type(menu) ~= "string" or type(spec) ~= "table" or type(spec.id) ~= "string"
        or (type(spec.rows) ~= "table" and type(spec.last) ~= "table") then
        return "VRFW.list_rows.Order(menu, {id = \"<mod>.<name>\", rows = {<row id>, ...}, last = {<row id>, ...}}) expected"
      end
      return
    end
    if type(menu) ~= "string" or type(spec) ~= "table" or type(spec.id) ~= "string" or type(spec.row) ~= "number" then
      return "VRFW.list_rows." .. what .. "(menu, {id = \"<mod>.<name>\", row = <number>, ...}) expected"
    end
    if needs_run and type(spec.run) ~= "function" then
      return "VRFW.list_rows." .. what .. ": " .. spec.id .. ": run = function(context) expected"
    end
  end

  --- Advanced: Hides a retail row of `menu`; answers the rule, or false, why.
  function R.hide(menu, spec)
    local why = check(menu, spec, "Hide", false)
    if why ~= nil then
      return refuse(why)
    end
    return put(rules_of(menu).hide, spec)
  end

  --- Advanced: Adds a row to `menu`; answers the rule, or false, why.
  function R.add(menu, spec)
    local why = check(menu, spec, "Add", true)
    if why ~= nil then
      return refuse(why)
    end
    if type(spec.text) ~= "number" then
      return refuse("VRFW.list_rows.Add: " .. spec.id .. ": text = <text id> expected")
    end
    return put(rules_of(menu).add, spec)
  end

  --- Advanced: Takes over a retail row of `menu`; answers the rule, or false, why.
  function R.handle(menu, spec)
    local why = check(menu, spec, "Handle", true)
    if why ~= nil then
      return refuse(why)
    end
    return put(rules_of(menu).handle, spec)
  end

  --- Advanced: Orders the rows of `menu`; answers the rule, or false, why.
  function R.order(menu, spec)
    local why = check(menu, spec, "Order", false)
    if why ~= nil then
      return refuse(why)
    end
    return put(rules_of(menu).order, spec)
  end

  --- Internal: True when `spec` applies in `context`.
  function R.applies(spec, context)
    if spec.when == nil then
      return true
    end
    local ok, result = pcall(spec.when, context)
    if not ok then
      if not spec.logged then
        spec.logged = true
        R.log(spec.id, "when failed", tostring(result))
      end
      return false
    end
    return result == true
  end

  --- Internal: The added rule of a row id (nil = a retail row).
  function R.added_row(menu, row)
    for _, spec in ipairs(rules_of(menu).add) do
      if spec.row == row then
        return spec
      end
    end
    return nil
  end

  --- Internal: The rule that takes `row` in `context`; nil when there is none.
  function R.taker(menu, row, context)
    local added = R.added_row(menu, row)
    if added ~= nil then
      return added
    end
    local taker
    for _, spec in ipairs(rules_of(menu).handle) do
      if spec.row == row and R.applies(spec, context) then
        if taker == nil then
          taker = spec
        elseif not spec.clash_logged then
          spec.clash_logged = true
          R.log(menu, "row", row, "claimed by", taker.id, "and", spec.id, "(the first registered runs)")
        end
      end
    end
    return taker
  end

  --- Internal: The order rule in force for `context`; nil when there is none.
  function R.order_rule(menu, context)
    local rules = rules_of(menu)
    local winner
    for i = #rules.order, 1, -1 do
      local spec = rules.order[i]
      if winner == nil then
        if R.applies(spec, context) then
          winner = spec
        end
      elseif not spec.overridden_logged and R.applies(spec, context) then
        spec.overridden_logged = true
        R.log(menu, "order", spec.id, "ignored:", winner.id, "registered later wins")
      end
    end
    return winner
  end

  --- Internal: Sorts `rows` by order_rule: its `rows` first, its `last` at the end, the others between in their order.
  function R.sort(rows, order_rule)
    local rank, tail = {}, {}
    for i, row in ipairs(order_rule.rows or {}) do
      if rank[row] == nil then
        rank[row] = i
      end
    end
    for i, row in ipairs(order_rule.last or {}) do
      if rank[row] == nil and tail[row] == nil then
        tail[row] = i
      end
    end
    local first, rest, final = {}, {}, {}
    for _, row in ipairs(rows) do
      if rank[row] ~= nil then
        first[#first + 1] = row
      elseif tail[row] ~= nil then
        final[#final + 1] = row
      else
        rest[#rest + 1] = row
      end
    end
    table.sort(first, function(a, b) return rank[a] < rank[b] end)
    table.sort(final, function(a, b) return tail[a] < tail[b] end)
    for _, row in ipairs(rest) do
      first[#first + 1] = row
    end
    for _, row in ipairs(final) do
      first[#first + 1] = row
    end
    return first
  end

  --- Internal: The rows of `menu` after its rules; answers the list.
  function R.apply(menu, retail_rows, context)
    local rules = rules_of(menu)
    local hidden = {}
    for _, spec in ipairs(rules.hide) do
      if hidden[spec.row] == nil and R.applies(spec, context) then
        hidden[spec.row] = true
      end
    end
    local out = {}
    for _, row in ipairs(retail_rows) do
      if not hidden[row] then
        out[#out + 1] = row
      end
    end
    for _, spec in ipairs(rules.add) do
      if not hidden[spec.row] and R.applies(spec, context) then
        local at = #out + 1
        if spec.after ~= nil then
          for i, row in ipairs(out) do
            if row == spec.after then
              at = i + 1
              break
            end
          end
        end
        table.insert(out, at, spec.row)
      end
    end
    local order_rule = R.order_rule(menu, context)
    if order_rule ~= nil then
      out = R.sort(out, order_rule)
    end
    return out
  end

  --- Internal: True when `spec` is enabled in `context`.
  function R.enabled(spec, context)
    if spec.enabled == nil then
      return true
    end
    local ok, result = pcall(spec.enabled, context)
    return ok and result ~= false
  end

  --- Internal: Declares a sub-window menu; answers the declaration.
  function R.declare_sub_window(menu, declaration)
    declaration.name = menu
    declaration.sub_window = true
    R.menus[menu] = declaration
    --- Internal: lookup of declarations by callback name, rebuilt on demand.
    R.by_callback = nil
    R.install_sub_window_callbacks(declaration)
    R.wrap_sub_window()
    R.wrap_opener(declaration)
    return declaration
  end

  -- Internal: argument positions of MENU_DEF.OpenSubWindow (after the two callbacks) that hold one value per row
  R.PER_ROW_ARGUMENTS = {2, 5, 11, 13, 14, 16}   -- texts, grey, icons, t15, t16, checks (positions in `...`)
  R.COUNT_ARGUMENT, R.SIZE_ARGUMENT, R.FOCUS_ARGUMENT, R.KIND_ARGUMENT = 1, 3, 6, 9

  local function declaration_of_callback(callback, kind)
    if R.by_callback == nil then
      R.by_callback = {}
      for _, d in pairs(R.menus) do
        if d.sub_window and d.callback ~= nil then
          R.by_callback[d.callback] = d
        end
      end
    end
    local d = R.by_callback[callback]
    if d ~= nil and (d.kind == nil or d.kind == kind) then
      return d
    end
    return nil
  end

  local function has_rules(menu)
    local r = R.rules[menu]
    return r ~= nil and (#r.hide > 0 or #r.add > 0 or #r.handle > 0 or #r.order > 0)
  end

  -- the window of a declared menu: rows filtered / added, per-row tables rebuilt, the mod's callbacks.
  local function rebuild_sub_window(d, callback, focus_callback, arguments)
    local count = arguments[R.COUNT_ARGUMENT]
    if type(count) ~= "number" or count < 1 then
      return nil
    end
    local context = {menu = d.name}
    local retail_rows = {}
    for i = 0, count - 1 do
      retail_rows[#retail_rows + 1] = i
    end
    local rows = R.apply(d.name, retail_rows, context)
    local position_of = {}
    for position, row in ipairs(rows) do
      position_of[row] = position - 1
    end
    local out = {}
    for k = 1, arguments.n do
      out[k] = arguments[k]
    end
    out.n = arguments.n
    for _, k in ipairs(R.PER_ROW_ARGUMENTS) do
      local source = arguments[k]
      if type(source) == "table" and #source > 0 then
        local rebuilt = {}
        for position, row in ipairs(rows) do
          local added = R.added_row(d.name, row)
          if added == nil then
            rebuilt[position] = source[row + 1]
          elseif k == 2 then
            rebuilt[position] = added.text
          elseif k == 5 then
            local enabled = R.enabled(added, {menu = d.name, row = row})
            -- a window whose retail rows are all grey (an empty team) greys the added rows too
            local any_enabled = false
            for i = 1, #source do
              any_enabled = any_enabled or source[i] ~= 0
            end
            if not any_enabled then
              enabled = false
            end
            rebuilt[position] = enabled and 1 or 0
          else
            rebuilt[position] = 0
          end
        end
        out[k] = rebuilt
      end
    end
    out[R.COUNT_ARGUMENT] = #rows
    local shown = math.min(#rows, d.rows_shown or #rows)
    if #rows ~= count and type(d.size_by_rows) == "table" and d.size_by_rows[shown] ~= nil then
      out[R.SIZE_ARGUMENT] = d.size_by_rows[shown]
    end
    local retail_focus = arguments[R.FOCUS_ARGUMENT]
    local focus_row = retail_focus
    if d.last_added ~= nil and d.forwarded_to == retail_focus and position_of[d.last_added] ~= nil then
      focus_row = d.last_added
    end
    out[R.FOCUS_ARGUMENT] = position_of[focus_row] or 0
    d.open = {rows = rows, position_of = position_of, callback = callback, focus_callback = focus_callback,
      focus_row = focus_row}
    return out
  end

  --- Internal: Wraps the opener so checkbox rows start with their state.
  function R.fix_checkboxes(d)
    local open = d.open
    if open == nil or d.checkbox_rows == nil then
      return
    end
    for row, checked in pairs(d.checkbox_rows) do
      local shown_there = open.rows[row + 1]
      if shown_there ~= nil and shown_there ~= row then
        pcall(funcLuaCommand, 628044124 --[[checkbox state]], row, false)
      end
    end
    for row, checked in pairs(d.checkbox_rows) do
      local position = open.position_of[row]
      if position ~= nil and position ~= row then
        local ok, value = pcall(checked)
        pcall(funcLuaCommand, 628044124 --[[checkbox state]], position, ok and value == true)
      end
    end
  end

  --- Internal: After the declared opener ran: the list focus (set by retail position) and the checkbox states.
  function R.fix_sub_window_positions(d)
    local open = d.open
    if open == nil then
      return
    end
    if d.list_locator ~= nil and open.position_of[open.focus_row] ~= nil then
      pcall(funcLuaCommand, 3647847018 --[[list focus]], open.position_of[open.focus_row], d.list_locator)
    end
    R.fix_checkboxes(d)
  end

  --- Internal: The window's pick: the position -> the retail row id; an added row / a taken-over row runs its rule.
  function R.pick_sub_window(menu, position, ...)
    local d = R.menus[menu]
    local open = d and d.open
    if open == nil then
      return nil
    end
    local retail_callback = _ENV[open.callback]
    local function retail(row, ...)
      d.forwarded_to = row
      if type(retail_callback) == "function" then
        return retail_callback(row, ...)
      end
    end
    if type(position) ~= "number" or position < 0 then
      return retail(position, ...)
    end
    local row = open.rows[position + 1]
    if row == nil then
      return retail(-1)
    end
    local context = {menu = menu, row = row, retail = retail}
    local taker = R.taker(menu, row, context)
    local result
    if taker ~= nil then
      d.last_added = R.added_row(menu, row) ~= nil and row or nil
      d.forwarded_to = nil
      R.log(menu, "row", row, "->", taker.id)
      result = table.pack(taker.run(context))
    else
      d.last_added, d.forwarded_to = nil, nil
      result = table.pack(retail(row, ...))
    end
    -- a checkbox row toggled in place (the window stays open): its state again at its position
    if d.checkbox_rows ~= nil and d.checkbox_rows[row] ~= nil and open.position_of[row] ~= row then
      R.fix_checkboxes(d)
    end
    return table.unpack(result, 1, result.n)
  end

  --- Internal: The window's focus callback with row ids; nil when there is none.
  function R.focus_sub_window(menu, position, ...)
    local d = R.menus[menu]
    local open = d and d.open
    local callback = open and _ENV[open.focus_callback]
    if type(callback) ~= "function" then
      return nil
    end
    local row = position
    if type(position) == "number" and position >= 0 then
      row = open.rows[position + 1] or -1
    end
    if R.added_row(menu, row) ~= nil then
      return nil
    end
    return callback(row, ...)
  end

  --- Internal: Wraps MENU_DEF.OpenSubWindow once.
  function R.wrap_sub_window()
    if MENU_DEF == nil or type(MENU_DEF.OpenSubWindow) ~= "function" or R.retail_open_sub_window ~= nil then
      return
    end
    --- Internal: the retail MENU_DEF.OpenSubWindow saved before the wrap.
    R.retail_open_sub_window = MENU_DEF.OpenSubWindow
    MENU_DEF.OpenSubWindow = function(callback, focus_callback, ...)
      local d = declaration_of_callback(callback, (select(R.KIND_ARGUMENT, ...)))
      if d ~= nil and has_rules(d.name) then
        local out = rebuild_sub_window(d, callback, focus_callback, table.pack(...))
        if out ~= nil then
          local our_focus = focus_callback
          if type(focus_callback) == "string" and focus_callback ~= "" then
            our_focus = R.SUBWINDOW_FOCUS_PREFIX .. d.global
          end
          return R.retail_open_sub_window(R.SUBWINDOW_CALLBACK_PREFIX .. d.global, our_focus,
            table.unpack(out, 1, out.n))
        end
      elseif d ~= nil then
        d.open = nil
      end
      return R.retail_open_sub_window(callback, focus_callback, ...)
    end
  end

  --- Internal: The declared opener: after it ran (the window is open and the retail code addressed it by position), fix that.
  function R.wrap_opener(d)
    local name = d.opener
    if type(name) ~= "string" or type(_ENV[name]) ~= "function" or d.wrappedOpener ~= nil then
      return
    end
    d.wrappedOpener = _ENV[name]
    _ENV[name] = function(...)
      d.open = nil
      local result = table.pack(d.wrappedOpener(...))
      if d.open ~= nil and d.open.callback ~= nil and has_rules(d.name) then
        R.fix_sub_window_positions(d)
      end
      return table.unpack(result, 1, result.n)
    end
  end

  --- Internal: Global callback names of a declared sub-window menu (the window calls its callbacks by name).
  function R.install_sub_window_callbacks(d)
    d.global = d.global or (d.name:gsub("[^%w]", "_"))
    _ENV[R.SUBWINDOW_CALLBACK_PREFIX .. d.global] = function(...)
      return R.pick_sub_window(d.name, ...)
    end
    _ENV[R.SUBWINDOW_FOCUS_PREFIX .. d.global] = function(...)
      return R.focus_sub_window(d.name, ...)
    end
  end

  -- The row list local of a declared local-list menu (VRFW.host locals), or nil.
  local function local_list(d)
    local host = VRFW.host ~= nil and VRFW.host.hosts ~= nil and VRFW.host.hosts[d.stem] or nil
    local list = host ~= nil and host.L ~= nil and host.L[d.list] or nil
    if type(list) ~= "table" then
      if not d.missing_logged then
        d.missing_logged = true
        R.log(d.name, "the row list local", d.list, "of", d.stem, "is not served: its rules do not run")
      end
      return nil
    end
    if d.list_table ~= list then
      d.list_table, d.retail_rows = list, {}
      for i, row in ipairs(list) do
        d.retail_rows[i] = row
      end
    end
    return list
  end

  -- Writes `rows` into the retail list table in place (the retail code holds that table).
  local function write_rows(list, rows)
    for i = #list, #rows + 1, -1 do
      list[i] = nil
    end
    for i, row in ipairs(rows) do
      list[i] = row
    end
  end

  --- Internal: Declares a menu whose rows are a list local of its retail chunk; answers the declaration.
  -- declaration: stem, list (the local's name in the host locals map), setup = {point, layer, instance} (where the
  -- rules are applied), reset (the function before which the list goes back to the retail order); hide and order rules.
  function R.declare_local_list(menu, declaration)
    declaration.name = menu
    R.menus[menu] = declaration
    if VRFW.host == nil or declaration.attached then
      return declaration
    end
    declaration.attached = true
    local setup = declaration.setup
    if declaration.reset ~= nil then
      VRFW.host.on(declaration.stem, declaration.reset, {id = "menu_engine.list_rows." .. menu .. ".reset",
        phase = "before", fn = function()
          local list = has_rules(menu) and local_list(declaration) or nil
          if list ~= nil then
            write_rows(list, R.sort(list, {rows = declaration.retail_rows}))
          end
        end})
    end
    VRFW.host.on(declaration.stem, setup.point, {id = "menu_engine.list_rows." .. menu .. ".rows", phase = "before",
      fn = function(layer, instance)
        if layer ~= setup.layer or (setup.instance ~= nil and instance ~= setup.instance) or not has_rules(menu) then
          return
        end
        local list = local_list(declaration)
        if list == nil then
          return
        end
        write_rows(list, R.apply(menu, list, {menu = menu}))
        if not declaration.logged then
          declaration.logged = true
          R.log(menu, "rows", table.concat(list, ","))
        end
      end})
    return declaration
  end

  -- the formation's team COMANDOS window (soccer_formation_menu_inc OpenSelectTeamMemberControlSubWindowCore)
  R.declare_sub_window(R.TEAM_COMMANDS, {
    callback = "CallbackCloseCondTeamCommandSubWin",
    kind = 22,                        -- win05_11_sub_list_locator_15 (the list window)
    rows = 6,
    rows_shown = 6,
    -- sub_window_group getMaxParamNum: rows -> size code (the retail 6-row window is code 3)
    size_by_rows = {[1] = 0, [2] = 0, [3] = 1, [4] = 2, [5] = 6, [6] = 3},
    list_locator = 118161610,         -- win05_11_sub_list_locator_15
    opener = "OpenSelectTeamMemberControlSubWindowCore",
    checkbox_rows = {
      [5] = function() return funcLuaCommand(545705220) == true end,
    },
  })
end

do
  local queue = rawget(VRFW, "list_rows_queue")
  if type(queue) == "table" and VRFW.list_rows ~= nil then
    rawset(VRFW, "list_rows_queue", nil)
    for _, register in ipairs(queue) do
      if type(register) == "function" then
        local ok, problem = pcall(register, VRFW.list_rows)
        if not ok then
          VRFW.list_rows.log("queued registration failed", tostring(problem))
        end
      end
    end
  end
end
