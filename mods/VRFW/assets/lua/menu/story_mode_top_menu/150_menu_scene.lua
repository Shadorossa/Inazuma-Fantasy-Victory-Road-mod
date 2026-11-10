
local MSP = {
  PICK = 1790329263,         -- param vrfw_menu_scene_story_pick
  LIST = 1903952903,         -- the submenu's entry list layer
  FOCUS_ACTIVE = VRFW.commands.IS_CTRL_FOCUS_ACTIVE,  -- (layer) -> the layer holds the control focus
  FOCUS_INDEX = 2603265800,  -- (layer) -> its focused instance
  FOCUS_MARK = 1778826357,   -- (layer, instance, true): the focus moves there
  READY_FRAMES = 15,
  GIVE_UP_FRAMES = 600,
}

local msp = { row = nil, frames = 0, ready = 0, marked = false, co = nil }

local MSP_Log = VRFW.logger.new("menu_scene, story_mode_top_menu")

local function MSP_Step()
  if msp.co ~= nil then
    if coroutine.status(msp.co) == "dead" then
      msp.co = nil
    else
      local ok, err = coroutine.resume(msp.co)
      if not ok then
        MSP_Log("pick error:", tostring(err))
        msp.co = nil
      end
    end
    return
  end
  if msp.row == nil then
    local v = VRFW.param.take(MSP.PICK)
    if v == nil then return end
    v = tonumber(v) or 0
    if v < 1 or v > 4 then return end
    msp.row, msp.frames, msp.ready, msp.marked = v - 1, 0, 0, false
    MSP_Log("entry", msp.row, "asked by the menu scene")
  end
  msp.frames = msp.frames + 1
  if msp.frames > MSP.GIVE_UP_FRAMES then
    MSP_Log("entry", msp.row, "not picked: the list never took the focus")
    msp.row = nil
    return
  end
  if VRFW.host.menu_command(MSP.FOCUS_ACTIVE, MSP.LIST) ~= true then
    msp.ready = 0
    return
  end
  msp.ready = msp.ready + 1
  if msp.ready < MSP.READY_FRAMES then return end
  if VRFW.host.menu_command(MSP.FOCUS_INDEX, MSP.LIST) ~= msp.row then
    if not msp.marked then
      msp.marked = true
      VRFW.host.menu_command(MSP.FOCUS_MARK, MSP.LIST, msp.row, true)
    end
    return
  end
  local row = msp.row
  msp.row = nil
  if type(OnDecideFocus) ~= "function" then
    MSP_Log("entry", row, "focused, no OnDecideFocus: left to the player")
    return
  end
  MSP_Log("entry", row, "picked")
  msp.co = coroutine.create(function() OnDecideFocus(MSP.LIST, row) end)
  local ok, err = coroutine.resume(msp.co)
  if not ok then
    MSP_Log("pick error:", tostring(err))
    msp.co = nil
  end
end

if type(Step) == "function" then
  local step_before = Step
  Step = function(...)
    local r = table.pack(step_before(...))
    local ok, err = pcall(MSP_Step)
    if not ok then MSP_Log("error:", tostring(err)) end
    return table.unpack(r, 1, r.n)
  end
end
