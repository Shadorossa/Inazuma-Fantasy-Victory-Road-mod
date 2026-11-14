-- Internal: Every menu that includes the formation screens (team dock, pre-match lineup, in-match formation) draws a declared synergy's detail with the framework's rows.
VRFW.synergy = VRFW.synergy or {}
local S = VRFW.synergy
--- Internal: state of the synergy detail panel in the formation screens.
S.formation = S.formation or {}
local W = S.formation

local DETAIL = 1473585342                  -- team16_02_synergy_item_detail
-- The include's two draws of this detail, (layer, item, team): the own team's and a viewed team's.
local DRAW = { [1150348853] = true, [2887296767] = true }

local function report(e)
  if S.err == nil then
    --- Internal: text of the first error of the synergy formation panel.
    S.err = tostring(e)
    VRFW.logger.new("VRFW synergy formation panel")("error", S.err)
  end
end

local function wrap(name, make)
  local cur = _G[name]
  if type(cur) ~= "function" or cur == W[name] then return end
  W[name] = make(cur)
  _G[name] = W[name]
end

-- The focused synergy button's detail: the game's draw first, then the framework's rows for the item it drew.
wrap("ChangeFocusToSynergyAttachmentButton", function(orig)
  return function(...)
    local real = funcLuaMenuCommand
    local item = 0
    funcLuaMenuCommand = function(cmd, layer, a, ...)
      if DRAW[cmd] and layer == DETAIL and type(a) == "number" then item = a end
      return real(cmd, layer, a, ...)
    end
    local r = table.pack(pcall(orig, ...))
    funcLuaMenuCommand = real
    if not r[1] then error(r[2], 0) end
    if S.apply_panel ~= nil then
      local ok, e = pcall(S.apply_panel, item)
      if not ok then report(e) end
    end
    return table.unpack(r, 2, r.n)
  end
end)

-- The detail hidden (the focus left the synergy buttons): the rows' extra pieces are turned off.
wrap("UnsetFocusSynergyAttachmentButton", function(orig)
  return function(...)
    local r = table.pack(orig(...))
    if S.hide_extras ~= nil then pcall(S.hide_extras) end
    return table.unpack(r, 1, r.n)
  end
end)

-- An instance of the rows' extra layers that is built is placed and shown (every including menu's OnOpenLayer calls this).
wrap("OnOpenLayerFormationCommon", function(orig)
  return function(a1, a2, ...)
    local r = table.pack(orig(a1, a2, ...))
    if S.built ~= nil then pcall(S.built, a1, a2) end
    return table.unpack(r, 1, r.n)
  end
end)
