-- VRFW › rival players: applies the rule of VRFW/lib/rival_players (content\rival_players\*.toml of every active mod)
-- to the rival players of the match being requested, for that match only (docs/framework/types/rival-players.md).
--
-- When a match is requested (match:start_request, before its players are built):
--   * the rule: the match's game, difficulty and play mode (the request's match info) -> RP.rule;
--   * the rival team: the request's rival team id when it has one, else the team of the game's difficulty row
--     (soccer_game_info SOCCER_GAME_DIFFICULTY, read once per session: a free match names its rival there);
--   * the players: the rival team's member rows as they are now (team_config in memory, so a team stand-in counts),
--     roster slots 0..18;
--   * passives: a rule with [[archetype]]s: the archetype of each player (RP.choose, the same every time) gives his last
--     2 slots, his own special stays in the first slot and the passives of his position fill the rest. Else one passive
--     set of the rule drawn with VRFW.rng for this entry; each player gets `set_passives` of it (drawn) in his last slots
--     and the passives of his position in the first ones. A [[player]] with its own passives gets those. His position
--     is his place in the rival team's formation (the record's formation as it is now, roster slot = place); a player
--     without a place (the bench) uses his card's. A list's repeat fills another slot (the engine stacks them).
--     Native table VRFW.RivalPassiveSlot (card, slot) -> { id, open };
--   * stats: a [[player]]'s stats (absolute) -> VRFW.RivalStatSet, its points -> VRFW.RivalStatAdd (card, stat);
--   * training: when the rule has one, the players, the position each one plays (his formation place's, 0 on the bench)
--     and the match go out as flags and the signal vrfw.rival_players.training; Player Training answers the stat deltas
--     of each card as flags and the signal vrfw.rival_players.trained: the deltas are added to VRFW.RivalStatAdd, a stat
--     it drained to its floor is set to that value in VRFW.RivalStatSet (the match copy's own value can differ from the
--     card's, so the delta alone could stop above the floor).
-- The tables are read natively (content\game\rival_players.toml): the slot readers, the match-copy builders and the
-- «datos» stats (CMND_GET_CHARA_INFO 14..21) of the players without a saved owner. Everything is emptied at the match
-- end, at a game reset and by a request no rule holds for.
-- The views read what the match has: the player page's stats (0x4375DC93 14..20, the character status getter), CMND_VRFW_RIVAL_STAT
-- and CMND_GET_CHARA_INFO 14..21 the match copy the builders made (VRFW.native.match_copy_stats); the passive rows, the archetype icon and the build type the
-- slots above (RivalPlayers.PlateInfo / Status / Build). No second copy of a formula.

RivalPlayers = RivalPlayers or {}

local RP = require "VRFW/lib/rival_players"
local ME = require "VRFW/lib/match_equipment"
local Id = require "VRFW/lib/ids"
local Places = require "VRFW/lib/formation_places"
require "VRFW/lib/basics"
local info, warn = VRFW.logger("rival_players")

local T_SLOT, T_SET, T_ADD = "VRFW.RivalPassiveSlot", "VRFW.RivalStatSet", "VRFW.RivalStatAdd"
local REQUEST_RIVAL_TEAM = 0xA8       -- StartMatchRequest: the rival team id (as TeamLineup.MatchRequest reads it)
local MEMBER_STRIDE, MEMBER_CARD, MEMBER_SLOT = 0x54, 0x20, 0x47   -- team_config member row (scripts\team_lineup.lua)
local LAST_PLAYER_SLOT = 18            -- roster slots 19 / 20 are the staff
local FLAG = "vrfw.rival_players"

local u32 = Id.u32
local ENTRY = 0                        -- requests seen this session (a word of the draw)
local CUR = nil                        -- { rule, cards = { card, ... }, set, add = { [card] = { [i] = n } },
                                       --   stat_set = { [card] = { [i] = n } }, flagged = n }
local VIEW = {}                        -- [chara handle] = card | false, this match (the «datos» filter)

local function rd(ty, at)
  if type(at) ~= "number" or at < 0x10000 then return nil end
  local ok, v = pcall(VRFW.mem.read, ty, at)
  return (ok and type(v) == "number") and v or nil
end

-- [game id] = { [difficulty] = team id, first = team id of its first row } (read once per session)
local GAME_TEAMS = nil

local function game_teams()
  if GAME_TEAMS then return GAME_TEAMS end
  GAME_TEAMS = {}
  local ok, err = pcall(function()
    local key = VRFW.table.source("soccer/soccer_game_info")
    local cur, slices, diffs, order = nil, {}, {}, {}
    for _, e in ipairs(VRFW.table.entries(key, { "SOCCER_GAME_INFO", "SOCCER_GAME_INFO_REF_DIFFICULTY",
      "SOCCER_GAME_DIFFICULTY" }, true)) do
      if e.name == "SOCCER_GAME_INFO" then
        cur = u32(e[1])
        order[#order + 1] = cur
      elseif e.name == "SOCCER_GAME_INFO_REF_DIFFICULTY" then
        if cur then slices[cur] = { tonumber(e[1]) or 0, tonumber(e[2]) or 0 } end
      elseif e.name == "SOCCER_GAME_DIFFICULTY" then
        diffs[#diffs + 1] = { tonumber(e[1]) or 0, u32(e[2]), tonumber(e[3]) }
      end
    end
    for _, g in ipairs(order) do
      local sl, t = slices[g], { levels = {} }
      if sl then
        for k = sl[1] + 1, sl[1] + sl[2] do
          local d = diffs[k]
          if d and d[2] ~= 0 then
            if t[d[1]] == nil then t[d[1]], t.levels[d[1]] = d[2], d[3] end
            if t.first == nil then t.first = d[2] end
          end
        end
      end
      GAME_TEAMS[g] = t
    end
  end)
  if not ok then warn("soccer_game_info not readable (" .. tostring(err) .. "): the rival team comes only from the request") end
  return GAME_TEAMS
end

-- the rival team of the match: the request's own id, else the game's difficulty row (its first row as a fallback)
local function rival_team(request, game, diff)
  local id = u32(rd("u32", request + REQUEST_RIVAL_TEAM) or 0)
  if id ~= 0 then return id, "request" end
  local t = game_teams()[u32(game or 0)]
  if t then
    if t[diff] then return t[diff], "game row" end
    if t.first then return t.first, "game first row" end
  end
  return 0, "none"
end

-- the level of the class row of the match (its soccer_game_info SOCCER_GAME_DIFFICULTY row), nil when it has none
local function class_level(game, diff)
  local t = game_teams()[u32(game or 0)]
  local l = t and t.levels[diff]
  return (l and l > 0) and math.floor(l) or nil
end

-- the member rows of team `id` as the game has them now: { card, ... } in roster slot order (players only), nil,
-- { [card] = roster slot }, the record's formation
local function live_cards(id)
  if not VRFW.is_on("RandomTeamFind") then return nil, "FindTeamConfig not resolved" end
  local okb, recb = pcall(VRFW.mem.buffer, "rp_team_rec", 8)
  local okc, contb = pcall(VRFW.mem.buffer, "rp_team_cont", 8)
  local okh, hashb = pcall(VRFW.mem.buffer, "rp_team_hash", 4)
  if not (okb and okc and okh) then return nil, "no native buffer" end
  VRFW.mem.write("u64", recb, 0)
  VRFW.mem.write("u64", contb, 0)
  VRFW.mem.write("u32", hashb, id)
  if not pcall(VRFW.call, "RandomTeamFind", recb, contb, hashb) then return nil, "FindTeamConfig faulted" end
  local rec, cont = rd("ptr", recb) or 0, rd("ptr", contb) or 0
  if rec < 0x10000 or cont < 0x10000 then return nil, string.format("team 0x%08X not in team_config", id) end
  local okC, cv = pcall(VRFW.mem.read_struct, "RandomTeamConfig", cont)
  local okR, rv = pcall(VRFW.mem.read_struct, "RandomTeamRecord", rec)
  local base = okC and type(cv) == "table" and cv.Members or nil
  local first = okR and type(rv) == "table" and rv.First or nil
  local count = okR and type(rv) == "table" and rv.Count or nil
  if not base or base < 0x10000 or not first or not count or count == 0 or count > 64 then
    return nil, "member slice unreadable"
  end
  local by_slot = {}
  for k = 0, count - 1 do
    local a = base + ((first % 65536) + k) * MEMBER_STRIDE
    local slot, card = rd("u8", a + MEMBER_SLOT), rd("u32", a + MEMBER_CARD)
    if slot and card and card ~= 0 and slot <= LAST_PLAYER_SLOT and not by_slot[slot] then by_slot[slot] = u32(card) end
  end
  local out, slot_of = {}, {}
  for s = 0, LAST_PLAYER_SLOT do
    if by_slot[s] then
      out[#out + 1] = by_slot[s]
      slot_of[by_slot[s]] = s
    end
  end
  return out, nil, slot_of, rv.Formation
end

-- { [card] = position of his place in the formation } (players without a place are left out)
local function field_positions(slot_of, formation)
  local out = {}
  local classes = (formation and formation ~= 0) and Places.classes(u32(formation)) or nil
  if classes then
    for card, slot in pairs(slot_of) do out[card] = classes[slot] end
  end
  return out
end

local function clear_flags()
  if not CUR then return end
  for k = 1, CUR.flagged or 0 do
    local card = VRFW.flag(FLAG .. ".card." .. k)
    pcall(VRFW.clear_flag, FLAG .. ".card." .. k)
    pcall(VRFW.clear_flag, FLAG .. ".place." .. k)
    for i = 0, 8 do
      pcall(VRFW.clear_flag, string.format("%s.trained.%d.%d", FLAG, u32(card or 0), i))
      pcall(VRFW.clear_flag, string.format("%s.floor.%d.%d", FLAG, u32(card or 0), i))
    end
  end
  for _, k in ipairs({ "count", "game", "difficulty", "play_mode", "level" }) do pcall(VRFW.clear_flag, FLAG .. "." .. k) end
  for _, card in ipairs(CUR.cards or {}) do
    pcall(VRFW.clear_flag, string.format("%s.archetype.%d", FLAG, card))
    pcall(VRFW.clear_flag, string.format("%s.slots.%d", FLAG, card))
  end
  CUR.flagged = nil
end

local function clear()
  clear_flags()
  if CUR then
    for _, t in ipairs({ T_SLOT, T_SET, T_ADD }) do pcall(VRFW.native.table_clear, t) end
  end
  CUR, VIEW = nil, {}
end

-- [card] = the card's own special (chara_param col 61, the first own passive), read once from the served table
local SPECIALS = nil
local COL_SPECIAL = 61

local function special_of(card)
  if not SPECIALS then
    SPECIALS = {}
    local ok, rows = pcall(VRFW.table.raw, "data/common/gamedata/character/chara_param_*.cfg.bin", "CHARA_PARAM_INFO", { 1, COL_SPECIAL + 1 })
    if ok and type(rows) == "table" then
      for _, r in ipairs(rows) do
        local id, own = r[1], r[COL_SPECIAL + 1]
        if type(id) == "number" and type(own) == "number" and own ~= 0 then SPECIALS[u32(id)] = u32(own) end
      end
    else
      warn("chara_param not readable: the rival players' specials are not kept")
    end
  end
  return SPECIALS[card]
end

-- the position whose list fills a player's slots: his place in the formation, else his card's
local function position_of(card)
  return CUR.field[card] or RP.position(card)
end

-- the 5 slots of a card of a rule with archetypes, in slot order: his special, the passives of his position (a list's
-- repeats stay; what his special or archetype already holds is not added), the archetype's last
local function archetype_slots(card, rule, arch)
  local pos, out, used = RP.position(card), {}, {}
  local tail = (arch and arch.passives[pos]) or {}
  for k = 1, math.min(#tail, RP.SLOTS) do used[tail[k]] = true end
  local room = RP.SLOTS - math.min(#tail, RP.SLOTS)
  local special = rule.keep_special and special_of(card) or nil
  if special and not used[special] then
    out[1], used[special] = special, true
  end
  for _, id in ipairs((rule.positions and rule.positions[position_of(card)]) or {}) do
    if #out >= room then break end
    if not used[id] then out[#out + 1] = id end
  end
  for k = 1, math.min(#tail, RP.SLOTS) do out[#out + 1] = tail[k] end
  return out
end

-- the passives of one card: its own list, else the position passives first and the drawn set's last
local function passives_of(card, rule, set_ids, gen)
  local own = rule.players[card] and rule.players[card].passives
  if own then
    local out = {}
    for k = 1, math.min(#own, RP.SLOTS) do out[k] = own[k] end
    return out
  end
  local picks, used = {}, {}
  if set_ids and rule.set_count > 0 then
    local pool = {}
    for k, id in ipairs(set_ids) do pool[k] = id end
    gen:shuffle(pool)
    for k = 1, math.min(rule.set_count, #pool, RP.SLOTS) do
      picks[#picks + 1], used[pool[k]] = pool[k], true
    end
  end
  local out = {}
  local room = RP.SLOTS - #picks
  for _, id in ipairs((rule.positions and rule.positions[position_of(card)]) or {}) do
    if #out >= room then break end
    if not used[id] then out[#out + 1] = id end
  end
  for _, id in ipairs(picks) do out[#out + 1] = id end
  return out
end

local function write_stats()
  local set_rows, add_rows = {}, {}
  for card, m in pairs(CUR.stat_set) do
    for i, v in pairs(m) do set_rows[#set_rows + 1] = { { card, i }, v } end
  end
  for card, m in pairs(CUR.add) do
    for i, v in pairs(m) do
      if v ~= 0 then add_rows[#add_rows + 1] = { { card, i }, v } end
    end
  end
  local ok1, e1 = pcall(VRFW.native.table_replace, T_SET, nil, set_rows)
  local ok2, e2 = pcall(VRFW.native.table_replace, T_ADD, nil, add_rows)
  if not ok1 then warn(T_SET .. ": " .. tostring(e1)) end
  if not ok2 then warn(T_ADD .. ": " .. tostring(e2)) end
end

local function add_points(card, i, n)
  CUR.add[card] = CUR.add[card] or {}
  CUR.add[card][i] = (CUR.add[card][i] or 0) + n
end

-- the slot tables of the running rule. A rule with archetypes takes each player's from Player Training's answer; without
-- one (training off) they are chosen here from his position and element.
local function write_slots()
  local rule, slot_rows, lines = CUR.rule, {}, {}
  local fallback = nil
  if rule.archetypes and next(CUR.picks) == nil then
    local rows = {}
    for _, card in ipairs(CUR.cards) do rows[#rows + 1] = { card = card, pos = RP.position(card) } end
    fallback = RP.choose(rule, rows)
  end
  for _, card in ipairs(CUR.cards) do
    local own = rule.players[card] and rule.players[card].passives
    local arch = CUR.picks[card] or (fallback and fallback[card]) or nil
    local list
    if rule.archetypes and not own then
      list = archetype_slots(card, rule, arch)
    else
      list = passives_of(card, rule, CUR.set and CUR.set.ids, CUR.gen)
    end
    CUR.slots[card] = {}
    for k, id in ipairs(list) do
      slot_rows[#slot_rows + 1] = { { card, k - 1 }, { id = id, open = 1 } }
      CUR.slots[card][k - 1] = id
    end
    pcall(VRFW.set_flag, string.format("%s.slots.%d", FLAG, card), 1)
    local ids = {}
    for _, id in ipairs(list) do ids[#ids + 1] = string.format("0x%08X", id) end
    lines[#lines + 1] = string.format("0x%08X %s%s: passives [%s]", card, RP.POSITION_KEY[position_of(card)],
      arch and (" " .. arch.name) or "", table.concat(ids, ", "))
  end
  local ok, e = pcall(VRFW.native.table_replace, T_SLOT, nil, slot_rows)
  if not ok then warn(T_SLOT .. ": " .. tostring(e)) end
  if not CUR.flagged then pcall(VRFW.set_flag, FLAG .. ".count", #CUR.cards) end
  for _, l in ipairs(lines) do info(l) end
end

local function apply(request)
  local off = select(2, pcall(VRFW.game.field, "Match.StartRequestInfo"))
  local at = (type(off) == "number" and request and request >= 0x10000) and (request + off) or nil
  local game, diff, mode = ME.match_of(at)
  local rule = game and RP.rule(game, diff, mode, "rival") or nil
  clear()
  if not rule then return end
  local team, from = rival_team(request, game, diff)
  local cards, why, slot_of, formation = live_cards(team)
  if not cards or #cards == 0 then
    warn(string.format("rule %s/%s: the rival team 0x%08X (%s) of game 0x%08X gives no players (%s): nothing applied",
      rule.source, rule.name, team, from, u32(game), tostring(why or "no member rows")))
    return
  end
  ENTRY = ENTRY + 1
  local gen = VRFW.rng("VRFW.rival_players", { game, diff, ENTRY, VRFW.now() })
  local set = (#rule.sets > 0) and rule.sets[gen:below(#rule.sets) + 1] or nil
  CUR = { rule = rule, cards = cards, set = set, add = {}, stat_set = {}, slots = {}, picks = {}, gen = gen,
    field = field_positions(slot_of, formation) }
  for _, card in ipairs(cards) do
    local p = rule.players[card]
    if p and p.stats then CUR.stat_set[card] = p.stats end
    if p and p.points then
      for i, n in pairs(p.points) do add_points(card, i, n) end
    end
  end
  write_stats()
  local level = rule.training and (rule.training.level or class_level(game, diff)) or nil
  info(string.format("rule %s/%s applied: game 0x%08X, rival team 0x%08X (%s), %d rival player(s), passive set %s%s",
    rule.source, rule.name, u32(game), team, from, #cards,
    set and set.name or "none", level and (", training Lv " .. level) or ""))
  -- the training to the full: Player Training answers through flags (signal vrfw.rival_players.trained, in this call)
  if rule.training and level then
    for k, card in ipairs(cards) do
      pcall(VRFW.set_flag, FLAG .. ".card." .. k, card)
      pcall(VRFW.set_flag, FLAG .. ".place." .. k, CUR.field[card] or 0)
    end
    pcall(VRFW.set_flag, FLAG .. ".count", #cards)
    pcall(VRFW.set_flag, FLAG .. ".game", game)
    pcall(VRFW.set_flag, FLAG .. ".difficulty", diff)
    pcall(VRFW.set_flag, FLAG .. ".play_mode", mode or -1)
    pcall(VRFW.set_flag, FLAG .. ".level", level)
    CUR.flagged = #cards
    pcall(VRFW.signal, "vrfw.rival_players.training")
  elseif rule.training then
    warn(string.format("rule %s/%s: game 0x%08X has no class level for difficulty %d: no training", rule.source, rule.name, u32(game), diff))
  end
  write_slots()
end

-- a stat drained to its floor: its absolute value, on a copy of what the rule's own [[player]] row holds
local function set_floor(card, i, value)
  local m = {}
  for k, v in pairs(CUR.stat_set[card] or {}) do m[k] = v end
  m[i] = value
  CUR.stat_set[card] = m
end

-- Player Training's answer (stats 0..7): flag vrfw.rival_players.floor.<card>.<stat> = the stat's absolute floor, else
-- vrfw.rival_players.trained.<card>.<stat> added to the stat points
local function take_training()
  if not CUR or not CUR.flagged then return end
  local n = 0
  for _, card in ipairs(CUR.cards) do
    for i = 0, 7 do
      local at_floor = tonumber(VRFW.flag(string.format("%s.floor.%d.%d", FLAG, card, i)))
      local d = tonumber(VRFW.flag(string.format("%s.trained.%d.%d", FLAG, card, i))) or 0
      if at_floor and at_floor > 0 then   -- a missing flag reads 0; a floor is at least 1
        set_floor(card, i, at_floor)
        n = n + 1
      elseif d ~= 0 then
        add_points(card, i, d)
        n = n + 1
      end
    end
    local a = tonumber(VRFW.flag(string.format("%s.archetype.%d", FLAG, card)))
    if a and CUR.rule.archetypes then CUR.picks[card] = CUR.rule.archetypes[a] end
  end
  if CUR.trained then return end
  CUR.trained = true
  write_stats()
  info(string.format("rule %s/%s: training added to %d stat(s)", CUR.rule.source, CUR.rule.name, n))
end

-- the stats of the match copy of a player without a saved owner, nil when none was built (cached per handle, this match)
local COPY = {}

local function copy_of(hdl)
  local c = COPY[hdl]
  if c ~= nil then return c or nil end
  local okO, owner = pcall(VRFW.character.owner, hdl)
  if not okO or owner ~= nil then
    COPY[hdl] = false
    return nil
  end
  local ok, stats = pcall(VRFW.native.match_copy_stats, hdl)
  if ok and type(stats) == "table" then
    COPY[hdl] = stats
    return stats
  end
  return nil
end

-- CMND_VRFW_RIVAL_STAT(charaStHdl, idx 0..8) -> the value the match has for a player without a saved owner, -1 when the
-- page's own value holds (a saved character's, no match copy, or Suerte, which has no match copy)
function RivalPlayers.PageStat(hdl, idx)
  hdl, idx = tonumber(hdl), tonumber(idx)
  if not hdl or not idx or idx < 0 or idx > 6 then return -1 end
  local c = copy_of(hdl)
  if not c then return -1 end
  if not CUR or CUR.view_logged then return c[idx + 1] end
  CUR.view_logged = true
  info(string.format("datos view: chara 0x%08X stat %d shows %d (the match copy)", u32(hdl), idx, c[idx + 1]))
  return c[idx + 1]
end

-- [passive id] = { value, def }, [def] = its archetype (build type), read once at the first view
local PASSIVES = nil

local function passives_table()
  if PASSIVES then return PASSIVES end
  PASSIVES = {}
  local ok, err = pcall(function()
    local key = "data/common/gamedata/skill/passive_skill_config_*.cfg.bin"
    local ids, effects, n = {}, {}, 0
    for _, e in ipairs(VRFW.table.entries(key, { "PASSIVE_SKILL_INFO", "PASSIVE_SKILL_INFO_REF_EFFECT", "PASSIVE_SKILL_EFFECT" }, true)) do
      if e.name == "PASSIVE_SKILL_INFO" then
        n = n + 1
        ids[n] = u32(e[1])
      elseif e.name == "PASSIVE_SKILL_INFO_REF_EFFECT" then
        PASSIVES[ids[n]] = { first = tonumber(e[1]) or 0 }
      elseif e.name == "PASSIVE_SKILL_EFFECT" then
        effects[#effects + 1] = { u32(e[1]), tonumber(e[2]) or 0 }
      end
    end
    for _, p in pairs(PASSIVES) do
      local x = effects[p.first + 1]
      if x then p.def, p.value = x[1], x[2] end
    end
    local defs, cur = {}, nil
    key = "data/common/gamedata/soccer/passive_skill_effect_config_*.cfg.bin"
    for _, e in ipairs(VRFW.table.entries(key, { "PASSIVE_SKILL_EFFECT_INFO", "PASSIVE_SKILL_EFFECT_INFO_GRAND_TOTAL_INFO_BUILD_TYPE_ICON_DATA" }, true)) do
      if e.name == "PASSIVE_SKILL_EFFECT_INFO" then
        cur = u32(e[1])
      elseif cur then
        defs[cur] = tonumber(e[1])
      end
    end
    for _, p in pairs(PASSIVES) do p.build = p.def and defs[p.def] or nil end
  end)
  if not ok then warn("passive tables not readable: " .. tostring(err)) end
  return PASSIVES
end

-- the slots of a rival player of the running rule, nil for any other character (cached per handle, this match)
local function view_slots(hdl)
  if not CUR then return nil end
  local card = VIEW[hdl]
  if card == nil then
    card = false
    local okR, rec = pcall(VRFW.character.record, hdl)
    local c = okR and rec and rec.param and u32(rec.param) or 0
    if CUR.slots[c] then
      local okO, owner = pcall(VRFW.chara.owner, hdl)
      if not (okO and owner) then card = c end
    end
    VIEW[hdl] = card
  end
  return card and CUR.slots[card] or nil
end

-- CMND_GET_CHARA_TEAM_PASSIVE_INFO(hdl, slot, field, useCopy, preview): the passive rows of a rival player are his match
-- slots (field 0 id, 1 value, 2 unlocked); the command reads the game's own slots itself, the slot hooks never see it
function RivalPlayers.PlateInfo(hdl, slot, field)
  hdl, slot, field = tonumber(hdl), tonumber(slot), tonumber(field)
  if not hdl or not slot or not field or field > 2 or slot >= RP.SLOTS then return false end
  local slots = view_slots(hdl)
  if not slots then return false end
  local id = slots[slot]
  if field == 2 then return true, true, id ~= nil end
  if not id then return true, true, 0 end
  if field == 0 then return true, true, id end
  local p = passives_table()[id]
  return true, true, p and p.value or 0
end

-- his archetype, as the game counts it: the build type of the passive in his first archetype slot, nil = the game's
local function view_build(hdl)
  local slots = view_slots(hdl)
  if not slots then return nil end
  for slot = RP.SLOTS - 2, RP.SLOTS - 1 do
    local p = slots[slot] and passives_table()[slots[slot]]
    if p and p.build then return p.build end
  end
  return nil
end

-- 0x4375DC93(hdl, 36): the archetype icon of a rival player of the rule
function RivalPlayers.Status(hdl, field)
  hdl, field = tonumber(hdl), tonumber(field)
  if not hdl or field ~= 36 then return false end
  local b = view_build(hdl)
  if b == nil then return false end
  return true, b
end

-- 0x2B16FA30(hdl, ...) -> ok, build type: the same answer
function RivalPlayers.Build(hdl)
  hdl = tonumber(hdl)
  if not hdl then return false end
  local b = view_build(hdl)
  if b == nil then return false end
  return true, true, b
end

-- CMND_GET_CHARA_INFO after the game: fields 14..20 of a player without a saved owner show his match copy's stats, and
-- before a copy exists the rule's values added to the game's
function RivalPlayers.CharaInfo(args, results)
  local hdl, field = tonumber(args and args[1]), tonumber(args and args[2])
  if not hdl or not field or field < 14 or field > 21 then return nil end
  local built = field < 21 and copy_of(hdl) or nil
  if built then
    local k = (type(results[1]) == "boolean") and 2 or 1
    if tonumber(results[k]) then return { [k] = built[field - 13] } end
    return nil
  end
  if not CUR then return nil end
  local card = VIEW[hdl]
  if card == nil then
    card = false
    local okR, rec = pcall(VRFW.character.record, hdl)
    local c = okR and rec and rec.param and u32(rec.param) or 0
    if (CUR.stat_set[c] or CUR.add[c] or CUR.slots[c]) then
      local okO, owner = pcall(VRFW.chara.owner, hdl)
      if not (okO and owner) then card = c end
    end
    VIEW[hdl] = card
  end
  if not card then return nil end
  local k = (type(results[1]) == "boolean") and 2 or 1
  local v = tonumber(results[k])
  if not v then return nil end
  local i = field - 14
  local base = (CUR.stat_set[card] and CUR.stat_set[card][i]) or v
  local add = (CUR.add[card] and CUR.add[card][i]) or 0
  local out = math.max(1, math.min(9999, math.floor(base + add)))
  if out ~= v and not CUR.view_logged then
    CUR.view_logged = true
    info(string.format("datos view: chara 0x%08X (card 0x%08X) stat %d %d -> %d (first change of this match)", u32(hdl),
      card, i, v, out))
  end
  return { [k] = out }
end

-- 0x4375DC93(hdl, 14..20) after the game: the getter the player page and the team views read a player's stats with.
-- The same answer as CMND_GET_CHARA_INFO's.
function RivalPlayers.StatusStat(args, results)
  local field = tonumber(args and args[2])
  if not field or field < 14 or field > 20 then return nil end
  return RivalPlayers.CharaInfo(args, results)
end

VRFW.on("match:start_request", function(ev)
  pcall(VRFW.native.match_copies_clear)
  COPY = {}
  local ok, e = pcall(apply, ev.args and ev.args[2])
  if not ok then warn(tostring(e)) end
end)

VRFW.on("signal:vrfw.rival_players.trained", function()
  local ok, e = pcall(take_training)
  if not ok then warn(tostring(e)) end
end)

local function forget_match()
  pcall(VRFW.native.match_copies_clear)
  COPY = {}
  clear()
end

VRFW.on("match_end", forget_match)
VRFW.on("game_reset", forget_match)
