-- lua_patch.scope: used
-- VRFW.online_compat: the online compatibility screen of the net service, shared by every online mode.
if VRFW.online_compat == nil then
  local OC = {
    VISIBLE = 12,
    LINES = 8,      -- mismatch lines of the message-window text
    COLUMNS = {
      { x = 0.00, w = 0.38 },
      { x = 0.38, w = 0.16 },
      { x = 0.54, w = 0.16 },
      { x = 0.70, w = 0.30 },
    },
  }
  VRFW.online_compat = OC
  -- the logger, made at the first line (VRFW.logger loads after this file)
  local logger = nil
  local function log(...)
    if logger == nil and type(VRFW.logger) == "table" then logger = VRFW.logger.new("VRFW online_compat") end
    if logger ~= nil then pcall(logger, ...) end
  end
  local COMPAT = VRFW.commands.VRFW_NET_COMPAT

  local function text(key)
    local t = VRFW.host.command(VRFW.commands.TEXT_GET, VRFW.crc32(key))
    return (type(t) == "string" and t ~= "") and t or key
  end

  local function fill(t, a)
    return (t:gsub("{a}", tostring(a)))
  end

  local function fields(line)
    local out = {}
    for f in (line .. "\t"):gmatch("([^\t]*)\t") do out[#out + 1] = f end
    return out
  end

  --- The online compatibility report as a table; nil when there is none.
  function OC.read()
    local ok, state, mismatches, can_continue, lines = pcall(funcLuaCommand, COMPAT)
    if not ok or type(state) ~= "string" or state == "none" then return nil end
    local r = { state = state, mismatches = tonumber(mismatches) or 0, can_continue = can_continue == true, rows = {} }
    for line in tostring(lines or ""):gmatch("[^\n]+") do
      local f = fields(line)
      r.rows[#r.rows + 1] = { state = f[1] or "", id = f[2] or "", parent = f[3] or "", mine = f[4] or "", theirs = f[5] or "" }
    end
    return r
  end

  local function summary(r)
    if r.mismatches == 0 then return text("vrfw_online_summary_same") end
    return fill(text(r.mismatches == 1 and "vrfw_online_summary_one" or "vrfw_online_summary"), r.mismatches)
  end
  OC.summary = summary

  local function version(v)
    return (v == nil or v == "") and "—" or v
  end

  local function shown_rows(r, show_ok)
    local listed, need_parent = {}, {}
    for _, x in ipairs(r.rows) do listed[x.id] = true end
    for _, x in ipairs(r.rows) do
      if x.state ~= "ok" and x.parent ~= "" then need_parent[x.parent] = true end
    end
    local out, hidden = {}, 0
    for _, x in ipairs(r.rows) do
      if show_ok or x.state ~= "ok" or need_parent[x.id] then
        local name = (x.parent ~= "" and listed[x.parent]) and ("      " .. x.id) or x.id
        out[#out + 1] = { cells = { name, version(x.mine), version(x.theirs), text("vrfw_online_state_" .. x.state) } }
      else
        hidden = hidden + 1
      end
    end
    if hidden > 0 then
      out[#out + 1] = { cells = { fill(text("vrfw_online_ok_hidden"), hidden), "", "", "" } }
    end
    return out
  end

  --- The report as text, at most `max` rows.
  function OC.text(r, max)
    max = max or OC.LINES
    local t, n = summary(r), 0
    for _, x in ipairs(r.rows) do
      if x.state ~= "ok" and x.state ~= "client_only" then
        n = n + 1
        if n <= max then
          t = t .. "\n" .. x.id .. ": " .. version(x.mine) .. " / " .. version(x.theirs) .. " (" .. text("vrfw_online_state_" .. x.state) .. ")"
        end
      end
    end
    if n > max then t = t .. "\n" .. fill(text("vrfw_online_more"), n - max) end
    return t
  end

  --- The labels the report panel needs for `visible` rows.
  function OC.labels_needed(visible)
    return VRFW.match_panel.labels_needed({ columns = OC.COLUMNS, visible = visible or OC.VISIBLE, buttons = { {}, {} } })
  end

  -- the window's two layers opened / closed instance by instance (a host may add them closed with its group)
  local function open_layers(on)
    local M = funcLuaMenuCommand
    for _, name in ipairs({ "vrfw_mp_plate", "vrfw_mp_label" }) do
      local layer = VRFW.crc32(name)
      local okn, n = pcall(M, VRFW.commands.GET_CREATE_LAYER_NUM, layer)
      for i = 0, ((okn and type(n) == "number") and n or 0) - 1 do
        pcall(M, on and VRFW.commands.OPEN_LAYER or VRFW.commands.CLOSE_LAYER, layer, i)
      end
    end
  end

  --- Hides the report panel.
  function OC.hide()
    if type(VRFW.match_panel) == "table" then pcall(VRFW.match_panel.hide) end
  end

  --- Shows the compatibility report; answers "back" or the player's choice.
  function OC.run(opts)
    opts = type(opts) == "table" and opts or {}
    local r = OC.read()
    if r == nil then return "back" end
    local MP = VRFW.match_panel
    local can = r.can_continue
    local buttons = {
      { label = text("vrfw_online_continue"), hint = text(can and "vrfw_online_continue_hint" or "vrfw_online_continue_blocked"), disabled = not can },
      { label = text("vrfw_online_back"), hint = text("vrfw_online_back_hint") },
    }
    local choice = nil
    local spec = {
      id = "VRFW.OnlineCompat",
      title = summary(r),
      columns = OC.COLUMNS,
      head = { text("vrfw_online_col_mod"), text("vrfw_online_col_mine"), text("vrfw_online_col_theirs"), text("vrfw_online_col_state") },
      rows = function() return shown_rows(r, opts.show_ok == true) end,
      visible = opts.visible or OC.VISIBLE,
      buttons = buttons,
      press = function(i)
        choice = i == 1 and "continue" or "back"
        MP.close(choice)
      end,
      closed = function(why)
        if choice == nil then choice = "back" end
      end,
      width = 1360,
    }
    if type(MP) == "table" and MP.available(spec) and not MP.is_open() then
      open_layers(true)
      if not MP.open(spec) then
        open_layers(false)
        return "back"
      end
      log("open:", r.mismatches, "mismatch(es),", #r.rows, "row(s), continue", tostring(can))
      while MP.is_open() do
        coroutine.yield()
        MP.step()
      end
      open_layers(false)
      log("closed:", tostring(choice))
      return choice or "back"
    end
    -- no window layers in this menu: the retail message window with the summary and the first lines
    log("no panel layers here: message window")
    if can and type(VRFW.question) == "table" then
      return VRFW.question.ask(OC.text(r) .. "\n" .. text("vrfw_online_continue_hint")) and "continue" or "back"
    end
    if type(VRFW.question) == "table" then VRFW.question.notice(OC.text(r)) end
    return "back"
  end
end
