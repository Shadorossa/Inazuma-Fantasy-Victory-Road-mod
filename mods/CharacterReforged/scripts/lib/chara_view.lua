-- A character's status object, save record, param block and effective level for the per-character stats and the training.

local M = {}

M.ERR_BAD_ARGS, M.ERR_NOT_READY, M.ERR_EXCEPTION, M.ERR_NO_RECORD = -1, -2, -4, -5

local OBJ_RECORD, OBJ_PARAMS, REC_PARAM_ID, REC_PRM_GROWTH = 0x08, 0x10, 0x04, 0x24
local PARAM_ARRAYS = { 0x10, 0x30, 0x50, 0x70, 0x90 }

local HBUF, FBUF

local Memory = VRFW.memory
local read_memory = Memory.read

local function bufs()
  if not HBUF then
    HBUF = VRFW.memory.buffer("character_reforged_stats_hdl", 8)
    FBUF = VRFW.memory.buffer("character_reforged_stats_flag", 8)
  end
end

function M.ready()
  return VRFW.is_on("Board.FindCharaRecord") and VRFW.is_on("Chara.HumanGetLevel")
    and VRFW.is_on("character_reforged_chara_containers")
end

-- the status object of a character handle checked against its record, or nil + error code
function M.object(hdl)
  local kind = math.floor(hdl / 4096) % 16
  if hdl == 0 or kind >= 0xD then return nil, M.ERR_BAD_ARGS end
  local conts = VRFW.game.character_reforged_chara_containers()
  if not conts then return nil, M.ERR_NOT_READY end
  local cont = read_memory("ptr", conts + 8 + kind * 8)
  if not cont or cont == 0 then return nil, M.ERR_NOT_READY end
  bufs()
  VRFW.memory.write("u32", HBUF, hdl)
  local ok, obj = pcall(VRFW.call, "Board.FindCharaRecord", cont, HBUF)
  if not ok then
    VRFW.error(string.format("stats: FindCharaRecord(0x%08X) raised: %s", hdl, tostring(obj)))
    return nil, M.ERR_EXCEPTION
  end
  if not obj or obj < 0x10000 then return nil, M.ERR_NO_RECORD end
  local rec = read_memory("ptr", obj + OBJ_RECORD)
  if not rec or read_memory("u32", rec) ~= hdl then return nil, M.ERR_NO_RECORD end
  return obj
end

-- the card (chara_param id) of a status object's record, or nil
function M.param_id(obj)
  local rec = read_memory("ptr", obj + OBJ_RECORD)
  return rec and read_memory("i32", rec + REC_PARAM_ID)
end

-- the record of a status object, or nil
function M.record(obj)
  return read_memory("ptr", obj + OBJ_RECORD)
end

-- the param block of a status object, or nil
function M.params(obj)
  return read_memory("ptr", obj + OBJ_PARAMS)
end

-- prm_growth[idx] of a save record (the trained points the menus add), or nil
function M.growth_of(rec, idx)
  return read_memory("i32", rec + REC_PRM_GROWTH + idx * 4)
end

-- { obj, rec, params, param_id } of a handle, or nil + error code
function M.view(hdl)
  local obj, e = M.object(hdl)
  if not obj then return nil, e end
  local rec = read_memory("ptr", obj + OBJ_RECORD)
  if not rec then return nil, M.ERR_NO_RECORD end
  local params = read_memory("ptr", obj + OBJ_PARAMS)
  if not params then return nil, M.ERR_NOT_READY end
  local pid = read_memory("i32", rec + REC_PARAM_ID)
  if not pid then return nil, M.ERR_NO_RECORD end
  return { obj = obj, rec = rec, params = params, param_id = pid }
end

-- the effective level of a status object, or nil + error code
function M.level(obj)
  bufs()
  local ok, v = pcall(VRFW.call, "Chara.HumanGetLevel", obj, FBUF)
  if not ok then
    VRFW.error(string.format("stats: GetLevel(0x%X) raised: %s", obj, tostring(v)))
    return nil, M.ERR_EXCEPTION
  end
  return v % 65536
end

function M.param_stat(params, idx)
  local b = read_memory("i32", params + PARAM_ARRAYS[1] + idx * 4)
  if b == nil then return nil end
  local sum = 0
  for _, a in ipairs(PARAM_ARRAYS) do
    local v = read_memory("i32", params + a + idx * 4)
    if v == nil then return nil end
    sum = sum + v
  end
  sum = sum % 4294967296
  if sum >= 2147483648 then sum = sum - 4294967296 end
  return b, sum
end

-- prm_growth[0..7] of a save record (Lua table 1..8), nil when unreadable
function M.prm_growth(rec)
  local g = {}
  for i = 0, 7 do
    local v = read_memory("i32", rec + REC_PRM_GROWTH + i * 4)
    if v == nil then return nil end
    g[i + 1] = v
  end
  return g
end

-- write prm_growth[0..7] and read it back
function M.write_prm_growth(rec, g)
  for i = 0, 7 do
    if not VRFW.memory.write("i32", rec + REC_PRM_GROWTH + i * 4, g[i + 1]) then return false end
  end
  local back = M.prm_growth(rec)
  if not back then return false end
  for i = 1, 8 do
    if back[i] ~= g[i] then return false end
  end
  return true
end

return M
