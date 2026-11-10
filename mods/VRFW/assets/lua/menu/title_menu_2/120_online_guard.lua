-- online_guard (VRFW, always on): the blocked modes of content\defaults\online_guard.toml leave the title row.
-- * the row: the framework served the title files with one upper button less per blocked item (the row centred again).

local OG = {
  TITLE = VRFW.commands.VRFW_BLOCKED_TITLE,
  LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM,   -- CMND_GET_CREATE_LAYER_NUM (as SetupItemButtonNum asks it)
  UPPER = 2250456639,       -- title00_07_item_button_upper
  MENU = 3874253475,        -- title_menu_2
  INPUT = 1558704558,       -- menu input on / off
  VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,      -- CMND_SET_LAYER_VISIBLE
  SOUND = VRFW.commands.SND_PLAY_SE,       -- play a system sound
  BUZZER = 2086672038,      -- sy0003 (the retail "not available" buzzer)
  ID = "VRFW.online_guard",
}

local og_lists = nil
local og_done = setmetatable({}, { __mode = "k" })   -- the t3 tables already shortened (one chunk = one t3)
local og_grey = false       -- the served row kept the blocked button(s): grey them

local OG_Log = VRFW.logger.new("online_guard, title")

local function OG_Lists()
  if og_lists == nil then
    og_lists = false
    local items, silence, layers, funcs = VRFW.host.command(OG.TITLE)
    if type(items) == "string" then
      local l = { items = {}, silence = {}, layers = {}, funcs = {}, any = false }
      for n in string.gmatch(items, "%d+") do
        l.items[tonumber(n)] = true
        l.any = true
      end
      for n in string.gmatch(tostring(silence or ""), "[^,%s]+") do l.silence[n] = true end
      for n in string.gmatch(tostring(layers or ""), "%d+") do l.layers[tonumber(n)] = true end
      for n in string.gmatch(tostring(funcs or ""), "%d+") do l.funcs[tonumber(n)] = true end
      og_lists = l
    end
  end
  return og_lists
end

local function OG_ItemBlocked(idx, upper)
  local l = OG_Lists()
  if not l or not l.any or type(GetTitleMenuItemId) ~= "function" then
    return false
  end
  local ok, id = pcall(GetTitleMenuItemId, idx, upper)
  return ok and l.items[id] == true
end

-- the blocked items out of the upper row's position tables, as many as the served row lost
local function OG_Row()
  local l = OG_Lists()
  local h = VRFW.host.hosts and VRFW.host.hosts.title_menu_2
  local L = h and h.L
  local t3 = L and L.t3
  if not l or not l.any or type(t3) ~= "table" or og_done[t3] then
    return
  end
  og_done[t3] = true
  local n = funcLuaMenuCommand(OG.LAYER_NUM, OG.UPPER)
  if type(n) ~= "number" then
    return
  end
  local extra = #t3 - n
  local t9, t = L.t9, L.t
  local removed = 0
  for p = #t3, 1, -1 do
    if removed < extra and OG_ItemBlocked(p - 1, true) then
      local id = GetTitleMenuItemId(p - 1, true)
      table.remove(t3, p)
      if type(t9) == "table" and #t9 >= p then table.remove(t9, p) end
      -- t[p] slides the buttons right of position p; the row lost its last locator: the last real slide goes
      if type(t) == "table" and #t >= 2 then table.remove(t, #t - 1) end
      removed = removed + 1
      OG_Log("item " .. tostring(id) .. " (position " .. tostring(p - 1) .. ") left the row")
    end
  end
  -- the buttons the title row takes out are not in the served row either
  local hidden = type(VRFW.title_row) == "table" and VRFW.title_row.hidden_items() or {}
  local missing = extra - removed
  for p = 0, #t3 - 1 do
    local ok, id = pcall(GetTitleMenuItemId, p, true)
    if ok and hidden[id] and not l.items[id] then
      missing = missing - 1
    end
  end
  if missing > 0 then
    OG_Log("ERROR the served row has " .. tostring(missing) .. " upper button(s) less than the tables and no blocked item to take out (a mod reused the blocked mode's slot?)")
  end
  og_grey = false
  for p = 0, #t3 - 1 do
    if OG_ItemBlocked(p, true) then
      og_grey = true
      OG_Log("item at position " .. tostring(p) .. " is blocked but the row kept its button (a mod reshaped the row): greyed out")
    end
  end
end

local function OG_Silence()
  local l = OG_Lists()
  if not l then
    return
  end
  for name in pairs(l.silence) do
    if type(_ENV[name]) == "function" then
      VRFW.host.on("title_menu_2", name, { id = OG.ID, phase = "before", fn = function()
        return VRFW.host.HALT
      end })
    end
  end
end

local function OG_Hide(layer, idx)
  local l = OG_Lists()
  if l and l.layers[layer] then
    funcLuaMenuCommand(OG.VISIBLE, layer, idx or 0, false)
  end
end

local function on(point, phase, fn)
  if type(_ENV[point]) == "function" then
    VRFW.host.on("title_menu_2", point, { id = OG.ID, phase = phase, fn = fn })
  end
end

if VRFW.host ~= nil and type(OnInit) == "function" then
  on("OnInit", "before", function()
    og_lists = nil
    if OG_Lists() then
      OG_Silence()
      OG_Row()
    end
  end)

  -- also here (the count is the one the retail start reads): a no-op when OnInit already did it
  on("SetupItemButtonNum", "after", function()
    OG_Row()
  end)

  on("IsEnableMenuItemButton", "around", function(nxt, a1, a2)
    if og_grey and OG_ItemBlocked(a1, a2) then
      return false
    end
    return nxt(a1, a2)
  end)

  on("OnEnter", "around", function(nxt, a1, a2)
    if og_grey and a1 == OG.UPPER and OG_ItemBlocked(a2, true) then
      funcLuaCommand(OG.SOUND, OG.BUZZER)
      return
    end
    return nxt(a1, a2)
  end)

  on("OnFunction", "around", function(nxt, a1, a2)
    local l = OG_Lists()
    if l and l.funcs[a1] then
      return
    end
    return nxt(a1, a2)
  end)

  on("OnSetupLayer", "after", function(_, a1, a2)
    OG_Hide(a1, a2)
  end)

  on("OnOpenLayer", "after", function(_, a1, a2)
    OG_Hide(a1, a2)
  end)

  on("GetSelectTitleMenuId", "after", function(r)
    local l = OG_Lists()
    if l and l.items[r[1]] then
      OG_Log("request " .. tostring(r[1]) .. " dropped (a blocked mode); the title takes input again")
      r[1] = 0
      funcLuaMenuCommand(OG.INPUT, OG.MENU, true)
    end
  end)
end
