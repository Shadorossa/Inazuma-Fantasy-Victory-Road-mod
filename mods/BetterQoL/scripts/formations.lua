-- BetterQoL › Unlocked formations (feature formations-§8b).
--
-- Which formations (derived from the tables the game loads, mods' formations included; no id list): a row of
-- formation_config m_SoccerFormationInfoList is unlocked when
--   1. it has 11 placements (an 11-a-side formation; the five-a-side lists: 5 placements);
--   2. its noun_id has a name in item_text (NOUN_INFO);
--   3. no formation item of item_config (ITEM_FORMATION_INFO) points at it (those the game already offers);
--   4. its name is not the name of an offered formation or of an earlier unlocked row;
--   5. its placements are not identical to another candidate's (v7.1.2: 15 rows share one placeholder layout).
-- On v7.1.2 the rule gives exactly UVR's 54 (rows 0-53, «F-Raimon» .. «F-Galaxia», row order).
-- The picker's row count getter is patched to the game's count + N (content\game\formations.toml FormationCount).
-- The five-a-side lists (which 2 / 3) feed the 5v5 picker the same way (research/grafts/utilities_formations).

local PLACES_11 = 11
local PLACES_5 = 5
local MAX_EXTRA = 248 -- the menu's own row array holds 256 rows; the game's lists have 8 (11v11) and 5 (5v5)
local SEP = "\1"
local TEXT_LANGS = { "ja", "en", "es", "fr", "de", "it", "pt", "zh_hans", "zh_hant" } -- fallback only

local Id = require "VRFW/lib/ids"
local u32 = Id.u32

local function cell_text(v)
  if type(v) == "table" then
    local parts = {}
    for i = 1, #v do
      parts[i] = cell_text(v[i])
    end
    for k, x in pairs(v) do
      if type(k) == "string" then
        parts[#parts + 1] = k .. "=" .. cell_text(x)
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return tostring(v)
end

local function row_text(r)
  local parts = {}
  for i = 1, #r do
    parts[i] = cell_text(r[i])
  end
  return table.concat(parts, SEP)
end

-- defenders, midfielders, forwards of a formation row (the position_id bands of formation_config)
local function layout_numbers(r, places)
  local df, mf, fw = 0, 0, 0
  local s = r.placement_info
  if type(s) == "table" and s.start and s.count then
    local start, count = s.start % 65536, s.count % 65536
    for k = start + 1, math.min(start + count, #places) do
      local p = places[k].position_id
      if p == 2 or p == 3 then
        df = df + 1
      elseif p >= 4 and p <= 7 then
        mf = mf + 1
      elseif p >= 8 then
        fw = fw + 1
      end
    end
  end
  return { df, mf, fw }
end

-- the formations in row order: { id, noun, layout = the placement rows as text, n = placement count, lines = its
-- defenders, midfielders and forwards }
local function formations()
  local rows = VRFW.table.rows("formation/formation")
  local places = VRFW.table.rows("formation/formation_soccer_form_placement_info")
  local out = {}
  for _, r in ipairs(rows) do
    local f = { id = u32(r.form_id), noun = u32(r.noun_id), n = 0, layout = "", lines = layout_numbers(r, places) }
    local s = r.placement_info
    if type(s) == "table" and s.start and s.count then
      local start, count = s.start % 65536, s.count % 65536
      if start + count <= #places then
        local parts = {}
        for k = start + 1, start + count do
          parts[#parts + 1] = row_text(places[k])
        end
        f.n, f.layout = count, table.concat(parts, SEP .. SEP)
      end
    end
    out[#out + 1] = f
  end
  return out
end

-- item_text NOUN_INFO of file `key`: noun id -> name (only the two columns are read: the table is wide and long)
local function noun_rows(key)
  local rows = VRFW.table.raw(key, "NOUN_INFO", { 1, 6 })
  local names = {}
  for _, r in ipairs(rows) do
    if type(r[1]) == "number" and type(r[6]) == "string" then
      names[u32(r[1])] = r[6]
    end
  end
  return names
end

-- item_text NOUN_INFO: noun id -> name, from the first text language that reads (a name's presence is the same in
-- every language)
local function noun_names()
  local keys = VRFW.table.keys("data/common/text/*/item_text.cfg.bin")
  if #keys == 0 then
    for _, l in ipairs(TEXT_LANGS) do
      keys[#keys + 1] = "data/common/text/" .. l .. "/item_text.cfg.bin"
    end
  end
  local last = "no text language"
  for _, k in ipairs(keys) do
    local ok, names = pcall(noun_rows, k)
    if ok then
      return names
    end
    last = tostring(names)
  end
  error(last)
end

-- formIds a formation item points at (any int value of ITEM_FORMATION_INFO that is a formId)
local function offered_ids(forms)
  local ids = {}
  for _, f in ipairs(forms) do
    if f.id ~= 0 then
      ids[f.id] = true
    end
  end
  local out = {}
  for _, r in ipairs(VRFW.table.rows("item/item_formation")) do
    for i = 1, #r do
      if type(r[i]) == "number" then
        local h = u32(r[i])
        if ids[h] then
          out[h] = true
        end
      end
    end
  end
  return out
end

local trim = require("VRFW/lib/basics").value.trim

local function unlockable(forms, offered, names, places)
  local function name(f)
    local n = names[f.noun]
    n = n and trim(n) or ""
    return n ~= "" and n or nil
  end
  local seen = {}
  for _, f in ipairs(forms) do
    if offered[f.id] then
      local n = name(f)
      if n then
        seen[n] = true
      end
    end
  end
  local cands, layouts = {}, {}
  for _, f in ipairs(forms) do
    if f.id ~= 0 and f.n == places and not offered[f.id] then
      local n = name(f)
      if n and not seen[n] then
        seen[n] = true
        cands[#cands + 1] = f
        layouts[f.layout] = (layouts[f.layout] or 0) + 1
      end
    end
  end
  local out = {}
  for _, f in ipairs(cands) do
    if layouts[f.layout] == 1 and #out < MAX_EXTRA then
      out[#out + 1] = f.id
    end
  end
  return out
end

-- `mov eax, [rcx+9E0h]; add eax, extra; ret` + int3 padding (the getter and its padding, 16 bytes)
local function getter_bytes(extra)
  local b = { 0x8B, 0x81, 0xE0, 0x09, 0x00, 0x00, 0x05 }
  for k = 0, 3 do
    b[#b + 1] = bit32.band(bit32.rshift(extra, 8 * k), 0xFF)
  end
  b[#b + 1] = 0xC3
  for _ = 1, 4 do
    b[#b + 1] = 0xCC
  end
  return b
end

local unlocked, game, unlocked5, game5, sort_rows = {}, {}, {}, {}, {}

local function build()
  -- the lists are built once and kept between starts (VRFW.derived); the patch below is applied every start
  local lists = VRFW.derived("formation_lists_by_size", nil, function()
    local forms = formations()
    local offered = offered_ids(forms)
    local names = noun_names()
    local out = { unlocked = unlockable(forms, offered, names, PLACES_11), game = {},
                  unlocked5 = unlockable(forms, offered, names, PLACES_5), game5 = {}, sort_rows = {} }
    for _, f in ipairs(forms) do
      if f.id ~= 0 then
        out.sort_rows[#out.sort_rows + 1] = { id = f.id, noun = f.noun, lines = f.lines }
      end
      if offered[f.id] then
        out.game[#out.game + 1] = f.id
        if f.n == PLACES_5 then
          out.game5[#out.game5 + 1] = f.id
        end
      end
    end
    return out
  end)
  unlocked, game = lists.unlocked or {}, lists.game or {}
  unlocked5, game5 = lists.unlocked5 or {}, lists.game5 or {}
  sort_rows = lists.sort_rows or {}
  VRFW.log(string.format("%d formation(s) unlocked, %d offered by the game; five-a-side: %d unlocked, %d offered",
    #unlocked, #game, #unlocked5, #game5))
  if #unlocked > 0 then
    local ok, done = pcall(VRFW.patch.apply, "FormationCount", getter_bytes(#unlocked))
    if ok and done then
      VRFW.log("count getter -> game count + " .. #unlocked)
    else
      VRFW.warn("count getter not patched (" .. tostring(done) .. "): the picker shows the game's rows only (the Lua list is longer, harmless)")
    end
  end
end

local ok, err = pcall(build)
if not ok then
  unlocked, game, unlocked5, game5, sort_rows = {}, {}, {}, {}, {}
  VRFW.warn("tables not read (" .. tostring(err) .. "): the formation picker lists the game's own formations")
end

-- Sort groups of the pickers (built the first time a picker opens in a language and kept between starts, so a later
-- start only reads a small file once): a formation's type is the numbers of its
-- name («4-4-2», «3-5-2 F-Gemini»: the digits left to right, in their full-width form too (ja)), or, for a name without
-- numbers (the five-a-side ones, in every language), its defenders, midfielders and forwards counted from its
-- placements. Types go up number by number; formations of one type share a group, so the graft keeps their order in
-- the list. Unnamed formations have no group (the picker keeps their place).
local FULL_DASH = "\239\188\141" -- U+FF0D
local groups_by_lang = {}
local groups_last = {}

local function ascii_name(s)
  s = s:gsub(FULL_DASH, "-")
  s = s:gsub("\239\188([\144-\153])", function(c) return tostring(c:byte() - 144) end)
  return s
end

-- the numbers at the start of a name (empty when it has none)
local function name_numbers(name)
  local prefix = ascii_name(trim(name)):match("^[%d%-%s]*") or ""
  local nums = {}
  for d in prefix:gmatch("%d+") do
    nums[#nums + 1] = tonumber(d)
  end
  return nums
end

-- -1, 0, 1: number by number; when one type is the start of the other, the shorter one first
local function compare_numbers(a, b)
  for i = 1, math.min(#a, #b) do
    if a[i] ~= b[i] then
      return a[i] < b[i] and -1 or 1
    end
  end
  if #a ~= #b then
    return #a < #b and -1 or 1
  end
  return 0
end

-- the game's text language of language code `code` (nil: none)
local function language_of(code)
  if type(code) == "number" and code >= 0 and type(VRFW.files.game_languages) == "function" then
    local ok, t = pcall(VRFW.files.game_languages)
    return ok and type(t) == "table" and t[math.floor(code) + 1] or nil
  end
  return nil
end

local function names_in(lang)
  if type(lang) == "string" then
    local ok, names = pcall(noun_rows, "data/common/text/" .. lang .. "/item_text.cfg.bin")
    if ok then
      return names
    end
  end
  return noun_names()
end

-- formId -> sort group of the names in `lang`
local function build_groups(lang)
  local names = names_in(lang)
  local keys = {}
  for _, f in ipairs(sort_rows) do
    local name = names[f.noun]
    if name and trim(name) ~= "" then
      local nums = name_numbers(name)
      keys[#keys + 1] = { id = f.id, nums = #nums > 0 and nums or f.lines }
    end
  end
  table.sort(keys, function(a, b)
    return compare_numbers(a.nums, b.nums) < 0
  end)
  local out, group, previous = {}, 0, nil
  for _, k in ipairs(keys) do
    if previous == nil or compare_numbers(previous, k.nums) ~= 0 then
      group, previous = group + 1, k.nums
    end
    out[k.id] = group
  end
  return out
end

-- formId -> sort group for language code `code`
local function sort_groups(code)
  local key = type(code) == "number" and code or -1
  if groups_by_lang[key] then
    return groups_by_lang[key]
  end
  local lang = language_of(code)
  local ok, out = pcall(VRFW.derived, "formation_sort_groups." .. (lang or "default"), nil, function()
    return build_groups(lang)
  end)
  if not ok then
    VRFW.warn("formation sort groups not built (" .. tostring(out) .. "): the pickers keep their order")
    out = {}
  end
  groups_by_lang[key] = out
  return out
end

-- which: 0 = unlocked (11-a-side), 1 = offered by the game (every size), 2 = unlocked five-a-side, 3 = offered
-- five-a-side; i: 0 = count, 1.. = formId (0 = none); 4 = build the sort groups for language code i (returns 1 when
-- they exist, else 0), 5 = sort group of formId i in the language asked last by 4 (0 = none)
local LISTS = {
  [0] = function() return unlocked end,
  [1] = function() return game end,
  [2] = function() return unlocked5 end,
  [3] = function() return game5 end,
}

function BetterQoL.Formation(which, i)
  i = type(i) == "number" and math.floor(i) or 0
  if which == 4 then
    groups_last = sort_groups(i) -- i = the language code (CMND_GET_LANGUAGE_CODE)
    return next(groups_last) ~= nil and 1 or 0
  elseif which == 5 then
    return groups_last[u32(i)] or 0
  end
  local l = (LISTS[which] or LISTS[0])()
  if i <= 0 then
    return #l
  end
  return l[i] or 0
end
