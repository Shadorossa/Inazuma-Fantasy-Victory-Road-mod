-- * The 5v5 templates are the retail teamInfo[1] of the same 11 docks.
FootballReforged = FootballReforged or {}
@BONUS5@
do
  if FootballReforged.friendly_dock_on == nil then
    FootballReforged.friendly_dock_on = true
  end
  if FootballReforged.friendly_dock_wrapped == nil then
    FootballReforged.friendly_dock_wrapped = {}
  end
  local PT = {
    INFO = @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_INFO@,
    VS = @crc:CMND_VRFW_FRIENDLY_VS@,           -- (op 0 take / 1 remember / 2 peek, vs) -> ok, vs
    TEMPLATE_OF_DOCK = @crc:CMND_BETTERQOL_TEMPLATE_OF_DOCK@,   -- (team set) -> the BetterQoL team template in that dock; nil without them
    FLAGS = @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_FLAGS@,
    VERSION = @crc:CMND_VRFW_LOADER_VERSION@,            -- CMND_VRFW_LOADER_VERSION -> api, module mask
    MOD_BIT = 2097152,
    EXISTS = 2947612279, GET = 3522198769, DEL = 3363400568, PUT = 3860611758,   -- menu parameter store
    KEY_KIND = 4081600465,           -- team kind of the dock / its children (0 = 11v11, 1 = 5v5)
    KEY_PLATE_KIND = 2419482555,     -- personal_plate_menu: 1 = 5v5 formation state
    KEY_MODE = @crc:football_reforged_friendlies_mode@,        -- type the next dock opens with (value + 1)
    KEY_DOCK = @crc:pachanga_dock@,
    UPVAL = @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_UPVAL@,     -- (fn, expect, value, ...) -> upvalues changed (-1 = not available)
    MIRROR = @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_MIRROR@,
    FORM_BOX = 3286546665,
    KEY_PF = {@crc:football_reforged_pachanga_formation_menu@, @crc:football_reforged_pf_group@},   -- formation screen VMs: 5v5 mode for dock (pachanga_formation)
    KEY_PF11 = {@crc:football_reforged_pachanga_formation11_menu@, @crc:football_reforged_pf11_group@},
    KEY_BANK = @crc:football_reforged_pb_dock@,    -- the bank's 5v5 view (graft pachanga_bank), value = dock
    KEY_ACTIVE_DOCK = 700666421,
    PLATE_MENU = 1427722143,
    BUILD_MENU = 1621705485,           -- build a menu object (menu, menu)
    NO5 = {[1179455358] = true,      -- team00_17_synergy_attachment_button_pillar (castle)
           [830633104] = true},      -- team00_17_synergy_attachment_button_flag (flag)
    TACTICS = {2579693296,
               3018698265,           -- soccer08_12_tactics_cmd (x3)
               1559239586},          -- team00_11_p1_tactics_focus (x3, opens the tactics picker)
    GET_INFO = @crc:CMND_GET_TEAM_SET_INFO@, SET_INFO = @crc:CMND_SET_TEAM_SET_INFO@,   -- CMND_GET / SET_TEAM_SET_INFO (set, team, field, ...)
    -- Default formation of a 5v5 team when it has none of the 5v5 formations (VRFW.formation).
    FORM5_DEFAULT = 712431653,
    VALID = 1538643580,              -- (set, team, false) -> 0 = the team can play (retail member check)
    CAN_ACTIVE = 1104634465,
    GET_VS = @crc:CMND_GET_VS_USE_TEAM_SET@, SET_VS = @crc:CMND_SET_VS_USE_TEAM_SET@,
    EQUIP_ALL = 10,
    ROWS = "FootballReforged.format_rows",   -- the id of the format rows in VRFW.team_dock.half_rows
    LIST = 3367997069,               -- team01_02_list_item
    GUIDE_LINE = 3078308064, GUIDE_NODE = 378156699, SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,
    MENU_ID = 937147172,             -- soccer_team_dock_menu
    TEXT_GET = @crc:CMND_TEXT_GET@, SET_HEADER = 2865764598, TEXT_HEADER = 1923260944,
    SOUND = @crc:CMND_SND_PLAY_SE@, SE_OK = 3848881948, SE_NG = 2086672038,
    ACTIVE_FUNC = 4219711668,
    NAME_FRAME = 1922851874,         -- team01_04_p1_team_name_frame (OnEnter: the retail team name edit)
    PAGE_FUNC = 2294853123,          -- OnFunction: Z / C (L1 / R1) previous / next dock
    T = {
      MATCH = @crc:football_reforged_pt_row_match@, FIVE_A_SIDE = @crc:football_reforged_pt_row_five_a_side@, HELP = @crc:football_reforged_pt_row_help@,
      LINE = @crc:football_reforged_pt_active_line@, NONE = @crc:football_reforged_pt_none@, NOW = @crc:football_reforged_pt_now_active@,
      NEED5 = @crc:football_reforged_pt_need_five@, NEED_MATCH = @crc:football_reforged_pt_need_match@, POOL_ONLY = @crc:football_reforged_pt_pool_only@, ONLY_TITLE = @crc:football_reforged_pt_only_title@, NO_LOADER = @crc:football_reforged_pt_no_loader@,
      HEADER = @crc:football_reforged_pt_header@,
      KIND_11 = @crc:football_reforged_pt_kind_11@, KIND_7 = @crc:football_reforged_pt_kind_7@, KIND_5 = @crc:football_reforged_pt_kind_5@,
      KIND_3 = @crc:football_reforged_pt_kind_3@, KIND_LOCKED = @crc:football_reforged_pt_kind_locked@,
      NAME_MATCH = 2223863259,
      NAME_FIVE_A_SIDE = @crc:football_reforged_pt_header@,
    },
    -- Fallback texts, because the texts ship in every language (text\rows\menu_text.toml of this mod).
    FALLBACK = {
      KIND_11 = "11v11", KIND_7 = "7v7", KIND_5 = "5v5", KIND_3 = "3v3",
    },
    active = -1, loader = false, start = nil, logs = 0,
  }
  FootballReforged.friendly_dock = PT

  function PT.pack(...)
    return {n = select("#", ...), ...}
  end

  function PT.log(...)
    if PT.logs < 40 then
      PT.logs = PT.logs + 1
      PT.logger = PT.logger or VRFW.logger.new("EVT pachanga")
      PT.logger(...)
    end
  end

  function PT.wrap(name, make)
    local cur = _ENV[name]
    if type(cur) ~= "function" or FootballReforged.friendly_dock_wrapped[cur] then
      return false
    end
    local w = make(cur)
    FootballReforged.friendly_dock_wrapped[w] = true
    _ENV[name] = w
    return true
  end

  function PT.text(key, subs)
    local s = nil
    local id = PT.T[key]
    if id ~= nil then
      local r = VRFW.host.command(PT.TEXT_GET, id)
      if type(r) == "string" and r ~= "" then
        s = r
      end
    end
    s = s or PT.FALLBACK[key] or ""
    for k, v in pairs(subs or {}) do
      s = string.gsub(s, "{" .. k .. "}", (string.gsub(tostring(v), "%%", "%%%%")))
    end
    return s
  end

  -- Reads or writes a key of the menu parameter store.
  function PT.param(k, v)
    if funcLuaCommand(PT.EXISTS, k) then
      funcLuaCommand(PT.DEL, k)
    end
    if v ~= nil then
      funcLuaCommand(PT.PUT, k, 0, v, 1)
    end
  end

  function PT.take(k)
    if not funcLuaCommand(PT.EXISTS, k) then
      return nil
    end
    local v = funcLuaCommand(PT.GET, k)
    funcLuaCommand(PT.DEL, k)
    return v
  end

  function PT.pachanga()
    return FootballReforged.friendly_dock_on and n10 == 1
  end

  function PT.is_dock(s)
    return type(s) == "number" and s >= 2 and s <= 12
  end

  -- a dock owner's answer (VRFW.team_dock.ask), nil when nobody answers
  function PT.ask(question, ...)
    if type(VRFW.team_dock) == "table" then
      return VRFW.team_dock.ask(question, ...)
    end
    return nil
  end

  function PT.notify(event, ...)
    if type(VRFW.team_dock) == "table" then
      VRFW.team_dock.emit(event, ...)
    end
  end

  function PT.refresh()
    PT.read_loader_state()
    local set = PT.ask("active_dock")
    if set ~= nil then
      PT.active = set
    end
  end

  function PT.read_loader_state()
    PT.loader, PT.active = false, -1
    local api, mods = VRFW.host.command(PT.VERSION)
    if type(mods) ~= "number" or math.floor(mods / PT.MOD_BIT) % 2 ~= 1 then
      return
    end
    local r, active = VRFW.host.command(PT.INFO)
    if r == true and type(active) == "number" then
      PT.loader, PT.active = true, active
    end
  end

  function PT.dock_claimed()
    return type(VRFW.team_dock) == "table" and VRFW.team_dock.is_owned()
  end

  -- the type can be switched here? (true | false, reason)
  function PT.can_switch()
    if not FootballReforged.friendly_dock_on then
      return false, "off"
    elseif PT.ask("type_switch_allowed") == true then
      return true
    elseif PT.dock_claimed() then
      return false, "dock claimed"
    elseif not flag4 then
      return false, "not standalone"
    elseif funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, 3902542018 --[[chronicle_mode_top_menu]]) == true then
      return false, "chronicle"
    elseif funcLuaCommand(@crc:CMND_GET_PLAY_GAME_MODE@) == 2 then
      return false, "story"
    elseif type(VRFW.team_dock) == "table" and VRFW.team_dock.online() then
      return false, "online"
    end
    return true
  end

  function PT.message(s)
    funcLuaMenuCommand(1558704558, PT.MENU_ID, false)
    VRFW.question.notice(s)
    funcLuaMenuCommand(1558704558, PT.MENU_ID, true)
  end

  -- OnEnter that yields counts as accepted and the engine goes on to OnDecideFocus, outside a coroutine
  function PT.say(s)
    if PT.co == nil and PT.msg == nil then
      PT.msg = s
    end
  end

  function PT.step_say()
    if PT.co == nil and PT.msg ~= nil and not VRFW.team_dock.half_rows.deciding() then
      local s = PT.msg
      PT.co = coroutine.create(function()
        PT.message(s)
      end)
    end
    if PT.co == nil then
      return
    end
    local ok, e = coroutine.resume(PT.co)
    if not ok then
      PT.log("dock coroutine error", tostring(e))
      pcall(funcLuaMenuCommand, 1558704558, PT.MENU_ID, true)
    end
    if not ok or coroutine.status(PT.co) == "dead" then
      PT.co, PT.msg = nil, nil
    end
  end

  -- The match formats of the first row, in cycle order.
  if FootballReforged.friendly_dock_kinds == nil then
    FootballReforged.friendly_dock_kinds = {
      {id = "11v11", text = "KIND_11", name = "NAME_MATCH", players = 11, rivals = 11, kind = 0, enabled = true},
      {id = "7v7", text = "KIND_7", players = 7, rivals = 7, enabled = false},
      {id = "5v5", text = "KIND_5", name = "NAME_FIVE_A_SIDE", players = 5, rivals = 5, kind = 1, enabled = true},
      {id = "3v3", text = "KIND_3", players = 3, rivals = 3, enabled = false},
    }
  end


  -- Format rows: one normal list row per enabled format, its text the format's name; Accept on a row switches the dock to that format (PT.switch).
  PT.pick = nil

  function PT.kinds()
    if type(FootballReforged.friendly_dock_kinds) == "table" and #FootballReforged.friendly_dock_kinds > 0 then
      return FootballReforged.friendly_dock_kinds
    end
    return {{id = "11v11", text = "KIND_11", name = "NAME_MATCH", players = 11, rivals = 11, kind = 0, enabled = true},
            {id = "5v5", text = "KIND_5", name = "NAME_FIVE_A_SIDE", players = 5, rivals = 5, kind = 1, enabled = true}}
  end

  function PT.kind_on(k)
    return type(k) == "table" and k.enabled ~= false and (k.kind == 0 or k.kind == 1)
  end

  -- the indexes of the enabled formats, in cycle order
  function PT.options()
    local list = {}
    for i, k in ipairs(PT.kinds()) do
      if PT.kind_on(k) then
        list[#list + 1] = i
      end
    end
    return list
  end

  function PT.kind_label(k)
    if type(k.text) == "number" then
      local s = VRFW.host.command(PT.TEXT_GET, k.text)
      if type(s) == "string" and s ~= "" then
        return s
      end
    elseif type(k.text) == "string" and PT.T[k.text] ~= nil then
      return PT.text(k.text)
    end
    return tostring(k.label or k.id or "?")
  end

  -- the format on screen (n10)
  function PT.active_col()
    for i, k in ipairs(PT.kinds()) do
      if PT.kind_on(k) and k.kind == (n10 or 0) then
        return i
      end
    end
    return 1
  end

  -- the format col of list kind `kind` (nil = not a format row)
  function PT.col_of_kind(kind)
    local cell = VRFW.team_dock.half_rows.cell_of_kind(kind)
    if cell ~= nil and cell.group.id == PT.ROWS then
      return cell.value
    end
    return nil
  end

  function PT.col_at(i)
    if type(i) ~= "number" or i < 0 or i >= (n or 0) then
      return nil
    end
    return PT.col_of_kind(t[i + 1])
  end

  function PT.list_index()
    local idx = VRFW.host.menu_command(2603265800, PT.LIST)
    return idx or nil
  end

  -- CMND_IS_CTRL_FOCUS_ACTIVE
  function PT.focused_col()
    if n6 ~= nil and n6 ~= 0 and n6 ~= PT.LIST then
      return nil
    end
    return PT.col_at(PT.list_index())
  end

  function PT.row_focused()
    return PT.focused_col() ~= nil
  end

  -- Returns the format column that the line and the guard talk about.
  function PT.cur_col()
    return PT.focused_col() or PT.active_col()
  end

  function PT.row_text(col)
    local k = PT.kinds()[col or PT.active_col()]
    if type(k) ~= "table" then
      return ""
    end
    local s = nil
    if type(k.name) == "string" and PT.T[k.name] ~= nil then
      s = PT.text(k.name)
    elseif type(k.name) == "number" then
      local r = VRFW.host.command(PT.TEXT_GET, k.name)
      s = r or nil
    end
    if type(s) == "string" and s ~= "" then
      return s
    end
    return PT.kind_label(k)
  end

  -- every format row's text (a refresh of the list may have rewritten them)
  function PT.draw_row()
    if not FootballReforged.friendly_dock_on or type(SetTeamDockListItemText) ~= "function" then
      return
    end
    for i = 0, (n or 0) - 1 do
      local col = PT.col_at(i)
      if col ~= nil then
        pcall(SetTeamDockListItemText, i, PT.row_text(col))
      end
    end
  end

  function PT.gate(col, quiet)
    local ok, why = PT.can_switch()
    local k = PT.kinds()[col or PT.cur_col()]
    local say = nil
    if not ok then
      if why == "not standalone" then
        say = "ONLY_TITLE"
      end
    elseif not PT.kind_on(k) then
      ok, why = false, "locked " .. tostring(k and k.id)
    elseif k.kind == (n10 or 0) then
      ok, why = false, "same"
    elseif k.kind == 0 and not PT.can_reset() then
      ok, why, say = false, "no include reset (loader)", "NO_LOADER"
    end
    if ok then
      return true
    end
    PT.log("switch refused", why, quiet and "(decide)" or "")
    if not quiet and why ~= "same" then
      funcLuaCommand(PT.SOUND, PT.SE_NG)
      if say ~= nil then
        PT.say(PT.text(say))
      end
    end
    return false, why
  end

  -- Watches every retail build of the player plate from the dock, which makes a new plate VM that reads its team kind from a key in OnInit; the key is left before each build so the plate reads the same team as the cards.
  function PT.watch_plate_build()
    if PT.plate_build_hook or type(VRFW.host) ~= "table" or type(VRFW.host.hook_command) ~= "function" then
      return
    end
    PT.plate_build_hook = true
    VRFW.host.hook_command(PT.BUILD_MENU, function(nxt, id, menu, ...)
      if menu == PT.PLATE_MENU then
        if PT.pachanga() then
          PT.param(PT.KEY_PLATE_KIND, 1)
          PT.plate_key_left = true
        elseif PT.plate_key_left then
          PT.param(PT.KEY_PLATE_KIND, nil)
          PT.plate_key_left = false
        end
      end
      return nxt(id, menu, ...)
    end, "FootballReforged.dock_plate_build")
  end

  function PT.describe(set, team)
    if not PT.is_dock(set) then
      return PT.text("NONE")
    end
    local name = ""
    if type(GetTeamName) == "function" then
      local ok, r = pcall(GetTeamName, set, team)
      if ok and type(r) == "string" then
        name = r
      end
    end
    return string.format("%02d", set - 1) .. (name ~= "" and (" " .. name) or "")
  end

  function PT.active_line()
    local vs = funcLuaCommand(PT.GET_VS)
    local ok, why = PT.can_switch()
    local line
    if not ok and why == "not standalone" then
      line = PT.text("ONLY_TITLE")   -- alone: joined with the active team it did not fit the guide line
    elseif ok and not PT.kind_on(PT.kinds()[PT.cur_col()]) then
      line = PT.text("KIND_LOCKED")  -- the cursor is on a locked type
    else
      line = PT.text("LINE", {team = PT.describe(vs, 0)})  -- the active pachanga team is its pair: one name
    end
    VRFW.host.menu_command(PT.SET_TEXT, PT.GUIDE_LINE, PT.GUIDE_NODE, line, 0)
  end

  function PT.header()
    if not PT.pachanga() then
      return
    end
    local r = VRFW.host.command(PT.TEXT_GET, PT.TEXT_HEADER)
    local base = (type(r) == "string") and r or ""
    VRFW.host.menu_command(PT.SET_HEADER, 5, base .. " · " .. PT.text("HEADER"))
  end

  -- Marks the teams in pachanga mode.
  function PT.marks()
    if not PT.pachanga() then
      return
    end
    n4 = PT.active
    pcall(UpdateViewTeamDockNo)
    pcall(SetActiveDockBackground, n4 == n5)
    pcall(SetVisibleHeaderTeamDoc, true, n5)
  end

  function PT.flags()
    if PT.loader then
      VRFW.host.command(PT.FLAGS)
    end
  end

  function PT.move_to(want)
    if PT.ask("dock_move_blocked") == true or not PT.is_dock(want) or want == n5 then
      return
    end
    n5 = want
    pcall(SetShowTeamDockNo, n5)
    pcall(function()
      SetFormationId(GetTeamDockFormationId())
    end)
  end

  -- The format rows are declared to the dock's row service: one cell per enabled format, a pair when there are two.
  if type(t) == "table" and type(t2) == "table" then
    local cells = {}
    for _, col in ipairs(PT.options()) do
      cells[#cells + 1] = {value = col, name = PT.T.MATCH, help = PT.T.HELP, label = function(cell)
        return PT.row_text(cell.value)
      end}
    end
    VRFW.team_dock.half_rows.add({
      id = PT.ROWS, place = "head", pair = #cells == 2, cells = cells, remove = {PT.EQUIP_ALL},
      when = function()
        return FootballReforged.friendly_dock_on == true
      end,
      greyed = function()
        return not PT.can_switch()
      end,
      busy = function()
        return PT.busy or PT.co ~= nil
      end,
      focused = function()
        if PT.row_focused() then
          PT.active_line()
        end
      end,
    })
  end

  function PT.starters(set)
    local c = 0
    for i = 0, 4 do
      local ok, idx = funcLuaCommand(1721292418, set, 1, i)
      if not ok or type(idx) ~= "number" then
        idx = i
      end
      local ok2, h = funcLuaCommand(1720957768, set, 1, idx, 0)
      if ok2 and type(h) == "number" and h ~= 0 then
        c = c + 1
      end
    end
    return c
  end

  -- Makes the teams both the active ones (the active pachanga team is the VS dock's pair).
  function PT.set_active()
    if n4 == n5 then
      return
    end
    if not PT.loader then
      funcLuaCommand(PT.SOUND, PT.SE_NG)
      PT.message(PT.text("NO_LOADER"))
      return
    end
    if type(CanActiveTeam) == "function" and not CanActiveTeam(n5) then
      funcLuaCommand(PT.SOUND, PT.SE_NG)
      return
    end
    local starters = PT.starters(n5)
    local code = funcLuaCommand(PT.VALID, n5, 1, false)
    if starters < 5 or (type(code) == "number" and code > 0 and code < 11) then
      PT.log("not complete", n5, "starters", starters, "code", tostring(code))
      funcLuaCommand(PT.SOUND, PT.SE_NG)
      PT.message(PT.text("NEED5"))
      return
    end
    local can11 = VRFW.host.command(PT.CAN_ACTIVE, n5, 0)
    if can11 == false then
      PT.log("match team not valid", n5)
      funcLuaCommand(PT.SOUND, PT.SE_NG)
      PT.message(PT.text("NEED_MATCH"))
      return
    end
    funcLuaCommand(PT.SET_VS, n5)
    PT.keep_vs()                      -- the new VS team is the one PT.leave keeps
    PT.refresh()
    PT.active = n5
    n4 = n5
    funcLuaCommand(PT.SOUND, PT.SE_OK)
    pcall(UpdateViewTeamDockNo)
    local name = ""
    if type(GetTeamName) == "function" then
      local ok2, s = pcall(GetTeamName, n5, 1)
      name = (ok2 and type(s) == "string") and s or ""
    end
    PT.message(PT.text("NOW", {n = string.format("%02d", n5 - 1), team = name}))
    pcall(SetActiveDockBackground, true)
    pcall(SetVisibleHeaderTeamDoc, true, n5)
    PT.log("active team (match + pachanga)", n5)
  end

  -- Clears the kind keys of the formation screen and plate (both kinds).
  function PT.clear_kind()
    PT.param(PT.KEY_KIND, nil)
    PT.param(PT.KEY_PLATE_KIND, nil)
    for _, k in ipairs(PT.KEY_PF) do
      PT.param(k, nil)
    end
    for _, k in ipairs(PT.KEY_PF11) do
      PT.param(k, nil)
    end
  end

  -- The formation INCLUDE keeps the 5v5 values of two locals (n33 starters 5, n37 field height 40) after OnInitFormationCommon(..., false), so the loader puts the 11v11 values back; probe returns 0 when available, -1 when not.
  function PT.can_reset()
    if not PT.loader or type(UpdateFormationReducedDrawingIconPos) ~= "function" then
      return false
    end
    local r = VRFW.host.command(PT.UPVAL, UpdateFormationReducedDrawingIconPos)
    return r == 0
  end

  function PT.ensure5(set)
    local changed = PT.ensure5core(set)
    if changed and type(PT.link) == "function" then
      PT.link(set)
    end
    if PT.ask("link_five", set) == true then
      return true
    end
    return changed
  end

  function PT.ensure5core(set)
    if not PT.is_dock(set) or not PT.loader then
      return false
    end
    PT.clear_ts(set)
    return (PT.form5(set))
  end

  -- Returns a 5v5 formation for team 1 of `set`.
  function PT.form5(set)
    local ok, f = funcLuaCommand(PT.GET_INFO, set, 1, 4)
    if ok and VRFW.formation.is_five_a_side(f) ~= false then
      return false, f
    end
    funcLuaCommand(PT.SET_INFO, set, 1, 3, PT.FORM5_DEFAULT)
    local ok2, name = funcLuaCommand(PT.GET_INFO, set, 0, 6)
    if ok2 and type(name) == "string" and name ~= "" then
      funcLuaCommand(PT.SET_INFO, set, 1, 0, name)
    end
    PT.log("5v5 template initialised", set, tostring(f))
    return true, PT.FORM5_DEFAULT
  end

  -- Brings the 5v5 team of `set` to its 11v11 team's players.
  function PT.mirror(set)
    if not PT.loader or not PT.is_dock(set) then
      return false, 0, 0
    end
    local changed, f = PT.form5(set)
    local n, out, inn = VRFW.host.command(PT.MIRROR, set, type(f) == "number" and f or 0)
    if type(n) == "number" and n > 0 then
      PT.log("5v5 players follow the match team", set, n, tostring(out), tostring(inn))
      return true, tonumber(out) or 0, tonumber(inn) or 0
    end
    return changed, 0, 0
  end

  function PT.refresh_all()
    local function try(f, ...)
      if type(f) == "function" then
        local ok, e = pcall(f, ...)
        if not ok then
          PT.log("refresh error", tostring(e))
        end
      end
    end
    try(SetupMemberCharaStHdlList, n5)
    try(SetShowTeamDockNo, n5)
    try(SetupTeamPower, n5)
    try(function()
      SetFormationId(GetTeamDockFormationId())
    end)
    try(SetVisibleHeaderTeamDoc, true, n5)
    for i = 0, (n or 0) - 1 do
      try(SetupTeamDockListItem, i)
      try(UpdateViewTeamDockListItem, i)
    end
    try(UpdateViewMenuByLock)
    try(funcLuaMenuCommand, @crc:CMND_UPDATE_SYNERGY_BUTTON@, 1179455358 --[[team00_17_synergy_attachment_button_pillar]], 0, n5, n10)
    try(funcLuaMenuCommand, @crc:CMND_UPDATE_SYNERGY_BUTTON@, 830633104 --[[team00_17_synergy_attachment_button_flag]], 0, n5, n10)
    try(SetupTeamDockTeamNameBar)
    try(UpdateViewTeamDockNo)
    try(SetActiveDockBackground, n4 == n5)
    try(UpdateTeamBuildTypeInfo, n5, n10)
    flag3 = true                     -- Step -> UpdateFormationInfo (cards on the pitch)
  end

  -- The card positions of the pitch are written once, in OnSetupCharaCardLayer (menu setup)
  PT.CARD, PT.BLANK = 1973487846, 3571911991   -- team00_01_chara_card_for_soccer / team00_01_p1_chara_card_blank
  PT.GET_POS, PT.SET_POS, PT.EXISTS_LAYER = @crc:CMND_GET_LAYER_LOCAL_POS@, @crc:CMND_SET_LAYER_LOCAL_POS@, @crc:CMND_IS_EXIST_LAYER@
  function PT.bench_rest()
    local moved = 0
    for _, L in ipairs({PT.CARD, PT.BLANK}) do
      local x, y, z = VRFW.host.menu_command(PT.GET_POS, L, 18)
      if type(x) ~= "number" then
        x, y, z = 0, 0, 0
      end
      for i = 5, 18 do
        if funcLuaMenuCommand(PT.EXISTS_LAYER, L, i) == true then
          funcLuaMenuCommand(PT.SET_POS, L, x, y or 0, z or 0, i)
          moved = moved + 1
        end
      end
    end
    return moved
  end

  -- 11v11-only layers of the pitch
  PT.ONLY11 = {209828247 --[[team00_16_nickname]], 3266940395 --[[vroad02_03_seasonal_cap_plate_small]]}
  function PT.close11()
    for _, L in ipairs(PT.ONLY11) do
      if funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, L) then
        funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, L)
      end
    end
  end

  -- the player plate VM looks cards up in the team of the pitch (graft pachanga_plate)
  function PT.plate_kind(kind)
    local r = VRFW.host.command(830228314, PT.PLATE_MENU, "football_reforged_plate_kind", kind, n5)
    PT.log("plate team kind", kind, "dock", n5, tostring(r))
  end

  -- Hides the Pachanga items.
  function PT.hide_ts()
    for L in pairs(PT.NO5) do
      local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, L) or 1
      for i = 0, math.max(n, 1) - 1 do
        VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, L, i, false)
      end
      VRFW.host.menu_command(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, L, false)
    end
  end

  function PT.show_ts()
    local all = {}
    for L in pairs(PT.NO5) do
      all[#all + 1] = L
    end
    for _, L in ipairs(PT.TACTICS) do
      all[#all + 1] = L
    end
    for _, L in ipairs(all) do
      if funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, L) then
        local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, L) or 1
        for i = 0, math.max(n, 1) - 1 do
          VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, L, i, true)
        end
      end
      VRFW.host.menu_command(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, L, true)
    end
  end

  function PT.clear_ts(set)
    if not PT.is_dock(set) then
      return
    end
    for kind = 0, 1 do
      VRFW.host.command(PT.SET_INFO, set, 1, 9, 0, kind)       -- synergy flag / pillar emptied (retail toggle)
    end
  end

  -- Rebuilds the field base and the 19 cards (OnCloseLayer to CloseCommonSoccerFormationUI).
  function PT.rebuild(to)
    local BAR = 1044086265           -- team01_04_team_name_bar
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, BAR)
    for _ = 1, 90 do
      if not funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, BAR)
          and not funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, n11) then
        break
      end
      coroutine.yield()
    end
    if to == 0 then
      PT.clear_kind()
      local r = funcLuaCommand(PT.UPVAL, UpdateFormationReducedDrawingIconPos, 5, 11, 40, 94)
      PT.log("include reset", tostring(r))
      SetFormationLayer(3321884270 --[[soccer11_02_formation_frame]])
      SetupTeamMemberNumMax(19)
    end
    if to == 1 then
      PT.refresh()
      PT.ensure5(n5)
    end
    n10 = to
    n11 = to == 1 and 3518110933 --[[mainmenu04_10_formation_base]] or 3321884270 --[[soccer11_02_formation_frame]]
    OnInitFormationCommon(GetTeamDockFormationId(), nil, n5, nil, nil, nil, to == 1)
    PT.plate_kind(to)
    PT.refresh()
    n4 = to == 1 and PT.active or funcLuaCommand(PT.GET_VS)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, BAR)
    coroutine.yield()
    if to == 0 then
      PT.show_ts()
    end
    PT.refresh_all()
    if to == 1 then
      PT.log("bench cards re-placed", PT.bench_rest())
      PT.close11()
      PT.hide_ts()
      PT.header()
    else
      local s = VRFW.host.command(PT.TEXT_GET, PT.TEXT_HEADER)
      VRFW.host.menu_command(PT.SET_HEADER, 5, (type(s) == "string") and s or "")
    end
    PT.flags()
  end

  function PT.switch(a1, col)
    PT.notify("type_switching")
    PT.switch_type(a1, col)
    PT.notify("type_switched")
  end

  function PT.switch_type(a1, col)
    col = col or PT.cur_col()
    local function back()
      funcLuaMenuCommand(1558704558, PT.MENU_ID, true)
      funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, a1, true)
    end
    if PT.busy then
      return                         -- one press = one switch (a second decide while the pitch is rebuilt)
    end
    if not PT.gate(col, true) then
      back()
      return
    end
    local to = PT.kinds()[col].kind
    if MENU_DEF.IsRequestToDisplayTeamDockMemberErrorMessage(nil, true, n10) then
      back()
      return
    end
    PT.busy = true
    PT.flags()
    PT.log("switch", n10, "->", to, "dock", n5, "in place")
    funcLuaMenuCommand(1558704558, PT.MENU_ID, false)
    local ok, e = pcall(PT.rebuild, to)
    PT.busy = false
    if not ok then
      PT.log("switch error", tostring(e))
    end
    PT.log("switched", PT.pachanga() and "pachanga" or "partido", "dock", n5, "active", n4)
    back()
    PT.draw_row()
  end

  if FootballReforged.friendly_dock_link == nil then
    FootballReforged.friendly_dock_link = true
  end
  if FootballReforged.friendly_dock_link_snap == nil then
    FootballReforged.friendly_dock_link_snap = {}
  end
  PT.L = {
    MOVE = 193693077,
    POS_IDX = 1721292418,            -- (set, team, pos) -> ok, member index
    IDX_HDL = 1720957768,            -- (set, team, member, 0 | 1) -> ok, handle | position
    DIRECTOR = 1108596907,           -- (set, team, director id): the coach id of the team (+0x288)
    CHARA = 1131797651,              -- (hdl, 4) -> director id of a character
    TEAM_UNIFORM = @crc:CMND_VRFW_TEAM_UNIFORM@,      -- CMND_VRFW_TEAM_UNIFORM (set, team [, uniformId]) -> ok, uniformId
    TACTIC_INFO = @crc:CMND_GET_SPECIAL_TACTICS_INFO@,        -- CMND_GET_SPECIAL_TACTICS_INFO (id, 10) -> ok, refused in a 5v5 team
    PLAY_MODE = @crc:CMND_GET_PLAY_GAME_MODE@,
    BANK = 16, COACH = 19, MEMBERS = {16, 17, 18, 19}, SLOTS = 4, ENTRIES = 29,
    logs = 0,
  }

  function PT.llog(...)
    if PT.L.logs < 60 then
      PT.L.logs = PT.L.logs + 1
      PT.L.logger = PT.L.logger or VRFW.logger.new("EVT pachanga link")
      PT.L.logger(...)
    end
  end

  function PT.can_link()
    if not FootballReforged.friendly_dock_on or not FootballReforged.friendly_dock_link or PT.dock_claimed() then
      return false
    end
    return VRFW.host.command(PT.L.PLAY_MODE) ~= 2
  end

  function PT.num(ok, v)
    if ok == true and type(v) == "number" then
      return v
    end
    return 0
  end

  -- Returns the handle at a position of template t (0 means empty).
  function PT.member_at(set, t, pos)
    local ok, idx = VRFW.host.command(PT.L.POS_IDX, set, t, pos)
    if ok ~= true or type(idx) ~= "number" or idx < 0 then
      return 0
    end
    local okh, h = VRFW.host.command(PT.L.IDX_HDL, set, t, idx, 0)
    if okh ~= true or type(h) ~= "number" or h == 0 then
      return 0
    end
    local okp, p = VRFW.host.command(PT.L.IDX_HDL, set, t, idx, 1)
    if okp == true and type(p) == "number" and p ~= pos then
      return 0
    end
    return h
  end

  function PT.member_link(set)
    return PT.loader == true and set >= 3 and set <= 12
  end

  -- Reads the identity of template t.
  function PT.read_id(set, t)
    local id = {tac = {}, mem = {}}
    local ok, s = VRFW.host.command(PT.GET_INFO, set, t, 6)
    id.name = (ok == true and type(s) == "string") and s or ""
    id.emblem = PT.num(VRFW.host.command(PT.GET_INFO, set, t, 5, 0))   -- (set, team, 5, 0): the retail emblem read
    id.kit = {PT.num(VRFW.host.command(PT.GET_INFO, set, t, 7)), PT.num(VRFW.host.command(PT.GET_INFO, set, t, 12))}
    for i = 1, PT.L.SLOTS do
      id.tac[i] = PT.num(VRFW.host.command(PT.GET_INFO, set, t, 9, i - 1))
    end
    if PT.member_link(set) then
      for _, p in ipairs(PT.L.MEMBERS) do
        id.mem[p] = PT.member_at(set, t, p)
      end
    end
    return id
  end

  -- The 5v5 team always wears the emblem of the dock's match team (Partido)
  function PT.copy_match_emblem(set, match, five)
    if match == 0 or match == five then
      return false
    end
    VRFW.host.command(PT.SET_INFO, set, 1, 1, match)
    return true
  end

  function PT.tac5(v)
    if v == 0 then
      return 0
    end
    local ok, no = VRFW.host.command(PT.L.TACTIC_INFO, v, 10)
    if ok and no then
      return 0
    end
    return v
  end

  local function same(a, b)
    if type(a) == "table" and type(b) == "table" then
      return a[1] == b[1] and a[2] == b[2]
    end
    return a == b
  end
  local function plain(v)
    return v
  end
  local function sameArr(x, y)
    for i = 1, PT.L.SLOTS do
      if x[i] ~= y[i] then
        return false
      end
    end
    return true
  end

  -- Picks the winner of one field.
  function PT.side(a, b, s, norm)
    norm = norm or plain
    if same(norm(a), b) then
      return nil
    end
    if s ~= nil and same(a, s) and not same(b, norm(s)) then
      return 1
    end
    return 0
  end

  function PT.put_kit(set, t, kit)
    local uid, inv = kit[1], kit[2]
    if inv ~= 0 then
      VRFW.host.command(PT.SET_INFO, set, t, 2, inv)             -- the owned kit item (SetTeamUniform: item + home uniform)
    elseif uid == 0 then
      VRFW.host.command(PT.SET_INFO, set, t, 7, 0)               -- no kit
    end
    if uid ~= 0 and PT.num(VRFW.host.command(PT.GET_INFO, set, t, 7)) ~= uid then
      VRFW.host.command(PT.L.TEAM_UNIFORM, set, t, uid)          -- the Visitante twin, or a kit without its item
    end
  end

  function PT.put_tac(set, t, vals)
    local cur = {}
    for i = 1, PT.L.SLOTS do
      cur[i] = PT.num(VRFW.host.command(PT.GET_INFO, set, t, 9, i - 1))
    end
    for i = 1, PT.L.SLOTS do                           -- empty the changed slots first: a tactic may change slot
      if cur[i] ~= vals[i] and cur[i] ~= 0 then
        VRFW.host.command(PT.SET_INFO, set, t, 4, 0, i - 1)
      end
    end
    for i = 1, PT.L.SLOTS do
      if cur[i] ~= vals[i] and vals[i] ~= 0 then
        VRFW.host.command(PT.SET_INFO, set, t, 4, vals[i], i - 1)
      end
    end
  end

  -- Template t's coach and managers become want[16..19] (each handle at most once).
  function PT.put_members(set, t, cur, want, note)
    local changes = false
    for _, p in ipairs(PT.L.MEMBERS) do
      if cur[p] ~= want[p] then
        changes = true
        if cur[p] ~= 0 then
          if p == PT.L.COACH then
            VRFW.host.command(PT.L.DIRECTOR, set, t, 0)
          end
          for _ = 1, PT.L.ENTRIES do
            if PT.member_at(set, t, p) ~= cur[p] then
              break
            end
            VRFW.host.command(PT.L.MOVE, PT.L.BANK, p, set, cur[p], t)
          end
        end
      end
    end
    if not changes then
      return
    end
    for _, p in ipairs(PT.L.MEMBERS) do
      local h = want[p]
      if h ~= 0 and PT.member_at(set, t, p) == 0 then
        VRFW.host.command(PT.L.MOVE, set, p, PT.L.BANK, h, t)
        if p == PT.L.COACH then
          local d = VRFW.host.command(PT.L.CHARA, h, 4)
          if type(d) == "number" and d ~= 0 then
            VRFW.host.command(PT.L.DIRECTOR, set, t, d)
          end
        end
      end
      if PT.member_at(set, t, p) ~= cur[p] then
        note(p, t)
      end
    end
  end

  -- Returns what position p of both templates holds after the sync.
  function PT.want_members(a, b, snap)
    local want, used = {}, {}
    for _, p in ipairs(PT.L.MEMBERS) do
      local first, second = a.mem[p], b.mem[p]
      if PT.side(first, second, snap.mem[p]) == 1 then
        first, second = second, first
      end
      local h = first
      if h ~= 0 and used[h] then
        h = second
      end
      if h ~= 0 and used[h] then
        h = 0
      end
      want[p] = h
      if h ~= 0 then
        used[h] = true
      end
    end
    return want
  end

  function PT.link(set)
    if not PT.is_dock(set) or not PT.can_link() then
      return false
    end
    -- the snapshot is the team's, and a dock's team changes with its team template
    local template = VRFW.host.command(PT.TEMPLATE_OF_DOCK, set)
    local key = type(template) == "number" and "template " .. template or set
    local snap = FootballReforged.friendly_dock_link_snap[key] or {tac = {}, mem = {}}
    local a, b = PT.read_id(set, 0), PT.read_id(set, 1)
    local did = {}
    local function note(what, side)
      did[#did + 1] = what .. (side == 1 and "<5v5" or ">5v5")
    end
    local sd = PT.side(a.name, b.name, snap.name)
    if sd == 0 then
      VRFW.host.command(PT.SET_INFO, set, 1, 0, a.name)
    elseif sd == 1 then
      VRFW.host.command(PT.SET_INFO, set, 0, 0, b.name)
    end
    if sd then note("name", sd) end
    if PT.copy_match_emblem(set, a.emblem, b.emblem) then note("emblem", 0) end
    sd = PT.side(a.kit, b.kit, snap.kit)
    if sd == 0 then
      PT.put_kit(set, 1, a.kit)
    elseif sd == 1 then
      PT.put_kit(set, 0, b.kit)
    end
    if sd then note("kit", sd) end
    local t0, t1, tw = {}, {}, false
    for i = 1, PT.L.SLOTS do
      t0[i], t1[i] = a.tac[i], b.tac[i]
      local s = PT.side(a.tac[i], b.tac[i], snap.tac[i], PT.tac5)
      if s == 0 then
        t1[i], tw = PT.tac5(a.tac[i]), true
      elseif s == 1 then
        t0[i], tw = b.tac[i], true
      end
    end
    if tw then
      if not sameArr(t0, a.tac) then
        PT.put_tac(set, 0, t0)
        note("tactics", 1)
      end
      if not sameArr(t1, b.tac) then
        PT.put_tac(set, 1, t1)
        note("tactics", 0)
      end
    end
    if PT.member_link(set) then
      local want = PT.want_members(a, b, snap)
      local function noteMember(p, t)
        note(p == PT.L.COACH and "coach" or ("manager" .. p), t == 0 and 1 or 0)
      end
      PT.put_members(set, 0, a.mem, want, noteMember)
      PT.put_members(set, 1, b.mem, want, noteMember)
    end
    local mirrored, out, inn = PT.mirror(set)
    if mirrored then
      did[#did + 1] = "players>5v5"
      PT.pool_fix = (PT.pool_fix or 0) + out + inn
    end
    -- A field still apart (a refused write) is not recorded, so the next sync takes the Partido value again instead of reading the refusal as a Pachanga edit.
    if #did > 0 then
      a, b = PT.read_id(set, 0), PT.read_id(set, 1)
    end
    local new = {tac = {}, mem = {}}
    if same(a.name, b.name) then new.name = a.name end
    if same(a.emblem, b.emblem) then new.emblem = a.emblem end
    if same(a.kit, b.kit) then new.kit = a.kit end
    for i = 1, PT.L.SLOTS do
      if same(PT.tac5(a.tac[i]), b.tac[i]) then new.tac[i] = a.tac[i] end
    end
    for _, p in ipairs(PT.L.MEMBERS) do
      if a.mem[p] ~= nil and same(a.mem[p], b.mem[p]) then new.mem[p] = a.mem[p] end
    end
    FootballReforged.friendly_dock_link_snap[key] = new
    if #did > 0 then
      PT.llog("dock", string.format("%02d", set - 1), table.concat(did, " "))
      return true
    end
    return false
  end

  -- Links every dock.
  function PT.link_all(why)
    if not PT.can_link() then
      return 0
    end
    local n = 0
    for set = 2, 12 do
      local ok, r = pcall(PT.link, set)
      if not ok then
        PT.llog("error", set, tostring(r))
      elseif r then
        n = n + 1
      end
    end
    if n > 0 then
      PT.flags()
    end
    PT.llog(why or "all", "docks changed", n)
    return n
  end

  -- Links the dock on screen, after something may have edited it (child menu, name, bank).
  function PT.link_shown()
    PT.pool_fix = 0
    local ok, r = pcall(PT.link, n5)
    if not ok then
      PT.llog("error", n5, tostring(r))
      return
    end
    if r then
      PT.flags()
      pcall(PT.refresh_all)
      if PT.pachanga() then
        pcall(PT.hide_ts)
        PT.marks()
        PT.header()
        if PT.pool_fix > 0 then
          PT.say(PT.text("POOL_ONLY"))
        end
      end
    end
  end

  -- Records the VS team the dock opened with, read underneath every hook.
  function PT.keep_vs()
    local v = VRFW.host.real_command(PT.GET_VS)
    if type(v) == "number" then
      PT.vs = v
    end
  end

  function PT.leave()
    if not FootballReforged.friendly_dock_on or PT.dock_claimed() then
      return
    end
    -- Does the last edit of the docks, after other mods saw the dock close.
    PT.link_all("exit")
    local want = PT.vs
    if PT.loader then
      local had, r = VRFW.host.command(PT.VS, 0)
      if had == true and type(r) == "number" and r >= 0 and r < 16 then
        want = r
      end
    end
    local vs = VRFW.host.real_command(PT.GET_VS)
    if type(want) == "number" and want >= 0 and want < 16 and type(vs) == "number" and vs ~= want then
      funcLuaCommand(PT.SET_VS, want)
      PT.log("exit: VS team put back", vs, "->", want)
    end
    if PT.pachanga() then
      local v = VRFW.host.command(PT.GET_VS)
      if type(v) == "number" then
        n4 = v
      end
    end
    pcall(PT.clear_kind)
    pcall(PT.param, PT.KEY_ACTIVE_DOCK, nil)
    pcall(PT.param, PT.KEY_BANK, nil)
    PT.log("exit", PT.pachanga() and "pachanga" or "partido", "dock", n5, "vs", tostring(VRFW.host.command(PT.GET_VS)),
      "pachanga", PT.active)
  end

  PT.wrap("OnInit", function(orig)
    return function(...)
      PT.watch_plate_build()
      PT.refresh()
      pcall(PT.link_all, "open")
      local mode = PT.take(PT.KEY_MODE)
      local dock = PT.take(PT.KEY_DOCK)
      PT.start = nil
      if FootballReforged.friendly_dock_on and type(mode) == "number" and not PT.dock_claimed()
          and funcLuaMenuCommand(2119959601) == true then
        if mode == 2 then
          PT.param(PT.KEY_KIND, 1)   -- the retail OnInit reads it: n10 = 1, 5v5 field
        end
        PT.start = dock
      end
      local r = PT.pack(orig(...))
      PT.refresh()
      if PT.loader then
        local had, vs = VRFW.host.command(PT.VS, 0)
        if had == true and type(vs) == "number" and vs >= 0 and vs < 16 then
          if funcLuaCommand(PT.GET_VS) ~= vs then
            funcLuaCommand(PT.SET_VS, vs)
            PT.log("VS team restored after a trial", vs)
          end
          if not PT.pachanga() then
            n4 = funcLuaCommand(PT.GET_VS)
            pcall(SetActiveDockBackground, n4 == n5)
          end
        end
      end
      PT.keep_vs()                    -- the Partido team this visit has to leave behind (PT.leave)
      if PT.pachanga() then
        local want = PT.start
        if not PT.is_dock(want) and PT.is_dock(PT.active) then
          want = PT.active
        end
        PT.move_to(want)
        PT.ensure5(n5)
        PT.plate_kind(1)
        n4 = PT.active
        pcall(SetVisibleHeaderTeamDoc, true, n5)
        pcall(SetActiveDockBackground, n4 == n5)
        PT.header()
      elseif PT.is_dock(PT.start) then
        PT.move_to(PT.start)
        pcall(SetVisibleHeaderTeamDoc, true, n5)
        pcall(SetActiveDockBackground, n4 == n5)
      end
      PT.flags()
      PT.pick = nil
      PT.log("open", PT.pachanga() and "pachanga" or "partido", "dock", n5, "active", n4, "pachanga", PT.active,
        "loader", tostring(PT.loader))
      return table.unpack(r, 1, r.n)
    end
  end)

  -- Handles the 5v5 field opening (Pachanga at open or after the switch).
  PT.wrap("OnOpenLayer", function(orig)
    return function(a1, a2, ...)
      local r = PT.pack(orig(a1, a2, ...))
      if PT.pachanga() and a1 == n11 then
        pcall(PT.close11)
      end
      if PT.pachanga() and PT.NO5[a1] then
        VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2 or 0, false)
        VRFW.host.menu_command(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, a1, false)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  PT.wrap("OnChangeFocus", function(orig)
    return function(a1, a2, ...)
      local r = PT.pack(orig(a1, a2, ...))
      if PT.pachanga() and PT.NO5[a1] and type(OnChangeFocusCommon) == "function" then
        PT.log("focus moved off a hidden tactics / synergy layer", a1)
        pcall(OnChangeFocusCommon, PT.FORM_BOX, 0, true)
      end
      if FootballReforged.friendly_dock_on and PT.row_focused() then
        PT.active_line()
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  PT.wrap("Step", function(orig)
    return function(...)
      local r = PT.pack(orig(...))
      if FootballReforged.friendly_dock_on then
        PT.step_say()
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  PT.wrap("OnEnter", function(orig)
    return function(a1, a2, ...)
      if PT.pachanga() and PT.NO5[a1] then
        funcLuaCommand(PT.SOUND, PT.SE_NG)
        return 1
      end
      local col = FootballReforged.friendly_dock_on and a1 == PT.LIST and PT.col_at(a2) or nil
      if col ~= nil then
        if PT.busy or PT.co ~= nil or VRFW.team_dock.half_rows.deciding() or not PT.gate(col) then
          return 1
        end
        PT.pick = col                -- the format of this press, for its OnDecideFocus
      end
      if a1 == PT.NAME_FRAME then
        local r = PT.pack(orig(a1, a2, ...))
        PT.link_shown()
        return table.unpack(r, 1, r.n)
      end
      return orig(a1, a2, ...)
    end
  end)

  PT.wrap("OnDecideFocus", function(orig)
    return function(a1, a2, ...)
      local kind = nil
      if FootballReforged.friendly_dock_on and a1 == PT.LIST and type(a2) == "number" then
        kind = t[a2 + 1]
      end
      local rowCol = PT.col_of_kind(kind)
      if rowCol ~= nil then
        local col = PT.pick or rowCol  -- a decide without the dock's OnEnter: the decided row's format
        PT.pick = nil
        PT.switch(a1, col)           -- PT.gate again inside: a press OnEnter refused never switches
        return
      end
      if PT.pachanga() and PT.NO5[a1] then
        funcLuaCommand(PT.SOUND, PT.SE_NG)
        return
      end
      if PT.pachanga() and a1 == 721367678 --[[team00_14_build_type_icon]] and PT.is_dock(n5) then
        local r = table.pack(FootballReforged.bonus5(n5, "dock", orig, a1, a2, ...))
        if not r[1] then
          funcLuaMenuCommand(1558704558, PT.MENU_ID, true)
          funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, a1, true)
          return
        end
        return table.unpack(r, 2, r.n)
      end
      -- Handles the case without the team kind.
      local form = kind == 0 or a1 == PT.FORM_BOX
      local five = form and PT.pachanga()
      local eleven = form and FootballReforged.friendly_dock_on and not five
      if five then
        PT.param(PT.KEY_KIND, 1)
        PT.param(PT.KEY_PLATE_KIND, 1)
        for _, k in ipairs(PT.KEY_PF) do
          PT.param(k, n5)
        end
        for _, k in ipairs(PT.KEY_PF11) do
          PT.param(k, nil)
        end
        PT.plate_kind(1)
        PT.log("formation screen in 5v5 mode", kind == 0 and "list" or "box", "dock", n5)
      elseif eleven then
        PT.param(PT.KEY_KIND, 0)
        PT.param(PT.KEY_PLATE_KIND, 0)
        for _, k in ipairs(PT.KEY_PF) do
          PT.param(k, nil)
        end
        for _, k in ipairs(PT.KEY_PF11) do
          PT.param(k, n5)
        end
        PT.log("formation screen in 11v11 mode", kind == 0 and "list" or "box", "dock", n5)
      end
      local r = PT.pack(pcall(orig, a1, a2, ...))
      if not r[1] then
        error(r[2], 0)
      end
      r = PT.pack(table.unpack(r, 2, r.n))
      if five or eleven then
        PT.clear_kind()
        if PT.pachanga() then
          pcall(PT.hide_ts)
        end
      end
      -- A child menu (emblem, kit, tactics, formation screen, bank, team name bar) may have edited one template.
      PT.link_shown()
      if kind ~= nil then
        PT.flags()
        PT.marks()
        PT.header()
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  PT.wrap("OnFunction", function(orig)
    return function(a1, a2, ...)
      if PT.pachanga() and a1 == PT.ACTIVE_FUNC and not PT.dock_claimed() then
        PT.set_active()
        return
      end
      local r = PT.pack(orig(a1, a2, ...))
      if a1 == PT.ACTIVE_FUNC and not PT.pachanga() then
        PT.keep_vs()
        PT.refresh()
      end
      if PT.pachanga() and a1 == PT.PAGE_FUNC then
        if PT.ensure5(n5) then
          PT.refresh_all()
        end
        PT.marks()
        pcall(PT.hide_ts)
        PT.plate_kind(1)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  PT.wrap("OpenCharaBank", function(orig)
    return function(...)
      if not (PT.pachanga() and PT.is_dock(n5)) then
        return orig(...)
      end
      PT.param(PT.KEY_BANK, n5)
      PT.log("bank in 5v5 view", n5)
      local r = PT.pack(pcall(orig, ...))
      PT.param(PT.KEY_BANK, nil)
      pcall(PT.refresh_all)
      pcall(PT.hide_ts)
      PT.plate_kind(1)
      if not r[1] then
        PT.log("bank error", tostring(r[2]))
        return
      end
      return table.unpack(r, 2, r.n)
    end
  end)

  PT.wrap("FuncOnBack", function(orig)
    return function(...)
      local ok, e = pcall(PT.leave)
      if not ok then
        PT.log("exit error", tostring(e))
      end
      PT.flags()
      return orig(...)
    end
  end)

  PT.wrap("SwapHeaderTextBack", function(orig)
    return function(...)
      local r = PT.pack(orig(...))
      PT.header()
      return table.unpack(r, 1, r.n)
    end
  end)

  PT.wrap("SetupTeamPower", function(orig)
    return function(a1, ...)
      if not PT.pachanga() then
        return orig(a1, ...)
      end
      local ok, at, df = funcLuaCommand(@crc:CMND_GET_TEAM_SET_INFO@, a1, 1, 14)
      local L = 859123864 --[[mainmenu04_06_team_atdf]]
      local p = funcLuaMenuCommand(@crc:CMND_SEARCH_PRIM_INDEX@, L, 0, 3699456408)
      funcLuaMenuCommand(3609943765, L, 0, p, at)
      p = funcLuaMenuCommand(@crc:CMND_SEARCH_PRIM_INDEX@, L, 0, 4110270132)
      funcLuaMenuCommand(3609943765, L, 0, p, df)
      funcLuaMenuCommand(1233047821, L, 0, 3699456408, true)
      funcLuaMenuCommand(1233047821, L, 0, 4110270132, true)
    end
  end)

  -- Wraps the header dock plate.
  PT.wrap("SetVisibleHeaderTeamDoc", function(orig)
    return function(a1, a2, a3, ...)
      if not PT.pachanga() then
        return orig(a1, a2, a3, ...)
      end
      local m = 811496143 --[[soccer_top_menu]]
      if a3 == nil then
        local p = MENU_DEF.GetParentMenuID(2049316981 --[[soccer_formation_menu]])
        if p ~= 0 then
          m = p
        end
      else
        m = a3
      end
      funcLuaMenuCommand(4108281619, m, a2, a1, a2 == PT.active)
    end
  end)

  -- Skips the check when no active pachanga dock exists, since there is nothing to check.
  if type(MENU_DEF) == "table" and type(MENU_DEF.IsRequestToDisplayTeamDockMemberErrorMessage) == "function"
      and not FootballReforged.friendly_dock_wrapped[MENU_DEF.IsRequestToDisplayTeamDockMemberErrorMessage] then
    local prev = MENU_DEF.IsRequestToDisplayTeamDockMemberErrorMessage
    local w = function(a1, a2, a3, a4)
      if a1 == nil and a3 == 1 and PT.pachanga() then
        if not PT.is_dock(PT.active) then
          return false
        end
        return prev(PT.active, a2, a3, a4)
      end
      return prev(a1, a2, a3, a4)
    end
    FootballReforged.friendly_dock_wrapped[w] = true
    MENU_DEF.IsRequestToDisplayTeamDockMemberErrorMessage = w
  end

  if type(VRFW.team_dock) == "table" then
    VRFW.team_dock.on("page_changing", "pachangas", function()
      PT.refresh()
      pcall(PT.link_all, "page")
      if PT.pachanga() then
        PT.ensure5(n5)
      end
    end)
    VRFW.team_dock.on("page_changed", "pachangas", function()
      PT.keep_vs()              -- the page swap restores that page's own VS team
      if PT.pachanga() then
        PT.refresh()
        PT.marks()
        pcall(PT.hide_ts)
        PT.plate_kind(1)
      end
    end)
    VRFW.team_dock.on("header", "pachangas", function()
      PT.header()
    end)
  end
end
