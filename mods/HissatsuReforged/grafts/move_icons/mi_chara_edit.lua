-- EVT move icons
HissatsuReforged = HissatsuReforged or {}
HissatsuReforged.move_icons_chara_edit = HissatsuReforged.move_icons_chara_edit or {}
if HissatsuReforged.move_icons_chara_edit.update_skill_info == nil then
  HissatsuReforged.move_icons_chara_edit.update_skill_info = UpdateSkillInfo
end
if HissatsuReforged.move_icons_chara_edit.update_skill_info ~= nil then
  function UpdateSkillInfo(a1, a2, ...)
    local r = table.pack(HissatsuReforged.move_icons_chara_edit.update_skill_info(a1, a2, ...))
    if HissatsuReforged.move_icons_row ~= nil and type(a1) == "number" and a1 ~= 0 then
      pcall(HissatsuReforged.move_icons_row, 1580043721 --[[soccer11_09_formation_chara_skill]], a2 or 0, a1, 0)
    end
    return table.unpack(r, 1, r.n)
  end
end
