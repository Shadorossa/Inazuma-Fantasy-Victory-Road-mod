-- The Draft's constants, its config.toml values and the Draft team's declaration in the mod's team files.
local Shared = require "lib/draft/context"

local U = require "lib/util"
local G = require "lib/game"
local TeamConfig = VRFW.teams.config

local D = {}

local floor = math.floor

local CANDIDATES = 5
local POS_ANY, POS_GK, POS_DF = 0, 1, 4
local STARTERS = 11
local STAFF = { coach = 5, manager = 6 }
local NONE, PICKING, COMPLETE, CAMPAIGN = 0, 1, 2, 3
local PHASE_NAME = { [0] = "None", "Picking", "Complete", "Campaign" }

local ROSTER_VERSION = 1
local BLOB = "bb_draft.json"               -- the roster of a running draft campaign, per save slot
local FILTER_BLOB = "bb_draft_filters.json" -- the last choices of the Draft's filter panel, per save slot
local FILTER_ROWS = { "scouts", "gender" }
local GENDER_ALL, GENDER_MALE, GENDER_FEMALE = 0, 1, 2 -- The filter's «all» value and the chara_gender values of a person.
-- The values each filter row offers, the default first (scouts: 1 = in the pool, 0 = out).
local FILTER_CHOICES = { scouts = { 1, 0 }, gender = { GENDER_ALL, GENDER_MALE, GENDER_FEMALE } }
local FILTERS = { scouts = 1, gender = GENDER_ALL }
Shared.FILTER_SLOT = nil
local OBJ_SIZE = 0x8A0                     -- the grid object image of the BB pages service (record pass)

local KEY_TEAM = "BattleBayDeluxe.draft.team"
local KEY_PHASE = "BattleBayDeluxe.draft.phase"


local info, warn, err = VRFW.logger("draft")

local function fail(msg)
  error(msg, 0)
end

local function num_set(list)
  local s = {}
  if type(list) == "table" then
    for _, v in ipairs(list) do
      if type(v) == "number" then
        s[floor(v)] = true
      end
    end
  end
  return s
end

local function num_set_u32(list)
  local s = {}
  if type(list) == "table" then
    for _, v in ipairs(list) do
      if type(v) == "number" then
        s[VRFW.ids.unsigned(v)] = true
      end
    end
  end
  return s
end

local CFG = {
  team = tostring(U.config("draft.team", "draft")),
  special = num_set(U.config("draft.special_rarities", { 5, 6, 7, 8, 10 })),
  exclude = num_set_u32(U.config("draft.exclude", {})),
  seed = tonumber(U.config("campaign.seed", 0)) or 0,
}

local function toml_u32(v)
  return VRFW.ids.parse(v, { hash_names = true })
end

local function draft_decl(data, name)
  local teams = type(data) == "table" and data.team
  if type(teams) ~= "table" then
    return nil
  end
  for _, t in ipairs(teams) do
    if type(t) == "table" and t.name == name then
      if type(t.key) ~= "string" then
        return nil, "the team has no key"
      end
      local formation = toml_u32(t.formation)
      if not formation then
        return nil, "the team has no formation"
      end
      if type(t.member) ~= "table" then
        return nil, "the team has no member list"
      end
      local members = {}
      for _, m in ipairs(t.member) do
        if type(m) ~= "table" or type(m.slot) ~= "number" then
          return nil, "a member without slot"
        end
        local card = toml_u32(m.card)
        if not card then
          return nil, "a member without card"
        end
        members[#members + 1] = { slot = floor(m.slot) % 256, card = card }
      end
      local level = type(t.level) == "number" and math.max(0, floor(t.level)) or 0
      return { key = t.key, formation = formation, level = level, members = members }
    end
  end
  return nil
end

-- the Draft team's declaration in the mod's own team files (content\teams)
local function find_decl(name)
  local ok, list = pcall(VRFW.files.declarations, "content/teams")
  for _, e in ipairs(ok and type(list) == "table" and list or {}) do
    if e.mod == VRFW.mod then
      local d, why = draft_decl(e.data, name)
      if why then
        return nil, tostring(e.file) .. ": " .. why
      end
      if d then
        return d
      end
    end
  end
  return nil, 'no [[team]] name = "' .. name .. '" in content\\teams'
end

local DECL, DECL_ERR = find_decl(CFG.team)
local TEAM = DECL and VRFW.crc32(DECL.key) or 0

if DECL then
  info(string.format("team %s = %s (%s), %d members, formation %s, level %d", CFG.team, DECL.key, VRFW.ids.hex_text(TEAM),
    #DECL.members, VRFW.ids.hex_text(DECL.formation), DECL.level))
else
  warn("off (" .. tostring(DECL_ERR) .. "): the Draft tile of the Campaña does nothing")
end
pcall(VRFW.state.set, KEY_TEAM, TEAM)
pcall(VRFW.state.set, KEY_PHASE, NONE)

-- The names the later parts of the Draft read.
Shared.TeamConfig = TeamConfig
Shared.D = D
Shared.CANDIDATES = CANDIDATES
Shared.POS_ANY = POS_ANY
Shared.POS_GK = POS_GK
Shared.POS_DF = POS_DF
Shared.STARTERS = STARTERS
Shared.STAFF = STAFF
Shared.NONE = NONE
Shared.PICKING = PICKING
Shared.COMPLETE = COMPLETE
Shared.CAMPAIGN = CAMPAIGN
Shared.PHASE_NAME = PHASE_NAME
Shared.ROSTER_VERSION = ROSTER_VERSION
Shared.BLOB = BLOB
Shared.FILTER_BLOB = FILTER_BLOB
Shared.FILTER_ROWS = FILTER_ROWS
Shared.GENDER_ALL = GENDER_ALL
Shared.GENDER_MALE = GENDER_MALE
Shared.GENDER_FEMALE = GENDER_FEMALE
Shared.FILTER_CHOICES = FILTER_CHOICES
Shared.FILTERS = FILTERS
Shared.OBJ_SIZE = OBJ_SIZE
Shared.KEY_PHASE = KEY_PHASE
Shared.info = info
Shared.warn = warn
Shared.err = err
Shared.fail = fail
Shared.CFG = CFG
Shared.DECL = DECL
Shared.TEAM = TEAM
