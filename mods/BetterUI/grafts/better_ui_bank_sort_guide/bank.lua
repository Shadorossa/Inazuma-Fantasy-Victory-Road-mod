-- ===== EVT better_ui bank_sort_guide BEGIN =====
do
local better_ui_block = function()
BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

if BetterUI.preset == nil then
  BetterUI.preset = "limpio"
end
BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, corner_buttons = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

@UI_WRAP@

-- Layer and icon ids of chara_bank_menu.
local GUIDE_LAYER = 1138543975
local ICON_SORT = 2387151820

if VRFW.footer_prompts ~= nil and VRFW.footer_prompts.hide ~= nil then
  VRFW.footer_prompts.hide({name = "BetterUI.BankSortGuide", icon = ICON_SORT, layer = GUIDE_LAYER,
    when = function()
      return UiOn("bank_sort_guide")
    end})
end

end
better_ui_block()
end
-- ===== EVT better_ui bank_sort_guide END =====
