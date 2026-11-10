BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}

if BetterQoL.album_visit == nil then
  BetterQoL.album_visit = {
    C = { CLOSE_MENU = VRFW.commands.CLOSE_MENU_OBJECT, IS_MENU = VRFW.commands.IS_EXIST_MENU_OBJECT,
      CAM_GET = 1877348924, CAM_SET = 284729675, LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE },
    PAGE = 3856542290,                    -- betterqol_album_menu
    PLATE = 1427722143,                   -- personal_plate_menu (opened by the page)
    PLATE_FLAG = 2398708549,
    PLATE_CARD = 2716223290,              -- VRFW.plate_card
    CAM = 1752770328,                     -- MenuCamera
    BACKGROUND = 367379312,               -- mainmenu90_00_background
    HEADER_TYPE = 9,
    TITLE = 4006794419,
    CLOSE_AGAIN = 30, CLOSE_MAX = 600,
    CAM_AGAIN = {30, 90},
    co = nil,
  }
end

local AL = BetterQoL.album_visit
local Page = BetterQoL.page
local Caseta = Page.caseta
local Log = Page.logger("betterqol album")

-- the page's cross-call when its multiple selection opens or closes, and around a presentation (hidden): the footer lives in this menu
function BetterQoL_AlbumGuide(multi, hidden)
  Caseta.guide(hidden == true and {} or Page.album_guide(multi == true))
end

local function Background(on)
  if AL.background_on == on then return end
  AL.background_on = on
  VRFW.host.menu_command(AL.C.LAYER_VISIBLE, AL.BACKGROUND, 0, on)
  Log("caseta background " .. (on and "shown" or "hidden"))
end

function BetterQoL_AlbumCasetaBackground(on)
  Background(on == true)
end

local function Camera()
  local has, x, y, z = VRFW.host.command(AL.C.CAM_GET, AL.CAM)
  return (has == true and type(x) == "number") and {x, y or 0, z or 0} or nil
end

local function CameraBack(cam)
  if cam ~= nil then VRFW.host.command(AL.C.CAM_SET, AL.CAM, cam[1], cam[2], cam[3]) end
end

local function Visit()
  local cam = Camera()
  local row = Caseta.leave(AL.PAGE, AL.HEADER_TYPE, AL.TITLE, Page.album_guide(false))
  Log("page open asked (row " .. tostring(row) .. ")")
  Caseta.wait_closed(AL.PAGE)
  Background(true)
  local frames, asked = 0, nil
  while VRFW.host.menu_command(AL.C.IS_MENU, AL.PLATE) == true and frames < AL.CLOSE_MAX do
    if asked == nil or frames - asked >= AL.CLOSE_AGAIN then
      VRFW.host.command(AL.C.CLOSE_MENU, AL.PLATE)
      asked = frames
    end
    frames = frames + 1
    coroutine.yield()
  end
  if VRFW.param.has(AL.PLATE_FLAG) then VRFW.param.clear(AL.PLATE_FLAG) end
  if VRFW.param.has(AL.PLATE_CARD) then VRFW.param.clear(AL.PLATE_CARD) end
  CameraBack(cam)
  Caseta.go_back(row)
  Log("back from the page" .. (frames >= AL.CLOSE_MAX and " (the plate was still there)" or ""))
  local waited = 0
  for _, due in ipairs(AL.CAM_AGAIN) do
    while waited < due do
      waited = waited + 1
      coroutine.yield()
    end
    CameraBack(cam)
  end
end

if BetterQoL.album_visit.hooked == nil then
  BetterQoL.album_visit.hooked = true
  AL.open = Caseta.visits(AL, Visit, Log,
    function() AL.co, AL.background_on = nil, nil end,
    function() Background(true) end)
end
BetterQoL.album = BetterQoL.album or {}
BetterQoL.album.open = AL.open
