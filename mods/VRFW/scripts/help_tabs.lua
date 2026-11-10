-- Help screen: the Mods tab of the rows the help_entry content type adds.

HelpTabs = HelpTabs or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("help_tabs")

local rd, wr = VRFW.memory.read, VRFW.memory.write

-- tab slots of the game's help list view: one byte per slot, 0xFF = slot off
local VIEW_TAB_SLOTS, TAB_SLOTS, SLOT_OFF = 0xA80, 7, 0xFF
-- the game's help database: rows array and count, row size, category byte
local ROOT_HELP_TABLE, ROWS, ROW_COUNT = 0x820, 0x48, 0x50
local ROW_SIZE, ROW_CATEGORY = 0x38, 0x2E
-- the game's own categories are 0..6; the slots of the full tab bar are 5
local GAME_CATEGORIES, FULL_BAR = 7, 5

local mods_category = nil
local looked_up = false

-- The category of the mods' rows (0 = none), read once from the game's database.
local function category_of_mod_rows()
  if looked_up then return mods_category end
  local root = VRFW.game.global("Game.Root")
  local tbl = root and rd("ptr", root + ROOT_HELP_TABLE)
  local rows = tbl and rd("ptr", tbl + ROWS)
  local n = tbl and rd("i32", tbl + ROW_COUNT)
  if not rows or not n then
    warn("help database not ready")
    return 0
  end
  looked_up = true
  mods_category = 0
  for i = 0, n - 1 do
    local c = rd("u8", rows + i * ROW_SIZE + ROW_CATEGORY)
    if c ~= nil and c >= GAME_CATEGORIES and c ~= SLOT_OFF then
      mods_category = c
      break
    end
  end
  info(mods_category ~= 0 and string.format("Mods tab: category %d", mods_category) or "no mod declares a help entry: no tab")
  return mods_category
end

-- After the game filled the tab slots: the full bar gets the Mods tab in its first free slot.
local function fill_post(ev)
  local view = ev.args[1]
  local category = category_of_mod_rows()
  if category == 0 or not view then return nil end
  local on, free = 0, nil
  for slot = 0, TAB_SLOTS - 1 do
    local v = rd("u8", view + VIEW_TAB_SLOTS + slot)
    if v == nil then return nil end
    if v == SLOT_OFF then
      free = free or slot
    else
      on = on + 1
    end
  end
  if on == FULL_BAR and free ~= nil then
    wr("u8", view + VIEW_TAB_SLOTS + free, category)
  end
  return nil
end

-- CMND_VRFW_HELP_MODS_TAB() -> category (0 = no tab), icon type, title text id
function HelpTabs.ModsTab()
  local category = category_of_mod_rows()
  if category == 0 then return 0, 0, 0 end
  return category, VRFW.config("help_entry.mods_tab_icon", 0), D.id_of(VRFW.config("help_entry.mods_tab_title", ""))
end

local ok, r, e = pcall(VRFW.hook.apply, "HelpTabs.Fill")
if ok and r == true then
  VRFW.on("hook:HelpTabs.Fill:post", fill_post)
else
  warn("detour not installed: " .. tostring(ok and e or r))
end
