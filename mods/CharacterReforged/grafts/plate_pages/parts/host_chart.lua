-- Player page block (plate_pages.lua): the stat chart and numbers on the hosts without pages
  -- round 11b: the dock lineup behind a bank's plate is hidden by the dock menus themselves (plate_dock_hide.lua);
  -- round 11's menu command 1558704558 here was MENU_ACTIVE (input), not visibility, and broke the dock

  -- a host without pages: the 8th value (Suerte, CMND_EVT_CHARA_STAT 8) on number instance 7 (the retail graph
  -- writes 7; plate_hiper's EVT_R9 writes all 8 only in personal_plate_menu)
  -- 2026-10-06 (hosts: added layers only) the chart = our layers placed on the card (G.CHART_AT), the retail radar
  -- pieces off; (Nacho: the skill table's card shows only the selected technique's plate) G.H.chart = false = no
  -- chart on that host: our chart layers are never opened there (only hidden if open), the bars follow
  function G.HostChart()
    local x, y = G.CHART_AT[1], -G.CHART_AT[2]
    if G.H.chart == false and G.override == nil then
      for _, l in ipairs({G.GRAPH, G.EXTRA, G.NUM}) do
        if Exists(l) then
          for k = 0, 7 do
            if Cmd(C.IS_OPEN, l, k) == true then
              Cmd(C.VIS, l, k, false)
            end
          end
        end
      end
    else
      local up = G.vals ~= nil
      for _, l in ipairs({G.GRAPH, G.EXTRA}) do
        if Exists(l) and Ready(l, 0) then
          Cmd(C.POS, l, x, y, 0, 0)
          Cmd(C.VIS, l, 0, up)
        end
      end
      if Exists(G.NUM) then
        for k = 0, 7 do
          if Ready(G.NUM, k) then
            Cmd(C.VIS, G.NUM, k, up)
          end
        end
      end
    end
    if G.KeepRadar() then
      return                                -- a panel of the host draws on the retail radar now: left to it
    end
    for _, l in ipairs({G.RETAIL_GRAPH, G.RETAIL_NUM, G.RADAR}) do        -- the retail radar pieces off
      if Exists(l) then
        for k = 0, 7 do
          if Cmd(C.IS_OPEN, l, k) == true then
            Cmd(C.VIS, l, k, false)
          end
        end
      end
    end
  end

  -- 2026-10-14: a host whose own panels draw on the retail radar (the skill table's set preview and training view)
  -- answers G.H.keep_radar() = true while they show it; the page then leaves the radar (and its polygon) alone
  function G.KeepRadar()
    if G.H.pages or type(G.H.keep_radar) ~= "function" then
      return false
    end
    local ok, keep = pcall(G.H.keep_radar)
    return ok and keep == true
  end

  -- a host panel that previews another build of the player (the skill table's set preview, graft pset_preview): the
  -- chart shows `vals` (8 values in the chart's group order, G.Values) on the card, also where the host has no chart;
  -- nil = the player's own values again. The retail fill (labels, position tags) runs once for the player `hdl`
  function G.ShowValues(vals, hdl)
    G.override = vals
    G.overrideDrawn = false
    G.vals = vals
    if vals ~= nil and hdl ~= nil and type(UpdateCharaParameterGraphByCharaStHdl) == "function" then
      pcall(UpdateCharaParameterGraphByCharaStHdl, G.RADAR, G.RETAIL_NUM or G.NUM, hdl, G.RETAIL_GRAPH or G.GRAPH)
    end
  end

  -- the shown build's 8 numbers over the fill's (once per fill; the number instance of group g is g - 1)
  function G.OverrideNumbers()
    if G.override == nil or G.overrideDrawn or not Exists(G.NUM) then
      return
    end
    local style = 2612831244
    for k = 0, 7 do
      if Cmd(C.IS_OPEN, G.NUM, k) ~= true then
        return
      end
    end
    for k = 0, 7 do
      local prim = Cmd(@crc:CMND_SEARCH_PRIM_INDEX@, G.NUM, k, style)
      Cmd(3609943765, G.NUM, k, prim, G.override[k + 1] or 0)
      Cmd(1233047821, G.NUM, k, style, true)
    end
    G.overrideDrawn = true
  end

  G.HOST_CHART = true                    -- the chart on the hosts' card (attach rows in player_page_layout.toml)
  function G.HostNumbers()
    if G.HOST_CHART then
      pcall(G.HostChart)
    end
    pcall(G.OverrideNumbers)
    if G.vals == nil or not Exists(G.NUM) or Cmd(C.IS_OPEN, G.NUM, 7) ~= true then
      return
    end
    local style = 2612831244
    local prim = Cmd(@crc:CMND_SEARCH_PRIM_INDEX@, G.NUM, 7, style)
    Cmd(3609943765, G.NUM, 7, prim, G.rowShown ~= nil and G.rowShown[8] or G.vals[8] or 0)
    Cmd(1233047821, G.NUM, 7, style, true)
    if Exists(G.EXTRA) and Cmd(C.IS_OPEN, G.EXTRA, 0) == true then
      Cmd(C.VIS, G.EXTRA, 0, Cmd(C.IS_VIS, G.GRAPH, 0) == true)
    end
  end
