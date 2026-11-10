
local RC = {
  FIND = VRFW.commands.VRFW_REDEEM_CODE_FIND,
  FLAG_GET = VRFW.commands.GET_GLOBAL_BIT_FLAG, -- CMND_GET_GLOBAL_BIT_FLAG (flag) -> on.
  LOG = VRFW.commands.VRFW_LOG,
  SHOW_MENU = 1558704558,
  THIS_MENU = 1525898793,        -- information_top_menu
  GIFT_CODE = 2670717212,
  REFUSAL_NONE = 0,              -- neither of the retail refusal windows
  REFUSAL_USED = 2,              -- the retail "already used" window
  HAS_ROOM = 765340069,          -- (item, count) -> true when it fits
  ADD_ITEM = 1897915498,         -- CMND_ADD_ITEM_ONLY (item, count)
  FLAG_SET = 3258400760,         -- CMND_SET_GLOBAL_BIT_FLAG (flag, on)
  WINDOWS_FREE_ASK = 218753920,
  WINDOWS_FREE = 682363669,
  WINDOW_MAKE = 2127769271,      -- (11, text id, item) -> window
  WINDOW_RUN = 1089303874,       -- CMND_RUN_INFO_WIN_STACK (window)
  WINDOW_RUNNING = 3215700878,   -- CMND_IS_RUN_INFO_WIN_STACK
  TEXT_ITEM_GOT = 3675423478,    -- sysmes_item_get
  TEXT_NO_ROOM = 4076165421,     -- the window of callPasswordItemOverDialog (post_menu)
  TEXT_GET = VRFW.commands.TEXT_GET,  -- CMND_TEXT_GET (id) -> string
  ITEM_PARAM = 1883585771,       -- CMND_GET_ITEM_PARAM (item, 0) -> the item's name
  TEXT_GOT_COUNT = "VRFW.RedeemCode.ItemGot",   -- menu_text row "You received [CG]%s (x%d)[C]!" (name, count)
}

local function RC_GotText(item, count)
  local name = VRFW.host.command(RC.ITEM_PARAM, item, 0)
  local format = VRFW.host.command(RC.TEXT_GET, VRFW.ids.crc32(RC.TEXT_GOT_COUNT))
  if type(name) ~= "string" or name == "" or type(format) ~= "string" or format == "" then
    return nil
  end
  local ok, line = pcall(string.format, format, name, math.floor(tonumber(count) or 0))
  return ok and line or nil
end

local function RC_ItemWindow(text, item, count)
  funcLuaCommand(RC.WINDOWS_FREE_ASK)
  while not funcLuaCommand(RC.WINDOWS_FREE) do
    coroutine.yield()
  end
  local line = count ~= nil and RC_GotText(item, count) or nil
  local window = line ~= nil and VRFW.host.command(RC.WINDOW_MAKE, 11, line, item) or nil
  if window == nil or window == false then
    window = funcLuaCommand(RC.WINDOW_MAKE, 11, text, item)
  end
  funcLuaCommand(RC.WINDOW_RUN, window)
  while funcLuaCommand(RC.WINDOW_RUNNING) do
    coroutine.yield()
  end
end

local function RC_Redeem(entry)
  for _, reward in ipairs(entry.REWARDS) do
    if VRFW.host.command(RC.HAS_ROOM, reward[1], reward[2]) ~= true then
      VRFW.host.command(RC.LOG, "redeem_codes", "no room for an item: nothing given")
      RC_ItemWindow(RC.TEXT_NO_ROOM, reward[1])
      return
    end
  end
  for _, reward in ipairs(entry.REWARDS) do
    funcLuaCommand(RC.ADD_ITEM, reward[1], reward[2])
  end
  funcLuaCommand(RC.FLAG_SET, entry.FLAG, true)
  VRFW.host.command(RC.LOG, "redeem_codes", "code redeemed")
  for _, reward in ipairs(entry.REWARDS) do
    RC_ItemWindow(RC.TEXT_ITEM_GOT, reward[1], reward[2])
  end
end

VRFW.host.on("information_top_menu", "PasswordInputFunction", {
  id = "menu_engine.redeem_codes", phase = "around",
  fn = function(nxt, ...)
    local accepted = nil
    local function gift_code(next_command, ...)
      local _, text = ...
      local entry = type(text) == "string" and VRFW.host.command(RC.FIND, text) or nil
      if type(entry) ~= "table" or type(entry.REWARDS) ~= "table" then
        return next_command(...)
      end
      local on = VRFW.host.command(RC.FLAG_GET, entry.FLAG)
      if on == true or on == 1 then
        return false, RC.REFUSAL_USED
      end
      accepted = entry
      return false, RC.REFUSAL_NONE
    end
    local function show_menu(next_command, ...)
      if accepted ~= nil then
        return
      end
      return next_command(...)
    end
    local overrides = { [RC.GIFT_CODE] = gift_code, menu = { [RC.SHOW_MENU] = show_menu } }
    local r = table.pack(VRFW.host.with_commands(overrides, nxt, ...))
    if accepted ~= nil then
      RC_Redeem(accepted)
      funcLuaMenuCommand(RC.SHOW_MENU, RC.THIS_MENU, true)
    end
    return table.unpack(r, 1, r.n)
  end,
})
