-- The codes the mods declare for the mailbox's «password» entry (content\redeem_codes\*.toml, [[VRFW.RedeemCode]]),
-- served to the game Lua by CMND_VRFW_REDEEM_CODE_FIND (content\game\redeem_codes.toml). The game Lua side is
-- assets\lua\menu\post_menu\100_redeem_codes.lua: the retail password dialog asks this script first and runs its own
-- flow (item check, items given, flag set, «obtained» windows) with the answer; an unknown code goes on to the game.
--
-- | Command | Args | Returns |
-- |---|---|---|
-- | CMND_VRFW_REDEEM_CODE_FIND | typed text | { FLAG = flag id, REWARDS = { { item id, count } … } }; nothing for an unknown code |
--
-- A code matches without case and without the spaces around it. The flag is a global bit flag the declaring mod lists
-- in its content\flags\ (the save keeps it): the game sets it when the rewards are given, so a code works once per save.

RedeemCodes = RedeemCodes or {}

local FOLDER = "content/redeem_codes"
local KIND = "VRFW.redeem_code/1"
local MAX_REWARDS = 2           -- rows the retail password dialog reads per code

local Id = require "VRFW/lib/ids"

local function warn(...) VRFW.warn("redeem_codes:", ...) end

local CODES = nil

-- a code as typed: no spaces around it, upper case
local function normal_code(text)
  if type(text) ~= "string" then return nil end
  local code = text:match("^%s*(.-)%s*$"):upper()
  if code == "" then return nil end
  return code
end

-- a game id: a number, "0x…" text, or a name (its crc32)
local function id_of(v)
  if type(v) == "number" then return Id.u32(v) end
  if type(v) ~= "string" or v == "" then return nil end
  if v:match("^0[xX]%x+$") then return Id.u32(tonumber(v)) end
  return VRFW.crc32(v)
end

local function build()
  local codes = {}
  local ok, files = pcall(VRFW.files.declarations, FOLDER)
  if not ok or type(files) ~= "table" then return codes end
  local count = 0
  for _, f in ipairs(files) do
    local data = type(f.data) == "table" and f.data or {}
    local where = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    if data.schema ~= KIND then
      warn(where .. ": schema " .. tostring(data.schema) .. " is not " .. KIND .. ": file left out")
    else
      local list = type(data.VRFW) == "table" and data.VRFW.RedeemCode or nil
      for _, e in ipairs(type(list) == "table" and list or {}) do
        local code = normal_code(e.code)
        local flag = id_of(e.flag)
        local rewards = {}
        for _, r in ipairs(type(e.rewards) == "table" and e.rewards or {}) do
          local item, n = id_of(r.item), math.floor(tonumber(r.count) or 0)
          if item ~= nil and n > 0 then rewards[#rewards + 1] = { item, n } end
        end
        local name = tostring(e.name)
        if code == nil or flag == nil or #rewards == 0 then
          warn(where .. ": " .. name .. ": needs code, flag and at least one reward: left out")
        elseif #rewards > MAX_REWARDS then
          warn(where .. ": " .. name .. ": more than " .. MAX_REWARDS .. " rewards: left out")
        elseif codes[code] ~= nil then
          warn(where .. ": " .. name .. ": code " .. code .. " already declared by " .. codes[code].NAME .. ": left out")
        else
          codes[code] = { NAME = name, FLAG = flag, REWARDS = rewards }
          count = count + 1
        end
      end
    end
  end
  if count > 0 then VRFW.log("redeem_codes:", count, "code(s)") end
  return codes
end

-- CMND_VRFW_REDEEM_CODE_FIND
function RedeemCodes.Find(text)
  if CODES == nil then CODES = build() end
  local code = normal_code(text)
  local entry = code and CODES[code] or nil
  if entry == nil then return nil end
  local rewards = {}
  for i, r in ipairs(entry.REWARDS) do rewards[i] = { r[1], r[2] } end
  return { FLAG = entry.FLAG, REWARDS = rewards }
end
