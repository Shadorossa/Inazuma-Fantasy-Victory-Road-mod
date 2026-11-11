
EquipList = EquipList or {}

local info, warn = VRFW.logger("equip_list")

-- The files that declare the disabled rows ([[VRFW.EquipListDisabledRows]]).
local DECLARATION_FOLDERS = { "content/equip_lists" }
-- [item kind] = 1 while a menu that declares the kind is open: the list builder keeps those items.
local KEPT_KINDS_TABLE = "EquipList.KeptKinds"
-- An item's category is a 16-bit number of the item table.
local LAST_KIND = 0xFFFF
-- Disabled rows logged per session.
local LOGGED_ROWS = 20

local u32 = VRFW.ids.unsigned

-- The declarations by menu name: { [menu] = { [item kind] = reason } }.
local function declared()
  if EquipList.by_menu then return EquipList.by_menu end
  local by_menu, count = {}, 0
  local ok, files = pcall(VRFW.files.declarations, DECLARATION_FOLDERS)
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local v = type(f.data) == "table" and f.data.VRFW or nil
    local decls = type(v) == "table" and v.EquipListDisabledRows or nil
    for _, d in ipairs(type(decls) == "table" and decls or {}) do
      local where = tostring(f.mod) .. ": [[VRFW.EquipListDisabledRows]] " .. tostring(d.name)
      if type(d.name) ~= "string" or d.name == "" then
        warn(where .. " has no name (left out)")
      elseif type(d.menu) ~= "string" or d.menu == "" then
        warn(where .. " names no menu (left out)")
      elseif type(d.reason) ~= "string" or d.reason == "" then
        warn(where .. " has no reason (left out)")
      elseif type(d.item_kinds) ~= "table" or #d.item_kinds == 0 then
        warn(where .. " names no item kind (left out)")
      else
        local kinds = by_menu[d.menu] or {}
        for _, kind in ipairs(d.item_kinds) do
          if type(kind) ~= "number" or kind ~= math.floor(kind) or kind < 1 or kind > LAST_KIND then
            warn(where .. ": item kind " .. tostring(kind) .. " is not 1.." .. LAST_KIND .. " (left out)")
          elseif kinds[kind] ~= nil then
            warn(where .. ": item kind " .. tostring(kind) .. " of menu " .. d.menu .. " is already declared (left out)")
          else
            kinds[kind] = d.reason
            count = count + 1
          end
        end
        if next(kinds) ~= nil then by_menu[d.menu] = kinds end
      end
    end
  end
  EquipList.by_menu, EquipList.declared_kinds = by_menu, count
  return by_menu
end

-- The list builder drops every item that fails the equip test, as the game does.
local function keep_nothing()
  EquipList.open = nil
  local ok, e = pcall(VRFW.native.table_clear, KEPT_KINDS_TABLE)
  if not ok then warn(KEPT_KINDS_TABLE .. ": " .. tostring(e)) end
end

-- (menu name) -> n: the list builder keeps the n item kinds declared for the menu (0 = none, or the hook is off)
function EquipList.CmdOpen(menu)
  if not EquipList.hook then return 0 end
  keep_nothing()
  local kinds = type(menu) == "string" and declared()[menu] or nil
  if kinds == nil then return 0 end
  local n = 0
  for kind in pairs(kinds) do
    local ok, e = pcall(VRFW.native.table_set, KEPT_KINDS_TABLE, kind, 1)
    if not ok then
      warn(KEPT_KINDS_TABLE .. ": " .. tostring(e) .. ": menu " .. menu .. " lists no disabled row")
      keep_nothing()
      return 0
    end
    n = n + 1
  end
  EquipList.open = kinds
  if not EquipList.open_logged then
    EquipList.open_logged = true
    info(string.format("menu %s open: %d item kind(s) kept in its lists (first time this session)", menu, n))
  end
  return n
end

-- () -> true: the list builder drops every item that fails the equip test again
function EquipList.CmdClose()
  keep_nothing()
  return true
end

-- (character handle, inventory handle) -> disabled, reason: the item is of a kept kind and fails the character's
-- equip test (the game's own test, asked again: the hook changes only the list builder's call of it).
function EquipList.CmdRow(character, inv)
  local kinds = EquipList.open
  if kinds == nil or type(character) ~= "number" or type(inv) ~= "number" or character == 0 or inv == 0 then
    return false
  end
  local okI, item = pcall(VRFW.item.of_inv, u32(inv))
  if not okI or type(item) ~= "number" then return false end
  local okK, kind = pcall(VRFW.call, "Item.Category", u32(item))
  local reason = okK and kinds[kind] or nil
  if reason == nil then return false end
  local okT, fits = pcall(VRFW.call, "Item.CharaCanEquip", u32(character), u32(inv))
  if not okT then
    if not EquipList.test_failed then
      EquipList.test_failed = true
      warn("the equip test did not answer (" .. tostring(fits) .. "): the rows of the kept kinds are drawn disabled")
    end
    return true, reason
  end
  if fits == true then return false end
  EquipList.logged_rows = (EquipList.logged_rows or 0) + 1
  if EquipList.logged_rows <= LOGGED_ROWS then
    info(string.format("disabled row #%d: character 0x%08X fails the equip test of item 0x%08X (kind %d, inventory 0x%08X)",
      EquipList.logged_rows, u32(character), u32(item), kind, u32(inv)))
  end
  return true, reason
end

local function start()
  local by_menu = declared()
  if next(by_menu) == nil then
    info("no mod declares disabled rows of an equipment list: the list builder is not hooked")
    return
  end
  local ok, on, why = pcall(VRFW.hook.apply, "EquipList.CanEquip")
  if not ok or on ~= true then
    VRFW.error("equip_list: the list builder hook is not installed (" .. tostring(ok and why or on) .. "): items that fail the equip test stay out of the lists")
    return
  end
  EquipList.hook = true
  local names = {}
  for menu in pairs(by_menu) do names[#names + 1] = menu end
  table.sort(names)
  info(string.format("%d item kind(s) declared for %s; list builder hooked", EquipList.declared_kinds, table.concat(names, " ")))
end

start()
