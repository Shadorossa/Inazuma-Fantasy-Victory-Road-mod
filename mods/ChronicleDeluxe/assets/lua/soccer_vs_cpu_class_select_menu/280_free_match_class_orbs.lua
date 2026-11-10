do
  local setup = OnSetupLayer
  local CARD = 1809045795           -- vsroute01_21_sub_list: the class cards
  local CARD_ATLAS = 3795985350     -- #/menu/30_vsroute/vsroute01/vsroute01_21/vsroute01_21.g4tx
  local TICK_SLOT = 2107860330      -- list_icon_state_comp01
  local TICK_MESH = 3583161402      -- _list_icon_state_comp01
  local SET_SPRITE = 558735651      -- (layer, atlas, sprite, slot, 0, item)
  local SET_MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE
  local function show_orb(a1, a2)
    local classes = VRFW.free_match_classes and VRFW.free_match_classes.cache   -- the classes the opponent offers, read by this row's setup
    if type(classes) ~= "table" or type(a2) ~= "number" then return end
    local orb = VRFW.match_difficulty.class_orb(VRFW.free_match_classes.game, classes[a2 + 1])   -- the class's declared Orb on this game
    if orb == nil then return end
    funcLuaMenuCommand(SET_SPRITE, a1, CARD_ATLAS, orb, TICK_SLOT, 0, a2)
    funcLuaMenuCommand(SET_MESH_VISIBLE, a1, TICK_MESH, true, a2)
  end
  if type(setup) == "function" then
    function OnSetupLayer(a1, a2, ...)
      local r = table.pack(setup(a1, a2, ...))
      if a1 == CARD then pcall(show_orb, a1, a2) end
      return table.unpack(r, 1, r.n)
    end
  end
end
