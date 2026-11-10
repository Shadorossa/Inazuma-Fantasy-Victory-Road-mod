BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

if BetterUI.preset == nil then
  BetterUI.preset = "limpio"
end
BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, compact_cards = true, corner_buttons = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

@UI_WRAP@

BetterUI.flags.compact_cards = true
-- soccer_common
local PC_CMD_CARD_HDL = 3837561292      -- chara card by chara status handle (native 0xCC2590)
local PC_CMD_CARD_PARAM = 2339877830    -- chara card by chara param id (native 0xCC2080)
local PC_CMD_CARD_TABLE = 2329292196    -- chara card from a table {layerName, layerIdx, ...} (0xCC0BF0)
local PC_CMD_LEADER_SOCCER = 1000031904 -- leader card by soccer chara handle
local PC_CMD_LEADER_TEAM = 3550249130   -- leader card of the team
local PC_CMD_PRIM_VISIBLE = 1233047821  -- (layer, idx, prim, visible)
local PC_CMD_MESH_VISIBLE = 3405944500  -- (layer, mesh, visible, idx)
local PC_CMD_NODE_VISIBLE = 2158717427  -- (layer, node, visible, idx)
local PC_CMD_TEXT_VISIBLE = 1505208242  -- CMND_SET_MENU_TEXT_VISIBLE (layer, text, visible, idx)
local PC_CMD_PLAY_ANIME = 3781155141    -- CMND_PLAY_ANIME_TYPE (layer, idx, set, 0, type)
local PC_CMD_ANIME_RESET = 1586300804   -- (layer, idx, set, 1, 0)
local PC_CMD_MESH_POSE = 2373227714     -- CMND_GET_MESH_POSE (layer, idx, node) -> ok, x, y, z, ...
local PC_CMD_LAYER_NUM = 1175615627     -- CMND_GET_CREATE_LAYER_NUM (layer) -> instance count
local PC_TEXT_NAME = 170976702
local PC_NODE_MARK = 1726289776
local PC_NODE_MARK_PARENT = 3279539624
local PC_LAYER_SOCCER = 1973487846
-- the formation layers of a formation screen (the menu-count fallback of the layout test)
local PC_FORMATION_LAYERS = {
  [1973487846] = true, [1658289671] = true,
  [3241819447] = true
}
local PC_LV_MESHES = {1343488901, 1198450632, 1451641049, 1107078292}
local PC_LV_PRIMS = {
  3653219854, 3469038147, 3883528262, 97120277, 3238733729,
  1687159846, 1202218120, 3594422447, 3957043376, 1031695061
}
local PC_HIDDEN_MESH = {}
for _, v in ipairs(PC_LV_MESHES) do
  PC_HIDDEN_MESH[v] = true
end
local PC_LV_PRIM_SET = {}
for _, v in ipairs(PC_LV_PRIMS) do
  PC_LV_PRIM_SET[v] = true
end
-- functions of include/menu/soccer_formation_menu_inc that draw the formation member / leader cards
local PC_FORMATION_FUNCS = {
  "UpdateMemberCharaIconInfo", "UpdateMemberCharaIconInfoByChrParamId", "UpdateMemberCharaIconInfoByChrStHdl",
  "UpdateLeaderChara", "UpdateLeaderCharaBySoccerCharaHdl", "UpdateLeaderCharaByCharaParamId",
  "UpdateLeaderCharaByCharaStHdl"
}

-- one state per menu VM (soccer_common can be INCLUDEd more than once)
if BetterUI.player_cards == nil then
  BetterUI.player_cards = {
    layout = {},
    name = {},       -- "layer:idx" -> true while the name line is hidden
    hide = {},       -- "layer:idx" -> true while the level is hidden
    wrapped = {},    -- formation functions already wrapped
    form = 0,        -- depth inside the formation card functions
    formKeys = {}
  }
end
local PC = BetterUI.player_cards

local function PcKey(layer, idx)
  return tostring(layer) .. ":" .. tostring(idx or 0)
end

local function PoseY(call, layer, idx, node)
  local p = Pack(pcall(call, PC_CMD_MESH_POSE, layer, idx or 0, node))
  if p[1] and type(p[3]) == "number" then
    return p[3]
  end
  return nil
end

-- Returns whether the layer and card use the compact layout.
function BetterUI.player_card_is_compact(call, layer, idx)
  if not VRFW.player_card.is_formation_card_layer(layer) then
    return false
  end
  local lv = PC.layout[layer]
  if lv == nil then
    local my = PoseY(call, layer, idx, PC_NODE_MARK)
    local py = PoseY(call, layer, idx, PC_NODE_MARK_PARENT)
    if my == nil then
      lv = false
      if PC_FORMATION_LAYERS[layer] then
        local ok, n = pcall(call, PC_CMD_LAYER_NUM, PC_LAYER_SOCCER)
        lv = ok and type(n) == "number" and n >= 11 and n <= 19
      end
    else
      local d = my - (py or 0)
      lv = d > 500 or d < -500
    end
    PC.layout[layer] = lv
    UiLog("layout", layer, idx, my, py, lv)
  end
  return lv
end

function BetterUI.player_card_hide_name(call, layer, idx)
  PC.name[PcKey(layer, idx)] = true
  call(PC_CMD_TEXT_VISIBLE, layer, PC_TEXT_NAME, false, idx or 0)
  call(PC_CMD_NODE_VISIBLE, layer, PC_TEXT_NAME, false, idx or 0)
end

function BetterUI.player_card_keep_name(layer, idx)
  PC.name[PcKey(layer, idx)] = nil
end

-- Hides the level parts on one card.
local function HideParts(call, layer, idx)
  PC.hide[PcKey(layer, idx)] = true
  for m in pairs(PC_HIDDEN_MESH) do
    call(PC_CMD_MESH_VISIBLE, layer, m, false, idx or 0)
  end
  for _, pr in ipairs(PC_LV_PRIMS) do
    call(PC_CMD_PRIM_VISIBLE, layer, idx or 0, pr, false)
  end
end

-- Hides the level on one card of any layer, including cards drawn by another mod.
function BetterUI.player_card_hide_level(layer, idx)
  HideParts(funcLuaMenuCommand, layer, idx)
end

-- Re-applies the hidden parts after a card command.
local function AfterCard(call, layer, idx)
  if layer == nil then
    return
  end
  local key = PcKey(layer, idx)
  if PC.form > 0 and PC_FORMATION_LAYERS[layer] then
    PC.formKeys[#PC.formKeys + 1] = key
  end
  if BetterUI.player_card_is_compact(call, layer, idx) then
    BetterUI.player_card_hide_name(call, layer, idx)
    HideParts(call, layer, idx)
  else
    PC.name[key] = nil
    PC.hide[key] = nil
  end
end

local function PcFilter(orig, id, ...)
  if not UiOn("compact_cards") then
    return nil
  end
  if id == PC_CMD_CARD_HDL or id == PC_CMD_CARD_PARAM or id == PC_CMD_LEADER_SOCCER or id == PC_CMD_LEADER_TEAM then
    local layer, idx = ...
    local r = Pack(orig(id, ...))
    AfterCard(orig, layer, idx)
    return r
  elseif id == PC_CMD_CARD_TABLE then
    local t = ...
    local r = Pack(orig(id, ...))
    if type(t) == "table" then
      AfterCard(orig, t.layerName, t.layerIdx)
    end
    return r
  elseif id == PC_CMD_TEXT_VISIBLE then
    local a = Pack(...)
    if a[2] == PC_TEXT_NAME and a[3] == true and PC.name[PcKey(a[1], a[4])] then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == PC_CMD_NODE_VISIBLE then
    local a = Pack(...)
    if a[2] == PC_TEXT_NAME and a[3] == true and PC.name[PcKey(a[1], a[4])] then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == PC_CMD_MESH_VISIBLE then
    local a = Pack(...)
    if a[3] == true and PC_HIDDEN_MESH[a[2]] and PC.hide[PcKey(a[1], a[4])] then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == PC_CMD_PRIM_VISIBLE then
    local a = Pack(...)
    if a[4] == true and PC_LV_PRIM_SET[a[3]] and PC.hide[PcKey(a[1], a[2])] then
      a[4] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == PC_CMD_PLAY_ANIME or id == PC_CMD_ANIME_RESET then
    local layer, idx = ...
    local r = Pack(orig(id, ...))
    if PC.hide[PcKey(layer, idx)] then
      HideParts(orig, layer, idx)
    end
    return r
  end
  return nil
end
UiHookMenuCommand(PcFilter)

-- Applies the hidden parts to the formation cards.
local function ApplyFormationHide()
  local keys = PC.formKeys
  PC.formKeys = {}
  if not UiOn("compact_cards") or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  for _, key in ipairs(keys) do
    local sep = string.find(key, ":", 1, true)
    local layer = tonumber(string.sub(key, 1, sep - 1))
    local idx = tonumber(string.sub(key, sep + 1)) or 0
    if layer ~= nil and PC.layout[layer] == true then
      HideParts(funcLuaMenuCommand, layer, idx)
    end
  end
end

function BetterUI.player_card_wrap_formation()
  for _, name in ipairs(PC_FORMATION_FUNCS) do
    local f = rawget(_ENV, name)
    if type(f) == "function" and not PC.wrapped[f] then
      local w = function(...)
        PC.form = PC.form + 1
        local r = Pack(f(...))
        PC.form = PC.form - 1
        if PC.form <= 0 then
          PC.form = 0
          ApplyFormationHide()
        end
        return table.unpack(r, 1, r.n)
      end
      PC.wrapped[w] = true
      rawset(_ENV, name, w)
    end
  end
end
