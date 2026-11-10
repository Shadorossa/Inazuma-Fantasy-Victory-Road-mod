
local RC = {
  FIND = VRFW.commands.VRFW_REDEEM_CODE_FIND,
  FLAG_GET = VRFW.commands.GET_GLOBAL_BIT_FLAG,  -- CMND_GET_GLOBAL_BIT_FLAG (flag) -> on.
  TEXT_GET = VRFW.commands.TEXT_GET,             -- CMND_TEXT_GET (id) -> string
  LOOKUP = 11726712,
  WRONG_TEXT = 694160043,                   -- the text id of callPasswordErrorDialog ("wrong password")
  USED_TEXT = "VRFW.RedeemCode.AlreadyRedeemed",
}

local function RC_Session()
  local session = { text = nil, entry = nil, used = false }

  local function entry_of(text)
    if text ~= session.text then
      session.text = text
      local entry = type(text) == "string" and VRFW.host.command(RC.FIND, text) or nil
      session.entry = type(entry) == "table" and type(entry.REWARDS) == "table" and entry or nil
      session.used = false
      if session.entry ~= nil then
        local on = VRFW.host.command(RC.FLAG_GET, session.entry.FLAG)
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
      return nxt(RC.TEXT_GET, VRFW.ids.crc32(RC.USED_TEXT))
    end
    return nxt(...)
  end

  return { post = { [RC.LOOKUP] = lookup }, [RC.TEXT_GET] = text_get }
end

VRFW.host.on("post_menu", "callPasswordDialog", {
  id = "menu_engine.redeem_codes", phase = "around",
  fn = function(nxt, ...)
    return VRFW.host.with_commands(RC_Session(), nxt, ...)
  end,
})
