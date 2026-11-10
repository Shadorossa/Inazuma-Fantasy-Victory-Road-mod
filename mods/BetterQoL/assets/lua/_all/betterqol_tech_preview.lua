BetterQoL_TP = type(BetterQoL_TP) == "table" and BetterQoL_TP or {}

function BetterQoL_TpCarrier(op, layer, x)
  local T = BetterQoL_TP
  if type(layer) ~= "number" then return false end
  if op == "set" then
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, layer, 0, false)
    VRFW.host.menu_command(59611540 --[[the layer's chara model]], layer, 0, x)
    VRFW.host.menu_command(180466856 --[[motion]], layer, 0, 2263925137 --[[立ち1L]], 0, 0)
    VRFW.host.menu_command(VRFW.commands.CHARA_MODEL_CHANGE, layer, 0, 0, 9)
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, layer, 0, false)
    T.polls = 0
    return true
  elseif op == "poll" then
    T.polls = (T.polls or 0) + 1
    local ready = VRFW.host.menu_command(1583438030 --[[the layer's model is built]], layer, 0, 0)
    local v = (ready == true and T.polls > 3) and 1 or (T.polls > 600 and 2 or 0)
    if v ~= 0 and type(x) == "number" then
      VRFW.param.set(x, v)
    end
    return true
  elseif op == "end" then
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, layer, 0, false)
    T.polls = 0
    return true
  end
  return false
end

function BetterQoL_TpBars(hide, list)
  local T = BetterQoL_TP
  if hide == 1 or hide == true then
    T.bars = T.bars or {}
    for s in tostring(list or ""):gmatch("[^,]+") do
      local l = tonumber(s)
      if l ~= nil then
        local n = VRFW.host.menu_command(VRFW.commands.GET_CREATE_LAYER_NUM, l)
        if type(n) == "number" and n > 0 then
          local vis = VRFW.host.menu_command(VRFW.commands.IS_LAYER_VISIBLE, l, 0)
          if vis == true then
            VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, l, 0, false)
            T.bars[#T.bars + 1] = l
          end
        end
      end
    end
  else
    local b = T.bars or {}
    T.bars = nil
    for i = #b, 1, -1 do
      VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, b[i], 0, true)
    end
  end
  return true
end
