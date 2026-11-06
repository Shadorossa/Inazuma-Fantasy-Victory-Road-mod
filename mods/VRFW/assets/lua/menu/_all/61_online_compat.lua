-- VRFW_OnlineCompat: the online compatibility screen of the net service, shared by every online mode. It shows which
-- mods differ from the other player's (CMND_VRFW_NET_COMPAT, docs/framework/online.md): a summary on top, then one
-- row per mod «Mod | Tu versión | Su versión | Estado», grouped by family (a parent mod, its modules indented under
-- it), OK rows hidden (one closing row counts them), a scrollable list inside the window, and two buttons: Continuar
-- (only when the room let this player in: a mode with mismatch = "allow") and Volver. Definitions only: no engine
-- call at load.
--   VRFW_OnlineCompat.Read() -> nil (no result) | { state = "same" | "differs", mismatches = n, can_continue = bool,
--                                                   rows = { { state, id, parent, mine, theirs }, … } }
--   VRFW_OnlineCompat.Run(opts) -> "continue" | "back"   inside the caller's coroutine (one yield per frame)
--       opts = { show_ok = false, visible = 12 }
--     The window is VRFW_MatchPanel in table mode: the host menu needs its two layers (vrfw_mp_plate x
--     VRFW_MatchPanel.PLATES, vrfw_mp_label x VRFW_OnlineCompat.LABELS) and must call VRFW_OnlineCompat.Hide() once
--     when it opens. A menu without them gets the retail message window with the summary and the first lines.
--   VRFW_OnlineCompat.Hide()   the window's layer instances hidden (the host menu's open)
--   VRFW_OnlineCompat.Text(r, max) -> the summary and at most `max` mismatch lines (the message window's text)
if VRFW_OnlineCompat == nil then
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
  VRFW_OnlineCompat = OC
  -- the logger, made at the first line (VRFW_Log loads after this file)
  local logger = nil
  local function log(...)
    if logger == nil and type(VRFW_Log) == "table" then logger = VRFW_Log.New("VRFW online_compat") end
    if logger ~= nil then pcall(logger, ...) end
  end
  local COMPAT = VRFW_Cmd.VRFW_NET_COMPAT

  local function text(key)
    local ok, t = pcall(funcLuaCommand, VRFW_Cmd.TEXT_GET, VRFW_Crc32(key))
    return (ok and type(t) == "string" and t ~= "") and t or key
  end

  local function fill(t, a)
    return (t:gsub("{a}", tostring(a)))
  end

  local function fields(line)
    local out = {}
    for f in (line .. "\t"):gmatch("([^\t]*)\t") do out[#out + 1] = f end
    return out
  end

  function OC.Read()
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
  OC.Summary = summary

  local function version(v)
    return (v == nil or v == "") and "—" or v
  end

  -- the rows to show: every row that is not OK, the parent of a shown module (for its family), every row with show_ok;
  -- the hidden OK rows counted in one closing row
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

  function OC.Text(r, max)
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

  function OC.LabelsNeeded(visible)
    return VRFW_MatchPanel.labels_needed({ columns = OC.COLUMNS, visible = visible or OC.VISIBLE, buttons = { {}, {} } })
  end

  -- the window's two layers opened / closed instance by instance (a host may add them closed with its group)
  local function open_layers(on)
    local M = funcLuaMenuCommand
    for _, name in ipairs({ "vrfw_mp_plate", "vrfw_mp_label" }) do
      local layer = VRFW_Crc32(name)
      local okn, n = pcall(M, VRFW_Cmd.GET_CREATE_LAYER_NUM, layer)
      for i = 0, ((okn and type(n) == "number") and n or 0) - 1 do
        pcall(M, on and VRFW_Cmd.OPEN_LAYER or VRFW_Cmd.CLOSE_LAYER, layer, i)
      end
    end
  end

  function OC.Hide()
    if type(VRFW_MatchPanel) == "table" then pcall(VRFW_MatchPanel.hide) end
  end

  function OC.Run(opts)
    opts = type(opts) == "table" and opts or {}
    local r = OC.Read()
    if r == nil then return "back" end
    local MP = VRFW_MatchPanel
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
    if can and type(VRFW_Question) == "table" then
      return VRFW_Question.Ask(OC.Text(r) .. "\n" .. text("vrfw_online_continue_hint")) and "continue" or "back"
    end
    if type(VRFW_Question) == "table" then VRFW_Question.Notice(OC.Text(r)) end
    return "back"
  end
end
