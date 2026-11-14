BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, compact_cards = true, corner_buttons = true, enemy_meters = true, esc_guide = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

local function UiOn(flag)
  return BetterUI.flags[flag] == true
end

local function Pack(...)
  return { n = select("#", ...), ... }
end

-- Logs at most 30 UI messages.
local log_count = 0
local function UiLog(...)
  if log_count >= 30 then
    return
  end
  log_count = log_count + 1
  local parts = {}
  for i = 1, select("#", ...) do
    parts[#parts + 1] = tostring((select(i, ...)))
  end
  if type(funcLuaCommand) == "function" then
    VRFW.host.command(@crc:CMND_VRFW_LOG_DEBUG@, "BetterUI @TAG@ " .. table.concat(parts, " "))
  end
end

-- Runs filter(call, id, ...) on every funcLuaMenuCommand of this VM as an innermost VRFW.host command hook, so the
-- other hooks run outside it; call(id, ...) passes the same command on and runs another one on the function under
-- every hook; a nil answer passes the command on.
local function UiHookMenuCommand(filter)
  local function register(host)
    local real = host.real_menu_command
    host.hook_command("*", function(nxt, id, ...)
      local function call(command, ...)
        if command == id then
          return nxt(command, ...)
        end
        return real(command, ...)
      end
      local r = filter(call, id, ...)
      if r ~= nil then
        return table.unpack(r, 1, r.n)
      end
      return nxt(id, ...)
    end, "BetterUI.@TAG@", { menu = true, priority = host.INNERMOST })
  end
  if type(VRFW) == "table" and type(VRFW.host) == "table" and type(VRFW.host.hook_command) == "function" then
    register(VRFW.host)
  else
    -- The menu chunk runs before the Lua patch files: BetterUI's lua/_all/better_ui.lua registers the queue after VRFW's.
    BetterUI.command_hooks = BetterUI.command_hooks or {}
    BetterUI.command_hooks[#BetterUI.command_hooks + 1] = register
  end
end

-- Wraps a menu callback (OnSetupLayer, OnOpenLayer, ...) that the chunk already defined: `after` runs after it.
local function UiWrapCallback(name, after)
  local orig = rawget(_ENV, name)
  if type(orig) ~= "function" then
    return false
  end
  rawset(_ENV, name, function(...)
    local r = Pack(orig(...))
    local ok, err = pcall(after, ...)
    if not ok then
      UiLog("error", name, err)
    end
    return table.unpack(r, 1, r.n)
  end)
  return true
end

BetterUI.flags.compact_cards = true
-- soccer_common
local PC_CMD_CARD_HDL = 3837561292      -- chara card by chara status handle (native 0xCC2590)
local PC_CMD_CARD_PARAM = 2339877830    -- chara card by chara param id (native 0xCC2080)
local PC_CMD_CARD_TABLE = @crc:CMND_SPECIFY_CONTENT_BAR@    -- chara card from a table {layerName, layerIdx, ...} (0xCC0BF0)
local PC_CMD_LEADER_SOCCER = 1000031904 -- leader card by soccer chara handle
local PC_CMD_LEADER_TEAM = @crc:CMND_DELETE_RESULT_PHASE_GET@   -- leader card of the team
local PC_CMD_PRIM_VISIBLE = 1233047821  -- (layer, idx, prim, visible)
local PC_CMD_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@  -- (layer, mesh, visible, idx)
local PC_CMD_NODE_VISIBLE = 2158717427  -- (layer, node, visible, idx)
local PC_CMD_TEXT_VISIBLE = @crc:CMND_SET_MENU_TEXT_VISIBLE@  -- CMND_SET_MENU_TEXT_VISIBLE (layer, text, visible, idx)
local PC_CMD_PLAY_ANIME = @crc:CMND_PLAY_ANIME_TYPE@    -- CMND_PLAY_ANIME_TYPE (layer, idx, set, 0, type)
local PC_CMD_ANIME_RESET = 1586300804   -- (layer, idx, set, 1, 0)
local PC_CMD_MESH_POSE = @crc:CMND_GET_MESH_POSE@     -- CMND_GET_MESH_POSE (layer, idx, node) -> ok, x, y, z, ...
local PC_CMD_LAYER_NUM = @crc:CMND_GET_CREATE_LAYER_NUM@     -- CMND_GET_CREATE_LAYER_NUM (layer) -> instance count
local PC_TEXT_NAME = @crc:_text_chr01@
local PC_NODE_MARK = @crc:_pos_atc_free02@
local PC_NODE_MARK_PARENT = @crc:_pos_base02@
local PC_LAYER_SOCCER = @crc:team00_01_chara_card_for_soccer@
-- the formation layers of a formation screen (the menu-count fallback of the layout test)
local PC_FORMATION_LAYERS = {
  [@crc:team00_01_chara_card_for_soccer@] = true, [@crc:team00_01_chara_card_for_leader@] = true,
  [@crc:team00_01_chara_card_for_move@] = true
}
local PC_LV_MESHES = {@crc:_gtxt_lv_l01@, @crc:_gtxt_lv_s01@, @crc:_num_chr_dmy_l01@, @crc:_num_chr_dmy_s01@}
local PC_LV_PRIMS = {
  @crc:num_chr_l01@, @crc:num_chr_s01@, @crc:num_chr_l01_q@, @crc:num_chr_s01_q@, @crc:num_chr_l01_gray@,
  @crc:num_chr_s01_gray@, @crc:num_chr_l01_cup@, @crc:num_chr_s01_cup@, @crc:num_chr_l01_basara@, @crc:num_chr_s01_basara@
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
