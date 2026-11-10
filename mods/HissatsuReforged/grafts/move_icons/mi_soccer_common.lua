-- Retail (SetupCommandActionSkillInfoCategoryIcon, this file) draws one badge in the row's slot

HissatsuReforged = HissatsuReforged or {}
HissatsuReforged.move_icons = HissatsuReforged.move_icons or {}
HissatsuReforged.move_icons.prev = HissatsuReforged.move_icons.prev or {}
HissatsuReforged.move_icons.cache = HissatsuReforged.move_icons.cache or {}       -- skill -> mask (per VM)
HissatsuReforged.move_icons.armed = HissatsuReforged.move_icons.armed or {}
HissatsuReforged.move_icons.GEOM = HissatsuReforged.move_icons.GEOM or {}
HissatsuReforged.move_icons.GEOM[1557009688] = HissatsuReforged.move_icons.GEOM[1557009688] or "a"   -- soccer08_10_cmd_act_skill_cmd (match command rows)
HissatsuReforged.move_icons.GEOM[1760473337] = HissatsuReforged.move_icons.GEOM[1760473337] or "a"   -- soccer08_10_cmd_act_skill_cmd_override
HissatsuReforged.move_icons.GEOM[1580043721] = HissatsuReforged.move_icons.GEOM[1580043721] or "b"   -- soccer11_09_formation_chara_skill (player page, chara edit)

HissatsuReforged.move_icons.CMD = @crc:CMND_VRFW_MOVE_ICONS@
HissatsuReforged.move_icons.SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@          -- (skill, 9) -> ok, category
HissatsuReforged.move_icons.SKILL_FLAG = 3029125066          -- (skill, bit) -> ok, has (skillEffectBitFlag)
HissatsuReforged.move_icons.COMMON = 1875260309
HissatsuReforged.move_icons.SPRITE_CMD = 558735651
HissatsuReforged.move_icons.MESH_VIS = @crc:CMND_SET_MESH_VISIBLE@
HissatsuReforged.move_icons.ICON_TEX = 502529699
HissatsuReforged.move_icons.SUB_MESH, HissatsuReforged.move_icons.SUB_PH = 559600405, 3992937973
HissatsuReforged.move_icons.ARMED_MESH, HissatsuReforged.move_icons.ARMED_PH = 1206374040, @crc:gtxt_cmd_armed01@
HissatsuReforged.move_icons.ARMED_TEX = {a = 2804251149,     -- #/menu/00_soccer/soccer08/soccer08_10/<LG>/soccer08_10.g4tx
  b = 868271091}                        -- #/menu/00_soccer/soccer11/soccer11_09/<LG>/soccer11_09.g4tx
HissatsuReforged.move_icons.BITS = {1, 2, 4, 8}              -- drawing order
-- Grafts' children may run in any order.
HissatsuReforged.move_icons.SPRITE = HissatsuReforged.move_icons.SPRITE or {}
HissatsuReforged.move_icons.SPRITE[1] = 1812000538           -- icon_sp_sub01
HissatsuReforged.move_icons.SPRITE[2] = 2181991990           -- icon_sp_sub03
HissatsuReforged.move_icons.SPRITE[4] = 4111056544           -- icon_sp_sub02
HissatsuReforged.move_icons.SECOND = HissatsuReforged.move_icons.SECOND or {}
HissatsuReforged.move_icons.SECOND.a = HissatsuReforged.move_icons.SECOND.a or {}
HissatsuReforged.move_icons.SECOND.b = HissatsuReforged.move_icons.SECOND.b or {}
HissatsuReforged.move_icons.SECOND.a[1], HissatsuReforged.move_icons.SECOND.a[2], HissatsuReforged.move_icons.SECOND.a[4] =
  @crc:hr_icon_sp_sub2_long_a@, @crc:hr_icon_sp_sub2_counter_a@, @crc:hr_icon_sp_sub2_block_a@
HissatsuReforged.move_icons.SECOND.b[1], HissatsuReforged.move_icons.SECOND.b[2], HissatsuReforged.move_icons.SECOND.b[4] =
  @crc:hr_icon_sp_sub2_long_b@, @crc:hr_icon_sp_sub2_counter_b@, @crc:hr_icon_sp_sub2_block_b@

function HissatsuReforged.move_icons.flag(skill, bit)
  local ok, r, has = pcall(funcLuaCommand, HissatsuReforged.move_icons.SKILL_FLAG, skill, bit)
  return ok and r == true and has == true
end

function HissatsuReforged.move_icons.category(skill)
  local ok, r, cat = pcall(funcLuaCommand, HissatsuReforged.move_icons.SKILL_INFO, skill, 9)
  if ok and r then
    return cat
  end
  return nil
end

-- Derives the mask from the game's own flags (no technique engine answer).
function HissatsuReforged.move_icons.derive(skill)
  local cat = HissatsuReforged.move_icons.category(skill)
  local m = 0
  if cat == 1 then
    if HissatsuReforged.move_icons.flag(skill, 4) then
      m = m + 1
    end
    if HissatsuReforged.move_icons.flag(skill, 16) then
      m = m + 2
    end
  elseif cat == 3 then
    if HissatsuReforged.move_icons.flag(skill, 16) then
      m = 4
    end
  elseif cat == 4 then
    if HissatsuReforged.move_icons.flag(skill, 2) then
      m = 8
    end
  end
  return m
end

-- Returns the badge retail drew for this move (0 means none).
function HissatsuReforged.move_icons.retail(skill)
  local cat = HissatsuReforged.move_icons.category(skill)
  if cat == 1 then
    if HissatsuReforged.move_icons.flag(skill, 8) then
      return 0
    elseif HissatsuReforged.move_icons.flag(skill, 4) then
      return 1
    elseif HissatsuReforged.move_icons.flag(skill, 16) then
      return 2
    end
  elseif cat == 3 and HissatsuReforged.move_icons.flag(skill, 16) then
    return 4
  end
  return 0
end

function HissatsuReforged.move_icons.mask(skill)
  if type(skill) ~= "number" or skill == 0 then
    return 0
  end
  local c = HissatsuReforged.move_icons.cache[skill]
  if c ~= nil then
    return c
  end
  local ok, known, mask = pcall(funcLuaCommand, HissatsuReforged.move_icons.CMD, skill)
  local m
  if ok and known == true and type(mask) == "number" then
    m = mask
  else
    m = HissatsuReforged.move_icons.derive(skill)
  end
  for _, b in ipairs(HissatsuReforged.move_icons.BITS) do
    if m % (b * 2) >= b and HissatsuReforged.move_icons.SPRITE[b] == nil then
      m = m - b
    end
  end
  HissatsuReforged.move_icons.cache[skill] = m
  return m
end

-- the bits of a mask in drawing order
function HissatsuReforged.move_icons.list(mask)
  local out = {}
  for _, b in ipairs(HissatsuReforged.move_icons.BITS) do
    if mask % (b * 2) >= b then
      out[#out + 1] = b
    end
  end
  return out
end

function HissatsuReforged.move_icons.get(t, L, inst)
  local r = t[L]
  return r ~= nil and r[inst] or nil
end

function HissatsuReforged.move_icons.put(t, L, inst, v)
  local r = t[L]
  if r == nil then
    r = {}
    t[L] = r
  end
  r[inst] = v
end

function HissatsuReforged.move_icons.second(L, inst, list)
  local g = HissatsuReforged.move_icons.GEOM[L]
  if g == nil then
    return
  end
  local cur = HissatsuReforged.move_icons.get(HissatsuReforged.move_icons.armed, L, inst)
  if #list >= 2 and HissatsuReforged.move_icons.SECOND[g] ~= nil and HissatsuReforged.move_icons.SECOND[g][list[2]] ~= nil then
    funcLuaMenuCommand(HissatsuReforged.move_icons.SPRITE_CMD, L, HissatsuReforged.move_icons.ICON_TEX, HissatsuReforged.move_icons.SECOND[g][list[2]], HissatsuReforged.move_icons.ARMED_PH, 0, inst)
    funcLuaMenuCommand(HissatsuReforged.move_icons.MESH_VIS, L, HissatsuReforged.move_icons.ARMED_MESH, true, inst)
    HissatsuReforged.move_icons.put(HissatsuReforged.move_icons.armed, L, inst, g)
  elseif cur ~= nil then
    funcLuaMenuCommand(HissatsuReforged.move_icons.SPRITE_CMD, L, HissatsuReforged.move_icons.ARMED_TEX[cur], HissatsuReforged.move_icons.ARMED_PH, HissatsuReforged.move_icons.ARMED_PH, 0, inst)
    HissatsuReforged.move_icons.put(HissatsuReforged.move_icons.armed, L, inst, nil)
  end
end

-- Runs after a retail row builder that sets the armed mesh's visibility after the badge pass.
function HissatsuReforged.move_icons.again(L, inst)
  if L ~= nil and HissatsuReforged.move_icons.get(HissatsuReforged.move_icons.armed, L, inst) ~= nil then
    funcLuaMenuCommand(HissatsuReforged.move_icons.MESH_VIS, L, HissatsuReforged.move_icons.ARMED_MESH, true, inst)
  end
end

function HissatsuReforged.move_icons.log(skill, mask, L)
  -- This include runs before the menu library that holds VRFW.logger, so the logger is made on first use.
  HissatsuReforged.move_icons.logger = HissatsuReforged.move_icons.logger or VRFW.logger.new("move_icons")
  HissatsuReforged.move_icons.logger.once(skill, "row", string.format("%08X", skill % 4294967296), tostring(mask),
    tostring(L), tostring(HissatsuReforged.move_icons.GEOM[L]))
end

-- Draws the row of a move.
function HissatsuReforged.move_icons_row(L, inst, skill, chara, sub_mesh, sub_ph)
  L, inst, skill = L or 0, inst or 0, skill or 0
  sub_mesh, sub_ph = sub_mesh or HissatsuReforged.move_icons.SUB_MESH, sub_ph or HissatsuReforged.move_icons.SUB_PH
  HissatsuReforged.move_icons.last_call = {L, inst}
  local mask = 0
  if type(skill) == "number" and skill ~= 0 then
    local okc, common = pcall(funcLuaCommand, HissatsuReforged.move_icons.COMMON, skill, chara or 0)
    if not (okc and common == true) then
      mask = HissatsuReforged.move_icons.mask(skill)
    end
  end
  local list = HissatsuReforged.move_icons.list(mask)
  if #list > 0 then
    funcLuaMenuCommand(HissatsuReforged.move_icons.SPRITE_CMD, L, HissatsuReforged.move_icons.ICON_TEX, HissatsuReforged.move_icons.SPRITE[list[1]], sub_ph, 0, inst)
    funcLuaMenuCommand(HissatsuReforged.move_icons.MESH_VIS, L, sub_mesh, true, inst)
    if #list >= 2 or list[1] == 8 then
      HissatsuReforged.move_icons.log(skill, mask, L)
    end
  elseif skill ~= 0 and HissatsuReforged.move_icons.retail(skill) ~= 0 then
    funcLuaMenuCommand(HissatsuReforged.move_icons.MESH_VIS, L, sub_mesh, false, inst)
  end
  HissatsuReforged.move_icons.second(L, inst, list)
  return mask
end

-- Draws the detail card of a move.
HissatsuReforged.move_icons.CARD_SUB_TEX = 2320109963
HissatsuReforged.move_icons.CARD_TEX = 3964676290            -- #/menu/102_team/team02/team02_02/<LG>/team02_02.g4tx
HissatsuReforged.move_icons.TAG_MESH, HissatsuReforged.move_icons.TAG_PH = 1220252763, 3782926831
HissatsuReforged.move_icons.TAG = HissatsuReforged.move_icons.TAG or {}
HissatsuReforged.move_icons.TAG[1] = 3782926831              -- gtxt_longshoot01
HissatsuReforged.move_icons.TAG[2] = 1602753691              -- gtxt_counter01
HissatsuReforged.move_icons.TAG[4] = 741900120               -- gtxt_shootblock01
HissatsuReforged.move_icons.TAG_LONG_COUNTER = @crc:hr_gtxt_long_counter01@

function HissatsuReforged.move_icons_detail(L, inst, skill)
  if type(skill) ~= "number" or skill == 0 then
    return 0
  end
  local mask = HissatsuReforged.move_icons.mask(skill)
  local list = HissatsuReforged.move_icons.list(mask)
  -- Handles a long shot with a counter shot.
  local both = list[1] == 1 and list[2] == 2
  if #list == 0 or (list[1] == HissatsuReforged.move_icons.retail(skill) and not both) then
    return mask
  end
  local b = list[1]
  funcLuaMenuCommand(HissatsuReforged.move_icons.SPRITE_CMD, L, HissatsuReforged.move_icons.CARD_SUB_TEX, HissatsuReforged.move_icons.SPRITE[b], HissatsuReforged.move_icons.SUB_PH, 0, inst)
  funcLuaMenuCommand(HissatsuReforged.move_icons.SPRITE_CMD, L, HissatsuReforged.move_icons.CARD_TEX, both and HissatsuReforged.move_icons.TAG_LONG_COUNTER or HissatsuReforged.move_icons.TAG[b], HissatsuReforged.move_icons.TAG_PH, 0, inst)
  funcLuaMenuCommand(HissatsuReforged.move_icons.MESH_VIS, L, HissatsuReforged.move_icons.SUB_MESH, true, inst)
  funcLuaMenuCommand(HissatsuReforged.move_icons.MESH_VIS, L, HissatsuReforged.move_icons.TAG_MESH, true, inst)
  HissatsuReforged.move_icons.log(skill, mask, L)
  return mask
end

if HissatsuReforged.move_icons.prev.SetupCommandActionSkillInfoCategoryIcon == nil then
  HissatsuReforged.move_icons.prev.SetupCommandActionSkillInfoCategoryIcon = SetupCommandActionSkillInfoCategoryIcon
end
if HissatsuReforged.move_icons.prev.SetupCommandActionSkillInfoCategoryIcon ~= nil then
  function SetupCommandActionSkillInfoCategoryIcon(a1, a2, a3, a4, a5, a6, a7, ...)
    local r = table.pack(HissatsuReforged.move_icons.prev.SetupCommandActionSkillInfoCategoryIcon(a1, a2, a3, a4, a5, a6, a7, ...))
    pcall(HissatsuReforged.move_icons_row, a1, a2, a3, a7, a6, a5)
    return table.unpack(r, 1, r.n)
  end
end

-- the badge provider of the VRFW move plate (VRFW.ui_plates.move_plate), registered once per VM
if HissatsuReforged.move_icons.badge_provider == nil then
  HissatsuReforged.move_icons.badge_provider = {
    id = "HissatsuReforged.move_icons",
    second_badge = function(row, inst)
      return HissatsuReforged.move_icons.get(HissatsuReforged.move_icons.armed, row, inst) ~= nil
    end,
    use_layer = function(row, geom)
      if HissatsuReforged.move_icons.GEOM[row] == nil then
        HissatsuReforged.move_icons.GEOM[row] = geom
      end
    end,
    has_badge = function(move, chara)
      local okc, common = pcall(funcLuaCommand, HissatsuReforged.move_icons.COMMON, move, chara or 0)
      local okm, mask = pcall(HissatsuReforged.move_icons.mask, move)
      return not (okc and common == true) and okm and type(mask) == "number" and mask > 0
    end,
  }
  VRFW.move_badge_providers = VRFW.move_badge_providers or {}
  table.insert(VRFW.move_badge_providers, HissatsuReforged.move_icons.badge_provider)
end
