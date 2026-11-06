-- Team planner of the mod BetterQoL (docs/game/ui/team-planner.md), team dock part (soccer_team_dock_menu). X on a card of
-- a squad with ghosts (OnFunction 3702644710, the retail name form key): the retail open of the formation screen, which
-- then picks the card up (parameter util_tp_auto_move, util_tp_formation.lua). SOURCE of
-- the hook file util_tp_dock.lua (research/grafts/util_team_planner/gen_hooks.py puts util_tp_common.lua in place of
-- @COMMON@ and fills the @crc placeholders; edit this file, then run the script).
-- * OnInit (before): the ghosts of the mounted team-bank page whose character the save now has get their real card
--   (TP.AssignAll, the game's own placement); the first Step shows «N planned player(s) joined their squad».
-- * UpdateFormationInfo (after): the dock's squad view draws its ghosts (semi-transparent cards over the empty slots);
--   UpdateViewMenuByLock (after): the ghost alpha again (the lock dims every card).
-- * TP.WrapCardRefresh: a focus change redraws the card the cursor left, and a ghost's slot gets its ghost back.
-- * CanActiveTeam (around): a squad with ghosts cannot become the active team; during «Equipo activo» (OnFunction
--   4219711668) the refusal shows BetterQoL.tp_refuse_active (the retail code plays the error sound).
-- * OnBack (around): the dock is not left while the ACTIVE squad has ghosts (the retail rule for an invalid active
--   team), message BetterQoL.tp_refuse_leave.
-- * OnEnter / OnDecideFocus (around): after the formation screen closed, its bank request (parameter util_tp_bank_req,
--   with util_tp_bank_slot for «Planificar equipo») runs the game's own «Banco» (OpenCharaBank, as list item 8 does)
--   through TP.OpenBank: «Añadir del banco» = the retail bank; a plan = the same bank as the planner's bank
--   (parameter util_tp_bank_plan for util_tp_bank.lua: every character of the game listed, a pick goes to the slot).
--   The request names the squad the formation screen shows (its L1 / R1 does not reach the dock): the dock takes that
--   squad first, so the bank opens on it and the dock shows it when the bank closes (TP.TakeSquad, TP.RedrawSquad).
-- Without BetterQoL's script (CMND_BETTERQOL_TP_INFO unanswered) nothing changes.
do
@COMMON@

  local STEM = "soccer_team_dock_menu"
  local SET_ACTIVE = 4219711668  -- OnFunction: «Equipo activo»
  local ATTACH_FORMATION = 2141963976 -- team01_03_attach_formation
  local NEXT_DOCK, LEFT = 2294853123, 2053629800 -- OnFunction: L1 / R1, its «left» argument
  local X_KEY = 3702644710       -- OnFunction: X on a card (the retail name form key)
  local HAS_FOCUS, FOCUS_IDX = 102308320, 2603265800 -- (layer) -> the layer has the control focus; its focused instance

  local function squad()
    return TP.ViewedSquad(STEM)
  end

  TP.Wrap(STEM, "OnInit", function(orig)
    return function(...)
      TP.ghost = {}
      TP.move_open = nil
      VRFW_Param.Clear(TP.KEY_AUTO_MOVE)
      local ok, n = pcall(TP.AssignAll)
      TP.assigned_msg = ok and n or 0
      if not ok then
        TP.Log("assignment failed:", tostring(n))
      end
      return orig(...)
    end
  end)

  TP.Wrap(STEM, "Step", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      if TP.move_open ~= nil then
        local ok, err = coroutine.resume(TP.move_open)
        if not ok then
          TP.Log("formation open failed:", tostring(err))
        end
        if not ok or coroutine.status(TP.move_open) == "dead" then
          TP.move_open = nil
        end
      end
      if (TP.assigned_msg or 0) > 0 then
        local n = TP.assigned_msg
        TP.assigned_msg = 0
        TP.Msg(TP.T_ASSIGNED, "%d planned player(s) joined their squad.", n)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.WrapCardRefresh(STEM, squad)

  TP.Wrap(STEM, "UpdateFormationInfo", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      local set, ty = squad()
      pcall(TP.Ghosts, set, ty)
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "UpdateViewMenuByLock", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      if next(TP.ghost) ~= nil then
        local on, alpha = TP.Info()
        if on then
          for slot in pairs(TP.ghost) do
            local leader = slot == TP.LEADER_SLOT
            TP.Alpha(leader and TP.LEADER or TP.CARD, leader and 0 or slot, alpha)
          end
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  -- X on a card of a squad with ghosts; true when it took the key
  local function open_for_move()
    if TP.move_open ~= nil or type(IsChangeMemberMode) ~= "function" or IsChangeMemberMode() then
      return false
    end
    local editor = rawget(_ENV, "VRFW_TeamEditor")
    if type(editor) == "table" and type(editor.Foreign) == "function" and editor.Foreign() ~= nil then
      return false
    end
    local leader = TP.M(HAS_FOCUS, TP.LEADER) == true
    local layer = leader and TP.LEADER or TP.CARD
    if not leader and TP.M(HAS_FOCUS, TP.CARD) ~= true then
      return false
    end
    local set, ty = squad()
    if not TP.HasGhosts(set, ty) then
      return false
    end
    local row = leader and 0 or TP.M(FOCUS_IDX, TP.CARD)
    if type(row) ~= "number" then
      return false
    end
    local slot = leader and TP.LEADER_SLOT or row
    if TP.Occupant(set, ty, slot) == 0 and (leader or TP.Plans(set, ty)[slot] == nil) then
      return false
    end
    VRFW_Param.Set(TP.KEY_AUTO_MOVE, 1)
    TP.Log("X on squad", set, ty, "slot", slot, ": the formation screen takes the move")
    local co, main = coroutine.running()
    if co ~= nil and not main then
      OnEnter(layer, row)
    else
      TP.move_open = coroutine.create(function()
        OnEnter(layer, row)
      end)
    end
    return true
  end

  TP.Wrap(STEM, "OnFunction", function(orig)
    return function(a1, ...)
      if a1 == X_KEY and open_for_move() then
        return 1
      end
      TP.setting_active = a1 == SET_ACTIVE
      local r = table.pack(orig(a1, ...))
      TP.setting_active = false
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "CanActiveTeam", function(orig)
    return function(set, ...)
      local r = table.pack(orig(set, ...))
      local _, ty = squad()
      if r[1] and TP.HasGhosts(set, ty) then
        if TP.setting_active then
          TP.Msg(TP.T_REFUSE_ACTIVE, "Missing players: this squad has planned players you do not have yet.")
        end
        return false
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "OnBack", function(orig)
    return function(a1, ...)
      local moving = a1 == ATTACH_FORMATION and type(IsChangeMemberMode) == "function" and IsChangeMemberMode()
      if not moving then
        local ok, act = pcall(funcLuaCommand, TP.C.VS_TEAM)
        if ok and type(act) == "number" and TP.HasGhosts(act, 0) then
          TP.Snd(TP.SY_ERROR)
          TP.Msg(TP.T_REFUSE_LEAVE, "The active squad has planned players you do not have yet.")
          return 1
        end
      end
      return orig(a1, ...)
    end
  end)

  -- the one way the planner opens the game's bank (the retail «Banco», OpenCharaBank); `slot` = nil: «Añadir del
  -- banco», the retail bank; a slot: «Planificar equipo», the same bank told by util_tp_bank_plan to list every
  -- character of the game (the ones not owned semi-transparent) and to put the pick in that slot of the squad
  function TP.OpenBank(set, ty, slot)
    VRFW_Param.Clear(TP.KEY_PLAN)
    if slot ~= nil then
      VRFW_Param.Set(TP.KEY_PLAN, TP.PlanCode(set, ty, slot))
    end
    OpenCharaBank()
    -- the bank has closed: a request it did not take goes, the plan list is off (its FinalizeMenu did it already)
    VRFW_Param.Clear(TP.KEY_PLAN)
    if slot ~= nil then
      TP.Cmd(TP.C.BANK_PLAN, false)
    end
  end

  -- the dock shows squad `set` from now on: OpenCharaBank hands the bank the dock's n5 and draws its header from it
  function TP.TakeSquad(set)
    if not TP.SetLocal(STEM, "n5", set) then
      return false
    end
    if type(SetShowTeamDockNo) == "function" then
      pcall(SetShowTeamDockNo, set)
    end
    pcall(function()
      SetFormationId(GetTeamDockFormationId())
    end)
    return true
  end

  -- the dock's own L1 / R1 refresh for squad `set` (it steps from n5, so it starts one above and goes «left»); its
  -- guards can refuse it: n5 stays `set` either way
  function TP.RedrawSquad(set)
    if type(OnFunction) ~= "function" or not TP.SetLocal(STEM, "n5", set + 1) then
      return
    end
    local ok, err = pcall(OnFunction, NEXT_DOCK, LEFT)
    if not ok then
      TP.Log("squad redraw failed:", tostring(err))
    end
    if squad() ~= set then
      TP.SetLocal(STEM, "n5", set)
    end
  end

  -- the formation screen asked for the game's bank: the retail «Banco» once it has closed
  function TP.BankRequest(from)
    if not VRFW_Param.Has(TP.KEY_BANK) then
      return
    end
    -- OpenCharaBank waits for the bank to close: it needs the dock's coroutine (never the main thread)
    local co, main = coroutine.running()
    if co == nil or main then
      TP.Log("bank request seen at", from, "outside a coroutine: kept for the next one")
      return
    end
    local set = VRFW_Param.Get(TP.KEY_BANK)
    local slot = VRFW_Param.Has(TP.KEY_BANK_SLOT) and VRFW_Param.Get(TP.KEY_BANK_SLOT) or nil
    VRFW_Param.Clear(TP.KEY_BANK)
    VRFW_Param.Clear(TP.KEY_BANK_SLOT)
    local cur, ty = squad()
    if type(OpenCharaBank) ~= "function" or type(set) ~= "number" then
      TP.Log("bank request of squad", tostring(set), "dropped")
      return
    end
    local moved = cur ~= nil and cur ~= set
    if moved and not TP.TakeSquad(set) then
      TP.Log("bank request of squad", tostring(set), "dropped (dock on", tostring(cur), ", not movable)")
      return
    end
    TP.Log("bank request of squad", tostring(set), slot ~= nil and ("plan of slot " .. tostring(slot)) or "add", "at", from, "dock was on", tostring(cur))
    TP.OpenBank(set, ty, slot)
    if moved then
      TP.RedrawSquad(set)
    end
    -- the player chosen in the bank lands in the slot: the squad on the pitch drawn again from the team set (the
    -- retail list gets this from its own return only while it holds the focus)
    if type(UpdateFormationInfo) == "function" then
      local okr, er = pcall(UpdateFormationInfo)
      if not okr then
        TP.Log("redraw after the bank failed:", tostring(er))
      end
    end
    if type(SetActiveDockBackground) == "function" then
      local n4 = TP.Local(STEM, "n4")
      pcall(SetActiveDockBackground, n4 ~= nil and n4 == set)
    end
  end

  -- taken when the dock's handler that opened the formation screen has finished (the dock resumed and back in input),
  -- the state in which the game's own list row «Banco» calls OpenCharaBank; never inside ResumeTeamDock: the bank
  -- opened in the frame the dock's resume animation starts left the dock's squad board drawn over the bank
  for _, point in ipairs({"OnEnter", "OnDecideFocus"}) do
    TP.Wrap(STEM, point, function(orig)
      return function(...)
        local r = table.pack(orig(...))
        TP.BankRequest(point)
        return table.unpack(r, 1, r.n)
      end
    end)
  end
end
