-- betterui_power_counter_menu (plain Lua 5.2 source): each side's total on the shot zone's plates during the cut-ins of a
-- special-move / power-action duel. Declared in content\menus\duel_readout.toml ([[screen]]). scripts\duel_readout.lua
-- opens it when a cut-in of the duel starts and closes it when the cut-in ends; it asks CMND_BETTERUI_DUEL_READOUT once
-- when it opens. Left plate = the player's side, right plate = the rival's, each with its player's 3D bust. No engine call
-- at load time but the game's own include.

-- SetupSoccereMenuCharaModel and GetMenuCharaCaptureCameraType, as soccer_vs_skill_menu; without them the plates have no
-- bust and the readout stays
pcall(INCLUDE, "LUA_SOCCER_COMMON")

local COMMAND = "CMND_BETTERUI_DUEL_READOUT"
local SCREEN = "betterui_power_counter_menu"
local LAYER_LABEL = "betterui_power_counter_label"

local LABEL_KEYS = { "BetterUI.duel_dribble", "BetterUI.duel_defense", "BetterUI.duel_power_charge",
  "BetterUI.duel_power_block" }

-- the rules of one plate: its retail layer, slide group, the band it keeps / hides, its picture label, slot, portrait, the
-- total's placeholder mesh (a white 16 x 16 sprite stretched to one digit, drawn under the digits unless hidden), the
-- total's node with the layout key of its x on this screen (the game centres the digits on that node; only this screen's
-- instance moves: the shot zone's plates keep their place) and the bust: the model slot and turn of the retail banner
-- (soccer_zone_menu UpdateATKPTelopCharaIcon), with a capture key of this screen. A capture cell belongs to its key, and the
-- zone's plates keep theirs for the rest of the match, so the retail keys would share a cell with them.
local PLATES = {
  { layer = "soccer10_25_at_kp_power_info_telop_self", anime = 949786159 --[[the left plate's slide group]],
    keep = "_pos_telop03_l", hide = "_pos_telop03_r", picture_label = "_gtxt_br_total_at01",
    slide = "_pos_slide01_l", portrait = "_icon_br_chr_dmy01", placeholder = "_num_br_total_at01_dmy01",
    number_node = "_num_total_at01", number_x_key = "left_number_x",
    bust_slot = 0, bust_turn = 30, bust_key = "betterui_duel_bust_left", side = "left" },
  { layer = "soccer10_25_at_kp_power_info_telop_enemy", anime = 2710947733 --[[the right plate's slide group]],
    keep = "_pos_telop03_r", hide = "_pos_telop03_l", picture_label = "_gtxt_br_total_at02",
    slide = "_pos_slide01_r", portrait = "_icon_br_chr_dmy02", placeholder = "_num_br_total_at02_dmy01",
    number_node = "_num_total_at02", number_x_key = "right_number_x",
    bust_slot = 1, bust_turn = -30, bust_key = "betterui_duel_bust_right", side = "right" },
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
local CMD_NODE_POSITION = 2575768773  -- (layer, instance, node, axis 0 x / 1 y, value): a node's local translation
local CMD_MOVE_NAME_TEXT = 720417636  -- a move's name text id -> its text
local CMD_FRAME_SECONDS = 1549797111
local CMD_BUST_SET_KEY = 4176779611    -- (layer, instance, key): before a build, as the retail banner
local CMD_BUST_REGIST = 186863317      -- (layer, instance, 1, slot): the scene chara's registration type
local CMD_BUST_LOOK = 156084207        -- (chara) -> the retail banner's look argument of the model build
local CMD_BUST_SWAP = 3747175963       -- (layer, instance, mesh, key): the mesh draws the key's capture cell
local CMD_BUST_COMPLETE = 1583438030   -- (layer, instance, slot) -> the model's build is complete

-- the retail banner's values (soccer_zone_menu UpdateATKPTelopCharaIcon)
local BUST_CAMERA = 94068733
local BUST_POSE = 3193384671
local BUST_MOTION = 3410957774
local BUST_CHANGE_ARG = 9

local LOG_WAIT_SECONDS = 1        -- the opening's log line waits this long for a plate that did not open
local MAX_SECONDS = 15            -- the screen closes itself when no closing event came
local LABEL_SCALE = 0.9
local LABEL_MIN_SCALE = 0.5
local LABEL_ROOM_NO_CONFIG = 380  -- px on screen a label may take without config.toml [duel_counter]: the distance of the
                                  -- totals at their retail place
local LABEL_BOX = 840             -- px at scale 1: the text node's box (label_room / LABEL_MIN_SCALE, its own layout in
                                  -- content\menus\duel_readout.toml); the game squeezes a wider line into it
local LABEL_UNIT_PX = 19          -- px at scale 1 of a text unit, when the game gives no width
local MOVE_NAME_FIELD = 4         -- CMND_GET_SOCCER_SKILL_INFO(move, 4) -> known, the name's text id
local LABEL_SNAP = 3              -- px: a label this close to its slot is shown
local LABEL_DONE = 0.5            -- px: a label this close is in place and left alone
local PROBE_STEP = 100            -- px the label layer moves while its offset is measured
local PROBE_WAIT = 2              -- frames between a probe move and its reading
local LABEL_SETTLE = 1            -- frames between a label move and the next correction

local counters = nil              -- per plate: { value, text, chara }
local layout = nil                -- config.toml [duel_counter]; nil = the retail number place
local busts = {}                  -- per plate: the bust waiting for its model, until its mesh is shown
local bust_states = {}            -- per plate: what its bust setup did, for the log
local plates_opened = 0
local open_logged = false
local labels = {}                 -- per label instance + 1: its placement
local position_map = nil          -- label layer position -> global position; false = labels off
local probe = nil
local labels_open = false
local labels_done = false
local elapsed = 0
local close_asked = false

local function Crc(text)
  return VRFW_Id.Crc(text)
end

local function Menu(command, ...)
  local result = table.pack(pcall(funcLuaMenuCommand, command, ...))
  if result[1] then
    return table.unpack(result, 2, result.n)
  end
  return nil
end

local function Game(command, ...)
  local result = table.pack(pcall(funcLuaCommand, command, ...))
  if result[1] then
    return table.unpack(result, 2, result.n)
  end
  return nil
end

local function Log(...)
  Game(Crc("CMND_EVT_LOG"), "BETTERUI_POWER_COUNTER", ...)
end

local function LabelText(label)
  local key = LABEL_KEYS[label]
  if key == nil then
    return ""
  end
  local id = Game(Crc("CMND_VRFW_TEXT_ID"), key)
  if type(id) ~= "number" or id == 0 then
    return ""
  end
  local text = Game(Crc("CMND_TEXT_GET"), id)
  return type(text) == "string" and text or ""
end

-- a move's name in the game's language; "" when there is no move or it has no name
local function MoveName(move)
  if type(move) ~= "number" or move == 0 then
    return ""
  end
  local known, text_id = Game(Crc("CMND_GET_SOCCER_SKILL_INFO"), move, MOVE_NAME_FIELD)
  if not known or text_id == nil then
    return ""
  end
  local name = Game(CMD_MOVE_NAME_TEXT, text_id)
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
  local left_power, left_label, right_power, right_label, left_move, right_move, left_chara, right_chara = Game(Crc(COMMAND))
  counters = {
    { value = tonumber(left_power) or 0, text = PlateText(left_move, left_label), chara = tonumber(left_chara) or 0 },
    { value = tonumber(right_power) or 0, text = PlateText(right_move, right_label), chara = tonumber(right_chara) or 0 },
  }
  local tunables = Game(Crc("CMND_BETTERUI_DUEL_PLATE_LAYOUT"))
  layout = type(tunables) == "table" and tunables or nil
end

-- the label's text on one line, its scale and its width at scale 1: a wide text shrinks to the label room, down to
-- LABEL_MIN_SCALE; what is still wider is squeezed into the box by the game, which is the label room at that scale
local function LabelLayout(instance, text)
  local line = (text:gsub("%s*[\r\n]+%s*", " "))
  local width = VRFW_Text.Measure(Crc(LAYER_LABEL), instance, Crc(LABEL_TEXT_NODE), line)
    or VRFW_Text.Units(line) * LABEL_UNIT_PX
  local room = layout ~= nil and layout.label_room or LABEL_ROOM_NO_CONFIG
  local scale = math.max(LABEL_MIN_SCALE, math.min(LABEL_SCALE, room / math.max(width, 1)))
  return line, scale, math.min(width, LABEL_BOX)
end

-- the plate's model build, in the retail banner's order; the model goes to the plate's capture cell and the portrait mesh
-- draws that cell. The mesh stays hidden until Step sees the model complete: an empty cell draws white. Returns the state
-- for the log; an error here costs the bust only.
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

-- once per frame while the screen is open: a bust's mesh shows when its model is complete and has had its settle frames
local function UpdateBusts()
  for plate_index, bust in pairs(busts) do
    if bust.complete or Menu(CMD_BUST_COMPLETE, bust.layer, bust.index, bust.plate.bust_slot) == true then
      bust.complete = true
      if bust.settle > 0 then
        bust.settle = bust.settle - 1
      else
        Menu(Crc("CMND_SET_MESH_VISIBLE"), bust.layer, Crc(bust.plate.portrait), true, bust.index)
        busts[plate_index] = nil
        Log(string.format("bust %s shown after %d frames", bust.plate.side, bust.frames))
      end
    end
    bust.frames = bust.frames + 1
  end
end

-- one line per opening: what the plates got
local function LogOpen()
  if open_logged or counters == nil then
    return
  end
  open_logged = true
  Log(string.format("opened: left chara 0x%08X bust %s, right chara 0x%08X bust %s", counters[1].chara,
    tostring(bust_states[1]), counters[2].chara, tostring(bust_states[2])))
end

-- the one display function of a counter: the plate's rules and its value. No value = the plate stays hidden.
local function ShowCounter(plate, index, value)
  local layer = Crc(plate.layer)
  if value <= 0 then
    Menu(Crc("CMND_SET_LAYER_VISIBLE"), layer, index, false)
    return
  end
  Menu(CMD_SUSPEND, layer, index, false)
  for _, prim in ipairs(PRIMS_HIDDEN) do
    Menu(CMD_PRIM_VISIBLE, layer, index, prim, false)
  end
  local total = Crc(PRIM_TOTAL)
  Menu(CMD_PRIM_VISIBLE, layer, index, total, true)
  local prim_index = Menu(Crc("CMND_SEARCH_PRIM_INDEX"), layer, index, total)
  if prim_index ~= nil then
    Menu(CMD_PRIM_VALUE, layer, index, prim_index, value)
  end
  Menu(CMD_NODE_VISIBLE, layer, Crc(BRECHA_BLOCK), false)
  Menu(CMD_NODE_VISIBLE, layer, Crc(plate.hide), false)
  Menu(CMD_NODE_VISIBLE, layer, Crc(plate.keep), true)
  Menu(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(plate.picture_label), false, index)
  Menu(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(plate.portrait), false, index)
  Menu(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(plate.placeholder), false, index)
  local number_x = layout ~= nil and layout[plate.number_x_key] or nil
  if number_x ~= nil then
    Menu(CMD_NODE_POSITION, layer, index, Crc(plate.number_node), 0, number_x)
  end
  local anime = Crc("CMND_PLAY_ANIME_TYPE")
  Menu(anime, layer, index, Crc("Open"), ANIME_FORWARD, ANIME_COMMON)
  Menu(anime, layer, index, Crc("Open"), ANIME_FORWARD, plate.anime)
end

local function HideLabel(instance)
  Menu(Crc("CMND_SET_LAYER_VISIBLE"), Crc(LAYER_LABEL), instance, false)
  labels[instance + 1] = nil
end

local function GlobalPosition(layer, index, node)
  local x, y = Menu(Crc("CMND_GET_MESH_GLOBAL_POSITION"), layer, index, node)
  if type(x) ~= "number" or type(y) ~= "number" then
    return nil
  end
  return x, y
end

-- the label layer's position -> its text node's global position (global = position * scale + offset, per axis), measured
-- once per opening with the hidden label 0. Called once per frame; true when known.
local function MeasurePositionMap()
  if position_map ~= nil then
    return position_map ~= false
  end
  local layer, node = Crc(LAYER_LABEL), Crc(LABEL_TEXT_NODE)
  if probe == nil then
    probe = { step = 0, wait = PROBE_WAIT }
    Menu(Crc("CMND_SET_LAYER_LOCAL_POS"), layer, 0, 0, 0, 0)
    return false
  end
  if probe.wait > 0 then
    probe.wait = probe.wait - 1
    return false
  end
  local x, y = GlobalPosition(layer, 0, node)
  if x == nil then
    position_map = false
    Log("label: no global position for its text node: labels off")
    return false
  end
  if probe.step == 0 then
    probe.x0, probe.y0, probe.step, probe.wait = x, y, 1, PROBE_WAIT
    Menu(Crc("CMND_SET_LAYER_LOCAL_POS"), layer, PROBE_STEP, PROBE_STEP, 0, 0)
    return false
  end
  local scale_x, scale_y = (x - probe.x0) / PROBE_STEP, (y - probe.y0) / PROBE_STEP
  if math.abs(scale_x) < 0.1 or math.abs(scale_y) < 0.1 then
    position_map = false
    Log("label: position does not move its text node: labels off")
    return false
  end
  position_map = { x = scale_x, y = scale_y, origin_x = probe.x0, origin_y = probe.y0 }
  return true
end

-- label `instance` under its plate's digits: the text's middle on the total's node, top on the plate's band. The text is
-- left-aligned in its box, so the box starts half the text's width before the middle. True once it is in place.
local function PlaceLabel(instance, plate, text)
  local map = position_map
  local layer = Crc(LAYER_LABEL)
  local node = Crc(LABEL_TEXT_NODE)
  local plate_layer = Crc(plate.layer)
  local centre_x = GlobalPosition(plate_layer, 0, Crc(plate.number_node))
  local _, target_y = GlobalPosition(plate_layer, 0, Crc(plate.slide))
  if centre_x == nil or target_y == nil then
    HideLabel(instance)
    return false
  end
  local label = labels[instance + 1]
  if label == nil then
    local shown_text, scale, width = LabelLayout(instance, text)
    local half_width = width * scale * math.abs(map.x) / 2
    for _, mesh in ipairs(LABEL_PLATE_MESHES) do
      Menu(Crc("CMND_SET_MESH_VISIBLE"), layer, Crc(mesh), false, instance)
    end
    Menu(Crc("CMND_SET_MENU_TEXT_STRING"), layer, node, shown_text, instance)
    Menu(Crc("CMND_SET_LAYER_LOCAL_SCALE"), layer, scale, scale, 1, instance)
    label = { x = (centre_x - half_width - map.origin_x) / map.x, y = (target_y - map.origin_y) / map.y, shown = false,
      wait = LABEL_SETTLE, half_width = half_width }
    labels[instance + 1] = label
    Menu(Crc("CMND_SET_LAYER_LOCAL_POS"), layer, label.x, label.y, 0, instance)
    return false
  end
  if label.wait > 0 then
    label.wait = label.wait - 1
    return false
  end
  local x, y = GlobalPosition(layer, instance, node)
  if x == nil then
    HideLabel(instance)
    return false
  end
  local error_x, error_y = centre_x - label.half_width - x, target_y - y
  if not label.shown and math.abs(error_x) <= LABEL_SNAP and math.abs(error_y) <= LABEL_SNAP then
    label.shown = true
    Menu(Crc("CMND_SET_LAYER_VISIBLE"), layer, instance, true)
  end
  if math.abs(error_x) > LABEL_DONE or math.abs(error_y) > LABEL_DONE then
    label.x = label.x + error_x / map.x
    label.y = label.y + error_y / map.y
    label.wait = LABEL_SETTLE
    Menu(Crc("CMND_SET_LAYER_LOCAL_POS"), layer, label.x, label.y, 0, instance)
    return false
  end
  return label.shown
end

-- true when no label needs more work
local function PlaceLabels()
  if not labels_open then
    return false
  end
  local layer = Crc(LAYER_LABEL)
  if Menu(Crc("CMND_IS_OPEN_LAYER"), layer) ~= true or Menu(Crc("CMND_IS_LOADING_LAYER"), layer) == true then
    return false
  end
  if not MeasurePositionMap() then
    return position_map == false
  end
  local done = true
  for i, plate in ipairs(PLATES) do
    local counter = counters[i]
    if counter.value > 0 and counter.text ~= "" and not PlaceLabel(i - 1, plate, counter.text) then
      done = false
    end
  end
  return done
end

function OnInit()
  counters, labels, position_map, probe = nil, {}, nil, nil
  layout, busts, bust_states, plates_opened, open_logged = nil, {}, {}, 0, false
  labels_open, labels_done, elapsed, close_asked = false, false, 0, false
end

function OnSetupLayer(layer, index)
end

function OnOpenLayer(layer, index)
  local i = (layer == Crc(PLATES[1].layer)) and 1 or (layer == Crc(PLATES[2].layer)) and 2 or nil
  if i ~= nil then
    ReadCounters()
    ShowCounter(PLATES[i], index or 0, counters[i].value)
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
      Menu(Crc("CMND_OPEN_LAYER_ARRAY"), Crc(LAYER_LABEL))
    end
  elseif layer == Crc(LAYER_LABEL) then
    Menu(Crc("CMND_SET_LAYER_VISIBLE"), layer, index or 0, false)
  end
end

function OnCloseLayer(layer, index)
  if layer == Crc(LAYER_LABEL) then
    Menu(Crc("CMND_SET_LAYER_VISIBLE"), layer, index or 0, false)
    return
  end
  for i, plate in ipairs(PLATES) do
    if layer == Crc(plate.layer) and counters ~= nil and counters[i].value > 0 then
      Menu(Crc("CMND_PLAY_ANIME_TYPE"), layer, index or 0, Crc("Open"), ANIME_REVERSE, plate.anime)
    end
  end
end

function Step()
  if counters ~= nil and not labels_done then
    labels_done = PlaceLabels()
  end
  UpdateBusts()
  local seconds = Game(CMD_FRAME_SECONDS)
  elapsed = elapsed + (type(seconds) == "number" and seconds or 0)
  if elapsed >= LOG_WAIT_SECONDS then
    LogOpen()
  end
  if elapsed >= MAX_SECONDS and not close_asked then
    close_asked = true
    Game(Crc("CMND_CLOSE_MENU_OBJECT"), Crc(SCREEN), true)
  end
end

function FinalizeMenu()
end
