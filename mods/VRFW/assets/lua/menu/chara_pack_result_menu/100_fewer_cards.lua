-- VRFW > the retail card screen with fewer cards than its 12 places (6 per row): the cursor stays on the cards. Retail
-- reads a card of every place it focuses, so an empty place would raise an error. With 12 cards every call is retail.
-- Wraps the menu's own globals (no host); nothing runs at load time.
do
  local PLACES, PER_ROW = 12, 6
  local CARD_LAYER = 2819584150         -- universe02_03_chara_spirit
  local COUNT_PARAM = 1872993680        -- the parameter store: how many cards
  local GET_FOCUS = 2603265800          -- (layer) -> the focused instance
  local SET_FOCUS = 1778826357          -- (layer, instance, on)
  local WRAP_GUARD = 2620918304         -- (command) -> true = retail does not wrap around a row on that key
  local SOUND = 1917805374              -- (sound)
  local SOUND_MOVE = 2500047763         -- sy0005
  local KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT = 2819907090, 2153103634, 3872241217, 4142155561
  local CMD_LEFT, CMD_RIGHT = 2765147006, 2075023265
  local cards = PLACES

  local init = OnInit
  local focus_changed = OnChangeFocus
  local move_cursor = UpdateSpiritIconMoveCursor

  if type(init) == "function" and type(focus_changed) == "function" and type(move_cursor) == "function" then
    OnInit = function(...)
      local count = VRFW_Param.Get(COUNT_PARAM)
      cards = (type(count) == "number" and count >= 1) and count or PLACES
      return init(...)
    end

    OnChangeFocus = function(layer, ...)
      if layer == CARD_LAYER and cards < PLACES then
        local at = funcLuaMenuCommand(GET_FOCUS, layer)
        if type(at) == "number" and at >= cards then
          funcLuaMenuCommand(SET_FOCUS, layer, cards - 1, true)
          return
        end
      end
      return focus_changed(layer, ...)
    end

    UpdateSpiritIconMoveCursor = function(key)
      if cards >= PLACES then
        return move_cursor(key)
      end
      local at = funcLuaMenuCommand(GET_FOCUS, CARD_LAYER)
      local to = at
      if key == KEY_UP then
        if at >= PER_ROW then
          to = at - PER_ROW
        end
      elseif key == KEY_DOWN then
        if at < PER_ROW and cards > PER_ROW then
          to = math.min(at + PER_ROW, cards - 1)
        end
      elseif key == KEY_LEFT then
        if at % PER_ROW == 0 then
          if funcLuaMenuCommand(WRAP_GUARD, CMD_LEFT) then
            return
          end
          to = math.min(at + PER_ROW - 1, cards - 1)
        else
          to = at - 1
        end
      elseif key == KEY_RIGHT then
        if (at + 1) % PER_ROW == 0 or at == cards - 1 then
          if funcLuaMenuCommand(WRAP_GUARD, CMD_RIGHT) then
            return
          end
          to = at - at % PER_ROW
        else
          to = at + 1
        end
      else
        return
      end
      if to ~= at then
        funcLuaMenuCommand(SET_FOCUS, CARD_LAYER, to, true)
        funcLuaCommand(SOUND, SOUND_MOVE)
      end
    end
  end
end
