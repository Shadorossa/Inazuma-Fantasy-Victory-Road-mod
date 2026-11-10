BetterUI = type(BetterUI) == "table" and BetterUI or {}
if BetterUI.vs_basic_data == nil then
  local V = {
    VIEW_PARAM = 2979464676,
    NAME_LAYER = 98463589,
    COACH_NAME_LAYER = 770171539,       -- better_ui_card_name_leader: on the coach card
    NAME_NODE = 931545948,              -- `_text_list01_on`
    SPARE_NODE = 3705682548,            -- _text_list01_off (unused, kept empty)
    NAME_STYLE = 3839036294,
    NAME_PLATES = {3025401186, 486732393, 1516082254, 3292070381, 376662541, 3232607807, 1712955010},
    CARD_NAME = 170976702,
    BADGES = {3895971012, 32585899, 1721769611, 4283246729, 378264806, 1910176454},
    LARGE = {x = -1.5, y = -33, scale = 0.85},
    SMALL = {x = -1.5, y = -21, scale = 0.58},
    FIRST_SMALL_SLOT = 11,              -- formation slots 11 .. 18 are small cards
    COACH_SLOT = 19,
    NAME_KEYS = {preview = "BetterUI.vs_preview", basic = "BetterUI.vs_basic_data"},
    NAME_KEY_CRCS = {preview = 1307210685, basic = 3674954174},
    PILL = {LAYER = 209828247, TEXT = 1704438437, SIZE = 4156564586, SCALE_GROUP = 2736921100},
    C = {
      TEXT_ID = VRFW.commands.VRFW_TEXT_ID,
      TEXT_GET = VRFW.commands.TEXT_GET,
      FULL_NAMES = 1332416299,          -- the game's name setting: true = full names
      CHARA_INFO = VRFW.commands.GET_CHARA_INFO,  -- (chara, 0 = full name / 10 = short name)
      TEAM_INFO = 2151743654,           -- (team, 8) -> ok, member count
      OPEN = VRFW.commands.OPEN_LAYER, IS_OPEN = VRFW.commands.IS_OPEN_LAYER, LAYER_COUNT = VRFW.commands.GET_CREATE_LAYER_NUM, VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
      POS = VRFW.commands.SET_LAYER_LOCAL_POS, SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,
      TEXT = VRFW.commands.SET_MENU_TEXT_STRING, TEXT_VISIBLE = VRFW.commands.SET_MENU_TEXT_VISIBLE, TEXT_STYLE = 2333948100,
      MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE, IS_MESH_VISIBLE = VRFW.commands.IS_MESH_VISIBLE, NODE_VISIBLE = 2158717427,
      GROUP_INDEX = VRFW.commands.GET_GROUP_INDEX, GROUP_RESET = 541357333, GROUP_RATE = 1595998683,
    },
  }
  BetterUI.vs_basic_data = V

  local Menu, Game = VRFW.host.menu_command, VRFW.host.command

  function V.is_basic()
    return VRFW.param.has(V.VIEW_PARAM)
  end

  function V.set_basic(on)
    VRFW.param.clear(V.VIEW_PARAM)
    if on then
      VRFW.param.set(V.VIEW_PARAM, 1)
    end
  end

  function V.text(which)
    local id = Game(V.C.TEXT_ID, V.NAME_KEYS[which])
    if type(id) ~= "number" or id == 0 then
      id = V.NAME_KEY_CRCS[which]
    end
    local s = Game(V.C.TEXT_GET, id)
    return type(s) == "string" and s or ""
  end

  -- the player's name as the game shows it (its full name / short name setting)
  function V.player_name(chara)
    local field = Game(V.C.FULL_NAMES) == false and 10 or 0
    local a, b = Game(V.C.CHARA_INFO, chara, field)
    local s = type(a) == "string" and a or b
    return type(s) == "string" and s or ""
  end

  -- names the view X switches to, sized as the retail UpdateNicknameButtonText sizes it
  function V.update_pill()
    local P = V.PILL
    local s = V.text(V.is_basic() and "preview" or "basic")
    Menu(V.C.TEXT, P.LAYER, P.TEXT, s)
    local group = Menu(V.C.GROUP_INDEX, P.LAYER, 0, P.SCALE_GROUP)
    if type(group) == "number" then
      Menu(V.C.GROUP_RESET, P.LAYER, P.SIZE, group, 0)
    end
    if type(MENU_DEF) == "table" and type(MENU_DEF.GetMenuTextRectSizeRate) == "function" then
      local ok, rate = pcall(MENU_DEF.GetMenuTextRectSizeRate, P.LAYER, P.TEXT, s, 64, 400)
      if ok and type(rate) == "number" then
        Menu(V.C.GROUP_RATE, P.LAYER, P.SIZE, 0, rate, 0, true, P.SCALE_GROUP)
      end
    end
  end

  local function Key(layer, idx)
    return tostring(layer) .. ":" .. tostring(idx or 0)
  end

  V.hidden = V.hidden or {}

  local function HideBadges(layer, idx)
    local list = {}
    for _, mesh in ipairs(V.BADGES) do
      if Menu(V.C.IS_MESH_VISIBLE, layer, mesh, idx) ~= false then
        Menu(V.C.MESH_VISIBLE, layer, mesh, false, idx)
        list[#list + 1] = mesh
      end
    end
    V.hidden[Key(layer, idx)] = {layer = layer, idx = idx, meshes = list}
  end

  local function ShowBadges()
    for key, e in pairs(V.hidden) do
      for _, mesh in ipairs(e.meshes) do
        Menu(V.C.MESH_VISIBLE, e.layer, mesh, true, e.idx)
      end
      V.hidden[key] = nil
    end
  end

  local function DressCard(layer, idx, coach)
    if type(BetterUI.player_card_hide_name) == "function" then
      BetterUI.player_card_hide_name(funcLuaMenuCommand, layer, idx)
    else
      Menu(V.C.TEXT_VISIBLE, layer, V.CARD_NAME, false, idx)
      Menu(V.C.NODE_VISIBLE, layer, V.CARD_NAME, false, idx)
    end
    if coach then
      if type(BetterUI.player_card_hide_level) == "function" then
        BetterUI.player_card_hide_level(layer, idx)
      end
    elseif type(BetterUI.player_cards) == "table" and type(BetterUI.player_cards.hide) == "table" then
      BetterUI.player_cards.hide[Key(layer, idx)] = nil
    end
    HideBadges(layer, idx)
  end

  local function HideNames(layer)
    local count = Menu(V.C.LAYER_COUNT, layer)
    for k = 0, (type(count) == "number" and count or 0) - 1 do
      if Menu(V.C.IS_OPEN, layer, k) == true then
        Menu(V.C.VISIBLE, layer, k, false)
      end
    end
  end

  local function ShowName(layer, idx, name, place)
    if Menu(V.C.IS_OPEN, layer, idx) ~= true then
      Menu(V.C.OPEN, layer, idx)
      for _, mesh in ipairs(V.NAME_PLATES) do
        Menu(V.C.MESH_VISIBLE, layer, mesh, false, idx)
      end
      Menu(V.C.TEXT_STYLE, layer, idx, V.NAME_NODE, V.NAME_STYLE)
      Menu(V.C.TEXT, layer, V.SPARE_NODE, "", idx)
      Menu(V.C.TEXT_VISIBLE, layer, V.SPARE_NODE, false, idx)
    end
    Menu(V.C.SCALE, layer, place.scale, place.scale, 1, idx)
    Menu(V.C.POS, layer, place.x, place.y, 0, idx)
    Menu(V.C.TEXT, layer, V.NAME_NODE, name, idx)
    Menu(V.C.TEXT_VISIBLE, layer, V.NAME_NODE, true, idx)
    Menu(V.C.VISIBLE, layer, idx, true)
  end

  -- "Basic data" on the cards the retail SetFormation(team, a2, a3, base, cards, blanks, coachCard, ...) just drew
  function V.apply_basic(a)
    local team, a2, a3, cards, coachCard = a[1], a[2], a[3], a[5], a[7]
    HideNames(V.NAME_LAYER)
    HideNames(V.COACH_NAME_LAYER)
    if type(team) ~= "number" or team == 0 or type(GetTeamMemberInfo) ~= "function" then
      return
    end
    local ok, count = Game(V.C.TEAM_INFO, team, 8)
    if not ok or type(count) ~= "number" then
      return
    end
    for k = 0, count - 1 do
      local got, chara, slot = GetTeamMemberInfo(team, k, a2, a3, true)
      if got and type(chara) == "number" and chara ~= 0 and type(slot) == "number" then
        local name = V.player_name(chara)
        if slot == V.COACH_SLOT and type(coachCard) == "number" then
          DressCard(coachCard, 0, true)
          if name ~= "" then
            ShowName(V.COACH_NAME_LAYER, 0, name, V.LARGE)
          end
        elseif slot >= 0 and slot < V.COACH_SLOT and type(cards) == "number" then
          DressCard(cards, slot, false)
          if name ~= "" then
            ShowName(V.NAME_LAYER, slot, name, slot >= V.FIRST_SMALL_SLOT and V.SMALL or V.LARGE)
          end
        end
      end
    end
  end

  function V.apply_preview()
    HideNames(V.NAME_LAYER)
    HideNames(V.COACH_NAME_LAYER)
    ShowBadges()
  end

  -- around handler of SetFormation.
  function V.draw(nxt, ...)
    V.last = table.pack(...)
    if not V.is_basic() then
      local r = table.pack(nxt(...))
      pcall(V.apply_preview)
      return table.unpack(r, 1, r.n)
    end
    local flags = type(BetterUI.flags) == "table" and BetterUI.flags or nil
    local was = flags and flags.compact_cards
    if flags then
      flags.compact_cards = false
    end
    local r = table.pack(pcall(nxt, ...))
    if flags then
      flags.compact_cards = was
    end
    if not r[1] then
      error(r[2], 0)
    end
    pcall(V.apply_basic, V.last)
    return table.unpack(r, 2, r.n)
  end

  -- the same half drawn again (after X)
  function V.redraw()
    local a = V.last
    if a ~= nil and type(SetFormation) == "function" then
      SetFormation(table.unpack(a, 1, a.n))
    end
  end
end
