
-- SetupSoccereMenuCharaModel and GetMenuCharaCaptureCameraType for the busts
pcall(INCLUDE, "LUA_SOCCER_COMMON")

local COMMAND = "CMND_BETTERUI_DUEL_READOUT"
local SCREEN = "betterui_power_counter_menu"

local LABEL_ATTACKS = { true, false, true, false }   -- per label: the side attacks

-- what only this screen does with the plates (their layers and nodes: BetterUI.power_counter.PLATES)
local PLATES = {
  { anime = 949786159 --[[the left plate's slide group]], keep = "_pos_telop03_l", hide = "_pos_telop03_r",
    picture_label = "_gtxt_br_total_at01", portrait = "_icon_br_chr_dmy01", placeholder = "_num_br_total_at01_dmy01",
    label_end_key = "left_label_end_x", edge_key = "left_plate_edge", bust_slot = 0, bust_turn = 30, bust_key = "betterui_duel_bust_left", side = "left" },
  { anime = 2710947733 --[[the right plate's slide group]], keep = "_pos_telop03_r", hide = "_pos_telop03_l",
    picture_label = "_gtxt_br_total_at02", portrait = "_icon_br_chr_dmy02", placeholder = "_num_br_total_at02_dmy01",
    label_end_key = "right_label_end_x", edge_key = "right_plate_edge", bust_slot = 1, bust_turn = -30, bust_key = "betterui_duel_bust_right", side = "right" },
}

local ANIME_COMMON = 1154021400   -- the plates' common open group
local ANIME_FORWARD = 0
local ANIME_REVERSE = 2
local BRECHA_BLOCK = "_pos_telop02"
local PRIM_TOTAL = "num_br_total_at01"
-- every other number of the plates' objects (brecha / save percentages, the second total)
local PRIMS_HIDDEN = { 1219286211, 3517285753, 2795681263, 952508492, 1338052826, 3603448160, 1536362464,
  1502288020, 1883395192, 676188912, 2571853099, 2392932880, 3862398564 }

-- commands the retail plates use, without a known name
local CMD_SUSPEND = 734148104
local CMD_NODE_VISIBLE = 2158717427
local CMD_PRIM_VISIBLE = 1233047821
local CMD_PRIM_VALUE = 3609943765
local CMD_NODE_POSITION = 2575768773
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

local PC = nil                    -- BetterUI.power_counter (assets/lua/_all/power_counter.lua)
local counters = nil              -- per plate: { value, chara, attacks, critical }
local layout = nil                -- config.toml [duel_counter]; nil = the retail number place
local busts = {}
local bust_states = {}            -- per plate: what its bust setup did, for the log
local plates_opened = 0
local open_logged = false
local tags = nil                  -- the «critical» tags of this opening
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

-- The layout x where plate `i`'s total ends on the right: its first digit starts `digits_gap` px after the label.
local function DigitsEnd(i)
  return layout[PLATES[i].label_end_key] + layout.digits_gap + #tostring(counters[i].value) * layout.digit_width
end

-- The node x, in the plate's own units, that centres the total's digits between their start and DigitsEnd.
local function NumberNodeX(i)
  local centre = DigitsEnd(i) - #tostring(counters[i].value) * layout.digit_width / 2
  return (centre - layout[PLATES[i].edge_key]) / layout.plate_scale
end

-- The layout x where plate `i`'s content ends on the right of its total: the «critical» tag's right edge, or the total.
local function TagEnd(i)
  if counters[i].critical then
    return DigitsEnd(i) + layout.tag_gap + layout.tag_width * layout.tag_scale
  end
  return DigitsEnd(i)
end

-- The layout x of plate `i`'s inner and outer content edges at the retail place. The left plate's inner edge is the
-- rightmost of the ribbon's visible end, the total and its tag; the right plate's is its label or the ribbon's visible
-- start. The outer edges are the busts' outer edges, or the right plate's tag when it reaches further. All x are
-- layout px of soccer10_25, which is anchored to the screen centre.
local function InnerEdge(i)
  if i == 1 then
    return math.max(layout.left_ribbon_inner_x, TagEnd(1))
  end
  return math.min(layout.right_ribbon_inner_x, layout.right_label_inner_x)
end

local function OuterEdge(i)
  if i == 1 then
    return layout.left_plate_outer_x
  end
  return math.max(layout.right_plate_outer_x, TagEnd(2))
end

-- The distance from the screen centre to both plates' inner edges: `half_distance`, raised to the retail plates' outer
-- edges plus `plate_gap`, then lowered so the wider plate still fits in `layout_width`. It never drops below the retail
-- plates' outer edges, so the plates never cover them.
local function HalfDistance()
  local retail = math.max(-layout.left_plate_outer_x, layout.right_plate_outer_x)
  local widest = math.max(InnerEdge(1) - OuterEdge(1), OuterEdge(2) - InnerEdge(2))
  local fit = layout.layout_width / 2 - widest
  return math.max(math.min(math.max(layout.half_distance, retail + layout.plate_gap), fit), retail)
end

-- The layer x that puts plate `i`'s inner edge at minus (left) or plus (right) HalfDistance, so both plates mirror each
-- other about the centre line and a longer total grows outward. A layer's local position is in layout px with y up,
-- and y 0 keeps both plates on the retail line.
local function PlateShift(i)
  local half = HalfDistance()
  return (i == 1 and -half or half) - InnerEdge(i)
end

-- asked once per opening
local function ReadCounters()
  if counters ~= nil then
    return
  end
  local left_power, left_label, right_power, right_label, left_move, right_move, left_chara, right_chara = VRFW.host.command(Crc(COMMAND))
  local function counter(power, label, move, chara)
    chara = tonumber(chara) or 0
    return { value = tonumber(power) or 0, chara = chara, attacks = LABEL_ATTACKS[label] == true,
      critical = PC.Critical(chara, move) }
  end
  counters = { counter(left_power, left_label, left_move, left_chara), counter(right_power, right_label, right_move, right_chara) }
  local tunables = VRFW.host.command(Crc("CMND_BETTERUI_DUEL_PLATE_LAYOUT"))
  layout = type(tunables) == "table" and tunables or nil
  local critical = { counters[1].value > 0 and counters[1].critical, counters[2].value > 0 and counters[2].critical }
  if critical[1] or critical[2] then
    local ends = layout ~= nil and { DigitsEnd(1) + PlateShift(1), DigitsEnd(2) + PlateShift(2) } or nil
    tags = PC.NewTags(critical, layout, Log, ends)
  end
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

-- the plate's own open animation (it slides in from its side)
local function SlideIn(i, layer, index)
  local anime = Crc("CMND_PLAY_ANIME_TYPE")
  VRFW.host.menu_command(anime, layer, index, Crc("Open"), ANIME_FORWARD, ANIME_COMMON)
  VRFW.host.menu_command(anime, layer, index, Crc("Open"), ANIME_FORWARD, PLATES[i].anime)
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
  if layout ~= nil then
    VRFW.host.menu_command(CMD_NODE_POSITION, layer, index, Crc(PC.PLATES[i].number_node), 0, NumberNodeX(i))
    VRFW.host.menu_command(Crc("CMND_SET_LAYER_LOCAL_POS"), layer, PlateShift(i), 0, 0, index)
  end
  SlideIn(i, layer, index)
end

function OnInit()
  PC = BetterUI.power_counter
  counters, tags = nil, nil
  layout, busts, bust_states, plates_opened, open_logged = nil, {}, {}, 0, false
  elapsed, close_asked = 0, false
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
  elseif layer == Crc(PC.TAG_LAYER) then
    VRFW.host.menu_command(Crc("CMND_SET_LAYER_VISIBLE"), layer, index or 0, false)
  end
end

function OnCloseLayer(layer, index)
  if layer == Crc(PC.TAG_LAYER) then
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
