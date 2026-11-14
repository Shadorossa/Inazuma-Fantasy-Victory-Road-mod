
CharacterReforged = CharacterReforged or {}
CharacterReforged.Cmd = CharacterReforged.Cmd or {}
local SP = CharacterReforged

local Order = VRFW.series
local Id = VRFW.ids
local u32 = Id.unsigned

local LOOK = {}              -- [chara_param id] = { card, chara, element, crest }
local FIRST_TIMED = false    -- whether the first look's timing was logged

-- the look of a card (for other scripts too)
function SP.CardLookOfCard(card)
  card = u32(card)
  local look = LOOK[card]
  if look ~= nil then return look end
  look = { card = card, chara = 0, element = 0, crest = 0 }
  local timed = not FIRST_TIMED
  local t0 = timed and VRFW.now_ms() or 0
  local t_card, t_chara = t0, t0
  local okc, c = pcall(VRFW.character.card, card)
  if timed then t_card = VRFW.now_ms() end
  if okc and type(c) == "table" then
    look.chara = u32(c.base)
    look.element = math.floor(tonumber(c.element) or 0)
    local okh, h = pcall(VRFW.character.character, look.chara)
    if timed then t_chara = VRFW.now_ms() end
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
  if timed then
    FIRST_TIMED = true
    VRFW.log(string.format("card look: first look took %.1f ms (card %.1f, character %.1f, crest %.1f)",
      VRFW.now_ms() - t0, t_card - t0, math.max(t_chara - t_card, 0), VRFW.now_ms() - math.max(t_chara, t_card)))
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
