-- The framework's own patch folder of its slot screen (evt_save_slot_menu). Its [[hooks]] entry gives the framework's
-- Lua root the screen's fingerprint (require EVT_SlotMenu_OnSubWindow), so the loader identifies the screen's VM with
-- any set of mods. This file only marks the VM as identified; the screen's OnInit logs it (VRFW_SS_IDENTIFIED).
-- Nothing calls the engine at chunk load.
VRFW_SS_IDENTIFIED = type(EVT_PATCH) == "table" and tostring(EVT_PATCH.script) or "evt_save_slot_menu"
