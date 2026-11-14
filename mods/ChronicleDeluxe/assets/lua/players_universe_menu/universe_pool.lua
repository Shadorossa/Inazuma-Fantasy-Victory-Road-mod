local PLAY_SOUND = VRFW.commands.SND_PLAY_SE             -- (sound)
local SOUND_DECIDE = VRFW.ids.crc32("sy0000")
local SOUND_CANCEL = VRFW.ids.crc32("sy0006")
local WINDOW_TEXT = 2289627655            -- (text id, 0, 0, 0, 0, 0, false)
local WINDOW_BUTTONS = 2351835063         -- (buttons, 0)
local WINDOW_SOUNDS = 528596549           -- (decide sound, cancel sound)
local WINDOWS_FREE = 682363669
local TEXT_POOL_EMPTY = VRFW.ids.crc32("ChronicleDeluxe.universe_pool_empty")

local function pool()
  return ChronicleDeluxe.UniversePool
end

VRFW.host.wrap_once("OnInit", "ChronicleDeluxe.universe_pool", function(retail_init, ...)
  pool().forget()
  return retail_init(...)
end)

-- True when the star the cursor is on has no card left to give.
local function selected_star_spent()
  if not pool().active() then
    return false
  end
  local sign = GetSelectedStarSignId()
  if not sign or sign == 0 then
    return false
  end
  local star = GetNowSelectStarKeyLayerIndex() + 1
  if star < 1 then
    star = 1
  end
  local drawn = GetOverrideLotteryStarSignId(sign, star)
  return pool().spent(drawn ~= 0 and drawn or sign)
end

-- Before the confirmation and the payment: a star with nothing left says so and costs nothing.
VRFW.host.wrap_once("StartStarDecided", "ChronicleDeluxe.universe_pool", function(retail_decided)
  if not IsSelectStarKeyValid() or not selected_star_spent() then
    return retail_decided()
  end
  funcLuaCommand(PLAY_SOUND, SOUND_DECIDE)
  HideCursorMesh()
  funcLuaCommand(WINDOW_TEXT, TEXT_POOL_EMPTY, 0, 0, 0, 0, 0, false)
  funcLuaCommand(WINDOW_BUTTONS, 1, 0)
  funcLuaCommand(WINDOW_SOUNDS, SOUND_DECIDE, SOUND_CANCEL)
  waitTrue(function()
    return funcLuaCommand(WINDOWS_FREE)
  end)
  ApplyStarCursorPos()
  ChangeCursorMesh(false)
end)

VRFW.host.wrap_once("LotteryStarSignCharacter", "ChronicleDeluxe.universe_pool", function(lottery_with_repeats, sign, is_last_star)
  if not pool().active() then
    return lottery_with_repeats(sign, is_last_star)
  end
  return pool().draw(sign, is_last_star)
end)
