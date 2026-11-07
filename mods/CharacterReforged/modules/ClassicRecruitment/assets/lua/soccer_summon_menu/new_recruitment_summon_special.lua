-- Classic Recruitment › the «Espíritu» screen turns Ídolo and Diamante cards into players, for the retail Basara flow.
-- A normal card a save still holds is not summoned (normal players are signed in the album), and a card the club
-- already has is not summoned twice (one copy per card: content\duplicate_rules\new_recruitment.toml). Every way to
-- summon asks OpenSummonCheckWindow first: its answer 1 is the retail «No». Not in a reserved slot.
-- A wrapper over the retail global; engine calls only inside the game's callbacks.
if VRFW_Host ~= nil and type(ClassicRecruitment) == "table" then
  local SELECTED = 3548785815        -- funcLuaMenuCommand (i) -> ok, card, rarity of the i-th selected spirit
  local CARD_OF_FOCUSED = 2831689043 -- (spirit inventory handle, 0) -> card
  local BASE_OF_CARD = 347353059     -- (card) -> character
  local NAME_OF_BASE = 523676951     -- (character) -> name
  local FIRST_SPECIAL_RARITY = 5     -- rarities 5-7 Ídolo, 8 Diamante
  local NORMAL_REFUSED = 1832650124  -- new_recruitment_summon_normal (text\rows\album_text.toml)
  local ANSWER_NO = 1

  -- the focused spirit's record, a chunk local of the retail function
  local function focused_spirit(retail)
    local debug_library = rawget(_ENV, "EVT_DEBUG")
    if type(debug_library) ~= "table" then return nil end
    local i = 1
    while true do
      local name, value = debug_library.getupvalue(retail, i)
      if name == nil then return nil end
      if type(value) == "table" and value.invHdl ~= nil then return value end
      i = i + 1
    end
  end

  -- {card, rarity} of each spirit the window asks about (the focused one when `focused`, as the retail window)
  local function asked_spirits(retail, count, focused)
    local out = {}
    if focused then
      local spirit = focused_spirit(retail)
      if spirit ~= nil then
        local ok, card = pcall(funcLuaCommand, CARD_OF_FOCUSED, spirit.invHdl, 0)
        if ok then out[1] = {card = card, rarity = spirit.rarity} end
        return out
      end
    end
    for i = 0, (count or 0) - 1 do
      local ok, got, card, rarity = pcall(funcLuaMenuCommand, SELECTED, i)
      if ok and got then out[#out + 1] = {card = card, rarity = rarity} end
    end
    return out
  end

  local function card_name(card)
    local ok, base = pcall(funcLuaCommand, BASE_OF_CARD, card)
    if not ok then return "" end
    local got, name = pcall(funcLuaCommand, NAME_OF_BASE, base)
    return got and type(name) == "string" and name or ""
  end

  -- the message when one of the spirits is refused, else nil
  local function refusal(spirits)
    for _, spirit in ipairs(spirits) do
      if type(spirit.rarity) == "number" and spirit.rarity < FIRST_SPECIAL_RARITY then
        return ClassicRecruitment.Say(NORMAL_REFUSED, "")
      end
      if type(VRFW_Recruit) == "table" and type(spirit.card) == "number" then
        local _, why = VRFW_Recruit.CanSign(spirit.card)
        if why == "owned" then
          return ClassicRecruitment.Say(ClassicRecruitment.Album.OWNED, card_name(spirit.card))
        end
      end
    end
    return nil
  end

  VRFW_Host.wrap("OpenSummonCheckWindow", function(retail)
    return function(count, new_character, focused)
      if ClassicRecruitment.Applies() then
        local text = refusal(asked_spirits(retail, count, focused))
        if text ~= nil then
          ClassicRecruitment.Notice(text)
          return ANSWER_NO
        end
      end
      return retail(count, new_character, focused)
    end
  end)
end
