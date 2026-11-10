BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
if BattleBayDeluxe.lineup_pages == nil and VRFW.player_pages ~= nil and type(VRFW.player_pages.show_when) == "function" then
  local L = {
    FLAG = 2100506454,                   -- crc32 of BattleBayDeluxe.lineup (this mod's parameter)
    CONTEXT = "battle_bay",              -- the framework context of the Battle Bay's menus
    MODE_IS = VRFW.commands.VRFW_MODE_IS,
    PAGES = {"vrfw.SixthSense", "vrfw.TeamPassives", "BetterQoL.Career"},
  }
  BattleBayDeluxe.lineup_pages = L

  -- false while the lineup screen shows the player page
  function L.shown()
    if not VRFW.param.has(L.FLAG) then
      return true
    end
    local okm, inside = pcall(funcLuaCommand, L.MODE_IS, L.CONTEXT)
    return not (okm and inside == true)
  end

  for _, name in ipairs(L.PAGES) do
    VRFW.player_pages.show_when(name, L.shown)
  end
end
