BetterUI = type(BetterUI) == "table" and BetterUI or {}
@UPV@
do
  local ROW_FILTER = {
    HIDDEN = {[12] = true, [0] = true},
    OWNERS = {"SetupTeamDockListItem", "UpdateViewTeamDockListItem", "OnSetupLayer", "OnEnter"},
    HOOK = "OnSetupLayer",
    LIST = 3367997069,                    -- team01_02_list_item
    LOG = 519897777,                     -- CMND_VRFW_LOG
    list = nil, removed = 0, logged = false,
  }

  -- numbers only, 3..16 rows, with kinds 7, 8, 9 and none of 3..6 (rules out the chunk's other small tables)
  local function is_row_kind_list(v)
    if v[0] ~= nil or #v < 3 or #v > 16 then
      return false
    end
    local seen = {}
    for _, k in ipairs(v) do
      if type(k) ~= "number" or (k >= 3 and k <= 6) then
        return false
      end
      seen[k] = true
    end
    return seen[7] == true and seen[8] == true and seen[9] == true
  end

  local function filter_rows()
    if ROW_FILTER.list == nil then
      ROW_FILTER.list = upvalue_find(ROW_FILTER.OWNERS, is_row_kind_list)
    end
    local kinds = ROW_FILTER.list
    if kinds == nil then
      return
    end
    for row = #kinds, 1, -1 do
      if ROW_FILTER.HIDDEN[kinds[row]] then
        table.remove(kinds, row)
        ROW_FILTER.removed = ROW_FILTER.removed + 1
      end
    end
  end

  filter_rows()

  if BetterUI.dock_rows_wrapped == nil then
    BetterUI.dock_rows_wrapped = {}
  end
  local cur = _ENV[ROW_FILTER.HOOK]
  if type(cur) == "function" and not BetterUI.dock_rows_wrapped[cur] then
    local w = function(a1, a2, ...)
      if a1 == ROW_FILTER.LIST and a2 == 0 then
        filter_rows()
        if not ROW_FILTER.logged then
          ROW_FILTER.logged = true
          local msg
          if ROW_FILTER.list == nil then
            msg = "row list not found (no VRFW.debug?): «Ajustes de equipo» / «Formación» stay"
          else
            msg = string.format("removed %d row(s) («Ajustes de equipo» / «Formación»), %d left",
              ROW_FILTER.removed, #ROW_FILTER.list)
          end
          pcall(funcLuaCommand, ROW_FILTER.LOG, "EVT dock_rows", msg)
        end
      end
      return cur(a1, a2, ...)
    end
    BetterUI.dock_rows_wrapped[w] = true
    _ENV[ROW_FILTER.HOOK] = w
  end
end
