-- EVT utilities_formations (mod BetterQoL, feature formations; research/grafts/utilities_formations/graft.toml).
-- The picker's lists are found among the table upvalues of its list functions: the 11-a-side list (main-chunk local t6
-- of soccer_formation_menu_inc) as the table whose every entry is an 11-a-side formation the game offers
-- (CMND_BETTERQOL_FORMATION 1, i); the 5v5 list (t7) as the table whose every entry is a five-a-side formation, offered
-- or unlocked (3 and 2: the game's t7 has no formation item). The unlocked ones (0) are appended in place to t6, the
-- five-a-side ones (3, 2) to t7, which is left in the VM global BetterQoL_FormationList5. Both lists are then sorted in
-- place by the formation's type (4 / 5), before the retail code looks for the current formation's row. Engine calls
-- only when the picker runs (wrappers), never while the chunk loads. No plugin / no EVT_DEBUG: the game's lists.
@UPV@
local UTIL_FM_CMD = @crc:CMND_BETTERQOL_FORMATION@
local UTIL_FM_DONE = false
local UTIL_FM_LIST11, UTIL_FM_LIST5

local function UTIL_FM_Get(which, i)
  local ok, v = pcall(funcLuaCommand, UTIL_FM_CMD, which, i)
  if ok and type(v) == "number" then
    return v
  end
  return 0
end

local UTIL_FM_FUNCS = {"OnInitFormationCommon", "UpdateListItem", "OnMoveListItem"}

-- the ids of list `which` of CMND_BETTERQOL_FORMATION as a set, and their count
local function UTIL_FM_Set(which)
  local set, n = {}, UTIL_FM_Get(which, 0)
  for i = 1, n do
    set[UTIL_FM_Get(which, i)] = true
  end
  return set, n
end

-- the picker list whose every entry is in the set `allowed`
local function UTIL_FM_Find(allowed)
  return EVT_UpvalueFind(UTIL_FM_FUNCS, function(t)
    if #t == 0 then
      return false
    end
    for i = 1, #t do
      if not allowed[t[i]] then
        return false
      end
    end
    return true
  end)
end

-- the ids of list `which` appended in place to `list` (each once)
local function UTIL_FM_Append(list, which)
  if list == nil then
    return
  end
  local have = {}
  for i = 1, #list do
    have[list[i]] = true
  end
  for i = 1, UTIL_FM_Get(which, 0) do
    local id = UTIL_FM_Get(which, i)
    if id ~= 0 and not have[id] then
      list[#list + 1] = id
      have[id] = true
    end
  end
end

-- the list `list` sorted in place by the plugin's groups (CMND_BETTERQOL_FORMATION 4 builds them for the game's
-- language, 5 reads a formation's): one type after another, formations of one type in their order in the list,
-- formations without a group at the end. One bounded walk, once per list.
local UTIL_FM_LANG = @crc:CMND_GET_LANGUAGE_CODE@
local function UTIL_FM_Sort(list)
  if list == nil then
    return
  end
  local n = #list
  local keyed = {}
  for i = 1, n do
    local group = UTIL_FM_Get(5, list[i])
    keyed[i] = {id = list[i], group = group > 0 and group or math.huge, pos = i}
  end
  table.sort(keyed, function(a, b)
    if a.group ~= b.group then
      return a.group < b.group
    end
    return a.pos < b.pos
  end)
  for i = 1, n do
    list[i] = keyed[i].id
  end
end

local function UTIL_FM_Fill()
  if UTIL_FM_DONE then
    return
  end
  UTIL_FM_DONE = true
  local game, ng = UTIL_FM_Set(1)
  if ng <= 0 then
    return
  end
  local offered5, unlocked5 = UTIL_FM_Set(3), UTIL_FM_Set(2)
  local any5, game11 = {}, {}
  for id in pairs(offered5) do
    any5[id] = true
  end
  for id in pairs(unlocked5) do
    any5[id] = true
  end
  for id in pairs(game) do
    if not offered5[id] then
      game11[id] = true
    end
  end
  local list11 = UTIL_FM_Find(game11)
  local list5 = UTIL_FM_Find(any5)
  UTIL_FM_Append(list11, 0)
  UTIL_FM_Append(list5, 3)
  UTIL_FM_Append(list5, 2)
  local lok, lang = pcall(funcLuaCommand, UTIL_FM_LANG)
  if UTIL_FM_Get(4, (lok and type(lang) == "number") and lang or -1) > 0 then
    UTIL_FM_Sort(list11)
    UTIL_FM_Sort(list5)
  end
  -- the 5v5 list for other scripts of this menu VM (its row count, e.g. the friendlies picker)
  BetterQoL_FormationList5 = list5
  UTIL_FM_LIST11, UTIL_FM_LIST5 = list11, list5
end

for _, name in ipairs(UTIL_FM_FUNCS) do
  local orig = rawget(_ENV, name)
  if type(orig) == "function" then
    _ENV[name] = function(...)
      UTIL_FM_Fill()
      return orig(...)
    end
  end
end

-- The retail open sets the list's row (OnOpenGeneralSubListLayer) before the row layers exist, so the list view's focus
-- step stops at its first missing row and only the row and scroll stay set; a list that opens deep (a sorted list puts
-- the current formation at any row) is left with a focus state out of step with its scroll. When the current row is
-- drawn its layers exist: the row is set again and focused, the jump of retail's chara_bank_menu_for_search. Once per
-- opening.
local UTIL_FM_LIST_LAYER = 3873858080 -- win05_01_general_sub_list_formation
local UTIL_FM_ITEM_LAYER = 1027507646 -- win05_02_general_sub_list_item
local UTIL_FM_SET_LIST_INDEX = 306610847
local UTIL_FM_LIST_INSTANCE = 3497892782
local UTIL_FM_FOCUS_INSTANCE = 1778826357
local UTIL_FM_PENDING_ROW

local function UTIL_FM_RowOf(list, id)
  if list ~= nil then
    for i = 1, #list do
      if list[i] == id then
        return i - 1
      end
    end
  end
  return nil
end

local UTIL_FM_OpenList = rawget(_ENV, "OnOpenGeneralSubListLayer")
local UTIL_FM_DrawRow = rawget(_ENV, "UpdateListItem")
if type(UTIL_FM_OpenList) == "function" and type(UTIL_FM_DrawRow) == "function" then
  _ENV.OnOpenGeneralSubListLayer = function(...)
    local ok, id = pcall(GetApplyFormationId)
    UTIL_FM_PENDING_ROW = ok and (UTIL_FM_RowOf(UTIL_FM_LIST11, id) or UTIL_FM_RowOf(UTIL_FM_LIST5, id)) or nil
    return UTIL_FM_OpenList(...)
  end
  _ENV.UpdateListItem = function(row, ...)
    local r = table.pack(UTIL_FM_DrawRow(row, ...))
    if row == UTIL_FM_PENDING_ROW then
      UTIL_FM_PENDING_ROW = nil
      pcall(funcLuaMenuCommand, UTIL_FM_SET_LIST_INDEX, UTIL_FM_LIST_LAYER, row)
      local ok, instance = pcall(funcLuaMenuCommand, UTIL_FM_LIST_INSTANCE, UTIL_FM_LIST_LAYER, row)
      if ok and type(instance) == "number" then
        pcall(funcLuaMenuCommand, UTIL_FM_FOCUS_INSTANCE, UTIL_FM_ITEM_LAYER, instance, true)
      end
    end
    return table.unpack(r, 1, r.n)
  end
end
