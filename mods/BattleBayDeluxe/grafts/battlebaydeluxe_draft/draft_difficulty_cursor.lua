-- Campaign difficulty window
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.difficulty_cursor = {
  GRID = @crc:vs01_43_enjoy_team_select_emblem_icon@,
  WINDOW = @crc:win05_11_select_difficulty_win_base@,
  LIST = @crc:win05_02_general_sub_list_item@,
  START = @crc:cmn03_05_cmn_button_b_graphic_text@,
  CURSOR = @crc:cursor@ --[[cursor: the attach of the grid tiles and of the start button]],
  LIST_CURSOR = @crc:select_cur@ --[[select_cur: the attach of the list rows]],
  ATTACH_TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@ --[[CMND_SET_LAYER_ATTACH_LOCATOR_TRACE (layer, idx, attach, on)]],
  CURSOR_LOCATOR = @crc:CMND_SET_CURSOR_LOCATOR@ --[[CMND_SET_CURSOR_LOCATOR (layer, attach, idx, count)]],
  LAYER_COUNT = @crc:CMND_GET_CREATE_LAYER_NUM@,
  IS_OPEN = @crc:CMND_IS_OPEN_LAYER@,
  FOCUS_INDEX = 2603265800,
  released = false,
  last = nil,
}

function BattleBayDeluxe.difficulty_cursor_log(...)
  BattleBayDeluxe.logger(BattleBayDeluxe.difficulty_cursor, "BattleBayDeluxe.difficulty_cursor")(...)
end

-- the instance count of a layer (0 when unknown)
function BattleBayDeluxe.difficulty_cursor_count(layer)
  local n = funcLuaMenuCommand(BattleBayDeluxe.difficulty_cursor.LAYER_COUNT, layer)
  return type(n) == "number" and n or 0
end

-- every grid tile's cursor attach traced or not
function BattleBayDeluxe.difficulty_cursor_grid(on)
  local C = BattleBayDeluxe.difficulty_cursor
  for i = 0, BattleBayDeluxe.difficulty_cursor_count(C.GRID) - 1 do
    funcLuaMenuCommand(C.ATTACH_TRACE, C.GRID, i, C.CURSOR, on)
  end
end

-- Runs when the focus enters the window's list (row idx) or its start button.
function BattleBayDeluxe.difficulty_cursor_on(layer, idx)
  local C = BattleBayDeluxe.difficulty_cursor
  if not C.released then
    BattleBayDeluxe.difficulty_cursor_grid(false)
    C.released = true
  end
  local rows = BattleBayDeluxe.difficulty_cursor_count(C.LIST)
  for i = 0, rows - 1 do
    funcLuaMenuCommand(C.ATTACH_TRACE, C.LIST, i, C.LIST_CURSOR, layer == C.LIST and i == idx)
  end
  funcLuaMenuCommand(C.ATTACH_TRACE, C.START, 0, C.CURSOR, layer == C.START)
  if layer == C.START then
    funcLuaMenuCommand(C.CURSOR_LOCATOR, C.START, C.CURSOR, 0, 1)
  else
    funcLuaMenuCommand(C.CURSOR_LOCATOR, C.LIST, C.LIST_CURSOR, idx, rows)
  end
  local where = layer == C.START and "start button" or ("list row " .. tostring(idx))
  if where ~= C.last then
    C.last = where
    BattleBayDeluxe.difficulty_cursor_log("cursor on the " .. where)
  end
end

-- Runs when the window is closed.
function BattleBayDeluxe.difficulty_cursor_back()
  local C = BattleBayDeluxe.difficulty_cursor
  if not C.released then
    return
  end
  C.released, C.last = false, nil
  funcLuaMenuCommand(C.ATTACH_TRACE, C.START, 0, C.CURSOR, false)
  BattleBayDeluxe.difficulty_cursor_grid(true)
  local cur = funcLuaMenuCommand(C.FOCUS_INDEX, C.GRID)
  if type(cur) == "number" and cur >= 0 then
    funcLuaMenuCommand(C.CURSOR_LOCATOR, C.GRID, C.CURSOR, cur, BattleBayDeluxe.difficulty_cursor_count(C.GRID))
  end
  BattleBayDeluxe.difficulty_cursor_log("cursor back on the grid, tile " .. tostring(cur))
end

do
  Wrap("BattleBayDeluxe.draft_difficulty_cursor", "OnChangeFocus", { around = function(change, a1, a2, ...)
    local r = table.pack(change(a1, a2, ...))
    local C = BattleBayDeluxe.difficulty_cursor
    if (a1 == C.START or a1 == C.LIST) and funcLuaMenuCommand(C.IS_OPEN, C.WINDOW) == true then
      local ok, err = pcall(BattleBayDeluxe.difficulty_cursor_on, a1, type(a2) == "number" and a2 or 0)
      if not ok then
        BattleBayDeluxe.difficulty_cursor_log("error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end })

  Wrap("BattleBayDeluxe.draft_difficulty_cursor", "OnCloseEndLayer", { around = function(closeEnd, a1, a2, ...)
    local r = table.pack(closeEnd(a1, a2, ...))
    if a1 == BattleBayDeluxe.difficulty_cursor.WINDOW then
      local ok, err = pcall(BattleBayDeluxe.difficulty_cursor_back)
      if not ok then
        BattleBayDeluxe.difficulty_cursor_log("error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end })
end
