-- Players Universe character list: the focused player's 3D model in the free column right of the list.
-- VRFW.model_card draws it in the 3D pass; while it is up the list's background is swapped for its background-pass
-- copy and the menus under the list hide their layers (menu event CharacterReforged.UniverseCover, VRFW.layer_cover).
local LIST_BACKGROUND = VRFW.crc32("universe03_00_bg")
local MODEL_LAYER = VRFW.crc32("character_reforged_universe_list_model")
local BACKDROP_LAYER = VRFW.crc32("character_reforged_universe_list_backdrop")
local COVER_EVENT = "CharacterReforged.UniverseCover"
local CLOSE_WAIT = 60          -- Steps the close waits for a model still being freed

local S = nil
local log = VRFW.logger.new("CharacterReforged.UniverseModel")

-- The menus under the list hide or show their layers with the backdrop swap.
local function Cover(on)
  VRFW.menu_event.emit(COVER_EVENT, on)
end

local function ShowFocused(chara_index)
  local info = GetCharaInfo(chara_index)
  if info ~= nil then
    S.pic.set_want({ card = info[1], team = 0, static = true, fit = true, box = S.box })
  end
end

local retail_init = OnInit
function OnInit(...)
  retail_init(...)
  -- the box on the character card: config.toml [players_universe]
  local x, y, w, h = VRFW.host.command(VRFW.commands.CHARACTERREFORGED_UNIVERSE_MODEL_BOX)
  S = { box = { x = x, y = y, w = w, h = h },
    pic = VRFW.model_card.new({ layer = MODEL_LAYER, backdrop = BACKDROP_LAYER, hide = { LIST_BACKGROUND },
      on_cover = Cover, log = log }) }
end

local retail_move_focus = OnListViewUniverseChara_MoveFocus
function OnListViewUniverseChara_MoveFocus(previous, current, chara_index, ...)
  retail_move_focus(previous, current, chara_index, ...)
  if S ~= nil and S.close_args == nil then
    ShowFocused(chara_index)
  end
end

-- The close runs once the model is freed, as a screen closes after its model is released.
local retail_close = CloseMenu
function CloseMenu(...)
  if S == nil then
    return retail_close(...)
  end
  if S.close_args == nil then
    S.close_args, S.close_wait = table.pack(...), 0
    S.pic.hide()
  end
end

local retail_step = Step
function Step(...)
  retail_step(...)
  if S == nil then
    return
  end
  S.pic.step()
  if S.close_args ~= nil then
    S.close_wait = S.close_wait + 1
    if S.pic.released() or S.close_wait >= CLOSE_WAIT then
      local args = S.close_args
      S.close_args = nil
      retail_close(table.unpack(args, 1, args.n))
    end
  end
end

local retail_finalize = FinalizeMenu
function FinalizeMenu(...)
  if S ~= nil then
    S.pic.hide()
  end
  return retail_finalize(...)
end
