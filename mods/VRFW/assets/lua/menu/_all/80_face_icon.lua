-- lua_patch.scope: used
if VRFW.face_icon == nil then
  local F = {
    FACE = 552280324,
    RESET = 4176779611,
    LOADING = 1277042906,        -- (layer, idx) -> true while the instance's face texture loads
    MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,   -- (layer, mesh, on, idx)
    NODE_VISIBLE = 2158717427,   -- (layer, node, on, idx)
    TEXT_VISIBLE = 2735666188,   -- (layer, text node, on, idx)
    SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,          -- (layer, sx, sy, sz, idx)
    POS = VRFW.commands.SET_LAYER_LOCAL_POS,            -- (layer, x, y, z, idx)
    CHARA_OF_CARD = 347353059,   -- (chara_param id) -> chara id
    WAIT = 300,
    CARD = {
      MESH = 2828003679 --[[_icon_chr_dmy_l01]], SLOT = 21929195 --[[icon_chr_dmy_l01]], NAME = 170976702 --[[_text_chr01]],
      RH = 156, OX = 59, OY = 11,
      -- the portrait's background and gradient: hidden unless opts.portrait
      FRAME = {2907077971 --[[_icon_chr_base_l01]], 2211886546 --[[_icon_chr_gradation_l01]]},
      HIDE = {
        960763094 --[[_seasonal_frame_l01]], 2508362790 --[[_avatar_frame_l01]], 3345942320 --[[_icon_chr_focus_l01]],
        1721769611 --[[_icon_chr_position_dmy_l01]], 3895971012 --[[_icon_base_l01]],
        32585899 --[[_icon_chr_type_dmy_l01]], 814224422 --[[_icon_lock01]], 2815608092 --[[_icon_captain01]],
        3203992661 --[[_icon_ai_role_dmy01]], 1343488901 --[[_gtxt_lv_l01]], 2635558741 --[[_icon_card01]],
        1458727926 --[[_icon_chr_def01_l]], 2942116298 --[[_icon_chr_grayout01]], 338392935 --[[_basara_avatar_l01]],
        1451641049 --[[_num_chr_dmy_l01]], 3482261859 --[[_num_chr_dmy_l02]], 4280102433 --[[_gauge_exp_base_l01]],
        3724093868 --[[_gauge_exp_l01]], 897168128 --[[_icon_synergy_l01]], 2893079226 --[[_icon_synergy_l02]],
        3098974311 --[[_leader_base01]], 3330617040 --[[_gtxt_leader01]],
      },
      HIDE_NODES = {
        3279539624 --[[_pos_base02]], 1387831794 --[[_pos_leader01]], 3524586656 --[[_pos_ai_role01]],
        2265056496 --[[_num_chr_l01]], 504059210 --[[_num_chr_l02]], 3442901805 --[[_pos_gauge_exp_l01]],
      },
    },
    shown = {},
    waiting = {},                -- "layer:idx" -> { layer, idx, mesh, key, left }
    card_key = {},
  }
  VRFW.face_icon = F

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("vrfw.FaceIcon")
    logger(...)
  end

  -- the chara key of `who` (nil, reason when there is none); a player handle form answers key, nil, handle, kind
  local function key_of(who)
    if type(who) == "number" then
      return who ~= 0 and who or nil, "no character"
    end
    if type(who) ~= "table" then
      return nil, "no character"
    end
    if type(who.handle) == "number" and who.handle ~= 0 then
      return type(who.chara) == "number" and who.chara or 0, nil, who.handle,
        type(who.kind) == "number" and who.kind or 0
    end
    if type(who.chara) == "number" and who.chara ~= 0 then
      return who.chara
    end
    if type(who.card) == "number" and who.card ~= 0 then
      local ok, id = pcall(funcLuaCommand, F.CHARA_OF_CARD, who.card)
      if ok and type(id) == "number" and id ~= 0 then
        return id
      end
      return nil, string.format("card %d has no character", who.card)
    end
    return nil, "no character"
  end

  local function fail(k, layer, idx, mesh, key, why, look)
    VRFW.host.menu_command(F.MESH_VISIBLE, layer, mesh, false, idx)
    F.waiting[k] = nil
    local s = F.shown[k]
    if s ~= nil and s.state == "failed" and s.key == key and s.look == look then
      return false
    end
    F.shown[k] = { key = key, mesh = mesh, look = look, state = "failed" }
    log("face not drawn", layer, idx, tostring(key), why)
    return false
  end

  local function request(layer, idx, key, mesh, slot, opts, handle, kind)
    opts = opts or {}
    handle, kind = handle or 0, kind or 0
    VRFW.host.menu_command(F.RESET, layer, idx, slot)
    if type(SetDisableForceCharaInvalidUseTarget) == "function" then
      pcall(SetDisableForceCharaInvalidUseTarget)
    end
    local ok, r
    if opts.coach or opts.manager then
      ok, r = pcall(funcLuaMenuCommand, F.FACE, layer, idx, opts.face_only == true, mesh, slot, handle, kind, key,
        opts.kit or 0, false, opts.use_args == true, 0, opts.coach == true, false, -1, 0, opts.manager == true)
    elseif opts.use_args or opts.kit ~= nil or opts.keeper ~= nil then
      ok, r = pcall(funcLuaMenuCommand, F.FACE, layer, idx, opts.face_only == true, mesh, slot, handle, kind, key,
        opts.kit or 0, opts.keeper == true, opts.use_args == true)
    else
      ok, r = pcall(funcLuaMenuCommand, F.FACE, layer, idx, opts.face_only == true, mesh, slot, handle, kind, key)
    end
    if type(SetEnableForceCharaInvalidUseTarget) == "function" then
      pcall(SetEnableForceCharaInvalidUseTarget)
    end
    if not ok or r == false then
      return false, ok and "refused" or tostring(r)
    end
    return true
  end

  --- Requests the face icon of `who`; answers false for no face.
  function F.request(layer, idx, who, mesh, slot, opts)
    local key, _, handle, kind = key_of(who)
    if key == nil then
      VRFW.host.menu_command(F.RESET, layer, idx, slot)
      return false
    end
    return (request(layer, idx, key, mesh, slot, opts, handle, kind))
  end

  --- Draws the face of `who`: "drawn", "loading", or the failure's answer.
  function F.face(layer, idx, who, mesh, slot, opts)
    local k = layer .. ":" .. idx
    local key, why, handle, kind = key_of(who)
    if key == nil then
      VRFW.host.menu_command(F.MESH_VISIBLE, layer, mesh, false, idx)
      F.waiting[k] = nil
      if why ~= "no character" then
        return fail(k, layer, idx, mesh, 0, why)
      end
      F.shown[k] = nil
      return false
    end
    local look = (opts and opts.coach) and "coach" or (opts and opts.manager) and "manager" or "player"
    if handle ~= nil then
      look = look .. ":" .. handle
    end
    local s = F.shown[k]
    if s ~= nil and s.key == key and s.mesh == mesh and s.look == look then
      if s.state == "failed" then
        return false
      end
      if s.state == "drawn" then
        return "drawn"
      end
    else
      local asked, why = request(layer, idx, key, mesh, slot, opts, handle, kind)
      if not asked then
        return fail(k, layer, idx, mesh, key, why, look)
      end
      F.shown[k] = { key = key, mesh = mesh, look = look, state = "loading" }
      F.waiting[k] = { layer = layer, idx = idx, mesh = mesh, key = key, left = F.WAIT }
    end
    if VRFW.host.menu_command(F.LOADING, layer, idx) == true then
      VRFW.host.menu_command(F.MESH_VISIBLE, layer, mesh, false, idx)
      return "loading"
    end
    F.shown[k].state = "drawn"
    F.waiting[k] = nil
    VRFW.host.menu_command(F.MESH_VISIBLE, layer, mesh, true, idx)
    return "drawn"
  end

  --- Draws a card face at (x, y) with `size`; answers as F.face.
  function F.card(layer, idx, who, x, y, size, opts)
    local C = F.CARD
    local s = size / C.RH
    VRFW.host.menu_command(F.SCALE, layer, s, s, 1, idx)
    VRFW.host.menu_command(F.POS, layer, x - C.OX * s, -y - C.OY * s, 0, idx)
    local k = layer .. ":" .. idx
    local mode = (opts and opts.portrait) and "portrait" or "face"
    if F.card_key[k] == nil then
      for _, m in ipairs(C.HIDE) do
        VRFW.host.menu_command(F.MESH_VISIBLE, layer, m, false, idx)
      end
      for _, n in ipairs(C.HIDE_NODES) do
        VRFW.host.menu_command(F.NODE_VISIBLE, layer, n, false, idx)
      end
      VRFW.host.menu_command(F.TEXT_VISIBLE, layer, C.NAME, false, idx)
    end
    if F.card_key[k] ~= mode then
      for _, m in ipairs(C.FRAME) do
        VRFW.host.menu_command(F.MESH_VISIBLE, layer, m, mode == "portrait", idx)
      end
      if F.card_key[k] ~= nil or mode == "portrait" then
        log("card", k, "now", mode)
      end
      F.card_key[k] = mode
    end
    return F.face(layer, idx, who, C.MESH, C.SLOT, opts)
  end

  --- True while a face is still loading.
  function F.pending()
    return next(F.waiting) ~= nil
  end

  --- Clears the faces that finished loading.
  function F.settle()
    for k, w in pairs(F.waiting) do
      if VRFW.host.menu_command(F.LOADING, w.layer, w.idx) ~= true then
        F.waiting[k] = nil
        local s = F.shown[k]
        if s ~= nil then
          s.state = "drawn"
        end
        VRFW.host.menu_command(F.MESH_VISIBLE, w.layer, w.mesh, true, w.idx)
      else
        w.left = w.left - 1
        if w.left <= 0 then
          fail(k, w.layer, w.idx, w.mesh, w.key, "still loading after " .. F.WAIT .. " checks",
            F.shown[k] and F.shown[k].look)
        end
      end
    end
  end

  --- Forgets the face state of (layer, idx), or of every instance of `layer`.
  function F.forget(layer, idx)
    if idx ~= nil then
      local k = layer .. ":" .. idx
      F.shown[k], F.waiting[k], F.card_key[k] = nil, nil, nil
      return
    end
    local pre = layer .. ":"
    for _, t in ipairs({ F.shown, F.waiting, F.card_key }) do
      for k in pairs(t) do
        if k:sub(1, #pre) == pre then
          t[k] = nil
        end
      end
    end
  end
end
