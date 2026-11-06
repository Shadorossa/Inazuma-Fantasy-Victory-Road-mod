-- VRFW › match equipment: the equipment a mod declares for the rival players of a match, worn for that match only
-- (nothing is written to a save). Data: every active mod's content\match_equipment\*.toml (schema
-- VRFW.match_equipment/1, content\types\match_equipment.toml): one [match] rule per file (play_mode, difficulty = a
-- [MatchDifficulty.<Id>] key or its number, side = "rival") and its [[game]] lists (game key, players = { card,
-- items = the 4 equip slots in order: boots, bracelet, pendant, special; "" = empty }). Readers: the passive engine
-- (Wears / WearsSet of the rival players) and a mod that adds equipment stats to the match copies.
--   local ME = require "VRFW/lib/match_equipment"
--   ME.of_info(info) -> { [card id] = { slot 1..4 item ids } } for the match whose match info block is at `info`
--                       (game profile MatchInfo.Game / MatchInfo.Difficulty), nil when no rule holds
--   ME.running()     -> the same for the running match
--   ME.match_of(info) -> game id, Difficulty number, play-mode byte of the match whose match info is at `info` (nil
--                       when unreadable): the match a rule of another kind (e.g. VRFW/lib/match_move_level) tests
--   ME.difficulty(v) -> the Difficulty number of `v` (a [MatchDifficulty.<Id>] key or a number), nil when unknown
-- The caller's mod declares the globals "match_equipment_info" ([[g_gameRoot]+Game.RootMatch]) and
-- "match_equipment_play_data" ([[g_gameRoot]+Game.RootPlayData]) in its content\game files (memory permission).
-- The files are read once per script VM; a match's table is built once and kept until another match asks.

local Id = require "VRFW/lib/ids"
require "VRFW/lib/basics"
local _, warn = VRFW.logger("match_equipment")

local M = {}
local TWO32 = 4294967296

local RULES = nil      -- { { play_mode, difficulty, side, games = { [game id] = the file's players list } } }
local LAST = nil       -- { key, answer }

local function crc(text)
  local f = VRFW.crc32 or (VRFW.ui and VRFW.ui.crc32)
  return f and (f(text) % TWO32) or 0
end

local function item_id(v)
  if type(v) == "number" then return Id.u32(v) end
  if type(v) == "string" then
    if v:match("^0[xX]%x+$") then return Id.u32(tonumber(v:sub(3), 16)) end
    return crc(v)
  end
  return 0
end

-- [MatchDifficulty.<Id>] Difficulty numbers, every active mod's content\defaults\match_difficulty.toml merged by Id
local function difficulty_numbers()
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, "content/defaults/match_difficulty.toml")
  for _, f in ipairs((ok and files) or {}) do
    for key, row in pairs(((f.data or {}).MatchDifficulty) or {}) do
      if type(row) == "table" and tonumber(row.Difficulty) then out[key] = tonumber(row.Difficulty) end
    end
  end
  return out
end

local function load()
  if RULES then return RULES end
  RULES = {}
  local ok, files = pcall(VRFW.files.declarations, "content/match_equipment")
  if not ok or type(files) ~= "table" or #files == 0 then return RULES end
  local numbers = difficulty_numbers()
  for _, f in ipairs(files) do
    local d = f.data or {}
    local m = d.match
    if type(m) == "table" then
      local diff = tonumber(m.difficulty) or numbers[tostring(m.difficulty)]
      local rule = { play_mode = tonumber(m.play_mode), difficulty = diff, side = m.side or "rival", games = {} }
      for _, g in ipairs(d.game or {}) do
        if type(g.players) == "table" and (type(g.game) == "string" or type(g.game) == "number") then
          rule.games[type(g.game) == "number" and Id.u32(g.game) or crc(g.game)] = g.players
        end
      end
      if diff then
        RULES[#RULES + 1] = rule
      else
        warn(tostring(f.mod) .. ": unknown difficulty " .. tostring(m.difficulty) .. " (rule off)")
      end
    end
  end
  return RULES
end

local function field(name)
  local ok, v = pcall(VRFW.game.field, name)
  return (ok and type(v) == "number") and v or nil
end

local function read(ty, at)
  if not at or at < 0x10000 then return nil end
  local ok, v = pcall(VRFW.mem.read, ty, at)
  return ok and v or nil
end

local function global(name)
  local g = VRFW.game and VRFW.game[name]
  if type(g) ~= "function" then return nil end
  local ok, p = pcall(g)
  return (ok and type(p) == "number" and p >= 0x10000) and p or nil
end

local function play_mode()
  local pd, off = global("match_equipment_play_data"), field("Game.PlayMode")
  return (pd and off) and read("u8", pd + off) or nil
end

local NUMBERS = nil

function M.difficulty(v)
  if tonumber(v) then return tonumber(v) end
  NUMBERS = NUMBERS or difficulty_numbers()
  return NUMBERS[tostring(v)]
end

function M.match_of(info)
  if not info or info < 0x10000 then return nil end
  local og, od = field("MatchInfo.Game"), field("MatchInfo.Difficulty")
  if not og or not od then return nil end
  local game, diff = read("u32", info + og), read("u8", info + od)
  if not game or not diff then return nil end
  return Id.u32(game), diff, play_mode()
end

function M.of_info(info)
  local rules = load()
  if #rules == 0 then return nil end
  local game, diff, mode = M.match_of(info)
  if not game then return nil end
  local key = string.format("%d:%d:%s", game, diff, tostring(mode))
  if LAST and LAST.key == key then return LAST.answer end
  local answer = nil
  for _, r in ipairs(rules) do
    if r.difficulty == diff and (r.play_mode == nil or r.play_mode == mode) and r.side == "rival" then
      local list = r.games[game]
      if list then
        answer = answer or {}
        for _, p in ipairs(list) do
          local card = Id.u32(p.card)
          local slots = { 0, 0, 0, 0 }
          for k = 1, 4 do
            local it = (p.items or {})[k]
            if it ~= nil and it ~= "" then slots[k] = item_id(it) end
          end
          if card ~= 0 then answer[card] = slots end
        end
      end
    end
  end
  LAST = { key = key, answer = answer }
  return answer
end

function M.running()
  return M.of_info(global("match_equipment_info"))
end

return M
