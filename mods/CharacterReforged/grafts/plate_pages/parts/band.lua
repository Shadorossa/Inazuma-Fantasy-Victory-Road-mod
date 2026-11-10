-- Player page block (plate_pages.lua)
  local function BandSetup()
    Cmd(C.MESH, G.BAND, G.M_PAGE, false, 0)  -- no page body
    Cmd(C.MESH, G.BAND, G.M_PORTRAIT, false, 0)
    for _, m in ipairs(G.M_PARAM) do
      Cmd(C.MESH, G.BAND, m, false, 0)
    end
    Cmd(C.MESH, G.BAND, G.M_BAND, false, 0)  -- the band is cr_pp_slant's
  end

  function G.band()
    if not Exists(G.BAND) or not Exists(G.PAGE) then
      return
    end
    local up = Cmd(C.IS_VIS, G.PAGE, 0) == true and Cmd(C.IS_OPEN, G.PAGE, 0) == true
    if not up then
      if Cmd(C.IS_OPEN, G.BAND, 0) == true then
        Cmd(C.VIS, G.BAND, 0, false)
      end
      return
    end
    -- The retail page body _personal_plate01 is hidden every frame.
    if CharacterReforged.PLAYER_PAGE_PAGE_BODY ~= true then
      Cmd(C.MESH, G.PAGE, G.M_PAGE, false, 0)
    end
    if not Ready(G.BAND, 0) then
      return
    end
    if not G.ready[G.BAND * 16] then
      G.ready[G.BAND * 16] = true
      G.bandkey = nil
      Cmd(C.TRACE, G.PAGE, 0, G.BAND, true)
      BandSetup()
    end
    -- Reads a host's own card rect (G.H.card = {x0, y0, x1, y1}, screen, y down).
    local cr = G.H.card
    if type(cr) == "table" then
      Cmd(C.NODE_POS, G.BAND, 0, G.M_PAGE, 0, cr[1] - 1435)
      Cmd(C.NODE_POS, G.BAND, 0, G.M_PAGE, 1, 560 - cr[2])
      Cmd(C.NODE_SCALE, G.BAND, 0, G.M_PAGE, cr[3] - cr[1], cr[4] - cr[2])
    end
    local desc = On() and G.ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE
    -- the body only as the content band of the page (its own height), on the pages that use it
    local b = On() and G.ptype ~= nil and G.BAND_ON[G.ptype] == true and not G.in_office()
    if G.bandkey ~= 1 then
      G.bandkey = 1
      Cmd(C.SPRITE, G.BAND, G.TX_T1101, G.SP_BAND, G.SP_BODY, 0, 0)
    end
    Cmd(C.MESH, G.BAND, G.M_PAGE, b, 0)
    Cmd(C.MESH, G.BAND, G.M_FLAVOR, desc or not On(), 0)
    Cmd(C.VIS, G.BAND, 0, true)
    -- the retail portrait frame _icon_chr_status_base01 is hidden every frame (the row shows no miniface)
    Cmd(C.MESH, G.PAGE, G.M_PORTRAIT, false, 0)
    if Exists(G.PLATE) and Cmd(C.IS_OPEN, G.PLATE, 0) == true then
      Cmd(C.MESH, G.PLATE, G.M_PORTRAIT, false, 0)
    end
    -- the page's own band / box (not drawn in the drawType-1 pass anyway) and its radar plates stay off
    Cmd(C.MESH, G.PAGE, G.M_BAND, false, 0)
    Cmd(C.MESH, G.PAGE, G.M_FLAVOR, false, 0)
    for _, m in ipairs(G.M_PARAM) do
      Cmd(C.MESH, G.PAGE, m, false, 0)
    end
  end

  local function SlantRarityOff(inst)
    inst = inst or 0
    Cmd(C.MESH, G.SLANT, G.SLANT_RARITY, false, inst)
    Cmd(C.NODE_VIS, G.SLANT, G.SLANT_RARITY_NODE, false, inst)
    Cmd(C.NODE_SCALE, G.SLANT, inst, G.SLANT_RARITY, G.HIDDEN_SCALE, G.HIDDEN_SCALE)
  end

  -- Runs when an instance of the slant copy opens or reopens.
  function G.slant_opened(inst)
    SlantRarityOff(inst)
    Cmd(C.VIS, G.SLANT, inst or 0, false)
    G.ready[G.SLANT * 16] = nil
  end

  local function SlantHide()
    VRFW.ui_plates.header_row.band(G.SLANT, 0, {band = true})
    SlantRarityOff()
    VRFW.ui_plates.header_row.portrait_off(G.PLATE, 0)
    -- the host's extra header nodes (G.H.plate_off) off screen too
    for _, nd in ipairs(G.H.plate_off or {}) do
      Cmd(C.NODE_POS, G.PLATE, 0, nd, 0, -5000)
    end
  end

  -- the player of the header plate on the slant copy (its rarity / position colours come with it)
  function G.slant_fill()
    if G.hdl == nil or not Exists(G.SLANT) or Cmd(C.IS_OPEN, G.SLANT, 0) ~= true
        or type(UpdateCharaStatusPlateInfoByCharaStHdl) ~= "function" or type(VRFW.ui_plates) ~= "table" then
      return
    end
    local header = type(CharacterReforged) == "table" and CharacterReforged.header or nil
    local colour = type(header) == "table" and header.band_colour or function() end
    G.busy = true
    VRFW.ui_plates.header_row.band_fill(G.SLANT, 0, G.hdl, {colour = colour})
    G.busy = false
    SlantHide()
  end

  function G.slant()
    if not Exists(G.SLANT) or not Exists(G.PAGE) or type(VRFW.ui_plates) ~= "table" then
      return
    end
    local up = Cmd(C.IS_VIS, G.PAGE, 0) == true and Cmd(C.IS_OPEN, G.PAGE, 0) == true
    if not up then
      if Cmd(C.IS_OPEN, G.SLANT, 0) == true then
        Cmd(C.VIS, G.SLANT, 0, false)
      end
      return
    end
    if not Ready(G.SLANT, 0) then
      return
    end
    if not G.ready[G.SLANT * 16] then
      G.ready[G.SLANT * 16] = true
      Cmd(C.TRACE, G.PAGE, 0, G.SLANT, true)
      VRFW.ui_plates.header_row.place_band(G.SLANT, 0)               -- under the row at its layout place (scale 1)
      G.slant_fill()
      SlantHide()
    end
    SlantRarityOff()
    if G.hdl ~= nil then                     -- shown once it holds a player (never its retail default)
      Cmd(C.VIS, G.SLANT, 0, true)
    end
  end
