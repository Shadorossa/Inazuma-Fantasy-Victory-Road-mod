-- lua_patch.scope: used
-- VRFW pick cards, game Lua side (every menu VM; script side scripts\pick_cards.lua; docs/framework/pick-cards.md).
if VRFW.pick_cards == nil then
  local K = {
    MENU = 234125520,
    KEY_PICK = 3913043416,
    CARDS = VRFW.commands.VRFW_PICK_CARDS,           -- CMND_VRFW_PICK_CARDS (0) -> the set's header
    OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT,       -- CMND_OPEN_MENU_OBJECT
    IS_MENU = VRFW.commands.IS_EXIST_MENU_OBJECT,        -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
    START_WAIT = 60,             -- frames the screen may take to appear
  }
  VRFW.pick_cards = K

  --- Logs through the pick-cards tag.
  function K.log(...)
    if PRINT ~= nil then pcall(PRINT, "VRFW.pick_cards", ...) end
  end

  local function up()
    local r = VRFW.host.menu_command(K.IS_MENU, K.MENU)
    return r == true
  end

  local function take()
    local v = VRFW.param.take(K.KEY_PICK)
    if v == nil then
      return 0
    end
    v = math.floor(tonumber(v) or 0)
    if v >= 2147483648 then
      v = v - 4294967296
    end
    return math.max(v, 0)
  end

  --- Opens the card picker in a coroutine; answers the pick, nil on a cancel.
  function K.show(opts)
    opts = opts or {}
    if coroutine.running() == nil then
      K.log("show: not in a coroutine")
      return nil
    end
    local okh, head = pcall(funcLuaCommand, K.CARDS, 0)
    if not okh or type(head) ~= "table" or (tonumber(head.count) or 0) <= 0 then
      K.log("show: no cards set")
      return nil
    end
    VRFW.param.clear(K.KEY_PICK)
    local hidden = VRFW.pose_row ~= nil and VRFW.pose_row.hide_layers(opts.hide) or {}
    pcall(funcLuaCommand, K.OPEN_MENU, K.MENU)
    local t = 0
    while not up() and t < K.START_WAIT do
      t = t + 1
      coroutine.yield()
    end
    local opened = up()
    while up() do
      coroutine.yield()
    end
    if VRFW.pose_row ~= nil then VRFW.pose_row.show_layers(hidden) end
    local pick = take()
    K.log("show", opened and "shown" or "never shown", "cards", tostring(head.count), "pick", pick)
    if not opened then return nil end
    return pick
  end
end
