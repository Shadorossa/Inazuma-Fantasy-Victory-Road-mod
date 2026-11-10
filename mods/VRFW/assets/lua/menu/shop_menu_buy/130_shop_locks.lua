-- VRFW › locked shop rows, menu side.
if VRFW.host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "VRFW.shop_locks_"

  local CMD = {
    LOCK_ON = VRFW.commands.VRFW_SHOP_LOCK_ON,       -- CMND_VRFW_SHOP_LOCK_ON(shop) -> bool
    LOCKED = VRFW.commands.VRFW_SHOP_LOCKED,        -- CMND_VRFW_SHOP_LOCKED(instance) -> locked, row, kind, a, b
    LOCKED_ITEM = VRFW.commands.VRFW_SHOP_LOCKED_ITEM,   -- CMND_VRFW_SHOP_LOCKED_ITEM(item) -> locked, kind, a, b
    SOURCE = VRFW.commands.VRFW_SHOP_LOCK_SOURCE,
    TEXT_GET = VRFW.commands.TEXT_GET,      -- CMND_TEXT_GET(text id) -> text
    LANGUAGE = VRFW.commands.GET_LANGUAGE_CODE,       -- CMND_GET_LANGUAGE_CODE
    PLAY_SE = VRFW.commands.SND_PLAY_SE,
    FOCUS_INSTANCE = 2603265800,
    MATERIAL_COLOR = 801406373,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    LAYER_VISIBLE = VRFW.commands.IS_LAYER_VISIBLE, -- CMND_IS_LAYER_VISIBLE
    SET_LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    SET_OBJECT_VISIBLE = 2171393651,
    GUIDE_SET = 2209673388,
    GUIDE_KEYS = 452337289,
    MESSAGE = 2289627655,
    MESSAGE_WAIT = 2351835063,
  }
  local SE_CANNOT = 2086672038  -- sy0003
  local LIST = 3747827324       -- shop01_02_list_item
  local LIST_BASE = 2569990914  -- shop01_01_list_base
  local BG = 717014739          -- shop01_00_background: its close = the shop is going
  local GREY = 0.5              -- retail grey of a locked special move
  local MATERIAL = 2239373704
  local NAME_NODES = { 931545948, 3705682548, 1059092884, 1230493388 }
  -- detail card layers (retail UpdateSelectItemInfo / ClearNotUseUpdateSelectInfoLayer)
  local DETAIL_LAYERS = {
    3633022365,  -- team00_21_item_detail
    1510257498,  -- team00_21b_item_detail
    2628045944,  -- team02_02_skill_detail_info
    26273556,    -- team00_30_p1_balloon
    3764752959,  -- team00_28_six_sense_detail_info
    3851505884,  -- team03_01_tactics_info
    812096501,   -- team00_35_chara_title_detail_info
    1921826160,  -- team00_40_change_page_guide
    2237891512,  -- team00_40_synergy_change_page_guide
    1492214428,  -- team16_05_synergy_item_detail_shop
    561386529,   -- soccer11_04_chara_stasus
    2129935798,  -- shop01_08_status_plate_attach
  }
  -- keys of the preview / detail that do nothing on a locked row
  local DEAD_KEYS = {
    [2027013857] = true,  -- Details / try on.
    [2870443176] = true,  -- rotate characters
    [3887644467] = true,  -- camera zoom
    [3484753847] = true,  -- camera up / down
    [1456809643] = true,  -- description balloon
  }
  local TX = {
    chapter_title = 1791082148,   -- vrfw_shop_lock_chapter_title
    chapter = 1264032831,         -- vrfw_shop_lock_chapter
    match = 859015253,            -- vrfw_shop_lock_match
    beat_chronicle = 1889241075,  -- vrfw_shop_lock_beat_chronicle
    beat = 3572702074,            -- vrfw_shop_lock_beat
    chronicle = 3455767110,       -- vrfw_shop_lock_chronicle
    later = 2775318297,           -- vrfw_shop_lock_later
    notice = 590314619,           -- vrfw_shop_lock_notice
  }
  local KEY_ENTER, GUIDE_ENTER_A, GUIDE_ENTER_B = 1981080283, 1847312674, 2750714971

  local SL = {}
  VRFW.shop_locks = SL

  local function reset()
    SL.on_by_shop = {}      -- shop id -> rows listed as locked
    SL.phrases = {}         -- "kind:a:b" -> sentence
    SL.focus = -1
    SL.tint = {}            -- instance -> greyed
    SL.detail_hidden = false
    SL.card_visible = {}
    SL.closing = false
  end
  reset()

  local Log = VRFW.logger.new("vrfw.ShopLocks")

  local function L()
    local h = VRFW.host.hosts[STEM]
    return h and h.L or {}
  end
  local function local_of(name)
    local ok, v = pcall(function() return L()[name] end)
    if ok then return v end
    return nil
  end


  -- rows of the open shop are listed as locked
  function SL.on()
    local ok, id = pcall(GetShopId)
    if not ok or type(id) ~= "number" then return false end
    local on = SL.on_by_shop[id]
    if on == nil then
      local r = VRFW.host.command(CMD.LOCK_ON, id)
      on = r == true
      SL.on_by_shop[id] = on
      if on then Log("shop", id, "lists locked rows") end
    end
    return on
  end

  local function text(id)
    local s = VRFW.host.command(CMD.TEXT_GET, id)
    if type(s) == "string" and s ~= "" then return s end
    return nil
  end

  local function fill(id, num, name)
    local s = text(id)
    if s == nil then return nil end
    s = s:gsub("<NUM>", tostring(num or ""))
    s = s:gsub("<NAME>", (tostring(name or ""):gsub("%%", "%%%%")))
    return s
  end

  -- what a locked row waits for, as a sentence in the game's language
  function SL.phrase(kind, a, b)
    local key = tostring(kind) .. ":" .. tostring(a) .. ":" .. tostring(b)
    local s = SL.phrases[key]
    if s ~= nil then return s end
    local code = VRFW.host.command(CMD.LANGUAGE)
    local form, name, num, tid = VRFW.host.command(CMD.SOURCE, kind or 0, a or 0, b or 0, code or -1)
    if form ~= nil then
      local named = type(name) == "string" and name ~= ""
      if form == "text" then
        s = text(tid)
      elseif form == "chapter" then
        s = named and fill(TX.chapter_title, num, name) or fill(TX.chapter, num)
      elseif (form == "match" or form == "beat_chronicle" or form == "beat") and named then
        s = fill(TX[form], num, name)
      elseif form == "chronicle" then
        s = text(TX.chronicle)
      end
    end
    s = s or text(TX.later) or "???"
    SL.phrases[key] = s
    return s
  end

  function SL.instance_info(inst)
    if type(inst) ~= "number" or inst < 0 or not SL.on() then return false end
    local locked, row, kind, a, b = VRFW.host.command(CMD.LOCKED, inst)
    if locked == nil then return false end
    return locked == true, kind, a, b, row
  end

  function SL.item_info(item)
    if type(item) ~= "number" or item == 0 or not SL.on() then return false end
    local locked, kind, a, b = VRFW.host.command(CMD.LOCKED_ITEM, item)
    if locked == true then return true, kind, a, b end
    return false
  end

  local function focus_instance()
    local inst = VRFW.host.menu_command(CMD.FOCUS_INSTANCE, LIST)
    if type(inst) == "number" and inst >= 0 then return inst end
    return SL.focus
  end

  function SL.focus_info(item)
    if not SL.on() then return false end
    local l, kind, a, b, row = SL.instance_info(focus_instance())
    if type(row) == "number" and row ~= 0 then return l, kind, a, b end
    if type(item) ~= "number" then
      local ok, it = pcall(GetShopListItemInfo, 0)
      item = ok and it or nil
    end
    return SL.item_info(item)
  end

  -- the focused row of the list (not the token / coin pickers) is locked
  function SL.focus_list(item)
    if not SL.on() then return false end
    if local_of("flag") == true or local_of("flag10") == true then return false end
    return (SL.focus_info(item)) == true
  end

  function SL.grey_row(layer, inst, on)
    local f = on and GREY or 1
    VRFW.host.menu_command(CMD.MATERIAL_COLOR, layer, inst, MATERIAL, f, f, f)
    SL.tint[inst] = on or nil
  end

  -- the detail card on the right goes while a locked row has the focus
  local function hide_detail()
    local n24, n28 = local_of("n24"), local_of("n28")
    local cards = { 3633022365, 1510257498 }
    if type(n28) == "number" and n28 ~= 0 then table.insert(cards, 1, n28) end
    if not SL.detail_hidden then
      SL.card_visible = {}
      for _, l in ipairs(cards) do
        local vis = VRFW.host.menu_command(CMD.LAYER_VISIBLE, l, 0)
        if vis == true then SL.card_visible[l] = true end
      end
      if type(n24) == "number" and n24 ~= 0 then
        local vis = VRFW.host.menu_command(CMD.LAYER_VISIBLE, n24, 0)
        if vis == true then SL.card_visible[n24] = true end
      end
    end
    SL.detail_hidden = true
    for _, l in ipairs(cards) do VRFW.host.menu_command(CMD.SET_LAYER_VISIBLE, l, 0, false) end
    if type(n24) == "number" and n24 ~= 0 then VRFW.host.menu_command(CMD.SET_LAYER_VISIBLE, n24, 0, false) end
    for _, l in ipairs(DETAIL_LAYERS) do VRFW.host.menu_command(CMD.SET_LAYER_VISIBLE, l, 0, false) end
    pcall(SetVisibleAllAuraDetailInfo, false)
    pcall(SetHideSynergyDetail)
    VRFW.host.menu_command(CMD.SET_OBJECT_VISIBLE, 2394257302 --[[shop01_10_body_type_item]], false)
    VRFW.host.menu_command(CMD.SET_OBJECT_VISIBLE, 858725131 --[[mainmenu01_08_chara_3d_shadow]], false)
    pcall(function() funcLuaMenuCommand(CMD.SET_LAYER_VISIBLE, GetShopHomeAwayLayerName(), 0, false) end)
    for i = 0, 3 do pcall(SetCharaModelVisible, i, false) end
  end

  local function show_detail(kind_of_item)
    if not SL.detail_hidden then return end
    SL.detail_hidden = false
    if kind_of_item == 80 or kind_of_item == 140 then return end
    local n24 = local_of("n24")
    if type(n24) == "number" and SL.card_visible[n24] then VRFW.host.menu_command(CMD.SET_LAYER_VISIBLE, n24, 0, true) end
  end

  local function closing() return SL.closing == true end

  local function on(point, phase, fn, create)
    VRFW.host.on(STEM, point, { id = ID .. point, phase = phase, fn = fn, create = create })
  end

  on("OnShopInit", "before", function(...)
    reset()
  end)

  on("OnCloseLayer", "before", function(a1, ...)
    if a1 == BG then SL.closing = true end
  end, true)

  on("FinalizeMenu", "before", function(...)
    SL.closing = true
  end, true)

  on("SetupGrayout", "around", function(nxt, a1, a2, a3)
    if a1 ~= LIST then return nxt(a1, a2, a3) end
    local locked, kind, pa, pb = SL.instance_info(a2)
    if locked then
      nxt(a1, a2, GREY)
      SL.grey_row(a1, a2, true)
      local s = SL.phrase(kind, pa, pb)
      for _, node in ipairs(NAME_NODES) do VRFW.host.menu_command(CMD.SET_TEXT, a1, node, s, a2) end
      return
    end
    if SL.tint[a2] then SL.grey_row(a1, a2, false) end
    return nxt(a1, a2, a3)
  end)

  on("OnChangeFocus", "before", function(a1, a2)
    if a1 == LIST then
      local inst = VRFW.host.menu_command(CMD.FOCUS_INSTANCE, a1)
      if type(inst) == "number" then SL.focus = inst end
    end
  end)

  on("UpdateSelectItemInfo", "after", function(r, a1, a2, a3, ...)
    if closing() or not SL.on() then return end
    local was = SL.detail_hidden
    if SL.focus_list(a2) then
      hide_detail()
      pcall(ResetCharaModelAll)
    else
      show_detail(a3)
      if was and (a3 == 80 or a3 == 140) then pcall(ChangeUniformModelView, local_of("flag4"), true) end
    end
    if was ~= SL.detail_hidden then pcall(UpdateButtonGuide, true) end
  end)

  on("OnFunction", "around", function(nxt, a1, a2, ...)
    if DEAD_KEYS[a1] and SL.focus_list() then return end
    local r = table.pack(nxt(a1, a2, ...))
    if SL.detail_hidden and not closing() and SL.focus_list() then hide_detail() end
    return table.unpack(r, 1, r.n)
  end)

  on("OnEnter", "around", function(nxt, a1, a2)
    if a1 == LIST_BASE then
      local locked, kind, pa, pb = SL.focus_info()
      if locked then
        VRFW.host.command(CMD.PLAY_SE, SE_CANNOT)
        local phrase = SL.phrase(kind, pa, pb)
        local msg = text(TX.notice)
        msg = msg and msg:gsub("<TEXT>", (phrase:gsub("%%", "%%%%"))) or phrase
        local okw = type(GENERAL_WINDOW) == "table" and type(GENERAL_WINDOW.ReserveGeneralWindow) == "function"
          and pcall(GENERAL_WINDOW.ReserveGeneralWindow, "", "", "", msg, 0)
        if not okw then
          VRFW.host.command(CMD.MESSAGE, msg, 0, 0, 0, 0, 0, false)
          VRFW.host.command(CMD.MESSAGE_WAIT, 1, 0)
        end
        return 1
      end
    end
    return nxt(a1, a2)
  end)

  on("CheckSufficientFunds", "around", function(nxt, a1, ...)
    if SL.on() and (SL.focus_info()) == true then return false end
    return nxt(a1, ...)
  end)

  -- no kit preview (4 characters wearing it) for a locked row
  on("ChangeCharaModels", "around", function(nxt, a1, ...)
    if closing() then return end
    if a1 ~= nil and a1 ~= 0 and SL.focus_list(a1) then
      pcall(ResetCharaModelAll)
      return
    end
    return nxt(a1, ...)
  end)

  on("ChangeUniformModelInfoVisible", "around", function(nxt, a1, a2, ...)
    if a1 == true and SL.focus_list() then a1 = false end
    return nxt(a1, a2, ...)
  end)

  on("UpdateButtonGuide", "around", function(nxt, a1, a2, ...)
    if a1 and SL.focus_list() then
      local layer, base, line = local_of("n"), 1138543975 --[[mainmenu01_06_base_button_guide]], 9396745 --[[mainmenu01_07_button_guide]]
      if local_of("flag3") == true then
        layer, base, line = 3170360552 --[[shop_menu]], 2062970623 --[[shopmenu01_06_base_button_guide]], 362164101 --[[shopmenu01_07_button_guide]]
      end
      local ok = pcall(function()
        funcLuaMenuCommand(CMD.GUIDE_SET, layer, base, { GUIDE_ENTER_A }, { GUIDE_ENTER_B }, { 0 }, { 0 }, { 0 }, true, false, false, 0, line)
        funcLuaMenuCommand(CMD.GUIDE_KEYS, layer, base, { KEY_ENTER })
      end)
      if ok then return end
    end
    return nxt(a1, a2, ...)
  end)
end
