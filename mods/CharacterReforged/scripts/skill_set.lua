
CharacterReforged = CharacterReforged or {}
local Unobtainable = require "lib/unobtainable_moves"

local BUILTIN = { moves_refuse_auras = true, aura_types = { 0, 3 }, mix_types = { 2, 6 } }
local RULES = nil
local PLACE = {}        -- name -> fn
local FAILED = {}

local info = VRFW.logger("skill set")

local function set_of(list)
  local s = {}
  for _, v in ipairs(type(list) == "table" and list or {}) do
    s[tonumber(v) or -1] = true
  end
  return s
end

function CharacterReforged.SkillSetRules()
  if RULES then return RULES end
  local r = {}
  for k, v in pairs(BUILTIN) do r[k] = v end
  local ok, decl = pcall(VRFW.files.declarations, "content/skill_set")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local t = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.SkillSet or nil
    if type(t) == "table" then
      for k, v in pairs(t) do r[k] = v end
    end
  end
  r.aura_set, r.mix_set = set_of(r.aura_types), set_of(r.mix_types)
  RULES = r
  return r
end

function CharacterReforged.AddPlaceRule(name, fn)
  if type(name) ~= "string" or name == "" or type(fn) ~= "function" then
    VRFW.warn("skill set: AddPlaceRule needs a name and a function")
    return false
  end
  PLACE[name] = fn
  FAILED[name] = nil
  info("place rule", name, "registered")
  return true
end

function CharacterReforged.RemovePlaceRule(name)
  PLACE[name] = nil
end

local function base_ok(slot, move)
  local r = CharacterReforged.SkillSetRules()
  local okT, t = pcall(VRFW.extra_slot.aura_type, move)
  if not okT then t = nil end
  if slot >= 1 and slot <= 6 then
    return not (r.moves_refuse_auras and t ~= nil)
  elseif slot == 7 then
    return t ~= nil and r.aura_set[t] == true
  elseif slot == 8 then
    return t ~= nil and r.mix_set[t] == true
  end
  return false
end

function CharacterReforged.CanPlace(hdl, slot, move)
  slot, move = tonumber(slot) or 0, tonumber(move) or 0
  if move == 0 then
    return true, ""                               -- emptying a slot is always allowed
  end
  if Unobtainable.has(move) then
    return false, "unobtainable"
  end
  if not base_ok(slot, move) then
    return false, "type"
  end
  local names = {}
  for n in pairs(PLACE) do names[#names + 1] = n end
  table.sort(names)
  for _, n in ipairs(names) do
    local ok, res, why = pcall(PLACE[n], hdl, slot, move)
    if not ok then
      if not FAILED[n] then
        FAILED[n] = true
        VRFW.warn("skill set: place rule " .. n .. " failed (allowed): " .. tostring(res))
      end
    elseif res == false then
      return false, (type(why) == "string" and why ~= "") and why or n
    end
  end
  return true, ""
end

local PRULES = nil
function CharacterReforged.PlaceRuleList()
  if PRULES then return PRULES end
  local m = {}
  local ok, decl = pcall(VRFW.files.declarations, "content/skill_set")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local t = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.PlaceRule or nil
    for _, r in ipairs(type(t) == "table" and t or {}) do
      if type(r) == "table" and type(r.name) == "string" then
        m[r.name] = m[r.name] or {}
        for k, v in pairs(r) do m[r.name][k] = v end
      end
    end
  end
  local out, names = {}, {}
  for name in pairs(m) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    local r = m[name]
    if r.off ~= true and type(r.command) == "string" and r.command:match("^CMND_[A-Z0-9_]+$") then
      local id = tonumber(VRFW.crc32(r.command)) or 0
      if id < 0 then id = id + 4294967296 end
      out[#out + 1] = { name = name, id = id, board = r.slot ~= "set" }
      info(string.format("place rule %s: command %s (slot argument %s)", name, r.command, r.slot ~= "set" and "board" or "set"))
    elseif r.off ~= true then
      VRFW.warn("skill set: place rule " .. tostring(name) .. ": command = \"CMND_…\" needed: left out")
    end
  end
  PRULES = out
  return out
end

function CharacterReforged.PlaceRulesCmd()
  local l = CharacterReforged.PlaceRuleList()
  local r = { #l }
  for _, x in ipairs(l) do
    r[#r + 1] = x.id
    r[#r + 1] = x.board and 1 or 0
  end
  return table.unpack(r)
end

VRFW.on("game_reset", function() RULES, PRULES = nil, nil end)
VRFW.on("slot_load", function()
  pcall(CharacterReforged.SkillSetRules)
  pcall(CharacterReforged.PlaceRuleList)
  pcall(Unobtainable.set)
  return nil
end)

-- CMND_CHARACTERREFORGED_CAN_PLACE(charaHdl, slot, move) -> ok, reason
function CharacterReforged.CanPlaceCmd(hdl, slot, move)
  local ok, res, why = pcall(CharacterReforged.CanPlace, hdl, slot, move)
  if not ok then
    VRFW.warn("skill set: CanPlace failed (allowed): " .. tostring(res))
    return true, ""
  end
  return res, why or ""
end
