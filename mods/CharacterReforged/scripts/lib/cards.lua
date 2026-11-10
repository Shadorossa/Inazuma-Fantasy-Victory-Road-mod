
local M = {}

local Id = VRFW.ids
M.u32 = Id.unsigned

M.hex = Id.hex_text

-- the save record of a character handle (nil = none)
function M.record(hdl)
  if not hdl or hdl == 0 then return nil end
  local ok, r = pcall(VRFW.character.record, hdl)
  if ok and type(r) == "table" and r.addr then return r end
  return nil
end

function M.param_of(hdl)
  local r = M.record(hdl)
  return r and M.u32(r.param) or nil
end

local FACTS = {}
function M.param_row(p)
  p = M.u32(p)
  if p == 0 then return nil end
  local cached = FACTS[p]
  if cached ~= nil then return cached or nil end
  local ok, c = pcall(VRFW.character.card, p)
  local row = false
  if ok and type(c) == "table" and M.u32(c.base) ~= 0 then
    row = { M.u32(c.base), tonumber(c.rarity) or 0, tonumber(c.element) or 0, tonumber(c.position) or 0 }
  end
  FACTS[p] = row
  return row or nil
end

function M.chara_of_param(p)
  local r = M.param_row(p)
  return r and r[1] or 0
end

-- every owned card { hdl, param }
function M.owned()
  local out = {}
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param" })
  if not ok or type(columns) ~= "table" then return out end
  for n, handle in ipairs(columns.handle) do
    local h, p = M.u32(handle), M.u32(columns.param[n])
    if h ~= 0 and p ~= 0 then out[#out + 1] = { h, p } end
  end
  return out
end

function M.card_arg(v)
  v = M.u32(v)
  if v == 0 or M.param_of(v) then return v end
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle" }, { param = v })
  if ok and type(columns) == "table" then
    for _, handle in ipairs(columns.handle) do
      if handle ~= 0 then return handle end
    end
  end
  return v
end

function M.fusion_partners()
  local out = {}
  local ok, s = pcall(VRFW.miximax.call, { op = "store" })
  local st = ok and type(s) == "table" and type(s[2]) == "table" and s[2] or nil
  for _, f in ipairs(st and st.fusions or {}) do
    local p = M.u32(f.partner_hdl)
    if p ~= 0 then out[p] = M.u32(f.base_hdl) end
  end
  return out
end

function M.slot()
  if VRFW.slots.ready() then return VRFW.slots.active() end
  return 1
end

return M
