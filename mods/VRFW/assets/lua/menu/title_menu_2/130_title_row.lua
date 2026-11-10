

local TR = {
  HOST = "title_menu_2.upper",
  UPPER = 2250456639,       -- title00_07_item_button_upper
  NAME = 3180406576,
  MENU = 3874253475,        -- title_menu_2
  CURSOR = 24113234,        -- cmn05_01_coursor
  COUNT = VRFW.commands.VRFW_MENU_ENTRY_COUNT,       -- CMND_VRFW_MENU_ENTRY_COUNT (host)
  ENTRY = VRFW.commands.VRFW_MENU_ENTRY,       -- CMND_VRFW_MENU_ENTRY (host, i)
  HIDDEN = VRFW.ids.crc32("CMND_VRFW_MENU_HIDDEN_LIST"),
  TEXT_KEY = VRFW.commands.VRFW_TEXT_GET,     -- CMND_VRFW_TEXT_GET (key)
  TEXT_ID = VRFW.commands.TEXT_GET,     -- CMND_TEXT_GET (id)
  SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,    -- CMND_SET_MENU_TEXT_STRING (layer, node, text, index)
  EXPLAIN = 499981750,      -- _text_explain01 of the flavour balloon
  SOUND = VRFW.commands.SND_PLAY_SE,
  BUZZER = 2086672038,      -- sy0003
  DECIDE = 766561556,       -- sy0080
  OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT,    -- CMND_OPEN_MENU_OBJECT
  IS_MENU = VRFW.commands.IS_EXIST_MENU_OBJECT,     -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
  CHILD = 2039986631,
  INPUT = 1558704558,       -- menu input on / off
  VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,      -- CMND_SET_LAYER_VISIBLE
  MSG = 2289627655, MSG_BUSY = 898725220, MSG_DONE = 682363669,   -- the system message window
  FADE = 609722083, FADE_DONE = 2259183189,   -- (on, seconds) the screen fade to black; it is done
  FOCUS_KEY = VRFW.ids.crc32("vrfw_title_row_focus"),
  -- the players mark after a label (retail gaiji texts: "1", "1-2", "1-3" players)
  GAIJI = {[1] = 3337686268, [2] = 3561086357, [3] = 433723010},
  LIST_NUM = 3252599449,    -- (layer, n): the focusable instances of a layer
  FOCUS_SET = 1778826357,   -- (layer, idx, on): the control focus on / off an instance
  FOCUS_GET = 2603265800,   -- (layer) -> the instance the control focus is on.
  CTRL = 3518307824,        -- CMND_SET_ENABLE_CTRL_FOCUS (layer, on)
  ZONE = 855005857,         -- (layer, idx, on): an instance's pointer zone
  BACK = 1522007426,        -- the retail back sound of the title
  IDX0 = 64,
  EMPTY = 63,               -- List index of an instance the row has no button for.
  ID = "menu_engine.title_row",
  T = "title_menu_2",
}

local tr = {
  ready = false,
  row = nil,
  raw = false,
  co = nil,                 -- the open_menu wait / the locked message
  press = nil,
  restore = nil,
  view = nil,               -- the open group: {key, lo, hi, from} (nil = the row itself)
  focus = nil,
  zone_off = {},
  logged = {},
}

local TR_Log = VRFW.logger.new("title_row")

local function TR_Once(k, ...)
  if not tr.logged[k] then
    tr.logged[k] = true
    TR_Log(...)
  end
end

-- a title item: a number as written, or crc32 of the name
local function TR_Id(s)
  if type(s) == "number" then
    return s
  end
  if type(s) ~= "string" or s == "" then
    return 0
  end
  return tonumber(s) or VRFW.ids.crc32(s)
end

-- a menu_text row (id = crc32 of the key) first, then the text engine's key (a mod's text.toml)
local function TR_Text(key)
  if type(key) ~= "string" or key == "" then
    return ""
  end
  local s = VRFW.host.command(TR.TEXT_ID, VRFW.ids.crc32(key))
  if type(s) ~= "string" or s == "" then
    s = VRFW.host.command(TR.TEXT_KEY, key)
  end
  return type(s) == "string" and s or ""
end

-- the declared buttons, in the menu engine's order
local function TR_Entries()
  local out = {}
  local n = VRFW.host.command(TR.COUNT, TR.HOST)
  if type(n) ~= "number" then
    return out
  end
  for i = 1, n do
    local r = table.pack(VRFW.host.command(TR.ENTRY, TR.HOST, i))
    if type(r[1]) == "string" then
      local e = {key = r[1], text = r[2], kind = r[4], value = tostring(r[5] or ""), order = tonumber(r[12]) or 1000,
                 flavor = r[15], players = tonumber(r[16]) or 1, locked_fn = r[18], locked_text = r[19], gate = r[20],
                 group = type(r[10]) == "string" and r[10] or ""}
      local spr = tostring(r[3] or ""):match("([^:]+)$")
      e.plate = {(r[13] and r[13] ~= "") and VRFW.ids.crc32(r[13]) or 0, (r[14] and r[14] ~= "") and VRFW.ids.crc32(r[14]) or 0,
                 spr and VRFW.ids.crc32(spr) or 0}
      e.item = (type(r[17]) == "string" and r[17] ~= "") and TR_Id(r[17]) or VRFW.ids.crc32(e.key)
      e.as = e.kind == "title" and TR_Id(e.value) or nil
      e.idx = TR.IDX0 + #out
      if e.plate[1] == 0 then
        TR_Once("plate " .. e.key, "button " .. e.key .. " has no [entry.title] plate: its instance keeps the art it had")
      end
      out[#out + 1] = e
    end
  end
  return out
end

-- the game's buttons the mods take out: their title items
local function TR_Hidden()
  local set, any = {}, false
  local s = VRFW.host.command(TR.HIDDEN, TR.HOST)
  if type(s) == "string" then
    for k in string.gmatch(s, "[^,]+") do
      if not string.find(k, ".", 1, true) then
        set[TR_Id(k)] = true
        any = true
      end
    end
  end
  return set, any
end

local function TR_Locked(e)
  if e.kind == "mode" and type(VRFW.mode) == "table" then
    if not VRFW.mode.on(e.value) or not VRFW.mode.unlocked(e.value) then
      return true
    end
  end
  if type(e.locked_fn) == "string" and e.locked_fn ~= "" then
    local f = _G[e.locked_fn]
    if type(f) ~= "function" then
      TR_Once("lockfn " .. e.key, "button " .. e.key .. ": locked function " .. e.locked_fn .. " is not defined (taken as unlocked)")
      return false
    end
    local ok, r = pcall(f, e.key)
    if not ok then
      TR_Once("lockerr " .. e.key, "button " .. e.key .. ": " .. e.locked_fn .. " failed: " .. tostring(r))
      return false
    end
    return r == true
  end
  return false
end

local function TR_Build()
  tr.row = false
  local all = TR_Entries()
  -- the groups' members leave the row (they show in the group's sub-row); a group without members is left out
  local members, entries = {}, {}
  for _, e in ipairs(all) do
    if e.group ~= "" then
      members[e.group] = members[e.group] or {}
      table.insert(members[e.group], e)
    end
  end
  for _, e in ipairs(all) do
    if e.group == "" and (e.kind ~= "group" or members[e.value] ~= nil) then
      entries[#entries + 1] = e
    elseif e.kind == "group" then
      TR_Once("empty " .. e.key, "group " .. e.key .. " has no member: left out of the row")
    end
  end
  local hidden, any_hidden = TR_Hidden()
  if #entries == 0 and not any_hidden then
    return
  end
  local h = VRFW.host.hosts and VRFW.host.hosts[TR.T]
  local L = h and h.L
  local rt3, rt8 = nil, nil
  if L ~= nil then
    pcall(function() rt3, rt8 = L.t3, L.t8 end)
  end
  local place = {}
  if type(rt3) == "table" then
    for p, idx in ipairs(rt3) do
      place[idx] = place[idx] or p
    end
  end
  if any_hidden and type(rt8) ~= "table" then
    TR_Once("nohide", "the retail title items are not readable (VRFW.debug off?): [[hide]] of the game's buttons not applied")
  end
  local get_idx = VRFW.host.original(TR.T, "GetItemListIdx")
  local base, gone, last = {}, {}, 0
  local blen = 0
  for i = 0, 31 do
    local ok, idx = pcall(get_idx, i, true)
    if not ok or type(idx) ~= "number" then
      break
    end
    blen = i + 1
    local id = type(rt8) == "table" and rt8[idx] or nil
    if id ~= nil and hidden[id] then
      gone[idx] = true
    else
      local o = place[idx] and place[idx] * 100 or (type(rt3) == "table" and last + 1 or (i + 1) * 100)
      last = o
      base[#base + 1] = {pos = i, idx = idx, order = o}
    end
  end
  local row, j = {}, 1
  for _, b in ipairs(base) do
    while j <= #entries and entries[j].order < b.order do
      row[#row + 1] = {e = entries[j]}
      j = j + 1
    end
    row[#row + 1] = b
  end
  for k = j, #entries do
    row[#row + 1] = {e = entries[k]}
  end
  local n = type(GetItemButtonNum) == "function" and GetItemButtonNum(true) or #row
  if type(n) ~= "number" then
    n = #row
  end
  if #row ~= n then
    TR_Log("WARN the row has " .. #row .. " buttons and the title " .. n .. " upper instances (the served row was not fitted): " ..
      (#row > n and "the last declared buttons are left out" or "the last instances stay empty"))
    while #row > n do
      local cut = nil
      for k = #row, 1, -1 do
        if row[k].e ~= nil then cut = k break end
      end
      table.remove(row, cut or #row)
    end
    while #row < n do
      row[#row + 1] = {empty = true}
    end
  end
  local by_idx, by_item, names = {}, {}, {}
  for p, s in ipairs(row) do
    s.at = p - 1
    if s.e ~= nil then
      by_idx[s.e.idx] = s.at
      by_item[s.e.item] = s.e
      s.e.at = s.at
      s.e.lock = TR_Locked(s.e)
      names[#names + 1] = s.e.key .. "@" .. s.at .. (s.e.lock and "(locked)" or "")
    elseif s.idx ~= nil then
      by_idx[s.idx] = s.at
    end
  end
  for _, list in pairs(members) do
    for _, e in ipairs(list) do
      by_item[e.item] = by_item[e.item] or e
    end
  end
  tr.row = {slots = row, by_idx = by_idx, by_item = by_item, gone = gone, blen = blen, n = n, members = members,
            main = {slots = row, by_idx = by_idx}}
  TR_Log("row: " .. #row .. " buttons (" .. #base .. " of the game, " .. #entries .. " declared: " .. table.concat(names, ", ") .. ")")
end

local function TR_Row()
  if not tr.ready or tr.raw then
    return nil
  end
  if tr.row == nil then
    local ok, err = pcall(TR_Build)
    if not ok then
      tr.row = false
      TR_Log("ERROR building the row: " .. tostring(err))
    end
  end
  return tr.row or nil
end

-- the slot at upper position `pos` (nil = not ours: pass on)
local function TR_Slot(pos, upper)
  if upper ~= true or type(pos) ~= "number" then
    return nil
  end
  local r = TR_Row()
  return r and r.slots[pos + 1] or nil
end

local function TR_Shown(r, p)
  local s = r.slots[p + 1]
  return s ~= nil and not s.empty
end

local function TR_Skip(r, to, from)
  if TR_Shown(r, to) then
    return to
  end
  local step = (type(from) == "number" and to < from) and -1 or 1
  for p = to + step, step > 0 and r.n - 1 or 0, step do
    if TR_Shown(r, p) then
      return p
    end
  end
  if type(from) == "number" and TR_Shown(r, from) then
    return from
  end
  for d = 1, r.n do
    if TR_Shown(r, to - d) then
      return to - d
    elseif TR_Shown(r, to + d) then
      return to + d
    end
  end
  return to
end

-- the pointer zone of upper instance p: off while it is empty, on again when it shows a button (changes only)
local function TR_Zone(r, p)
  local off = not TR_Shown(r, p)
  if (tr.zone_off[p] == true) == off then
    return
  end
  tr.zone_off[p] = off or nil
  VRFW.host.menu_command(TR.ZONE, TR.UPPER, p, not off)
end

local function TR_Label(e)
  local s = TR_Text(e.text)
  if s == "" then
    s = e.key
  end
  local g = VRFW.host.command(TR.TEXT_ID, TR.GAIJI[e.players] or TR.GAIJI[1])
  if type(g) == "string" and g ~= "" then
    s = s .. "  " .. g
  end
  return s
end

local function TR_Busy()
  return tr.co ~= nil
end

local function TR_Restore()
  funcLuaMenuCommand(TR.VISIBLE, TR.CURSOR, 0, true)
  funcLuaMenuCommand(TR.INPUT, TR.MENU, true)
end

local function TR_MessageCo(text)
  funcLuaMenuCommand(TR.INPUT, TR.MENU, false)
  funcLuaMenuCommand(TR.VISIBLE, TR.CURSOR, 0, false)
  coroutine.yield()
  funcLuaCommand(TR.MSG, text, 0, 0, 0, 0, 0, false)
  while funcLuaCommand(TR.MSG_BUSY) do
    coroutine.yield()
  end
  while not funcLuaCommand(TR.MSG_DONE) do
    coroutine.yield()
  end
  TR_Restore()
end

local function TR_OpenCo(menu)
  funcLuaMenuCommand(TR.INPUT, TR.MENU, false)
  funcLuaMenuCommand(TR.VISIBLE, TR.CURSOR, 0, false)
  coroutine.yield()
  funcLuaCommand(TR.OPEN_MENU, menu)
  funcLuaCommand(TR.CHILD, false)
  coroutine.yield()
  while funcLuaMenuCommand(TR.IS_MENU, menu) do
    coroutine.yield()
  end
  funcLuaCommand(TR.CHILD, true)
  TR_Restore()
end

local function TR_RootCo(e, menu)
  funcLuaMenuCommand(TR.INPUT, TR.MENU, false)
  funcLuaMenuCommand(TR.VISIBLE, TR.CURSOR, 0, false)
  funcLuaCommand(TR.FADE, 1, 0.3)
  coroutine.yield()
  while not funcLuaCommand(TR.FADE_DONE) do
    coroutine.yield()
  end
  local state = VRFW.host.command(VRFW.commands.VRFW_MENU_SCENE_STATE)
  if state == "up" then
    VRFW.host.command(VRFW.commands.VRFW_MENU_SCENE_SET, "leaving", "title row " .. e.key .. ": root_menu " .. e.value)
  end
  VRFW.param.set(TR.FOCUS_KEY, e.item)
  local how = VRFW.reset.straight({ menu = menu, bgm_stop = true, need_carry = true,
    log = function(text) TR_Log("button " .. e.key .. ": root_menu: " .. text) end })
  TR_Log("button " .. e.key .. ": root_menu " .. e.value .. ": " .. how)
  if how == "refused" then
    VRFW.param.clear(TR.FOCUS_KEY)
    funcLuaCommand(TR.SOUND, TR.BUZZER)
    funcLuaCommand(TR.FADE, 0, 0.3)
    TR_Restore()
    return
  end
  for _ = 1, 900 do
    coroutine.yield()
  end
  TR_Log("button " .. e.key .. ": root_menu: still here 900 frames after the reset")
  funcLuaCommand(TR.FADE, 0, 0.3)
  TR_Restore()
end

local function TR_ModeCo(e)
  while type(VRFW.mode) == "table" and VRFW.mode.busy() do
    VRFW.mode.step()
    coroutine.yield()
  end
end

-- the group's sub-row on the row's instances: its members centred, every other instance empty (hidden)
local function TR_GroupView(r, g)
  local list = r.members[g.value] or {}
  local m = math.min(#list, r.n)
  if #list > r.n then
    TR_Once("cut " .. g.key, "group " .. g.key .. " has " .. #list .. " members and the row " .. r.n .. " instances: the last ones are left out")
  end
  local lo = math.floor((r.n - m) / 2)
  local slots, by_idx = {}, {}
  for p = 0, r.n - 1 do
    local e = list[p - lo + 1]
    if p >= lo and p < lo + m and e ~= nil then
      e.at = p
      e.lock = TR_Locked(e)
      slots[p + 1] = {e = e, at = p}
      by_idx[e.idx] = p
    else
      slots[p + 1] = {empty = true, at = p}
    end
  end
  return {slots = slots, by_idx = by_idx, lo = lo, hi = lo + m - 1}
end

-- the row's instances drawn again for `view` (the row's own or a group's), the focus on instance `focus`
local function TR_Show(r, view, focus, open)
  r.slots, r.by_idx = view.slots, view.by_idx
  tr.view = open
  for p = 0, r.n - 1 do
    funcLuaMenuCommand(TR.VISIBLE, TR.UPPER, p, not r.slots[p + 1].empty)
    TR_Zone(r, p)
    if type(SetupItemButton) == "function" then
      pcall(SetupItemButton, TR.UPPER, p, true)
    end
  end
  funcLuaMenuCommand(TR.LIST_NUM, TR.UPPER, open and (open.hi + 1) or r.n)
  funcLuaMenuCommand(TR.CTRL, TR.UPPER, true)
  local layer, sel = GetSelectItemLayerName(), GetSelectItemIdx()
  if layer ~= nil and sel ~= nil then
    funcLuaMenuCommand(TR.FOCUS_SET, layer, sel, false)
  end
  funcLuaMenuCommand(TR.FOCUS_SET, TR.UPPER, focus, true)
  tr.focus = focus
  if type(OnChangeFocus) == "function" then
    pcall(OnChangeFocus, TR.UPPER)
  end
  if type(SetupItemName) == "function" then
    for p = 0, r.n - 1 do
      pcall(SetupItemName, p, true)
    end
  end
end

local function TR_SwapCo(open)
  funcLuaMenuCommand(TR.INPUT, TR.MENU, false)
  coroutine.yield()
  local r = TR_Row()
  if r then
    if open ~= nil then
      local v = TR_GroupView(r, open.e)
      open.lo, open.hi = v.lo, v.hi
      TR_Show(r, v, v.lo, open)
      TR_Log("group " .. open.e.key .. " open: members at " .. v.lo .. ".." .. v.hi)
    else
      local from = tr.view and tr.view.from or 0
      TR_Show(r, r.main, from, nil)
      TR_Log("group closed: the row again, focus " .. from)
    end
  end
  TR_Restore()
end

local function TR_OpenGroup(e, pos)
  funcLuaCommand(TR.SOUND, TR.DECIDE)
  tr.co = coroutine.create(function() TR_SwapCo({e = e, from = pos}) end)
  return 1
end

local function TR_CloseGroup()
  funcLuaCommand(TR.SOUND, TR.BACK)
  tr.co = coroutine.create(function() TR_SwapCo(nil) end)
  return 1
end

local function TR_Refuse(e)
  funcLuaCommand(TR.SOUND, TR.BUZZER)
  TR_Log("button " .. e.key .. " is locked: refused")
  local text = TR_Text(e.locked_text)
  if text ~= "" and tr.co == nil then
    tr.co = coroutine.create(function() TR_MessageCo(text) end)
  end
  return 1
end

-- a press of declared button `e` (a1, a2 = OnEnter's; nxt = the title's own OnEnter)
local function TR_Press(e, nxt, a1, a2)
  if e.lock or TR_Locked(e) then
    return TR_Refuse(e)
  end
  if type(e.gate) == "string" and e.gate ~= "" then
    local f = _G[e.gate]
    if type(f) ~= "function" then
      TR_Log("button " .. e.key .. ": gate " .. e.gate .. " is not defined: refused")
      funcLuaCommand(TR.SOUND, TR.BUZZER)
      return 1
    end
    local ok, r = pcall(f, e.key)
    if not ok or r ~= true then
      if not ok then
        TR_Log("button " .. e.key .. ": gate " .. e.gate .. " failed: " .. tostring(r))
      end
      return 1
    end
  end
  TR_Log("button " .. e.key .. " pressed: " .. tostring(e.kind) .. " " .. e.value)
  if e.kind == "open_menu" then
    funcLuaCommand(TR.SOUND, TR.DECIDE)
    local m = VRFW.ids.crc32(e.value)
    tr.co = coroutine.create(function() TR_OpenCo(m) end)
    return
  elseif e.kind == "root_menu" then
    funcLuaCommand(TR.SOUND, TR.DECIDE)
    local m = VRFW.ids.crc32(e.value)
    tr.co = coroutine.create(function() TR_RootCo(e, m) end)
    return
  elseif e.kind == "lua" then
    local f = _G[e.value]
    if type(f) ~= "function" then
      TR_Log("button " .. e.key .. ": function " .. e.value .. " is not defined")
      funcLuaCommand(TR.SOUND, TR.BUZZER)
      return 1
    end
    return f(e.key, a2)
  elseif e.kind == "command" then
    funcLuaCommand(TR.SOUND, TR.DECIDE)
    VRFW.host.command(VRFW.ids.crc32(e.value), e.key)
    return
  elseif e.kind == "title" then
    -- the retail press of that title item, from this position; the title focuses this button when it comes back
    VRFW.param.set(TR.FOCUS_KEY, e.item)
    tr.press = {pos = a2, id = e.as}
    local r = table.pack(pcall(nxt, a1, a2))
    tr.press = nil
    if not r[1] then
      VRFW.param.clear(TR.FOCUS_KEY)
      error(r[2], 0)
    end
    if r[2] == 1 then
      VRFW.param.clear(TR.FOCUS_KEY)
    end
    return table.unpack(r, 2, r.n)
  elseif e.kind == "group" then
    return TR_OpenGroup(e, a2)
  elseif e.kind == "mode" then
    if type(VRFW.mode) ~= "table" then
      return TR_Refuse(e)
    end
    local ok, code = VRFW.mode.start(e.value, "title_row", a2, {
      before = function()
        funcLuaMenuCommand(TR.INPUT, TR.MENU, false)
        funcLuaMenuCommand(TR.VISIBLE, TR.CURSOR, 0, false)
      end,
      back = function()
        TR_Restore()
      end,
    })
    if not ok then
      TR_Log("button " .. e.key .. ": mode " .. e.value .. " refused (code " .. tostring(code) .. ")")
      funcLuaCommand(TR.SOUND, TR.BUZZER)
      return 1
    end
    funcLuaCommand(TR.SOUND, TR.DECIDE)
    tr.co = coroutine.create(function() TR_ModeCo(e) end)
    return
  end
  TR_Log("button " .. e.key .. ": action " .. tostring(e.kind) .. " is not one the title row runs")
  funcLuaCommand(TR.SOUND, TR.BUZZER)
  return 1
end

VRFW.title_row = VRFW.title_row or {}

-- true = title item `id` is a declared button whose action runs inside the title (the title is still there after it)
function VRFW.title_row.stays(id)
  local r = TR_Row()
  local e = r and r.by_item[id]
  return e ~= nil and e.kind ~= "title"
end

function VRFW.title_row.item(key)
  for _, e in ipairs(TR_Entries()) do
    if e.key == key then
      return e.item
    end
  end
  return nil
end

function VRFW.title_row.retail(fn, ...)
  local was = tr.raw
  tr.raw = true
  local r = table.pack(pcall(fn, ...))
  tr.raw = was
  if not r[1] then
    error(r[2], 0)
  end
  return table.unpack(r, 2, r.n)
end

-- the title items of the game's buttons the mods take out of the row (set: item id -> true)
function VRFW.title_row.hidden_items()
  return (TR_Hidden())
end

function VRFW.title_row.position(key)
  local r = TR_Row()
  if not r then
    return nil
  end
  for _, s in ipairs(r.slots) do
    if s.e ~= nil and s.e.key == key then
      return s.at
    end
  end
  return nil
end

local function on(point, phase, fn)
  if type(_ENV[point]) == "function" then
    VRFW.host.on(TR.T, point, { id = TR.ID, phase = phase, fn = fn })
  end
end

if VRFW.host ~= nil and type(GetItemListIdx) == "function" and type(OnEnter) == "function" and type(Step) == "function" then
  on("OnInit", "around", function(nxt, ...)
    tr.ready, tr.row, tr.co, tr.press, tr.restore, tr.view = false, nil, nil, nil, nil, nil
    tr.focus, tr.zone_off = nil, {}
    if VRFW.param.has(TR.FOCUS_KEY) then
      local v = VRFW.param.get(TR.FOCUS_KEY)
      VRFW.param.clear(TR.FOCUS_KEY)
      if type(v) == "number" and v < 0 then
        v = v + 4294967296
      end
      if type(v) == "number" and v ~= 0 then
        tr.restore = {item = v}
      end
    end
    local r = table.pack(nxt(...))
    tr.restore = nil
    return table.unpack(r, 1, r.n)
  end)

  -- the instances are known: the row can be laid out (after the online guard's own pass on this point)
  on("SetupItemButtonNum", "after", function()
    tr.ready, tr.row, tr.view = true, nil, nil
    tr.focus, tr.zone_off = nil, {}
  end)

  -- an instance laid out (OnOpenLayer, a group swap): an empty one has no pointer zone, a shown one has it again
  on("SetupItemButton", "after", function(_, a1, a2, a3)
    if a1 == TR.UPPER and a3 == true and type(a2) == "number" then
      local r = TR_Row()
      if r then
        TR_Zone(r, a2)
      end
    end
  end)

  on("OnChangeFocus", "around", function(nxt, a1, a2, ...)
    local r = a1 == TR.UPPER and TR_Row() or nil
    if r then
      local at = VRFW.host.menu_command(TR.FOCUS_GET, a1)
      if type(at) ~= "number" then
        at = a2
      end
      if type(at) == "number" then
        local to = TR_Skip(r, at, tr.focus)
        if to ~= at then
          funcLuaMenuCommand(TR.FOCUS_SET, a1, at, false)
          funcLuaMenuCommand(TR.FOCUS_SET, a1, to, true)
          TR_Once("skip " .. at .. ">" .. to, "focus on empty instance " .. at .. ": moved on to " .. to)
          if type(a2) == "number" then
            a2 = to
          end
        end
        tr.focus = to
      end
    end
    if a2 == nil and select("#", ...) == 0 then
      return nxt(a1)
    end
    return nxt(a1, a2, ...)
  end)

  on("GetItemListIdx", "around", function(nxt, a1, a2)
    local s = TR_Slot(a1, a2)
    if s == nil then
      return nxt(a1, a2)
    elseif s.e ~= nil then
      return s.e.idx
    elseif s.empty then
      return TR.EMPTY
    end
    return nxt(s.pos, true)
  end)

  on("GetTextureNameItemButton", "around", function(nxt, a1, a2, a3)
    local s = TR_Slot(a1, a3)
    if s ~= nil and s.e ~= nil then
      return s.e.plate[a2] or 0
    elseif s ~= nil and s.empty then
      return 0
    end
    return nxt(a1, a2, a3)
  end)

  on("IsEnableMenuItemButton", "around", function(nxt, a1, a2)
    local s = TR_Slot(a1, a2)
    if s ~= nil and s.e ~= nil then
      return not s.e.lock
    elseif s ~= nil and s.empty then
      return false
    end
    return nxt(a1, a2)
  end)

  on("GetTextNameItemName", "around", function(nxt, a1, a2)
    local s = TR_Slot(a1, a2)
    if s ~= nil and (s.e ~= nil or s.empty) then
      return 0
    end
    return nxt(a1, a2)
  end)

  -- a1 = the label instance (upper ones = their position), a2 = upper
  on("GetTextItemName", "around", function(nxt, a1, a2)
    local s = TR_Slot(a1, a2)
    if s ~= nil and s.e ~= nil then
      return TR_Label(s.e)
    elseif s ~= nil and s.empty then
      return " "
    end
    return nxt(a1, a2)
  end)

  on("GetPlayableModeGaiji", "around", function(nxt, a1, a2)
    local s = TR_Slot(a1, a2)
    if s ~= nil and s.e ~= nil then
      return TR.GAIJI[s.e.players] or TR.GAIJI[1]
    elseif s ~= nil and s.empty then
      return 0
    end
    return nxt(a1, a2)
  end)

  on("GetTitleMenuItemId", "around", function(nxt, a1, a2)
    if tr.press ~= nil and a2 == true and a1 == tr.press.pos then
      return tr.press.id
    end
    local s = TR_Slot(a1, a2)
    local id
    if s ~= nil and s.e ~= nil then
      id = s.e.item
    elseif s ~= nil and s.empty then
      return 0
    else
      id = nxt(a1, a2)
    end
    -- the way back from a "title" press: this button stands for the request it made, the item it pressed does not
    local back = tr.restore
    if back ~= nil then
      local r = TR_Row()
      local e = r and r.by_item[back.item]
      if e ~= nil and e.as ~= nil then
        if s ~= nil and s.e == e then
          return e.as
        elseif id == e.as then
          return 0
        end
      end
    end
    return id
  end)

  on("GetLayerNameFromItemListIdx", "around", function(nxt, a1)
    local r = TR_Row()
    if r then
      if r.by_idx[a1] ~= nil then
        return TR.UPPER
      elseif r.gone[a1] then
        return 0
      end
    end
    return nxt(a1)
  end)

  on("GetLayerIndexFromItemListIdx", "around", function(nxt, a1)
    local r = TR_Row()
    if r then
      if r.by_idx[a1] ~= nil then
        return r.by_idx[a1]
      elseif r.gone[a1] then
        return 0
      end
    end
    return nxt(a1)
  end)

  -- the slide animation of a position the title's table does not reach: none
  on("GetOffsetAnimeItemAttachLocator", "around", function(nxt, a1, a2)
    local v = nxt(a1, a2)
    if v == nil then
      return 0
    end
    return v
  end)

  -- the balloon: a declared button's own text; a game button's from its own place in the title's table
  on("SetFlavorBalloonText", "around", function(nxt, ...)
    local r = TR_Row()
    if r and type(GetSelectItemLayerName) == "function" and GetSelectItemLayerName() == TR.UPPER then
      local sel = GetSelectItemIdx()
      local s = r.slots[(sel or -1) + 1]
      if s ~= nil and s.e ~= nil then
        local text = TR_Text(s.e.flavor)
        if text ~= "" and type(GetCurrentVisibleFlavorLayer) == "function" then
          funcLuaMenuCommand(TR.SET_TEXT, GetCurrentVisibleFlavorLayer(), TR.EXPLAIN, text, 0)
        end
        return
      elseif s ~= nil and s.empty then
        return
      elseif s ~= nil and s.pos ~= sel and type(SetSelectItemLayerInfo) == "function" then
        SetSelectItemLayerInfo(TR.UPPER, s.pos)
        tr.raw = true
        local res = table.pack(pcall(nxt, ...))
        tr.raw = false
        SetSelectItemLayerInfo(TR.UPPER, sel)
        if not res[1] then
          error(res[2], 0)
        end
        return table.unpack(res, 2, res.n)
      end
    end
    return nxt(...)
  end)

  -- the labels: the title tells upper from lower by the length of its own table; the row's length decides
  on("OnOpenLayer", "after", function(_, a1, a2)
    if a1 ~= TR.NAME or type(a2) ~= "number" then
      return
    end
    local r = TR_Row()
    if r and (a2 < r.blen) ~= (a2 < r.n) and type(SetupItemName) == "function" then
      SetupItemName(a2, a2 < r.n)
    end
  end)

  on("OnEnter", "around", function(nxt, a1, a2)
    if TR_Busy() then
      return 1
    end
    if a1 == TR.UPPER and type(a2) == "number" then
      local r = TR_Row()
      if r then
        local s = r.slots[a2 + 1]
        if s ~= nil and s.empty then
          funcLuaCommand(TR.SOUND, TR.BUZZER)
          return 1
        end
        -- by title item: a press another title code forces on any position (top-bar hand-offs) reaches the button too
        local id = GetTitleMenuItemId(a2, true)
        local e = r.by_item[id]
        if e ~= nil then
          return TR_Press(e, nxt, a1, a2)
        end
      end
    end
    return nxt(a1, a2)
  end)

  on("OnBack", "around", function(nxt, ...)
    if TR_Busy() then
      return 1
    end
    if tr.view ~= nil then
      return TR_CloseGroup()
    end
    return nxt(...)
  end)

  on("OnFunction", "around", function(nxt, ...)
    if TR_Busy() then
      return
    end
    return nxt(...)
  end)

  on("Step", "after", function()
    if tr.co ~= nil then
      local ok, err = coroutine.resume(tr.co)
      if not ok then
        TR_Log("ERROR " .. tostring(err))
        pcall(TR_Restore)
      end
      if not ok or coroutine.status(tr.co) == "dead" then
        tr.co = nil
      end
    end
  end)
end
