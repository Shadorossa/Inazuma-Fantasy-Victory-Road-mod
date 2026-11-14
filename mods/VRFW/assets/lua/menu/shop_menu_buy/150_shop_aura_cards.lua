-- VRFW › shop aura cards, menu side.
if VRFW.host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "VRFW.shop_aura_cards_"

  local CMD = {
    CARDS = VRFW.commands.VRFW_SHOP_AURA_CARDS,
    SKILL_INFO = VRFW.commands.GET_SOCCER_SKILL_INFO,
    SKILL_NAME = 720417636,      -- move name text id -> text
    SKILL_TEXT = 4113915188,     -- move description text id -> text
  }
  local MENU = {
    IS_EXIST_LAYER = VRFW.commands.IS_EXIST_LAYER,
    SET_LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    SET_POS_VISIBLE = 2158717427,
    SET_TEXT_VISIBLE = 2735666188,
    SET_PART_VISIBLE = 1233047821,
    SET_MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    SET_TEXTURE = 558735651,
    CLEAR_FACE = 4176779611,
    SWAP_FACE = 346643487,       -- SwapLayerFaceIconTex
  }
  local PAGE_GUIDE = 1921826160  -- team00_40_change_page_guide
  -- the card's parts, as the game's mode change filler names them
  local PART = {
    PAGE = { 3407216458, 1377611504, 622567014, 3145665477, 3430431571 },       -- _pos_page01 … _pos_page05
    PAGE_TITLE = { 3542179801, 1244139107, 2739645270 },                        -- _text_page_title01, 02, 04
    TEXT_FSP = 1179414078, FLAVOR1 = 691026122, AREA = 1899787537, FLAVOR2 = 2956552560, FLAVOR5 = 777911507,
    PAGE1_PART = 2223127589,
    LIST1 = 1307475940, LIST2 = 3571920478,                                       -- _pos_list01, _pos_list02
    ARMED = 811580556, FS_FACE = 2449339029, CHR_FACE = 478320441,                -- _gtxt_armed01, _icon_fs_dmy01, _icon_chr_dmy01
    CHR_FACE_SLOT = 3237726902,
    NAME = 2915321899,                                                           -- _text_fs01
    BAND = 1716659057, AREA_ICON = 4285917355,                                    -- fs_base01, icon_fs_area_dmy01
  }
  local TEX = {
    CARD = 2815298114,           -- #/menu/102_team/team00/team00_30/<LG>/team00_30.g4tx
    ICONS = 2320109963,          -- #/menu/200_icon/15_icon_common/icon_common.g4tx
    AREA = 1917130140,           -- icon_sp_area11
  }
  local FACE_TYPE_PARTNER = 12   -- face icon type of a partner portrait (the miximax card's)

  local ST = { loaded = false, on = false, subs = {}, layer_of = {}, cards = {} }
  --- Internal: Namespace: the shop aura cards state (loaded, on, subs, layer_of, cards).
  VRFW.shop_aura_cards = ST

  local Log = VRFW.logger.new("vrfw.ShopAuraCards")

  local function on(point, phase, fn)
    VRFW.host.on(STEM, point, { id = ID .. point, phase = phase, fn = fn })
  end

  local function load()
    if ST.loaded then return end
    --- Internal: true once the card list was fetched from the plugin.
    ST.loaded = true
    local r = table.pack(VRFW.host.command(CMD.CARDS))
    if type(r[2]) ~= "number" then return end
    --- Internal: true when the plugin enables the aura cards.
    ST.on = r[1] == true
    for k = 1, r[2] do
      local sub, aura_type, layer = r[3 * k], r[1 + 3 * k], r[2 + 3 * k]
      if type(sub) == "number" and type(aura_type) == "number" and type(layer) == "number" then
        ST.subs[sub] = true
        ST.layer_of[aura_type] = ST.layer_of[aura_type] or layer
        ST.cards[layer] = true
      end
    end
  end

  local function band_of(element)
    if CALC_CRC == nil then return nil end
    if type(element) ~= "number" or element < 1 or element > 5 then element = 1 end
    return CALC_CRC("mode_base0" .. element)
  end

  -- the mode change card without a player
  local function fill(A, skill, a6)
    if not funcLuaMenuCommand(MENU.IS_EXIST_LAYER, A) then
      Log("no card layer", A, "(the declaring mod's content\\menus adds it to the shop_menu_buy group)")
      return
    end
    local has_guide = funcLuaMenuCommand(MENU.IS_EXIST_LAYER, PAGE_GUIDE)
    funcLuaMenuCommand(MENU.SET_LAYER_VISIBLE, A, 0, false)
    if has_guide then
      funcLuaMenuCommand(MENU.SET_LAYER_VISIBLE, PAGE_GUIDE, 0, false)
    end
    if skill == nil or skill == 0 then
      return
    end
    -- page 3 only (name + description), as the game's mode change card
    local p1, p2, p3, p4, p5 = false, false, true, false, false
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.PAGE[1], p1, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.TEXT_FSP, p1, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.FLAVOR1, p1, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.AREA, p1, 0)
    funcLuaMenuCommand(MENU.SET_PART_VISIBLE, A, 0, PART.PAGE1_PART, p1)
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.PAGE[2], p2, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.FLAVOR1, p2, 0)
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.PAGE[3], p3, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.FLAVOR2, p3, 0)
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.PAGE[4], p4, 0)
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.PAGE[5], p5, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.FLAVOR5, p5, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.PAGE_TITLE[1], p1, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.PAGE_TITLE[2], p2, 0)
    funcLuaMenuCommand(MENU.SET_TEXT_VISIBLE, A, PART.PAGE_TITLE[3], p4, 0)
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.LIST1, false, 0)
    funcLuaMenuCommand(MENU.SET_POS_VISIBLE, A, PART.LIST2, false, 0)
    funcLuaMenuCommand(MENU.SET_MESH_VISIBLE, A, PART.ARMED, false)
    funcLuaMenuCommand(MENU.SET_MESH_VISIBLE, A, PART.FS_FACE, false)
    funcLuaMenuCommand(MENU.SET_MESH_VISIBLE, A, PART.CHR_FACE, false)
    local okn, name = funcLuaCommand(CMD.SKILL_INFO, skill, 4)
    if okn then
      funcLuaMenuCommand(MENU.SET_TEXT, A, PART.NAME, funcLuaCommand(CMD.SKILL_NAME, name), 0)
    end
    local okd, text = funcLuaCommand(CMD.SKILL_INFO, skill, 5)
    if okd then
      funcLuaMenuCommand(MENU.SET_TEXT, A, PART.FLAVOR2, funcLuaCommand(CMD.SKILL_TEXT, text), 0)
    end
    if ChangeVisbleUseAiMeshIcon ~= nil then
      pcall(ChangeVisbleUseAiMeshIcon, skill, nil, A, a6)
    end
    local oke, element = funcLuaCommand(CMD.SKILL_INFO, skill, 7)
    local band = band_of(oke and element or nil)
    if band ~= nil then
      funcLuaMenuCommand(MENU.SET_TEXTURE, A, TEX.CARD, band, PART.BAND, 0, 0)
    end
    funcLuaMenuCommand(MENU.SET_TEXTURE, A, TEX.ICONS, TEX.AREA, PART.AREA_ICON, 0, 0)
    funcLuaMenuCommand(MENU.CLEAR_FACE, A, 0, PART.CHR_FACE_SLOT)
    local okc, chara = funcLuaCommand(CMD.SKILL_INFO, skill, 17)
    if okc and type(chara) == "number" and chara ~= 0 then
      funcLuaMenuCommand(MENU.SET_MESH_VISIBLE, A, PART.CHR_FACE, true, 0)
      funcLuaMenuCommand(MENU.SWAP_FACE, A, 0, PART.CHR_FACE, PART.CHR_FACE_SLOT, chara, 0, FACE_TYPE_PARTNER, true, true, true, 5)
    end
    funcLuaMenuCommand(MENU.SET_LAYER_VISIBLE, A, 0, true)
  end

  on("OnInit", "before", function()
    ST.loaded = false
    ST.on, ST.subs, ST.layer_of, ST.cards = false, {}, {}, {}
  end)

  -- a declared card layer is hidden when the shop sets it up, as the game's own aura cards
  on("OnSetupLayer", "after", function(r, layer, instance)
    load()
    if ST.cards[layer] then
      funcLuaMenuCommand(MENU.SET_LAYER_VISIBLE, layer, instance or 0, false)
    end
  end)

  on("IsAuraSkillFromType", "around", function(nxt, sub, ...)
    load()
    if ST.on and ST.subs[sub] then
      return true
    end
    return nxt(sub, ...)
  end)

  on("GetAuraSkillLayer", "around", function(nxt, aura_type, ...)
    load()
    if ST.on and ST.layer_of[aura_type] ~= nil then
      return ST.layer_of[aura_type]
    end
    return nxt(aura_type, ...)
  end)

  on("UpdateModeChangeDetailInfo", "around", function(nxt, layer, skill, chara, a4, a5, a6)
    load()
    if ST.on and ST.cards[layer] and (chara == nil or chara == 0) then
      local ok, err = pcall(fill, layer, skill, a6)
      if not ok then
        Log("fill error", tostring(err))
      end
      return
    end
    return nxt(layer, skill, chara, a4, a5, a6)
  end)
end
