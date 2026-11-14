-- Element cheat: the element picked for a card on the skill table, kept per save and written into the card's row in memory.

CharacterReforged = CharacterReforged or {}
CharacterReforged.ElementCheat = CharacterReforged.ElementCheat or {}
local E = CharacterReforged.ElementCheat

local info, warn = VRFW.logger("element_cheat")

local OPTION = "element_cheat"
local STORE = VRFW.save.doc.new("element_cheat.json", { version = 1, stage = true, log = "element_cheat" })

local candidates = nil   -- the element values a card may take, from the game's cards
local written = false    -- true while picked elements are in the game's memory

local function on()
  return VRFW.option(OPTION) == 1
end

local function key_of(card)
  return string.format("%08X", math.floor(tonumber(card) or 0) % 0x100000000)
end

-- Returns every element value from 0 up to the highest element a game card has, read once from the character index.
local function element_values()
  if candidates then return candidates end
  local top = nil
  local ok, cards = pcall(VRFW.character.cards)
  for _, c in ipairs(ok and type(cards) == "table" and cards or {}) do
    local v = tonumber(c.element)
    if v and (top == nil or v > top) then top = v end
  end
  candidates = {}
  for v = 0, top or -1 do candidates[#candidates + 1] = v end
  if top == nil then warn("character index unreadable: no element values (" .. tostring(cards) .. ")") end
  return candidates
end

-- Returns the picked elements of the active slot's document ({ [card hex] = element }) and the document.
local function picks()
  local doc = STORE:get()
  if type(doc) ~= "table" then doc = { version = 1 } end
  if type(doc.cards) ~= "table" then doc.cards = {} end
  return doc.cards, doc
end

-- Makes the card look cache (scripts\card_look.lua) answer `element` for `card`.
local function look(card, element)
  if type(CharacterReforged.CardLookOfCard) == "function" then
    CharacterReforged.CardLookOfCard(card).element = element
  end
end

-- Gives the game's cards their own elements back, then writes the picked ones while the option is on.
function E.apply()
  local restored, back = VRFW.chara_param.restore_elements()
  for card, element in pairs(back) do look(card, element) end
  written = false
  if not on() then return restored end
  local n = 0
  for key, element in pairs(picks()) do
    local card = tonumber(key, 16)
    if card and VRFW.chara_param.set_element(card, element) then
      n = n + 1
      look(card, element)
    end
  end
  written = n > 0
  info(string.format("%d picked elements written, %d cards given back first", n, restored))
  return n
end

-- Returns the card (chara_param id) of player handle `hdl`, nil when it has none.
local function card_of(hdl)
  local ok, r = pcall(VRFW.character.record, VRFW.ids.unsigned(hdl))
  return (ok and type(r) == "table" and type(r.param) == "number") and r.param or nil
end

--- CMND_CHARACTERREFORGED_ELEMENT_INFO(charaStHdl) -> on, the player's card element, then every element value it may take.
function E.Info(hdl)
  if not on() then
    if written then E.apply() end
    return false
  end
  local card = card_of(hdl)
  local element = card and VRFW.chara_param.element(card)
  if element == nil then return false end
  return true, element, table.unpack(element_values())
end

--- CMND_CHARACTERREFORGED_ELEMENT_SET(charaStHdl, element) -> ok: the player's card takes the element and the save document keeps it.
function E.Set(hdl, element)
  local card = card_of(hdl)
  if not on() or not card then return false end
  local v = math.floor(tonumber(element) or -1)
  local allowed = false
  for _, c in ipairs(element_values()) do
    if c == v then allowed = true end
  end
  if not allowed or not VRFW.chara_param.set_element(card, v) then return false end
  written = true
  look(card, v)
  local map, doc = picks()
  map[key_of(card)] = v
  local ok, where = STORE:put(doc)
  if not ok then warn("element of " .. key_of(card) .. " not kept: " .. tostring(where)) end
  info(string.format("card %s: element %d", key_of(card), v))
  return true
end

VRFW.on("save:slot_load", function(event)
  if event and event.after_load then E.apply() end
  return nil
end)

VRFW.on("game:reset", function()
  local _, back = VRFW.chara_param.restore_elements()
  for card, element in pairs(back) do look(card, element) end
  written = false
  return nil
end)
