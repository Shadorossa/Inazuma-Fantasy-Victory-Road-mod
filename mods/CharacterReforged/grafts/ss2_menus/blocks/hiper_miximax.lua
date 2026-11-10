PL.MX_CMD = {FUSION_GET = @crc:CMND_CHARACTERREFORGED_MIXIMAX_FUSION_GET@,
  FUSION_CLEAR = @crc:CMND_CHARACTERREFORGED_MIXIMAX_CLEAR@}
-- (text ids)
PL.MX_TX = {ASSIGNED = 544123214 --[[skill_table_mx_assigned]], ASK_REMOVE = 1297342256 --[[skill_table_mx_ask_remove]]}
PL.MX_LAYER = 3679282495                         -- team00_30_aura_mixi_max_detail_info

function PL.mx_param(hdl)
  local ok, p = pcall(funcLuaCommand, 1131797651, hdl, 4)
  return ok and type(p) == "number" and to_u32(p) or 0
end

function PL.mx_chara_name(chara)
  local ok, a, b = pcall(funcLuaCommand, @crc:CMND_GET_CHARA_INFO@, chara, 10)
  if ok and type(b) == "string" then
    return b
  elseif ok and type(a) == "string" then
    return a
  end
  return string.format("%08X", to_u32(chara or 0))
end

-- Returns the fusion of the current player (the running fusion and the partner's handle).
function PL.mx_get()
  local h = PL.mx_test_hdl or n                    -- (mx_test_hdl: harness only, nil in game)
  if h == nil or h == 0 then
    return nil
  end
  local ok, exists, partner, m1, m2, chara, best, phdl = pcall(funcLuaCommand, PL.MX_CMD.FUSION_GET, h)
  if not ok or exists ~= true then
    return nil
  end
  local f = {partner = to_u32(partner or 0), move = to_u32(m1 or 0), move2 = to_u32(m2 or 0), chara = chara or 0,
    best = best == true or best == 1, phdl = type(phdl) == "number" and phdl or 0}
  -- the partner's face key (from 347353059(param), as the retail miximax window)
  local okk, face = pcall(funcLuaCommand, 347353059, f.partner)
  f.face = (okk and type(face) == "number" and face ~= 0) and face or f.chara
  return f
end

-- list rows of the three Miximax lists (the custom-passive list window, generic modes)
function PL.mx_row_base(L, k, e, selected)
  PL.row_full(L, k)
  for _, m in ipairs(PL.SSROW_HIDE) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L, m, false, k)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.SSROW_BASE_ON, selected, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.SSROW_BASE_OFF, not selected, k)
  local name = e.grey and ("[CGRAYOUT04]" .. e.name .. "[C]") or e.name
  funcLuaMenuCommand(C.TEXT, L, PL.SSROW_TEXT_ON, name, k)
  funcLuaMenuCommand(C.TEXT, L, PL.SSROW_TEXT_OFF, name, k)
  funcLuaMenuCommand(2735666188 --[[text visible]], L, PL.SSROW_TEXT_ON, selected, k)
  funcLuaMenuCommand(2735666188 --[[text visible]], L, PL.SSROW_TEXT_OFF, not selected, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 2164615260 --[[_icon_sp_area_dmy01]], false, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 2384755812 --[[_icon_sixth_dmy01]], false, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 2309656400 --[[_icon_check01]], e.check == true, k)
  funcLuaMenuCommand(POSITION_VISIBLE, L, 442049775 --[[_pos_equip01]], false, k)
  funcLuaMenuCommand(POSITION_VISIBLE, L, 3426045766 --[[_pos_have01]], e.num ~= nil, k)
  funcLuaMenuCommand(1233047821 --[[number visible]], L, k, 3974820126 --[[num_equip01]], false)
  funcLuaMenuCommand(1233047821 --[[number visible]], L, k, 3334923667 --[[num_have01]], e.num ~= nil)
  if e.num ~= nil then
    funcLuaMenuCommand(C.MESH_VISIBLE, L, 2037408502 --[[_icon_have01]], false, k)
    local idx = funcLuaMenuCommand(@crc:CMND_SEARCH_PRIM_INDEX@, L, k, 3334923667)
    if type(idx) == "number" and idx >= 0 then
      funcLuaMenuCommand(3609943765 --[[set number]], L, k, idx, e.num)
    end
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 1255155594 --[[_icon_cmd_type_dmy01]], false, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, 2172872396 --[[_icon_cmd_type_base01]], false, k)
end

function PL.mx_clear()
  local base = PL.mx_param(n)
  local okc, cleared = pcall(funcLuaCommand, PL.MX_CMD.FUSION_CLEAR, n)
  if okc and cleared == true then
    local have = funcLuaCommand(PL.ITEM_NUM, PL.MX_FUSION)
    if type(have) == "number" and have > 0 then
      funcLuaCommand(PL.DEL_ITEM, PL.MX_FUSION, 1)
    end
  end
  pcall(Call, C.LOG, "skill_slots", "miximax clear", string.format("%08X", base))
  funcLuaCommand(C.SE, SE_REMOVE)
end

PL.MX_CREATE = 2771212752              -- "Crear miximax" (Character Reforged's create item, never equipped)
PL.MX_FUSION = 2450842569                     -- the fusion aura (the Hiper slot holds it)
PL.MX_KEY_DEL = 99760714            -- pick block: Eliminar on a list entry
PL.MX_KEY_PRIME = 2900901523          -- pick block: "Crear miximax" greyed (Prime base)
PL.MX_KEY_BASE = 1847499704            -- pick block: the base player's handle

-- Handles the Hiper picker's result.
PL.mx_prev_equip = CharacterReforged.skill_table_equip
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  local del = VRFW.param.has(PL.MX_KEY_DEL)
  VRFW.param.clear(PL.MX_KEY_DEL)
  if row == 0 and del and skill == PL.MX_FUSION then
    PL.mx_clear()
    if Skill(0) == PL.MX_FUSION then
      CharacterReforged.skill_table_restore_coroutine(0)
    end
    return
  end
  return PL.mx_prev_equip(row, skill, inv_hint, cur)
end
