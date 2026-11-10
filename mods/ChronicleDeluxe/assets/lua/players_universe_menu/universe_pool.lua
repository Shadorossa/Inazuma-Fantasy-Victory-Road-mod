local PLAY_SOUND = 1917805374             -- (sound)
local SOUND_DECIDE = 3848881948           -- sy0000
local SOUND_CANCEL = 202039849            -- sy0006
local SOUND_REFUSED = 2086672038          -- sy0003
local WINDOW_TEXT = 2289627655            -- (text id, 0, 0, 0, 0, 0, false)
local WINDOW_BUTTONS = 2351835063         -- (buttons, 0)
local WINDOW_SOUNDS = 528596549           -- (decide sound, cancel sound)
local WINDOWS_FREE = 682363669
local TEXT_POOL_EMPTY = 612388116         -- ChronicleDeluxe.universe_pool_empty

local shown_held = {}                     -- card -> held, for the detail window; a pull clears it

local function pool()
  return ChronicleDeluxe.UniversePool
end

local retail_init = OnInit
function OnInit(...)
  pool().forget()
  return retail_init(...)
end

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
local retail_decided = StartStarDecided
function StartStarDecided()
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
end

local retail_open_list = OpenCharaListMenu
function OpenCharaListMenu(...)
  if selected_star_spent() then
    funcLuaCommand(PLAY_SOUND, SOUND_REFUSED)
    return
  end
  return retail_open_list(...)
end

local lottery_with_repeats = LotteryStarSignCharacter
function LotteryStarSignCharacter(sign, is_last_star)
  if not pool().active() then
    return lottery_with_repeats(sign, is_last_star)
  end
  shown_held = {}
  return pool().draw(sign, is_last_star)
end

local retail_characters = GetStarSignCharacters
function GetStarSignCharacters(...)
  local rows = retail_characters(...)
  if rows == nil or not pool().active() then
    return rows
  end
  local left = {}
  for _, row in ipairs(rows) do
    if not pool().held(row[1], shown_held) then
      left[#left + 1] = row
    end
  end
  return left
end
