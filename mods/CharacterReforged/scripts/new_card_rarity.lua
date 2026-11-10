
local Rules = require "lib/duplicate_players/rules"

local HOOK = "CharacterReforged.SetRarity"
local HANDLE_KIND_UNIT = 4096   -- a handle's kind is its bits 12-15
local HANDLE_KINDS = 16
local KIND_CLUB = 0  -- saved club players only

local ok_rules, policy = pcall(Rules.load)
local rule_rarity = ok_rules and policy.normal_card_rarity or nil

local function applies_to_active_slot()
  local ok, slot = pcall(VRFW.slots.active)
  if not ok or type(slot) ~= "number" or slot <= 0 then return true end
  return Rules.is_player_slot(slot)
end

VRFW.on("hook:" .. HOOK, function(event)
  if rule_rarity == nil then return nil end
  local handle, rarity = event.args[2], event.args[3]
  if rarity == rule_rarity or math.floor(handle / HANDLE_KIND_UNIT) % HANDLE_KINDS ~= KIND_CLUB then return nil end
  if not applies_to_active_slot() then return nil end
  VRFW.log(string.format("new_card_rarity: handle 0x%08X: rarity %d -> %d", handle, rarity, rule_rarity))
  return { args = { [3] = rule_rarity } }
end)

if rule_rarity ~= nil then
  local ok, done, why = pcall(VRFW.hook.apply, HOOK)
  if not (ok and done == true) then
    VRFW.warn("new_card_rarity: detour not installed (" .. tostring(ok and why or done) .. "): only the load pass applies the rule")
  end
end
