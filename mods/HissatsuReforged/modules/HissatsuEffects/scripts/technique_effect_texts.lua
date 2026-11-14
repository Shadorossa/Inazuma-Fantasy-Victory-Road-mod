
HissatsuEffects = HissatsuEffects or {}
HissatsuEffects.RuleTexts = HissatsuEffects.RuleTexts or {}
local RuleTexts = HissatsuEffects.RuleTexts

local FOLDERS = { "rules", "content/rules", "features/*/content/rules" }

local cache = nil

local u32 = VRFW.ids.unsigned

local function as_list(v)
  if type(v) == "table" then
    return v
  end
  if v ~= nil then
    return { v }
  end
  return {}
end

-- a move named in a rule (internal key, <mod>.<name> or id) -> its id, nil = unknown
local function move_id(ref)
  if type(ref) == "number" then
    return u32(ref)
  end
  if type(ref) ~= "string" or ref == "" then
    return nil
  end
  local ok, id = pcall(VRFW.technique, ref)
  if ok and id ~= nil and u32(id) ~= 0 then
    return u32(id)
  end
  return nil
end

local function text_of(key, mod)
  local ok, v = pcall(VRFW.text, key)
  if ok and type(v) == "string" and v ~= "" then
    return v
  end
  local rest = string.match(key, "^[^%.]+%.(.+)$")
  if rest ~= nil and mod ~= nil then
    local ok2, v2 = pcall(VRFW.text, tostring(mod) .. "." .. rest)
    if ok2 and type(v2) == "string" and v2 ~= "" then
      return v2
    end
  end
  return ""
end

-- the change a rule's `do` makes, as shown next to its sentence: the one `*_mult` field as a signed percent
-- (1.12 -> "+12 %", 0.7 -> "-30 %"); nil when `do` has none or several
local function rule_value(d)
  if type(d) ~= "table" then
    return nil
  end
  local shown = nil
  for k, v in pairs(d) do
    if type(k) == "string" and type(v) == "number" and k:match("_mult$") then
      if shown ~= nil then
        return nil
      end
      local pct = math.floor((v - 1) * 1000 + 0.5) / 10
      shown = string.format("%s%g %%", pct >= 0 and "+" or "-", math.abs(pct))
    end
  end
  return shown
end

-- `s` without its leading value (the sentence's own "+12 %" / "+12%" when it starts with the rule's number) and its joining word, a
-- first lower-case ASCII letter raised; nil when it does not start with it
local function without_value(s, shown)
  local number = shown:match("^([%+%-]?[%d%.]+)")
  if number == nil then
    return nil
  end
  local alt = number:gsub("%.", ",")
  for _, n in ipairs({ number, alt }) do
    local plain = n:gsub("[%+%-%.]", "%%%0")
    local rest = s:match("^" .. plain .. "%s?%%%s+(.+)$")
    if rest ~= nil and rest ~= "" then
      -- the language's joining word goes with the value (text key value_row_lead: «de» in «+12 % de potencia»)
      local lead = text_of("HissatsuEffects.value_row_lead")
      if lead ~= "" and rest:sub(1, #lead + 1) == lead .. " " and #rest > #lead + 1 then
        rest = rest:sub(#lead + 2)
      end
      return (rest:gsub("^%l", string.upper))
    end
  end
  return nil
end

-- The lowest grade a rule's `when.grade` lets in (a number, a list of numbers or { min, max }); nil when the rule has no grade condition.
local function grade_floor(g)
  if type(g) == "number" then
    return g
  end
  if type(g) ~= "table" then
    return nil
  end
  local low = tonumber(g.min)
  for _, v in ipairs(g) do
    if type(v) == "number" and (low == nil or v < low) then
      low = v
    end
  end
  return low or 1
end

-- move id -> list of { key, mod, value, grade } (load order, each key once); grade: the rule holds from that grade on, nil = at every grade
local function build_index()
  local index = {}
  local ok, files = pcall(VRFW.files.declarations, FOLDERS, "rule")
  if not ok or type(files) ~= "table" then
    VRFW.warn("technique effect texts: the rule files could not be read: " .. tostring(files))
    return index
  end
  for _, f in ipairs(files) do
    local rules = type(f.data) == "table" and f.data.rule or nil
    for _, r in ipairs(type(rules) == "table" and rules or {}) do
      local key = type(r) == "table" and type(r.text) == "string" and r.text or ""
      local when = type(r) == "table" and type(r.when) == "table" and r.when or {}
      if key ~= "" and r.enabled ~= false then
        local value = rule_value(r["do"])
        if not string.find(key, ".", 1, true) then
          key = tostring(f.mod) .. "." .. key
        end
        -- a rule about the opponent of a move (`when.rival.technique`, no `when.technique`) describes that move
        local refs = as_list(when.technique)
        if #refs == 0 and type(when.rival) == "table" then
          refs = as_list(when.rival.technique)
        end
        for _, ref in ipairs(refs) do
          local id = move_id(ref)
          if id ~= nil then
            local list = index[id] or {}
            local seen = false
            for _, e in ipairs(list) do
              if e.key == key then
                seen = true
              end
            end
            if not seen then
              list[#list + 1] = { key = key, mod = f.mod, value = value, grade = grade_floor(when.grade) }
            end
            index[id] = list
          end
        end
      end
    end
  end
  return index
end

-- the index, built once and kept between starts (mod rule files and move ids only)
local function load_all()
  if cache == nil then
    cache = VRFW.derived("technique_effect_texts_3", nil, build_index)
  end
  return cache
end

-- built at load, so neither a slot load nor the first move card reads every rule file
load_all()

-- The effects the move has at every grade (a rule with `when.grade` is a grade effect: GradesOfMove).
-- (move) -> { count, [i] = sentence, value = { [i] = "+12 %" or nil }, rest = { [i] = the sentence without its
-- leading value, or nil } }
function RuleTexts.OfMove(move)
  local out = { count = 0, value = {}, rest = {} }
  for _, e in ipairs(load_all()[u32(move)] or {}) do
    local s = e.grade == nil and text_of(e.key, e.mod) or ""
    if s ~= "" then
      out.count = out.count + 1
      out[out.count] = s
      out.value[out.count] = e.value
      out.rest[out.count] = e.value ~= nil and without_value(s, e.value) or nil
    end
  end
  return out
end

-- CMND_HISSATSUEFFECTS_MOVE_GRADE_TEXTS(move) -> { count, [i] = { level, kind = "effect", text, shown } }: the effects the
-- move gains at a grade (the rules that name it with `when.grade`), in grade order; level = the lowest grade of the
-- rule, text = its sentence (without its leading value when `shown` carries it).
function RuleTexts.GradesOfMove(move)
  local out = { count = 0 }
  for _, e in ipairs(load_all()[u32(move)] or {}) do
    local s = e.grade ~= nil and text_of(e.key, e.mod) or ""
    if s ~= "" then
      local rest = e.value ~= nil and without_value(s, e.value) or nil
      out.count = out.count + 1
      out[out.count] = { level = e.grade, kind = "effect", text = rest or s, shown = rest ~= nil and e.value or nil }
    end
  end
  table.sort(out, function(p, q) return p.level < q.level end)
  return out
end
