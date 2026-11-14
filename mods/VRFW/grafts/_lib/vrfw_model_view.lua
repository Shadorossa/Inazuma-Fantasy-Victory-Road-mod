--@section ModelView --- Advanced: Menu model view camera and pose helpers.
local MV = {}
MV.CAM, MV.CAM_OFS, MV.CAM_GET = 1752770328, 284729675, 1877348924   -- shared menu model camera offset (set / get)
MV.ROT = 2463117189                    -- (layer, idx, rx, ry, rz): the retail view's turn after a build
MV.MOTION, MV.STAND = 180466856, 2263925137
MV.POSE_UPD, MV.POSE_ARG = @crc:CMND_UPDATE_CHARA_MODEL_POSE@, 3459069566                     -- CMND_UPDATE_CHARA_MODEL_POSE (dock pose)
MV.EXIST_MENU = @crc:CMND_IS_EXIST_MENU@              -- (menu crc)
MV.RETAIL = {cam = {0, 0, 0}, rot_y = -7.5}

--- The current menu when the rules hide the model view in it; nil otherwise.
function MV.hidden(rules)
  local t = type(rules) == "table" and rules.hide_in_menus or nil
  if type(t) ~= "table" then
    return nil
  end
  for _, menu in ipairs(t) do
    if VRFW.host.command(MV.EXIST_MENU, menu) == true then
      return menu
    end
  end
  return nil
end

--- The current menu when the rules offer the model view in it; nil otherwise.
function MV.offer(rules)
  local t = type(rules) == "table" and rules.view_in_menus or nil
  if type(t) ~= "table" then
    return nil
  end
  local key = rules.view_key
  if key ~= nil and not VRFW.param.has(key) then
    return nil
  end
  for _, menu in ipairs(t) do
    if VRFW.host.command(MV.EXIST_MENU, menu) == true then
      return menu
    end
  end
  return nil
end

-- Asks that menu to open the retail view, which runs its own visual check mode.
MV.CROSS_CALL = 830228314              -- (menu crc, global function name, ...) in that menu's VM
--- Calls the view function of `rules` in `menu` over a cross-menu call; answers that call's result.
function MV.open_view(rules, menu)
  local fn = type(rules) == "table" and rules.view_func or "EVT_FVD_Open"
  return VRFW.host.command(MV.CROSS_CALL, menu, fn)
end

--- Moves the view camera to the retail offset; answers has, x, y, z of the camera before the move.
function MV.camera()
  local has, x, y, z = VRFW.host.command(MV.CAM_GET, MV.CAM)
  local c = MV.RETAIL.cam
  VRFW.host.command(MV.CAM_OFS, MV.CAM, c[1], c[2], c[3])
  return has, x, y, z
end

-- Runs after a build and again once the model is loaded.
--- Frames the model of (layer, idx): camera, rotation and stand motion; runs after a build and again once the model is loaded.
function MV.frame(layer, idx)
  MV.camera()
  VRFW.host.menu_command(MV.ROT, layer, idx or 0, 0, MV.RETAIL.rot_y, 0)
  VRFW.host.menu_command(MV.MOTION, layer, idx or 0, MV.STAND, 0, 0, 0, 0, 0)
  VRFW.host.menu_command(MV.POSE_UPD, layer, idx or 0, MV.POSE_ARG)
end
