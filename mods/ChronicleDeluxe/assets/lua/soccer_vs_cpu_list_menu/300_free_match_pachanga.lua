-- Chronicle Deluxe: the Pachanga mode of the free match list. Select (CMD_FUNC2, Tab on the keyboard) switches the list
-- between Match (the retail class menu) and Pachanga (a 5v5 friendly against the focused team). The key row is this
-- mod's own input row (content\menus\free_match_pachanga.toml) and arrives in OnFunction like every retail key. In
-- Pachanga mode the class menu picks the rival's class as in Match (soccer_vs_cpu_class_select_menu\
-- 300_free_match_pachanga.lua), each row's orb is painted by the framework's orb rule from the pachanga wins per class,
-- and the team panel shows the rival's five-a-side team (a [[VRFW.FormationFitTeams]] team, the team the pachanga
-- plays) on the retail 5-a-side pitch with the formation INCLUDE's own 5-a-side drawing (VRFW.formation.
-- five_a_side_view). The mode and the wins are kept in the save engine's per-save data of this mod;
-- scripts\free_match_pachanga.lua records the wins. No engine call at load time.
ChronicleDeluxe = type(ChronicleDeluxe) == "table" and ChronicleDeluxe or {}
ChronicleDeluxe.FreeMatchPachanga = ChronicleDeluxe.FreeMatchPachanga or {}
if VRFW.host ~= nil then
  local P = ChronicleDeluxe.FreeMatchPachanga
  local STEM = "soccer_vs_cpu_list_menu"
  local OWNER = "ChronicleDeluxe"
  local K = {
    FUNCTION = VRFW.ids.crc32("chronicle_deluxe_free_match_mode"),        -- the Select row's function
    KEY = VRFW.ids.crc32("CMD_FUNC2"),             -- Select on the pad, Tab on the keyboard
    GLYPH = 2387151820,           -- the guide glyph the retail menus show with CMD_FUNC2
    LIST = VRFW.ids.crc32("team05_03_soccer_cpu_opponent_list"),
    MENU = VRFW.ids.crc32("soccer_vs_cpu_list_menu"),
    CARD_ICON = VRFW.ids.crc32("team00_01_chara_card_for_soccer"),       -- the team panel's player icons, one instance per roster slot
    CARD_BLANK = VRFW.ids.crc32("team00_01_p1_chara_card_blank"),      -- the team panel's empty places, one instance per roster slot
    GUIDE_LINE = VRFW.ids.crc32("mainmenu90_05_content_guide_line01"),
    GUIDE_TEXT = VRFW.ids.crc32("_text_guide01"),
    TEAM_INFO = 2151743654,       -- (team, field) -> has, value
    MEMBER_INFO = 34355761,       -- (team, member, field, game, class) -> has, value
    SAVED_TAB = 3683890655,       -- The screen keeps its tab in this temp byte.
    SE_OK = VRFW.ids.crc32("sy0000"),
    CLASS = "ChronicleDeluxe.FreeMatchPachangaClass",   -- The parameter the class menu answers the chosen class in.
    TOP_MENU_MATCH = 570346750,   -- the param that tells soccer_top_menu.OpenList a match starts
    ARM = VRFW.ids.crc32("CMND_CHRONICLEDELUXE_FREE_MATCH_PACHANGA_ARM"),
    FIVE = VRFW.ids.crc32("CMND_CHRONICLEDELUXE_FREE_MATCH_PACHANGA_FIVE"),
    TEXT_MATCH = VRFW.ids.crc32("ChronicleDeluxe.FreeMatchModeMatch"),
    TEXT_PACHANGA = VRFW.ids.crc32("ChronicleDeluxe.FreeMatchModePachanga"),
    TEXT_HINT = VRFW.ids.crc32("ChronicleDeluxe.FreeMatchPachangaHint"),
    TEXT_ASK = VRFW.ids.crc32("ChronicleDeluxe.FreeMatchPachangaAsk"),
    TEXT_NO_FIVE = VRFW.ids.crc32("ChronicleDeluxe.FreeMatchPachangaNoFive"),
  }
  local MODE_KEY, WON_KEY = "free_match.mode", "free_match_pachanga.won."
  P.K = K
  P.rows = {}            -- list item instance -> the arguments of its last UpdateItem
  P.won = {}             -- game -> class -> won on this save (read once per list open)
  P.panel = nil          -- the arguments (team, game) of the team panel's last UpdateFormation
  P.fives = {}           -- free match team -> its five-a-side team, false when it has none (read once per list open)
  P.five_view = false    -- true while the team panel draws on the 5-a-side pitch (a new list opens in the 11 view)
  P.mode_cache = nil     -- "match" or "pachanga" (read once per list open)
  P.class_open = false   -- true while the class menu is over the list
  P.levelled = P.levelled or {}   -- five-a-side teams CMND_VRFW_TEAM_LEVEL re-levelled for a pachanga (their offsets go back at the next list open)

  local log = VRFW.logger.new("ChronicleDeluxe free_match_pachanga")

  local function store()
    return VRFW.save ~= nil and VRFW.save.open(OWNER) or nil
  end

  local function free_match()
    local FM = VRFW.free_match
    if type(FM) ~= "table" or type(FM.off) ~= "function" or FM.off() then return nil end
    return FM
  end

  -- BetterMenu's crest strip has its own input layer without the Select row, so the list keeps the Match mode there.
  local function strip_shown()
    local C = BetterMenu and BetterMenu.competition
    return type(C) == "table" and type(C.active) == "function" and C.active() == true
  end

  --- The list's current mode: "match" or "pachanga".
  function P.mode()
    if strip_shown() or free_match() == nil then return "match" end
    if P.mode_cache == nil then
      local s = store()
      local saved = s ~= nil and s.get(MODE_KEY, "match") or "match"
      P.mode_cache = saved == "pachanga" and "pachanga" or "match"
    end
    return P.mode_cache
  end

  -- the lowest class `game` offers (nil when the framework does not answer)
  local function lowest_class(game)
    local FM = free_match()
    local classes = FM ~= nil and FM.diffs(game) or nil
    return classes ~= nil and classes[1] or nil
  end

  --- True when a pachanga against `game` at class `d` was won on this save.
  function P.cleared(game, d)
    P.won[game] = P.won[game] or {}
    local won = P.won[game]
    if won[d] == nil then
      local s = store()
      local key = WON_KEY .. string.format("%.0f", game)
      -- A win stored without a class was played at the lowest offered class.
      won[d] = s ~= nil and (s.get(key .. "." .. d, false) == true
        or (s.get(key, false) == true and d == lowest_class(game))) or false
    end
    return won[d]
  end

  local function text(id)
    local s = VRFW.host.command(VRFW.commands.TEXT_GET, id)
    if type(s) == "string" and s ~= "" then return s end
    return nil
  end

  --- The five-a-side team a pachanga against free match team `team` plays; nil when it has none.
  function P.five(team)
    local five = P.fives[team]
    if five == nil then
      local id = VRFW.host.command(K.FIVE, team)
      five = type(id) == "number" and id ~= 0 and id or false
      if not five then log("no five-a-side team for team", string.format("0x%08X", VRFW.ids.unsigned(team))) end
      P.fives[team] = five
    end
    return five or nil
  end

  -- Opens or closes one pitch layer of the panel when it is not already in that state.
  local function set_pitch_open(layer, open)
    local is_open = funcLuaMenuCommand(VRFW.commands.IS_OPEN_LAYER, layer, 0) == true
    if is_open ~= open then
      -- Logged: a free match that never leaves the loading screen shows whether the panel reopened a pitch after the request.
      log("team panel pitch", tostring(layer), open and "opened" or "closed", "mode", tostring(P.mode_cache), "five view", tostring(P.five_view))
      funcLuaMenuCommand(open and VRFW.commands.OPEN_LAYER or VRFW.commands.CLOSE_LAYER, layer, 0)
    end
  end

  -- Both pitches attach the same cards, so like the retail team docks only the view's pitch is open: the other closes first.
  local function show_pitch(five)
    local F = VRFW.formation
    set_pitch_open(F.pitch(five and "eleven" or "five"), false)
    set_pitch_open(F.pitch(five and "five" or "eleven"), true)
  end

  -- the team panel drawn in the 5-a-side view (`five`) or the 11-a-side one; answers true when the view is the asked one.
  -- The retail 11-a-side panel this open never left is not touched: Match mode keeps the retail pitches (a pitch opened
  -- while the menu hands over to the match keeps it on the loading screen).
  local function panel_view(five)
    local ok, changed = VRFW.formation.five_a_side_view(five)
    if not ok then
      log("team panel view not switched", tostring(five), tostring(changed))
      return false
    end
    local was = P.five_view
    P.five_view = five
    if five or was or changed then show_pitch(five) end
    return true
  end

  -- the places past the five's players hidden (the card instances are roster slots; the INCLUDE places only starters)
  local function hide_past(five)
    local ok, formation = VRFW.host.command(K.TEAM_INFO, five, 3)
    local players = ok == true and VRFW.formation.players(formation) or nil
    local n = VRFW.host.menu_command(VRFW.commands.GET_CREATE_LAYER_NUM, K.CARD_ICON)
    if type(players) ~= "number" or players <= 0 or type(n) ~= "number" then
      log("no five-a-side size for the team panel", tostring(players), tostring(n))
      return
    end
    for slot = players, n - 1 do
      funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, K.CARD_ICON, slot, false)
      funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, K.CARD_BLANK, slot, false)
    end
  end

  -- the team panel drawn again by the retail UpdateFormation (forced past its cache)
  local function redraw_panel()
    if P.panel ~= nil and type(UpdateFormation) == "function" then pcall(UpdateFormation, P.panel[1], P.panel[2], true) end
  end

  -- the help line under the list: the pachanga hint in Pachanga mode, the retail line in Match mode
  local function draw_hint()
    local s = P.mode() == "pachanga" and text(K.TEXT_HINT) or text(3822200449)
    if s ~= nil then
      VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_STRING, K.GUIDE_LINE, K.GUIDE_TEXT, s, 0)
    end
  end

  -- the guide of the list again (the retail call of OnInit), with this mode's entry
  local function draw_guide()
    if type(UpdateButtonGuideFromTopMenu) == "function" then pcall(UpdateButtonGuideFromTopMenu, 11) end
  end

  local function shown_in(mode)
    return function() return not P.class_open and free_match() ~= nil and not strip_shown() and P.mode() == mode end
  end

  -- every row shown again through the retail UpdateItem (its name, crest and orbs)
  local function redraw_rows()
    for _, args in pairs(P.rows) do
      if type(UpdateItem) == "function" then pcall(UpdateItem, table.unpack(args, 1, 4)) end
    end
  end

  local function toggle()
    local mode = P.mode() == "pachanga" and "match" or "pachanga"
    P.mode_cache = mode
    local s = store()
    if s ~= nil then s.set(MODE_KEY, mode, true) end
    VRFW.host.command(VRFW.commands.SND_PLAY_SE, K.SE_OK)
    redraw_rows()
    redraw_panel()
    draw_hint()
    draw_guide()
    log("mode", mode)
  end

  -- the level the class card shows for `team` in `game` at class `class`: the retail average of its starting members
  local function rival_level(team, game, class)
    local has, count = VRFW.host.command(K.TEAM_INFO, team, 8)
    if has ~= true or type(count) ~= "number" then return nil end
    local sum, n = 0, 0
    for i = 0, count - 1 do
      local ok_slot, slot = VRFW.host.command(K.MEMBER_INFO, team, i, 7)
      local ok_level, level = VRFW.host.command(K.MEMBER_INFO, team, i, 6, game, class)
      if ok_slot == true and ok_level == true and type(slot) == "number" and slot < 20 and type(level) == "number" then
        sum, n = sum + level, n + 1
      end
    end
    if n == 0 then return nil end
    return math.ceil(sum / n)
  end

  local function story_of(game)
    local ok, row = funcLuaMenuCommand(1666448199, 3)
    if not ok then row = 0 end
    local tab = funcLuaCommand(VRFW.commands.GET_TEMP_BYTE_FLAG, K.SAVED_TAB)
    if IsStory ~= nil and IsStory(tab) and row == 0 then return 0 end
    return 1
  end

  local function ask(team)
    local ask_text = text(K.TEXT_ASK)
    local ok, name = VRFW.host.command(K.TEAM_INFO, team, 2)
    if ask_text == nil or ok ~= true or type(name) ~= "string" or name == "" then return true end
    funcLuaMenuCommand(1558704558, K.MENU, false)
    local yes = VRFW.question.ask((string.gsub(ask_text, "%%s", function() return name end, 1)),
      {on_open = function() funcLuaCommand(2529383714, 0, 1, 0) end})
    if not yes then funcLuaMenuCommand(1558704558, K.MENU, true) end
    return yes
  end

  -- Tells the player that `team` has no five-a-side team, so the pachanga against it cannot start.
  local function no_five(team)
    local no_five_text = text(K.TEXT_NO_FIVE)
    local ok, name = VRFW.host.command(K.TEAM_INFO, team, 2)
    if no_five_text == nil or ok ~= true or type(name) ~= "string" or name == "" then return end
    funcLuaMenuCommand(1558704558, K.MENU, false)
    VRFW.question.notice((string.gsub(no_five_text, "%%s", function() return name end, 1)))
    funcLuaMenuCommand(1558704558, K.MENU, true)
  end

  -- the pachanga against the focused team: the team of class `class` at that class's level, on the declared row
  local function launch(FM, game, class)
    local team = class ~= nil and FM.team(game, class) or nil
    if team == nil then
      log("no rival team for game", game)
      VRFW.host.command(VRFW.commands.SND_PLAY_SE, VRFW.ids.crc32("sy0003"))
      return
    end
    local five = P.five(team)
    if five == nil then
      VRFW.host.command(VRFW.commands.SND_PLAY_SE, VRFW.ids.crc32("sy0003"))
      no_five(team)
      return
    end
    if not ask(team) then return end
    local plan = VRFW.host.command(K.ARM, game, class)
    if type(plan) ~= "table" or type(plan.friendly) ~= "string" or type(plan.game) ~= "string" then
      log("no pachanga declaration answered for game", game)
      funcLuaMenuCommand(1558704558, K.MENU, true)
      VRFW.host.command(VRFW.commands.SND_PLAY_SE, VRFW.ids.crc32("sy0003"))
      return
    end
    local row, difficulty = VRFW.ids.crc32(plan.game), tonumber(plan.difficulty) or 1
    local level = rival_level(team, game, class)
    if level ~= nil then
      local ok, why = VRFW.host.command(VRFW.commands.VRFW_TEAM_LEVEL, five, row, difficulty, level)
      log("rival five", five, "of team", team, "game", game, "class", class, "level", level, tostring(ok), tostring(why))
      if ok == true then P.levelled[five] = true end
    end
    local started, reason = VRFW.match_start.start{
      friendly = plan.friendly, game = row, difficulty = difficulty, rival = five, black = false,
      overrides = { { "teams.rival.team", five } },
      set = function() return VRFW.match_start.pachanga_team(plan.friendly_active_team) end,
      on_reserved = function()
        if VRFW.param.has(K.TOP_MENU_MATCH) then VRFW.param.clear(K.TOP_MENU_MATCH) end
        VRFW.param.set(K.TOP_MENU_MATCH, 1)
      end,
      on_failed = function(why)
        log("pachanga start failed", tostring(why))
        funcLuaMenuCommand(1558704558, K.MENU, true)
      end,
    }
    log("pachanga start", tostring(started), tostring(reason), "game", game, "team", team, "five", five)
    if started ~= true then
      VRFW.host.command(VRFW.commands.VRFW_TEAM_LEVEL_RESTORE, five)
      P.levelled[five] = nil
      funcLuaMenuCommand(1558704558, K.MENU, true)
    end
  end

  if VRFW.footer_prompts ~= nil then
    VRFW.footer_prompts.add({name = "ChronicleDeluxe.FreeMatchModeMatch", menu = STEM, text = K.TEXT_MATCH, icon = K.GLYPH,
      command = K.KEY, order = 50, when = shown_in("match")})
    VRFW.footer_prompts.add({name = "ChronicleDeluxe.FreeMatchModePachanga", menu = STEM, text = K.TEXT_PACHANGA,
      icon = K.GLYPH, command = K.KEY, order = 50, when = shown_in("pachanga")})
    VRFW.footer_prompts.attach(STEM, "UpdateButtonGuideFromTopMenu")
  end

  -- a new list: the mode and the wins are read again for this open
  VRFW.host.on(STEM, "OnInit", {id = "ChronicleDeluxe.free_match_pachanga.open", phase = "before", fn = function()
    -- the list draws a five at the focused class row + its offsets: the offsets a pachanga wrote go back to the data's
    for five in pairs(P.levelled) do VRFW.host.command(VRFW.commands.VRFW_TEAM_LEVEL_RESTORE, five) end
    P.levelled = {}
    P.rows, P.won, P.mode_cache, P.class_open, P.panel, P.fives, P.five_view = {}, {}, nil, false, nil, {}, false
  end})

  VRFW.host.on(STEM, "OnFunction", {id = "ChronicleDeluxe.free_match_pachanga.key", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= K.FUNCTION then return nxt(a1, ...) end
      if free_match() == nil or strip_shown() then return end
      toggle()
    end})

  VRFW.host.on(STEM, "UpdateItem", {id = "ChronicleDeluxe.free_match_pachanga.orb", phase = "after",
    after = {"menu_engine.free_match_difficulty"},
    fn = function(r, a1, a2, a3, a4)
      if a2 == nil then return end
      P.rows[a2] = {a1, a2, a3, a4}
      local FM = free_match()
      if a3 == nil or a3 == 0 or FM == nil or P.mode() ~= "pachanga" then return end
      FM.draw_orb(a2, a3, P.cleared)
    end})

  -- In Pachanga mode the panel draws the focused team's five on the 5-a-side pitch; in Match mode the retail panel.
  VRFW.host.on(STEM, "UpdateFormation", {id = "ChronicleDeluxe.free_match_pachanga.panel", phase = "around",
    after = {"menu_engine.free_match_difficulty"},
    fn = function(nxt, a1, a2, a3, ...)
      if a1 == nil or a1 == 0 then return nxt(a1, a2, a3, ...) end
      P.panel = {a1, a2}
      local five = P.mode() == "pachanga" and P.five(a1) or nil
      if five == nil or not panel_view(true) then
        panel_view(false)
        return nxt(a1, a2, a3, ...)
      end
      local r = table.pack(nxt(five, a2, true, ...))
      hide_past(five)
      return table.unpack(r, 1, r.n)
    end})

  -- A pitch the menu opens while the panel shows the other view closes again, so one pitch holds the cards.
  VRFW.host.on(STEM, "OnOpenLayer", {id = "ChronicleDeluxe.free_match_pachanga.pitch", phase = "after",
    fn = function(r, a1)
      local F = VRFW.formation
      if P.mode() == "pachanga" and a1 == F.pitch(P.five_view and "eleven" or "five") then
        set_pitch_open(a1, false)
      end
    end})

  VRFW.host.on(STEM, "OnOpenLayer", {id = "ChronicleDeluxe.free_match_pachanga.hint", phase = "after",
    fn = function(r, a1)
      if a1 == K.GUIDE_LINE and P.mode() == "pachanga" then draw_hint() end
    end})

  VRFW.host.on(STEM, "OpenClassSelect", {id = "ChronicleDeluxe.free_match_pachanga.class_menu", phase = "around",
    fn = function(nxt, ...)
      P.class_open = true
      local r = table.pack(pcall(nxt, ...))
      P.class_open = false
      if not r[1] then error(r[2], 0) end
      return table.unpack(r, 2, r.n)
    end})

  VRFW.host.on(STEM, "OnDecideFocus", {id = "ChronicleDeluxe.free_match_pachanga.decide", phase = "around",
    before = {"menu_engine.free_match_difficulty"},
    fn = function(nxt, a1, a2, ...)
      local FM = free_match()
      if a1 ~= K.LIST or FM == nil or P.mode() ~= "pachanga" then return nxt(a1, a2, ...) end
      local ok, game = funcLuaMenuCommand(1666448199, 0)
      if not ok or type(game) ~= "number" or game == 0 then return nxt(a1, a2, ...) end
      if FM.locked(game, story_of(game)) then return nxt(a1, a2, ...) end
      local classes = FM.diffs(game)
      if classes ~= nil and #classes == 1 then return launch(FM, game, classes[1]) end
      -- The retail decide opens the class menu, which answers the chosen class in the parameter and closes.
      VRFW.param.replace(K.CLASS, 0)
      local r = table.pack(pcall(nxt, a1, a2, ...))
      local class = VRFW.param.take(K.CLASS)
      if not r[1] then error(r[2], 0) end
      if type(class) == "number" and class > 0 then launch(FM, game, class) end
      return table.unpack(r, 2, r.n)
    end})
end
