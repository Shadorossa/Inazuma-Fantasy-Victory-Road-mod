-- Advanced: menu_scene (VRFW, docs/framework/menu-scene.md "Scene actors"): a scene's people as scene characters.

VRFW.menu_scene = VRFW.menu_scene or {}
local MS = {
  FOR = VRFW.commands.VRFW_MENU_SCENE_FOR,          -- CMND_VRFW_MENU_SCENE_FOR (menu) -> key | ""
  SCENE = VRFW.commands.VRFW_MENU_SCENE,        -- CMND_VRFW_MENU_SCENE (key) -> table | ""
  STATE = VRFW.commands.VRFW_MENU_SCENE_STATE,
  SET = VRFW.commands.VRFW_MENU_SCENE_SET,          -- CMND_VRFW_MENU_SCENE_SET (state, arg) -> 1 | 0, state
  HAS_SAVE = 8577266,        -- (1) -> a save exists (the title's own test)
  FADE = 609722083,          -- (1 to black | 0 in, seconds)
  VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,       -- CMND_SET_LAYER_VISIBLE (layer, index, on)
  LAYER_EXISTS = VRFW.commands.IS_EXIST_LAYER,  -- CMND_IS_EXIST_LAYER (layer, index)
  MENU_EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT,  -- (menu) -> the menu object exists
  IS_MENU_OPEN = VRFW.commands.IS_EXIST_MENU,  -- CMND_IS_EXIST_MENU (menu) -> the menu is open
  CLOSE = VRFW.commands.CLOSE_MENU_OBJECT,         -- CMND_CLOSE_MENU_OBJECT (menu)
  MINIMAP = 1868910795,      -- (on) the field's minimap shown / hidden (0x6F6550CB)
  IS_MENU = VRFW.commands.IS_EXIST_MENU,       -- CMND_IS_EXIST_MENU (menu)
  MSG_BUSY = 898725220,      -- a message window is open
  SHEET = 3492314538,
  GO = 2860602156,           -- param vrfw_menu_scene_go: title_main presses Options
  OPTIONS = 1432246941,
  HUD_OFF = 3499142076,
  TITLE_READY = 358816896,
  CAMERA_POS = VRFW.commands.VRFW_FIELD_CAMERA_POS,
  SHOT = VRFW.commands.VRFW_MENU_SCENE_SHOT,
  SHOT_STEP = VRFW.commands.VRFW_MENU_SCENE_SHOT_STEP,
  STORY_GO = 4275168888,
  STORY_INFO = 3984017190,
  SHOT_PREV = 2155540576,
  SHOT_NEXT = 951543817,     -- CMD_FUNCTION arg crc32 vrfw_menu_scene_shot_next
  UPPER = 2250456639,
  FOCUS_ACTIVE = VRFW.commands.IS_CTRL_FOCUS_ACTIVE,  -- (layer) -> the layer holds the control focus
  FOCUS_INDEX = 2603265800,  -- (layer) -> its focused instance
  LOWER = 3873872512,        -- title00_07_item_button_lower: the lower row
  CURSOR = 24113234,         -- cmn05_01_coursor: the focus cursor
  FOCUS_MOVE = 2649971789,
  DIR_UP = 1133833840,
  DIR_LOW = 2458417313,
  KEY_HELD = 2620918304,
  KEY_UP = 1197218715,       -- CMD_UP
  CTRL_FOCUS = VRFW.commands.SET_ENABLE_CTRL_FOCUS,   -- (layer, on): the layer takes the control focus
  FOCUS_MARK = 1778826357,
  TRACE = VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE,
  CURSOR_LOCATOR = 282284405, -- _pos_atc_cur01
  SOUND = VRFW.commands.SND_PLAY_SE,
  SOUND_MOVE = 3284053048,   -- sy0082: the title's focus move sound
  -- the mode's name: layer vrfw_ms_label (object vrfw_mp_label: the corner button's text node, its plates hidden)
  LABEL = 2134430854,        -- vrfw_ms_label
  LABEL_NODE = 378327766,    -- _text_cmd_back01
  LABEL_MESHES = { 298211823, 2853207670 },   -- _cmd_back_base01, _cmd_back_base01_add
  LABEL_LEFT = -384,         -- the text node's left edge in its object (px)
  LABEL_MID_Y = 144,         -- its centre line
  OPEN_LAYER = VRFW.commands.OPEN_LAYER,    -- (layer, instance)
  LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM,    -- (layer) -> instances
  POS = VRFW.commands.SET_LAYER_LOCAL_POS,          -- CMND_SET_LAYER_LOCAL_POS (layer, x, y, z, instance): y up
  SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,        -- CMND_SET_LAYER_LOCAL_SCALE (layer, sx, sy, sz, instance)
  TEXT = VRFW.commands.SET_MENU_TEXT_STRING,         -- CMND_SET_MENU_TEXT_STRING (layer, node, text, instance)
  TEXT_ALPHA = VRFW.commands.SET_MENU_TEXT_ALPHA,   -- CMND_SET_MENU_TEXT_ALPHA (layer, instance, node, alpha)
  MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE, -- (layer, mesh, on, instance)
  HOTSPOTS = VRFW.commands.VRFW_MENU_SCENE_HOTSPOTS,
  SCREENS = VRFW.commands.VRFW_MENU_SCENE_SCREENS,
  SHOT_TAGS = VRFW.commands.VRFW_MENU_SCENE_SHOT_TAGS,
  LAYER_ALPHA = VRFW.commands.SET_LAYER_MODEL_ALPHA,  -- CMND_SET_LAYER_MODEL_ALPHA (layer, instance, 0, alpha)
  STORY_KIND = 3368022765,
  STORY_PICK = 1790329263,
  STORY_WAIT = 2392182225,
  BIT = VRFW.commands.GET_GLOBAL_BIT_FLAG,           -- (global bit) -> set
  STORY_MODES_BIT = 750283301,
  TEXT_GET = VRFW.commands.TEXT_GET,     -- CMND_TEXT_GET (id) -> text
  TEXT_GET_KEY = VRFW.commands.VRFW_TEXT_GET,  -- CMND_VRFW_TEXT_GET (key) -> text
  TEXT_SIZE = VRFW.commands.GET_MENU_TEXT_RECT_SIZE,
  NODE_SCALE = 2885415772,   -- (layer, instance, node, width, height): the text node's box
  BUZZER = 2086672038,       -- sy0003
  SELECTED_GROW = 1.15,      -- the selected hotspot's text, larger
  UNSELECTED_ALPHA = 0.8,
  FRAME = 3295131811,        -- vrfw_ms_frame
  FRAME_QUAD = 36,           -- the quad's own size (px)
  FRAME_SPRITE_NODE = 1909474081,   -- icon_new01: the quad's sprite
  FRAME_MESH = 312193881,    -- _icon_new01: the quad's mesh (its colour)
  FRAME_ATLAS = 528860506,   -- #/menu/220_img/vrfw_plain/vrfw_plain.g4tx
  FRAME_SQUARE = 1334397707, -- vrfw_plain_square (white)
  FRAME_COLOUR = { 0.32, 0.72, 1.0 },   -- the game's light blue
  FRAME_THICKNESS = 6,       -- px
  FLOOD_INSTANCE = 4,
  FLOOD_COLOUR = { 1.0, 0.96, 0.86 },   -- warm daylight
  SPRITE = 558735651,
  ROTATE = 3476640154,       -- (layer, x, y, z radians, instance)
  PRIM_COLOR = VRFW.commands.SET_PRIM_COLOR,    -- (layer, instance, mesh, r, g, b)
  MAP_TAG = VRFW.commands.SET_MAP_TAG,
  DOOR_OPEN = VRFW.commands.DOOR_OPEN,
  DOOR_TYPE = VRFW.commands.GET_DOOR_TYPE,
  CHRONICLE_WAIT = 53570903,
  PENDING = VRFW.commands.VRFW_MENU_SCENE_PENDING,      -- CMND_VRFW_MENU_SCENE_PENDING (action | "")
  LEAVE_WHITE = 2048703318,
  PICK_LAYER = 2283875177,
  PICK_INDEX = 3968429426, -- param vrfw_menu_scene_pick_index: that entry + 1
  PICK_OPTION = 2481379900,
  BB_CAMPAIGN_SAVE = VRFW.commands.GET_BB_STADIUM_CAMPAIGN_INFO,
  PICK_WAIT = 2171674033,
  HOME = VRFW.commands.VRFW_MENU_SCENE_HOME,         -- CMND_VRFW_MENU_SCENE_HOME (key[, on]) -> 1 on the home entry
  COME_BACK = VRFW.commands.VRFW_MENU_SCENE_COME_BACK,
  PICK_RETURN = 1862198659,
  FOCUS_WAIT_FRAMES = 10,
  MENU = "title_menu_2",
  ID = "VRFW.menu_scene",
  ASK_FRAMES = 60,
  READY_FRAMES = 1800,
}

-- per menu visit: phase ask | wait_ready | requested | handed | going_up | up | off
local ms = { phase = "off", frames = 0, asks = 0, key = nil, timeout = 600, hide = {}, hidden = {}, close = {}, closed = 0, up_frames = 0,
  counts = {}, hidden_set = {}, modes = false, mode_idx = nil, cursor_hidden = false, label = nil,
  home_shot = nil, home = false, home_restore = nil, home_leave = false, focus_wait = nil }

local MS_Log = VRFW.logger.new("menu_scene, title_menu_2")

--- Advanced: Tells whether the menu scene is up; answers true or false.
function VRFW.menu_scene.is_up() return ms.phase == "up" end
--- Advanced: Tells whether the menu scene is up on the home shot; answers true or false.
function VRFW.menu_scene.is_home() return ms.phase == "up" and ms.home == true end

VRFW.menu_scene = VRFW.menu_scene or {}
local ms_listeners = { mode_focused = {}, home_changed = {} }
--- Advanced: Registers listener fn under id for event (mode_focused or home_changed); answers true, or false for bad arguments.
function VRFW.menu_scene.on(event, id, fn)
  local list = ms_listeners[event]
  if list == nil or type(id) ~= "string" or type(fn) ~= "function" then return false end
  for i, l in ipairs(list) do
    if l.id == id then
      list[i].fn = fn
      return true
    end
  end
  list[#list + 1] = { id = id, fn = fn }
  return true
end
local function MS_Emit(event, ...)
  for _, l in ipairs(ms_listeners[event]) do
    local ok, why = pcall(l.fn, ...)
    if not ok then MS_Log("listener", l.id, event, "error:", tostring(why)) end
  end
end

-- a param cleared only when it is set (the retail way)
local function MS_Clear(k)
  if VRFW.param.has(k) then
    VRFW.param.clear(k)
  end
end

local function MS_Fail(why)
  MS_Log("FAILED:", why, "-> the retail main menu")
  MS_Clear(MS.HUD_OFF)
  ms.home = false
  VRFW.host.command(MS.SET, "failed", "title_menu_2: " .. tostring(why))
  MS_Clear(MS.GO)
  VRFW.host.command(MS.FADE, 0, 0.3)
  ms.phase = "off"
end

-- the menu's opening coroutine is done and nothing is open over it
local function MS_Ready()
  if VRFW.host.command(MS.MSG_BUSY) == true or VRFW.host.command(MS.IS_MENU, MS.SHEET) == true then
    return false
  end
  local h = type(VRFW.host) == "table" and VRFW.host.hosts and VRFW.host.hosts.title_menu_2
  local L = h and h.L
  if L ~= nil then
    local ok, co, t12 = pcall(function() return L.l5, L.t12 end)
    if ok then
      return co == nil or (type(t12) == "table" and t12[4] == true)
    end
  end
  return ms.frames >= 90       -- no locals: the opening coroutine's usual length
end

-- the scene's hidden layers, every instance (counted again on `recount`: a row may grow)
local function MS_Hide(recount)
  for _, id in ipairs(ms.hide) do
    local n = ms.counts[id]
    if n == nil or recount then
      n = 1
      for k = 1, 15 do
        local has = VRFW.host.menu_command(MS.LAYER_EXISTS, id, k)
        if has ~= true then break end
        n = k + 1
      end
      ms.counts[id] = n
    end
    for k = 0, n - 1 do
      VRFW.host.menu_command(MS.VISIBLE, id, k, false)
    end
    if not ms.hidden[id] then
      ms.hidden[id] = true
      MS_Log("layer", id, "hidden (the map shows through)")
    end
  end
end

-- the field's HUD menus (gauges, button guide, date, pop-ups) closed and its minimap hidden: only the map stays
local function MS_CloseField()
  ms.seen = ms.seen or {}
  for _, m in ipairs(ms.close) do
    local a, b = VRFW.host.command(MS.MENU_EXISTS, m), VRFW.host.command(MS.IS_MENU_OPEN, m)
    if not ms.seen[m] then
      ms.seen[m] = true
      MS_Log("field menu", m, "exists:", tostring(a), "open:", tostring(b))
    end
    if a == true or b == true then
      VRFW.host.command(MS.CLOSE, m)
      ms.closed = ms.closed + 1
      if ms.closed <= 8 then
        MS_Log("field menu", m, "closed (the field HUD off under the main menu)")
      end
    end
  end
  if #ms.close > 0 then
    VRFW.host.command(MS.MINIMAP, false)
  end
end

local function MS_ReportFocus()
  if ms.phase ~= "up" or type(GetSelectItemLayerName) ~= "function" or type(GetTitleMenuItemId) ~= "function" then
    return
  end
  if ms.home then
    ms.focus = nil
    return
  end
  local okl, layer = pcall(GetSelectItemLayerName)
  if not okl or layer ~= MS.UPPER then
    ms.focus = nil              -- off the mode row: the shot stays
    return
  end
  local oki, idx = pcall(GetSelectItemIdx)
  if not oki or type(idx) ~= "number" then return end
  local wait = ms.focus_wait
  if wait then
    -- Just out of the home entry: the title's selection may still be the tile it sat on.
    if idx ~= wait.idx and ms.up_frames <= wait.last then return end
    ms.focus_wait = nil
  end
  local okt, item = pcall(GetTitleMenuItemId, idx, true)
  if not okt or type(item) ~= "number" then return end
  item = item % 4294967296
  if item == ms.focus then return end
  ms.focus = item
  local shot = VRFW.host.command(MS.SHOT, ms.key, string.format("%.0f", item))
  MS_Log("focus: mode row tile", idx, string.format("%.0f", item), "-> shot", tostring(shot))
end

local function MS_ModeFocused(index)
  MS_Emit("mode_focused", index)
end

local function MS_SetHome(on, why)
  if not ms.home_shot then return end
  ms.home, ms.focus, ms.label = on, nil, nil
  local r = VRFW.host.command(MS.HOME, ms.key, on and 1 or 0)
  MS_Log("home entry", on and "on" or "off", "(", tostring(why), "): framework", tostring(r))
  MS_Emit("home_changed", on, why)            -- the "home_changed" event (VRFW.menu_scene.on)
end

-- the title's own selection: layer, instance
local function MS_Selected()
  if type(GetSelectItemLayerName) ~= "function" or type(GetSelectItemIdx) ~= "function" then return nil, nil end
  local okl, layer = pcall(GetSelectItemLayerName)
  local oki, idx = pcall(GetSelectItemIdx)
  return okl and layer or nil, oki and idx or nil
end

-- the instances of vrfw_ms_label (0 = the menu has no such layer: the mod's menus TOML is not installed)
local function MS_LabelCount()
  if ms.label_count == nil then
    local n = VRFW.host.menu_command(MS.LAYER_NUM, MS.LABEL)
    ms.label_count = type(n) == "number" and n or 0
    ms.label_open = {}
    if ms.label_count == 0 then MS_Log("no layer vrfw_ms_label in this menu: no mode name, no hotspot texts") end
  end
  return ms.label_count
end

local function MS_Text(k, text, x, y, sx, sy, alpha)
  if k >= MS_LabelCount() then return false end
  if type(text) ~= "string" or text == "" then
    if ms.label_open[k] then
      VRFW.host.menu_command(MS.VISIBLE, MS.LABEL, k, false)
      VRFW.host.menu_command(MS.POS, MS.LABEL, -4000, 4000, 0, k)
    end
    return true
  end
  if not ms.label_open[k] then
    ms.label_open[k] = true
    VRFW.host.menu_command(MS.OPEN_LAYER, MS.LABEL, k)
    VRFW.host.menu_command(MS.NODE_SCALE, MS.LABEL, k, MS.LABEL_NODE, 1600, 76)   -- a box wider than any line: never squeezed
  end
  for _, m in ipairs(MS.LABEL_MESHES) do VRFW.host.menu_command(MS.MESH_VISIBLE, MS.LABEL, m, false, k) end
  VRFW.host.menu_command(MS.TEXT, MS.LABEL, MS.LABEL_NODE, text, k)
  VRFW.host.menu_command(MS.SCALE, MS.LABEL, sx, sy, 1, k)
  VRFW.host.menu_command(MS.POS, MS.LABEL, x - MS.LABEL_LEFT * sx, -y - MS.LABEL_MID_Y * sy, 0, k)
  VRFW.host.menu_command(MS.TEXT_ALPHA, MS.LABEL, k, MS.LABEL_NODE, alpha or 1)
  VRFW.host.menu_command(MS.VISIBLE, MS.LABEL, k, true)
  return true
end

local function MS_ModeFrame()
  local layer, idx = MS_Selected()
  if layer == MS.UPPER and type(idx) == "number" then
    ms.mode_idx = idx
    if not ms.cursor_hidden or ms.up_frames % 10 == 0 then
      VRFW.host.menu_command(MS.VISIBLE, MS.CURSOR, 0, false)
      ms.cursor_hidden = true
    end
  elseif ms.cursor_hidden then
    ms.cursor_hidden = false
    VRFW.host.menu_command(MS.VISIBLE, MS.CURSOR, 0, true)
  end
  if ms.mode_idx == nil then return end
  local on_row = layer == MS.UPPER
  local want = string.format("%d:%s:%s", ms.mode_idx, tostring(on_row), tostring(ms.home))
  if want == ms.label then return end
  ms.label = want
  local name = ""
  if ms.home then
    if ms.label_on then MS_Text(0, "") end
    MS_Log("mode: the home entry", on_row and "(focused)" or "(the lower row has the focus)")
    return
  end
  if type(GetTextItemName) == "function" then
    local ok, t = pcall(GetTextItemName, ms.mode_idx, true)
    if ok and type(t) == "string" then name = t end
  end
  if ms.label_on then
    MS_Text(0, name, ms.label_x, ms.label_y, ms.label_scale, ms.label_scale, on_row and 1 or 0.6)
  end
  MS_Log("mode:", ms.mode_idx, name, on_row and "(focused)" or "(the lower row has the focus)")
end

-- the previous (-1) / next (+1) mode: the mode row's focus moves there (from the lower row too)
local function MS_ModeStep(dir)
  local n = type(GetItemButtonNum) == "function" and GetItemButtonNum(true) or 0
  if type(n) ~= "number" or n < 1 then return end
  local layer, idx = MS_Selected()
  local from = (layer == MS.UPPER and idx) or ms.mode_idx or 0
  local to = (from + dir) % n
  -- with a home entry: true = into it (past the first / last mode; the hidden focus stays), false = out of it
  local home = nil
  if ms.home_shot then
    if ms.home then
      to, home = (dir > 0 and 0 or n - 1), false
    elseif (dir > 0 and from == n - 1) or (dir < 0 and from == 0) then
      to, home = from, true
    end
  end
  if layer ~= MS.UPPER and layer ~= nil then
    VRFW.host.menu_command(MS.TRACE, layer, idx or 0, MS.CURSOR_LOCATOR, false)
    VRFW.host.menu_command(MS.CTRL_FOCUS, layer, false)
    VRFW.host.menu_command(MS.CTRL_FOCUS, MS.UPPER, true)
  end
  local was_home = ms.home
  if home ~= nil then MS_SetHome(home, dir < 0 and "previous mode key" or "next mode key") end
  if home == false then ms.focus_wait = { idx = to, last = ms.up_frames + MS.FOCUS_WAIT_FRAMES } end
  if not (layer == MS.UPPER and idx == to) then
    ms.own_move = ms.up_frames
    VRFW.host.menu_command(MS.FOCUS_MARK, MS.UPPER, to, true)
  end
  VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
  MS_Log("mode key", dir < 0 and "previous" or "next", ":", was_home and "home" or from, "->", home == true and "home" or to)
  MS_ModeFocused(home == true and -1 or to)
end

-- Advanced: A scene-reload host restores the mode through the same home/focus state used by navigation.
function VRFW.menu_scene.focus_mode(index)
  if ms.phase ~= "up" then return false end
  index = tonumber(index)
  local n = type(GetItemButtonNum) == "function" and GetItemButtonNum(true) or 0
  if not index or index ~= math.floor(index) or index < -1 or index >= n then return false end
  if index < 0 then
    if not ms.home_shot then return false end
    MS_SetHome(true, "restored after a scene reload")
    MS_ModeFocused(-1)
    return true
  end
  MS_SetHome(false, "restored after a scene reload")
  ms.home_restore, ms.home_leave, ms.focus = nil, false, nil
  ms.mode_idx = index
  ms.focus_wait = { idx = index, last = ms.up_frames + MS.FOCUS_WAIT_FRAMES }
  ms.own_move = ms.up_frames
  VRFW.host.menu_command(MS.CTRL_FOCUS, MS.UPPER, true)
  VRFW.host.menu_command(MS.FOCUS_MARK, MS.UPPER, index, true)
  MS_ModeFocused(index)
  return true
end

local function MS_HomeMove(old, new)
  local n = type(GetItemButtonNum) == "function" and GetItemButtonNum(true) or 0
  if type(n) ~= "number" or n < 1 then return false end
  local dir = ((new - old) % n) == 1 and 1 or -1
  if ms.home then
    local to = dir > 0 and 0 or n - 1
    if new == to then
      MS_SetHome(false, "left / right")
      return false
    end
    ms.home_restore, ms.home_leave = to, true
  elseif (dir > 0 and old == n - 1) or (dir < 0 and old == 0) then
    MS_SetHome(true, "left / right")
    ms.home_restore, ms.home_leave = old, false
  else
    return false
  end
  VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
  MS_Log("left / right:", old, "->", new, ms.home_leave and ("out of the home entry to " .. tostring(ms.home_restore))
    or "into the home entry")
  return true
end

-- up / down with the mode row hidden: true = handled here (the title's own move does not run)
local function MS_ModeUpDown(dir)
  local layer, idx = MS_Selected()
  local h = ms.hot
  if h and h.active and h.keys == "up_down" and layer == MS.UPPER and h.n > 1 then
    local to = h.sel + ((dir == MS.DIR_UP) and -1 or 1)
    if to >= 1 and to <= h.n then
      h.sel = to
      VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
      MS_Log("hotspot", h.sel, h.list[h.sel] and h.list[h.sel].name, "(up / down)")
      return true
    end
  end
  if dir == MS.DIR_UP and layer == MS.LOWER and ms.mode_idx ~= nil then
    if VRFW.host.menu_command(MS.KEY_HELD, MS.KEY_UP) then return true end
    -- back to the mode on screen, not to the tile above
    VRFW.host.menu_command(MS.TRACE, layer, idx or 0, MS.CURSOR_LOCATOR, false)
    VRFW.host.menu_command(MS.CTRL_FOCUS, layer, false)
    VRFW.host.menu_command(MS.CTRL_FOCUS, MS.UPPER, true)
    ms.own_move = ms.up_frames
    VRFW.host.menu_command(MS.FOCUS_MARK, MS.UPPER, ms.mode_idx, true)
    VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
    return true
  end
  if (dir == MS.DIR_UP and layer == MS.UPPER) or (dir == MS.DIR_LOW and layer == MS.LOWER) then
    -- the title's target (a banner): refused when the scene hides it
    local target
    if type(GetNextFocusBannerLayerName) == "function" then
      local ok, t = pcall(GetNextFocusBannerLayerName, layer, idx or 0)
      target = ok and t or nil
    end
    if target ~= nil and ms.hidden_set[target] then return true end
  end
  return false
end

local STORY_ROW = { story_new_game = 0, story_continue = 1, story_plus = 2, story_extended = 3 }
local ACTION_TEXT = { story_new_game = 1851993283, story_continue = 2856747853, story_plus = 1003539027, story_extended = 89409320,
  chronicle_map = 365874030 }

local function MS_StorySaves()
  local _, saves = VRFW.host.command(MS.STORY_INFO)
  return tonumber(saves) or 0
end

-- the conditions a hotspot's open_group_if may name
local GROUP_CONDITIONS = {
  bb_campaign_save = function() return VRFW.host.menu_command(MS.BB_CAMPAIGN_SAVE, 0) == true end,
}

local function MS_ActionAvailable(a, saves, e)
  if a == "open_group" then
    if not e or (e.open_group or "") == "" then return false end
    local cond = e.open_group_if or ""
    if cond == "" then return true end
    local f = GROUP_CONDITIONS[cond]
    local ok, yes = pcall(f or function() return false end)
    return ok and yes == true
  end
  if a == "story_continue" then return saves > 0 end
  if a == "story_new_game" then return saves <= 0 end
  if a == "story_plus" or a == "story_extended" then return VRFW.host.command(MS.BIT, MS.STORY_MODES_BIT) == true end
  if a == "chronicle_map" then return true end
  if a == "menu_pick" then return true end
  if a == "call" then return e ~= nil and (e.call or "") ~= "" end
  return false
end

local function MS_TextOf(t, action)
  if type(t) == "string" and t ~= "" then
    local id = tonumber(t)
    if id then
      local s = VRFW.host.command(MS.TEXT_GET, id)
      if type(s) == "string" and s ~= "" then return s end
    end
    local s = VRFW.host.command(MS.TEXT_GET_KEY, t)
    if type(s) == "string" and s ~= "" then return s end
  end
  local s = VRFW.host.command(MS.TEXT_GET, ACTION_TEXT[action] or 0)
  return type(s) == "string" and s or ""
end

local function MS_FrameCount()
  if ms.frame_count == nil then
    local n = VRFW.host.menu_command(MS.LAYER_NUM, MS.FRAME)
    ms.frame_count = type(n) == "number" and n or 0
    ms.frame_open = {}
    if ms.frame_count < 4 then MS_Log("no layer vrfw_ms_frame (4 instances) in this menu: no hotspot outline") end
  end
  return ms.frame_count
end

-- the outline's instances shown last frame (hidden again when not drawn)
local function MS_FrameHide(from)
  if not ms.frame_shown then return end
  for k, on in pairs(ms.frame_shown) do
    if on and (from == nil or not from[k]) then
      VRFW.host.menu_command(MS.VISIBLE, MS.FRAME, k, false)
      ms.frame_shown[k] = nil
    end
  end
  if from == nil then ms.frame_shown = false end
end

-- the parts of the segment a -> b (0..1 along it) outside the boxes { x0, y0, x1, y1, … } grown by `pad` (menu px)
local function MS_SegmentOutside(ax, ay, bx, by, boxes, pad)
  local keep = { { 0, 1 } }
  for b = 1, #boxes - 3, 4 do
    local x0, y0, x1, y1 = boxes[b] - pad, boxes[b + 1] - pad, boxes[b + 2] + pad, boxes[b + 3] + pad
    -- the segment's part inside the box (Liang-Barsky)
    local t0, t1, inside = 0, 1, true
    for _, edge in ipairs({ { -(bx - ax), ax - x0 }, { bx - ax, x1 - ax }, { -(by - ay), ay - y0 }, { by - ay, y1 - ay } }) do
      local p, q = edge[1], edge[2]
      if p == 0 then
        if q < 0 then inside = false end
      else
        local r = q / p
        if p < 0 then t0 = math.max(t0, r) else t1 = math.min(t1, r) end
      end
    end
    if inside and t0 < t1 then
      local cut = {}
      for _, piece in ipairs(keep) do
        if piece[2] <= t0 or piece[1] >= t1 then
          cut[#cut + 1] = piece
        else
          if piece[1] < t0 then cut[#cut + 1] = { piece[1], t0 } end
          if piece[2] > t1 then cut[#cut + 1] = { t1, piece[2] } end
        end
      end
      keep = cut
    end
  end
  return keep
end

local function MS_FrameDraw(outline, hidden)
  if MS_FrameCount() < 4 or type(outline) ~= "table" or #outline < 8 then return MS_FrameHide() end
  local t = MS.FRAME_THICKNESS
  local boxes = type(hidden) == "table" and hidden or {}
  local pieces = {}
  for k = 0, 3 do
    local ax, ay = outline[k * 2 + 1], outline[k * 2 + 2]
    local n = (k + 1) % 4
    local bx, by = outline[n * 2 + 1], outline[n * 2 + 2]
    -- a little longer at both ends: the corners close
    local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
    if len > 0 then
      local ux, uy = (bx - ax) / len, (by - ay) / len
      ax, ay, bx, by = ax - ux * t / 2, ay - uy * t / 2, bx + ux * t / 2, by + uy * t / 2
      for _, part in ipairs(MS_SegmentOutside(ax, ay, bx, by, boxes, t / 2)) do
        local px, py = ax + (bx - ax) * part[1], ay + (by - ay) * part[1]
        local qx, qy = ax + (bx - ax) * part[2], ay + (by - ay) * part[2]
        if (qx - px) ^ 2 + (qy - py) ^ 2 >= 4 then pieces[#pieces + 1] = { px, py, qx, qy } end
      end
    end
  end
  local drawn, k, count = {}, 0, 0
  for _, piece in ipairs(pieces) do
    if k == MS.FLOOD_INSTANCE then k = k + 1 end
    if k >= MS_FrameCount() then break end
    local ax, ay, bx, by = piece[1], piece[2], piece[3], piece[4]
    if not ms.frame_open[k] then
      ms.frame_open[k] = true
      VRFW.host.menu_command(MS.OPEN_LAYER, MS.FRAME, k)
      VRFW.host.menu_command(MS.SPRITE, MS.FRAME, MS.FRAME_ATLAS, MS.FRAME_SQUARE, MS.FRAME_SPRITE_NODE, 0, k)
      VRFW.host.menu_command(MS.PRIM_COLOR, MS.FRAME, k, MS.FRAME_MESH, MS.FRAME_COLOUR[1], MS.FRAME_COLOUR[2], MS.FRAME_COLOUR[3])
    end
    VRFW.host.menu_command(MS.SCALE, MS.FRAME, math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) / MS.FRAME_QUAD, t / MS.FRAME_QUAD, 1, k)
    VRFW.host.menu_command(MS.ROTATE, MS.FRAME, 0, 0, math.atan2(-(by - ay), bx - ax), k)
    VRFW.host.menu_command(MS.POS, MS.FRAME, (ax + bx) / 2, -(ay + by) / 2, 0, k)
    VRFW.host.menu_command(MS.VISIBLE, MS.FRAME, k, true)
    drawn[k] = true
    k, count = k + 1, count + 1
  end
  if count < #pieces and not ms.frame_short_logged then
    ms.frame_short_logged = true
    MS_Log("outline:", #pieces, "parts, vrfw_ms_frame draws", count, "(more instances needed)")
  end
  if type(ms.frame_shown) == "table" then MS_FrameHide(drawn) end
  ms.frame_shown = drawn
end

local function MS_EdgeTo(slot)
  local h = ms.hot
  if (h.edge_shown or 0) == (slot or 0) then return end
  if VRFW.menu_scene and VRFW.menu_scene.actor_edge then
    if (h.edge_shown or 0) ~= 0 then VRFW.menu_scene.actor_edge(h.edge_shown, false) end
    if (slot or 0) ~= 0 then VRFW.menu_scene.actor_edge(slot, true) end
  end
  h.edge_shown = slot or 0
end

local function MS_HotHide()
  local h = ms.hot
  h.outline_on = nil
  MS_EdgeTo(0)
  MS_FrameHide()
  if not h.drawn then return end
  h.drawn = false
  for i = 1, h.n or 0 do
    MS_Text(i, "")
  end
end

-- the hotspots of a shot that just came: each one's action (the first available), its text, the one selected
local function MS_HotLoad(r)
  local h = ms.hot
  if r.shot ~= h.group_shot then h.group, h.group_shot = "", r.shot end   -- a new shot opens on its first group
  h.group = h.group or ""
  h.shot, h.list, h.sel = r.shot, {}, 1
  h.keys = r.keys or "left_right"
  local saves = MS_StorySaves()
  local max = MS_LabelCount() - 1
  local src = {}
  for i = 1, tonumber(r.n) or 0 do
    if type(r[i]) == "table" and (r[i].group or "") == h.group and #src < max then src[#src + 1] = i end
  end
  h.n = #src
  for j, si in ipairs(src) do
    local i, e = j, r[si]
    local pick, ok = nil, false
    for _, a in ipairs(type(e.actions) == "table" and e.actions or {}) do
      if MS_ActionAvailable(a, saves, e) then pick, ok = a, true break end
    end
    pick = pick or (type(e.actions) == "table" and e.actions[1]) or ""
    h.list[i] = { name = e.name, action = pick, available = ok, text = MS_TextOf(e.text, pick), push_shot = e.push_shot,
      ms = tonumber(e.ms) or 800, flood_ms = tonumber(e.flood_ms) or 0, width = nil,
      door = type(e.door) == "string" and e.door or "", door_id = tonumber(e.door_id) or 0,
      door_ms = tonumber(e.door_ms) or 0, door_reverse = e.door_reverse == 1, leave_white = e.leave_white == 1,
      pick_layer = tonumber(e.pick_layer) or 0, pick_index = tonumber(e.pick_index) or 0, draw = e.draw ~= 0,
      pick_option = tonumber(e.pick_option) or -1, open_group = e.open_group or "", back_to = e.back_to or "", src = si,
      outline_tag = tonumber(e.outline_tag) or 0, edge_actor = tonumber(e.edge_actor) or 0, call = e.call or "" }
    if e.start == 1 then h.sel = i end
    MS_Log("hotspot", i, e.name, "->", pick, ok and "available" or "not available", h.list[i].text)
    if h.list[i].door_id ~= 0 then
      local registered, kind = VRFW.host.command(MS.DOOR_TYPE, h.list[i].door_id)
      MS_Log("hotspot", e.name, "door", h.list[i].door, string.format("0x%08X", h.list[i].door_id), "registered:",
        tostring(registered) or "call failed", kind and string.format("type 0x%08X", kind % 4294967296) or "")
    end
  end
  if #src >= max and h.n < (tonumber(r.n) or 0) then MS_Log("vrfw_ms_label has", MS_LabelCount(), "instance(s): only", h.n, "hotspot(s) drawn") end
end

-- the text's width at scale 1 (the game's measure, else 13 px per character)
local function MS_TextWidth(k, text)
  VRFW.host.menu_command(MS.NODE_SCALE, MS.LABEL, k, MS.LABEL_NODE, 1600, 76)
  VRFW.host.menu_command(MS.SCALE, MS.LABEL, 1, 1, 1, k)
  VRFW.host.menu_command(MS.TEXT, MS.LABEL, MS.LABEL_NODE, text, k)
  local w = VRFW.host.menu_command(MS.TEXT_SIZE, MS.LABEL, k, MS.LABEL_NODE)
  if type(w) ~= "number" or w <= 0 then w = 13 * #text end
  return w
end

local function MS_HotFrame()
  local h = ms.hot
  local layer = MS_Selected()
  if ms.home then
    h.active, h.shot = false, nil   -- the home entry: no hotspots (A does nothing there)
    return MS_HotHide()
  end
  local r = VRFW.host.command(MS.HOTSPOTS, ms.key)
  if type(r) ~= "table" or r.settled ~= 1 or MS_LabelCount() < 2 then
    h.active = false
    if type(r) ~= "table" then h.shot = nil end
    return MS_HotHide()
  end
  if r.shot ~= h.shot then MS_HotLoad(r) end
  h.active = h.n > 0 and layer == MS.UPPER
  local outline, hidden = nil, nil
  h.outline_on = nil
  local edge = 0
  for i = 1, h.n do
    local d = h.list[i]
    local e = r[d.src or i]
    if e.seen ~= 1 or not d.draw then
      MS_Text(i, "")                 -- not seen, or drawn by the mod (draw = false)
    else
      d.width = d.width or MS_TextWidth(i, d.text)
      local sc = math.max(0.5, math.min(1.0, e.w * 0.9 / d.width, e.h * 0.8 / 40))
      local sy = sc
      if e.w > 0 and e.h < e.w * 0.45 then sy = sc * math.max(0.6, e.h / (e.w * 0.45)) end
      -- the selected one (only while the mode row has the focus): full white, a little larger, outlined; not available: faint
      local selected = h.active and i == h.sel
      local alpha = not d.available and 0.4 or (selected and 1 or MS.UNSELECTED_ALPHA)
      local grow = selected and MS.SELECTED_GROW or 1
      MS_Text(i, d.text, e.x - d.width * sc * grow / 2, e.y, sc * grow, sy * grow, alpha)
      if selected then
        if d.edge_actor ~= 0 then
          edge = d.edge_actor            -- the actor's own edge, no rectangle
        elseif d.outline_tag ~= 0 then
          h.outline_on = d.outline_tag   -- the mod's outline of the object (map tag), no rectangle
        else
          outline, hidden = e.outline, e.hidden
        end
      end
    end
  end
  if outline then MS_FrameDraw(outline, hidden) else MS_FrameHide() end
  MS_EdgeTo(edge)
  h.drawn = true
end

--- Advanced: Reads the hotspot state; answers shot, selected index, selected name, count ("", 0, "", 0 when none).
function VRFW.menu_scene.hotspot()
  local h = ms.hot
  if not h or not h.shot or (h.n or 0) == 0 then return "", 0, "", 0 end
  local d = h.list[h.sel]
  return h.shot, h.active and h.sel or 0, d and d.name or "", h.n
end

local function MS_ScreenHide()
  for name, st in pairs(ms.screens or {}) do
    if st.shown then
      for _, layer in ipairs(st.layers or {}) do VRFW.host.menu_command(MS.VISIBLE, layer, 0, false) end
      st.shown, st.alpha = false, 0
      MS_Log("screen", name, "hidden")
    end
  end
end

local function MS_TagFrame(all)
  local want, order = {}, {}
  for _, t in ipairs(ms.tags or {}) do
    if want[t[1]] == nil then order[#order + 1] = t[1] end
    want[t[1]] = t[2]
  end
  local r = VRFW.host.command(MS.SHOT_TAGS, ms.key)
  local shot = type(r) == "table" and r.shot or ""
  if type(r) == "table" then
    for _, pair in ipairs({ { r.on, true }, { r.off, false } }) do
      for _, id in ipairs(type(pair[1]) == "table" and pair[1] or {}) do
        if want[id] == nil then order[#order + 1] = id end
        want[id] = pair[2]
      end
    end
  end
  -- The hotspots' outline tags: only the selected hotspot's is on.
  local selected = ms.hot and ms.hot.outline_on
  for _, id in ipairs(ms.outline_tags or {}) do
    if want[id] == nil then order[#order + 1] = id end
    want[id] = id == selected
  end
  ms.tag_state = ms.tag_state or {}
  for _, id in ipairs(order) do
    if all or ms.tag_state[id] ~= want[id] then
      local ok = pcall(funcLuaCommand, MS.MAP_TAG, id, want[id])
      if ms.tag_state[id] ~= want[id] then
        MS_Log(string.format("map tag 0x%08X %s for shot %s (%s)", id % 4294967296, want[id] and "on" or "off", shot, tostring(ok)))
      end
      ms.tag_state[id] = want[id]
    end
  end
end

local function MS_ScreenFrame()
  local r = VRFW.host.command(MS.SCREENS, ms.key)
  if type(r) ~= "table" then return MS_ScreenHide() end
  ms.screens = ms.screens or {}
  for i = 1, tonumber(r.n) or 0 do
    local e = r[i]
    local st = ms.screens[e.name]
    if not st then
      st = { alpha = 0, open = {}, shown = false, layers = e.layers }
      ms.screens[e.name] = st
    end
    local fade = tonumber(e.fade_ms) or 0
    local step = fade > 0 and (1000 / 60) / fade or 1
    local target = (e.on == 1 and e.seen == 1) and 1 or 0
    if st.alpha < target then st.alpha = math.min(target, st.alpha + step)
    elseif st.alpha > target then st.alpha = math.max(target, st.alpha - step) end
    local d = type(e.design) == "table" and e.design or { 0, 0, 1920, 1080 }
    if st.alpha > 0 and e.seen == 1 and d[3] > 0 and d[4] > 0 then
      local sx, sy = (e.x1 - e.x0) / d[3], (e.y1 - e.y0) / d[4]
      for _, layer in ipairs(e.layers) do
        if not st.open[layer] then
          st.open[layer] = true
          VRFW.host.menu_command(MS.OPEN_LAYER, layer, 0)
        end
        VRFW.host.menu_command(MS.SCALE, layer, sx, sy, 1, 0)
        VRFW.host.menu_command(MS.POS, layer, e.x0 - d[1] * sx, -(e.y0 - d[2] * sy), 0, 0)
        VRFW.host.menu_command(MS.LAYER_ALPHA, layer, 0, 0, st.alpha)
        VRFW.host.menu_command(MS.VISIBLE, layer, 0, true)
      end
      if not st.shown then
        st.shown = true
        MS_Log(string.format("screen %s shown: %d layer(s) on x %.0f .. %.0f, y %.0f .. %.0f (scale %.3f x %.3f)", e.name,
          #e.layers, e.x0, e.x1, e.y0, e.y1, sx, sy))
      end
    elseif st.shown then
      for _, layer in ipairs(e.layers) do VRFW.host.menu_command(MS.VISIBLE, layer, 0, false) end
      st.shown = false
      MS_Log("screen", e.name, "hidden")
    end
  end
end

local function MS_FloodFrame()
  local f = ms.flood
  if not f or MS_FrameCount() <= MS.FLOOD_INSTANCE then return end
  local elapsed = ms.up_frames - f.start
  local begin = f.total - f.length
  if elapsed < begin then return end
  local k = f.length > 0 and math.min(1, (elapsed - begin) / f.length) or 1
  k = k * k * (3 - 2 * k)
  local cx, cy, w, h = 960, 540, 0, 0
  local r = VRFW.host.command(MS.HOTSPOTS, ms.key, f.shot)
  local e = type(r) == "table" and r[f.index] or nil
  if type(e) == "table" and e.seen == 1 then cx, cy, w, h = e.x, e.y, e.w, e.h end
  -- from the rectangle to a little more than the screen
  local fx, fy, fw, fh = cx + (960 - cx) * k, cy + (540 - cy) * k, w + (2000 - w) * k, h + (1140 - h) * k
  local q = MS.FLOOD_INSTANCE
  if not ms.frame_open[q] then
    ms.frame_open[q] = true
    VRFW.host.menu_command(MS.OPEN_LAYER, MS.FRAME, q)
    VRFW.host.menu_command(MS.SPRITE, MS.FRAME, MS.FRAME_ATLAS, MS.FRAME_SQUARE, MS.FRAME_SPRITE_NODE, 0, q)
  end
  VRFW.host.menu_command(MS.PRIM_COLOR, MS.FRAME, q, MS.FRAME_MESH, MS.FLOOD_COLOUR[1], MS.FLOOD_COLOUR[2], MS.FLOOD_COLOUR[3])
  VRFW.host.menu_command(MS.ROTATE, MS.FRAME, 0, 0, 0, q)
  VRFW.host.menu_command(MS.SCALE, MS.FRAME, math.max(fw, 1) / MS.FRAME_QUAD, math.max(fh, 1) / MS.FRAME_QUAD, 1, q)
  VRFW.host.menu_command(MS.POS, MS.FRAME, fx, -fy, 0, q)
  VRFW.host.menu_command(MS.VISIBLE, MS.FRAME, q, true)
  if not f.logged then
    f.logged = true
    MS_Log("light flood from hotspot", f.index, "over", math.floor(f.length * 1000 / 60), "ms")
  end
end

local function MS_DoorFrame()
  local d = ms.door
  if not d or d.done or ms.up_frames - d.start < d.wait then return end
  d.done = true
  local registered, kind = VRFW.host.command(MS.DOOR_TYPE, d.id)
  if registered ~= true then
    MS_Log("door", d.name, string.format("0x%08X", d.id), "not opened: not a registered door of the map (",
      tostring(registered) or "call failed", "): the light flood alone")
    return
  end
  local res = VRFW.host.command(MS.DOOR_OPEN, d.id, true, d.reverse)
  MS_Log("door", d.name, string.format("0x%08X", d.id), "opens", d.reverse and "(reverse clips)" or "", "type",
    kind and string.format("0x%08X", kind % 4294967296) or "?", tostring(res) or "call failed")
end

-- left / right on the mode row while hotspots are shown: the selection moves, the row's own move is undone
local function MS_HotMove(old, new)
  local h = ms.hot
  local n = type(GetItemButtonNum) == "function" and GetItemButtonNum(true) or 0
  local d = (n > 0) and ((new - old) % n) or (new - old)
  local dir = d == 1 and 1 or -1
  h.sel = ((h.sel - 1 + dir) % h.n) + 1
  h.restore = old
  VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
  MS_Log("hotspot", h.sel, h.list[h.sel] and h.list[h.sel].name)
end

-- A on the mode row while hotspots are shown: true = handled (the title's press then runs or not as returned)
local function MS_HotEnter()
  local h = ms.hot
  local e = h.list[h.sel]
  if not e then return false end
  if not e.available then
    VRFW.host.command(MS.SOUND, MS.BUZZER)
    MS_Log("hotspot", e.name, ":", e.action, "not available")
    return true, false
  end
  if e.action == "call" then
    -- a function of the title's Lua (a mod's: it does the rest; the title is not left)
    local fn = _G
    for part in tostring(e.call):gmatch("[^%.]+") do fn = type(fn) == "table" and fn[part] or nil end
    if type(fn) ~= "function" then
      MS_Log("hotspot", e.name, ": call", e.call, "is not a function of the title")
      return true, false
    end
    local ok, why = pcall(fn, e.name)
    MS_Log("hotspot", e.name, ": call", e.call, ok and "" or ("error " .. tostring(why)))
    return true, false
  end
  if e.action == "open_group" then
    -- the shot shows the hotspots of the group (Back: its first group again)
    h.group, h.shot = e.open_group, nil
    VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
    MS_Log("hotspot", e.name, ": group", e.open_group)
    return true, false
  end
  for _, k in ipairs({ MS.STORY_GO, MS.STORY_KIND, MS.STORY_PICK, MS.STORY_WAIT, MS.CHRONICLE_WAIT, MS.LEAVE_WHITE,
      MS.PICK_LAYER, MS.PICK_INDEX, MS.PICK_WAIT, MS.PICK_OPTION, MS.PICK_RETURN }) do
    MS_Clear(k)
  end
  if e.leave_white then
    VRFW.param.set(MS.LEAVE_WHITE, 1)
  end
  -- Back from what the action opens comes to the title: it opens again on this mode
  if e.back_to == "title" and ms.mode_idx ~= nil then VRFW.host.command(MS.COME_BACK, ms.key, ms.mode_idx) end
  if e.action == "chronicle_map" then
    VRFW.param.set(MS.CHRONICLE_WAIT, e.ms)
  elseif e.action == "menu_pick" then
    -- the press is the tile's own; title_main ends after the push-in, the next menu holding pick_layer presses the entry
    VRFW.param.set(MS.PICK_LAYER, e.pick_layer)
    VRFW.param.set(MS.PICK_INDEX, e.pick_index + 1)
    if (e.pick_option or -1) >= 0 then VRFW.param.set(MS.PICK_OPTION, e.pick_option + 1) end
    if e.back_to == "title" then VRFW.param.set(MS.PICK_RETURN, 1) end
    VRFW.param.set(MS.PICK_WAIT, e.ms)
  elseif e.action == "story_continue" or e.action == "story_new_game" then
    VRFW.param.set(MS.STORY_GO, e.ms)
    VRFW.param.set(MS.STORY_KIND, e.action == "story_new_game" and 2 or 1)
  else
    VRFW.param.set(MS.STORY_PICK, STORY_ROW[e.action] + 1)
    VRFW.param.set(MS.STORY_WAIT, e.ms)
  end
  if type(e.push_shot) == "string" and e.push_shot ~= "" then
    VRFW.host.command(MS.SHOT, ms.key, e.push_shot)
  end
  if e.flood_ms > 0 then
    ms.flood = { shot = h.shot, index = e.src or h.sel, start = ms.up_frames, total = e.ms * 60 / 1000,
      length = math.min(e.flood_ms, e.ms) * 60 / 1000, logged = false }
  end
  if e.door_id ~= 0 then
    ms.door = { id = e.door_id, name = e.door, start = ms.up_frames, wait = e.door_ms * 60 / 1000, reverse = e.door_reverse,
      done = false }
  end
  MS_Log("hotspot", e.name, ":", e.action, "after", e.ms, "ms (push", tostring(e.push_shot), ", light", e.flood_ms, "ms, door",
    e.door_id ~= 0 and (e.door .. " after " .. e.door_ms .. " ms") or "none", ", leave", e.leave_white and "white" or "black", ")")
  return true, true
end

--- Internal: gate of the scene reveal for key; answers true unless another module overrides it.
function VRFW.menu_scene.can_reveal(key) return true end

local function MS_GoUp(key)
  if VRFW.menu_scene.can_reveal(key) ~= true then return false end
  local ok = VRFW.host.command(MS.SET, "up")
  if ok ~= 1 then
    return false
  end
  ms.key, ms.phase, ms.up_frames = key, "up", 0
  VRFW.host.command(MS.FADE, 0, 0.3)
  VRFW.host.command(MS.FADE, 0, 0.3, 1)
  local sc = VRFW.host.command(MS.SCENE, key)
  ms.hide = type(sc) == "table" and type(sc.hide_layers) == "table" and sc.hide_layers or {}
  ms.close = type(sc) == "table" and type(sc.close_menus) == "table" and sc.close_menus or {}
  ms.hidden_set = {}
  for _, id in ipairs(ms.hide) do ms.hidden_set[id] = true end
  ms.modes = type(sc) == "table" and sc.shots_select_modes == 1
  ms.label_on = not (type(sc) == "table" and sc.mode_label == 0)
  ms.label_x = type(sc) == "table" and tonumber(sc.mode_label_x) or 64
  ms.label_y = type(sc) == "table" and tonumber(sc.mode_label_y) or 880
  ms.label_scale = type(sc) == "table" and tonumber(sc.mode_label_scale) or 0.75
  ms.mode_idx, ms.label, ms.cursor_hidden, ms.label_count = nil, nil, false, nil
  ms.frame_count, ms.frame_open, ms.frame_shown, ms.flood, ms.door = nil, {}, false, nil, nil
  ms.hot = { n = 0, list = {}, sel = 1 }
  ms.screens = {}
  MS_Clear(MS.LEAVE_WHITE)
  for _, k in ipairs({ MS.PICK_LAYER, MS.PICK_INDEX, MS.PICK_WAIT }) do MS_Clear(k) end
  ms.actions = {}
  for _, a in ipairs(type(sc) == "table" and type(sc.actions) == "table" and sc.actions or {}) do
    if type(a) == "table" and type(a.tile) == "number" then ms.actions[a.tile % 4294967296] = a end
  end
  MS_Log("opened over the map of", key, "(scene up):", #ms.hide, "layer(s) to hide,", #ms.close, "field menu(s) to close,",
    ms.modes and "the shots select the modes" or "the mode row as the game's")
  local okp, x, y, z = VRFW.host.command(MS.CAMERA_POS)
  MS_Log("field camera anchor (the walker):", tostring(okp), tostring(x), tostring(y), tostring(z))
  MS_CloseField()
  MS_Hide()
  ms.tags, ms.tag_state = {}, {}
  ms.outline_tags = type(sc) == "table" and type(sc.outline_tags) == "table" and sc.outline_tags or {}
  for _, pair in ipairs({ { type(sc) == "table" and sc.map_tags_on, true }, { type(sc) == "table" and sc.map_tags_off, false } }) do
    for _, tag in ipairs(type(pair[1]) == "table" and pair[1] or {}) do
      ms.tags[#ms.tags + 1] = { tag, pair[2] }
      ms.tag_state = ms.tag_state or {}
      ms.tag_state[tag] = pair[2]
      local okt = pcall(funcLuaCommand, MS.MAP_TAG, tag, pair[2])
      MS_Log(string.format("map tag 0x%08X %s (%s)", tag % 4294967296, pair[2] and "on" or "off", tostring(okt)))
    end
  end
  ms.focus, ms.home, ms.home_restore, ms.home_leave, ms.focus_wait = nil, false, nil, false, nil
  ms.home_shot = ms.modes and type(sc) == "table" and type(sc.home_shot) == "string" and sc.home_shot ~= "" and sc.home_shot or nil
  -- A return to the title after an action that declared it (return = "title") opens on the mode it left from.
  local back = tonumber(VRFW.host.command(MS.COME_BACK, key)) or -1
  if back >= 0 and VRFW.menu_scene.focus_mode(back) then
    MS_Log("opened on mode", back, "(the return of the action it left by)")
  elseif ms.home_shot then
    MS_SetHome(true, "the menu opens on it")
  end
  MS_ReportFocus()               -- the tile focused at the open
  local open_layer, open_idx = MS_Selected()
  if ms.home then
    MS_ModeFocused(-1)
  elseif open_layer == MS.UPPER and type(open_idx) == "number" then
    MS_ModeFocused(open_idx)
  end
  return true
end

local function MS_Ask()
  local state, key = VRFW.host.command(MS.STATE)
  if type(state) ~= "string" then
    ms.asks = ms.asks + 1
    if ms.asks > MS.ASK_FRAMES then
      MS_Log("the framework did not answer: the retail main menu")
      ms.phase = "off"
    end
    return
  end
  if state == "switching" or state == "up" then
    ms.phase = "going_up"
    ms.key = key
    local sc = VRFW.host.command(MS.SCENE, key)
    ms.hide = type(sc) == "table" and type(sc.hide_layers) == "table" and sc.hide_layers or {}
    MS_Hide()
    return
  end
  if state ~= "idle" then
    MS_Fail("the main menu opened while the scene was at " .. state)
    return
  end
  MS_Clear(MS.HUD_OFF)         -- no scene up: the field HUD is the game's again
  local k = VRFW.host.command(MS.FOR, MS.MENU)
  if type(k) ~= "string" then
    ms.asks = ms.asks + 1
    if ms.asks > MS.ASK_FRAMES then ms.phase = "off" end
    return
  end
  if k == "" then
    ms.phase = "off"
    return
  end
  if VRFW.host.command(MS.HAS_SAVE, 1) ~= true then
    MS_Log("scene", k, "skipped: no save data (the scene loads the save first)")
    ms.phase = "off"
    return
  end
  local sc = VRFW.host.command(MS.SCENE, k)
  ms.timeout = type(sc) == "table" and tonumber(sc.timeout_ms) and math.floor(sc.timeout_ms / 1000 * 60) or 600
  ms.key, ms.phase, ms.frames = k, "wait_ready", 0
  VRFW.host.command(MS.FADE, 1, 0)
  MS_Log("scene", k, "declared for this menu: black, waiting for the menu to be ready")
end

local function MS_Step()
  if ms.phase == "off" then
    return
  end
  ms.frames = ms.frames + 1
  if ms.phase == "ask" then
    MS_Ask()
  elseif ms.phase == "wait_ready" then
    VRFW.host.command(MS.FADE, 1, 0)
    if MS_Ready() then
      local ok = VRFW.host.command(MS.SET, "requested", ms.key)
      if ok == 1 then
        VRFW.host.command(MS.FADE, 1, 0)
        VRFW.param.set(MS.GO, 1)
        ms.phase, ms.frames = "requested", 0
        MS_Log("black: Options requested from the title (it loads the save, then the map of", ms.key, "loads)")
      elseif ok == 0 then
        MS_Fail("the framework refused the request")
      end
    elseif ms.frames > MS.READY_FRAMES then
      MS_Log("the menu was not ready within", MS.READY_FRAMES, "frames: the retail main menu this time")
      VRFW.host.command(MS.FADE, 0, 0.3)
      ms.phase = "off"
    end
  elseif ms.phase == "requested" then
    VRFW.host.command(MS.FADE, 1, 0)    -- stay black until the title leaves
    if not VRFW.param.has(MS.GO) then
      ms.phase = "handed"
      MS_Log("title_main took the request after", ms.frames, "frame(s)")
    elseif ms.frames > ms.timeout then
      MS_Fail("title_main did not take the request within " .. ms.timeout .. " frames")
    end
  elseif ms.phase == "going_up" then
    MS_Hide()
    -- Native title/menu opening animations may request their own fade-in.
    VRFW.host.command(MS.FADE, 1, 0)
    ms.wait_up = (ms.wait_up or 0) + 1
    if (not MS_Ready() or not VRFW.param.has(MS.TITLE_READY)) and ms.wait_up < 300 then
      return
    end
    if ms.wait_up >= 300 then MS_Log("the title did not report ready within 300 frames: up anyway") end
    if not MS_GoUp(ms.key) and ms.wait_up > 300 + MS.ASK_FRAMES then
      MS_Fail("the framework did not confirm the scene up")
    end
  elseif ms.phase == "up" then
    ms.up_frames = ms.up_frames + 1
    if ms.home_restore ~= nil then
      -- a left / right into or out of the home entry: the row's focus to the tile it keeps
      local to, leave = ms.home_restore, ms.home_leave
      ms.home_restore, ms.home_leave = nil, false
      if leave then
        MS_SetHome(false, "left / right")
        ms.focus_wait = { idx = to, last = ms.up_frames + MS.FOCUS_WAIT_FRAMES }
      end
      ms.own_move = ms.up_frames
      VRFW.host.menu_command(MS.FOCUS_MARK, MS.UPPER, to, true)
    end
    MS_ReportFocus()
    if ms.modes then
      MS_Hide(ms.up_frames % 30 == 0)
      if ms.hot.restore ~= nil then
        -- a left / right between hotspots: the row's focus back on its mode
        ms.own_move = ms.up_frames
        VRFW.host.menu_command(MS.FOCUS_MARK, MS.UPPER, ms.hot.restore, true)
        ms.hot.restore = nil
      end
      MS_ModeFrame()
      MS_HotFrame()
      MS_ScreenFrame()
      MS_DoorFrame()
      MS_FloodFrame()
    elseif ms.up_frames % 30 == 0 then
      MS_Hide(true)
    end
    MS_TagFrame(ms.up_frames % 30 == 0)
    if ms.up_frames % 30 == 0 then
      MS_CloseField()
    end
    if ms.up_frames == 60 then
      MS_Log("scene up for", ms.up_frames, "frames (", math.floor(ms.up_frames / 60), "s )")
    end
  end
end

if VRFW.host ~= nil then
  VRFW.host.on("title_menu_2", "OnInit", {
    id = MS.ID .. ".init",
    phase = "before",
    fn = function()
      ms.phase, ms.frames, ms.asks, ms.key, ms.hide, ms.hidden, ms.up_frames = "ask", 0, 0, nil, {}, {}, 0
      ms.counts, ms.hidden_set, ms.modes, ms.mode_idx, ms.label, ms.cursor_hidden, ms.label_count = {}, {}, false, nil, nil, false, nil
      ms.hot, ms.own_move, ms.screens = { n = 0, list = {}, sel = 1 }, false, {}
      ms.frame_count, ms.frame_open, ms.frame_shown, ms.flood, ms.door = nil, {}, false, nil, nil
      MS_Clear(MS.STORY_PICK)           -- A submenu pick never outlives the title it came from.
      MS_Clear(MS.CHRONICLE_WAIT)
      VRFW.host.command(MS.PENDING, "")           -- a title opened: no menu after a leave is waiting
      ms.close, ms.closed, ms.seen, ms.wait_up = {}, 0, {}, 0
      MS_Clear(MS.GO)    -- A request never outlives the title it came from.
      MS_Clear(MS.OPTIONS)
      MS_Clear(MS.TITLE_READY)          -- set again by this title's title_main once it reads requests
      ms.home_shot, ms.home, ms.home_restore, ms.home_leave, ms.focus_wait = nil, false, nil, false, nil
    end,
  })
  VRFW.host.on("title_menu_2", "Step", {
    id = MS.ID .. ".step",
    phase = "after",
    fn = function()
      local ok, err = pcall(MS_Step)
      if not ok then
        MS_Fail("error " .. tostring(err))
      end
    end,
  })
  -- the home entry: A on the hidden row does nothing (no sound, no request)
  VRFW.host.on("title_menu_2", "OnEnter", {
    id = MS.ID .. ".home_enter",
    phase = "before",
    priority = -100,
    fn = function(a1)
      if ms.phase == "up" and ms.home and a1 == MS.UPPER then
        MS_Log("A on the home entry: nothing")
        return VRFW.host.HALT
      end
    end,
  })
  VRFW.host.on("title_menu_2", "OnBack", {
    id = MS.ID .. ".hotspot_group_back",
    phase = "around",
    fn = function(nxt, ...)
      local h = ms.hot
      if ms.phase == "up" and h and (h.group or "") ~= "" then
        MS_Log("hotspot group", h.group, "left (Back)")
        h.group, h.shot = "", nil
        VRFW.host.command(MS.SOUND, MS.SOUND_MOVE)
        return 1
      end
      return nxt(...)
    end,
  })
  VRFW.host.on("title_menu_2", "OnEnter", {
    id = MS.ID .. ".tile_action",
    phase = "around",
    fn = function(nxt, a1, a2, ...)
      if ms.phase == "up" and a1 == MS.UPPER and ms.hot and ms.hot.active then
        local ok, handled, press = pcall(MS_HotEnter)
        if ok and handled then
          if press then return nxt(a1, a2, ...) end
          return
        end
      end
      if ms.phase == "up" and a1 == MS.UPPER and type(GetTitleMenuItemId) == "function" and ms.actions then
        local ok, item = pcall(GetTitleMenuItemId, a2, true)
        local act = ok and type(item) == "number" and ms.actions[item % 4294967296] or nil
        MS_Clear(MS.LEAVE_WHITE)
        if act and act.leave_white == 1 then
          VRFW.param.set(MS.LEAVE_WHITE, 1)
        end
        if act and act.action == "chronicle_map" then
          MS_Clear(MS.CHRONICLE_WAIT)
          VRFW.param.set(MS.CHRONICLE_WAIT, tonumber(act.ms) or 800)
          if type(act.shot) == "string" and act.shot ~= "" then
            VRFW.host.command(MS.SHOT, ms.key, act.shot)
          end
          MS_Log("tile action chronicle_map: push-in", tostring(act.shot), tonumber(act.ms), "ms, then the Chronicle map")
        elseif act and act.action == "continue_story" then
          local has, saves = VRFW.host.command(MS.STORY_INFO)
          if type(saves) == "number" and saves > 0 then
            MS_Clear(MS.STORY_GO)
            VRFW.param.set(MS.STORY_GO, tonumber(act.ms) or 800)
            if type(act.shot) == "string" and act.shot ~= "" then
              VRFW.host.command(MS.SHOT, ms.key, act.shot)
            end
            MS_Log("tile action continue_story: push-in", tostring(act.shot), tonumber(act.ms), "ms, then the story («Continuar»)")
          else
            MS_Log("tile action continue_story: no story save (", tostring(saves), "): the game's story submenu")
          end
        end
      end
      return nxt(a1, a2, ...)
    end,
  })

  VRFW.host.on("title_menu_2", "OnFunction", {
    id = MS.ID .. ".shot_keys",
    phase = "around",
    fn = function(nxt, a1, a2, ...)
      if a1 == MS.FOCUS_MOVE and ms.phase == "up" and ms.modes then
        local ok, done = pcall(MS_ModeUpDown, a2)
        if ok and done then return end
        return nxt(a1, a2, ...)
      end
      if a1 ~= MS.SHOT_PREV and a1 ~= MS.SHOT_NEXT then
        return nxt(a1, a2, ...)
      end
      if ms.phase == "up" and ms.modes then
        local ok, err = pcall(MS_ModeStep, a1 == MS.SHOT_PREV and -1 or 1)
        if not ok then MS_Log("mode key error:", tostring(err)) end
      elseif ms.phase == "up" then
        local shot = VRFW.host.command(MS.SHOT_STEP, ms.key, a1 == MS.SHOT_PREV and -1 or 1)
        MS_Log("shot key", a1 == MS.SHOT_PREV and "previous" or "next", "-> shot", tostring(shot))
      end
    end,
  })
  VRFW.host.on("title_menu_2", "OnChangeFocus", {
    id = MS.ID .. ".hotspot_keys",
    phase = "around",
    fn = function(nxt, a1, ...)
      -- (a move made here is reported within a few frames; an older mark is stale)
      if ms.own_move and ms.up_frames - ms.own_move <= 5 then
        ms.own_move = false
        local r = table.pack(nxt(a1, ...))
        if ms.phase == "up" and ms.modes then MS_Hide() end
        return table.unpack(r, 1, r.n)
      end
      if ms.phase == "up" and a1 == MS.UPPER and ms.hot and ms.hot.active and ms.hot.n > 1 then
        local new = VRFW.host.menu_command(MS.FOCUS_INDEX, MS.UPPER)
        local _, old = MS_Selected()
        if type(new) == "number" and type(old) == "number" and new ~= old then
          local ok, err = pcall(MS_HotMove, old, new)
          if ok then return end
          MS_Log("hotspot move error:", tostring(err))
        end
      end
      if ms.phase == "up" and ms.modes and ms.home_shot and a1 == MS.UPPER then
        local new = VRFW.host.menu_command(MS.FOCUS_INDEX, MS.UPPER)
        local layer, old = MS_Selected()
        if layer == MS.UPPER and type(new) == "number" and type(old) == "number" and new ~= old then
          local ok, handled = pcall(MS_HomeMove, old, new)
          if ok and handled then return end
          if not ok then MS_Log("home move error:", tostring(handled)) end
        end
      end
      local r = table.pack(nxt(a1, ...))
      if ms.phase == "up" and ms.modes then MS_Hide() end
      return table.unpack(r, 1, r.n)
    end,
  })
  VRFW.host.on("title_menu_2", "OnOpenLayer", {
    id = MS.ID .. ".layers",
    phase = "after",
    fn = function(r, a1, a2)
      if ms.phase ~= "up" and ms.phase ~= "going_up" then
        return
      end
      for _, id in ipairs(ms.hide) do
        if a1 == id then
          VRFW.host.menu_command(MS.VISIBLE, a1, a2 or 0, false)
        end
      end
    end,
  })
end
