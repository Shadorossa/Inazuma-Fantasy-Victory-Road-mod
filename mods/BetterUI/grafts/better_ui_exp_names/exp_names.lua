BetterUI = type(BetterUI) == "table" and BetterUI or {}
do
  local EXP_NAMES = {
    CARD_LAYER = 1774749226,                             -- chara card, 20 instances
    TEXT = 170976702,
    CMD_TEXT_VISIBLE = @crc:CMND_SET_MENU_TEXT_VISIBLE@, -- (layer, text, visible, idx)
    CMD_NODE_VISIBLE = 2158717427,                       -- (layer, node, visible, idx)
    LOG = @crc:CMND_VRFW_LOG@,
    logged = false,
  }

  local function hide_card_name(idx)
    if type(funcLuaMenuCommand) ~= "function" then
      return
    end
    pcall(funcLuaMenuCommand, EXP_NAMES.CMD_TEXT_VISIBLE, EXP_NAMES.CARD_LAYER, EXP_NAMES.TEXT, false, idx)
    pcall(funcLuaMenuCommand, EXP_NAMES.CMD_NODE_VISIBLE, EXP_NAMES.CARD_LAYER, EXP_NAMES.TEXT, false, idx)
    if not EXP_NAMES.logged then
      EXP_NAMES.logged = true
      pcall(funcLuaCommand, EXP_NAMES.LOG, "EVT exp_names", "player name hidden on the exp result cards")
    end
  end

  if BetterUI.exp_names_wrapped == nil then
    BetterUI.exp_names_wrapped = {}
  end

  local cur = _ENV["OnOpenLayer"]
  if type(cur) == "function" and not BetterUI.exp_names_wrapped[cur] then
    local w = function(a1, a2, ...)
      local r1, r2, r3, r4 = cur(a1, a2, ...)
      if a1 == EXP_NAMES.CARD_LAYER then
        hide_card_name(a2)
      end
      return r1, r2, r3, r4
    end
    BetterUI.exp_names_wrapped[w] = true
    _ENV["OnOpenLayer"] = w
  end

  -- UpdateAllCharaCard runs the card command again after the exp skip
  local upd = _ENV["UpdateAllCharaCard"]
  if type(upd) == "function" and not BetterUI.exp_names_wrapped[upd] then
    local w2 = function(...)
      local r1, r2, r3, r4 = upd(...)
      for i = 0, 19 do
        hide_card_name(i)
      end
      return r1, r2, r3, r4
    end
    BetterUI.exp_names_wrapped[w2] = true
    _ENV["UpdateAllCharaCard"] = w2
  end
end
