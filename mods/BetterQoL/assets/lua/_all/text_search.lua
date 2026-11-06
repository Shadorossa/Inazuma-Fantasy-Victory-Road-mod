-- BetterQoL › name search, the part every search of the mod shares (the shop's technique search, the album's player
-- search): the game's text entry and the text folding. Caller rules: which menu, which title, what a confirmed text
-- does. A caller runs T.Run inside a coroutine resumed from its Step. Definitions only: no engine call at load.
--   BetterQoL.TextSearch.Fold(s)   -> s lower case, no accents / diaeresis / tilde, no markup, spaces collapsed
--   BetterQoL.TextSearch.Refuse()  -> the buzzer of a search that found nothing
--   BetterQoL.TextSearch.Run(menu, title, initial, apply) -> false when the text entry did not open. Input of `menu`
--     off, decide sound, the text entry (title: a text id), apply(folded text, text as typed), input of `menu` on.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.TextSearch == nil then
  local PLAY_SOUND = 1917805374
  local SOUND_DECIDE, SOUND_REFUSED = 3848881948, 2086672038 -- sy0000, the buzzer
  local KEYBOARD = { OPEN = 962493425, BUSY = 422535539, TEXT = 1487869455, CLOSE = 3351189333, MAX_LENGTH = 20 }
  local KEYBOARD_WAIT_FRAMES = 10

  local T = {}
  BetterQoL.TextSearch = T

  -- «Pingüino Infernal» -> «pinguino infernal»
  local FOLD = {
    {"Á", "a"}, {"À", "a"}, {"Â", "a"}, {"Ä", "a"}, {"á", "a"}, {"à", "a"}, {"â", "a"}, {"ä", "a"},
    {"É", "e"}, {"È", "e"}, {"Ê", "e"}, {"Ë", "e"}, {"é", "e"}, {"è", "e"}, {"ê", "e"}, {"ë", "e"},
    {"Í", "i"}, {"Ì", "i"}, {"Î", "i"}, {"Ï", "i"}, {"í", "i"}, {"ì", "i"}, {"î", "i"}, {"ï", "i"},
    {"Ó", "o"}, {"Ò", "o"}, {"Ô", "o"}, {"Ö", "o"}, {"ó", "o"}, {"ò", "o"}, {"ô", "o"}, {"ö", "o"},
    {"Ú", "u"}, {"Ù", "u"}, {"Û", "u"}, {"Ü", "u"}, {"ú", "u"}, {"ù", "u"}, {"û", "u"}, {"ü", "u"},
    {"Ñ", "n"}, {"ñ", "n"}, {"Ç", "c"}, {"ç", "c"}, {"ß", "ss"},
  }
  T.Fold = function(s)
    if type(s) ~= "string" then
      return ""
    end
    s = s:gsub("<[^>]*>", "")
    for _, p in ipairs(FOLD) do
      s = s:gsub(p[1], p[2])
    end
    s = s:lower():gsub("%s+", " ")
    return (s:gsub("^ ", ""):gsub(" $", ""))
  end

  T.Refuse = function()
    funcLuaCommand(PLAY_SOUND, SOUND_REFUSED)
  end

  -- the game's text entry: the text typed, or nil when it did not open
  local function AskText(title, initial)
    if funcLuaCommand(KEYBOARD.BUSY) == true then
      funcLuaCommand(KEYBOARD.CLOSE, "")
      coroutine.yield()
    end
    local ok = pcall(funcLuaCommand, KEYBOARD.OPEN, 0, initial or "", title, 0,
      KEYBOARD.MAX_LENGTH, 0, 0, 0, 0, 0, 0, true, true, 1)
    if not ok then
      return nil
    end
    local opened = false
    for _ = 1, KEYBOARD_WAIT_FRAMES do
      if funcLuaCommand(KEYBOARD.BUSY) == true then
        opened = true
        break
      end
      coroutine.yield()
    end
    if not opened then
      return nil
    end
    local typed = initial or ""
    while funcLuaCommand(KEYBOARD.BUSY) == true do
      local t = funcLuaCommand(KEYBOARD.TEXT) -- the live text (the final answer alone is not reliable)
      if type(t) == "string" then
        typed = t
      end
      coroutine.yield()
    end
    local text = funcLuaCommand(KEYBOARD.TEXT)
    if type(text) == "string" and text ~= "" then
      return text
    end
    return typed
  end

  T.Run = function(menu, title, initial, apply)
    funcLuaCommand(PLAY_SOUND, SOUND_DECIDE)
    funcLuaMenuCommand(VRFW_Cmd.SET_INPUT_ENABLE_MENU_OBJECT, menu, false)
    local text = AskText(title, initial)
    if text ~= nil then
      apply(T.Fold(text), text)
    end
    funcLuaMenuCommand(VRFW_Cmd.SET_INPUT_ENABLE_MENU_OBJECT, menu, true)
    return text ~= nil
  end
end
