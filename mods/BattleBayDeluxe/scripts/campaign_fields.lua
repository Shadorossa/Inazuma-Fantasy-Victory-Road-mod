-- The Campaña's 7 matches are played on special-conditions fields drawn from [campaign_fields] fields of config.toml.

local U = require "lib/util"
local G = require "lib/game"
local Block = require "lib/campaign_block"
local Active = require "active_team"

local info, warn = VRFW.logger("campaign fields")

local BLOB = "bb_campaign_fields.json"

local STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "campaign fields",
  default = function() return nil end,
  decode = function(doc)
    if type(doc.order) ~= "table" then return nil, "unreadable" end
    return doc
  end,
})

local function declared_fields()
  local list = U.config("campaign_fields.fields", {})
  if type(list) ~= "table" then
    list = { list }
  end
  local fields, seen = {}, {}
  for _, entry in ipairs(list) do
    local map = VRFW.strings.trim(tostring(entry))
    if map ~= "" and not seen[map] then
      seen[map] = true
      fields[#fields + 1] = map
    end
  end
  return fields
end

local FIELDS = declared_fields()
local SEED = tonumber(U.config("campaign.seed", 0)) or 0

info(string.format("%d special-conditions fields for the Campaña", #FIELDS))

-- true while a Decide of the free match grid runs: its request is never the Campaña's
local free_grid_decide = false

VRFW.on("hook:Decide", function(ev)
  local menu = U.struct("GridMenu", ev.args[1])
  free_grid_decide = (U.get(menu, "campaign") or 0) == 0
  return nil
end)

VRFW.on("hook:Decide:post", function()
  free_grid_decide = false
  return nil
end)

-- the block when `request` is the Campaña's next match; nil for any other match
local function campaign_block_of(request)
  if free_grid_decide or U.rd("u8", request + G.REQUEST_EXPLICIT) ~= 1 then
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
  local rival = U.rd("u32", request + G.REQUEST_RIVAL)
  if rival == nil or U.u32(rival) ~= U.u32(block.rivals[index + 1] or 0) then
    return nil
  end
  local player = U.u32(U.rd("u32", request + G.REQUEST_PLAYER) or 0)
  local same_team = player == U.u32(block.player or 0)
  -- the Active team tile's request names no team: 0 = the player's active team
  if not same_team and not (player == 0 and Active.is_tile(U.u32(block.player or 0))) then
    return nil
  end
  return block
end

local function belongs_to_run(doc, block)
  return doc ~= nil and #doc.order > 0 and U.u32(doc.player or 0) == U.u32(block.player or 0)
    and U.u32(doc.first_rival or 0) == U.u32(block.rivals[1] or 0) and doc.clears == block.clears
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
  low = bit32.bxor(low, U.u32(block.player or 0), U.u32(block.rivals[1] or 0))
  local order = {}
  for position, map in ipairs(FIELDS) do
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
  doc = { v = 1, player = U.u32(block.player or 0), first_rival = U.u32(block.rivals[1] or 0), clears = block.clears,
    order = shuffled_fields(request, block) }
  local written, why = STORE:write(doc, slot, true)
  if not written then
    warn(BLOB .. " not written (" .. tostring(why) .. "): a reload of this Campaña draws its fields again")
  end
  return doc.order
end

VRFW.on("hook:StartMatchRequest", function(ev)
  local request = ev.args and ev.args[2]
  if type(request) ~= "number" or request < 0x10000 or #FIELDS == 0 then
    return nil
  end
  local block = campaign_block_of(request)
  if not block then
    return nil
  end
  local order = run_order(request, block)
  local map = order[block.index % #order + 1]
  local stadium = U.u32(VRFW.crc32(map))
  if U.wr("u32", request + G.REQUEST_STADIUM, stadium) then
    info(string.format("match %d: field %s (0x%08X)", block.index + 1, map, stadium))
  else
    warn(string.format("match %d: field %s NOT written: the rival's own stadium", block.index + 1, map))
  end
  return nil
end)
