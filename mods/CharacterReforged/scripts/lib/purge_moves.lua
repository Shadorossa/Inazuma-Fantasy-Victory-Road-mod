
local T = require "lib/duplicate_players/save_tree"

local PurgeMoves = {}

local BOARD_SLOTS = 9
local BLOCK_INVENTORY, BLOCK_CHARACTERS, BLOCK_TEAMS = 4, 5, 7

local function element(array, count, i)
  if array and i < count then return T.at(array, i) end
  return nil
end

local function characters(tree)
  local permanent = T.unwrap(tree, "block5", "m_Permanent")
  local out = {}
  local humans = T.kids(tree, permanent, "m_saveHumanP")
  if humans then
    local handles = T.words(T.leaf(tree, humans, "handle") or "")
    local lists, list_count = T.array(tree, humans, "skill_list")
    local placed, placed_count = T.array(tree, humans, "skillEquipInvInfo")
    local native, native_count = T.array(tree, humans, "skillEquipInvInfoOverWrite")
    for i0, handle in ipairs(handles) do
      local i = i0 - 1
      if handle ~= 0 then
        local list_element = element(lists, list_count, i)
        out[#out + 1] = {
          label = "m_saveHumanP[" .. i .. "]", handle = handle,
          placed = element(placed, placed_count, i), native = element(native, native_count, i),
          list = list_element and T.array(tree, list_element, "skill_list") or nil,
        }
      end
    end
  end
  local function record(path, label)
    local handle = T.number(tree, path, "handle") or 0
    if handle ~= 0 then
      out[#out + 1] = {
        label = label, handle = handle, placed = T.kids(tree, path, "skillEquipInvInfo"),
        native = T.kids(tree, path, "skillEquipInvInfoOverWrite"), list = T.array(tree, path, "skill_list"),
      }
    end
  end
  local guest = T.kids(tree, permanent, "m_stGuestP")
  if guest then record(guest, "m_stGuestP") end
  for _, name in ipairs({ "m_stEditP", "m_stStoryScoutP" }) do
    local array, count = T.array(tree, permanent, name)
    for i = 0, (count or 0) - 1 do record(T.at(array, i), name .. "[" .. i .. "]") end
  end
  return out
end

-- every team of block 7 (every team set, every team)
local function teams(tree)
  local out = {}
  local permanent = T.unwrap(tree, "block7", "m_InfoPermanent")
  local sets, set_count = T.array(tree, T.kids(tree, permanent, "teamSetList"), "m_buffer")
  for s = 0, (set_count or 0) - 1 do
    local team_list, team_count = T.array(tree, T.at(sets, s), "teamInfoList")
    for k = 0, (team_count or 0) - 1 do out[#out + 1] = { path = T.at(team_list, k), label = s .. "/" .. k } end
  end
  return out
end

local Id = VRFW.ids
local hex = Id.hex_text

function PurgeMoves.run(tree, moves)
  for _, id in ipairs({ BLOCK_INVENTORY, BLOCK_CHARACTERS, BLOCK_TEAMS }) do
    if not T.has_block(tree, id) then error("block " .. id .. " not found") end
  end
  local P = T.patches(tree)
  local report = { players = 0, board = 0, list = 0, team_auras = 0, stacks = 0, removed = 0, bytes_patched = 0, lines = {} }

  local inventory = T.unwrap(tree, "block4", "m_Permanent")
  local stacks, stack_count = T.array(tree, inventory, "invSkill")
  if not stacks then error("invSkill not found in block 4") end
  local move_of, purged_stacks = {}, {}
  for i = 0, stack_count - 1 do
    local stack = T.at(stacks, i)
    local handle, move = T.number(tree, stack, "handle"), T.number(tree, stack, "item_id")
    if handle and handle ~= 0 and move then
      move_of[handle] = move
      if moves[move] then purged_stacks[#purged_stacks + 1] = { stack, move } end
    end
  end

  for _, character in ipairs(characters(tree)) do
    local removed = {}
    for _, board in ipairs({ character.placed or false, character.native or false }) do
      if board then
        for k = 0, BOARD_SLOTS - 1 do
          local path = board .. ".specialSkill_" .. k
          local handle = T.number(tree, board, "specialSkill_" .. k)
          local move = handle and handle ~= 0 and move_of[handle] or nil
          if move and moves[move] then
            P:set(path, handle, 0)
            report.board = report.board + 1
            removed[#removed + 1] = "board slot " .. (k + 1) .. " " .. hex(move)
          end
        end
      end
    end
    if character.list then
      for k = 0, tree:get(character.list).len - 1 do
        local entry = T.at(character.list, k)
        local move = T.number(tree, entry, "id_crc")
        if move and moves[move] then
          P:set(entry .. ".id_crc", move, 0)
          local rank, ai = T.number(tree, entry, "skillRank"), T.number(tree, entry, "isUnusableAI")
          if rank then P:set(entry .. ".skillRank", rank, 0) end
          if ai then P:set(entry .. ".isUnusableAI", ai, 0) end
          report.list = report.list + 1
          removed[#removed + 1] = "match move " .. (k + 1) .. " " .. hex(move)
        end
      end
    end
    if #removed > 0 then
      report.players = report.players + 1
      report.lines[#report.lines + 1] = string.format("0x%08X %s: %s", character.handle, character.label, table.concat(removed, ", "))
    end
  end

  -- team aura entries
  for _, team in ipairs(teams(tree)) do
    local auras, aura_count = T.array(tree, team.path, "auraSkillSlotInfoList")
    for k = 0, (aura_count or 0) - 1 do
      local entry = T.at(auras, k)
      local holder, move = T.number(tree, entry, "charaStHdl"), T.number(tree, entry, "skillId")
      if move and moves[move] then
        if holder then P:set(entry .. ".charaStHdl", holder, 0) end
        P:set(entry .. ".skillId", move, 0)
        report.team_auras = report.team_auras + 1
        report.lines[#report.lines + 1] = string.format("team %s aura entry %d: %s of 0x%08X emptied", team.label, k + 1, hex(move), holder or 0)
      end
    end
  end

  -- the stacks themselves (no reference is left)
  for _, entry in ipairs(purged_stacks) do
    P:zero(entry[1])
    report.stacks = report.stacks + 1
    report.lines[#report.lines + 1] = string.format("invSkill %s: stack of %s emptied", entry[1], hex(entry[2]))
  end

  report.removed = report.board + report.list + report.team_auras
  report.bytes_patched = P:apply()
  return report
end

function PurgeMoves.summary(report)
  return string.format("%d players: %d board slots, %d match moves, %d team aura entries, %d invSkill stacks emptied; %d bytes patched",
    report.players, report.board, report.list, report.team_auras, report.stacks, report.bytes_patched)
end

function PurgeMoves.misplaced_auras(tree, is_aura, aura_slots)
  for _, id in ipairs({ BLOCK_INVENTORY, BLOCK_CHARACTERS }) do
    if not T.has_block(tree, id) then error("block " .. id .. " not found") end
  end
  local P = T.patches(tree)
  local report = { players = 0, board = 0, list = 0, bytes_patched = 0, lines = {} }
  local inventory = T.unwrap(tree, "block4", "m_Permanent")
  local stacks, stack_count = T.array(tree, inventory, "invSkill")
  if not stacks then error("invSkill not found in block 4") end
  local move_of = {}
  for i = 0, stack_count - 1 do
    local stack = T.at(stacks, i)
    local handle, move = T.number(tree, stack, "handle"), T.number(tree, stack, "item_id")
    if handle and handle ~= 0 and move and move ~= 0 then move_of[handle] = move end
  end
  local known = {}
  local function aura(move)
    if known[move] == nil then known[move] = is_aura(move) == true end
    return known[move]
  end
  for _, character in ipairs(characters(tree)) do
    local removed, dropped, kept = {}, {}, {}
    for _, board in ipairs({ character.placed or false, character.native or false }) do
      if board then
        for k = 0, BOARD_SLOTS - 1 do
          local handle = T.number(tree, board, "specialSkill_" .. k)
          local move = handle and handle ~= 0 and move_of[handle] or nil
          if move and not aura_slots[k] and aura(move) then
            P:set(board .. ".specialSkill_" .. k, handle, 0)
            report.board = report.board + 1
            dropped[move] = true
            removed[#removed + 1] = "board slot " .. (k + 1) .. " " .. hex(move)
          elseif move then
            kept[move] = true
          end
        end
      end
    end
    if character.list and next(dropped) then
      for k = 0, tree:get(character.list).len - 1 do
        local entry = T.at(character.list, k)
        local move = T.number(tree, entry, "id_crc")
        if move and dropped[move] and not kept[move] then
          P:set(entry .. ".id_crc", move, 0)
          local rank, ai = T.number(tree, entry, "skillRank"), T.number(tree, entry, "isUnusableAI")
          if rank then P:set(entry .. ".skillRank", rank, 0) end
          if ai then P:set(entry .. ".isUnusableAI", ai, 0) end
          report.list = report.list + 1
          removed[#removed + 1] = "match move " .. (k + 1) .. " " .. hex(move)
        end
      end
    end
    if #removed > 0 then
      report.players = report.players + 1
      report.lines[#report.lines + 1] = string.format("0x%08X %s: %s", character.handle, character.label, table.concat(removed, ", "))
    end
  end
  report.bytes_patched = P:apply()
  return report
end

return PurgeMoves
