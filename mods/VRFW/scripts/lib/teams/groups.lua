
local M = {}

local GENDER = { male = 1, female = 2 }

local Id = VRFW.ids
local u32 = Id.unsigned

local function list_of(v) return VRFW.value.list(v, {}) end

local POOLS = nil

local function read()
  if POOLS then return POOLS end
  POOLS = {}
  local ok, files = pcall(VRFW.files.declarations, "content/synergies")
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local d = f.data or {}
    local v = type(d.VRFW) == "table" and d.VRFW or {}
    for _, p in ipairs(type(v.SynergyPool) == "table" and v.SynergyPool or {}) do
      if type(p.name) == "string" then
        local key = tostring(f.mod) .. "." .. p.name
        if not POOLS[key] then
          local x = { key = key, teams = {}, series = list_of(p.series), role = p.role, gender = GENDER[tostring(p.gender)],
            charas = {}, exclude = {} }
          for _, t in ipairs(list_of(p.teams)) do
            local id = Id.parse(t)
            if id then x.teams[#x.teams + 1] = id end
          end
          for _, c in ipairs(list_of(p.charas)) do
            local id = Id.character(c, { hash_names = true })
            if id then x.charas[#x.charas + 1] = id end
          end
          for _, c in ipairs(list_of(p.exclude)) do
            local id = Id.character(c, { hash_names = true })
            if id then x.exclude[#x.exclude + 1] = id end
          end
          POOLS[key] = x
        end
      end
    end
  end
  return POOLS
end

--- True when pool `key` exists.
function M.has_pool(key)
  return read()[key] ~= nil
end

--- the characters of a pool (evaluated once)
function M.members(key)
  local p = read()[key]
  if not p then return {} end
  if p.members then return p.members end
  local set = {}
  local include = {}
  if #p.charas > 0 then include[#include + 1] = { characters = p.charas } end
  if #p.teams > 0 or #p.series > 0 or p.role or p.gender then
    local series = {}
    for _, s in ipairs(p.series) do
      local ok, n = pcall(VRFW.character.series_of, s)
      series[#series + 1] = (ok and n) or s
    end
    include[#include + 1] = { team = #p.teams > 0 and p.teams or nil, series = #series > 0 and series or nil, role = p.role,
      gender = p.gender and { p.gender } or nil }
  end
  if #include > 0 then
    local spec = { include = include, exclude = #p.exclude > 0 and { { characters = p.exclude } } or nil }
    local ok, ids = pcall(VRFW.character.select, spec, { characters = true })
    if ok and type(ids) == "table" then
      for _, b in ipairs(ids) do set[u32(b)] = true end
    else
      -- the character index is not readable yet: asked again next time
      return set
    end
  end
  p.members = set
  return set
end

local GROUPS_OF = {}

--- the pools naming belong teams that hold character `base`
function M.groups_of(base)
  base = u32(base)
  local g = GROUPS_OF[base]
  if g then return g end
  g = {}
  for key, p in pairs(read()) do
    if #p.teams > 0 and M.members(key)[base] then g[key] = true end
  end
  GROUPS_OF[base] = g
  return g
end

return M
