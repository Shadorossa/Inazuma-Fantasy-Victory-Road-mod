CharacterReforged_PassiveDisplay = type(CharacterReforged_PassiveDisplay) == "table" and CharacterReforged_PassiveDisplay or {}
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.parts = type(CharacterReforged.parts) == "table" and CharacterReforged.parts or {}
CharacterReforged.parts.passive_display = CharacterReforged_PassiveDisplay
local D = CharacterReforged_PassiveDisplay

D.OWN_PASSIVE = 2777885667     -- CMND_CHARACTERREFORGED_OWN_PASSIVE (charaHdl) -> passive id
D.DESCRIPTION = 1136033383      -- (id, 0) -> has, description text
D.PASSIVE_EFFECT = 4054311845   -- (passive id) -> has, effect id
D.PASSIVE_INFO = 1448743477
D.TEXT_FORMAT = 910683996
D.TEXT_GET = 4074371074         -- CMND_TEXT_GET (text id)
D.SLOT_NAME = 1901464137        -- menu_text Own Passive
D.NAME_LINE = "^%[CPASSIVE01%]([^%[]*)%[C%]$"
D.EFFECT_KIND = 551963711
D.TEAMBUFF_TEX = 2301895383     -- #/menu/200_icon/08_icon_teambuff/<LG>/icon_teambuff.g4tx
D.PASSIVE_SAGA = 601743200      -- CMND_CHARACTERREFORGED_PASSIVE_SAGA (passive id, charaHdl) -> series
D.ELEMENT_ICON = 2635235859     -- CMND_CHARACTERREFORGED_ELEMENT_ICON (passive id) -> sprite crc
D.SERIES_ICON = 817571471       -- CMND_VRFW_SERIES_ICON (series, "on") -> ok, sheet, sprite
D.CURRENT_VALUE = 4220024749
D.VS_SET = 3713813716           -- CMND_GET_VS_USE_TEAM_SET () -> the active team set
D.MEMBER = 1720957768
D.MEMBER_SLOTS = 29             -- the slots a team set holds
D.LAST_STARTER = 10             -- positions 0..10: the players on the pitch
D.CURRENT_TEXT = {percent = 2518574393, flat = 2808706569}   -- text rows signature_passives_current_percent / _flat
D.CURRENT_COLOUR = "[CWG]"      -- the line's grey (font_color WG)

-- the player's own passive id (0 = none or the module answers nothing)
function D.own_passive(hdl)
  if type(hdl) ~= "number" or hdl == 0 then
    return 0
  end
  local passive = VRFW.host.command(D.OWN_PASSIVE, hdl)
  if type(passive) == "number" then
    return passive
  end
  return 0
end

function D.slot_name()
  local text = VRFW.host.command(D.TEXT_GET, D.SLOT_NAME)
  return (type(text) == "string") and text or ""
end

-- the position and length of the first line break of a game text (the two characters \n, or a newline)
function D.first_break(text)
  local at, size = string.find(text, "\\n", 1, true), 2
  local newline = string.find(text, "\n", 1, true)
  if newline ~= nil and (at == nil or newline < at) then
    at, size = newline, 1
  end
  return at, size
end

-- description -> name, effect (name nil when the first line is not a name line)
function D.split(text)
  local at, size = D.first_break(text)
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
function D.effect_id(passive)
  local has, effect = VRFW.host.command(D.PASSIVE_EFFECT, passive)
  if has and type(effect) == "number" then
    return effect
  end
  local effect2 = VRFW.host.command(D.PASSIVE_INFO, 0, passive)
  return (type(effect2) == "number") and effect2 or 0
end

-- the passive's description with its VALUE tag filled ("" when it has none)
function D.description(passive)
  local has, text = VRFW.host.command(D.DESCRIPTION, passive, 0)
  if has ~= true or type(text) ~= "string" then
    return ""
  end
  if string.find(text, "VALUE", 1, true) then
    local value = VRFW.host.command(D.PASSIVE_INFO, 1, passive)
    if type(value) == "number" then
      local filled = VRFW.host.command(D.TEXT_FORMAT, text, "VALUE", value)
      if type(filled) == "string" then
        text = filled
      end
    end
  end
  return text
end

function D.of(hdl, passive)
  passive = passive or D.own_passive(hdl)
  if type(passive) ~= "number" or passive == 0 then
    return nil
  end
  local name, effect = D.split(D.description(passive))
  return {passive = passive, hdl = hdl, name = name or D.slot_name(), effect = effect, effect_id = D.effect_id(passive)}
end

-- the character handles on the pitch of the active team set, "hdl,hdl,…" ("" = no active set)
function D.lineup()
  local set = VRFW.host.command(D.VS_SET)
  if type(set) ~= "number" or set < 0 then
    return ""
  end
  local out = {}
  for k = 0, D.MEMBER_SLOTS - 1 do
    local has, hdl = VRFW.host.command(D.MEMBER, set, 0, k, 0)
    if has and type(hdl) == "number" and hdl ~= 0 then
      local hasp, pos = VRFW.host.command(D.MEMBER, set, 0, k, 1)
      if hasp and type(pos) == "number" and pos >= 0 and pos <= D.LAST_STARTER then
        out[#out + 1] = string.format("%.0f", VRFW.ids.unsigned(hdl))
      end
    end
  end
  return table.concat(out, ",")
end

local function Number(v)
  if v == math.floor(v) then
    return string.format("%d", v)
  end
  return string.format("%.1f", v)
end

function D.current(hdl, passive)
  if type(hdl) ~= "number" or hdl == 0 then
    return nil
  end
  local lineup = D.lineup()
  if lineup == "" then
    return nil
  end
  local known, value, unit = VRFW.host.command(D.CURRENT_VALUE, passive, hdl, lineup)
  if known ~= true or type(value) ~= "number" then
    return nil
  end
  local row = D.CURRENT_TEXT[unit]
  local text = VRFW.host.command(D.TEXT_GET, row or 0)
  if row == nil or type(text) ~= "string" or text == "" then
    return nil
  end
  return D.CURRENT_COLOUR .. string.gsub(text, "{value}", Number(value)) .. "[C]"
end

function D.icon(display)
  if type(display) ~= "table" then
    return nil
  end
  local tex, sprite = D.buff_icon(display)
  local element = VRFW.host.command(D.ELEMENT_ICON, display.passive or 0)
  if type(element) == "number" and element ~= 0 then
    tex, sprite = D.TEAMBUFF_TEX, element
  end
  local series = VRFW.host.command(D.PASSIVE_SAGA, display.passive or 0, display.hdl or 0)
  if type(series) == "number" and series > 0 then
    local has, sheet, icon = VRFW.host.command(D.SERIES_ICON, series, "on")
    if has == true and type(sheet) == "number" and type(icon) == "number" then
      return sheet, icon, tex, sprite
    end
  end
  return tex, sprite
end

function D.buff_icon(display)
  if type(GeTeamBuffIconTextureName) ~= "function" then
    return nil
  end
  local effect = display.effect_id or (display.passive and D.effect_id(display.passive)) or 0
  if effect == 0 then
    return nil
  end
  local has, kind = VRFW.host.command(D.EFFECT_KIND, effect, 2, 0)
  if not has then
    return nil
  end
  local okn, sprite = pcall(GeTeamBuffIconTextureName, kind)
  if okn and sprite ~= nil and sprite ~= 0 then
    return D.TEAMBUFF_TEX, sprite
  end
  return nil
end

BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.album_keep_pages = BetterQoL.album_keep_pages or {}
BetterQoL.album_keep_pages["vrfw.SixthSense"] = function()
  local hdl = type(CharacterReforged.player_page) == "table" and CharacterReforged.player_page.hdl or nil
  return D.own_passive(hdl) ~= 0
end
