
BetterQoL = BetterQoL or {}
BetterQoL.TechPreview = BetterQoL.TechPreview or {}
local TP = BetterQoL.TechPreview

local info, warn = VRFW.logger("tech_preview")

local Id = VRFW.ids
local u32, hex = Id.unsigned, Id.hex_text

local cfg = {
  -- the squad's first `lineup` members are the starters
  lineup = 11,
  positions = { ["1"] = 2, ["2"] = 3, ["3"] = 4, ["4"] = 1 },
  -- prefer a player whose card learns the move
  prefer_learners = true,
  need_any_menu = { "team_dock_common_top_menu", "soccer_top_menu" },
  off_with_menus = { "chronicle_mode_top_menu", "team_dock_menu_rpg_battle" },
  hide_menus = { "ability_list_menu", "sub_window", "item_filter_menu", "ability_learning_board_menu",
    "personal_plate_menu", "team_dock_formation_menu", "soccer_formation_menu", "soccer_team_dock_menu",
    "team_dock_common_top_menu", "soccer_top_menu" },
  -- header / guide layers hidden in those menus
  bar_menus = { "team_dock_common_top_menu", "soccer_top_menu", "soccer_team_dock_menu" },
  bar_layers = { "mainmenu90_01_header", "mainmenu90_03_header_rank", "mainmenu90_31_doc_item",
    "mainmenu90_05_content_guide_line01", "mainmenu90_06_content_guide_line03", "mainmenu01_06_base_button_guide" },
  -- menu holding the performer's model (an event over the menus only binds actors to models a menu holds)
  carrier_menu = "chara_model_only_view_menu",
  carrier_layer = "rpg99_99_chara_model_only_view",
  backdrop = "bg10000",
  -- prompt offset from the card's retail page guide (menu px, x right / y up)
  hint_x = 0,
  hint_y = 0,
  fade_s = 0.3,
  bgm_fade_s = 0.5,
  model_wait_frames = 300,
  max_seconds = 120,
  -- B ends the cut-in.
  back_skips = true,
  -- log every answer of CMND_BETTERQOL_TECH_PREVIEW
  log_queries = false,
}

do
  local c = VRFW.config("tech_preview")
  if type(c) == "table" then
    for k, v in pairs(c) do
      if cfg[k] ~= nil and type(v) == type(cfg[k]) then cfg[k] = v end
    end
  end
end

-- a served table's rows, or nil and the error
local function table_rows(path)
  local ok, rows = pcall(VRFW.table.rows, path)
  if ok and type(rows) == "table" then return rows end
  return nil, rows
end

local MOVES = nil     -- skill id -> { event, category, players }
local function moves()
  if MOVES then return MOVES end
  MOVES = {}
  local rows, err = table_rows("skill/skill")
  if not rows then
    warn("skill/skill not readable: " .. tostring(err) .. " (no preview)")
    return MOVES
  end
  local n = 0
  for _, r in ipairs(rows) do
    local ev = r.event_id_name
    if type(ev) == "string" and ev ~= "" then
      MOVES[u32(r.skill_id)] = { event = ev, category = tonumber(r.category) or 0, players = tonumber(r.partner_type) or 0 }
      n = n + 1
    end
  end
  info(n .. " moves with a cut-in (skill/skill event_id_name)")
  return MOVES
end

-- does card `param` learn move `skill`?
local function learns(param, skill)
  if not (VRFW.learn and VRFW.learn.learnset) then return nil end
  local ok, set = pcall(VRFW.learn.learnset, param)
  if not ok or type(set) ~= "table" then return nil end
  for _, e in ipairs(set) do
    if type(e) == "table" and u32(e[1] or e.move) == skill then return true end
  end
  return false
end

local MODEL_BODY = nil   -- chara_model id -> rig 1-4
local function rig_of_path(p)
  local d = tostring(p or ""):match("c000(%d)01")
  local n = tonumber(d)
  if n and n >= 1 and n <= 4 then return n end
  return nil
end
local function model_bodies()
  if MODEL_BODY then return MODEL_BODY end
  MODEL_BODY = {}
  local by_body = {}
  for _, b in ipairs(table_rows("character/chara_body") or {}) do by_body[u32(b.id)] = rig_of_path(b.skeleton_path) end
  local models, err = table_rows("character/chara_model")
  if models then
    for _, m in ipairs(models) do
      MODEL_BODY[u32(m.id)] = by_body[u32(m.body)] or rig_of_path(m.skeleton_path)
    end
  else
    warn("character/chara_model not readable: " .. tostring(err) .. " (body rig 1 for everyone)")
  end
  return MODEL_BODY
end

local BASE_MODEL = nil   -- chara_base id -> chara_model id
local function base_model(base)
  if not BASE_MODEL then
    BASE_MODEL = {}
    for _, r in ipairs(table_rows("character/chara_base") or {}) do
      local id = u32(r.id)
      if id ~= 0 and BASE_MODEL[id] == nil then BASE_MODEL[id] = u32(r.model) end
    end
  end
  return BASE_MODEL[u32(base)]
end

local Memory = VRFW.memory
local Squads = VRFW.squads

local function squad()
  local party = VRFW.game.global("team_template_party")
  if party == nil then return nil, "no party" end
  local logical = Squads.active(party)
  if logical == nil or logical >= Squads.layout().set_count then return nil, "no active squad" end
  local team = Squads.squad(logical, party)
  if team == nil then return nil, "no squad data" end
  local out = {}
  for _, member in ipairs(Squads.members(team, 0)) do
    local okr, r = pcall(VRFW.character.record, member.handle)
    if okr and type(r) == "table" and type(r.param) == "number" then
      local okc, card = pcall(VRFW.character.card, r.param)
      card = okc and card or nil
      out[#out + 1] = { hdl = member.handle, param = u32(r.param), base = card and card.base or nil,
        position = card and tonumber(card.position) or 0, slot = member.slot }
    end
  end
  if #out == 0 then return nil, "the active squad is empty" end
  return out
end

local function pick(members, skill, want)
  local lineup = math.max(1, tonumber(cfg.lineup) or 11)
  local known = {}
  local function knows(m)
    if not cfg.prefer_learners then return false end
    if known[m.param] == nil then known[m.param] = learns(m.param, skill) == true end
    return known[m.param]
  end
  local passes = {
    { "starter, position + learns it", function(m, i) return i <= lineup and m.position == want and knows(m) end },
    { "starter, learns it", function(m, i) return i <= lineup and knows(m) end },
    { "starter at the position", function(m, i) return i <= lineup and m.position == want end },
    { "bench, position + learns it", function(m, i) return i > lineup and m.position == want and knows(m) end },
    { "bench at the position", function(m, i) return i > lineup and m.position == want end },
    { "first starter", function(_, i) return i == 1 end },
  }
  for _, p in ipairs(passes) do
    for i, m in ipairs(members) do
      if m.base and p[2](m, i) then return m, p[1] end
    end
  end
  return nil, "no member with a character"
end

local last_logged = nil

-- CMND_BETTERQOL_TECH_PREVIEW(skill) -> ok (0 / 1), event, performer handle, chara name, body (1-4), category, why
function TP.Plan(skill)
  skill = u32(skill)
  local function no(why)
    if cfg.log_queries and last_logged ~= skill then
      last_logged = skill
      info("move " .. hex(skill) .. ": no preview (" .. why .. ")")
    end
    return 0, "", 0, "", 0, 0, why
  end
  if skill == 0 then return no("no move") end
  local mv = moves()[skill]
  if not mv then return no("not a special move with a cut-in") end
  local want = tonumber(cfg.positions[tostring(mv.category)]) or 0
  local members, why = squad()
  if not members then return no(why) end
  local m, how = pick(members, skill, want)
  if not m then return no(how) end
  local okc, ch = pcall(VRFW.character.character, m.base)
  local name = okc and type(ch) == "table" and ch.name or nil
  if type(name) ~= "string" or name == "" then return no("the performer's character has no name") end
  local body = model_bodies()[base_model(m.base) or 0] or 1
  if cfg.log_queries and last_logged ~= skill then
    last_logged = skill
    info(string.format("move %s: %s (category %d, %d player(s)) by %s (card %s, slot %d, position %d: %s), body %d",
      hex(skill), mv.event, mv.category, math.max(1, mv.players), name, hex(m.param), m.slot, m.position, how, body))
  end
  return 1, mv.event, m.hdl, name, body, mv.category, how
end

local function crcs(list)
  local out = {}
  for i, s in ipairs(list or {}) do out[i] = VRFW.crc32(s) end
  return out
end

-- CMND_BETTERQOL_TECH_PREVIEW_CFG() -> the menu side's tunables
function TP.Config()
  return {
    need_any = crcs(cfg.need_any_menu), off_with = crcs(cfg.off_with_menus), hide = crcs(cfg.hide_menus),
    bar_menus = crcs(cfg.bar_menus), bar_layers = crcs(cfg.bar_layers),
    carrier = VRFW.crc32(cfg.carrier_menu), carrier_layer = VRFW.crc32(cfg.carrier_layer),
    backdrop = cfg.backdrop ~= "" and VRFW.crc32(cfg.backdrop) or 0,
    hint_x = tonumber(cfg.hint_x) or 0, hint_y = tonumber(cfg.hint_y) or 0,
    fade_s = tonumber(cfg.fade_s) or 0.3, bgm_fade_s = tonumber(cfg.bgm_fade_s) or 0.5,
    model_wait = tonumber(cfg.model_wait_frames) or 300, max_frames = math.floor((tonumber(cfg.max_seconds) or 120) * 60),
    back_skips = cfg.back_skips and 1 or 0,
  }
end

do
  local ok, e = pcall(function()
    local t = VRFW.derived("tech_preview_tables", nil, function()
      moves(); model_bodies(); base_model(0)
      return { moves = MOVES, model_body = MODEL_BODY, base_model = BASE_MODEL }
    end)
    MOVES, MODEL_BODY, BASE_MODEL = t.moves, t.model_body, t.base_model
  end)
  if not ok then
    warn("tables not read at load (" .. tostring(e) .. "): read when a card asks")
    MOVES, MODEL_BODY, BASE_MODEL = nil, nil, nil
  end
end
info("ready")
