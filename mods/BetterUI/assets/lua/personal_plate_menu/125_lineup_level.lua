BetterUI = type(BetterUI) == "table" and BetterUI or {}
if BetterUI.lineup_level == nil then
  local L = {
    FLAG = 2100506454,                   -- the Battle Bay lineup parameter (crc32 of its key)
    CONTEXT = "battle_bay",              -- the framework context of the Battle Bay's menus
    HEADERS = {1844915256, 607716004},   -- soccer11_04_formation_chara_status, soccer11_04_chara_status
    MESHES = {1034363700 --[[_gtxt_status_lv01]], 4071435007 --[[_icon_lock_lv01]]},
    NODES = {2976428572 --[[_num_status_lv01]], 1469422130 --[[_pos_exp01]]},
    DIGITS = 3434305008,                 -- num_status_lv01, the level digits' number setting
    C = {
      MODE_IS = VRFW.commands.VRFW_MODE_IS,
      LAYER_COUNT = VRFW.commands.GET_CREATE_LAYER_NUM, IS_OPEN = VRFW.commands.IS_OPEN_LAYER,
      MESH = VRFW.commands.SET_MESH_VISIBLE, NODE = 2158717427, PRIM = 1233047821,
    },
    ASK_EVERY = 10,                      -- frames between two looks at the parameter
    frames = nil,
    on = false,
  }
  BetterUI.lineup_level = L

  local Cmd = VRFW.host.menu_command

  function L.lineup()
    if not VRFW.param.has(L.FLAG) then
      return false
    end
    local inside = VRFW.host.command(L.C.MODE_IS, L.CONTEXT)
    return inside == true
  end

  -- the level parts off on every open header plate
  function L.hide()
    for _, layer in ipairs(L.HEADERS) do
      local count = Cmd(L.C.LAYER_COUNT, layer)
      count = type(count) == "number" and count or 1
      for k = 0, count - 1 do
        if Cmd(L.C.IS_OPEN, layer, k) == true then
          for _, mesh in ipairs(L.MESHES) do
            Cmd(L.C.MESH, layer, mesh, false, k)
          end
          for _, node in ipairs(L.NODES) do
            Cmd(L.C.NODE, layer, node, false, k)
          end
          Cmd(L.C.PRIM, layer, k, L.DIGITS, false)
        end
      end
    end
  end

  function L.frame()
    L.frames = (L.frames or L.ASK_EVERY) + 1
    if L.frames >= L.ASK_EVERY then
      L.frames = 0
      L.on = L.lineup()
    end
    if L.on then
      L.hide()
    end
  end

  BetterUI.wrap_global(_ENV, "LineupLevel", "PostStep", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      pcall(L.frame)
      return table.unpack(r, 1, r.n)
    end
  end)

  BetterUI.wrap_global(_ENV, "LineupLevel", "UpdateCharaStatusPlateInfoByCharaStHdl", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      if L.on then
        pcall(L.hide)
      end
      return table.unpack(r, 1, r.n)
    end
  end)
end
