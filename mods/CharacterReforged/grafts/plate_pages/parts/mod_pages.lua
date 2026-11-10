-- Player page block (plate_pages.lua)
  G.MOD_PAGE_GEO = {origin = {1495, 880}, center = 1450, top = 704, height = 214}

  -- the declarations that carry `field`
  local function ModPagesWith(field)
    local P = VRFW.player_pages
    local out = {}
    if type(P) ~= "table" or type(P.resolve) ~= "function" then
      return out
    end
    for _, d in ipairs(P.resolve()) do
      if type(d[field]) == "function" then
        out[#out + 1] = d
      end
    end
    return out
  end

  function G.mod_pages()
    local plate = On()
    for _, d in ipairs(ModPagesWith("plate_step")) do
      d.plate_step(plate and G.ptype == d.type, G.MOD_PAGE_GEO)
    end
  end

  function G.player_refresh(hdl)
    G.pcardHdl = nil                     -- the own passive card (parts/passives.lua) reads its player again
    G.pcardFilled = false
    for _, d in ipairs(ModPagesWith("player_change")) do
      pcall(d.player_change, hdl)
    end
  end

  function G.mod_pages_hide()
    for _, d in ipairs(ModPagesWith("hide")) do
      pcall(d.hide)
    end
  end
