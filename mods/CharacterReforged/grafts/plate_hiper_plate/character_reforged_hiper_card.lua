-- ===== EVT hiper_card BEGIN ===== (shared Hiper card component; docs/game/hiper/plate-hiper-page.md «Shared card»)
CharacterReforged.hyper_card = CharacterReforged.hyper_card or {}
CharacterReforged.hyper_card.SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@       -- (skill, 13 aura type | 16 change skill | 11 cost)
CharacterReforged.hyper_card.MC_TYPE = 6
CharacterReforged.hyper_card.TEAM02 = 3964676290           -- #/menu/102_team/team02/team02_02/<LG>/team02_02.g4tx
CharacterReforged.hyper_card.SP_RGB = {0.32, 0.72, 1.0}
CharacterReforged.hyper_card.TENS_RGB = {0.99, 0.51, 0.0}
CharacterReforged.hyper_card.PEG_RGB = {0.72, 0.42, 1.0}   -- the PEG gauge / label / number tint (the match HUD's PEG purple)

function CharacterReforged.hyper_card.log(...)
  CharacterReforged.hyper_card.logger = CharacterReforged.hyper_card.logger or VRFW.logger.new("hiper_card")
  CharacterReforged.hyper_card.logger(...)
end

function CharacterReforged.hyper_card.aura_type(skill)
  local ok, t = funcLuaCommand(CharacterReforged.hyper_card.SKILL_INFO, skill or 0, 13)
  if ok and type(t) == "number" then
    return t
  end
  return nil
end

function CharacterReforged.hyper_card.is_mode_change(skill)
  return CharacterReforged.hyper_card.aura_type(skill) == CharacterReforged.hyper_card.MC_TYPE
end

CharacterReforged.hyper_card.BANDS = {
  [0] = {1716659057, 4284183243, 2287747677, 372824062, 1631577960},   -- fs_base     keshin
  [1] = {1742805750, 4276636492, 2314173402, 395046521, 1619844847},   -- fsa_base    keshin armed
  [2] = {3558327990, 1293850380, 974759834, 2759668281, 3547988655},   -- mixi_base   miximax
  [3] = {2619781135, 87024053, 1915277603, 3964421248, 2605413398},
  [4] = {1514509020, 3276587878, 3024876528, 707749459, 1562924741},   -- kizuna_base kizuna trans
  [5] = {4250578944, 1683218874, 324325676, 2368750735, 4197938201},   -- power_base  awakening power
  [6] = {3293713115, 1566262113, 710702071, 3023627860, 3275740866},   -- mode_base   mode change
}
-- Aura-type icon of the band's left slot (icon_common.g4tx onto icon_fs_area_dmy01).
CharacterReforged.hyper_card.TYPE_ICON = {[0] = 1815339204, 4114264446, 2185069032, 310549625, 1703259375, 88220938, 1917130140}
CharacterReforged.hyper_card.TEX_T30 = 2815298114         -- #/menu/102_team/team00/team00_30/<LG>/team00_30.g4tx

-- Returns the band sprite of an aura skill.
function CharacterReforged.hyper_card.band(skill)
  local t = CharacterReforged.hyper_card.aura_type(skill)
  local fam = t ~= nil and CharacterReforged.hyper_card.BANDS[t] or nil
  if fam == nil then
    return nil
  end
  local ok, e = funcLuaCommand(CharacterReforged.hyper_card.SKILL_INFO, skill, 7)
  if ok and e == 5 then
    local okc, common = funcLuaCommand(800895612, skill)
    if okc and common then
      e = 6
    end
  end
  local band = ok and type(e) == "number" and fam[e] or nil
  return band or fam[1]
end

-- Sets band, type icon and name on a team00_30 aura window (or its clone) instance.
function CharacterReforged.hyper_card.header(A, skill, name, inst)
  inst = inst or 0
  local band = CharacterReforged.hyper_card.band(skill)
  if band ~= nil then
    funcLuaMenuCommand(558735651, A, CharacterReforged.hyper_card.TEX_T30, band, 1716659057 --[[fs_base01]], 0, inst)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, A, 734954092 --[[_fs_base01]], true, inst)
  local t = CharacterReforged.hyper_card.aura_type(skill)
  local icon = t ~= nil and CharacterReforged.hyper_card.TYPE_ICON[t] or nil
  if icon ~= nil then
    funcLuaMenuCommand(558735651, A, 2320109963 --[[icon_common.g4tx]], icon, 4285917355 --[[icon_fs_area_dmy01]], 0, inst)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, A, 1605611365 --[[_icon_fs_area_dmy01]], icon ~= nil, inst)
  if type(name) == "string" then
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, A, 2915321899 --[[_text_fs01]], name, inst)
    funcLuaMenuCommand(2735666188, A, 2915321899, true, inst)
  end
  return icon
end

function CharacterReforged.hyper_card.desc(skill)
  local ok, id = funcLuaCommand(CharacterReforged.hyper_card.SKILL_INFO, skill, 5)
  if not ok or id == nil then
    return ""
  end
  local okt, s = pcall(funcLuaCommand, 4113915188, id)
  return (okt and type(s) == "string") and s or ""
end

function CharacterReforged.hyper_card.mc_ask(chara)
  local page = type(CharacterReforged) == "table" and CharacterReforged.page or nil
  if type(page) ~= "table" or type(page.mode_change_partner) ~= "function" then
    return false
  end
  local ok, pparam, pchara, phdl, label, in_team = pcall(page.mode_change_partner, chara)
  if ok and type(pparam) == "number" and pparam ~= 0 then
    return true, true, pparam, pchara, phdl, label, in_team
  end
  return false
end

function CharacterReforged.hyper_card.mc_get(chara, skill)
  if chara == nil or chara == 0 or not CharacterReforged.hyper_card.is_mode_change(skill) then
    return nil
  end
  local ok, exists, pparam, pchara, phdl, _, in_team = CharacterReforged.hyper_card.mc_ask(chara)
  if not ok or not exists or type(pparam) ~= "number" or pparam == 0 then
    return nil
  end
  local m = {chara = pchara or 0, phdl = type(phdl) == "number" and phdl or 0}
  -- Keeps the text that says a change gives no swap while its partner is in the base's team (empty when the rule allows it).
  m.in_team_text = type(in_team) == "string" and in_team or ""
  local okk, face = pcall(funcLuaCommand, 347353059, pparam)
  m.face = (okk and type(face) == "number" and face ~= 0) and face or m.chara
  local okn, a, b = pcall(funcLuaCommand, @crc:CMND_GET_CHARA_INFO@, m.chara, 10)
  m.name = (okn and type(b) == "string" and b) or (okn and type(a) == "string" and a) or nil
  return m
end

function CharacterReforged.hyper_card.title(name, fusion, mc)
  if fusion ~= nil then
    return name or "Miximax Trans"
  end
  if mc ~= nil and mc.name ~= nil then
    return (name or "Modo cambio") .. ": " .. mc.name
  end
  return name
end

CharacterReforged.hyper_card.CHR_MESH, CharacterReforged.hyper_card.CHR_SLOT = 478320441, 3237726902
CharacterReforged.hyper_card.FS_MESH, CharacterReforged.hyper_card.FS_SLOT = 2449339029, 1051570875
function CharacterReforged.hyper_card.partner(A, face, ctx, inst)
  inst = inst or 0
  funcLuaMenuCommand(4176779611 --[[clear face icon]], A, inst, CharacterReforged.hyper_card.FS_SLOT)
  funcLuaMenuCommand(4176779611 --[[clear face icon]], A, inst, CharacterReforged.hyper_card.CHR_SLOT)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@ --[[MESH_VISIBLE]], A, CharacterReforged.hyper_card.FS_MESH, false, inst)
  if face == nil or face == 0 then
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, A, CharacterReforged.hyper_card.CHR_MESH, false, inst)
    return false
  end
  pcall(funcLuaCommand, @crc:CMND_VRFW_APPEARANCE@, ctx or "plate_page", face)
  local has = funcLuaMenuCommand(2208175668 --[[has a miximax face icon]], face)
  -- VRFW.face_icon shows the mesh once the texture has loaded, so the cleared slot's white fill never shows.
  VRFW.face_icon.forget(A, inst, CharacterReforged.hyper_card.CHR_MESH)
  VRFW.face_icon.face(A, inst, face, CharacterReforged.hyper_card.CHR_MESH, CharacterReforged.hyper_card.CHR_SLOT,
    has and {art = 12} or nil)
  CharacterReforged.hyper_card.log("partner", tostring(A), tostring(face), tostring(has))
  return true
end

CharacterReforged.hyper_card.FACE_BY_TYPE = {[0] = {2449339029, 1051570875, 8}, [1] = {2449339029, 1051570875, 8},
  [2] = {478320441, 3237726902, 12}, [3] = {2449339029, 1051570875, 14}}
-- Draws the portrait of an aura card; with `rules.partner_frame` an aura's own face takes the partner's frame (mesh, size, crop).
function CharacterReforged.hyper_card.portrait(A, skill, fusion, mc, ctx, inst, rules)
  inst = inst or 0
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, A, CharacterReforged.hyper_card.FS_MESH, false, inst)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, A, CharacterReforged.hyper_card.CHR_MESH, false, inst)
  funcLuaMenuCommand(4176779611 --[[clear face icon]], A, inst, CharacterReforged.hyper_card.FS_SLOT)
  funcLuaMenuCommand(4176779611 --[[clear face icon]], A, inst, CharacterReforged.hyper_card.CHR_SLOT)
  local partner = (fusion ~= nil and fusion.face) or (mc ~= nil and mc.face) or nil
  if fusion ~= nil or mc ~= nil then
    CharacterReforged.hyper_card.partner(A, partner, ctx, inst)
    return partner
  end
  local t = CharacterReforged.hyper_card.aura_type(skill)
  local face = t ~= nil and CharacterReforged.hyper_card.FACE_BY_TYPE[t] or nil
  local okc, cid = funcLuaCommand(CharacterReforged.hyper_card.SKILL_INFO, skill, 17)
  if okc and cid ~= nil and cid ~= 0 and face ~= nil then
    local mesh, slot = face[1], face[2]
    if rules ~= nil and rules.partner_frame then
      mesh, slot = CharacterReforged.hyper_card.CHR_MESH, CharacterReforged.hyper_card.CHR_SLOT
    end
    -- VRFW.face_icon shows the mesh once the texture has loaded.
    VRFW.face_icon.forget(A, inst, mesh)
    VRFW.face_icon.face(A, inst, cid, mesh, slot, {art = face[3]})
    return cid
  end
  return nil
end

function CharacterReforged.hyper_card.aura_move(skill)
  if CharacterReforged.hyper_card.is_mode_change(skill) then
    return false, 0
  end
  local ok, move = funcLuaCommand(CharacterReforged.hyper_card.SKILL_INFO, skill, 16)
  if ok and type(move) == "number" and move ~= 0 then
    return true, move
  end
  local okl, kind, keshin = pcall(funcLuaCommand, CALC_CRC("CMND_CHARACTERREFORGED_SLOT_OF"), skill)
  if okl and kind == 2 and type(keshin) == "number" and keshin ~= 0 then
    local okk, km = funcLuaCommand(CharacterReforged.hyper_card.SKILL_INFO, keshin, 16)
    if okk and type(km) == "number" and km ~= 0 then
      return true, km
    end
  end
  return false, 0
end

function CharacterReforged.hyper_card.peg_info(aura)
  local ok, has, kind, pool, cost = pcall(funcLuaCommand, CALC_CRC("CMND_CHARACTERREFORGED_POINTS_PEG_INFO"), aura or 0)
  if ok and has == true and type(pool) == "number" and pool > 0 then
    return {kind = kind, pool = pool, cost = cost or 0}
  end
  return nil
end

function CharacterReforged.hyper_card.peg_look(L, inst, on, kind)
  local sp = on and kind == 2
  local c = on and (sp and CharacterReforged.hyper_card.SP_RGB or CharacterReforged.hyper_card.PEG_RGB) or CharacterReforged.hyper_card.TENS_RGB
  local ok1, r1 = pcall(funcLuaMenuCommand, 558735651, L, CharacterReforged.hyper_card.TEAM02, on and CALC_CRC(sp and "cr_tension_on_sp" or "cr_tension_on_peg") or CALC_CRC("tension_on01"),
    CALC_CRC("tension_on01"), 0, inst)
  local ok2, r2 = pcall(funcLuaMenuCommand, 558735651, L, CharacterReforged.hyper_card.TEAM02, on and CALC_CRC(sp and "cr_gtxt_sp_t" or "cr_gtxt_peg_t") or CALC_CRC("gtxt_t01"),
    CALC_CRC("gtxt_t01"), 0, inst)
  CharacterReforged.hyper_card.PEG_LOGS = (CharacterReforged.hyper_card.PEG_LOGS or 0) + 1
  if on and CharacterReforged.hyper_card.PEG_LOGS <= 8 then
    CharacterReforged.hyper_card.log("peg look", string.format("layer %s inst %s kind %s squares %s/%s T %s/%s", tostring(L), tostring(inst),
      tostring(kind), tostring(ok1), tostring(r1), tostring(ok2), tostring(r2)))
  end
  pcall(funcLuaMenuCommand, 558735651, L, CharacterReforged.hyper_card.TEAM02, CALC_CRC("gtxt_tension01"), CALC_CRC("gtxt_tension01"), 0, inst)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, CALC_CRC("_gtxt_tension01"), not on, inst)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, CALC_CRC("_tension_off01"), not on, inst)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, CALC_CRC("_gtxt_t01"), true, inst)
  -- Keep the obsolete label transparent even if a parent show restores mesh visibility.
  pcall(funcLuaMenuCommand, @crc:CMND_SET_PRIM_ALPHA@, L, inst, CALC_CRC("_gtxt_tension01"), on and 0 or 1)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_PRIM_ALPHA@, L, inst, CALC_CRC("_tension_off01"), on and 0 or 1)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_PRIM_COLOR@, L, inst, 3424269865 --[[number prim]], c[1], c[2], c[3])
  -- the number field's placeholder _num_tension_dmy01 off after every show of _pos_tension01
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, CALC_CRC("_num_tension_dmy01"), false, inst)
end

function CharacterReforged.hyper_card.pool_name(name, peg)
  if name == nil or peg == nil then
    return name
  end
  return string.format("%s  ·  %s %d", name, peg.kind == 2 and "SP" or "PEG", math.floor(peg.pool + 0.5))
end

function CharacterReforged.hyper_card.peg_pool(L, peg)
  pcall(funcLuaMenuCommand, 558735651, L, CharacterReforged.hyper_card.TEAM02, CALC_CRC("gtxt_cmd_at01"), CALC_CRC("gtxt_cmd_at01"), 0, 0)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_PRIM_COLOR@, L, 0, 2223127589, 1, 1, 1)
end

function CharacterReforged.hyper_card.steps(cost, scale)
  if type(cost) ~= "number" or scale == nil or scale <= 0 then
    return 0
  end
  return math.min(10, math.max(1, math.floor(cost / scale * 10 + 0.5)))
end
-- The «Armadura» badge of a keshin card: the retail framed badge _gtxt_cmd_armed01 on its own layer, centred on the
-- bottom edge of the card's band.
CharacterReforged.hyper_card.ARMOUR_BADGE = 1206374040              -- _gtxt_cmd_armed01
CharacterReforged.hyper_card.ARMOUR_BADGE_K = 0.8                   -- size factor on the retail 120 x 48 badge
CharacterReforged.hyper_card.EXIST_LAYER = 262659071                -- (layer) -> layer declared on this menu

-- Returns the armour `chara` can wear with keshin `skill` (0 = none or not a keshin), from the mod's armour data.
function CharacterReforged.hyper_card.keshin_armour(skill, chara)
  if CharacterReforged.hyper_card.aura_type(skill) ~= 0 or chara == nil or chara == 0 then
    return 0
  end
  local ok, armour = pcall(funcLuaCommand, CALC_CRC("CMND_CHARACTERREFORGED_KESHIN_HYPER_ARMOUR"), chara, skill)
  return (ok and type(armour) == "number") and armour or 0
end

-- Shows the badge on rules.layer when `chara` can wear an armour with keshin `skill`, else hides it.
-- rules.band = {x, top, w, h} of the card's band in the badge layer's frame; rules.scale (default 1) and rules.prio
-- (draw priority, optional). Returns the badge point {x, y} when shown, else nil.
function CharacterReforged.hyper_card.armour_mark(skill, chara, rules)
  local T = rules.layer
  if T == nil or funcLuaMenuCommand(CharacterReforged.hyper_card.EXIST_LAYER, T) ~= true then
    return nil
  end
  local armour = CharacterReforged.hyper_card.keshin_armour(skill, chara)
  local open = funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, T, 0)
  if armour == 0 then
    if open then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, T, 0, false)
    end
    return nil
  end
  if not open then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, T, 0)
  end
  local b, s = rules.band, rules.scale or 1
  local at = {b[1] + b[3] * s / 2, b[2] - b[4] * s}
  local k = s * CharacterReforged.hyper_card.ARMOUR_BADGE_K
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, T, CharacterReforged.hyper_card.ARMOUR_BADGE, true, 0)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, T, k, k, 1, 0)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, T, at[1], at[2], 0, 0)
  if rules.prio ~= nil then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@, T, 0, rules.prio, true)
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, T, 0, true)
  CharacterReforged.hyper_card.log("armour badge", string.format("%08X", skill or 0), tostring(armour),
    string.format("%.1f", at[1]), string.format("%.1f", at[2]))
  return at
end
-- ===== EVT hiper_card END =====
