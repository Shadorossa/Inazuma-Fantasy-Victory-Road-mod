BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.view_forms = type(BetterQoL.view_forms) == "table" and BetterQoL.view_forms or {}
do
  local VF = BetterQoL.view_forms
  VF.HOST = "BetterQoL.view_forms"
  VF.COMMAND = 4039536666 --[[CMD_BETTERQOL_VIEW_FORMS]]
  VF.GLYPH = "<CMD_BETTERQOL_VIEW_FORMS>"
  VF.CTRLS = {1332654303 --[[MENU_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]],
    3526778166 --[[MENU_CTRL_SEPARATE_CROSS_KEY]]}
  VF.CHECK = 4265778440 --[[CMND_CHECK_INPUT_CMD (ctrl, command)]]
  VF.FORM_LIST = 2188689660 --[[CMND_VRFW_FORM_LIST (hdl) -> n, form1..formN]]
  VF.LOG = 519897777 --[[CMND_VRFW_LOG]]
  VF.GUARD = 8
  -- per VM state
  VF.vm = VF.vm or {stem = nil, loaded = false, entries = {}, was = false, tick = 0, last = -100}

  local function Log(...)
    VRFW.host.command(VF.LOG, "BetterQoL view_forms", ...)
  end

  -- the entries of the host that name `stem` (read once per VM, inside a callback)
  local function Load()
    local S = VF.vm
    if S.loaded then
      return S.entries
    end
    S.loaded = true
    S.entries = {}
    if type(VRFW.menu) ~= "table" or type(VRFW.menu.entries) ~= "function" or S.stem == nil then
      return S.entries
    end
    local ok, list = pcall(VRFW.menu.entries, VF.HOST)
    if not ok or type(list) ~= "table" then
      return S.entries
    end
    for _, e in ipairs(list) do
      local menus = type(e.menus) == "string" and e.menus or ""
      for m in menus:gmatch("[^,]+") do
        if m == S.stem then
          S.entries[#S.entries + 1] = e
          break
        end
      end
    end
    if #S.entries > 0 then
      local keys = {}
      for _, e in ipairs(S.entries) do
        keys[#keys + 1] = tostring(e.key) .. " -> " .. tostring(e.value)
      end
      Log(S.stem, table.concat(keys, "; "))
    end
    return S.entries
  end

  -- a global function by name ("Name" or "A.B")
  local function Resolve(name)
    if type(name) ~= "string" then
      return nil
    end
    local v = _G
    for part in name:gmatch("[^.]+") do
      if type(v) ~= "table" then
        return nil
      end
      v = rawget(v, part)
    end
    return type(v) == "function" and v or nil
  end

  -- is `stem` (this VM's script) one of the declared menus?
  function VF.declared(stem)
    local S = VF.vm
    if stem ~= nil and stem ~= S.stem then
      return false
    end
    return #Load() > 0
  end

  -- the action's command fired this frame on one of its controllers (raw, no edge)
  function VF.pressed()
    for _, c in ipairs(VF.CTRLS) do
      local v = VRFW.host.command(VF.CHECK, c, VF.COMMAND)
      if v == true then
        return true
      end
    end
    return false
  end

  function VF.down(stem)
    return VF.declared(stem) and VF.pressed()
  end

  function VF.forms(hdl)
    local r = {VRFW.host.command(VF.FORM_LIST, hdl)}
    local t, src = {}, {}
    local answered = type(r[1]) == "number"
    if answered then
      local n = r[1]
      for i = 1, n do
        if type(r[i + 1]) == "number" then
          t[#t + 1] = r[i + 1]
          local s = r[n + i + 1]
          src[#src + 1] = type(s) == "string" and s or "?"
        end
      end
    end
    if #t == 0 then
      t[1], src[1] = 0, "-"
    end
    return t, src, answered
  end

  function VF.tick()
    local S = VF.vm
    S.tick = S.tick + 1
    if S.loaded and #S.entries == 0 then
      return
    end
    if #Load() == 0 then
      return
    end
    local p = VF.pressed()
    local edge = p and not S.was
    S.was = p
    if not edge or S.tick - S.last < VF.GUARD then
      return
    end
    S.last = S.tick
    for _, e in ipairs(S.entries) do
      local f = Resolve(e.value)
      if f ~= nil then
        local ok, err = pcall(f, e)
        if not ok then
          Log("action failed", tostring(e.key), tostring(err))
        end
      end
    end
  end

  local p = type(VRFW.patch) == "table" and VRFW.patch.script or nil
  local stem = type(p) == "string" and p:gsub("_%d+%.%d+%.%d+[%.%d]*$", "") or nil
  if type(stem) == "string" and VF.vm.stem == nil then
    VF.vm.stem = stem
    local point = type(rawget(_G, "PostStep")) == "function" and "PostStep" or "Step"
    local spec = {id = "BetterQoL.view_forms_tick", phase = "after", fn = function()
      pcall(VF.tick)
    end}
    local H = VRFW.host
    if type(H) == "table" and type(H.on) == "function" then
      pcall(H.on, stem, point, spec)
    else
      VRFW.host_queue = VRFW.host_queue or {}
      table.insert(VRFW.host_queue, {"on", stem, point, spec})
    end
  end
end
