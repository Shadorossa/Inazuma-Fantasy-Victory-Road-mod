-- EVT hud_layout, soccer_area_title_menu
BetterUI.hud_layout = BetterUI.hud_layout or {}
BetterUI = type(BetterUI) == "table" and BetterUI or {}
BetterUI.hud_layout.AREA_TITLE_SCALE = 0.61    -- ZONA / FOCO: text 29 / 48 = 0.60, bar 15 / 24 = 0.63
BetterUI.hud_layout.AREA_TITLE_DX = 0          -- fine tuning after the alignment (layout units, + = right)
BetterUI.hud_layout.AREA_TITLE_DY = 0          -- (+ = up)
BetterUI.hud_layout.ZONE_TITLE = true

local HLA_LAYER = 2169865486 --[[soccer00_14_area_title]]
local HLA_FOCO_TEXT_LEFT, HLA_FOCO_BAR_BOTTOM = -31 + 86, -143 - 74
local HLA_ZONE_TEXT_LEFT, HLA_ZONE_BAR_BOTTOM = -1 + 30, -146 - 51
local HLA_MESH_X, HLA_MESH_Y, HLA_MESH_W, HLA_MESH_H = -31, -143, 456, 76
local HLA_ZMESH_X, HLA_ZMESH_Y, HLA_ZMESH_W, HLA_ZMESH_H = -1, -146, 268, 52 -- soccer00_15 _zonearea_title01
local HLA_ZONE_TYPE = 3
local HLA_CMND_POS = @crc:CMND_SET_LAYER_LOCAL_POS@
local HLA_CMND_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@
local HLA_CMND_SWAP = 558735651
local HLA_ATLAS_15 = 1215532632 --[[#/menu/00_soccer/soccer00/soccer00_15/<LG>/soccer00_15.g4tx]]
local HLA_ZONE_SPRITE = 437059094 --[[title_zonearea01]]
local HLA_SLOT = 2491981732 --[[title_focus01: slot of _mode_title01]]
local hla_type = 0
local hla_sx, hla_sy = 1, 1       -- layer scale applied by HLA_Apply (1 = retail)

if BetterUI.hud_layout.ZONE_TITLE and type(BetterUI.flags) == "table" then
  BetterUI.flags.zone_hud = false
end

--@lib vrfw_menu_kit.lua#Pack

local function HLA_Apply()
  if type(funcLuaMenuCommand) ~= "function" then
    return
  end
  local sx, sy, x, y
  if hla_type == HLA_ZONE_TYPE and BetterUI.hud_layout.ZONE_TITLE then
    sx, sy = HLA_ZMESH_W / HLA_MESH_W, HLA_ZMESH_H / HLA_MESH_H
    x = HLA_ZMESH_X - sx * HLA_MESH_X
    y = HLA_ZMESH_Y - sy * HLA_MESH_Y
    pcall(funcLuaMenuCommand, HLA_CMND_SWAP, HLA_LAYER, HLA_ATLAS_15, HLA_ZONE_SPRITE, HLA_SLOT, 0, 0)
  else
    sx = BetterUI.hud_layout.AREA_TITLE_SCALE
    sy = sx
    x = HLA_ZONE_TEXT_LEFT - sx * HLA_FOCO_TEXT_LEFT + BetterUI.hud_layout.AREA_TITLE_DX
    y = HLA_ZONE_BAR_BOTTOM - sy * HLA_FOCO_BAR_BOTTOM + BetterUI.hud_layout.AREA_TITLE_DY
  end
  pcall(funcLuaMenuCommand, HLA_CMND_SCALE, HLA_LAYER, sx, sy, 1, 0)
  pcall(funcLuaMenuCommand, HLA_CMND_POS, HLA_LAYER, x, y, 0, 0)
  hla_sx, hla_sy = sx, sy
end

local function HLA_Wrap(name, onlyLayer, setsType)
  VRFW.host.wrap_once(name, "BetterUI.hud_layout.area_title", function(previous, a1, ...)
    if setsType then
      hla_type = type(a1) == "number" and a1 or 0
    end
    local r = Pack(previous(a1, ...))
    if not onlyLayer or a1 == HLA_LAYER then
      pcall(HLA_Apply)
    end
    return table.unpack(r, 1, r.n)
  end)
end

HLA_Wrap("OnSetupLayer", true, false)
HLA_Wrap("OnOpenLayer", true, false)
HLA_Wrap("SetupAreaTitle", false, true)

-- Time line settings.
BetterUI.hud_layout.TIMELINE_ON = true
BetterUI.hud_layout.TIMELINE_H = 5             -- line thickness, screen layout units
BetterUI.hud_layout.TIMELINE_LEN = 0.65        -- full-time length / the banner bar's width
BetterUI.hud_layout.TIMELINE_GAP = 1           -- gap between the banner's bar and the line
BetterUI.hud_layout.TIMELINE_DX = 0
BetterUI.hud_layout.TIMELINE_DY = 0            -- (+ = up)

local HLT_KEY = {[1] = 3795993759 --[[better_ui_hl_timeline_focus]], [2] = 2765993817 --[[better_ui_hl_timeline_scramble]],
  [3] = 1199734162 --[[better_ui_hl_timeline_zone]]}
-- Displayed sprite.
local HLT_SPR = {[1] = {456, 76, 74, 297}, [2] = {456, 76, 74, 385}, [3] = {456, 76, 74, 296}}
local HLT_SPR_ZONEAREA = {268, 52, 51, 257}
local HLT_TEX_PATH = "#/menu/00_soccer/better_ui/bui_hl_timeline.g4tx"
local HLT_TEX = 1693430560 --[[crc32 of HLT_TEX_PATH]]
local HLT_SPRITE = 1902106078 --[[bui_hl_timeline01: 528 x 16 px, opaque rows 3..12]]
local HLT_SLOT = 876725243 --[[gtxt_speed_low01: slot of _speed01]]
local HLT_MESH = 2750042957 --[[_speed01]]
local HLT_PARENT_Y = -14
local HLT_ROWS, HLT_ROW0, HLT_OPAQUE = 16, 3, 10
local HLT_QUAD_W, HLT_QUAD_END = 264, 262   -- sprite width / its slanted end's top corner, screen layout units
local HLT_CMND_IS_OPEN = @crc:CMND_IS_OPEN_LAYER@
local HLT_CMND_MESH_VIS = @crc:CMND_SET_MESH_VISIBLE@
local HLT_CMND_NODE_POS = 2575768773 --[[(layer, idx, node, axis 0 x / 1 y, value)]]
local HLT_CMND_NODE_SIZE = 2885415772 --[[(layer, idx, node, sx, sy): a mesh's size]]
-- The parameter store does not overwrite an existing key.
local hlt = {swapped = false, shown = nil, geo = nil, logs = 0}

local function HLT_Log(...)
  if hlt.logs < 20 and type(funcLuaCommand) == "function" then
    hlt.logs = hlt.logs + 1
    BetterUI.hud_layout.timeline_logger = BetterUI.hud_layout.timeline_logger or VRFW.logger.new("EVT hud_layout timeline")
    BetterUI.hud_layout.timeline_logger.debug(...)
  end
end

local function HLT_Show(on)
  if hlt.shown ~= on then
    funcLuaMenuCommand(HLT_CMND_MESH_VIS, HLA_LAYER, HLT_MESH, on, 0)
    hlt.shown = on
  end
end

local function HLT_Sprite()
  if hla_type == HLA_ZONE_TYPE and BetterUI.hud_layout.ZONE_TITLE then
    return HLT_SPR_ZONEAREA
  end
  return HLT_SPR[hla_type]
end

local function HLT_Step()
  if not BetterUI.hud_layout.TIMELINE_ON or type(funcLuaMenuCommand) ~= "function" or type(funcLuaCommand) ~= "function" then
    return
  end
  local key, spr = HLT_KEY[hla_type], HLT_Sprite()
  if key == nil or spr == nil then
    return
  end
  if funcLuaMenuCommand(HLT_CMND_IS_OPEN, HLA_LAYER) ~= true then
    hlt.swapped, hlt.shown, hlt.geo = false, nil, nil
    return
  end
  if not VRFW.textures.poll(HLT_TEX_PATH, VRFW.textures.SETTLED) then
    return
  end
  local v
  if VRFW.param.has(key) then
    v = VRFW.param.get(key)
  end
  hlt.nf = (hlt.seen == hla_type and (hlt.nf or 0) or 0) + 1
  if hlt.seen ~= hla_type then
    hlt.seen, hlt.logged = hla_type, false
  end
  if not hlt.logged and ((type(v) == "number" and v >= 0) or hlt.nf == 60) then
    hlt.logged = true
    HLT_Log("banner", hla_type, "rate", tostring(v), "after", hlt.nf, "frames")
  end
  if type(v) ~= "number" or v < 0 or v ~= v then
    HLT_Show(false)
    return
  end
  if not hlt.swapped then
    funcLuaMenuCommand(HLA_CMND_SWAP, HLA_LAYER, HLT_TEX, HLT_SPRITE, HLT_SLOT, 0, 0)
    hlt.swapped, hlt.geo = true, nil
  end
  local rate = math.max(0, math.min(1, v / 1000))
  local sx, sy = hla_sx, hla_sy
  local quad_h = BetterUI.hud_layout.TIMELINE_H / sy * HLT_ROWS / HLT_OPAQUE
  local bar_bottom = HLA_MESH_Y - HLA_MESH_H / spr[2] * spr[3]
  local line_top = bar_bottom - (BetterUI.hud_layout.TIMELINE_GAP - BetterUI.hud_layout.TIMELINE_DY) / sy
  local top = line_top + quad_h * HLT_ROW0 / HLT_ROWS
  local bar_left = HLA_MESH_X + BetterUI.hud_layout.TIMELINE_DX / sx
  local w = HLA_MESH_W / spr[1] * spr[4] * BetterUI.hud_layout.TIMELINE_LEN * rate   -- remaining width, layer units
  if w * sx < 0.5 then
    HLT_Show(false)
    return
  end
  local quad_w = HLT_QUAD_W / sx                      -- fixed size: the slant keeps its angle
  local left = bar_left + w - HLT_QUAD_END / sx       -- slanted end on the remaining width, the rest off screen
  local g = hlt.geo
  if g == nil or math.abs(g[1] - left) > 0.01 or g[2] ~= top or g[3] ~= quad_w or g[4] ~= quad_h then
    funcLuaMenuCommand(HLT_CMND_NODE_SIZE, HLA_LAYER, 0, HLT_MESH, quad_w, quad_h)
    funcLuaMenuCommand(HLT_CMND_NODE_POS, HLA_LAYER, 0, HLT_MESH, 0, left)
    funcLuaMenuCommand(HLT_CMND_NODE_POS, HLA_LAYER, 0, HLT_MESH, 1, top - HLT_PARENT_Y)
    hlt.geo = {left, top, quad_w, quad_h}
  end
  HLT_Show(true)
end

-- A new banner or set-up layer has the retail sprite back.
local function HLT_Reset(clearKeys)
  hlt.swapped, hlt.shown, hlt.geo, hlt.seen = false, nil, nil, nil
  if clearKeys and type(funcLuaCommand) == "function" then
    for _, k in pairs(HLT_KEY) do
      VRFW.param.clear(k)
      VRFW.param.set(k, -1, "plain")
    end
  end
end

local function HLT_Wrap(name, onlyLayer, clearKeys)
  local prev = rawget(_ENV, name)
  rawset(_ENV, name, function(...)
    local r = Pack()
    if type(prev) == "function" then
      r = Pack(prev(...))
    end
    local a1 = ...
    if not onlyLayer or a1 == HLA_LAYER then
      HLT_Reset(clearKeys and BetterUI.hud_layout.TIMELINE_ON)
    end
    if name == "PostStep" then
      local ok, err = pcall(HLT_Step)
      if not ok then
        HLT_Log("error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end)
end

if type(rawget(_ENV, "SetupAreaTitle")) == "function" then
  HLT_Wrap("SetupAreaTitle", false, true)
  HLT_Wrap("OnSetupLayer", true, false)
  HLT_Wrap("OnOpenLayer", true, false)
  HLT_Wrap("PostStep", true, false)
end
