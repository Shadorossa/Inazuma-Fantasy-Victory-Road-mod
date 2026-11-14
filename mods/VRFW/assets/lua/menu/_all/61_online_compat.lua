-- lua_patch.scope: used
-- VRFW.online_compat: the online compatibility screen of the net service, shared by every online mode.
if VRFW.online_compat == nil then
  local OC = {
    VISIBLE = 12,
    LINES = 8,      -- mismatch lines of the message-window text
    WIDTH = 1280,
    ROW_H = 46,
    INDENT = 40,    -- the setting rows under their mod
    COLUMNS = {
      { x = 0.00, w = 0.44 },
      { x = 0.44, w = 0.22 },
      { x = 0.66, w = 0.15, align = "right" },
      { x = 0.81, w = 0.19, align = "right" },
    },
    COLOR = { theirs = "Y", state = "Y", heading = "N", dim = "WG" },
    SEPARATOR = " › ",
  }
  --- Internal: Namespace of the online compatibility summary: mod and setting differences between players.
  VRFW.online_compat = OC
  -- the logger, made at the first line (VRFW.logger loads after this file)
  local logger = nil
  local function log(...)
    if logger == nil and type(VRFW.logger) == "table" then logger = VRFW.logger.new("VRFW online_compat") end
    if logger ~= nil then pcall(logger, ...) end
  end
  local COMPAT = VRFW.commands.VRFW_NET_COMPAT

  -- the retail options screen's icons (data\dx11\menu\108_option) the rows use, by state
  local ATL_LIST = "#/menu/108_option/option01/option01_02/option01_02.g4tx"
  local STYLE = {
    icon_box = {ATL_LIST, "list_state_base01"},
    icon_plus = {ATL_LIST, "icon_plus01"},
    icon_minus = {ATL_LIST, "icon_minus01"},
    icon_version = {ATL_LIST, "list_icon_state_comp01"},
    icon_setting = {ATL_LIST, "btn_dialog01_on"},
  }
  local GREEN, RED = {0.43, 0.9, 0.51}, {1, 0.43, 0.43}
  local ICONS = {
    missing_there = { part = "icon_plus", box = "icon_box", tint = GREEN },   -- only you have it
    missing_here = { part = "icon_minus", box = "icon_box", tint = RED },     -- only the rival has it
    version = { part = "icon_version" },
    files = { part = "icon_version" },
    base = { part = "icon_version" },
    order = { part = "icon_version" },
    setting = { part = "icon_setting" },
  }

  local function text_id(id, fallback)
    id = tonumber(id) or 0
    if id ~= 0 then
      local t = VRFW.host.command(VRFW.commands.TEXT_GET, id)
      if type(t) == "string" and t ~= "" then return t end
    end
    return fallback or ""
  end

  local function text(key)
    return text_id(VRFW.crc32(key), key)
  end

  local function fill(t, a)
    return (t:gsub("{a}", tostring(a)))
  end

  local function fields(line)
    local out = {}
    for f in (line .. "\t"):gmatch("([^\t]*)\t") do out[#out + 1] = f end
    return out
  end

  --- Internal: The online compatibility report as a table; nil when there is none.
  function OC.read()
    local ok, state, mismatches, can_continue, lines = pcall(funcLuaCommand, COMPAT)
    if not ok or type(state) ~= "string" or state == "none" then return nil end
    local r = { state = state, mismatches = tonumber(mismatches) or 0, can_continue = can_continue == true, rows = {} }
    for line in tostring(lines or ""):gmatch("[^\n]+") do
      local f = fields(line)
      r.rows[#r.rows + 1] = {
        state = f[1] or "", id = f[2] or "", parent = f[3] or "", mine = f[4] or "", theirs = f[5] or "", family = f[6] or "",
        family_name = text_id(f[7], f[8] or f[6]), name = text_id(f[9], f[10] or f[2]), section = text_id(f[11], f[12]),
        mine_text = text_id(f[13], f[14] or f[4]), theirs_text = text_id(f[15], f[16] or f[5]),
      }
    end
    return r
  end

  local function version(v)
    return (v == nil or v == "") and "—" or v
  end

  -- the rows the screen lists: mod rows, setting rows, rows that match, client-only rows
  local function split(r)
    local mods, settings, same, client = {}, {}, 0, {}
    for _, x in ipairs(r.rows) do
      if x.state == "ok" then
        same = same + 1
      elseif x.state == "client_only" then
        client[#client + 1] = x.name
      elseif x.state == "setting" then
        settings[#settings + 1] = x
      else
        mods[#mods + 1] = x
      end
    end
    return mods, settings, same, client
  end

  local function count(n, one, many)
    return n == 1 and text(one) or fill(text(many), n)
  end

  local function summary(r)
    if r.mismatches == 0 then return text("vrfw_online_summary_same") end
    return fill(text(r.mismatches == 1 and "vrfw_online_summary_one" or "vrfw_online_summary"), r.mismatches)
  end
  --- Internal: function building the summary text of the differences.
  OC.summary = summary

  -- «N mods · M settings», the parts with differences only
  local function counts(r)
    local mods, settings = split(r)
    local parts = {}
    if #mods > 0 then parts[#parts + 1] = count(#mods, "vrfw_online_count_mod_one", "vrfw_online_count_mods") end
    if #settings > 0 then parts[#parts + 1] = count(#settings, "vrfw_online_count_setting_one", "vrfw_online_count_settings") end
    return table.concat(parts, " · ")
  end
  --- Internal: function counting mods and settings that differ.
  OC.counts = counts

  -- a label with a dimmed prefix («Classic Recruitment › Remove gacha»)
  local function prefixed(prefix, label)
    if prefix == nil or prefix == "" then return label end
    return { { prefix .. OC.SEPARATOR, OC.COLOR.dim }, { label } }
  end

  local function shown_rows(r)
    local mods, settings = split(r)
    local out = {}
    local function heading(kind, label)
      out[#out + 1] = { kind = kind, cells = { label }, colors = { OC.COLOR.heading } }
    end
    if #mods > 0 then
      heading("section", text("vrfw_online_section_mods"))
      for _, x in ipairs(mods) do
        local name = x.parent ~= "" and prefixed(x.family_name, x.name) or x.name
        out[#out + 1] = {
          cells = { name, text("vrfw_online_state_" .. x.state), version(x.mine), version(x.theirs) },
          colors = { nil, OC.COLOR.state, nil, OC.COLOR.theirs },
          icon = ICONS[x.state],
        }
      end
    end
    if #settings > 0 then
      heading("section", text("vrfw_online_section_settings"))
      -- by family in the order they first appear, a family's own rows before its modules' rows
      local order, by = {}, {}
      for _, x in ipairs(settings) do
        if by[x.family] == nil then
          by[x.family] = { name = x.family_name, own = {}, modules = {} }
          order[#order + 1] = x.family
        end
        local g = by[x.family]
        local list = (x.id:match("^([^.]+)") == x.family) and g.own or g.modules
        list[#list + 1] = x
      end
      for _, fam in ipairs(order) do
        local g = by[fam]
        heading("group", g.name)
        for _, list in ipairs({ g.own, g.modules }) do
          for _, x in ipairs(list) do
            out[#out + 1] = {
              cells = { prefixed(x.section, x.name), "", version(x.mine_text), version(x.theirs_text) },
              colors = { nil, nil, nil, OC.COLOR.theirs },
              icon = ICONS.setting,
              indent = OC.INDENT,
            }
          end
        end
      end
    end
    return out
  end

  -- «Same: N mods.  Only on your screen (not counted): A, B»
  local function note(r)
    local _, _, same, client = split(r)
    local t = same > 0 and fill(text("vrfw_online_note_same"), same) or ""
    if #client > 0 then
      t = (t ~= "" and (t .. "  ") or "") .. fill(text("vrfw_online_note_client_only"), table.concat(client, ", "))
    end
    return t
  end

  --- Internal: The report as text, at most `max` rows.
  function OC.text(r, max)
    max = max or OC.LINES
    local t, n = summary(r), 0
    for _, x in ipairs(r.rows) do
      if x.state ~= "ok" and x.state ~= "client_only" then
        n = n + 1
        if n <= max then
          local name = x.section ~= "" and (x.section .. OC.SEPARATOR .. x.name) or x.name
          local mine, theirs = x.state == "setting" and x.mine_text or x.mine, x.state == "setting" and x.theirs_text or x.theirs
          t = t .. "\n" .. name .. ": " .. version(mine) .. " / " .. version(theirs) .. " (" .. text("vrfw_online_state_" .. x.state) .. ")"
        end
      end
    end
    if n > max then t = t .. "\n" .. fill(text("vrfw_online_more"), n - max) end
    return t
  end

  local function spec_of(r, buttons, press, closed, visible)
    return {
      id = "VRFW.OnlineCompat",
      title = r.mismatches == 0 and summary(r) or text("vrfw_online_title"),
      title_right = counts(r),
      columns = OC.COLUMNS,
      head = { "", "", text("vrfw_online_col_you"), text("vrfw_online_col_rival") },
      rows = function() return shown_rows(r) end,
      note = note(r),
      visible = visible or OC.VISIBLE,
      buttons = buttons,
      focus = (buttons[1] ~= nil and buttons[1].disabled) and 2 or 1,
      press = press,
      closed = closed,
      width = OC.WIDTH,
      row_h = OC.ROW_H,
      opaque = true,
      style = STYLE,
    }
  end

  --- Internal: The labels the report panel needs for `visible` rows.
  function OC.labels_needed(visible)
    return VRFW.match_panel.labels_needed({ columns = OC.COLUMNS, visible = visible or OC.VISIBLE, buttons = { {}, {} } })
  end

  --- Internal: The plates the report panel needs for `visible` rows.
  function OC.plates_needed(visible)
    return VRFW.match_panel.plates_needed({ columns = OC.COLUMNS, visible = visible or OC.VISIBLE, buttons = { {}, {} } })
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

  --- Internal: Hides the report panel.
  function OC.hide()
    if type(VRFW.match_panel) == "table" then pcall(VRFW.match_panel.hide) end
  end

  --- Internal: Shows the compatibility report; answers "back" or the player's choice.
  function OC.run(opts)
    opts = type(opts) == "table" and opts or {}
    local r = OC.read()
    if r == nil then return "back" end
    local MP = VRFW.match_panel
    local can = r.can_continue
    local buttons = {
      { label = text("vrfw_online_continue"), hint = text(can and "vrfw_online_continue_hint" or "vrfw_online_continue_blocked"), disabled = not can },
      { label = text("vrfw_online_back"), hint = text(can and "vrfw_online_back_hint" or "vrfw_online_continue_blocked") },
    }
    local choice = nil
    local spec = spec_of(r, buttons, function(i)
      choice = i == 1 and "continue" or "back"
      MP.close(choice)
    end, function()
      if choice == nil then choice = "back" end
    end, opts.visible)
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
