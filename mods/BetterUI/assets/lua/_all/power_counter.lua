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
  local PROBE_STEP = 100           -- px the layer moves while its offset is measured
  local PROBE_WAIT = 2             -- frames between a probe move and its reading
  local SNAP = 3                   -- px: an item this close to its place is shown
  local DONE = 0.5                 -- px: an item this close is in place and left alone
  local SETTLE = 1                 -- frames between a move and the next correction

  local function command(name, ...)
    return VRFW.host.menu_command(Crc(name), ...)
  end

  -- true when player `chara`'s execution of `move` was a critical hit
  function P.Critical(chara, move)
    if type(chara) ~= "number" or chara == 0 or type(move) ~= "number" or move == 0 then
      return false
    end
    return VRFW.host.command(Crc(CMD_CRITICAL), chara, move) ~= nil
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

  function P.GlobalPosition(layer, index, node)
    local x, y = command("CMND_GET_MESH_GLOBAL_POSITION", layer, index, node)
    if type(x) ~= "number" or type(y) ~= "number" then
      return nil
    end
    return x, y
  end

  -- where on screen a plate's tag goes: config.toml [duel_counter] tag_x / tag_y from the plate's total
  function P.TagTarget(i, layout)
    local plate = P.PLATES[i]
    local layer = Crc(plate.layer)
    if command("CMND_IS_OPEN_LAYER", layer) ~= true then
      return nil
    end
    local x = P.GlobalPosition(layer, 0, Crc(plate.number_node))
    local _, y = P.GlobalPosition(layer, 0, Crc(plate.slide))
    if x == nil or y == nil or type(layout) ~= "table" or layout.tag_x == nil or layout.tag_y == nil then
      return nil
    end
    return x + layout.tag_x, y + layout.tag_y
  end

  -- A placer moves the instances of one layer so that one of their nodes lands on a screen point.
  function P.NewPlacer(layer_name, node_name, log)
    return { layer = Crc(layer_name), node = Crc(node_name), map = nil, probe = nil, items = {}, log = log }
  end

  -- true once the layer's position -> screen map is known; placer.map == false when it cannot be
  function P.Measure(p)
    if p.map ~= nil then
      return p.map ~= false
    end
    if p.probe == nil then
      p.probe = { step = 0, wait = PROBE_WAIT }
      command("CMND_SET_LAYER_LOCAL_POS", p.layer, 0, 0, 0, 0)
      return false
    end
    if p.probe.wait > 0 then
      p.probe.wait = p.probe.wait - 1
      return false
    end
    local x, y = P.GlobalPosition(p.layer, 0, p.node)
    if x == nil then
      p.map = false
      p.log("placer: no global position for its node: off")
      return false
    end
    if p.probe.step == 0 then
      p.probe.x0, p.probe.y0, p.probe.step, p.probe.wait = x, y, 1, PROBE_WAIT
      command("CMND_SET_LAYER_LOCAL_POS", p.layer, PROBE_STEP, PROBE_STEP, 0, 0)
      return false
    end
    local scale_x, scale_y = (x - p.probe.x0) / PROBE_STEP, (y - p.probe.y0) / PROBE_STEP
    if math.abs(scale_x) < 0.1 or math.abs(scale_y) < 0.1 then
      p.map = false
      p.log("placer: position does not move its node: off")
      return false
    end
    p.map = { x = scale_x, y = scale_y, origin_x = p.probe.x0, origin_y = p.probe.y0 }
    return true
  end

  function P.Started(p, instance)
    return p.items[instance + 1] ~= nil
  end

  function P.Hide(p, instance)
    command("CMND_SET_LAYER_VISIBLE", p.layer, instance, false)
    p.items[instance + 1] = nil
  end

  -- one step of moving `instance` so its node lands on (x, y); true when it is shown in place
  function P.Place(p, instance, x, y)
    local map = p.map
    local item = p.items[instance + 1]
    if item == nil then
      item = { x = (x - map.origin_x) / map.x, y = (y - map.origin_y) / map.y, shown = false, wait = SETTLE }
      p.items[instance + 1] = item
      command("CMND_SET_LAYER_LOCAL_POS", p.layer, item.x, item.y, 0, instance)
      return false
    end
    if item.wait > 0 then
      item.wait = item.wait - 1
      return false
    end
    local now_x, now_y = P.GlobalPosition(p.layer, instance, p.node)
    if now_x == nil then
      P.Hide(p, instance)
      return false
    end
    local error_x, error_y = x - now_x, y - now_y
    if not item.shown and math.abs(error_x) <= SNAP and math.abs(error_y) <= SNAP then
      item.shown = true
      command("CMND_SET_LAYER_VISIBLE", p.layer, instance, true)
    end
    if math.abs(error_x) > DONE or math.abs(error_y) > DONE then
      item.x = item.x + error_x / map.x
      item.y = item.y + error_y / map.y
      item.wait = SETTLE
      command("CMND_SET_LAYER_LOCAL_POS", p.layer, item.x, item.y, 0, instance)
      return false
    end
    return item.shown
  end

  -- the tag layer's instance `instance` shows the tag sprite only
  function P.DressTag(instance)
    local layer = Crc(P.TAG_LAYER)
    VRFW.host.menu_command(CMD_SPRITE, layer, Crc(TAG.atlas), Crc(TAG.sprite), Crc(TAG.slot), 0, instance)
    command("CMND_SET_MESH_VISIBLE", layer, Crc(TAG.mesh), true, instance)
    command("CMND_SET_MESH_VISIBLE", layer, Crc(TAG.glow), false, instance)
    command("CMND_SET_MENU_TEXT_STRING", layer, Crc(TAG.text), "", instance)
  end

  -- A tag set: the tags of the plates whose player made a critical hit, placed while their plates are open.
  function P.NewTags(critical, layout, log)
    return { critical = critical, layout = layout, placer = P.NewPlacer(P.TAG_LAYER, TAG.mesh, log), done = false, opened = false,
      hidden = false }
  end

  -- one step of the tag set; true when nothing is left to do
  function P.StepTags(t)
    if t.done then
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
    if not t.hidden then
      t.hidden = true
      for i = 1, #P.PLATES do
        command("CMND_SET_LAYER_VISIBLE", layer, i - 1, false)
      end
    end
    if not P.Measure(t.placer) then
      t.done = t.placer.map == false
      return t.done
    end
    local done = true
    for i = 1, #P.PLATES do
      if t.critical[i] then
        local x, y = P.TagTarget(i, t.layout)
        if x ~= nil and not P.Started(t.placer, i - 1) then
          P.DressTag(i - 1)
        end
        if x == nil or not P.Place(t.placer, i - 1, x, y) then
          done = false
        end
      end
    end
    t.done = done
    return done
  end

  function P.HideTags(t)
    for i = 1, #P.PLATES do
      P.Hide(t.placer, i - 1)
    end
    t.done = true
  end

  BetterUI.power_counter = P
end
