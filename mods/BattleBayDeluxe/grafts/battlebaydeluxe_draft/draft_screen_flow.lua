-- The Draft screen's flow: open, the team panel, start, cursor moves, picks, back, the quit question and the per-frame step.
-- open the Draft layers (once per screen) and give the control focus to the anchor
function BattleBayDeluxe.draft_open()
  local B = BattleBayDeluxe.draft
  if not B.opened then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, B.SLOT)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, B.CARD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.QUAD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.TXT)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.CREST)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, B.ANCHOR)
    B.opened = true
  end
  BattleBayDeluxe.draft_formation_layers(true)
  -- Moves the anchor (a button object) off screen and makes it invisible.
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.ANCHOR, B.ANCHOR_X, B.ANCHOR_Y, 0, 0)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.ANCHOR, 0, false)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.ANCHOR, true)
  funcLuaMenuCommand(1778826357, B.ANCHOR, 0, true)
end

-- close the Draft layers (their card textures are released), the panel back, the focus off the anchor
function BattleBayDeluxe.draft_close_layers()
  local B = BattleBayDeluxe.draft
  if B.shown ~= nil then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, B.shown[1], B.shown[2],
                       BattleBayDeluxe.draft_cursor_label(B.shown[1], B.shown[2]), false)
    B.shown = nil
  end
  pcall(BattleBayDeluxe.draft_pack_end)
  B.cands = {}
  B.mode = nil
  B.reapply = nil
  B.probe = nil
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.ANCHOR, false)
  if B.opened then
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, B.SLOT)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, B.CARD)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.QUAD)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.TXT)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.CREST)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, B.ANCHOR)
    B.opened = false
  end
  pcall(BattleBayDeluxe.draft_formation_layers, false)
  B.quitTo = nil
  B.ready = {}
  local ok, err = pcall(BattleBayDeluxe.draft_screen_off)
  if not ok then
    BattleBayDeluxe.draft_log("screen off error", tostring(err))
  end
end

function BattleBayDeluxe.draft_grid_back()
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, true)
  if BattleBayDeluxe.draft_free() then
    -- The grid came back with the stash (see BattleBayDeluxe.draft_screen_off).
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, true)
    local cur = funcLuaMenuCommand(2603265800, B.GRID)
    if type(cur) == "number" then
      funcLuaMenuCommand(4233535095, B.GRID, cur, true)
    end
    if SetButtonGuideText ~= nil then
      pcall(SetButtonGuideText, -1)
    end
    B.refresh = B.REFRESH_FRAMES
    return
  end
  local ok, err = pcall(OnCloseEndLayer, B.DIFFWIN, 0)
  if not ok then
    BattleBayDeluxe.draft_log("grid back error", tostring(err))
  end
  B.refresh = B.REFRESH_FRAMES
end

-- Refreshes the tile and the panel.
function BattleBayDeluxe.draft_refresh(tile, panel, keep)
  local B = BattleBayDeluxe.draft
  tile = tile or B.tile
  local page = funcLuaCommand(B.PAGE_REFRESH)
  local redrawn = false
  if type(page) == "number" and VRFW.battle_bay_pages ~= nil and (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.query ~= nil) and (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.redraw ~= nil) then
    VRFW.battle_bay_pages.query()
    redrawn = pcall(VRFW.battle_bay_pages.redraw)
  end
  if not redrawn then
    -- Skips the page handling when there is no pages service.
    local args = {}
    for i, rec in pairs(B.slotArgs) do
      args[#args + 1] = {i, rec}
    end
    for _, a in ipairs(args) do
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.GRID, a[1], a[2][1] ~= 0)
      if not keep then
        funcLuaMenuCommand(4176779611 --[[reset icon]], B.GRID, a[1], B.EMBLEM_TEX)
      end
      pcall(SetupEmblemIcon, a[1], a[2][1], a[2][2], a[2][3])
      funcLuaMenuCommand(2158717427 --[[node visible]], B.GRID, B.EMBLEM_NODE, a[2][1] ~= 0, a[1])
    end
  end
  -- Sets focus and cursor on the tile.
  if tile >= 0 then
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.GRID) or 0
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, true)
    funcLuaMenuCommand(1778826357, B.GRID, tile, true)
    funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, B.GRID, B.GRID_CURSOR, tile, n)
  end
  if panel ~= nil then
    panel()
  else
    BattleBayDeluxe.draft_panel_back()
  end
  BattleBayDeluxe.draft_log("grid refreshed", page, redrawn, tile)
end

function BattleBayDeluxe.draft_panel()
  local B = BattleBayDeluxe.draft
  B.ours = true
  pcall(UpdateTeamNameText, B.TEAM, true)
  local ok, err = pcall(UpdateFormation, B.TEAM, true)
  B.ours = false
  if not ok then
    BattleBayDeluxe.draft_log("panel error", tostring(err))
  end
end

-- Goes back from the panel (BattleBayDeluxe.draft_panel).
function BattleBayDeluxe.draft_panel_back()
  local B = BattleBayDeluxe.draft
  if not BattleBayDeluxe.draft_free() or B.side ~= false then
    BattleBayDeluxe.draft_panel()
    return
  end
  B.ours = true
  local p1 = B.drawn[true]
  if p1 ~= nil and p1 ~= 0 then
    pcall(UpdateTeamNameText, p1, true)
    pcall(UpdateFormation, p1, true)
  end
  pcall(UpdateTeamNameText, B.TEAM, false)
  local ok, err = pcall(UpdateFormation, B.TEAM, false)
  B.ours = false
  if not ok then
    BattleBayDeluxe.draft_log("panel error (right)", tostring(err))
  end
end

function BattleBayDeluxe.draft_start(tile)
  local B = BattleBayDeluxe.draft
  local ok, phase = BattleBayDeluxe.draft_info()
  if not ok then
    BattleBayDeluxe.draft_log("no loader draft: the Draft tile does nothing")
    return
  end
  B.tile = tile
  B.used = true
  if phase >= 2 and BattleBayDeluxe.draft_free() then
    -- Decides the tile automatically in a free match with a complete draft.
    B.autoDecide = true
    B.refresh = 1
    return
  end
  if phase == 2 then
    -- Handles a tile that was already drafted (back from the difficulty window).
    B.bypass = true
    pcall(OnDecideFocus, B.GRID, tile)
    B.bypass = false
    return
  end
  if phase ~= 1 and not BattleBayDeluxe.draft_free() then
    -- The Campaign's Draft opens the filter panel first; its start button calls draft_begin.
    B.filterTile = tile
    B.filterCo = coroutine.create(BattleBayDeluxe.draft_filters_then_begin)
    BattleBayDeluxe.draft_filters_step()
    return
  end
  BattleBayDeluxe.draft_begin(tile, phase ~= 1, false)
end

-- Begins (fresh) or resumes the Draft on `tile`; `filtered` applies the panel's filters.
function BattleBayDeluxe.draft_begin(tile, fresh, filtered)
  local B = BattleBayDeluxe.draft
  if fresh then
    local okb, total = funcLuaCommand(B.BEGIN, filtered and 1 or 0)
    if okb ~= true then
      BattleBayDeluxe.draft_log("begin refused by the loader")
      BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(B.TXT_ERROR))
      return
    end
    BattleBayDeluxe.draft_log("begin", tile, total)
  end
  if not BattleBayDeluxe.draft_load_slots() then
    BattleBayDeluxe.draft_log("no slots from the loader")
    funcLuaCommand(B.ABANDON)
    return
  end
  B.refresh = nil
  B.mode = "pitch"
  B.sel = 0
  B.cands = {}
  BattleBayDeluxe.draft_screen_on()
  BattleBayDeluxe.draft_open()
  BattleBayDeluxe.draft_panel()
  BattleBayDeluxe.draft_draw_pitch()
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
  B.probe = B.PROBE_FRAMES
  BattleBayDeluxe.draft_mouse_open()
  BattleBayDeluxe.draft_log("screen", #B.slots, "slots, formation", B.formation)
  B.quitTo = nil
  if not (fresh and BattleBayDeluxe.draft_formation_open("start")) then
    BattleBayDeluxe.draft_formation_render()
  end
end

-- nearest slot in the direction (dx, dy) (screen, y up) from the selected one
function BattleBayDeluxe.draft_move(dx, dy)
  local B = BattleBayDeluxe.draft
  if B.ptr ~= nil then
    B.ptr.key_step() -- the keys own the selection until the pointer really moves again
  end
  if B.mode == "formation" then
    if dx ~= 0 then
      BattleBayDeluxe.draft_formation_move(dx)
    end
    return
  end
  if B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      return -- the pack is still being turned (Enter shows all)
    end
    -- Treats the candidates as a row on the pack's band.
    local d = (dy ~= 0) and -dy or dx
    if d ~= 0 then
      BattleBayDeluxe.draft_select_candidate(math.max(0, math.min(#B.cands - 1, B.csel + d)))
    end
    return
  end
  if B.mode ~= "pitch" then
    return
  end
  local from = B.where[B.sel]
  if from == nil then
    return
  end
  local layer, to = BattleBayDeluxe.draft_focus_move(from[1], from[2], #B.slots, dx, dy)
  for k = 0, #B.slots - 1 do
    local w = B.where[k]
    if layer ~= nil and w ~= nil and w[1] == layer and w[2] == to then
      BattleBayDeluxe.draft_select_slot(k)
      return
    end
  end
end

function BattleBayDeluxe.draft_next_empty(from)
  local B = BattleBayDeluxe.draft
  for d = 0, #B.slots - 1 do
    local k = (from + d) % #B.slots
    if B.slots[k + 1].param == 0 then
      return k
    end
  end
  return from
end

-- Handles Enter.
function BattleBayDeluxe.draft_decide()
  local B = BattleBayDeluxe.draft
  if B.mode == "formation" then
    BattleBayDeluxe.draft_formation_confirm()
    return
  end
  if B.mode == "pitch" then
    if BattleBayDeluxe.draft_filled() >= #B.slots then
      B.mode = "start"
    elseif B.slots[B.sel + 1].param == 0 then
      local r = table.pack(funcLuaCommand(B.CANDS, B.sel))
      if r[1] ~= true then
        BattleBayDeluxe.draft_log("no candidates for slot", B.sel)
        return
      end
      B.k = r[2]
      B.cands = {}
      for i = 0, (r[5] or 0) - 1 do
        B.cands[i + 1] = {param = r[6 + 3 * i], pos = r[7 + 3 * i], team = r[8 + 3 * i]}
      end
      B.mode = "cands"
      B.csel = 0
      BattleBayDeluxe.draft_pack_start()
    else
      return
    end
  elseif B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      BattleBayDeluxe.draft_pack_done(true) -- Enter during the animation: all 5 at once
      BattleBayDeluxe.draft_show_guide()
      return
    end
    local ok, done, slot, param = funcLuaCommand(B.PICK, B.k, B.csel)
    if ok ~= true then
      BattleBayDeluxe.draft_log("pick refused", B.k, B.csel)
      BattleBayDeluxe.draft_exit(true)
      BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(B.TXT_ERROR))
      return
    end
    B.slots[B.k + 1].param = param
    BattleBayDeluxe.draft_draw_slot(B.k)
    BattleBayDeluxe.draft_pack_outro(B.k, B.csel) -- the card flies to its place, the screen comes back
    B.mode = done and "start" or "pitch"
    for i = 0, 4 do
      BattleBayDeluxe.draft_draw_candidate(i)
    end
    B.sel = B.k
  elseif B.mode == "start" then
    BattleBayDeluxe.draft_finish()
    return
  elseif B.mode == "quit" then
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0010@ --[[decide]])
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
end

-- Handles Back.
function BattleBayDeluxe.draft_back()
  local B = BattleBayDeluxe.draft
  if B.mode == "formation" then
    BattleBayDeluxe.draft_formation_back()
    return
  end
  if B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      BattleBayDeluxe.draft_pack_done(true) -- Back during the animation: all 5 at once too
      return
    end
    -- the 5 of a slot cannot be left without a pick (no reroll by backing out)
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, B.SE_NG)
    local rec = B.slots[B.k + 1]
    BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(B.TXT_POS[rec and rec.pos or 0]) .. ": " .. BattleBayDeluxe.draft_text(B.TXT_PICK_ONE))
    BattleBayDeluxe.draft_log("pick open: back refused", B.k)
    return
  elseif B.mode == "quit" then
    return
  elseif B.mode == "pitch" then
    BattleBayDeluxe.draft_quit_open(nil)
    return
  elseif B.mode == "start" then
    B.mode = "pitch"
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@ --[[back]])
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
end

function BattleBayDeluxe.draft_quit_ask()
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_MAKE_ACHIEVE_MESSAGE@, B.MENU, false)
  local text = BattleBayDeluxe.draft_text(B.TXT_QUIT_ASK)
  local yes = VRFW.question.ask(text, {on_open = function() funcLuaCommand(2529383714, 1) end}) -- the cursor starts on No
  funcLuaMenuCommand(@crc:CMND_MAKE_ACHIEVE_MESSAGE@, B.MENU, true)
  return yes
end

function BattleBayDeluxe.draft_quit_open(to)
  local B = BattleBayDeluxe.draft
  B.mode = "quit"
  B.quitTo = to
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@ --[[back]])
  B.quitCo = coroutine.create(BattleBayDeluxe.draft_quit_ask)
  BattleBayDeluxe.draft_quit_step()
end

function BattleBayDeluxe.draft_quit_step()
  local B = BattleBayDeluxe.draft
  if B.quitCo == nil then
    return
  end
  local ok, yes = coroutine.resume(B.quitCo)
  if ok and coroutine.status(B.quitCo) ~= "dead" then
    return
  end
  B.quitCo = nil
  if not ok then
    BattleBayDeluxe.draft_log("quit window error", tostring(yes))
    pcall(funcLuaMenuCommand, @crc:CMND_MAKE_ACHIEVE_MESSAGE@, B.MENU, true)
    yes = false
  end
  if B.mode ~= "quit" then
    return
  end
  if yes == true then
    BattleBayDeluxe.draft_log("abandoned with", BattleBayDeluxe.draft_filled(), "picks")
    BattleBayDeluxe.draft_exit(true)
    return
  end
  B.mode = B.quitTo or "pitch"
  B.quitTo = nil
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
end

-- Leaves the Draft screen.
function BattleBayDeluxe.draft_exit(abandon)
  local B = BattleBayDeluxe.draft
  if abandon then
    funcLuaCommand(B.ABANDON)
  end
  BattleBayDeluxe.draft_close_layers()
  BattleBayDeluxe.draft_grid_back()
  BattleBayDeluxe.draft_panel_back()
end

-- Finishes the draft once 16 players are drafted and confirmed.
function BattleBayDeluxe.draft_finish()
  local B = BattleBayDeluxe.draft
  BattleBayDeluxe.draft_close_layers()
  if BattleBayDeluxe.draft_free() then
    -- Free match: decides the tile directly.
    BattleBayDeluxe.draft_log("complete: the tile's decide (free match)")
    BattleBayDeluxe.draft_grid_back()
    BattleBayDeluxe.draft_panel_back()
    B.autoDecide = true
    return
  end
  BattleBayDeluxe.draft_panel()
  BattleBayDeluxe.draft_log("complete: difficulty window")
  B.bypass = true
  local ok, err = pcall(OnDecideFocus, B.GRID, B.tile)
  B.bypass = false
  if not ok then
    BattleBayDeluxe.draft_log("difficulty window error", tostring(err))
  end
end

function BattleBayDeluxe.draft_step()
  local B = BattleBayDeluxe.draft
  if B.pk ~= nil then
    local ok, err = pcall(BattleBayDeluxe.draft_pack_step)
    if not ok then
      BattleBayDeluxe.draft_logger().once("pack_error", "pack error", tostring(err))
      pcall(BattleBayDeluxe.draft_pack_end)
      if B.mode == "cands" then
        for i = 0, 4 do
          pcall(BattleBayDeluxe.draft_draw_candidate, i) -- the plain cards back (no pack)
        end
        pcall(BattleBayDeluxe.draft_cursor)
      end
    end
  end
  if B.quitCo ~= nil then
    BattleBayDeluxe.draft_quit_step()
  end
  if B.filterCo ~= nil then
    BattleBayDeluxe.draft_filters_step()
  end
  if BattleBayDeluxe.draft_formation.dirty and B.mode ~= nil then
    local okf, errf = pcall(BattleBayDeluxe.draft_formation_render)
    if not okf then
      BattleBayDeluxe.draft_logger().once("formation_error", "formation step error", tostring(errf))
    end
  end
  local okm, errm = pcall(BattleBayDeluxe.draft_mouse)
  if not okm then
    B.polled = false
    BattleBayDeluxe.draft_logger().once("mouse_error", "mouse error", tostring(errm))
  end
  if B.refresh ~= nil then
    B.refresh = B.refresh - 1
    if B.refresh <= 0 then
      B.refresh = nil
      local ok, err = pcall(BattleBayDeluxe.draft_refresh)
      if not ok then
        BattleBayDeluxe.draft_logger().once("refresh_error", "refresh error", tostring(err))
      end
      if B.autoDecide then
        -- Free match: clears the automatic decision.
        B.autoDecide = false
        local done = VRFW.host.command(B.DECIDE, B.tile)
        BattleBayDeluxe.draft_log("free match decide", tostring(done), B.tile)
      end
    end
  end
  if B.reapply ~= nil and B.mode ~= nil then
    B.reapply = B.reapply - 1
    for k = 0, #B.slots - 1 do
      local w = B.where[k]
      if w ~= nil and B.slots[k + 1].param == 0 and B.ready[w[1] .. ":" .. w[2]] then
        BattleBayDeluxe.draft_rehide(w[1], w[2])
      end
    end
    if B.reapply <= 0 then
      B.reapply = nil
    end
  end
  if B.probe ~= nil and B.mode ~= nil then
    B.probe = B.probe - 1
    if B.probe <= 0 then
      B.probe = nil
      local ok, err = pcall(BattleBayDeluxe.draft_probe)
      if not ok then
        BattleBayDeluxe.draft_logger().once("probe_error", "probe error", tostring(err))
      end
    end
  end
end
