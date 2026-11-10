-- lua_patch.scope: used
-- Row ids = the retail setting types (VRFW.list_rows.PLAYER_COMMAND).
if VRFW.list_rows ~= nil and VRFW.list_rows.attach_player_commands == nil then
  local R = VRFW.list_rows
  local STEM = "team_dock_formation_menu"
  local MENU = R.PLAYER_COMMANDS
  local ID = "menu_engine.list_rows."

  local function player()
    if type(GetFormationSelectCharaStHdl) ~= "function" then
      return 0
    end
    local ok, handle = pcall(GetFormationSelectCharaStHdl)
    return ok and handle or 0
  end

  --- Installs the player-command row rules.
  function R.attach_player_commands()
    if VRFW.host == nil or R.player_commands_attached then
      return
    end
    R.player_commands_attached = true

    -- The rows: hidden ones out, added ones in.
    VRFW.host.on(STEM, "GetSelectSettingTypeOrderList", {id = ID .. "rows", phase = "after", fn = function(results)
      local list = results[1]
      local rules = R.rules[MENU]
      if type(list) ~= "table" or rules == nil or (#rules.hide == 0 and #rules.add == 0 and #rules.order == 0) then
        return
      end
      results[1] = R.apply(MENU, list, {menu = MENU, handle = player()})
    end})

    -- the text of each added row: t5[row + 1] (the retail table of the setting types' texts)
    VRFW.host.on(STEM, "@edit", {id = ID .. "texts", fn = function(L)
      local rules = R.rules[MENU]
      if rules == nil or #rules.add == 0 then
        return
      end
      local texts = L.t5
      if type(texts) ~= "table" then
        R.log(MENU, "the setting texts (t5) are not readable: added rows have no text")
        return
      end
      for _, spec in ipairs(rules.add) do
        if texts[spec.row + 1] == nil then
          texts[spec.row + 1] = spec.text
        end
      end
    end})

    -- a pick of a row some rule takes over: the retail close, then the retail cancel; the rule runs after the popup
    VRFW.host.on(STEM, "CallbackCloseSelectCharaSetting", {id = ID .. "pick", phase = "around",
      fn = function(next_handler, position, ...)
        R.pending_player_command = nil
        if type(position) ~= "number" or position < 0 or type(GetSelectSettingTypeOrderList) ~= "function" then
          return next_handler(position, ...)
        end
        local list = GetSelectSettingTypeOrderList()
        local row = type(list) == "table" and list[position + 1] or nil
        if row == nil then
          return next_handler(position, ...)
        end
        local context = {menu = MENU, row = row, handle = player()}
        local taker = R.taker(MENU, row, context)
        if taker == nil then
          return next_handler(position, ...)
        end
        local result = table.pack(next_handler(position, ...))
        next_handler(-1)
        R.pending_player_command = {spec = taker, context = context}
        R.log(MENU, "row", row, "->", taker.id)
        return table.unpack(result, 1, result.n)
      end})

    -- right after the popup closed, in OnDecideFocus' coroutine: the rule's run (called directly: it may yield)
    VRFW.host.on(STEM, "WaitCloseSubWindow", {id = ID .. "run", phase = "around", fn = function(next_handler, ...)
      local result = table.pack(next_handler(...))
      local pending = R.pending_player_command
      R.pending_player_command = nil
      if pending ~= nil then
        pending.spec.run(pending.context)
      end
      return table.unpack(result, 1, result.n)
    end})
  end
end
