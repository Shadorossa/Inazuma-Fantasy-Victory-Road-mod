-- Element cell of the skill table (option CharacterReforged.element_cheat): right of «Entrenar», A opens a row of the element icons.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.element_cell == nil and type(rawget(_ENV, "OnInit")) == "function" then
  local E = {
    LAYER = 1221220500,               -- cr_cmn03_07_btn_icon: instance 0 = the cell, 1 = the idol button, 2.. = the row's tiles
    TRAIN = 3123242707,               -- cr_cmn03_07_btn_train («Entrenar», left of the cell)
    TILE_FIRST = 2,                   -- the first instance of the row's tiles
    ICON_FIRST = 12,                  -- soccer11_20_formation_team_passive instance 12 + k draws the icon of instance k
    BUTTON_ROOT = 2946790888,         -- cmn03_07_output (the root joint of a button instance)
    ICON_ROOT = 1668446432,           -- soccer11_20_output (the root joint of an icon instance)
    CELL_DX = -80,                    -- the cell sits one square button (72) and its gap (8) left of the idol button's place
    ROW_DY = 110,                     -- the row of tiles sits above the bottom buttons
    TILE_STEP = 88,                   -- one tile (72) and a gap (16)
    -- «Entrenar»'s joints and their full width and height; the cell takes CELL_DX off their width
    TRAIN_NODES = {
      {1359436915, 324, 72},          -- _cmd_btn_base_on01
      {4263478209, 324, 72},          -- _cmd_btn_base_off01
      {3441742689, 324, 72},          -- _cmd_btn_base01_add
      {625330766, 304, 54},           -- _text_cmd01
      {3240206870, 304, 54},          -- _touch_cmd_btn01
    },
    MESH_ON = 1359436915,             -- _cmd_btn_base_on01 (the lit base of the chosen tile)
    MESH_OFF = 4263478209,            -- _cmd_btn_base_off01
    ICON_PRIORITY = 560,              -- as the icons of the other square buttons
    INFO = 856660639,                 -- CMND_CHARACTERREFORGED_ELEMENT_INFO (charaStHdl) -> on, element, values...
    SET = 34702369,                   -- CMND_CHARACTERREFORGED_ELEMENT_SET (charaStHdl, element) -> ok
    GUIDE = 1824363678,               -- character_reforged_element_guide (text\rows\skill_table.toml)
    NODE_POS = 2575768773,            -- (layer, instance, node, axis 0 x / 1 y, value)
    NODE_SCALE = 2885415772,          -- (layer, instance, node, sx, sy)
    CREATED = 1175615627,             -- CMND_GET_CREATE_LAYER_NUM (layer) -> its instance count
    ENABLE_COMMAND = 2559269762,      -- (layer, command, on)
    FOCUS_COMMANDS = {3407457192, 2734193315, 264576151},   -- CMD_FCS_BACK, CMD_FCS_NEXT, CMD_FCS_MTX_UP
    K_LEFT = 2765147006,              -- CMD_LEFT
    K_RIGHT = 2075023265,             -- CMD_RIGHT
    K_ENTER = 1981080283,             -- CMD_ENTER
    K_CLICK = 1651523701,             -- CMD_ENTER_CLICK
    K_BACK = 3011112225,              -- CMD_BACK
    SE_CURSOR = 2500047763,           -- sy0005
    REAPPLY_FRAMES = 10,              -- the layer open resets mesh visibility: the icons are drawn again after it
    LOG = VRFW.commands.VRFW_LOG,
    ok = nil,                         -- the layers have every instance the cell needs (nil = not checked)
    shown = false,                    -- the cell takes instance 0
    shown_for = false,                -- the cell was laid out for this player
    covered = false,                  -- a screen mode hides the bottom buttons
    element = nil,
    values = {},
    frames = 0,
  }
  CharacterReforged.element_cell = E

  local function log(...)
    pcall(funcLuaCommand, E.LOG, "CharacterReforged element_cell", ...)
  end

  local function screen()
    local host = CharacterReforged.skill_table
    return type(host) == "table" and host.L or nil
  end

  -- Whether the screen created every instance the cell and its row use; logs one WARN when not and the table stays retail.
  function E.check(L)
    if E.ok ~= nil then return E.ok end
    local buttons = funcLuaMenuCommand(E.CREATED, E.LAYER)
    local icons = funcLuaMenuCommand(E.CREATED, L.L_PV_ROW)
    local tiles = type(buttons) == "number" and buttons - E.TILE_FIRST or -1
    E.ok = tiles >= 1 and type(icons) == "number" and icons >= E.ICON_FIRST + E.TILE_FIRST + tiles
    if E.ok then
      E.tiles = tiles
      log("INFO cell built:", buttons, "button instances,", icons, "icon instances")
    else
      log("WARN the skill table has not the element cell's instances (buttons " .. tostring(buttons) .. ", icons "
        .. tostring(icons) .. "): the cell stays off and the table is the retail one")
    end
    return E.ok
  end

  -- Moves button instance k and its icon instance by (dx, dy) from their attach point.
  local function place(L, k, dx, dy)
    funcLuaMenuCommand(E.NODE_POS, E.LAYER, k, E.BUTTON_ROOT, 0, dx)
    funcLuaMenuCommand(E.NODE_POS, E.LAYER, k, E.BUTTON_ROOT, 1, dy)
    funcLuaMenuCommand(E.NODE_POS, L.L_PV_ROW, E.ICON_FIRST + k, E.ICON_ROOT, 0, dx)
    funcLuaMenuCommand(E.NODE_POS, L.L_PV_ROW, E.ICON_FIRST + k, E.ICON_ROOT, 1, dy)
  end

  -- Shows or hides button instance k with its icon of element `element`.
  local function tile(L, k, show, element)
    local sprite = show and VRFW.chara_icons.element_sprite(element) or nil
    if sprite ~= nil then
      pcall(L.ButtonIcon, E.ICON_FIRST + k, L.TEXTURE_ICON_COMMON, sprite)
    end
    funcLuaMenuCommand(L.C.LAYER_VISIBLE, E.LAYER, k, show)
    funcLuaMenuCommand(L.C.LAYER_VISIBLE, L.L_PV_ROW, E.ICON_FIRST + k, show and sprite ~= nil)
  end

  -- Gives «Entrenar» its full width, or the width left of the cell.
  local function train_width(short)
    for _, n in ipairs(E.TRAIN_NODES) do
      funcLuaMenuCommand(E.NODE_SCALE, E.TRAIN, 0, n[1], n[2] + (short and E.CELL_DX or 0), n[3])
    end
  end

  -- Reads the shown player's element and the values it may take; false when the option is off or the player has none.
  local function read(L)
    local answer = table.pack(VRFW.host.command(E.INFO, L.n))
    if answer[1] ~= true or type(answer[2]) ~= "number" then return false end
    E.element = answer[2]
    E.values = {}
    for i = 3, answer.n do
      local v = answer[i]
      if type(v) == "number" and VRFW.chara_icons.element_sprite(v) ~= nil and #E.values < E.tiles then
        E.values[#E.values + 1] = v
      end
    end
    return #E.values > 0
  end

  -- Lays the cell out for the shown player: on, «Entrenar» narrows and the cell shows the element; off, the retail row.
  function E.layout(L)
    local B = CharacterReforged.hero_style_button
    if not E.check(L) then
      E.shown = false
      return
    end
    local show = not E.covered and read(L)
    if show ~= E.shown then
      log("INFO cell", show and "shown" or "hidden", "for", tostring(L.n), "element", tostring(E.element))
    end
    E.shown = show
    train_width(show)
    place(L, 0, show and E.CELL_DX or 0, 0)
    tile(L, 0, show, E.element)
    if not show then
      funcLuaMenuCommand(L.C.LAYER_VISIBLE, E.LAYER, 1, false)
      funcLuaMenuCommand(L.C.LAYER_VISIBLE, L.L_PV_ROW, E.ICON_FIRST + 1, false)
    end
    if type(B) == "table" then
      B.shown_for = false             -- the idol button follows the cell's slot
    end
  end

  -- Marks the tile of position `sel` as the chosen one.
  local function mark(L, sel)
    for k = 0, #E.values - 1 do
      funcLuaMenuCommand(L.C.MESH_VISIBLE, E.LAYER, E.MESH_ON, k == sel, E.TILE_FIRST + k)
      funcLuaMenuCommand(L.C.MESH_VISIBLE, E.LAYER, E.MESH_OFF, k ~= sel, E.TILE_FIRST + k)
    end
  end

  -- Runs in the screen's coroutine: the row of element tiles above the cell, Left / Right to choose, A to take it.
  function E.run()
    local L = screen()
    if L == nil or not E.shown then return end
    local handle, n = L.n, #E.values
    local sel = 0
    for k, v in ipairs(E.values) do
      if v == E.element then sel = k - 1 end
    end
    for _, c in ipairs(E.FOCUS_COMMANDS) do
      funcLuaMenuCommand(E.ENABLE_COMMAND, E.LAYER, c, false)
    end
    for k = 0, n - 1 do
      place(L, E.TILE_FIRST + k, E.CELL_DX + math.floor((k - (n - 1) / 2) * E.TILE_STEP), E.ROW_DY)
      tile(L, E.TILE_FIRST + k, true, E.values[k + 1])
    end
    mark(L, sel)
    log("INFO row opened:", n, "elements, current", tostring(E.element))
    coroutine.yield()                 -- the Aceptar that opened the row must not count
    local picked = nil
    while true do
      coroutine.yield()
      local PL = L.PL
      if PL.key(E.K_BACK) then
        CharacterReforged.skill_table.sound("back")
        break
      elseif PL.key(E.K_ENTER) or PL.key(E.K_CLICK) then
        picked = E.values[sel + 1]
        break
      else
        local left, right = PL.key(E.K_LEFT), PL.key(E.K_RIGHT)
        if left or right then
          sel = (sel + (left and -1 or 1)) % n
          pcall(funcLuaCommand, L.C.SE, E.SE_CURSOR)
          mark(L, sel)
        end
      end
    end
    for k = 0, n - 1 do
      tile(L, E.TILE_FIRST + k, false)
    end
    for _, c in ipairs(E.FOCUS_COMMANDS) do
      funcLuaMenuCommand(E.ENABLE_COMMAND, E.LAYER, c, true)
    end
    coroutine.yield()                 -- the closing input must not reach the screen
    if picked == nil or picked == E.element then
      log("INFO row closed without a change")
      return
    end
    local ok = VRFW.host.command(E.SET, handle, picked)
    log("INFO element set:", tostring(handle), tostring(E.element), "->", picked, "ok", tostring(ok))
    if ok ~= true then
      CharacterReforged.skill_table.sound("refused")
      return
    end
    pcall(VRFW.chara_icons.forget)    -- this menu's cached element icons are read again
    CharacterReforged.skill_table.sound("decide")
    E.shown_for = false
    CharacterReforged.skill_table.refresh()
  end

  local init = OnInit
  function OnInit(...)
    E.ok, E.shown, E.shown_for = nil, false, false
    return init(...)
  end

  local setup_layer = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == L.L_PV_ROW and type(a2) == "number" and a2 > E.ICON_FIRST then
      funcLuaMenuCommand(L.Priority, a1, a2, E.ICON_PRIORITY, true)
      funcLuaMenuCommand(L.C.LAYER_VISIBLE, a1, a2, false)
      E.shown_for = false
      return
    end
    return setup_layer(a1, a2, ...)
  end

  local open_layer = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == L.L_PV_ROW and type(a2) == "number" and a2 > E.ICON_FIRST then
      E.frames = E.REAPPLY_FRAMES
      return
    end
    return open_layer(a1, a2, ...)
  end

  local change_focus = OnChangeFocus
  function OnChangeFocus(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == E.LAYER and a2 == 0 and E.shown then
      L.n14 = L.L_BTN                 -- the rows' arrow cursor leaves the rows, as for the other square buttons
      pcall(UpdateEquipItemInfo)
      pcall(L.PL.guide, L.PL.txt(E.GUIDE))
      return
    end
    return change_focus(a1, a2, ...)
  end

  local decide_focus = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    local L = screen()
    if L ~= nil and a1 == E.LAYER and a2 == 0 and E.shown then
      if L.vrfw_co == nil then
        L.vrfw_co = coroutine.create(E.run)
      end
      return
    end
    return decide_focus(a1, a2, ...)
  end

  local step = Step
  function Step(...)
    local results = table.pack(step(...))
    local L = screen()
    if L ~= nil and L.n ~= nil then
      local B = CharacterReforged.hero_style_button
      local covered = type(B) == "table" and type(B.covers) == "table" and next(B.covers) ~= nil
      if covered ~= E.covered then    -- a screen mode hides or gives back the bottom buttons
        E.covered = covered
        E.shown_for = false
      end
      if E.frames > 0 then
        E.frames = E.frames - 1
        if E.frames == 0 then
          E.shown_for = false
        end
      end
      if E.shown_for ~= L.n and L.vrfw_co == nil then    -- laid out once per shown player
        E.shown_for = L.n
        E.layout(L)
      end
    end
    return table.unpack(results, 1, results.n)
  end
end
