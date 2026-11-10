  BetterQoL = BetterQoL or {}
  BetterQoL.team_planner = BetterQoL.team_planner or {}
  local TP = BetterQoL.team_planner
  TP.C = {
    INFO = @crc:CMND_BETTERQOL_TP_INFO@,
    LIST = @crc:CMND_BETTERQOL_TP_LIST@,
    SET = @crc:CMND_BETTERQOL_TP_SET@,
    CANDIDATES = @crc:CMND_BETTERQOL_TP_CANDIDATES@,
    ASSIGNED = @crc:CMND_BETTERQOL_TP_ASSIGNED@,
    MOVE = @crc:CMND_BETTERQOL_TP_MOVE@,
    PENDING = @crc:CMND_BETTERQOL_TP_PENDING@,
    BANK_PLAN = @crc:CMND_BETTERQOL_TP_BANK_PLAN@,
    BANK_ENTRY = @crc:CMND_BETTERQOL_TP_BANK_ENTRY@,
    TEXT_GET = 4074371074,       -- CMND_TEXT_GET
    SND = 1917805374,            -- the menus' sound effect call
    SYS_MSG = 2289627655,        -- system message (text, 0, 0, 0, 0, 0, false)
    LAYER_VISIBLE = 711242136,   -- CMND_SET_LAYER_VISIBLE (layer, instance, on)
    MESH_VISIBLE = 3405944500,   -- CMND_SET_MESH_VISIBLE (layer, mesh, on, instance)
    MODEL_ALPHA = 4231609516,    -- CMND_SET_LAYER_MODEL_ALPHA (layer, instance, 0, alpha)
    TEXT_ALPHA = 1126837159,     -- CMND_SET_MENU_TEXT_ALPHA (layer, instance, text node, alpha)
    PRIM_ALPHA = 2219773080,     -- CMND_SET_PRIM_ALPHA (layer, instance, prim, alpha)
    CARD_BY_PARAM = 2339877830,
    FORMATION_INFO = 2649030357, -- CMND_GET_SOCCER_FORMATION_INFO (6, formation, slot) -> ok, pos type
    PLACE_CHECK = 1730898405,
    PLACE = 193693077,           -- (set, pos, from set, hdl, type): the bank -> slot placement
    PLACE_PREP = 2379170951,
    VS_TEAM = 3713813716,        -- CMND_GET_VS_USE_TEAM_SET
    HAS_FOCUS = 102308320,
  }
  TP.CARD = 1973487846           -- team00_01_chara_card_for_soccer
  TP.LEADER = 1658289671         -- team00_01_chara_card_for_leader
  TP.BLANK = 3571911991          -- team00_01_p1_chara_card_blank
  TP.BLANK_LEADER = 2290394976   -- team00_01_p1_chara_card_blank_for_leader
  TP.TEXT_NODE = 170976702
  TP.PRIMS = {3653219854 --[[num_chr_l01]], 3469038147 --[[num_chr_s01]]}
  TP.MESH_LOCK_BIG, TP.MESH_LOCK_SMALL = 814224422 --[[_icon_lock01]], 2843821468 --[[_icon_lock02]]
  TP.MESH_BOOKING_BIG, TP.MESH_BOOKING_SMALL = 2635558741 --[[_icon_card01]], 69091055 --[[_icon_card02]]
  TP.MESH_BLANK_BIG, TP.MESH_BLANK_SMALL = 3133268926 --[[_chr_blank01]], 2623475960 --[[_chr_blank_s01]]
  TP.MESH_SOURCE_BIG, TP.MESH_SOURCE_SMALL = 3083628236 --[[_chr_change_blank01]], 308279580 --[[_chr_change_blank_s01]]
  TP.NEXT_DOCK = 2294853123      -- OnFunction: L1 / R1, the next squad
  TP.LEADER_SLOT = 19
  TP.FROM_BANK = 16
  TP.SY_OK, TP.SY_MOVE, TP.SY_BACK, TP.SY_ERROR = 3848881948, 2500047763, 202039849, 2086672038
  TP.KEY_BANK = @crc:betterqol_tp_bank_req@
  TP.KEY_BANK_SLOT = @crc:betterqol_tp_bank_slot@ -- parameter: with it the request is a plan of that slot
  TP.KEY_PLAN = @crc:betterqol_tp_bank_plan@
  TP.KEY_AUTO_MOVE = @crc:betterqol_tp_auto_move@
  TP.T_REFUSE_ACTIVE = @crc:BetterQoL.tp_refuse_active@
  TP.T_REFUSE_LEAVE = @crc:BetterQoL.tp_refuse_leave@
  TP.T_ASSIGNED = @crc:BetterQoL.tp_assigned@
  TP.ghost = TP.ghost or {}      -- slot -> param drawn as a ghost on this screen

  function TP.plan_code(set, ty, slot)
    return set * 256 + (ty or 0) * 32 + slot
  end

  function TP.plan_decode(code)
    if type(code) ~= "number" or code < 0 then
      return nil
    end
    return math.floor(code / 256), math.floor((code % 256) / 32), code % 32
  end

  function TP.log(...)
    TP.logger = TP.logger or VRFW.logger.new("BetterQoL team_planner")
    TP.logger(...)
  end

  function TP.snd(id)
    pcall(funcLuaCommand, TP.C.SND, id)
  end

  function TP.text(id, fallback)
    local ok, s = pcall(funcLuaCommand, TP.C.TEXT_GET, id)
    if ok and type(s) == "string" and s ~= "" then
      return s
    end
    return fallback
  end

  function TP.msg(id, fallback, ...)
    local s = TP.text(id, fallback)
    if select("#", ...) > 0 then
      local ok, f = pcall(string.format, s, ...)
      s = ok and f or s
    end
    pcall(funcLuaCommand, TP.C.SYS_MSG, s, 0, 0, 0, 0, 0, false)
  end

  function TP.info()
    local on, alpha, rarity = VRFW.host.command(TP.C.INFO)
    if on ~= true then
      return false, 1, 4
    end
    return true, type(alpha) == "number" and alpha or 0.45, type(rarity) == "number" and rarity or 4
  end

  -- slot -> param of a squad, and the display rarity
  function TP.plans(set, ty)
    local out = {}
    local s, rarity = VRFW.host.command(TP.C.LIST, set, ty or 0)
    if type(s) == "string" then
      for slot, param in s:gmatch("(%d+):(%d+)") do
        out[tonumber(slot)] = tonumber(param)
      end
    end
    return out, type(rarity) == "number" and rarity or 4
  end

  function TP.set_plan(set, ty, slot, param)
    return VRFW.host.command(TP.C.SET, set, ty or 0, slot, param or 0) == true
  end

  -- Returns the character in a squad slot (0 means empty).
  function TP.occupant(set, ty, slot)
    if type(SearchTeamSetCharaStHdlByScPosNo) ~= "function" then
      return 0
    end
    local ok, h = pcall(SearchTeamSetCharaStHdlByScPosNo, slot, set, ty or 0)
    if ok and type(h) == "number" and h ~= 0 then
      if type(IsInvalidSoccerCharaHdl) == "function" and IsInvalidSoccerCharaHdl(h) then
        return 0
      end
      return h
    end
    return 0
  end

  -- Returns the slots of a squad that hold a ghost (planned and still empty).
  function TP.ghost_slots(set, ty)
    local out, n = {}, 0
    local plans = TP.plans(set, ty)
    for slot, param in pairs(plans) do
      if TP.occupant(set, ty, slot) ~= 0 then
        if not TP.keep_plans then
          TP.set_plan(set, ty, slot, 0)
          TP.log("squad", set, ty, "slot", slot, "filled by hand: plan dropped")
        end
      else
        out[slot] = param
        n = n + 1
      end
    end
    return out, n
  end

  function TP.has_ghosts(set, ty)
    if type(set) ~= "number" or not TP.info() then
      return false
    end
    local _, n = TP.ghost_slots(set, ty or 0)
    return n > 0
  end

  -- Places an owned character into a squad slot with the game's own check and bank placement.
  function TP.place(set, ty, slot, h)
    local okC, accept, code = pcall(funcLuaCommand, TP.C.PLACE_CHECK, h, set, slot, TP.FROM_BANK, ty)
    if not (okC and accept) then
      TP.log("squad", set, ty, "slot", slot, "copy", h, "refused by the game's check, code", tostring(code))
      return false
    end
    VRFW.host.menu_command(TP.C.PLACE_PREP, h)
    local okP = pcall(funcLuaCommand, TP.C.PLACE, set, slot, TP.FROM_BANK, h, ty)
    if okP and TP.occupant(set, ty, slot) == h then
      return true
    end
    TP.log("squad", set, ty, "slot", slot, "placement of", h, "did not stick")
    return false
  end

  -- Returns a ghost's real copy.
  function TP.assign_slot(set, ty, slot, param)
    local list = VRFW.host.command(TP.C.CANDIDATES, param)
    if type(list) ~= "string" or list == "" then
      return nil
    end
    for hs in list:gmatch("%d+") do
      local h = tonumber(hs)
      local used = false
      if type(IsCharaInTeam) == "function" then
        local okU, u = pcall(IsCharaInTeam, h, set)
        used = okU and u == true
      end
      if not used then
        if TP.place(set, ty, slot, h) then
          VRFW.host.command(TP.C.ASSIGNED, set, ty, slot, h)
          return h
        end
      end
    end
    return nil
  end

  function TP.assign_all()
    if not TP.info() then
      return 0
    end
    local squads = VRFW.host.command(TP.C.PENDING)
    if type(squads) ~= "string" or squads == "" then
      return 0
    end
    local n = 0
    for s, t in squads:gmatch("(%d+):(%d+)") do
      local set, ty = tonumber(s), tonumber(t)
      local ghosts = TP.ghost_slots(set, ty)
      for slot, param in pairs(ghosts) do
        if TP.assign_slot(set, ty, slot, param) then
          n = n + 1
        end
      end
    end
    if n > 0 then
      TP.log("assigned", n, "planned player(s)")
    end
    return n
  end


  function TP.alpha(layer, inst, a)
    VRFW.host.menu_command(TP.C.MODEL_ALPHA, layer, inst, 0, a)
    VRFW.host.menu_command(TP.C.TEXT_ALPHA, layer, inst, TP.TEXT_NODE, a)
    for _, p in ipairs(TP.PRIMS) do
      VRFW.host.menu_command(TP.C.PRIM_ALPHA, layer, inst, p, a)
    end
  end

  -- the formation of the squad on screen
  function TP.formation_id()
    for _, f in ipairs({"GetTeamDockFormationId", "GetApplyFormationId"}) do
      local fn = rawget(_ENV, f)
      if type(fn) == "function" then
        local ok, id = pcall(fn)
        if ok and type(id) == "number" and id ~= 0 then
          return id
        end
      end
    end
    return 0
  end

  -- Draws the ghost of `param` as the card of slot `slot` on a layer instance.
  function TP.draw_card(layer, inst, slot, param, rarity, alpha)
    local leader = slot == TP.LEADER_SLOT
    local main = false
    if not leader and type(IsMainMember) == "function" then
      local ok, m = pcall(IsMainMember, slot)
      main = ok and m == true
    end
    local big = leader
    if not leader and type(IsCharaCardBigtype) == "function" then
      local ok, b = pcall(IsCharaCardBigtype, slot, TP.CARD)
      big = ok and b == true
    end
    local pos = 0
    if main then
      local ok, got, p = pcall(funcLuaCommand, TP.C.FORMATION_INFO, 6, TP.formation_id(), slot)
      pos = (ok and got and type(p) == "number") and p or 0
    elseif not leader and type(GetSoccerCharaCalcParamBestPositionTypeByCharaParamID) == "function"
        and type(ConvertPosTypeToScPosType) == "function" then
      local ok, p = pcall(GetSoccerCharaCalcParamBestPositionTypeByCharaParamID, param, 0)
      if ok then
        local ok2, sp = pcall(ConvertPosTypeToScPosType, p)
        pos = ok2 and sp or 0
      end
    end
    local face = 0
    if type(GetCharaFaceType) == "function" then
      local ok, f = pcall(GetCharaFaceType)
      face = (ok and type(f) == "number") and f or 0
    end
    local manager = false
    if not leader and type(IsManager) == "function" then
      local ok, m = pcall(IsManager, slot)
      manager = ok and m == true
    end
    local drawn = VRFW.host.menu_command(TP.C.CARD_BY_PARAM, layer, inst, param, big, leader, pos, face, 1, false, false, rarity, 0,
      false, main, 0, false, false, manager)
    if drawn == false then
      TP.log("ghost", slot, param, "not drawn")
      return false
    end
    VRFW.host.menu_command(TP.C.LAYER_VISIBLE, layer, inst, true)
    -- Draws a ghost's marker.
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, layer, TP.MESH_LOCK_BIG, big, inst)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, layer, TP.MESH_LOCK_SMALL, not big, inst)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, layer, TP.MESH_BOOKING_BIG, false, inst)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, layer, TP.MESH_BOOKING_SMALL, false, inst)
    TP.alpha(layer, inst, alpha)
    return true
  end

  -- draw the ghost of `param` on slot `slot` (19 = the coach card)
  function TP.draw(slot, param, rarity, alpha)
    local leader = slot == TP.LEADER_SLOT
    if not TP.draw_card(leader and TP.LEADER or TP.CARD, leader and 0 or slot, slot, param, rarity, alpha) then
      return false
    end
    VRFW.host.menu_command(TP.C.LAYER_VISIBLE, leader and TP.BLANK_LEADER or TP.BLANK, leader and 0 or slot, false)
    TP.ghost[slot] = param
    return true
  end

  function TP.unghost(slot)
    if TP.ghost[slot] == nil then
      return
    end
    TP.ghost[slot] = nil
    local leader = slot == TP.LEADER_SLOT
    TP.alpha(leader and TP.LEADER or TP.CARD, leader and 0 or slot, 1)
  end

  function TP.ghosts(set, ty, only)
    if type(set) ~= "number" then
      return
    end
    local on, alpha, rarity = TP.info()
    if not on then
      return
    end
    local ghosts = TP.ghost_slots(set, ty or 0)
    local held = TP.hold
    if held ~= nil and held.set == set and held.ty == (ty or 0) then
      ghosts[held.slot] = nil
    end
    for slot in pairs(TP.ghost) do
      if (only == nil or only == slot) and ghosts[slot] == nil then
        TP.unghost(slot)
        if TP.occupant(set, ty or 0, slot) == 0 then
          local leader = slot == TP.LEADER_SLOT
          VRFW.host.menu_command(TP.C.LAYER_VISIBLE, leader and TP.LEADER or TP.CARD, leader and 0 or slot, false)
          if type(UpdateMemberCharaBlankSlot) == "function" then
            pcall(UpdateMemberCharaBlankSlot, leader and 0 or slot, true, leader or nil)
          end
        end
      end
    end
    for slot, param in pairs(ghosts) do
      if only == nil or only == slot then
        TP.draw(slot, param, rarity, alpha)
      end
    end
  end

  -- Marks the slot a held ghost left.
  function TP.mark_held_slot(slot)
    local big = true
    if type(IsCharaCardBigtype) == "function" then
      local ok, b = pcall(IsCharaCardBigtype, slot)
      big = ok and b == true
    end
    VRFW.host.menu_command(TP.C.LAYER_VISIBLE, TP.BLANK, slot, true)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, TP.BLANK, TP.MESH_BLANK_BIG, false, slot)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, TP.BLANK, TP.MESH_BLANK_SMALL, false, slot)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, TP.BLANK, TP.MESH_SOURCE_BIG, big, slot)
    VRFW.host.menu_command(TP.C.MESH_VISIBLE, TP.BLANK, TP.MESH_SOURCE_SMALL, not big, slot)
  end

  -- Wraps global `name` of the stem.
  TP.wrapped = TP.wrapped or {}
  function TP.wrap(stem, name, make)
    local H = VRFW.host
    H.on(stem, name, {id = "BetterQoL.team_planner." .. name, phase = "around", fn = function(nxt, ...)
      return make(nxt)(...)
    end})
  end

  -- Wraps the card refreshes of the formation INCLUDE on a stem.
  function TP.wrap_card_refresh(stem, squad)
    TP.wrap(stem, "UpdateMemberCharaIconInfoByChrStHdl", function(orig)
      return function(...)
        local r = table.pack(orig(...))
        local a = table.pack(...)
        local slot = a[2] or 0
        local layer = a[7] or TP.CARD
        local inst = a[8] or slot
        local set, ty = squad()
        if layer == TP.CARD and inst == slot and type(set) == "number" then
          if r[1] then
            TP.unghost(slot)
          elseif (a[1] or 0) == 0 then
            pcall(TP.ghosts, set, ty, slot)
          end
        end
        return table.unpack(r, 1, r.n)
      end
    end)

    TP.wrap(stem, "UpdateLeaderChara_CommonPostProcess", function(orig)
      return function(a1, a2, a3, a4, ...)
        local r = table.pack(orig(a1, a2, a3, a4, ...))
        local set, ty = squad()
        if a1 == TP.LEADER and type(set) == "number" then
          if (a4 or 0) == 0 then
            pcall(TP.ghosts, set, ty, TP.LEADER_SLOT)
          else
            TP.unghost(TP.LEADER_SLOT)
          end
        end
        return table.unpack(r, 1, r.n)
      end
    end)

    TP.wrap(stem, "UpdateMemberCharaBlankSlot", function(orig)
      return function(a1, a2, a3, ...)
        local r = table.pack(orig(a1, a2, a3, ...))
        local slot = a3 and TP.LEADER_SLOT or (a1 or 0)
        if TP.ghost[slot] ~= nil then
          VRFW.host.menu_command(TP.C.LAYER_VISIBLE, a3 and TP.BLANK_LEADER or TP.BLANK, a3 and 0 or slot, false)
        end
        local held = TP.hold
        if held ~= nil and not a3 and a2 == true and held.slot == slot and squad() == held.set then
          TP.mark_held_slot(slot)
        end
        return table.unpack(r, 1, r.n)
      end
    end)
  end

  -- the host's retail locals of the stem (nil without VRFW.debug)
  function TP.locals(stem)
    local H = VRFW.host
    local h = type(H) == "table" and type(H.hosts) == "table" and H.hosts[stem] or nil
    return h ~= nil and h.L or nil
  end

  function TP.local_value(stem, k)
    local L = TP.locals(stem)
    if L == nil then
      return nil
    end
    local ok, v = pcall(function()
      return L[k]
    end)
    return ok and v or nil
  end

  function TP.set_local(stem, k, v)
    local L = TP.locals(stem)
    if L == nil then
      return false
    end
    return (pcall(function()
      L[k] = v
    end))
  end

  -- Retail locals of the squad on screen.
  TP.VIEWED = {
    soccer_team_dock_menu = {set = "n5", ty = "n10"},
    team_dock_formation_menu = {set = "n", ty = "n10"},
    chara_bank_menu = {set = "n5"},
  }

  -- Returns the squad the player is looking at on `stem`.
  function TP.viewed_squad(stem)
    local v = TP.VIEWED[stem]
    if v == nil then
      return nil, 0
    end
    return TP.local_value(stem, v.set), (v.ty ~= nil and TP.local_value(stem, v.ty)) or 0
  end
