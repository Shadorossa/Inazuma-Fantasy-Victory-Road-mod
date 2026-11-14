local UNIVERSE_SIGN_LIST = 579326081      -- (0, universe) -> count; (1, universe, index) -> sign
local STAR_KEY_INFO = 1041824793          -- (4, sign, star index) -> the sign the star draws from.
local STAR_KEY_IS_LAST = 3                -- sub of STAR_KEY_INFO: the star is its constellation's last star
local STARS_PER_SIGN = 8
local STAR_INFO = 2558342785              -- (6, sign) -> the layer of the sign's drawing
local ATTACH_TARGET = VRFW.commands.SET_ATTACH_LOCATOR_TARGET           -- (layer, instance, attach, bone)
local OPEN_LAYER = VRFW.commands.OPEN_LAYER
local RARE_LAYER = VRFW.ids.crc32("universe01_08_rare_star_key")
local RARE_ATTACH = VRFW.ids.crc32("star_rare")            -- where the drawing holds the last star
local ORB_STATE = VRFW.commands.CHRONICLEDELUXE_UNIVERSE_ORB_STATE
local ORB_PULL = VRFW.commands.CHRONICLEDELUXE_UNIVERSE_ORB_PULL
local PROP_LIST_SIGN = 1387388075         -- the sign chara_pack_probability_list_menu opens
local PROP_SEARCH_RESULT = 1963839147     -- the sign the search result screen hands back
local PROP_LIST_LAST_STAR = 478309527
local MAX_LOG_LINES = 24                  -- first run diagnostics: one line per pull, bounded

local STAR_KEY_LAYER = 4246964035
local STAR_INFO_STARS = 3                 -- sub of STAR_INFO: (sign) -> ok, stars of the constellation
local LAST_STAR_PULLED = 1810803886       -- (sign) -> true once a last star pull was made: the game's stamp rule
local SIGN_INFO = 1112436817              -- (0, sign) -> ok, name
local ICON_LAYER = VRFW.ids.crc32("universe01_11_chara_icon")
local CLOSE_LAYER = VRFW.commands.CLOSE_LAYER            -- (layer, instance)
local MAX_STAMP_LOG_LINES = 8
local MAX_ICON_LOG_LINES = 12
local UNIVERSE_DAY = VRFW.commands.CHRONICLEDELUXE_UNIVERSE_DAY
local SET_GLOBAL_BIT_FLAG = VRFW.commands.SET_GLOBAL_BIT_FLAG    -- (flag, on)

-- the item prize of a pull (content\universe_prizes), given on this screen once the result screen has closed
local ROLL_PRIZE = VRFW.commands.CHRONICLEDELUXE_ROLL_UNIVERSE_PRIZE
local HAS_ROOM = 765340069                -- (item, count) -> true when it fits
local ADD_ITEM = VRFW.commands.ADD_ITEM_ONLY               -- (item, count)
local WINDOWS_FREE_ASK = 218753920
local WINDOWS_FREE = 682363669
local WINDOW_MAKE = 2127769271            -- (11, text id, item) -> the retail item window
local WINDOW_RUN = VRFW.commands.RUN_INFO_WIN_STACK             -- (window)
local WINDOW_RUNNING = VRFW.commands.IS_RUN_INFO_WIN_STACK
local TEXT_ITEM_GOT = VRFW.ids.crc32("sysmes_item_get")

local log = type(VRFW.logger) == "table" and VRFW.logger.new("ChronicleDeluxe.Universe") or function() end
local logged = 0
local star_of_pool = nil                  -- pool sign -> { sign = visible sign, star = 1..8 }
local wanted_star = nil                   -- The star a search result asked for.
local prize_due = false                   -- Back from a pull's event, its result screen is on.
local restoring = false
local pulled = nil                        -- { sign, star } of the pull read back
local applied_day = nil                   -- the day whose window flags this screen set
local last_star_of = {}                   -- sign -> index of its last star (0 = none), read once per sign
local orb_of = {}                         -- sign -> { count, pending, active }, read once per sign
local pull_now = nil                      -- { sign, star, rate_up } from the confirmation to the pack event
local rare_instance = {}                  -- sign -> instance of its last star layer
local rate_up_placed = {}                 -- sign -> its last star layer already sits on the rate-up orb

-- one bounded walk, the first time it is needed
local function pools()
  if star_of_pool ~= nil then
    return star_of_pool
  end
  star_of_pool = {}
  local universe = GetSelectedUniverse()
  local ok, count = funcLuaMenuCommand(UNIVERSE_SIGN_LIST, 0, universe)
  if not ok then
    return star_of_pool
  end
  for i = 0, count - 1 do
    local has, sign = funcLuaMenuCommand(UNIVERSE_SIGN_LIST, 1, universe, i)
    if has then
      for star = 1, STARS_PER_SIGN do
        local got, pool = funcLuaMenuCommand(STAR_KEY_INFO, 4, sign, star - 1)
        if got and pool ~= 0 then
          star_of_pool[pool] = { sign = sign, star = star }
        end
      end
    end
  end
  log("stars with a pool", count * STARS_PER_SIGN)
  return star_of_pool
end

local function last_star(sign)
  if not sign or sign == 0 then
    return 0
  end
  local found = last_star_of[sign]
  if found == nil then
    found = 0
    for star = 1, STARS_PER_SIGN do
      local got, is_last = funcLuaMenuCommand(STAR_KEY_INFO, STAR_KEY_IS_LAST, sign, star - 1)
      if got and is_last then
        found = star
        break
      end
    end
    last_star_of[sign] = found
  end
  return found
end

local function orb(sign)
  local state = orb_of[sign]
  if state == nil then
    local saved = funcLuaCommand(ORB_STATE, sign)
    state = type(saved) == "table" and { count = saved[1], pending = saved[2], active = saved[3] } or { count = 0, pending = 0, active = 0 }
    orb_of[sign] = state
  end
  return state
end

-- whether orb `star` of `sign` draws from the constellation's last star list now
local function draws_last_star(sign, star)
  if not sign or sign == 0 or star == 0 then
    return false
  end
  if restoring then
    return orb(sign).active == star
  end
  if pull_now ~= nil then
    return pull_now.rate_up and sign == pull_now.sign and star == pull_now.star
  end
  return orb(sign).pending == star
end

-- the day's window flags, once per day while the screen is open (a new day applies on the next star read)
local function apply_day()
  if type(VRFW.daily) ~= "table" then
    return
  end
  local day = VRFW.daily.period("day")
  if day == nil or day == applied_day then
    return
  end
  local flags = funcLuaCommand(UNIVERSE_DAY, day)
  if type(flags) ~= "table" then
    return
  end
  for i = 1, #flags - 1, 2 do
    funcLuaCommand(SET_GLOBAL_BIT_FLAG, flags[i], flags[i + 1] == 1)
  end
  applied_day = day
  log("day", day, "window flags", math.floor(#flags / 2))
end

-- every reader of a star's list (side window, list button, pull, read back) asks this first
VRFW.host.wrap_once("GetOverrideLotteryStarSignId", "ChronicleDeluxe.universe_stars", function(retail_override, sign, star)
  apply_day()
  local rate_up = draws_last_star(sign, star)
  if restoring then
    pulled = { sign = sign, star = star, rate_up = rate_up }
  end
  if rate_up and last_star(sign) ~= 0 then
    star = last_star(sign)
  end
  return retail_override(sign, star)
end)

-- an orb comes back after its pull: only the constellation's last star stays closed, the rate-up orb stands for it
VRFW.host.wrap_once("IsStarKeyValid", "ChronicleDeluxe.universe_stars", function(retail_valid, sign, star)
  local last = last_star(sign)
  local valid
  if last == 0 or star == 0 or star > STARS_PER_SIGN then
    valid = retail_valid(sign, star)
  else
    valid = star ~= last
  end
  -- a spent orb takes the game's used orb look; nothing is saved, so it comes back when a card is free again
  return valid and not ChronicleDeluxe.UniversePool.orb_spent(sign, star, GetOverrideLotteryStarSignId)
end)

-- while orbs run out the stamp follows them: on when no orb of the constellation has a card left
local stamp_logged = 0
VRFW.host.wrap_once("SetupStarSignClearStamp", "ChronicleDeluxe.universe_stars", function(retail_clear_stamp, layer, instance)
  local pool = ChronicleDeluxe.UniversePool
  if not pool.orbs_run_out() then
    return retail_clear_stamp(layer, instance)
  end
  local sign = SearchSelectedStarSignId(instance)
  if not sign or sign == 0 then
    return
  end
  local got, stars = funcLuaMenuCommand(STAR_INFO, STAR_INFO_STARS, sign)
  local last, orbs, spent = last_star(sign), 0, 0
  for star = 1, got and stars or 0 do
    if star ~= last then
      orbs = orbs + 1
      if pool.orb_spent(sign, star, GetOverrideLotteryStarSignId) then
        spent = spent + 1
      end
    end
  end
  local complete = orbs > 0 and spent == orbs
  if complete then
    funcLuaMenuCommand(OPEN_LAYER, layer, instance)
  end
  if stamp_logged < MAX_STAMP_LOG_LINES then
    local pulled_last = funcLuaCommand(LAST_STAR_PULLED, sign) == true
    if complete or pulled_last then
      stamp_logged = stamp_logged + 1
      log("clear stamp: sign", sign, "orbs spent", spent, "of", orbs, "stamp", complete, "last star pulled", pulled_last)
    end
  end
end)

function DeactiveStarKeyValid()
  local sign = GetSelectedStarSignId()
  if not sign or sign == 0 then
    return
  end
  local star = GetNowSelectStarKeyLayerIndex() + 1
  pull_now = { sign = sign, star = star, rate_up = funcLuaCommand(ORB_PULL, sign, star) == 1 }
end

VRFW.host.wrap_once("IsRarePackStar", "ChronicleDeluxe.universe_stars", function(retail_is_last, sign, star)
  if pull_now ~= nil and pull_now.rate_up and sign == pull_now.sign and star == pull_now.star then
    return true
  end
  return retail_is_last(sign, star)
end)

VRFW.host.wrap_once("SetupRareStarLayer", "ChronicleDeluxe.universe_stars", function(retail_rare_layer, layer, instance)
  retail_rare_layer(layer, instance)
  local sign = SearchSelectedStarSignId(instance)
  if sign ~= nil and sign ~= 0 then
    rare_instance[sign] = instance
  end
end)

-- the last star layer moves onto the rate-up orb when that orb first gets its layer
local function place_rate_up(sign, star)
  local instance = rare_instance[sign]
  if instance == nil or rate_up_placed[sign] then
    return
  end
  local got, drawing = funcLuaMenuCommand(STAR_INFO, 6, sign)
  if not got then
    return
  end
  rate_up_placed[sign] = true
  funcLuaMenuCommand(ATTACH_TARGET, drawing, 0, RARE_ATTACH, VRFW.ids.crc32("_atc_star0" .. star))
  funcLuaMenuCommand(OPEN_LAYER, RARE_LAYER, instance)
  SetStarKeyLayerValid(true, RARE_LAYER, instance)
  log("rate-up orb: sign", sign, "star", star)
end

VRFW.host.wrap_once("SetupStarLayerTexture", "ChronicleDeluxe.universe_stars", function(retail_star_texture, layer, instance, sign, star)
  retail_star_texture(layer, instance, sign, star)
  if orb(sign).pending == star then
    place_rate_up(sign, star)
  end
end)

VRFW.host.wrap_once("RestoreLotteryCharacter", "ChronicleDeluxe.universe_stars", function(retail_restore, ...)
  restoring = true
  local ok, err = pcall(retail_restore, ...)
  restoring = false
  if not ok then
    error(err, 0)
  end
end)

VRFW.host.wrap_once("OnChangeFocus", "ChronicleDeluxe.universe_stars", function(retail_focus, layer, ...)
  retail_focus(layer, ...)
  if layer == STAR_KEY_LAYER then
    ApplyDetailWindowLotteryInfo()
  end
end)

local icons_shown = 0                     -- icon instances the side window holds open
local icons_drawn = nil                   -- icons of the redraw in progress
local icon_logged = 0

VRFW.host.wrap_once("UpdateCharaIcon", "ChronicleDeluxe.universe_stars", function(retail_icon, layer, instance, ...)
  if icons_drawn ~= nil and layer == ICON_LAYER and instance >= icons_drawn then
    icons_drawn = instance + 1
  end
  return retail_icon(layer, instance, ...)
end)

-- the game redraws the open side window without closing the icons past the new count: a shorter list kept the old ones
VRFW.host.wrap_once("UpdateDetailWindow", "ChronicleDeluxe.universe_stars", function(retail_detail, sign, ...)
  if not funcLuaMenuCommand(SIGN_INFO, 0, sign) then
    return retail_detail(sign, ...)
  end
  icons_drawn = 0
  retail_detail(sign, ...)
  local drawn = icons_drawn
  icons_drawn = nil
  for instance = drawn, icons_shown - 1 do
    funcLuaMenuCommand(CLOSE_LAYER, ICON_LAYER, instance)
  end
  if drawn < icons_shown and icon_logged < MAX_ICON_LOG_LINES then
    icon_logged = icon_logged + 1
    log("side window: sign", sign, "icons", drawn, "closed", icons_shown - drawn)
  end
  icons_shown = drawn
end)

VRFW.host.wrap_once("CloseDetailWindow", "ChronicleDeluxe.universe_stars", function(retail_close_detail, ...)
  icons_shown = 0
  return retail_close_detail(...)
end)

VRFW.host.wrap_once("RegisterPropValue", "ChronicleDeluxe.universe_stars", function(retail_register, key, value, ...)
  if key == PROP_LIST_SIGN and value ~= 0 then
    local place = pools()[value]
    local sign, star = value, GetNowSelectStarKeyLayerIndex() + 1
    if place ~= nil then
      sign, star = place.sign, place.star
    else
      if star < 1 then
        star = 1
      end
      local pool = GetOverrideLotteryStarSignId(value, star)
      if pool ~= 0 then
        value = pool
      end
    end
    retail_register(PROP_LIST_LAST_STAR, (IsRarePackStar(sign, star) or draws_last_star(sign, star)) and 1 or 0, ...)
  end
  return retail_register(key, value, ...)
end)

VRFW.host.wrap_once("DeletePropValue", "ChronicleDeluxe.universe_stars", function(retail_delete, key, ...)
  if key == PROP_LIST_SIGN then
    retail_delete(PROP_LIST_LAST_STAR)
  end
  return retail_delete(key, ...)
end)

VRFW.host.wrap_once("GetPropValue", "ChronicleDeluxe.universe_stars", function(retail_prop, key, ...)
  local value = retail_prop(key, ...)
  if key == PROP_SEARCH_RESULT and value ~= nil and value ~= 0 then
    local place = pools()[value]
    if place ~= nil then
      wanted_star = place.star
      return place.sign
    end
  end
  return value
end)

VRFW.host.wrap_once("GetFirstSelectStarKeyIndex", "ChronicleDeluxe.universe_stars", function(retail_first, sign)
  local star = wanted_star
  wanted_star = nil
  if star ~= nil and IsStarKeyValid(sign, star) then
    return star
  end
  return retail_first(sign)
end)

VRFW.host.wrap_once("ApplyStarKeySelectMode", "ChronicleDeluxe.universe_stars", function(retail_select, sign)
  retail_select(sign)
  ApplyDetailWindowLotteryInfo()
end)

VRFW.host.wrap_once("LotteryStarSignCharacter", "ChronicleDeluxe.universe_stars", function(retail_lottery, pool, is_last_star)
  local cards = retail_lottery(pool, is_last_star)
  if logged < MAX_LOG_LINES then
    logged = logged + 1
    local place = pools()[pool]
    log("pull: sign", place and place.sign or 0, "star", place and place.star or 0, "pool", pool, "last star", is_last_star, "cards", #cards)
  end
  return cards
end)

VRFW.host.wrap_once("OpenResultMenu", "ChronicleDeluxe.universe_stars", function(retail_open_result)
  prize_due = true
  return retail_open_result()
end)

local function give_prize(item)
  if funcLuaCommand(HAS_ROOM, item, 1) ~= true then
    return
  end
  funcLuaCommand(ADD_ITEM, item, 1)
  funcLuaCommand(WINDOWS_FREE_ASK)
  while not funcLuaCommand(WINDOWS_FREE) do
    coroutine.yield()
  end
  funcLuaCommand(WINDOW_RUN, funcLuaCommand(WINDOW_MAKE, 11, TEXT_ITEM_GOT, item))
  while funcLuaCommand(WINDOW_RUNNING) do
    coroutine.yield()
  end
end

local function give_pull_prizes()
  local place = pulled
  pulled = nil
  local is_last_star = place ~= nil and place.rate_up == true
  local items = { funcLuaCommand(ROLL_PRIZE, is_last_star and 1 or 0) }
  log("prize roll: sign", place and place.sign or 0, "star", place and place.star or 0, "last star", is_last_star,
      "items", tostring(items[1]), tostring(items[2]))
  for _, item in ipairs(items) do
    if type(item) == "number" and item ~= 0 then
      give_prize(item)
    end
  end
end

VRFW.host.wrap_once("ResumeMenu", "ChronicleDeluxe.universe_stars", function(retail_resume, ...)
  retail_resume(...)
  ApplyDetailWindowLotteryInfo()
  if prize_due then
    prize_due = false
    give_pull_prizes()
  end
end)
