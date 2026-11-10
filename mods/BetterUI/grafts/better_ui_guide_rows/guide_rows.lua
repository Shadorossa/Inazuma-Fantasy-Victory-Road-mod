@UPV@
do
  local GUIDE_ROWS = {
    OWNERS = {"OnInit", "SetupListItemButton", "GetListButtonLayerIndex", "OnDecideFocus", "OnChangeFocus", "OnEnter"},
    LIST = 530619243,                    -- mainmenu90_12_list_item_small
    LOG = 519897777,                    -- CMND_VRFW_LOG
    HELP = 0,                            -- the help row's kind
    kinds = nil, logged = false,
  }

  -- distinct integers 0..127, 4..16 of them, with kinds 0..3 (rules out t2 = {0, 0, 0, 0})
  local function is_guide_kinds(v)
    if v[0] ~= nil or #v < 4 or #v > 16 then
      return false
    end
    local seen = {}
    for _, k in ipairs(v) do
      if type(k) ~= "number" or k % 1 ~= 0 or k < 0 or k > 127 or seen[k] then
        return false
      end
      seen[k] = true
    end
    return seen[0] == true and seen[1] == true and seen[2] == true and seen[3] == true
  end

  local function guide_kinds()
    if GUIDE_ROWS.kinds == nil then
      GUIDE_ROWS.kinds = upvalue_find(GUIDE_ROWS.OWNERS, is_guide_kinds)
    end
    return GUIDE_ROWS.kinds
  end

  -- Moves the help row to the end (last = true) or the front.
  local function move_guide_rows(last)
    local kinds = guide_kinds()
    if kinds == nil then
      return false
    end
    local at
    for i = 1, #kinds do
      if kinds[i] == GUIDE_ROWS.HELP then
        at = i
        break
      end
    end
    local want = last and #kinds or 1
    if at == nil or at == want then
      return false
    end
    table.remove(kinds, at)
    table.insert(kinds, want, GUIDE_ROWS.HELP)
    return true
  end

  BetterUI = type(BetterUI) == "table" and BetterUI or {}
  BetterUI.guide_list = {Apply = function() return move_guide_rows(true) end}

  if BetterUI.guide_rows_wrapped == nil then
    BetterUI.guide_rows_wrapped = {}
  end

  -- Wraps retail OnInit, which marks a locked row by row index where the lists read it by kind.
  local init = _ENV.OnInit
  if type(init) == "function" and not BetterUI.guide_rows_wrapped[init] then
    local w = function(...)
      move_guide_rows(false)
      return init(...)
    end
    BetterUI.guide_rows_wrapped[w] = true
    _ENV.OnInit = w
  end

  local setup = _ENV.OnSetupLayer
  if type(setup) == "function" and not BetterUI.guide_rows_wrapped[setup] then
    local w = function(a1, a2, ...)
      if a1 == GUIDE_ROWS.LIST and a2 == 0 then
        move_guide_rows(true)
        if not GUIDE_ROWS.logged then
          GUIDE_ROWS.logged = true
          local kinds = GUIDE_ROWS.kinds
          pcall(funcLuaCommand, GUIDE_ROWS.LOG, "EVT guide_rows",
            kinds == nil and "row list not found (no VRFW.debug?): «Ayuda» stays first"
              or string.format("«Ayuda» last of %d row(s)", #kinds))
        end
      end
      return setup(a1, a2, ...)
    end
    BetterUI.guide_rows_wrapped[w] = true
    _ENV.OnSetupLayer = w
  end
end
