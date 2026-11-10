BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.archetype_header = type(BetterQoL.archetype_header) == "table" and BetterQoL.archetype_header or {}
do
  local AH = BetterQoL.archetype_header
  AH.INFO = 3569354349 --[[CMND_BETTERQOL_PC_INFO (hdl) -> ok, mode, archetype 1, archetype 2, max slots, inactive]]
  AH.ICON_TEXTURE = 2320109963 --[[#/menu/200_icon/15_icon_common/icon_common.g4tx]]
  AH.SECOND_MESH = 1670039012 --[[_icon_lock_status01]]
  AH.SECOND_SLOT = 3276571178 --[[icon_lock_status01 (the quad's texture slot)]]
  AH.SWAP_SPRITE = 558735651 --[[the menu sprite swap (layer, texture, sprite, texture slot, 0, inst)]]
  AH.MESH_VISIBLE = 3405944500 --[[CMND_SET_MESH_VISIBLE (layer, mesh, on, inst)]]
  AH.NO_ARCHETYPE = 6
  AH.MAX_ARCHETYPE = 63

  local function is_archetype(n)
    return type(n) == "number" and n >= 0 and n <= AH.MAX_ARCHETYPE and n ~= AH.NO_ARCHETYPE
  end

  -- (first, second) of a double archetype, or nil
  function AH.double(hdl)
    if type(hdl) ~= "number" or hdl == 0 then
      return nil
    end
    local got, _, a, b = VRFW.host.command(AH.INFO, hdl)
    if got ~= true or not is_archetype(a) or not is_archetype(b) or a == b then
      return nil
    end
    return a, b
  end

  function AH.draw_second(layer, inst, hdl)
    local shown = rawget(_ENV, "GetBuildTypeIconTextureNameByCharaStHdl")
    if type(shown) == "function" then
      local ok, tex = pcall(shown, hdl)
      if ok and tex == 0 then
        return false -- the header shows no archetype at all (a coach, a manager...)
      end
    end
    local _, b = AH.double(hdl)
    local icon_of = rawget(_ENV, "GeTeamBuffBuildTypeIconTextureName")
    if b == nil or type(icon_of) ~= "function" then
      return false
    end
    local ok, sprite = pcall(icon_of, b)
    if not ok or type(sprite) ~= "number" or sprite == 0 then
      return false
    end
    VRFW.host.menu_command(AH.SWAP_SPRITE, layer, AH.ICON_TEXTURE, sprite, AH.SECOND_SLOT, 0, inst or 0)
    VRFW.host.menu_command(AH.MESH_VISIBLE, layer, AH.SECOND_MESH, true, inst or 0)
    return true
  end

  function AH.piece(phase, ctx)
    if phase == "fill" and type(ctx) == "table" then
      AH.draw_second(ctx.layer, ctx.inst, ctx.hdl)
    end
    return 0
  end
end
