-- The Draft's filter panel: the options panel (BattleBayDeluxe.options_panel_run) whose rows are pool filters.
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.draft_filters = {
  CMD = @crc:CMND_BATTLEBAYDELUXE_DRAFT_FILTERS@,
  ROWS = { "scouts", "gender" },
  KEY = { scouts = @crc:battlebaydeluxe_draft_filter_scouts@, gender = @crc:battlebaydeluxe_draft_filter_gender@ },
  VALUE = {}, ok = false, count = 0,
}

function BattleBayDeluxe.draft_filter_text(key)
  return VRFW.host.command(@crc:CMND_TEXT_GET@, VRFW.ids.crc32(key)) or ""
end

-- A row value's text key.
function BattleBayDeluxe.draft_filter_value_key(name, v)
  if name == "gender" then
    return "battlebaydeluxe_draft_filter_gender_" .. v
  end
  return v == 0 and "battlebaydeluxe_draft_filter_no" or "battlebaydeluxe_draft_filter_yes"
end

function BattleBayDeluxe.draft_filter_row_text(name)
  local F = BattleBayDeluxe.draft_filters
  local v = F.VALUE[name]
  local key = BattleBayDeluxe.draft_filter_value_key(name, v)
  local value = BattleBayDeluxe.draft_filter_text(key)
  if value == "" then
    value = tostring(v)
  end
  return VRFW.text_fold.fill_template(BattleBayDeluxe.draft_filter_text("battlebaydeluxe_draft_filter_" .. name), value)
end

-- Asks the script (row -1: read only): the row values, whether the pool fills a draft, its size.
function BattleBayDeluxe.draft_filters_read(row, dir)
  local F = BattleBayDeluxe.draft_filters
  local r = table.pack(funcLuaCommand(F.CMD, row, dir))
  if r[1] ~= true then
    return false
  end
  for i, name in ipairs(F.ROWS) do
    F.VALUE[name] = r[i + 1]
  end
  F.ok, F.count = r[#F.ROWS + 2] == true, r[#F.ROWS + 3] or 0
  return true
end

function BattleBayDeluxe.draft_filters_refresh(row)
  local F = BattleBayDeluxe.draft_filters
  VRFW.host.command(830228314 --[[cross-menu call]], BattleBayDeluxe.tournament.SUB_WINDOW, "BattleBayDeluxeSubWindowRowText", row,
    BattleBayDeluxe.draft_filter_row_text(F.ROWS[row + 1]))
end

function BattleBayDeluxe.draft_filters_start_text()
  local F = BattleBayDeluxe.draft_filters
  return VRFW.text_fold.fill_template(BattleBayDeluxe.draft_filter_text(F.ok and "battlebaydeluxe_draft_filter_start"
    or "battlebaydeluxe_draft_filter_short"), F.count)
end

-- Left / right on a row (called by name).
function BattleBayDeluxeDraftFilterMove(row, dir)
  if not BattleBayDeluxe.draft_filters_read(row, dir == 1 and 1 or -1) then
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3791946501 --[[sy0004]])
  BattleBayDeluxe.draft_filters_refresh(row)
  BattleBayDeluxe.options_panel_set_start(BattleBayDeluxe.draft_filters_start_text())
end

-- Sub window list-item refresh callback (called by name)
function BattleBayDeluxeDraftFilterItem()
  VRFW.host.command(830228314 --[[cross-menu call]], BattleBayDeluxe.tournament.SUB_WINDOW, "BattleBayDeluxeTournamentSubWindowPanelDress",
    #BattleBayDeluxe.draft_filters.ROWS)
end

-- Sub window end callback (called by name)
function BattleBayDeluxeDraftFilterDone(r)
  BattleBayDeluxe.draft_filters.opt_result = r
  if r ~= -1 then
    funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW)
  end
end

-- The panel in a coroutine; true = the player started with a pool that fills the draft.
function BattleBayDeluxe.draft_filters_panel()
  local F = BattleBayDeluxe.draft_filters
  while true do
    if not BattleBayDeluxe.draft_filters_read(-1, 0) then
      BattleBayDeluxe.draft_log("no filter answer from the script")
      return false
    end
    local ids = {}
    for i, name in ipairs(F.ROWS) do
      ids[i] = F.KEY[name]
    end
    local r = BattleBayDeluxe.options_panel_run({
      state = F, rows = #F.ROWS, ids = ids,
      move_cb = "BattleBayDeluxeDraftFilterMove",
      item_cb = "BattleBayDeluxeDraftFilterItem",
      done_cb = "BattleBayDeluxeDraftFilterDone",
      refresh = BattleBayDeluxe.draft_filters_refresh,
      start_text = BattleBayDeluxe.draft_filters_start_text,
      accept = function(row)
        BattleBayDeluxeDraftFilterMove(row, 1)
      end,
    })
    if r == nil or r == -1 then
      BattleBayDeluxe.draft_log("filters: back to the grid")
      return false
    end
    if F.ok then
      return true
    end
    -- Too few players: the button's text says so; the panel opens again.
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, BattleBayDeluxe.draft.SE_NG)
  end
end

function BattleBayDeluxe.draft_filters_then_begin()
  if BattleBayDeluxe.draft_filters_panel() then
    BattleBayDeluxe.draft_begin(BattleBayDeluxe.draft.filterTile, true, true)
  end
end

function BattleBayDeluxe.draft_filters_step()
  local B = BattleBayDeluxe.draft
  local ok, err = coroutine.resume(B.filterCo)
  if not ok then
    BattleBayDeluxe.draft_log("filter panel error", tostring(err))
    B.filterCo = nil
    pcall(BattleBayDeluxe.draft_exit, true)
  elseif coroutine.status(B.filterCo) == "dead" then
    B.filterCo = nil
  end
end
