-- (another mod's patch redefines SetupElementIconTexture, so a plain wrapper would be dropped).
local H = VRFW.host
if type(H) == "table" and type(H.on) == "function" then
  H.on("team_dock_menu_rpg_battle", "SetupElementIconTexture", {id = "BetterQoL.neutral_element_dock", phase = "after",
    fn = function(r, a1, a2)
      local el = funcLuaCommand(1131797651, a2, 8)
      if el == 0 or el == 5 then
        funcLuaMenuCommand(558735651, 201053059 --[[mainmenu04_03_2_chara_status]], MAIN_MENU.GetTexturePathCommandCommonIcon(),
                           3196645112 --[[icon_cmd_type00]], 1265099231 --[[icon_type_dmy01]], 0, a1)
      end
    end})
end
