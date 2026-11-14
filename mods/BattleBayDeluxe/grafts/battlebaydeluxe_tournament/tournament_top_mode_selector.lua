-- Top menu part
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}


-- After a team grid this file did not open closes
BattleBayDeluxe.tournament_mode_go_tournament_param = @crc:battlebaydeluxe_mode_go_tournament@
function BattleBayDeluxe.tournament_mode_after_grid()
  local S = BattleBayDeluxe.tournament_state
  local exists = funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, @crc:enjoy_team_select_menu@) == true
  if exists then
    if not S.grid_seen then
      S.grid_seen = true
      S.grid_own = S.newrun == true
      S.grid_active = BattleBayDeluxe.tournament_info().active == true
    end
    return
  end
  if not S.grid_seen then
    return
  end
  S.grid_seen = false
  if S.grid_own then
    return
  end
  if VRFW.param.has(BattleBayDeluxe.tournament_mode_go_tournament_param) then
    VRFW.param.clear(BattleBayDeluxe.tournament_mode_go_tournament_param)
    S.after_grid, S.frames_after = "tournament", 0
    BattleBayDeluxe.tournament_log("grid closed: the tournament asked from its header")
    return
  end
  local info = BattleBayDeluxe.tournament_info()
  if info.active and not S.grid_active then
    S.after_grid, S.frames_after = "bracket", 0
    BattleBayDeluxe.tournament_log("grid closed: a tournament started in it, its bracket")
  elseif info.armed then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.DISARM)
    VRFW.host.command(BattleBayDeluxe.tournament.RULE_SELECT, "")
  end
end

-- Action waiting for the menu focus after a grid or a mode switch.
function BattleBayDeluxe.tournament_mode_after_step()
  local S = BattleBayDeluxe.tournament_state
  if S.after_grid == nil or S.co ~= nil or S.open or S.entry then
    return
  end
  S.frames_after = (S.frames_after or 0) + 1
  if S.frames_after > 600 then
    BattleBayDeluxe.tournament_log("mode: gave up waiting for the menu:", S.after_grid)
    S.after_grid = nil
    return
  end
  if S.frames_after < 6 or not BattleBayDeluxe.tournament_host.ready() or funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) == true
    or funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) == true then
    return
  end
  local what = S.after_grid
  S.after_grid = nil
  if what == "bracket" then
    if BattleBayDeluxe.tournament_info().fmt == 2 then
      S.co = coroutine.create(BattleBayDeluxe.tournament_league_hub)
    else
      BattleBayDeluxe.tournament_open(BattleBayDeluxe.tournament_entry_page())
    end
  elseif what == "tournament" or what == "campaign" then
    BattleBayDeluxe.tournament_decide_campaign_row(what)
  end
end

-- Step hook of this menu
function BattleBayDeluxe.tournament_mode_top_step()
  if BattleBayDeluxe.tournament_host.name ~= "bb_stadium_top_menu" then
    return
  end
  local S = BattleBayDeluxe.tournament_state
  BattleBayDeluxe.tournament_mode_after_grid()
  BattleBayDeluxe.tournament_mode_after_step()
  -- The selector layers live only in the grid menu
  BattleBayDeluxe.tournament_mode_poll(false)   -- keeps the key / click edges current
end

-- Diagnostics, once per opening TournamentSetupFrames Steps after OnInit
BattleBayDeluxe.tournament_setup_frames = 180
function BattleBayDeluxe.tournament_setup_check()
  if BattleBayDeluxe.tournament_host.name ~= "bb_stadium_top_menu" then
    return
  end
  local parts, short = {}, 0
  for k, n in pairs(BattleBayDeluxe.tournament.N) do
    local got = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, BattleBayDeluxe.tournament.L[k])
    got = type(got) == "number" and got or -1
    if got < n then
      short = short + 1
    end
    parts[#parts + 1] = string.format("%s %d/%d", k, got, n)
  end
  table.sort(parts)
  local bg = funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, @crc:mainmenu90_00_background@, 0)
  local covered = funcLuaCommand(2259183189) == true
  BattleBayDeluxe.tournament_log(string.format("top menu setup: %s; background open %s, covered %s (%s)", table.concat(parts, ", "),
    tostring(bg), tostring(covered), (short > 0 or covered) and "STUCK? pools short or screen covered" or "ok"))
end
