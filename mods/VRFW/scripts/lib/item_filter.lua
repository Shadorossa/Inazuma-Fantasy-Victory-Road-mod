-- A mod's side of the item filter sections (VRFW.item_filter, docs/framework/item-filter-sections.md).
local ItemFilter = {}

-- The files that declare the sections ([[VRFW.ItemFilterSection]]).
local SECTION_FOLDERS = { "content/item_filter_sections" }
-- The mod's native table the framework's item test reads: [item id] = 1 hides the item.
local REJECTED_TABLE = "ItemFilter.Rejected"

--- The handler of a mod's serve command. `spec`: `command` (the command's name, as the sections' `serve`), `items()`
--- (every item id the tests know), `test(test, character, rows)` (a function (item) -> true when the row holds for the
--- item), `list(name)` (the rows of an `each` list: { name, label, test, inventories = { [inventory] = true } | nil }).
--- Requests: ("rows", section, inventory) -> n, then value, label per row; ("context", character) -> true;
--- ("tick", scope, section, values...) -> true: rows ticked in a section that filters (a command takes 32 arguments at
--- most, so a section may come in several requests); ("apply", scope) -> the number of items hidden by the rows
--- ticked since the last one. Scope "list" = the list's filter, "window" = the filter window's own while it is open,
--- "close" = the window closed.
function ItemFilter.server(spec)
  local info, warn = VRFW.logger("item_filter")
  local sections = nil
  local state = { character = 0, list = nil, window = nil, items = nil, ticked = {} }

  local function label_of(key)
    local ok, text = pcall(VRFW.text, key)
    return (ok and type(text) == "string" and text ~= "") and text or tostring(key)
  end

  -- [section name] = its rows in a fixed order (a row's value = its place): { name, label, test, inventories }.
  local function load_sections()
    if sections then return sections end
    sections = {}
    local ok, files = pcall(VRFW.files.declarations, SECTION_FOLDERS)
    for _, f in ipairs((ok and type(files) == "table") and files or {}) do
      local v = type(f.data) == "table" and f.data.VRFW or nil
      local decls = type(v) == "table" and v.ItemFilterSection or nil
      for _, d in ipairs(type(decls) == "table" and decls or {}) do
        if d.serve == spec.command and type(d.name) == "string" then
          local rows = {}
          for _, r in ipairs(type(d.rows) == "table" and d.rows or {}) do
            if type(r.each) == "string" then
              local okL, list = pcall(spec.list, r.each)
              if not okL or type(list) ~= "table" then
                warn(d.name .. ": list \"" .. r.each .. "\" gave no rows (" .. tostring(list) .. ")")
                list = {}
              end
              for _, e in ipairs(list) do rows[#rows + 1] = e end
            elseif type(r.name) == "string" and type(r.test) == "string" then
              rows[#rows + 1] = { name = r.name, label = label_of(r.text), test = r.test }
            else
              warn(d.name .. ": a row has neither each nor name and test (left out)")
            end
          end
          sections[d.name] = rows
        end
      end
    end
    return sections
  end

  local function universe()
    if state.items then return state.items end
    local ok, items = pcall(spec.items)
    state.items = (ok and type(items) == "table") and items or {}
    return state.items
  end

  -- The items a set of ticked rows hides: { [item] = true }, nil when no section filters.
  local function rejected_by(groups)
    local filters = {}
    local all = load_sections()
    for _, g in ipairs(groups) do
      local rows = all[g.section]
      local tests = {}
      for _, value in ipairs(g.values) do
        local row = rows and rows[value]
        if row then
          local ok, test = pcall(spec.test, row.test, state.character, rows)
          if ok and type(test) == "function" then
            tests[#tests + 1] = test
          else
            warn(g.section .. "." .. row.name .. ": no test (" .. tostring(test) .. "): the row lists nothing")
          end
        end
      end
      filters[#filters + 1] = tests
    end
    if #filters == 0 then return nil end
    local rejected = {}
    for _, item in ipairs(universe()) do
      for _, tests in ipairs(filters) do
        local passes = false
        for _, test in ipairs(tests) do
          if test(item) then
            passes = true
            break
          end
        end
        if not passes then
          rejected[item] = true
          break
        end
      end
    end
    return rejected
  end

  -- The table the item test reads: the window's filter while it is open, else the list's.
  local function publish()
    local rejected = state.window or state.list
    local entries = {}
    for item in pairs(rejected or {}) do entries[#entries + 1] = { item, 1 } end
    local ok, e = pcall(VRFW.native.table_replace, REJECTED_TABLE, nil, entries)
    if not ok then warn(REJECTED_TABLE .. ": " .. tostring(e)) end
    if state.published ~= #entries then
      state.published = #entries
      info(string.format("%s: %d item(s) hidden", spec.command, #entries))
    end
    return #entries
  end

  -- The rows ticked for `scope` since its last «apply»: { { section, values } }, forgotten once read.
  local function ticked_of(scope)
    local groups = state.ticked[scope] or {}
    state.ticked[scope] = nil
    return groups
  end

  local function tick(scope, section, ...)
    local groups = state.ticked[scope]
    if not groups then
      groups = {}
      state.ticked[scope] = groups
    end
    local group = nil
    for _, g in ipairs(groups) do
      if g.section == section then group = g end
    end
    if not group then
      group = { section = section, values = {} }
      groups[#groups + 1] = group
    end
    for _, value in ipairs({ ... }) do
      if type(value) == "number" then group.values[#group.values + 1] = math.floor(value) end
    end
  end

  return function(request, ...)
    if request == "rows" then
      local section, inventory = ...
      local rows = load_sections()[section]
      local out, n = {}, 0
      for value, row in ipairs(rows or {}) do
        if row.inventories == nil or row.inventories[inventory] then
          n = n + 1
          out[#out + 1] = value
          out[#out + 1] = row.label
        end
      end
      return n, table.unpack(out)
    elseif request == "context" then
      local character = ...
      state.character = type(character) == "number" and character or 0
      return true
    elseif request == "tick" then
      local scope, section = ...
      if type(scope) ~= "string" or type(section) ~= "string" then return false end
      tick(scope, section, select(3, ...))
      return true
    elseif request == "apply" then
      local scope = ...
      if scope == "close" then
        state.ticked = {}
        state.window = nil
      elseif scope == "window" then
        state.window = rejected_by(ticked_of(scope)) or {}
      elseif scope == "list" then
        state.list = rejected_by(ticked_of(scope))
      else
        return 0
      end
      return publish()
    end
    return 0
  end
end

return ItemFilter
