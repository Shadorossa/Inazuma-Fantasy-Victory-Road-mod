-- lua_patch.scope: used
-- VRFW.summon_presentation: the game's summon performance (3D player, plates, «WELCOME!») as presentation only.
-- It opens soccer_summon_menu for cards a mod names. It never grants or consumes anything: the caller already did.
if VRFW.summon_presentation == nil then
  local Presentation = {}

  local SUMMON_MENU = 369188769        -- soccer_summon_menu
  local FADE = 609722083               -- (1 = to black | 0 = from black, seconds)
  local FADE_SECONDS = 0.3
  local FADE_WAIT_STEPS = 120
  local CAMERA_GET = 1877348924        -- (camera) -> has, x, y, z
  local CAMERA_SET = 284729675         -- (camera, x, y, z)
  local MENU_CAMERA = 1752770328       -- MenuCamera
  local MAX_PLAYERS = 30
  local MAX_OPEN_STEPS = 36000         -- the menu closes itself after the last player; this only ends a stuck one
  local KEY = "VRFW.summon_presentation."
  local KEY_COUNT = KEY .. "count"
  local KEY_TAKES_INPUT = KEY .. "takes_input"

  local log = VRFW.logger.new("VRFW.summon_presentation")

  local function card_key(index)
    return KEY .. "card_" .. index
  end

  local function rarity_key(index)
    return KEY .. "rarity_" .. index
  end

  local function clear_u32(name)
    VRFW.param.clear(name .. "_hi")
    VRFW.param.clear(name .. "_lo")
  end

  local function clear_request(count)
    VRFW.param.clear(KEY_COUNT)
    VRFW.param.clear(KEY_TAKES_INPUT)
    for index = 0, count - 1 do
      clear_u32(card_key(index))
      VRFW.param.clear(rarity_key(index))
    end
  end

  local function send_request(players, takes_input)
    for index, player in ipairs(players) do
      VRFW.param.set_u32(card_key(index - 1), player.card)
      VRFW.param.replace(rarity_key(index - 1), player.rarity)
    end
    VRFW.param.replace(KEY_TAKES_INPUT, takes_input and 1 or 0)
    VRFW.param.replace(KEY_COUNT, #players)
  end

  --- The request of this opening for the summon menu's Lua, consumed: {count, takes_input, cards, rarities}; nil = none.
  function Presentation.take_request()
    local count = tonumber(VRFW.param.get(KEY_COUNT)) or 0
    if count <= 0 then
      return nil
    end
    local request = {count = count, takes_input = tonumber(VRFW.param.get(KEY_TAKES_INPUT)) == 1, cards = {}, rarities = {}}
    for index = 0, count - 1 do
      request.cards[index] = VRFW.param.get_u32(card_key(index)) or 0
      request.rarities[index] = tonumber(VRFW.param.get(rarity_key(index))) or 0
    end
    clear_request(count)
    return request
  end

  local function wait_fade()
    local steps = 0
    while funcLuaCommand(VRFW.commands.BRIGHT_IS_FADE) and steps < FADE_WAIT_STEPS do
      steps = steps + 1
      coroutine.yield()
    end
  end

  local function read_camera()
    local ok, has, x, y, z = pcall(funcLuaCommand, CAMERA_GET, MENU_CAMERA)
    if ok and has == true and type(x) == "number" then
      return {x, y or 0, z or 0}
    end
    return nil
  end

  local function write_camera(camera)
    if camera ~= nil then
      pcall(funcLuaCommand, CAMERA_SET, MENU_CAMERA, camera[1], camera[2], camera[3])
    end
  end

  local function menu_exists()
    return funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, SUMMON_MENU) == true
  end

  -- From a coroutine of a menu's Step. spec = {players = {{card, rarity}, ...}, before, after, restore_camera, fade_back,
  -- takes_input}. The screen goes black, before() runs, the performance plays, after() runs. fade_back = lit again here;
  -- otherwise the caller lights it. restore_camera = the menu camera comes back. takes_input = the summon menu's rule:
  -- the summon menu switches its own input on before the performance.
  --- Plays the summon presentation for spec.players; answers true when played, false without players.
  function Presentation.play(spec)
    local players = spec.players
    local count = math.min(#players, MAX_PLAYERS)
    if count == 0 then
      return false
    end
    local listed = {}
    for index = 1, count do
      listed[index] = players[index]
    end
    local camera = spec.restore_camera and read_camera() or nil
    funcLuaCommand(FADE, 1, FADE_SECONDS)
    wait_fade()
    if spec.before ~= nil then
      spec.before()
    end
    send_request(listed, spec.takes_input == true)
    funcLuaCommand(VRFW.commands.OPEN_MENU_OBJECT, SUMMON_MENU)
    coroutine.yield()
    coroutine.yield()
    log("open", count, "player(s), menu exists", tostring(menu_exists()))
    local steps = 0
    while menu_exists() and steps < MAX_OPEN_STEPS do
      steps = steps + 1
      coroutine.yield()
    end
    if steps >= MAX_OPEN_STEPS then
      log("still open after", steps, "steps: closed")
      funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, SUMMON_MENU)
    end
    clear_request(count)
    write_camera(camera)
    if spec.after ~= nil then
      spec.after()
    end
    write_camera(camera)
    if spec.fade_back then
      funcLuaCommand(FADE, 0, FADE_SECONDS)
      wait_fade()
    end
    return true
  end

  Presentation.MAX_PLAYERS = MAX_PLAYERS
  VRFW.summon_presentation = Presentation
end
