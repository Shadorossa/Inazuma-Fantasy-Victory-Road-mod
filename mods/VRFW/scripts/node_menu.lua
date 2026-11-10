-- Board node menus, script side (game Lua side: assets\lua\menu\_all\75_node_menu.lua; docs/framework/node-menu.md).

NodeMenu = NodeMenu or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("node_menu")

local BY_PIECE = nil     -- pieceId -> { handler, node, key, banner, rows }

local crc = VRFW.crc32

-- a declared row -> its answer (text / game ids, the level band); nil + why = left out
local function row_of(r)
  local text = D.id_of(r.text)
  if text == nil then return nil, "no text" end
  local out = { text = text, unlock = D.id_of(r.unlock or "") or 0, game = D.id_of(r.game or r.unlock or "") or 0,
    level = r.level or 0, min = 0, max = 0 }
  if r.levels ~= nil then
    local lo, hi = r.levels[1], r.levels[2]
    if #r.levels ~= 2 or lo > hi then return nil, "levels is not [lowest, highest]" end
    out.min, out.max = lo, hi
  end
  return out
end

local function load_menus()
  if BY_PIECE ~= nil then return BY_PIECE end
  BY_PIECE = {}
  local schema, why = D.schema("node_menu")
  if not schema then
    warn(why .. ": no node menu")
    return BY_PIECE
  end
  for _, d in ipairs(D.load(schema, warn)) do
    local v = d.v
    local where = string.format("mods/%s/%s", tostring(d.mod), tostring(d.file))
    if not tostring(v.handler):match("^[%a_][%w_]*$") and not tostring(v.handler):match("^[%a_][%w_]*%.[%a_][%w_]*$") then
      warn(where .. ": " .. d.key .. ": handler `" .. tostring(v.handler) .. "` is not a Lua name (`Name` or `Table.Name`): left out")
    else
      local rows = {}
      for i, r in ipairs(v.rows or {}) do
        local row, bad = row_of(r)
        if row == nil then
          warn(string.format("%s: %s: row %d: %s: left out", where, d.key, i, bad))
        else
          rows[#rows + 1] = row
        end
      end
      local n = 0
      for _, node in ipairs(v.nodes or {}) do
        local piece = crc("vrfw_node_piece_" .. node)
        local old = BY_PIECE[piece]
        if old ~= nil and old.key ~= d.key then
          warn(string.format("%s: node %s is %s's already: %s wins", where, node, old.key, d.key))
        end
        BY_PIECE[piece] = { handler = v.handler, node = node, key = d.key, banner = D.id_of(v.banner or "") or 0,
          rows = rows }
        n = n + 1
      end
      info(string.format("%s: %d node(s), %d row(s), handler %s", d.key, n, #rows, v.handler))
    end
  end
  return BY_PIECE
end

local function of_piece(piece)
  return load_menus()[math.floor(tonumber(piece) or 0) % 4294967296]
end

-- CMND_VRFW_NODE_MENU_OF_PIECE(pieceId) -> handler, node, key
function NodeMenu.OfPiece(piece)
  local m = of_piece(piece)
  if m == nil then return nil end
  return m.handler, m.node, m.key
end

function NodeMenu.Rows(piece)
  local m = of_piece(piece)
  if m == nil or #m.rows == 0 then return nil end
  local rows = {}
  for i, r in ipairs(m.rows) do
    rows[i] = { text = r.text, unlock = r.unlock, level = r.level, min = r.min, max = r.max, game = r.game }
  end
  return { handler = m.handler, node = m.node, key = m.key, banner = m.banner, rows = rows }
end

pcall(load_menus)
