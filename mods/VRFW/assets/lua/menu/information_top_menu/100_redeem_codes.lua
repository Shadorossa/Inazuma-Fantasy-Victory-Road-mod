-- redeem_codes (VRFW mechanism; no content of its own): the retail «Gift code» row of the Information screen
-- (PasswordInputFunction) also takes the codes the mods DECLARE ([[VRFW.RedeemCode]] in their content\redeem_codes\).
--
-- The retail function opens the keyboard and asks the gift code command (CMND_PLAY_MENU_COMMAND_PARAM (text) -> accepted,
-- refusal, title, flag; refusal 1 = unknown, 2 = already used). Around it this handler answers that command for a
-- declared code (CMND_VRFW_REDEEM_CODE_FIND, scripts\redeem_codes.lua):
--   flag already on: refusal 2, the game's own «already used» window;
--   flag off: no accepted and no refusal, so the retail function shows no window; the menu stays hidden as in the
--   retail windows, the rewards are given and the flag set (CMND_SET_GLOBAL_BIT_FLAG, kept in the save: once per save),
--   with the windows of the game's item gifts, then the menu comes back. Without room for a reward nothing is given
--   and the code stays free.
-- Any other text goes to the game's lookup unchanged. No engine call at load time.

local RC = {
  FIND = VRFW_Cmd.VRFW_REDEEM_CODE_FIND,   -- CMND_VRFW_REDEEM_CODE_FIND (text) -> { FLAG, REWARDS = { { item, count } … } }
  FLAG_GET = VRFW_Cmd.GET_GLOBAL_BIT_FLAG, -- CMND_GET_GLOBAL_BIT_FLAG (flag) -> on
  LOG = VRFW_Cmd.EVT_LOG,
  SHOW_MENU = 1558704558,        -- funcLuaMenuCommand (menu, show): PasswordInputFunction hides and shows the screen
  THIS_MENU = 1525898793,        -- information_top_menu
  GIFT_CODE = 2670717212,        -- CMND_PLAY_MENU_COMMAND_PARAM (text) -> accepted, refusal, title, flag
  REFUSAL_NONE = 0,              -- neither of the retail refusal windows
  REFUSAL_USED = 2,              -- the retail «already used» window
  HAS_ROOM = 765340069,          -- (item, count) -> true when it fits
  ADD_ITEM = 1897915498,         -- CMND_ADD_ITEM_ONLY (item, count)
  FLAG_SET = 3258400760,         -- CMND_SET_GLOBAL_BIT_FLAG (flag, on)
  WINDOWS_FREE_ASK = 218753920,  -- both as post_menu does before one of these windows
  WINDOWS_FREE = 682363669,
  WINDOW_MAKE = 2127769271,      -- (11, text id, item) -> window
  WINDOW_RUN = 1089303874,       -- CMND_RUN_INFO_WIN_STACK (window)
  WINDOW_RUNNING = 3215700878,   -- CMND_IS_RUN_INFO_WIN_STACK
  TEXT_ITEM_GOT = 3675423478,    -- sysmes_item_get
  TEXT_NO_ROOM = 4076165421,     -- the window of callPasswordItemOverDialog (post_menu)
  TEXT_GET = VRFW_Cmd.TEXT_GET,  -- CMND_TEXT_GET (id) -> string
  ITEM_PARAM = 1883585771,       -- CMND_GET_ITEM_PARAM (item, 0) -> the item's name
  TEXT_GOT_COUNT = "VRFW.RedeemCode.ItemGot",   -- menu_text row «You received [CG]%s (x%d)[C]!» (name, count)
}

local function RC_Command(...)
  local r = table.pack(pcall(funcLuaCommand, ...))
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2, r.n)
end

-- the «received» line with the reward's count («Name (x1000)»); nil when the name or the row is not there (the game's
-- own window shows then)
local function RC_GotText(item, count)
  local name = RC_Command(RC.ITEM_PARAM, item, 0)
  local format = RC_Command(RC.TEXT_GET, VRFW_Id.Crc(RC.TEXT_GOT_COUNT))
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
  local window = line ~= nil and RC_Command(RC.WINDOW_MAKE, 11, line, item) or nil
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
    if RC_Command(RC.HAS_ROOM, reward[1], reward[2]) ~= true then
      RC_Command(RC.LOG, "redeem_codes", "no room for an item: nothing given")
      RC_ItemWindow(RC.TEXT_NO_ROOM, reward[1])
      return
    end
  end
  for _, reward in ipairs(entry.REWARDS) do
    funcLuaCommand(RC.ADD_ITEM, reward[1], reward[2])
  end
  funcLuaCommand(RC.FLAG_SET, entry.FLAG, true)
  RC_Command(RC.LOG, "redeem_codes", "code redeemed")
  for _, reward in ipairs(entry.REWARDS) do
    RC_ItemWindow(RC.TEXT_ITEM_GOT, reward[1], reward[2])
  end
end

VRFW_Host.on("information_top_menu", "PasswordInputFunction", {
  id = "menu_engine.redeem_codes", phase = "around",
  fn = function(nxt, ...)
    local accepted = nil
    local function gift_code(next_command, ...)
      local _, text = ...
      local entry = type(text) == "string" and RC_Command(RC.FIND, text) or nil
      if type(entry) ~= "table" or type(entry.REWARDS) ~= "table" then
        return next_command(...)
      end
      local on = RC_Command(RC.FLAG_GET, entry.FLAG)
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
    local r = table.pack(VRFW_Host.WithCommands(overrides, nxt, ...))
    if accepted ~= nil then
      RC_Redeem(accepted)
      funcLuaMenuCommand(RC.SHOW_MENU, RC.THIS_MENU, true)
    end
    return table.unpack(r, 1, r.n)
  end,
})
