-- element 5
BetterQoL = BetterQoL or {}
BetterQoL.neutral_element = BetterQoL.neutral_element or {}
BetterQoL.neutral_element.CMD = {{icon_cmd_type00}}
BetterQoL.neutral_element.GAIJI = "[$gaiji_cmd_type00]"
BetterQoL.neutral_element.prev = BetterQoL.neutral_element.prev or {}

function BetterQoL.neutral_element.chara(el)
  return el == 0 or el == 5
end

-- the original of global `name`, kept once per VM so a second run does not wrap the wrapper
local function orig(name)
  local P = BetterQoL.neutral_element.prev
  if P[name] == nil then
    P[name] = _ENV[name]
  end
  return P[name]
end

-- character by chara status handle
if orig("GetCharaElementIconNameByCharaStHdl") ~= nil then
  function GetCharaElementIconNameByCharaStHdl(a1, ...)
    local r = BetterQoL.neutral_element.prev.GetCharaElementIconNameByCharaStHdl(a1, ...)
    if r == 0 and a1 ~= nil and a1 ~= 0 and not IsInvalidSoccerCharaHdl(a1) then
      if BetterQoL.neutral_element.chara(funcLuaCommand(1131797651, a1, 8)) then
        return BetterQoL.neutral_element.CMD
      end
    end
    return r
  end
end

-- character by chara param id
if orig("GetCharaElementIconNameByCharaParamId") ~= nil then
  function GetCharaElementIconNameByCharaParamId(a1, ...)
    local r = BetterQoL.neutral_element.prev.GetCharaElementIconNameByCharaParamId(a1, ...)
    if r == 0 and a1 ~= nil and a1 ~= 0 then
      local ok, el = funcLuaCommand(4060384944 --[[CMND_GET_CHARA_INFO]], a1, 13)
      if ok and BetterQoL.neutral_element.chara(el) then
        return BetterQoL.neutral_element.CMD
      end
    end
    return r
  end
end

-- character by soccer handle
if orig("GetSoccerCharaElementIcon") ~= nil then
  function GetSoccerCharaElementIcon(a1, ...)
    local r = BetterQoL.neutral_element.prev.GetSoccerCharaElementIcon(a1, ...)
    if r == 0 then
      local ok, el = GetSoccerCharaParamBySoccerHdl(a1, 8)
      if ok ~= false and BetterQoL.neutral_element.chara(el) then
        return BetterQoL.neutral_element.CMD
      end
    end
    return r
  end
end

-- element number -> icon (skill elements)
if orig("GetElementIcon") ~= nil then
  function GetElementIcon(a1, ...)
    if a1 == 5 then
      return BetterQoL.neutral_element.CMD
    end
    return BetterQoL.neutral_element.prev.GetElementIcon(a1, ...)
  end
end

-- skill element as an inline text icon (parameter screen)
if orig("GetSkillElementGaijiTexture") ~= nil then
  function GetSkillElementGaijiTexture(a1, ...)
    if a1 == 5 then
      return BetterQoL.neutral_element.GAIJI
    end
    return BetterQoL.neutral_element.prev.GetSkillElementGaijiTexture(a1, ...)
  end
end

-- Wraps the skill info element icon.
if orig("SetupSpecialSkillInfoElementIcon") ~= nil then
  function SetupSpecialSkillInfoElementIcon(a1, a2, a3, a4, ...)
    local r = {BetterQoL.neutral_element.prev.SetupSpecialSkillInfoElementIcon(a1, a2, a3, a4, ...)}
    local ok, el = funcLuaCommand(2580586398, a3, 7)
    if ok and el == 5 then
      local slot = a4 and a4 or 917245562 --[[icon_cmd_type_dmy01]]
      funcLuaMenuCommand(558735651, a1, 502529699 --[[icon_common <LG>]], BetterQoL.neutral_element.CMD, slot, 0, a2)
      funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], a1, 1255155594 --[[_icon_cmd_type_dmy01]], true, a2)
      funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], a1, 2172872396 --[[_icon_cmd_type_base01]], true, a2)
    end
    return table.unpack(r)
  end
end
