
CharacterReforged = CharacterReforged or {}
CharacterReforged.Cmd = CharacterReforged.Cmd or {}
local SP = CharacterReforged

local info, warn = VRFW.logger("own_passives")

local L = VRFW.passives

local T_OWN, T_OPEN = "CharacterReforged.OwnPassive", "CharacterReforged.AlwaysOpen"

local BY_CARD = nil          -- [chara_param id] = { passive = id, always = bool, mod = id }
local OWN_OPTION = "CharacterReforged.own_passives"   -- options.toml row, default 1, read once per start
local OWN_ON_STATE = "CharacterReforged.own_passives.on"   -- content\game\own_passives.toml: 0 lets the game's custom passives answer
local BUILD_ERROR = nil
local u32 = L.u32

local function own_slots(warn, info)
  local map, n_entries = {}, 0
  local function put(cards, passive, always, mod, where)
    if #cards == 0 then
      warn(where .. ": no card found (left out)")
      return
    end
    for _, c in ipairs(cards) do
      local before = map[c]
      if before ~= nil and before.mod ~= mod and info then
        info(string.format("card %s: the own passive of %s replaces the one of %s", L.hex(c), mod, before.mod))
      end
      map[c] = { passive = passive, always = always, mod = mod }
    end
  end
  for _, e in ipairs(L.data(warn).characters) do
    local slot = nil
    for _, p in ipairs(e.passives) do
      if p.slot then
        if slot then warn(e.where .. ": " .. p.key .. " also has a GamePassive block (his slot holds one: " .. slot.key .. ")") else slot = p.slot end
      end
    end
    if slot then
      local passive = L.id_of(slot.v.passive)
      if passive and passive ~= 0 then
        n_entries = n_entries + 1
        put(L.cards_of(e), passive, slot.v.unlock == "always", e.mod, e.where)
      end
    end
  end
  return map, n_entries
end

local build_icons

-- the own slots and the passive icons, built from the files once and kept between starts (VRFW.derived)
local function build()
  local function from_files()
    -- the block and passive files' problems are logged once, by the framework's scripts\passives.lua
    L.data(function() end)
    local map, n_entries = own_slots(warn, info)
    local okicons, icons = pcall(build_icons)
    if not okicons then warn("passive icons not read: " .. tostring(icons)) end
    return { map = map, n_entries = n_entries, icons = (okicons and type(icons) == "table") and icons or {} }
  end
  local kept = type(VRFW.derived) == "function" and VRFW.derived("own_passives", nil, from_files) or from_files()
  return kept.map, kept.n_entries, kept.icons
end

local ICONS = nil            -- [game passive id] = sprite crc

-- The option is read once per start: on, own passives fill the custom passive slot; off, the game's own custom passives do.
local function own_passives_on()
  local okopt, on = pcall(VRFW.option, OWN_OPTION)
  return not (okopt and (on == false or tonumber(on) == 0))
end

local OWN_ON = own_passives_on()

local function fill()
  local ok, map, n_entries, icons = pcall(build)
  if not ok or map == nil then
    BUILD_ERROR = tostring(ok and n_entries or map)
    return false
  end
  ICONS = ICONS or icons
  if not OWN_ON then
    map = {}
    info("option own_passives off: the game's custom passives fill the slot")
  end
  local own, open = {}, {}
  for card, e in pairs(map) do
    own[#own + 1] = { card, e.passive }
    if e.always then open[#open + 1] = { card, 1 } end
  end
  VRFW.native.table_replace(T_OWN, nil, own)
  VRFW.native.table_replace(T_OPEN, nil, open)
  BY_CARD, BUILD_ERROR = map, nil
  info(string.format("%d declaration(s), %d card(s) with an own passive, %d always open", n_entries, #own, #open))
  return true
end

-- a failed build is tried again once on first use and at each save load, never on every call
local USE_TRIED = false
local function ready()
  if BY_CARD == nil and not USE_TRIED then
    USE_TRIED = true
    if not fill() then warn("tables not built (" .. tostring(BUILD_ERROR) .. "): the own passive slot stays empty") end
  end
  return BY_CARD ~= nil
end

function SP.OwnPassiveOfCard(card)
  if not ready() then return 0, false, nil end
  local e = BY_CARD[u32(card)]
  if e == nil then return 0, false, nil end
  return e.passive, e.always, e.mod
end

local ICON_KIND = "CharacterReforged.passive_icon/1"

-- the mods' content\passive_icons files, read once for the passive icons and the element icons
local ICON_FILES = nil
local function icon_files()
  if ICON_FILES == nil then
    local ok, files = pcall(VRFW.files.declarations, "content/passive_icons")
    ICON_FILES = (ok and type(files) == "table") and files or {}
  end
  return ICON_FILES
end

local function icon_sprite(v)
  if type(v) ~= "string" or v == "" then return nil end
  if v:match("^[%w_]+%.[%w_]+$") then
    local ok, r = pcall(VRFW.icons.resolve, v)
    return (ok and type(r) == "table") and r.picture_id or nil
  end
  return L.id_of(v)
end

function build_icons()
  local d = L.data(function() end)
  local map, n = {}, 0
  for _, f in ipairs(icon_files()) do
    local doc = f.data
    local where0 = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    local list = type(doc) == "table" and type(doc.CharacterReforged) == "table" and doc.CharacterReforged.PassiveIcon
    if type(doc) ~= "table" or doc.schema ~= ICON_KIND then
      warn(where0 .. ": schema is not " .. ICON_KIND .. " (file left out)")
    else
      for k, e in ipairs(type(list) == "table" and list or {}) do
        local p = L.lookup(d.passives, tostring(f.mod), e.passive)
        local passive = p and p.slot and L.id_of(p.slot.v.passive)
        local sprite = icon_sprite(e.icon)
        if passive == nil or passive == 0 or sprite == nil then
          warn(string.format("%s [[CharacterReforged.PassiveIcon]] #%d: %s (left out)", where0, k,
            sprite == nil and "no icon" or "no passive with a GamePassive block named " .. tostring(e.passive)))
        else
          map[passive] = sprite
          n = n + 1
        end
      end
    end
  end
  for _, p in pairs(d.passives) do
    local passive = p.icon and p.slot and L.id_of(p.slot.v.passive)
    if passive and passive ~= 0 then
      local sprite = icon_sprite(p.icon)
      if sprite == nil then
        warn(string.format("%s: icon %s: no such icon (declare it with [[VRFW.Icon]], Kind = \"passive_icon\")", p.key, p.icon))
      else
        if map[passive] == nil then n = n + 1 end
        map[passive] = sprite
      end
    end
  end
  info(string.format("%d passive icon(s)", n))
  return map
end

local function icons()
  if ICONS == nil then
    local ok, map = pcall(build_icons)
    if not ok then warn("passive icons not read: " .. tostring(map)) end
    ICONS = (ok and type(map) == "table") and map or {}
  end
  return ICONS
end

local function live_signature(hdl)
  local id, open = VRFW.passives.own_passive(hdl, { id = "Passive.SignatureSlotId", open = "Passive.SignaturePieceOpen" })
  return id, open, ""
end

function SP.Cmd.OwnPassive(hdl)
  hdl = u32(hdl)
  if hdl == 0 then return 0, false, "" end
  local okoff, off = pcall(VRFW.state.get, "vrfw.passive.all_off")
  if okoff and tonumber(off) == 1 then return 0, false, "" end
  local okmode, mode = pcall(VRFW.state.get, "vrfw.passive.slots_off")
  if not OWN_ON or (okmode and tonumber(mode) == 1) then return live_signature(hdl) end
  local ok, r = pcall(VRFW.character.record, hdl)
  if not ok or type(r) ~= "table" or type(r.param) ~= "number" then return 0, false, "" end
  local passive, always, mod = SP.OwnPassiveOfCard(r.param)
  return passive, always, mod or ""
end

-- the buff icon of a game passive (sprite crc of the icon_teambuff atlas or a redirected own atlas), 0 = the game's
function SP.Cmd.PassiveIcon(passive)
  passive = u32(passive)
  if passive == 0 then return 0 end
  return icons()[passive] or 0
end

local ELEMENT_ICONS = nil    -- [game passive id] = sprite crc

local function build_element_icons()
  local d = L.data(function() end)
  local by_element, map, n = {}, {}, 0
  local files = icon_files()
  for _, f in ipairs(files) do
    local doc = f.data
    local list = type(doc) == "table" and doc.schema == ICON_KIND and type(doc.CharacterReforged) == "table"
      and doc.CharacterReforged.ElementIcon
    for _, e in ipairs(type(list) == "table" and list or {}) do
      if type(e.element) == "string" and type(e.icon) == "string" and e.icon ~= "" then
        by_element[e.element] = L.id_of(e.icon)
      end
    end
  end
  for _, f in ipairs(files) do
    local doc = f.data
    local list = type(doc) == "table" and doc.schema == ICON_KIND and type(doc.CharacterReforged) == "table"
      and doc.CharacterReforged.PassiveIcon
    for _, e in ipairs(type(list) == "table" and list or {}) do
      local sprite = type(e.element) == "string" and by_element[e.element] or nil
      if sprite then
        local p = L.lookup(d.passives, tostring(f.mod), e.passive)
        local passive = p and p.slot and L.id_of(p.slot.v.passive)
        if passive and passive ~= 0 then
          map[passive] = sprite
          n = n + 1
        end
      end
    end
  end
  local elements = 0
  for _ in pairs(by_element) do elements = elements + 1 end
  info(string.format("%d element icon(s) for %d passive(s)", elements, n))
  return map
end

local function element_icons()
  if ELEMENT_ICONS == nil then
    local ok, map = pcall(build_element_icons)
    if not ok then warn("element icons not read: " .. tostring(map)) end
    ELEMENT_ICONS = (ok and type(map) == "table") and map or {}
  end
  return ELEMENT_ICONS
end

function SP.Cmd.ElementIcon(passive)
  passive = u32(passive)
  if passive == 0 then return 0 end
  return element_icons()[passive] or 0
end

local SAGA_OF = nil

local function saga_traits()
  local map = {}
  local d = L.data(function() end)
  for _, p in pairs(d.passives) do
    local id = p.slot and L.id_of(p.slot.v.passive)
    if id and id ~= 0 then
      local e = { names = {}, own = false }
      for _, list in ipairs({ p.counts, p.conditions }) do
        for _, b in ipairs(list) do
          local t = b.trait and b.trait.v
          if t then
            for _, name in ipairs(t.series or {}) do e.names[#e.names + 1] = name end
            if t.same_saga_as_holder then e.own = true end
          end
        end
      end
      if #e.names > 0 or e.own then map[id] = e end
    end
  end
  return map
end

local function holder_series(hdl)
  local okr, r = pcall(VRFW.character.record, hdl)
  local card = (okr and type(r) == "table") and r.param or nil
  local okc, c = pcall(VRFW.character.card, card)
  local base = (okc and type(c) == "table") and c.base or nil
  local okh, ch = pcall(VRFW.character.character, base)
  return (okh and type(ch) == "table" and type(ch.series) == "number") and ch.series or nil
end

local function sagas()
  if SAGA_OF == nil then
    local ok, map = pcall(saga_traits)
    if not ok then warn("passive sagas not read: " .. tostring(map)) end
    SAGA_OF = (ok and type(map) == "table") and map or {}
  end
  return SAGA_OF
end

-- (game passive id, charaHdl) -> the series number its traits name (0 = none or several)
function SP.Cmd.PassiveSaga(passive, hdl)
  passive = u32(passive)
  if passive == 0 then return 0 end
  local e = sagas()[passive]
  if e == nil then return 0 end
  local found = nil
  for _, name in ipairs(e.names) do
    local ok, n = pcall(VRFW.character.series_of, name)
    if not ok or type(n) ~= "number" or (found ~= nil and found ~= n) then return 0 end
    found = n
  end
  if e.own then
    local n = holder_series(u32(hdl))
    if n == nil or (found ~= nil and found ~= n) then return 0 end
    found = n
  end
  return found or 0
end

do
  local okset, e = pcall(VRFW.state.set, OWN_ON_STATE, OWN_ON and 1 or 0)
  if not okset then warn(OWN_ON_STATE .. ": " .. tostring(e)) end
end
if not fill() then
  info("tables not built at load (" .. tostring(BUILD_ERROR) .. "); built on first use")
end
element_icons()
sagas()
-- The tables above are all the commands read, so the passive data leaves this VM before the first command.
L.release_data()
VRFW.on("save:slot_load", function()
  if BY_CARD == nil then fill() end
end)
