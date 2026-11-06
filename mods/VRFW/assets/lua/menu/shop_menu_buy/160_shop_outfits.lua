-- VRFW › shop outfits, menu side. Handlers of the framework's shop_menu_buy host (VRFW_Host, 000_host.lua); no engine call at load time.
--
-- A new outfit ([[VRFW.Outfit]] with Name: a costume item that wears a kit, CMND_VRFW_OUTFIT_IS second answer) is previewed on the right as
-- the game previews kits: the game's costume preview (ChangeCharaModels, item category 140) poses the model with the costume pose of its
-- story-model costumes. The model is the outfit's wearer when its equip condition names characters (the game's own pick for a character
-- costume), else the kit models; every other item keeps the game's preview.
-- The wearer icon under the preview (UpdateSelectItemInfo) has a picture only for the game's own equip conditions (its table t17): for a
-- condition a mod added it is hidden instead of drawn without a picture.
-- An item that transforms its wearer ([[VRFW.ItemTransform]]) is previewed on the character he becomes.
if VRFW_Host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "VRFW.shop_outfits_"

  local CMD = {
    IS = VRFW_Cmd.VRFW_OUTFIT_IS,     -- CMND_VRFW_OUTFIT_IS(item) -> declared, new outfit
    ITEM_PARAM = 1883585771,          -- (item, 2) -> category
    UNIFORM = 845816129,              -- (item) -> has, uniform (item col 18)
    VIEW_CHARA = 1852689012,          -- (item) -> the item's own preview character (0 none)
    COND = 2421738681,                -- (item) -> has, equip condition
    COND_CHARA = 2389691295,          -- (equip condition) -> has, its character
    XFORM_TARGET = VRFW_Cmd.VRFW_ITEM_XFORM_TARGET,  -- (item, character) -> the character he becomes wearing it (0 none)
  }
  local COSTUME = 140                 -- item category of costumes
  local WEARER_ICON = 2394257302      -- the layer of the wearer / body type icon under the preview
  -- the game's kit preview (ChangeCharaModels, non-costume items): look flags per model slot (the view character's
  -- slot takes the second row), jersey number and poses per model count
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
    local h = VRFW_Host.hosts[STEM]
    return h and h.L or {}
  end

  local function call(...)
    local r = table.pack(pcall(funcLuaCommand, ...))
    if not r[1] then return nil end
    return table.unpack(r, 2, r.n)
  end

  -- true for a new outfit of a mod
  local function own_outfit(item)
    if type(item) ~= "number" or item == 0 then return false end
    if call(CMD.ITEM_PARAM, item, 2) ~= COSTUME then return false end
    local declared, own = call(CMD.IS, item)
    return declared == true and own == true
  end

  -- the condition's character, 0 when it names none
  local function wearer(item)
    local has, cond = call(CMD.COND, item)
    if has ~= true or type(cond) ~= "number" or not IsCharacterIconType(cond) then return 0, cond end
    local ok, chara = call(CMD.COND_CHARA, cond)
    if ok == true and type(chara) == "number" and chara ~= 0 then return chara, cond end
    return 0, cond
  end

  VRFW_Host.on(STEM, "ChangeCharaModels", { id = ID .. "preview", phase = "around", fn = function(nxt, a1, ...)
    if not own_outfit(a1) then return nxt(a1, ...) end
    local has, uniform = call(CMD.UNIFORM, a1)
    if has ~= true or type(uniform) ~= "number" or uniform == 0 then return nxt(a1, ...) end
    local h = L()
    local count, views = h.n5, h.t2
    if type(count) ~= "number" or type(views) ~= "table" then return nxt(a1, ...) end
    local same = a1 == h.n9
    h.n9 = a1
    local who = wearer(a1)
    if who ~= 0 then
      local target = call(CMD.XFORM_TARGET, a1, who)
      if type(target) == "number" and target ~= 0 then who = target end
    end
    local own_view = call(CMD.VIEW_CHARA, a1)
    local poses = POSES[count] or {}
    for i = 0, count - 1 do
      local k = i + 1
      local chara = views[k]
      if who ~= 0 then
        chara = who
      elseif type(own_view) == "number" and own_view ~= 0 and i == 0 then
        chara = own_view
      end
      local flags = FLAGS[k] or 0
      if k == h.n10 then flags = FLAGS_VIEW[k] or flags end
      SetupCharaModel(i, chara, uniform, NUMBER, flags, poses[k] or POSE_DEFAULT, 0, same)
    end
  end })

  VRFW_Host.on(STEM, "UpdateSelectItemInfo", { id = ID .. "wearer_icon", phase = "after", fn = function(r, a1, a2, a3)
    if a3 ~= COSTUME or not own_outfit(a2) then return end
    local who, cond = wearer(a2)
    if who == 0 then return end
    local icons = L().t17
    local pic = type(icons) == "table" and icons[cond] or nil
    if pic == nil or pic == 0 then
      pcall(funcLuaMenuCommand, VRFW_Cmd.SET_LAYER_VISIBLE, WEARER_ICON, 0, false)
    end
  end })
end
