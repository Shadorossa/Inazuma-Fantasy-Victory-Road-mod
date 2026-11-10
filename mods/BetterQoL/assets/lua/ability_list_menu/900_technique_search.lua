-- Technique name search of the ability list (Habilidades): X opens the game's text entry instead of «Cómo se usa»;
-- the list then shows the moves whose name holds the text, in every tab, with the game's filter on top.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.ability_search == nil and VRFW.host ~= nil then
  local STEM = "ability_list_menu"
  local ID = "BetterQoL.AbilitySearch."
  local USAGE_FUNCTION = 1456809643    -- OnFunction id of the «Cómo se usa» balloon
  local USAGE_GLYPH = 950905002        -- the key glyph of that guide entry
  local FUNC4 = 1435897304             -- CMD_FUNC4 (X)
  local LIST, TAB_BAR, DETAIL = 571205469, 4044286600, 1205526439
  local ITEM_SKILL = 901208644         -- list item id -> its move id
  local LIST_REFRESH, LIST_FOCUS, LAYER_REFRESH, GET_FOCUS = 4114514990, 306610847, 1778826357, 2603265800

  local S = { query = "", text = "", co = nil, serial = nil, first = false }
  BetterQoL.ability_search = S

  local function Log(...)
    VRFW.host.command(VRFW.commands.VRFW_LOG, "BetterQoL ability_search", ...)
  end

  -- the list rebuilt as CallBackSort does, then the tab's focus handler (empty list, button guide)
  local function Rebuild()
    funcLuaMenuCommand(LIST_REFRESH, LIST, true)
    funcLuaMenuCommand(LIST_FOCUS, LIST, 0)
    funcLuaMenuCommand(LAYER_REFRESH, DETAIL, 0, true)
    local tab = funcLuaMenuCommand(GET_FOCUS, TAB_BAR)
    funcLuaMenuCommand(LAYER_REFRESH, TAB_BAR, tab, true)
    if type(OnChangeFocus) == "function" then
      OnChangeFocus(TAB_BAR, tab)
    end
  end

  local function Stop()
    S.query, S.text, S.serial, S.first = "", "", nil, false
    VRFW.host.command(VRFW.commands.BETTERQOL_ABILITY_SEARCH_STOP)
  end

  local function Matches(item)
    local skill = VRFW.host.command(ITEM_SKILL, item)
    return type(skill) == "number" and skill ~= 0 and BetterQoL.text_search.move_name(skill):find(S.query, 1, true) ~= nil
  end

  -- judges the rows of the last build the search has not seen; a first search with no match is refused
  local function Judge()
    local r = table.pack(VRFW.host.command(VRFW.commands.BETTERQOL_ABILITY_SEARCH_PENDING))
    local serial, n = r[1], r[2]
    if type(serial) ~= "number" or serial == S.serial then
      return
    end
    S.serial = serial
    if type(n) ~= "number" or n == 0 then
      return
    end
    local hits, misses = {}, {}
    for i = 3, 2 + n do
      if type(r[i]) == "number" then
        local list = Matches(r[i]) and hits or misses
        list[#list + 1] = r[i]
      end
    end
    Log("search", S.query, "rows", n, "found", #hits)
    if S.first and #hits == 0 then
      Stop()
      BetterQoL.text_search.refuse()
      Rebuild()
      return
    end
    S.first = false
    local matched = #hits
    for _, item in ipairs(misses) do
      hits[#hits + 1] = item
    end
    VRFW.host.command(VRFW.commands.BETTERQOL_ABILITY_SEARCH_DECIDE, matched, table.unpack(hits))
    Rebuild()
  end

  -- what a confirmed text does: "" ends the search
  local function Apply(query, text)
    if query == "" then
      Stop()
    elseif VRFW.host.command(VRFW.commands.BETTERQOL_ABILITY_SEARCH_START) == true then
      S.query, S.text, S.serial, S.first = query, text, nil, true
    else
      Log("search not applied: the ability list hook is off")
      BetterQoL.text_search.refuse()
      return
    end
    Rebuild()
  end

  local function Search()
    local title = VRFW.crc32("betterqol_technique_search_title")
    if not BetterQoL.text_search.run(VRFW.crc32(STEM), title, S.text, Apply) then
      Log("text entry did not open")
    end
  end

  local function Resume()
    local ok, err = coroutine.resume(S.co)
    if not ok then
      Log("error", tostring(err))
      funcLuaMenuCommand(VRFW.commands.SET_INPUT_ENABLE_MENU_OBJECT, VRFW.crc32(STEM), true)
    end
    if not ok or coroutine.status(S.co) == "dead" then
      S.co = nil
    end
  end

  local function on(point, fn, create)
    VRFW.host.on(STEM, point, { id = ID .. point, phase = "around", create = create == true, fn = fn })
  end

  on("OnInit", function(nxt, ...)
    local r = table.pack(nxt(...))
    S.co = nil
    Stop()
    return table.unpack(r, 1, r.n)
  end)

  on("FinalizeMenu", function(nxt, ...)
    S.co = nil
    Stop()
    if nxt ~= nil then
      return nxt(...)
    end
  end, true)

  -- X: the search instead of the usage balloon
  on("OnFunction", function(nxt, id, ...)
    if id ~= USAGE_FUNCTION then
      return nxt(id, ...)
    end
    if S.co == nil then
      S.co = coroutine.create(Search)
      Resume()
    end
  end)

  on("Step", function(nxt, ...)
    if S.co ~= nil then
      Resume()
    elseif S.query ~= "" then
      local ok, err = pcall(Judge)
      if not ok then
        Log("judge error", tostring(err))
      end
    end
    if nxt ~= nil then
      return nxt(...)
    end
  end, true)

  -- the X entry of the button guide: "Search" in place of «Cómo se usa», shown on every row
  if VRFW.footer_prompts ~= nil then
    VRFW.footer_prompts.add({
      name = "BetterQoL.AbilitySearch",
      menu = STEM,
      text = VRFW.crc32("betterqol_technique_search"),
      icon = USAGE_GLYPH,
      replaces = USAGE_GLYPH,
      command = FUNC4,
      order = 100,
    })
    VRFW.footer_prompts.attach(STEM, "UpdateButtonGuide")
  end
end
