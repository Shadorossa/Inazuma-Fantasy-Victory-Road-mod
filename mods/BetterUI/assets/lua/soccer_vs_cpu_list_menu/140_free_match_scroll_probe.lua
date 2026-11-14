-- Diagnostics (scroll bar missing on the free match team list with free_match_rows.toml): logs the visibility of the
-- list's scroll line and knob meshes at focus changes when it changes. Bounded: one line per change.
if VRFW.host ~= nil then
  local LIST = VRFW.ids.crc32("team05_03_soccer_cpu_opponent_list")
  local LINE, KNOB = VRFW.ids.crc32("_scr_line01"), VRFW.ids.crc32("_scr_obj01")
  local log = VRFW.logger.new("BetterUI.free_match_scroll")
  local function probe(point)
    local line = VRFW.host.menu_command(VRFW.commands.IS_MESH_VISIBLE, LIST, LINE, 0)
    local knob = VRFW.host.menu_command(VRFW.commands.IS_MESH_VISIBLE, LIST, KNOB, 0)
    local value = tostring(line) .. "/" .. tostring(knob)
    log.changed("scroll", value, "scroll line/knob visible", value, "at", point)
  end
  for _, point in ipairs({ "OnChangeFocus" }) do
    VRFW.host.on("soccer_vs_cpu_list_menu", point, {
      id = "BetterUI.free_match_scroll_probe", phase = "after",
      fn = function() probe(point) end,
    })
  end
end
