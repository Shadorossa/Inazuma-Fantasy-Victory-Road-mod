-- BetterUI (mod BetterUI, prefix BetterUI), the kit picker («Cambiar equipación», equip_uniform_menu_list): the four
-- kit models on the right (fielder, keeper, coach, manager) are drawn through the picker's own menu camera
-- (0xEA129747, eye (0, 2.25, 12.5), about 245 px a metre at 1080p) and the leftmost one stands too close to the kit
-- grid. The camera's offset (CMND 284729675 on a named camera, the call the contact map and the model view use on the
-- shared MenuCamera) moves the whole group: offset -x = models +x on screen. Set with each model build (absolute, no
-- drift) and given back to 0 when the picker closes, because the item screen (item01_01_list_base) uses the same camera.
-- The LOCAL / VISITANTE header and the kit name move with the models in content\menus\kit_picker_view.toml.
-- Wrappers by assignment (the script has no VRFW_Host host); no engine call at load time.
if BetterUI_KitViewShift == nil and type(UpdateCharaModel) == "function" and type(FinalizeMenu) == "function" then
  local K = {
    CAMERA = 3927086919,         -- the picker's menu camera (m_menuCameraNameCrc -367880377 of team06_01_uniform_list)
    CAMERA_OFFSET = 284729675,   -- (camera, x, y, z): the named camera's offset
    SHIFT_METERS = 0.12,         -- the group's move to the right: about 30 px at 1080p (= content\menus\kit_picker_view.toml)
    applied = false,
  }
  BetterUI_KitViewShift = K

  local function log(...)
    if PRINT ~= nil then
      pcall(PRINT, "BetterUI kit_view", ...)
    end
  end

  -- camera offset x for a shift of the models to the right
  function K.Set(meters)
    local ok = pcall(funcLuaCommand, K.CAMERA_OFFSET, K.CAMERA, -meters, 0, 0)
    if not K.logged then
      K.logged = true
      log("camera offset", -meters, tostring(ok))
    end
  end

  local update_model = UpdateCharaModel
  UpdateCharaModel = function(slot, ...)
    local r = table.pack(update_model(slot, ...))
    if not K.applied then
      K.applied = true
      K.Set(K.SHIFT_METERS)
    end
    return table.unpack(r, 1, r.n)
  end

  local finalize = FinalizeMenu
  FinalizeMenu = function(...)
    if K.applied then
      K.applied = false
      K.Set(0)
    end
    return finalize(...)
  end
end
