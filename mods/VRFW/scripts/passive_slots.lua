-- Passive slot modes: every active mod's content/passive_slots/*.toml (`VRFW.passive_slots/1`).

PassiveSlots = PassiveSlots or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("passive_slots")

local KEY_OFF = "vrfw.passive.slots_off"
local KEY_ALL_OFF = "vrfw.passive.all_off"
local N_SLOTS = 5
local LIST_HANDLE_BASE, LIST_HANDLE_MASK = 0xE000, 0xFFFFF000

local MODES = {}               -- [[VRFW.SignatureOnly]]: { key, state }
local NO_PASSIVE_MODES = {}    -- [[VRFW.NoPassives]]: { key, state }
local PUBLISHED = {}           -- state key -> the value last written

local Id = VRFW.ids
local Passives = VRFW.passives
-- the bindings that answer slot 9 of a character handle
local LIVE_READERS = { id = "VRFW.SignatureSlotIdLive", open = "VRFW.SignaturePieceOpenLive" }
local function u32(v) return Id.unsigned_or(v, nil) end

local function load()
  local schema, why = D.schema("passive_slot_mode")
  if not schema then
    warn(tostring(why))
    return
  end
  local lists = { SignatureOnly = MODES, NoPassives = NO_PASSIVE_MODES }
  for _, d in ipairs(D.load(schema, warn)) do
    local list = lists[d.entry]
    if list and type(d.v.state) == "string" and d.v.state ~= "" then
      list[#list + 1] = { key = d.key, state = d.v.state }
    end
  end
  for entry, list in pairs(lists) do
    if #list > 0 then
      local names = {}
      for _, m in ipairs(list) do names[#names + 1] = m.key .. " (" .. m.state .. ")" end
      info(entry .. " modes: " .. table.concat(names, ", "))
    end
  end
end

local function running_of(list)
  for _, m in ipairs(list) do
    local ok, v = pcall(VRFW.state.get, m.state)
    if ok and tonumber(v) == 1 then return m end
  end
  return nil
end

local function running()
  return running_of(MODES)
end

local function publish_key(key, list, why)
  if #list == 0 then return end
  local m = running_of(list)
  local v = m and 1 or 0
  if v == PUBLISHED[key] then return end
  local ok, e = pcall(VRFW.state.set, key, v)
  if not ok then
    warn(key .. ": " .. tostring(e))
    return
  end
  PUBLISHED[key] = v
  info(string.format("%s = %d (%s%s)", key, v, why, m and (", " .. m.key) or ""))
end

local function publish(why)
  publish_key(KEY_OFF, MODES, why)
  publish_key(KEY_ALL_OFF, NO_PASSIVE_MODES, why)
end

-- CMND_GET_CHARA_TEAM_PASSIVE_INFO(hdl, slot, field, useCopy, preview): a real player's 5 rows read empty
function PassiveSlots.PlateInfo(h, slot, field)
  h, slot, field = u32(h), u32(slot), u32(field)
  if not (h and slot and field) or field > 2 or slot >= N_SLOTS then return false end
  if bit32.band(h, LIST_HANDLE_MASK) == LIST_HANDLE_BASE then return false end
  if running() == nil then return false end
  if field == 2 then return true, true, false end
  return true, true, 0
end

function PassiveSlots.CmdOff()
  return running() ~= nil
end

function PassiveSlots.CmdOwnPassive(hdl)
  hdl = u32(hdl)
  local on = running() ~= nil
  if not hdl or hdl == 0 then return 0, false, on end
  local id, open = Passives.own_passive(hdl, LIVE_READERS)
  return id, open, on
end

do
  local ok, e = pcall(load)
  if not ok then warn("declarations: " .. tostring(e)) end
end
if #MODES > 0 or #NO_PASSIVE_MODES > 0 then
  publish("start")
  for _, ev in ipairs({ "save:slot_load", "game:reset", "mode:enter", "mode:leave", "match:start" }) do
    VRFW.on(ev, function() publish(ev) end)
  end
end
