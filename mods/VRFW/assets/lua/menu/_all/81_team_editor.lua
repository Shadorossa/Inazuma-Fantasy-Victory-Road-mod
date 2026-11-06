-- menu_engine: the TEAM EDITOR service. Definitions only: this file runs in every menu VM (lua\_all) after the retail
-- chunk; no engine call at load time.
--
-- Opens the game's own team dock (soccer_team_dock_menu, «Plantilla de equipo») for a team that is not one of the
-- player's docks (a league team, a tournament team, any team a mode keeps as data) and hands back the order the
-- player left there. The player's save is never changed:
--   1. a framework session of kind «test» starts (CMND_VRFW_SESSION_BEGIN kind 1): the whole game is kept as an image
--      in memory and every save write of the slot is discarded until the session ends (a crash or a quit inside the
--      dock leaves the slot's file as it was);
--   2. the team dock in use (CMND_GET_VS_USE_TEAM_SET) is emptied and filled with one temporary club player per
--      member of the given team (CMND_ADD_PARTY), placed with the retail place pair, with the team's formation, name
--      and emblem; with spec.foreign also its coach, kit, tactics and synergies (none given = none shown);
--   3. the dock opens over the caller's menu (hidden while it is up, as soccer_top_menu does for its own dock); with
--      spec.foreign the dock runs in its foreign team mode (soccer_team_dock_menu\130_foreign_team.lua): nothing that
--      reads or writes the player's own team docks is offered;
--   4. when it closes, the positions of the temporary players and the formation are read;
--   5. the session ends with restore + verification (CMND_VRFW_SESSION_END 0): the game image of step 1 is loaded
--      back, so the temporary players, the emptied dock and anything else changed inside the dock are gone. A failed
--      restore runs the framework's in-place reload of the slot's own (untouched) file (RELOAD, LOAD_HEADER,
--      LOAD_GAME_DATA, APPLY, END 3).
-- The caller stores the result in its own data and writes it to its team before its matches.
--
--   VRFW_TeamEditor.CanOpen()        -> true, or false + why (a session already open, the slot service off)
--   VRFW_TeamEditor.Run(spec)        -> result, or nil + why. Call it from a menu coroutine (it yields until the
--                                       dock closes).
--   VRFW_TeamEditor.Release(why)     -> true when no kept dock is left: a dock kept by spec.keep closed and its session
--                                       ended (call it from a menu coroutine: it yields until the dock is gone)
--   VRFW_TeamEditor.Kept(owner)      -> true while a dock kept for `owner` (spec.keep) is open, hidden or shown
--   VRFW_TeamEditor.PageTurn(d)      -> team page: the dock's own L1 (d < 0) / R1 asked by the host (a click on its tab
--                                       bar); true when the dock took it (ignored while its open has not ended)
--   VRFW_TeamEditor.TemporaryCard(h) -> the card of temporary player h while the session runs (any menu VM), else nil:
--                                       the player plate shows his card's set as the match plays it
--                                       (personal_plate_menu\122_plate_member.lua)
--   VRFW_TeamEditor.Foreign()        -> nil, or { stadium = map, rows = { [kind] = true } } while a foreign team's dock
--                                       is open (any menu VM)
--   VRFW_TeamEditor.ShowCard(spec)   -> the player page (personal_plate_menu) of a card that is no player of the save,
--                                       as a temporary player (his card's set); yields until B closes it (call it from
--                                       a menu coroutine; personal_plate_menu\123_card_page.lua)
--   VRFW_TeamEditor.GuardSwap(nxt, ...) -> SwapChara run so that only the team's own players swap (foreign mode)
--   VRFW_TeamEditor.ViewOnly(spec)  -> a screen opened from a foreign team's dock stays view only (patch file, at load)
--   VRFW_TeamEditor.Scene(scene)     -> the team screen as its own menu scene: the game kept in memory and reset
--                                       straight into the team dock as the scene's root, as the game opens its own
--                                       team screen from the title; Back resets straight into scene.back. "straight" /
--                                       "title", or nil + why (nothing was reset). Call it from a menu coroutine.
--                                       scene = { owner = "<mod id>", back = "<menu name>", resume = n, page = n }
--   VRFW_TeamEditor.SceneProvider(owner, p) -> (the owner's soccer_team_dock_menu patch file, at load) the team of its
--                                       scenes: p.spec() -> spec (as Run's; nil = not ready, nil + why = refused),
--                                       p.done(result) -> true once the result is kept (called each frame until then)
--   VRFW_TeamEditor.SceneReturn(menu) -> { resume, page, direction } once, in the menu a scene went back to, else nil
--   spec = {
--     owner = "<mod id>",            -- the mod that asks (the session's owner, its journal)
--     host = <menu id>,              -- the menu the dock opens over
--     host_root = true,              -- the host is its menu scene's root: its input goes off under the dock but it is
--                                    -- never suspended (a suspended scene root hides the dock's player menu window
--                                    -- and the player page's 3D model; the retail screens never suspend their root)
--     members = { {slot, param[, level[, exp]]}, ... },  -- 0-10 starters in formation order, 11-18 bench, 20-28
--                                    -- reserves (chara_param ids); level: that player's own level (nil / 0 = spec.level);
--                                    -- exp: his EXP bar's fill 0..1 (nil = the new player's own)
--     formation = <formation_config id>, level = <level of the temporary players>, name = "<team name>",
--     emblem = <emblem item id>,     -- 0 / nil = the dock's own (foreign: none)
--     foreign = true,                -- a team that is not one of the player's: the whole team record below, and the
--                                    -- dock's foreign team mode (no bank, no team switching, no active team)
--     coach = <chara_param id>,      -- foreign: the team's coach (dock position 19; 0 / nil = none, the place is empty)
--     kit = <uniform item id>,       -- foreign: the team's kit
--     tactics = { id, id, id },      -- foreign: the team's special tactics (the 3 «TÁCTICAS» slots)
--     synergies = { flag, pillar },  -- foreign: the team's synergy items
--     stadium = <map id>,            -- foreign: the team's own stadium (VRFW_TeamEditor.Foreign() for the dock's add-ons)
--     tab = true,                    -- the team page mode: the whole record as with foreign, every retail row and
--                                    -- edit offered but the hidden rows (spec.hide_rows, default { ROW.BANK }); L1 / R1
--                                    -- close the dock (result.direction -1 / 1, 0 = Back); result also gives the
--                                    -- record as left: name, emblem, kit, coach, tactics
--     keep = true,                   -- team page: L1 / R1 hide the dock instead of closing it (suspended, its input off,
--                                    -- the session kept open); the next Run with the same owner shows it again at once
--                                    -- (no open, no fill, no transition). The result has kept = true; Back still closes
--                                    -- it. The caller ends it with Release before anything that changes the team or the
--                                    -- game (a match, a save, a squad change) and before its own screen closes
--     leaving = function(direction), -- team page: called the moment L1 / R1 hid the kept dock (the host draws its next
--                                    -- page in the same frame), before the result is read
--     header = false,                -- team page: the team name bar (crest, name, kit, player plate, level) hidden,
--                                    -- for a host that draws its own header there
--     header_top = <screen y>,       -- team page: the team name bar shown, its base locator moved to this screen y (px,
--                                    -- 1080p; nil = retail): under a host's own bar, the bar keeps its crest, name and kit
--     header_dx = <px>,              -- team page, with header_top: the team name bar (crest, name, kit, player plate,
--                                    -- level) this many px to the side (negative: left)
--     lock_identity = true,          -- team page: the emblem, the team name and the kit are fixed (a decide on them is
--                                    -- refused, their pointer zones off): the caller owns the team's identity
--     identity_choices = { emblems = { id, ... }, kits = { id, ... } },   -- team page: with 2 or more of a kind, a
--                                    -- decide (pad or pointer) on the crest / the kit shows the next one of the list
--                                    -- (lock_identity too); result.emblem / result.kit give the one left on screen
--     list_top = <screen y>,         -- team page: the list's first row placed at this screen y (px, 1080p; nil = retail)
--     field_dy = <px>,               -- team page: the pitch, bench, coach, tactics and AT / DF this many px lower
--     hide_card_rows = { kind, ... }, -- foreign / team page: the player popup («PERSONAJE») rows left out
--                                    -- (VRFW_ListRows.PLAYER_COMMAND kinds, e.g. 9 inherited passives)
--     inline_card_actions = true,    -- foreign / team page: A on a player card opens its popup («PERSONAJE») on the
--                                    -- dock (the lineup screen runs hidden under it); Y opens the player page
--                                    -- (soccer_team_dock_menu__inline_card_actions.lua)
--     hide_pager = true,             -- foreign / team page: the dock's team-slot pager under the pitch («L1 ‹ icon 03 › R1»: the
--                                    -- arrows, the team icon, the number and the L1 / R1 / Z / C glyphs) hidden with its pointer
--                                    -- zones, for a host with one team; L1 / R1 never switch team slots there
--     hide_list = true,              -- foreign / team page: the dock list moved off screen (its rows are reached
--                                    -- through `icons`); needs the dock panel graft, which takes the focus off it
--     icons = { { row = kind, sprite = "<sprite>", w = px, h = px[, atlas = "<atlas>"] }, ... },   -- foreign / team
--                                    -- page: up to 3 icon buttons in one row of the dock panel graft, each
--                                    -- opening that list row's screen; sprite (name or crc32) of `atlas` (path or
--                                    -- crc32, loaded in soccer_team_dock_menu; default the hub header atlas
--                                    -- mainmenu90_01), drawn w x h px (default 46 x 46)
--     rows = { kind, ... },          -- foreign: the dock list rows offered (VRFW_TeamEditor.ROW; default { ROW.LINEUP });
--                                    -- they open on the dock's team, view only
--     own = true,                    -- the player's own team: the dock opens as it is (no session, no copy, no result)
--   }
--   result = { formation = id, members = { {position, param}, ... } (dock positions 0-18 and 20-28 of the team's players),
--              foreign = n (positions holding a player of the club, not of the team), opened = true }
if VRFW_TeamEditor == nil then
  local E = {
    C = {
      SESSION_BEGIN = VRFW_Cmd.VRFW_SESSION_BEGIN,    -- CMND_VRFW_SESSION_BEGIN (mod, storageSlot, kind) -> ok, code, imageKiB, ms
      SESSION_END = VRFW_Cmd.VRFW_SESSION_END,      -- CMND_VRFW_SESSION_END (mode) -> closed, code, dirtyBlocks, ms
      SESSION_STATE = VRFW_Cmd.VRFW_SESSION_STATE,     -- CMND_VRFW_SESSION_STATE -> open, slot, discardedWrites, ...
      SESSION_RELOAD = VRFW_Cmd.VRFW_SESSION_RELOAD,   -- CMND_VRFW_SESSION_RELOAD -> ok, code
      LOAD_HEADER = 4179471494, IS_SAVE_WORKING = 1979970074, LOAD_GAME_DATA = 2585060058,
      LOAD_FAILED = 3772572101, APPLY = 3660094710,
      ADD_PARTY = VRFW_Cmd.ADD_PARTY,        -- CMND_ADD_PARTY
      VS_DOCK = VRFW_Cmd.GET_VS_USE_TEAM_SET,          -- CMND_GET_VS_USE_TEAM_SET
      PLACE_CHECK = 1730898405,      -- (handle, set, position, fromSet, team) -> ok, code (retail SwapChara check)
      PLACE = 193693077,             -- (toSet, position, fromSet, handle, team); set 16 = the club bank
      POSITION_INDEX = 1721292418,   -- (set, team, position) -> ok, member index
      INDEX_HANDLE = 1720957768,     -- (set, team, index, 0) -> ok, handle
      TEAM_GET = VRFW_Cmd.GET_TEAM_SET_INFO,         -- CMND_GET_TEAM_SET_INFO (set, team, field[, slot]) -> ok, value (4 formation,
                                     -- 7 kit, 9 tactic of a slot)
      TEAM_SET = VRFW_Cmd.SET_TEAM_SET_INFO,         -- CMND_SET_TEAM_SET_INFO (set, team, field, value[, slot]): 0 name, 1 emblem,
                                     -- 3 formation, 4 tactic (id, slot 0-2), 5 kit (uniform item), 7 kit off (0),
                                     -- 9 synergy (item, slot 0 flag / 1 pillar)
      ITEM_COUNT = VRFW_Cmd.GET_ITEM_NUM,       -- CMND_GET_ITEM_NUM (item) -> count
      ITEM_ADD = VRFW_Cmd.ADD_ITEM_ONLY,         -- CMND_ADD_ITEM_ONLY (item, count)
      OPEN_MENU = VRFW_Cmd.OPEN_MENU_OBJECT,         -- CMND_OPEN_MENU_OBJECT
      CLOSE_MENU = 320421347,        -- CMND_CLOSE_MENU_OBJECT (menu)
      -- menu commands (funcLuaMenuCommand, as the retail menus call them)
      MENU_EXISTS = VRFW_Cmd.IS_EXIST_MENU_OBJECT,      -- CMND_IS_EXIST_MENU_OBJECT (menu) -> exists
      MENU_INPUT = 1558704558,       -- (menu, on): the menu's input
      MENU_SUSPEND = 369172623,      -- (menu): the menu's layer groups suspended (retail soccer_top_menu, before its dock)
      MENU_RESUME = 66378409,        -- (menu): the same back
      CALL_IN_MENU = 830228314,      -- (menu, "global function", ...)
      SOUND = VRFW_Cmd.SND_PLAY_SE,            -- (sound)
      MEMBER_EXP = VRFW_Cmd.VRFW_TEAM_MEMBER_EXP,   -- CMND_VRFW_TEAM_MEMBER_EXP (handle, share) -> ok, EXP (the EXP bar)
      TEAM_SET_KIT = VRFW_Cmd.VRFW_TEAM_SET_KIT,     -- CMND_VRFW_TEAM_SET_KIT (set, team, uniform) -> ok, uniform now (TeamInfo +0x290,
                                     -- the kit every consumer reads; scripts	eam_editor.lua)
      LOG = VRFW_Cmd.EVT_LOG,              -- CMND_EVT_LOG
      LOG_DEBUG = VRFW_Cmd.EVT_LOG_DEBUG,  -- CMND_EVT_LOG_DEBUG
    },
    DOCK = 937147172,                -- soccer_team_dock_menu
    MODEL_VIEW = 3685122053,         -- menu_chara_model_comp (a 3D model view)
    SUB_WINDOW = 968210065,          -- sub_window (the retail sub windows: the card's PERSONAJE window)
    TOP = 811496143,                 -- soccer_top_menu (its common background is hidden under the dock, as retail)
    SCREEN_TOP = 91676902,           -- team_dock_common_top_menu: the game's own background and header of its team screen
    -- the top menus that give the dock its background (the list of the retail SetActiveDockBackground)
    SCREEN_TOPS = { 3902542018, 91676902, 811496143, 3653404168, 1385239856, 1917973090 },
    -- mainmenu90_00_background, mainmenu90_01_header: a host's own, hidden under SCREEN_TOP
    HOST_CHROME = { 367379312, 575058101 },
    MENU_HIDE = 1670867360,          -- (1, menu): the whole menu not drawn (the retail full-screen hide)
    MENU_SHOW = 3257327861,          -- (menu): drawn again
    BANK = 16,
    LAST_POSITION = 18,              -- 0-10 starters, 11-15 bench, 16-18 support
    RESERVE_FIRST = 20, RESERVE_LAST = 28,   -- the team's reserve positions (read back, never drawn)
    SE_NO = 2086672038,              -- sy0003 (refused)
    COACH_POSITION = 19,             -- the coach (foreign / team page: the team's own or empty, else left as it is)
    TACTIC_SLOTS = 3, SYNERGY_SLOTS = 2,
    -- cross-menu parameters of the foreign team mode (crc32 of the names), written while its dock is open
    FOREIGN_KEY = 4265785820,        -- VRFW_team_editor_foreign
    STADIUM_HIGH_KEY = 3441793561,   -- VRFW_team_editor_stadium_high (upper 16 bits of the map id)
    STADIUM_LOW_KEY = 2970805637,    -- VRFW_team_editor_stadium_low
    ROWS_KEY = 3645648100,           -- VRFW_team_editor_rows (bit k = dock list row kind k offered)
    TAB_KEY = 1657797995,           -- VRFW_team_editor_tab (1 = the team page mode, spec.tab)
    DIRECTION_KEY = 1934393829,     -- VRFW_team_editor_direction (written by the dock: 1 = L1, 2 = R1)
    PAGE_FUNCTION = 2294853123,     -- the dock's OnFunction for L1 / R1, its argument PAGE_LEFT (crc32 "left") / PAGE_RIGHT
    PAGE_LEFT = 2053629800, PAGE_RIGHT = 3033167124,
    HEADER_OFF_KEY = 1242260664,    -- VRFW_team_editor_header_off (1 = spec.header false)
    LIST_TOP_KEY = 3144387975,      -- VRFW_team_editor_list_top (spec.list_top + 1, 0 = retail)
    FIELD_DY_KEY = 648944452,       -- VRFW_team_editor_field_dy (spec.field_dy)
    HEADER_TOP_KEY = 2137925169,    -- VRFW_team_editor_header_top (spec.header_top + 1, 0 = retail)
    HEADER_DX_KEY = "VRFW_team_editor_header_dx",   -- spec.header_dx + OFFSET_BIAS
    LOCK_IDENTITY_KEY = 1601930639, -- VRFW_team_editor_lock_identity (1 = spec.lock_identity)
    KEEP_KEY = 406294606,           -- VRFW_team_editor_keep (1 = spec.keep: L1 / R1 leave the dock open)
    HIDDEN_CARD_ROWS_KEY = 2580972447,   -- VRFW_team_editor_hidden_card_rows (bit k = player popup row kind k hidden)
    INLINE_CARDS_KEY = "VRFW_team_editor_inline_card_actions",   -- 1 = spec.inline_card_actions
    CARD_ACTION_KEY = "VRFW_team_editor_card_action",   -- while the dock opens its lineup screen for a card action:
                                    -- CARD_ACTION.POPUP or CARD_ACTION.PAGE (written by the dock, removed after)
    CARD_MOVE_KEY = "VRFW_team_editor_card_move",       -- 1 = the popup's «Mover» was picked (the dock starts the move)
    CARD_ACTION = { POPUP = 1, PAGE = 2 },
    OFFSET_BIAS = 4096,             -- a signed px offset kept as a positive parameter
    HIDE_PAGER_KEY = "VRFW_team_editor_hide_pager",   -- 1 = spec.hide_pager
    HIDE_LIST_KEY = 2065651157,     -- VRFW_team_editor_hide_list (1 = spec.hide_list)
    ICONS_KEY = 202318521,          -- VRFW_team_editor_icons (the number of spec.icons)
    ICON_PREFIX = "VRFW_team_editor_icon",   -- <prefix><i>_row, _w, _h, _sprite, _atlas (VRFW_Param.SetU32) per icon
    ICON_MAX = 3,                   -- icon buttons in the panel row (vrfw_team_icon instances)
    -- spec.identity_choices: <prefix>_count and <prefix><i> (VRFW_Param.SetU32) per choice
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

  local function Write(cmd, ...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    pcall(funcLuaCommand, cmd, "VRFW team editor", table.concat(parts, " "))
  end

  -- per-action details: debug level
  local function Log(...)
    Write(E.C.LOG_DEBUG, ...)
  end

  -- refusals and failures: info level
  local function Note(...)
    Write(E.C.LOG, ...)
  end

  local function Call(cmd, ...)
    local r = table.pack(pcall(funcLuaCommand, cmd, ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
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
    Call(E.C.OPEN_MENU, E.DOCK)
  end

  -- the handle at a dock position (0 = empty)
  -- the dock positions a team's players may hold: 0-18 and the reserve positions
  local function Positions()
    local out = {}
    for position = 0, E.LAST_POSITION do out[#out + 1] = position end
    for position = E.RESERVE_FIRST, E.RESERVE_LAST do out[#out + 1] = position end
    return out
  end

  local function HandleAt(set, team, position)
    local ok, index = Call(E.C.POSITION_INDEX, set, team, position)
    if ok ~= true or type(index) ~= "number" then
      return 0
    end
    local ok2, handle = Call(E.C.INDEX_HANDLE, set, team, index, 0)
    return (ok2 == true and type(handle) == "number") and handle or 0
  end

  -- the retail place: the check, then the place; true when the player is at `position` now
  local function Place(handle, set, position)
    local ok, code = Call(E.C.PLACE_CHECK, handle, set, position, E.BANK, 0)
    if ok ~= true then
      Note("place refused by the retail check: position", position, "code", tostring(code))
      return false
    end
    Call(E.C.PLACE, set, position, E.BANK, handle, 0)
    return HandleAt(set, 0, position) == handle
  end

  -- every player of both teams of the dock (11v11 and 5v5) back to the club bank; -> players left in the 11v11 team
  local function Empty(set)
    for team = 0, 1 do
      for _, position in ipairs(Positions()) do
        local handle = HandleAt(set, team, position)
        if handle ~= 0 then
          Call(E.C.PLACE, E.BANK, position, set, handle, team)
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
    while Call(E.C.IS_SAVE_WORKING) == true do
      k = k + 1
      if k > E.JOB_WAIT then
        return false
      end
      coroutine.yield()
    end
    return true
  end

  -- the temporary players of the open session, as cross-menu parameters (the plate runs in its own menu VM):
  -- VRFW_team_editor_temporary_<handle> = his card while the session runs (E.TemporaryCard)
  E.TEMPORARY_PREFIX = "VRFW_team_editor_temporary_"
  E.temporary = {}
  local function MarkTemporary(handle, param)
    E.temporary[#E.temporary + 1] = handle
    VRFW_Param.Replace(E.TEMPORARY_PREFIX .. string.format("%d", handle), param)
  end
  local function ClearTemporary()
    for _, handle in ipairs(E.temporary) do
      VRFW_Param.Clear(E.TEMPORARY_PREFIX .. string.format("%d", handle))
    end
    E.temporary = {}
  end

  -- the session closed: restore + verification, else the slot read again from its own file in place
  local function EndSession()
    ClearTemporary()
    local closed, code, dirty = Call(E.C.SESSION_END, E.END_RESTORE)
    if closed == true then
      Log("session closed: the game is the one before the dock (restored and verified)")
      return true
    end
    Note("session END refused (code", tostring(code), "dirty blocks", tostring(dirty), "): in-place reload of the slot's file")
    if Call(E.C.SESSION_RELOAD) ~= true then
      Note("in-place reload refused: saves stay discarded until the game goes back to the title")
      return false
    end
    Call(E.C.LOAD_HEADER)
    local ok = WaitJob()
    ok = ok and Call(E.C.LOAD_GAME_DATA, 1) and WaitJob() and Call(E.C.LOAD_FAILED) ~= true
    if not ok then
      Note("in-place reload failed: saves stay discarded until the game goes back to the title")
      return false
    end
    Call(E.C.APPLY)
    local reloaded, code2 = Call(E.C.SESSION_END, E.END_RELOADED)
    Log("in-place reload done, session closed", tostring(reloaded), tostring(code2))
    return reloaded == true
  end

  -- the dock over `host` until it is fully gone (it and its formation screen); false when it never came up. The host
  -- is suspended and its input off while the dock is up, as soccer_top_menu does for its own dock; the caller hides
  -- the host's own layers it does not want under the dock (the dock writes its button guide on its parent's layer).
  -- A host under no team screen top menu has no background for the dock: the game's own top menu opens first, as the
  -- retail dock does when it opens alone. -> the state ScreenTopClose needs, nil when it was not opened.
  local function ScreenTopOpen(host)
    for _, menu in ipairs(E.SCREEN_TOPS) do
      if Exists(menu) then return nil end
    end
    local state = { hidden = {} }
    for _, layer in ipairs(E.HOST_CHROME) do
      if MenuCall(VRFW_Cmd.IS_OPEN_LAYER, layer, 0, host) == true then
        MenuCall(VRFW_Cmd.SET_LAYER_VISIBLE, layer, 0, false, host)
        state.hidden[#state.hidden + 1] = layer
      end
    end
    if VRFW_TopBarHide ~= nil then pcall(VRFW_TopBarHide, true) end
    Call(E.C.OPEN_MENU, E.SCREEN_TOP)
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
      Call(E.C.CLOSE_MENU, E.SCREEN_TOP)
      local f = 0
      while Exists(E.SCREEN_TOP) and f < E.OPEN_WAIT do
        f = f + 1
        coroutine.yield()
      end
    end
    if VRFW_TopBarHide ~= nil then pcall(VRFW_TopBarHide, false) end
    for _, layer in ipairs(state.hidden) do
      MenuCall(VRFW_Cmd.SET_LAYER_VISIBLE, layer, 0, true, host)
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
      Call(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", false)
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
      Call(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", true)
    end
    if host then
      if not root then MenuCall(E.C.MENU_RESUME, host) end
      coroutine.yield()
      MenuCall(E.C.MENU_INPUT, host, true)
    end
    return opened
  end

  function E.CanOpen()
    local open = Call(E.C.SESSION_STATE)
    if open == nil then
      return false, "the framework's save sessions are off"
    end
    if open == true then
      return false, "a save session is already open"
    end
    return true
  end

  -- an item the dock's team record points at, held in the bag (the retail scripts add a kit / emblem before they set
  -- it: AddItemNoCount + CMND_SET_TEAM_SET_INFO); inside the session, so the bag is put back when it ends
  local function Hold(item)
    if Int(Call(E.C.ITEM_COUNT, item)) < 1 then
      Call(E.C.ITEM_ADD, item, 1)
    end
  end

  -- the club's coach at dock position 19 to the bank: the place is empty, as for a team of the game without a coach
  local function ClearCoach(set)
    local old = HandleAt(set, 0, E.COACH_POSITION)
    if old == 0 then
      return true
    end
    Call(E.C.PLACE, E.BANK, E.COACH_POSITION, set, old, 0)
    return HandleAt(set, 0, E.COACH_POSITION) == 0
  end

  -- the team's coach at dock position 19 instead of the club's (the club's goes to the bank only once the team's is
  -- made; the place stays empty when the team's cannot be placed)
  local function PlaceCoach(set, coach, level)
    local handle = Call(E.C.ADD_PARTY, coach, level, false, false, 0, 0, false, false, false, E.BANK, 255, 255, 0,
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

  -- a foreign team's record in the dock: coach, emblem, kit, tactics and synergies; what the spec does not give is
  -- left empty (nothing of the player's own team stays on screen)
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
    Call(E.C.TEAM_SET, set, 0, 1, emblem)
    local kit = Int(spec.kit)
    if kit ~= 0 then
      -- the retail field 5 write never reached the set's kit (TeamInfo +0x290): the framework's command writes it and
      -- clears the owned kit item the dock's icon reads first
      for team = 0, 1 do
        local okk, now = Call(E.C.TEAM_SET_KIT, set, team, kit)
        if okk ~= true then
          Note("kit of team", team, "not written (now", tostring(now), ")")
        end
      end
    else
      Call(E.C.TEAM_SET, set, 0, 7, 0)
    end
    local okk, shown = Call(E.C.TEAM_GET, set, 0, 7)
    Log("kit", kit, "-> dock kit", okk == true and tostring(shown) or "unread", "; emblem", emblem)
    local tactics = type(spec.tactics) == "table" and spec.tactics or {}
    for slot = 0, E.TACTIC_SLOTS - 1 do
      local id = Int(tactics[slot + 1])
      Call(E.C.TEAM_SET, set, 0, 4, id, slot)
      local okt, now = Call(E.C.TEAM_GET, set, 0, 9, slot)
      Log("tactic slot", slot, id, "-> dock", okt == true and tostring(now) or "unread")
    end
    local synergies = type(spec.synergies) == "table" and spec.synergies or {}
    for slot = 0, E.SYNERGY_SLOTS - 1 do
      Call(E.C.TEAM_SET, set, 0, 9, Int(synergies[slot + 1]), slot)
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
        local handle = Call(E.C.ADD_PARTY, param, own_level > 0 and own_level or level, false, false, 0, 0, false, false,
          false, E.BANK, 255, 255, 0, false, false, false, 0, false, false)
        if type(handle) == "number" and handle ~= 0 then
          made[handle] = param
          if exp_share ~= nil then
            local oke = Call(E.C.MEMBER_EXP, handle, exp_share)
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
      Call(E.C.TEAM_SET, set, 0, 3, Int(spec.formation))
    end
    if type(spec.name) == "string" and spec.name ~= "" then
      Call(E.C.TEAM_SET, set, 0, 0, spec.name)
    end
    if spec.foreign or spec.tab then
      FillRecord(set, spec, level)
    elseif Int(spec.emblem) ~= 0 then
      Call(E.C.TEAM_SET, set, 0, 1, Int(spec.emblem))
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
    local ok, formation = Call(E.C.TEAM_GET, set, 0, 4)
    out.formation = (ok == true and type(formation) == "number") and formation or 0
    return out
  end

  -- the team page mode: the team's record as the player left it (name, crest, kit, coach, tactics)
  local function ReadRecord(set, out)
    local okn, name = Call(E.C.TEAM_GET, set, 0, 6)
    out.name = (okn == true and type(name) == "string") and name or nil
    local oke, emblem = Call(E.C.TEAM_GET, set, 0, 5, 0)
    out.emblem = (oke == true and type(emblem) == "number") and emblem or 0
    local okk, kit = Call(E.C.TEAM_GET, set, 0, 7)
    out.kit = (okk == true and type(kit) == "number") and kit or 0
    local coach = HandleAt(set, 0, E.COACH_POSITION)
    local card = coach ~= 0 and Call(E.STATUS, coach, 4) or 0
    out.coach = type(card) == "number" and card or 0
    out.tactics = {}
    for slot = 0, E.TACTIC_SLOTS - 1 do
      local okt, id = Call(E.C.TEAM_GET, set, 0, 9, slot)
      out.tactics[slot + 1] = (okt == true and type(id) == "number") and id or 0
    end
    local dir = VRFW_Param.Has(E.DIRECTION_KEY) and Int(VRFW_Param.Get(E.DIRECTION_KEY)) or 0
    out.direction = dir == 1 and -1 or (dir == 2 and 1 or 0)
    if VRFW_Param.Has(E.DIRECTION_KEY) then
      VRFW_Param.Clear(E.DIRECTION_KEY)
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
      if VRFW_Param.Has(key) then
        VRFW_Param.Clear(key)
      end
    end
    for i = 1, E.ICON_MAX do
      for _, part in ipairs({ "_row", "_w", "_h", "_sprite_hi", "_sprite_lo", "_atlas_hi", "_atlas_lo" }) do
        VRFW_Param.Clear(E.ICON_PREFIX .. i .. part)
      end
    end
    for _, prefix in pairs(E.CHOICE_PREFIXES) do
      VRFW_Param.Clear(prefix .. "_count")
      for i = 1, E.CHOICE_MAX do
        VRFW_Param.Clear(prefix .. i .. "_hi")
        VRFW_Param.Clear(prefix .. i .. "_lo")
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
          VRFW_Param.SetU32(prefix .. n, Int(id))
        end
      end
      if n > 0 then VRFW_Param.Set(prefix .. "_count", n) end
    end
    -- the list hidden and the icon buttons that replace it (the dock panel graft lays them out)
    if spec.hide_list == true then VRFW_Param.Set(E.HIDE_LIST_KEY, 1) end
    if spec.hide_pager == true then VRFW_Param.Set(E.HIDE_PAGER_KEY, 1) end
    local icons = 0
    for _, icon in ipairs(type(spec.icons) == "table" and spec.icons or {}) do
      local sprite = type(icon.sprite) == "string" and VRFW_Crc32(icon.sprite) or Int(icon.sprite)
      if icons < E.ICON_MAX and type(icon) == "table" and sprite ~= 0 then
        icons = icons + 1
        VRFW_Param.Set(E.ICON_PREFIX .. icons .. "_row", Int(icon.row))
        VRFW_Param.Set(E.ICON_PREFIX .. icons .. "_w", Int(icon.w) > 0 and Int(icon.w) or E.ICON_SIZE)
        VRFW_Param.Set(E.ICON_PREFIX .. icons .. "_h", Int(icon.h) > 0 and Int(icon.h) or E.ICON_SIZE)
        VRFW_Param.SetU32(E.ICON_PREFIX .. icons .. "_sprite", sprite)
        local atlas = type(icon.atlas) == "string" and VRFW_Crc32(icon.atlas) or Int(icon.atlas)
        if atlas ~= 0 then VRFW_Param.SetU32(E.ICON_PREFIX .. icons .. "_atlas", atlas) end
      end
    end
    if icons > 0 then VRFW_Param.Set(E.ICONS_KEY, icons) end
    local stadium = Int(spec.stadium) % 4294967296
    VRFW_Param.Set(E.STADIUM_HIGH_KEY, math.floor(stadium / 65536))
    VRFW_Param.Set(E.STADIUM_LOW_KEY, stadium % 65536)
    -- the player popup («PERSONAJE») rows the caller leaves out
    local hidden_mask = 0
    for _, kind in ipairs(type(spec.hide_card_rows) == "table" and spec.hide_card_rows or {}) do
      kind = Int(kind)
      if kind >= 0 and kind < 30 and math.floor(hidden_mask / 2 ^ kind) % 2 == 0 then
        hidden_mask = hidden_mask + 2 ^ kind
      end
    end
    if hidden_mask > 0 then VRFW_Param.Set(E.HIDDEN_CARD_ROWS_KEY, hidden_mask) end
    if spec.inline_card_actions == true then VRFW_Param.Set(E.INLINE_CARDS_KEY, 1) end
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
      VRFW_Param.Set(E.TAB_KEY, 1)
      -- the host's layout of the page: its header over the dock's top, the list and the pitch moved under it
      if spec.header == false then VRFW_Param.Set(E.HEADER_OFF_KEY, 1) end
      if tonumber(spec.list_top) then VRFW_Param.Set(E.LIST_TOP_KEY, Int(spec.list_top) + 1) end
      if tonumber(spec.header_top) then VRFW_Param.Set(E.HEADER_TOP_KEY, Int(spec.header_top) + 1) end
      if tonumber(spec.header_dx) then VRFW_Param.Set(E.HEADER_DX_KEY, Int(spec.header_dx) + E.OFFSET_BIAS) end
      if spec.lock_identity == true then VRFW_Param.Set(E.LOCK_IDENTITY_KEY, 1) end
      if tonumber(spec.field_dy) then VRFW_Param.Set(E.FIELD_DY_KEY, Int(spec.field_dy)) end
      if spec.keep then VRFW_Param.Set(E.KEEP_KEY, 1) end
    end
    for _, kind in ipairs(rows) do
      kind = Int(kind)
      if kind >= 0 and kind < 30 and math.floor(mask / 2 ^ kind) % 2 == 0 then
        mask = mask + 2 ^ kind
      end
    end
    VRFW_Param.Set(E.ROWS_KEY, mask)
    VRFW_Param.Set(E.FOREIGN_KEY, 1)
  end

  -- Foreign team mode: a swap in the dock or its lineup screen only among the team's own players (the copy holds all
  -- of them in dock positions 0-18). Runs the retail SwapChara (`nxt`) with its place checks answered «refused» for a
  -- player that comes from another set (the club bank, another dock): the retail code then cancels the swap itself.
  local SWAP_CHECKS = {
    [1730898405] = true,             -- (handle, toSet, position, fromSet, team) -> ok, code (retail SwapChara check)
    [99793139] = true,               -- the same check of the other swap kind
  }
  -- A screen opened from a foreign team's dock that must stay VIEW ONLY (its data is the throwaway copy): called from
  -- the screen's own patch file at load (no engine call). While a foreign team is shown: Accept (OnEnter) and the
  -- spec's editing function keys (OnFunction ids) are refused with the «no» sound, and every button guide the
  -- spec's guide functions send keeps only the entries of spec.guide_keep (default: none but Back, which the guide
  -- never lists). spec = { stem = "<script stem>", functions = { [id] = true }, guides = { "GlobalName", ... },
  -- guide_keep = { [input] = true }, skill_board_lock = true }. With skill_board_lock the screen is also view only
  -- while the skill board lock holds (VRFW_SkillBoardLock, asked at its OnInit; the Accept entry shows the lock's text).
  local GUIDE_COLUMNS, GUIDE_INPUTS = 2209673388, 452337289   -- the guide's columns, then its input commands
  local CMD_ENTER = 1981080283                                -- the guide's Accept input
  function E.ViewOnly(spec)
    spec = type(spec) == "table" and spec or {}
    if type(VRFW_Host) ~= "table" or type(VRFW_Host.wrap) ~= "function" then
      return false
    end
    local function board_locked()
      if not spec.skill_board_lock or type(VRFW_SkillBoardLock) ~= "table" then
        return false, 0
      end
      return VRFW_SkillBoardLock.Locked()
    end
    local function on()
      local ok, v = pcall(E.Foreign)
      return (ok and v ~= nil and not v.tab) or board_locked()
    end
    if spec.skill_board_lock and type(VRFW_SkillBoardLock) == "table" then
      VRFW_Host.wrap("OnInit", function(orig)
        return function(...)
          VRFW_SkillBoardLock.Read()
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
    VRFW_Host.wrap("OnEnter", function(orig)
      return function(...)
        if on() then
          refuse()
          return 1
        end
        return orig(...)
      end
    end, opts("OnEnter"))
    VRFW_Host.wrap("OnFunction", function(orig)
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
      VRFW_Host.wrap(name, function(orig)
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
          local r = table.pack(pcall(VRFW_Host.WithCommands,
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

  function E.GuardSwap(nxt, ...)
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
    local r = table.pack(pcall(VRFW_Host.WithCommands, overrides, nxt, ...))
    if refused then
      VRFW_Host.Command(E.C.SOUND, E.SE_NO)
      Note("swap refused: the player is not one of the team's")
    end
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  -- the card (chara_param id) of a temporary player of the open session (any menu VM); nil = not one
  function E.TemporaryCard(handle)
    if type(handle) ~= "number" or handle == 0 then
      return nil
    end
    local card = VRFW_Param.Get(E.TEMPORARY_PREFIX .. string.format("%d", handle))
    return (type(card) == "number" and card ~= 0) and card or nil
  end

  function E.Foreign()
    if not VRFW_Param.Has(E.FOREIGN_KEY) then
      return nil
    end
    local function part(key)
      return VRFW_Param.Has(key) and Int(VRFW_Param.Get(key)) % 65536 or 0
    end
    local mask = VRFW_Param.Has(E.ROWS_KEY) and Int(VRFW_Param.Get(E.ROWS_KEY)) or 1
    local rows = {}
    for kind = 0, 29 do
      if math.floor(mask / 2 ^ kind) % 2 == 1 then
        rows[kind] = true
      end
    end
    local function value(key)
      return VRFW_Param.Has(key) and Int(VRFW_Param.Get(key)) or 0
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
        sprite = VRFW_Param.GetU32(p .. "_sprite") or 0, atlas = VRFW_Param.GetU32(p .. "_atlas") or 0 }
    end
    local choices = {}
    for kind, prefix in pairs(E.CHOICE_PREFIXES) do
      choices[kind] = {}
      for i = 1, math.min(value(prefix .. "_count"), E.CHOICE_MAX) do
        choices[kind][i] = VRFW_Param.GetU32(prefix .. i) or 0
      end
    end
    return { identity_choices = choices, icons = icons, hide_list = VRFW_Param.Has(E.HIDE_LIST_KEY), stadium = part(E.STADIUM_HIGH_KEY) * 65536 + part(E.STADIUM_LOW_KEY), rows = rows,
      tab = VRFW_Param.Has(E.TAB_KEY), keep = VRFW_Param.Has(E.KEEP_KEY),
      header = not VRFW_Param.Has(E.HEADER_OFF_KEY),
      list_top = list_top > 0 and list_top - 1 or nil, field_dy = value(E.FIELD_DY_KEY),
      header_top = header_top > 0 and header_top - 1 or nil,
      header_dx = VRFW_Param.Has(E.HEADER_DX_KEY) and value(E.HEADER_DX_KEY) - E.OFFSET_BIAS or 0, lock_identity = VRFW_Param.Has(E.LOCK_IDENTITY_KEY),
      hide_pager = VRFW_Param.Has(E.HIDE_PAGER_KEY), hidden_card_rows = hidden_card_rows, inline_card_actions = VRFW_Param.Has(E.INLINE_CARDS_KEY) }
  end

  -- The card action the dock asked of its lineup screen (spec.inline_card_actions): set by the dock right before it
  -- opens the screen for a player card and removed when the screen closed; read by the screen and the player plate at
  -- their OnInit. mode = CARD_ACTION.POPUP / PAGE, nil = none.
  function E.SetCardAction(mode)
    if mode == nil then
      if VRFW_Param.Has(E.CARD_ACTION_KEY) then VRFW_Param.Clear(E.CARD_ACTION_KEY) end
    else
      VRFW_Param.Set(E.CARD_ACTION_KEY, mode)
    end
  end

  function E.CardAction()
    if not VRFW_Param.Has(E.CARD_ACTION_KEY) then
      return nil
    end
    local mode = Int(VRFW_Param.Get(E.CARD_ACTION_KEY))
    return (mode == E.CARD_ACTION.POPUP or mode == E.CARD_ACTION.PAGE) and mode or nil
  end

  -- «Mover» picked in the hidden lineup screen: the dock starts the move on its own pitch once the screen closed
  function E.RequestCardMove()
    VRFW_Param.Set(E.CARD_MOVE_KEY, 1)
  end

  function E.TakeCardMove()
    if not VRFW_Param.Has(E.CARD_MOVE_KEY) then
      return false
    end
    VRFW_Param.Clear(E.CARD_MOVE_KEY)
    return true
  end

  -- the kept dock (spec.keep) on screen: the host suspended under it, the dock resumed with its input
  local function KeptShow(k)
    MenuCall(E.C.MENU_INPUT, k.host, false)
    if not k.root then MenuCall(E.C.MENU_SUSPEND, k.host) end
    MenuCall(E.C.MENU_RESUME, E.DOCK)
    MenuCall(E.C.MENU_INPUT, E.DOCK, true)
  end

  -- the kept dock until the player leaves it. L1 / R1 (the dock writes the direction): the dock suspended (hidden,
  -- input off), the host back at once, the result read with the session left open (result.kept). Back (the dock
  -- closed): read, the session ended, nothing kept.
  local function KeptVisit(k, spec)
    while Exists(E.DOCK) and not VRFW_Param.Has(E.DIRECTION_KEY) do
      coroutine.yield()
    end
    if Exists(E.DOCK) then
      MenuCall(E.C.MENU_INPUT, E.DOCK, false)
      MenuCall(E.C.MENU_SUSPEND, E.DOCK)
      if not k.root then MenuCall(E.C.MENU_RESUME, k.host) end
      local dir = Int(VRFW_Param.Get(E.DIRECTION_KEY))
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
    E.kept = nil
    while Exists(E.FORMATION) do
      coroutine.yield()
    end
    Wait(10)
    Log("team dock closed")
    if k.top then
      Call(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", true)
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

  function E.Kept(owner)
    return E.kept ~= nil and (owner == nil or E.kept.owner == tostring(owner)) and Exists(E.DOCK)
  end

  -- the team page's L1 / R1 asked by the host (a click on its own tab bar): the dock's own L1 / R1 (its OnFunction,
  -- which ignores it until the dock's open has ended) -> true when the dock took it (the direction written)
  function E.PageTurn(direction)
    if not Exists(E.DOCK) or VRFW_Param.Has(E.DIRECTION_KEY) then
      return false
    end
    Call(E.C.CALL_IN_MENU, E.DOCK, "OnFunction", E.PAGE_FUNCTION, direction < 0 and E.PAGE_LEFT or E.PAGE_RIGHT)
    return VRFW_Param.Has(E.DIRECTION_KEY)
  end

  function E.Release(why)
    local k = E.kept
    if k == nil then
      return true
    end
    E.kept = nil
    Log("kept dock released:", tostring(why))
    if Exists(E.DOCK) then
      Call(E.C.CLOSE_MENU, E.DOCK)
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
      Call(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", true)
    end
    SetForeign(nil)
    if VRFW_Param.Has(E.DIRECTION_KEY) then
      VRFW_Param.Clear(E.DIRECTION_KEY)
    end
    return EndSession()
  end

  -- the player page of one card (E.ShowCard): the game's player plate opened on its own for a temporary player of
  -- that card; the plate's part is personal_plate_menu\123_card_page.lua (B closes it, its open and its close call
  -- the host's VM back)
  E.PAGE = 1427722143                -- personal_plate_menu
  E.PAGE_HANDLE = 1038144478         -- the plate's player (charaStHdl): read and deleted by the plate's OnInit
  E.PAGE_HOST_KEY = "VRFW_team_editor_card_page_host"   -- the host menu (VRFW_Param.SetU32) while its page is up
  E.PAGE_OPENED_CALL = "VRFW_TeamEditor_CardPageOpened"  -- the host VM's globals the plate calls (CALL_IN_MENU)
  E.PAGE_CLOSED_CALL = "VRFW_TeamEditor_CardPageClosed"
  E.page = nil                       -- { opened, closed } while this VM's page is up

  function E.PageHost()
    return VRFW_Param.GetU32(E.PAGE_HOST_KEY)
  end

  local function ClearPageHost()
    VRFW_Param.Clear(E.PAGE_HOST_KEY .. "_hi")
    VRFW_Param.Clear(E.PAGE_HOST_KEY .. "_lo")
  end

  VRFW_TeamEditor_CardPageOpened = function()
    if E.page ~= nil then
      E.page.opened = true
    end
  end
  VRFW_TeamEditor_CardPageClosed = function()
    if E.page ~= nil then
      if not E.page.opened then
        Note("player page closed without its open call")
      end
      E.page.closed = true
    end
  end

  -- the temporary player of `card` in the open session: the kept dock's own player of that card, the one made for an
  -- earlier page of the same session, else a new one in the club bank (CMND_ADD_PARTY); 0 = none
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
    local handle = Call(E.C.ADD_PARTY, card, math.max(1, Int(level)), false, false, 0, 0, false, false, false, E.BANK,
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

  -- E.ShowCard(spec): the player page of a card that is no player of the save, until the player closes it (B). Call it
  -- from a menu coroutine (it yields until the page is gone). The card is a temporary player of a save session (the
  -- kept dock's session of spec.owner, else one of its own, ended when the page closes), so the page shows his card's
  -- set (VRFW_TeamEditor.TemporaryCard). The host's input is not switched: the host takes no keys while this runs.
  --   spec = { owner = "<mod id>", host = <menu id>, card = <chara_param id>, level = <level>,
  --            shown = function() end (the page is up), closed = function() end (the page is gone) }
  --   -> { opened = true, handle }, or nil + why
  function E.ShowCard(spec)
    spec = type(spec) == "table" and spec or {}
    local card, host = Int(spec.card), spec.host
    if card == 0 or host == nil then
      return nil, "no card or no host"
    end
    if E.page ~= nil then
      return nil, "a player page is already up"
    end
    local k = E.kept
    if k ~= nil and not (k.owner == tostring(spec.owner) and Exists(E.DOCK)) then
      if not E.Release("a player page asked") then
        return nil, "the kept dock's session did not end"
      end
      k = nil
    end
    local own = false
    if k == nil then
      local can, why = E.CanOpen()
      if not can then
        return nil, why
      end
      local ok, code = Call(E.C.SESSION_BEGIN, tostring(spec.owner or "VRFW"), 0, E.KIND_TEST)
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
    VRFW_Param.SetU32(E.PAGE_HOST_KEY, host)
    VRFW_Param.Replace(E.PAGE_HANDLE, handle)
    Call(E.C.OPEN_MENU, E.PAGE)
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
    if VRFW_Param.Has(E.PAGE_HANDLE) then
      VRFW_Param.Clear(E.PAGE_HANDLE)
    end
    -- the close call comes from the plate's FinalizeMenu: one frame for the plate to go before the session ends
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

  function E.Run(spec)
    spec = type(spec) == "table" and spec or {}
    local kept = E.kept
    if kept ~= nil then
      if spec.keep and spec.tab and kept.owner == tostring(spec.owner) and Exists(E.DOCK) then
        if VRFW_Param.Has(E.DIRECTION_KEY) then
          VRFW_Param.Clear(E.DIRECTION_KEY)
        end
        KeptShow(kept)
        return KeptVisit(kept, spec)
      end
      if not E.Release("another dock asked") then
        return nil, "the kept dock's session did not end"
      end
    end
    if spec.own then
      if ShowDock(spec.host, spec.host_root == true) then
        return { opened = true, own = true }
      end
      return nil, "the team dock did not open"
    end
    local can, why = E.CanOpen()
    if not can then
      return nil, why
    end
    local ok, code = Call(E.C.SESSION_BEGIN, tostring(spec.owner or "VRFW"), 0, E.KIND_TEST)
    if ok ~= true then
      return nil, "the save session did not start (code " .. tostring(code) .. ")"
    end
    Log("session open for", tostring(spec.owner), ": saves of the slot are discarded until the dock closes")
    local set = Int(Call(E.C.VS_DOCK))
    local made, err = Fill(set, spec)
    local result
    if made then
      if spec.foreign or spec.tab then
        SetForeign(spec)
      end
      if VRFW_Param.Has(E.DIRECTION_KEY) then
        VRFW_Param.Clear(E.DIRECTION_KEY)
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
          Call(E.C.CALL_IN_MENU, E.TOP, "SetDisplaySoccerTopCommonBgImage", false)
        end
        OpenDock()
        local f = 0
        while not Exists(E.DOCK) and f < E.OPEN_WAIT do
          f = f + 1
          coroutine.yield()
        end
        if Exists(E.DOCK) then
          Log("team dock open after", f, "frame(s), kept between visits")
          E.kept = k
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

  -- ---- the team screen as its own menu scene ------------------------------------------------------------------------
  -- The host's side (E.Scene) keeps the game in memory and resets straight into the team dock as the root of a new menu
  -- scene (VRFW_Reset.straight, as the top bar's «Plantilla de equipo»): the dock, its lineup screen and their player
  -- menu run as in the game's own team screen. The dock's side (soccer_team_dock_menu\138_team_editor_scene.lua):
  -- E.SceneOpen at its OnInit asks the owner's provider for the team, opens the session and fills the dock; Back (its
  -- FuncOnBack, also L1 / R1 of the team page) runs E.SceneBack: the dock read, the session ended, the result handed to
  -- the provider, the game kept in memory and reset straight into the host's menu, which takes E.SceneReturn once.
  E.SCENE = {
    OWNER_KEY = "VRFW_team_editor_scene_owner",     -- SetU32: crc32 of the owner while a scene is asked or up
    BACK_KEY = "VRFW_team_editor_scene_back",       -- SetU32: crc32 of the menu the scene goes back to
    RESUME_KEY = "VRFW_team_editor_scene_resume",   -- the host's resume value, handed back once
    PAGE_KEY = "VRFW_team_editor_scene_page",       -- the host's page, handed back once
    RETURN_KEY = "VRFW_team_editor_scene_return",   -- SetU32: crc32 of the menu a scene went back to
    DIRECTION_KEY = "VRFW_team_editor_scene_direction",   -- the team page's leave direction + 1 (L1 0, Back 1, R1 2)
    IS_SCENE_ROOT = 2119959601,     -- (menu command) true when this menu is its menu scene's root
    FADE = 609722083,               -- (1 = to black / 0 = in, seconds)
    FADE_FRAMES = 20,               -- frames of the fade to black before a reset
    ASK = 8,                        -- tries of the provider's spec at the dock's OnInit (its scripts may be busy)
    DONE_WAIT = 600,                -- frames the provider may take to keep the result
  }
  E.providers = E.providers or {}

  local function ClearU32(name)
    VRFW_Param.Clear(name .. "_hi")
    VRFW_Param.Clear(name .. "_lo")
  end

  local function SetNumber(key, v)
    if type(v) == "number" then
      VRFW_Param.Replace(key, Int(v))
    elseif VRFW_Param.Has(key) then
      VRFW_Param.Clear(key)
    end
  end

  local function TakeNumber(key)
    local v = VRFW_Param.Has(key) and VRFW_Param.Get(key) or nil
    if v ~= nil then VRFW_Param.Clear(key) end
    return type(v) == "number" and v or nil
  end

  local function SceneClear()
    ClearU32(E.SCENE.OWNER_KEY)
    ClearU32(E.SCENE.BACK_KEY)
    ClearU32(E.SCENE.RETURN_KEY)
    for _, key in ipairs({ E.SCENE.RESUME_KEY, E.SCENE.PAGE_KEY, E.SCENE.DIRECTION_KEY }) do
      if VRFW_Param.Has(key) then VRFW_Param.Clear(key) end
    end
  end

  function E.SceneProvider(owner, provider)
    if type(owner) == "string" and type(provider) == "table" and type(provider.spec) == "function" then
      E.providers[owner] = provider
    end
  end

  function E.Scene(scene)
    scene = type(scene) == "table" and scene or {}
    if type(scene.owner) ~= "string" or type(scene.back) ~= "string" then
      return nil, "a scene needs its owner and its way back menu"
    end
    if type(VRFW_Reset) ~= "table" or type(VRFW_Reset.straight) ~= "function" then
      return nil, "no reset service in this menu"
    end
    local can, why = E.CanOpen()
    if not can then
      return nil, why
    end
    SceneClear()
    VRFW_Param.SetU32(E.SCENE.OWNER_KEY, VRFW_Crc32(scene.owner))
    VRFW_Param.SetU32(E.SCENE.BACK_KEY, VRFW_Crc32(scene.back))
    SetNumber(E.SCENE.RESUME_KEY, scene.resume)
    SetNumber(E.SCENE.PAGE_KEY, scene.page)
    Note("scene: the team screen of", scene.owner, "as its own menu scene, back to", scene.back)
    Call(E.SCENE.FADE, 1, 0.3)
    Wait(E.SCENE.FADE_FRAMES)
    local how = VRFW_Reset.straight({ menu = E.DOCK, need_carry = true, log = function(text) Note("scene:", text) end })
    if how == "refused" then
      SceneClear()
      Call(E.SCENE.FADE, 0, 0.3)
      return nil, "the game could not be kept in memory"
    end
    return how
  end

  -- the dock is a scene's root: the owner's team in it, the session open (OnInit, before the retail one reads the dock)
  function E.SceneOpen()
    local owner = VRFW_Param.GetU32(E.SCENE.OWNER_KEY)
    if owner == nil or E.scene ~= nil or MenuCall(E.SCENE.IS_SCENE_ROOT) ~= true then
      return
    end
    local sc = { owner = owner, back = VRFW_Param.GetU32(E.SCENE.BACK_KEY) }
    E.scene = sc
    if VRFW_TopBarHide ~= nil then pcall(VRFW_TopBarHide, true) end
    for name, p in pairs(E.providers) do
      if VRFW_Crc32(name) % 4294967296 == owner % 4294967296 then
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
    local can, no = E.CanOpen()
    if not can then
      sc.failed = tostring(no)
      Note("scene:", sc.failed)
      return
    end
    local ok, code = Call(E.C.SESSION_BEGIN, sc.name, 0, E.KIND_TEST)
    if ok ~= true then
      sc.failed = "the save session did not start (code " .. tostring(code) .. ")"
      Note("scene:", sc.failed)
      return
    end
    sc.session = true
    local set = Int(Call(E.C.VS_DOCK))
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
    if VRFW_Param.Has(E.DIRECTION_KEY) then
      VRFW_Param.Clear(E.DIRECTION_KEY)
    end
    SetForeign(spec)
    sc.set, sc.made, sc.spec = set, made, spec
    Note("scene: the dock holds the team of", sc.name, "(session open; the scene's root)")
  end

  -- the way back: the dock read, the session ended, the result kept by the provider, reset straight into the host
  local function SceneBack(sc)
    MenuCall(E.C.MENU_INPUT, E.DOCK, false)
    Call(E.SCENE.FADE, 1, 0.3)
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
    if VRFW_TopBarHide ~= nil then pcall(VRFW_TopBarHide, false) end
    ClearU32(E.SCENE.OWNER_KEY)
    ClearU32(E.SCENE.BACK_KEY)
    E.scene = nil
    if sc.back == nil then
      Note("scene: no way back menu: reset to the title")
      SceneClear()
      VRFW_Reset.to_title()
      return
    end
    VRFW_Param.SetU32(E.SCENE.RETURN_KEY, sc.back)
    SetNumber(E.SCENE.DIRECTION_KEY, (result and result.direction or 0) + 1)
    Note("scene: back to menu", sc.back, "direction", result and result.direction or 0)
    local how = VRFW_Reset.straight({ menu = sc.back, need_carry = true, log = function(text) Note("scene:", text) end })
    if how == "refused" then
      Note("scene: the game could not be kept in memory: reset to the title")
      SceneClear()
      VRFW_Reset.to_title()
    end
  end

  -- the dock's Back while it is a scene's root: true when the scene takes it (its FuncOnBack is not run)
  function E.SceneLeave()
    local sc = E.scene
    if sc == nil then
      return false
    end
    if sc.co == nil then
      Note("scene: the team screen closes")
      sc.co = coroutine.create(function() return SceneBack(sc) end)
    end
    return true
  end

  -- the dock's Step: the way back runs (at once when the scene could not open)
  function E.SceneStep()
    local sc = E.scene
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

  -- the host's menu after the way back: what it gave E.Scene, once
  function E.SceneReturn(menu)
    local back = VRFW_Param.GetU32(E.SCENE.RETURN_KEY)
    if back == nil or type(menu) ~= "string" or back % 4294967296 ~= VRFW_Crc32(menu) % 4294967296 then
      return nil
    end
    ClearU32(E.SCENE.RETURN_KEY)
    local out = { resume = TakeNumber(E.SCENE.RESUME_KEY), page = TakeNumber(E.SCENE.PAGE_KEY),
      direction = (TakeNumber(E.SCENE.DIRECTION_KEY) or 1) - 1 }
    Log("scene return to", menu, ": resume", tostring(out.resume), "page", tostring(out.page), "direction",
      out.direction)
    return out
  end

  VRFW_TeamEditor = E
end
