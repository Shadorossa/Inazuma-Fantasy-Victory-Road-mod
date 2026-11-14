if VRFW.host ~= nil and type(ClassicRecruitment) == "table" then
  local SELECTED = 3548785815
  local CARD_OF_FOCUSED = 2831689043 -- (spirit inventory handle, 0) -> card
  local BASE_OF_CARD = 347353059     -- (card) -> character
  local NAME_OF_BASE = 523676951     -- (character) -> name
  local FIRST_SPECIAL_RARITY = 5     -- rarities 5-7 Ídolo, 8 Diamante
  local NORMAL_REFUSED = 3228857518
  local ANSWER_NO = 1

  -- the focused spirit's record (an upvalue of the retail function)
  local function focused_spirit(retail)
    local debug_library = rawget(_ENV, "VRFW.debug")
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
        local card = VRFW.host.command(CARD_OF_FOCUSED, spirit.invHdl, 0)
        if card ~= nil then out[1] = {card = card, rarity = spirit.rarity} end
        return out
      end
    end
    for i = 0, (count or 0) - 1 do
      local got, card, rarity = VRFW.host.menu_command(SELECTED, i)
      if got then out[#out + 1] = {card = card, rarity = rarity} end
    end
    return out
  end

  local function card_name(card)
    local base = VRFW.host.command(BASE_OF_CARD, card)
    if base == nil then return "" end
    local name = VRFW.host.command(NAME_OF_BASE, base)
    return type(name) == "string" and name or ""
  end

  -- the message when one of the spirits is refused, else nil
  local function refusal(spirits)
    for _, spirit in ipairs(spirits) do
      -- normal cards reach the bag only through the gacha, which the option players_universe off keeps closed
      if type(spirit.rarity) == "number" and spirit.rarity < FIRST_SPECIAL_RARITY and ClassicRecruitment.gacha_removed() then
        return ClassicRecruitment.say(NORMAL_REFUSED, "")
      end
      -- A spirit of a card the club holds at the same rarity is refused only while duplicates are off (the option spirit_section off); the same card at another rarity is another player.
      if type(VRFW.recruit) == "table" and type(spirit.card) == "number" and type(spirit.rarity) == "number"
          and ClassicRecruitment.spirits_hidden() and CharacterReforged.holds_copy(spirit.card, spirit.rarity) then
        return ClassicRecruitment.say(ClassicRecruitment.album.OWNED, card_name(spirit.card))
      end
    end
    return nil
  end

  VRFW.host.wrap("OpenSummonCheckWindow", function(retail)
    return function(count, new_character, focused)
      if ClassicRecruitment.applies() then
        local text = refusal(asked_spirits(retail, count, focused))
        if text ~= nil then
          VRFW.question.notice(text)
          return ANSWER_NO
        end
      end
      return retail(count, new_character, focused)
    end
  end)
end
