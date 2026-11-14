-- Chronicle Deluxe: the pachangas of the free match list, script side. The list arms a pachanga against a free match
-- game at a class (CMND_CHRONICLEDELUXE_FREE_MATCH_PACHANGA_ARM) and asks for the five-a-side team of a free match team
-- (CMND_CHRONICLEDELUXE_FREE_MATCH_PACHANGA_FIVE, the [[VRFW.FormationFitTeams]] rule of content\teams); a won match with this pachanga's tag marks that game
-- and class won in this mod's per-save data, which the list reads for its orbs (assets\lua\soccer_vs_cpu_list_menu\
-- 300_free_match_pachanga.lua).
ChronicleDeluxe = ChronicleDeluxe or {}

local info, warn = VRFW.logger("ChronicleDeluxe.FreeMatchPachanga")

local FOLDER = "content/free_match_pachanga"
local KIND = "ChronicleDeluxe.free_match_pachanga/1"
local TEAMS_FOLDER = "content/teams"
local RULE_KEY = "VRFW.FormationFitTeams"
local FLAT_SUFFIX = "_flat"   -- the key suffix of the framework's free-match copy of a team (team engine fm_flat_team)
local PENDING_KEY, PENDING_CLASS_KEY = "free_match_pachanga.pending", "free_match_pachanga.pending_class"
local WON_KEY = "free_match_pachanga.won."

local PLAN = nil
local FIVES = nil

-- the declared pachanga (the last mod's declaration wins)
local function plan()
  if PLAN ~= nil then
    return PLAN
  end
  PLAN = false
  for _, file in ipairs(VRFW.files.declarations(FOLDER)) do
    local data = type(file.data) == "table" and file.data or {}
    local root = type(data.ChronicleDeluxe) == "table" and data.ChronicleDeluxe.FreeMatchPachanga or nil
    if data.schema ~= KIND then
      warn(string.format("mods/%s/%s: schema %s is not %s: file left out", tostring(file.mod), tostring(file.file), tostring(data.schema), KIND))
    elseif type(root) == "table" and type(root.friendly) == "string" and type(root.game) == "string" and type(root.tag) == "string" then
      PLAN = root
    else
      warn(string.format("mods/%s/%s: [ChronicleDeluxe.FreeMatchPachanga] needs friendly, game and tag", tostring(file.mod), tostring(file.file)))
    end
  end
  return PLAN
end

-- free match team id -> the id of its five-a-side team: the teams of the plan's [[VRFW.FormationFitTeams]] rule, each one
-- keyed `<KeyPrefix><source key>`, also for the framework's free-match copy `<source key>_flat` of a source team
local function fives()
  if FIVES ~= nil then
    return FIVES
  end
  FIVES = {}
  local p = plan()
  if not p or type(p.rivals) ~= "string" then
    return FIVES
  end
  local prefix = nil
  for _, file in ipairs(VRFW.files.declarations(TEAMS_FOLDER, RULE_KEY)) do
    local data = type(file.data) == "table" and file.data or {}
    local rules = type(data.VRFW) == "table" and data.VRFW.FormationFitTeams or nil
    for _, rule in ipairs(type(rules) == "table" and rules or {}) do
      if tostring(file.mod) .. "." .. tostring(rule.Id) == p.rivals and type(rule.KeyPrefix) == "string" then
        prefix = rule.KeyPrefix
      end
    end
  end
  if prefix == nil then
    warn("rival fives: no [[VRFW.FormationFitTeams]] rule " .. p.rivals .. ": a pachanga has no rival")
    return FIVES
  end
  local rows, why = VRFW.catalogue.pool({ key_prefix = prefix, columns = { "id", "key" } })
  if not rows then
    warn("rival fives: team_config not readable (" .. tostring(why) .. ")")
    return FIVES
  end
  for _, r in ipairs(rows) do
    local key, id = r.key or r[2], r.id or r[1]
    if type(key) == "string" and type(id) == "number" then
      local source = key:sub(#prefix + 1)
      FIVES[VRFW.crc32(source)] = VRFW.ids.unsigned(id)
      FIVES[VRFW.crc32(source .. FLAT_SUFFIX)] = VRFW.ids.unsigned(id)
    end
  end
  info(string.format("rival fives of %s: %d", p.rivals, #rows))
  return FIVES
end

-- (free match team id) -> the id of the five-a-side team a pachanga against it plays, or nil when it has none
function ChronicleDeluxe.FreeMatchPachangaFive(team)
  if type(team) ~= "number" then
    return nil
  end
  return fives()[VRFW.ids.unsigned(team)]
end

local function key_of(game, class)
  return WON_KEY .. string.format("%.0f", game) .. "." .. string.format("%.0f", class)
end

-- (free match game, class) -> the declared pachanga; the game and class are kept as the pending ones until its result
function ChronicleDeluxe.FreeMatchPachangaArm(game, class)
  local p = plan()
  if not p or type(game) ~= "number" or type(class) ~= "number" then
    return nil
  end
  VRFW.save.set(PENDING_KEY, game)
  VRFW.save.set(PENDING_CLASS_KEY, class)
  return { friendly = p.friendly, friendly_active_team = p.friendly_active_team or "", game = p.game,
    difficulty = tonumber(p.difficulty) or 1 }
end

VRFW.on("script:signal:vrfw.match_result", function()
  local p = plan()
  if not p or VRFW.match.has_tag(p.tag) ~= true then
    return
  end
  local game, class = VRFW.save.get(PENDING_KEY, nil), VRFW.save.get(PENDING_CLASS_KEY, nil)
  VRFW.save.set(PENDING_KEY, nil)
  VRFW.save.set(PENDING_CLASS_KEY, nil)
  local last = VRFW.match.results.last()
  if type(game) ~= "number" or type(class) ~= "number" or type(last) ~= "table" then
    return
  end
  info(string.format("pachanga against game %.0f class %.0f: %s %s-%s", game, class, tostring(last.outcome),
    tostring(last.score_for), tostring(last.score_against)))
  if last.won == true then
    VRFW.save.set(key_of(game, class), true)
  end
  VRFW.save.commit()
end)
