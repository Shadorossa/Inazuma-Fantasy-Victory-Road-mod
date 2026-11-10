-- VRFW: the photo scene after a won competition (the game's Victory Road final photo; docs/framework/trophy.md).
do
  local PHOTO = {
    TROPHY_INFO = VRFW.commands.VRFW_TROPHY_INFO,   -- CMND_VRFW_TROPHY_INFO
    TEXT_GET = VRFW.commands.TEXT_GET,              -- CMND_TEXT_GET
    LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    LOG = VRFW.commands.VRFW_LOG,                    -- CMND_VRFW_LOG
    TOURNAMENT_PLATE = 718961583,     -- vroad01_52_tournament_plate_big
    TOURNAMENT_TEXT = 1691757743,     -- _text_tournament01
    ONLINE_PLATES = {
      [3546704442] = true,            -- soccer00_40_username_champion_photo
      [2280287248] = true,            -- soccer00_43_user_title
      [3351788064] = true,            -- cmn01_54_user_id_c
    },
    STEMS = { "victory_road_final_game_auto_photo_menu", "victory_road_final_game_manual_photo_menu" },
  }
  local trophy, logged = nil, false

  -- the celebration being shown: { active, name, name_id } (CMND_VRFW_TROPHY_INFO), asked once per photo scene; false = none
  local function shown_trophy()
    if trophy == nil then
      local info = VRFW.host.command(PHOTO.TROPHY_INFO)
      trophy = type(info) == "table" and info.active == true and info or false
    end
    return trophy
  end

  local function opened(layer, index)
    local t = shown_trophy()
    if not t then return end
    index = type(index) == "number" and index or 0
    if PHOTO.ONLINE_PLATES[layer] then
      VRFW.host.menu_command(PHOTO.LAYER_VISIBLE, layer, index, false)
    elseif layer == PHOTO.TOURNAMENT_PLATE and type(t.name_id) == "number" and t.name_id ~= 0 then
      local name = VRFW.host.command(PHOTO.TEXT_GET, t.name_id)
      if type(name) == "string" then
        VRFW.host.menu_command(PHOTO.SET_TEXT, layer, PHOTO.TOURNAMENT_TEXT, name, index)
      end
    end
    if not logged then
      logged = true
      VRFW.host.command(PHOTO.LOG, "VRFW.trophy",
        "celebration photo: online plates hidden, plate named " .. tostring(t.name))
    end
  end

  if VRFW.host then
    for _, stem in ipairs(PHOTO.STEMS) do
      VRFW.host.on(stem, "OnInit", { id = "menu_engine.trophy_photo.init", phase = "before", create = true,
        fn = function() trophy, logged = nil, false end })
      VRFW.host.on(stem, "OnOpenLayer", { id = "menu_engine.trophy_photo.plates", phase = "after", create = true,
        fn = function(layer, index) pcall(opened, layer, index) end })
    end
  end
end
