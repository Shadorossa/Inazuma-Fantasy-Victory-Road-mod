
HissatsuReforged = HissatsuReforged or {}
HissatsuReforged.Families = HissatsuReforged.Families or {}
local Families = HissatsuReforged.Families

local FOLDERS = { "techniques", "content/techniques", "features/*/content/techniques" }

local cache = nil

local u32 = VRFW.ids.unsigned

local function text_key(t, mod)
  if t == "" then
    return ""
  end
  local ok, v = pcall(VRFW.text, t)
  if ok and v ~= nil and v ~= "" then
    return t
  end
  local rest = string.match(t, "^[^%.]+%.(.+)$")
  if rest ~= nil and mod ~= nil then
    local alt = tostring(mod) .. "." .. rest
    local ok2, v2 = pcall(VRFW.text, alt)
    if ok2 and v2 ~= nil and v2 ~= "" then
      return alt
    end
  end
  return t
end

local function load_all()
  if cache ~= nil then
    return cache
  end
  cache = { list = {}, by_key = {}, of_move = {} }
  local ok, files = pcall(VRFW.files.declarations, FOLDERS)
  if not ok or type(files) ~= "table" then
    VRFW.warn("technique families: the technique files could not be read: " .. tostring(files))
    return cache
  end
  for _, f in ipairs(files) do
    local v = type(f.data) == "table" and f.data.VRFW or nil
    local decls = type(v) == "table" and v.TechniqueFamily or nil
    for _, d in ipairs(type(decls) == "table" and decls or {}) do
      if type(d.name) == "string" and d.name ~= "" then
        local key = string.find(d.name, ".", 1, true) and d.name or (tostring(f.mod) .. "." .. d.name)
        local fam = { key = key, text = text_key(type(d.text) == "string" and d.text or "", f.mod),
          icon = type(d.icon) == "string" and d.icon or "", moves = {} }
        local at = cache.by_key[key]
        if at ~= nil then
          cache.list[at] = fam
        else
          cache.list[#cache.list + 1] = fam
          cache.by_key[key] = #cache.list
        end
      end
    end
  end
  for i, fam in ipairs(cache.list) do
    local okm, moves = pcall(VRFW.technique_family, fam.key)
    if okm and type(moves) == "table" then
      for _, id in ipairs(moves) do
        local m = u32(id)
        fam.moves[#fam.moves + 1] = m
        local of = cache.of_move[m]
        if of == nil then
          of = {}
          cache.of_move[m] = of
        end
        of[#of + 1] = i
      end
    end
  end
  return cache
end

-- the index is built when a slot loads (off the game thread), so the first move card does not build it
VRFW.on("slot_load", function()
  load_all()
end)

function Families.OfMove(move)
  local c = load_all()
  local out = { count = 0 }
  for _, i in ipairs(c.of_move[u32(move)] or {}) do
    local fam = c.list[i]
    local moves = {}
    for k, m in ipairs(fam.moves) do
      moves[k] = m
    end
    out.count = out.count + 1
    out[out.count] = { key = fam.key, text = fam.text, icon = fam.icon, count = #moves, moves = moves }
  end
  return out
end
