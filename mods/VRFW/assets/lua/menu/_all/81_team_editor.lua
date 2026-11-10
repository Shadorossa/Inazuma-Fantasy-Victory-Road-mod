-- menu_engine: the TEAM EDITOR service.
if VRFW.team_editor == nil then
  local E = {
    C = {
      SESSION_BEGIN = VRFW.commands.VRFW_SESSION_BEGIN,
      SESSION_END = VRFW.commands.VRFW_SESSION_END,
      SESSION_STATE = VRFW.commands.VRFW_SESSION_STATE,     -- CMND_VRFW_SESSION_STATE -> open, slot, discardedWrites, ...
      SESSION_RELOAD = VRFW.commands.VRFW_SESSION_RELOAD,   -- CMND_VRFW_SESSION_RELOAD -> ok, code
      LOAD_HEADER = 4179471494, IS_SAVE_WORKING = 1979970074, LOAD_GAME_DATA = 2585060058,
      LOAD_FAILED = 3772572101, APPLY = 3660094710,
      ADD_PARTY = VRFW.commands.ADD_PARTY,        -- CMND_ADD_PARTY
      VS_DOCK = VRFW.commands.GET_VS_USE_TEAM_SET,          -- CMND_GET_VS_USE_TEAM_SET
      PLACE_CHECK = 1730898405,
      PLACE = 193693077,
      POSITION_INDEX = 1721292418,   -- (set, team, position) -> ok, member index
      INDEX_HANDLE = 1720957768,     -- (set, team, index, 0) -> ok, handle
      TEAM_GET = VRFW.commands.GET_TEAM_SET_INFO,
      TEAM_SET = VRFW.commands.SET_TEAM_SET_INFO,
                                     -- 3 formation, 4 tactic (id, slot 0-2), 5 kit (uniform item), 7 kit off (0), 9 synergy (item, slot 0 flag / 1 pillar)
      ITEM_COUNT = VRFW.commands.GET_ITEM_NUM,       -- CMND_GET_ITEM_NUM (item) -> count
      ITEM_ADD = VRFW.commands.ADD_ITEM_ONLY,         -- CMND_ADD_ITEM_ONLY (item, count)
      OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT,         -- CMND_OPEN_MENU_OBJECT
      CLOSE_MENU = 320421347,        -- CMND_CLOSE_MENU_OBJECT (menu)
      -- menu commands (funcLuaMenuCommand, as the retail menus call them)
      MENU_EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT,      -- CMND_IS_EXIST_MENU_OBJECT (menu) -> exists
      MENU_INPUT = 1558704558,       -- (menu, on): the menu's input
      MENU_SUSPEND = 369172623,
      MENU_RESUME = 66378409,        -- (menu): the same back
      CALL_IN_MENU = 830228314,      -- (menu, "global function", ...)
      SOUND = VRFW.commands.SND_PLAY_SE,            -- (sound)
      MEMBER_EXP = VRFW.commands.VRFW_TEAM_MEMBER_EXP,
      TEAM_SET_KIT = VRFW.commands.VRFW_TEAM_SET_KIT,
    },
    DOCK = 937147172,                -- soccer_team_dock_menu
    MODEL_VIEW = 3685122053,         -- menu_chara_model_comp (a 3D model view)
    SUB_WINDOW = 968210065,
    TOP = 811496143,
    SCREEN_TOP = 91676902,
    -- the top menus that give the dock its background (the list of the retail SetActiveDockBackground)
    SCREEN_TOPS = { 3902542018, 91676902, 811496143, 3653404168, 1385239856, 1917973090 },
    -- mainmenu90_00_background, mainmenu90_01_header: a host's own, hidden under SCREEN_TOP
    HOST_CHROME = { 367379312, 575058101 },
    MENU_HIDE = 1670867360,
    MENU_SHOW = 3257327861,          -- (menu): drawn again
    BANK = 16,
    LAST_POSITION = 18,              -- 0-10 starters, 11-15 bench, 16-18 support
    RESERVE_FIRST = 20, RESERVE_LAST = 28,   -- the team's reserve positions (read back, never drawn)
    SE_NO = 2086672038,              -- sy0003 (refused)
    COACH_POSITION = 19,
    TACTIC_SLOTS = 3, SYNERGY_SLOTS = 2,
    -- cross-menu parameters of the foreign team mode (crc32 of the names), written while its dock is open
    FOREIGN_KEY = 4265785820,        -- VRFW_team_editor_foreign
    STADIUM_HIGH_KEY = 3441793561,   -- VRFW_team_editor_stadium_high (upper 16 bits of the map id)
    STADIUM_LOW_KEY = 2970805637,    -- VRFW_team_editor_stadium_low
    ROWS_KEY = 3645648100,           -- VRFW_team_editor_rows (bit k = dock list row kind k offered)
    TAB_KEY = 1657797995,           -- VRFW_team_editor_tab (1 = the team page mode, spec.tab)
    DIRECTION_KEY = 1934393829,
    PAGE_FUNCTION = 2294853123,
    PAGE_LEFT = 2053629800, PAGE_RIGHT = 3033167124,
    HEADER_OFF_KEY = 1242260664,    -- VRFW_team_editor_header_off (1 = spec.header false)
    LIST_TOP_KEY = 3144387975,      -- VRFW_team_editor_list_top (spec.list_top + 1, 0 = retail)
    FIELD_DY_KEY = 648944452,       -- VRFW_team_editor_field_dy (spec.field_dy)
    HEADER_TOP_KEY = 2137925169,
    HEADER_DX_KEY = "VRFW_team_editor_header_dx",   -- spec.header_dx + OFFSET_BIAS
    LOCK_IDENTITY_KEY = 1601930639, -- VRFW_team_editor_lock_identity (1 = spec.lock_identity)
    KEEP_KEY = 406294606,
    HIDDEN_CARD_ROWS_KEY = 2580972447,
    INLINE_CARDS_KEY = "VRFW_team_editor_inline_card_actions",   -- 1 = spec.inline_card_actions
    CARD_ACTION_KEY = "VRFW_team_editor_card_action",
                                    -- CARD_ACTION.POPUP or CARD_ACTION.PAGE (written by the dock, removed after)
    CARD_MOVE_KEY = "VRFW_team_editor_card_move",
    CARD_ACTION = { POPUP = 1, PAGE = 2 },
    OFFSET_BIAS = 4096,             -- a signed px offset kept as a positive parameter
    HIDE_PAGER_KEY = "VRFW_team_editor_hide_pager",   -- 1 = spec.hide_pager
    HIDE_LIST_KEY = 2065651157,     -- VRFW_team_editor_hide_list (1 = spec.hide_list)
    ICONS_KEY = 202318521,          -- VRFW_team_editor_icons (the number of spec.icons)
    ICON_PREFIX = "VRFW_team_editor_icon",
    ICON_MAX = 3,                   -- icon buttons in the panel row (vrfw_team_icon instances)
    -- spec.identity_choices: <prefix>_count and <prefix><i> (VRFW.param.set_u32) per choice
    CHOICE_PREFIXES = { emblems = "VRFW_team_editor_emblem_choice", kits = "VRFW_team_editor_kit_choice" },
    CHOICE_MAX = 8,                 -- choices of one kind
    ICON_SIZE = 46,                 -- default icon size (px)
    -- the dock list's row kinds a caller may offer for a foreign team (spec.rows): they open on the dock's team
    ROW = { LINEUP = 0, SPIRIT = 1, BONDS = 2, ABILITIES = 7, BANK = 8, HYPER_COMMANDS = 9, EQUIP_ALL = 10,
      TEAM_SETTINGS = 12 },
    ALL_ROWS = { 12, 0, 10, 1, 2, 7, 9, 8 },   -- the retail dock list's row kinds, in its order
    STATUS = 1131797651,             -- (handle, 4) -> chara_param
    KIND_TEST = 1,                   -- session kind: image + discarded saves only
    END_RESTORE = 0, END_RELOADED = 3,
    FORMATION = 935586083,           -- team_dock_formation_menu (the dock's own child)
    OPEN_WAIT = 300,                 -- frames for the dock to come up
    JOB_WAIT = 600,                  -- frames for a load job of the in-place reload
  }

  local logger
  local function Write(debug_level, ...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    logger = logger or VRFW.logger.new("VRFW team editor")
    local text = table.concat(parts, " ")
    if debug_level then
      logger.debug(text)
    else
      logger(text)
    end
  end

  -- per-action details: debug level
  local function Log(...)
    Write(true, ...)
  end

  -- refusals and failures: info level
  local function Note(...)
    Write(false, ...)
  end

  -- a menu command (the retail menus' channel), nil when it failed
  local function MenuCall(cmd, ...)
    local r = table.pack(pcall(funcLuaMenuCommand, cmd, ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
  end

  local function Exists(menu)
    return MenuCall(E.C.MENU_EXISTS, menu) == true
  end

  local function Int(v)
    return type(v) == "number" and math.floor(v) or 0
  end

  local function Wait(frames)
    for _ = 1, frames do
      coroutine.yield()
    end
  end

  -- the dock opened over the caller's menu
  local function OpenDock()
    VRFW.host.command(E.C.OPEN_MENU, E.DOCK)
  end

  -- the handle at a dock position (0 = empty) the dock positions a team's players may hold: 0-18 and the reserve positions
  local function Positions()
    local out = {}
    for position = 0, E.LAST_POSITION do out[#out + 1] = position end
    for position = E.RESERVE_FIRST, E.RESERVE_LAST do out[#out + 1] = position end
    return out
  end

  local function HandleAt(set, team, position)
    local ok, index = VRFW.host.command(E.C.POSITION_INDEX, set, team, position)
    if ok ~= true or type(index) ~= "number" then
      return 0
    end
    local ok2, handle = VRFW.host.command(E.C.INDEX_HANDLE, set, team, index, 0)
    return (ok2 == true and type(handle) == "number") and handle or 0
  end

  local function Place(handle, set, position)
    local ok, code = VRFW.host.command(E.C.PLACE_CHECK, handle, set, position, E.BANK, 0)
    if ok ~= true then
      Note("place refused by the retail check: position", position, "code", tostring(code))
      return false
    end
    VRFW.host.command(E.C.PLACE, set, position, E.BANK, handle, 0)
    return HandleAt(set, 0, position) == handle
  end

  -- every player of both teams of the dock (11v11 and 5v5) back to the club bank; -> players left in the 11v11 team
  local function Empty(set)
    for team = 0, 1 do
      for _, position in ipairs(Positions()) do
        local handle = HandleAt(set, team, position)
        if handle ~= 0 then
          VRFW.host.command(E.C.PLACE, E.BANK, position, set, handle, team)
        end
      end
    end
    local left = 0
    for _, position in ipairs(Positions()) do
      if HandleAt(set, 0, position) ~= 0 then
        left = left + 1
      end
    end
    return left
  end

  local function WaitJob()
    coroutine.yield()
    local k = 0
    while VRFW.host.command(E.C.IS_SAVE_WORKING) == true do
      k = k + 1
      if k > E.JOB_WAIT then
        return false
      end
      coroutine.yield()
    end
    return true
  end

  E.TEMPORARY_PREFIX = "VRFW_team_editor_temporary_"
  E.temporary = {}
  local function MarkTemporary(handle, param)
    E.temporary[#E.temporary + 1] = handle
    VRFW.param.replace(E.TEMPORARY_PREFIX .. string.format("%d", handle), param)
  end
  local function ClearTemporary()
    for _, handle in ipairs(E.temporary) do
      VRFW.param.clear(E.TEMPORARY_PREFIX .. string.format("%d", handle))
    end
    E.temporary = {}
  end

  -- the session closed: restore + verification, else the slot read again from its own file in place
  local function EndSession()
    ClearTemporary()
    local closed, code, dirty = VRFW.host.command(E.C.SESSION_END, E.END_RESTORE)
    if closed == true then
      Log("session closed: the game is the one before the dock (restored and verified)")
      return true
    end
    Note("session END refused (code", tostring(code), "dirty blocks", tostring(dirty), "): in-place reload of the slot's file")
    if VRFW.host.command(E.C.SESSION_RELOAD) ~= true then
      Note("in-place reload refused: saves stay discarded until the game goes back to the title")
      return false
    end
    VRFW.host.command(E.C.LOAD_HEADER)
    local ok = WaitJob()
    ok = ok and VRFW.host.command(E.C.LOAD_GAME_DATA, 1) and WaitJob() and VRFW.host.command(E.C.LOAD_FAILED) ~= true
    if not ok then
      Note("in-place reload failed: saves stay discarded until the game goes back to the title")
      return false
    end
    VRFW.host.command(E.C.APPLY)
    local reloaded, code2 = VRFW.host.command(E.C.SESSION_END, E.END_RELOADED)
    Log("in-place reload done, session closed", tostring(reloaded), tostring(code2))
    return reloaded == true
  end

  -- the dock over `host` until it is fully gone (it and its formation screen); false when it never came up.
  local function ScreenTopOpen(host)
    for _, menu in ipairs(E.SCREEN_TOPS) do
      if Exists(menu) then return nil end
    end
    local state = { hidden = {} }
    for _, layer in ipairs(E.HOST_CHROME) do
      if MenuCall(VRFW.commands.IS_OPEN_LAYER, layer, 0, host) == true then
        MenuCall(VRFW.commands.SET_LAYER_VISIBLE, layer, 0, false, host)
        state.hidden[#state.hidden + 1] = layer
      end
    end
    if VRFW.top_bar.hide ~= nil then pcall(VRFW.top_bar.hide, true) end
    VRFW.host.command(E.C.OPEN_MENU, E.SCREEN_TOP)
    local f = 0
    while not Exists(E.SCREEN_TOP) and f < E.OPEN_WAIT do
      f = f + 1
      coroutine.yield()
    end
    Note("team screen top menu", Exists(E.SCREEN_TOP) and "open" or "did not open", "after", f, "frame(s)")
    return state
  end

  local function ScreenTopClose(host, state)
    if state == nil then return end
    if Exists(E.SCREEN_TOP) then
      VRFW.host.command(E.C.CLOSE_MENU, E.SCREEN_TOP)
      local f = 0
      while Exists(E.SCREEN_TOP) and f < E.OPEN_WAIT do
        f = f + 1
        coroutine.yield()
      end
    end
    if VRFW.top_bar.hide ~= nil then pcall(VRFW.top_bar.hide, false) end
    for _, layer in ipairs(state.hidden) do
      MenuCall(VRFW.commands.SET_LAYER_VISIBLE, layer, 0, true, host)
    end
  end

  local function ShowDock(host, root)
    local top = Exists(E.TOP)
    Note("dock opening over host", tostring(host), "scene root", tostring(root == true), "; model view already up",
      tostring(Exists(E.MODEL_VIEW)), "; sub window up", tostring(Exists(E.SUB_WINDOW)))
    if host then
      MenuCall(E.C.MENU_INPUT, host, false)
      if not root then MenuCall(E.C.MENU_SUSPEND, host) end
    end
    if top then
      VRFW.host.command(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", false)
    end
    local screen_top = (host and not root) and ScreenTopOpen(host) or nil
    OpenDock()
    local f = 0
    while not Exists(E.DOCK) and f < E.OPEN_WAIT do
      f = f + 1
      coroutine.yield()
    end
    local opened = Exists(E.DOCK)
    if opened then
      Log("team dock open after", f, "frame(s)")
    else
      Note("the team dock did not open in", E.OPEN_WAIT, "frames")
    end
    -- never go on (read, restore the game) while the dock or its formation screen still exists
    while Exists(E.DOCK) or Exists(E.FORMATION) do
      coroutine.yield()
    end
    Wait(10)
    if opened then
      Log("team dock closed")
    end
    ScreenTopClose(host, screen_top)
    if top then
      VRFW.host.command(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", true)
    end
    if host then
      if not root then MenuCall(E.C.MENU_RESUME, host) end
      coroutine.yield()
      MenuCall(E.C.MENU_INPUT, host, true)
    end
    return opened
  end

  --- True when the team editor can open, or false, why.
  function E.can_open()
    local open = VRFW.host.command(E.C.SESSION_STATE)
    if open == nil then
      return false, "the framework's save sessions are off"
    end
    if open == true then
      return false, "a save session is already open"
    end
    return true
  end

  local function Hold(item)
    if Int(VRFW.host.command(E.C.ITEM_COUNT, item)) < 1 then
      VRFW.host.command(E.C.ITEM_ADD, item, 1)
    end
  end

  -- the club's coach at dock position 19 to the bank: the place is empty, as for a team of the game without a coach
  local function ClearCoach(set)
    local old = HandleAt(set, 0, E.COACH_POSITION)
    if old == 0 then
      return true
    end
    VRFW.host.command(E.C.PLACE, E.BANK, E.COACH_POSITION, set, old, 0)
    return HandleAt(set, 0, E.COACH_POSITION) == 0
  end

  local function PlaceCoach(set, coach, level)
    local handle = VRFW.host.command(E.C.ADD_PARTY, coach, level, false, false, 0, 0, false, false, false, E.BANK, 255, 255, 0,
      false, false, false, 0, false, false)
    if type(handle) ~= "number" or handle == 0 then
      Note("coach card", coach, "not created: the coach place is empty (", tostring(ClearCoach(set)), ")")
      return false
    end
    ClearCoach(set)
    if Place(handle, set, E.COACH_POSITION) then
      Log("coach card", coach, "-> temporary coach", handle)
      return true
    end
    Note("coach card", coach, "not placed: the coach place is empty")
    return false
  end

  local function FillRecord(set, spec, level)
    if Int(spec.coach) ~= 0 then
      PlaceCoach(set, Int(spec.coach), level)
    else
      Log("no coach given: the coach place is empty, as the team has none (", tostring(ClearCoach(set)), ")")
    end
    local emblem = Int(spec.emblem)
    if emblem ~= 0 then
      Hold(emblem)
    end
    VRFW.host.command(E.C.TEAM_SET, set, 0, 1, emblem)
    local kit = Int(spec.kit)
    if kit ~= 0 then
      for team = 0, 1 do
        local okk, now = VRFW.host.command(E.C.TEAM_SET_KIT, set, team, kit)
        if okk ~= true then
          Note("kit of team", team, "not written (now", tostring(now), ")")
        end
      end
    else
      VRFW.host.command(E.C.TEAM_SET, set, 0, 7, 0)
    end
    local okk, shown = VRFW.host.command(E.C.TEAM_GET, set, 0, 7)
    Log("kit", kit, "-> dock kit", okk == true and tostring(shown) or "unread", "; emblem", emblem)
    local tactics = type(spec.tactics) == "table" and spec.tactics or {}
    for slot = 0, E.TACTIC_SLOTS - 1 do
      local id = Int(tactics[slot + 1])
      VRFW.host.command(E.C.TEAM_SET, set, 0, 4, id, slot)
      local okt, now = VRFW.host.command(E.C.TEAM_GET, set, 0, 9, slot)
      Log("tactic slot", slot, id, "-> dock", okt == true and tostring(now) or "unread")
    end
    local synergies = type(spec.synergies) == "table" and spec.synergies or {}
    for slot = 0, E.SYNERGY_SLOTS - 1 do
      VRFW.host.command(E.C.TEAM_SET, set, 0, 9, Int(synergies[slot + 1]), slot)
    end
  end

  -- the temporary copy of the team in the dock: { handle -> param }, or nil + why
  local function Fill(set, spec)
    local left = Empty(set)
    if left > 0 then
      return nil, left .. " player(s) of the dock could not be moved to the bank"
    end
    local made, created, placed, starters = {}, 0, 0, 0
    local level = math.max(1, Int(spec.level))
    for _, m in ipairs(spec.members or {}) do
      local slot, param = Int(m[1]), Int(m[2])
      local own_level = Int(m[3])
      local exp_share = type(m[4]) == "number" and m[4] or nil
      local valid = (slot >= 0 and slot <= E.LAST_POSITION) or (slot >= E.RESERVE_FIRST and slot <= E.RESERVE_LAST)
      if valid and param ~= 0 then
        local handle = VRFW.host.command(E.C.ADD_PARTY, param, own_level > 0 and own_level or level, false, false, 0, 0, false, false,
          false, E.BANK, 255, 255, 0, false, false, false, 0, false, false)
        if type(handle) == "number" and handle ~= 0 then
          made[handle] = param
          if exp_share ~= nil then
            local oke = VRFW.host.command(E.C.MEMBER_EXP, handle, exp_share)
            if oke ~= true then Note("slot", slot, "card", param, "EXP bar not set") end
          end
          MarkTemporary(handle, param)
          created = created + 1
          Log("slot", slot, "card", param, "-> temporary player", handle)
          if Place(handle, set, slot) then
            placed = placed + 1
            if slot <= 10 then
              starters = starters + 1
            end
          else
            Note("slot", slot, "card", param, "not placed")
          end
        else
          Note("slot", slot, "card", param, "not created")
        end
        if created % 6 == 5 then
          coroutine.yield()
        end
      end
    end
    if starters < 11 then
      return nil, "only " .. starters .. " starters placed"
    end
    if Int(spec.formation) ~= 0 then
      VRFW.host.command(E.C.TEAM_SET, set, 0, 3, Int(spec.formation))
    end
    if type(spec.name) == "string" and spec.name ~= "" then
      VRFW.host.command(E.C.TEAM_SET, set, 0, 0, spec.name)
    end
    if spec.foreign or spec.tab then
      FillRecord(set, spec, level)
    elseif Int(spec.emblem) ~= 0 then
      VRFW.host.command(E.C.TEAM_SET, set, 0, 1, Int(spec.emblem))
    end
    Log("dock", set, "holds the team:", placed, "players placed")
    return made
  end

  -- the order left in the dock
  local function Read(set, made)
    local out = { members = {}, foreign = 0 }
    for _, position in ipairs(Positions()) do
      local handle = HandleAt(set, 0, position)
      if handle ~= 0 then
        if made[handle] then
          out.members[#out.members + 1] = { position, made[handle] }
          Log("read: position", position, "temporary player", handle, "-> card", made[handle])
        else
          out.foreign = out.foreign + 1
          Log("read: position", position, "club player", handle, "(not of the team)")
        end
      end
    end
    local ok, formation = VRFW.host.command(E.C.TEAM_GET, set, 0, 4)
    out.formation = (ok == true and type(formation) == "number") and formation or 0
    return out
  end

  -- the team page mode: the team's record as the player left it (name, crest, kit, coach, tactics)
  local function ReadRecord(set, out)
    local okn, name = VRFW.host.command(E.C.TEAM_GET, set, 0, 6)
    out.name = (okn == true and type(name) == "string") and name or nil
    local oke, emblem = VRFW.host.command(E.C.TEAM_GET, set, 0, 5, 0)
    out.emblem = (oke == true and type(emblem) == "number") and emblem or 0
    local okk, kit = VRFW.host.command(E.C.TEAM_GET, set, 0, 7)
    out.kit = (okk == true and type(kit) == "number") and kit or 0
    local coach = HandleAt(set, 0, E.COACH_POSITION)
    local card = coach ~= 0 and VRFW.host.command(E.STATUS, coach, 4) or 0
    out.coach = type(card) == "number" and card or 0
    out.tactics = {}
    for slot = 0, E.TACTIC_SLOTS - 1 do
      local okt, id = VRFW.host.command(E.C.TEAM_GET, set, 0, 9, slot)
      out.tactics[slot + 1] = (okt == true and type(id) == "number") and id or 0
    end
    local dir = VRFW.param.has(E.DIRECTION_KEY) and Int(VRFW.param.get(E.DIRECTION_KEY)) or 0
    out.direction = dir == 1 and -1 or (dir == 2 and 1 or 0)
    if VRFW.param.has(E.DIRECTION_KEY) then
      VRFW.param.clear(E.DIRECTION_KEY)
    end
    Log("team page read: name", tostring(out.name), "emblem", out.emblem, "kit", out.kit, "coach", out.coach,
      "direction", out.direction)
  end

  -- the foreign team mode's cross-menu parameters (the dock runs in its own menu VM): on while the dock is up
  local function SetForeign(spec)
    for _, key in ipairs({ E.FOREIGN_KEY, E.STADIUM_HIGH_KEY, E.STADIUM_LOW_KEY, E.ROWS_KEY, E.TAB_KEY,
        E.HEADER_OFF_KEY, E.LIST_TOP_KEY, E.FIELD_DY_KEY, E.KEEP_KEY, E.HEADER_TOP_KEY, E.HEADER_DX_KEY, E.LOCK_IDENTITY_KEY,
        E.HIDDEN_CARD_ROWS_KEY, E.HIDE_LIST_KEY, E.ICONS_KEY,
        E.INLINE_CARDS_KEY, E.CARD_ACTION_KEY, E.CARD_MOVE_KEY, E.HIDE_PAGER_KEY }) do
      if VRFW.param.has(key) then
        VRFW.param.clear(key)
      end
    end
    for i = 1, E.ICON_MAX do
      for _, part in ipairs({ "_row", "_w", "_h", "_sprite_hi", "_sprite_lo", "_atlas_hi", "_atlas_lo" }) do
        VRFW.param.clear(E.ICON_PREFIX .. i .. part)
      end
    end
    for _, prefix in pairs(E.CHOICE_PREFIXES) do
      VRFW.param.clear(prefix .. "_count")
      for i = 1, E.CHOICE_MAX do
        VRFW.param.clear(prefix .. i .. "_hi")
        VRFW.param.clear(prefix .. i .. "_lo")
      end
    end
    if not spec then
      return
    end
    -- the crests and kits a decide on the team page's header goes through
    local choices = type(spec.identity_choices) == "table" and spec.identity_choices or {}
    for kind, prefix in pairs(E.CHOICE_PREFIXES) do
      local n = 0
      for _, id in ipairs(type(choices[kind]) == "table" and choices[kind] or {}) do
        if n < E.CHOICE_MAX and Int(id) ~= 0 then
          n = n + 1
          VRFW.param.set_u32(prefix .. n, Int(id))
        end
      end
      if n > 0 then VRFW.param.set(prefix .. "_count", n) end
    end
    -- the list hidden and the icon buttons that replace it (the dock panel graft lays them out)
    if spec.hide_list == true then VRFW.param.set(E.HIDE_LIST_KEY, 1) end
    if spec.hide_pager == true then VRFW.param.set(E.HIDE_PAGER_KEY, 1) end
    local icons = 0
    for _, icon in ipairs(type(spec.icons) == "table" and spec.icons or {}) do
      local sprite = type(icon.sprite) == "string" and VRFW.crc32(icon.sprite) or Int(icon.sprite)
      if icons < E.ICON_MAX and type(icon) == "table" and sprite ~= 0 then
        icons = icons + 1
        VRFW.param.set(E.ICON_PREFIX .. icons .. "_row", Int(icon.row))
        VRFW.param.set(E.ICON_PREFIX .. icons .. "_w", Int(icon.w) > 0 and Int(icon.w) or E.ICON_SIZE)
        VRFW.param.set(E.ICON_PREFIX .. icons .. "_h", Int(icon.h) > 0 and Int(icon.h) or E.ICON_SIZE)
        VRFW.param.set_u32(E.ICON_PREFIX .. icons .. "_sprite", sprite)
        local atlas = type(icon.atlas) == "string" and VRFW.crc32(icon.atlas) or Int(icon.atlas)
        if atlas ~= 0 then VRFW.param.set_u32(E.ICON_PREFIX .. icons .. "_atlas", atlas) end
      end
    end
    if icons > 0 then VRFW.param.set(E.ICONS_KEY, icons) end
    local stadium = Int(spec.stadium) % 4294967296
    VRFW.param.set(E.STADIUM_HIGH_KEY, math.floor(stadium / 65536))
    VRFW.param.set(E.STADIUM_LOW_KEY, stadium % 65536)
    -- the player popup ("CHARACTER") rows the caller leaves out
    local hidden_mask = 0
    for _, kind in ipairs(type(spec.hide_card_rows) == "table" and spec.hide_card_rows or {}) do
      kind = Int(kind)
      if kind >= 0 and kind < 30 and math.floor(hidden_mask / 2 ^ kind) % 2 == 0 then
        hidden_mask = hidden_mask + 2 ^ kind
      end
    end
    if hidden_mask > 0 then VRFW.param.set(E.HIDDEN_CARD_ROWS_KEY, hidden_mask) end
    if spec.inline_card_actions == true then VRFW.param.set(E.INLINE_CARDS_KEY, 1) end
    local mask = 0
    local rows = type(spec.rows) == "table" and spec.rows or { E.ROW.LINEUP }
    if spec.tab then
      -- the team page: every retail row but the ones the caller hides (default: the club bank)
      local hidden = {}
      for _, kind in ipairs(type(spec.hide_rows) == "table" and spec.hide_rows or { E.ROW.BANK }) do
        hidden[Int(kind)] = true
      end
      rows = {}
      for _, kind in ipairs(E.ALL_ROWS) do
        if not hidden[kind] then rows[#rows + 1] = kind end
      end
      VRFW.param.set(E.TAB_KEY, 1)
      if spec.header == false then VRFW.param.set(E.HEADER_OFF_KEY, 1) end
      if tonumber(spec.list_top) then VRFW.param.set(E.LIST_TOP_KEY, Int(spec.list_top) + 1) end
      if tonumber(spec.header_top) then VRFW.param.set(E.HEADER_TOP_KEY, Int(spec.header_top) + 1) end
      if tonumber(spec.header_dx) then VRFW.param.set(E.HEADER_DX_KEY, Int(spec.header_dx) + E.OFFSET_BIAS) end
      if spec.lock_identity == true then VRFW.param.set(E.LOCK_IDENTITY_KEY, 1) end
      if tonumber(spec.field_dy) then VRFW.param.set(E.FIELD_DY_KEY, Int(spec.field_dy)) end
      if spec.keep then VRFW.param.set(E.KEEP_KEY, 1) end
    end
    for _, kind in ipairs(rows) do
      kind = Int(kind)
      if kind >= 0 and kind < 30 and math.floor(mask / 2 ^ kind) % 2 == 0 then
        mask = mask + 2 ^ kind
      end
    end
    VRFW.param.set(E.ROWS_KEY, mask)
    VRFW.param.set(E.FOREIGN_KEY, 1)
  end

  local SWAP_CHECKS = {
    [1730898405] = true,
    [99793139] = true,               -- the same check of the other swap kind
  }
  local GUIDE_COLUMNS, GUIDE_INPUTS = 2209673388, 452337289   -- the guide's columns, then its input commands
  local CMD_ENTER = 1981080283                                -- the guide's Accept input
  --- Sets the team editor view-only; answers whether it applied.
  function E.view_only(spec)
    spec = type(spec) == "table" and spec or {}
    if type(VRFW.host) ~= "table" or type(VRFW.host.wrap) ~= "function" then
      return false
    end
    local function board_locked()
      if not spec.skill_board_lock or type(VRFW.skill_board_lock) ~= "table" then
        return false, 0
      end
      return VRFW.skill_board_lock.locked()
    end
    local function on()
      local ok, v = pcall(E.foreign)
      return (ok and v ~= nil and not v.tab) or board_locked()
    end
    if spec.skill_board_lock and type(VRFW.skill_board_lock) == "table" then
      VRFW.host.wrap("OnInit", function(orig)
        return function(...)
          VRFW.skill_board_lock.read()
          return orig(...)
        end
      end, { stem = spec.stem, id = "menu_engine.team_editor_view_only.OnInit" })
    end
    local function refuse()
      pcall(funcLuaCommand, E.C.SOUND, E.SE_NO)
    end
    local function opts(name)
      return { stem = spec.stem, id = "menu_engine.team_editor_view_only." .. name }
    end
    VRFW.host.wrap("OnEnter", function(orig)
      return function(...)
        if on() then
          refuse()
          return 1
        end
        return orig(...)
      end
    end, opts("OnEnter"))
    VRFW.host.wrap("OnFunction", function(orig)
      return function(a1, ...)
        if on() and type(spec.functions) == "table" and spec.functions[a1] then
          refuse()
          return
        end
        return orig(a1, ...)
      end
    end, opts("OnFunction"))
    local keep = type(spec.guide_keep) == "table" and spec.guide_keep or {}
    for _, name in ipairs(type(spec.guides) == "table" and spec.guides or {}) do
      VRFW.host.wrap(name, function(orig)
        return function(...)
          if not on() then
            return orig(...)
          end
          -- the columns are held until the input commands arrive; the entries whose input is not kept leave both
          local held = nil
          local function hold_columns(nxt, cmd, ...)
            if held == nil then
              held = table.pack(cmd, ...)
              return
            end
            return nxt(cmd, ...)
          end
          local function filter_inputs(nxt, cmd, ...)
            if held ~= nil then
              local a = table.pack(cmd, ...)
              local drop = {}
              local locked, lock_text = board_locked()
              if type(a[4]) == "table" then
                for i, c in ipairs(a[4]) do
                  drop[i] = not keep[c]
                  -- the skill board lock: Accept stays in the guide with the lock's text
                  if locked and lock_text ~= 0 and c == CMD_ENTER and type(held[4]) == "table" then
                    drop[i] = false
                    held[4][i] = lock_text
                  end
                end
              end
              local function kept(list)
                if type(list) ~= "table" then
                  return list
                end
                local out = {}
                for i, v in ipairs(list) do
                  if not drop[i] then
                    out[#out + 1] = v
                  end
                end
                return out
              end
              for k = 4, 8 do
                held[k] = kept(held[k])
              end
              a[4] = kept(a[4])
              local h = held
              held = nil
              nxt(table.unpack(h, 1, h.n))
              return nxt(table.unpack(a, 1, a.n))
            end
            return nxt(cmd, ...)
          end
          local r = table.pack(pcall(VRFW.host.with_commands,
            { menu = { [GUIDE_COLUMNS] = hold_columns, [GUIDE_INPUTS] = filter_inputs } }, orig, ...))
          if held ~= nil then
            funcLuaMenuCommand(table.unpack(held, 1, held.n))
          end
          if not r[1] then
            error(r[2], 0)
          end
          return table.unpack(r, 2, r.n)
        end
      end, opts(name))
    end
    return true
  end

  --- Refuses a swap into a foreign team; answers as the swap.
  function E.guard_swap(nxt, ...)
    local refused = false
    local function check(send, ...)
      local _, _, to_set, _, from_set = ...
      if from_set ~= to_set then
        refused = true
        return false, 0
      end
      return send(...)
    end
    local overrides = {}
    for cmd in pairs(SWAP_CHECKS) do
      overrides[cmd] = check
    end
    local r = table.pack(pcall(VRFW.host.with_commands, overrides, nxt, ...))
    if refused then
      VRFW.host.command(E.C.SOUND, E.SE_NO)
      Note("swap refused: the player is not one of the team's")
    end
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  --- The card (chara_param id) of a temporary player of the open session (any menu VM); nil = not one.
  function E.temporary_card(handle)
    if type(handle) ~= "number" or handle == 0 then
      return nil
    end
    local card = VRFW.param.get(E.TEMPORARY_PREFIX .. string.format("%d", handle))
    return (type(card) == "number" and card ~= 0) and card or nil
  end

  --- The foreign team of the open dock as a table; nil when there is none.
  function E.foreign()
    if not VRFW.param.has(E.FOREIGN_KEY) then
      return nil
    end
    local function part(key)
      return VRFW.param.has(key) and Int(VRFW.param.get(key)) % 65536 or 0
    end
    local mask = VRFW.param.has(E.ROWS_KEY) and Int(VRFW.param.get(E.ROWS_KEY)) or 1
    local rows = {}
    for kind = 0, 29 do
      if math.floor(mask / 2 ^ kind) % 2 == 1 then
        rows[kind] = true
      end
    end
    local function value(key)
      return VRFW.param.has(key) and Int(VRFW.param.get(key)) or 0
    end
    local list_top, header_top = value(E.LIST_TOP_KEY), value(E.HEADER_TOP_KEY)
    local hidden_card_rows, hidden_mask = {}, value(E.HIDDEN_CARD_ROWS_KEY)
    for kind = 0, 29 do
      if math.floor(hidden_mask / 2 ^ kind) % 2 == 1 then hidden_card_rows[kind] = true end
    end
    local icons = {}
    for i = 1, math.min(value(E.ICONS_KEY), E.ICON_MAX) do
      local p = E.ICON_PREFIX .. i
      icons[i] = { row = value(p .. "_row"), w = value(p .. "_w"), h = value(p .. "_h"),
        sprite = VRFW.param.get_u32(p .. "_sprite") or 0, atlas = VRFW.param.get_u32(p .. "_atlas") or 0 }
    end
    local choices = {}
    for kind, prefix in pairs(E.CHOICE_PREFIXES) do
      choices[kind] = {}
      for i = 1, math.min(value(prefix .. "_count"), E.CHOICE_MAX) do
        choices[kind][i] = VRFW.param.get_u32(prefix .. i) or 0
      end
    end
    return { identity_choices = choices, icons = icons, hide_list = VRFW.param.has(E.HIDE_LIST_KEY), stadium = part(E.STADIUM_HIGH_KEY) * 65536 + part(E.STADIUM_LOW_KEY), rows = rows,
      tab = VRFW.param.has(E.TAB_KEY), keep = VRFW.param.has(E.KEEP_KEY),
      header = not VRFW.param.has(E.HEADER_OFF_KEY),
      list_top = list_top > 0 and list_top - 1 or nil, field_dy = value(E.FIELD_DY_KEY),
      header_top = header_top > 0 and header_top - 1 or nil,
      header_dx = VRFW.param.has(E.HEADER_DX_KEY) and value(E.HEADER_DX_KEY) - E.OFFSET_BIAS or 0, lock_identity = VRFW.param.has(E.LOCK_IDENTITY_KEY),
      hide_pager = VRFW.param.has(E.HIDE_PAGER_KEY), hidden_card_rows = hidden_card_rows, inline_card_actions = VRFW.param.has(E.INLINE_CARDS_KEY) }
  end

  --- Stores the card action mode, or clears it with nil.
  function E.set_card_action(mode)
    if mode == nil then
      if VRFW.param.has(E.CARD_ACTION_KEY) then VRFW.param.clear(E.CARD_ACTION_KEY) end
    else
      VRFW.param.set(E.CARD_ACTION_KEY, mode)
    end
  end

  --- The stored card action mode; nil when there is none.
  function E.card_action()
    if not VRFW.param.has(E.CARD_ACTION_KEY) then
      return nil
    end
    local mode = Int(VRFW.param.get(E.CARD_ACTION_KEY))
    return (mode == E.CARD_ACTION.POPUP or mode == E.CARD_ACTION.PAGE) and mode or nil
  end

  --- "Move" picked in the hidden lineup screen: the dock starts the move on its own pitch once the screen closed.
  function E.request_card_move()
    VRFW.param.set(E.CARD_MOVE_KEY, 1)
  end

  --- Takes the pending card move; answers true when there was one.
  function E.take_card_move()
    if not VRFW.param.has(E.CARD_MOVE_KEY) then
      return false
    end
    VRFW.param.clear(E.CARD_MOVE_KEY)
    return true
  end

  -- the kept dock (spec.keep) on screen: the host suspended under it, the dock resumed with its input
  local function KeptShow(k)
    MenuCall(E.C.MENU_INPUT, k.host, false)
    if not k.root then MenuCall(E.C.MENU_SUSPEND, k.host) end
    MenuCall(E.C.MENU_RESUME, E.DOCK)
    MenuCall(E.C.MENU_INPUT, E.DOCK, true)
  end

  -- the kept dock until the player leaves it.
  local function KeptVisit(k, spec)
    while Exists(E.DOCK) and not VRFW.param.has(E.DIRECTION_KEY) do
      coroutine.yield()
    end
    if Exists(E.DOCK) then
      MenuCall(E.C.MENU_INPUT, E.DOCK, false)
      MenuCall(E.C.MENU_SUSPEND, E.DOCK)
      if not k.root then MenuCall(E.C.MENU_RESUME, k.host) end
      local dir = Int(VRFW.param.get(E.DIRECTION_KEY))
      if type(spec.leaving) == "function" then
        pcall(spec.leaving, dir == 1 and -1 or 1)
      end
      local result = Read(k.set, k.made)
      result.opened, result.kept = true, true
      ReadRecord(k.set, result)
      coroutine.yield()
      MenuCall(E.C.MENU_INPUT, k.host, true)
      Log("kept dock hidden: read", #result.members, "team players, formation", result.formation)
      return result
    end
    E.kept_dock = nil
    while Exists(E.FORMATION) do
      coroutine.yield()
    end
    Wait(10)
    Log("team dock closed")
    if k.top then
      VRFW.host.command(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", true)
    end
    if not k.root then MenuCall(E.C.MENU_RESUME, k.host) end
    coroutine.yield()
    MenuCall(E.C.MENU_INPUT, k.host, true)
    local result = Read(k.set, k.made)
    result.opened = true
    ReadRecord(k.set, result)
    SetForeign(nil)
    if not EndSession() then
      return nil, "the game could not be put back as it was"
    end
    return result
  end

  --- True when a dock is kept, for `owner` when given.
  function E.kept(owner)
    return E.kept_dock ~= nil and (owner == nil or E.kept_dock.owner == tostring(owner)) and Exists(E.DOCK)
  end

  --- Asks for a page turn; answers true when the request was stored.
  function E.page_turn(direction)
    if not Exists(E.DOCK) or VRFW.param.has(E.DIRECTION_KEY) then
      return false
    end
    VRFW.host.command(E.C.CALL_IN_MENU, E.DOCK, "OnFunction", E.PAGE_FUNCTION, direction < 0 and E.PAGE_LEFT or E.PAGE_RIGHT)
    return VRFW.param.has(E.DIRECTION_KEY)
  end

  --- Releases the kept dock; answers true when nothing is left.
  function E.release(why)
    local k = E.kept_dock
    if k == nil then
      return true
    end
    E.kept_dock = nil
    Log("kept dock released:", tostring(why))
    if Exists(E.DOCK) then
      VRFW.host.command(E.C.CLOSE_MENU, E.DOCK)
      local f = 0
      while (Exists(E.DOCK) or Exists(E.FORMATION)) and f < E.OPEN_WAIT do
        f = f + 1
        coroutine.yield()
      end
      if Exists(E.DOCK) then
        Note("the kept dock did not close in", E.OPEN_WAIT, "frames")
      end
    end
    if k.top then
      VRFW.host.command(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", true)
    end
    SetForeign(nil)
    if VRFW.param.has(E.DIRECTION_KEY) then
      VRFW.param.clear(E.DIRECTION_KEY)
    end
    return EndSession()
  end

  E.PAGE = 1427722143                -- personal_plate_menu
  E.PAGE_HANDLE = 1038144478
  E.PAGE_HOST_KEY = "VRFW_team_editor_card_page_host"   -- the host menu (VRFW.param.set_u32) while its page is up
  E.PAGE_OPENED_CALL = "vrfw_team_editor_card_page_opened"  -- the host VM's globals the plate calls (CALL_IN_MENU)
  E.PAGE_CLOSED_CALL = "vrfw_team_editor_card_page_closed"
  E.page = nil                       -- { opened, closed } while this VM's page is up

  --- The menu hash hosting the player page; nil when there is none.
  function E.page_host()
    return VRFW.param.get_u32(E.PAGE_HOST_KEY)
  end

  local function ClearPageHost()
    VRFW.param.clear(E.PAGE_HOST_KEY .. "_hi")
    VRFW.param.clear(E.PAGE_HOST_KEY .. "_lo")
  end

  vrfw_team_editor_card_page_opened = function()
    if E.page ~= nil then
      E.page.opened = true
    end
  end
  vrfw_team_editor_card_page_closed = function()
    if E.page ~= nil then
      if not E.page.opened then
        Note("player page closed without its open call")
      end
      E.page.closed = true
    end
  end

  local function PageHandle(k, card, level)
    if k ~= nil then
      for handle, param in pairs(k.made or {}) do
        if param == card then
          return handle
        end
      end
      k.pages = k.pages or {}
      if k.pages[card] then
        return k.pages[card]
      end
    end
    local handle = VRFW.host.command(E.C.ADD_PARTY, card, math.max(1, Int(level)), false, false, 0, 0, false, false, false, E.BANK,
      255, 255, 0, false, false, false, 0, false, false)
    if type(handle) ~= "number" or handle == 0 then
      return 0
    end
    MarkTemporary(handle, card)
    if k ~= nil then
      k.pages[card] = handle
    end
    return handle
  end

  -- E.ShowCard(spec): the player page of a card that is no player of the save, until the player closes it (B).
  --- Shows the player page of a card that is no player of the save; answers info, or nil, why.
  function E.show_card(spec)
    spec = type(spec) == "table" and spec or {}
    local card, host = Int(spec.card), spec.host
    if card == 0 or host == nil then
      return nil, "no card or no host"
    end
    if E.page ~= nil then
      return nil, "a player page is already up"
    end
    local k = E.kept_dock
    if k ~= nil and not (k.owner == tostring(spec.owner) and Exists(E.DOCK)) then
      if not E.release("a player page asked") then
        return nil, "the kept dock's session did not end"
      end
      k = nil
    end
    local own = false
    if k == nil then
      local can, why = E.can_open()
      if not can then
        return nil, why
      end
      local ok, code = VRFW.host.command(E.C.SESSION_BEGIN, tostring(spec.owner or "VRFW"), 0, E.KIND_TEST)
      if ok ~= true then
        return nil, "the save session did not start (code " .. tostring(code) .. ")"
      end
      own = true
    end
    local handle = PageHandle(k, card, spec.level)
    if handle == 0 then
      if own then
        EndSession()
      end
      return nil, "card " .. tostring(card) .. ": no temporary player made"
    end
    local page = { opened = false, closed = false, shown = false }
    E.page = page
    VRFW.param.set_u32(E.PAGE_HOST_KEY, host)
    VRFW.param.replace(E.PAGE_HANDLE, handle)
    VRFW.host.command(E.C.OPEN_MENU, E.PAGE)
    -- the plate calls back when it is up (OnInit) and when it closes (FinalizeMenu): only those calls end the wait
    while not page.closed do
      coroutine.yield()
      if page.opened and not page.shown then
        page.shown = true
        Log("player page of card", card, "up: temporary player", handle, own and "(its own session)" or "(the kept dock's session)")
        if type(spec.shown) == "function" then
          pcall(spec.shown)
        end
      end
    end
    if VRFW.param.has(E.PAGE_HANDLE) then
      VRFW.param.clear(E.PAGE_HANDLE)
    end
    coroutine.yield()
    ClearPageHost()
    E.page = nil
    Log("player page of card", card, "closed")
    if type(spec.closed) == "function" then
      pcall(spec.closed)
    end
    if own and not EndSession() then
      return nil, "the game could not be put back as it was"
    end
    if not page.opened then
      return nil, "the player page did not open"
    end
    return { opened = true, handle = handle }
  end

  --- Opens the team dock for spec; answers an info table, or nil, why.
  function E.run(spec)
    spec = type(spec) == "table" and spec or {}
    local kept = E.kept_dock
    if kept ~= nil then
      if spec.keep and spec.tab and kept.owner == tostring(spec.owner) and Exists(E.DOCK) then
        if VRFW.param.has(E.DIRECTION_KEY) then
          VRFW.param.clear(E.DIRECTION_KEY)
        end
        KeptShow(kept)
        return KeptVisit(kept, spec)
      end
      if not E.release("another dock asked") then
        return nil, "the kept dock's session did not end"
      end
    end
    if spec.own then
      if ShowDock(spec.host, spec.host_root == true) then
        return { opened = true, own = true }
      end
      return nil, "the team dock did not open"
    end
    local can, why = E.can_open()
    if not can then
      return nil, why
    end
    local ok, code = VRFW.host.command(E.C.SESSION_BEGIN, tostring(spec.owner or "VRFW"), 0, E.KIND_TEST)
    if ok ~= true then
      return nil, "the save session did not start (code " .. tostring(code) .. ")"
    end
    Log("session open for", tostring(spec.owner), ": saves of the slot are discarded until the dock closes")
    local set = Int(VRFW.host.command(E.C.VS_DOCK))
    local made, err = Fill(set, spec)
    local result
    if made then
      if spec.foreign or spec.tab then
        SetForeign(spec)
      end
      if VRFW.param.has(E.DIRECTION_KEY) then
        VRFW.param.clear(E.DIRECTION_KEY)
      end
      if spec.keep and spec.tab and spec.host then
        -- the kept dock: opened over the host, then shown and hidden by L1 / R1 until Release
        local k = { owner = tostring(spec.owner), host = spec.host, set = set, made = made, top = Exists(E.TOP),
          root = spec.host_root == true }
        Note("kept dock opening over host", tostring(k.host), "scene root", tostring(k.root), "; model view already up",
          tostring(Exists(E.MODEL_VIEW)), "; sub window up", tostring(Exists(E.SUB_WINDOW)))
        MenuCall(E.C.MENU_INPUT, k.host, false)
        if not k.root then MenuCall(E.C.MENU_SUSPEND, k.host) end
        if k.top then
          VRFW.host.command(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", false)
        end
        OpenDock()
        local f = 0
        while not Exists(E.DOCK) and f < E.OPEN_WAIT do
          f = f + 1
          coroutine.yield()
        end
        if Exists(E.DOCK) then
          Log("team dock open after", f, "frame(s), kept between visits")
          E.kept_dock = k
          return KeptVisit(k, spec)
        end
        Note("the team dock did not open in", E.OPEN_WAIT, "frames")
        if not k.root then MenuCall(E.C.MENU_RESUME, k.host) end
        MenuCall(E.C.MENU_INPUT, k.host, true)
        SetForeign(nil)
        EndSession()
        return nil, "the team dock did not open"
      end
      local opened = ShowDock(spec.host, spec.host_root == true)
      if spec.foreign or spec.tab then
        SetForeign(nil)
      end
      if opened then
        result = Read(set, made)
        result.opened = true
        if spec.tab then
          ReadRecord(set, result)
        end
        Log("read:", #result.members, "team players placed,", result.foreign, "club players, formation", result.formation)
      else
        err = "the team dock did not open"
      end
    end
    if not EndSession() then
      return nil, "the game could not be put back as it was"
    end
    if not result then
      return nil, err
    end
    return result
  end

  E.SCENE = {
    OWNER_KEY = "VRFW_team_editor_scene_owner",
    BACK_KEY = "VRFW_team_editor_scene_back",       -- SetU32: crc32 of the menu the scene goes back to.
    RESUME_KEY = "VRFW_team_editor_scene_resume",   -- the host's resume value, handed back once
    PAGE_KEY = "VRFW_team_editor_scene_page",       -- the host's page, handed back once
    RETURN_KEY = "VRFW_team_editor_scene_return",   -- SetU32: crc32 of the menu a scene went back to.
    DIRECTION_KEY = "VRFW_team_editor_scene_direction",   -- the team page's leave direction + 1 (L1 0, Back 1, R1 2)
    IS_SCENE_ROOT = 2119959601,     -- (menu command) true when this menu is its menu scene's root
    FADE = 609722083,               -- (1 = to black / 0 = in, seconds)
    FADE_FRAMES = 20,
    ASK = 8,
    DONE_WAIT = 600,                -- frames the provider may take to keep the result
  }
  E.providers = E.providers or {}

  local function ClearU32(name)
    VRFW.param.clear(name .. "_hi")
    VRFW.param.clear(name .. "_lo")
  end

  local function SetNumber(key, v)
    if type(v) == "number" then
      VRFW.param.replace(key, Int(v))
    elseif VRFW.param.has(key) then
      VRFW.param.clear(key)
    end
  end

  local function TakeNumber(key)
    local v = VRFW.param.has(key) and VRFW.param.get(key) or nil
    if v ~= nil then VRFW.param.clear(key) end
    return type(v) == "number" and v or nil
  end

  local function SceneClear()
    ClearU32(E.SCENE.OWNER_KEY)
    ClearU32(E.SCENE.BACK_KEY)
    ClearU32(E.SCENE.RETURN_KEY)
    for _, key in ipairs({ E.SCENE.RESUME_KEY, E.SCENE.PAGE_KEY, E.SCENE.DIRECTION_KEY }) do
      if VRFW.param.has(key) then VRFW.param.clear(key) end
    end
  end

  --- Sets `provider` as the scene provider of `owner`.
  function E.scene_provider(owner, provider)
    if type(owner) == "string" and type(provider) == "table" and type(provider.spec) == "function" then
      E.providers[owner] = provider
    end
  end

  --- Opens a scene on the dock; answers how it opened, or nil, why.
  function E.scene(scene)
    scene = type(scene) == "table" and scene or {}
    if type(scene.owner) ~= "string" or type(scene.back) ~= "string" then
      return nil, "a scene needs its owner and its way back menu"
    end
    if type(VRFW.reset) ~= "table" or type(VRFW.reset.straight) ~= "function" then
      return nil, "no reset service in this menu"
    end
    local can, why = E.can_open()
    if not can then
      return nil, why
    end
    SceneClear()
    VRFW.param.set_u32(E.SCENE.OWNER_KEY, VRFW.crc32(scene.owner))
    VRFW.param.set_u32(E.SCENE.BACK_KEY, VRFW.crc32(scene.back))
    SetNumber(E.SCENE.RESUME_KEY, scene.resume)
    SetNumber(E.SCENE.PAGE_KEY, scene.page)
    Note("scene: the team screen of", scene.owner, "as its own menu scene, back to", scene.back)
    VRFW.host.command(E.SCENE.FADE, 1, 0.3)
    Wait(E.SCENE.FADE_FRAMES)
    local how = VRFW.reset.straight({ menu = E.DOCK, need_carry = true, log = function(text) Note("scene:", text) end })
    if how == "refused" then
      SceneClear()
      VRFW.host.command(E.SCENE.FADE, 0, 0.3)
      return nil, "the game could not be kept in memory"
    end
    return how
  end

  --- Opens the pending scene when this menu is its root.
  function E.scene_open()
    local owner = VRFW.param.get_u32(E.SCENE.OWNER_KEY)
    if owner == nil or E.scene_state ~= nil or MenuCall(E.SCENE.IS_SCENE_ROOT) ~= true then
      return
    end
    local sc = { owner = owner, back = VRFW.param.get_u32(E.SCENE.BACK_KEY) }
    E.scene_state = sc
    if VRFW.top_bar.hide ~= nil then pcall(VRFW.top_bar.hide, true) end
    for name, p in pairs(E.providers) do
      if VRFW.crc32(name) % 4294967296 == owner % 4294967296 then
        sc.name, sc.provider = name, p
      end
    end
    if sc.provider == nil then
      sc.failed = "no team provider of owner " .. tostring(owner) .. " in this menu"
      Note("scene:", sc.failed)
      return
    end
    local spec, why
    for _ = 1, E.SCENE.ASK do
      local ok, v, no = pcall(sc.provider.spec)
      if ok and type(v) == "table" then
        spec = v
        break
      end
      why = ok and no or v
      if not ok or no ~= nil then
        break
      end
    end
    if spec == nil then
      sc.failed = "the team of " .. sc.name .. " was not given (" .. tostring(why or "its scripts did not answer") .. ")"
      Note("scene:", sc.failed)
      return
    end
    local can, no = E.can_open()
    if not can then
      sc.failed = tostring(no)
      Note("scene:", sc.failed)
      return
    end
    local ok, code = VRFW.host.command(E.C.SESSION_BEGIN, sc.name, 0, E.KIND_TEST)
    if ok ~= true then
      sc.failed = "the save session did not start (code " .. tostring(code) .. ")"
      Note("scene:", sc.failed)
      return
    end
    sc.session = true
    local set = Int(VRFW.host.command(E.C.VS_DOCK))
    -- the fill at once (its yields only spread the work over frames)
    local co = coroutine.create(function() return Fill(set, spec) end)
    local made, err
    while true do
      local okf, a, b = coroutine.resume(co)
      if not okf then
        err = tostring(a)
        break
      end
      if coroutine.status(co) == "dead" then
        made, err = a, b
        break
      end
    end
    if not made then
      sc.failed = "the dock was not filled (" .. tostring(err) .. ")"
      Note("scene:", sc.failed)
      return
    end
    if VRFW.param.has(E.DIRECTION_KEY) then
      VRFW.param.clear(E.DIRECTION_KEY)
    end
    SetForeign(spec)
    sc.set, sc.made, sc.spec = set, made, spec
    Note("scene: the dock holds the team of", sc.name, "(session open; the scene's root)")
  end

  -- the way back: the dock read, the session ended, the result kept by the provider, reset straight into the host
  local function SceneBack(sc)
    MenuCall(E.C.MENU_INPUT, E.DOCK, false)
    VRFW.host.command(E.SCENE.FADE, 1, 0.3)
    Wait(E.SCENE.FADE_FRAMES)
    local result
    if sc.made then
      result = Read(sc.set, sc.made)
      result.opened = true
      if sc.spec.tab then
        ReadRecord(sc.set, result)
      end
      Log("scene read:", #result.members, "team players placed,", result.foreign, "club players, formation",
        result.formation)
    end
    SetForeign(nil)
    if sc.session and not EndSession() then
      Note("scene: the game could not be put back as it was")
      result = nil
    end
    if result and type(sc.provider.done) == "function" then
      local kept = false
      for _ = 1, E.SCENE.DONE_WAIT do
        local ok, fin = pcall(sc.provider.done, result)
        if not ok then
          Note("scene: the provider's done failed:", tostring(fin))
          break
        end
        if fin == true then
          kept = true
          break
        end
        coroutine.yield()
      end
      if not kept then Note("scene: the result was not kept by", sc.name) end
    end
    if VRFW.top_bar.hide ~= nil then pcall(VRFW.top_bar.hide, false) end
    ClearU32(E.SCENE.OWNER_KEY)
    ClearU32(E.SCENE.BACK_KEY)
    E.scene_state = nil
    if sc.back == nil then
      Note("scene: no way back menu: reset to the title")
      SceneClear()
      VRFW.reset.to_title()
      return
    end
    VRFW.param.set_u32(E.SCENE.RETURN_KEY, sc.back)
    SetNumber(E.SCENE.DIRECTION_KEY, (result and result.direction or 0) + 1)
    Note("scene: back to menu", sc.back, "direction", result and result.direction or 0)
    local how = VRFW.reset.straight({ menu = sc.back, need_carry = true, log = function(text) Note("scene:", text) end })
    if how == "refused" then
      Note("scene: the game could not be kept in memory: reset to the title")
      SceneClear()
      VRFW.reset.to_title()
    end
  end

  --- The dock's Back while it is a scene's root: true when the scene takes it (its FuncOnBack is not run).
  function E.scene_leave()
    local sc = E.scene_state
    if sc == nil then
      return false
    end
    if sc.co == nil then
      Note("scene: the team screen closes")
      sc.co = coroutine.create(function() return SceneBack(sc) end)
    end
    return true
  end

  --- The dock's Step: the way back runs (at once when the scene could not open).
  function E.scene_step()
    local sc = E.scene_state
    if sc == nil then
      return
    end
    if sc.failed and sc.co == nil then
      sc.co = coroutine.create(function() return SceneBack(sc) end)
    end
    local co = sc.co
    if co == nil or coroutine.status(co) == "dead" then
      return
    end
    local ok, err = coroutine.resume(co)
    if not ok then
      Note("scene: way back error", tostring(err))
    end
  end

  --- The host's menu after the way back: what it gave E.scene, once.
  function E.scene_return(menu)
    local back = VRFW.param.get_u32(E.SCENE.RETURN_KEY)
    if back == nil or type(menu) ~= "string" or back % 4294967296 ~= VRFW.crc32(menu) % 4294967296 then
      return nil
    end
    ClearU32(E.SCENE.RETURN_KEY)
    local out = { resume = TakeNumber(E.SCENE.RESUME_KEY), page = TakeNumber(E.SCENE.PAGE_KEY),
      direction = (TakeNumber(E.SCENE.DIRECTION_KEY) or 1) - 1 }
    Log("scene return to", menu, ": resume", tostring(out.resume), "page", tostring(out.page), "direction",
      out.direction)
    return out
  end

  VRFW.team_editor = E
end
