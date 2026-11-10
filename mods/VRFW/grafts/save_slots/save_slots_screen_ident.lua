-- The framework's own patch folder of its slot screen (vrfw_save_slot_menu).
VRFW.save_slots = VRFW.save_slots or {}
VRFW.save_slots.IDENTIFIED = type(VRFW.patch) == "table" and tostring(VRFW.patch.script) or "vrfw_save_slot_menu"
