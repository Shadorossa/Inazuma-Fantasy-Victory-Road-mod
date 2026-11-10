-- ===== EVT ss2_pc_rows BEGIN ===== (research/grafts/ss2_pc_rows, docs/game/mechanics/pasivas-configurables.md §10)
-- The skill table's list picker uses the taller row better_qol_pc_row
do
  CharacterReforged.passive_rows = CharacterReforged.passive_rows or {}

  function CharacterReforged.passive_rows.rows(L)
    local ok, n = pcall(funcLuaMenuCommand, @crc:CMND_GET_CREATE_LAYER_NUM@, L)
    if ok and type(n) == "number" and n >= 1 and PL ~= nil then
      PL.SSROWS = math.min(n, 9)
    end
  end

  -- Draws the icons of custom-passive rows.
  function CharacterReforged.passive_rows.row_icons(L, k, id)
    local real = funcLuaMenuCommand
    local ok, err = pcall(function()
      funcLuaMenuCommand = function(cmd, a, b, c, d, e, f, ...)
        if cmd == 558735651 and a == L and f == k then
          if d == 566439826 then -- icon_sp_area_dmy01: the hexagon, replaced by the backing
            return true
          elseif d == 669321680 then -- icon_sixth_dmy01: the board icon, onto the icon quad
            return real(cmd, a, b, c, 566439826, e, f, ...)
          end
        end
        return real(cmd, a, b, c, d, e, f, ...)
      end
      CharacterReforged.passive_rows.prevRowIcons(L, k, id)
    end)
    funcLuaMenuCommand = real
    local item = id ~= nil and id ~= 0
    BetterQoL.passive_icons.row_backing(L, k, item, false)
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, L, 2384755812, false, k)
    if not ok then
      error(err)
    end
  end

  function CharacterReforged.passive_rows.hook()
    if CharacterReforged.passive_rows.prevRowIcons ~= nil or PL == nil or type(PL.ss_row_icons) ~= "function" then
      return
    end
    CharacterReforged.passive_rows.prevRowIcons = PL.ss_row_icons
    PL.ss_row_icons = CharacterReforged.passive_rows.row_icons
  end
  CharacterReforged.passive_rows.hook()

  if CharacterReforged.passive_rows.prevSetup == nil and type(OnSetupLayer) == "function" then
    CharacterReforged.passive_rows.prevSetup = OnSetupLayer
    function OnSetupLayer(a1, a2, ...)
      if PL ~= nil and a1 == PL.L_SSROW and a2 == 0 then
        CharacterReforged.passive_rows.rows(a1)
      end
      return CharacterReforged.passive_rows.prevSetup(a1, a2, ...)
    end
  end
@ICONS@
  BetterQoL.passive_icons.hook()
end
-- ===== EVT ss2_pc_rows END =====
