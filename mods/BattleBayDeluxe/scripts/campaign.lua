
local U = require "lib/util"
local G = require "lib/game"
local Draft = require "draft"
local Tourn = require "tournament"
local Active = require "active_team"
local Net = require "net_match"
-- The kit diagnostic log runs only when config.toml [debug] kit_log is true.
if U.config("debug.kit_log", false) == true then
  require "kit_diag"
end
require "campaign_fields"
-- the "Daily challenge" (its commands, its blob, its match handlers)
require "daily_challenge"
local Block = require "lib/campaign_block"
local Trophy = require "lib/trophy_celebration"

local CAMPAIGN_LAST = nil

VRFW.on("match:start", function()
  CAMPAIGN_LAST = nil
  local b = Block.read()
  if b and (b.rivals[1] or 0) ~= 0 and b.index == Block.RIVALS - 1 then
    CAMPAIGN_LAST = { rival = VRFW.ids.unsigned(b.rivals[Block.RIVALS] or 0) }
  end
  return nil
end)

VRFW.on("script:signal:vrfw.match_result", function()
  local c = CAMPAIGN_LAST
  CAMPAIGN_LAST = nil
  if not c then
    return nil
  end
  local rival = Trophy.rival_team()
  if rival == 0 or rival ~= c.rival then
    VRFW.log(string.format("campaign: match with the block at its last match, rival %s, not the block's last rival %s: " ..
      "not the Campaña's match", VRFW.ids.hex_text(rival), VRFW.ids.hex_text(c.rival)))
    return nil
  end
  Trophy.play("campaign", Trophy.last_result())
  return nil
end)
Tourn.on_started = function(run)
  if run.player_team == Draft.team() then
    Draft.campaign_started()
  end
end
Draft.tournament_team = Tourn.player_team
-- the league's top scorers draw the simulated goals among a team's starters (its member rows in memory)
Tourn.roster = Draft.roster
Tourn.before_match = function(run)
  local team = Draft.team()
  if team ~= 0 and run.player_team == team then
    Draft.before_run_match("Torneo match")
  end
end

local floor = math.floor

local CFG = {
  seed = tonumber(U.config("campaign.seed", 0)) or 0,
}

local info, warn, err = VRFW.logger("campaign")

info(string.format("rivals from the whole enjoy table (seed %s)", tostring(CFG.seed)))
if not VRFW.is_on("EvalCondition") then
  warn("unlock-condition evaluator not resolved: conditioned rows off the grid are never campaign rivals")
end

local function candidates(rows, grid, player)
  local on_grid = {}
  for _, g in ipairs(grid) do
    if on_grid[g.team] == nil then
      on_grid[g.team] = g.unlocked
    end
  end
  local out, locked, seen = {}, 0, {}
  for _, r in ipairs(rows) do
    if r.team ~= 0 and r.team ~= player and not seen[r.team] then
      seen[r.team] = true
      local unlocked = on_grid[r.team]
      if unlocked == nil then
        unlocked = r.lock == "free" or r.lock == "cond_true"
      end
      if unlocked then
        out[#out + 1] = r.team
      else
        locked = locked + 1
      end
    end
  end
  return out, locked
end

local function draw(cands, n, rng)
  local m = #cands
  if m == 0 or n == 0 then
    return {}
  end
  local v = {}
  for i, c in ipairs(cands) do
    v[i] = c
  end
  rng:shuffle(v)
  local out = {}
  for k = 0, n - 1 do
    out[#out + 1] = v[k % m + 1]
  end
  return out
end

local CAMPAIGNS = 0
local PREP = nil

local function slot_struct(menu, i)
  return VRFW.memory.struct("GridSlot", G.slot_addr(menu, i))
end

local DRAFT_MODES = {}
do
  local m = U.config("draft.modes", { "campaign", "free_match" })
  if type(m) ~= "table" then
    m = { m }
  end
  for _, v in ipairs(m) do
    DRAFT_MODES[VRFW.strings.trim(tostring(v))] = true
  end
end
local FREE = nil
local FREE_MENU = nil

local function network_session()
  if not VRFW.is_on("Net.IsSession") then
    return nil
  end
  local ok, v = U.call("Net.IsSession")
  if not ok then
    return nil
  end
  return U.truthy(v)
end

local function draft_gate(menu, btn, idx)
  local team = Draft.team()
  if team == 0 or idx >= G.SLOTS or VRFW.memory.read("u32", btn) ~= G.GRID_LAYER then
    return nil
  end
  if U.get(VRFW.memory.struct("GridMenu", menu), "campaign") ~= 0 or U.get(slot_struct(menu, idx), "team") ~= team then
    return nil
  end
  local why = nil
  if not DRAFT_MODES.free_match then
    why = "config.toml [draft] modes has no \"free_match\""
  else
    local net = network_session()
    if net == nil then
      why = "the network check (IsNetworkSession) is off"
    elseif net then
      why = "network session"
    end
  end
  if why then
    VRFW.log("draft: the Draft tile (slot " .. idx .. ") outside the Campaña refused (" .. why .. ")")
    return "refuse"
  end
  if Draft.ready_to_play() then
    VRFW.log("draft: free match: the Draft tile (slot " .. idx .. ") decided with the drafted squad")
    return "pass"
  end
  return "open"
end

local function active_gate(menu, btn, idx)
  if idx >= G.SLOTS or VRFW.memory.read("u32", btn) ~= G.GRID_LAYER then
    return nil
  end
  if not Active.is_tile(U.get(slot_struct(menu, idx), "team") or 0) then
    return nil
  end
  local m = VRFW.memory.struct("GridMenu", menu)
  local campaign = (U.get(m, "campaign") or 0) ~= 0
  local player_one_decided = (U.get(m, "player_one_decided") or 0) ~= 0
  local why = Active.refusal(campaign, player_one_decided, network_session())
  if why then
    VRFW.log("active team: the Active team tile (slot " .. idx .. ") refused (" .. why .. ")")
    return "refuse"
  end
  return nil
end

local function free_back(why)
  local f = FREE
  FREE = nil
  if f then
    local ok = pcall(function()
      VRFW.memory.struct("GridMenu", f.menu).campaign = f.was
    end)
    if not ok then
      warn("free match: the grid's campaign flag NOT put back (" .. why .. ")")
    end
  end
end

function BattleBayDeluxe.DraftDecide(slot)
  slot = U.int(slot, -1)
  local f = FREE_MENU
  FREE_MENU = nil
  if not f or (slot >= 0 and slot ~= f.slot) then
    warn("free match: no Draft screen to decide (slot " .. tostring(slot) .. ")")
    return false
  end
  local menu = f.menu
  local team = Draft.team()
  if team == 0 or not Draft.ready_to_play() then
    warn("free match: the draft is not complete: nothing decided")
    return false
  end
  local m = VRFW.memory.struct("GridMenu", menu)
  if not m or U.get(m, "campaign") ~= 0 or U.get(slot_struct(menu, f.slot), "team") ~= team then
    warn("free match: the grid changed (slot " .. f.slot .. " no longer the Draft tile): nothing decided")
    return false
  end
  local lb = VRFW.memory.buffer("bbd_layer_decide", 4)
  local okb = lb ~= nil
  if not okb or not VRFW.memory.write("u32", lb, G.GRID_LAYER) then
    return false
  end
  local ok, e = U.call("GameDecide", menu, lb, f.slot)
  if not ok then
    warn("free match: the retail decide failed: " .. tostring(e))
    return false
  end
  VRFW.log("draft: free match: the drafted Draft team decided (slot " .. f.slot .. ")")
  return true
end

local function restore_grid(p)
  for i, g in ipairs(p.grid) do
    local s = slot_struct(p.menu, i - 1)
    if s then
      pcall(function()
        s.team = g.team
        s.unlocked = g.raw
      end)
    end
  end
end

local function prepare(menu, btn)
  if VRFW.memory.read("u32", btn) ~= G.BTN_CAMPAIGN_START then
    return nil
  end
  local m = VRFW.memory.struct("GridMenu", menu)
  local camp = U.get(m, "campaign")
  if not camp or camp == 0 then
    return nil
  end
  local lb = VRFW.memory.buffer("bbd_layer", 4)
  local okb = lb ~= nil
  if not okb or not VRFW.memory.write("u32", lb, G.GRID_LAYER) then
    warn("layer buffer not writable: game campaign draw (visible page only)")
    return nil
  end
  local okc, child = U.call("FindChildByHash", menu, lb, 0)
  if not okc then
    warn("grid layer not found: game campaign draw (visible page only)")
    return nil
  end
  local cursor = U.get(VRFW.memory.struct("GridChild", child), "cursor")
  if not cursor then
    warn("cursor slot not readable: game campaign draw (visible page only)")
    return nil
  end
  if cursor < 0 or cursor >= G.SLOTS then
    warn("cursor slot " .. cursor .. " out of range: game campaign draw")
    return nil
  end
  local grid = {}
  for i = 0, G.SLOTS - 1 do
    local s = slot_struct(menu, i)
    local team, un = U.get(s, "team"), U.get(s, "unlocked")
    if team == nil or un == nil then
      warn("grid slot " .. i .. " not readable (slot base " .. tostring(G.slot_base()) .. "): game campaign draw "
        .. "(visible page only)")
      return nil
    end
    grid[i + 1] = { team = team, raw = un }
  end
  local player = Tourn.picked_player() or grid[cursor + 1].team
  if player == 0 then
    warn("cursor slot " .. cursor .. " holds no team: game campaign draw (visible page only)")
    return nil
  end
  local page_pool = 0
  for _, x in ipairs(grid) do
    if x.team ~= 0 and x.team ~= player and x.raw ~= 0 then
      page_pool = page_pool + 1
    end
  end
  local raw = G.enjoy_rows()
  if not raw then
    warn("enjoy table not readable: game campaign draw")
    return nil
  end
  if Active.team() ~= 0 then
    local keep = {}
    for _, r in ipairs(raw) do
      if not Active.is_tile(r.team) then
        keep[#keep + 1] = r
      end
    end
    raw = keep
    if Active.is_tile(player) then
      info("the campaign plays the player's active team (the Active team tile)")
    end
  end
  local draft_team = Draft.team()
  if draft_team ~= 0 then
    local keep = {}
    for _, r in ipairs(raw) do
      if r.team ~= draft_team then
        keep[#keep + 1] = r
      end
    end
    raw = keep
    if player == draft_team then
      if not Draft.ready_to_play() then
        VRFW.warn("draft: campaign started with the Draft team but no complete draft: it plays the placeholders")
      end
      Draft.before_campaign()
    end
  end
  local rule, nrule = {}, 0
  local function rule_check(t)
    if t ~= 0 and rule[t] == nil then
      local r = G.unlock_rule(t)
      rule[t] = r ~= nil and r >= 0
      if rule[t] then
        nrule = nrule + 1
      end
    end
  end
  for _, r in ipairs(raw) do
    rule_check(r.team)
  end
  for _, g in ipairs(grid) do
    rule_check(g.team)
  end
  local free_rows = 0
  for _, r in ipairs(raw) do
    if r.cond == 0 or rule[r.team] then
      free_rows = free_rows + 1
    end
  end
  local layout_ok = free_rows > 0 and (#raw - free_rows) * 2 <= #raw
  if not layout_ok then
    warn(string.format("%d of %d rows without unlock condition (layout?): rows outside the grid taken as unlocked",
      free_rows, #raw))
  end
  local eval_on = VRFW.is_on("EvalCondition")
  local rows, cond_open, cond_shut = {}, 0, 0
  for _, r in ipairs(raw) do
    local lock
    if r.cond == 0 or not layout_ok or rule[r.team] then
      lock = "free"
    elseif not eval_on then
      lock = "unknown"
    else
      local v = G.eval(r.cond)
      if v == nil then
        lock = "unknown"
      elseif v then
        lock = "cond_true"
      else
        lock = "cond_false"
      end
    end
    if lock == "cond_true" then
      cond_open = cond_open + 1
    elseif lock == "cond_false" or lock == "unknown" then
      cond_shut = cond_shut + 1
    end
    rows[#rows + 1] = { team = r.team, lock = lock }
  end
  local g = {}
  for i, x in ipairs(grid) do
    g[i] = { team = x.team, unlocked = x.raw ~= 0 or rule[x.team] == true }
  end
  local pool, locked = candidates(rows, g, player)
  -- the player's team in another version (another row with the same team name text) is never a rival either
  local player_name = Tourn.name_text(player)
  local variants = 0
  if player_name ~= 0 then
    local keep = {}
    for _, t in ipairs(pool) do
      if Tourn.name_text(t) == player_name then
        variants = variants + 1
      else
        keep[#keep + 1] = t
      end
    end
    pool = keep
  end
  Tourn.note_pool(#pool, pool, player)
  if #pool == 0 then
    warn("no unlocked team besides the player's in " .. #rows .. " rows: game campaign draw")
    return nil
  end
  local n = CAMPAIGNS
  CAMPAIGNS = CAMPAIGNS + 1
  local h, l
  if CFG.seed ~= 0 then
    h, l = U.split64(CFG.seed)
    l = bit32.bxor(l, player)
  else
    h, l = U.entropy(menu, n)
    l = bit32.bxor(l, player)
  end
  if Tourn.armed() then
    local trun, why = Tourn.begin(pool, player, h, l)
    if not trun then
      warn("tournament not started (" .. tostring(why) .. "): the start refused")
      Tourn.fail(why)
    else
      Tourn.pend(trun)
    end
    return { tournament_pending = true, menu = menu }
  end
  local rivals = draw(pool, G.RIVALS, U.rng(h, l))
  if #rivals ~= G.RIVALS then
    return nil
  end
  if #pool < G.RIVALS then
    warn("only " .. #pool .. " candidate(s): the 7 matches repeat rivals")
  end
  local p = { menu = menu, grid = grid, rivals = rivals, player = player, seed = VRFW.ids.hex_text(h) .. ":" .. VRFW.ids.hex_text(l),
    pool = #pool }
  local carrier = cursor == 0 and 1 or 0
  for i = 0, G.SLOTS - 1 do
    if i ~= cursor then
      local s = slot_struct(menu, i)
      if s then
        pcall(function()
          if i == carrier then
            s.team = rivals[1]
            s.unlocked = 1
          else
            s.unlocked = 0
          end
        end)
      end
    end
  end
  info(string.format("start, player %s (slot %d), pool %d teams from every page (%d enjoy rows; the visible page alone "
    .. "gives %d; %d version(s) of the player's team left out; %d locked; rows without condition %d (%d of the unlock "
    .. "rule: CPU rivals), conditioned unlocked %d / locked %d), seed %s", VRFW.ids.hex_text(player), cursor, #pool, #rows,
    page_pool, variants, locked, free_rows, nrule, cond_open, cond_shut, p.seed))
  return p
end

local function check_team(team)
  if team == 0 then
    return nil, "team hash 0 (empty pool slot)"
  end
  local rows, why = G.enjoy_rows()
  if not rows then
    return nil, why
  end
  local idx, row
  for i, r in ipairs(rows) do
    if r.team == team then
      idx, row = i - 1, r.addr
      break
    end
  end
  if not row then
    return nil, "enjoy row: none of the " .. #rows .. " enjoy_mode_team_config rows names it"
  end
  local er = VRFW.memory.struct("EnjoyRow", row)
  local leader = U.get(er, "leader") or 0
  local stadium = U.get(er, "stadium") or 0
  local bgm = U.get(er, "bgm") or 0
  local members, merr = Draft.roster(team)
  if not members then
    return nil, "team_config record: " .. tostring(merr)
  end
  local players, member = 0, false
  for _, m in ipairs(members) do
    if m[1] < 19 then
      players = players + 1
    end
    if m[2] == leader then
      member = true
    end
  end
  if players < 11 then
    return nil, string.format("team_config record: %d players (slots 0-18) of %d rows, 11 needed", players, #members)
  end
  if leader == 0 or not member then
    return nil, string.format("enjoy row %d: leader %s is not one of its %d member rows", idx, VRFW.ids.hex_text(leader), #members)
  end
  if stadium == 0 then
    return nil, string.format("enjoy row %d: no stadium (col 4)", idx)
  end
  return string.format("row %d, %d members, leader %s member, stadium %s, bgm %s", idx, #members, VRFW.ids.hex_text(leader),
    VRFW.ids.hex_text(stadium), VRFW.ids.hex_text(bgm))
end

local function check_match(sess, player, rival)
  local s = VRFW.memory.struct("Session", sess)
  local game = U.get(s, "game") or 0
  local diff = U.get(s, "difficulty") or 0
  local idx = U.get(s, "match") or 0xFF
  local bad, parts = {}, {}
  for _, e in ipairs({ { "player", player }, { "rival 1", rival } }) do
    local d, why = check_team(e[2])
    if d then
      parts[#parts + 1] = e[1] .. " " .. VRFW.ids.hex_text(e[2]) .. " [" .. d .. "]"
    else
      err(string.format("match %d check FAILED: %s team %s: %s", idx + 1, e[1], VRFW.ids.hex_text(e[2]), tostring(why)))
      bad[#bad + 1] = e[1]
      parts[#parts + 1] = e[1] .. " " .. VRFW.ids.hex_text(e[2]) .. " [FAILED]"
    end
  end
  info(string.format("match %d request: game %s, difficulty %d, map = rival stadium; %s%s", idx + 1, VRFW.ids.hex_text(game), diff,
    table.concat(parts, " vs "), #bad == 0 and "" or " (" .. table.concat(bad, " + ") .. " failed: the load may never finish)"))
end

local function finish(p)
  restore_grid(p)
  local sess = VRFW.game.global("session")
  if not sess then
    warn("session block not readable: rivals 2-7 left as the game wrote them")
    return
  end
  local got = {}
  for k = 0, G.RIVALS - 1 do
    local v = VRFW.memory.read("u32", sess + G.S_RIVALS + 4 * k)
    if v == nil then
      return
    end
    got[k + 1] = v
  end
  local player = U.get(VRFW.memory.struct("Session", sess), "player")
  if player == nil then
    return
  end
  local zero = true
  for k = 2, G.RIVALS do
    if got[k] ~= 0 then
      zero = false
    end
  end
  if player ~= p.player or got[1] ~= p.rivals[1] or not zero then
    local shown = {}
    for k, v in ipairs(got) do
      shown[k] = string.format("%08X", v)
    end
    info(string.format("not started by this decide (block player %s, rivals [%s]): nothing written", VRFW.ids.hex_text(player),
      table.concat(shown, ", ")))
    return
  end
  for k = 2, G.RIVALS do
    VRFW.memory.write("u32", sess + G.S_RIVALS + 4 * (k - 1), p.rivals[k])
  end
  if p.player == Draft.team() then
    Draft.campaign_started()
    VRFW.log(string.format("draft: match 1 requested (player %s vs %s): the campaign scene loads next", VRFW.ids.hex_text(p.player),
      VRFW.ids.hex_text(p.rivals[1])))
  end
  local desc = {}
  for k, t in ipairs(p.rivals) do
    desc[k] = VRFW.ids.hex_text(t)
  end
  info(string.format("rivals (seed %s, %d candidates): %s", p.seed, p.pool, table.concat(desc, ", ")))
  check_match(sess, p.player, p.rivals[1])
end

local CAMPAIGN_GRID = nil

local function decide_pre(menu, btn, idx)
  local okn, net = pcall(Net.decide, menu, btn, idx)
  if not okn then
    warn("room pick check failed: " .. tostring(net))
  elseif net then
    return net
  end
  pcall(function()
    if VRFW.memory.read("u32", btn) == G.GRID_LAYER and (U.get(VRFW.memory.struct("GridMenu", menu), "campaign") or 0) ~= 0 then
      CAMPAIGN_GRID = menu
    end
  end)
  if PREP then
    if PREP.menu == menu then
      restore_grid(PREP)
    end
    PREP = nil
  end
  if FREE then
    free_back("a post-phase that never ran")
  end
  local oka, active = pcall(active_gate, menu, btn, idx)
  if not oka then
    warn("Active team tile check failed: " .. tostring(active))
  elseif active == "refuse" then
    return { skip = true, ret = 0 }
  end
  local ok, gate = pcall(draft_gate, menu, btn, idx)
  if not ok then
    warn("Draft tile check failed: " .. tostring(gate))
  elseif gate == "refuse" then
    return { skip = true, ret = 0 }
  elseif gate == "open" then
    local m = VRFW.memory.struct("GridMenu", menu)
    local was = U.get(m, "campaign")
    if was ~= nil and pcall(function()
      m.campaign = 1
    end) then
      FREE = { menu = menu, was = was }
      FREE_MENU = { menu = menu, slot = idx }
      VRFW.log("draft: free match: the Draft tile (slot " .. idx .. ") opens the Draft screen")
    else
      warn("free match: the grid's campaign flag not writable: the Draft tile refused")
      return { skip = true, ret = 0 }
    end
    return nil
  end
  local okp, p = pcall(prepare, menu, btn)
  if not okp then
    warn("pre-phase failed (" .. tostring(p) .. "): game campaign draw")
    return nil
  end
  if p and p.tournament_pending then
    PREP = nil
    return { skip = true, ret = 0 }
  end
  PREP = p
  return nil
end

-- the post-phase of a decide on `menu`
local function decide_post(menu)
  if FREE and FREE.menu == menu then
    free_back("post-phase")
  end
  local p = PREP
  PREP = nil
  if not p or p.menu ~= menu then
    return nil
  end
  local ok, e = pcall(finish, p)
  if not ok then
    warn("post-phase failed: " .. tostring(e))
    pcall(restore_grid, p)
  end
  return nil
end

VRFW.on("hook:Decide", function(ev)
  return decide_pre(ev.args[1], ev.args[2], ev.args[3])
end)

VRFW.on("hook:Decide:post", function(ev)
  return decide_post(ev.args[1])
end)

local DIFFICULTY_LEVELS = 4 -- the game's difficulty windows: 4 levels, index 0-3
local DIFFICULTY_STATES = {}
do
  local keys = U.config("difficulty.owner_states", {})
  if type(keys) ~= "table" then
    keys = { keys }
  end
  for _, k in ipairs(keys) do
    k = VRFW.strings.trim(tostring(k))
    if k ~= "" then
      DIFFICULTY_STATES[#DIFFICULTY_STATES + 1] = k
    end
  end
end
local difficulty_shown = nil
local difficulty_bad = {}

local function owned_difficulty()
  for _, key in ipairs(DIFFICULTY_STATES) do
    local ok, v = pcall(VRFW.state.get, key)
    v = ok and tonumber(v) or nil
    if v ~= nil then
      v = floor(v)
      if v >= 0 and v < DIFFICULTY_LEVELS then
        return v, key
      end
      if not difficulty_bad[key] then
        difficulty_bad[key] = true
        warn(string.format("difficulty: game_state %s = %d is not a difficulty index (0-%d): ignored", key, v,
          DIFFICULTY_LEVELS - 1))
      end
    end
  end
  return nil
end

-- CMND_BATTLEBAYDELUXE_DIFFICULTY_OWNED -> the owned difficulty index, -1 = none (logged when it changes)
function BattleBayDeluxe.OwnedDifficulty()
  local ok, idx, key = pcall(owned_difficulty)
  if not ok then
    warn("difficulty: owner check failed: " .. tostring(idx))
    return -1
  end
  local shown = idx and (key .. "=" .. idx) or "none"
  if shown ~= difficulty_shown then
    difficulty_shown = shown
    if idx then
      info(string.format("difficulty: owned (game_state %s): index %d of 0-%d for every Battle Bay match, no "
        .. "difficulty asked", key, idx, DIFFICULTY_LEVELS - 1))
    else
      info("difficulty: no mod owns it (config.toml [difficulty] owner_states): the player picks it")
    end
  end
  return idx or -1
end

local function start_without_difficulty()
  local idx = owned_difficulty()
  if idx == nil then
    warn("difficulty start: no mod owns the difficulty: nothing started")
    return false
  end
  local menu = CAMPAIGN_GRID
  CAMPAIGN_GRID = nil
  if not menu or (U.get(VRFW.memory.struct("GridMenu", menu), "campaign") or 0) == 0 then
    warn("difficulty start: no Campaña grid decided: nothing started")
    return false
  end
  local lb = VRFW.memory.buffer("bbd_layer_start", 4)
  local okb = lb ~= nil
  if not okb or not VRFW.memory.write("u32", lb, G.BTN_CAMPAIGN_START) then
    warn("difficulty start: layer buffer not writable: nothing started")
    return false
  end
  local r = decide_pre(menu, lb, 0)
  if type(r) == "table" and r.skip then
    info("difficulty start: the game's start not run (the Torneo draws its run): difficulty index " .. idx)
    return true
  end
  local ok, e = U.call("GameDecide", menu, lb, 0)
  decide_post(menu)
  if not ok then
    warn("difficulty start: the game's start failed: " .. tostring(e))
    return false
  end
  info("difficulty start: the Campaña started without the difficulty window, difficulty index " .. idx)
  return true
end

-- CMND_BATTLEBAYDELUXE_DIFFICULTY_START -> true = started (or the Torneo's run drawn), false = nothing started
function BattleBayDeluxe.StartWithoutDifficulty()
  local ok, done = pcall(start_without_difficulty)
  if not ok then
    warn("difficulty start failed: " .. tostring(done))
    return false
  end
  return done == true
end

-- the slot document that keeps the template each picked Personal Teams tile plays ("team:template,...")
local RUN_DOC = "campaign.personal_run"

-- The document as team -> template.
local function tile_templates(slot)
  local map, n = {}, 0
  for team, template in tostring(VRFW.save.doc.read_text(RUN_DOC, slot) or ""):gmatch("(%d+):(%d+)") do
    map[tonumber(team)] = tonumber(template)
    n = n + 1
  end
  return map, n
end

-- The Personal Teams tile a saved Campaña or a running Torneo plays; 0 when none.
local function run_tile()
  local b = Block.read()
  if Block.alive(b) and not Block.lent() and Active.is_tile(b.player) and b.player ~= Active.team() then
    return b.player
  end
  local t = Tourn.player_team() or 0
  if Active.is_tile(t) and t ~= Active.team() then
    return t
  end
  return 0
end

-- CMND_BATTLEBAYDELUXE_TILE_RUN -> team, template the saved run plays; nil when no run plays a Personal Teams tile
function BattleBayDeluxe.TileRun()
  local slot = VRFW.save.doc.slot()
  local team = run_tile()
  local map, n = tile_templates(slot)
  local template = map[team]
  -- only the saved run's tile stays in the document: the other picks were single matches
  -- no saved run plays a tile: the document is set aside, an empty one would lose data
  if template == nil and n > 0 then
    local ok, why = VRFW.save.doc.set_aside(RUN_DOC, slot)
    if not ok then
      warn("personal run: tile templates no saved run plays not set aside (" .. tostring(why) .. ")")
    end
    info("personal run: " .. n .. " tile template(s) no saved run plays dropped")
  elseif template ~= nil and n > 1 then
    VRFW.save.doc.write_text(RUN_DOC, string.format("%.0f:%d", team, template), slot)
    info("personal run: " .. (n - 1) .. " tile template(s) no saved run plays dropped")
  end
  if template == nil then
    return nil
  end
  return team, template
end

-- CMND_BATTLEBAYDELUXE_TILE_PLAYS (team, team set, template) -> true: the tile's matches play that team set
function BattleBayDeluxe.TilePlays(team, set, template)
  team, set, template = VRFW.ids.unsigned(tonumber(team) or 0) or 0, U.int(set, -1), U.int(template, 0)
  if not Active.is_tile(team) or team == Active.team() or set < 0 or template < 1 then
    return false
  end
  if not pcall(VRFW.native.table_set, "BattleBayDeluxe.ActiveSet", team, set) then
    warn("personal tile " .. VRFW.ids.hex_text(team) .. ": team set " .. set .. " not written to the hook's table")
    return false
  end
  local slot = VRFW.save.doc.slot()
  local map, parts = tile_templates(slot), {}
  map[team] = template
  for tile, kept in pairs(map) do
    parts[#parts + 1] = string.format("%.0f:%d", tile, kept)
  end
  table.sort(parts)
  local ok, why = VRFW.save.doc.write_text(RUN_DOC, table.concat(parts, ","), slot)
  if not ok then
    warn("personal tile " .. VRFW.ids.hex_text(team) .. ": template " .. template .. " not kept for the run (" .. tostring(why) .. ")")
  end
  info(string.format("personal tile %s plays template %d in team set %d", VRFW.ids.hex_text(team), template, set))
  return true
end

function BattleBayDeluxe.CampaignSync()
  local b = Block.read()
  local campaign = Block.alive(b) and not Block.lent()
  if campaign then
    local rows = G.enjoy_rows()
    if rows and not G.enjoy_row(b.player) then
      if Block.clear() then
        info(string.format("top menu sync: the saved Campaña of team %s ended (no Battle Bay team has that id)",
          VRFW.ids.hex_text(b.player)))
        campaign = false
      else
        warn("top menu sync: the saved Campaña of an unknown team " .. VRFW.ids.hex_text(b.player) .. " could not be ended")
      end
    end
    if campaign and Active.dock_ready(b.player) == false then
      if Block.clear() then
        info("top menu sync: the saved Campaña of team " .. VRFW.ids.hex_text(b.player) .. " ended (its dock has no 11 starters now)")
        campaign = false
      else
        warn("top menu sync: the saved Campaña of the emptied dock team " .. VRFW.ids.hex_text(b.player) .. " could not be ended")
      end
    end
  end
  local player = campaign and b.player or 0
  local phase, lost = Draft.sync(campaign, player)
  if lost then
    if campaign and player == Draft.team() then
      if Block.clear() then
        info("top menu sync: the saved Campaña with the Draft team ended (its drafted squad is not stored)")
      else
        warn("top menu sync: the saved Campaña with the Draft team could not be ended")
      end
    elseif Tourn.player_team() == Draft.team() then
      BattleBayDeluxe.TournamentAbandon()
      info("top menu sync: the running Torneo with the Draft team ended (its drafted squad is not stored)")
    end
  end
  return phase
end
