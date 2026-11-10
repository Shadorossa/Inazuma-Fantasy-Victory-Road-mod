
local S = VRFW.synergy
if S == nil or S.apply_panel == nil then return end
local CMD_ITEM_OF_INV = 2662166687

local function item_of(inv)
  if type(inv) ~= "number" or inv == 0 then return 0 end
  local it = VRFW.host.command(CMD_ITEM_OF_INV, inv, 0)
  if type(it) == "number" then return it end
  return 0
end

S.list = S.list or {}
local W = S.list

local CMD_LIST_COUNT = 2389020234
local LIST = 1986515389                    -- team05_03_synergy_list
local TAB = 4044286600                     -- cmn06_20_list_tab_item

-- UpdateItemEquipMenu(inv): the focused synergy's detail.
if type(UpdateItemEquipMenu) == "function" and UpdateItemEquipMenu ~= W.UpdateItemEquipMenu then
  local orig = UpdateItemEquipMenu
  W.UpdateItemEquipMenu = function(a1, ...)
    local drawn = W.shown_inv == nil or a1 ~= W.shown_inv
    W.shown_inv = a1
    local r = orig(a1, ...)
    if drawn then
      local ok, e = pcall(S.apply_panel, item_of(a1))
      if not ok and S.err == nil then
        S.err = tostring(e)
        VRFW.logger.new("VRFW synergy panel")("error", S.err)
      end
    end
    return r
  end
  UpdateItemEquipMenu = W.UpdateItemEquipMenu
end

-- OnChangeFocus on the tabs: another tab's list.
if type(OnChangeFocus) == "function" and OnChangeFocus ~= W.OnChangeFocus then
  local orig = OnChangeFocus
  W.OnChangeFocus = function(a1, ...)
    local r = table.pack(orig(a1, ...))
    if a1 == TAB then
      W.shown_inv = nil
      local n = VRFW.host.menu_command(CMD_LIST_COUNT, LIST)
      if n == 0 then
        W.shown_inv = 0
        pcall(S.apply_panel, 0)
      end
    end
    return table.unpack(r, 1, r.n)
  end
  OnChangeFocus = W.OnChangeFocus
end

-- OnOpenLayer: the extra layers' instances (the retail one runs first)
if OnOpenLayer ~= W.OnOpenLayer then
  local orig = OnOpenLayer
  W.OnOpenLayer = function(a1, a2, ...)
    local r
    if type(orig) == "function" then r = orig(a1, a2, ...) end
    pcall(S.built, a1, a2)
    return r
  end
  OnOpenLayer = W.OnOpenLayer
end
