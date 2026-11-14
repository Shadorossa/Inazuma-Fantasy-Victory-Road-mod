-- lua_patch.scope: used
-- The move rows of a card: list position unlock levels and learned moves (every menu that names them).
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.move_rows = CharacterReforged.move_rows or {}
CharacterReforged.move_rows.LEARNABLE = 3475351727
CharacterReforged.move_rows.CHARA_GET = 1131797651              -- 0x4375DC93 (charaStHdl, 0) -> the player's level
CharacterReforged.move_rows.ALWAYS_FREE = {false, false, false, false, true, true}
CharacterReforged.move_rows.FALLBACK = {1, 13, 20, 30, 0, 0}    -- the retail ladder of positions 1-6 (a card without a learn table)

-- Returns the level that opens list position `position` (0-5) of card `hdl` (0 or 1 means always open) and the move learned there.
function CharacterReforged.move_rows.need(call, hdl, position)
  if type(position) ~= "number" or position < 0 or position > 5 then
    return 0, 0
  end
  if CharacterReforged.move_rows.ALWAYS_FREE[position + 1] then
    return 0, 0
  end
  if type(hdl) == "number" and hdl ~= 0 then
    local ok, okr, moves, levels = pcall(call, CharacterReforged.move_rows.LEARNABLE, hdl)
    if ok and okr and type(levels) == "table" and type(levels[position + 1]) == "number" and levels[position + 1] > 0 then
      local move = type(moves) == "table" and VRFW.ids.unsigned(moves[position + 1]) or 0
      return levels[position + 1], move
    end
  end
  return CharacterReforged.move_rows.FALLBACK[position + 1] or 0, 0
end

-- Returns whether card `hdl` is still below learn level `need` (0 or 1 means learned from the start) and that level.
function CharacterReforged.move_rows.below(call, hdl, need)
  need = tonumber(need) or 0
  if need <= 1 then
    return false, need
  end
  local ok, level = pcall(call, CharacterReforged.move_rows.CHARA_GET, hdl, 0)
  level = ok and tonumber(level) or 0
  return level < need, need
end

function CharacterReforged.move_rows.lock(call, hdl, position)
  local need, move = CharacterReforged.move_rows.need(call, hdl, position)
  local locked = CharacterReforged.move_rows.below(call, hdl, need)
  return locked, need, move
end

CharacterReforged.move_rows.LEARNSET = 1491603481                -- CMND_VRFW_CHARACTER_LEARNSET (charaStHdl) -> answered, {move per learn list slot}, {level per slot}
CharacterReforged.move_rows.SLOT_OF = 1826049290                 -- CMND_CHARACTERREFORGED_SLOT_OF (move) -> slot kind (0 aura, 1 mix, 2 armour, -1 none)

-- Returns the first move of card `hdl`'s learn list whose slot kind is in `kinds` and whose learn level he has not reached, and that level (0, 0 = none).
function CharacterReforged.move_rows.locked_entry(call, hdl, kinds)
  if type(hdl) ~= "number" or hdl == 0 or type(kinds) ~= "table" then
    return 0, 0
  end
  local ok, answered, moves, levels = pcall(call, CharacterReforged.move_rows.LEARNSET, hdl)
  if not ok or answered ~= true or type(moves) ~= "table" or type(levels) ~= "table" then
    return 0, 0
  end
  for k = 1, #moves do
    local move = VRFW.ids.unsigned(moves[k] or 0)
    if move ~= 0 then
      local okk, kind = pcall(call, CharacterReforged.move_rows.SLOT_OF, move)
      if okk and kinds[kind] then
        local locked, need = CharacterReforged.move_rows.below(call, hdl, levels[k])
        if locked then
          return move, need
        end
      end
    end
  end
  return 0, 0
end

CharacterReforged.move_rows.AURA_SLOT_KINDS = {[0] = true, [2] = true}   -- slot kinds of the aura slot: aura, armour
CharacterReforged.move_rows.MIX_SLOT_KINDS = {[1] = true}                -- slot kind of the mix slot

CharacterReforged.move_rows.CARD_PARAM = 4                       -- CHARA_GET field: the card's chara_param id

-- Returns the level card `hdl` still needs for his Hiper row (0 = open) and whether he is below it: the VR-Framework's extra slot rule `learn_lock`, the same one the match plays (CMND_VRFW_EXTRA_SLOT_LEARN_NEED).
function CharacterReforged.move_rows.hyper_row_need(call, hdl)
  if type(hdl) ~= "number" or hdl == 0 then
    return 0, false
  end
  local okp, param = pcall(call, CharacterReforged.move_rows.CHARA_GET, hdl, CharacterReforged.move_rows.CARD_PARAM)
  local ok, need = pcall(call, VRFW.commands.VRFW_EXTRA_SLOT_LEARN_NEED, hdl, okp and tonumber(param) or 0)
  need = ok and tonumber(need) or 0
  return need, need > 0
end

-- Adds to an empty slot of `value` the learn list move it gets at a level card `card` has not reached, and sets aura_need / mix_need (the level each Hiper half still needs, 0 = open): below the Hiper row's level both halves need at least that level, else a half needs the level of the learn list move it shows.
function CharacterReforged.move_rows.with_locked(call, card, value)
  if type(value) ~= "table" then
    return value
  end
  value.aura_need, value.mix_need = 0, 0
  if (value.aura or 0) == 0 then
    value.aura, value.aura_need = CharacterReforged.move_rows.locked_entry(call, card, CharacterReforged.move_rows.AURA_SLOT_KINDS)
  end
  if (value.mix or 0) == 0 then
    value.mix, value.mix_need = CharacterReforged.move_rows.locked_entry(call, card, CharacterReforged.move_rows.MIX_SLOT_KINDS)
  end
  local row_need, row_locked = CharacterReforged.move_rows.hyper_row_need(call, card)
  if row_locked then
    value.aura_need, value.mix_need = math.max(value.aura_need or 0, row_need), math.max(value.mix_need or 0, row_need)
  end
  return value
end

CharacterReforged.move_rows.GET_SKILL =903078840               -- (charaStHdl, list position 0..5) -> move
CharacterReforged.move_rows.SKILL_INFO = 2580586398             -- CMND_GET_SOCCER_SKILL_INFO (move, 7) -> known, element
CharacterReforged.move_rows.COMMON_MOVE = 800895612
CharacterReforged.move_rows.ELEMENT_VOID = 5
CharacterReforged.move_rows.ROW_COUNT = 6
CharacterReforged.move_rows.LOG = 519897777                    -- CMND_VRFW_LOG (loader log)

-- Returns the card's 6 move rows as the plate shows them.
function CharacterReforged.move_rows.rows(call, hdl)
  local rows_of = CharacterReforged.PLAYER_PAGE_FANTASY_MOVES
  local ok, rows = false, nil
  if type(rows_of) == "table" and type(rows_of.rows) == "function" then
    ok, rows = pcall(rows_of.rows, call, hdl)
  end
  if ok and type(rows) == "table" then
    return rows
  end
  if not CharacterReforged.move_rows.rows_failed then
    CharacterReforged.move_rows.rows_failed = true
    pcall(call, CharacterReforged.move_rows.LOG, "Character Reforged move rows: no answer, rows left empty", tostring(rows))
  end
  rows = {}
  for position = 0, CharacterReforged.move_rows.ROW_COUNT - 1 do
    rows[position + 1] = {move = 0, slot = position}
  end
  return rows
end

function CharacterReforged.move_rows.is_learned(call, hdl, row)
  if type(row) ~= "table" or (row.move or 0) == 0 then
    return false
  end
  if type(row.slot) == "number" and CharacterReforged.move_rows.lock(call, hdl, row.slot) then
    return false
  end
  return true
end

function CharacterReforged.move_rows.is_grey(call, move)
  local ok, known, element = pcall(call, CharacterReforged.move_rows.SKILL_INFO, move, 7)
  if not ok or known ~= true or element ~= CharacterReforged.move_rows.ELEMENT_VOID then
    return false
  end
  local okc, knownc, common = pcall(call, CharacterReforged.move_rows.COMMON_MOVE, move)
  return okc and knownc == true and common == true
end

-- how many rows of card `hdl` are learned, and how many of those are not grey
function CharacterReforged.move_rows.learned_counts(call, hdl)
  local learned, real = 0, 0
  for _, row in ipairs(CharacterReforged.move_rows.rows(call, hdl)) do
    if CharacterReforged.move_rows.is_learned(call, hdl, row) then
      learned = learned + 1
      if not CharacterReforged.move_rows.is_grey(call, row.move) then
        real = real + 1
      end
    end
  end
  return learned, real
end
