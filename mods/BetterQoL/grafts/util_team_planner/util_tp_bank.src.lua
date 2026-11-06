-- Team planner of the mod BetterQoL (docs/game/ui/team-planner.md), bank part (chara_bank_menu, the game's «Banco» of
-- the team dock). SOURCE of the hook file util_tp_bank.lua (research/grafts/util_team_planner/gen_hooks.py puts
-- util_tp_common.lua in place of @COMMON@ and fills the @crc placeholders; edit this file, then run the script).
-- «Planificar equipo» opens this bank (the dock's TP.OpenBank with parameter util_tp_bank_plan = squad, type, slot):
-- * OnInit (around): the plan rule is taken; CMND_BETTERQOL_TP_BANK_PLAN(true) makes the bank's list also list every
--   character of the game the save does not own (BetterQoL's script, after the game's own list build and sort; the
--   game's filter and tabs apply to them), FinalizeMenu (before, created) switches it off.
-- * UpdateItem (around): a row without a character handle is such a character: his card is drawn from his card param
--   at the planner's display rarity and ghost alpha (CMND_BETTERQOL_TP_BANK_ENTRY gives the param of a row).
-- * OnEnter (around): A on a card of the list puts him in the planned slot: an owned card with the game's own check and
--   bank placement, a character not owned as the slot's plan (a ghost); then the bank closes as its own «back» does.
-- Without the plan rule nothing changes: the bank is the retail bank («Añadir del banco»).
do
@COMMON@

  local STEM = "chara_bank_menu"
  local B = TP.B or {}
  TP.B = B
  B.LIST = 449417347             -- team14_01_chara_bank_list
  B.CHECK_MARK = 30530992        -- team00_01_p4_check_mark
  B.HIDDEN_MESHES = {814224422 --[[_icon_lock01]], 2843821468 --[[_icon_lock02]], 2635558741 --[[_icon_card01]],
                     69091055 --[[_icon_card02]]}
  B.MESH_VISIBLE = 3405944500    -- CMND_SET_MESH_VISIBLE (layer, mesh, on, instance)
  B.BACK = 1842266423            -- OnFunction: back (the bank closes)

  function B.Reset()
    B.on, B.set, B.ty, B.slot, B.focus, B.ghosts = false, nil, 0, nil, nil, {}
  end

  -- the param of list row `i` when it is a character not owned (0 = an owned card or none)
  function B.Entry(i)
    local p = TP.Cmd(TP.C.BANK_ENTRY, i)
    return type(p) == "number" and p or 0
  end

  -- a character not owned: his card from the param, small as the bank's cards, at the ghost alpha
  function B.Draw(layer, inst, param)
    local on, alpha, rarity = TP.Info()
    if not on then
      return
    end
    local pos = 0
    if type(GetSoccerCharaCalcParamBestPositionTypeByCharaParamID) == "function"
        and type(ConvertPosTypeToScPosType) == "function" then
      local ok, p = pcall(GetSoccerCharaCalcParamBestPositionTypeByCharaParamID, param, 0)
      if ok then
        local ok2, sp = pcall(ConvertPosTypeToScPosType, p)
        pos = (ok2 and type(sp) == "number") and sp or 0
      end
    end
    local face = 0
    if type(GetCharaFaceType) == "function" then
      local ok, f = pcall(GetCharaFaceType)
      face = (ok and type(f) == "number") and f or 0
    end
    local drawn = TP.M(TP.C.CARD_BY_PARAM, layer, inst, param, false, false, pos, face, 1, false, false, rarity, 0,
      false, true, 0, false, false, false)
    TP.M(TP.C.LAYER_VISIBLE, layer, inst, drawn ~= false)
    TP.M(TP.C.LAYER_VISIBLE, B.CHECK_MARK, inst, false)
    for _, mesh in ipairs(B.HIDDEN_MESHES) do
      TP.M(B.MESH_VISIBLE, layer, mesh, false, inst)
    end
    TP.Alpha(layer, inst, alpha)
    B.ghosts[inst] = true
  end

  -- A on the list's focused card: he goes to the planned slot of the squad on screen (the bank has its own L1 / R1), then
  -- the bank closes
  function B.Pick()
    local h = type(GetSelectedCharaStHdlInList) == "function" and GetSelectedCharaStHdlInList() or 0
    local viewed = TP.ViewedSquad(STEM)
    local set, ty, slot = type(viewed) == "number" and viewed or B.set, B.ty, B.slot
    if TP.Occupant(set, ty, slot) ~= 0 then
      TP.Log("plan bank: squad", set, ty, "slot", slot, "is no longer empty")
      TP.Snd(TP.SY_ERROR)
      return
    end
    if h ~= 0 then
      local used = false
      if type(IsCharaInTeam) == "function" then
        local okU, u = pcall(IsCharaInTeam, h, set)
        used = okU and u == true
      end
      if used or not TP.Place(set, ty, slot, h) then
        TP.Snd(TP.SY_ERROR)
        return
      end
      TP.SetPlan(set, ty, slot, 0)
      TP.Log("plan bank: squad", set, ty, "slot", slot, "owned card", h, "placed")
    else
      local param = B.focus ~= nil and B.Entry(B.focus) or 0
      if param == 0 or not TP.SetPlan(set, ty, slot, param) then
        TP.Snd(TP.SY_ERROR)
        return
      end
      TP.Log("plan bank: squad", set, ty, "slot", slot, "planned", param)
    end
    TP.Snd(TP.SY_OK)
    B.Close()
  end

  -- the bank's own «back» (the list keeps its cards until the bank's FinalizeMenu switches the plan off)
  function B.Close()
    if type(OnFunction) == "function" then
      OnFunction(B.BACK)
    end
  end

  function B.Off()
    if B.on then
      B.on = false
      TP.Cmd(TP.C.BANK_PLAN, false)
    end
  end

  B.Reset()

  TP.Wrap(STEM, "OnInit", function(orig)
    return function(...)
      B.Reset()
      if VRFW_Param.Has(TP.KEY_PLAN) then
        local set, ty, slot = TP.PlanDecode(VRFW_Param.Get(TP.KEY_PLAN))
        VRFW_Param.Clear(TP.KEY_PLAN)
        if set ~= nil and TP.Info() then
          local n = TP.Cmd(TP.C.BANK_PLAN, true)
          if type(n) == "number" then
            B.on, B.set, B.ty, B.slot = true, set, ty, slot
            TP.Log("plan bank: squad", set, ty, "slot", slot, "characters not owned", n)
          end
        end
      end
      return orig(...)
    end
  end)

  local H = VRFW_Host or EVT_Host
  if type(H) == "table" and type(H.on) == "function" then
    H.on(STEM, "FinalizeMenu", {id = "BetterQoL.team_planner.bank_close", phase = "before", create = true, fn = function()
      B.Off()
    end})
  end

  TP.Wrap(STEM, "UpdateItem", function(orig)
    return function(a1, a2, a3, a4, a5, a6, ...)
      if not B.on then
        return orig(a1, a2, a3, a4, a5, a6, ...)
      end
      if a5 then
        B.focus = a3
      end
      local param = (a4 == 0 and type(a3) == "number") and B.Entry(a3) or 0
      if param == 0 then
        local r = table.pack(orig(a1, a2, a3, a4, a5, a6, ...))
        if a6 and B.ghosts[a2] then
          B.ghosts[a2] = nil
          TP.Alpha(a1, a2, 1)
        end
        return table.unpack(r, 1, r.n)
      end
      -- the retail part without the card (its blank card for a row without a handle), then the param card
      local r = table.pack(orig(a1, a2, a3, a4, a5, false, ...))
      if a6 then
        B.Draw(a1, a2, param)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  TP.Wrap(STEM, "OnEnter", function(orig)
    return function(a1, a2, ...)
      local mode = TP.Local(STEM, "n18")
      if B.on and a1 == B.LIST and (mode == nil or mode == 0) then
        B.Pick()
        return
      end
      return orig(a1, a2, ...)
    end
  end)
end
