-- VRFW bb_pages, campaign grid only (enjoy_team_select_menu_campaign).
do
  local closeEnd = OnCloseEndLayer
  function OnCloseEndLayer(a1, a2, ...)
    local r = table.pack(closeEnd(a1, a2, ...))
    local B = VRFW.battle_bay_pages
    if a1 == B.DIFFWIN and B.on and (B.total > 1 or B.seasons >= 2) then
      local ok, err = pcall(VRFW.battle_bay_pages.redraw)
      if not ok then
        VRFW.battle_bay_pages.log("redraw error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end
end
