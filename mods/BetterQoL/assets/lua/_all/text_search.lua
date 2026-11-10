BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.text_search == nil then
  local PLAY_SOUND = 1917805374
  local SOUND_DECIDE, SOUND_REFUSED = 3848881948, 2086672038 -- sy0000, the buzzer
  local KEYBOARD = { OPEN = 962493425, BUSY = 422535539, TEXT = 1487869455, CLOSE = 3351189333, MAX_LENGTH = 20 }
  local KEYBOARD_WAIT_FRAMES = 10

  local T = {}
  BetterQoL.text_search = T

  -- "Infernal Penguin" -> "infernal penguin"
  local FOLD = {
    {"Á", "a"}, {"À", "a"}, {"Â", "a"}, {"Ä", "a"}, {"á", "a"}, {"à", "a"}, {"â", "a"}, {"ä", "a"},
    {"É", "e"}, {"È", "e"}, {"Ê", "e"}, {"Ë", "e"}, {"é", "e"}, {"è", "e"}, {"ê", "e"}, {"ë", "e"},
    {"Í", "i"}, {"Ì", "i"}, {"Î", "i"}, {"Ï", "i"}, {"í", "i"}, {"ì", "i"}, {"î", "i"}, {"ï", "i"},
    {"Ó", "o"}, {"Ò", "o"}, {"Ô", "o"}, {"Ö", "o"}, {"ó", "o"}, {"ò", "o"}, {"ô", "o"}, {"ö", "o"},
    {"Ú", "u"}, {"Ù", "u"}, {"Û", "u"}, {"Ü", "u"}, {"ú", "u"}, {"ù", "u"}, {"û", "u"}, {"ü", "u"},
    {"Ñ", "n"}, {"ñ", "n"}, {"Ç", "c"}, {"ç", "c"}, {"ß", "ss"},
  }
  T.fold = function(s)
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

  local SKILL_INFO_NAME = 4         -- CMND_GET_SOCCER_SKILL_INFO(move, 4) -> name text id
  local MOVE_NAME_TEXT = 720417636  -- a move's name text id -> its text
  local move_names = {}

  -- the folded name of move `skill`, asked once per move in this VM ("" = no name)
  T.move_name = function(skill)
    local cached = move_names[skill]
    if cached ~= nil then
      return cached
    end
    local name = ""
    local ok, name_id = VRFW.host.command(VRFW.commands.GET_SOCCER_SKILL_INFO, skill, SKILL_INFO_NAME)
    if ok and name_id then
      local s = VRFW.host.command(MOVE_NAME_TEXT, name_id)
      if type(s) == "string" then
        name = T.fold(s)
      end
    end
    move_names[skill] = name
    return name
  end

  T.refuse = function()
    funcLuaCommand(PLAY_SOUND, SOUND_REFUSED)
  end

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

  T.run = function(menu, title, initial, apply)
    funcLuaCommand(PLAY_SOUND, SOUND_DECIDE)
    funcLuaMenuCommand(VRFW.commands.SET_INPUT_ENABLE_MENU_OBJECT, menu, false)
    local text = AskText(title, initial)
    if text ~= nil then
      apply(T.fold(text), text)
    end
    funcLuaMenuCommand(VRFW.commands.SET_INPUT_ENABLE_MENU_OBJECT, menu, true)
    return text ~= nil
  end
end
