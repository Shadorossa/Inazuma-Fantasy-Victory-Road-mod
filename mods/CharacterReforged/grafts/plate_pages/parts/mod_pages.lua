-- Player page block (plate_pages.lua): the pages other mods declare to the VR-Framework's player page registry
-- (VRFW_PlayerPages.Add, docs/framework/player-pages.md) and draw themselves. A declaration may carry
--   PlateStep(on, geo)  every frame of the paged plate: on = its page is the current page; geo = the page body's
--                       geometry {origin = the status base's _atc_passive01 on screen, center = page centre x,
--                       top = page top y, height = page body height}
--   Hide()              the plate shows no player (an empty slot)
--   PageChange(...)     the page change, under this block's wrappers (plate_pages.lua head)
--   PlayerChange(hdl)   the plate's player was refreshed (G.PlayerRefresh): drop what the page keeps of its player
  G.MOD_PAGE_GEO = {origin = {1495, 880}, center = 1450, top = 704, height = 214}

  -- the declarations that carry `field`
  local function ModPagesWith(field)
    local P = VRFW_PlayerPages
    local out = {}
    if type(P) ~= "table" or type(P.Resolve) ~= "function" then
      return out
    end
    for _, d in ipairs(P.Resolve()) do
      if type(d[field]) == "function" then
        out[#out + 1] = d
      end
    end
    return out
  end

  function G.ModPages()
    local plate = On()
    for _, d in ipairs(ModPagesWith("PlateStep")) do
      d.PlateStep(plate and G.ptype == d.Type, G.MOD_PAGE_GEO)
    end
  end

  -- the one refresh of every page's per-player state, on each retail refresh of the header plate (the player change
  -- of the album cursor, L1 / R1 and the screens' cursor). A handle alone does not name a player: the album's
  -- players-universe card is removed and added again per row and can get the same handle back.
  function G.PlayerRefresh(hdl)
    G.pcardHdl = nil                     -- the own passive card (parts/passives.lua) reads its player again
    G.pcardFilled = false
    for _, d in ipairs(ModPagesWith("PlayerChange")) do
      pcall(d.PlayerChange, hdl)
    end
  end

  function G.ModPagesHide()
    for _, d in ipairs(ModPagesWith("Hide")) do
      pcall(d.Hide)
    end
  end
