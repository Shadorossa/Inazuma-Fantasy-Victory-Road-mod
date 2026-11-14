-- Advanced: VRFW.table_files: the game's table files as a script reads them (any mod's scripts; read VRFW.table_files.<name>).

local GAMEDATA = "data/common/gamedata/"

local M = {
  FORMATION_CONFIG = GAMEDATA .. "formation/formation_config",
  CHARA_PARAM = GAMEDATA .. "character/chara_param",
  AURA_SKILL_CONFIG = GAMEDATA .. "skill/aura_skill_config",
  CHARA_NAME_TAG = GAMEDATA .. "character/chara_name_tag",
  MAP_NAME_TAG = GAMEDATA .. "map/map_name_tag",
  MENU_CHARA_MODEL_POSE_CONFIG = GAMEDATA .. "menu/menu_chara_model_pose_config",
}

local KEYS = {}   -- stem -> the key answered

--- Advanced: The file key of table stem `stem`; nil when unknown.
function M.file_name(stem)
  local known = KEYS[stem]
  if known ~= nil then
    return known
  end
  local plain = stem .. ".cfg.bin"
  local ok, keys = pcall(VRFW.table.keys, plain)
  local key = (ok and type(keys) == "table" and #keys > 0) and plain or (stem .. "_*.cfg.bin")
  if ok then
    KEYS[stem] = key
  end
  return key
end

--- Advanced: The rows of list `list` of table `id` by column `names`: rows, column places.
function M.read(id, list, names)
  if type(VRFW.table) ~= "table" or type(VRFW.table.raw) ~= "function" then return nil, "no table service" end
  local okc, cols = pcall(VRFW.table.columns, id)
  if not okc or type(cols) ~= "table" then return nil, tostring(cols) end
  local position = {}
  for i, name in ipairs(cols) do position[name] = i end
  local at, wanted = {}, {}
  for _, name in ipairs(names) do
    local i = position[name]
    if i == nil then return nil, id .. ": no column " .. tostring(name) end
    at[name] = i
    wanted[#wanted + 1] = i
  end
  local oks, key = pcall(VRFW.table.source, id)
  if not oks or type(key) ~= "string" then return nil, tostring(key) end
  local okr, rows = pcall(VRFW.table.raw, key, list, wanted)
  if not okr or type(rows) ~= "table" then return nil, tostring(rows) end
  return rows, at
end

local Id = VRFW.ids
local _, warn = VRFW.logger("table_files")

local u32 = Id.unsigned
local GAMES = nil

-- [game id] = { [difficulty] = team, first = team, levels = { [difficulty] = level } } of soccer_game_info
local function read_games()
  local out = {}
  do
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
      out[g] = t
    end
  end
  return out
end

-- the games' table, built once per VM and kept between starts (it is game data only)
local function games()
  if GAMES then return GAMES end
  local ok, t = pcall(VRFW.derived, "soccer_game_rows", nil, read_games)
  if ok and type(t) == "table" then
    GAMES = t
  else
    GAMES = {}
    warn("soccer_game_info not readable (" .. tostring(t) .. ")")
  end
  return GAMES
end

--- Internal: Builds (or reads from the start cache) the games' table; a script calls it at load so a match call stays short.
function M.prepare_games()
  games()
end

--- Advanced: The team of game `game` at `difficulty`; nil when none.
function M.team(game, difficulty)
  local t = games()[u32(game or 0)]
  if t then
    if t[difficulty] then return t[difficulty], "row" end
    if t.first then return t.first, "first row" end
  end
  return 0, "none"
end

--- Internal: The level of game `game` at `difficulty`; nil when none.
function M.level(game, difficulty)
  local t = games()[u32(game or 0)]
  local l = t and t.levels[difficulty]
  return (l and l > 0) and math.floor(l) or nil
end

return M
