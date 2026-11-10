local NO_TITLE_SPRITE = "no_more_rarities_no_title"
-- position icon type (0 GK, 1 DF, 2 MF, 3 FW) -> card frame, status / personal plate sprites, plate colour
local POSITION_LOOKS = {
  [0] = {key = "goalkeeper", card_frame = 16, status_plate = "status_chr_base01_s04", personal_plate = "status_chr_plate01_04", rgb = {231, 185, 1}},
  [1] = {key = "defender", card_frame = 18, status_plate = "status_chr_base01_s01", personal_plate = "status_chr_plate01_01", rgb = {38, 158, 30}},
  [2] = {key = "midfielder", card_frame = 17, status_plate = "status_chr_base01_s02", personal_plate = "status_chr_plate01_02", rgb = {34, 119, 238}},
  [3] = {key = "forward", card_frame = 19, status_plate = "status_chr_base01_s01_type03", personal_plate = "status_chr_plate01_19", rgb = {192, 52, 33}},
}
-- staff role -> card frame (colours are the generator's STAFF_COLOURS)
local STAFF_LOOKS = {
  coach = {key = "coach", card_frame = 20},
  manager = {key = "manager", card_frame = 21},
}
local PLAIN_POSITION = 2               -- unknown position: the MF look (the game's plain green card)
local POSITION_SPIRIT_SETS = {[0] = 4, [1] = 1, [2] = 2, [3] = 5}

local CHARA = 1131797651               -- CMND_GET_CHARA (hdl, 12) = the status' rarity
local CHARA_INFO = 4060384944

local function StatusRarity(hdl)
  local rarity = VRFW.host.command(CHARA, hdl, 12)
  return type(rarity) == "number" and rarity or nil
end

local function ParamRarity(param)
  local first, second = VRFW.host.command(CHARA_INFO, param, 8)
  if not first then
    return nil
  end
  if type(second) == "number" then
    return second
  end
  return type(first) == "number" and first or nil
end

-- the saved rarity of a status handle, else of a chara param id
local function SavedRarity(hdl, param)
  if hdl ~= nil then
    return StatusRarity(hdl)
  elseif param ~= nil then
    return ParamRarity(param)
  end
  return nil
end

ClassicCards = type(ClassicCards) == "table" and ClassicCards or {}
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.parts = type(CharacterReforged.parts) == "table" and CharacterReforged.parts or {}
CharacterReforged.parts.card_look = ClassicCards
ClassicCards.POSITION_LOOKS = ClassicCards.POSITION_LOOKS or POSITION_LOOKS
ClassicCards.STAFF_LOOKS = ClassicCards.STAFF_LOOKS or STAFF_LOOKS

function ClassicCards.staff_look_of(role)
  return ClassicCards.STAFF_LOOKS[role or ""]
end

-- the card rarity of a chara param id (chara_param col 41), nil when unknown
ClassicCards.param_rarity = ClassicCards.param_rarity or ParamRarity

local draws_cards = type(rawget(_ENV, "UpdateCharaStatusPlateInfoByCharaStHdl")) == "function"
  or (type(rawget(_ENV, "MENU_DEF")) == "table" and type(MENU_DEF.SetupCharaRarityIcon) == "function")

if ClassicCards.rarity_removal_applies == nil then
  local SLOT_ACTIVE = 4245285902       -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
  local SLOT_RESERVED = 1380583127

  function ClassicCards.rarity_removal_applies()
    if type(funcLuaCommand) ~= "function" then
      return true
    end
    local active = VRFW.host.command(SLOT_ACTIVE)
    if type(active) ~= "number" or active <= 0 then
      return true
    end
    local reserved = VRFW.host.command(SLOT_RESERVED, active)
    return reserved ~= true
  end
end

if ClassicCards.rarity_removed == nil then
  local OPTION_GET = 4082322029        -- CMND_VRFW_OPTION_GET (row key) -> the value in force
  local OPTION_KEY = "ClassicCards.removed_rarities"
  local OPTION_DEFAULT = 0             -- options.toml default: basic only
  local LAST_BASIC_RARITY, LAST_IDOL_RARITY, DIAMOND_RARITY = 4, 7, 8
  local DIAMOND_FRAME = 10             -- every other rarity's frame is rarity + 1
  local TIERS_OF_CHOICE = {[0] = {}, {idol = true}, {diamond = true}, {idol = true, diamond = true}}

  local function RemovedTiers()
    local value = VRFW.host.command(OPTION_GET, OPTION_KEY)
    return TIERS_OF_CHOICE[type(value) == "number" and value or OPTION_DEFAULT] or TIERS_OF_CHOICE[OPTION_DEFAULT]
  end

  function ClassicCards.rarity_removed(rarity)
    if type(rarity) ~= "number" or rarity < 0 then
      return false
    end
    if rarity <= LAST_BASIC_RARITY then
      return true
    end
    if rarity <= LAST_IDOL_RARITY then
      return RemovedTiers().idol == true
    end
    if rarity == DIAMOND_RARITY then
      return RemovedTiers().diamond == true
    end
    return false
  end

  -- the card / plate / title frame number of a rarity
  function ClassicCards.frame_of_rarity(rarity)
    return rarity == DIAMOND_RARITY and DIAMOND_FRAME or rarity + 1
  end

  ClassicCards.LAST_REMOVABLE_RARITY = DIAMOND_RARITY
end

if ClassicCards.normal_card_rarity == nil then
  local NORMAL_CARD_RARITY = 4

  -- the rarity every normal card has while the removal applies, else nil
  function ClassicCards.normal_card_rarity()
    if ClassicCards.rarity_removal_applies() then
      return NORMAL_CARD_RARITY
    end
    return nil
  end
end

if ClassicCards.shown_rarity == nil then
  function ClassicCards.shown_rarity(rarity)
    if ClassicCards.rarity_removed(rarity) then
      return ClassicCards.normal_card_rarity() or rarity
    end
    return rarity
  end
end

if ClassicCards.position_colour == nil then
  local SLOT_POSITION_BITS = {{16, 0}, {32, 1}, {64, 2}, {128, 3}}

  local function IsId(value)
    return type(value) == "number" and value ~= 0
  end

  -- card = a status handle, or {charaStHdl | hdl, charaParamId | param, rarity, overwritePosType}
  local function CardFields(card)
    if type(card) == "number" then
      return card, nil, nil, nil
    end
    if type(card) ~= "table" then
      return nil, nil, nil, nil
    end
    local hdl = card.charaStHdl or card.hdl
    if not IsId(hdl) then
      hdl = nil
    end
    local param = card.charaParamId or card.param
    if not IsId(param) then
      param = nil
    end
    return hdl, param, card.rarity, card.overwritePosType
  end

  local function TypeOfSlotBits(bits)
    if type(bits) ~= "number" or bits <= 0 then
      return nil
    end
    for _, pair in ipairs(SLOT_POSITION_BITS) do
      local bit = pair[1]
      if bits % (bit + bit) >= bit then
        return pair[2]
      end
    end
    return nil
  end

  -- the player's own position icon type (VRFW.ui_plates.header_row), nil for staff or unknown
  local function OwnType(hdl, param)
    local rows = type(VRFW.ui_plates) == "table" and VRFW.ui_plates.header_row or nil
    if type(rows) ~= "table" then
      return nil
    end
    if hdl ~= nil then
      local ok, positionType = pcall(rows.natural_type, hdl)
      return ok and positionType or nil
    end
    local ok, positionType = pcall(rows.param_type, param)
    return ok and positionType or nil
  end

  function ClassicCards.position_look_of_type(positionType)
    return ClassicCards.POSITION_LOOKS[positionType or -1]
  end

  -- the card's rarity (the given one, else the saved one) is a removed one
  function ClassicCards.is_normal_card(card)
    local hdl, param, rarity = CardFields(card)
    if hdl == nil and param == nil then
      return false
    end
    if type(rarity) ~= "number" or rarity == 0 then
      rarity = SavedRarity(hdl, param)
    end
    return ClassicCards.rarity_removed(rarity)
  end

  function ClassicCards.card_position_type(card)
    local hdl, param, _, slotBits = CardFields(card)
    if hdl == nil and param == nil then
      return nil
    end
    local slotType = TypeOfSlotBits(slotBits)
    if slotType ~= nil then
      return slotType
    end
    return OwnType(hdl, param)
  end

  -- the card loses its rarity look in the loaded save
  function ClassicCards.loses_rarity_look(card)
    return ClassicCards.is_normal_card(card) and ClassicCards.rarity_removal_applies()
  end

  -- the position look of a card, nil = keep the retail look (reserved slot, kept rarity, staff, unknown position)
  function ClassicCards.position_colour(card)
    if not ClassicCards.loses_rarity_look(card) then
      return nil
    end
    return ClassicCards.position_look_of_type(ClassicCards.card_position_type(card))
  end
end

-- the engine's menu command, past this file's filter
function ClassicCards.raw_menu_command()
  local look = ClassicCards.card_look
  return look ~= nil and look.raw or funcLuaMenuCommand
end

if draws_cards and ClassicCards.card_look == nil then
  local L = {installed = false, raw = nil, plate_position = nil, last_position = nil, plate_depth = 0, named = false,
    late_done = false, staff_swapped = {}, own_wrappers = {}}
  ClassicCards.card_look = L

  local CARD_BY_STATUS = 3837561292
  local CARD_BY_PARAM = 2339877830     -- (layer, idx, chara param id, ...), the same arguments
  local CARD_BY_TABLE = 2329292196
  local LEADER_BY_SOCCER_HANDLE = 1000031904
  local LEADER_OF_TEAM = 3550249130    -- (layer, idx, team, big, true, ...): the team's coach card
  local SWAP_SPRITE = 558735651        -- (layer, texture, sprite, slot, 0, idx)
  local HAS_ABILITY = 2361903722
  local SPIRIT_CHARA_PARAM = 1545473289
  local SET_MESH_VISIBLE = 3405944500
  -- the native card's defaults of the arguments 4-10 when a caller gave fewer (game/characters/position-cards.md §2)
  local CARD_DEFAULTS = {nil, nil, nil, true, false, 0, 0, 0, false, false}
  local LAST_DEFAULTED_ARGUMENT = 10
  local CARD_COACH_ARGUMENT = 5
  local CARD_SLOT_ARGUMENT = 6
  local CARD_RARITY_ARGUMENT = 11
  local CARD_MANAGER_ARGUMENT = 18
  -- the layers whose cards show their formation slot's position badge (position-cards.md §4c)
  local FORMATION_LAYER_NAMES = {"team00_01_chara_card_for_soccer", "team00_01_chara_card_for_leader",
    "team00_01_chara_card_for_move"}
  -- the card's meshes by their default sprite (base and side gradient, large and small) and the frame sprite formats
  local CARD_MESHES = {{"icon_chr_base01_l01", "icon_chr_base01_l%02d"}, {"icon_chr_base01_s01", "icon_chr_base01_s%02d"},
    {"icon_chr_color01_l01", "icon_chr_color01_l%02d"}, {"icon_chr_color01_s01", "icon_chr_color01_s%02d"}}
  local DIRECTOR_ABILITY, MANAGER_ABILITY = "abl_000002", "abl_000003"
  local SPIRIT_TEXTURE_NAME = "#/menu/20_cmn/cmn01/cmn01_07/cmn01_07.g4tx"
  local SPIRIT_PARTS = {flame = "spirit_ef%02d", frame = "spirit_frame%02d", base = "spirit_base%02d"}

  local function Pack(...)
    return {n = select("#", ...), ...}
  end

  local function Finish(result)
    if not result[1] then
      error(result[2], 0)
    end
    return table.unpack(result, 2, result.n)
  end

  -- {crc(name) = rarity} of a sprite format for every removable rarity
  local function RaritySprites(crc, format)
    local sprites = {}
    for rarity = 0, ClassicCards.LAST_REMOVABLE_RARITY do
      sprites[crc(string.format(format, ClassicCards.frame_of_rarity(rarity)))] = rarity
    end
    return sprites
  end

  local function Ready()
    if L.named then
      return L.crc ~= nil
    end
    L.named = true
    local crc = rawget(_ENV, "CRC32")
    if type(crc) ~= "function" then
      return false
    end
    L.crc = crc
    L.STATUS_TEXTURE = crc("#/menu/00_soccer/soccer11/soccer11_04/<LG>/soccer11_04.g4tx")
    L.STATUS_SLOT = crc("status_chr_base01_s01")
    L.PERSONAL_TEXTURE = crc("#/menu/102_team/team11/team11_01/team11_01.g4tx")
    L.PERSONAL_SLOT = crc("status_chr_plate01_01")
    L.TITLE_TEXTURE = crc("#/menu/200_icon/05_icon_rarity/<LG>/icon_rarity.g4tx")
    L.CARD_TEXTURE = crc("#/menu/102_team/team00/team00_01/<LG>/team00_01.g4tx")
    L.NO_TITLE = crc(NO_TITLE_SPRITE)
    L.PLAIN_STATUS_PLATE, L.PLAIN_PERSONAL_PLATE = L.STATUS_SLOT, L.PERSONAL_SLOT
    for _, look in pairs(ClassicCards.POSITION_LOOKS) do
      look.status_plate_id = crc(look.status_plate)
      look.personal_plate_id = crc(look.personal_plate)
    end
    L.STATUS_RARITY_PLATES = RaritySprites(crc, "status_chr_base01_s%02d")
    L.PERSONAL_RARITY_PLATES = RaritySprites(crc, "status_chr_plate01_%02d")
    L.NORMAL_TITLES = RaritySprites(crc, "gtxt_rarity01_%02d")
    for element = 1, 5 do
      L.NORMAL_TITLES[crc(string.format("gtxt_rarity01_01_type%02d", element))] = 0
    end
    L.SPIRIT_TEXTURE = crc(SPIRIT_TEXTURE_NAME)
    L.SPIRIT_SLOTS, L.SPIRIT_RARITY_SPRITES, L.SPIRIT_POSITION_SPRITES = {}, {}, {}
    for part, format in pairs(SPIRIT_PARTS) do
      L.SPIRIT_SLOTS[crc(string.format(format, 1))] = part
      L.SPIRIT_RARITY_SPRITES[part] = RaritySprites(crc, format)
    end
    for positionType, set in pairs(POSITION_SPIRIT_SETS) do
      L.SPIRIT_POSITION_SPRITES[positionType] = {}
      for part, format in pairs(SPIRIT_PARTS) do
        L.SPIRIT_POSITION_SPRITES[positionType][part] = crc(string.format(format, set))
      end
    end
    L.FORMATION_LAYERS = {}
    for _, name in ipairs(FORMATION_LAYER_NAMES) do
      L.FORMATION_LAYERS[crc(name)] = true
    end
    L.DIRECTOR_ABILITY, L.MANAGER_ABILITY = crc(DIRECTOR_ABILITY), crc(MANAGER_ABILITY)
    L.frame_sprites = {}
    return true
  end

  local function FrameSprites(frame)
    local sprites = L.frame_sprites[frame]
    if sprites == nil then
      sprites = {}
      for _, mesh in ipairs(CARD_MESHES) do
        sprites[#sprites + 1] = {L.crc(mesh[1]), L.crc(string.format(mesh[2], frame))}
      end
      L.frame_sprites[frame] = sprites
    end
    return sprites
  end

  local function SwapCardFrame(raw, layer, idx, frame)
    for _, pair in ipairs(FrameSprites(frame)) do
      pcall(raw, SWAP_SPRITE, layer, L.CARD_TEXTURE, pair[2], pair[1], 0, idx or 0)
    end
  end

  local function CardKey(layer, idx)
    return tostring(layer) .. ":" .. tostring(idx or 0)
  end

  local function IsFormationCard(layer, idx)
    if L.FORMATION_LAYERS[layer] then
      return true
    end
    local compact = (type(rawget(_ENV, "BetterUI")) == "table" and BetterUI.player_card_is_compact or nil)
    if type(compact) ~= "function" then
      return false
    end
    local ok, answer = pcall(compact, L.raw, layer, idx)
    return ok and answer == true
  end

  local function HasAbility(hdl, ability)
    if type(hdl) ~= "number" or hdl == 0 or type(funcLuaCommand) ~= "function" then
      return false
    end
    local found, has = VRFW.host.command(HAS_ABILITY, hdl, ability)
    return found ~= false and has == true
  end

  -- the caller's coach / manager flags, else the status handle's director / manager ability
  local function StaffRole(coach, manager, hdl)
    if coach == true then
      return "coach"
    elseif manager == true then
      return "manager"
    elseif HasAbility(hdl, L.DIRECTOR_ABILITY) then
      return "coach"
    elseif HasAbility(hdl, L.MANAGER_ABILITY) then
      return "manager"
    end
    return nil
  end

  -- the rarity sent to the engine for this card (its staff or position frame - 1), nil = draw it as the caller gave it
  local function LookCardRarity(card, layer, idx, coach, manager, hdl)
    if not ClassicCards.loses_rarity_look(card) then
      return nil
    end
    local staff = ClassicCards.staff_look_of(StaffRole(coach, manager, hdl))
    if staff ~= nil then
      return staff.card_frame - 1
    end
    if not IsFormationCard(layer, idx) then
      card.overwritePosType = nil
    end
    local look = ClassicCards.position_look_of_type(ClassicCards.card_position_type(card))
      or ClassicCards.POSITION_LOOKS[PLAIN_POSITION]
    return look.card_frame - 1
  end

  local function DrawnFrame(card, sentRarity)
    local rarity = sentRarity
    if type(rarity) ~= "number" or rarity == 0 then
      rarity = card.rarity
    end
    if type(rarity) ~= "number" or rarity == 0 then
      local saved = SavedRarity(card.charaStHdl, card.charaParamId)
      if saved ~= nil then
        rarity = saved
      end
    end
    if type(rarity) ~= "number" or rarity < 0 then
      return nil
    end
    return ClassicCards.frame_of_rarity(rarity)
  end

  local function UndoStaffSwap(raw, layer, idx, card, sentRarity)
    local key = CardKey(layer, idx)
    if not L.staff_swapped[key] then
      return
    end
    L.staff_swapped[key] = nil
    local frame = DrawnFrame(card, sentRarity)
    if frame ~= nil then
      SwapCardFrame(raw, layer, idx, frame)
    end
  end

  local function CardCommand(raw, id, ...)
    local args = Pack(...)
    local card = {rarity = args[CARD_RARITY_ARGUMENT], overwritePosType = args[CARD_SLOT_ARGUMENT]}
    local hdl = nil
    if id == CARD_BY_STATUS then
      card.charaStHdl = args[3]
      hdl = args[3]
    else
      card.charaParamId = args[3]
    end
    local rarity = LookCardRarity(card, args[1], args[2], args[CARD_COACH_ARGUMENT], args[CARD_MANAGER_ARGUMENT], hdl)
    local result
    if rarity == nil then
      result = Pack(pcall(raw, id, ...))
    else
      local count = args.n
      for i = count + 1, LAST_DEFAULTED_ARGUMENT do
        args[i] = CARD_DEFAULTS[i]
      end
      args[CARD_RARITY_ARGUMENT] = rarity
      if count < CARD_RARITY_ARGUMENT then
        count = CARD_RARITY_ARGUMENT
      end
      result = Pack(pcall(raw, id, table.unpack(args, 1, count)))
    end
    if result[1] then
      UndoStaffSwap(raw, args[1], args[2], card, rarity)
    end
    return Finish(result)
  end

  local function TableCardCommand(raw, id, ...)
    local given = ...
    if type(given) ~= "table" then
      return raw(id, ...)
    end
    local card = {charaStHdl = given.charaStHdl, charaParamId = given.charaParamId, rarity = given.rarity,
      overwritePosType = given.overwritePosType}
    local rarity = LookCardRarity(card, given.layerName, given.layerIdx, given.isForceLeader, given.isManager,
      given.charaStHdl)
    local givenRarity = given.rarity
    if rarity ~= nil then
      given.rarity = rarity
    end
    local result = Pack(pcall(raw, id, ...))
    given.rarity = givenRarity         -- the caller's table back as it gave it
    if result[1] then
      UndoStaffSwap(raw, given.layerName, given.layerIdx, card, rarity)
    end
    return Finish(result)
  end

  local function LeaderCommand(raw, id, ...)
    local result = Pack(pcall(raw, id, ...))
    if result[1] and ClassicCards.rarity_removal_applies() then
      local layer, idx = ...
      SwapCardFrame(raw, layer, idx, ClassicCards.staff_look_of("coach").card_frame)
      L.staff_swapped[CardKey(layer, idx)] = true
    end
    return Finish(result)
  end

  -- The plate fill's own position (false = it has none), else the last player whose rarity a plate asked for.
  local function PlatePosition()
    if L.plate_position ~= nil then
      return L.plate_position or nil
    end
    return L.last_position
  end

  -- this sprite of a rarity sprite set belongs to a removed rarity
  local function SpriteRemoved(set, sprite)
    local rarity = set[sprite]
    return rarity ~= nil and ClassicCards.rarity_removed(rarity)
  end

  local function SwapCommand(raw, id, ...)
    local args = Pack(...)
    local texture, sprite, slot = args[2], args[3], args[4]
    local target, field = nil, nil
    if texture == L.STATUS_TEXTURE and slot == L.STATUS_SLOT and SpriteRemoved(L.STATUS_RARITY_PLATES, sprite) then
      target, field = L.PLAIN_STATUS_PLATE, "status_plate_id"
    elseif texture == L.PERSONAL_TEXTURE and slot == L.PERSONAL_SLOT and SpriteRemoved(L.PERSONAL_RARITY_PLATES, sprite) then
      target, field = L.PLAIN_PERSONAL_PLATE, "personal_plate_id"
    elseif texture == L.TITLE_TEXTURE and SpriteRemoved(L.NORMAL_TITLES, sprite) then
      target = L.NO_TITLE
    elseif texture == L.SPIRIT_TEXTURE and L.SPIRIT_SLOTS[slot] ~= nil
        and SpriteRemoved(L.SPIRIT_RARITY_SPRITES[L.SPIRIT_SLOTS[slot]], sprite) then
      local sprites = L.SPIRIT_POSITION_SPRITES[L.spirit_position or PLAIN_POSITION]
        or L.SPIRIT_POSITION_SPRITES[PLAIN_POSITION]
      target = sprites[L.SPIRIT_SLOTS[slot]]
    end
    if target == nil or not ClassicCards.rarity_removal_applies() then
      return raw(id, ...)
    end
    if field ~= nil then
      local look = ClassicCards.position_look_of_type(PlatePosition())
      if look ~= nil then
        target = look[field]
      end
    end
    args[3] = target
    return raw(id, table.unpack(args, 1, args.n))
  end

  local HANDLERS = {[CARD_BY_STATUS] = CardCommand, [CARD_BY_PARAM] = CardCommand,
    [CARD_BY_TABLE] = TableCardCommand, [LEADER_BY_SOCCER_HANDLE] = LeaderCommand, [LEADER_OF_TEAM] = LeaderCommand,
    [SWAP_SPRITE] = SwapCommand}

  local function StatusType(hdl)
    return ClassicCards.card_position_type({charaStHdl = hdl})
  end

  local function ParamType(param)
    return ClassicCards.card_position_type({charaParamId = param})
  end

  local PLATE_FUNCTIONS = {
    {name = "UpdateCharaStatusPlateInfoByCharaStHdl", position = StatusType, rarity_argument = 8,
      title_rarity = "GetCharaStatusRarity"},
    {name = "UpdateCharaStatusPlateInfoByCharaStHdlUseAttributeBg", position = StatusType, rarity_argument = 8,
      title_rarity = "GetCharaStatusRarity"},
    {name = "UpdateCharaStatusPlateInfoByCharaParamId", position = ParamType, rarity_argument = 7,
      title_rarity = "GetCharaParamRarity"},
    {name = "UpdateCharaStatusPlateInfoByCharaId", rarity_argument = 8},
    {name = "SwapPersonalPlateTexture"},
    {name = "SwapPersonalPlateTextureByCharaParamId"},
  }

  local function PlateRarity(rarity)
    local shown = ClassicCards.shown_rarity(rarity)
    if shown ~= rarity and type(VRFW.logger) == "table" then
      L.log = L.log or VRFW.logger.new("ClassicCards.plate")
      L.log.once(rarity, "plate of removed rarity", rarity, "drawn as rarity", shown)
    end
    return shown
  end

  -- VRFW.ui_plates.header_row when it can fill a plate without its rarity title, else nil
  local function HeaderRow()
    local ui = rawget(VRFW, "ui_plates")
    local row = type(ui) == "table" and ui.header_row or nil
    if type(row) == "table" and type(row.without_title) == "function" and type(row.RARITY) == "table" then
      return row
    end
    return nil
  end

  -- this plate fill draws the title of a removed rarity (its explicit rarity, else its rarity query's answer)
  local function TitleRemoved(entry, args)
    if entry.title_rarity == nil then
      return false
    end
    local rarity = args[entry.rarity_argument]
    if type(rarity) ~= "number" then
      local query = rawget(_ENV, entry.title_rarity)
      if type(query) ~= "function" then
        return false
      end
      local ok, value = pcall(query, args[3])
      rarity = ok and value or nil
    end
    return ClassicCards.rarity_removed(rarity) and ClassicCards.rarity_removal_applies()
  end

  local function SpiritFill(original)
    return function(...)
      local args = Pack(...)
      local previous = L.spirit_position
      local positionType = nil
      if type(funcLuaCommand) == "function" and type(args[3]) == "number" and args[3] ~= 0 then
        local param = VRFW.host.command(SPIRIT_CHARA_PARAM, args[3], args[4] or 0)
        if type(param) == "number" and param ~= 0 then
          positionType = ParamType(param)
        end
      end
      L.spirit_position = positionType
      local result = Pack(pcall(original, ...))
      L.spirit_position = previous
      return Finish(result)
    end
  end

  local function PlateFill(entry)
    return function(original)
      return function(...)
        local args = Pack(...)
        local previousPosition, previousDepth = L.plate_position, L.plate_depth
        if entry.position ~= nil then
          local ok, positionType = pcall(entry.position, args[3])
          L.plate_position = (ok and positionType ~= nil) and positionType or false
        end
        local index = entry.rarity_argument
        local titleOff = TitleRemoved(entry, args)
        if index ~= nil and type(args[index]) == "number" then
          args[index] = PlateRarity(args[index])
        end
        L.plate_depth = previousDepth + 1
        local result
        local row = titleOff and HeaderRow() or nil
        if row ~= nil then
          result = Pack(row.without_title(original, table.unpack(args, 1, args.n)))
          VRFW.host.menu_command(SET_MESH_VISIBLE, args[1], row.RARITY.MESH, false, args[2] or 0)
        else
          result = Pack(pcall(original, table.unpack(args, 1, args.n)))
        end
        L.plate_position, L.plate_depth = previousPosition, previousDepth
        return Finish(result)
      end
    end
  end

  local function RarityQuery(ownType)
    return function(original)
      return function(key, ...)
        local ok, positionType = pcall(ownType, key)
        L.last_position = ok and positionType or nil
        if L.plate_depth > 0 then
          return PlateRarity(original(key, ...))
        end
        return original(key, ...)
      end
    end
  end

  -- wraps holder[name] (default the globals) once per function object, so a later redefinition is wrapped again
  local function WrapGlobal(name, make, holder)
    holder = holder or _ENV
    if type(holder) ~= "table" then
      return
    end
    local original = rawget(holder, name)
    if type(original) == "function" and not L.own_wrappers[original] then
      local wrapper = make(original)
      L.own_wrappers[wrapper] = true
      rawset(holder, name, wrapper)
    end
  end

  local function WrapPlateFunctions()
    for _, entry in ipairs(PLATE_FUNCTIONS) do
      WrapGlobal(entry.name, PlateFill(entry))
    end
    local menuDef = rawget(_ENV, "MENU_DEF")
    if type(menuDef) == "table" then
      WrapGlobal("SetupSpritIcon", SpiritFill, menuDef)
    end
    WrapGlobal("GetCharaStatusRarity", RarityQuery(StatusType))
    WrapGlobal("GetCharaParamRarity", RarityQuery(ParamType))
  end

  -- the handled command goes on through the hook chain, any other (the coach frame's swaps) straight to the engine
  local function CommandUnder(nxt, handled)
    return function(id, ...)
      if id == handled then
        return nxt(id, ...)
      end
      return VRFW.host.real_menu_command(id, ...)
    end
  end

  local function MenuFilter(nxt, ...)
    L.installed = true
    local id = ...
    local handler = HANDLERS[id]
    if handler ~= nil and Ready() then
      return handler(CommandUnder(nxt, id), ...)
    end
    return nxt(...)
  end

  local LATE_OWNER = "ClassicCards.card_look_late"
  local function FirstMenuCommand(nxt, ...)
    if not L.late_done then
      L.late_done = true
      VRFW.host.unhook_command(LATE_OWNER, {menu = true})
      pcall(WrapPlateFunctions)
    end
    return nxt(...)
  end

  local function RegisterHooks()
    local ids = {}
    for id in pairs(HANDLERS) do
      ids[#ids + 1] = id
    end
    local innermost = {menu = true, priority = VRFW.host.INNERMOST}
    L.raw = VRFW.host.real_menu_command
    local installed = VRFW.host.hook_command(ids, MenuFilter, "ClassicCards.card_look", innermost)
    if not L.late_done then
      VRFW.host.hook_command("*", FirstMenuCommand, LATE_OWNER, innermost)
    end
    return installed
  end

  function L.install()
    if L.installed or type(funcLuaMenuCommand) ~= "function" then
      return
    end
    L.installed = RegisterHooks()
  end

  pcall(WrapPlateFunctions)
  RegisterHooks()

  local init = rawget(_ENV, "OnInit")
  if type(init) == "function" then
    OnInit = function(...)
      pcall(L.install)
      return init(...)
    end
  end
  local host = rawget(VRFW, "host")
  local patch = rawget(VRFW, "patch")
  local script = type(patch) == "table" and patch.script or nil
  local stem = type(script) == "string" and script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "") or nil
  if type(stem) == "string" and type(host) == "table" and type(host.on) == "function" then
    pcall(host.on, stem, "OnInit", {id = "ClassicCards.card_look", phase = "before", fn = function()
      pcall(L.install)
    end})
  end
end
