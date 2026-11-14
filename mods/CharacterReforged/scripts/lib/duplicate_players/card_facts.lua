
local CardFacts = {}

local COLUMN_CARD, COLUMN_CHARACTER, COLUMN_ELEMENT, COLUMN_POSITION, COLUMN_SPECIAL_RARITY = 1, 2, 3, 4, 42
local COLUMN_AURA_ID, COLUMN_AURA_KEY, COLUMN_AURA_TYPE = 1, 2, 11
local AURA_TYPE_GENERIC_POWER = 5
local TEST_AURA_PREFIX = "test_"
local FIRST_ELEMENT, LAST_ELEMENT = 1, 4

local Id = VRFW.ids
local u32 = Id.unsigned

local function whole(v)
  if type(v) ~= "number" then return 0 end
  return v
end

local function read_cards()
  local rows = VRFW.table.raw(VRFW.table_files.file_name(VRFW.table_files.CHARA_PARAM), "CHARA_PARAM_INFO", { COLUMN_CARD, COLUMN_CHARACTER, COLUMN_ELEMENT, COLUMN_POSITION, COLUMN_SPECIAL_RARITY })
  local cards = {}
  for order, row in ipairs(rows) do
    if row[COLUMN_CARD] ~= nil then
      local card = u32(row[COLUMN_CARD])
      if cards[card] == nil then
        cards[card] = {
          character = u32(row[COLUMN_CHARACTER]), element = whole(row[COLUMN_ELEMENT]) % 256, position = whole(row[COLUMN_POSITION]) % 256,
          special_rarity = u32(row[COLUMN_SPECIAL_RARITY]), order = order,
        }
      end
    end
  end
  return cards
end

local function first_normal_cards(cards)
  local by_order = {}
  for card, facts in pairs(cards) do by_order[#by_order + 1] = { facts.order, card, facts } end
  table.sort(by_order, function(a, b) return a[1] < b[1] end)
  local base = {}
  for _, entry in ipairs(by_order) do
    local facts = entry[3]
    if facts.special_rarity == 0 and facts.character ~= 0 and base[facts.character] == nil then
      base[facts.character] = entry[2]
    end
  end
  return base
end

-- the element and the position of each character's base card
local function first_normal_elements(cards)
  local elements, positions = {}, {}
  for character, card in pairs(first_normal_cards(cards)) do
    elements[character], positions[character] = cards[card].element, cards[card].position
  end
  return elements, positions
end

local function read_hidden(cards, sources)
  local hidden = {}
  if #sources == 0 then return hidden end
  local elements, positions = first_normal_elements(cards)
  local function add(card, character_key)
    card = u32(card)
    if card == 0 then return end
    local character = type(character_key) == "string" and VRFW.character(character_key) or nil
    hidden[card] = { element = character and elements[character] or nil, position = character and positions[character] or nil }
  end
  for _, source in ipairs(sources) do
    local ok, declarations = pcall(VRFW.files.declarations, source.file)
    if not ok or type(declarations) ~= "table" then
      VRFW.warn("duplicate_players: " .. source.mod .. ":" .. source.file .. " could not be read (" .. tostring(declarations) .. "): its cards are not released")
    else
      for _, file in ipairs(declarations) do
        if file.mod == source.mod and type(file.data) == "table" then
          for _, row in ipairs(file.data.remove or {}) do
            if row.mode == "hide" then add(row.card, row.character or row.target) end
          end
          for _, row in ipairs(file.data.hide or {}) do
            if type(row.card) == "number" then add(row.card, row.target or row.character) end
            for _, card in ipairs(type(row.cards) == "table" and row.cards or {}) do add(card, row.target or row.character) end
          end
        end
      end
    end
  end
  return hidden
end

local function read_auras()
  local auras = {}
  for _, row in ipairs(VRFW.table.raw(VRFW.table_files.file_name(VRFW.table_files.AURA_SKILL_CONFIG), "AURA_CMD_INFO", { COLUMN_AURA_ID, COLUMN_AURA_KEY, COLUMN_AURA_TYPE })) do
    local id = u32(row[COLUMN_AURA_ID])
    if id ~= 0 and auras[id] == nil then
      local aura_type = row[COLUMN_AURA_TYPE] ~= nil and (whole(row[COLUMN_AURA_TYPE]) % 256) or nil
      local key = type(row[COLUMN_AURA_KEY]) == "string" and row[COLUMN_AURA_KEY] or ""
      auras[id] = aura_type ~= AURA_TYPE_GENERIC_POWER and key:sub(1, #TEST_AURA_PREFIX) ~= TEST_AURA_PREFIX
    end
  end
  return auras
end

-- The card and aura rows come from the game's tables, which stay the same for the whole session, so they are read once.
local game_cards, game_auras = nil, nil

-- Everything the pass reads, once per copy; the hidden cards follow the policy of this pass.
function CardFacts.load(policy)
  if game_cards == nil then
    local cards = read_cards()
    if next(cards) == nil then error("chara_param: no CHARA_PARAM_INFO rows") end
    game_cards, game_auras = cards, read_auras()
  end
  local self = { cards = game_cards, hidden = read_hidden(game_cards, policy.hidden_card_sources), auras = game_auras }
  return setmetatable(self, { __index = CardFacts })
end

-- element (1..4) of a card, nil when unknown
function CardFacts:element_of(card)
  local facts = self.cards[card]
  local element = facts and facts.element or (self.hidden[card] and self.hidden[card].element)
  if element and element >= FIRST_ELEMENT and element <= LAST_ELEMENT then return element end
  return nil
end

-- main position (1 GK, 2 DF, 3 MF, 4 FW) of a card, nil when unknown
function CardFacts:position_of(card)
  local facts = self.cards[card]
  return facts and facts.position or (self.hidden[card] and self.hidden[card].position)
end

-- chara_param col 41 of a card (nil = no row)
function CardFacts:special_rarity_of(card)
  local facts = self.cards[card]
  return facts and facts.special_rarity or nil
end

-- the character (chara_base) of a card, 0 = unknown row
function CardFacts:character_of(card)
  local facts = self.cards[card]
  return facts and facts.character or 0
end

-- the base card of a character (his first normal card), nil when he has none
function CardFacts:base_card_of(character)
  if self.base_cards == nil then self.base_cards = first_normal_cards(self.cards) end
  return self.base_cards[character]
end

function CardFacts:is_hidden(card)
  return self.hidden[card] ~= nil
end

-- Whether any card is hidden in this pass.
function CardFacts:has_hidden()
  return next(self.hidden) ~= nil
end

-- an aura command a team's aura entry may keep
function CardFacts:is_team_aura(move)
  return move ~= 0 and self.auras[move] == true
end

return CardFacts
