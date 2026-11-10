

local CEL = {
  VISIBLE = VRFW.commands.VRFW_CELEBRATION_VISIBLE,  -- (handle, performanceId) -> bool
  INFO = 3399635787,                                  -- (index, field): 3 = valid, 4 = performanceId
  ITEM = 1076657304,                                  -- win05_36_performance_chara_list_item
  hdl = nil,
}

local CEL_UpdateListItem = UpdateListItem
function UpdateListItem(a1, a2, a3, a4)
  if a1 == CEL.ITEM and a4 and a3 ~= nil then
    CEL.hdl = a3
  end
  return CEL_UpdateListItem(a1, a2, a3, a4)
end

local CEL_InitPerformanceInfoArray = InitPerformanceInfoArray
function InitPerformanceInfoArray()
  local hdl = CEL.hdl
  local real = funcLuaCommand
  if hdl == nil or real == nil then
    return CEL_InitPerformanceInfoArray()
  end
  funcLuaCommand = function(...)
    local cmd, a, b = ...
    if cmd == CEL.INFO and b == 3 then
      local ok, valid = real(...)
      if ok ~= false and valid ~= false then
        local okid, pid = real(CEL.INFO, a, 4)
        if okid ~= false and pid ~= nil and pid ~= 0 then
          local okv, vis = pcall(real, CEL.VISIBLE, hdl, pid)
          if okv and vis == false then
            return ok, false
          end
        end
      end
      return ok, valid
    end
    return real(...)
  end
  local okc, err = pcall(CEL_InitPerformanceInfoArray)
  funcLuaCommand = real
  if not okc then
    error(err)
  end
end
