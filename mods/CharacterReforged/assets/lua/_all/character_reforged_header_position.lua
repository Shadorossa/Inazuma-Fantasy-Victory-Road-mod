CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.header_position == nil and type(rawget(_ENV, "UpdateCharaStatusPlateInfoByCharaStHdl")) == "function" then
  local P = {
    -- soccer11_04_formation_chara_status, soccer11_04_chara_status (the header plates)
    LAYERS = {[1844915256] = true, [607716004] = true},
    wrapped = false,
  }
  CharacterReforged.header_position = P

  function P.after_fill(layer, inst, hdl)
    if not P.LAYERS[layer] then
      return
    end
    local rows = type(VRFW.ui_plates) == "table" and VRFW.ui_plates.header_row or nil
    if rows == nil then
      return
    end
    local staff, icon = rows.natural(hdl)
    if staff == false and icon ~= nil then
      rows.badge(layer, inst or 0, icon)
    end
  end

  function CharacterReforged.enable_header_position()
    if P.wrapped then
      return
    end
    P.wrapped = true
    P.previousFill = UpdateCharaStatusPlateInfoByCharaStHdl
    function UpdateCharaStatusPlateInfoByCharaStHdl(layer, inst, hdl, ...)
      local result = table.pack(P.previousFill(layer, inst, hdl, ...))
      pcall(P.after_fill, layer, inst, hdl)
      return table.unpack(result, 1, result.n)
    end
  end

  if CharacterReforged.header_position_wanted then
    CharacterReforged.enable_header_position()
  end
end
