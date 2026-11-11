-- VRFW › shop outfits, menu side.
if VRFW.host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "VRFW.shop_outfits_"

  local CMD = {
    IS = VRFW.commands.VRFW_OUTFIT_IS,     -- CMND_VRFW_OUTFIT_IS(item) -> declared, new outfit
    ITEM_PARAM = 1883585771,          -- (item, 2) -> category
    UNIFORM = 845816129,              -- (item) -> has, uniform (item col 18)
    VIEW_CHARA = 1852689012,          -- (item) -> the item's own preview character (0 none)
    COND = 2421738681,                -- (item) -> has, equip condition
    COND_CHARA = 2389691295,          -- (equip condition) -> has, its character
    BODIES = 3358195198,              -- (uniform) -> has, its body types
    CHARA_INFO = VRFW.commands.GET_CHARA_INFO,  -- (character, 22, 0) -> has, his body type
    XFORM_TARGET = VRFW.commands.VRFW_ITEM_XFORM_TARGET,
  }
  local COSTUME = 140                 -- item category of costumes
  local BODY_INFO = 22                -- GET_CHARA_INFO field of the body type
  local COND_MALE, COND_FEMALE = 3, 4 -- equip conditions of male / female wearers
  local WEARER_ICON = 2394257302      -- the layer of the wearer / body type icon under the preview
  local HIDE_INSTANCES = 2171393651   -- (layer, false) hides every instance of a layer
  local INSTANCE_COUNT = 1175615627   -- (layer) -> the instances the layer has
  local SET_SPRITE = 558735651        -- (layer, atlas, sprite, node, 0, instance) draws a sprite on a node
  local BODY_ICON_ATLAS = 2320109963  -- #/menu/200_icon/15_icon_common/icon_common.g4tx
  local BODY_ICON_NODE = 2190317620   -- icon_body_type_dmy01
  local FLAGS = { 0, 2, 1, 3 }
  local FLAGS_VIEW = { 8, 10, 9, 11 }
  local NUMBER = 10
  local POSES = {
    { 1325728155 },
    { 1591269689, 2506065662 },
    { 1275840522, 1325728155, 3704418768 },
    { 1275840522, 1591269689, 2506065662, 3704418768 },
  }
  local POSE_DEFAULT = 1325728155

  local function L()
    local h = VRFW.host.hosts[STEM]
    return h and h.L or {}
  end

  -- true for a new outfit of a mod
  local function own_outfit(item)
    if type(item) ~= "number" or item == 0 then return false end
    if VRFW.host.command(CMD.ITEM_PARAM, item, 2) ~= COSTUME then return false end
    local declared, own = VRFW.host.command(CMD.IS, item)
    return declared == true and own == true
  end

  -- the condition's character, 0 when it names none
  local function wearer(item)
    local has, cond = VRFW.host.command(CMD.COND, item)
    if has ~= true or type(cond) ~= "number" or not IsCharacterIconType(cond) then return 0, cond end
    local ok, chara = VRFW.host.command(CMD.COND_CHARA, cond)
    if ok == true and type(chara) == "number" and chara ~= 0 then return chara, cond end
    return 0, cond
  end

  -- the body types the uniform has a mesh for, nil when the game lists none
  local function bodies(uniform)
    local has, list = VRFW.host.command(CMD.BODIES, uniform)
    if has ~= true or type(list) ~= "table" or #list == 0 then return nil end
    return list
  end

  -- true when the character's body type is one of the list
  local function fits(chara, list)
    local has, body = VRFW.host.command(CMD.CHARA_INFO, chara, BODY_INFO, 0)
    if has ~= true then return false end
    for _, b in ipairs(list) do
      if b == body then return true end
    end
    return false
  end

  -- the game's preview model of the first listed body type the condition allows (its costume rule), 0 none
  local function body_model(list, cond)
    local h = L()
    local models, male = h.t14, h.t15
    if type(models) ~= "table" or type(male) ~= "table" then return 0 end
    for _, b in ipairs(list) do
      local k = b + 1
      if (cond ~= COND_MALE or male[k] == true) and (cond ~= COND_FEMALE or male[k] == false) then return models[k] or 0 end
    end
    return 0
  end

  VRFW.host.on(STEM, "ChangeCharaModels", { id = ID .. "preview", phase = "around", fn = function(nxt, a1, ...)
    if not own_outfit(a1) then return nxt(a1, ...) end
    local has, uniform = VRFW.host.command(CMD.UNIFORM, a1)
    if has ~= true or type(uniform) ~= "number" or uniform == 0 then return nxt(a1, ...) end
    local h = L()
    local count, views = h.n5, h.t2
    if type(count) ~= "number" or type(views) ~= "table" then return nxt(a1, ...) end
    local same = a1 == h.n9
    h.n9 = a1
    -- The condition's character is only its first listed one, so the preview shows a character only when the outfit turns him into a form.
    local first, cond = wearer(a1)
    local who = 0
    if first ~= 0 then
      local target = VRFW.host.command(CMD.XFORM_TARGET, a1, first)
      if type(target) == "number" and target ~= 0 then who = target end
    end
    local list = bodies(uniform)
    if who ~= 0 and list ~= nil and not fits(who, list) then who = 0 end
    local model = (who == 0 and list ~= nil) and body_model(list, cond) or 0
    local own_view = VRFW.host.command(CMD.VIEW_CHARA, a1)
    local poses = POSES[count] or {}
    for i = 0, count - 1 do
      local k = i + 1
      local chara = views[k]
      if who ~= 0 then
        chara = who
      elseif model ~= 0 then
        chara = model
      elseif type(own_view) == "number" and own_view ~= 0 and i == 0 then
        chara = own_view
      end
      local flags = FLAGS[k] or 0
      if k == h.n10 then flags = FLAGS_VIEW[k] or flags end
      SetupCharaModel(i, chara, uniform, NUMBER, flags, poses[k] or POSE_DEFAULT, 0, same)
    end
  end })

  -- Draws the body type icons of the body types in `list`, as the game draws a costume's; false when none is drawn.
  local function show_bodies(list)
    local h = L()
    local icon_of, icons = h.t5, h.t6
    if type(icon_of) ~= "table" or type(icons) ~= "table" then return false end
    local shown = {}
    for _, b in ipairs(list) do
      local k = icon_of[b + 1]
      if k ~= nil then shown[k] = true end
    end
    VRFW.host.menu_command(HIDE_INSTANCES, WEARER_ICON, false)
    local room = VRFW.host.menu_command(INSTANCE_COUNT, WEARER_ICON)
    if type(room) ~= "number" then return false end
    local at, last = 0, 0
    for k = 1, #icons do
      if at >= room then break end
      if shown[k] then
        VRFW.host.menu_command(SET_SPRITE, WEARER_ICON, BODY_ICON_ATLAS, icons[k], BODY_ICON_NODE, 0, at)
        VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, WEARER_ICON, at, true)
        last = at
        at = at + 1
      end
    end
    -- The game shows the instances 0..n26 again when the preview comes back.
    h.n26 = last
    return at > 0
  end

  VRFW.host.on(STEM, "UpdateSelectItemInfo", { id = ID .. "wearer_icon", phase = "after", fn = function(r, a1, a2, a3)
    if a3 ~= COSTUME or not own_outfit(a2) then return end
    -- An outfit anyone wears and the game's male / female conditions keep the game's icons.
    local limited, cond = VRFW.host.command(CMD.COND, a2)
    if limited ~= true or type(cond) ~= "number" or not IsCharacterIconType(cond) then return end
    local pictures = L().t17
    if type(pictures) == "table" and pictures[cond] ~= nil and pictures[cond] ~= 0 then return end
    -- A wearer list of a mod has no picture: the icons are the body types its uniform has a mesh for, not the game's
    -- pairs of both sexes.
    local has, uniform = VRFW.host.command(CMD.UNIFORM, a2)
    local list = has == true and type(uniform) == "number" and bodies(uniform) or nil
    if list == nil or not show_bodies(list) then
      VRFW.host.menu_command(HIDE_INSTANCES, WEARER_ICON, false)
    end
  end })
end
