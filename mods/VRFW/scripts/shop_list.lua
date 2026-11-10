-- Shop list refresh.

local band = bit32.band

local info, warn = VRFW.logger("shop_list")

-- shop list view fields (v7.2.1)
local DIRTY = 0x1B0          -- u8: rows changed, set by a tab change / list command
local LAST_COUNT = 0x140     -- u32: row count Update saw last
local COUNT = 0x1E0          -- u32: row count
local ROWS, ROW_STRIDE = 0x1E8, 0x18  -- row pointer of row index i: this + ROWS + i * ROW_STRIDE
local SCROLL_A, SCROLL_B = 0xDC, 0x130
local MAX_ROWS = 0x140

local rd = VRFW.memory.read

local view = 0               -- The list view the cache belongs to.
local shown = {}
local frame = nil
local last_logged = nil

local function row_of(this, index)
  local count = rd("u32", this + COUNT) or 0
  if index < 0 or index >= count or index >= MAX_ROWS then return 0 end
  return rd("ptr", this + ROWS + index * ROW_STRIDE) or 0
end

local function update_pre(ev)
  local this = ev.args[1] or 0
  if this ~= view then
    view, shown = this, {}
  end
  local dirty = (rd("u8", this + DIRTY) or 0) ~= 0
  local count_changed = (rd("u32", this + LAST_COUNT) or 0) ~= (rd("u32", this + COUNT) or 0)
  local content = dirty or count_changed
  if content then shown = {} end
  frame = {
    content = content and (dirty and "rows marked changed" or "row count changed") or nil,
    scroll_a = rd("u32", this + SCROLL_A), scroll_b = rd("u32", this + SCROLL_B),
    forced = 0, kept = 0,
  }
  return nil
end

local function update_post(ev)
  local f = frame
  frame = nil
  if f == nil or f.forced == 0 then return nil end
  local this = ev.args[1] or 0
  local cause = f.content
  if cause == nil then
    local moved = rd("u32", this + SCROLL_A) ~= f.scroll_a or rd("u32", this + SCROLL_B) ~= f.scroll_b
    cause = moved and "scroll" or "layout moved"
  end
  local line = string.format("forced refresh (%s): %d of %d row(s) kept", cause, f.kept, f.forced)
  if line ~= last_logged then
    last_logged = line
    VRFW.debug("shop_list: " .. line)
  end
  return nil
end

local function update_item_pre(ev)
  local this, item, index, force = ev.args[1] or 0, ev.args[2] or 0, ev.args[3] or 0, ev.args[4] or 0
  -- not forced: the game refills only the newly focused row, with the row it already shows
  if band(force, 0xFF) == 0 or item == 0 or this ~= view then return nil end
  local row = row_of(this, index)
  local was = shown[item]
  local f = frame
  if f ~= nil then f.forced = f.forced + 1 end
  if f ~= nil and f.content == nil and row ~= 0 and was ~= nil and was.row == row and was.index == index then
    f.kept = f.kept + 1
    return { args = { [4] = 0 } }
  end
  shown[item] = row ~= 0 and { row = row, index = index } or nil
  return nil
end

local function start()
  local ok_u, r_u, e_u = pcall(VRFW.hook.apply, "ShopList.Update")
  local ok_i, r_i, e_i = pcall(VRFW.hook.apply, "ShopList.UpdateItem")
  if ok_u and r_u == true and ok_i and r_i == true then
    VRFW.on("hook:ShopList.Update", update_pre)
    VRFW.on("hook:ShopList.Update:post", update_post)
    VRFW.on("hook:ShopList.UpdateItem", update_item_pre)
    info("on: a forced refresh of the shop list refills only the row instances whose row changed")
  else
    warn(string.format("hooks not installed (update: %s, update item: %s): the shop list refreshes as the game does",
      tostring(ok_u and (r_u == true and "ok" or e_u) or r_u), tostring(ok_i and (r_i == true and "ok" or e_i) or r_i)))
  end
end

start()
