-- Advanced: Layers that mods add so that their cards count as formation cards.
if VRFW.player_card == nil then
  local P = {
    FILL = 2339877830,
    PRIM_VISIBLE = 1233047821,  -- (layer, idx, number prim, on)
    NODE_VISIBLE = 2158717427,  -- (layer, node, on, idx)
    -- the layers created from the game's team00_01 card objbins (all menus)
    CARD_LAYERS = {
      [1973487846] = true, [1658289671] = true,
      [3241819447] = true, [1791816279] = true,
      [1774956026] = true, [3003299608] = true, [3825623416] = true,
      [2344757061] = true, [3940198160] = true,
      [3578260017] = true, [1690405657] = true,
      [2276833727] = true
    },
    -- the large card's body from the layer origin (layout px, y up): its height and centre
    BODY = { H = 132, CX = 0, CY = -6 },
    NAME = 170976702,           -- _text_chr01
    -- the parts never shown: card / lock icons, the focus frame, the grey-out, the EXP gauge
    HIDE = { 2635558741 --[[_icon_card01]], 814224422 --[[_icon_lock01]], 3345942320 --[[_icon_chr_focus_l01]],
      2942116298 --[[_icon_chr_grayout01]], 4280102433 --[[_gauge_exp_base_l01]], 3724093868 --[[_gauge_exp_l01]] },
    HIDE_NODES = { 3442901805 --[[_pos_gauge_exp_l01]] },
    -- the level: its label and anchor meshes, its nodes and every number prim variant (plain, ?, grey, cap, basara)
    LEVEL_MESHES = { 1343488901 --[[_gtxt_lv_l01]], 1198450632, 1451641049 --[[_num_chr_dmy_l01]], 1107078292 },
    LEVEL_NODES = { 2265056496 --[[_num_chr_l01]], 504059210 --[[_num_chr_l02]] },
    LEVEL_PRIMS = { 3653219854, 3469038147, 3883528262, 97120277, 3238733729, 1687159846, 1202218120, 3594422447,
      3957043376, 1031695061 },
    -- the retail name setting of a soccer card: the game's card fills find the card's parts by these tags
    NAMES = {
      {"text_charaname", "_text_chr01"}, {"locator_base_pos_L", "_pos_base01"}, {"locator_base_pos_S", "_pos_base02"},
      {"numprim_level_L", "num_chr_l01"}, {"numprim_level_S", "num_chr_s01"},
      {"numprim_level_q_L", "num_chr_l01_q"}, {"numprim_level_q_S", "num_chr_s01_q"},
      {"numprim_level_gray_L", "num_chr_l01_gray"}, {"numprim_level_gray_S", "num_chr_s01_gray"},
      {"numprim_level_cap_L", "num_chr_l01_cup"}, {"numprim_level_cap_S", "num_chr_s01_cup"},
      {"numprim_level_basara_L", "num_chr_l01_basara"}, {"numprim_level_basara_S", "num_chr_s01_basara"},
      {"rate_anim_exp", "exp_gauge01"}, {"rate_group_exp", "bar"},
      {"locator_gp_gauge_L", "_pos_gauge_gp_l01"}, {"locator_gp_gauge_S", "_pos_gauge_gp_s01"},
      {"rate_anim_gp", "gp_gauge01"}, {"rate_group_gp", "bar"},
      {"locator_kp_gauge_L", "_pos_gauge_kp_l01"}, {"locator_kp_gauge_S", "_pos_gauge_kp_s01"},
      {"rate_anim_kp", "kp_gauge01"}, {"rate_group_kp", "bar"},
      {"tex_chara_face_L", "icon_chr_dmy_l01"}, {"tex_chara_face_S", "icon_chr_dmy_s01"},
      {"mesh_chara_face_L", "_icon_chr_dmy_l01"}, {"mesh_chara_face_S", "_icon_chr_dmy_s01"},
      {"mesh_icon_element_L", "_icon_chr_type_dmy_l01"}, {"mesh_icon_element_S", "_icon_chr_type_dmy_s01"},
      {"mesh_base_element_L", "_icon_base_l01"}, {"mesh_base_element_S", "_icon_base_s01"},
      {"tex_element_L", "icon_chr_type_dmy_l01"}, {"tex_element_S", "icon_chr_type_dmy_s01"},
      {"tex_file_element", "#/menu/200_icon/15_icon_common/icon_common.g4tx"},
      {"mesh_icon_position_L", "_icon_chr_position_dmy_l01"}, {"mesh_icon_position_S", "_icon_chr_position_dmy_s01"},
      {"tex_position_L", "icon_chr_position_dmy_l01"}, {"tex_position_S", "icon_chr_position_dmy_s01"},
      {"tex_file_position", "#/menu/200_icon/15_icon_common2/<LG>/icon_common2.g4tx"},
      {"tex_file_rarity", "#/menu/102_team/team00/team00_01/<LG>/team00_01.g4tx"},
      {"mesh_base_rarity_L", "_icon_chr_base_l01"}, {"mesh_base_rarity_S", "_icon_chr_base_s01"},
      {"tex_base_rarity_L", "icon_chr_base01_l01"}, {"tex_base_rarity_S", "icon_chr_base01_s01"},
      {"mesh_color_rarity_L", "_icon_chr_dmy_l01"}, {"mesh_color_rarity_S", "_icon_chr_dmy_s01"},
      {"tex_color_rarity_L", "icon_chr_color01_l01"}, {"tex_color_rarity_S", "icon_chr_color01_s01"},
      {"tex_gradation_rarity_L", "icon_chr_gradation_l01"}, {"tex_gradation_rarity_S", "icon_chr_gradation_s01"},
      {"mesh_captain_L", "_icon_captain01"}, {"mesh_captain_S", "_icon_captain02"},
      {"mesh_seasonal_flame_L", "_seasonal_frame_l01"}, {"mesh_seasonal_flame_S", "_seasonal_frame_s01"},
      {"mesh_ai_role_setting_icon_L", "_icon_ai_role_dmy01"}, {"mesh_ai_role_setting_icon_S", "_icon_ai_role_dmy02"},
      {"tex_ai_role_setting_icon_L", "icon_ai_role_dmy01"}, {"tex_ai_role_setting_icon_S", "icon_ai_role_dmy01"},
      {"tex_file_ai_role", "#/menu/200_icon/15_icon_common/<LG>/icon_common.g4tx"},
      {"pos_leader_L", "_pos_leader01"}, {"pos_leader_S", "_pos_leader02"},
      {"pos_gauge_exp_L", "_pos_gauge_exp_l01"}, {"pos_gauge_exp_S", "_pos_gauge_exp_s01"},
      {"hidden_exp_gauge", "true"}, {"material_rarity_color", "rarity_color"},
    },
    named = {},
    filled = {},                -- "layer:idx" -> the key of the fill shown (card and rules)
    told = {},                  -- the failures already logged
  }
  --- Advanced: Namespace of the player card helpers: which layers count as formation cards and card lookups.
  VRFW.player_card = P

  -- Layers that mods add so that their cards count as formation cards.
  VRFW.formation_card_extra = VRFW.formation_card_extra or {}

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("vrfw.PlayerCard")
    logger(...)
  end

  local function tell(what, ...)
    if P.told[what] then
      return
    end
    P.told[what] = true
    log(what, ...)
  end

  -- the name setting of instance (layer, idx): true once written
  local function name_card(layer, idx, k)
    if P.named[k] then
      return true
    end
    if MENU_DEF == nil or type(MENU_DEF.NameSettingBegin) ~= "function" then
      tell("no name setting in this menu VM: cards not filled")
      return false
    end
    P.named[k] = true
    local ok, err = pcall(function()
      MENU_DEF.NameSettingBegin(layer, idx)
      for _, e in ipairs(P.NAMES) do
        MENU_DEF.AddName(e[1], e[2])
      end
      MENU_DEF.NameSettingEnd()
    end)
    if not ok then
      log("name setting failed", k, tostring(err))
    end
    return ok
  end

  -- the parts the rules leave out
  local function hide_parts(layer, idx, opts)
    for _, m in ipairs(P.HIDE) do
      VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, layer, m, false, idx)
    end
    for _, n in ipairs(P.HIDE_NODES) do
      VRFW.host.menu_command(P.NODE_VISIBLE, layer, n, false, idx)
    end
    if opts.name ~= true then
      VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_VISIBLE, layer, P.NAME, false, idx)
      VRFW.host.menu_command(P.NODE_VISIBLE, layer, P.NAME, false, idx)
    end
    if type(opts.level) ~= "number" then
      for _, m in ipairs(P.LEVEL_MESHES) do
        VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, layer, m, false, idx)
      end
      for _, n in ipairs(P.LEVEL_NODES) do
        VRFW.host.menu_command(P.NODE_VISIBLE, layer, n, false, idx)
      end
      for _, pr in ipairs(P.LEVEL_PRIMS) do
        VRFW.host.menu_command(P.PRIM_VISIBLE, layer, idx, pr, false)
      end
    end
  end

  --- Advanced: Answers whether `layer` holds formation cards: a card layer of the game or one in `VRFW.formation_card_extra`.
  function P.is_formation_card_layer(layer)
    return P.CARD_LAYERS[layer] == true or VRFW.formation_card_extra[layer] == true
  end

  --- Advanced: Draws a player card; answers true, or false for no card.
  function P.draw(layer, idx, card, x, y, size, opts)
    opts = opts or {}
    local k = layer .. ":" .. idx
    if type(card) ~= "number" or card == 0 then
      P.filled[k] = nil
      return false
    end
    local B = P.BODY
    local s = size / B.H
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_LOCAL_SCALE, layer, s, s, 1, idx)
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_LOCAL_POS, layer, x - B.CX * s, -y - B.CY * s, 0, idx)
    local key = table.concat({ card, tostring(opts.level), tostring(opts.name == true), tostring(opts.captain == true),
      opts.uniform or 0, opts.rarity or 0, opts.priority or 0 }, ",")
    if P.filled[k] == key then
      return true
    end
    if not name_card(layer, idx, k) then
      return false
    end
    if type(SetDisableForceCharaInvalidUseTarget) == "function" then
      pcall(SetDisableForceCharaInvalidUseTarget)
    end
    local done = VRFW.host.menu_command(P.FILL, layer, idx, card, true, false, 0, 0, type(opts.level) == "number" and opts.level or 1,
      opts.captain == true, false, opts.rarity or 0, opts.uniform or 0)
    if type(SetEnableForceCharaInvalidUseTarget) == "function" then
      pcall(SetEnableForceCharaInvalidUseTarget)
    end
    if done == false then
      tell("refused " .. card, "card", card, "on", k)
      P.filled[k] = nil
      return false
    end
    hide_parts(layer, idx, opts)
    if type(opts.priority) == "number" then
      VRFW.host.menu_command(VRFW.commands.SET_DRAW_PRIORITY, layer, idx, opts.priority, true)
    end
    P.filled[k] = key
    return true
  end

  --- Internal: Sets the card name of (layer, idx); answers true, or false.
  function P.name(layer, idx)
    if type(layer) ~= "number" or type(idx) ~= "number" then
      return false
    end
    return name_card(layer, idx, layer .. ":" .. idx)
  end

  --- Advanced: Forgets the card state of (layer, idx), or of `layer`.
  function P.forget(layer, idx)
    if idx ~= nil then
      P.filled[layer .. ":" .. idx] = nil
      return
    end
    local pre = layer .. ":"
    for k in pairs(P.filled) do
      if k:sub(1, #pre) == pre then
        P.filled[k] = nil
      end
    end
  end
end
