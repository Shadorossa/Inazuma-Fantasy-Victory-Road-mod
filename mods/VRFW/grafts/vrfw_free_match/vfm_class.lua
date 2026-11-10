-- VRFW free-match classes ----------------- The class menu lists the classes the opponent offers
VRFW.free_match_classes = VRFW.free_match_classes or {}
VRFW.free_match_classes.RULES = @crc:CMND_VRFW_FM_RULES@
VRFW.free_match_classes.DIFFS = @crc:CMND_VRFW_FM_DIFFICULTIES@
VRFW.free_match_classes.CLASS = @crc:CMND_VRFW_FM_CLASS@
VRFW.free_match_classes.ATLAS = 1103995203
VRFW.free_match_classes.BALLS = 3795985350
VRFW.free_match_classes.cache = nil
VRFW.free_match_classes.banners = VRFW.free_match_classes.banners or {}
VRFW.free_match_classes.game_banners = VRFW.free_match_classes.game_banners or {}
VRFW.free_match_classes.game_balls = VRFW.free_match_classes.game_balls or {}

function VRFW.free_match_classes.rules()
  if VRFW.free_match_classes.rules_cache == nil then
    local r = {VRFW.host.command(VRFW.free_match_classes.RULES)}
    if r[1] == true then
      VRFW.free_match_classes.rules_cache = {ticks = r[2] ~= false, together = r[5] == true}
    else
      VRFW.free_match_classes.rules_cache = {ticks = true, together = false}
    end
  end
  return VRFW.free_match_classes.rules_cache
end
function VRFW.free_match_classes.list(game)
  if VRFW.free_match_classes.cache == nil then
    local t = {}
    local r = {VRFW.host.command(VRFW.free_match_classes.DIFFS, game)}
    if r[1] == true and type(r[2]) == "number" then
      for i = 1, r[2] do
        if type(r[2 + i]) == "number" then
          t[#t + 1] = r[2 + i]
        end
      end
    end
    if #t == 0 then
      t = {6, 7, 8, 9}
    end
    VRFW.free_match_classes.cache = t
    VRFW.free_match_classes.game = game
  end
  return VRFW.free_match_classes.cache
end
-- class index 0..3 (row 6 + c) shown on menu row a2
function VRFW.free_match_classes.cls(game, a2)
  local l = VRFW.free_match_classes.list(game)
  local d = l[a2 + 1] or l[#l]
  return d - 6
end
-- Menu row a2 beyond the offered list.
function VRFW.free_match_classes.hidden(game, a2)
  return a2 >= #VRFW.free_match_classes.list(game)
end
function VRFW.free_match_classes.locked(game, story, c)
  if VRFW.free_match_classes.rules().together then
    return false
  end
  return VRFW.free_match_lock.retail_locked(game, story, c)
end
-- The art of class index c (0..3), read once.
function VRFW.free_match_classes.art(c)
  local b = VRFW.free_match_classes.banners[c]
  if type(b) ~= "table" or b.ball == nil then
    b = {banner = false, ball = false}
    local r = {VRFW.host.command(VRFW.free_match_classes.CLASS, c + 6)}
    if r[1] == true then
      if type(r[3]) == "number" and r[3] ~= 0 and type(r[4]) == "number" and r[4] ~= 0 then
        b.banner = {r[3], r[4]}
      end
      if type(r[5]) == "number" and r[5] ~= 0 and type(r[6]) == "number" and r[6] ~= 0 then
        b.ball = {r[5], r[6]}
      end
    end
    VRFW.free_match_classes.banners[c] = b
  end
  return b
end
-- The title of class index c (0..3) on game `game`, read once.
function VRFW.free_match_classes.game_banner(game, c)
  local per_game = VRFW.free_match_classes.game_banners[game]
  if per_game == nil then
    per_game = {}
    VRFW.free_match_classes.game_banners[game] = per_game
  end
  local b = per_game[c]
  if b == nil then
    b = false
    local r = {VRFW.host.command(VRFW.free_match_classes.CLASS, c + 6, game)}
    if r[1] == true and type(r[3]) == "number" and r[3] ~= 0 and type(r[4]) == "number" and r[4] ~= 0 then
      b = {r[3], r[4]}
    end
    per_game[c] = b
  end
  return b
end
-- The title of class index c (0..3) on game `game`.
function VRFW.free_match_classes.banner(c, retail, game)
  local b
  if game ~= nil then
    b = VRFW.free_match_classes.game_banner(game, c)
  else
    b = VRFW.free_match_classes.art(c).banner
  end
  if b then
    return b[1], b[2]
  end
  return VRFW.free_match_classes.ATLAS, retail
end
-- The level ball of class index c on game `game`, read once.
function VRFW.free_match_classes.game_ball(game, c)
  local per_game = VRFW.free_match_classes.game_balls[game]
  if per_game == nil then
    per_game = {}
    VRFW.free_match_classes.game_balls[game] = per_game
  end
  local b = per_game[c]
  if b == nil then
    b = false
    local r = {VRFW.host.command(VRFW.free_match_classes.CLASS, c + 6, game)}
    if r[1] == true and type(r[5]) == "number" and r[5] ~= 0 and type(r[6]) == "number" and r[6] ~= 0 then
      b = {r[5], r[6]}
    end
    per_game[c] = b
  end
  return b
end
-- The level ball of class index c on game `game`.
function VRFW.free_match_classes.ball(c, retail, game)
  local b = VRFW.free_match_classes.game_ball(game, c)
  if b then
    return b[1], b[2]
  end
  return VRFW.free_match_classes.BALLS, retail
end
-- the row's mark box (_list_state_base01) hidden without ClearTicks (the marks are never shown there)
function VRFW.free_match_classes.box(layer, a2)
  if not VRFW.free_match_classes.rules().ticks then
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, 1445391659 --[[_list_state_base01]], false, a2)
  end
end
-- The team of `game`'s row of difficulty d (0x836C9C28(game, d)).
function VRFW.free_match_classes.team(game, d, fallback)
  local has, team = VRFW.host.command(2204933160, game, d)
  if has and type(team) == "number" and team ~= 0 then
    return team
  end
  return fallback
end
-- the clear mark and the advantage-win mark of class c (none without ClearTicks)
function VRFW.free_match_classes.marks(game, c)
  if not VRFW.free_match_classes.rules().ticks then
    return false, false
  end
  return funcLuaCommand(@crc:CMND_GET_SOCCER_GAME_CLEAR_FLAG@, game, 6 + c), funcLuaCommand(479325357, game, 6 + c)
end
-- VRFW free-match classes end ------------------------------------------------------------------
