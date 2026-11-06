-- Signature Passives › own passives («Pasiva propia»): one passive per player in the custom passive slot (board equip
-- slot 9): the GamePassive block of his special passives (content\special_passives\, read by the framework's passive
-- engine library VRFW/lib/passives), or an older content\own_passives\*.toml declaration (schema
-- PersonalPassives.own_passives/1) of any active mod. The
-- engine entries are content\game\own_passives.toml. This script fills their native tables:
--
--   PersonalPassives.OwnPassive  (chara_param id) -> passive id   the slot reader answers it (no entry = empty slot)
--   PersonalPassives.AlwaysOpen  (chara_param id) -> 1            the piece gate answers it (unlock = "always")
--
--   CMND_PERSONALPASSIVES_OWN_PASSIVE(charaStHdl) -> passive id (0 = none), always open, declaring mod
--        the skill boards' Lua (graft signature_passives_board) asks it to draw the slot and its detail window.
--   CMND_PERSONALPASSIVES_PASSIVE_ICON(game passive id) -> buff icon sprite crc (0 = the game's icon)
--        the passive's icon of content\passive_icons\*.toml (PersonalPassives.passive_icon/1, any active mod), drawn by
--        the menus' passive windows (assets\lua\_all\signature_passives_icon.lua).
--   CMND_PERSONALPASSIVES_PASSIVE_SAGA(game passive id, charaHdl) -> the series number its player traits name (0 =
--        none or several): the own passive card draws that series' icon (assets\lua\_all\signature_passives_display.lua).
--   CMND_PERSONALPASSIVES_ELEMENT_ICON(game passive id) -> the card's element icon sprite crc (0 = none): the
--        [[ElementIcon]] of its [[PassiveIcon]]'s `element` (content\passive_icons\element_icons.toml).
--
-- Nothing calls the game at load: the tables are built from files (the declarations and the character index).

PersonalPassives = PersonalPassives or {}
PersonalPassives.Cmd = PersonalPassives.Cmd or {}
local SP = PersonalPassives

require "VRFW/lib/basics"
local info, warn = VRFW.logger("own_passives")

local L = require "VRFW/lib/passives"
local OWN_KIND = "PersonalPassives.own_passives/1"

local T_OWN, T_OPEN = "PersonalPassives.OwnPassive", "PersonalPassives.AlwaysOpen"

local BY_CARD = nil          -- [chara_param id] = { passive = id, always = bool, mod = id }
local BUILD_ERROR = nil
local u32 = L.u32

-- ---------------------------------------------------------------------------------------------- own passive slot

-- [card id] = { passive = id, always = bool, mod = id }: the GamePassive block of each character's passives, and the
-- older content\own_passives\*.toml declarations. A later entry for the same card replaces an earlier one.
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
  local ok, files = pcall(VRFW.files.declarations, "content/own_passives")
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local doc = f.data
    local where0 = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    if type(doc) ~= "table" or doc.schema ~= OWN_KIND then
      warn(where0 .. ": schema is not " .. OWN_KIND .. " (file left out)")
    else
      for k, e in ipairs(type(doc.own_passive) == "table" and doc.own_passive or {}) do
        local where = string.format("%s [[own_passive]] #%d", where0, k)
        local passive = L.id_of(e.passive)
        local unlock = e.unlock == nil and "board" or e.unlock
        if unlock ~= "board" and unlock ~= "always" then
          warn(where .. ": unlock must be \"board\" or \"always\" (taken as \"board\")")
          unlock = "board"
        end
        if passive == nil or passive == 0 then
          warn(where .. ": no passive (left out)")
        elseif e.character == nil and e.card == nil then
          warn(where .. ": needs `character` or `card` (left out)")
        else
          n_entries = n_entries + 1
          put(L.cards_of({ character = e.character, card = e.card }), passive, unlock == "always", tostring(f.mod), where)
        end
      end
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

local function fill()
  local ok, map, n_entries, icons = pcall(build)
  if not ok or map == nil then
    BUILD_ERROR = tostring(ok and n_entries or map)
    return false
  end
  ICONS = ICONS or icons
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

-- ---------------------------------------------------------------------------------------------- for other scripts

-- the own passive of a card: passive id (0 = none), always open, declaring mod
function SP.OwnPassiveOfCard(card)
  if not ready() then return 0, false, nil end
  local e = BY_CARD[u32(card)]
  if e == nil then return 0, false, nil end
  return e.passive, e.always, e.mod
end

-- ---------------------------------------------------------------------------------------------- passive icons

local ICON_KIND = "PersonalPassives.passive_icon/1"

-- an icon value as a sprite crc: a [[VRFW.Icon]] id "<mod>.<name>" (Kind = "passive_icon": its sprite of the buff icon
-- atlas), else a sprite name of the buff icon atlas; nil = none / an icon no active mod declares
local function icon_sprite(v)
  if type(v) ~= "string" or v == "" then return nil end
  if v:match("^[%w_]+%.[%w_]+$") then
    local ok, r = pcall(VRFW.icons.resolve, v)
    return (ok and type(r) == "table") and r.picture_id or nil
  end
  return L.id_of(v)
end

-- content\passive_icons\*.toml of every active mod: [[PersonalPassives.PassiveIcon]] passive (its GamePassive block
-- names the game passive) -> icon (sprite name or [[VRFW.Icon]] id). A later entry for the same game passive replaces an
-- earlier one; a passive's own `icon` ([[VRFW.Passive]]) replaces them.
function build_icons()
  local d = L.data(function() end)
  local map, n = {}, 0
  local ok, files = pcall(VRFW.files.declarations, "content/passive_icons")
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local doc = f.data
    local where0 = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    local list = type(doc) == "table" and type(doc.PersonalPassives) == "table" and doc.PersonalPassives.PassiveIcon
    if type(doc) ~= "table" or doc.schema ~= ICON_KIND then
      warn(where0 .. ": schema is not " .. ICON_KIND .. " (file left out)")
    else
      for k, e in ipairs(type(list) == "table" and list or {}) do
        local p = L.lookup(d.passives, tostring(f.mod), e.passive)
        local passive = p and p.slot and L.id_of(p.slot.v.passive)
        local sprite = icon_sprite(e.icon)
        if passive == nil or passive == 0 or sprite == nil then
          warn(string.format("%s [[PersonalPassives.PassiveIcon]] #%d: %s (left out)", where0, k,
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

-- ---------------------------------------------------------------------------------------------- commands

-- the custom passive slot as its two readers answer it (every subscriber's answer): passive id, open, ""
local BUF_ID, BUF_HDL = nil, nil
local function live_signature(hdl)
  if not BUF_ID then
    BUF_ID = VRFW.mem.buffer("signature_passives_own_live_id", 8)
    BUF_HDL = VRFW.mem.buffer("signature_passives_own_live_hdl", 4)
  end
  VRFW.mem.write("u32", BUF_ID, 0)
  if not pcall(VRFW.call, "Passive.SignatureSlotId", BUF_ID, hdl) then return 0, false, "" end
  local id = VRFW.mem.read("u32", BUF_ID) or 0
  VRFW.mem.write("u32", BUF_HDL, hdl)
  local ok, open = pcall(VRFW.call, "Passive.SignaturePieceOpen", BUF_HDL)
  return id, ok and tonumber(open) ~= nil and tonumber(open) % 256 ~= 0, ""
end

function SP.Cmd.OwnPassive(hdl)
  hdl = u32(hdl)
  if hdl == 0 then return 0, false, "" end
  -- a mode without player passives (the framework's vrfw.passive.all_off): the boards show the slot empty
  local okoff, off = pcall(VRFW.state.get, "vrfw.passive.all_off")
  if okoff and tonumber(off) == 1 then return 0, false, "" end
  -- a framework signature-only mode (vrfw.passive.slots_off): the slot shows what its readers answer
  local okmode, mode = pcall(VRFW.state.get, "vrfw.passive.slots_off")
  if okmode and tonumber(mode) == 1 then return live_signature(hdl) end
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

-- the own passive card's element icon: content\passive_icons\*.toml [[ElementIcon]] (element -> sprite) and the
-- `element` of each [[PassiveIcon]] (its effect improves the moves of that element); built on first use
local ELEMENT_ICONS = nil    -- [game passive id] = sprite crc

local function build_element_icons()
  local d = L.data(function() end)
  local by_element, map, n = {}, {}, 0
  local ok, files = pcall(VRFW.files.declarations, "content/passive_icons")
  files = (ok and type(files) == "table") and files or {}
  for _, f in ipairs(files) do
    local doc = f.data
    local list = type(doc) == "table" and doc.schema == ICON_KIND and type(doc.PersonalPassives) == "table"
      and doc.PersonalPassives.ElementIcon
    for _, e in ipairs(type(list) == "table" and list or {}) do
      if type(e.element) == "string" and type(e.icon) == "string" and e.icon ~= "" then
        by_element[e.element] = L.id_of(e.icon)
      end
    end
  end
  for _, f in ipairs(files) do
    local doc = f.data
    local list = type(doc) == "table" and doc.schema == ICON_KIND and type(doc.PersonalPassives) == "table"
      and doc.PersonalPassives.PassiveIcon
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

-- (game passive id) -> the own passive card's element icon (sprite crc of the icon_teambuff atlas or a redirected
-- own atlas), 0 = none
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

-- the series a game passive's player traits name (its Count / Present / Absent / Holder blocks): one series, or the
-- holder's own (same_saga_as_holder); nil when it names none or several
local SAGA_OF = nil          -- [game passive id] = { names = { series name … }, own = bool }

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

-- ---------------------------------------------------------------------------------------------- start

if not fill() then
  info("tables not built at load (" .. tostring(BUILD_ERROR) .. "); built on first use")
end
-- the passive windows' element icons and sagas, built at load (files and the character index only) instead of on the
-- first window drawn
element_icons()
sagas()
VRFW.on("slot_load", function()
  if BY_CARD == nil then fill() end
end)
