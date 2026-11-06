-- «Configuración de pasivas» of the mod BetterQoL (BetterQoL's old DLL, feature passive_config;
-- docs/game/mechanics/pasivas-configurables.md), team dock part (team_dock_formation_menu). SOURCE of the hook file
-- util_pc_dock.lua (research/grafts/passive_config/gen_hooks.py fills the @crc / @ICONS@ placeholders; edit this
-- file, then run the script).
-- 2026-10-08 back to the ORIGINAL design (Inazuma Fantasy 2026-09-28, ff3bb93934): setting type 9 («Pasivas
-- heredadas», renamed «Configuración de pasivas») is offered to every player the configurator handles (also a coach,
-- the leader card, and a manager: their slots take their role's passives) and hidden for players of a mode's reserved
-- slot; type 10 (the inheritance trash button) is gone. Choosing
-- type 9 never opens the inherit menu: a Handle rule of the VR-Framework's list rows (docs/framework/list-rows.md,
-- since BetterQoL 1.15.10; until then one line inserted into the retail OnDecideFocus by the graft
-- passive_config_dispatch, which redefined that whole function) runs UTIL_PCD.Plate in the dock's own per-player
-- coroutine right after the popup closed (Inazuma Fantasy's merged file carries the same call in its graft
-- prime_dock): it turns the plate to «PASIVAS DE EQUIPO», hands a session to personal_plate_menu (util_pc_plate.lua)
-- through the parameter store, waits in the dock's coroutine until it ends and restores the dock exactly as the
-- original did; the dock then goes on as after any setting (the framework cancels the retail pick). (The 2026-10-08 replacement, which let the retail branch run and faked the inherit menu's
-- open / exists answers, left the dock waiting for a restore the retail code never did: stuck after Atrás.)
-- Without the plugin (CMND_BETTERQOL_PC_INFO unanswered) nothing changes.
-- Hook file (graft [[hooks]]): GetSelectSettingTypeOrderList is wrapped with an EVT_Host handler of the
-- VR-Framework's host of team_dock_formation_menu; without EVT_Host the global is wrapped directly.
do
  UTIL_PCD = UTIL_PCD or {}
  UTIL_PCD.STEM = "team_dock_formation_menu"
  UTIL_PCD.CMD_INFO = @crc:CMND_BETTERQOL_PC_INFO@

  -- wrap global `name` of this script: make(orig) returns the wrapper (an EVT_Host around handler when the host is
  -- there, else the global itself, once)
  UTIL_PCD.wrapped = UTIL_PCD.wrapped or {}
  function UTIL_PCD.Wrap(name, make)
    if type(EVT_Host) == "table" and type(EVT_Host.on) == "function" then
      EVT_Host.on(UTIL_PCD.STEM, name, {id = "BetterQoL.passive_config." .. name, phase = "around", fn = function(nxt, ...)
        return make(nxt)(...)
      end})
      return true
    end
    local cur = _ENV[name]
    if type(cur) ~= "function" or UTIL_PCD.wrapped[cur] then
      return false
    end
    local w = make(cur)
    UTIL_PCD.wrapped[w] = true
    _ENV[name] = w
    return true
  end

  -- plugin answer for a player: on (bool), mode (0 none, 1 all slots, 2 Ídolo: slots 4-5)
  function UTIL_PCD.Info(h)
    if h == nil or h == 0 then
      return false, 0
    end
    local ok, got, mode = pcall(funcLuaCommand, UTIL_PCD.CMD_INFO, h)
    if not ok or type(mode) ~= "number" then
      return false, 0
    end
    return got == true, mode
  end

  -- During a session the dock's own layers are hidden and shown again after it (the configurator's list window
  -- draws on the left half): BetterQoL.PassiveSession (assets/lua/_all/passive_config_session.lua), the one opener
  -- the bank's command list uses too. The group and its camera stay as they are, so the player page's model keeps
  -- its framing; the dock's and mods' Steps may show a card again, so the session hides again each waited frame.
  function UTIL_PCD.Session()
    local S = type(BetterQoL) == "table" and BetterQoL.PassiveSession or nil
    if type(S) == "table" and type(S.Run) == "function" then
      return S
    end
    return nil
  end

  -- dispatch of type 9 inside the team dock's per-player coroutine: true = handled here (the original's steps)
  function UTIL_PCD.Plate(h)
    local on, mode = UTIL_PCD.Info(h)
    local session = UTIL_PCD.Session()
    if not on or mode <= 0 or session == nil then
      return false
    end
    if type(ChangePageInfo) == "function" then
      pcall(ChangePageInfo, 2)
    end
    -- no team-dock input while the plate runs the session (restored below / by the retail path after the branch).
    -- 2026-10-13 (owner: «en las pasivas configurables el jugador se ve alejado»): the dock's layer group
    -- team_dock_formation_menu (935586083) is NOT suspended any more. Its name is also the menu model camera's
    -- (external_camera_config row 25), and the player page's 3D model (Inazuma Fantasy's plate_model, layer
    -- evt_pp_model) is framed by that camera: with the group suspended the model drew tiny at the left edge. The
    -- retail dock never suspends that group while a 3D model is up (its visual check, type 6, skips the suspend);
    -- the state kept here is the one of the ordinary player page over the dock (the dock's menu object inactive);
    -- the dock's field is hidden layer by layer instead (BetterQoL.PassiveSession.Run).
    pcall(funcLuaMenuCommand, 1558704558, 2049316981, false)
    if g_parentMenuId ~= nil and g_parentMenuId ~= 0 then
      pcall(funcLuaMenuCommand, 1558704558, g_parentMenuId, false)
    end
    session.Run(h, g_parentMenuId or 0, {keep_hidden = true})
    if g_parentMenuId ~= nil and g_parentMenuId ~= 0 then
      pcall(funcLuaMenuCommand, 1558704558, g_parentMenuId, true)
    end
    if type(SetupDefaultFormationButtonGuide) == "function" then
      pcall(SetupDefaultFormationButtonGuide)
    end
    return true
  end

  -- every layer instance this menu sets up (hidden during a session)
  UTIL_PCD.Wrap("OnSetupLayer", function(orig)
    return function(a1, a2, ...)
      local session = UTIL_PCD.Session()
      if session ~= nil then
        session.NoteLayer(a1, a2)
      end
      return orig(a1, a2, ...)
    end
  end)

  UTIL_PCD.Wrap("GetSelectSettingTypeOrderList", function(orig)
    return function(...)
      local src = orig(...)
      if type(src) ~= "table" then
        return src
      end
      if type(GetFormationSelectCharaStHdl) ~= "function" then
        return src
      end
      local h = GetFormationSelectCharaStHdl()
      local on, mode = UTIL_PCD.Info(h)
      if not on then
        return src
      end
      local out = {}
      local has9 = false
      for i = 1, #src do
        local t = src[i]
        if t == 9 then
          has9 = true
        end
        if t ~= 10 and (mode > 0 or t ~= 9) then
          out[#out + 1] = t
        end
      end
      if mode > 0 then
        if not has9 then
          out[#out + 1] = 9
        end
        EVT_PRIME_NO_INHERIT = false -- Inazuma Fantasy's Prime refusal belongs to the retired inheritance
        if type(RemoveToGrayoutList) == "function" then
          RemoveToGrayoutList(9)
        end
      end
      return out
    end
  end)
  -- «Configuración de pasivas» (setting type 9) of the player popup: the session above instead of the inherit menu,
  -- for the players the plugin configures (the same test UTIL_PCD.Plate makes)
  if VRFW_ListRows ~= nil then
    VRFW_ListRows.Handle(VRFW_ListRows.PLAYER_COMMANDS, {id = "BetterQoL.passive_config",
      row = VRFW_ListRows.PLAYER_COMMAND.INHERITED_PASSIVES,
      when = function(context)
        local on, mode = UTIL_PCD.Info(context.handle)
        return on and mode > 0
      end,
      run = function(context)
        UTIL_PCD.Plate(context.handle)
      end})
  end
@ICONS@
  UTIL_PCI.Install(UTIL_PCD.Wrap)
end
