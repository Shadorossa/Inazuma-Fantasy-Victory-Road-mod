-- The Campaña's 7 matches are played on special-conditions fields: the maps of the game's stadium gimmick table.

local U = require "lib/util"
local G = require "lib/game"
local Block = require "lib/campaign_block"
local Active = require "active_team"

local info, warn = VRFW.logger("campaign fields")

local BLOB = "bb_campaign_fields.json"
local BLOB_VERSION = 2
local GIMMICK_TABLE = "data/common/gamedata/soccer/soccer_studium_gimmick_config"

local STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "campaign fields",
  version = BLOB_VERSION,
  default = function() return nil end,
  -- Version 1 kept the fields as map names, and version 2 kept their crc32 under the key "v".
  migrate = function(doc)
    if doc.v == 1 and type(doc.order) == "table" then
      for i, map in ipairs(doc.order) do
        doc.order[i] = type(map) == "string" and VRFW.crc32(map) or map
      end
    elseif doc.v ~= 2 then
      return nil, "version " .. tostring(doc.version or doc.v) .. " is not known"
    end
    doc.v, doc.version = nil, BLOB_VERSION
    return doc
  end,
  decode = function(doc)
    if type(doc.order) ~= "table" then return nil, "no field order" end
    return doc
  end,
})

local SEED = tonumber(U.config("campaign.seed", 0)) or 0

-- every map with a row in STUDIUM_GIMMICK_INFO (column 1 = the map hash), in the table's order
local function gimmick_fields()
  local ok, rows = pcall(VRFW.table.raw, VRFW.table_files.file_name(GIMMICK_TABLE), "STUDIUM_GIMMICK_INFO", { 1 })
  if not ok or type(rows) ~= "table" then
    warn("stadium gimmick table not readable (" .. tostring(rows) .. "): the Campaña keeps the rivals' stadiums")
    return {}
  end
  local fields, seen = {}, {}
  for _, r in ipairs(rows) do
    local map = type(r[1]) == "number" and VRFW.ids.unsigned(r[1]) or 0
    if map ~= 0 and not seen[map] then
      seen[map] = true
      fields[#fields + 1] = map
    end
  end
  info(string.format("%d special-conditions fields for the Campaña", #fields))
  return fields
end

local FIELDS = nil
local function fields()
  if FIELDS == nil then
    FIELDS = gimmick_fields()
  end
  return FIELDS
end

-- true while a Decide of the free match grid runs: its request is never the Campaña's
local free_grid_decide = false

VRFW.on("hook:Decide", function(ev)
  local menu = VRFW.memory.struct("GridMenu", ev.args[1])
  free_grid_decide = (U.get(menu, "campaign") or 0) == 0
  return nil
end)

VRFW.on("hook:Decide:post", function()
  free_grid_decide = false
  return nil
end)

-- the block when `request` is the Campaña's next match; nil for any other match
local function campaign_block_of(request)
  if free_grid_decide or VRFW.memory.read("u8", request + G.REQUEST_EXPLICIT) ~= 1 then
    return nil
  end
  local block = Block.read()
  if not Block.alive(block) or Block.lent() then
    return nil
  end
  local index = block.index
  if type(index) ~= "number" or index >= Block.RIVALS then
    return nil
  end
  local rival = VRFW.memory.read("u32", request + G.REQUEST_RIVAL)
  if rival == nil or VRFW.ids.unsigned(rival) ~= VRFW.ids.unsigned(block.rivals[index + 1] or 0) then
    return nil
  end
  local player = VRFW.ids.unsigned(VRFW.memory.read("u32", request + G.REQUEST_PLAYER) or 0)
  local same_team = player == VRFW.ids.unsigned(block.player or 0)
  -- the Active team tile's request names no team: 0 = the player's active team
  if not same_team and not (player == 0 and Active.is_tile(VRFW.ids.unsigned(block.player or 0))) then
    return nil
  end
  return block
end

local function belongs_to_run(doc, block)
  return doc ~= nil and #doc.order > 0 and VRFW.ids.unsigned(doc.player or 0) == VRFW.ids.unsigned(block.player or 0)
    and VRFW.ids.unsigned(doc.first_rival or 0) == VRFW.ids.unsigned(block.rivals[1] or 0) and doc.clears == block.clears
end

local draws = 0

local function shuffled_fields(request, block)
  draws = draws + 1
  local high, low
  if SEED ~= 0 then
    high, low = U.split64(SEED)
  else
    high, low = U.entropy(request, draws)
  end
  low = bit32.bxor(low, VRFW.ids.unsigned(block.player or 0), VRFW.ids.unsigned(block.rivals[1] or 0))
  local order = {}
  for position, map in ipairs(fields()) do
    order[position] = map
  end
  U.rng(high, low):shuffle(order)
  return order
end

-- the run's field order: drawn once per Campaña and kept in the slot, so a retried or reloaded match keeps its field
local function run_order(request, block)
  local slot = Block.slot()
  local doc = STORE:load(slot)
  if belongs_to_run(doc, block) then
    return doc.order
  end
  doc = { version = BLOB_VERSION, player = VRFW.ids.unsigned(block.player or 0), first_rival = VRFW.ids.unsigned(block.rivals[1] or 0), clears = block.clears,
    order = shuffled_fields(request, block) }
  local written, why = STORE:write(doc, slot, true)
  if not written then
    warn(BLOB .. " not written (" .. tostring(why) .. "): a reload of this Campaña draws its fields again")
  end
  return doc.order
end

VRFW.on("hook:StartMatchRequest", function(ev)
  local request = ev.args and ev.args[2]
  if type(request) ~= "number" or request < 0x10000 or #fields() == 0 then
    return nil
  end
  local block = campaign_block_of(request)
  if not block then
    return nil
  end
  local order = run_order(request, block)
  local stadium = VRFW.ids.unsigned(order[block.index % #order + 1])
  if VRFW.memory.write("u32", request + G.REQUEST_STADIUM, stadium) then
    info(string.format("match %d: field 0x%08X", block.index + 1, stadium))
  else
    warn(string.format("match %d: field 0x%08X NOT written: the rival's own stadium", block.index + 1, stadium))
  end
  return nil
end)
