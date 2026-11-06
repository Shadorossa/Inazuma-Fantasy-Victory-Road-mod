-- Signature Passives › how a player's own passive is shown: its name (the header of a passive window) and its effect
-- lines (the window's text). One function for every screen: the skill boards' custom passive window (graft
-- signature_passives_board, Character Reforged's skill table) and the player page's custom passive page; D.Icon the
-- passive's icon on Character Reforged's own passive card.
-- D.Current the grey last line of a stacking passive («Actual: 12 %»: its value now in the active team's lineup), D.Icon
-- the series icon of a passive whose player traits name a series.
-- A signature passive's description is «[CPASSIVE01]Name[C]\n<effect lines>»: the first line is the name, the rest the
-- effect. Any other description is the effect, and the name is the slot's label («Pasiva propia»).
-- Definitions only; no engine call at load time.
PersonalPassives_Display = type(PersonalPassives_Display) == "table" and PersonalPassives_Display or {}
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.Parts = type(CharacterReforged.Parts) == "table" and CharacterReforged.Parts or {}
CharacterReforged.Parts.PassiveDisplay = PersonalPassives_Display   -- handed to Character Reforged's pages
local D = PersonalPassives_Display

D.OWN_PASSIVE = 2686424402      -- CMND_PERSONALPASSIVES_OWN_PASSIVE (charaStHdl) -> passive id (0 = none), open, mod
D.DESCRIPTION = 1136033383      -- (id, 0) -> has, description text
D.PASSIVE_EFFECT = 4054311845   -- (passive id) -> has, effect id
D.PASSIVE_INFO = 1448743477     -- CMND_GET_PASSIVE_SKILL_INFO (0, id) -> effect id; (1, id) -> value
D.TEXT_FORMAT = 910683996       -- (text, tag, value, ...) -> text with the tag replaced
D.TEXT_GET = 4074371074         -- CMND_TEXT_GET (text id)
D.SLOT_NAME = 1901464137        -- menu_text «Pasiva propia» (Signature Passives' text row)
D.NAME_LINE = "^%[CPASSIVE01%]([^%[]*)%[C%]$"
D.EFFECT_KIND = 551963711       -- CMND_GET_PASSIVE_EFFECT_INFO (effect id, 2, 0) -> has, buff icon type
D.TEAMBUFF_TEX = 2301895383     -- #/menu/200_icon/08_icon_teambuff/<LG>/icon_teambuff.g4tx
D.PASSIVE_SAGA = 2680082628      -- CMND_PERSONALPASSIVES_PASSIVE_SAGA (id, charaHdl) -> series number (0 = none)
D.ELEMENT_ICON = 561089975     -- CMND_PERSONALPASSIVES_ELEMENT_ICON (id) -> sprite crc of icon_teambuff (0 = none)
D.SERIES_ICON = 817571471       -- CMND_VRFW_SERIES_ICON (series, "on") -> ok, sheet, sprite
D.CURRENT_VALUE = 4220024749    -- CMND_VRFW_PASSIVE_CURRENT_VALUE (id, charaHdl, "hdl,…") -> known, value, unit
D.VS_SET = 3713813716           -- CMND_GET_VS_USE_TEAM_SET () -> the active team set
D.MEMBER = 1720957768           -- team set member (set, team type, slot, 0 handle | 1 position) -> has, value
D.MEMBER_SLOTS = 29             -- the slots a team set holds
D.LAST_STARTER = 10             -- positions 0..10: the players on the pitch
D.CURRENT_TEXT = {percent = 2518574393, flat = 2808706569}   -- text rows signature_passives_current_percent / _flat
D.CURRENT_COLOUR = "[CWG]"      -- the line's grey (font_color WG)

-- the player's own passive id (0 = none or the module answers nothing)
function D.OwnPassive(hdl)
  if type(hdl) ~= "number" or hdl == 0 then
    return 0
  end
  local ok, passive = pcall(funcLuaCommand, D.OWN_PASSIVE, hdl)
  if ok and type(passive) == "number" then
    return passive
  end
  return 0
end

function D.SlotName()
  local ok, text = pcall(funcLuaCommand, D.TEXT_GET, D.SLOT_NAME)
  return (ok and type(text) == "string") and text or ""
end

-- the position and length of the first line break of a game text (the two characters \n, or a newline)
function D.FirstBreak(text)
  local at, size = string.find(text, "\\n", 1, true), 2
  local newline = string.find(text, "\n", 1, true)
  if newline ~= nil and (at == nil or newline < at) then
    at, size = newline, 1
  end
  return at, size
end

-- description -> name, effect (name nil when the first line is not a name line)
function D.Split(text)
  local at, size = D.FirstBreak(text)
  if at == nil then
    return nil, text
  end
  local name = string.match(string.sub(text, 1, at - 1), D.NAME_LINE)
  if name == nil or name == "" then
    return nil, text
  end
  return name, string.sub(text, at + size)
end

-- the passive's effect id (0 = none)
function D.EffectId(passive)
  local ok, has, effect = pcall(funcLuaCommand, D.PASSIVE_EFFECT, passive)
  if ok and has and type(effect) == "number" then
    return effect
  end
  local ok2, effect2 = pcall(funcLuaCommand, D.PASSIVE_INFO, 0, passive)
  return (ok2 and type(effect2) == "number") and effect2 or 0
end

-- the passive's description with its VALUE tag filled ("" when it has none)
function D.Description(passive)
  local ok, has, text = pcall(funcLuaCommand, D.DESCRIPTION, passive, 0)
  if not ok or has ~= true or type(text) ~= "string" then
    return ""
  end
  if string.find(text, "VALUE", 1, true) then
    local okv, value = pcall(funcLuaCommand, D.PASSIVE_INFO, 1, passive)
    if okv and type(value) == "number" then
      local okf, filled = pcall(funcLuaCommand, D.TEXT_FORMAT, text, "VALUE", value)
      if okf and type(filled) == "string" then
        text = filled
      end
    end
  end
  return text
end

-- the display of a passive: {passive, name, effect, effect_id}; passive defaults to the player's own (nil = none)
function D.Of(hdl, passive)
  passive = passive or D.OwnPassive(hdl)
  if type(passive) ~= "number" or passive == 0 then
    return nil
  end
  local name, effect = D.Split(D.Description(passive))
  return {passive = passive, hdl = hdl, name = name or D.SlotName(), effect = effect, effect_id = D.EffectId(passive)}
end

-- the character handles on the pitch of the active team set, "hdl,hdl,…" ("" = no active set)
function D.Lineup()
  local ok, set = pcall(funcLuaCommand, D.VS_SET)
  if not ok or type(set) ~= "number" or set < 0 then
    return ""
  end
  local out = {}
  for k = 0, D.MEMBER_SLOTS - 1 do
    local okh, has, hdl = pcall(funcLuaCommand, D.MEMBER, set, 0, k, 0)
    if okh and has and type(hdl) == "number" and hdl ~= 0 then
      local okp, hasp, pos = pcall(funcLuaCommand, D.MEMBER, set, 0, k, 1)
      if okp and hasp and type(pos) == "number" and pos >= 0 and pos <= D.LAST_STARTER then
        out[#out + 1] = string.format("%.0f", hdl % 4294967296)
      end
    end
  end
  return table.concat(out, ",")
end

-- a number as the card writes it: whole without decimals, else one decimal
local function Number(v)
  if v == math.floor(v) then
    return string.format("%d", v)
  end
  return string.format("%.1f", v)
end

-- the grey last line of a stacking passive: its value now in the active team's lineup («Actual: 12 %»); nil when the
-- framework cannot know it here (a passive that stacks on events, a trait of the match, no active team)
function D.Current(hdl, passive)
  if type(hdl) ~= "number" or hdl == 0 then
    return nil
  end
  local lineup = D.Lineup()
  if lineup == "" then
    return nil
  end
  local ok, known, value, unit = pcall(funcLuaCommand, D.CURRENT_VALUE, passive, hdl, lineup)
  if not ok or known ~= true or type(value) ~= "number" then
    return nil
  end
  local row = D.CURRENT_TEXT[unit]
  local okt, text = pcall(funcLuaCommand, D.TEXT_GET, row or 0)
  if row == nil or not okt or type(text) ~= "string" or text == "" then
    return nil
  end
  return D.CURRENT_COLOUR .. string.gsub(text, "{value}", Number(value)) .. "[C]"
end

-- the passive's icon on its card (the own passive card of Character Reforged's skill table and player page):
-- texture, sprite; nil = none. The game's team-buff icon of the passive's effect, as its own passive windows draw it.
-- The one source of the card's icon: a per-passive icon replaces only this function.
-- In order: a passive whose player traits name one series (or the holder's own): that series' icon (white); a
-- passive whose effect improves the moves of one element: that element's icon (content\passive_icons\
-- element_icons.toml); else the buff icon. Answers texture, sprite[, fallback texture, fallback sprite] (the
-- fallback while the series' sheet is not in).
function D.Icon(display)
  if type(display) ~= "table" then
    return nil
  end
  local tex, sprite = D.BuffIcon(display)
  local oke, element = pcall(funcLuaCommand, D.ELEMENT_ICON, display.passive or 0)
  if oke and type(element) == "number" and element ~= 0 then
    tex, sprite = D.TEAMBUFF_TEX, element
  end
  local okn, series = pcall(funcLuaCommand, D.PASSIVE_SAGA, display.passive or 0, display.hdl or 0)
  if okn and type(series) == "number" and series > 0 then
    local oki, has, sheet, icon = pcall(funcLuaCommand, D.SERIES_ICON, series, "on")
    if oki and has == true and type(sheet) == "number" and type(icon) == "number" then
      return sheet, icon, tex, sprite
    end
  end
  return tex, sprite
end

-- the game's team-buff icon of the passive's effect: texture, sprite; nil = none
function D.BuffIcon(display)
  if type(GeTeamBuffIconTextureName) ~= "function" then
    return nil
  end
  local effect = display.effect_id or (display.passive and D.EffectId(display.passive)) or 0
  if effect == 0 then
    return nil
  end
  local ok, has, kind = pcall(funcLuaCommand, D.EFFECT_KIND, effect, 2, 0)
  if not ok or not has then
    return nil
  end
  local okn, sprite = pcall(GeTeamBuffIconTextureName, kind)
  if okn and sprite ~= nil and sprite ~= 0 then
    return D.TEAMBUFF_TEX, sprite
  end
  return nil
end

-- BetterQoL's player album leaves the sixth sense page out of its plate; that page is where a player's signature
-- passive shows (the own passive card of Character Reforged's player page), so it stays for a card that has one
-- (BetterQoL.AlbumKeepPages, asked by the album's plate at run time; the plate's player is EVT_PPG.hdl)
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.AlbumKeepPages = BetterQoL.AlbumKeepPages or {}
BetterQoL.AlbumKeepPages["vrfw.SixthSense"] = function()
  local hdl = type(EVT_PPG) == "table" and EVT_PPG.hdl or nil
  return D.OwnPassive(hdl) ~= 0
end
