-- model_wait_guard (VRFW retail bug fix; lua\_all\08_model_wait_guard.lua):
-- «Equipamiento» (equip_menu_select) runs OnOpenLayer of its status base (soccer11_05_equip_status_base) in its open
-- coroutine, and that callback waits with no frame limit until the layer's 3D model component reports its resources
-- built (read 2787787510). When that never happens the open never ends: nothing of the screen is drawn and it takes no
-- input. Capped at 120 frames, then the retail goes on with the read answered true. No engine call at load time.
if VRFW_ModelWaitGuard ~= nil then
  VRFW_ModelWaitGuard("OnOpenLayer", { layer = 2917320188, ready = 2787787510, layer_arg = true, max = 120 })
end
