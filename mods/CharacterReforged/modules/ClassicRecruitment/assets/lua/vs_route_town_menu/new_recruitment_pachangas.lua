-- Classic Recruitment › the pachanga zones of the Chronicle board, game Lua of
-- the board (vs_route_town_menu). A zone node is a [[VRFW.NodeMenu]] node (content\node_menus\pachangas.toml): picking
-- it calls ClassicRecruitment.PachangaNode, which opens the zone's pachanga list (ClassicRecruitment.PachangaMenu.Open: the
-- framework's pose row screen, content\pose_rows\pachangas.toml); choosing a pachanga plays it
-- (ClassicRecruitment.PachangaBoard.Play): a 5v5 friendly of the framework's match start service (friendly
-- new_recruitment_pachanga, the rival team and the zone's stadium given), back on the board afterwards. A pachanga is
-- only a match: nobody joins after it; a won one is ticked on the list (save key won.<pachanga>).
-- Handlers of the framework's board host (VRFW_Host) and globals only: nothing runs at load but their registration.
if VRFW_Host ~= nil then
  ClassicRecruitment = ClassicRecruitment or {}
  local B = {
    STEM = "vs_route_town_menu",
    ZONE = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_ZONE,               -- CMND_CLASSICRECRUITMENT_PACHANGA_ZONE (node) -> zone, title, stadium, count
    GET = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_GET,                -- CMND_CLASSICRECRUITMENT_PACHANGA_GET (zone, i) -> key, team, name, level, format, won, n, cards…
    ARM = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_ARM,               -- CMND_CLASSICRECRUITMENT_PACHANGA_ARM (key)
    RESULT = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_RESULT,            -- CMND_CLASSICRECRUITMENT_PACHANGA_RESULT () -> key, won
    SET_WON = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_SET_WON,           -- CMND_CLASSICRECRUITMENT_PACHANGA_SET_WON (key)
    FRIENDLY = "new_recruitment_pachanga",
    -- no active pachanga team: the same pachanga with the player's active match team (content\friendlies\pachanga.toml)
    FRIENDLY_TEAM = "new_recruitment_pachanga_active_team",
    K_NO_TEAM = 1906889941,         -- new_recruitment_pachangas_no_team (the notice of a pachanga that cannot start)
    GAME = 2372839589,              -- sbtl_rojiura_01: a retail 5v5 match row (game type 2: the stadiums' 5v5 lines)
    MENU = "ClassicRecruitment.pachangas",   -- the pose row (content\pose_rows\pachangas.toml)
    -- the board's layers hidden while the list is up and shown again when it closes (VRFW_PoseRow.Open): its footer,
    -- the piece's title banner, the zoom guides, the cursor, the area / route header, and the map's node pieces, their
    -- team emblems, clear orbs, locks, keys and destination icons (they are drawn over the list and the side panel,
    -- ); the map and its roads stay
    HIDE = {1423637364 --[[rpg00_05_menu_button_guide]], 139522149 --[[vsroute02_03_gametitle]],
            3860387247 --[[vsroute_zoom_guide]], 1635409244 --[[vsroute_p1_area_zoom_guide]],
            2296367164 --[[cmn05_01_cursor]], 3905678584 --[[vsroute00_03_area_name_plate]],
            4002479583 --[[vsroute00_05_town_map_piece]], 1632548965 --[[vsroute00_07_town_map_piece_atc_chara]],
            4088477286 --[[vsroute01_06b_town_map_piece_clear_icon]],
            2638032167 --[[vsroute01_06c_town_map_piece_clear_icon]],
            1617793781 --[[vsroute01_09_town_map_piece_lock_front]],
            3060354640 --[[vsroute01_09b_town_map_piece_lock_back]],
            907932950 --[[vsroute01_07c_gate_key_icon]], 1225175571 --[[vsroute01_07_obtain_gate_key_icon]],
            57708379 --[[vsroute01_07b_gate_keyhole_icon]], 3325939278 --[[vsroute01_08_destination_icon]]},
    BASE = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_BASE,              -- CMND_CLASSICRECRUITMENT_PACHANGA_BASE (team level): the levels scale from it
    LEVEL = VRFW_Cmd.CLASSICRECRUITMENT_PACHANGA_LEVEL,             -- CMND_CLASSICRECRUITMENT_PACHANGA_LEVEL (key) -> its level now, the row level
    TEAM_LEVEL = VRFW_Cmd.VRFW_TEAM_LEVEL,        -- CMND_VRFW_TEAM_LEVEL (team, row level, level): the team plays at that level
    BOARD = 364708540,              -- vs_route_town_menu (the host the team dock opens over)
    TEAM_KIND = 4081600465,         -- retail parameter: the team kind the team dock opens with (1 = 5v5)
    FIVE = 1,
    -- the board's caravan (the background layer's menu model, slot 0) hidden while the list is up
    MODELS = {{1021315501 --[[vsroute00_00_background]], 0}},
  }
  ClassicRecruitment.PachangaBoard = B

  local function call(cmd, ...)
    local r = table.pack(pcall(funcLuaCommand, cmd, ...))
    if not r[1] then return nil end
    return table.unpack(r, 2, r.n)
  end

  function B.Log(...)
    pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "ClassicRecruitment pachangas", ...)
  end

  -- a zone of a node: {index, title, stadium, list = {{key, team, name, level, format, won, cards}…}}
  function B.Zone(node)
    local zi, title, stadium, n = call(B.ZONE, node)
    if type(zi) ~= "number" then return nil end
    local zone = {index = zi, node = node, title = title or 0, stadium = stadium or 0, list = {}}
    for i = 1, n or 0 do
      local r = table.pack(call(B.GET, zi, i))
      if r[1] ~= nil then
        zone.list[#zone.list + 1] = {key = r[1], team = r[2], name = r[3], level = r[4], format = r[5],
                                     won = r[6] == true, cards = {table.unpack(r, 8, 7 + (r[7] or 0))}}
      end
    end
    return zone
  end

  -- start pachanga `p` of `zone` (B.Zone) from the board: true, or false + why
  function B.Play(zone, p)
    if VRFW_MATCH == nil or VRFW_MATCH.start == nil then return false, "no match start service" end
    -- its level (the player's team level + the pachanga's offset): the rival's members' offsets over the row level
    local lv, row = call(B.LEVEL, p.key)
    if type(lv) == "number" and type(row) == "number" and row >= 1 then
      local okl, whyl = call(B.TEAM_LEVEL, p.team, row, lv)
      B.Log("level", p.key, lv, "row", row, tostring(okl), tostring(whyl))
    end
    if call(B.ARM, p.key) ~= true then return false, "unknown pachanga" end
    B.Log("play", p.key, "team", p.team, "stadium", zone.stadium)
    return VRFW_MATCH.start{
      friendly = B.FRIENDLY, game = B.GAME, difficulty = 1, set = B.TeamSet,
      stadium = (zone.stadium ~= 0) and zone.stadium or nil, rival = p.team,
      overrides = {{"teams.rival.team", p.team}}, play_mode = 1, black = false,
      on_failed = function(why)
        B.Log("start failed", p.key, tostring(why))
        B.Explain(why)
      end,
    }
  end

  -- the team that plays (read by the match start service under the match's play mode): the active pachanga team;
  -- none set: the active match team's five with the friendly of that policy; neither has a complete five: -1 (the
  -- friendly refuses, B.Explain tells why)
  -- (the framework's shared policy: VRFW_MATCH.pachanga_team)
  function B.TeamSet()
    return VRFW_MATCH.pachanga_team(B.FRIENDLY_TEAM)
  end

  -- the list's Y «Plantilla de equipo»: the player's own team dock in its 5v5 view (the retail team kind parameter
  -- read by the dock's OnInit; the Pachanga templates open on the active pachanga team) through the framework's team
  -- editor in its own team mode (the dock edits the save as the main menu's does), over the board with the board's
  -- list chrome and caravan hidden
  function B.TeamDock()
    local E = VRFW_TeamEditor
    if E == nil or type(E.Run) ~= "function" then
      B.Log("team dock: no team editor service")
      return false
    end
    pcall(funcLuaMenuCommand, VRFW_Cmd.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE, false)
    pcall(funcLuaMenuCommand, 1524491681, 10)   -- as the board's command menu does before it opens the dock
    VRFW_Param.Clear(B.TEAM_KIND)
    VRFW_Param.Set(B.TEAM_KIND, B.FIVE)
    local hidden = VRFW_PoseRow.HideLayers(B.HIDE)
    local kept = VRFW_PoseRow.CallerModels(B.MODELS, false)
    local ok, res, why = pcall(E.Run, {owner = "ClassicRecruitment", host = B.BOARD, own = true})
    VRFW_PoseRow.CallerModels(B.MODELS, true, kept)
    VRFW_PoseRow.ShowLayers(hidden)
    -- the team screen's background turned the free cursor on; the list opens as it did before the dock
    pcall(funcLuaMenuCommand, VRFW_Cmd.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE, false)
    if not ok or type(res) ~= "table" then
      -- never opened: the kind is not left for the next dock
      VRFW_Param.Clear(B.TEAM_KIND)
      B.Log("team dock", "not opened", tostring(ok and why or res))
      return false
    end
    B.Log("team dock", "closed")
    return true
  end

  -- a pachanga refused for its team (the match engine's refusal 4, no team): the game's notice says what to do
  -- instead of the list just closing
  function B.Explain(why)
    if tonumber(why) ~= 4 then
      return
    end
    local t = call(VRFW_Cmd.TEXT_GET, B.K_NO_TEAM)
    if type(t) ~= "string" or t == "" or ClassicRecruitment.Notice == nil or coroutine.running() == nil then
      return
    end
    pcall(ClassicRecruitment.Notice, t)
  end

  -- back on the board: the last armed pachanga's result (read once); a won one is ticked in the save
  VRFW_Host.on(B.STEM, "OnInit", {
    id = "ClassicRecruitment.pachanga_result", phase = "after",
    fn = function()
      local key, won = call(B.RESULT)
      if key == nil then return end
      B.Log("result", key, won == true and "won" or "not won")
      if won == true then call(B.SET_WON, key) end
    end,
  })
end

ClassicRecruitment = ClassicRecruitment or {}

-- the zone's pachanga list (the framework's pose row screen, waited for in the board's coroutine); a pick plays it
ClassicRecruitment.PachangaMenu = ClassicRecruitment.PachangaMenu or {}
function ClassicRecruitment.PachangaMenu.Open(zone)
  local B = ClassicRecruitment.PachangaBoard
  if VRFW_PoseRow == nil or #zone.list == 0 then
    return false
  end
  -- the levels scale with the player's active team (zone_rules.toml [level])
  if VRFW_Recruit ~= nil and VRFW_Recruit.TeamLevel ~= nil then
    pcall(funcLuaCommand, B.BASE, VRFW_Recruit.TeamLevel())
  end
  local pick, focus
  while true do
    pick, focus = VRFW_PoseRow.Open(B.MENU, zone.index, {hide = B.HIDE, models = B.MODELS, focus = focus})
    if pick == nil then
      return false                   -- never shown: the piece's command menu opens as usual
    end
    if pick ~= -1 then
      break
    end
    -- Y «Plantilla de equipo»: the player's own 5v5 team, then the list again on the same pachanga (built again from
    -- the edited team)
    B.TeamDock()
  end
  local p = zone.list[pick]
  if p ~= nil then
    local ok, why = B.Play(zone, p)
    if ok ~= true then
      B.Log("play", p.key, "refused", tostring(why))
      B.Explain(why)
    end
  end
  return true
end

-- [[VRFW.NodeMenu]] handler (content\node_menus\pachangas.toml): a zone node was picked on the board
function ClassicRecruitment.PachangaNode(idx, node, key)
  local B = ClassicRecruitment.PachangaBoard
  if B == nil then
    return false
  end
  local zone = B.Zone(node)
  if zone == nil then
    B.Log("node", node, "has no zone")
    return false
  end
  return ClassicRecruitment.PachangaMenu.Open(zone) == true
end
