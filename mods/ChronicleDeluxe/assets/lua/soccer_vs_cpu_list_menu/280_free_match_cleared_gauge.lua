ChronicleDeluxe = type(ChronicleDeluxe) == "table" and ChronicleDeluxe or {}
ChronicleDeluxe.cleared_gauge = ChronicleDeluxe.cleared_gauge or {}
do
  local G = ChronicleDeluxe.cleared_gauge
  local ID = "ChronicleDeluxe.ClearedGauge"
  local LAYER = VRFW.ids.crc32("chronicle_deluxe_cleared_gauge")
  local ITEM = VRFW.ids.crc32("mainmenu90_19_vs_cpu_list_item")           -- the list rows' focus layer
  local PILL, CAPSULE, PILL_ORB = VRFW.ids.crc32("_pos_base02"), VRFW.ids.crc32("_pos_base01"), VRFW.ids.crc32("_pos_clear05")
  local PILL_ORB_MESH = VRFW.ids.crc32("_clear_icon05")
  local PILL_ORB_GLOWS = {VRFW.ids.crc32("_clear_icon05_add01"), VRFW.ids.crc32("_clear_icon05_add02")}   -- additive copies, hidden
  local ORB_SLOTS = {VRFW.ids.crc32("clear_icon04"), VRFW.ids.crc32("clear_icon05")}
  local ORB_ATLAS = 2855820778
  local CLASSES = {6, 7, 8, 9}
  local CLEAR = VRFW.commands.GET_SOCCER_GAME_CLEAR_FLAG           -- (game, class)
  local LOG = VRFW.commands.VRFW_LOG
  local CENTRE_X, CENTRE_Y, HEIGHT = 27, -33, 32
  G.logged = nil
  local SCALE, PRIORITY = 1.0, 575
  G.opened = false
  G.ready = false

  local function M(...) return VRFW.host.menu_command(...) end
  local function competition()
    local C = BetterMenu and BetterMenu.competition
    if type(C) ~= "table" or type(C.reserve_under_crest) ~= "function" or type(C.active) ~= "function" then return nil end
    if C.active() ~= true then return nil end
    return C
  end

  local function has_layer()
    local n = M(VRFW.commands.GET_CREATE_LAYER_NUM, LAYER)            -- created instances of the layer
    return type(n) == "number" and n >= 1
  end

  local function hide()
    local C = BetterMenu and BetterMenu.competition
    if type(C) == "table" and type(C.reserve_under_crest) == "function" then C.reserve_under_crest(ID, 0) end
    if has_layer() then M(VRFW.commands.SET_LAYER_VISIBLE, LAYER, 0, false) end
  end

  function G.refresh()
    if not G.ready or not has_layer() then return end
    local C = competition()
    if not C or not VRFW.free_match or type(VRFW.free_match.best) ~= "function" then return hide() end
    local ok, game = M(1666448199, 0)
    if not ok or type(game) ~= "number" or game == 0 then return hide() end
    local okb, best = pcall(VRFW.free_match.best, game)
    if not okb or type(best) ~= "number" then return hide() end
    local sprite = best ~= 0 and VRFW.match_difficulty.class_orb(game, best) or nil   -- the best class's declared Orb on this game; none = the empty pill
    local band = HEIGHT / 2
    local top, x, crest_bottom, glyph = C.reserve_under_crest(ID, band)
    if type(glyph) ~= "number" then glyph = 0 end
    if type(crest_bottom) ~= "number" then crest_bottom = top + glyph end
    local name_top = top + band + glyph
    local centre = (crest_bottom + name_top) / 2
    if not G.opened then
      M(VRFW.commands.OPEN_LAYER, LAYER, 0)
      M(3849595087, LAYER, 2, 0)                -- as the retail list opens its clear-icon instances
      G.opened = true
    end
    M(2158717427, LAYER, CAPSULE, false, 0)
    M(2158717427, LAYER, PILL, true, 0)
    M(2158717427, LAYER, PILL_ORB, sprite ~= nil, 0)
    M(VRFW.commands.SET_MESH_VISIBLE, LAYER, PILL_ORB_MESH, sprite ~= nil, 0)
    for _, mesh in ipairs(PILL_ORB_GLOWS) do M(VRFW.commands.SET_MESH_VISIBLE, LAYER, mesh, false, 0) end
    local swapped = {}
    if sprite ~= nil then
      for k, slot in ipairs(ORB_SLOTS) do swapped[k] = tostring(M(558735651, LAYER, ORB_ATLAS, sprite, slot, 0, 0)) end
    end
    if G.logged ~= game then
      G.logged = game
      local won = {}
      for _, d in ipairs(CLASSES) do won[#won + 1] = d .. "=" .. tostring(funcLuaCommand(CLEAR, game, d)) end
      pcall(funcLuaCommand, LOG, string.format("ChronicleDeluxe cleared gauge: game %s best %s won [%s] orb sprite swap [%s] at y %s",
        tostring(game), tostring(best), table.concat(won, " "), table.concat(swapped, " "), tostring(centre)))
    end    M(VRFW.commands.SET_LAYER_LOCAL_SCALE, LAYER, SCALE, SCALE, 1, 0)
    M(VRFW.commands.SET_LAYER_LOCAL_POS, LAYER, x - CENTRE_X * SCALE, -centre - CENTRE_Y * SCALE, 0, 0)
    M(VRFW.commands.SET_DRAW_PRIORITY, LAYER, 0, PRIORITY, true)
    M(VRFW.commands.SET_LAYER_VISIBLE, LAYER, 0, true)
  end

  BetterMenu = type(BetterMenu) == "table" and BetterMenu or {}
  BetterMenu.competition = BetterMenu.competition or {}
  BetterMenu.competition.strip_listeners = BetterMenu.competition.strip_listeners or {}
  BetterMenu.competition.strip_listeners[ID] = function() G.ready = true G.refresh() end
  if VRFW.host then
    VRFW.host.on("soccer_vs_cpu_list_menu", "OnInit", { id = "ChronicleDeluxe.cleared_gauge.open", phase = "before",
      fn = function() G.opened, G.ready = false, false end })
    VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", { id = "ChronicleDeluxe.cleared_gauge.focus", phase = "after",
      fn = function(r, a1) if a1 == ITEM and G.ready then G.refresh() end end })
  end
end
