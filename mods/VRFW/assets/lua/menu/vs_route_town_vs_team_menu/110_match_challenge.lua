if VRFW.match_challenge ~= nil then
  local S = type(VRFW.match_challenge_vs_screen) == "table" and VRFW.match_challenge_vs_screen or {game = 0, diff = 1}
  VRFW.match_challenge_vs_screen = S
  local C = {
    PIECE = 160947459, DIFFICULTY = 2968810192,
    PIECE_INFO = 126049514,
    BUTTON = 2055576472, BUTTON_TEXTS = {1317518280, 2729666850}, START_TEXT = 3646324900,
    UNMET_TEXT = 3503321613,                             -- crc32("vrfw_mc_unmet_start"), text\rows\match_challenge.toml
  }

  local function param(key)
    if VRFW.param.has(key) then
      return VRFW.param.get(key)
    end
    return nil
  end

  -- the screen's match challenge against the active dock (VRFW.match_challenge.status), nil = no piece or no challenge
  local function status()
    if S.game == 0 then
      return nil
    end
    return VRFW.match_challenge.status(S.game, 0, S.diff)
  end

  -- the start button's label: "Requirements missing" while the dock does not meet the challenge, else the retail one
  local function label()
    local st = status()
    if st == nil then
      return
    end
    local s = VRFW.host.command(VRFW.commands.TEXT_GET, st.ok and C.START_TEXT or C.UNMET_TEXT)
    if type(s) ~= "string" then
      return
    end
    for _, t in ipairs(C.BUTTON_TEXTS) do
      VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_STRING, C.BUTTON, t, s)
    end
  end

  -- wrapped once per definition of the retail function (a chunk that runs again gets wrapped again)
  local init = rawget(_ENV, "OnInit")
  if type(init) == "function" and init ~= S.init_wrap then
    S.init_wrap = function(...)
      S.game, S.diff = 0, 1
      VRFW.host.command(VRFW.match_challenge.AURAS_DISARM)
      if VRFW.route_slots ~= nil then
        pcall(VRFW.route_slots.install)   -- an extended node's slot and clear bits (36_route_slots.lua)
      end
      local piece = param(C.PIECE)
      local diff = param(C.DIFFICULTY)
      if type(piece) == "number" then
        local ok, _, game = VRFW.host.command(C.PIECE_INFO, piece, 2, true)
        if ok and type(game) == "number" then
          S.game = game
        end
      end
      if type(diff) == "number" then
        S.diff = diff
      end
      return init(...)
    end
    OnInit = S.init_wrap
  end

  local decide = rawget(_ENV, "OnDecideFocus")
  if type(decide) == "function" and decide ~= S.decide_wrap then
    S.decide_wrap = function(...)
      local st = status()
      if st ~= nil then
        if not st.ok then
          VRFW.match_challenge.log("vs screen", "game", S.game, "difficulty", S.diff, "refused", "offenders", st.offenders)
          VRFW.host.command(VRFW.match_challenge.SE, VRFW.match_challenge.SE_NG)
          return
        end
      end
      VRFW.match_challenge.arm_auras(S.game, S.diff)
      return decide(...)
    end
    OnDecideFocus = S.decide_wrap
  end

  if VRFW.host ~= nil then
    VRFW.host.on("vs_route_town_vs_team_menu", "OnSetupLayer", {
      id = "VRFW.match_challenge_vs_button", phase = "after",
      fn = function(_, a1)
        if a1 == C.BUTTON then
          label()
        end
      end,
    })
    VRFW.host.on("vs_route_town_vs_team_menu", "SetTeamDockFormation", {
      id = "VRFW.match_challenge_vs_dock", phase = "after",
      fn = function()
        label()
      end,
    })
  end
end
