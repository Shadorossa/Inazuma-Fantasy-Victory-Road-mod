@UPV@
CharacterReforged_PointsBuffRow = CharacterReforged_PointsBuffRow or {}
local R = CharacterReforged_PointsBuffRow

local CMD_TEAM_MAX = @crc:CMND_VRFW_FORM_TEAM_MAX@
local CMD_PARTS = @crc:CMND_CHARACTERREFORGED_POINTS_ACTIVE_PARTS@ --[[the mod's parts this start: ok, peg, sp, pe]]
local PORTRAIT = 1535165083 --[[soccer00_53_aura_buff_chara_icon]]
local CMND_IS_OPEN = @crc:CMND_IS_OPEN_LAYER@
local MEMBERS = 29 --[[the retail member loop of UpdateAuraBuffCharaIcon (0..28)]]
R.RESWAP_FRAMES = 30 --[[a second face swap of one instance within this many frames is redone this many frames later]]
R.frame = R.frame or 0
R.faces = R.faces or {} --[[portrait instance -> {hdl, metamorphosed, frame, redo}: its last face swap]]

function R.draw_face(hdl, layer, i, metamorphosed, armour)
  if armour then
    local ok, own = GetSoccerCharaInfo(hdl, 1)
    local chara = ok and own ~= nil and own ~= 0 and funcLuaCommand(1131797651, own, 1) or 0
    if chara ~= 0 then
      local has, face = GetSoccerCharaInfo(hdl, 13)
      SwapLayerFaceIconTex(chara, layer, i, 620971603, 1501523875, has and face or 0, 10, true, true, true)
      return
    end
  end
  SwapLayerFaceIconTexBySoccerCharaHdl(hdl, layer, i, 620971603, 1501523875, faceType, 1, true, true, true, false, metamorphosed)
end

function R.swap_face(hdl, layer, i, metamorphosed, armour)
  local last = R.faces[i]
  local redo = last ~= nil and R.frame - last.frame < R.RESWAP_FRAMES and R.frame + R.RESWAP_FRAMES or nil
  R.faces[i] = {hdl = hdl, layer = layer, metamorphosed = metamorphosed, armour = armour, frame = R.frame, redo = redo}
  R.draw_face(hdl, layer, i, metamorphosed, armour)
end

-- Runs every frame (the bar block's Step wrapper).
function R.step()
  R.frame = R.frame + 1
  for i, f in pairs(R.faces) do
    if f.redo ~= nil and R.frame >= f.redo then
      f.redo = nil
      if IsInvalidSoccerCharaHdl(f.hdl) == false then
        R.draw_face(f.hdl, f.layer, i, f.metamorphosed, f.armour)
        pcall(funcLuaCommand, @crc:CMND_VRFW_LOG@, "CharacterReforged points buff row face swapped again", i, string.format("0x%X", f.hdl))
      end
    end
  end
end

-- Returns the portrait layer's open instances (the menu's layer count).
function R.instances()
  local n = 0
  while n < MEMBERS do
    local ok, open = pcall(funcLuaMenuCommand, CMND_IS_OPEN, PORTRAIT, n)
    if not ok or open ~= true then
      break
    end
    n = n + 1
  end
  return n
end

function R.read_pools_on()
  if R.pools_on ~= nil then
    return R.pools_on
  end
  R.asks = (R.asks or 0) + 1
  local ok, answered, peg, sp = pcall(funcLuaCommand, CMD_PARTS)
  if ok and answered == true then
    R.pools_on = peg == 1 or peg == true or sp == 1 or sp == true
  elseif R.asks >= 600 then
    R.pools_on = true
  end
  return R.pools_on == true
end

function R.rows()
  local base = R.retail or 0
  if R.t5 == nil or not R.read_pools_on() then
    return base
  end
  if R.cap == nil then
    local n = R.instances()
    if n > 0 then
      R.cap = n
    end
  end
  local want = R.cap or base
  local ok, max = pcall(funcLuaCommand, CMD_TEAM_MAX)
  if ok and type(max) == "number" and max >= 0 then
    want = math.min(want, max)
  end
  return math.max(base, want)
end

function R.grow()
  if R.t5 == nil then
    return
  end
  for k = #R.t5 + 1, R.rows() do
    R.t5[k] = {auraCharaHdl = 0, auraAttr = 0}
  end
end

local t5 = upvalue_find({"UpdateAuraBuffCharaIcon", "OnSetupLayer", "UpdateAuraActiveTimeGauge"}, function(t)
  return #t > 0 and type(t[1]) == "table" and t[1].auraCharaHdl ~= nil and t[1].auraAttr ~= nil
end)
-- Draws the bar and label on its player's portrait.
R.drawn = t5
local retail_update = UpdateAuraBuffCharaIcon
if t5 ~= nil and type(retail_update) == "function" and retail_update ~= R.wrapper then
  local n, n4
  -- Replaces the retail UpdateAuraBuffCharaIcon.
  local widened = function()
    local n6 = 0
    local l1 = #t5
    local t6 = {}
    for k = 1, l1 do
      t6[k] = {auraCharaHdl = 0, auraAttr = 0}
    end
    for i = 0, 28 do
      local ret2, ret3 = funcLuaCommand(66484325, n, i, true)
      ret2, auraAttr = GetSoccerCharaInfo(ret3, 26)
      if ret2 and auraAttr ~= 0 then
        t6[n6 + 1].auraCharaHdl = ret3
        t6[n6 + 1].auraAttr = auraAttr
        n6 = n6 + 1
        if l1 <= n6 then
          break
        end
      end
    end
    n4 = n6
    local n7 = 1535165083 --[[soccer00_53_aura_buff_chara_icon]]
    local n8 = 698939060 --[[soccer00_54_aura_recast_gauge]]
    n6 = 0
    for i2 = 0, l1 - 1 do
      local aura_chara_hdl = t6[i2 + 1].auraCharaHdl
      local aura_attr = t6[i2 + 1].auraAttr
      local l2 = IsInvalidSoccerCharaHdl(aura_chara_hdl) == false
      local flag = false
      if t5[i2 + 1].auraCharaHdl ~= aura_chara_hdl or t5[i2 + 1].auraAttr ~= aura_attr then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, n7, i2, l2)
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, n8, i2, l2)
        flag = true
      end
      t5[i2 + 1].auraCharaHdl = aura_chara_hdl
      t5[i2 + 1].auraAttr = aura_attr
      if flag then
        local n9 = 0
        local convert_aura_attr_to_aura_ty = ConvertAuraAttrToAuraType(aura_attr)
        n9 = GetSkillAuraCategoryIcon(convert_aura_attr_to_aura_ty)
        if n9 == 0 then
          n9 = 1815339204 --[[icon_sp_area05]]
        end
        local n10 = 3669916425
        funcLuaMenuCommand(558735651, n8, 502529699 --[[#/menu/200_icon/15_icon_common/<LG>/icon_common.g4tx]], n9, n10, 0, i2)
        local is_aura_skill_metamorphosed = IsAuraSkillMetamorphosed(convert_aura_attr_to_aura_ty)
        CharacterReforged_PointsBuffRow.swap_face(aura_chara_hdl, n7, i2, is_aura_skill_metamorphosed, IsAuraSkillKeshinArmed(convert_aura_attr_to_aura_ty))
      end
      local l3 = 68 * n6
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, n7, l3, 0, 0, i2)
      n6 = n6 + 1
    end
  end
  local ok, joined = pcall(upvalue_join, widened, retail_update)
  if ok and type(joined) == "number" and joined > 0 then
    R.t5 = t5
    R.retail = #t5
    R.wrapper = function(...)
      pcall(R.grow)
      return widened(...)
    end
    UpdateAuraBuffCharaIcon = R.wrapper
  end
end
