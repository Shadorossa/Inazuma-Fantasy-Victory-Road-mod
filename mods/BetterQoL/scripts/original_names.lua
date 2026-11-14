
local Cat = require "lib/original_names_catalogue"
local T = require "lib/original_names_tables"

BetterQoL = BetterQoL or {}
BetterQoL.OriginalNames = BetterQoL.OriginalNames or {}

local OPT_PREFIX, OPT_CUSTOM = "names.", "names.custom"
local TEAMS_FILE = "content/original_names/teams.toml"
-- offsets from the game profile
local LAYOUT_NAMES = {
  character_names = "GameSettings.CharacterNames", text_language = "GameSettings.TextLanguage",
  draft_rows = "SettingsMenu.DraftRows", applied_rows = "SettingsMenu.AppliedRows",
  row_size = "SettingsMenuRow", row_label = "SettingsMenuRow.Label", row_type = "SettingsMenuRow.Type",
  row_list = "SettingsMenuRow.List", row_count = "SettingsMenuRow.Count", row_index = "SettingsMenuRow.Index",
  row_base = "SettingsMenuRow.Base",
}
local L, LAYOUT_MISSING = {}, nil
for key, name in pairs(LAYOUT_NAMES) do
  local ok, v = pcall(VRFW.game.field, name)
  if ok and type(v) == "number" then
    L[key] = v
  elseif LAYOUT_MISSING == nil then
    LAYOUT_MISSING = name
  end
end
-- the draft rows run up to the applied rows
local DRAFT_ROW_COUNT = LAYOUT_MISSING == nil and math.floor((L.applied_rows - L.draft_rows) / L.row_size) or 0
local ROW_TYPE, ROW_VALUES = 63, 3
local IDX_DUB, IDX_CUSTOM, IDX_ORIGINAL = 0, 1, 2
local PUMP_ROW = 1

local cfg = {
  team_skip = { ja = true }, picker_reopen = false,
  log = true,
  grid = { cols = 8, rows = 4, pitch_x = 196, pitch_y = 180, tile = 132, cx = 960, cy = 560, grey = 0.38, names = true },
  team_grid = { cols = 8, rows = 3, pitch_x = 210, pitch_y = 236, cx = 960, cy = 520 },
}
local cat = nil            -- the catalogue (nil = off)
local langs, lang_set = {}, {}
local team_names = {}      -- Japanese team name -> original name
local ja_names = nil
local text_ids = {}        -- the text ids the picker shows (series + team names)
local outcomes = {}
local pending = {}         -- builds of other languages: { lang, kind, sig, ids }
local queued = {}          -- "lang|kind|sig" -> true while in `pending` (queued once)
local loaded = {}
local counts = {}          -- filter -> opens seen
local set_keys = {}
local cur_lang = nil       -- the language of the last text load seen
local sig_cache, sig_cache_n = {}, 0
local all_sigs = nil
local picker, pick_texts, pick_names = nil, {}, nil
-- VRFW.options.values() (a file read + JSON decode) and the saved choices, kept until a store, the picker or the title
local opt_cache, saved_cache = nil, nil

local function opt_values()
  if opt_cache == nil then
    opt_cache = VRFW.options.values() or {}
  end
  return opt_cache
end

local function opt_forget()
  opt_cache, saved_cache = nil, nil
end

local info, warn = VRFW.logger("original_names")

local function int(v) return VRFW.value.integer(v, nil) end

local Memory = VRFW.memory
local read_memory, write_memory = Memory.read, Memory.write

local ROW = { row_on = 0, row_label = 0, menu = 0, list = 0 }

local function load_cfg()
  local c = VRFW.config("original_names")
  if type(c) ~= "table" then
    return
  end
  if type(c.team_skip_langs) == "table" then
    cfg.team_skip = {}
    for _, l in ipairs(c.team_skip_langs) do
      cfg.team_skip[tostring(l)] = true
    end
  end
  cfg.picker_reopen = c.picker_reopen == true
  cfg.log = c.log ~= false
  for _, part in ipairs({ "grid", "team_grid" }) do
    if type(c[part]) == "table" then
      for k, v in pairs(c[part]) do
        if cfg[part][k] ~= nil and type(v) == type(cfg[part][k]) then
          cfg[part][k] = v
        end
      end
    end
  end
end

local function settings()
  local s = VRFW.game.global("game_settings")
  if s == nil then
    return nil
  end
  return s
end

-- the game's "Originals" byte (false when the settings are not there yet)
local function romaji()
  local s = settings()
  local b = s and L.character_names and read_memory("u8", s + L.character_names)
  return type(b) == "number" and b ~= 0
end

local function row_index(rom, custom)
  if rom then
    return IDX_ORIGINAL
  elseif custom then
    return IDX_CUSTOM
  end
  return IDX_DUB
end

local VALUE_NAMES = { [IDX_DUB] = "Doblaje", [IDX_CUSTOM] = "Por equipos", [IDX_ORIGINAL] = "Originales" }

local function hex_id(h)
  local id = h and tonumber(h, 16)
  if id and id <= 0xFFFFFFFF then
    return id
  end
  return nil
end

local function read_saved()
  local values = opt_values()
  local s = { custom = (tonumber(values[OPT_CUSTOM]) or 0) ~= 0, chosen = {} }
  for k, v in pairs(values) do
    if type(k) == "string" and type(v) == "number" and v ~= 0 then
      local c = hex_id(k:match("^names%.c%.(%x+)$"))
      if c then s.chosen[c] = true end
    end
  end
  return s
end

-- cached, read-only for callers
local function saved()
  if saved_cache == nil then
    local s = read_saved()
    if cat then
      s.chosen = Cat.normalize(cat, s.chosen)
    end
    saved_cache = s
  end
  return saved_cache
end

-- stores the choices, replacing every older names.* key
local function store(custom, chosen)
  local ch = {}
  for k in pairs(VRFW.options.values()) do
    if type(k) == "string" and k:sub(1, #OPT_PREFIX) == OPT_PREFIX then
      ch[k] = false
    end
  end
  ch[OPT_CUSTOM] = custom and 1 or 0
  for id in pairs(chosen) do
    ch[string.format("names.c.%08x", id)] = 1
  end
  local ok, why = VRFW.options.store(ch)
  opt_forget()
  return ok, why
end

local function sigs(chosen)
  local sv = saved_cache
  local is_saved = sv ~= nil and chosen == sv.chosen
  if is_saved and sv.sg ~= nil then
    return sv.sg
  end
  local k = Cat.sel_key(chosen)
  local c = sig_cache[k]
  if not c then
    local cids, n = Cat.chara_name_ids(cat, chosen)
    local tids = Cat.team_name_ids(cat, chosen, false)
    c = { chara_ids = cids, chara_sig = T.ids_sig(cids), team_ids = tids, team_sig = T.ids_sig(tids), n = n }
    if sig_cache_n >= 16 then
      sig_cache, sig_cache_n = {}, 0
    end
    sig_cache[k], sig_cache_n = c, sig_cache_n + 1
  end
  if is_saved then
    sv.sg = c
  end
  return c
end

local function selection_text(chosen)
  local sg = sigs(chosen)
  return string.format("%d player(s), %d full team(s)", sg.n, #sg.team_ids)
end

local function okey(lang, kind, sig)
  return lang .. "|" .. kind .. "|" .. sig
end

local function kind_name(kind)
  return kind == "chara" and "characters" or "teams"
end

local function build_one(lang, kind, sig, ids)
  if not lang_set[lang] then
    return ""
  end
  local tbl = kind == "chara" and T.CHARA or T.TEAM
  if kind ~= "chara" and (cfg.team_skip[lang] or ja_names == nil or next(team_names) == nil) then
    return ""
  end
  local built = VRFW.derived("original_names." .. kind .. "." .. lang, sig, function()
    local over, n
    if kind == "chara" then
      local dub, e1 = VRFW.files.text_rows(T.text_key(lang, T.CHARA))
      if not dub then
        error(e1, 0)
      end
      local roma, e2 = VRFW.files.text_rows(T.text_key(lang, T.ROMA))
      if not roma then
        error(e2, 0)
      end
      over, n = T.chara_overrides(dub, roma, ids)
    else
      local rows, e = VRFW.files.text_rows(T.text_key(lang, T.TEAM))
      if not rows then
        error(e, 0)
      end
      over, n = T.team_overrides(ja_names, rows, ids, team_names)
    end
    return { over = over, n = n }
  end)
  local over, n = built.over, built.n
  if n == 0 then
    return ""
  end
  local key = T.served_key(lang, tbl, sig)
  local changed, why = VRFW.files.serve_text(key, T.text_key(lang, tbl), over)
  if changed == nil then
    return nil, why
  end
  if changed == 0 then
    return ""
  end
  info(string.format("%s %s: table %s served (%d row(s) changed)", lang, kind_name(kind), sig, changed))
  return key
end

local function ensure(lang, kind, sig, ids)
  local k = okey(lang, kind, sig)
  local o = outcomes[k]
  if o ~= nil then
    return o
  end
  local ok, r, why = pcall(build_one, lang, kind, sig, ids)
  if not ok then
    r, why = nil, r
  end
  if r == nil then
    warn(lang, kind_name(kind), tostring(why))
    o = false
  else
    o = r
  end
  outcomes[k] = o
  return o
end

local function want_all(kind, sig, ids, first, now)
  if not sig then
    return
  end
  for _, l in ipairs(langs) do
    local k = okey(l, kind, sig)
    if outcomes[k] == nil then
      if now or l == first then
        ensure(l, kind, sig, ids)
      elseif not queued[k] then
        queued[k] = true
        pending[#pending + 1] = { l, kind, sig, ids }
      end
    end
  end
end

local function pump(n)
  while n > 0 and #pending > 0 do
    local j = table.remove(pending, 1)
    local k = okey(j[1], j[2], j[3])
    queued[k] = nil
    if outcomes[k] == nil then
      ensure(j[1], j[2], j[3], j[4])
      n = n - 1
    end
  end
end

-- the character and team tables of a selection's signatures
local function want_selection(sg, first, now)
  want_all("chara", sg.chara_sig, sg.chara_ids, first, now)
  if sg.team_sig ~= all_sigs.team_sig then
    want_all("team", sg.team_sig, sg.team_ids, first, now)
  end
end

local function want_saved(s, first, now, any)
  local sg = sigs(s.chosen)
  want_all("team", all_sigs.team_sig, all_sigs.team_ids, first, now)
  if s.custom or (any and next(s.chosen) ~= nil) then
    want_selection(sg, first, now)
  end
end

local function poll()
  local seen = false
  for _, l in ipairs(langs) do
    local lo = loaded[l]
    local fc, fr, ft = T.filter(l, T.CHARA), T.filter(l, T.ROMA), T.filter(l, T.TEAM)
    local lc, nc = VRFW.files.opened(fc)
    local _, nr = VRFW.files.opened(fr)
    local lt, nt = VRFW.files.opened(ft)
    nc, nr, nt = nc or 0, nr or 0, nt or 0
    local dc, dr, dt = nc > (counts[fc] or 0), nr > (counts[fr] or 0), nt > (counts[ft] or 0)
    counts[fc], counts[fr], counts[ft] = nc, nr, nt
    if dc and dr then
      if romaji() then
        dc = false
      else
        dr = false
      end
    end
    if dr then
      lo.chara = T.ROMAJI
    elseif dc and lc ~= nil then
      lo.chara = lc == "" and T.DUB or (T.sig_of_key(lc) or T.DUB)
    end
    if dt and lt ~= nil then
      lo.team = lt == "" and T.DUB or (T.sig_of_key(lt) or T.DUB)
    end
    if dc or dr or dt then
      cur_lang, seen = l, true
    end
  end
  if seen and cfg.log then
    local lo = loaded[cur_lang]
    info(string.format("texts loaded (%s): character names %s, team names %s", cur_lang, T.loaded_name(lo.chara), T.loaded_name(lo.team)))
  end
end

local redirect_said = {}

local function redirect(filter, key)
  local want = key or false
  if set_keys[filter] == want then
    return
  end
  local ok, why = VRFW.files.redirect(filter, key)
  if ok then
    set_keys[filter] = want
  elseif not redirect_said[filter] then
    redirect_said[filter] = true
    warn("redirect of", filter, "refused:", tostring(why), "(those names stay the game's)")
  end
end

local function served(lang, kind, sig)
  if not sig then
    return nil
  end
  local o = outcomes[okey(lang, kind, sig)]
  if o and o ~= "" then
    return o
  end
  return nil
end

local function apply_redirects()
  poll()
  local rom = romaji()
  local s = saved()
  local sg = sigs(s.chosen)
  local tw = T.team_wanted(rom, s.custom, sg.team_sig, all_sigs.team_sig)
  for _, l in ipairs(langs) do
    redirect(T.filter(l, T.CHARA), s.custom and served(l, "chara", sg.chara_sig) or nil)
    redirect(T.filter(l, T.ROMA), nil)
    redirect(T.filter(l, T.TEAM), tw ~= T.DUB and served(l, "team", tw) or nil)
  end
  return s, sg, rom
end

local function lang_by_code(c)
  local l = VRFW.names.language(c, nil)
  if l and lang_set[l] then
    return l
  end
  return nil
end

-- the code's language, else the last text load's, else the settings' text language byte, else en
local function lang_of(code)
  local l = lang_by_code(int(code))
  if l then
    return l
  end
  poll()
  if cur_lang then
    return cur_lang
  end
  local s = settings()
  l = s and L.text_language and lang_by_code(read_memory("u8", s + L.text_language))
  if l then
    return l
  end
  return lang_set.en and "en" or (langs[1] or "en")
end

local function texts_for(lang)
  local out = {}
  for _, tbl in ipairs({ T.TEAM, T.SERIES_TEXT }) do
    local rows = VRFW.files.text_rows(T.text_key(lang, tbl))
    if rows then
      for id in pairs(text_ids) do
        if out[id] == nil then
          local r = rows[id]
          local s = r and r[0]
          if type(s) == "string" then
            out[id] = T.strip_furigana(s)
          end
        end
      end
    end
  end
  return out
end

local function name_of(id)
  local s = pick_texts[id]
  if type(s) == "string" and s ~= "" then
    return s
  end
  return string.format("0x%08X", id)
end

local function team_label(team)
  local nm = cat.team_names[team]
  return nm and name_of(nm) or string.format("0x%08X", team)
end

-- a character's name in chara_text / chara_text_roma `rows`, furigana reduced
local function chara_name(rows, c)
  local r = rows and rows[c[1]]
  local s = r and r[0]
  if type(s) == "string" and s ~= "" then
    return T.strip_furigana(s)
  end
  return ""
end

-- the names row among the draft rows of the open settings menu (type 63 with the mod's value list)
local function draft_row()
  local menu, list = ROW.menu, ROW.list
  if not menu or menu < 0x10000 or not list or list == 0 then
    return nil
  end
  for i = 0, DRAFT_ROW_COUNT - 1 do
    local r = menu + L.draft_rows + i * L.row_size
    if read_memory("u32", r + L.row_type) == ROW_TYPE and read_memory("ptr", r + L.row_list) == list then
      return r
    end
  end
  return nil
end

local function draft_after_pick(empty, current)
  if not empty then
    return current ~= IDX_CUSTOM and IDX_CUSTOM or nil
  end
  return current == IDX_CUSTOM and IDX_DUB or nil
end

local function cur_rows()
  local s = picker and cat.series[picker.page]
  return s and Cat.rows(cat, s) or {}, s
end

function BetterQoL.OriginalNames.Row()
  if not cat then
    return false
  end
  pump(PUMP_ROW)
  local on, label = ROW.row_on, ROW.row_label
  if on == 1 and label and label ~= 0 then
    return label
  end
  return false
end

function BetterQoL.OriginalNames.PickOpen(code)
  if not cat or #cat.series == 0 then
    return 0
  end
  opt_forget()
  local lang = lang_of(code)
  pick_texts = texts_for(lang)
  pick_names = { dub = VRFW.files.text_rows(T.text_key(lang, T.CHARA)), roma = VRFW.files.text_rows(T.text_key(lang, T.ROMA)) }
  picker = Cat.picker(cat, saved().chosen)
  info(string.format("picker opened (%s): %d page(s), %d player(s) chosen", lang, #cat.series, Cat.count(picker.chosen)))
  return #cat.series, picker.page, cfg.picker_reopen
end

-- CMND_BETTERQOL_NAMES_PICK_GRID() -> cols, rows, pitch x, pitch y, tile, centre x, centre y, grey, names
function BetterQoL.OriginalNames.PickGrid()
  local g = cfg.grid
  return g.cols, g.rows, g.pitch_x, g.pitch_y, g.tile, g.cx, g.cy, g.grey, g.names == true
end

-- CMND_BETTERQOL_NAMES_PICK_TEAM_GRID() -> cols, rows, pitch x, pitch y, centre x, centre y
function BetterQoL.OriginalNames.PickTeamGrid()
  local g = cfg.team_grid
  return g.cols, g.rows, g.pitch_x, g.pitch_y, g.cx, g.cy
end

-- CMND_BETTERQOL_NAMES_PICK_TAB(dir) -> page (1-based), the series' name, its players chosen, its players, its team rows
function BetterQoL.OriginalNames.PickTab(dir)
  if not cat or not picker then
    return false
  end
  local d = int(dir) or 0
  d = d < -1 and -1 or (d > 1 and 1 or d)
  if d ~= 0 then
    Cat.step_page(cat, picker, d)
  end
  local rows, s = cur_rows()
  if not s then
    return false
  end
  local on, n = Cat.page_counts(cat, picker)
  return picker.page, name_of(s.name_text), on, n, #rows
end

function BetterQoL.OriginalNames.PickItem(i)
  if not cat or not picker then
    return false
  end
  local rows, s = cur_rows()
  local r = rows[int(i) or 0]
  if not r then
    return false
  end
  local on, n = Cat.players_on(cat, r.players, picker.chosen)
  return team_label(r.team), on, n, Cat.team_emblem(cat, r.team, s.ty)
end

function BetterQoL.OriginalNames.PickTeam(i)
  if not cat or not picker then
    return false
  end
  i = int(i) or 0
  local r = cur_rows()[i]
  if not r then
    return false
  end
  picker.row = i
  local on, n = Cat.players_on(cat, r.players, picker.chosen)
  return n, on, team_label(r.team)
end

function BetterQoL.OriginalNames.PickPlayer(j)
  if not cat or not picker then
    return false
  end
  local r = cur_rows()[picker.row]
  local ci = r and r.players[int(j) or 0]
  if not ci then
    return false
  end
  local c = cat.charas[ci]
  local dub = chara_name(pick_names and pick_names.dub, c)
  local orig = chara_name(pick_names and pick_names.roma, c)
  return c[8], picker.chosen[c[8]] == true, dub, orig ~= "" and orig or dub
end

function BetterQoL.OriginalNames.PickToggle(j)
  if not cat or not picker then
    return false
  end
  j = int(j)
  if not j or j < 0 then
    return false
  end
  return Cat.toggle(cat, picker, j)
end

function BetterQoL.OriginalNames.PickClose()
  local p = picker
  picker, pick_texts, pick_names = nil, {}, nil
  if not cat or not p then
    return false, -1, 0, false
  end
  if not Cat.changed(p) then
    info("picker closed: no change")
    return false, -1, 0, false
  end
  local s = saved()
  local ok, why = store(s.custom, p.chosen)
  if ok then
    info("picker closed: " .. selection_text(p.chosen) .. " (saved)")
  else
    warn("picker: selection not saved (" .. tostring(why) .. ")")
  end
  poll()
  want_selection(sigs(p.chosen), cur_lang, false)
  apply_redirects()
  local row = draft_row()
  local cur = row_index(romaji(), s.custom)
  if row then
    local idx, base = read_memory("i32", row + L.row_index), read_memory("i32", row + L.row_base)
    if type(idx) == "number" and type(base) == "number" then
      cur = math.max(idx + base, 0)
    end
  end
  local new = draft_after_pick(next(p.chosen) == nil, cur)
  if not new then
    return true, -1, 0, false
  end
  if not row then
    warn("picker: the settings row was not found: choose «Por equipos» with ←/→")
    return true, -1, 0, false
  end
  local base = read_memory("i32", row + L.row_base) or 0
  if not VRFW.memory.write("i32", row + L.row_index, new - base) then
    warn("picker: the settings row was not written: choose «Por equipos» with ←/→")
    return true, -1, 0, false
  end
  local list = read_memory("ptr", row + L.row_list)
  local text = (type(list) == "number" and list >= 0x10000) and read_memory("u32", list + 4 * new) or 0
  info(string.format("«Nombres de los personajes» (draft): %s -> %s", VALUE_NAMES[cur] or tostring(cur), VALUE_NAMES[new]))
  return true, new, text or 0, new + 1 == ROW_VALUES
end

function BetterQoL.OriginalNames.Reload(code)
  if not cat then
    return false
  end
  poll()
  local lang = cur_lang or lang_of(code)
  local s = saved()
  local target = lang_by_code(int(code))
  want_saved(s, target or lang, false)
  local rom = romaji()
  local sg = sigs(s.chosen)
  local function effective(kind, want, ids)
    if want == T.DUB or want == T.ROMAJI then
      return want
    end
    if lang and served(lang, kind, want) == nil then
      ensure(lang, kind, want, ids)
    end
    if lang and served(lang, kind, want) then
      return want
    end
    return T.DUB
  end
  local cw = effective("chara", T.chara_wanted(rom, s.custom, sg.chara_sig), sg.chara_ids)
  local tw = T.team_wanted(rom, s.custom, sg.team_sig, all_sigs.team_sig)
  tw = effective("team", tw, rom and all_sigs.team_ids or sg.team_ids)
  apply_redirects()
  if not lang or not loaded[lang] then
    return false
  end
  local lo = loaded[lang]
  local lc = lo.chara ~= T.UNKNOWN and lo.chara or (rom and T.ROMAJI or T.DUB)
  local lt = lo.team ~= T.UNKNOWN and lo.team or T.DUB
  local rc, rt = T.reload_needed(rom, cw, lc, tw, lt)
  if rc or rt then
    info(string.format("names to reload (%s): characters loaded %s / wanted %s, teams loaded %s / wanted %s: back to the title, the game reloads its texts (as with «Originales»)",
      lang, T.loaded_name(lc), T.loaded_name(cw), T.loaded_name(lt), T.loaded_name(tw)))
  end
  return rc or rt
end

local function start()
  load_cfg()
  local ok, err = pcall(function()
    -- kept between starts
    local built = VRFW.derived("original_names.catalogue", nil, function()
      local series = Cat.series_rows()
      local belong = Cat.belong_rows()
      local charas = Cat.charas(VRFW.files.text_rows(T.text_key("ja", T.CHARA)), T.strip_furigana)
      local decls = Cat.declarations()
      local c = Cat.build(series, belong, charas, decls)
      local listed = 0
      for _ in pairs(Cat.assign(c)) do
        listed = listed + 1
      end
      return { cat = c, listed = listed, decls = #decls }
    end)
    cat = built.cat
    local nt = 0
    for _, s in ipairs(cat.series) do
      nt = nt + #s.teams
    end
    info(string.format("%d series tab(s), %d team(s), %d character(s) of %d person(s), %d listed once each; %d series / team pair(s) declared by mods' card filters", #cat.series, nt, #cat.charas, #cat.persons, built.listed, built.decls))
  end)
  if not ok then
    cat = nil
    warn("no catalogue (" .. tostring(err) .. "): the game's names, no picker")
    return
  end
  for _, s in ipairs(cat.series) do
    text_ids[s.name_text] = true
    for _, t in ipairs(s.teams) do
      local n = cat.team_names[t]
      if n then
        text_ids[n] = true
      end
    end
  end
  langs = VRFW.files.languages() or {}
  for _, l in ipairs(langs) do
    lang_set[l] = true
    loaded[l] = { chara = T.UNKNOWN, team = T.UNKNOWN }
  end
  local doc, why = VRFW.files.toml(TEAMS_FILE)
  local n_names = 0
  if doc then
    team_names, n_names = T.team_names(doc)
  else
    warn(tostring(why) .. ": no original team names")
  end
  if n_names > 0 then
    local ja = VRFW.files.text_rows(T.text_key("ja", T.TEAM))
    ja_names = {}
    for id, r in pairs(ja or {}) do
      for var, s in pairs(r) do
        local nm = T.strip_furigana(s)
        if team_names[nm] then
          ja_names[id] = ja_names[id] or {}
          ja_names[id][var] = nm
        end
      end
    end
  end
  local all_team = Cat.team_name_ids(cat, {}, true)
  all_sigs = { team_ids = all_team, team_sig = T.ids_sig(all_team) }
  local s = saved()
  info("saved: " .. (s.custom and "«Por equipos»" or "not «Por equipos»") .. ", " .. selection_text(s.chosen))
  want_saved(s, nil, true, true)
  apply_redirects()
  info("the engine's opens of chara_text / team_text (" .. #langs .. " language(s)) are redirected to the chosen tables")
end

local ROW_VALUE_KEY = "BetterQoL.names_by_team"

local function saved_custom()
  return (tonumber(opt_values()[OPT_CUSTOM]) or 0) ~= 0
end

local function is_draft_row(menu, row)
  return row >= menu + L.draft_rows and row < menu + L.applied_rows and (row - menu - L.draft_rows) % L.row_size == 0
end

-- the mod's three-value list, built once from the retail two-value list at `list`
local function our_list(list)
  if ROW.list ~= 0 then
    return ROW.list
  end
  local a, b = read_memory("u32", list), read_memory("u32", list + 4)
  if not a or not b then
    return nil
  end
  local ours = VRFW.crc32(ROW_VALUE_KEY)
  local p = VRFW.memory.buffer("names_row_values", 12)
  write_memory("u32", p, a)
  write_memory("u32", p + 4, ours)
  write_memory("u32", p + 8, b)
  ROW.list = p
  info(string.format("«Nombres de los personajes»: values %08X / %08X (%s) / %08X", a, ours, ROW_VALUE_KEY, b))
  return p
end

ROW.row_on = (LAYOUT_MISSING == nil and VRFW.is_on("SettingRowRead") and VRFW.is_on("SettingRowWrite")) and 1 or 0
if LAYOUT_MISSING ~= nil then
  warn("settings row not extended (the game profile has no " .. LAYOUT_MISSING .. "): «Nombres de los personajes» keeps its two values, no picker")
elseif ROW.row_on == 1 then
  info("«Nombres de los personajes» row: Doblaje / Por equipos / Originales (saved: " .. (saved_custom() and "Por equipos" or "the game's") .. ")")
else
  warn("settings row not extended (hooks SettingRowRead / SettingRowWrite off): «Nombres de los personajes» keeps its two values, no picker")
end

VRFW.on("hook:SettingRowRead:post", function(ev)
  local menu, row = ev.args[1], ev.args[2]
  if ROW.row_on ~= 1 or row < 0x10000 or read_memory("u32", row + L.row_type) ~= ROW_TYPE then
    return nil
  end
  local list, count = read_memory("ptr", row + L.row_list), read_memory("u16", row + L.row_count)
  if not list or not count then
    return nil
  end
  if list ~= ROW.list or ROW.list == 0 then
    if count ~= 2 then
      return nil -- not the retail two values: leave it
    end
    local p = our_list(list)
    if not p then
      return nil
    end
    write_memory("ptr", row + L.row_list, p)
    write_memory("u16", row + L.row_count, 3)
  end
  ROW.row_label = read_memory("u32", row + L.row_label) or ROW.row_label
  if is_draft_row(menu, row) then
    ROW.menu = menu
  end
  local base = read_memory("i32", row + L.row_base) or 0
  write_memory("i32", row + L.row_index, row_index(romaji(), saved_custom()) - base)
  return nil
end)

local pending_write

VRFW.on("hook:SettingRowWrite", function(ev)
  pending_write = nil
  local row = ev.args[2]
  if row < 0x10000 or ROW.list == 0 or read_memory("u32", row + L.row_type) ~= ROW_TYPE then
    return nil
  end
  local i, base = read_memory("i32", row + L.row_index), read_memory("i32", row + L.row_base)
  if not i or not base then
    return nil
  end
  local was = saved_custom()
  local chosen = math.max(i + base, 0)
  local retail = (chosen == IDX_ORIGINAL) and 1 or 0
  write_memory("i32", row + L.row_index, retail - base)
  pending_write = { row = row, i = i, before = row_index(romaji(), was), chosen = chosen, was = was, ours = chosen == IDX_CUSTOM, retail = retail }
  return nil
end)

VRFW.on("hook:SettingRowWrite:post", function(ev)
  local w = pending_write
  pending_write = nil
  if not w then
    return nil
  end
  write_memory("i32", w.row + L.row_index, w.i)
  if w.before ~= w.chosen then
    info(string.format("«Nombres de los personajes»: %s -> %s (the game stores «%s»)", VALUE_NAMES[w.before] or "?", VALUE_NAMES[w.chosen] or "?", w.retail == 1 and "Originales" or "Doblaje"))
  end
  if w.was ~= w.ours then
    local ok, why = VRFW.options.store({ [OPT_CUSTOM] = w.ours and 1 or 0 })
    opt_forget()
    if ok then
      info("«Por equipos» " .. (w.ours and "chosen" or "off") .. " (saved)")
    else
      warn("«Por equipos» " .. (w.ours and "chosen" or "off") .. ": not saved (" .. tostring(why) .. ")")
    end
  end
  return nil
end)

VRFW.on("game:reset", function()
  opt_forget()
  return nil
end)

start()
