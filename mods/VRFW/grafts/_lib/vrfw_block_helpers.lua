-- Helpers shared by graft patch files; parts taken with --@lib.
--@section Wrap --- Advanced: 
--- Wraps global `name` once for `owner` with `parts`: `before` and `after` run in a pcall with the same arguments, `around(previous, ...)` makes the call; answers true, or false, why.
local function Wrap(owner, name, parts)
  local function failed(phase, err)
    if parts.on_error ~= nil then
      parts.on_error(err, phase)
    else
      VRFW.host.note(owner, name .. " " .. phase .. " error: " .. tostring(err))
    end
  end
  return VRFW.host.wrap_once(name, owner, function(previous, ...)
    if parts.before ~= nil then
      local ok, err = pcall(parts.before, ...)
      if not ok then
        failed("before", err)
      end
    end
    local results
    if parts.around ~= nil then
      results = table.pack(parts.around(previous, ...))
    else
      results = table.pack(previous(...))
    end
    if parts.after ~= nil then
      local ok, err = pcall(parts.after, ...)
      if not ok then
        failed("after", err)
      end
    end
    return table.unpack(results, 1, results.n)
  end)
end
--@section WrapAfter --- Advanced: 
--- Wraps global `name` once for `owner`: runs `after` with the same arguments after the previous function (needs the Wrap section).
local function WrapAfter(owner, name, after, on_error)
  return Wrap(owner, name, { after = after, on_error = on_error })
end
--@section DropAuraArt --- Advanced: 
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
