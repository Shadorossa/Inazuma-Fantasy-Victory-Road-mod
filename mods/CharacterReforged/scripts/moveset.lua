
CharacterReforged = CharacterReforged or {}

local TECHNIQUES = 4
local SLOTS = 9
local AURA_SLOT = 9
local COL_FIRST = 11           -- slot k: move col 11 + 2 (k - 1), level col 12 + 2 (k - 1)

local LISTS = nil              -- [u32 card] = { {move, level} x 9 }
local MIX = nil                -- [u32 card] = aura command id

local Id = VRFW.ids
local u32 = Id.unsigned

local function load_lists()
  if LISTS then return LISTS end
  LISTS = {}
  local pos = { 1 }
  for k = 1, SLOTS do
    pos[#pos + 1] = COL_FIRST + 2 * (k - 1) + 1
    pos[#pos + 1] = COL_FIRST + 2 * (k - 1) + 2
  end
  local ok, rows = pcall(VRFW.table.raw, VRFW.table_files.file_name(VRFW.table_files.CHARA_PARAM), "CHARA_PARAM_INFO", pos)
  if not ok or type(rows) ~= "table" then
    VRFW.warn("moveset: chara_param unreadable: " .. tostring(rows))
    return LISTS
  end
  for _, r in ipairs(rows) do
    if type(r[1]) == "number" then
      local key = u32(r[1])
      if not LISTS[key] then
        local l = {}
        for k = 1, SLOTS do
          local m, lv = r[2 * k], r[2 * k + 1]
          l[k] = { u32(type(m) == "number" and m or 0), type(lv) == "number" and lv or 0 }
        end
        LISTS[key] = l
      end
    end
  end
  return LISTS
end

local function load_mix()
  if MIX then return MIX end
  MIX = {}
  local ok, decl = pcall(VRFW.files.declarations, "content/movesets")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local t = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.Mix or nil
    if type(t) == "table" then
      for k, v in pairs(t) do
        local c = tonumber(k)
        if c and type(v) == "number" then MIX[u32(c)] = u32(v)
        else VRFW.warn("moveset: [CharacterReforged.Mix] " .. tostring(k) .. " = " .. tostring(v) .. " ignored (\"<card id>\" = <aura command id>)") end
      end
    end
  end
  return MIX
end

function CharacterReforged.Moveset(id)
  local n = tonumber(id)
  if not n then return nil end
  local key = u32(n)
  local l = load_lists()[key]
  if not l then return nil end
  local out = { card = key, techniques = {} }
  for k = 1, SLOTS do
    if k ~= AURA_SLOT and l[k][1] ~= 0 and #out.techniques < TECHNIQUES then
      out.techniques[#out.techniques + 1] = { move = l[k][1], level = l[k][2] }
    end
  end
  if l[AURA_SLOT][1] ~= 0 then
    out.aura, out.aura_level = l[AURA_SLOT][1], l[AURA_SLOT][2]
  end
  out.mix = load_mix()[key]
  return out
end
