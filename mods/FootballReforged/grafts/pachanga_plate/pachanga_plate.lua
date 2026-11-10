-- soccer_formation_menu_inc (position -> member of team (dock, n31))
function football_reforged_plate_kind(kind, dock)
  if type(OnInitFormationCommon) ~= "function" or type(dock) ~= "number" then
    return false
  end
  local ok, got, fid = pcall(funcLuaCommand, @crc:CMND_GET_TEAM_SET_INFO@, dock, kind == 1 and 1 or 0, 4)
  local f = (ok and got) and fid or nil
  local r
  if kind == 1 then
    r = table.pack(pcall(OnInitFormationCommon, f, nil, dock, nil, nil, nil, true))
  else
    r = table.pack(pcall(OnInitFormationCommon, f, nil, dock, nil, nil, nil, false))
    -- OnInitFormationCommon(..., false) does not put back the starters count / field height of the 11v11 mode
    if type(UpdateFormationReducedDrawingIconPos) == "function" then
      pcall(funcLuaCommand, @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_UPVAL@, UpdateFormationReducedDrawingIconPos, 5, 11, 40, 94)
    end
  end
  pcall(funcLuaCommand, @crc:CMND_VRFW_LOG@, "EVT pachanga plate", "team kind", kind, "dock", dock,
    tostring(r[1]), tostring(r[2]))
  return r[1]
end
