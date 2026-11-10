do
  PassivesSynergies_Board = PassivesSynergies_Board or {}
  local Board = PassivesSynergies_Board
  Board.OWN_PASSIVE = 1144239916
  Board.SIX_SENSE_GRID = 1822684097                  -- team13_05_effect_grid_six_sense
  Board.CATEGORY_SIX_SENSE = 5                       -- the custom passive piece's category (GetEffectPieceInfoFromMenu)
  Board.FOCUS_RING = 2907318182                      -- team13_09_effect_grid_focus_ring
  Board.FOCUS_INDEX = 2603265800                     -- (layer) -> the focused piece
  Board.PIECE_INFO = 4147077179
  Board.DETAIL = 1593383077                          -- team00_26_passive_slot_detail_info
  Board.NAME_NODE = 1704438437
  Board.EFFECT_NODE = 691026122
  Board.TEXT_VISIBLE = 1505208242                    -- (layer, text node, visible, idx)
  Board.PASSIVE_INFO = 1448743477                    -- CMND_GET_PASSIVE_SKILL_INFO (0, id) -> effect
  Board.TEXT_GET = 4074371074                        -- CMND_TEXT_GET (text id)
  Board.SLOT_NAME = 1901464137
  Board.SET_TEXT = 1083631230                        -- CMND_SET_MENU_TEXT_STRING (layer, node, text, idx)
  Board.LAYER_VISIBLE = 711242136                    -- CMND_SET_LAYER_VISIBLE (layer, idx, visible)
  Board.PARAM_CHARA = 4161869490                     -- the player the team dock passes (OnInit reads and clears it)
  Board.SOUND = 1917805374                           -- play a system sound
  Board.SOUND_CANNOT = 2086672038
  Board.chara = nil

  -- the shown player's own passive id (0 = none)
  function Board.own_passive()
    local hdl = Board.chara
    if type(hdl) ~= "number" or hdl == 0 then
      return 0
    end
    local ok, passive = pcall(funcLuaCommand, Board.OWN_PASSIVE, hdl)
    if ok and type(passive) == "number" then
      return passive
    end
    return 0
  end

  -- Returns the name (the window's header) and effect lines (its text).
  function Board.display(passive)
    local display = type(PassivesSynergies_Display) == "table" and PassivesSynergies_Display.of(Board.chara, passive)
    if type(display) == "table" then
      return display
    end
    local ok, text = pcall(funcLuaCommand, Board.TEXT_GET, Board.SLOT_NAME)
    return {name = (ok and type(text) == "string") and text or ""}
  end

  -- Draws the detail window of the custom passive piece.
  function Board.detail()
    local piece = funcLuaMenuCommand(Board.FOCUS_INDEX, Board.FOCUS_RING)
    if type(piece) ~= "number" then
      return
    end
    local category = select(5, funcLuaMenuCommand(Board.PIECE_INFO, piece))
    if category ~= Board.CATEGORY_SIX_SENSE then
      return
    end
    local passive = Board.own_passive()
    if passive == 0 then
      UpdateEmptySixSenseSlotDetailWindow(0)
      return
    end
    local effect = funcLuaCommand(Board.PASSIVE_INFO, 0, passive)
    UpdateSixSenseDetailInfo(0, passive, effect, Board.chara)
    local shown = Board.display(passive)
    funcLuaMenuCommand(Board.SET_TEXT, Board.DETAIL, Board.NAME_NODE, shown.name, 0)
    if shown.effect ~= nil then
      funcLuaMenuCommand(Board.SET_TEXT, Board.DETAIL, Board.EFFECT_NODE, shown.effect, 0)
      funcLuaMenuCommand(Board.TEXT_VISIBLE, Board.DETAIL, Board.EFFECT_NODE, true, 0)
    end
    funcLuaMenuCommand(Board.LAYER_VISIBLE, Board.DETAIL, 0, true)
  end

  VRFW.host.wrap("OnInit", function(previous)
    return function(...)
      Board.chara = nil
      pcall(function()
        if VRFW.param.has(Board.PARAM_CHARA) then
          Board.chara = VRFW.param.get(Board.PARAM_CHARA)
        end
      end)
      return previous(...)
    end
  end)

  -- Handles L and R.
  VRFW.host.wrap("OnChangeTargetChara", function(previous)
    return function(chara, ...)
      Board.chara = chara
      return previous(chara, ...)
    end
  end)

  -- Wraps the piece icon update.
  VRFW.host.wrap("UpdateEffectPieceIcon", function(previous)
    return function(layer, idx, piece, skill, equipped, ...)
      if layer == Board.SIX_SENSE_GRID then
        local ok, passive = pcall(Board.own_passive)
        if ok and passive ~= 0 then
          return previous(layer, idx, piece, passive, true, ...)
        end
        return previous(layer, idx, piece, skill, false, ...)
      end
      return previous(layer, idx, piece, skill, equipped, ...)
    end
  end)

  VRFW.host.wrap("UpdateDetailWindow", function(previous)
    return function(show, a2, a3, title, ...)
      local result = table.pack(previous(show, a2, a3, title, ...))
      if show ~= false and not title then
        pcall(Board.detail)
      end
      return table.unpack(result, 1, result.n)
    end
  end)

  -- The custom passive list (OpenAbilityListMenu's third argument) never opens.
  VRFW.host.wrap("OpenAbilityListMenu", function(previous)
    return function(piece, skill, six_sense, ...)
      if six_sense then
        pcall(funcLuaCommand, Board.SOUND, Board.SOUND_CANNOT)
        return
      end
      return previous(piece, skill, six_sense, ...)
    end
  end)
end
