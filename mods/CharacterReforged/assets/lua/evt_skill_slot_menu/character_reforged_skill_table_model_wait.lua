-- Character Reforged: the skill table (evt_skill_slot_menu, built on the retail equip_menu_select) under the
-- VR-Framework's model wait guard (lua\_all\08_model_wait_guard.lua). The screen's open runs OnOpenLayer of its status
-- base (soccer11_05_equip_status_base) in the open coroutine, and that callback waits with no frame limit until the
-- layer's 3D model component reports its resources built (read 2787787510) before it sets the player's model. When that
-- never happens the open never ends: no layer of the screen is drawn and it takes no input. The guard caps the wait at
-- 120 frames, then the open goes on (the model shows up by itself once it is ready). No engine call at load time.
if VRFW_ModelWaitGuard ~= nil then
  VRFW_ModelWaitGuard("OnOpenLayer", { layer = 2917320188, ready = 2787787510, layer_arg = true, max = 120 })
end
