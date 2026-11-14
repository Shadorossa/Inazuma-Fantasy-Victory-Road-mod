-- The play guide list with the help row (kind 0) last, applied by the list-rows service each time the list is set up.
if VRFW.list_rows ~= nil then
  VRFW.list_rows.order(VRFW.list_rows.PLAY_GUIDE, { id = "BetterUI.guide_rows", last = { 0 } })
end
