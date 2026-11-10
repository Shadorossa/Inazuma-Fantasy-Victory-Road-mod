-- the cursor stays on the rows the bank accepts (character_reforged_create_pick_mask), and a release resets
do
  CharacterReforged_PlateMoves = CharacterReforged_PlateMoves or {}
  local P = CharacterReforged_PlateMoves
  P.STEM = "personal_plate_menu"
  P.ID = "CharacterReforged.create_plate_moves"
  P.KEY_PICKING = 2195309509                         -- character_reforged_create_pick_moves
  P.KEY_PICKED_ROW = 2315084405                      -- character_reforged_create_pick_row
  P.SKILL_ROWS = 1580043721                          -- soccer11_09_formation_chara_skill (the plate's move rows)
  P.KEY_PLATE_RELEASE = 2526449858                   -- character_reforged_create_plate_release
  P.KEY_PICK_MASK = 1309442123                     -- character_reforged_create_pick_mask: bit r = row r can be picked
  P.ROW_COUNT = 6
  P.COLUMNS = 2                                      -- the move rows' grid: 2 columns, in row order
  P.FOCUS_GET = 2603265800                           -- (layer) -> the focused row
  P.FOCUS_SET = 3466097042                           -- (layer, row)
  P.FOCUS_MARK = 1778826357                          -- (layer, row, on)
  P.POINTER_MOVED = 3272825600                       -- () -> the pointer moved this frame
  P.IN_SKILL_MODE = 2100229437                       -- () -> the plate's cursor is on the move rows
  P.SOUND = 1917805374
  P.SE_REFUSED = 2086672038                          -- sy0003
  P.last, P.setting, P.refused_row = nil, false, nil

  function P.picking()
    return VRFW.param.has(P.KEY_PICKING)
  end

  function P.selectable(row)
    local mask = VRFW.param.has(P.KEY_PICK_MASK) and VRFW.param.get(P.KEY_PICK_MASK) or nil
    if type(mask) ~= "number" or type(row) ~= "number" or row < 0 or row >= P.ROW_COUNT then
      return false
    end
    return math.floor(mask / 2 ^ row) % 2 == 1
  end

  -- Returns the nearest selectable row from `from` in the direction of the press that went to `to`.
  function P.row_towards(from, to)
    local from_col, from_line = from % P.COLUMNS, math.floor(from / P.COLUMNS)
    local to_col, to_line = to % P.COLUMNS, math.floor(to / P.COLUMNS)
    local lines = to_line - from_line
    local lengthwise, step = lines ~= 0, 0
    if lengthwise then
      -- A jump of more than one line is the grid wrapping.
      step = math.abs(lines) > 1 and (lines > 0 and -1 or 1) or lines
    else
      step = to_col > from_col and 1 or -1
    end
    local best, best_main, best_side = nil, 0, 0
    for row = 0, P.ROW_COUNT - 1 do
      local col, line = row % P.COLUMNS, math.floor(row / P.COLUMNS)
      local main = lengthwise and (line - from_line) * step or (col - from_col) * step
      local side = lengthwise and math.abs(col - from_col) or math.abs(line - from_line)
      if main > 0 and P.selectable(row) and (best == nil or main < best_main or (main == best_main and side < best_side)) then
        best, best_main, best_side = row, main, side
      end
    end
    return best
  end

  function P.focus(row)
    P.setting = true
    pcall(funcLuaMenuCommand, P.FOCUS_SET, P.SKILL_ROWS, row)
    P.setting = false
    P.last = row
  end

  -- Runs when the plate entered the move rows during the pick.
  function P.start_cursor()
    if not P.picking() or funcLuaMenuCommand(P.IN_SKILL_MODE) ~= true then
      return
    end
    P.refused_row = nil
    for row = 0, P.ROW_COUNT - 1 do
      if P.selectable(row) then
        P.focus(row)
        pcall(funcLuaMenuCommand, P.FOCUS_MARK, P.SKILL_ROWS, row, true)
        return
      end
    end
    P.last = nil
  end

  function P.change_focus(nxt, layer, ...)
    if layer ~= P.SKILL_ROWS or not P.picking() then
      return nxt(layer, ...)
    end
    if P.setting then
      return
    end
    local row = funcLuaMenuCommand(P.FOCUS_GET, P.SKILL_ROWS)
    if P.selectable(row) then
      P.last, P.refused_row = row, nil
      return nxt(layer, ...)
    end
    local from = P.last
    if funcLuaMenuCommand(P.POINTER_MOVED) == true then
      if P.refused_row ~= row then
        P.refused_row = row
        funcLuaCommand(P.SOUND, P.SE_REFUSED)
      end
      if from ~= nil then
        P.focus(from)
      end
      return
    end
    local target = from ~= nil and type(row) == "number" and P.row_towards(from, row) or nil
    if target == nil then
      if from ~= nil then
        P.focus(from)
      end
      return
    end
    P.focus(target)
    return nxt(layer, ...)
  end

  function P.decide(nxt, layer, index, ...)
    if layer ~= P.SKILL_ROWS or not P.picking() then
      return nxt(layer, index, ...)
    end
    -- a row held by the retail drag goes back to its place at once (no animation wait)
    if type(TerminateCharaSkillSort) == "function" then
      pcall(TerminateCharaSkillSort, true)
    end
    VRFW.param.clear(P.KEY_PICKED_ROW)
    if type(index) == "number" and index >= 0 then
      VRFW.param.set(P.KEY_PICKED_ROW, index + 1)
    end
    return 1
  end

  -- the bank's card off the plate (UpdateCharaStHdlPersonalPlateFromCharaBank(0, ...) from the releasing bank)
  function P.release(nxt, hdl, ...)
    if hdl ~= 0 or not VRFW.param.has(P.KEY_PLATE_RELEASE) then
      return nxt(hdl, ...)
    end
    VRFW.param.clear(P.KEY_PLATE_RELEASE)
    if type(TerminateCharaSkillSort) == "function" then
      pcall(TerminateCharaSkillSort, true)
    end
    SetCharaStHdl(0, true)
    pcall(UpdatePersonalPlatePage)
  end

  if VRFW.host ~= nil then
    VRFW.host.on(P.STEM, "UpdateCharaStHdlPersonalPlateFromCharaBank", {id = P.ID .. ".release", phase = "around",
      fn = function(nxt, ...)
        return P.release(nxt, ...)
      end})
    VRFW.host.on(P.STEM, "UpdateShowSkillDetailInfo", {id = P.ID .. ".start_cursor", phase = "after", fn = function()
      P.start_cursor()
    end})
    VRFW.host.on(P.STEM, "OnChangeFocus", {id = P.ID .. ".cursor", phase = "around", fn = function(nxt, ...)
      return P.change_focus(nxt, ...)
    end})
    for _, point in ipairs({"OnEnter", "OnDecideFocus"}) do
      VRFW.host.on(P.STEM, point, {id = P.ID .. ".pick", phase = "around", fn = function(nxt, ...)
        return P.decide(nxt, ...)
      end})
    end
  end
end
