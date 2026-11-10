
local M = {}

local TEXT_DIR = "data/common/text/"
M.CHARA = "chara_text"
M.ROMA = "chara_text_roma"
M.TEAM = "team_text"
M.SERIES_TEXT = "chara_add_info_text"
local SERVED_TAG = "_betterqol_names_"

M.UNKNOWN, M.DUB, M.ROMAJI = "unknown", "dub", "romaji"

function M.text_key(lang, tbl)
  return TEXT_DIR .. lang .. "/" .. tbl .. ".cfg.bin"
end

function M.served_key(lang, tbl, sig)
  return TEXT_DIR .. lang .. "/" .. tbl .. SERVED_TAG .. sig .. ".cfg.bin"
end

function M.shown_chara_key(lang)
  if VRFW.name_tags.original_names() then
    return M.text_key(lang, M.ROMA)
  end
  return VRFW.names.shown_key(lang, M.CHARA) or M.text_key(lang, M.CHARA)
end

-- the redirect filter of the engine's opens of `tbl` in `lang` (paths are matched lowercase with `/`)
function M.filter(lang, tbl)
  return "/text/" .. lang:lower() .. "/" .. tbl .. ".cfg.bin"
end

-- the signature of a served key (nil for anything else)
function M.sig_of_key(key)
  return type(key) == "string" and key:match(SERVED_TAG .. "(%x+)%.cfg%.bin$") or nil
end

local function fnv_byte(hi, lo, b)
  lo = bit32.bxor(lo, b)
  local p = lo * 0x1B3
  local nlo = p % 0x100000000
  local carry = (p - nlo) / 0x100000000
  local nhi = (carry + hi * 0x1B3 + lo * 0x100) % 0x100000000
  return nhi, nlo
end

function M.ids_sig(ids)
  if #ids == 0 then
    return nil
  end
  local hi, lo = 0xcbf29ce4, 0x84222325
  for _, id in ipairs(ids) do
    hi, lo = fnv_byte(hi, lo, bit32.extract(id, 0, 8))
    hi, lo = fnv_byte(hi, lo, bit32.extract(id, 8, 8))
    hi, lo = fnv_byte(hi, lo, bit32.extract(id, 16, 8))
    hi, lo = fnv_byte(hi, lo, bit32.extract(id, 24, 8))
  end
  hi = bit32.bor(hi, 0x80000000)
  return string.format("%08x%08x", hi, lo)
end

local trim = VRFW.strings.trim

-- Text `s` with each `[kanji/kana]` replaced by its kana.
function M.furigana_reading(s)
  return (s:gsub("%[[^/%]]*/([^%]]*)%]", "%1"))
end

function M.strip_furigana(s)
  local out, rest = {}, s
  while true do
    local i = rest:find("[", 1, true)
    if not i then
      break
    end
    out[#out + 1] = rest:sub(1, i - 1)
    local tail = rest:sub(i + 1)
    local sl, en = tail:find("/", 1, true), tail:find("]", 1, true)
    if sl and en and sl < en then
      out[#out + 1] = tail:sub(1, sl - 1)
      rest = tail:sub(en + 1)
    else
      out[#out + 1] = "["
      rest = tail
    end
  end
  out[#out + 1] = rest
  return trim(table.concat(out))
end

function M.team_names(doc)
  local out, n = {}, 0
  for _, t in ipairs(type(doc) == "table" and type(doc.team) == "table" and doc.team or {}) do
    if type(t) == "table" and type(t.ja) == "string" and type(t.name) == "string" and trim(t.name) ~= "" then
      out[M.strip_furigana(t.ja)] = trim(t.name)
      n = n + 1
    end
  end
  return out, n
end

function M.chara_overrides(dub, roma, ids)
  local over, n = {}, 0
  for _, id in ipairs(ids) do
    local r = roma[id]
    if r then
      local d = dub[id]
      for var, s in pairs(r) do
        if s ~= "" and (d == nil or d[var] ~= s) then
          over[id] = over[id] or {}
          over[id][var] = s
          n = n + 1
        end
      end
    end
  end
  return over, n
end

function M.team_overrides(ja_names, lang_rows, ids, names)
  local marked, any = {}, false
  for _, id in ipairs(ids) do
    local r = ja_names[id]
    if r then
      for _, nm in pairs(r) do
        if names[nm] then
          marked[nm] = true
          any = true
        end
      end
    end
  end
  local over, n = {}, 0
  if not any then
    return over, 0
  end
  for id, r in pairs(ja_names) do
    for var, nm in pairs(r) do
      if marked[nm] then
        local orig = names[nm]
        local cur = lang_rows[id] and lang_rows[id][var]
        if cur ~= nil and cur ~= orig then
          over[id] = over[id] or {}
          over[id][var] = orig
          n = n + 1
        end
      end
    end
  end
  return over, n
end

function M.chara_wanted(romaji, custom, chara_sig)
  if romaji then
    return M.ROMAJI
  elseif custom then
    return chara_sig or M.DUB
  end
  return M.DUB
end

function M.team_wanted(romaji, custom, team_sig, all_sig)
  if romaji then
    return all_sig or M.DUB
  elseif custom then
    return team_sig or M.DUB
  end
  return M.DUB
end

function M.reload_needed(romaji_now, chara_want, chara_loaded, team_want, team_loaded)
  local chara = not romaji_now and chara_loaded ~= M.UNKNOWN and chara_loaded ~= chara_want
  local teams = team_loaded ~= M.UNKNOWN and team_loaded ~= team_want
  return chara, teams
end

function M.loaded_name(s)
  if s == M.UNKNOWN then
    return "not loaded yet"
  elseif s == M.DUB then
    return "dub"
  elseif s == M.ROMAJI then
    return "all original (retail Originales)"
  end
  return "selection " .. tostring(s)
end

return M
