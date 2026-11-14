-- The power counters' shared parts (duel screen betterui_power_counter_menu, shot readout soccer_shoot_catch_info_menu).
BetterUI = type(BetterUI) == "table" and BetterUI or {}
if BetterUI.power_counter == nil then
  local Crc = VRFW.ids.crc32
  local P = {}

  -- the retail plates: 1 = the self layer (left), 2 = the enemy layer (right)
  P.PLATES = {
    { layer = "soccer10_25_at_kp_power_info_telop_self", number_node = "_num_total_at01", slide = "_pos_slide01_l",
      picture_slot = "gtxt_total_at01_dmy01" },
    { layer = "soccer10_25_at_kp_power_info_telop_enemy", number_node = "_num_total_at02", slide = "_pos_slide01_r",
      picture_slot = "gtxt_total_at02_dmy01" },
  }
  -- the plate pictures: attacker TOTAL AT (retail), defender TOTAL DF (images\menu\00_soccer\power_counter.toml)
  P.PICTURES = {
    attack = { atlas = "#/menu/00_soccer/soccer10/soccer10_25/<LG>/soccer10_25.g4tx", sprite = "gtxt_br_total_at01" },
    defense = { atlas = "#/menu/00_soccer/better_ui_power_counter/better_ui_power_counter.g4tx", sprite = "better_ui_gtxt_total_df01" },
  }
  -- the «critical» tag: one instance per plate of a betterui_power_counter_label layer, its plate mesh showing the tag sprite
  P.TAG_LAYER = "betterui_power_counter_crit"
  local TAG = { atlas = "#/menu/00_soccer/better_ui_power_counter/<LG>/better_ui_power_counter_crit.g4tx",
    sprite = "better_ui_gtxt_critical01", slot = "cmd_back_base01", mesh = "_cmd_back_base01", glow = "_cmd_back_base01_add",
    text = "_text_cmd_back01" }

  local CMD_SPRITE = 558735651     -- (layer, atlas path crc, new sprite, old sprite, 0, instance): a mesh shows another sprite
  local CMD_CRITICAL = "CMND_VRFW_CRITICAL"

  local function command(name, ...)
    return VRFW.host.menu_command(Crc(name), ...)
  end

  -- True when player `chara`'s execution of `move` was a critical hit: the command answers the hit's multiplier, or false.
  function P.Critical(chara, move)
    if type(chara) ~= "number" or chara == 0 or type(move) ~= "number" or move == 0 then
      return false
    end
    return type(VRFW.host.command(Crc(CMD_CRITICAL), chara, move)) == "number"
  end

  -- plate `i`'s picture: "attack" or "defense"
  function P.ShowPicture(i, layer, index, kind)
    local picture = P.PICTURES[kind]
    local plate = P.PLATES[i]
    if picture == nil or plate == nil then
      return
    end
    VRFW.host.menu_command(CMD_SPRITE, layer, Crc(picture.atlas), Crc(picture.sprite), Crc(plate.picture_slot), 0, index)
  end

  -- Where tag `i`'s centre goes, in layout px of soccer10_25 (anchored to the screen centre, y up): `tag_gap` px right of
  -- the total's right end `digits_end`, on the total's middle line. Without `digits_end` the total is the retail one,
  -- `tag_default_digits` digits centred on the retail number node.
  local function TagCentre(i, layout, digits_end)
    if digits_end == nil then
      local node_x = i == 1 and layout.left_retail_number_x or layout.right_retail_number_x
      digits_end = node_x + layout.tag_default_digits * layout.digit_width / 2
    end
    return digits_end + layout.tag_gap + layout.tag_width * layout.tag_scale / 2, layout.digits_mid_y
  end

  -- Shows tag instance `i - 1` with its centre on layout point (x, y). The tag layer has no anchor, so its origin is the
  -- layout's top-left corner with y up, and its scale applies around that origin together with the mesh centre
  -- (`tag_centre_x`, `tag_centre_y` in its object).
  local function PlaceTag(i, layout, x, y)
    local layer, instance, scale = Crc(P.TAG_LAYER), i - 1, layout.tag_scale
    command("CMND_SET_LAYER_LOCAL_SCALE", layer, scale, scale, 1, instance)
    VRFW.host.menu_command(CMD_SPRITE, layer, Crc(TAG.atlas), Crc(TAG.sprite), Crc(TAG.slot), 0, instance)
    command("CMND_SET_MESH_VISIBLE", layer, Crc(TAG.mesh), true, instance)
    command("CMND_SET_MESH_VISIBLE", layer, Crc(TAG.glow), false, instance)
    command("CMND_SET_MENU_TEXT_STRING", layer, Crc(TAG.text), "", instance)
    local local_x = layout.layout_width / 2 + x - layout.tag_centre_x * scale
    local local_y = y - layout.layout_height / 2 - layout.tag_centre_y * scale
    command("CMND_SET_LAYER_LOCAL_POS", layer, local_x, local_y, 0, instance)
    command("CMND_SET_LAYER_VISIBLE", layer, instance, true)
  end

  -- A tag set: the tags of the plates whose player made a critical hit. `ends` (optional) holds each total's right end in
  -- layout px; without it the totals are the retail ones.
  function P.NewTags(critical, layout, log, ends)
    return { critical = critical, layout = layout, ends = ends or {}, log = log, done = false, opened = false }
  end

  -- one step of the tag set; true when nothing is left to do
  function P.StepTags(t)
    if t.done then
      return true
    end
    if type(t.layout) ~= "table" then
      t.done = true
      return true
    end
    local layer = Crc(P.TAG_LAYER)
    if not t.opened then
      t.opened = true
      if command("CMND_IS_OPEN_LAYER", layer) ~= true then
        command("CMND_OPEN_LAYER_ARRAY", layer)
        return false
      end
    end
    if command("CMND_IS_OPEN_LAYER", layer) ~= true or command("CMND_IS_LOADING_LAYER", layer) == true then
      return false
    end
    for i = 1, #P.PLATES do
      if t.critical[i] then
        PlaceTag(i, t.layout, TagCentre(i, t.layout, t.ends[i]))
      else
        command("CMND_SET_LAYER_VISIBLE", layer, i - 1, false)
      end
    end
    t.done = true
    return true
  end

  function P.HideTags(t)
    for i = 1, #P.PLATES do
      command("CMND_SET_LAYER_VISIBLE", Crc(P.TAG_LAYER), i - 1, false)
    end
    t.done = true
  end

  BetterUI.power_counter = P
end
