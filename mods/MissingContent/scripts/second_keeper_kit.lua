-- A goalkeeper who did not start the match wears the other keeper kit of his team's uniform (option second_keeper_kit).

local OPTION = "second_keeper_kit"

-- Look flags of a match player's model (CreateMatchCharaModel, +0x716 of the model).
local FLAG_ALTERNATE, FLAG_KEEPER = 1, 2
local MODEL_FLAGS = 0x716

-- Model pool: [SoccerSystem + 0x50] + 0x10 + (handle & 0xFFFF) * 0x1460; the record holds its own handle at +0x70.
local POOL_LIST, POOL_FIRST, POOL_STRIDE, POOL_COUNT, MODEL_HANDLE = 0x50, 0x10, 0x1460, 0x280, 0x70
local MODEL_UNIFORM = 0x708

-- Match info: team records at +0x60 (stride 0x1130), members from +0x80 (stride 0x80), the character handle at member +0x50.
local TEAM_FIRST, TEAM_STRIDE, TEAM_UNIFORM, TEAM_MEMBERS, TEAM_MEMBER_COUNT = 0x60, 0x1130, 0x1040, 0x80, 0x1D
local MEMBER_STRIDE, MEMBER_CHARA = 0x80, 0x50

-- Closure of RefreshMatchCharaLook: pointers to the keeper byte, the coach byte, the team byte and the member pointer.
local CLOSURE_KEEPER, CLOSURE_TEAM, CLOSURE_MEMBER = 0, 0x10, 0x18

local Mem = VRFW.memory
local u32 = VRFW.ids.unsigned

local starters = {}        -- character handle of a starting keeper -> the alternate bit of his team's kit
local team_alternate = {}  -- team index -> the alternate bit of its kit
local loaded = false       -- true once the first kick-off of this match has been reached
local two_keeper_kits = nil

local function enabled()
  return VRFW.option(OPTION) == 1
end

-- Uniforms with a type 0 and a type 1 row holding two different keeper shirts.
local function read_two_keeper_kits()
  if two_keeper_kits then
    return two_keeper_kits
  end
  local found = {}
  local models = VRFW.table.rows("character/uniform_model_info")
  local type_col, keeper_col
  for i, name in ipairs(VRFW.table.columns("character/uniform_model_info")) do
    if name == "type_id" then
      type_col = i
    elseif name == "uniform_keeper_model_id_crc" then
      keeper_col = i
    end
  end
  if type_col and keeper_col then
    for _, row in ipairs(VRFW.table.rows("character/uniform")) do
      local slice = row.model_info
      if type(slice) == "table" and slice.count == 2 and slice.start >= 0 and slice.start + 2 <= #models then
        local shirt = {}
        for k = slice.start + 1, slice.start + 2 do
          shirt[models[k][type_col]] = u32(models[k][keeper_col])
        end
        if shirt[0] and shirt[1] and shirt[0] ~= 0 and shirt[1] ~= 0 and shirt[0] ~= shirt[1] then
          found[u32(row.name_id)] = true
        end
      end
    end
  else
    VRFW.warn("uniform_model_info has no type_id or keeper column: every keeper keeps his team's kit")
  end
  two_keeper_kits = found
  return found
end

local function has_second_keeper_kit(uniform)
  return uniform ~= 0 and read_two_keeper_kits()[uniform] == true
end

-- The team's kit variant, read from the starting keeper recorded at the first build of this match; nil when it had none.
local function alternate_of(team)
  if team_alternate[team] ~= nil then
    return team_alternate[team]
  end
  local info = VRFW.game.missing_content_match()
  if not info then
    return nil
  end
  local first = info + TEAM_FIRST + team * TEAM_STRIDE + TEAM_MEMBERS
  for slot = 0, TEAM_MEMBER_COUNT - 1 do
    local hdl = Mem.read("u32", first + slot * MEMBER_STRIDE + MEMBER_CHARA)
    if hdl and starters[hdl] ~= nil then
      team_alternate[team] = starters[hdl]
      return starters[hdl]
    end
  end
  return nil
end

VRFW.on("match:start_request", function()
  starters, team_alternate, loaded = {}, {}, false
  if enabled() then
    read_two_keeper_kits()
  end
  return nil
end)

VRFW.on("match:kickoff", function()
  loaded = true
  return nil
end)

-- Every model the match builds: records the starting keepers, then dresses a rebuilt substitute keeper.
VRFW.on("hook:VRFW.MatchLook", function(ev)
  local hdl, flags, uniform = u32(ev.args[1]), ev.args[2], u32(ev.args[4])
  if math.floor(flags / 16) % 4 ~= 0 or math.floor(flags / FLAG_KEEPER) % 2 == 0 then
    return nil
  end
  local alternate = flags % 2
  if not loaded then
    starters[hdl] = alternate
    return nil
  end
  if starters[hdl] == nil and enabled() and has_second_keeper_kit(uniform) then
    return { args = { [2] = flags + (alternate == 0 and FLAG_ALTERNATE or -FLAG_ALTERNATE) } }
  end
  return nil
end)

-- A substitution or position change is about to reload this model with the keeper's flag set or cleared.
VRFW.on("hook:MissingContent.KeeperLookRefresh", function(ev)
  local closure, handle = ev.args[1], u32(ev.args[2])
  local system = VRFW.game.missing_content_soccer_system()
  local index = handle % 0x10000
  if not system or handle == 0 or index >= POOL_COUNT then
    return nil
  end
  local list = Mem.read_pointer(system + POOL_LIST)
  if not list then
    return nil
  end
  local model = list + POOL_FIRST + index * POOL_STRIDE
  if Mem.read("u32", model + MODEL_HANDLE) ~= handle then
    return nil
  end
  local team_byte = Mem.read_pointer(closure + CLOSURE_TEAM)
  local keeper_byte = Mem.read_pointer(closure + CLOSURE_KEEPER)
  local member_slot = Mem.read_pointer(closure + CLOSURE_MEMBER)
  local member = member_slot and Mem.read_pointer(member_slot)
  if not team_byte or not keeper_byte or not member then
    return nil
  end
  local team = Mem.read("u8", team_byte)
  local alternate = team and team < 2 and alternate_of(team) or nil
  local flags = Mem.read("u8", model + MODEL_FLAGS)
  if alternate == nil or not flags then
    return nil
  end
  local uniform = u32(Mem.read("u32", model + MODEL_UNIFORM) or 0)
  if uniform == 0 then
    local info = VRFW.game.missing_content_match()
    uniform = info and u32(Mem.read("u32", info + TEAM_FIRST + team * TEAM_STRIDE + TEAM_UNIFORM) or 0) or 0
  end
  local hdl = Mem.read("u32", member + MEMBER_CHARA)
  local is_keeper = Mem.read("u8", keeper_byte) ~= 0
  local other = is_keeper and hdl ~= nil and starters[hdl] == nil and enabled() and has_second_keeper_kit(uniform)
  local wanted = other and 1 - alternate or alternate
  if flags % 2 ~= wanted then
    Mem.write("u8", model + MODEL_FLAGS, flags + (wanted == 1 and FLAG_ALTERNATE or -FLAG_ALTERNATE))
  end
  return nil
end)
