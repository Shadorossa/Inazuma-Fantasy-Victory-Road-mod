
-- SetupSoccereMenuCharaModel and GetMenuCharaCaptureCameraType for the busts
pcall(INCLUDE, "LUA_SOCCER_COMMON")

local COMMAND = "CMND_BETTERUI_DUEL_READOUT"
local SCREEN = "betterui_power_counter_menu"
local LAYER_LABEL = "betterui_power_counter_label"

local LABEL_KEYS = { "BetterUI.duel_dribble", "BetterUI.duel_defense", "BetterUI.duel_power_charge",
  "BetterUI.duel_power_block" }
local LABEL_ATTACKS = { true, false, true, false }   -- per label: the side attacks

-- what only this screen does with the plates (their layers and nodes: BetterUI.power_counter.PLATES)
local PLATES = {
  { anime = 949786159 --[[the left plate's slide group]], keep = "_pos_telop03_l", hide = "_pos_telop03_r",
    picture_label = "_gtxt_br_total_at01", portrait = "_icon_br_chr_dmy01", placeholder = "_num_br_total_at01_dmy01",
    number_x_key = "left_number_x", bust_slot = 0, bust_turn = 30, bust_key = "betterui_duel_bust_left", side = "left" },
  { anime = 2710947733 --[[the right plate's slide group]], keep = "_pos_telop03_r", hide = "_pos_telop03_l",
    picture_label = "_gtxt_br_total_at02", portrait = "_icon_br_chr_dmy02", placeholder = "_num_br_total_at02_dmy01",
    number_x_key = "right_number_x", bust_slot = 1, bust_turn = -30, bust_key = "betterui_duel_bust_right", side = "right" },
}

local ANIME_COMMON = 1154021400   -- the plates' common open group
local ANIME_FORWARD = 0
local ANIME_REVERSE = 2
local BRECHA_BLOCK = "_pos_telop02"
local PRIM_TOTAL = "num_br_total_at01"
-- every other number of the plates' objects (brecha / save percentages, the second total)
local PRIMS_HIDDEN = { 1219286211, 3517285753, 2795681263, 952508492, 1338052826, 3603448160, 1536362464,
  1502288020, 1883395192, 676188912, 2571853099, 2392932880, 3862398564 }
local LABEL_TEXT_NODE = "_text_cmd_back01"
local LABEL_PLATE_MESHES = { "_cmd_back_base01", "_cmd_back_base01_add" }

-- commands the retail plates use, without a known name
local CMD_SUSPEND = 734148104
local CMD_NODE_VISIBLE = 2158717427
local CMD_PRIM_VISIBLE = 1233047821
local CMD_PRIM_VALUE = 3609943765
local CMD_NODE_POSITION = 2575768773
local CMD_MOVE_NAME_TEXT = 720417636  -- a move's name text id -> its text
local CMD_FRAME_SECONDS = 1549797111
local CMD_BUST_SET_KEY = 4176779611
local CMD_BUST_REGIST = 186863317
local CMD_BUST_LOOK = 156084207
local CMD_BUST_SWAP = 3747175963
local CMD_BUST_COMPLETE = 1583438030   -- (layer, instance, slot) -> the model's build is complete

-- the retail banner's values (soccer_zone_menu UpdateATKPTelopCharaIcon)
local BUST_CAMERA = 94068733
local BUST_POSE = 3193384671
local BUST_MOTION = 3410957774
local BUST_CHANGE_ARG = 9

local LOG_WAIT_SECONDS = 1
local MAX_SECONDS = 15            -- the screen closes itself when no closing event came
local LABEL_SCALE = 0.9
local LABEL_MIN_SCALE = 0.5
local LABEL_ROOM_NO_CONFIG = 380
                                  -- totals at their retail place
local LABEL_BOX = 840
local LABEL_UNIT_PX = 19          -- px at scale 1 of a text unit, when the game gives no width
local MOVE_NAME_FIELD = 4

local PC = nil                    -- BetterUI.power_counter (assets/lua/_all/power_counter.lua)
local counters = nil              -- per plate: { value, text, chara, attacks, critical }
local layout = nil                -- config.toml [duel_counter]; nil = the retail number place
local busts = {}
local bust_states = {}            -- per plate: what its bust setup did, for the log
local plates_opened = 0
local open_logged = false
local label_placer = nil          -- the label layer's placer
local label_widths = {}           -- per label instance + 1: half its width on screen
local tags = nil                  -- the «critical» tags of this opening
local labels_open = false
local labels_done = false
local elapsed = 0
local close_asked = false

local function Crc(text)
  return VRFW.ids.crc32(text)
end

local logger
local function Log(...)
  logger = logger or VRFW.logger.new("BETTERUI_POWER_COUNTER")
  logger(...)
end

local function LabelText(label)
  local key = LABEL_KEYS[label]
  if key == nil then
    return ""
  end
  local id = VRFW.host.command(Crc("CMND_VRFW_TEXT_ID"), key)
  if type(id) ~= "number" or id == 0 then
    return ""
  end
  local text = VRFW.host.command(Crc("CMND_TEXT_GET"), id)
  return type(text) == "string" and text or ""
end

local function MoveName(move)
  if type(move) ~= "number" or move == 0 then
    return ""
  end
  local known, text_id = VRFW.host.command(Crc("CMND_GET_SOCCER_SKILL_INFO"), move, MOVE_NAME_FIELD)
  if not known or text_id == nil then
    return ""
  end
  local name = VRFW.host.command(CMD_MOVE_NAME_TEXT, text_id)
  return type(name) == "string" and name or ""
end

-- the move's name, else the label of what the side did
local function PlateText(move, label)
  local name = MoveName(move)
  return name ~= "" and name or LabelText(label)
end

-- asked once per opening
local function ReadCounters()
  if counters ~= nil then
    return
  end
  local left_power, left_label, right_power, right_label, left_move, right_move, left_chara, right_chara = VRFW.host.command(Crc(COMMAND))
  local function counter(power, label, move, chara)
    chara = tonumber(chara) or 0
    return { value = tonumber(power) or 0, text = PlateText(move, label), chara = chara, attacks = LABEL_ATTACKS[label] == true,
      critical = PC.Critical(chara, move) }
  end
  counters = { counter(left_power, left_label, left_move, left_chara), counter(right_power, right_label, right_move, right_chara) }
  local tunables = VRFW.host.command(Crc("CMND_BETTERUI_DUEL_PLATE_LAYOUT"))
  layout = type(tunables) == "table" and tunables or nil
  local critical = { counters[1].value > 0 and counters[1].critical, counters[2].value > 0 and counters[2].critical }
  if critical[1] or critical[2] then
    tags = PC.NewTags(critical, layout, Log)
  end
end

local function LabelLayout(instance, text)
  local line = (text:gsub("%s*[\r\n]+%s*", " "))
  local width = VRFW.text_fold.measure(Crc(LAYER_LABEL), instance, Crc(LABEL_TEXT_NODE), line)
    or VRFW.text_fold.units(line) * LABEL_UNIT_PX
  local room = layout ~= nil and layout.label_room or LABEL_ROOM_NO_CONFIG
  local scale = math.max(LABEL_MIN_SCALE, math.min(LABEL_SCALE, room / math.max(width, 1)))
  return line, scale, math.min(width, LABEL_BOX)
end

local function SetupBust(plate, plate_index, layer, index, chara)
  if chara == 0 then
    return "no handle"
  end
  if SetupSoccereMenuCharaModel == nil or GetMenuCharaCaptureCameraType == nil then
    return "no retail include"
  end
  local key = Crc(plate.bust_key)
  local ok, built = pcall(function()
    if IsInvalidSoccerCharaHdl ~= nil and IsInvalidSoccerCharaHdl(chara) then
      return "invalid handle"
    end
    funcLuaMenuCommand(CMD_BUST_SET_KEY, layer, index, key)
    funcLuaMenuCommand(CMD_BUST_REGIST, layer, index, 1, plate.bust_slot)
    local camera = GetMenuCharaCaptureCameraType(chara, BUST_CAMERA)
    local look = funcLuaMenuCommand(CMD_BUST_LOOK, chara)
    if SetupSoccereMenuCharaModel(layer, index, plate.bust_slot, key, chara, 0, 0, 0, plate.bust_turn, BUST_POSE, BUST_MOTION,
        1, 0, camera, nil, nil, nil, nil, nil, look, BUST_CHANGE_ARG) == false then
      return "no chara info"
    end
    funcLuaMenuCommand(CMD_BUST_SWAP, layer, index, Crc(plate.portrait), key)
    return "set up"
  end)
  if not ok then
    return "failed: " .. tostring(built)
  end
  if built == "set up" then
    busts[plate_index] = { plate = plate, layer = layer, index = index, frames = 0,
      settle = layout ~= nil and layout.bust_settle_frames or 0 }
  end
  return built
end

local function UpdateBusts()
  for plate_index, bust in pairs(busts) do
    if bust.complete or VRFW.host.menu_command(CMD_BUST_COMPLETE, bust.layer, bust.index, bust.plate.bust_slot) == true then
      bust.complete = true
      if bust.settle > 0 then
        bust.settle = bust.settle - 1
      else
        VRFW.host.menu_command(Crc("CMND_SET_MESH_VISIBLE"), bust.layer, Crc(bust.plate.portrait), true, bust.index)
        busts[plate_index] = nil
        Log(string.format("bust %s shown after %d frames", bust.plate.side, bust.frames))
      end
    end
    bust.frames = bust.frames + 1
  end
end

local function LogOpen()
  if open_logged or counters == nil then
    return
  end
  open_logged = true
  Log(string.format("opened: left chara 0x%08X bust %s, right chara 0x%08X bust %s", counters[1].chara,
    tostring(bust_states[1]), counters[2].chara, tostring(bust_states[2])))
end

local function ShowCounter(i, index, counter)
  local plate, value = PLATES[i], counter.value
  local layer = Crc(PC.PLATES[i].layer)
  if value <= 0 then
    VRFW.host.menu_command(Crc("CMND_SET_LAYER_VISIBLE"), layer, index, false)
    return
  end
  VRFW.host.menu_command(CMD_SUSPEND, layer, index, false)
  for _, prim in ipairs(PRIMS_HIDDEN) do
    VRFW.host.menu_command(CMD_PRIM_VISIBLE, layer, index, prim, false)
  end
  local total = Crc(PRIM_TOTAL)
  VRFW.host.menu_command(CMD_PRIM_VISIBLE, layer, index, total, true)
  local prim_index = VRFW.host.menu_command(Crc("CMND_SEARCH_PRIM_INDEX"), layer, index, total)
  if prim_index ~= nil then
    VRFW.host.menu_command(CMD_PRIM_VALUE, layer, index, prim_index, value)
  end
  VRFW.host.menu_command(CMD_NODE_VISIBLE, layer, Crc(BRECHA_BLOCK), false)
  VRFW.host.menu_command(CMD_NODE_VISIBLE, layer, Crc(plate.hide), false)
  VRFW.host.menu_command(CMD_NODE_VISIBLE, layer, Crc(plate.keep), true)
  VRFW.host.menu_command(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(plate.picture_label), true, index)
  PC.ShowPicture(i, layer, index, counter.attacks and "attack" or "defense")
  VRFW.host.menu_command(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(plate.portrait), false, index)
  VRFW.host.menu_command(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(plate.placeholder), false, index)
  local number_x = layout ~= nil and layout[plate.number_x_key] or nil
  if number_x ~= nil then
    VRFW.host.menu_command(CMD_NODE_POSITION, layer, index, Crc(PC.PLATES[i].number_node), 0, number_x)
  end
  local anime = Crc("CMND_PLAY_ANIME_TYPE")
  VRFW.host.menu_command(anime, layer, index, Crc("Open"), ANIME_FORWARD, ANIME_COMMON)
  VRFW.host.menu_command(anime, layer, index, Crc("Open"), ANIME_FORWARD, plate.anime)
end

local function PlaceLabel(instance, i, text)
  local plate_layer = Crc(PC.PLATES[i].layer)
  local centre_x = PC.GlobalPosition(plate_layer, 0, Crc(PC.PLATES[i].number_node))
  local _, target_y = PC.GlobalPosition(plate_layer, 0, Crc(PC.PLATES[i].slide))
  if centre_x == nil or target_y == nil then
    PC.Hide(label_placer, instance)
    return false
  end
  if not PC.Started(label_placer, instance) then
    local layer = Crc(LAYER_LABEL)
    local shown_text, scale, width = LabelLayout(instance, text)
    label_widths[instance + 1] = width * scale * math.abs(label_placer.map.x) / 2
    for _, mesh in ipairs(LABEL_PLATE_MESHES) do
      VRFW.host.menu_command(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(mesh), false, instance)
    end
    VRFW.host.menu_command(Crc("CMND_SET_MENU_TEXT_STRING"), layer, Crc(LABEL_TEXT_NODE), shown_text, instance)
    VRFW.host.menu_command(Crc("CMND_SET_LAYER_LOCAL_SCALE"), layer, scale, scale, 1, instance)
  end
  return PC.Place(label_placer, instance, centre_x - label_widths[instance + 1], target_y)
end

-- true when no label needs more work
local function PlaceLabels()
  if not labels_open then
    return false
  end
  local layer = Crc(LAYER_LABEL)
  if VRFW.host.menu_command(Crc("CMND_IS_OPEN_LAYER"), layer) ~= true or VRFW.host.menu_command(Crc("CMND_IS_LOADING_LAYER"), layer) == true then
    return false
  end
  if not PC.Measure(label_placer) then
    return label_placer.map == false
  end
  local done = true
  for i = 1, #PLATES do
    local counter = counters[i]
    if counter.value > 0 and counter.text ~= "" and not PlaceLabel(i - 1, i, counter.text) then
      done = false
    end
  end
  return done
end

function OnInit()
  PC = BetterUI.power_counter
  counters, label_placer, label_widths, tags = nil, PC.NewPlacer(LAYER_LABEL, LABEL_TEXT_NODE, Log), {}, nil
  layout, busts, bust_states, plates_opened, open_logged = nil, {}, {}, 0, false
  labels_open, labels_done, elapsed, close_asked = false, false, 0, false
end

function OnSetupLayer(layer, index)
end

function OnOpenLayer(layer, index)
  local i = (layer == Crc(PC.PLATES[1].layer)) and 1 or (layer == Crc(PC.PLATES[2].layer)) and 2 or nil
  if i ~= nil then
    ReadCounters()
    ShowCounter(i, index or 0, counters[i])
    if counters[i].value > 0 then
      bust_states[i] = SetupBust(PLATES[i], i, layer, index or 0, counters[i].chara)
    else
      bust_states[i] = "no plate"
    end
    plates_opened = plates_opened + 1
    if plates_opened >= #PLATES then
      LogOpen()
    end
    if not labels_open then
      labels_open = true
      VRFW.host.menu_command(Crc("CMND_OPEN_LAYER_ARRAY"), Crc(LAYER_LABEL))
    end
  elseif layer == Crc(LAYER_LABEL) or layer == Crc(PC.TAG_LAYER) then
    VRFW.host.menu_command(Crc("CMND_SET_LAYER_VISIBLE"), layer, index or 0, false)
  end
end

function OnCloseLayer(layer, index)
  if layer == Crc(LAYER_LABEL) or layer == Crc(PC.TAG_LAYER) then
    VRFW.host.menu_command(Crc("CMND_SET_LAYER_VISIBLE"), layer, index or 0, false)
    return
  end
  for i, plate in ipairs(PLATES) do
    if layer == Crc(PC.PLATES[i].layer) and counters ~= nil and counters[i].value > 0 then
      VRFW.host.menu_command(Crc("CMND_PLAY_ANIME_TYPE"), layer, index or 0, Crc("Open"), ANIME_REVERSE, plate.anime)
    end
  end
end

function Step()
  if counters ~= nil and not labels_done then
    labels_done = PlaceLabels()
  end
  if tags ~= nil then
    PC.StepTags(tags)
  end
  UpdateBusts()
  local seconds = VRFW.host.command(CMD_FRAME_SECONDS)
  elapsed = elapsed + (type(seconds) == "number" and seconds or 0)
  if elapsed >= LOG_WAIT_SECONDS then
    LogOpen()
  end
  if elapsed >= MAX_SECONDS and not close_asked then
    close_asked = true
    VRFW.host.command(Crc("CMND_CLOSE_MENU_OBJECT"), Crc(SCREEN), true)
  end
end

function FinalizeMenu()
end
