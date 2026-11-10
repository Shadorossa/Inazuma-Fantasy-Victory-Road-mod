-- Player page block (plate_pages.lua)

  -- Draws the chart for a host without pages.
  function G.host_chart()
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
    if G.keep_radar() then
      return                                -- a host panel draws on the retail radar: left to it
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

  -- A host whose panels draw on the retail radar answers G.H.keep_radar() = true.
  function G.keep_radar()
    if G.H.pages or type(G.H.keep_radar) ~= "function" then
      return false
    end
    local ok, keep = pcall(G.H.keep_radar)
    return ok and keep == true
  end

  -- Shows values for a host panel that previews another build of the player (the skill table's set preview, graft pset_preview).
  function G.show_values(vals, hdl)
    G.override = vals
    G.overrideDrawn = false
    G.vals = vals
    if vals ~= nil and hdl ~= nil and type(UpdateCharaParameterGraphByCharaStHdl) == "function" then
      pcall(UpdateCharaParameterGraphByCharaStHdl, G.RADAR, G.RETAIL_NUM or G.NUM, hdl, G.RETAIL_GRAPH or G.GRAPH)
    end
  end

  function G.override_numbers()
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

  G.HOST_CHART = true
  function G.host_numbers()
    if G.HOST_CHART then
      pcall(G.host_chart)
    end
    pcall(G.override_numbers)
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
