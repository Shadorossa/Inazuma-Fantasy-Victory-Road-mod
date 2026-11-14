-- The running Tournament's state, its save blob, the campaign block copy and the one-run mark.
local Shared = require "lib/tournament/context"
local T = require "lib/tourney"
local Block = require "lib/campaign_block"
local Tn = Shared.Tn
local BLOB = Shared.BLOB
local RUN_VERSION = Shared.RUN_VERSION
local info = Shared.info
local warn = Shared.warn

Shared.RUN, Shared.RUN_SLOT = nil, nil
Shared.ARMED = nil
Shared.PENDING = nil
Shared.PENDING_DIFF = nil
Shared.FAILED = nil
Shared.POOL = nil
Shared.POOL_LEAGUE = nil
Shared.PLAYED = nil
Shared.LIVE = nil
Shared.final_request = nil

local RUN_STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "tournament",
  default = function() return nil end,
  decode = function(doc)
    if doc.v ~= RUN_VERSION then return nil, "version: no tournament" end
    return doc
  end,
})

local function blob_off(why)
  local n = VRFW.slots.active()
  if type(VRFW.save.doc.read_text(BLOB, n)) == "string" then
    local ok2, where = VRFW.save.doc.set_aside(BLOB, n)
    info(BLOB .. " (slot " .. n .. ") put aside (" .. why .. "): " .. tostring(ok2 and where or "failed"))
  end
end

local function save()
  if not Shared.RUN then
    return
  end
  if Shared.RUN.outcome then
    blob_off(Shared.RUN.outcome)
    return
  end
  local n = VRFW.slots.active()
  local done, why = RUN_STORE:write(Shared.RUN, n, true)
  if not done then
    warn(BLOB .. " (slot " .. n .. ") not written: " .. tostring(why))
  end
end

local function load()
  local n = VRFW.slots.active()
  if Shared.RUN_SLOT == n then
    return Shared.RUN
  end
  Shared.RUN, Shared.RUN_SLOT = nil, n
  local doc, state = RUN_STORE:load(n)
  if state == "ok" and doc.outcome then
    local aside, why = VRFW.save.doc.set_aside(BLOB, n)
    if not aside then
      warn(BLOB .. " (slot " .. n .. ") stays on record after its run ended: " .. tostring(why))
    end
    Tn.stale = string.format("an ended %s (%s)", tostring(doc.fmt), tostring(doc.outcome))
  elseif state == "ok" then
    Shared.RUN = doc
    info(string.format("run of slot %d: %s / %d teams%s, %d match(es) played, stage %s", n, doc.fmt, doc.size,
      doc.double and " (home and away)" or "", doc.k, tostring(doc.stage)))
  end
  return Shared.RUN
end

local function drop(why)
  blob_off(why)
  Shared.RUN = nil
end

-- the block holds this run (player team and first rival)
local function block_is_run(b, run)
  return b and run.sess and b.player == run.sess.player and b.rivals[1] == run.sess.r1 and b.rivals[1] ~= 0
end

local function write_block(run)
  if not Block.session() or not run.sess then
    return false
  end
  local opp = T.opponent(run)
  if opp == 0 then
    return false
  end
  run.sess.r1 = run.teams[opp]
  local ok = Block.write(run.sess.game, run.sess.diff, run.sess.player, { run.teams[opp] }, 0)
  if ok then
    info(string.format("match %d/%d: rival %s (the Campaña's block borrowed)", run.k + 1, T.run_matches(run),
      VRFW.ids.hex_text(run.teams[opp])))
  else
    warn("campaign block not written")
  end
  return ok
end

local CAMP_BLOB = "bb_tournament_campaign.json"

-- Puts the kept copy of the campaign block aside.
local function campaign_copy_off()
  local aside, why = VRFW.save.doc.set_aside(CAMP_BLOB, VRFW.slots.active())
  if not aside then
    warn(CAMP_BLOB .. " stays on record: " .. tostring(why))
  end
end

-- the block zeroed as the game's own reset does, its kept copy put aside
local function campaign_clear()
  local ok = Block.clear()
  if ok then
    campaign_copy_off()
  end
  return ok
end

local ONE_RUN_STORE = VRFW.save.doc.new("bb_one_run.json", {
  aside = false,
  log = "tournament",
  default = function() return nil end,
})
local ONE_RUN = { slot = nil, mark = nil, first = false }

local function one_run_mark(n)
  if ONE_RUN.slot ~= n then
    local doc, state = ONE_RUN_STORE:load(n)
    ONE_RUN.slot, ONE_RUN.mark, ONE_RUN.first = n, doc, state == "new"
  end
  return ONE_RUN
end

local function one_run_write(n, doc)
  ONE_RUN.mark, ONE_RUN.first = doc, false
  local done, why = ONE_RUN_STORE:write(doc, n, true)
  if not done then
    warn("bb_one_run.json not written: " .. tostring(why))
  end
end

-- After every top menu sync.
local function one_run_check()
  local n = VRFW.slots.active()
  local run = load()
  local notes = {}
  if Tn.stale then
    notes[1] = Tn.stale
    Tn.stale = nil
  end
  local b = Block.read()
  local lent = (run and run.loaded) or Shared.ARMED ~= nil or Shared.PENDING ~= nil
  for _, name in ipairs(Block.LENT_BLOBS) do
    lent = lent or (name ~= CAMP_BLOB and Block.has_snapshot(name))
  end
  if b and not lent then
    local m = one_run_mark(n)
    local running = run ~= nil and not run.outcome
    local again = type(m.mark) == "table" and m.mark.player == b.player and m.mark.r1 == b.rivals[1]
    if Block.alive(b) and (running or (b.index == 0 and (m.first or again))) then
      if campaign_clear() then
        notes[#notes + 1] = string.format("a Campaña (player %s, rival 1 %s, match %d, %s)", VRFW.ids.hex_text(b.player),
          VRFW.ids.hex_text(b.rivals[1]), b.index + 1, running and "behind a running run" or "no match won")
        one_run_write(n, { v = 1, player = b.player, r1 = b.rivals[1], index = b.index })
      end
    elseif m.first then
      one_run_write(n, { v = 1 })
    end
  end
  if #notes > 0 then
    info(string.format("one saved run (slot %d): removed %s", n, table.concat(notes, " and ")))
  end
end

function Tn.armed()
  return Shared.ARMED ~= nil
end

function Tn.note_pool(n, list, player)
  if type(n) == "number" and n >= 0 then
    Shared.POOL = n
  end
  if type(list) == "table" then
    local ok, a, b = pcall(function()
      local x = Tn.excluded(list)
      return #Tn.league_pool(x, player or 0, false), #Tn.league_pool(x, player or 0, true)
    end)
    if ok then
      Shared.POOL_LEAGUE = { a, b }
    end
  end
end

-- The names the later parts of the Tournament read.
Shared.save = save
Shared.load = load
Shared.drop = drop
Shared.block_is_run = block_is_run
Shared.write_block = write_block
Shared.CAMP_BLOB = CAMP_BLOB
Shared.campaign_copy_off = campaign_copy_off
Shared.campaign_clear = campaign_clear
Shared.one_run_check = one_run_check
