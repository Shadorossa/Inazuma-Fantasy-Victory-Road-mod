CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.create_card == nil then
  local Card = {}
  CharacterReforged.create_card = Card
  Card.ITEMS = 2820944175
  Card.ITEM_ALLOWED = 3462128076
  Card.SKILL_INFO = 2580586398             -- (skill, field): 4 name id, 5 description id, 13 aura type
  Card.NAME_TEXT = 720417636
  Card.DESC_TEXT = 4113915188
  Card.AURA_MIXIMAX = 2
  Card.AURA_MODE_CHANGE = 6
  Card.ICON_BY_TYPE = {[2] = 2185069032 --[[icon_sp_area07]], [6] = 1917130140 --[[icon_sp_area11]]}
  Card.ICON_ATLAS = 2320109963             -- icon_common
  Card.MIXIMAX_WINDOW = 3679282495         -- team00_30_aura_mixi_max_detail_info
  Card.ROW_OF = 2827747337
                                           -- check command
  Card.items = nil
  Card.base_ok = {}

  function Card.U32(v)
    return VRFW.ids.unsigned(v)
  end

  function Card.reset()
    Card.items = nil
    Card.base_ok = {}
  end

  function Card.is_create(skill)
    if type(skill) ~= "number" or skill == 0 then
      return false
    end
    if Card.items == nil then
      Card.items = {}
      local ok, answer = pcall(function() return table.pack(funcLuaCommand(Card.ITEMS)) end)
      if ok and type(answer[1]) == "number" then
        for i = 1, answer[1] do
          if type(answer[i + 1]) == "number" then
            Card.items[Card.U32(answer[i + 1])] = true
          end
        end
      end
    end
    return Card.items[Card.U32(skill)] == true
  end

  function Card.create_allowed(skill, hdl)
    if not Card.is_create(skill) or type(hdl) ~= "number" or hdl == 0 then
      return true
    end
    local key = tostring(Card.U32(skill)) .. ":" .. tostring(Card.U32(hdl))
    local known = Card.base_ok[key]
    if known ~= nil then
      return known
    end
    local allowed = true
    local row, _, _, check = VRFW.host.command(Card.ROW_OF, skill)
    if type(row) == "number" and row > 0 then
      if type(check) == "number" and check ~= 0 then
        local code = VRFW.host.command(check, hdl, 0)
        allowed = not (type(code) == "number" and code ~= 0)
        VRFW.host.command(Card.LOG, "create row check", "item", skill, "player", hdl, code or "no answer")
      end
    end
    Card.base_ok[key] = allowed
    return allowed
  end

  Card.LOG = 2743311895                    -- CMND_CHARACTERREFORGED_CREATE_LOG (step, values…)

  function Card.aura_type(skill)
    local ok, t = funcLuaCommand(Card.SKILL_INFO, skill, 13)
    return ok and t or nil
  end

  -- may player `hdl` take aura `skill`?
  function Card.allowed(skill, hdl)
    local _, allowed = Card.rule(skill, hdl)
    return allowed
  end

  -- the framework's rule for `hdl` and aura `skill` -> answered, allowed
  function Card.rule(skill, hdl)
    if type(skill) ~= "number" or skill == 0 or type(hdl) ~= "number" or hdl == 0 then
      return false, true
    end
    local restricted, allowed = VRFW.host.command(Card.ITEM_ALLOWED, skill, hdl)
    if type(restricted) ~= "boolean" then
      return false, true
    end
    return true, not (restricted and allowed == false)
  end

  function Card.name(skill)
    local ok, id = funcLuaCommand(Card.SKILL_INFO, skill, 4)
    if ok and id ~= nil then
      local s = funcLuaCommand(Card.NAME_TEXT, id)
      if type(s) == "string" then
        return s
      end
    end
    return ""
  end

  function Card.desc(skill)
    local ok, id = funcLuaCommand(Card.SKILL_INFO, skill, 5)
    if ok and id ~= nil then
      local s = VRFW.host.command(Card.DESC_TEXT, id)
      if type(s) == "string" then
        return s
      end
    end
    return ""
  end

  function Card.row(L, inst, skill)
    local name = Card.name(skill)
    if name ~= "" then
      funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, L, 931545948 --[[`_text_list01_on`]], name, inst)
      funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, L, 3705682548 --[[_text_list01_off]], name, inst)
    end
    for _, m in ipairs({1255155594 --[[_icon_cmd_type_dmy01]], 2172872396 --[[_icon_cmd_type_base01]],
        559600405 --[[_icon_sp_sub_dmy01]], 1228576956 --[[_base_have01]], 1202991162 --[[_base_equip01]],
        2037408502 --[[_icon_have01]], 1139638886 --[[_gtxt_equip01]]}) do
      funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, L, m, false, inst)
    end
    funcLuaMenuCommand(2158717427, L, 442049775 --[[_pos_equip01]], false, inst)
    funcLuaMenuCommand(2158717427, L, 3426045766 --[[_pos_have01]], false, inst)
    funcLuaMenuCommand(1233047821 --[[number visible]], L, inst, 3334923667 --[[num_have01]], false)
    funcLuaMenuCommand(1233047821 --[[number visible]], L, inst, 3974820126 --[[num_equip01]], false)
    local icon = Card.ICON_BY_TYPE[Card.aura_type(skill) or -1]
    if icon ~= nil then
      funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, L, 2164615260 --[[_icon_sp_area_dmy01]], true, inst)
      funcLuaMenuCommand(558735651, L, Card.ICON_ATLAS, icon, 566439826 --[[icon_sp_area_dmy01]], 0, inst)
    else
      funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, L, 2164615260, false, inst)
    end
  end

  function Card.detail(skill)
    if not Card.is_create(skill) or Card.aura_type(skill) ~= Card.AURA_MIXIMAX then
      return false
    end
    local A = Card.MIXIMAX_WINDOW
    if not funcLuaMenuCommand(VRFW.commands.IS_EXIST_LAYER, A) then
      return false
    end
    for _, p in ipairs({3407216458 --[[_pos_page01]], 1377611504 --[[_pos_page02]], 3145665477 --[[_pos_page04]],
        3430431571 --[[_pos_page05]], 1307475940 --[[_pos_list01]], 3571920478 --[[_pos_list02]]}) do
      funcLuaMenuCommand(2158717427, A, p, false, 0)
    end
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, 1921826160 --[[team00_40_change_page_guide]], 0, false)
    for _, x in ipairs({1179414078 --[[_text_fsp01]], 1899787537 --[[_text_area01]], 3542179801 --[[_text_page_title01]],
        1244139107 --[[_text_page_title02]], 2739645270 --[[_text_page_title04]], 3561790400 --[[_text_page_title05]],
        691026122 --[[_text_flavor01]], 777911507 --[[_text_flavor05]], 325360264 --[[_text_scr_btn01]],
        1757105749}) do
      funcLuaMenuCommand(2735666188, A, x, false, 0)
    end
    for _, m in ipairs({3032210235, 206240291, 563708378 --[[_gtxt_cmd_at01]], 3516146179 --[[_area_base01]],
        811580556 --[[_gtxt_armed01]], 1013569271 --[[_ai_use01]], 2992676399, 2269285990, 2408672862,
        658945009, 905124895, 2370796410, 1956062673, 859266817, 240613041, 380545388, 68880002, 3165086183,
        561011038, 4195885618, 3182975202, 2161668434, 855158082, 4122450641,
        2449339029 --[[_icon_fs_dmy01]], 478320441 --[[_icon_chr_dmy01]]}) do
      funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, A, m, false, 0)
    end
    funcLuaMenuCommand(1233047821 --[[number visible]], A, 0, 2223127589 --[[AT power]], false)
    funcLuaMenuCommand(4176779611 --[[clear face icon]], A, 0, 3237726902 --[[icon_chr_dmy01]])
    funcLuaMenuCommand(2158717427, A, 622567014 --[[_pos_page03]], true, 0)
    funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, A, 728354709, true, 0)
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, A, 2915321899 --[[_text_fs01]], Card.name(skill), 0)
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, A, 2956552560 --[[_text_flavor02]], Card.desc(skill), 0)
    funcLuaMenuCommand(2735666188, A, 2956552560, true, 0)
    funcLuaMenuCommand(558735651, A, 2815298114 --[[team00_30 <LG>]], 3558327990 --[[mixi_base01]], 1716659057 --[[fs_base01]], 0, 0)
    funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, A, 1605611365, true, 0)
    return true
  end

  Card.ROW = 2827747337
  Card.KEY_BASE = 2918576166
  Card.KEY_ROW = 416963278                 -- character_reforged_create_row
  Card.KEY_MOVES = {892911027, 2888952841} -- character_reforged_create_move1 / _move2
  Card.KEY_EARLY = 1743709088
  Card.TEMP_SET = 2565779025
  Card.BANK_RESULT = 2524660062            -- the bank's pick (retail temp int)
  Card.OPEN_MENU = 433545986               -- CMND_OPEN_MENU_OBJECT
  Card.BANK_MENU = 1981996040              -- chara_bank_menu_for_search
  Card.MENU_SUSPEND = 1129326309           -- (menu) suspended while the bank is open
  Card.MENU_HIDE = 1670867360
  Card.LOG = 2743311895                    -- CMND_CHARACTERREFORGED_CREATE_LOG (step, values…)

  function Card.open_bank_early(base, item, hide)
    if type(base) ~= "number" or base == 0 or not Card.is_create(item) or not Card.create_allowed(item, base) then
      return false
    end
    local row = funcLuaCommand(Card.ROW, item)
    if type(row) ~= "number" or row <= 0 then
      return false
    end
    for _, key in ipairs(Card.KEY_MOVES) do
      VRFW.param.clear(key)
    end
    VRFW.param.clear(Card.KEY_BASE)
    VRFW.param.set(Card.KEY_BASE, base)
    VRFW.param.clear(Card.KEY_ROW)
    VRFW.param.set(Card.KEY_ROW, row)
    funcLuaCommand(Card.TEMP_SET, Card.BANK_RESULT, 0)
    VRFW.param.clear(Card.KEY_EARLY)
    VRFW.param.set(Card.KEY_EARLY, 1)
    if hide ~= nil then
      -- every layer of that menu hidden (a resumed menu would draw through the bank)
      funcLuaMenuCommand(Card.MENU_HIDE, 1, hide)
      funcLuaMenuCommand(Card.MENU_SUSPEND, hide)
    end
    funcLuaCommand(Card.OPEN_MENU, Card.BANK_MENU)
    VRFW.host.command(Card.LOG, "bank opened from the list", "player", base, "row", row, "item", item)
    return true
  end
end
