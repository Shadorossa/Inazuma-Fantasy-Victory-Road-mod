-- Internal: VRFW: the score card of the champions' celebration (docs/framework/trophy.md).
VRFW.trophy_board = VRFW.trophy_board or {}
do
  local BOARD = {
    IMAGE = 3189473175,                -- soccer21_01_half_time_image
    RANK_MESHES = { 364170841, 2361237475 },   -- _icon_rank_dmy01, _icon_rank_dmy02
    PLATES = {
      [2781487712] = true,             -- soccer00_40_username
      [2280287248] = true,             -- soccer00_43_user_title
    },
    IS_ONLINE = 3959907440,            -- retail check of these layers, online match
    IS_OBSERVER = 1191545622,          -- retail check of these layers, observed match
  }

  local function celebration_offline()
    local info = VRFW.host.command(VRFW.commands.VRFW_TROPHY_INFO)
    if type(info) ~= "table" or info.active ~= true then return false end
    return not funcLuaCommand(BOARD.IS_ONLINE) and not funcLuaCommand(BOARD.IS_OBSERVER)
  end

  local function hide_unfilled(layer, index)
    if not celebration_offline() then return end
    if BOARD.PLATES[layer] then
      funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, layer, index, false)
    else
      for _, mesh in ipairs(BOARD.RANK_MESHES) do
        funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, layer, mesh, false)
      end
    end
  end

  local previous = OnOpenLayer
  if type(previous) == "function" and type(SetupEmblemIconFromResultView) == "function"
    and previous ~= VRFW.trophy_board.open then
    --- Internal: Retail wrap: hides the unfilled plates of a trophy board; answers the previous results.
    VRFW.trophy_board.open = function(layer, index, ...)
      local results = table.pack(previous(layer, index, ...))
      if layer == BOARD.IMAGE or BOARD.PLATES[layer] then
        pcall(hide_unfilled, layer, index)
      end
      return table.unpack(results, 1, results.n)
    end
    OnOpenLayer = VRFW.trophy_board.open
  end
end
