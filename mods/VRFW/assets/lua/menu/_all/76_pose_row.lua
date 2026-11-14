-- lua_patch.scope: used
-- VRFW pose rows, game Lua side (every menu VM; script side scripts\pose_row.lua; docs/framework/pose-row.md).
if VRFW.pose_row == nil then
  local R = {
    MENU = 3907790619,
    KEY_ROW = 970894462,         -- crc32("vrfw_pose_row"): parameter in, crc32 of the key
    KEY_CTX = 734132499,         -- crc32("vrfw_pose_row_context"): parameter in, the context
    KEY_PICK = 203690515,        -- crc32("vrfw_pose_row_pick"): parameter out, the picked entry
    KEY_FOCUS = 2167843046,
    OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT,       -- CMND_OPEN_MENU_OBJECT
    IS_MENU = VRFW.commands.IS_EXIST_MENU_OBJECT,        -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
    VISIBLE_ALL = 2171393651,    -- (layer, on): every instance of a layer
    START_WAIT = 60,             -- frames the screen may take to appear
    LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM,      -- (layer) -> instance count
    IS_VISIBLE = VRFW.commands.IS_LAYER_VISIBLE,     -- (layer, instance) -> visible
    MODEL_HANDLE = 3895705890,   -- (layer, instance, slot) -> the menu model's handle (0: none)
    MODEL_VISIBLE = 1890282463,  -- (handle, on)
    LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,   -- CMND_SET_LAYER_VISIBLE (layer, instance, on)
  }
  --- Advanced: State of the pose rows extension.
  VRFW.pose_row = R

  --- Internal: Logs through the pose-row tag.
  function R.log(...)
    if PRINT ~= nil then pcall(PRINT, "VRFW.pose_row", ...) end
  end

  local function param(key, value)
    VRFW.param.clear(key)
    VRFW.param.set(key, value)
  end

  local function up()
    local r = VRFW.host.menu_command(R.IS_MENU, R.MENU)
    return r == true
  end

  --- Advanced: Hides the visible layers of `layers`; answers what it hid.
  function R.hide_layers(layers)
    local hidden = {}
    for _, l in ipairs(layers or {}) do
      local okn, n = pcall(funcLuaMenuCommand, R.LAYER_NUM, l)
      for i = 0, (okn and type(n) == "number" and n or 0) - 1 do
        local okv, v = pcall(funcLuaMenuCommand, R.IS_VISIBLE, l, i)
        if okv and v == true then
          pcall(funcLuaMenuCommand, R.LAYER_VISIBLE, l, i, false)
          hidden[#hidden + 1] = {l, i}
        end
      end
    end
    return hidden
  end

  --- Advanced: Shows again what hide_layers hid.
  function R.show_layers(hidden)
    for _, h in ipairs(hidden or {}) do
      pcall(funcLuaMenuCommand, R.LAYER_VISIBLE, h[1], h[2], true)
    end
  end

  --- Internal: The caller's models: hidden (on = false: each one's handle kept), shown again (on = true).
  function R.model_show(list, on, kept)
    kept = kept or {}
    for k, m in ipairs(list or {}) do
      local h = kept[k]
      if not on then
        local ok, v = pcall(funcLuaMenuCommand, R.MODEL_HANDLE, m[1], 0, m[2] or 0)
        h = ok and type(v) == "number" and v ~= 0 and v or nil
        kept[k] = h or false
      end
      if h then
        pcall(funcLuaCommand, R.MODEL_VISIBLE, h, on)
      end
      if not on then
        R.log("caller model", m[1], m[2] or 0, h and "hidden by its handle" or "has no model")
      end
    end
    return kept
  end

  --- Advanced: The caller's models hidden (on = false) / given back (on = true, with what the hide returned).
  function R.caller_models(list, on, kept)
    if list == nil or #list == 0 then
      return nil
    end
    if type(SetCharaEnable) == "function" then
      local ok, err = pcall(SetCharaEnable, on)
      R.log("caller models", on and "given back" or "hidden", "by the menu's SetCharaEnable", ok and "" or tostring(err))
      if ok then
        return "menu"
      end
    end
    if kept == "menu" then
      kept = nil
    end
    return R.model_show(list, on, kept)
  end

  --- Internal: a whole-number parameter out of the screen, read once (0 when absent).
  function R.take(k)
    local v = VRFW.param.take(k)
    if v == nil then
      return 0
    end
    v = math.floor(tonumber(v) or 0)
    if v >= 2147483648 then
      v = v - 4294967296
    end
    return v
  end

  --- Advanced: Opens the pose row screen for `key` in a coroutine; answers pick and focus, nil on a cancel.
  function R.open(key, context, opts)
    opts = opts or {}
    if type(key) ~= "string" or coroutine.running() == nil then
      R.log("open", tostring(key), "not in a coroutine or no key")
      return nil
    end
    param(R.KEY_ROW, CRC32(key))
    param(R.KEY_CTX, math.floor(tonumber(context) or 0))
    VRFW.param.clear(R.KEY_PICK)
    VRFW.param.clear(R.KEY_FOCUS)
    if (tonumber(opts.focus) or 0) > 0 then
      param(R.KEY_FOCUS, math.floor(opts.focus))
    end
    local yielded = vrfw_hub_yield ~= nil and pcall(vrfw_hub_yield, true, R.MENU)
    local hidden = R.hide_layers(opts.hide)
    local kept = R.caller_models(opts.models, false)
    pcall(funcLuaCommand, R.OPEN_MENU, R.MENU)
    R.log("open", key, "context", tostring(context), "requested")
    local t = 0
    while not up() and t < R.START_WAIT do
      t = t + 1
      coroutine.yield()
    end
    local opened = up()
    R.log("open", key, opened and "up after" or "not up after", t, "frames")
    while up() do
      coroutine.yield()
    end
    R.show_layers(hidden)
    R.caller_models(opts.models, true, kept)
    if yielded then pcall(vrfw_hub_yield, false, R.MENU) end
    local pick, focus = R.take(R.KEY_PICK), R.take(R.KEY_FOCUS)
    R.log("open", key, "context", tostring(context), opened and "shown" or "never shown", "pick", pick, "focus", focus)
    if not opened then return nil end
    return pick, focus > 0 and focus or nil
  end
end
