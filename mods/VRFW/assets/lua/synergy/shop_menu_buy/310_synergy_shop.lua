if VRFW.host ~= nil then
  local STEM = "shop_menu_buy"
  local DETAIL = 1492214428              -- team16_05_synergy_item_detail_shop
  local UPDATE = VRFW.commands.UPDATE_SYNERGY_DETAIL              -- (layer, instance, item, team, page, b, b)
  local NO_TEAM = 255
  local ITEM_PARAM = VRFW.commands.GET_ITEM_PARAM          -- (item, 2) -> its category (230 = a synergy)
  local SYNERGY_CATEGORY = 230
  local PAGE_FUNCTION = 3757123912       -- OnFunction argument of the members / effects page switch
  local SWITCH = VRFW.commands.VRFW_SYNERGY_SHOP_CONDITIONS
  local RULES = { checks = false, detail = DETAIL, hide_undrawn = true }
  local on = nil                         -- the switch, asked at the first draw of a shop

  local function L()
    local h = VRFW.host.hosts ~= nil and VRFW.host.hosts[STEM] or nil
    return h ~= nil and h.L or nil
  end

  local function enabled()
    if on == nil then
      local v = VRFW.host.command(SWITCH, DETAIL)   -- (on: the framework draws this detail with no team)
      on = not (v == false)
    end
    return on
  end

  local function is_synergy(item)
    local cat = VRFW.host.command(ITEM_PARAM, item, 2)
    return cat == SYNERGY_CATEGORY
  end

  -- the extra pieces of the condition rows off (another item, the effects page)
  local function hide_extras()
    local S = VRFW.synergy
    if S ~= nil and S.hide_extras ~= nil then
      pcall(S.hide_extras)
    end
  end

  local function redraw(item, page)
    if not enabled() or type(item) ~= "number" or item == 0 or not is_synergy(item) then
      hide_extras()
      return
    end
    page = type(page) == "number" and page or 0
    VRFW.host.menu_command(UPDATE, DETAIL, 0, item, NO_TEAM, page, true, false)
    if page ~= 0 then
      hide_extras()
      return
    end
    local S = VRFW.synergy
    if S ~= nil and S.apply_panel ~= nil then
      pcall(S.apply_panel, item, RULES)
    end
  end

  local function page()
    local l = L()
    local ok, p = pcall(function() return l.n30 end)
    return ok and p or 0
  end

  VRFW.host.on(STEM, "UpdateSelectItemInfo", {
    id = "menu_engine.synergy_shop_register", phase = "before",
    fn = function(a1, a2, a3)
      if a3 == SYNERGY_CATEGORY then enabled() end
    end,
  })

  -- a synergy item focused: the game drew its panel (category 230 = the third argument)
  VRFW.host.on(STEM, "UpdateSelectItemInfo", {
    id = "menu_engine.synergy_shop", phase = "after",
    fn = function(r, a1, a2, a3)
      if a3 == SYNERGY_CATEGORY then
        redraw(a2, page())
      else
        hide_extras()
      end
    end,
  })

  -- the members / effects page switch ("And Effects"): the game drew the other page
  VRFW.host.on(STEM, "OnFunction", {
    id = "menu_engine.synergy_shop", phase = "after",
    fn = function(r, a1)
      if a1 ~= PAGE_FUNCTION then
        return
      end
      -- the game switches the page only while the panel shows (not its usage balloon)
      local okb, balloon = pcall(function() return DETAIL_WINDOW.IsNowBalloonTypeUsage() end)
      if okb and balloon == true then
        return
      end
      local l = L()
      local ok, item = pcall(function() return l.n8 end)
      if ok then
        redraw(item, page())
      end
    end,
  })

  -- the synergy rows' extra layers: an instance built is placed and shown (no per-frame code)
  VRFW.host.on(STEM, "OnOpenLayer", {
    id = "menu_engine.synergy_shop", phase = "after",
    fn = function(r, a1, a2)
      local S = VRFW.synergy
      if S ~= nil and S.built ~= nil then
        pcall(S.built, a1, a2)
      end
    end,
  })
end
