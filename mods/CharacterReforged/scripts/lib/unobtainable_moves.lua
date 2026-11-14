
local Unobtainable = {}

local COLUMN_AURA_ID, COLUMN_AURA_TYPE = 1, 11

local SET = nil        -- [move id] = true
local COUNT = 0
local RULES = 0

local Id = VRFW.ids
local u32 = Id.unsigned

local function move_id(ref) return Id.parse(ref, { hash_names = true }) or 0 end

-- the [[VRFW.Unobtainable]] entries of every active mod (load order)
local function read_rules()
  local rules = {}
  local ok, declarations = pcall(VRFW.files.declarations, "content/techniques", { "VRFW.Unobtainable", "vrfw.Unobtainable" })
  for _, file in ipairs(ok and type(declarations) == "table" and declarations or {}) do
    local data = type(file) == "table" and file.data or nil
    local framework = type(data) == "table" and (data.VRFW or data.vrfw) or nil
    local list = type(framework) == "table" and framework.Unobtainable or nil
    for _, rule in ipairs(type(list) == "table" and list or {}) do
      if type(rule) == "table" then rules[#rules + 1] = rule end
    end
  end
  return rules
end

local function load()
  if SET then return SET end
  SET, COUNT = {}, 0
  local rules = read_rules()
  RULES = #rules
  if RULES == 0 then return SET end
  local types = {}
  local function add(id)
    if id ~= 0 and not SET[id] then
      SET[id] = true
      COUNT = COUNT + 1
    end
  end
  for _, rule in ipairs(rules) do
    for _, t in ipairs(type(rule.AuraTypes) == "table" and rule.AuraTypes or {}) do
      if type(t) == "number" then types[t] = true end
    end
    for _, ref in ipairs(type(rule.Techniques) == "table" and rule.Techniques or {}) do add(move_id(ref)) end
  end
  if next(types) ~= nil then
    local ok, rows = pcall(VRFW.table.raw, VRFW.table_files.file_name(VRFW.table_files.AURA_SKILL_CONFIG), "AURA_CMD_INFO", { COLUMN_AURA_ID, COLUMN_AURA_TYPE })
    if not ok or type(rows) ~= "table" then
      VRFW.warn("unobtainable moves: aura_skill_config unreadable: " .. tostring(rows))
    else
      for _, row in ipairs(rows) do
        local aura_type = row[COLUMN_AURA_TYPE]
        if type(aura_type) == "number" and types[aura_type % 256] then add(u32(row[COLUMN_AURA_ID])) end
      end
    end
  end
  VRFW.log(string.format("unobtainable moves: %d move(s) from %d rule(s)", COUNT, RULES))
  return SET
end

-- the move can never be a player's
function Unobtainable.has(move)
  return load()[u32(tonumber(move) or 0)] == true
end

-- [move id] = true of every such move
function Unobtainable.set()
  return load()
end

-- how many moves, how many rules
function Unobtainable.count()
  load()
  return COUNT, RULES
end

return Unobtainable
