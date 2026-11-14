PL.MX_SCENE_ON = true
PL.MX_CMD.SCENE = @crc:CMND_CHARACTERREFORGED_MIXIMAX_SCENE@             -- (base) -> ok, event, map | false, reason
PL.MX_CMD.SCENE_END = @crc:CMND_CHARACTERREFORGED_MIXIMAX_SCENE_END@        -- (why)
PL.MX_CMD.SCENE_STATE = @crc:CMND_CHARACTERREFORGED_MIXIMAX_SCENE_STATE@      -- () -> pending, base handle, seconds
-- The scene plays through the VRFW's live player (end hold off).
PL.MX_CMD.LIVE_RUN = @crc:CMND_VRFW_ANIM_LIVE_RUN@         -- (reservation, event) -> true, slot | false, why
PL.MX_CMD.LIVE_TICK = @crc:CMND_VRFW_ANIM_LIVE_TICK@        -- () -> phase, frame, total, ...
PL.MX_CMD.LIVE_CTL = @crc:CMND_VRFW_ANIM_LIVE_CTL@          -- (op, n): "hold" 0 = play into the end
PL.MX_CMD.LIVE_WINDOW = @crc:CMND_VRFW_ANIM_LIVE_WINDOW@      -- (x, y, w, h, muted): w 0 = full screen
PL.MX_CMD.LIVE_VIEW = @crc:CMND_VRFW_ANIM_LIVE_VIEW@        -- (zoom, pan x, pan y): 1, 0, 0 = the event's framing
PL.mx_scene_busy = false                -- the scene is on: this screen takes no input (the module's own flag, below)

-- run the reserved event `ev` -> pcall results (ok, true, slot | ok, false, why)
function PL.mx_scene_run(reserved, ev)
  pcall(funcLuaCommand, PL.MX_CMD.LIVE_WINDOW, 0, 0, 0, 0, 0)
  pcall(funcLuaCommand, PL.MX_CMD.LIVE_VIEW, 1, 0, 0)
  local ok, run, info = pcall(funcLuaCommand, PL.MX_CMD.LIVE_RUN, reserved, ev)
  if ok and run == true then
    pcall(funcLuaCommand, PL.MX_CMD.LIVE_CTL, "hold", 0)
  end
  return ok, run, info
end

function PL.mx_scene_tick()
  local ok, ph, frame, total = pcall(funcLuaCommand, PL.MX_CMD.LIVE_TICK)
  return ok, ph, (type(frame) == "number" and frame / 60 or nil), (type(total) == "number" and total / 60 or nil)
end

-- the framework's top bar is hidden while the scene plays (param vrfw_top_bar_hidden / VRFW.top_bar.hide)
function PL.mx_scene_top_bar(hide)
  if type(VRFW.top_bar.hide) == "function" then
    pcall(VRFW.top_bar.hide, hide)
  elseif hide then
    VRFW.param.set(1455983968 --[[vrfw_top_bar_hidden]], 1)
  elseif VRFW.param.has(1455983968) == true then
    VRFW.param.clear(1455983968)
  end
end
PL.MX_SCENE_DOCK = 937147172            -- soccer_team_dock_menu
PL.MX_SCENE_TOP = 811496143             -- soccer_top_menu (hub; dock opened by graft comp_menu)
PL.MX_SCENE_DOCK_TOP = 91676902
-- Modes with a playable field under the dock.
PL.MX_SCENE_FIELD_MODES = {"story", "free_walk", "match"}
-- The event is pushed as SceneEvent on top of the menu scene (the live player)
PL.MX_SCENE_HIDE = {EVT_MENU, 1981996040 --[[chara_bank_menu_for_search]], 968210065 --[[sub_window]],
  1427722143 --[[personal_plate_menu]], 935586083 --[[team_dock_formation_menu]], 2049316981 --[[soccer_formation_menu]],
  937147172 --[[soccer_team_dock_menu]], 91676902 --[[team_dock_common_top_menu]], 811496143 --[[soccer_top_menu]]}
-- Chronicle's top menu, the board and its Start menu under the dock
PL.MX_SCENE_HIDE_ONLY = {3902542018 --[[chronicle_mode_top_menu]], 3653404168 --[[kizuna_town_mainmenu]],
  364708540 --[[vs_route_town_menu]]}
-- The header bar, guide line and button guide layers of the dock's top menus and the screen's parent.
PL.MX_SCENE_BAR_MENUS = {91676902 --[[team_dock_common_top_menu]], 811496143 --[[soccer_top_menu]],
  937147172 --[[soccer_team_dock_menu]]}
PL.MX_SCENE_BARS = {575058101 --[[mainmenu90_01_header]], 2750436121 --[[mainmenu90_03_header_rank]],
  2279382105 --[[mainmenu90_31_doc_item]], 3078308064 --[[mainmenu90_05_content_guide_line01]],
  1138543975 --[[mainmenu01_06_base_button_guide]]}
PL.MX_CMD.MENU_LAYER_VISIBLE = 3579981806
PL.MX_SCENE_BAR_OWNERS = {91676902 --[[team_dock_common_top_menu]], 811496143 --[[soccer_top_menu]],
  3902542018 --[[chronicle_mode_top_menu]], 3653404168 --[[kizuna_town_mainmenu]]}
function PL.mx_scene_bar_owners(hide)
  for _, m in ipairs(PL.MX_SCENE_BAR_OWNERS) do
    if funcLuaMenuCommand(C.EXIST_MENU, m) == true then
      local ok, r = pcall(funcLuaCommand, 830228314, m, "CharacterReforged_MiximaxSceneBars", hide)
      pcall(Call, C.LOG, "skill_slots", "miximax scene bars", string.format("%08X", m), tostring(hide),
        tostring(ok), tostring(r))
    end
  end
end
function PL.mx_scene_bars(hide, list)
  if not hide then
    PL.mx_scene_bar_owners(false)
    funcLuaMenuCommand(C.LAYER_VISIBLE, 3078308064 --[[mainmenu90_05_content_guide_line01]], 0, true)
    for i = #list, 1, -1 do
      pcall(funcLuaMenuCommand, PL.MX_CMD.MENU_LAYER_VISIBLE, list[i][1], list[i][2], 1)
    end
    return list
  end
  PL.mx_scene_bar_owners(true)
  -- this screen's own guide line (graft training_btn) is drawn even with the menu hidden
  funcLuaMenuCommand(C.LAYER_VISIBLE, 3078308064 --[[mainmenu90_05_content_guide_line01]], 0, false)
  local out, seen = {}, {}
  local menus = {}
  for _, m in ipairs(PL.MX_SCENE_BAR_MENUS) do menus[#menus + 1] = m end
  if n12 ~= nil and n12 ~= 0 then menus[#menus + 1] = n12 end
  for _, m in ipairs(menus) do
    if not seen[m] and funcLuaMenuCommand(C.EXIST_MENU, m) == true then
      seen[m] = true
      for _, L in ipairs(PL.MX_SCENE_BARS) do
        if pcall(funcLuaMenuCommand, PL.MX_CMD.MENU_LAYER_VISIBLE, m, L, 0) then
          out[#out + 1] = {m, L}
        end
      end
    end
  end
  return out
end
PL.MX_SCENE_MAX_FRAMES = 60 * 180      -- give the menus back after 3 min whatever the loader says
-- The partner is in no team, so his model is preloaded in chara_model_only_view_menu (PL.mx_scene_preload)
PL.MX_SCENE_PRELOAD = true
PL.MX_SCENE_MODEL_LAYER = 2917320188   -- soccer11_05_equip_status_base
PL.MX_SCENE_PRELOAD_MAX = 240          -- coroutine steps waiting for the model
-- Scene message duration in seconds.
PL.MX_SCENE_MSG = false
PL.MX_SCENE_MSG_AT = 3.75
PL.MX_SCENE_MSG_END = 5.05
PL.MX_SCENE_MSG_MENU = 449578137       -- general_window

-- this screen's 3D model shows card h (the retail SetupCharaModel reads the screen's card n)
function PL.mx_scene_model(h)
  local keep = n
  n = h
  local ok, err = pcall(SetupCharaModel, PL.MX_SCENE_MODEL_LAYER, 0)
  n = keep
  return ok, err
end

-- The base stays in this screen's model
PL.MX_SCENE_MV = 275734212             -- chara_model_only_view_menu
PL.MX_SCENE_MV_READY = 2565877806
PL.MX_SCENE_MV_SKIP = {[@crc:CMND_SET_CHARA_MODEL_SHADOW@] = true --[[shadow]], [@crc:CMND_OPEN_LAYER@] = true --[[open layer]]}
PL.mx_scene_mv_opened = false

-- the model commands this screen's SetupCharaModel sends for card h (recorded, not executed)
function PL.mx_scene_model_cmds(h)
  local rec = {}
  local real = funcLuaMenuCommand
  funcLuaMenuCommand = function(...)
    rec[#rec + 1] = table.pack(...)
    return nil
  end
  local keep = n
  n = h
  local ok, err = pcall(SetupCharaModel, PL.MX_SCENE_MODEL_LAYER, 0)
  n = keep
  funcLuaMenuCommand = real
  return ok, err, rec
end

function PL.mx_scene_mv(name, ...)
  return pcall(funcLuaCommand, 830228314, PL.MX_SCENE_MV, name, ...)
end

function PL.mx_scene_preload(h)
  if not PL.MX_SCENE_PRELOAD or type(h) ~= "number" or h == 0 then
    return false
  end
  local ok, err, rec = PL.mx_scene_model_cmds(h)
  if not ok or #rec == 0 then
    pcall(Call, C.LOG, "skill_slots", "miximax scene preload", "no model commands", tostring(err))
    return false
  end
  if funcLuaMenuCommand(C.EXIST_MENU, PL.MX_SCENE_MV) ~= true then
    funcLuaCommand(@crc:CMND_OPEN_MENU_OBJECT@, PL.MX_SCENE_MV)
    PL.mx_scene_mv_opened = true
  end
  local steps = 0
  while steps < PL.MX_SCENE_PRELOAD_MAX do
    coroutine.yield()
    steps = steps + 1
    local okl, loading = pcall(funcLuaCommand, 667479479, PL.MX_SCENE_MV)
    if funcLuaMenuCommand(C.EXIST_MENU, PL.MX_SCENE_MV) == true and not (okl and loading == true) then
      break
    end
  end
  coroutine.yield()
  PL.mx_scene_mv("CharacterReforged_MiximaxSceneModelBegin")
  local sent = 0
  for _, r in ipairs(rec) do
    local cmd = r[1]
    if r[2] == PL.MX_SCENE_MODEL_LAYER and not PL.MX_SCENE_MV_SKIP[cmd] then
      if cmd == @crc:CMND_CHARA_MODEL_CHANGE@ then
        PL.mx_scene_mv("CharacterReforged_MiximaxSceneModelCmd", 180466856 --[[motion]], 2263925137 --[[立ち1L]], 0, 0)
        PL.mx_scene_mv("CharacterReforged_MiximaxSceneModelCmd", cmd, 0, 9)
      else
        PL.mx_scene_mv("CharacterReforged_MiximaxSceneModelCmd", cmd, table.unpack(r, 4, r.n))
      end
      sent = sent + 1
    end
  end
  PL.mx_scene_mv("CharacterReforged_MiximaxSceneModelWatch")
  local ready, wait = nil, 0
  while wait < PL.MX_SCENE_PRELOAD_MAX * 2 do
    coroutine.yield()
    wait = wait + 1
    if VRFW.param.has(PL.MX_SCENE_MV_READY) then
      ready = VRFW.param.get(PL.MX_SCENE_MV_READY)
      VRFW.param.clear(PL.MX_SCENE_MV_READY)
      break
    end
  end
  pcall(Call, C.LOG, "skill_slots", "miximax scene preload", string.format("%08X", to_u32(h)),
    "model view", tostring(PL.mx_scene_mv_opened), "commands", sent, "ready", tostring(ready), "steps", steps, wait)
  return ready == 1
end

-- The fused model is rebuilt and cleared after the scene.
PL.MX_SCENE_FUSED = true
PL.MX_CMD.FORM_MODEL = @crc:CMND_VRFW_FORM_MODEL@      -- (hdl, form) -> look model id (0 = none)
PL.MX_CMD.FORM_CLEAR = @crc:CMND_VRFW_FORM_CLEAR@      -- ()
PL.MX_SCENE_SHADOW_LAYER = 858725131   -- mainmenu01_08_chara_3d_shadow

-- wait (coroutine) until this screen's model is built, at most n steps
function PL.mx_scene_model_wait(steps_max)
  local steps = 0
  while steps < steps_max do
    coroutine.yield()
    steps = steps + 1
    local okr, r = pcall(funcLuaMenuCommand, 1583438030, PL.MX_SCENE_MODEL_LAYER, 0, 0)
    if okr and r == true and steps >= 4 then
      return true, steps
    end
  end
  return false, steps
end

function PL.mx_scene_fused_look()
  if not PL.MX_SCENE_FUSED then
    return 0
  end
  local ok, id = pcall(funcLuaCommand, PL.MX_CMD.FORM_MODEL, n, 1)
  id = (ok and type(id) == "number") and id or 0
  if id ~= 0 then
    PL.mx_scene_model(n)
    local ready, steps = PL.mx_scene_model_wait(PL.MX_SCENE_PRELOAD_MAX)
    pcall(Call, C.LOG, "skill_slots", "miximax scene fused look", string.format("%08X", to_u32(id)),
      "ready", tostring(ready), "steps", steps)
  else
    pcall(Call, C.LOG, "skill_slots", "miximax scene fused look", "none", tostring(ok))
  end
  return id
end

-- Enables the mid-scene swap.
PL.MX_SCENE_SWAP = false
PL.MX_SCENE_SWAP_AT = 4.75
PL.MX_SCENE_SWAP_MAX = 30
PL.MX_SCENE_SWAP_SKIP = {[@crc:CMND_SET_CHARA_MODEL_SHADOW@] = true --[[shadow]], [@crc:CMND_OPEN_LAYER@] = true --[[open layer]],
  [@crc:CMND_UPDATE_CHARA_MODEL_POSE@] = true --[[pose]]}

-- Begins the swap.
function PL.mx_scene_swap_begin()
  local ok, id = pcall(funcLuaCommand, PL.MX_CMD.FORM_MODEL, n, 1)
  id = (ok and type(id) == "number") and id or 0
  if id == 0 then
    return 0, 0
  end
  local okc, _err, rec = PL.mx_scene_model_cmds(n)
  local sent = 0
  if okc then
    for _, r in ipairs(rec) do
      if r[2] == PL.MX_SCENE_MODEL_LAYER and not PL.MX_SCENE_SWAP_SKIP[r[1]] then
        pcall(funcLuaMenuCommand, table.unpack(r, 1, r.n))
        sent = sent + 1
      end
    end
  end
  return id, sent
end

-- Finishing shot: this screen puts the Miximax look on its model, the final event plays, then everything is restored.
PL.MX_SCENE_FINAL = true
PL.MX_CMD.WHITE_FADE = 4011714927
PL.MX_SCENE_END_BLACK = 0.25
PL.MX_SCENE_END_FADE = 0.15

function PL.mx_scene_final(ev2)
  local r = {look = 0, ready = false, steps = 0, st = "not run", bars = {}}
  pcall(funcLuaCommand, PL.MX_CMD.WHITE_FADE, 1, 0)
  pcall(Call, C.LOG, "skill_slots", "miximax scene final", ev2, "white held")
  pcall(funcLuaMenuCommand, 66378409 --[[resume]], EVT_MENU)
  local okf, id = pcall(PL.mx_scene_fused_look)
  r.look = (okf and type(id) == "number") and id or 0
  if r.look ~= 0 then
    -- read the state once more for the log
    local okr, ready = pcall(funcLuaMenuCommand, 1583438030, PL.MX_SCENE_MODEL_LAYER, 0, 0)
    r.ready = okr and ready == true
  end
  pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, PL.MX_SCENE_SHADOW_LAYER, 0, false)
  pcall(funcLuaMenuCommand, 369172623 --[[suspend]], EVT_MENU)
  -- The screen drew its button guide again when resumed for the look.
  r.bars = PL.mx_scene_bars(true)
  pcall(Call, C.LOG, "skill_slots", "miximax scene final look", string.format("%08X", to_u32(r.look)),
    "ready", tostring(r.ready))
  local okr, a, b = pcall(funcLuaCommand, @crc:CMND_RESERVE_EVENT@, CALC_CRC(ev2))
  pcall(Call, C.LOG, "skill_slots", "miximax scene final reserved", ev2, tostring(okr), tostring(a), tostring(b))
  if not okr then
    r.st = "reserve failed"
    return r
  end
  local okp, run, info = PL.mx_scene_run(a, ev2)
  pcall(Call, C.LOG, "skill_slots", "miximax scene final run", tostring(okp), tostring(run), tostring(info))
  if not okp or run ~= true then
    r.st = "run refused"
    return r
  end
  local frames, st, black = 0, "starting", false
  while frames < PL.MX_SCENE_MAX_FRAMES do
    coroutine.yield()
    frames = frames + 1
    local okt, s, secs, total = PL.mx_scene_tick()
    st = okt and s or "error"
    if st ~= "starting" and st ~= "running" then
      break
    end
    if not black and st == "running" and type(secs) == "number" and type(total) == "number" and total > 0
        and secs >= total - PL.MX_SCENE_END_BLACK then
      black = true
      funcLuaCommand(609722083 --[[fade]], 1, PL.MX_SCENE_END_FADE)
      pcall(Call, C.LOG, "skill_slots", "miximax scene final", "black before the end", secs, total)
    end
  end
  if not black then
    funcLuaCommand(609722083 --[[fade]], 1, 0)
    pcall(Call, C.LOG, "skill_slots", "miximax scene final", "black at the end", frames)
  end
  r.st = st
  pcall(Call, C.LOG, "skill_slots", "miximax scene final back", st, frames)
  return r
end

function PL.mx_scene_model_restore(fused)
  if fused ~= 0 then
    pcall(funcLuaCommand, PL.MX_CMD.FORM_CLEAR)
  end
  pcall(funcLuaMenuCommand, @crc:CMND_CLOSE_LAYER@, PL.MX_SCENE_MODEL_LAYER, 0)
  pcall(funcLuaMenuCommand, @crc:CMND_CLOSE_LAYER@, PL.MX_SCENE_SHADOW_LAYER, 0)
  coroutine.yield()
  pcall(funcLuaMenuCommand, @crc:CMND_OPEN_LAYER@, PL.MX_SCENE_MODEL_LAYER, 0)
  pcall(funcLuaMenuCommand, @crc:CMND_OPEN_LAYER@, PL.MX_SCENE_SHADOW_LAYER, 0)
  local ready, steps = PL.mx_scene_model_wait(PL.MX_SCENE_PRELOAD_MAX)
  pcall(Call, C.LOG, "skill_slots", "miximax scene model restored", "ready", tostring(ready), "steps", steps)
end

-- Runs after the scene.
function PL.mx_scene_preload_end()
  if PL.mx_scene_mv_opened then
    pcall(funcLuaCommand, @crc:CMND_CLOSE_MENU_OBJECT@, PL.MX_SCENE_MV)
    PL.mx_scene_mv_opened = false
  end
end
PL.MX_SCENE_ROUTES = {root = true, hub = true, inside = true}
-- "root", "hub", "inside" (the dock under another menu with no field behind) or nil, reason
function PL.mx_scene_context()
  local function has(m)
    return funcLuaMenuCommand(C.EXIST_MENU, m) == true
  end
  if not has(PL.MX_SCENE_DOCK) then
    return nil, "not the menu-scene team dock"
  end
  for _, mode in ipairs(PL.MX_SCENE_FIELD_MODES) do
    local okm, on = pcall(funcLuaCommand, @crc:CMND_VRFW_MODE_IS@, mode)
    if okm and on == true then
      return nil, "a field behind the dock: mode " .. mode
    end
  end
  local ctx = "inside"
  if has(PL.MX_SCENE_TOP) then
    ctx = "hub"
  elseif has(PL.MX_SCENE_DOCK_TOP) then
    ctx = "root"
  end
  if PL.MX_SCENE_ROUTES[ctx] ~= true then
    return nil, ctx .. " route off (PL.MX_SCENE_ROUTES)"
  end
  return ctx
end

-- Layers watched for diagnostics.
PL.MX_SCENE_WATCH_LAYERS = {
  {2917320188 --[[soccer11_05_equip_status_base]], 1},
  {858725131 --[[mainmenu01_08_chara_3d_shadow]], 1},
  {607716004 --[[soccer11_04_chara_status]], 1},
  {3214615867 --[[cr_pp_band]], 1},
  {1787290097 --[[cr_pp_slant]], 1},
  {626604567 --[[cr_pp_tag]], 1},
  {575058101 --[[mainmenu90_01_header]], 1},
  {3730537440 --[[vrfw_topbar_plate]], 8},
  {2854477426 --[[vrfw_topbar_icon]], 8},
  {3241819447 --[[team00_01_chara_card_for_move]], 1},
  {1973487846 --[[team00_01_chara_card_for_soccer]], 25},
  {3571911991 --[[team00_01_p1_chara_card_blank]], 25},
  {1658289671 --[[team00_01_chara_card_for_leader]], 1},
  {2290394976 --[[team00_01_p1_chara_card_blank_for_leader]], 1},
  {1559239586 --[[team00_11_p1_tactics_focus]], 1},
  {3367997069 --[[team01_02_list_item]], 25},
  {1922851874 --[[team01_04_p1_team_name_frame]], 1},
  {3926241346 --[[team01_04_p2_deck_name_frame]], 1},
  {3518110933 --[[mainmenu04_10_formation_base]], 1},
  {3321884270 --[[soccer11_02_formation_frame]], 1},
  {2296367164 --[[cmn05_01_cursor]], 1},
  {2279382105 --[[mainmenu90_31_doc_item]], 1},
  {3085812933 --[[better_ui_chr_box]], 25},
  {878737202 --[[team11_01_personal_plate]], 1},
}
PL.MX_CMD.IS_LAYER_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@

function PL.mx_scene_layer_log(step, menus, state)
  local now, checked, changed = {}, 0, 0
  for _, m in ipairs(menus) do
    if funcLuaMenuCommand(C.EXIST_MENU, m) == true then
      for _, w in ipairs(PL.MX_SCENE_WATCH_LAYERS) do
        for idx = 0, w[2] - 1 do
          local key = string.format("%08X %08X %d", to_u32(m), to_u32(w[1]), idx)
          local okv, vis = pcall(funcLuaMenuCommand, PL.MX_CMD.IS_LAYER_VISIBLE, w[1], idx, m)
          local value = (okv and vis == true) and "visible" or "hidden"
          if m == EVT_MENU then
            local oko, open = pcall(funcLuaMenuCommand, @crc:CMND_IS_OPEN_LAYER@, w[1], idx)
            value = value .. ((oko and open == true) and " open" or " closed")
          end
          now[key] = value
          checked = checked + 1
          if state ~= nil and state[key] ~= value then
            changed = changed + 1
            pcall(Call, C.LOG, "skill_slots", "miximax scene layer changed", step, key, tostring(state[key]), value)
          end
        end
      end
    end
  end
  pcall(Call, C.LOG, "skill_slots", "miximax scene layer check", step, "instances", checked, "changed", changed)
  return now
end

function PL.mx_scene_play()
  if not PL.MX_SCENE_ON or n == nil or n == 0 then
    return false
  end
  local ctx, why = PL.mx_scene_context()
  if ctx == nil then
    pcall(Call, C.LOG, "skill_slots", "miximax scene", "skipped: " .. why)
    return false
  end
  local okt0, t0 = PL.mx_scene_tick()
  if not okt0 or type(t0) ~= "string" then
    pcall(Call, C.LOG, "skill_slots", "miximax scene", "skipped: no live scene player")
    return false
  end
  local ok, go, ev, map, phdl, ev2, fxn = pcall(funcLuaCommand, PL.MX_CMD.SCENE, n)
  pcall(Call, C.LOG, "skill_slots", "miximax scene", ctx, tostring(ok), tostring(go), tostring(ev), tostring(map),
    tostring(phdl), "final", tostring(ev2), "effects installed", tostring(fxn))
  -- Handles two events (ev2 is not empty).
  local two = PL.MX_SCENE_FINAL and ok and type(ev2) == "string" and ev2 ~= ""
  if not ok or go ~= true or type(ev) ~= "string" then
    return false
  end
  PL.mx_scene_busy = true
  PL.mx_scene_top_bar(true)
  if ctx == "inside" then
    funcLuaCommand(@crc:CMND_BGM_PAUSE@)
  else
    funcLuaCommand(@crc:CMND_BGM_STOP@, 0.5)
  end
  funcLuaCommand(609722083 --[[fade]], 1, 0.5)
  while funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) do
    coroutine.yield()
  end
  -- Keeps the fused model under the black.
  local fused = (two or PL.MX_SCENE_SWAP) and 0 or PL.mx_scene_fused_look()
  local summary = {main = "not run", final = two and ev2 or "-", look = 0, ready = "-", final_run = "-"}
  local preloaded = PL.mx_scene_preload(phdl)
  local okr, a, b = pcall(funcLuaCommand, @crc:CMND_RESERVE_EVENT@, CALC_CRC(ev))
  pcall(Call, C.LOG, "skill_slots", "miximax scene reserved", ev, tostring(okr), tostring(a), tostring(b))
  local played = false
  local hidden = {}
  local hidden_only = {}
  local bars = {}
  local watch_menus = {}
  for _, m in ipairs(PL.MX_SCENE_HIDE) do watch_menus[#watch_menus + 1] = m end
  for _, m in ipairs(PL.MX_SCENE_HIDE_ONLY) do watch_menus[#watch_menus + 1] = m end
  local watch = PL.mx_scene_layer_log("before the hide", watch_menus)
  if okr then
    for _, m in ipairs(PL.MX_SCENE_HIDE) do
      if funcLuaMenuCommand(C.EXIST_MENU, m) == true then
        funcLuaMenuCommand(369172623 --[[suspend]], m)
        funcLuaMenuCommand(1670867360 --[[hide (movie)]], 1, m)
        hidden[#hidden + 1] = m
      end
    end
    for _, m in ipairs(PL.MX_SCENE_HIDE_ONLY) do
      if funcLuaMenuCommand(C.EXIST_MENU, m) == true then
        funcLuaMenuCommand(1670867360 --[[hide (movie)]], 1, m)
        hidden_only[#hidden_only + 1] = m
      end
    end
    bars = PL.mx_scene_bars(true)
    if ctx ~= "inside" then
      funcLuaCommand(@crc:CMND_EXEC_CRAFT_OBJ_ID@, 623523592 --[[bg10000]])
    end
    local okp, run, info = PL.mx_scene_run(a, ev)
    pcall(Call, C.LOG, "skill_slots", "miximax scene run", tostring(okp), tostring(run), tostring(info))
    if okp and run == true then
      local frames, st = 0, "starting"
      local msg = 0                      -- 0 not yet, 1 open, 2 closed
      local swap, swap_steps = 0, 0      -- 0 not yet, 1 waiting for the fused model, 2 done
      while frames < PL.MX_SCENE_MAX_FRAMES do
        coroutine.yield()
        frames = frames + 1
        local okt, s, secs = PL.mx_scene_tick()
        st = okt and s or "error"
        if st ~= "starting" and st ~= "running" then
          break
        end
        if PL.MX_SCENE_SWAP and swap == 0 and st == "running" and type(secs) == "number" and secs >= PL.MX_SCENE_SWAP_AT then
          local id, sent = PL.mx_scene_swap_begin()
          fused = id
          swap = id ~= 0 and 1 or 2
          pcall(Call, C.LOG, "skill_slots", "miximax scene swap", string.format("%08X", to_u32(id)),
            "commands", sent, "at", secs)
        elseif swap == 1 then
          swap_steps = swap_steps + 1
          local okr, r = pcall(funcLuaMenuCommand, 1583438030, PL.MX_SCENE_MODEL_LAYER, 0, 0)
          if (okr and r == true and swap_steps >= 4) or swap_steps >= PL.MX_SCENE_SWAP_MAX then
            swap = 2
            pcall(Call, C.LOG, "skill_slots", "miximax scene swap ready", tostring(okr and r == true), "steps",
              swap_steps, "at", secs)
          end
        end
        if PL.MX_SCENE_MSG and st == "running" and type(secs) == "number" then
          if msg == 0 and secs >= PL.MX_SCENE_MSG_AT then
            msg = 1
            local fusion = PL.mx_get()
            pcall(funcLuaCommand, C.MSG_OPEN, PL.txt(PL.MX_TX.ASSIGNED, fusion ~= nil and PL.mx_chara_name(fusion.chara) or ""), 0, 0, 0,
              0, 0, false)
            pcall(Call, C.LOG, "skill_slots", "miximax scene message", "open", secs)
          elseif msg == 1 and secs >= PL.MX_SCENE_MSG_END then
            msg = 2
            pcall(funcLuaCommand, @crc:CMND_CLOSE_MENU_OBJECT@, PL.MX_SCENE_MSG_MENU)
            pcall(Call, C.LOG, "skill_slots", "miximax scene message", "closed", secs)
          end
        end
      end
      if msg == 1 then
        pcall(funcLuaCommand, @crc:CMND_CLOSE_MENU_OBJECT@, PL.MX_SCENE_MSG_MENU)
      end
      played = st == "done"
      summary.main = st
      pcall(Call, C.LOG, "skill_slots", "miximax scene back", st, frames)
      if played and two then
        local r = PL.mx_scene_final(ev2)
        fused = r.look
        summary.look, summary.ready, summary.final_run = r.look, tostring(r.ready), r.st
        for _, b in ipairs(r.bars or {}) do
          bars[#bars + 1] = b
        end
      end
    else
      summary.main = "run refused"
    end
  end
  pcall(Call, C.LOG, "skill_slots", "miximax scene summary", "actors base + partner (partner model ready",
    tostring(preloaded) .. ")", "main", summary.main, "final", summary.final, "look", string.format("%08X", to_u32(summary.look)),
    "look ready", summary.ready, "final run", summary.final_run, "effects installed", tostring(fxn),
    "(drawn: see mods: trace lines)")
  PL.mx_scene_bars(false, bars)
  for i = #hidden_only, 1, -1 do
    funcLuaMenuCommand(3257327861 --[[show again]], hidden_only[i])
  end
  for i = #hidden, 1, -1 do
    funcLuaMenuCommand(3257327861 --[[show again]], hidden[i])
  end
  watch = PL.mx_scene_layer_log("after show again", watch_menus, watch)
  for i = #hidden, 1, -1 do
    funcLuaMenuCommand(66378409 --[[resume]], hidden[i])
  end
  PL.mx_scene_preload_end()
  PL.mx_scene_model_restore(fused)
  watch = PL.mx_scene_layer_log("after resume and model restore", watch_menus, watch)
  pcall(funcLuaCommand, PL.MX_CMD.SCENE_END, played and "played over the menus" or "not played")
  PL.mx_scene_top_bar(false)
  PL.mx_scene_busy = false
  funcLuaCommand(@crc:CMND_BGM_RESUME@)
  funcLuaCommand(609722083 --[[fade]], 0, 0.3)
  while funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) do
    coroutine.yield()
  end
  watch = PL.mx_scene_layer_log("page back", watch_menus, watch)
  PL.deferred[#PL.deferred + 1] = coroutine.create(function()
    for _ = 1, 60 do
      coroutine.yield()
    end
    PL.mx_scene_layer_log("60 steps after", watch_menus, watch)
  end)
  return played
end

-- Reopens this menu (back from the scene, or any later visit).
PL.mx_scene_prev_init = OnInit
function OnInit()
  local okS, on, base = pcall(funcLuaCommand, PL.MX_CMD.SCENE_STATE)
  pcall(funcLuaCommand, PL.MX_CMD.SCENE_END, "skill slot menu opened")
  local r = PL.mx_scene_prev_init()
  if okS and on == true and type(base) == "number" and n ~= nil and to_u32(base) == to_u32(n) then
    pcall(Call, C.LOG, "skill_slots", "miximax scene: back on the card", string.format("%08X", to_u32(n)))
    PL.deferred[#PL.deferred + 1] = coroutine.create(PL.mx_scene_back_message)
  end
  return r
end

function PL.mx_scene_back_message()
  for _ = 1, 20 do                     -- the screen's open animation / first rows
    coroutine.yield()
  end
  while funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) do
    coroutine.yield()
  end
  local f = PL.mx_get()
  local name = f ~= nil and PL.mx_chara_name(f.chara) or ""
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  VRFW.question.notice(PL.txt(PL.MX_TX.ASSIGNED, name))
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end

function PL.mx_ask_remove()
  local f = PL.mx_get()
  if f == nil then
    return false
  end
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  local yes = VRFW.question.ask(PL.txt(PL.MX_TX.ASK_REMOVE, PL.mx_chara_name(f.chara)))
  if yes then
    PL.mx_removing = true
    pcall(PL.mx_prev_restore, 0)                    -- the Hiper slot emptied (native Eliminar path)
    PL.mx_removing = false
    PL.mx_clear()
  else
    funcLuaCommand(C.SE, SE_BACK)
  end
  RefreshRows()
  UpdateEquipItemInfo()
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
  return yes
end

PL.mx_prev_pick = CharacterReforgedSkillTablePickCoroutine
function CharacterReforgedSkillTablePickCoroutine(row)
  if row == 0 and Skill(0) == PL.MX_FUSION and PL.mx_get() ~= nil then
    PL.mx_ask_remove()                               -- no picker while a fusion is the Hiper
    return
  end
  if row == 0 then
    VRFW.param.clear(PL.MX_KEY_DEL)
    VRFW.param.clear(PL.MX_KEY_PRIME)
    P_Set(PL.MX_KEY_BASE, n)                     -- the picker checks the retail miximaxes against this player
    if CharacterReforged.skill_table_is_prime() then
      P_Set(PL.MX_KEY_PRIME, 1)
    end
  end
  -- The loader drops "Crear miximax" and the fusion carrier from every Habilidades list.
  local flag = row == 0 and not CharacterReforged.skill_table_is_prime()
  pcall(funcLuaCommand, @crc:CMND_VRFW_UI_FLAG_SET@, 4054855615, flag and 1 or 0)
  local ok, err = pcall(PL.mx_prev_pick, row)
  pcall(funcLuaCommand, @crc:CMND_VRFW_UI_FLAG_SET@, 4054855615, 0)
  if not ok then
    error(err, 0)
  end
end

-- Eliminar on the Hiper row while it holds the fusion
PL.mx_prev_restore = CharacterReforged.skill_table_restore_coroutine
function CharacterReforged.skill_table_restore_coroutine(row)
  if row == 0 and Skill(0) == PL.MX_FUSION and not PL.mx_removing then
    PL.mx_ask_remove()                               -- Eliminar on the row: the same confirm
    return
  end
  PL.mx_prev_restore(row)
end

-- Wraps the Hiper row with a fusion.
PL.mx_prev_row = UpdateEquipListItem
function UpdateEquipListItem(a1)
  PL.mx_prev_row(a1)
  if a1 ~= 0 then
    return
  end
  local okf, f = pcall(PL.mx_get)
  if okf and f ~= nil and Skill(0) == PL.MX_FUSION then
    local info = GetEquipListItemInfo(GetEquipType(0))
    local text = Name(PL.MX_FUSION)             -- the move's name only, never the player's
    if SPECIAL_LABEL ~= "" then
      text = SPECIAL_LABEL .. "   " .. text
    end
    funcLuaMenuCommand(C.TEXT, L_ROW, info.itemTextName, text, 0)
  end
end

-- the second full-size retail aura header under the move row (layer character_reforged_ss_aura2)
PL.L_AURA2 = 1281343292
PL.AURA_FACE_TYPE = {[0] = 8, 8, 12, 14}          -- retail SwapLayerFaceIconTex type per aura type

function PL.mx_detail(f, team_info)
  local A = PL.MX_LAYER
  if not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, A) then
    return false
  end
  PL.detail_hide_all()
  PL.open(A)
  PL.open(PL.L_HIPER)
  -- Reads the band's element.
  local _, el = funcLuaCommand(C.SKILL_INFO, f.move, 7)
  el = (type(el) == "number" and el >= 1 and el <= 5) and el or 1
  local bands = {3558327990, 1293850380, 974759834, 2759668281, 3547988655}   -- mixi_base01..05 (team00_30)
  funcLuaMenuCommand(C.SPRITE, A, 2815298114 --[[team00_30 <LG>]], bands[el], 1716659057 --[[fs_base01]], 0, 0)
  funcLuaMenuCommand(C.SPRITE, A, 2320109963 --[[icon_common]], 2185069032 --[[icon_sp_area07]], 4285917355 --[[icon_fs_area_dmy01]], 0, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, A, 2449339029 --[[_icon_fs_dmy01]], false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, A, 1605611365, true, 0)
  PL.aura_clean(A)

  local pname = PL.mx_chara_name(f.chara)
  funcLuaMenuCommand(C.TEXT, A, 2915321899 --[[_text_fs01]], Name(PL.MX_FUSION), 0)
  funcLuaMenuCommand(2158717427, A, 622567014 --[[_pos_page03]], true, 0)
  -- Shows no text under a miximax (the gains live in the plate's Atributos L3 view) and no empty quote bar.
  funcLuaMenuCommand(C.TEXT, A, 2956552560 --[[_text_flavor02]], "", 0)
  funcLuaMenuCommand(2735666188, A, 2956552560, false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, A, 728354709, false, 0)
  local face = f.face or f.chara
  if face ~= nil and face ~= 0 then
    pcall(PL.face_reset, A)
    -- Mirrors retail UpdateMixiMaxDetailInfo; VRFW.face_icon shows the mesh once the texture has loaded.
    pcall(funcLuaCommand, @crc:CMND_VRFW_APPEARANCE@, "skill_panel", face)   -- the partner on purpose (module appearance)
    local has = funcLuaMenuCommand(2208175668, face)
    VRFW.face_icon.forget(A, 0)                     -- drawn again on every fill: the retail fill may change the mesh
    local r = VRFW.face_icon.face(A, 0, face, 478320441 --[[_icon_chr_dmy01]], 3237726902 --[[icon_chr_dmy01]],
      has and {art = 12} or nil)
    r = tostring(has) .. "/" .. tostring(r)
    pcall(Call, C.LOG, "skill_slots", "miximax portrait", "chara", tostring(f.chara), "face key", tostring(face),
      "param", string.format("%08X", f.partner or 0), tostring(r))
  else
    funcLuaMenuCommand(C.MESH_VISIBLE, A, 478320441, false, 0)
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, A, 0, true)
  local L = PL.L_HIPER
  for _, m in ipairs(PL.HIPER_HIDE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, 0)
  end
  for _, p in ipairs(PL.HIPER_HIDE_POS) do
    funcLuaMenuCommand(2158717427, L, p, false, 0)
  end
  for _, x in ipairs(PL.HIPER_HIDE_TEXT) do
    funcLuaMenuCommand(2735666188, L, x, false, 0)
  end
  funcLuaMenuCommand(1233047821, L, 0, 2223127589, false)
  -- Shows why a stored miximax gives nothing in a match: the retail alert icon, a short label and the reason under the header.
  local warned = PL.pair_warning(A, f.warning)
  funcLuaMenuCommand(2158717427, L, 2313134961 --[[_pos_area01]], f.best == true or warned, 0)
  funcLuaMenuCommand(C.TEXT, L, 1899787537 --[[_text_area01]], warned and f.warning_label or (f.best and "Best Match" or ""), 0)
  funcLuaMenuCommand(2735666188, L, 1899787537, f.best == true or warned, 0)
  PL.move_row(L, f.move, team_info, 0, false, f.phdl)   -- the partner owns the move: coloured, not greyed
  pcall(Call, C.LOG, "skill_slots", "miximax move row", string.format("%08X", to_u32(f.move or 0)),
    "owner", tostring(f.phdl), "shown", tostring(funcLuaMenuCommand(@crc:CMND_IS_LAYER_VISIBLE@, PL.L_HROW, 0)))
  funcLuaMenuCommand(C.LAYER_VISIBLE, PL.L_HROW, 1, false)
  -- the miximax tab shows the miximax only (no attached keshin / totem header)
  funcLuaMenuCommand(C.LAYER_VISIBLE, PL.L_AURA2, 0, false)
  funcLuaMenuCommand(C.LAYER_VISIBLE, PL.MX_LAYER, 0, true)
  -- the power cube and the tag pills of both layers off
  for _, m in ipairs({4122450641, 3516146179 --[[_area_base01]]}) do
    funcLuaMenuCommand(C.MESH_VISIBLE, A, m, false, 0)
    funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, 0)
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, true)
  character_reforged_detail_on = true
  PL.hiper_wide = true
  pcall(CharacterReforged.skill_table_detail_graph_sync)
  pcall(PL.set_detail_layout, "mx")
  return true
end

-- the declared row actions' guide entries are added by graft skill_table_host over this (no R3 view switch)
function PL.mx_guide_add(t, i, c, o)
end

-- R3 does nothing on this screen 
function PL.mx_poll_r3()
end

PL.mx_prev_item_info = UpdateEquipItemInfo
function UpdateEquipItemInfo()
  PL.mx_prev_item_info()
  if n14 == L_BTN then
    return
  end
  local row = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
  if row ~= 0 then
    return
  end
  local okf, f = pcall(PL.mx_get)
  if okf and f ~= nil and Skill(0) == PL.MX_FUSION then
    local _, team_info = GetSoccerTeamInfo(0)
    local ok, shown = pcall(PL.mx_detail, f, team_info)
    if ok and shown then
      SetVisibleEquipInfoWindow(false)
    else
      pcall(Call, C.LOG, "skill_slots", "miximax panel", tostring(ok), tostring(shown))
    end
  end
end

-- The retail OnOpenLayer of soccer11_05_equip_status_base yields
PL.deferred = {}
PL.mx_prev_open_layer2 = OnOpenLayer
function OnOpenLayer(a1, a2)
  local _, main = coroutine.running()
  if a1 == 2917320188 --[[soccer11_05_equip_status_base]] and main then
    local co = coroutine.create(function() PL.mx_prev_open_layer2(a1, a2) end)
    local ok, err = coroutine.resume(co)
    if not ok then
      pcall(Call, C.LOG, "skill_slots", "deferred open layer error", tostring(err))
    elseif coroutine.status(co) ~= "dead" then
      PL.deferred[#PL.deferred + 1] = co
    end
    return
  end
  return PL.mx_prev_open_layer2(a1, a2)
end
PL.mx_prev_step = Step
function Step(...)
  local r = PL.mx_prev_step ~= nil and PL.mx_prev_step(...) or nil
  if PL.hiper_wide then
    funcLuaMenuCommand(C.MESH_VISIBLE, 2917320188 --[[soccer11_05_equip_status_base]], 2682382918 --[[_sixth_base01]],
      false, 0)
  end
  for i = #PL.deferred, 1, -1 do
    local co = PL.deferred[i]
    local ok, err = coroutine.resume(co)
    if not ok then
      pcall(Call, C.LOG, "skill_slots", "deferred open layer error", tostring(err))
    end
    if not ok or coroutine.status(co) == "dead" then
      table.remove(PL.deferred, i)
    end
  end
  return r
end

-- ===== Miximax END =====
