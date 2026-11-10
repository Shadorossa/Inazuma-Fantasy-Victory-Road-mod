-- The formation screen is two VMs
FootballReforged = FootballReforged or {}
@BONUS5@
do
  local PF = {
    KEY = FootballReforged.friendly_formation_key,
    KEY11 = FootballReforged.friendly_formation_key11,            -- set by the dock in Partido: football_reforged_pachanga_formation11_menu / football_reforged_pf11_group
    UPVAL = @crc:CMND_FOOTBALLREFORGED_FRIENDLIES_UPVAL@,
    SELECT = 2438617231,
    NO5 = {[3966159602] = true,      -- soccer11_40_synergy_attachment_button_pillar (castle)
           [212184996] = true},      -- soccer11_40_synergy_attachment_button_flag (flag)
    on = false, dock = nil, opens = 0,
  }
  FootballReforged.friendly_formation = PF

  function PF.log(...)
    PF.logger = PF.logger or VRFW.logger.new("EVT pachanga formation")
    PF.logger(...)
  end
  function PF.hide()
    for L in pairs(PF.NO5) do
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, L, 0, false)
      VRFW.host.menu_command(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, L, false)
    end
  end
  function PF.guard()
    if type(VRFW.host) ~= "table" or type(VRFW.host.hook_command) ~= "function" then
      return
    end
    local menu = {menu = true}
    VRFW.host.hook_command(@crc:CMND_SET_LAYER_VISIBLE@, function(nxt, id, layer, index, visible, ...)
      if PF.on and PF.NO5[layer] and visible then
        return nxt(id, layer, index, false, ...)
      end
      return nxt(id, layer, index, visible, ...)
    end, "FootballReforged.formation_layer_visible", menu)
    VRFW.host.hook_command(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, function(nxt, id, layer, enabled, ...)
      if PF.on and PF.NO5[layer] and enabled then
        return nxt(id, layer, false, ...)
      end
      return nxt(id, layer, enabled, ...)
    end, "FootballReforged.formation_layer_focus", menu)
    VRFW.host.hook_command({@crc:CMND_UPDATE_SYNERGY_BUTTON@, 3964547760}, function(nxt, id, layer, ...)
      local r = table.pack(nxt(id, layer, ...))
      if PF.on and PF.NO5[layer] then
        PF.hide()
      end
      return table.unpack(r, 1, r.n)
    end, "FootballReforged.formation_synergy_button", menu)
  end
  local function wrapcb(name, make)
    local f = rawget(_ENV, name)
    if type(f) == "function" and not (FootballReforged.friendly_formation_wrapped or {})[f] then
      local w = make(f)
      FootballReforged.friendly_formation_wrapped = FootballReforged.friendly_formation_wrapped or {}
      FootballReforged.friendly_formation_wrapped[w] = true
      rawset(_ENV, name, w)
    end
  end
  wrapcb("OnOpenLayer", function(orig)
    return function(a1, ...)
      local r = table.pack(orig(a1, ...))
      if PF.on and PF.NO5[a1] then
        PF.hide()
      end
      return table.unpack(r, 1, r.n)
    end
  end)
  -- The formation picker (native MenuListViewSoccerFormation in win05_01).
  PF.LIST, PF.ITEM, PF.COUNT = 3873858080, 1027507646, 5
  function PF.rows()
    local list = rawget(_ENV, "BetterQoL_FormationList5")
    if type(list) == "table" and #list >= PF.COUNT then
      return #list
    end
    return PF.COUNT
  end
  wrapcb("OnOpenGeneralSubListLayer", function(orig)
    return function(...)
      local r = table.pack(orig(...))
      if PF.on then
        local rows = PF.rows()
        VRFW.host.menu_command(3252599449, PF.LIST, rows)
        VRFW.host.menu_command(3252599449, PF.ITEM, rows, rows)
        PF.log("picker rows", rows)
      end
      return table.unpack(r, 1, r.n)
    end
  end)
  for _, cb in ipairs({"OnDecideFocus", "OnEnter"}) do
    wrapcb(cb, function(orig)
      return function(a1, ...)
        if PF.on and PF.NO5[a1] then
          VRFW.host.command(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
          return
        end
        return orig(a1, ...)
      end
    end)
  end
  wrapcb("OpenAndWaitTeamSkillParameterMenu", function(orig)
    return function(...)
      if PF.on and type(PF.dock) == "number" then
        return select(2, FootballReforged.bonus5(PF.dock, "formation", orig, ...))
      end
      return orig(...)
    end
  end)
  local init = rawget(_ENV, "OnInit")
  if type(init) == "function" and not (FootballReforged.friendly_formation_wrapped or {})[init] then
    local w = function(...)
      local dock, dock11, sel = nil, nil, false
      PF.on, PF.dock = false, nil
      PF.opens = PF.opens + 1
      pcall(function()
        if VRFW.param.has(PF.KEY) then
          dock = VRFW.param.get(PF.KEY)
          VRFW.param.clear(PF.KEY)
        end
        if type(PF.KEY11) == "number" and VRFW.param.has(PF.KEY11) then
          dock11 = VRFW.param.get(PF.KEY11)
          VRFW.param.clear(PF.KEY11)
        end
        sel = VRFW.param.has(PF.SELECT)
      end)
      local r = table.pack(init(...))
      if type(dock) == "number" and funcLuaCommand(@crc:CMND_GET_PLAY_GAME_MODE@) ~= 2
          and type(OnInitFormationCommon) == "function" then
        local got, fid = VRFW.host.command(@crc:CMND_GET_TEAM_SET_INFO@, dock, 1, 4)
        local e = select(2, pcall(OnInitFormationCommon, got and fid or nil, nil, dock,
          (FootballReforged.friendly_formation_select and sel) or nil, nil, true, true))
        PF.log("5v5 list", "dock", dock,
          "formation", tostring(fid), "select", tostring(sel), tostring(e))
        PF.on, PF.dock = true, dock
        PF.guard()
        PF.hide()
      elseif type(dock11) == "number" and PF.opens > 1 and type(OnInitFormationCommon) == "function" then
        local got, fid = VRFW.host.command(@crc:CMND_GET_TEAM_SET_INFO@, dock11, 0, 4)
        local u = -1
        if type(UpdateFormationReducedDrawingIconPos) == "function" then
          local n = VRFW.host.command(PF.UPVAL, UpdateFormationReducedDrawingIconPos, 5, 11, 40, 94)
          u = n or -1
        end
        if type(SetFormationLayer) == "function" then
          pcall(SetFormationLayer, 3321884270 --[[soccer11_02_formation_frame]])
        end
        local e = select(2, pcall(OnInitFormationCommon, got and fid or nil, nil, dock11,
          (FootballReforged.friendly_formation_select and sel) or nil, nil, true, false))
        PF.log("11v11 state", "dock", dock11,
          "formation", tostring(fid), "upvalues", tostring(u), "open", PF.opens, tostring(e))
      end
      return table.unpack(r, 1, r.n)
    end
    FootballReforged.friendly_formation_wrapped = FootballReforged.friendly_formation_wrapped or {}
    FootballReforged.friendly_formation_wrapped[w] = true
    rawset(_ENV, "OnInit", w)
  end
end
