-- The Draft screen's pack, pitch, mouse and sync commands and the team panel's avatar model.
local Shared = require "lib/draft/context"
local U = require "lib/util"
local G = require "lib/game"
local D = Shared.D
local floor = math.floor
local NONE = Shared.NONE
local COMPLETE = Shared.COMPLETE
local CAMPAIGN = Shared.CAMPAIGN
local OBJ_SIZE = Shared.OBJ_SIZE
local info = Shared.info
local warn = Shared.warn
local err = Shared.err
local draft_roster = Shared.draft_roster
local save_roster = Shared.save_roster
local drop_roster = Shared.drop_roster
local with = Shared.with
local apply = Shared.apply
local restore = Shared.restore
local campaign_started = Shared.campaign_started
local sync_leader = Shared.sync_leader
local tournament_owns = Shared.tournament_owns
local restore_run = Shared.restore_run
local ensure_slot = Shared.ensure_slot

local PACK = nil
local PACK_KEYS = {
  { "intro", 0.25 }, { "deal", 0.22 }, { "deal_stagger", 0.07 }, { "flip", 0.22 }, { "settle", 0.12 },
  { "flash", 0.30 }, { "gap", 0.45 }, { "suspense", 0.40 }, { "outro", 0.28 }, { "dim", 0.72 }, { "scale", 1.6 },
  { "spacing", 330 },
}
local PACK_SE = { { "se_open", "sy0000" }, { "se_deal", "sy0009" }, { "se_reveal", "sy0010" }, { "se_best", "sy0080" } }

local function pack_look()
  if PACK then
    return PACK
  end
  local t = U.config("draft.pack", nil)
  if type(t) ~= "table" then
    t = {}
  end
  local function get(k, d)
    local v = t[k]
    if v == nil then
      v = U.config("draft.pack." .. k, d)
    end
    return v
  end
  local out = {}
  for _, kv in ipairs(PACK_KEYS) do
    local v = tonumber(get(kv[1], kv[2]))
    if v == nil or v < 0 then
      warn("[draft.pack] " .. kv[1] .. ": not a number >= 0, " .. tostring(kv[2]) .. " used")
      v = kv[2]
    end
    out[#out + 1] = v
  end
  for _, kv in ipairs(PACK_SE) do
    local v = get(kv[1], kv[2])
    if type(v) ~= "string" or VRFW.strings.trim(v) == "" then
      v = kv[2]
    end
    out[#out + 1] = VRFW.crc32(VRFW.strings.trim(v))
  end
  PACK = out
  info("pack opening look: " .. #out .. " values from [draft.pack]")
  return PACK
end

function BattleBayDeluxe.DraftPack()
  local ok, p = pcall(pack_look)
  if not ok then
    err("[draft.pack] unreadable: " .. tostring(p))
    return false
  end
  return true, table.unpack(p)
end

-- how the starters' cards fit the Draft's pitch (config.toml [draft.pitch]), asked once per menu by the graft
function BattleBayDeluxe.DraftPitch()
  local t = U.config("draft.pitch", nil)
  if type(t) ~= "table" then
    return false
  end
  local out = {}
  for i, key in ipairs({ "card_scale", "card_width", "card_height", "card_gap", "edge_margin", "same_row_distance",
                         "symmetry_tolerance" }) do
    if type(t[key]) ~= "number" then
      err("[draft.pitch] " .. key .. " is not a number")
      return false
    end
    out[i] = t[key]
  end
  return true, table.unpack(out)
end

function BattleBayDeluxe.DraftMouse()
  local v = U.config("draft.mouse", true)
  return true, v ~= false
end

function D.sync(active, player)
  ensure_slot()
  local team0 = D.team()
  local owned = (active and player ~= 0 and player == team0) or (team0 ~= 0 and tournament_owns(team0))
  if Shared.RT == nil and not Shared.FAILED and not owned then
    if D.team() == 0 then
      return -1, false
    end
    drop_roster(string.format("top menu sync: no campaign with the Draft team (campaign %s, player team %s)", tostring(active), VRFW.ids.hex_text(player)))
    sync_leader("sync")
    return NONE, false
  end
  local r = with()
  local phase = -1
  local lost = false
  if r then
    local was = r.phase
    local team = r.pool.team
    local ours = team ~= 0 and ((active and player == team) or tournament_owns(team))
    if ours and (was == COMPLETE or was == CAMPAIGN) then
      local want = r.draft and draft_roster(r.draft, r.pool) or {}
      campaign_started(r)
      local ok, why = apply(r, want)
      if ok then
        if was == COMPLETE then
          save_roster(r)
        end
      else
        err("campaign running but the roster was not written again: " .. tostring(why))
      end
    elseif ours then
      local _, _, gone = restore_run(r, "top menu sync")
      lost = gone == true
    else
      local ok, why = true, nil
      local n = 0
      if was ~= NONE then
        n, why = restore(r)
        ok = n ~= nil
      end
      if ok then
        if was ~= NONE then
          info("discarded (campaign over or another team): placeholders back (" .. n .. " rows)")
        end
      else
        err("discarded, placeholders NOT written back (" .. tostring(why) .. ")")
      end
      drop_roster(string.format("top menu sync: campaign over or another team (campaign %s, player team %s, phase %d)", tostring(active), VRFW.ids.hex_text(player), was))
    end
    phase = r.phase
  end
  sync_leader("sync")
  return phase, lost
end

-- The team panel shows the hovered slot's leader as its 3D model.

local AVATAR_LOGGED = nil

local function record_object(hdl)
  if not VRFW.is_on("FindCharaRecord") or hdl == 0 or hdl % 65536 >= 0xD000 then
    return nil
  end
  local kind = floor(hdl / 4096) % 16
  local conts = VRFW.game.global("chara_containers")
  local cont = conts and VRFW.memory.read_pointer(conts + 8 + kind * 8)
  if not cont then
    return nil
  end
  local hb = VRFW.memory.buffer("bbd_avatar_hdl", 4)
  local okb = hb ~= nil
  if not okb or not VRFW.memory.write("u32", hb, hdl) then
    return nil
  end
  local ok, rec = U.call("FindCharaRecord", cont, hb)
  if ok and type(rec) == "number" and rec >= 0x10000 then
    return rec
  end
  return nil
end

local function avatar_param()
  local kz = VRFW.memory.struct("Kizuna", VRFW.game.global("kizuna"))
  local hdl, idx = U.get(kz, "avatar"), U.get(kz, "avatar_index")
  if not hdl or idx ~= 0 or hdl == 0 or hdl % 65536 >= 0xD000 then
    return nil
  end
  local obj = record_object(hdl)
  local rec8 = obj and VRFW.memory.read_pointer(obj + 8)
  if not rec8 or VRFW.memory.read("u32", rec8) ~= hdl then
    return nil
  end
  local p = VRFW.memory.read("u32", rec8 + 4)
  if p and p ~= 0 then
    return p
  end
  return nil
end

VRFW.on("hook:VRFW.BattleBayRecord", function(ev)
  local img, len = ev.args[1], ev.args[2]
  if type(img) ~= "number" or img < 0x10000 or type(len) ~= "number" or len < OBJ_SIZE then
    return nil
  end
  local team = D.team()
  if team == 0 then
    return nil
  end
  local avatar = avatar_param()
  local key = avatar or 0
  if AVATAR_LOGGED ~= key then
    AVATAR_LOGGED = key
    if avatar then
      info("the Draft tile's panel model = the player's avatar " .. VRFW.ids.hex_text(avatar))
    else
      warn("no usable Kizuna avatar in this save: the Draft tile keeps its placeholder model")
    end
  end
  if not avatar then
    return nil
  end
  if not G.slot_base() then
    return nil
  end
  for i = 0, G.SLOTS - 1 do
    local rec = G.slot_addr(img, i)
    if VRFW.memory.read("u32", rec + 0x4) == team and VRFW.memory.read("u32", rec + 0x8) ~= avatar then
      VRFW.memory.write("u32", rec + 0x8, avatar)
    end
  end
  return nil
end)
