-- VRFW route_board BEGIN VRFW
VRFW.route_board_commands = VRFW.route_board_commands or {}
VRFW.route_board_commands.STEM = "vs_route_town_command_select_menu"
VRFW.route_board_commands.LOCALS = {
  n2 = {function() return n2 end, function(v) n2 = v end},         -- the piece's save slot (statusFlagIndex)
  n4 = {function() return n4 end, function(v) n4 = v end},         -- the piece's game id
  n12 = {function() return n12 end, function(v) n12 = v end},      -- the parent menu (the board)
  t3 = {function() return t3 end, function(v) t3 = v end},         -- the menu's rows ({difficultyType, ...}, OnInit)
  flag = {function() return flag end, function(v) flag = v end},
  flag2 = {function() return flag2 end, function(v) flag2 = v end} -- the drop-rate window is open
}
VRFW.route_board_commands.L = setmetatable({}, {
  __index = function(_, k)
    local a = VRFW.route_board_commands.LOCALS[k]
    if a == nil then
      error("VRFW.route_board_commands.L: the command menu serves no local " .. tostring(k), 2)
    end
    return a[1]()
  end,
  __newindex = function(_, k, v)
    local a = VRFW.route_board_commands.LOCALS[k]
    if a == nil then
      error("VRFW.route_board_commands.L: the command menu serves no local " .. tostring(k), 2)
    end
    a[2](v)
  end
})

function VRFW.route_board_commands.rows(rows, kind, slot)
  if VRFW.node_menu ~= nil and VRFW.node_menu.rows_for ~= nil then
    local g = VRFW.node_menu.rows_for(slot, rows)
    if g ~= nil then
      return g
    end
  end
  if (VRFW.route_nodes ~= nil and VRFW.route_nodes.rows ~= nil) then
    return VRFW.route_nodes.rows(rows, slot)
  end
  return rows
end

function VRFW.route_board_commands.guide(item, icons, texts, cmds)
end

function VRFW.route_board_commands.service_piece()
  if VRFW.node_menu == nil or VRFW.node_menu.menu_of_slot == nil or VRFW.route_board_commands == nil or VRFW.route_board_commands.L == nil then
    return false
  end
  local ok, slot = pcall(function() return VRFW.route_board_commands.L.n2 end)
  return ok and type(slot) == "number" and VRFW.node_menu.menu_of_slot(slot) ~= nil
end

VRFW.route_board_commands.panel = VRFW.route_board_commands.panel or {extra = 0, bands = {}}
VRFW.route_board_commands.GEOMETRY = {FIRST_ROW_MID_Y = 442, ROW_STEP = 70, ROW_HALF_HEIGHT = 30, PANEL_MID_X = 436}

function VRFW.route_board_commands.list_layer(layer, kind, rows)
  local p = VRFW.route_board_commands.panel
  p.layer, p.kind, p.rows, p.extra, p.bands, p.reserved = layer, kind, rows, 0, {}, {}
  local ok, x, y = pcall(funcLuaMenuCommand, @crc:CMND_GET_LAYER_LOCAL_POS@, layer, 0)
  p.x = ok and type(x) == "number" and x or nil
  p.y = ok and type(y) == "number" and y or nil
end

function VRFW.route_board_commands.panel_extra(layer, kind, rows, extra)
  VRFW.route_board_commands.panel.extra = extra
end

-- Returns a band's height as laid out.
function VRFW.route_board_commands.band_height(p, id)
  local band = (p.bands or {})[id]
  local reserve = (p.reserved or {})[id]
  local h = band ~= nil and band.height or 0
  if reserve ~= nil and reserve.height > h then
    h = reserve.height
  end
  return h
end

function VRFW.route_board_commands.band_order(p, id)
  local band = (p.bands or {})[id] or (p.reserved or {})[id]
  return band ~= nil and band.order or 0
end

function VRFW.route_board_commands.bands_changed(p)
  local total, seen = 0, {}
  for _, list in ipairs({p.bands or {}, p.reserved or {}}) do
    for id in pairs(list) do
      if not seen[id] then
        seen[id] = true
        total = total + VRFW.route_board_commands.band_height(p, id)
      end
    end
  end
  if total == p.extra then
    return
  end
  if p.layer ~= nil then
    VRFW.route_board_commands.panel_extra(p.layer, p.kind, p.rows, total)
  else
    p.extra = total
  end
end

function VRFW.route_board_commands.panel_band(id, height, order)
  local p = VRFW.route_board_commands.panel
  p.bands = p.bands or {}
  local old = p.bands[id]
  height = height or 0
  order = order or 0
  if height <= 0 then
    if old == nil then
      return
    end
    p.bands[id] = nil
  elseif old ~= nil and old.height == height and old.order == order then
    return
  else
    p.bands[id] = {height = height, order = order}
  end
  VRFW.route_board_commands.bands_changed(p)
end

function VRFW.route_board_commands.panel_band_reserve(id, height, order)
  local p = VRFW.route_board_commands.panel
  p.reserved = p.reserved or {}
  if (height or 0) <= 0 then
    p.reserved[id] = nil
  else
    p.reserved[id] = {height = height, order = order or 0}
  end
  VRFW.route_board_commands.bands_changed(p)
end

function VRFW.route_board_commands.panel_band_top(id)
  local p = VRFW.route_board_commands.panel
  local g = VRFW.route_board_commands.GEOMETRY
  local y = g.FIRST_ROW_MID_Y + g.ROW_STEP * (math.max(p.rows or 1, 1) - 1) + g.ROW_HALF_HEIGHT
  local own = VRFW.route_board_commands.band_order(p, id)
  local seen = {[id] = true}
  for _, list in ipairs({p.bands or {}, p.reserved or {}}) do
    for other in pairs(list) do
      if not seen[other] then
        seen[other] = true
        local o = VRFW.route_board_commands.band_order(p, other)
        if o < own or (o == own and other < id) then
          y = y + VRFW.route_board_commands.band_height(p, other)
        end
      end
    end
  end
  return y
end

function VRFW.route_board_commands.panel_shift()
  local p = VRFW.route_board_commands.panel
  if p.layer == nil or p.x == nil or p.y == nil then
    return 0, 0
  end
  local ok, x, y = pcall(funcLuaMenuCommand, @crc:CMND_GET_LAYER_LOCAL_POS@, p.layer, 0)
  if not ok or type(x) ~= "number" or type(y) ~= "number" then
    return 0, 0
  end
  return x - p.x, y - p.y
end
-- VRFW route_board END
