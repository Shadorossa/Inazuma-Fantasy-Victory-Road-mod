-- Signature Passives › what the own passive card shows of its player besides the passive (Character Reforged's card on
-- the skill table and the player page, research/grafts/plate_pages parts/passives.lua EVT_PPG.PassiveCardFill):
--
--   CMND_PERSONALPASSIVES_CARD_LOOK(charaStHdl) -> card (chara_param id), character (chara_base id), element (the
--        card's element, 0..255), crest (item_emblem id: the crest his first team with one shows in the era of his
--        series, else in any era; 0 = none)
--
-- Everything is read from the game's tables through the framework (VRFW.character, VRFW/lib/series_order); one answer
-- kept per card. Nothing calls the game at load.

PersonalPassives = PersonalPassives or {}
PersonalPassives.Cmd = PersonalPassives.Cmd or {}
local SP = PersonalPassives

require "VRFW/lib/basics"
local Order = require "VRFW/lib/series_order"
local Id = require "VRFW/lib/ids"
local u32 = Id.u32

local LOOK = {}              -- [chara_param id] = { card, chara, element, crest }

-- the look of a card (for other scripts too)
function SP.CardLookOfCard(card)
  card = u32(card)
  local look = LOOK[card]
  if look ~= nil then return look end
  look = { card = card, chara = 0, element = 0, crest = 0 }
  local okc, c = pcall(VRFW.character.card, card)
  if okc and type(c) == "table" then
    look.chara = u32(c.base)
    look.element = math.floor(tonumber(c.element) or 0)
    local okh, h = pcall(VRFW.character.character, look.chara)
    if okh and type(h) == "table" then
      for _, team in ipairs(h.teams or {}) do
        local crest = Order.team_emblem(team, h.series)
        if crest ~= 0 then
          look.crest = crest
          break
        end
      end
    end
  end
  LOOK[card] = look
  return look
end

function SP.Cmd.CardLook(hdl)
  hdl = u32(hdl)
  if hdl == 0 then return 0, 0, 0, 0 end
  local ok, r = pcall(VRFW.character.record, hdl)
  if not ok or type(r) ~= "table" or type(r.param) ~= "number" then return 0, 0, 0, 0 end
  local look = SP.CardLookOfCard(r.param)
  return look.card, look.chara, look.element, look.crest
end
