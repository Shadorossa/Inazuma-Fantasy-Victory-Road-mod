-- Advanced: Persons: the versions of one character are every chara_base with the same name in each of NAME_LANGUAGES.

local M = {}

local u32 = VRFW.ids.unsigned
local Names = VRFW.names

-- Text languages whose names must all match for two cards to be the same person.
local NAME_LANGUAGES = { "ja", "en" }

local PERSON = nil       -- chara_base id -> the person's first chara_base id (chara_base order)
local VERSIONS = nil     -- the person's first chara_base id -> every chara_base id of the person

local function groups()
  local chars = VRFW.character.characters()
  local text_ids, seen = {}, {}
  for _, c in ipairs(chars) do
    local t = u32(c.name_text or 0)
    if t ~= 0 and not seen[t] then
      seen[t] = true
      text_ids[#text_ids + 1] = t
    end
  end
  local names = {}
  for i, lang in ipairs(NAME_LANGUAGES) do names[i] = Names.chara_names(text_ids, lang) end
  local by_key, out = {}, {}
  for _, c in ipairs(chars) do
    local t = u32(c.name_text or 0)
    local parts = {}
    for i = 1, #NAME_LANGUAGES do
      local s = t ~= 0 and names[i][t] or ""
      if s == "" then
        parts = nil
        break
      end
      parts[i] = s
    end
    if parts then
      local key = table.concat(parts, "\n")
      local g = by_key[key]
      if not g then
        g = {}
        by_key[key] = g
        out[#out + 1] = g
      end
      g[#g + 1] = u32(c.id)
    end
  end
  -- only the persons with two or more versions are kept (a lone character is his own person)
  local kept = {}
  for _, g in ipairs(out) do
    if #g > 1 then kept[#kept + 1] = g end
  end
  return { groups = kept }
end

local function build()
  if PERSON then return end
  PERSON, VERSIONS = {}, {}
  local ok, kept = pcall(VRFW.derived, "persons", { languages = NAME_LANGUAGES }, groups)
  if not ok or type(kept) ~= "table" or type(kept.groups) ~= "table" then
    VRFW.warn("persons: the character names could not be read (" .. tostring(kept) .. "): every character is his own person")
    return
  end
  for _, g in ipairs(kept.groups) do
    local first = u32(g[1])
    local list = {}
    for i, b in ipairs(g) do
      b = u32(b)
      list[i] = b
      PERSON[b] = first
    end
    VERSIONS[first] = list
  end
end

--- Advanced: The person of character `base`: the first chara_base id of his versions (base itself when he has no other).
function M.of_character(base)
  build()
  base = u32(base or 0)
  return PERSON[base] or base
end

--- Internal: Every version of character `base` (chara_base ids, chara_base order; { base } when he has no other).
function M.versions(base)
  build()
  base = u32(base or 0)
  return VERSIONS[PERSON[base] or 0] or { base }
end

--- Internal: True when characters `a` and `b` are versions of one person.
function M.same(a, b)
  return M.of_character(a) == M.of_character(b)
end

return M
