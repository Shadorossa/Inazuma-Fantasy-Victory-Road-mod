-- Chronicle top menu: its layers hidden while the Players Universe character list shows its 3D model (universe_model.lua).
local retail_setup = OnSetupLayer
function OnSetupLayer(layer, instance, ...)
  VRFW.layer_cover.record(layer, instance)
  return retail_setup(layer, instance, ...)
end

local retail_init = OnInit
function OnInit(...)
  retail_init(...)
  VRFW.layer_cover.listen("CharacterReforged.UniverseCover", VRFW.crc32("chronicle_mode_top_menu"),
    "character_reforged_universe_cover_chronicle")
end
