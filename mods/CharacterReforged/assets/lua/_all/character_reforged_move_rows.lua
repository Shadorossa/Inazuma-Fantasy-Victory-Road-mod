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

function CharacterReforged.move_rows.lock(call, hdl, position)
  local need, move = CharacterReforged.move_rows.need(call, hdl, position)
  if need <= 1 then
    return false, need, move
  end
  local ok, level = pcall(call, CharacterReforged.move_rows.CHARA_GET, hdl, 0)
  level = ok and tonumber(level) or 0
  return level < need, need, move
end

CharacterReforged.move_rows.GET_SKILL = 903078840               -- (charaStHdl, list position 0..5) -> move
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
