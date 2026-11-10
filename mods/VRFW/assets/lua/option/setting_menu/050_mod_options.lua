
VRFW.mod_options = VRFW.mod_options or {}
VRFW.mod_settings = VRFW.mod_settings or {}
local mod_options_legacy_rows, mod_options_legacy_order = VRFW.mod_settings.ROWS, VRFW.mod_settings.ORDER

VRFW.mod_options.VERSION = 1
VRFW.mod_settings.ROWS = {}
VRFW.mod_settings.ORDER = {}                     -- row ids in registration order
VRFW.mod_settings.DRAFT = {}                     -- row id -> pending value while the menu is open
VRFW.mod_settings.LABELS = {}                    -- list cell -> label text (UpdateListItem)
VRFW.mod_settings.LAST_OK = true
VRFW.mod_options.CELLS = {}
VRFW.mod_options.LABEL_KEYS = {}                -- label text -> row key (declared rows)
VRFW.mod_options.LABEL_DUP = {}
VRFW.mod_options.LOADED = false                 -- declared rows fetched from the plugin
VRFW.mod_options.GATED = {}
VRFW.mod_options.FIXED = {}
VRFW.mod_options.PARENT = {}
VRFW.mod_options.HAS_CHILD = {}                 -- row key -> true: some row names it as its parent
VRFW.mod_options.TAB_IDX = nil                  -- strip index of the mod tab for this opening (false = no tab)
VRFW.mod_options.COMMANDS = {
  TAB = VRFW.commands.VRFW_OPTION_TAB, VIEW = 2795212795, CELL = VRFW.commands.VRFW_OPTION_CELL, ROWS = VRFW.commands.VRFW_OPTION_ROWS, ROW = VRFW.commands.VRFW_OPTION_ROW,
  GET = VRFW.commands.VRFW_OPTION_GET, SET = VRFW.commands.VRFW_OPTION_SET, STEP = VRFW.commands.VRFW_OPTION_STEP, TEXT = VRFW.commands.VRFW_OPTION_TEXT
}
VRFW.mod_options.TITLE_ID = 2653374959
VRFW.mod_options.UNAVAILABLE_ID = 516770612
VRFW.mod_options.ICON = 13
VRFW.mod_options.PREVIEW = {handle = 0, key = nil, paused = false, frame = 0, key_down = false, input = true}
VRFW.mod_options.PREVIEW_HAS = {}                    -- row key -> true / false: some value of the row has a preview
VRFW.mod_options.PREVIEW_COMMANDS = {
  PREVIEW = VRFW.commands.VRFW_OPTION_PREVIEW,
  LANG = VRFW.commands.GET_LANGUAGE_CODE,                    -- CMND_GET_LANGUAGE_CODE (retail)
  SND_PLAY = VRFW.commands.SND_PLAY, SND_STOP = VRFW.commands.SND_STOP, SND_PLAYING = 1372088528,
  BGM_PAUSE = VRFW.commands.BGM_PAUSE, BGM_RESUME = VRFW.commands.BGM_RESUME,
  CHECK_INPUT = VRFW.commands.CHECK_INPUT_CMD, MENU_CTRL = 1332654303,
  KEY = 3170216173,                    -- CMD_FUNC2: pad Select / View / touch pad, keyboard Tab
  CLICK = 1651523701,                  -- CMD_ENTER_CLICK (left mouse button, but also Enter / A)
  LEFT = 749879980,
  ENTER = 1981080283,                  -- CMD_ENTER (Enter / A, never the mouse)
  POINTER = 558229292,                 -- funcLuaMenuCommand () -> mouse x, y
  MESH_POS = VRFW.commands.GET_MESH_GLOBAL_POSITION,                -- CMND_GET_MESH_GLOBAL_POSITION(layer, idx, node) -> x, y, z
  PLAY_MARK = "  ▶", STOP_MARK = "  ■"     -- UTF-8 literals (Lua 5.2 has no \u escape)
}

function VRFW.mod_options.text(id, fallback)    -- menu_text row in the game's language, else the fallback
  if type(id) == "number" and id ~= 0 then
    local s = VRFW.host.command(VRFW.commands.TEXT_GET, id)
    if type(s) == "string" and s ~= "" then
      return s
    end
  end
  return fallback
end
function VRFW.mod_options.register(key, row)
  if VRFW.mod_settings.ROWS[key] == nil then
    VRFW.mod_settings.ORDER[#VRFW.mod_settings.ORDER + 1] = key
  end
  VRFW.mod_settings.ROWS[key] = row
end
function VRFW.mod_settings.register(label, row)
  VRFW.mod_options.register(label, row)
end
function VRFW.mod_options.declared(key, storage, get_cmd, set_cmd) -- a toggle / list / number row of an options.toml
  local row = {}
  function row.get()
    if storage == "command" then
      local v, extra = VRFW.host.command(get_cmd)
      if type(v) == "number" then
        return v
      end
      if type(v) == "boolean" and (v or extra ~= nil) then -- a lone false = module off
        if v then
          return 1
        end
        return 0
      end
      return nil
    end
    local v, dv = VRFW.host.command(VRFW.mod_options.COMMANDS.GET, key, "stored") -- the stored value whatever a parent says (greyed here)
    row.dimmed = nil
    if type(v) == "number" then
      return v
    end
    if v == false and type(dv) == "number" then -- enabled_if not met: its value, greyed, no changes
      row.dimmed = dv
    end
    return nil
  end
  function row.step(v, dir)
    local n = VRFW.host.command(VRFW.mod_options.COMMANDS.STEP, key, v, dir)
    if type(n) == "number" then
      return n
    end
    return v
  end
  function row.fmt(v)
    local id, fb = VRFW.host.command(VRFW.mod_options.COMMANDS.TEXT, key, v)
    if type(id) ~= "number" then
      return tostring(v)
    end
    return VRFW.mod_options.text(id, fb)
  end
  function row.set(v)
    if storage == "command" then
      return VRFW.host.command(set_cmd, v) == true
    end
    return VRFW.host.command(VRFW.mod_options.COMMANDS.SET, key, v) == true
  end
  return row
end
function VRFW.mod_options.load()                -- the declared rows (once, from the plugin; inside a callback)
  if VRFW.mod_options.LOADED then
    return
  end
  local n = VRFW.host.command(VRFW.mod_options.COMMANDS.ROWS)
  if type(n) ~= "number" then
    return
  end
  VRFW.mod_options.LOADED = true
  for i = 1, n do
    local key, kind, storage, label, fallback, get_cmd, set_cmd, gated, fixed, parent = VRFW.host.command(VRFW.mod_options.COMMANDS.ROW, i)
    if type(key) == "string" then
      if type(parent) == "string" and parent ~= "" then
        VRFW.mod_options.PARENT[key] = parent
        VRFW.mod_options.HAS_CHILD[parent] = true
      end
      if gated == true then
        VRFW.mod_options.GATED[key] = true
      end
      if type(fixed) == "number" then
        VRFW.mod_options.FIXED[key] = fixed
      end
      local text = VRFW.mod_options.text(label, fallback)
      if type(text) == "string" and text ~= "" then
        if VRFW.mod_options.LABEL_KEYS[text] ~= nil and VRFW.mod_options.LABEL_KEYS[text] ~= key then
          VRFW.mod_options.LABEL_DUP[text] = true
        end
        VRFW.mod_options.LABEL_KEYS[text] = key
      end
      if kind ~= "lua" and VRFW.mod_settings.ROWS[key] == nil then
        VRFW.mod_options.register(key, VRFW.mod_options.declared(key, storage, get_cmd, set_cmd))
      end
    end
  end
end
function VRFW.mod_options.key_of_label(label)
  if type(label) ~= "string" then
    return nil
  end
  VRFW.mod_options.load()
  if VRFW.mod_options.LABEL_DUP[label] then
    return nil
  end
  return VRFW.mod_options.LABEL_KEYS[label]
end
function VRFW.mod_options.tab()
  if VRFW.mod_options.TAB_IDX == nil then
    local n = 4
    local p = VRFW.host.command(VRFW.commands.GET_APP_PLATFORM)
    if p == 1 then              -- the retail strip hides the graphics tab there
      n = 3
    end
    if VRFW.host.command(VRFW.mod_options.COMMANDS.TAB, n) == true then
      VRFW.mod_options.TAB_IDX = n
    else
      VRFW.mod_options.TAB_IDX = false
    end
  end
  return VRFW.mod_options.TAB_IDX
end
function VRFW.mod_options.in_view()              -- the mod tab is the one shown
  return VRFW.host.command(VRFW.mod_options.COMMANDS.VIEW) == true
end
function VRFW.mod_settings.label(a1)
  local key = VRFW.mod_options.CELLS[a1]
  if key ~= nil and VRFW.mod_settings.ROWS[key] ~= nil then
    return key
  end
  local label = VRFW.mod_settings.LABELS[a1]
  if label == nil then
    return nil
  end
  if VRFW.mod_settings.ROWS[label] ~= nil then
    return label
  end
  VRFW.mod_options.load()
  if key ~= nil and VRFW.mod_settings.ROWS[key] ~= nil then
    return key
  end
  local k = VRFW.mod_options.LABEL_KEYS[label]
  if k ~= nil and VRFW.mod_settings.ROWS[k] ~= nil and (key == nil or key == k) then
    return k
  end
  return nil
end
function VRFW.mod_settings.focused()             -- row id under the list cursor (or nil), cell index
  local idx = VRFW.host.menu_command(1727549139, 2081113831)
  if type(idx) ~= "number" then
    return nil, nil
  end
  return VRFW.mod_settings.label(idx), idx
end
function VRFW.mod_options.is_mod_cell(a1)         -- a cell of the mod tab (driven or not)
  return VRFW.mod_options.CELLS[a1] ~= nil
end
function VRFW.mod_options.parent_off(id)         -- a child row whose parent's value (draft, else stored) is 0
  local p = VRFW.mod_options.PARENT[id]
  if p == nil or VRFW.mod_settings.ROWS[p] == nil then
    return false
  end
  local v = VRFW.mod_options.current(p)
  return type(v) == "number" and v == 0
end
function VRFW.mod_settings.text(id)
  local row = VRFW.mod_settings.ROWS[id]
  VRFW.mod_options.load()
  if VRFW.mod_options.FIXED[id] ~= nil then     -- disabled by its content gate: its off value, greyed
    VRFW.mod_settings.DRAFT[id] = nil
    return row.fmt(VRFW.mod_options.FIXED[id]), true
  end
  local cur = row.get()
  if cur ~= nil and VRFW.mod_options.parent_off(id) then
    local v = VRFW.mod_settings.DRAFT[id]
    if v == nil then
      v = cur
    end
    return row.fmt(v), true
  end
  if cur == nil then
    if row.dimmed ~= nil then
      return row.fmt(row.dimmed), true
    end
    if row.off ~= nil then
      return row.off()
    end
    return VRFW.mod_options.text(VRFW.mod_options.UNAVAILABLE_ID, "-")
  end
  local v = VRFW.mod_settings.DRAFT[id]
  if v == nil then
    v = cur
  end
  return row.fmt(v)
end
function VRFW.mod_settings.toggle(id, dir)
  local row = VRFW.mod_settings.ROWS[id]
  VRFW.mod_options.load()
  if VRFW.mod_options.FIXED[id] ~= nil then     -- disabled: never changes
    return false
  end
  if VRFW.mod_options.parent_off(id) then         -- Its parent is off: no changes until the parent is on.
    return false
  end
  local cur = row.get()
  if cur == nil then
    return false
  end
  local v = VRFW.mod_settings.DRAFT[id]
  if v == nil then
    v = cur
  end
  local new = row.step(v, dir)
  if new ~= v and VRFW.mod_options.PREVIEW.key == id then -- the previewed value changed: its preview stops
    VRFW.mod_options.preview_stop("value")
  end
  if new == cur then
    VRFW.mod_settings.DRAFT[id] = nil
  else
    VRFW.mod_settings.DRAFT[id] = new
  end
  return true
end
function VRFW.mod_settings.dirty()               -- a draft differs from its stored value
  for _, id in ipairs(VRFW.mod_settings.ORDER) do
    local v = VRFW.mod_settings.DRAFT[id]
    if v ~= nil then
      local cur = VRFW.mod_settings.ROWS[id].get()
      if cur ~= nil and cur ~= v then
        return true
      end
    end
  end
  return false
end
function VRFW.mod_settings.commit()
  for _, id in ipairs(VRFW.mod_settings.ORDER) do
    local v = VRFW.mod_settings.DRAFT[id]
    if v ~= nil then
      pcall(VRFW.mod_settings.ROWS[id].set, v)
    end
  end
  VRFW.mod_settings.DRAFT = {}
end
function VRFW.mod_options.show_text(a1, s, a3, a4)
  funcLuaMenuCommand(2158717427, 3344436024, 644932521, false, a1)
  funcLuaMenuCommand(2158717427, 3344436024, 1948393973, false, a1)
  funcLuaMenuCommand(2158717427, 3344436024, 64821773, false, a1)
  funcLuaMenuCommand(2158717427, 3344436024, 4203144987 --[[_pos_arrow01]], true, a1)
  funcLuaMenuCommand(3404096044, 3344436024, a1, 2475420648, true)
  funcLuaMenuCommand(3404096044, 3344436024, a1, 2234738066, true)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 569341911, s, a1)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 2795244008, s, a1)
  if a3 then
    funcLuaMenuCommand(VRFW.commands.PLAY_ANIME_TYPE, 3344436024, a1, 1203080170, 0, 3627544126)
  elseif a4 then
    funcLuaMenuCommand(VRFW.commands.PLAY_ANIME_TYPE, 3344436024, a1, 3183130249, 0, 3627544126)
  end
  funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, 3344436024, 2475420648, true, a1)
  funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, 3344436024, 2234738066, true, a1)
end
function VRFW.mod_options.dim(a1, alpha)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_MODEL_ALPHA, 3344436024, a1, 0, alpha)
  for _, t in ipairs({861591609, 3778835256, 569341911, 2795244008, 75769867, 702348360}) do
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_ALPHA, 3344436024, a1, t, alpha)
  end
end
function VRFW.mod_options.child_look(a1, label)
  funcLuaMenuCommand(2158717427, 3344436024, 2894095071 --[[_pos_summary01]], false, a1)
  funcLuaMenuCommand(2158717427, 3344436024, 898184037 --[[_pos_summary02]], true, a1)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 861591609 --[[`_text_option_list01_on`]], "", a1)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 3778835256 --[[_text_option_list01_off]], "", a1)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 75769867 --[[`_text_option_list04_on`]], label, a1)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 702348360 --[[_text_option_list04_off]], label, a1)
end
function VRFW.mod_options.is_child(id)           -- a child row whose parent is on the tab
  local p = VRFW.mod_options.PARENT[id]
  return p ~= nil and VRFW.mod_settings.ROWS[p] ~= nil
end
function VRFW.mod_settings.show(a1, id, a3, a4)
  local s, dim = VRFW.mod_settings.text(id)
  VRFW.mod_options.show_text(a1, s, a3, a4)
  local child = VRFW.mod_options.is_child(id)
  if child and type(VRFW.mod_settings.LABELS[a1]) == "string" then
    VRFW.mod_options.child_look(a1, VRFW.mod_settings.LABELS[a1])
  end
  pcall(VRFW.mod_options.mark, a1, id)
  if VRFW.mod_options.GATED[id] or child then
    if dim then
      VRFW.mod_options.dim(a1, 0.5)
    else
      VRFW.mod_options.dim(a1, 1)
    end
  end
  if VRFW.mod_options.HAS_CHILD[id] then         -- a parent: its children follow its (draft) value
    VRFW.mod_options.refresh_children(id)
  end
end
function VRFW.mod_options.refresh_children(parent) -- redraw the cells showing a child of `parent`
  for cell, _ in pairs(VRFW.mod_settings.LABELS) do
    local ok, k = pcall(VRFW.mod_settings.label, cell)
    if ok and k ~= nil and k ~= parent and VRFW.mod_options.PARENT[k] == parent then
      pcall(VRFW.mod_settings.show, cell, k, false, false)
    end
  end
end
function VRFW.mod_options.refresh_gated()
  if next(VRFW.mod_options.GATED) == nil then
    return
  end
  for cell, label in pairs(VRFW.mod_settings.LABELS) do
    local k = VRFW.mod_options.LABEL_KEYS[label]
    if k ~= nil and VRFW.mod_options.GATED[k] and VRFW.mod_settings.ROWS[k] ~= nil then
      pcall(VRFW.mod_settings.show, cell, k, false, false)
    end
  end
end

function VRFW.mod_options.lang()
  local l = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.LANG)
  if type(l) == "number" then
    return l
  end
  return nil
end
function VRFW.mod_options.has_preview(key)
  local h = VRFW.mod_options.PREVIEW_HAS[key]
  if h == nil then
    h = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.PREVIEW, key) == true
    VRFW.mod_options.PREVIEW_HAS[key] = h
  end
  return h
end
function VRFW.mod_options.current(key)
  local row = VRFW.mod_settings.ROWS[key]
  if row == nil then
    return nil
  end
  local v = VRFW.mod_settings.DRAFT[key]
  if v == nil then
    local ok, cur = pcall(row.get)
    if ok then
      v = cur
    end
  end
  return v
end
function VRFW.mod_options.preview_id(key)
  if type(key) ~= "string" or not VRFW.mod_options.has_preview(key) then
    return nil
  end
  local v = VRFW.mod_options.current(key)
  if type(v) ~= "number" then
    return nil
  end
  local id = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.PREVIEW, key, v, VRFW.mod_options.lang())
  if type(id) == "number" and id ~= 0 then
    return id
  end
  return nil
end
function VRFW.mod_options.mark(a1, key)
  local label = VRFW.mod_settings.LABELS[a1]
  if type(label) ~= "string" or type(key) ~= "string" or not VRFW.mod_options.has_preview(key) then
    return
  end
  local s = label
  if VRFW.mod_options.PREVIEW.handle ~= 0 and VRFW.mod_options.PREVIEW.key == key then
    s = label .. VRFW.mod_options.PREVIEW_COMMANDS.STOP_MARK
  elseif VRFW.mod_options.preview_id(key) ~= nil then
    s = label .. VRFW.mod_options.PREVIEW_COMMANDS.PLAY_MARK
  end
  if VRFW.mod_options.is_child(key) then           -- a child row: its label is list04
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 75769867 --[[`_text_option_list04_on`]], s, a1)
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 702348360 --[[_text_option_list04_off]], s, a1)
    return
  end
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 861591609 --[[`_text_option_list01_on`]], s, a1)
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 3344436024, 3778835256 --[[_text_option_list01_off]], s, a1)
end
function VRFW.mod_options.remark(key)           -- redraw the mark of the cells showing row `key`
  for cell, _ in pairs(VRFW.mod_settings.LABELS) do
    local ok, k = pcall(VRFW.mod_settings.label, cell)
    if ok and k == key then
      pcall(VRFW.mod_options.mark, cell, key)
    end
  end
end
function VRFW.mod_options.preview_stop(why)      -- stop the preview; the menu's own music comes back
  local key = VRFW.mod_options.PREVIEW.key
  if VRFW.mod_options.PREVIEW.handle ~= 0 then
    VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.SND_STOP, VRFW.mod_options.PREVIEW.handle)
  end
  VRFW.mod_options.PREVIEW.handle = 0
  VRFW.mod_options.PREVIEW.key = nil
  if VRFW.mod_options.PREVIEW.paused then
    VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.BGM_RESUME)
    VRFW.mod_options.PREVIEW.paused = false
  end
  if key ~= nil then
    VRFW.mod_options.remark(key)
  end
end
function VRFW.mod_options.preview_play(key)
  if VRFW.mod_options.PREVIEW.handle ~= 0 and VRFW.mod_options.PREVIEW.key == key then
    VRFW.mod_options.preview_stop("again")
    return true
  end
  local id = VRFW.mod_options.preview_id(key)
  if id == nil then
    return false
  end
  local old = VRFW.mod_options.PREVIEW.key
  if VRFW.mod_options.PREVIEW.handle ~= 0 then        -- another row's preview: it stops, the menu music stays paused
    VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.SND_STOP, VRFW.mod_options.PREVIEW.handle)
    VRFW.mod_options.PREVIEW.handle = 0
    VRFW.mod_options.PREVIEW.key = nil
    if old ~= nil then
      VRFW.mod_options.remark(old)
    end
  end
  if not VRFW.mod_options.PREVIEW.paused then
    VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.BGM_PAUSE)
    VRFW.mod_options.PREVIEW.paused = true
  end
  local h = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.SND_PLAY, id)
  if type(h) ~= "number" or h == 0 then
    VRFW.mod_options.preview_stop("not played")
    return false
  end
  VRFW.mod_options.PREVIEW.handle = h
  VRFW.mod_options.PREVIEW.key = key
  VRFW.mod_options.PREVIEW.frame = 0
  VRFW.mod_options.remark(key)
  return true
end
function VRFW.mod_options.click_on_mark(a1, key)
  if VRFW.mod_options.preview_id(key) == nil and VRFW.mod_options.PREVIEW.key ~= key then
    return false
  end
  local function In(cmd)
    local c = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.CHECK_INPUT, VRFW.mod_options.PREVIEW_COMMANDS.MENU_CTRL, cmd)
    return c == true
  end
  if not In(VRFW.mod_options.PREVIEW_COMMANDS.LEFT) and (In(VRFW.mod_options.PREVIEW_COMMANDS.ENTER) or not In(VRFW.mod_options.PREVIEW_COMMANDS.CLICK)) then
    return false
  end
  local px = VRFW.host.menu_command(VRFW.mod_options.PREVIEW_COMMANDS.POINTER)
  local ax = VRFW.host.menu_command(VRFW.mod_options.PREVIEW_COMMANDS.MESH_POS, 3344436024, a1, 2475420648 --[[_btn_arrow_l01]])
  if type(px) ~= "number" or type(ax) ~= "number" then
    return false
  end
  return px < ax
end
function VRFW.mod_options.preview_step()
  if VRFW.mod_options.PREVIEW.handle ~= 0 then
    VRFW.mod_options.PREVIEW.frame = VRFW.mod_options.PREVIEW.frame + 1
    if not VRFW.mod_options.in_view() then
      VRFW.mod_options.preview_stop("tab left")
    elseif VRFW.mod_options.PREVIEW.frame % 30 == 0 then
      local p = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.SND_PLAYING, VRFW.mod_options.PREVIEW.handle)
      if p == false then
        VRFW.mod_options.preview_stop("ended")
      end
    end
  end
  if not VRFW.mod_options.TAB_IDX or VRFW.mod_options.PREVIEW.input == false then
    VRFW.mod_options.PREVIEW.key_down = false
    return
  end
  local k = VRFW.host.command(VRFW.mod_options.PREVIEW_COMMANDS.CHECK_INPUT, VRFW.mod_options.PREVIEW_COMMANDS.MENU_CTRL, VRFW.mod_options.PREVIEW_COMMANDS.KEY)
  local down = k == true
  if down and not VRFW.mod_options.PREVIEW.key_down and VRFW.mod_options.in_view() then
    local id = VRFW.mod_settings.focused()
    if id ~= nil and VRFW.mod_options.has_preview(id) and not VRFW.mod_options.preview_play(id) then
      funcLuaCommand(VRFW.commands.SND_PLAY, 2086672038 --[[sy0003]])
    end
  end
  VRFW.mod_options.PREVIEW.key_down = down
end

-- Every handler has the id "mod_options.tab".
local mod_options_host = "setting_menu"
local function mod_options_on(point, phase, fn, create)
  VRFW.host.on(mod_options_host, point, {id = "mod_options.tab", phase = phase, fn = fn, create = create})
end

if VRFW.host ~= nil then
  VRFW.host.list(mod_options_host, "option_rows", {apply = function(items)
    for _, it in ipairs(items) do
      if type(it.value) == "table" and VRFW.mod_settings.ROWS[it.id] == nil then
        VRFW.mod_options.register(it.id, it.value)
      end
    end
  end})

  mod_options_on("OnInit", "before", function()
    if VRFW.mod_options.PREVIEW.handle ~= 0 or VRFW.mod_options.PREVIEW.paused then
      VRFW.mod_options.preview_stop("menu opened")
    end
    VRFW.mod_options.PREVIEW.input = true
    VRFW.mod_settings.DRAFT = {}
    VRFW.mod_settings.LABELS = {}
    VRFW.mod_options.CELLS = {}
    VRFW.mod_options.TAB_IDX = nil
  end)

  mod_options_on("OnSetupLayer", "after", function(_, a1, a2)  -- the 5th tab: attach set of k + 1 tabs, item k visible
    if a1 == 601987949 or a1 == 4044286600 --[[cmn06_20_list_tab_item]] then
      local k = VRFW.mod_options.tab()
      if k then
        if a1 == 601987949 then
          LISTVIEW.UpdateAttachTabNum(k + 1, a1)
        else
          if a2 == k then
            funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, a1, a2, true)
            LISTVIEW.SetupTabIcon(a1, a2, VRFW.mod_options.ICON, true)
          end
          funcLuaMenuCommand(3252599449, a1, k + 1)
        end
      end
    end
  end)

  mod_options_on("OnChangeFocus", "around", function(nxt, a1, a2)  -- the mod tab focused: its title in the header
    if a1 == 4044286600 --[[cmn06_20_list_tab_item]] then
      local k = VRFW.mod_options.tab()
      if k then
        local idx = VRFW.host.menu_command(2603265800, a1)
        if idx == k then
          LISTVIEW.SetFocusFromHeaderToList(a1, 2081113831)
          funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, 601987949, 2303671242, VRFW.mod_options.text(VRFW.mod_options.TITLE_ID, "Mod options"), 0)
          return
        end
      end
    end
    return nxt(a1, a2)
  end)

  mod_options_on("UpdateListItem", "before", function(a1, a2)
    VRFW.mod_settings.LABELS[a1] = a2
    local key = VRFW.host.command(VRFW.mod_options.COMMANDS.CELL, a1)
    if type(key) == "string" then
      VRFW.mod_options.CELLS[a1] = VRFW.mod_options.key_of_label(a2) or key
    else
      VRFW.mod_options.CELLS[a1] = nil
    end
  end)

  mod_options_on("UpdateListContentDynamicText", "around", function(nxt, a1, a2, a3, a4)
    if a2 == 40 then
      local id = VRFW.mod_settings.label(a1)
      if id ~= nil then
        if a3 or a4 then               -- left / right (populate: both false)
          VRFW.mod_settings.LAST_OK = VRFW.mod_settings.toggle(id, a4 and 1 or -1)
        end
        VRFW.mod_settings.show(a1, id, a3, a4)
        return
      end
      if VRFW.mod_options.is_mod_cell(a1) then    -- a mod-tab row nobody drives: never the retail FPS code
        if a3 or a4 then
          VRFW.mod_settings.LAST_OK = false
        end
        VRFW.mod_options.show_text(a1, VRFW.mod_options.text(VRFW.mod_options.UNAVAILABLE_ID, "-"), false, false)
        return
      end
    end
    return nxt(a1, a2, a3, a4)
  end)

  -- a retail row with values drawn / changed: gated rows follow it
  mod_options_on("UpdateListContentText", "after", function()
    VRFW.mod_options.refresh_gated()
  end)
  mod_options_on("UpdateListContentCustomText", "after", function()
    VRFW.mod_options.refresh_gated()
  end)

  mod_options_on("PlayUpdateContentSound", "around", function(nxt, a1)
    if a1 == 40 then
      local id, idx = VRFW.mod_settings.focused()
      if id ~= nil or (idx ~= nil and VRFW.mod_options.is_mod_cell(idx)) then
        if VRFW.mod_settings.LAST_OK then
          funcLuaCommand(VRFW.commands.SND_PLAY, 3791946501 --[[sy0004]])
        else
          funcLuaCommand(VRFW.commands.SND_PLAY, 2086672038 --[[sy0003]])
        end
        VRFW.mod_settings.LAST_OK = true
        return 0
      end
    end
    return nxt(a1)
  end)

  mod_options_on("OnEnter", "around", function(nxt, a1, a2)  -- A on a mod row = right (the engine is not told)
    if a1 == 2081113831 or a1 == 3344436024 then
      local id, idx = VRFW.mod_settings.focused()
      if id ~= nil and VRFW.mod_options.has_preview(id) and VRFW.mod_options.click_on_mark(idx, id) then -- click on the ▶ side: preview
        if not VRFW.mod_options.preview_play(id) then
          funcLuaCommand(VRFW.commands.SND_PLAY, 2086672038 --[[sy0003]])
        end
        return
      end
      if id ~= nil then
        if VRFW.mod_settings.toggle(id, 1) then
          funcLuaCommand(VRFW.commands.SND_PLAY, 3848881948 --[[sy0000]])
        else
          funcLuaCommand(VRFW.commands.SND_PLAY, 2086672038 --[[sy0003]])
        end
        VRFW.mod_settings.show(idx, id, false, true)
        return
      end
      if idx ~= nil and VRFW.mod_options.is_mod_cell(idx) then
        funcLuaCommand(VRFW.commands.SND_PLAY, 2086672038 --[[sy0003]])
        return
      end
    end
    return nxt(a1, a2)
  end)

  mod_options_on("IsChangedGraphicSetting", "around", function(nxt, a1)
    if a1 == 40 and VRFW.mod_settings.dirty() then
      return true
    end
    return nxt(a1)
  end)

  mod_options_on("callBackSaveCheckDialog", "before", function(a1)
    if (a1 == 0 or a1 == 1) and VRFW.mod_options.PREVIEW.handle ~= 0 then
      VRFW.mod_options.preview_stop("drafts applied / dropped")
    end
    if a1 == 0 then
      VRFW.mod_settings.commit()
    elseif a1 == 1 then
      VRFW.mod_settings.DRAFT = {}
    end
  end)

  -- the preview key (Select / Tab) and the preview's end
  mod_options_on("Step", "after", function()
    VRFW.mod_options.preview_step()
  end)

  -- retail input gate (dialogs, sub windows): no preview key while it is off
  mod_options_on("SetInputEnbaleMenuObject", "before", function(a1)
    VRFW.mod_options.PREVIEW.input = a1
  end)

  mod_options_on("CloseMenuSetting", "before", function()
    if VRFW.mod_options.PREVIEW.handle ~= 0 or VRFW.mod_options.PREVIEW.paused then
      VRFW.mod_options.preview_stop("menu closed")
    end
  end)

  -- the menu object is destroyed: never leave the game's music paused (create: the retail script has no FinalizeMenu)
  mod_options_on("FinalizeMenu", "before", function()
    if VRFW.mod_options.PREVIEW.handle ~= 0 or VRFW.mod_options.PREVIEW.paused then
      VRFW.mod_options.preview_stop("menu finalized")
    end
  end, true)
end

if type(mod_options_legacy_rows) == "table" then -- an older framework build: adopt its rows
  for _, label in ipairs(mod_options_legacy_order or {}) do
    if mod_options_legacy_rows[label] ~= nil and VRFW.mod_settings.ROWS[label] == nil then
      VRFW.mod_options.register(label, mod_options_legacy_rows[label])
    end
  end
end
if type(VRFW.mod_options_queue) == "table" then
  for _, q in ipairs(VRFW.mod_options_queue) do
    if q.key ~= nil and q.row ~= nil then
      VRFW.mod_options.register(q.key, q.row)
    elseif q.label ~= nil and q.row ~= nil then
      VRFW.mod_settings.register(q.label, q.row)
    end
  end
end
VRFW.mod_options_queue = nil

