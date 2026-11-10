
PassivesSynergies = PassivesSynergies or {}
PassivesSynergies.Cmd = PassivesSynergies.Cmd or {}
local SP = PassivesSynergies

local Order = VRFW.series
local Id = VRFW.ids
local u32 = Id.unsigned

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
