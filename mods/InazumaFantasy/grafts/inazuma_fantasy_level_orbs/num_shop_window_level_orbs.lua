-- Inazuma Fantasy level orbs: the amount window's side. Only while the item use menu has set the three params
-- (item_use_level_orbs.lua) the window's label shows the result level and the window draws over that menu; a shop opens
-- it without the params and nothing changes.
local level_orb_window = nil

local function read_param(key)
  local value = funcLuaCommand(3522198769, key)
  return type(value) == "number" and value or nil
end

local function show_result_level()
  local target = math.min(level_orb_window.from + GetSelectNum() * level_orb_window.per_orb, level_orb_window.cap)
  local text = funcLuaCommand(4074371074 --[[CMND_TEXT_GET]], @crc:InazumaFantasy.level_orb_result@)
  text = string.gsub(text, "{1}", string.format("%d", level_orb_window.from))
  text = string.gsub(text, "{2}", string.format("%d", target))
  funcLuaMenuCommand(1083631230 --[[CMND_SET_MENU_TEXT_STRING?]], GetWindowLayerName(), 109717146 --[[_text_qty01]], text, 0)
end

local retail_OpenWindow = OpenWindow
function OpenWindow(...)
  level_orb_window = nil
  local from = read_param(@crc:InazumaFantasy.level_orb_from@)
  local per_orb = read_param(@crc:InazumaFantasy.level_orb_per_orb@)
  local cap = read_param(@crc:InazumaFantasy.level_orb_cap@)
  if from and per_orb and cap then
    level_orb_window = { from = from, per_orb = per_orb, cap = cap }
  end
  return retail_OpenWindow(...)
end

local retail_OnOpenLayer = OnOpenLayer
function OnOpenLayer(a1, a2)
  retail_OnOpenLayer(a1, a2)
  if level_orb_window == nil then
    return
  end
  if a1 == GetWindowLayerName() and a2 == 0 then
    funcLuaMenuCommand(2628464193, a1, a2, 1000)
    show_result_level()
  elseif a1 == 790585329 --[[cmn03_10_sub_window_button]] then
    funcLuaMenuCommand(2628464193, a1, a2, 1001)
  end
end

local retail_OnFunction = OnFunction
function OnFunction(a1, a2)
  retail_OnFunction(a1, a2)
  if level_orb_window ~= nil then
    show_result_level()
  end
end
