-- Temporary diagnostic: one log block per side each time the Chronicle VS screen opens, to find why a side draws no character models.
do
  local LOG = 519897777 --[[CMND_VRFW_LOG]]
  local CAPTAIN_HANDLE = 2074791338
  local MEMBER_HANDLE = 3690462912
  local original_side = SetupTeamInfoModel
  local original_model = SetupSoccereMenuCharaModel

  local function chara_info(handle, field)
    local ok, value = GetSoccerCharaInfo(handle, field)
    return tostring(ok) .. ":" .. tostring(value)
  end

  if type(original_side) == "function" and type(original_model) == "function" then
    SetupTeamInfoModel = function(layer, scene, own_side)
      local side = own_side and 0 or 1
      local members, overwrites = {}, {}
      for slot = 0, 10 do
        members[#members + 1] = tostring(funcLuaCommand(MEMBER_HANDLE, side, slot))
      end
      for slot = 0, 3 do
        overwrites[#overwrites + 1] = tostring(GetOverwriteAssignCharaHdl(side, slot))
      end
      funcLuaCommand(LOG, "vs models: side " .. side .. " captain " .. tostring(funcLuaCommand(CAPTAIN_HANDLE, side))
        .. " members " .. table.concat(members, ",") .. " overwrites " .. table.concat(overwrites, ","))
      return original_side(layer, scene, own_side)
    end

    SetupSoccereMenuCharaModel = function(layer, scene, slot, model, handle, x, y, z, angle, motion, a11, a12, a13, a14, a15, sx, sy, sz, a19, a20, a21)
      local drawn = original_model(layer, scene, slot, model, handle, x, y, z, angle, motion, a11, a12, a13, a14, a15, sx, sy, sz, a19, a20, a21)
      local body_ok, body = GetBodyTypeWithCharaHdl(handle)
      funcLuaCommand(LOG, "vs models: slot " .. tostring(slot) .. " handle " .. tostring(handle) .. " invalid " .. tostring(IsInvalidSoccerCharaHdl(handle))
        .. " base " .. chara_info(handle, 6) .. " look " .. chara_info(handle, 16) .. " " .. chara_info(handle, 17) .. " " .. chara_info(handle, 18)
        .. " body " .. tostring(body_ok) .. ":" .. tostring(body) .. " pos " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. " angle " .. tostring(angle)
        .. " scale " .. tostring(sx) .. "," .. tostring(sy) .. "," .. tostring(sz) .. " motion " .. tostring(motion) .. " drawn " .. tostring(drawn))
      return drawn
    end
  end
end
