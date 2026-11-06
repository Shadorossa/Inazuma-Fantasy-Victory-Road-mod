-- redeem_codes (VRFW mechanism; no content of its own): the retail mailbox's «password» entry (post_menu,
-- callPasswordDialog) also takes the codes the mods DECLARE ([[VRFW.RedeemCode]] in their content\redeem_codes\).
--
-- The retail dialog opens the keyboard, then asks the password lookup (funcLuaMenuPostCommand 0x00B2EF78, the game's
-- password_list_config) for rows 0 and 1: found, item, count, flag. Around that dialog this handler answers the lookup
-- for a declared code (CMND_VRFW_REDEEM_CODE_FIND, scripts\redeem_codes.lua): row n = the code's reward n + 1 and its
-- flag. The retail flow then runs as for its own passwords: the room check, CMND_ADD_ITEM_ONLY, the «obtained»
-- windows and CMND_SET_GLOBAL_BIT_FLAG on the code's flag (kept in the save: once per save).
-- A declared code whose flag is already on answers «not found», and the retail «wrong password» window shows the
-- text row VRFW.RedeemCode.AlreadyRedeemed instead. Any other text goes to the game's lookup unchanged.
-- No engine call at load time.

local RC = {
  FIND = VRFW_Cmd.VRFW_REDEEM_CODE_FIND,   -- CMND_VRFW_REDEEM_CODE_FIND (text) -> { FLAG, REWARDS = { { item, count } … } }
  FLAG_GET = VRFW_Cmd.GET_GLOBAL_BIT_FLAG,  -- CMND_GET_GLOBAL_BIT_FLAG (flag) -> on
  TEXT_GET = VRFW_Cmd.TEXT_GET,             -- CMND_TEXT_GET (id) -> string
  LOOKUP = 11726712,                        -- 0x00B2EF78 funcLuaMenuPostCommand (text, row) -> found, item, count, flag
  WRONG_TEXT = 694160043,                   -- the text id of callPasswordErrorDialog («wrong password»)
  USED_TEXT = "VRFW.RedeemCode.AlreadyRedeemed",
}

local function RC_Command(...)
  local r = table.pack(pcall(funcLuaCommand, ...))
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2, r.n)
end

-- one password dialog: the declared code typed, asked once per text
local function RC_Session()
  local session = { text = nil, entry = nil, used = false }

  local function entry_of(text)
    if text ~= session.text then
      session.text = text
      local entry = type(text) == "string" and RC_Command(RC.FIND, text) or nil
      session.entry = type(entry) == "table" and type(entry.REWARDS) == "table" and entry or nil
      session.used = false
      if session.entry ~= nil then
        local on = RC_Command(RC.FLAG_GET, session.entry.FLAG)
        session.used = (on == true or on == 1)
      end
    end
    return session.entry
  end

  local function lookup(nxt, ...)
    local _, text, row = ...
    local entry = entry_of(text)
    if entry == nil then
      return nxt(...)
    end
    if session.used then
      return false
    end
    local reward = entry.REWARDS[(tonumber(row) or 0) + 1]
    if reward == nil then
      return false
    end
    return true, reward[1], reward[2], entry.FLAG
  end

  local function text_get(nxt, ...)
    local _, id = ...
    if session.used and id == RC.WRONG_TEXT then
      return nxt(RC.TEXT_GET, VRFW_Id.Crc(RC.USED_TEXT))
    end
    return nxt(...)
  end

  return { post = { [RC.LOOKUP] = lookup }, [RC.TEXT_GET] = text_get }
end

VRFW_Host.on("post_menu", "callPasswordDialog", {
  id = "menu_engine.redeem_codes", phase = "around",
  fn = function(nxt, ...)
    return VRFW_Host.WithCommands(RC_Session(), nxt, ...)
  end,
})
