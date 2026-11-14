-- lua_patch.scope: used
-- Team templates as the teams of VRFW.team_loadout: each template has a stable key, and the player set links kept before move in once.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.team_loadout == nil then
  local L = {
    -- the menus that switch teams or edit a player's moves (named so the loader runs this file there)
    MENUS = {"soccer_team_dock_menu", "soccer_battle_setting_flow_formation_menu", "vrfw_skill_slot_menu"},
    C = {
      KEY = 2404682753,           -- CMND_BETTERQOL_TEMPLATE_LOADOUT_KEY (team set) -> key
      TEAMS = 4227637372,         -- CMND_BETTERQOL_TEMPLATE_LOADOUT_TEAMS -> "key:h,h;key:..."
      KEY_OF = 2316120034,        -- CMND_BETTERQOL_TEMPLATE_LOADOUT_KEY_OF (template number) -> key
      LINKS_TO_MOVE = 3369181370, -- CMND_BETTERQOL_SET_LINKS_TO_MOVE -> "n:h=s,h=s;n:..."
      LINKS_MOVED = 524720000,    -- CMND_BETTERQOL_SET_LINKS_MOVED -> set aside
    },
    TEXT = {
      OWN = 2853082265,           -- BetterQoL.TeamSet.Own
      NONE = 3425356419,          -- BetterQoL.TeamSet.None
      COPY_ASK = 4252917507,      -- BetterQoL.TeamSet.CopyAsk
      COPIED = 2110901830,        -- BetterQoL.TeamSet.Copied
      NO_OTHER = 48081201,        -- BetterQoL.TeamSet.NoOther
      RESET_ASK = 3295854426,     -- BetterQoL.TeamSet.ResetAsk
    },
    migration_logged = false,
  }
  BetterQoL.team_loadout = L

  local function command(id, ...)
    return VRFW.host.command(id, ...)
  end

  local function log(...)
    if VRFW.team_loadout ~= nil then
      VRFW.team_loadout.log("BetterQoL", ...)
    end
  end

  --- The stable key of the template in team set `set`; nil when that set is no dock.
  function L.key(set)
    local key = command(L.C.KEY, set)
    return (type(key) == "string" and key ~= "") and key or nil
  end

  --- Every template that has players: { { key, handles } }.
  function L.teams()
    local text = command(L.C.TEAMS)
    if type(text) ~= "string" then
      return nil
    end
    local out = {}
    for key, list in text:gmatch("([^;:]+):([^;]*)") do
      local handles = {}
      for h in list:gmatch("[^,]+") do
        handles[#handles + 1] = tonumber(h, 16)
      end
      out[#out + 1] = {key = key, handles = handles}
    end
    return out
  end

  --- Moves the links of «Link to this team» (one saved set per player and template) into the team records once.
  function L.migrate()
    local text = command(L.C.LINKS_TO_MOVE)
    if type(text) ~= "string" or text == "" then
      return
    end
    local S = type(CharacterReforged) == "table" and CharacterReforged.player_sets or nil
    local field = type(CharacterReforged) == "table" and CharacterReforged.team_loadout or nil
    if type(S) ~= "table" or type(S.read) ~= "function" or type(field) ~= "table" then
      if not L.migration_logged then
        L.migration_logged = true
        log("player set links kept for later: Character Reforged's set writer is not loaded here")
      end
      return
    end
    local moved, gone = 0, 0
    for n, links in text:gmatch("(%d+):([^;]+)") do
      local key = command(L.C.KEY_OF, tonumber(n))
      for h, set in links:gmatch("(%x+)=(%d+)") do
        local handle = tonumber(h, 16)
        local ok, p = pcall(S.read, handle, tonumber(set))
        if type(key) == "string" and ok and p ~= nil
            and VRFW.team_loadout.keep(key, handle, field.KEY .. "=" .. field.encode(p), true) then
          moved = moved + 1
        else
          gone = gone + 1
        end
      end
    end
    command(L.C.LINKS_MOVED)
    log("player set links moved into the team records:", moved, "kept,", gone, "with an empty or missing set")
  end

  local function text(id)
    local t = command(VRFW.commands.TEXT_GET, id)
    return type(t) == "string" and t or ""
  end

  --- The moves screen's X action (host CharacterReforged.skill_table.x_action): the player's set in the active team,
  --- copied to every other team he is in, or put back on his card's default set.
  function L.x_action(phase, ctx)
    local TL = VRFW.team_loadout
    if TL == nil or type(ctx) ~= "table" or type(ctx.chara) ~= "number" then
      return phase == "available" and false or nil
    end
    if phase == "available" then
      return TL.is_active_member(ctx.chara)
    elseif phase == "press" then
      local h = ctx.chara
      local state = text(TL.has_record(h) and L.TEXT.OWN or L.TEXT.NONE)
      if VRFW.question.ask(state .. "\n" .. text(L.TEXT.COPY_ASK)) then
        local n = TL.copy_to_all(h)
        VRFW.question.notice(text(n > 0 and L.TEXT.COPIED or L.TEXT.NO_OTHER))
        return true
      end
      if VRFW.question.ask(text(L.TEXT.RESET_ASK)) then
        TL.reset(h)
        if type(CharacterReforged) == "table" and type(CharacterReforged.skill_table_after_change) == "function" then
          pcall(CharacterReforged.skill_table_after_change)
        end
      end
      return true
    end
    return nil
  end

  local function register(TL)
    local ok, why = TL.set_source({key = L.key, teams = L.teams, migrate = L.migrate})
    if not ok then
      log("team source not set:", tostring(why))
    end
  end
  if VRFW.team_loadout ~= nil then
    register(VRFW.team_loadout)
  else
    VRFW.team_loadout_queue = VRFW.team_loadout_queue or {}
    table.insert(VRFW.team_loadout_queue, register)
  end
end
