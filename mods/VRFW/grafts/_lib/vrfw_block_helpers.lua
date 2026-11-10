-- Helpers shared by graft patch files; parts taken with --@lib.
--@section WrapAfter
--- Wraps global `name` once for `owner`: runs `after` with the same arguments after the previous function.
local function WrapAfter(owner, name, after, on_error)
  VRFW.host.wrap_once(name, owner, function(previous, ...)
    local results = table.pack(previous(...))
    local ok, err = pcall(after, ...)
    if not ok and on_error ~= nil then
      on_error(err)
    end
    return table.unpack(results, 1, results.n)
  end)
end
--@section DropAuraArt
--- The character an aura item's art shows: its own (info 17), or the one of its partner card (info 19).
local function DropAuraChara(item)
  local has_chara, chara = VRFW.host.command(@crc:CMND_GET_SOCCER_SKILL_INFO@, item, 17)
  if has_chara and type(chara) == "number" and chara ~= 0 then
    return chara
  end
  local has_card, card = VRFW.host.command(@crc:CMND_GET_SOCCER_SKILL_INFO@, item, 19)
  if has_card and type(card) == "number" and card ~= 0 then
    local partner = VRFW.host.command(347353059, card)
    if type(partner) == "number" then
      return partner
    end
  end
  return 0
end

--- Draws the aura's portrait on (mesh, slot) as the game's aura windows do; `screen` holds ART_SIZE and FACE.
local function DropAuraPortrait(screen, layer, instance, mesh, slot, chara, kind)
  local art = screen.ART_SIZE[kind] or 8
  if art == 12 and VRFW.host.menu_command(2208175668 --[[has Mix-Max face art]], chara) ~= true then
    art = nil
  end
  if art ~= nil then
    local ok, drawn = pcall(funcLuaMenuCommand, screen.FACE, layer, instance, mesh, slot, chara, 0, art, true, true, true, 5)
    if ok and drawn ~= false then
      return true
    end
    VRFW.host.menu_command(4176779611 --[[ResetFaceIcon]], layer, instance, slot)
  end
  return VRFW.face_icon.request(layer, instance, chara, mesh, slot)
end
