-- ===== EVT ui_clean bank_sort_guide BEGIN =====
-- research/scripts/ui_clean_build.py, docs/game/ui-redesign.md section 11
do
local EVT_UI_Block = function()
-- EVT ui_clean graft: common part (research/scripts/ui_clean_build.py, docs/game/ui-redesign.md section 11).
-- Appended as one child function to the retail bytecode of a menu and run at the end of its main chunk.
-- Build-time placeholders: limpio (string), the owning mod's ui_flags.toml flags, merged (Lua table body), bank (menu tag for the log).
local EVT_UI_MARK = "EVT_UI_CLEAN_GRAFT"

-- Kill switch. EVT_UI_PRESET = "off" makes every ui_clean wrapper pass everything through unchanged.
-- Each feature can also be switched off on its own in EVT_UI_FLAGS (set by the build, see --preset / --no-*).
if EVT_UI_PRESET == nil then
  EVT_UI_PRESET = "limpio"
end
EVT_UI_FLAGS = EVT_UI_FLAGS or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, corner_buttons = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if EVT_UI_FLAGS[k] == nil then
    EVT_UI_FLAGS[k] = v
  end
end

@UI_WRAP@

-- EVT ui_clean, menu chara_bank_menu (Banco): the bottom guide entry of the sort mode ("Por adquisición",
-- "Por rareza", ... with the swap / CMD_FUNC2 glyph 2387151820) is hidden through VRFW_FooterPrompts.Hide (taken out of
-- the guide tables and the same place out of its keys), so the other entries close up (the guide row is laid out by
-- the engine from the tables). The sort itself (CMD_FUNC2 key binding of the menu setting) and the sort label at the
-- top right of the list are not touched. Flag: bank_sort_guide.
local GUIDE_LAYER = 1138543975
local ICON_SORT = 2387151820

if VRFW_FooterPrompts ~= nil and VRFW_FooterPrompts.Hide ~= nil then
  VRFW_FooterPrompts.Hide({Name = "BetterUI.BankSortGuide", Icon = ICON_SORT, Layer = GUIDE_LAYER,
    When = function()
      return UiOn("bank_sort_guide")
    end})
end

end
EVT_UI_Block()
end
-- ===== EVT ui_clean bank_sort_guide END =====
