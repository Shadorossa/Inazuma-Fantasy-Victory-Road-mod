-- Board entry points
PL.KEY_READONLY = 156152477
PL.readonly = false
PL.RO_GUIDE = 651715743 --[[skill_table_readonly_guide]]

PL.prev_init = OnInit
function OnInit()
  if VRFW.param.has(PL.KEY_READONLY) then
    local v = VRFW.param.get(PL.KEY_READONLY)
    PL.readonly = v == true or v == 1
    VRFW.param.clear(PL.KEY_READONLY)
  end
  PL.prev_init()
end

function PL.refuse()
  funcLuaCommand(C.SE, SE_NG)
  funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]], PL.txt(PL.RO_GUIDE), 0)
end

PL.ro_prev_decide = OnDecideFocus
function OnDecideFocus(a1, a2)
  if PL.readonly then
    PL.refuse()
    return
  end
  PL.ro_prev_decide(a1, a2)
end

PL.ro_prev_function = OnFunction
function OnFunction(a1, a2)
  if PL.readonly and (a1 == 4109882573 --[[CMD_FUNC3 Eliminar]] or a1 == 1141890006 --[[CMD_FUNC4 Restablecer]]) then
    PL.refuse()
    return
  end
  PL.ro_prev_function(a1, a2)
end

PL.ro_prev_item_info = UpdateEquipItemInfo
function UpdateEquipItemInfo()
  PL.ro_prev_item_info()
  if PL.readonly then
    VRFW.footer_prompts.set(nil, n12, {}, {guide = 1138543975 --[[mainmenu01_06_base_button_guide]], declared = false})
    funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]], PL.txt(PL.RO_GUIDE), 0)
  end
end
