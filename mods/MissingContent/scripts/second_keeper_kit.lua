-- A goalkeeper who did not start the match wears the other keeper kit of his team's uniform (option second_keeper_kit).

local OPTION = "second_keeper_kit"

-- Look flags of a match player's model (Scene.CharaObjectLookFlags of the profile).
local FLAG_ALTERNATE, FLAG_KEEPER = 1, 2

-- The layouts come from the game profile: the model pool of Match.SoccerSystem, the match info's teams and the closure of RefreshMatchCharaLook.
local field = VRFW.game.field
local POOL_LIST, POOL_FIRST, POOL_STRIDE = field("Scene.CharaObjects"), field("Scene.CharaObjectBase"), field("Scene.CharaObjectSize")
local POOL_COUNT, MODEL_HANDLE = field("Scene.CharaObjectCount"), field("Scene.CharaObjectHandle")
local MODEL_FLAGS, MODEL_UNIFORM = field("Scene.CharaObjectLookFlags"), field("Scene.CharaObjectUniform")
local TEAM_FIRST, TEAM_STRIDE, TEAM_UNIFORM = field("MatchInfo.Teams"), field("MatchTeam"), field("MatchTeam.Uniform")
local TEAM_MEMBERS, TEAM_MEMBER_COUNT = field("MatchTeam.Members"), field("Match.TeamMemberSlots")
local MEMBER_STRIDE, MEMBER_CHARA = field("MatchTeamMember"), field("MatchTeamMember.Chara")
local CLOSURE_KEEPER, CLOSURE_TEAM, CLOSURE_MEMBER = field("MatchLookRefreshClosure.Keeper"), field("MatchLookRefreshClosure.Team"), field("MatchLookRefreshClosure.Member")
local LAYOUT_KNOWN = POOL_LIST and POOL_FIRST and POOL_STRIDE and POOL_COUNT and MODEL_HANDLE and MODEL_FLAGS and MODEL_UNIFORM
  and TEAM_FIRST and TEAM_STRIDE and TEAM_UNIFORM and TEAM_MEMBERS and TEAM_MEMBER_COUNT and MEMBER_STRIDE and MEMBER_CHARA
  and CLOSURE_KEEPER and CLOSURE_TEAM and CLOSURE_MEMBER
if not LAYOUT_KNOWN then
  VRFW.warn("the game profile lacks a model pool, match team or look closure field: every keeper keeps his team's kit")
end

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
local function build_two_keeper_kits()
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
  return found
end

-- The uniforms above, built once and kept between starts (game data only).
local function read_two_keeper_kits()
  if two_keeper_kits then
    return two_keeper_kits
  end
  local ok, found = pcall(VRFW.derived, "two_keeper_kits", nil, build_two_keeper_kits)
  if not ok or type(found) ~= "table" then
    VRFW.warn("uniform tables not readable (" .. tostring(found) .. "): every keeper keeps his team's kit")
    found = {}
  end
  two_keeper_kits = found
  return found
end

-- Built at load: the match start only resets this match's records.
read_two_keeper_kits()

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
  return nil
end)

VRFW.on("match:kickoff", function()
  loaded = true
  return nil
end)

-- Every model the match builds: records the starting keepers, then dresses a rebuilt substitute keeper.
VRFW.on("hook:VRFW.MatchLook", function(ev)
  if not LAYOUT_KNOWN then
    return nil
  end
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
  if not LAYOUT_KNOWN then
    return nil
  end
  local var = VRFW.game.symbol("Match.SoccerSystem")
  local system = var and Mem.read_pointer(var)
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
