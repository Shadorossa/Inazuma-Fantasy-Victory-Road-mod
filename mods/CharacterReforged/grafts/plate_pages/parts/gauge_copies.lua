-- Player page block (plate_pages.lua)
  function G.gauge_copy_count(layer)
    if G.gaugeCopyCounts == nil then
      -- the Trayectoria bands' layer stays in the page objects (its page is a declared mod page)
      G.CSB = G.CSB or @crc:cr_pp_csband@
      G.gaugeCopyCounts = {[G.TAG] = 1, [G.PT] = 5, [G.PTRULE] = 1, [G.SXBAR] = 1, [G.SXPLATE] = 1, [G.CSB] = 2,
        [G.FBADGE] = 3}
    end
    return G.gaugeCopyCounts[layer]
  end
  function G.is_gauge_copy_placed(layer, instance)
    if layer == G.PT and instance == 0 and G.emptyOn then
      return true
    end
    return G.ready[layer * 16 + instance] == true
  end
  function G.hide_unplaced_gauge_copies()
    G.gauge_copy_count(G.TAG)
    for layer, count in pairs(G.gaugeCopyCounts) do
      if Exists(layer) then
        for instance = 0, count - 1 do
          if not G.is_gauge_copy_placed(layer, instance) and Cmd(C.IS_OPEN, layer, instance) == true then
            Cmd(C.VIS, layer, instance, false)
          end
        end
      end
    end
  end
  function G.forget_gauge_copy(layer, instance)
    if type(instance) ~= "number" or G.gauge_copy_count(layer) == nil then
      return
    end
    G.ready[layer * 16 + instance] = false
    if layer == G.PT and instance == 0 then
      G.emptyOn = false
    elseif layer == G.FBADGE then
      G.fbKey = nil
    end
    Cmd(C.VIS, layer, instance, false)
  end
