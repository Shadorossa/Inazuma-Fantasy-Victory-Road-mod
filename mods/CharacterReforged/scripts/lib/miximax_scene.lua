
local M = {}

M.EVENT, M.MAP, M.FINAL_EVENT = "ev99_97010", "evtgx_tm_i", "ev99_97020"
local SCENE_EVENT_FILE = "data/common/event_cfg/evt/ev99_97010.cfg.bin"
local FINAL_KEY = "data/common/event_cfg/evt/ev99_97020.cfg.bin"
local function template_key(k) return (k:gsub("%.cfg%.bin$", ".template.cfg.bin")) end
-- placeholders of the template lists (content\anims\miximax_scene.toml)
local MODEL_S00, MODEL_S01, BODY_TOKEN = "c99999901_mx_scene_base_", "c99999902_mx_scene_aura_", "c000101"
local PATH_S00 = "common/event/ev99/ev99_97010/ev99_97010_c000101_s00_p00_c0010.g4pk"
local PATH_S01 = "common/event/ev99/ev99_97010/ev99_97010_c000101_s01_p00_c0010.g4pk"
local PATH_F00 = "common/event/ev99/ev99_97020/ev99_97020_c000101_s00_p00_c0010.g4pk"
local RIGS = { "c000101", "c000201", "c000301", "c000401" }

local Id = VRFW.ids
local info, warn = VRFW.logger("CharacterReforged miximax: scene")

local function u32le(s, at)
  local a, b, c, d = s:byte(at + 1, at + 4)
  if not d then return nil end
  return a + b * 256 + c * 65536 + d * 16777216
end

function M.patch_strings(t2b, subst)
  for _, p in ipairs(subst) do
    if #p[2] > #p[1] or #p[2] == 0 then return nil, string.format("%s -> %s: the replacement must be 1..%d bytes", p[1], p[2], #p[1]) end
    if p[2]:find("\0", 1, true) then return nil, p[2] .. ": NUL inside" end
  end
  if #t2b < 16 then return nil, "not a T2B file (too short)" end
  local so, ss = u32le(t2b, 4), u32le(t2b, 8)
  if so == 0 or so + ss > #t2b then return nil, string.format("string pool 0x%X+0x%X outside the file (0x%X)", so, ss, #t2b) end
  local parts, counts = { t2b:sub(1, so) }, {}
  for i = 1, #subst do counts[i] = 0 end
  local p, pend = so + 1, so + ss
  while p <= pend do
    local z = t2b:find("\0", p, true)
    local e = (z and z <= pend) and z - 1 or pend
    local s = t2b:sub(p, e)
    for k, q in ipairs(subst) do
      if s == q[1] then
        s = q[2] .. string.rep("\0", #q[1] - #q[2])
        counts[k] = counts[k] + 1
        break
      end
    end
    parts[#parts + 1] = s
    if e < pend then parts[#parts + 1] = "\0" end
    p = e + 2
  end
  parts[#parts + 1] = t2b:sub(pend + 1)
  return table.concat(parts), counts
end

local function all_found(c)
  for _, n in ipairs(c) do if n == 0 then return false end end
  return true
end

function M.rig_of_skeleton(skel)
  local s = tostring(skel or ""):lower()
  for _, r in ipairs(RIGS) do
    if s:find(r, 1, true) then return r end
  end
  return nil
end

local LISTS = {}

local function boot(key, placeholders)
  local tpl, why = VRFW.files.game_read(template_key(key))
  if not tpl then tpl, why = VRFW.files.game_read(key) end
  if not tpl then return nil, tostring(why) .. " (not installed)" end
  local probe = {}
  for i, ph in ipairs(placeholders) do probe[i] = { ph, ph } end
  local _, c = M.patch_strings(tpl, probe)
  if not c or not all_found(c) then return nil, string.format("%s: placeholders missing", key) end
  local ok, e = VRFW.files.serve(key, tpl)
  if not ok then return nil, tostring(e) end
  return { key = key, tpl = tpl }
end

local function serve_play(l, subst)
  local out, c = M.patch_strings(l.tpl, subst)
  if not out then return nil, c end
  if not all_found(c) then return nil, "placeholders missing in the template" end
  if #out ~= #l.tpl then return nil, string.format("size %d differs from the served size %d", #out, #l.tpl) end
  local ok, e = VRFW.files.serve(l.key, out)
  if not ok then return nil, tostring(e) end
  return c
end

local function name_ok(n) return type(n) == "string" and #n > 0 and #n <= #MODEL_S00 and not n:find("[%z\128-\255]") end

local ACTOR_PREFIX, ACTOR_CHARS, ACTOR_FILLER, ACTOR_CHAR_BITS = "mx_", 8, 0x60, { 0, 2, 3, 4 }

local function actor_text(picks)
  local chars = {}
  for pos = 1, ACTOR_CHARS do
    local code = ACTOR_FILLER
    for k, char_bit in ipairs(ACTOR_CHAR_BITS) do
      if bit32.extract(picks, (pos - 1) * #ACTOR_CHAR_BITS + k - 1) == 1 then code = code + 2 ^ char_bit end
    end
    chars[pos] = string.char(code)
  end
  return ACTOR_PREFIX .. table.concat(chars)
end

local function text_with_crc(id)
  local start = VRFW.crc32(actor_text(0))
  local pivots = {}
  for bit = 0, ACTOR_CHARS * #ACTOR_CHAR_BITS - 1 do
    local picks = bit32.lshift(1, bit)
    local delta = bit32.bxor(VRFW.crc32(actor_text(picks)), start)
    for _, p in ipairs(pivots) do
      if bit32.btest(delta, p.low) then delta, picks = bit32.bxor(delta, p.delta), bit32.bxor(picks, p.picks) end
    end
    if delta ~= 0 then pivots[#pivots + 1] = { delta = delta, picks = picks, low = bit32.band(delta, -delta) } end
  end
  local rest, picks = bit32.bxor(id, start), 0
  for _, p in ipairs(pivots) do
    if bit32.btest(rest, p.low) then rest, picks = bit32.bxor(rest, p.delta), bit32.bxor(picks, p.picks) end
  end
  local text = actor_text(picks)
  if rest ~= 0 or VRFW.crc32(text) ~= id then return nil end
  return text
end

local function actor_name(label, id)
  local chara = Id.unsigned(id)
  if chara == 0 then return nil end
  if name_ok(label) and VRFW.crc32(label) == chara then return label end
  local text = text_with_crc(chara)
  if text then info(string.format("actor string of chara %s (label %s): %s", Id.hex_text(chara), tostring(label), text)) end
  return text
end

function M.load()
  local why
  LISTS.main, why = boot(SCENE_EVENT_FILE, { MODEL_S00, MODEL_S01, PATH_S00, PATH_S01 })
  if LISTS.main then info(M.EVENT, "served (" .. #LISTS.main.tpl .. " bytes)") else warn(M.EVENT, "not served:", why) end
  LISTS.final, why = boot(FINAL_KEY, { MODEL_S00, PATH_F00 })
  if LISTS.final then info(M.FINAL_EVENT, "served (final shot)") else info(M.FINAL_EVENT, "not served (" .. tostring(why) .. "): the main event alone") end
end

local function effect_report()
  local eff = VRFW.files.game_read("data/common/event_cfg/eff/" .. M.EVENT .. "_eff.cfg.bin")
  if not eff or #eff < 16 then return 0, 0, "" end
  local so, ss = u32le(eff, 4), u32le(eff, 8)
  if so == 0 or so + ss > #eff then return 0, 0, "" end
  local n, ok, list = 0, 0, {}
  for s in eff:sub(so + 1, so + ss):gmatch("[^%z]+") do
    if s:sub(1, 14) == "common/effect/" and s:sub(-7) == ".objbin" then
      local stem = s:sub(1, -8)
      local tex = stem:gsub("^common/", "dx11/", 1)
      local files = { "data/" .. s, "data/" .. stem .. ".g4pkm", "data/" .. stem .. ".g4mg", "data/" .. tex .. ".g4tx" }
      local found = 0
      for _, f in ipairs(files) do if VRFW.files.game_exists(f) then found = found + 1 end end
      n = n + 1
      if found == 4 then ok = ok + 1 end
      list[#list + 1] = (stem:match("[^/]+$") or stem) .. ":" .. found .. "/4"
    end
  end
  return n, ok, table.concat(list, " ")
end

local PENDING = nil
local PENDING_MAX_S = 90

function M.prepare(base_hdl, f)
  if not LISTS.main then return false, "the scene is not installed / not served this session" end
  local base_name, partner_name = actor_name(f.base, f.base_chara), actor_name(f.partner, f.partner_chara)
  if not base_name or not partner_name then
    return false, string.format("no actor string for chara %s / %s", tostring(f.base_chara), tostring(f.partner_chara))
  end
  local function rig(param)
    local b = VRFW.miximax.call { op = "body", param = param }
    return (type(b) == "table" and M.rig_of_skeleton(b[2])) or RIGS[1]
  end
  local rb, rp = rig(f.base_param), rig(f.partner_param)
  local c, why = serve_play(LISTS.main, {
    { MODEL_S00, base_name }, { MODEL_S01, partner_name },
    { PATH_S00, (PATH_S00:gsub(BODY_TOKEN, rb, 1)) }, { PATH_S01, (PATH_S01:gsub(BODY_TOKEN, rp, 1)) },
  })
  if not c then return false, why end
  local fin = ""
  if LISTS.final then
    local c2, why2 = serve_play(LISTS.final, { { MODEL_S00, base_name }, { PATH_F00, (PATH_F00:gsub(BODY_TOKEN, rb, 1)) } })
    if c2 then
      fin = M.FINAL_EVENT
      info(string.format("final shot %s = %s (%s), strings replaced [%s]", M.FINAL_EVENT, base_name, rb, table.concat(c2, ", ")))
    else
      warn(string.format("final shot %s not prepared (%s): the main event alone", M.FINAL_EVENT, tostring(why2)))
    end
  else
    info("final shot not served this session: the main event alone")
  end
  local n, ok, list = effect_report()
  info(string.format("effects: %d object(s) in the eff list, %d with all 4 files installed [%s]", n, ok, list))
  PENDING = { base = base_hdl, at = VRFW.now_ms() }
  info(string.format("%s = %s (%s) + %s (%s, card 0x%08X), strings replaced [%s]", M.EVENT, base_name, rb, partner_name, rp, f.partner_hdl, table.concat(c, ", ")))
  return true, fin, ok
end

function M.state()
  if PENDING and (VRFW.now_ms() - PENDING.at) / 1000 > PENDING_MAX_S then
    info(string.format("ended (timeout %d s) base 0x%08X", PENDING_MAX_S, PENDING.base))
    PENDING = nil
  end
  if not PENDING then return false, 0, 0 end
  return true, PENDING.base, math.floor((VRFW.now_ms() - PENDING.at) / 1000)
end

function M.ended(why)
  if PENDING then
    info(string.format("ended (%s) base 0x%08X after %.1f s", why, PENDING.base, (VRFW.now_ms() - PENDING.at) / 1000))
    PENDING = nil
  end
end

return M
