-- VRFW › the shop's synergy panel (the Mercado's detail of a synergy item, team16_05_synergy_item_detail_shop) as the
-- synergy screen's condition card with no team. The game draws it with CMND_UPDATE_SYNERGY_DETAIL (layer, 0,
-- item, team, page, ...) and team 2, so its rows showed the active squad's members. After each of the game's draws
-- (UpdateSelectItemInfo for a synergy item, the members / effects page switch of OnFunction) the panel is drawn again
-- with no team (255: the engine reads no team for any value from 16 up, the synergy screen's own "none"): every
-- condition unfulfilled. The rows are then filled by the shared panel fill (VRFW_Synergy.ApplyPanel,
-- lua\synergy\_all\30_synergy_rows.lua) with this menu's rule: no check box on any row (with no
-- team a box only ever shows empty); a synergy declared by a mod gets the shop's row look (one row per requirement).
-- The game's arguments are never changed: the second draw comes after the game's own. The effects page (page 1) and
-- any other item: the rows' extra pieces hidden.
-- Switch: config.toml [shop] synergy_conditions (CMND_VRFW_SYNERGY_SHOP_CONDITIONS(detail layer), asked once per
-- shop; on, the framework's rows hook draws this detail with no team for every draw, the game's own team-2 draw
-- too: nothing of the active team shows); false = the game's panel. No engine call at load time.
if VRFW_Host ~= nil then
  local STEM = "shop_menu_buy"
  local DETAIL = 1492214428              -- team16_05_synergy_item_detail_shop
  local UPDATE = VRFW_Cmd.UPDATE_SYNERGY_DETAIL              -- (layer, instance, item, team, page, b, b)
  local NO_TEAM = 255
  local ITEM_PARAM = VRFW_Cmd.GET_ITEM_PARAM          -- (item, 2) -> its category (230 = a synergy)
  local SYNERGY_CATEGORY = 230
  local PAGE_FUNCTION = 3757123912       -- OnFunction argument of the members / effects page switch
  local SWITCH = VRFW_Cmd.VRFW_SYNERGY_SHOP_CONDITIONS
  -- the shared fill's rules for this panel: its own detail layer, no check box, and every game row the framework did not
  -- draw this time hidden (the shop's builder keeps a row it skips on screen with its last name, face, check and series)
  local RULES = { checks = false, detail = DETAIL, hide_undrawn = true }
  local on = nil                         -- the switch, asked at the first draw of a shop

  local function L()
    local h = VRFW_Host.hosts ~= nil and VRFW_Host.hosts[STEM] or nil
    return h ~= nil and h.L or nil
  end

  local function enabled()
    if on == nil then
      local ok, v = pcall(funcLuaCommand, SWITCH, DETAIL)   -- (on: the framework draws this detail with no team)
      on = not (ok and v == false)
    end
    return on
  end

  local function is_synergy(item)
    local ok, cat = pcall(funcLuaCommand, ITEM_PARAM, item, 2)
    return ok and cat == SYNERGY_CATEGORY
  end

  -- the extra pieces of the condition rows off (another item, the effects page)
  local function hide_extras()
    local S = VRFW_Synergy
    if S ~= nil and S.HideExtras ~= nil then
      pcall(S.HideExtras)
    end
  end

  -- the panel of `item` on `page` again, with no team; on the conditions page (0) filled by the shared panel fill; the
  -- effects page (1) shows the effect texts only: no crest, miniface or icon of the rows
  local function redraw(item, page)
    if not enabled() or type(item) ~= "number" or item == 0 or not is_synergy(item) then
      hide_extras()
      return
    end
    page = type(page) == "number" and page or 0
    pcall(funcLuaMenuCommand, UPDATE, DETAIL, 0, item, NO_TEAM, page, true, false)
    if page ~= 0 then
      hide_extras()
      return
    end
    local S = VRFW_Synergy
    if S ~= nil and S.ApplyPanel ~= nil then
      pcall(S.ApplyPanel, item, RULES)
    end
  end

  local function page()
    local l = L()
    local ok, p = pcall(function() return l.n30 end)
    return ok and p or 0
  end

  -- a synergy item about to be drawn: the detail layer registered as a no-team panel before the game's own draw (team 2),
  -- so even the first card of a session never gets the active team's members as rows
  VRFW_Host.on(STEM, "UpdateSelectItemInfo", {
    id = "menu_engine.synergy_shop_register", phase = "before",
    fn = function(a1, a2, a3)
      if a3 == SYNERGY_CATEGORY then enabled() end
    end,
  })

  -- a synergy item focused: the game drew its panel (category 230 = the third argument)
  VRFW_Host.on(STEM, "UpdateSelectItemInfo", {
    id = "menu_engine.synergy_shop", phase = "after",
    fn = function(r, a1, a2, a3)
      if a3 == SYNERGY_CATEGORY then
        redraw(a2, page())
      else
        hide_extras()
      end
    end,
  })

  -- the members / effects page switch («Y Efectos»): the game drew the other page
  VRFW_Host.on(STEM, "OnFunction", {
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
  VRFW_Host.on(STEM, "OnOpenLayer", {
    id = "menu_engine.synergy_shop", phase = "after",
    fn = function(r, a1, a2)
      local S = VRFW_Synergy
      if S ~= nil and S.Built ~= nil then
        pcall(S.Built, a1, a2)
      end
    end,
  })
end
