-- ===== Move plate rows + own list layers BEGIN ===== The 6 move rows drawn as move plates on layer
PL.RP = {
  ON = true,
  L = 1876016261 --[[character_reforged_ss_row_plate]],
  PRIO = 553,                                      -- the list row is 552 (soccer11_08 m_drawPriority)
  ROW_BASE = 970690259 --[[_item_list_base01]],    -- the row's white / navy base, hidden under the plate
  -- The plate's own parts, sprites and states.
  IS_OPEN = @crc:CMND_IS_OPEN_LAYER@, IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@,
  want = {},
  -- The mix half's lock: the same plate on its own layer, instance r on list row r (only instance 0, the Hiper row, is drawn).
  MIX_LOCK = 4262169076 --[[character_reforged_ss_mix_lock]],
  mix_lock_want = {},
}
-- Each plate layer of the rows and the table of the instances it wants shown.
PL.RP.LAYERS = {[PL.RP.L] = PL.RP.want, [PL.RP.MIX_LOCK] = PL.RP.mix_lock_want}

function PL.row_plate(r, skill, locked, need, fixed, inactive)
  local P = PL.RP
  local L = P.L
  P.want[r] = false
  if not P.ON or r < 1 or r >= ROW_NUM or SetupCharaSkillItem == nil or type(VRFW.ui_plates) ~= "table"
      or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
    return false
  end
  skill = skill or 0
  local ok, err = VRFW.ui_plates.move_plate.row(L, r, n, skill, {page = L_ROW, open = PL.open, restore = {nil, L_DETAIL, 0, nil, nil},
    locked = locked, need = need, fixed = fixed, lock_color = PL.LOCK_COLOR,
    name = skill ~= 0 and (inactive and (PL.LOCK_COLOR .. Name(skill) .. "[C]") or Name(skill)) or nil,
    suffix = inactive and "" or nil, empty_text = "", log = true})
  if not ok then
    pcall(Call, C.LOG, "skill_slots", "row plate failed", r, string.format("%08X", to_u32(skill)), tostring(err))
    return false
  end
  P.want[r] = true
  pcall(PL.row_plate_sync)
  return true
end

-- a plate shows while it is wanted and its list row is visible (the lists covering the column hide the rows)
function PL.row_plate_sync(step)
  local P = PL.RP
  if type(VRFW.ui_plates) == "table" then
    VRFW.ui_plates.move_plate.pump(step)
  end
  for L, want in pairs(P.LAYERS) do
    if funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
      for r = 0, ROW_NUM - 1 do
        if funcLuaMenuCommand(P.IS_OPEN, L, r) then
          local v = want[r] == true and funcLuaMenuCommand(P.IS_VISIBLE, L_ROW, r) == true
          if (funcLuaMenuCommand(P.IS_VISIBLE, L, r) == true) ~= v then
            funcLuaMenuCommand(C.LAYER_VISIBLE, L, r, v)
          end
        end
      end
    end
  end
end

-- the combo partner picker's own list frame and rows (character_reforged_cpk_list / character_reforged_cpk_row), passed to PL.pop_list
PL.L_CPK_LIST = 1524569892 --[[character_reforged_cpk_list]]
PL.L_CPK_ROW = 2452464201 --[[character_reforged_cpk_row]]
PL.CPK_ROWS = 9
PL.PTR_CPK = {-98, 970, 60}                        -- the row's visible plate (75 high sprite, ~56 opaque; step 68)
-- Scroll arrows of that list (layer character_reforged_cpk_arrow).
PL.L_CPK_ARROW = 4148594006 --[[character_reforged_cpk_arrow]]
PL.CPK_ARROW_UP = 1288675512 --[[_pos_arrow_u01]]
PL.CPK_ARROW_DOWN = 1361799679 --[[_pos_arrow_d01]]

function PL.list_arrows(show, first, nr, total, list_layer)
  local L = PL.L_CPK_ARROW
  if list_layer ~= PL.L_CPK_LIST or not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L) then
    return
  end
  local up = show and first > 0
  local down = show and first + nr < total
  if up or down then
    PL.open(L)
    funcLuaMenuCommand(POSITION_VISIBLE, L, PL.CPK_ARROW_UP, up, 0)
    funcLuaMenuCommand(POSITION_VISIBLE, L, PL.CPK_ARROW_DOWN, down, 0)
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L, 0, up or down)
end

PL.rp_prev_setup_layer = OnSetupLayer
function OnSetupLayer(a1, a2)
  if PL.RP.LAYERS[a1] ~= nil then
    funcLuaMenuCommand(Priority, a1, a2, PL.RP.PRIO, true)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == PL.L_CPK_LIST then
    funcLuaMenuCommand(Priority, a1, a2, 450, true)
    for _, pos in ipairs({1839509013 --[[_pos_scr_base01]], 1060758565 --[[_pos_scr_obj01]]}) do
      funcLuaMenuCommand(POSITION_VISIBLE, a1, pos, false, a2)
    end
    funcLuaMenuCommand(C.MESH_VISIBLE, a1, 3660005257 --[[_text_list_empty01]], false, a2)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == PL.L_CPK_ROW then
    funcLuaMenuCommand(Priority, a1, a2, 451, true)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == PL.L_CPK_ARROW then
    funcLuaMenuCommand(Priority, a1, a2, 452, true)
    for _, pos in ipairs({1839509013 --[[_pos_scr_base01]], 1060758565 --[[_pos_scr_obj01]]}) do
      funcLuaMenuCommand(POSITION_VISIBLE, a1, pos, false, a2)
    end
    funcLuaMenuCommand(C.MESH_VISIBLE, a1, 970690259 --[[_item_list_base01]], false, a2)
    funcLuaMenuCommand(C.MESH_VISIBLE, a1, 3037571460 --[[_text_list01]], false, a2)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  end
  return PL.rp_prev_setup_layer(a1, a2)
end

PL.rp_prev_open_layer = OnOpenLayer
function OnOpenLayer(a1, a2)
  if PL.RP.LAYERS[a1] ~= nil then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)   -- PL.row_plate_sync shows it (next Step)
    return
  elseif a1 == PL.L_CPK_LIST or a1 == PL.L_CPK_ROW or a1 == PL.L_CPK_ARROW then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  end
  return PL.rp_prev_open_layer(a1, a2)
end

PL.rp_prev_step = Step
function Step(...)
  local r = PL.rp_prev_step ~= nil and PL.rp_prev_step(...) or nil
  pcall(PL.row_plate_sync, true)
  return r
end
-- ===== Move plate rows + own list layers END =====
