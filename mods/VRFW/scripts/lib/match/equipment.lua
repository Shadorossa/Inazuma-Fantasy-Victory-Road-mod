
local Id = VRFW.ids
local Memory = VRFW.memory
local _, warn = VRFW.logger("match_equipment")

local M = {}

local RULES = nil
local LAST = nil       -- { key, answer }

local function crc(text)
  return Id.unsigned(VRFW.crc32(text))
end

local function item_id(v)
  return Id.parse(v, { hash_names = true }) or 0
end

-- [MatchDifficulty.<Id>] Difficulty numbers, every active mod's content\defaults\match_difficulty.toml merged by Id
local function difficulty_numbers()
  local out = {}
  for key, row in pairs(VRFW.match.difficulty.rows()) do
    if tonumber(row.Difficulty) then out[key] = tonumber(row.Difficulty) end
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
          rule.games[type(g.game) == "number" and Id.unsigned(g.game) or crc(g.game)] = g.players
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

local read = Memory.read
local global = VRFW.game.global

local function play_mode()
  local pd, off = global("match_equipment_play_data"), field("Game.PlayMode")
  return (pd and off) and read("u8", pd + off) or nil
end

local NUMBERS = nil

--- Difficulty `v` (a number or a name) as its number.
function M.difficulty(v)
  if tonumber(v) then return tonumber(v) end
  NUMBERS = NUMBERS or difficulty_numbers()
  return NUMBERS[tostring(v)]
end

--- The game, difficulty and play mode of match info `info`; nil when not an address.
function M.match_of(info)
  if not info or info < 0x10000 then return nil end
  local og, od = field("MatchInfo.Game"), field("MatchInfo.Difficulty")
  if not og or not od then return nil end
  local game, diff = read("u32", info + og), read("u8", info + od)
  if not game or not diff then return nil end
  return Id.unsigned(game), diff, play_mode()
end

--- The equipment rule answer for match info `info`; nil when none.
function M.for_match_info(info)
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
          local card = Id.unsigned(p.card)
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

--- The equipment rule answer for the running match.
function M.running()
  return M.for_match_info(global("match_equipment_info"))
end

return M
