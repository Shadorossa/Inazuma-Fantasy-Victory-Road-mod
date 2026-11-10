
local Id = VRFW.ids

local U = {}

local bxor = bit32.bxor
local floor = math.floor
local TWO32 = 4294967296
U.TWO32 = TWO32

U.u32 = Id.unsigned

-- an integer argument of a command (nil = default)
function U.int(v, default)
  if type(v) == "number" then
    return floor(v)
  end
  if v == true then
    return 1
  end
  if v == false then
    return 0
  end
  return default
end

U.hex = Id.hex_text

-- round half away from zero
U.round = VRFW.value.round

function U.rng(hi, lo)
  return VRFW.random.splitmix64(U.u32(hi), U.u32(lo))
end

function U.split64(n)
  n = floor(math.max(0, n or 0))
  return floor(n / TWO32) % TWO32, n % TWO32
end

function U.entropy(addr, n)
  local t = U.u32(VRFW.now_ms() * 1000003)
  local ah, al = U.split64(addr or 0)
  return bxor(ah, U.u32(n * 0x9E3779B9)), bxor(al, t)
end

local Memory = VRFW.memory
U.rd = Memory.read
U.rdp = Memory.read_pointer
U.wr = Memory.write
U.struct = Memory.struct
function U.get(view, name) return view and view[name] end
U.global = VRFW.game.global

function U.call(name, ...)
  return pcall(VRFW.call, name, ...)
end

-- a boolean / bool-like return value
function U.truthy(v)
  if type(v) == "boolean" then
    return v
  end
  return type(v) == "number" and v % 256 ~= 0
end

-- a value of the mod's merged config.toml (+ the loader's [BattleBayDeluxe] / [mods.BattleBayDeluxe]).
local CONFIG_MISSING = {}
function U.config(path, default)
  local v = VRFW.config(path)
  if v ~= nil then
    return v
  end
  if default ~= nil and not CONFIG_MISSING[path] then
    CONFIG_MISSING[path] = true
    VRFW.warn("config: config.toml has no " .. path .. ": the scripts' default " .. tostring(default) .. " is used")
  end
  return default
end

return U
