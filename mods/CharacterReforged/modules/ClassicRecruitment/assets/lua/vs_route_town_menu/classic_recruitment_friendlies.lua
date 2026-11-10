if VRFW.host ~= nil then
  ClassicRecruitment = ClassicRecruitment or {}
  local B = {
    STEM = "vs_route_town_menu",
    ZONE = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_ZONE,
    GET = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_GET,
    ARM = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_ARM,               -- CMND_CLASSICRECRUITMENT_FRIENDLY_ARM (key)
    RESULT = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_RESULT,            -- CMND_CLASSICRECRUITMENT_FRIENDLY_RESULT () -> key, won
    SET_WON = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_SET_WON,           -- CMND_CLASSICRECRUITMENT_FRIENDLY_SET_WON (key)
    FRIENDLY = "classic_recruitment_friendly",
    FRIENDLY_TEAM = "classic_recruitment_friendly_active_team",
    K_NO_TEAM = 2169483940,
    GAME = 2372839589,
    MENU = "ClassicRecruitment.friendlies",   -- the pose row (content\pose_rows\friendlies.toml)
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
    BASE = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_BASE,
    LEVEL = VRFW.commands.CLASSICRECRUITMENT_FRIENDLY_LEVEL,
    TEAM_LEVEL = VRFW.commands.VRFW_TEAM_LEVEL,
    BOARD = 364708540,              -- vs_route_town_menu (the host the team dock opens over)
    TEAM_KIND = 4081600465,
    FIVE = 1,
    -- the board's caravan (the background layer's menu model, slot 0) hidden while the list is up
    MODELS = {{1021315501 --[[vsroute00_00_background]], 0}},
  }
  ClassicRecruitment.friendly_board = B

  function B.log(...)
    VRFW.host.command(VRFW.commands.VRFW_LOG, "ClassicRecruitment friendlies", ...)
  end

  function B.zone(node)
    local zi, title, stadium, n, music = VRFW.host.command(B.ZONE, node)
    if type(zi) ~= "number" then return nil end
    local zone = {index = zi, node = node, title = title or 0, stadium = stadium or 0, music = music or 0, list = {}}
    for i = 1, n or 0 do
      local r = table.pack(VRFW.host.command(B.GET, zi, i))
      if r[1] ~= nil then
        zone.list[#zone.list + 1] = {key = r[1], team = r[2], name = r[3], level = r[4], format = r[5],
                                     won = r[6] == true, cards = {table.unpack(r, 8, 7 + (r[7] or 0))}}
      end
    end
    return zone
  end

  function B.play(zone, p)
    if VRFW.match_start == nil or VRFW.match_start.start == nil then return false, "no match start service" end
    -- the rival plays at the friendly's level on B.GAME difficulty 1
    local lv = VRFW.host.command(B.LEVEL, p.key)
    if type(lv) == "number" then
      local okl, whyl = VRFW.host.command(B.TEAM_LEVEL, p.team, B.GAME, 1, lv)
      B.log("level", p.key, lv, tostring(okl), tostring(whyl))
    end
    if VRFW.host.command(B.ARM, p.key) ~= true then return false, "unknown friendly" end
    B.log("play", p.key, "team", p.team, "stadium", zone.stadium, "music", zone.music)
    local overrides = {{"teams.rival.team", p.team}}
    if zone.music ~= 0 then overrides[#overrides + 1] = {"music.set", zone.music} end
    return VRFW.match_start.start{
      friendly = B.FRIENDLY, game = B.GAME, difficulty = 1, set = B.team_set,
      stadium = (zone.stadium ~= 0) and zone.stadium or nil, rival = p.team,
      overrides = overrides, play_mode = 1, black = false,
      on_failed = function(why)
        B.log("start failed", p.key, tostring(why))
        B.explain(why)
      end,
    }
  end

  function B.team_set()
    return VRFW.match_start.pachanga_team(B.FRIENDLY_TEAM)
  end

  function B.team_dock()
    local E = VRFW.team_editor
    if E == nil or type(E.run) ~= "function" then
      B.log("team dock: no team editor service")
      return false
    end
    VRFW.host.menu_command(VRFW.commands.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE, false)
    VRFW.host.menu_command(1524491681, 10)
    VRFW.param.clear(B.TEAM_KIND)
    VRFW.param.set(B.TEAM_KIND, B.FIVE)
    local hidden = VRFW.pose_row.hide_layers(B.HIDE)
    local kept = VRFW.pose_row.caller_models(B.MODELS, false)
    local ok, res, why = pcall(E.run, {owner = "ClassicRecruitment", host = B.BOARD, own = true})
    VRFW.pose_row.caller_models(B.MODELS, true, kept)
    VRFW.pose_row.show_layers(hidden)
    VRFW.host.menu_command(VRFW.commands.SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE, false)
    if not ok or type(res) ~= "table" then
      VRFW.param.clear(B.TEAM_KIND)
      B.log("team dock", "not opened", tostring(ok and why or res))
      return false
    end
    B.log("team dock", "closed")
    return true
  end

  function B.explain(why)
    if tonumber(why) ~= 4 then
      return
    end
    local t = VRFW.host.command(VRFW.commands.TEXT_GET, B.K_NO_TEAM)
    if type(t) ~= "string" or t == "" or VRFW.question.notice == nil or coroutine.running() == nil then
      return
    end
    pcall(VRFW.question.notice, t)
  end

  VRFW.host.on(B.STEM, "OnInit", {
    id = "ClassicRecruitment.friendly_result", phase = "after",
    fn = function()
      local key, won = VRFW.host.command(B.RESULT)
      if key == nil then return end
      B.log("result", key, won == true and "won" or "not won")
      if won == true then VRFW.host.command(B.SET_WON, key) end
    end,
  })
end

ClassicRecruitment = ClassicRecruitment or {}

ClassicRecruitment.friendly_menu = ClassicRecruitment.friendly_menu or {}
function ClassicRecruitment.friendly_menu.open(zone)
  local B = ClassicRecruitment.friendly_board
  if VRFW.pose_row == nil or #zone.list == 0 then
    return false
  end
  -- the levels scale with the player's active team (zone_rules.toml [level])
  if VRFW.recruit ~= nil and VRFW.recruit.team_level ~= nil then
    VRFW.host.command(B.BASE, VRFW.recruit.team_level())
  end
  local pick, focus
  while true do
    pick, focus = VRFW.pose_row.open(B.MENU, zone.index, {hide = B.HIDE, models = B.MODELS, focus = focus})
    if pick == nil then
      return false                   -- never shown: the piece's command menu opens as usual
    end
    if pick ~= -1 then
      break
    end
    B.team_dock()
  end
  local p = zone.list[pick]
  if p ~= nil then
    local ok, why = B.play(zone, p)
    if ok ~= true then
      B.log("play", p.key, "refused", tostring(why))
      B.explain(why)
    end
  end
  return true
end

function ClassicRecruitment.friendly_node(idx, node, key)
  local B = ClassicRecruitment.friendly_board
  if B == nil then
    return false
  end
  local zone = B.zone(node)
  if zone == nil then
    B.log("node", node, "has no zone")
    return false
  end
  return ClassicRecruitment.friendly_menu.open(zone) == true
end
