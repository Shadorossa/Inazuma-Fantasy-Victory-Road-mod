-- menu_engine: INPUT TRACE (diagnostics).
-- after leaving any shop page the hub under it takes no input (no key reaches its Lua).
-- MENU_ACTIVE (menu, on), the layer input switch 2171393651 (layer, on), the ctrl focus 3518307824 (layer, on), the
if VRFW.input_trace == nil then
  local T = {on = true, logging = false, MAX = 400, n = 0, frame = 0, last = {}, installed = false, vm = "?",
    watch_frames = 0, WATCH = 3600, EVERY = 60, owners = nil, corner = nil,
    DUMP = VRFW.commands.VRFW_MENU_INPUT_DUMP, GPOS = 4002164178, IS_VISIBLE = VRFW.commands.IS_LAYER_VISIBLE, LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM,
    CORNER = {"vrfw_topbar_back", "vrfw_topbar_plate", "vrfw_topbar_icon", "vrfw_topbar_hint", "vrfw_topbar_drop_plate",
      "vrfw_topbar_drop_icon", "vrfw_topbar_drop_label",
      "vrfw_cm_bust", "vrfw_cm_busticon", "mainmenu01_10_return_arrow_button_guide"},
    MENU = {[1558704558] = "menu_active", [2171393651] = "layer_input", [VRFW.commands.SET_ENABLE_CTRL_FOCUS] = "ctrl_focus",
      [1951894516] = "free_cursor", [VRFW.commands.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE] = "virtual_mouse", [369172623] = "menu_hide", [66378409] = "menu_show",
      [438207617] = "input_ctrl", [2515285936] = "input_switch", [3694710990] = "finalize_menu"},
    CMD = {[1813741958] = "cursor_control", [VRFW.commands.CLOSE_MENU_OBJECT] = "close_menu", [VRFW.commands.OPEN_MENU_OBJECT] = "open_menu",
      [VRFW.commands.SET_TEMP_BIT_FLAG] = "temp_flag", [2515285936] = "input_switch", [2770980979] = "pause_input"},
    ring = {}, RING = 50}
  --- Internal: State of the input trace that logs menu commands per frame.
  VRFW.input_trace = T

  --- Internal: Records one command in this VM's ring.
  function T.log(what, ...)
    local args = {}
    for i = 1, select("#", ...) do
      args[#args + 1] = tostring((select(i, ...)))
    end
    local sig = table.concat(args, ",")
    -- the last RING calls of this VM, every one (the freeze watchdog dumps them)
    T.ring[#T.ring + 1] = "f" .. T.frame .. " " .. what .. "(" .. sig .. ")"
    if #T.ring > T.RING then
      table.remove(T.ring, 1)
    end
    local key = T.frame .. "|" .. sig
    if T.last[what] == key then
      return
    end
    T.last[what] = key
    if not T.logging or T.n >= T.MAX then
      return
    end
    --- Internal: count of traced commands.
    T.n = T.n + 1
    pcall(T.raw_cmd, VRFW.commands.VRFW_LOG, "VRFW input", T.vm, "f" .. T.frame, what, sig)
  end

  --- Internal: Reads the command owners; logs them when they changed.
  function T.watch(owners_only)
    local ok, list = pcall(T.raw_cmd, T.DUMP)
    if ok and type(list) == "string" and list ~= T.owners then
      T.owners = list
      local G = VRFW.top_bar.guard
      local okh, has = pcall(T.raw_cmd, VRFW.commands.PARAM_HAS, 1768396853 --[[vrfw_top_bar_nav]])
      pcall(T.raw_cmd, VRFW.commands.VRFW_LOG, "VRFW input owners", T.vm, "f" .. T.frame, list, "guard off",
        tostring(type(G) == "table" and G.off), "nav param", tostring(okh and has))
    end
    if owners_only or type(CRC32) ~= "function" then
      return
    end
    local hits = {}
    for _, name in ipairs(T.CORNER) do
      local layer = CRC32(name)
      local okn, n = pcall(T.raw_menu, T.LAYER_NUM, layer)
      if okn and type(n) == "number" then
        for idx = 0, math.min(n, 128) - 1 do
          local okv, v = pcall(T.raw_menu, T.IS_VISIBLE, layer, idx)
          if okv and v == true then
            local okp, gx, gy = pcall(T.raw_menu, T.GPOS, layer, idx)
            if okp and type(gx) == "number" and type(gy) == "number" and gx < 400 and gy > -250 then
              hits[#hits + 1] = name .. " " .. idx .. " " .. math.floor(gx) .. " " .. math.floor(gy)
            end
          end
        end
      end
    end
    local s = table.concat(hits, "; ")
    if s ~= (T.corner or "") then
      T.corner = s
      pcall(T.raw_cmd, VRFW.commands.VRFW_LOG, "VRFW input topleft", T.vm, "f" .. T.frame, s ~= "" and s or "none")
    end
  end

  --- Internal: Installs the command trace wrappers once.
  function T.install()
    if T.installed or type(funcLuaCommand) ~= "function" or type(funcLuaMenuCommand) ~= "function" then
      return
    end
    --- Internal: true once the trace is installed.
    T.installed = true
    local p = type(VRFW.patch) == "table" and VRFW.patch.script or nil
    --- Internal: script name of this VM, or "?".
    T.vm = type(p) == "string" and p or "?"
    --- Internal: menu stem of this VM.
    T.stem = (T.vm:gsub("_%d+%.%d+%.%d+[%.%d]*$", ""))
    -- Internal: the trace's own reads and resets go past every command handler (VRFW.host)
    T.raw_cmd = VRFW.host.real_command
    --- Internal: original menu command function.
    T.raw_menu = VRFW.host.real_menu_command
    local function IdsOf(map)
      local ids = {}
      for c in pairs(map) do
        ids[#ids + 1] = c
      end
      return ids
    end
    VRFW.host.hook_command(IdsOf(T.MENU), function(nxt, c, ...)
      local what = T.on and T.MENU[c] or nil
      if what ~= nil then
        pcall(T.log, what, ...)
        if c == 1558704558 and select(2, ...) == true then
          T.watch_frames = T.WATCH                      -- a menu made active again: watch its input for 60 s
          if T.inactive and T.CURSOR_RESET[T.stem or ""] then
            T.cr = 0                             -- the device-mode reset below
          end
          T.inactive = false
        elseif c == 1558704558 and select(2, ...) == false then
          T.inactive = true
        end
      end
      return nxt(c, ...)
    end, "VRFW.input_trace", { menu = true })
    VRFW.host.hook_command(IdsOf(T.CMD), function(nxt, ...)
      local c, a = ...
      local what = T.on and T.CMD[c] or nil
      if what ~= nil and (c ~= VRFW.commands.SET_TEMP_BIT_FLAG or a == 939384271) then
        pcall(T.log, what, select(2, ...))
      end
      return nxt(...)
    end, "VRFW.input_trace")
    --- Internal: frames to watch.
    T.watch_frames = T.WATCH
    if T.WD.STEMS[T.stem or ""] ~= nil then
      pcall(T.watchdog_callbacks)                     -- the freeze watchdog counts this VM's input callbacks
    end
    pcall(T.flow_install)
    if not T.ticking and type(Step) == "function" then
      local step = Step
      Step = function(...)
        return T.wrapped(step, ...)
      end
    end
    pcall(T.log, "trace on")
  end

  --- Internal: One tick per engine Step call, however many of the mod's wrappers are in its chain.
  function T.wrapped(step, ...)
    --- Internal: true once the trace Step wrapper ran.
    T.ticking = true
    if T.in_step then
      return step(...)
    end
    --- Internal: true while a trace step is running.
    T.in_step = true
    pcall(T.tick)
    local r = table.pack(pcall(step, ...))
    T.in_step = false
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  --- Internal: set of menus whose cursor is reset.
  T.CURSOR_RESET = {market_menu = true, soccer_vs_cpu_list_menu = true}
  --- Internal: One frame of the cursor-reset countdown.
  function T.cursor_reset()
    if T.cr == nil then return end
    --- Internal: frame counter of the cursor reset.
    T.cr = T.cr + 1
    if T.cr == 2 then
      pcall(T.raw_menu, VRFW.commands.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE, false, false, true)
    elseif T.cr == 4 then
      pcall(T.raw_menu, 438207617 --[[CMND_CHANGE_MENU_INPUT_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]])
      pcall(T.raw_menu, VRFW.commands.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE, true, false, true)
      if T.logging then pcall(T.raw_cmd, VRFW.commands.VRFW_LOG, "VRFW input", T.vm, "f" .. T.frame, "cursor reset") end
      T.cr = nil
    end
  end

  -- Internal: FREEZE WATCHDOG (shop freeze, intermittent).
  -- its input switch on, MENU_ACTIVE(menu, true), the list's ctrl focus, the virtual-mouse reset. Log «freeze
  -- watchdog: recovered».
  T.WD = {on = true, PRESSES = 3, SPAN = 120, GAP = 600, MAX = 5, n = 0, last = -100000, cb = 0, cb_name = "none",
    presses = 0, first = nil, held = {},
    STEMS = {market_menu = {menu = 839500579, list = 536841765},
      soccer_vs_cpu_list_menu = {menu = 1970579282}, shop_menu_buy = {menu = 3170360552, list = 2569990914},
      soccer_battle_setting_flow_vs_menu = {menu = 1853845420, dump_only = true},
      chronicle_mode_top_menu = {menu = 3902542018, dump_only = true}},
    -- menus that legitimately take the input from the watched one
    OVER = {[839500579] = {3170360552, 713974531, 1970579282, 449578137, 968210065, 1427722143, 1355292071},
      [1970579282] = {3170360552, 449578137, 968210065, 1427722143},
      [3170360552] = {449578137, 968210065, 1427722143},
      [3902542018] = {2357301264, 937147172, 3518667992, 3170360552, 948899592, 1936716961, 613075359,
        449578137, 968210065, 1427722143}},
    NAMES = {[839500579] = "market_menu", [1970579282] = "soccer_vs_cpu_list_menu", [3170360552] = "shop_menu",
      [713974531] = "shop_menu_basara_top", [449578137] = "general_window", [968210065] = "sub_window",
      [1427722143] = "personal_plate_menu", [1355292071] = "vrfw_contact_map_menu",
      [1853845420] = "soccer_battle_setting_flow_vs_menu", [3902542018] = "chronicle_mode_top_menu",
      [3518667992] = "item_menu_soccer", [2384748956] = "item_use_menu", [1956876983] = "num_shop_window"},
    -- {name, pad bit, Windows key}: Accept and Back
    KEYS = {{"enter", 0x4000, 0x0D}, {"back", 0x2000, 0x1B}}}

  --- Internal: Wraps the retail input callbacks for the freeze watchdog.
  function T.watchdog_callbacks()
    local W = T.WD
    for _, name in ipairs({"OnFunction", "OnDecideFocus", "OnEnter", "OnBack", "OnChangeFocus"}) do
      local f = _G[name]
      if type(f) == "function" then
        _G[name] = function(...)
          W.cb = T.frame
          W.cb_name = name
          W.presses, W.first = 0, nil
          return f(...)
        end
      end
    end
  end

  --- Internal: True when the watched device has key k held.
  function T.watchdog_device(k)
    local okp, held = pcall(T.raw_cmd, VRFW.commands.VRFW_INPUT_PAD)
    if okp and type(held) == "number" and held >= 0 and math.floor(held / k[2]) % 2 == 1 then
      return true
    end
    local okk, v = pcall(T.raw_cmd, VRFW.commands.VRFW_INPUT_KEY, k[3])
    return okk and v == true
  end

  --- Internal: True when menu m exists.
  function T.watchdog_open(m)
    local ok, e = pcall(T.raw_menu, VRFW.commands.IS_EXIST_MENU_OBJECT, m)
    return ok and e == true
  end

  --- Internal: True when the watchdog may act on screen S now.
  function T.watchdog_eligible(S)
    if not T.watchdog_open(S.menu) then
      return false
    end
    local okc, closing = pcall(T.raw_cmd, VRFW.commands.IS_CLOSING_MENU_OBJECT, S.menu)
    if okc and closing == true then
      return false
    end
    for _, m in ipairs(T.WD.OVER[S.menu] or {}) do
      if T.watchdog_open(m) then
        return false
      end
    end
    local okf, fade = pcall(T.raw_cmd, VRFW.commands.BRIGHT_IS_FADE)
    return not (okf and fade == true)
  end

  --- Internal: Logs through the freeze-watchdog tag.
  function T.watchdog_log(...)
    pcall(T.raw_cmd, VRFW.commands.VRFW_LOG, "VRFW freeze watchdog", T.vm, "f" .. T.frame, ...)
  end

  --- Internal: Logs the freeze state of screen S and why.
  function T.watchdog_dump(S, why)
    local W = T.WD
    T.watchdog_log("FROZEN", why)
    local ok, list = pcall(T.raw_cmd, T.DUMP)
    T.watchdog_log("owners / controller", ok and tostring(list) or "n/a")
    local menus = {}
    for m, name in pairs(W.NAMES) do
      if T.watchdog_open(m) then
        local okc, closing = pcall(T.raw_cmd, VRFW.commands.IS_CLOSING_MENU_OBJECT, m)
        menus[#menus + 1] = name .. ((okc and closing == true) and " closing" or " open")
      end
    end
    local okf, fade = pcall(T.raw_cmd, VRFW.commands.BRIGHT_IS_FADE)
    local okl, lf = pcall(T.raw_menu, VRFW.commands.IS_CTRL_FOCUS_ACTIVE, S.list or 0)
    T.watchdog_log("menus: " .. (#menus > 0 and table.concat(menus, ", ") or "none") .. " | fade " .. tostring(okf and fade)
      .. " | list focus " .. tostring(okl and lf) .. " | last callback " .. W.cb_name .. " at f" .. W.cb
      .. " | MENU_ACTIVE(false) last " .. tostring(T.inactive))
    for i = 1, #T.ring, 10 do
      T.watchdog_log("last calls " .. i .. "-" .. math.min(i + 9, #T.ring) .. ": "
        .. table.concat(T.ring, "; ", i, math.min(i + 9, #T.ring)))
    end
  end

  --- Internal: Gives screen S its input back.
  function T.watchdog_recover(S)
    pcall(T.raw_menu, 438207617 --[[CMND_CHANGE_MENU_INPUT_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]])
    local okw, was = pcall(T.raw_cmd, VRFW.commands.VRFW_MENU_INPUT_CTRL_ON)
    pcall(T.raw_menu, 1558704558 --[[MENU_ACTIVE]], S.menu, true)
    if S.list ~= nil then
      pcall(T.raw_menu, VRFW.commands.SET_ENABLE_CTRL_FOCUS, S.list, true)
    end
    T.cr = 0                                   -- the virtual-mouse reset (CursorReset: off, then on)
    local okc, ctrl = pcall(T.raw_cmd, VRFW.commands.VRFW_MENU_INPUT_CTRL)
    T.watchdog_log("freeze watchdog: recovered", "input switch was " .. tostring(okw and was), "now " .. tostring(okc and ctrl))
  end

  --- Internal: One frame of the freeze watchdog.
  function T.watchdog_tick()
    local W = T.WD
    local S = W.STEMS[T.stem or ""]
    if S == nil or not W.on or not T.installed or W.n >= W.MAX then
      return
    end
    local press = false
    for _, k in ipairs(W.KEYS) do
      local on = T.watchdog_device(k)
      if on and not W.held[k[1]] then
        press = true
      end
      W.held[k[1]] = on
    end
    if not press then
      return
    end
    if not T.watchdog_eligible(S) then
      W.presses, W.first = 0, nil
      return
    end
    -- a callback in the 3 frames after the press resets the count (W.cb is set by the callback wrappers)
    W.presses = W.presses + 1
    W.first = W.first or T.frame
    if W.presses >= W.PRESSES and T.frame - W.first >= W.SPAN and T.frame - W.last >= W.GAP
        and T.frame - W.cb > T.frame - W.first then
      W.n, W.last = W.n + 1, T.frame
      local why = W.presses .. " Accept / Back presses in " .. (T.frame - W.first) .. " frames, no input callback"
      W.presses, W.first = 0, nil
      pcall(T.watchdog_dump, S, why)
      if not S.dump_only then pcall(T.watchdog_recover, S) end
    end
  end

  --- Internal: open-flow watch settings.
  T.FLOW = {OPEN_WATCH = {personal_plate_menu = 1427722143}, LINES = 16, lines = 0}

  --- Internal: Installs the open-flow watch of this menu.
  function T.flow_install()
    local own = T.FLOW.OPEN_WATCH[T.stem or ""]
    if own == nil then
      return
    end
    VRFW.host.hook_command({VRFW.commands.OPEN_LAYER}, function(nxt, c, ...)
      local ok, closing = pcall(T.raw_cmd, VRFW.commands.IS_CLOSING_MENU_OBJECT, own)
      if ok and closing == true and T.FLOW.lines < T.FLOW.LINES then
        T.FLOW.lines = T.FLOW.lines + 1
        pcall(T.raw_cmd, VRFW.commands.VRFW_LOG, "VRFW layer trace", T.vm, "f" .. T.frame,
          "layer opened while the menu closes", tostring((...)), tostring((select(2, ...))))
      end
      return nxt(c, ...)
    end, "VRFW.layer_trace", {menu = true})
  end

  --- Internal: One frame of the trace: cursor reset, flow and watchdog.
  function T.tick()
    --- Internal: frame counter of the trace.
    T.frame = T.frame + 1
    if T.cr ~= nil then
      pcall(T.cursor_reset)
    end
    if T.WD.on then
      pcall(T.watchdog_tick)
    end
    if not T.installed then
      pcall(T.install)
    end
    if T.on and T.logging and T.watch_frames > 0 then
      T.watch_frames = T.watch_frames - 1
      if T.watch_frames % T.EVERY == 0 then
        pcall(T.watch)
      end
    end
  end

  local init = OnInit
  if type(init) == "function" then
    OnInit = function(...)
      pcall(T.install)
      return init(...)
    end
  end
  local step = Step
  if type(step) == "function" then
    Step = function(...)
      return T.wrapped(step, ...)
    end
  end
  local VH = VRFW.host
  local p = type(VRFW.patch) == "table" and VRFW.patch.script or nil
  local stem = type(p) == "string" and p:gsub("_%d+%.%d+%.%d+[%.%d]*$", "") or nil
  if type(stem) == "string" and type(VH) == "table" and type(VH.on) == "function" then
    pcall(VH.on, stem, "OnInit", {id = "VRFW.input_trace_init", phase = "before", fn = function(...)
      pcall(T.install)
    end})
    pcall(VH.on, stem, "Step", {id = "VRFW.input_trace_step", phase = "after", fn = function(r, ...)
      if not T.ticking then
        pcall(T.tick)
      end
    end})
  end
end
