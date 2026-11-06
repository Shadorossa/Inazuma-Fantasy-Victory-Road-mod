-- Character Reforged › the lock rule of a move row: ONE rule for the skill board (graft ss2_menus, EVT_UnlockLevel)
-- and the player plate's move page (graft plate_pages, EVT_PPG_FANTASY_MOVES). A row is locked by its LIST POSITION
-- p (0-5): the level of learn slot p + 1 (the retail learn table 0xCF25A8AF, answered by the framework's learn levels),
-- positions 5-6 always free, the retail ladder when the card has no learn table; locked while the player's level is
-- below it. A locked row shows its own move (list position or board cell), else the move learn slot p + 1 will teach.
-- CR_MOVE_ROWS.LearnedCounts: learned and learned non-grey moves (the «Crear …» bank's partner rule).
-- Put in place by `--@lib cr_move_rows.lua#MoveRows` (graft_lib.expand_lib); global table only, no main-chunk local
-- (the board's chunk is at Lua 5.2's 200-local limit); no engine call at chunk load.
--@section MoveRows
CR_MOVE_ROWS = CR_MOVE_ROWS or {}
CR_MOVE_ROWS.LEARNABLE = 3475351727              -- 0xCF25A8AF (charaStHdl) -> ok, {move per slot 1-6}, {level per slot}
CR_MOVE_ROWS.CHARA_GET = 1131797651              -- 0x4375DC93 (charaStHdl, 0) -> the player's level
CR_MOVE_ROWS.ALWAYS_FREE = {false, false, false, false, true, true}
CR_MOVE_ROWS.FALLBACK = {1, 13, 20, 30, 0, 0}    -- the retail ladder of positions 1-6 (a card without a learn table)

-- the level that opens list position `position` (0-5) of card `hdl` (0 / 1 = always open) and the move learn slot
-- position + 1 teaches (0 = none)
function CR_MOVE_ROWS.Need(call, hdl, position)
  if type(position) ~= "number" or position < 0 or position > 5 then
    return 0, 0
  end
  if CR_MOVE_ROWS.ALWAYS_FREE[position + 1] then
    return 0, 0
  end
  if type(hdl) == "number" and hdl ~= 0 then
    local ok, okr, moves, levels = pcall(call, CR_MOVE_ROWS.LEARNABLE, hdl)
    if ok and okr and type(levels) == "table" and type(levels[position + 1]) == "number" and levels[position + 1] > 0 then
      local move = type(moves) == "table" and tonumber(moves[position + 1]) or 0
      if move < 0 then
        move = move + 4294967296
      end
      return levels[position + 1], move
    end
  end
  return CR_MOVE_ROWS.FALLBACK[position + 1] or 0, 0
end

-- is list position `position` of card `hdl` locked: locked, the level that opens it, the move its learn slot teaches
function CR_MOVE_ROWS.Lock(call, hdl, position)
  local need, move = CR_MOVE_ROWS.Need(call, hdl, position)
  if need <= 1 then
    return false, need, move
  end
  local ok, level = pcall(call, CR_MOVE_ROWS.CHARA_GET, hdl, 0)
  level = ok and tonumber(level) or 0
  return level < need, need, move
end

CR_MOVE_ROWS.GET_SKILL = 903078840               -- (charaStHdl, list position 0..5) -> move
CR_MOVE_ROWS.SKILL_INFO = 2580586398             -- CMND_GET_SOCCER_SKILL_INFO (move, 7) -> known, element
CR_MOVE_ROWS.COMMON_MOVE = 800895612             -- (move) -> known, a common skill (not a grey move by itself: see IsGrey)
CR_MOVE_ROWS.ELEMENT_VOID = 5
CR_MOVE_ROWS.ROW_COUNT = 6
CR_MOVE_ROWS.LOG = 3661580131                    -- CMND_EVT_LOG

-- the card's 6 move rows as the plate shows them: { { move, slot } } (slot = the row's list position, nil = none), from
-- the player page's rule (EVT_PPG_FANTASY_MOVES.Rows); no answer = 6 empty rows, never the game's list positions
function CR_MOVE_ROWS.Rows(call, hdl)
  local rows_of = rawget(_ENV, "EVT_PPG_FANTASY_MOVES")
  local ok, rows = false, nil
  if type(rows_of) == "table" and type(rows_of.Rows) == "function" then
    ok, rows = pcall(rows_of.Rows, call, hdl)
  end
  if ok and type(rows) == "table" then
    return rows
  end
  if not CR_MOVE_ROWS.rows_failed then
    CR_MOVE_ROWS.rows_failed = true
    pcall(call, CR_MOVE_ROWS.LOG, "Character Reforged move rows: no answer, rows left empty", tostring(rows))
  end
  rows = {}
  for position = 0, CR_MOVE_ROWS.ROW_COUNT - 1 do
    rows[position + 1] = {move = 0, slot = position}
  end
  return rows
end

-- is `row` of CR_MOVE_ROWS.Rows a move the card can already use (not empty, not locked)
function CR_MOVE_ROWS.IsLearned(call, hdl, row)
  if type(row) ~= "table" or (row.move or 0) == 0 then
    return false
  end
  if type(row.slot) == "number" and CR_MOVE_ROWS.Lock(call, hdl, row.slot) then
    return false
  end
  return true
end

-- is `move` drawn on a grey row: the retail row colour (SetupSkillItemBaseTexture): a void-element common skill
function CR_MOVE_ROWS.IsGrey(call, move)
  local ok, known, element = pcall(call, CR_MOVE_ROWS.SKILL_INFO, move, 7)
  if not ok or known ~= true or element ~= CR_MOVE_ROWS.ELEMENT_VOID then
    return false
  end
  local okc, knownc, common = pcall(call, CR_MOVE_ROWS.COMMON_MOVE, move)
  return okc and knownc == true and common == true
end

-- how many rows of card `hdl` are learned, and how many of those are not grey
function CR_MOVE_ROWS.LearnedCounts(call, hdl)
  local learned, real = 0, 0
  for _, row in ipairs(CR_MOVE_ROWS.Rows(call, hdl)) do
    if CR_MOVE_ROWS.IsLearned(call, hdl, row) then
      learned = learned + 1
      if not CR_MOVE_ROWS.IsGrey(call, row.move) then
        real = real + 1
      end
    end
  end
  return learned, real
end
