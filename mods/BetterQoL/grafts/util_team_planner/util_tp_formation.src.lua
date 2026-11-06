-- Team planner of the mod BetterQoL (docs/game/ui/team-planner.md), formation part (team_dock_formation_menu, the
-- «Formación» screen of the team dock). SOURCE of the hook file util_tp_formation.lua
-- (research/grafts/util_team_planner/gen_hooks.py puts util_tp_common.lua in place of @COMMON@ and fills the @crc
-- placeholders; edit this file, then run the script).
-- * OnEnter (around): A on an EMPTY slot (the game plays the error sound there) opens a one-column sub window:
--   «Añadir del banco» and «Planificar equipo» both close the formation screen with a request for the dock
--   (parameters util_tp_bank_req = the squad, util_tp_bank_slot = the slot of a plan); the dock opens the game's own
--   bank (util_tp_dock.lua, TP.OpenBank): the retail bank, or the same bank listing every character of the game
--   (util_tp_bank.lua). On a ghost the window also has «Quitar planificación».
-- * Ghosts: UpdateMemberCharaIconInfoByChrStHdl / UpdateLeaderChara_CommonPostProcess / UpdateMemberCharaBlankSlot
--   (around): an empty planned slot shows its ghost card, a real card on a ghost instance gets its normal alpha back.
-- * The squad is always the one on screen (F.Squad): L1 / R1 on this screen changes it without the dock knowing, so the
--   menu, the plans, the ghosts and the dock's bank request all read the screen's own squad; OnFunction (around) redraws
--   the ghosts when L1 / R1 changed it.
-- * Moving a ghost with X (OnFunction 1565342223, the row CMD_FUNC4 of the card layers): the retail move mode
--   (StartMemberChangeMode) with TP.HOLD_TOKEN as the held handle, which only this file's hooks ever see. The drop is
--   SwapChara (around): plan data only (CMND_BETTERQOL_TP_MOVE), or the game's own check and placement when a real card
--   is displaced. docs/game/ui/team-planner.md section 2.3 has the rules.
-- Without BetterQoL's script (CMND_BETTERQOL_TP_INFO unanswered) nothing changes.
do
@COMMON@

  local STEM = "team_dock_formation_menu"
  local F = TP.F or {}
  TP.F = F
  F.C = {
    SUB_OPEN_POS = 63483614,     -- (x, y): the open sub window's top centre (the opener's position call)
    IS_EXIST_MENU = 2231168902,  -- CMND_IS_EXIST_MENU_OBJECT?
    IS_OPEN = 3693934564,        -- CMND_IS_OPEN_MENU_OBJECT (menu, layer)
    CLOSE_OBJ = 320421347,       -- CMND_CLOSE_MENU_OBJECT
  }
  F.SUB_WINDOW = 968210065       -- sub_window
  F.CURSOR = 2296367164          -- cmn05_01_cursor
  F.DOCK_MENU = 937147172        -- soccer_team_dock_menu
  F.NEXT_DOCK = 2294853123       -- OnFunction: L1 / R1, the next squad
  F.TITLE_SPRITE = 2637871535    -- gtxt_character01 (the one-column window's title sprite)
  F.PARAM_DOCK, F.PARAM_TYPE = 3357163798, 4081600465   -- the dock's parameters for this screen (set, team type)
  F.T_ADD_BANK = @crc:BetterQoL.tp_add_bank@
  F.T_PLAN = @crc:BetterQoL.tp_plan@
  F.T_UNPLAN = @crc:BetterQoL.tp_unplan@
  F.MOVE_KEY = 1565342223        -- OnFunction: X on a card
  F.ROW_ARG = 4108050209         -- the second argument of a row without one
  F.MOVE_CARD = 3241819447       -- team00_01_chara_card_for_move
  F.SKILL_GUIDE = 1803124851     -- soccer11_15_skill_detail_check_button_guide (hidden by the retail pick-up)
  F.SY_PICK = 2064503487         -- sy0007
  F.HAS_FOCUS = 102308320        -- CMND_IS_CTRL_FOCUS_ACTIVE? (layer)
  F.AUTO_MOVE_FRAMES = 600       -- the opening screen gets this long to take the dock's X
  TP.HOLD_TOKEN = -1             -- the held handle of a ghost: no character has it; never reaches the engine
  -- the game's sub window size code by row count (the settings script's GetSubWinSizeAnimeType)
  F.SIZE = {[1] = 0, [2] = 5, [3] = 1, [4] = 2, [5] = 6, [6] = 3, [7] = 7, [8] = 8}

  -- the squad on screen; F.set (the dock's parameter at OnInit) says the dock opened this screen and is the fallback
  function F.Squad()
    if type(F.set) ~= "number" then
      return nil, 0
    end
    local set, ty = TP.ViewedSquad(STEM)
    if type(set) ~= "number" then
      return F.set, F.type or 0
    end
    return set, ty
  end

  function F.Closed(menu)
    local ok, ex = pcall(funcLuaMenuCommand, F.C.IS_EXIST_MENU, menu)
    return ok and ex == false
  end

  -- ---- the menu of an empty slot -----------------------------------------------------------------------------------

  function F.OpenMenu(slot)
    local set, ty = F.Squad()
    if type(set) ~= "number" or not TP.Info() then
      return false
    end
    local plans = TP.Plans(set, ty)
    local rows = {}
    -- both rows open the game's bank from the dock: only when the formation screen was opened by the dock
    if not F.Closed(F.DOCK_MENU) and type(FuncCloseFormationMenu) == "function" then
      rows[#rows + 1] = {id = F.T_ADD_BANK, act = "bank"}
      rows[#rows + 1] = {id = F.T_PLAN, act = "plan"}
    end
    if plans[slot] ~= nil then
      rows[#rows + 1] = {id = F.T_UNPLAN, act = "unplan"}
    end
    local ids, en, new = {}, {}, {}
    for i, r in ipairs(rows) do
      ids[i], en[i], new[i] = r.id, 1, 0
    end
    F.rows, F.slot, F.choice = rows, slot, nil
    if type(SetSubMenuBusy) == "function" then
      SetSubMenuBusy(true)
    end
    TP.Snd(TP.SY_OK)
    -- one cursor owner: the popup's own row cursor; the formation's cursor (the slot's arrow, behind the popup) is
    -- hidden until the popup closes
    TP.M(TP.C.LAYER_VISIBLE, F.CURSOR, 0, false)
    MENU_DEF.OpenSubWindow("UTIL_TP_OnMenu", "", #rows, ids, F.SIZE[#rows] or 0, F.TITLE_SPRITE, en, 0, false, false, 0, 0, new)
    F.state = "menu_opening"
    TP.Log("menu: squad", set, ty, "slot", slot, #rows, "row(s)")
    return true
  end

  function F.OnMenu(a1)
    if F.state ~= "menu_opening" and F.state ~= "menu" then
      return
    end
    F.choice = type(a1) == "number" and a1 >= 0 and F.rows[a1 + 1] or nil
    if F.choice ~= nil then
      funcLuaCommand(F.C.CLOSE_OBJ, F.SUB_WINDOW)
    end
    F.state = "menu_closing"
  end

  function F.MenuDone()
    if type(SetSubMenuBusy) == "function" then
      SetSubMenuBusy(false)
    end
    local c = F.choice
    F.choice = nil
    F.state = nil
    TP.M(TP.C.LAYER_VISIBLE, F.CURSOR, 0, true)
    if c == nil then
      return
    end
    local set, ty = F.Squad()
    if c.act == "bank" or c.act == "plan" then
      -- the dock opens the bank once this screen has closed (TP.OpenBank): the retail bank, or for a plan the same
      -- bank listing every character of the game, whose pick goes to this slot
      VRFW_Param.Clear(TP.KEY_BANK)
      VRFW_Param.Clear(TP.KEY_BANK_SLOT)
      VRFW_Param.Set(TP.KEY_BANK, set)
      if c.act == "plan" then
        VRFW_Param.Set(TP.KEY_BANK_SLOT, F.slot)
      end
      TP.Log("bank request (" .. c.act .. "): squad", set, "slot", F.slot)
      pcall(FuncCloseFormationMenu)
    elseif c.act == "unplan" then
      TP.SetPlan(set, ty, F.slot, 0)
      TP.Ghosts(set, ty, F.slot)
      TP.Snd(TP.SY_OK)
    end
  end

  -- ---- moving a ghost ----------------------------------------------------------------------------------------------

  -- the focused slot (19 = the coach card)
  function F.FocusSlot()
    if IsSelectLeaderCard() then
      return TP.LEADER_SLOT
    end
    return GetFormationSelectCharaIdx()
  end

  -- X on a ghost of the pitch or the bench: picked up as the retail OnEnterCommon does; true when it took the key
  function F.TryHold()
    if type(F.set) ~= "number" or F.state ~= nil or IsChangeMemberMode() or IsSubMenuBusy() or IsUniverseCharaMode()
        or TP.Local(STEM, "flag2") == true or IsSelectLeaderCard() or TP.M(F.HAS_FOCUS, TP.CARD) ~= true then
      return false
    end
    local set, ty = F.Squad()
    if type(set) ~= "number" or not TP.Info() then
      return false
    end
    local slot = F.FocusSlot()
    local param = TP.Plans(set, ty)[slot]
    if param == nil or TP.Occupant(set, ty, slot) ~= 0 then
      return false
    end
    TP.Unghost(slot)
    TP.hold = {set = set, ty = ty, slot = slot, param = param}
    SetFormationHoldCharaIdx(slot)
    SetFormationHoldCharaTeamDockNo(set)
    SetHoldCharaStHandle(TP.HOLD_TOKEN)
    StartMemberChangeMode(set)
    TP.M(TP.C.LAYER_VISIBLE, F.SKILL_GUIDE, 0, false)
    TP.Snd(F.SY_PICK)
    TP.Log("picked up: squad", set, ty, "slot", slot)
    return true
  end

  -- a real card back on the screen, as SwapChara redraws one
  function F.DrawReal(set, ty, h, slot)
    UpdateMemberCharaIconInfoByChrStHdl(h, slot, GetApplyFormationId(), GetCharaFaceType(), 0, IsCaptainChara(h), nil, nil,
      nil, nil, nil, nil, nil, nil, GetCharaTitleAttr(set, ty, h))
  end

  -- the plan landed on `target`: the retail end of the move mode, the card settling there; `real` went to the old slot
  function F.EndHold(set, ty, target, real)
    local held = TP.hold
    local same = held.set == set and held.ty == ty
    TP.hold = nil
    if same and target ~= held.slot then
      SetFormationHoldCharaIdx(target)
      UpdateHoldCharaOriginPos()
      ResetBlankLayerView(held.slot, false)
      if real ~= nil then
        F.DrawReal(set, ty, real, held.slot)
      else
        UpdateMemberCharaBlankSlot(held.slot, true)
      end
    end
    TerminateMemberChangeMode(rawget(_ENV, "_teamDockTop"))
    TP.Alpha(F.MOVE_CARD, 0, 1)
    TP.Log("dropped: squad", held.set, held.ty, "slot", held.slot, "-> squad", set, ty, "slot", target,
      real ~= nil and "(real card swapped)" or "")
  end

  -- the drop of a held ghost; 0 = done, 1 = refused (the retail error sound; the ghost stays in the hand)
  function F.DropHeld()
    local held = TP.hold
    if held == nil then
      return 1
    end
    local set, ty = F.Squad()
    local target = F.FocusSlot()
    if type(set) ~= "number" or target == TP.LEADER_SLOT then
      return 1
    end
    if held.set == set and held.ty == ty and held.slot == target then
      F.EndHold(set, ty, target, nil)
      return 0
    end
    local real = TP.Occupant(set, ty, target)
    if real == 0 then
      if TP.Cmd(TP.C.MOVE, held.set, held.ty, held.slot, set, ty, target) ~= true then
        return 1
      end
      F.EndHold(set, ty, target, nil)
      return 0
    end
    -- a real card here: it takes the ghost's empty slot through the game's own check and placement, in this squad only
    if held.set ~= set or held.ty ~= ty then
      return 1
    end
    local okC, accept = pcall(funcLuaCommand, TP.C.PLACE_CHECK, real, set, held.slot, set, ty)
    if not (okC and accept) then
      return 1
    end
    local okP = pcall(funcLuaCommand, TP.C.PLACE, set, held.slot, set, real, ty)
    if not okP or TP.Occupant(set, ty, held.slot) ~= real or TP.Occupant(set, ty, target) ~= 0 then
      TP.Log("squad", set, ty, "real card", real, "not placed on slot", held.slot)
      return 1
    end
    if TP.Cmd(TP.C.MOVE, set, ty, held.slot, set, ty, target) ~= true then
      pcall(funcLuaCommand, TP.C.PLACE, set, target, set, real, ty)   -- the plan stayed: the real card goes back
      return 1
    end
    F.EndHold(set, ty, target, real)
    return 0
  end

  -- a real card dropped on a ghost: the swap the player asked for, the ghost going to the slot the card left
  function F.DropOnPlan(orig, a1, a2, set, ty, target)
    local from_set = GetFormationHoldCharaTeamDockNo()
    local from_slot = IsHoldLeaderCard() and TP.LEADER_SLOT or GetFormationHoldCharaIdx()
    if from_set ~= set or from_slot == TP.LEADER_SLOT or target == TP.LEADER_SLOT or TP.Occupant(set, ty, from_slot) ~= a1 then
      TP.Log("squad", set, ty, "slot", target, "holds a plan with nowhere to go: the drop is refused")
      return 1
    end
    TP.keep_plans = true
    local r = table.pack(orig(a1, a2))
    TP.keep_plans = false
    if r[1] == 0 and TP.Occupant(set, ty, target) == a1 and TP.Occupant(set, ty, from_slot) == 0 then
      TP.Cmd(TP.C.MOVE, set, ty, target, set, ty, from_slot)
    end
    pcall(TP.Ghosts, set, ty)
    return table.unpack(r, 1, r.n)
  end

  -- per frame while the sub window opens or closes
  function F.Step()
    local st = F.state
    if st == "auto_move" then      -- the dock's X waits for this screen to open
      F.auto_frames = F.auto_frames - 1
      if F.auto_frames <= 0 then
        F.state = nil
      elseif IsEndOpenAnimeAllDelayInLayers() and TP.M(F.HAS_FOCUS, IsSelectLeaderCard() and TP.LEADER or TP.CARD) == true then
        F.state = nil
        OnFunction(F.MOVE_KEY, F.ROW_ARG)
      end
    elseif st == "menu_opening" then
      local ok, open = pcall(funcLuaCommand, F.C.IS_OPEN, F.SUB_WINDOW, F.CURSOR)
      if ok and open == true then
        pcall(funcLuaCommand, F.C.SUB_OPEN_POS, 500, -260)
        F.state = "menu"
      end
    elseif st == "menu_closing" then
      if F.Closed(F.SUB_WINDOW) then
        F.MenuDone()
      end
    end
  end

  rawset(_ENV, "UTIL_TP_OnMenu", function(...) return F.OnMenu(...) end)

  -- ---- hooks -------------------------------------------------------------------------------------------------------

  TP.Wrap(STEM, "OnInit", function(orig)
    return function(...)
      TP.ghost, F.state = {}, nil
      TP.hold, TP.keep_plans = nil, false
      F.set, F.type = nil, 0
      if VRFW_Param.Has(TP.KEY_AUTO_MOVE) then
        VRFW_Param.Clear(TP.KEY_AUTO_MOVE)
        F.state, F.auto_frames = "auto_move", F.AUTO_MOVE_FRAMES
      end
      if VRFW_Param.Has(F.PARAM_DOCK) then
        F.set = VRFW_Param.Get(F.PARAM_DOCK)
      end
      if VRFW_Param.Has(F.PARAM_TYPE) then
        F.type = VRFW_Param.Get(F.PARAM_TYPE) or 0
      end
      VRFW_Param.Clear(TP.KEY_BANK)  -- a request nobody took
      VRFW_Param.Clear(TP.KEY_BANK_SLOT)
      return orig(...)
    end
  end)

  -- L1 / R1: the retail refresh redraws only the occupied cards; the ghosts of the squad left go, those of this one come
  TP.Wrap(STEM, "OnFunction", function(orig)
    return function(a1, ...)
      if a1 == F.MOVE_KEY and F.TryHold() then
        return 1
      end
      local before = a1 == F.NEXT_DOCK and F.Squad() or nil
      local r = table.pack(orig(a1, ...))
      if before ~= nil then
        local set, ty = F.Squad()
        if set ~= before then
          TP.Log("lineup screen: squad", before, "->", set)
          pcall(TP.Ghosts, set, ty)
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "Step", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      if F.state ~= nil then
        local ok, err = pcall(F.Step)
        if not ok then
          TP.Log("step failed:", tostring(err))
          F.state = nil
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "OnEnter", function(orig)
    return function(a1, a2, ...)
      if F.state ~= nil then
        return 1
      end
      if (a1 == TP.CARD or a1 == TP.LEADER) and type(F.set) == "number"
          and not (type(IsChangeMemberMode) == "function" and IsChangeMemberMode())
          and not (type(IsSubMenuBusy) == "function" and IsSubMenuBusy())
          and TP.Local(STEM, "flag2") ~= true
          and TP.M(102308320 --[[CMND_IS_CTRL_FOCUS_ACTIVE?]], a1, a2) == true then
        local h = type(GetFormationSelectCharaStHdl) == "function" and GetFormationSelectCharaStHdl() or nil
        if h == 0 then
          local leader = type(IsSelectLeaderCard) == "function" and IsSelectLeaderCard()
          local slot = leader and TP.LEADER_SLOT or (type(GetFormationSelectCharaIdx) == "function" and GetFormationSelectCharaIdx() or nil)
          if type(slot) == "number" and F.OpenMenu(slot) then
            return 1
          end
        end
      end
      return orig(a1, a2, ...)
    end
  end)

  TP.Wrap(STEM, "SwapChara", function(orig)
    return function(a1, a2, ...)
      if TP.hold ~= nil or a1 == TP.HOLD_TOKEN then
        return F.DropHeld()
      end
      local set, ty = F.Squad()
      if type(set) ~= "number" then
        return orig(a1, a2, ...)
      end
      local target = F.FocusSlot()
      if TP.Plans(set, ty)[target] ~= nil and TP.Occupant(set, ty, target) == 0 then
        return F.DropOnPlan(orig, a1, a2, set, ty, target)
      end
      local r = table.pack(orig(a1, a2, ...))
      if r[1] == 0 then
        pcall(TP.Ghosts, set, ty)    -- the retail end of a move sets every card's alpha to 1
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "TerminateMemberChangeMode", function(orig)
    return function(...)
      local held = TP.hold ~= nil
      TP.hold = nil
      local r = table.pack(orig(...))
      if held then
        TP.Alpha(F.MOVE_CARD, 0, 1)
      end
      local set, ty = F.Squad()
      pcall(TP.Ghosts, set, ty)
      return table.unpack(r, 1, r.n)
    end
  end)

  -- the card in the hand: the retail keeps the place (its argument true), the ghost is drawn in place of a card
  TP.Wrap(STEM, "UpdateMoveHoldCharaChardLayer", function(orig)
    return function(a1, ...)
      local held = TP.hold
      if held == nil then
        return orig(a1, ...)
      end
      orig(true)
      if a1 ~= true then
        local _, alpha, rarity = TP.Info()
        TP.DrawCard(F.MOVE_CARD, 0, held.slot, held.param, rarity, alpha)
      end
    end
  end)

  TP.Wrap(STEM, "IsEquipDirectorBadge", function(orig)
    return function(a1, ...)
      if a1 == TP.HOLD_TOKEN then
        return false
      end
      return orig(a1, ...)
    end
  end)

  TP.WrapCardRefresh(STEM, F.Squad)
end
