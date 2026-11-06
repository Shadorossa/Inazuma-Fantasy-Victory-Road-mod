-- image spill (VRFW, assets/lua/menu/_all/09_image_spill.lua): this resident menu (created at the title, alive
-- until the game reset) holds the sprite redirects' own atlases for every menu. Nothing runs at load time.
if VRFW_ImageSpill ~= nil then
  VRFW_ImageSpill.holder = "rpg_info_window"
end
