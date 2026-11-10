-- Players Universe character list model: its box from config.toml [players_universe] for the list's menu Lua.
CharacterReforged = CharacterReforged or {}
CharacterReforged.UniverseModel = CharacterReforged.UniverseModel or {}
local U = CharacterReforged.UniverseModel

local setting = VRFW.config

--- The model's box on the character card (1920 x 1080 screen px, y down): x, y, w, h.
function U.Box()
  return setting("players_universe.model_box_x"), setting("players_universe.model_box_y"),
    setting("players_universe.model_box_w"), setting("players_universe.model_box_h")
end
