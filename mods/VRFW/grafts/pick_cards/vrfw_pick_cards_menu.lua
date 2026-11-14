-- vrfw_pick_cards_menu (plain Lua 5.2 source)
INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_SAVEDATA_MANAGEMENT_MENU_INC")   -- header helpers (soccer top inc)

local MENU = 234125520
local KEY_RESULT = 3913043416
local CMD_CARDS = @crc:CMND_VRFW_PICK_CARDS@
local CMD_CHARA_INFO = @crc:CMND_GET_CHARA_INFO@ -- (chara_param, 0) -> ok, name

local L_ROW = 3455690937        -- save01_02_list_item (1 instance: the input anchor, off screen)
local L_HEADER = 575058101      -- mainmenu90_01_header (off)
local L_GUIDE_LINE = 3078308064 -- mainmenu90_05_content_guide_line01 (off)
local L_CURSOR = 2296367164     -- cmn05_01_cursor (off)
local L_BTN_GUIDE = 1138543975  -- mainmenu01_06_base_button_guide
local L_BTN = 9396745           -- mainmenu01_07_button_guide
local L_RET = 2005383485        -- mainmenu01_10_return_arrow_button_guide
local L_RETAIL_BG = 367379312
local L_PLATE = 2153900801
local L_FACE = 785015734        -- vrfw_pc_face  x3: the players' portraits (VRFW.face_icon.card)
local L_TEXT = 274054934        -- vrfw_pc_text  x64 (save01_02_list_item): every text line
local N = {PLATE = 48, FACE = 3, TEXT = 64}

local C = {
  DRAW_PRIORITY = @crc:CMND_SET_DRAW_PRIORITY@,   -- (layer, instance, priority, children)
  TEXT = @crc:CMND_SET_MENU_TEXT_STRING@, MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@, LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@, ALPHA = @crc:CMND_SET_LAYER_MODEL_ALPHA@,
  ATTACH_TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, OPEN_LAYER = @crc:CMND_OPEN_LAYER@,
  GUIDE_SET = 2209673388, GUIDE_CMD = 452337289, GUIDE_OPT = 1432240275,
  SE = @crc:CMND_SND_PLAY_SE@, CLOSE_MENU = @crc:CMND_CLOSE_MENU_OBJECT@,
  TEXT_VISIBLE = @crc:CMND_SET_MENU_TEXT_VISIBLE@,
  MSG_BUSY = 898725220, FREE_CURSOR = @crc:CMND_SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE@,
}
local CUR = 3313461902
local FN = {LEFT = 1371144121, RIGHT = 1161120078, UP = 2985797217, DOWN = 924944618}
local T_CHOOSE, T_SKIP = 2572112352 --[[VRFW.PickCards.Choose]], 2232040966 --[[VRFW.PickCards.Skip]]
local I_ENTER, K_ENTER = 2750714971 --[[<CMD_ENTER>]], 1981080283
local I_BACK, K_BACK = 1582778933 --[[<CMD_BACK>]], 3011112225
local SE_OK, SE_DECIDE, SE_BACK, SE_NG = 3848881948, 4235359837, 202039849, 2086672038
local ROW_MESHES = {3025401186, 486732393, 376662541, 3232607807, 1516082254, 3292070381, 1712955010}
local TEXT_ON, TEXT_OFF = 931545948 --[[_text_list01_on: light]], 3705682548 --[[_text_list01_off: dark]]
local TEXT_DX = 226             -- the list item's text node starts this far right of its origin
local CHAR_W = 15               -- the width of one letter at scale 1
local WRAP_W = 21

-- the layout (screen px at 1080p, y down) and the draw priorities (over the menu under the screen)
local LO = {
  title_y = 150, subtitle_y = 200, top = 250, card_w = 420, card_h = 560, gap = 60, view = 3, border = 6, focus = 16,
  face_y = 150, face = 210, icon = 160, name_y = 292, sub_y = 330, line_y = 372, line_dy = 34, desc_dy = 30,
  desc_lines = 4, badge_h = 52, skip_y = 905, skip_w = 360, skip_h = 70, arrow = 64,
  prio = {dim = 1001, focus = 1002, frame = 1002, card = 1003, part = 1004, text = 1006},
}

-- The screen's pictures by ROLE.
local ART_SCREEN = "pick_cards"
local FALLBACK = {
  dim = {"square", {0, 0, 0}},
  card = {"square", {0.06, 0.12, 0.26}},
  card_disabled = {"square", {0.16, 0.16, 0.18}},
  focus = {"square", {1, 0.84, 0.25}},
  rarity_0 = {"square", {0.55, 0.60, 0.70}},
  rarity_1 = {"square", {0.70, 0.74, 0.80}},     -- common
  rarity_2 = {"square", {0.25, 0.55, 0.95}},     -- rare
  rarity_3 = {"square", {0.62, 0.32, 0.90}},     -- epic
  rarity_4 = {"square", {1.00, 0.62, 0.12}},     -- legendary
  rarity_5 = {"square", {0.95, 0.22, 0.30}},     -- mythic
  band = {"square", {0.10, 0.20, 0.42}},
  badge = {"square", {0.02, 0.05, 0.12}},
  icon_ground = {"circle", {0.14, 0.25, 0.50}},
  skip = {"square", {0.10, 0.20, 0.42}},
  skip_focus = {"square", {1, 0.84, 0.25}},
  arrow_l = {"arrow_l", {1, 1, 1}},
  arrow_r = {"arrow_r", {1, 1, 1}},
}
local FALLBACK_ANY = {"square", {1, 1, 1}}

local HEAD = nil
local cards = {}
local sel, first = 1, 1 -- the selection (count + 1 = the skip), the first card in view
local zones = {}        -- id -> {x, y, hw, hh}: the hit areas of the last drawing
local used = {plate = 0, text = 0, face = 0, plate_was = 0, text_was = 0, face_was = 0}
local ready, open_guard, vrfw_co, closing = false, 20, nil, nil

local Log                       -- set in OnInit

--@lib vrfw_menu_kit.lua#Call,Int

--@lib vrfw_menu_kit.lua#Pointer,Keys
local Kit, Ptr                  -- set in OnInit

local function count()
  return HEAD ~= nil and Int(HEAD.count) or 0
end

local function skip_on()
  return HEAD ~= nil and HEAD.skip == true
end

-- Draws the next plate of the pool.
local function Plate(role, x, y, w, h, priority, alpha)
  if used.plate >= N.PLATE then
    return nil
  end
  local idx = used.plate
  used.plate = used.plate + 1
  Kit.art_quad(L_PLATE, idx, role, x + w / 2, y + h / 2, w, h)
  pcall(funcLuaMenuCommand, C.DRAW_PRIORITY, L_PLATE, idx, priority or LO.prio.card, true)
  pcall(funcLuaMenuCommand, C.ALPHA, L_PLATE, idx, 0, alpha or 1)
  return idx
end

-- a mod's icon (atlas + sprite) centred on (x, y)
local function Icon(atlas, sprite, x, y, size)
  if used.plate >= N.PLATE or atlas == "" or sprite == "" then
    return
  end
  local tc = Kit.texture(atlas)
  if not tc then
    return
  end
  local idx = used.plate
  used.plate = used.plate + 1
  Kit.textured_quad(L_PLATE, idx, tc, CRC32(sprite), x, y, size, size)
  pcall(funcLuaMenuCommand, C.DRAW_PRIORITY, L_PLATE, idx, LO.prio.part, true)
  pcall(funcLuaMenuCommand, C.ALPHA, L_PLATE, idx, 0, 1)
end

-- the width of a text at `scale` (CJK letters count twice)
local function Units(s) return VRFW.text_fold.units(s) end

-- Draws the next text line of the pool.
local function Line(s, x, y, scale)
  if s == nil or s == "" or used.text >= N.TEXT then
    return
  end
  local idx = used.text
  used.text = used.text + 1
  Kit.show(L_TEXT, idx)
  Kit.scale(L_TEXT, idx, scale, scale)
  funcLuaMenuCommand(C.TEXT, L_TEXT, TEXT_ON, s, idx)
  funcLuaMenuCommand(C.TEXT_VISIBLE, L_TEXT, TEXT_ON, true, idx)
  funcLuaMenuCommand(C.TEXT_VISIBLE, L_TEXT, TEXT_OFF, false, idx)
  pcall(funcLuaMenuCommand, C.DRAW_PRIORITY, L_TEXT, idx, LO.prio.text, true)
  Kit.place(L_TEXT, idx, x - TEXT_DX * scale, y)
end

-- a line centred on cx
local function LineC(s, cx, y, scale)
  Line(s, cx - Units(s) * CHAR_W * scale / 2, y, scale)
end

local function Wrap(s, w, scale)
  local max = math.max(4, math.floor(w / (WRAP_W * scale)))
  local out, cur = {}, ""
  for part in string.gmatch(s, "[^\n]+") do
    for word in string.gmatch(part, "%S+") do
      if Units(word) > max then
        for ch in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
          if Units(cur .. ch) > max then
            out[#out + 1] = cur
            cur = ""
          end
          cur = cur .. ch
        end
      else
        local nxt = cur == "" and word or (cur .. " " .. word)
        if Units(nxt) > max and cur ~= "" then
          out[#out + 1] = cur
          cur = word
        else
          cur = nxt
        end
      end
    end
    if cur ~= "" then
      out[#out + 1] = cur
      cur = ""
    end
  end
  return out
end

-- the portrait of player card `card` centred on (x, y)
local function Face(card, x, y, size)
  if VRFW.face_icon == nil or used.face >= N.FACE or card == 0 then
    return
  end
  local idx = used.face
  used.face = used.face + 1
  Kit.show(L_FACE, idx)
  VRFW.face_icon.card(L_FACE, idx, {card = card}, x, y, size)
  Kit.forget(L_FACE, idx, "pos")  -- face_icon placed it
  pcall(funcLuaMenuCommand, C.DRAW_PRIORITY, L_FACE, idx, LO.prio.part, true)
end

local function HideRest()
  for i = used.plate, used.plate_was - 1 do
    Kit.hide_off_screen(L_PLATE, i)
  end
  for i = used.text, used.text_was - 1 do
    Kit.hide_off_screen(L_TEXT, i)
  end
  for i = used.face, used.face_was - 1 do
    Kit.hide_off_screen(L_FACE, i)
    if VRFW.face_icon ~= nil then
      VRFW.face_icon.forget(L_FACE, i)
    end
  end
  used.plate_was, used.text_was, used.face_was = used.plate, used.text, used.face
end

local function Load()
  HEAD = Call(CMD_CARDS, 0)
  cards = {}
  if type(HEAD) ~= "table" then
    HEAD = nil
    return
  end
  for i = 1, count() do
    local c = Call(CMD_CARDS, i)
    if type(c) ~= "table" then
      c = {kind = "text", title = "?"}
    end
    c.lines = type(c.lines) == "table" and c.lines or {}
    -- Handles a player card.
    if Int(c.card) ~= 0 then
      local _, name = Call(CMD_CHARA_INFO, c.card, 0)
      name = type(name) == "string" and name or ""
      if c.title == nil or c.title == "" then
        c.title = name
      end
      local function fill(v)
        return type(v) == "string" and (v:gsub("{name}", function() return name end)) or v
      end
      c.title, c.subtitle, c.desc, c.badge = fill(c.title), fill(c.subtitle), fill(c.desc), fill(c.badge)
      for k, l in ipairs(c.lines) do
        c.lines[k] = fill(l)
      end
    end
    cards[i] = c
  end
end

local function CardX(k)
  local total = LO.view * LO.card_w + (LO.view - 1) * LO.gap
  local x0 = (1920 - total) / 2
  return x0 + (k - 1) * (LO.card_w + LO.gap)
end

local function DrawCard(i, k)
  local c = cards[i]
  local x, y, w, h = CardX(k), LO.top, LO.card_w, LO.card_h
  local cx = x + w / 2
  local on = sel == i
  if on then
    Plate("focus", x - LO.focus, y - LO.focus, w + 2 * LO.focus, h + 2 * LO.focus, LO.prio.focus)
  end
  Plate("rarity_" .. Int(c.rarity), x - LO.border, y - LO.border, w + 2 * LO.border, h + 2 * LO.border, LO.prio.frame)
  Plate(c.disabled == true and "card_disabled" or "card", x, y, w, h, LO.prio.card)
  local py = y + LO.face_y
  if c.kind == "player" then
    Face(Int(c.card), cx, py, LO.face)
  elseif c.kind == "item" then
    Plate("icon_ground", cx - LO.icon / 2 - 10, py - LO.icon / 2 - 10, LO.icon + 20, LO.icon + 20, LO.prio.part)
    Icon(tostring(c.icon_atlas or ""), tostring(c.icon_sprite or ""), cx, py, LO.icon)
  else
    Plate("band", x + 30, py - 50, w - 60, 100, LO.prio.part)
  end
  LineC(tostring(c.title or ""), cx, y + LO.name_y, 0.9)
  LineC(tostring(c.subtitle or ""), cx, y + LO.sub_y, 0.68)
  local ly = y + LO.line_y
  for _, l in ipairs(c.lines) do
    LineC(tostring(l), cx, ly, 0.62)
    ly = ly + LO.line_dy
  end
  local desc = tostring(c.desc or "")
  if desc ~= "" then
    local lines = Wrap(desc, w - 50, 0.58)
    for n = 1, math.min(#lines, LO.desc_lines) do
      local s = lines[n]
      if n == LO.desc_lines and #lines > LO.desc_lines then
        s = s .. "…"
      end
      LineC(s, cx, ly + 6, 0.58)
      ly = ly + LO.desc_dy
    end
  end
  local badge = tostring(c.badge or "")
  if badge ~= "" then
    local by = y + h - LO.badge_h - 16
    Plate("badge", x + 40, by, w - 80, LO.badge_h, LO.prio.part)
    LineC(badge, cx, by + LO.badge_h / 2, 0.72)
  end
  zones[i] = {x = cx, y = y + h / 2, hw = w / 2, hh = h / 2}
end

local function DrawAll()
  if HEAD == nil then
    return
  end
  Kit.begin()
  zones = {}
  used.plate, used.text, used.face = 0, 0, 0
  Plate("dim", 0, 0, 1920, 1080, LO.prio.dim, 0.72)
  LineC(tostring(HEAD.title or ""), 960, LO.title_y, 1.1)
  LineC(tostring(HEAD.subtitle or ""), 960, LO.subtitle_y, 0.75)
  local n = count()
  for k = 1, math.min(LO.view, n) do
    local i = first + k - 1
    if cards[i] ~= nil then
      DrawCard(i, k)
    end
  end
  if n > LO.view then
    local my = LO.top + LO.card_h / 2
    if first > 1 then
      Plate("arrow_l", CardX(1) - LO.gap - LO.arrow, my - LO.arrow / 2, LO.arrow, LO.arrow, LO.prio.part)
      zones.prev = {x = CardX(1) - LO.gap - LO.arrow / 2, y = my, hw = LO.arrow / 2, hh = LO.arrow / 2}
    end
    if first + LO.view - 1 < n then
      local xr = CardX(LO.view) + LO.card_w + LO.gap
      Plate("arrow_r", xr, my - LO.arrow / 2, LO.arrow, LO.arrow, LO.prio.part)
      zones.next = {x = xr + LO.arrow / 2, y = my, hw = LO.arrow / 2, hh = LO.arrow / 2}
    end
  end
  if skip_on() then
    local x, y = 960 - LO.skip_w / 2, LO.skip_y - LO.skip_h / 2
    if sel == n + 1 then
      Plate("skip_focus", x - 8, y - 8, LO.skip_w + 16, LO.skip_h + 16, LO.prio.focus)
    end
    Plate("skip", x, y, LO.skip_w, LO.skip_h, LO.prio.card)
    local label = tostring(HEAD.skip_text or "")
    if label == "" then
      label = Kit.text(T_SKIP)
    end
    LineC(label, 960, LO.skip_y, 0.8)
    zones[n + 1] = {x = 960, y = LO.skip_y, hw = LO.skip_w / 2, hh = LO.skip_h / 2}
  end
  HideRest()
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, false)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_GUIDE_LINE, 0, false)
end

local function UpdateButtonGuide()
  local texts, icons, offs, keys = {T_CHOOSE}, {I_ENTER}, {18}, {K_ENTER}
  if skip_on() then
    texts[2], icons[2], offs[2], keys[2] = T_SKIP, I_BACK, 36, K_BACK
  end
  funcLuaMenuCommand(C.GUIDE_SET, MENU, L_BTN_GUIDE, texts, icons, offs, {}, {})
  funcLuaMenuCommand(C.GUIDE_CMD, MENU, L_BTN_GUIDE, keys)
  funcLuaMenuCommand(C.GUIDE_OPT, MENU, L_BTN_GUIDE, false)
end

local function Select(i)
  local n = count()
  local last = skip_on() and n + 1 or n
  if i < 1 or i > last or i == sel then
    return false
  end
  sel = i
  if i <= n then
    if i < first then
      first = i
    elseif i > first + LO.view - 1 then
      first = i - LO.view + 1
    end
  end
  funcLuaCommand(C.SE, SE_OK)
  DrawAll()
  return true
end

local function Leave(result)
  ready = false
  closing = result
end

local function CloseNow()
  local result = closing
  closing = nil
  pcall(funcLuaMenuCommand, C.FREE_CURSOR, true, false, true)
  VRFW.param.clear(KEY_RESULT)
  VRFW.param.set(KEY_RESULT, result)
  funcLuaCommand(C.CLOSE_MENU, MENU)
  Log("closed, pick", result)
end

local function Decide()
  local n = count()
  if sel == n + 1 and skip_on() then
    funcLuaCommand(C.SE, SE_BACK)
    Log("skip")
    Leave(0)
    return
  end
  local c = cards[sel]
  if c == nil or c.disabled == true then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  Log("pick", sel)
  Leave(sel)
end

local function Back()
  if not skip_on() then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_BACK)
  Log("back: skip")
  Leave(0)
end

local function Move(dir)
  local n = count()
  if dir == "LEFT" then
    if sel <= n then Select(sel - 1) end
  elseif dir == "RIGHT" then
    if sel < n then Select(sel + 1) end
  elseif dir == "DOWN" then
    if skip_on() and sel <= n then Select(n + 1) end
  elseif dir == "UP" then
    if sel == n + 1 then Select(math.min(first, n)) end
  end
end

-- The keys read from the polled pad for a press that no callback reported.
local NAV_KEYS = {LEFT = VRFW.keys.LEFT, RIGHT = VRFW.keys.RIGHT, UP = VRFW.keys.UP, DOWN = VRFW.keys.DOWN,
                  ENTER = VRFW.keys.ENTER, BACK = VRFW.keys.BACK}

local function Act(name)
  if name == "ENTER" then
    Decide()
  elseif name == "BACK" then
    Back()
  else
    Ptr.key_step()
    Move(name)
  end
end

local function PollPointer()
  local ev = Kit.poll_pointer(zones)
  if vrfw_co ~= nil or not ready or open_guard > 0 then
    return
  end
  if type(ev.hover) == "number" and ev.hover ~= sel then
    Select(ev.hover)
  end
  if ev.click == "prev" or ev.click == "next" then
    Kit.key_reported("ENTER")
    Move(ev.click == "prev" and "LEFT" or "RIGHT")
  elseif type(ev.click) == "number" then
    Kit.key_reported("ENTER")
    Select(ev.click)
    Decide()
  elseif type(ev.wheel) == "number" then
    Move(ev.wheel < 0 and "LEFT" or "RIGHT")
  end
end

function OnInit()
  Log = VRFW.logger.new("pick_cards")
  Kit = VRFW.screen_kit.new({log = Log, art = VRFW.screen_art.get(ART_SCREEN), fallback = FALLBACK, fallback_any = FALLBACK_ANY})
  Ptr = Kit.pointer()
  VRFW.param.clear(KEY_RESULT)
  for _, path in ipairs(VRFW.screen_art.atlases(ART_SCREEN)) do
    Kit.texture(path)
  end
  ready, open_guard, closing, zones = false, 20, nil, {}
  used = {plate = 0, text = 0, face = 0, plate_was = N.PLATE, text_was = N.TEXT, face_was = N.FACE}
  if VRFW.face_icon ~= nil then
    VRFW.face_icon.forget(L_FACE)
  end
  Load()
  local n = count()
  sel = HEAD ~= nil and math.max(1, math.min(n, Int(HEAD.focus))) or 1
  first = math.max(1, math.min(sel, n - LO.view + 1))
  Log("open", n, "card(s), skip", tostring(skip_on()))
end

local function OpenOwnLayers()
  for i = 0, N.PLATE - 1 do
    funcLuaMenuCommand(C.OPEN_LAYER, L_PLATE, i)
  end
  for i = 0, N.TEXT - 1 do
    funcLuaMenuCommand(C.OPEN_LAYER, L_TEXT, i)
  end
  for i = 0, N.FACE - 1 do
    funcLuaMenuCommand(C.OPEN_LAYER, L_FACE, i)
  end
end

function OnSetupLayer(a1, a2)
  Kit.forget()                  -- a layer that (re)opens has none of the commands sent so far
  if a1 == L_HEADER then
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_HEADER, 0, false)
    OpenOwnLayers()
  elseif a1 == L_ROW or a1 == L_TEXT then
    funcLuaMenuCommand(C.TEXT, a1, TEXT_ON, "", a2)
    funcLuaMenuCommand(C.TEXT, a1, TEXT_OFF, "", a2)
    funcLuaMenuCommand(C.TEXT_VISIBLE, a1, TEXT_ON, false, a2)
    funcLuaMenuCommand(C.TEXT_VISIBLE, a1, TEXT_OFF, false, a2)
    for _, m in ipairs(ROW_MESHES) do
      funcLuaMenuCommand(C.MESH_VISIBLE, a1, m, false, a2)
    end
    funcLuaMenuCommand(C.ATTACH_TRACE, a1, a2, CUR, false)
    if a1 ~= L_ROW then
      Kit.hide_off_screen(a1, a2)
    end
  elseif a1 == L_PLATE or a1 == L_FACE then
    Kit.hide_off_screen(a1, a2)
  elseif a1 == L_RETAIL_BG or a1 == L_GUIDE_LINE then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, 0, false)
  elseif a1 == L_BTN_GUIDE then
    UpdateButtonGuide()
  end
end

function OnOpenLayer(a1, a2)
  Kit.forget()                  -- a layer that (re)opens has none of the commands sent so far
  if a1 == L_ROW and a2 == 0 then
    Kit.open_list_anchor(a1, L_CURSOR, CUR)
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_RETAIL_BG, 0, false)
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_HEADER, 0, false)
    if HEAD == nil then
      Log("open: no cards set: closing")
      Leave(0)
      return
    end
    UpdateButtonGuide()
    DrawAll()
    Ptr.reset()
    pcall(funcLuaMenuCommand, C.FREE_CURSOR, true, false, true)
    ready = true
  elseif a1 == L_HEADER or a1 == L_RETAIL_BG or a1 == L_GUIDE_LINE then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, 0, false)
  end
end

function OnDecideFocus(a1, a2)
  Kit.key_reported("ENTER")
  if vrfw_co ~= nil or not ready or open_guard > 0 or Ptr.owns() then
    return
  end
  Decide()
end

function OnEnter(a1, a2)
  Kit.key_reported("ENTER")
  if a1 == L_BTN or a1 == L_RET then
    return 1
  end
  OnDecideFocus(a1, a2)
end

function OnFunction(a1, a2)
  local id = a1
  if a1 ~= FN.LEFT and a1 ~= FN.RIGHT and a1 ~= FN.UP and a1 ~= FN.DOWN then
    id = a2
  end
  local name = (id == FN.LEFT and "LEFT") or (id == FN.RIGHT and "RIGHT") or (id == FN.UP and "UP")
    or (id == FN.DOWN and "DOWN") or nil
  if name == nil then
    return
  end
  Kit.key_reported(name)
  if vrfw_co ~= nil or not ready then
    return 1
  end
  Ptr.key_step()
  Move(name)
  return 1
end

function OnBack(a1)
  Kit.key_reported("BACK")
  if vrfw_co ~= nil or not ready or open_guard > 0 then
    return 1
  end
  Back()
  return 1
end

function Step()
  if closing ~= nil then
    CloseNow()
    return
  end
  if not ready then
    return
  end
  if open_guard > 0 then
    open_guard = open_guard - 1
  end
  -- Redraws once every texture being waited for finished loading.
  if Kit.waiting then
    Kit.settle()
    if not Kit.pending() then
      DrawAll()
    end
  end
  PollPointer()
  local free = vrfw_co == nil and open_guard <= 0 and funcLuaCommand(C.MSG_BUSY) ~= true
  Kit.poll_keys(NAV_KEYS, Act, {enabled = free})
end
