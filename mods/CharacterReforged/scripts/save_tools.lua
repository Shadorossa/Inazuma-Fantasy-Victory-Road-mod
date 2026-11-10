
local Rules = require "lib/duplicate_players/rules"
local CardFacts = require "lib/duplicate_players/card_facts"
local MergePass = require "lib/duplicate_players/merge_pass"
local Unobtainable = require "lib/unobtainable_moves"
local PurgeMoves = require "lib/purge_moves"
local PurgeKits = require "lib/purge_kits"
local Id = VRFW.ids

local PLAYER_SETS_BLOB = "ss_player_sets.json"

local function log(message) VRFW.log("save adjust: " .. message) end

-- a shallow copy of the merged policy with some keys changed (`false` = the key removed)
local function policy_with(changes)
  local policy = {}
  for key, value in pairs(Rules.load()) do policy[key] = value end
  for key, value in pairs(changes) do
    if value == false then policy[key] = nil else policy[key] = value end
  end
  return policy
end

local function run_pass(tree, policy, action)
  local report = MergePass.run(tree, CardFacts.load(policy), policy)
  log(action .. ": " .. Rules.describe(policy) .. "; " .. MergePass.summary(report))
  for _, line in ipairs(report.lines) do log(action .. ": " .. line) end
  return report
end

CharacterReforged = CharacterReforged or {}
local SaveAdjust = {}
CharacterReforged.SaveAdjust = SaveAdjust

function SaveAdjust.can_remove_duplicates()
  local policy = Rules.load()
  return #policy.names > 0 and policy.one_card_per ~= nil
end

function SaveAdjust.remove_duplicates(tree, event)
  local policy = policy_with({ normal_card_rarity = false, normal_special_rarities = false })
  if policy.one_card_per == nil then return { error = "no duplicate rule declares one_card_per" } end
  local report = run_pass(tree, policy, "remove_duplicates (slot " .. event.slot .. ")")
  return { count = report.duplicates_merged, log = report.duplicates_merged .. " duplicates merged, " .. report.hidden_released
    .. " hidden cards released, " .. (report.protected or 0) .. " kept (not retirable / not signed)" }
end

function SaveAdjust.can_set_normal_rarity()
  local policy = Rules.load()
  if #policy.names == 0 or policy.normal_card_rarity == nil then return false end
  return policy.normal_rarity_label or true
end

function SaveAdjust.normal_rarity(tree, event)
  local policy = policy_with({ one_card_per = false, hidden_card_sources = {}, convert_special_cards = true })
  if policy.normal_card_rarity == nil then return { error = "no duplicate rule declares normal_card_rarity" } end
  policy.raise_every_saved_player = policy.save_adjust_every_saved_player == true
  local report = run_pass(tree, policy, "normal_rarity (slot " .. event.slot .. ")")
  return { count = report.to_normal_rarity + report.duplicates_merged, log = report.to_normal_rarity .. " cards -> rarity "
    .. tostring(policy.normal_card_rarity) .. " (" .. report.to_base_card .. " special cards -> their base card), "
    .. report.duplicates_merged .. " copies merged, " .. (report.protected or 0) .. " kept (not retirable / not signed)" }
end

local function purge_player_sets(slot, drop, action)
  local ok, text = pcall(VRFW.save.get_blob, slot, PLAYER_SETS_BLOB)
  if not ok or type(text) ~= "string" or text == "" then return 0 end
  local decoded, file = pcall(VRFW.json.decode, text)
  if not decoded or type(file) ~= "table" or type(file.players) ~= "table" then
    log(action .. ": " .. PLAYER_SETS_BLOB .. " not readable: left as it is")
    return 0
  end
  local u32 = Id.unsigned
  local n = 0
  for _, player in pairs(file.players) do
    for _, set in pairs(type(player) == "table" and type(player.sets) == "table" and player.sets or {}) do
      if type(set) == "table" then
        if type(set.moves) == "table" then
          for k, move in pairs(set.moves) do
            if drop("moves", u32(move)) then set.moves[k] = 0; n = n + 1 end
          end
        end
        for _, field in ipairs({ "hiper", "kit" }) do
          if set[field] ~= nil and drop(field, u32(set[field])) then set[field] = 0; n = n + 1 end
        end
      end
    end
  end
  if n > 0 then
    local encoded, out = pcall(VRFW.json.encode, file)
    local written, why = false, out
    if encoded then written, why = pcall(VRFW.save.set_blob, slot, PLAYER_SETS_BLOB, out) end
    if not encoded or not written or why == false then
      error(PLAYER_SETS_BLOB .. " of slot " .. tostring(slot) .. " not written: " .. tostring(why))
    end
    log(action .. ": " .. n .. " player set value(s) emptied in " .. PLAYER_SETS_BLOB)
  end
  return n
end

function SaveAdjust.can_remove_unobtainable_moves()
  local moves = Unobtainable.count()
  return moves > 0
end

function SaveAdjust.remove_unobtainable_moves(tree, event)
  local moves = Unobtainable.set()
  if next(moves) == nil then return { error = "no [[VRFW.Unobtainable]] rule names a move" } end
  local action = "remove_unobtainable_moves (slot " .. event.slot .. ")"
  local report = PurgeMoves.run(tree, moves)
  log(action .. ": " .. PurgeMoves.summary(report))
  for _, line in ipairs(report.lines) do log(action .. ": " .. line) end
  local sets = purge_player_sets(event.slot, function(field, value) return field ~= "kit" and moves[value] == true end, action)
  local count = report.removed + sets
  return { count = count, log = count .. " move(s) removed from the players (" .. PurgeMoves.summary(report) .. "; " .. sets .. " in player sets)" }
end

function SaveAdjust.can_remove_hidden_kits()
  local ok, facts = pcall(PurgeKits.facts)
  return ok and facts ~= nil and facts.count > 0
end

local function hidden_kit_value(facts, value)
  if facts.by_item[value] then return true end
  for _, kit in pairs(facts.by_item) do
    if kit.uniform ~= 0 and kit.uniform == value then return true end
  end
  return false
end

function SaveAdjust.remove_hidden_kits(tree, event)
  local facts, why = PurgeKits.facts()
  if not facts then return { error = why } end
  if facts.count == 0 then return { error = "no active mod hides a kit" } end
  local action = "remove_hidden_kits (slot " .. event.slot .. ")"
  local report, not_removed = PurgeKits.run(tree, facts)
  if not report then return { error = not_removed } end
  log(action .. ": " .. PurgeKits.summary(report))
  for _, line in ipairs(report.lines) do log(action .. ": " .. line) end
  local sets = purge_player_sets(event.slot, function(field, value) return field == "kit" and hidden_kit_value(facts, value) end, action)
  local count = report.removed + sets
  return { count = count, log = count .. " kit(s) removed (" .. PurgeKits.summary(report) .. "; " .. sets .. " in player sets)" }
end
