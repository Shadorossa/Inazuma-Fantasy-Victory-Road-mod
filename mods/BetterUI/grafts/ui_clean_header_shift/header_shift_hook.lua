-- BetterUI header_shift: this menu's root layers move up under the compact top header (content\header_shift\menus.toml,
-- VRFW_HeaderShift). Off with the ui_clean kill switch (EVT_UI_PRESET = "off") or EVT_UI_FLAGS.header_short = false.
VRFW_HeaderShift.Apply("BetterUI.header_shift", function()
  return EVT_UI_PRESET ~= "off" and (type(EVT_UI_FLAGS) ~= "table" or EVT_UI_FLAGS.header_short ~= false)
end)
