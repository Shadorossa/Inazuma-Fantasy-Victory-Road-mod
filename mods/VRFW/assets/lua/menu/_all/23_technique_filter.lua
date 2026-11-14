--- Internal: Namespace of the technique filter extension.
VRFW.technique_filter = VRFW.technique_filter or {}
if VRFW.technique_filter.save == nil and type(SaveFilterData) == "function" and type(LoadFilterData) == "function"
    and type(OpenFilter) == "function" and type(OnAfterReceiveFilterParamCommon) == "function"
    and type(GetFilterParamArray) == "function" and type(CreateSendFilterParamArray) == "function"
    and type(InsertFilterParam) == "function" then
  local TS = {
    CMD_VALUES = VRFW.commands.VRFW_TECHNIQUE_FILTER_VALUES,
    CMD_TABS = VRFW.commands.VRFW_TECHNIQUE_FILTER_TABS,
    ADDED_CODE = 256,          -- saved value of the first row of the added tabs, +1 per further row
    CMD_KEEP = VRFW.commands.VRFW_TECHNIQUE_FILTER_KEEP,
    CMD_KEPT = VRFW.commands.VRFW_TECHNIQUE_FILTER_KEPT,
    CMD_SAVE = 3666261249,
    TENSION = 3,               -- list item type of the tension tab
    ALL = 8,                   -- list item type "all rows of a tab" (value = the tab's type)
    loading = nil,
  }
  --- Internal: State that saves and restores the technique filter choices.
  VRFW.technique_filter.save = TS

  local function served()
    local r = table.pack(pcall(funcLuaCommand, TS.CMD_VALUES, TS.TENSION))
    if not r[1] or type(r[2]) ~= "number" or r[2] <= 0 then
      return nil
    end
    local values = {}
    for i = 1, r[2] do
      values[i] = r[2 + i]
    end
    local f = table.pack(pcall(funcLuaCommand, TS.CMD_TABS))
    if f[1] and type(f[2]) == "number" and type(f[3]) == "number" then
      local at, added = 4, 0
      for _ = 1, f[3] do
        local n = type(f[at + 5]) == "number" and f[at + 5] or 0
        for _ = 1, n do
          values[f[2] + added + 1] = TS.ADDED_CODE + added
          added = added + 1
        end
        at = at + 6 + 2 * n
      end
    end
    return values
  end

  local function is_all(p)
    return p.listItemType == TS.ALL and p.value == TS.TENSION and p.option == 0
  end

  local game_save = SaveFilterData
  --- Retail override: saves the filter data, using the framework's values when it serves them.
  function SaveFilterData(a1)
    local values = served()
    if values == nil then
      return game_save(a1)
    end
    local copy, ticked, all, any = {}, {}, false, false
    for _, p in ipairs(GetFilterParamArray()) do
      if p.listItemType == TS.TENSION and p.option == 0 then
        any = true
        ticked[#ticked + 1] = values[p.value + 1]
      else
        all = all or is_all(p)
        copy[#copy + 1] = p
      end
    end
    if not any and not all then
      return game_save(a1)
    end
    if any then
      pcall(funcLuaCommand, TS.CMD_KEEP, a1, #ticked, table.unpack(ticked))
      if not all then
        InsertFilterParam(copy, TS.ALL, TS.TENSION, 0)
      end
    else
      pcall(funcLuaCommand, TS.CMD_KEEP, a1, -1)
    end
    local send = CreateSendFilterParamArray(copy)
    funcLuaMenuCommand(TS.CMD_SAVE, a1, #send, send)
  end

  local game_load = LoadFilterData
  --- Retail override: remembers the filter id, then loads it.
  function LoadFilterData(a1, a2)
    --- Internal: filter data id being loaded.
    TS.loading = a1
    return game_load(a1, a2)
  end

  local game_open = OpenFilter
  --- Retail override: clears the remembered filter id, then opens the filter.
  function OpenFilter(...)
    TS.loading = nil
    return game_open(...)
  end

  local game_after = OnAfterReceiveFilterParamCommon
  --- Retail override: applies the served filter after the common filter params arrive.
  function OnAfterReceiveFilterParamCommon(...)
    local id = TS.loading
    TS.loading = nil
    local values = id ~= nil and served() or nil
    if values ~= nil then
      local t = GetFilterParamArray()
      local r = table.pack(pcall(funcLuaCommand, TS.CMD_KEPT, id))
      local kept = r[1] and type(r[2]) == "number" and r[2] >= 0
      local had = false
      for i = #t, 1, -1 do
        local p = t[i]
        if p.listItemType == TS.TENSION and p.option == 0 then
          had = true
          table.remove(t, i)
        elseif is_all(p) then
          had = had or kept
          if kept then
            table.remove(t, i)
          end
        end
      end
      if had then
        local row, added = {}, 0
        for i, v in ipairs(values) do
          row[v] = i - 1
        end
        if kept then
          for i = 1, r[2] do
            local at = row[r[2 + i]]
            if at ~= nil then
              InsertFilterParam(t, TS.TENSION, at, 0)
              added = added + 1
            end
          end
        end
        if added == 0 and not (kept and r[2] == 0) then
          InsertFilterParam(t, TS.ALL, TS.TENSION, 0)
        end
      end
    end
    return game_after(...)
  end
end
