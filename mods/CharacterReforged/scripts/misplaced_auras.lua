
local T = VRFW.save_tree
local PurgeMoves = require "lib/purge_moves"

local MARKER_BLOB = "misplaced_auras.txt"

local function log(message) VRFW.log("misplaced auras: " .. message) end
local function warn(message) VRFW.warn("misplaced auras: " .. message) end

-- [0-based board slot] = true for every aura_board_slots of the active mods
local function aura_slots()
  local list = nil
  local ok, decl = pcall(VRFW.files.declarations, "content/skill_set")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local t = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.SkillSet or nil
    if type(t) == "table" and type(t.aura_board_slots) == "table" then list = t.aura_board_slots end
  end
  if not list then return nil end
  local set = {}
  for _, v in ipairs(list) do
    local n = tonumber(v)
    if n then set[n] = true end
  end
  return set
end

local function is_aura(move)
  local ok, t = pcall(VRFW.extra_slot.aura_type, move)
  return ok and t ~= nil
end

local function is_player_slot(slot)
  local ok_locked, locked = pcall(VRFW.slots.locked)
  if ok_locked and locked == slot then return false end
  local ok_reserved, reserved = pcall(VRFW.slots.reserved, slot)
  return not (ok_reserved and reserved)
end

VRFW.on("save:slot_load", function(event)
  local slot = event.slot
  if not event.has_data or not is_player_slot(slot) then return nil end
  local ok_marker, marker = pcall(VRFW.save.get_blob, slot, MARKER_BLOB)
  if ok_marker and type(marker) == "string" and marker ~= "" then return nil end
  -- the game already holds this save and the slot is not writable: the check runs at the next load of this slot
  if event.after_load then return nil end
  local slots = aura_slots()
  if not slots then return nil end
  local tree, why = T.open(slot)
  if not tree then
    warn("slot " .. slot .. ": the save could not be read (" .. tostring(why) .. ")")
    return nil
  end
  local ok, report = pcall(PurgeMoves.misplaced_auras, tree, is_aura, slots)
  if not ok then
    warn("slot " .. slot .. ": not checked (" .. tostring(report) .. ")")
    return nil
  end
  if tree:changed() then
    local ok_commit, written = pcall(function() return tree:commit() end)
    if not ok_commit or not written then
      warn("slot " .. slot .. ": the save was not written (" .. tostring(ok_commit and "nothing written" or written) .. ")")
      return nil
    end
    log(string.format("slot %d: %d players, %d board slots, %d match moves emptied", slot, report.players, report.board, report.list))
    for _, line in ipairs(report.lines) do log("slot " .. slot .. ": " .. line) end
  end
  pcall(VRFW.save.set_blob, slot, MARKER_BLOB, string.format("checked: %d board slots, %d match moves emptied\n", report.board, report.list))
  return nil
end)
