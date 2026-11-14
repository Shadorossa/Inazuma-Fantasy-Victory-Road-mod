
CharacterReforged = CharacterReforged or {}

local Rules = require "lib/duplicate_players/rules"
local CardFacts = require "lib/duplicate_players/card_facts"
local MergePass = require "lib/duplicate_players/merge_pass"
local T = require "lib/duplicate_players/save_tree"

local REPORT_BLOB = "duplicate_players.txt"

local function log(message) VRFW.log("duplicate_players: " .. message) end
local function warn(message) VRFW.warn("duplicate_players: " .. message) end

local pending_reports = {}
local events_seen
do
  local ok, sequence = pcall(VRFW.slots.event_seq)
  events_seen = (ok and type(sequence) == "number") and sequence or 0
end

local function deliver_reports()
  local ok, sequence = pcall(VRFW.slots.event_seq)
  if not ok or type(sequence) ~= "number" then return end
  while events_seen < sequence do
    events_seen = events_seen + 1
    local ok_event, kind, first_slot, second_slot = pcall(VRFW.slots.event, events_seen)
    if ok_event and kind == "copied" and pending_reports[second_slot] then
      local text = pending_reports[second_slot]
      pending_reports[second_slot] = nil
      local ok_write, written, where = pcall(VRFW.save.set_blob, second_slot, REPORT_BLOB, text)
      if ok_write and written then
        log("COPY " .. first_slot .. "->" .. second_slot .. ": report written (blob " .. REPORT_BLOB .. ")")
      else
        warn("slot " .. second_slot .. ": " .. REPORT_BLOB .. " not written (" .. tostring(where) .. ")")
      end
    elseif ok_event and (kind == "deleted" or kind == "new_game") then
      pending_reports[first_slot] = nil
    end
  end
end

function CharacterReforged.DuplicatePolicy()
  return Rules.load()
end

VRFW.on("save:slot_copy", function(event)
  deliver_reports()
  local from, to = event.from, event.to
  local policy = Rules.load()
  if #policy.names == 0 then
    event.bytes = nil
    return nil
  end
  local tree, why = T.open_bytes(event.bytes)
  event.bytes = nil -- the save string is big: let it go
  if not tree then
    warn("COPY " .. from .. "->" .. to .. ": the save could not be read (" .. tostring(why) .. "): copy refused, slot " .. from .. " untouched")
    return { refuse = "Character Reforged: the save could not be read" }
  end
  local ok, report, outcome = pcall(function()
    return MergePass.run(tree, CardFacts.load(policy), policy)
  end)
  if not ok then
    warn("COPY " .. from .. "->" .. to .. ": the duplicate rules could not be applied (" .. tostring(report) .. "): copy refused, slot " .. from .. " untouched")
    return { refuse = "Character Reforged: the duplicate rules could not be applied" }
  end
  local merges = {}
  for _, merge in ipairs(outcome.merges) do
    merges[#merges + 1] = string.format("merge 0x%08X (card 0x%08X) -> kept 0x%08X (card 0x%08X)", merge.duplicate, merge.duplicate_card, merge.kept, merge.kept_card)
  end
  pending_reports[to] = string.format("slot %d -> slot %d\n%s\n\n%s\n\n== merges ==\n%s\n\n== players ==\n%s\n",
    from, to, Rules.describe(policy), MergePass.summary(report), table.concat(merges, "\n"), table.concat(report.lines, "\n"))
  log("COPY " .. from .. "->" .. to .. ": " .. Rules.describe(policy) .. "; " .. report.duplicates_merged .. " duplicates merged, "
    .. report.hidden_released .. " hidden cards released, " .. report.to_normal_rarity .. " normal cards to the normal rarity")
  if not tree:changed() then return nil end
  return { bytes = tree:commit() }
end)

local LOAD_REPORT_BLOB = "duplicate_players_load.txt"
local BACKUP_MARKER_BLOB = "duplicate_players_backup.txt"
local is_player_slot = Rules.is_player_slot

local function backup_once(slot)
  local ok_marker, marker = pcall(VRFW.save.get_blob, slot, BACKUP_MARKER_BLOB)
  if ok_marker and type(marker) == "string" and marker ~= "" then
    return { done = true, where = marker:match("^backup: ([^\n]+)") or "(see the marker)", earlier = true }
  end
  if type(VRFW.slots.read_file) ~= "function" then
    return { done = false, why = "this VRFW cannot read a slot's file (VRFW.slots.read_file)" }
  end
  local ok_read, bytes, why = pcall(VRFW.slots.read_file, slot)
  if not ok_read or type(bytes) ~= "string" or #bytes == 0 then
    return { done = false, why = "slot " .. slot .. " not read (" .. tostring(ok_read and why or bytes) .. ")" }
  end
  local ok_stamp, stamp = pcall(VRFW.time.file_stamp)
  if ok_stamp and type(stamp) == "string" then
    stamp = stamp:lower():gsub("[^%w%-]", "-")
  else
    stamp = tostring(VRFW.now_ms())
  end
  local name = string.format("save-backup-slot%d-%s-before-duplicate-rules.bin", slot, stamp)
  local size = #bytes
  local written, where = VRFW.save.doc.write_text(name, bytes, "global")
  bytes = nil
  if not written then
    return { done = false, why = "the copy " .. name .. " was not written (" .. tostring(where) .. ")" }
  end
  local text = string.format("backup: %s\nslot %d, %d bytes, before the first load pass of the duplicate rules (%s)\n",
    tostring(where), slot, size, stamp)
  pcall(VRFW.save.set_blob, slot, BACKUP_MARKER_BLOB, text)
  return { done = true, where = tostring(where) }
end

VRFW.on("save:slot_load", function(event)
  deliver_reports()
  local slot = event.slot
  if not event.has_data or not is_player_slot(slot) then return nil end
  local policy = Rules.load()
  if #policy.names == 0 or not policy.apply_on_load then return nil end
  -- A load keeps the duplicates a save holds unless the one-card rule itself asks to merge them on load.
  if not policy.merge_on_load then policy.one_card_per = nil end
  -- the game already holds this save (it applied it) and the slot is not writable: the pass runs at the next load of this slot
  if event.after_load then return nil end
  local tree, why = T.open(slot)
  VRFW.time.mark_step("save read")
  if not tree then
    warn("LOAD slot " .. slot .. ": the save could not be read (" .. tostring(why) .. "): the slot loads as it is")
    return nil
  end
  local ok, report, outcome = pcall(function()
    local facts = CardFacts.load(policy)
    VRFW.time.mark_step("card facts")
    return MergePass.run(tree, facts, policy)
  end)
  VRFW.time.mark_step("pass end")
  if not ok then
    warn("LOAD slot " .. slot .. ": the duplicate rules could not be applied (" .. tostring(report) .. "): the slot loads as it is")
    return nil
  end
  if not tree:changed() then
    log("LOAD slot " .. slot .. ": nothing to change (" .. report.players .. " players; " .. Rules.describe(policy) .. ")")
    return nil
  end
  local counts = report.to_normal_rarity .. " normal cards to rarity " .. tostring(policy.normal_card_rarity) .. ", "
    .. report.duplicates_merged .. " duplicates merged, " .. report.hidden_released .. " hidden cards released"
  local backup = backup_once(slot)
  if backup.done and not backup.earlier then
    log("LOAD slot " .. slot .. ": backup of the save before the duplicate rules -> " .. backup.where)
  elseif not backup.done then
    warn("LOAD slot " .. slot .. ": no durable backup (" .. backup.why .. "); the slot service's own backup (backups\\slot"
      .. slot .. ") holds the original")
  end
  local ok_commit, written = pcall(function() return tree:commit() end)
  if not ok_commit or not written then
    warn("LOAD slot " .. slot .. ": the save was not written (" .. tostring(ok_commit and "nothing written" or written)
      .. "): the slot loads as it is")
    return nil
  end
  log("LOAD slot " .. slot .. ": " .. Rules.describe(policy) .. "; " .. counts .. " (" .. report.players .. " players, "
    .. report.bytes_patched .. " bytes patched)")
  for _, line in ipairs(report.lines) do log("LOAD slot " .. slot .. ": " .. line) end
  local merges = {}
  for _, merge in ipairs(outcome.merges) do
    local line = string.format("duplicate removed: character 0x%08X kept 0x%08X (card 0x%08X) removed 0x%08X (card 0x%08X)",
      merge.character or 0, merge.kept, merge.kept_card, merge.duplicate, merge.duplicate_card)
    log("LOAD slot " .. slot .. ": " .. line)
    merges[#merges + 1] = line
  end
  local text = string.format("LOAD slot %d (backup: %s)\n%s\n\n%s\n\n== duplicates removed ==\n%s\n\n== players ==\n%s\n",
    slot, backup.done and backup.where or ("none: " .. backup.why), Rules.describe(policy), MergePass.summary(report),
    table.concat(merges, "\n"), table.concat(report.lines, "\n"))
  local ok_blob, blob_written, where = pcall(VRFW.save.set_blob, slot, LOAD_REPORT_BLOB, text)
  if not ok_blob or not blob_written then
    warn("slot " .. slot .. ": " .. LOAD_REPORT_BLOB .. " not written (" .. tostring(ok_blob and where or blob_written) .. ")")
  end
  return nil
end)

local one_card_rule = nil                 -- whether a duplicate rule declares one_card_per, read once

-- 1 while the loaded save keeps one card per player, else 0.
function CharacterReforged.OneCardPerPlayer()
  if one_card_rule == nil then
    one_card_rule = Rules.load().one_card_per ~= nil
  end
  local slot = VRFW.slots.ready() and VRFW.slots.active() or 0
  return one_card_rule and slot > 0 and is_player_slot(slot) and 1 or 0
end

local copy_policy = nil                  -- the merged duplicate policy, read once

-- The rarity a club copy saved at `rarity` of a card of special rarity `card_rarity` (chara_param col 41) holds in the loaded save: the rarity that, with the card, names one player.
function CharacterReforged.CopyRarity(rarity, card_rarity)
  if type(rarity) ~= "number" or type(card_rarity) ~= "number" then return rarity end
  if copy_policy == nil then copy_policy = Rules.load() end
  local slot = VRFW.slots.ready() and VRFW.slots.active() or 0
  if slot <= 0 or not is_player_slot(slot) then return rarity end
  return Rules.copy_rarity(copy_policy, rarity, card_rarity)
end
