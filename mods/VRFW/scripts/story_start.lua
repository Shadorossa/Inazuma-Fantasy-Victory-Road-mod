
StoryStart = StoryStart or {}

local FOLDER = "content/story_start"
local KIND = "VRFW.story_start/1"

local function warn(...) VRFW.warn("story_start:", ...) end

local DATA = nil
local LOADED = false

local function append(out, list, f)
  if type(list) ~= "table" then return end
  for _, v in ipairs(list) do
    local x = f and f(v) or v
    if x ~= nil then out[#out + 1] = x end
  end
end

local function build()
  local ok, files = pcall(VRFW.files.declarations, FOLDER)
  if not ok or type(files) ~= "table" then return nil end
  local d = {
    VERSION = 0, LEVEL = 0, NORMAL_LEVEL = 0, PHASE = { 0, 0 },
    BITS = {}, BITS_OFF = {}, BYTES = {}, HELP = {}, QUESTS = {}, WORDS = {}, GAMES = {}, ITEMS = {},
    TEAM_INFO = {}, TEAM_SET = {}, ADDS = {}, SCOUTS = {}, NORMAL = {}, CHARACTER_OF = {}, CHARACTER_CARDS = {},
    TROPHIES = {},
  }
  local clear = nil
  local entries = 0
  for _, f in ipairs(files) do
    local data = type(f.data) == "table" and f.data or {}
    local where = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    if data.schema ~= KIND then
      warn(where .. ": schema " .. tostring(data.schema) .. " is not " .. KIND .. ": file left out")
    else
      local list = type(data.VRFW) == "table" and data.VRFW.StoryStart or nil
      for _, e in ipairs(type(list) == "table" and list or {}) do
        entries = entries + 1
        d.VERSION = tonumber(e.version) or d.VERSION
        d.LEVEL = tonumber(e.level) or d.LEVEL
        d.NORMAL_LEVEL = tonumber(e.normal_level) or d.NORMAL_LEVEL
        if type(e.phase) == "table" and #e.phase == 2 then d.PHASE = { e.phase[1], e.phase[2] } end
        clear = tonumber(e.story_clear_flag) or clear
        append(d.BITS, e.flags_on)
        append(d.BITS_OFF, e.flags_off)
        append(d.BYTES, e.byte_flags, function(b) return { b.flag, b.value } end)
        append(d.HELP, e.help)
        append(d.QUESTS, e.quests, function(q) return { q.quest, q.state } end)
        append(d.WORDS, e.search_words)
        append(d.GAMES, e.story_matches)
        append(d.ITEMS, e.items, function(i) return { i.item, i.count } end)
        append(d.TEAM_INFO, e.team_info, function(t) return t.args end)
        append(d.TEAM_SET, e.team_set, function(t) return t.args end)
        append(d.ADDS, e.story_roster, function(a)
          return { a.card, a.arg3, a.arg4, a.story_bank, a.arg8, a.arg9, a.team_set, a.slot, a.arg12, a.arg16, a.arg19 }
        end)
        append(d.SCOUTS, e.scouts, function(s) return { s.card, s.character, s.join_flag, s.team_set } end)
        append(d.NORMAL, e.normal_copies)
        for _, c in ipairs(type(e.characters) == "table" and e.characters or {}) do
          local cards = {}
          append(cards, c.cards)
          d.CHARACTER_CARDS[c.character] = cards
          for _, card in ipairs(cards) do d.CHARACTER_OF[card] = c.character end
        end
        append(d.TROPHIES, e.trophies, function(t) return { t.trophy, t.tier } end)
      end
    end
  end
  if entries == 0 then return nil end
  if clear == nil then
    warn("no story_clear_flag: the story-complete start is off")
    return nil
  end
  d.BITS[#d.BITS + 1] = clear
  VRFW.log("story_start:", entries, "entry(ies),", #d.BITS, "flags,", #d.ADDS + #d.SCOUTS, "roster,", #d.NORMAL,
           "normal copies,", #d.TROPHIES, "trophy tiers")
  return d
end

-- CMND_VRFW_STORY_START_DATA
function StoryStart.Data()
  if not LOADED then
    LOADED = true
    DATA = build()
  end
  return DATA
end
