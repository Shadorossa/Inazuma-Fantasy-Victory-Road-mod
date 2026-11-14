
local U = require "lib/util"

local B = {}

-- The session's campaign fields by their game profile names; the first rival is followed by the other six (u32 each).
local S_GAME, S_DIFF, S_PLAYER = VRFW.game.field("Session.Game"), VRFW.game.field("Session.Difficulty"), VRFW.game.field("Session.Player")
local S_RIVALS, S_INDEX = VRFW.game.field("Session.Rival1"), VRFW.game.field("Session.Match")
-- The clear count has no game profile name.
local S_CLEARS = 0x208
B.RIVALS = 7

local info, warn = VRFW.logger("campaign block")

local Doc = VRFW.save.doc

-- the active save slot (1 while the slot service does not run)
B.slot = Doc.slot

local stores = {}
local function store_of(blob)
  local store = stores[blob]
  if not store then
    store = Doc.new(blob, {
      aside = false,
      log = "campaign block",
      default = function() return nil end,
      decode = function(doc)
        if type(doc.rivals) ~= "table" then return nil, "unreadable" end
        return doc
      end,
    })
    stores[blob] = store
  end
  return store
end

function B.session()
  return VRFW.game.global("session")
end

function B.read()
  local s = B.session()
  if not s then
    return nil
  end
  local r = {
    game = VRFW.memory.read("u32", s + S_GAME), diff = VRFW.memory.read("u8", s + S_DIFF), player = VRFW.memory.read("u32", s + S_PLAYER),
    index = VRFW.memory.read("u8", s + S_INDEX), clears = VRFW.memory.read("u32", s + S_CLEARS), rivals = {},
  }
  for i = 0, B.RIVALS - 1 do
    r.rivals[i + 1] = VRFW.memory.read("u32", s + S_RIVALS + 4 * i) or 0
  end
  return r
end

function B.write(game, diff, player, rivals, index)
  local s = B.session()
  if not s then
    return false
  end
  local ok = VRFW.memory.write("u32", s + S_GAME, VRFW.ids.unsigned(game)) and VRFW.memory.write("u8", s + S_DIFF, diff)
    and VRFW.memory.write("u32", s + S_PLAYER, VRFW.ids.unsigned(player))
  for i = 0, B.RIVALS - 1 do
    ok = ok and VRFW.memory.write("u32", s + S_RIVALS + 4 * i, VRFW.ids.unsigned(rivals[i + 1] or 0))
  end
  return ok and VRFW.memory.write("u8", s + S_INDEX, index)
end

function B.snapshot(blob)
  local b = B.read()
  if not b then
    return false
  end
  local doc = { v = 1, game = b.game or 0, diff = b.diff or 0, player = b.player or 0, index = b.index or 0,
    clears = b.clears or 0, rivals = {} }
  for i = 1, B.RIVALS do
    doc.rivals[i] = b.rivals[i] or 0
  end
  local done, why = store_of(blob):write(doc, B.slot(), true)
  if not done then
    warn(blob .. " not written (" .. tostring(why) .. "): the Campaña's block is not lent")
    return false
  end
  info(string.format("Campaña block kept in %s (player %s, rival 1 %s, index %d)", blob, VRFW.ids.hex_text(doc.player),
    VRFW.ids.hex_text(doc.rivals[1]), doc.index))
  return true
end

function B.alive(b)
  return b ~= nil and (b.rivals[1] or 0) ~= 0
end

function B.clear()
  return B.write(0, 0, 0, {}, 0)
end

B.LENT_BLOBS = { "bb_tournament_campaign.json", "bb_daily_campaign.json", "bb_net_campaign.json" }

function B.kept(blob)
  return (store_of(blob):load(B.slot()))
end

function B.has_snapshot(blob)
  return type(VRFW.save.doc.read_text(blob, B.slot())) == "string"
end

-- whether another mode has lent the block (one of B.LENT_BLOBS kept in the slot)
function B.lent()
  for _, blob in ipairs(B.LENT_BLOBS) do
    if B.has_snapshot(blob) then
      return true
    end
  end
  return false
end

function B.restore(blob)
  local doc, state = store_of(blob):load(B.slot())
  if state == "new" then
    return false
  end
  if state ~= "ok" then
    warn(blob .. " unreadable: the Campaña's block stays as it is")
    return false
  end
  local before = B.read()
  if not B.write(doc.game, doc.diff, doc.player, doc.rivals, doc.index) then
    warn("the Campaña's block was not written back (kept in " .. blob .. ")")
    return false
  end
  if before and doc.clears and before.clears ~= doc.clears then
    warn(string.format("the campaign clear counter changed while the block was lent (%d -> %d)", doc.clears,
      before.clears))
  end
  local aside, why = VRFW.save.doc.set_aside(blob, B.slot())
  if not aside then
    warn(blob .. " stays on record after the block came back: " .. tostring(why))
  end
  info(string.format("Campaña block back from %s (player %s, rival 1 %s, index %d)", blob, VRFW.ids.hex_text(VRFW.ids.unsigned(doc.player)),
    VRFW.ids.hex_text(VRFW.ids.unsigned(doc.rivals[1])), doc.index))
  return true
end

return B
