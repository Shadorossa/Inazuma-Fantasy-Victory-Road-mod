-- menu_engine: VRFW_TabPager, pages of a screen tab bar whose tabs are a Lua table of the screen (docs/framework/card-filter.md
-- §13). One mechanism for every such bar; the screens differ only by their rules (tabs per page, pinned tabs) and by
-- four callbacks. Page 1 = the first `per_page` tabs; a later page = the `pinned` first tabs + the next tabs. L1 / R1
-- (the bar's own focus moves) walk through every tab: a wrap from the last slot to the first turns to the next page,
-- from the first slot to the last to the previous one. Needs at least 3 tabs on every page (pinned + own).
--   local pager = VRFW_TabPager.New{
--     name = "chara_bank_menu", layer = <tab item layer crc>, per_page = 11, pinned = 2, entries = {...all tabs...},
--     show = function(list) end,          -- the screen's tab table now holds `list` (the page's tabs, in slot order)
--     icon = function(slot, entry) end,   -- instance `slot` draws `entry`
--     bar = function(n) end,              -- the bar's layout for n tabs
--     changed = function() end,           -- the screen rebuilds for the focused tab (its tab-change handler)
--   }
--   pager:Pages() / pager:List(p) / pager:Reset() (page 1, table only) / pager:Show(p, slot, rebuild)
--   pager:Focus(slot) -> true when the focus move was a wrap and the page turned (the caller skips the screen's own handler)
-- The free-match section pages (soccer_vs_cpu_list_menu/100_free_match_tabs.lua) keep their own native tab index map.
-- No engine call at load time.
if VRFW_TabPager == nil then
  local TP = {
    VISIBLE = VRFW_Cmd.SET_LAYER_VISIBLE,   -- CMND_SET_LAYER_VISIBLE (layer, instance, on)
    FOCUS_COUNT = 3252599449,               -- (layer, count): the instances the focus may reach
    FOCUS_SET = 1778826357,                 -- (layer, instance, on): the focus moves there
    FOCUSED = 2603265800,                   -- (layer) -> the focused instance
    HAS_FOCUS = 102308320,                  -- (layer) -> the layer has the control focus
    PLAY_ANIME = VRFW_Cmd.PLAY_ANIME_TYPE,  -- CMND_PLAY_ANIME_TYPE (layer, instance, type, 0 in / 2 out, set)
    ANIME_FOCUS = 2734777837,               -- Focus: the tab's selected look
    ANIME_SET_BUTTON = 973515837,           -- button
    LOG = VRFW_Cmd.EVT_LOG,
  }
  TP.__index = TP

  function TP.New(spec)
    local p = setmetatable({spec = spec, page = 1, slot = nil, turning = false, rebuilt = false}, TP)
    spec.pinned = math.max(0, math.min(spec.pinned or 0, (spec.per_page or 1) - 1))
    return p
  end

  function TP:Log(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    pcall(funcLuaCommand, TP.LOG, "VRFW tab_pager " .. tostring(self.spec.name) .. " " .. table.concat(parts, " "))
  end

  function TP:Pages()
    local s = self.spec
    local total, per = #s.entries, s.per_page or 0
    if per <= 0 or total <= per then
      return 1
    end
    return 1 + math.ceil((total - per) / (per - s.pinned))
  end

  -- the tabs of page p in slot order
  function TP:List(p)
    local s = self.spec
    local out = {}
    if p <= 1 or self:Pages() <= 1 then
      for i = 1, math.min(#s.entries, s.per_page > 0 and s.per_page or #s.entries) do
        out[#out + 1] = s.entries[i]
      end
      return out
    end
    for i = 1, s.pinned do
      out[#out + 1] = s.entries[i]
    end
    local own = s.per_page - s.pinned
    local first = s.per_page + (p - 2) * own
    for i = first + 1, math.min(#s.entries, first + own) do
      out[#out + 1] = s.entries[i]
    end
    return out
  end

  -- page 1 in the screen's table, without drawing (the screen opening)
  function TP:Reset()
    self.page, self.slot = 1, nil
    self.spec.show(self:List(1))
  end

  -- show page p with the focus on `slot`; rebuild = the screen rebuilds for that tab
  function TP:Show(p, slot, rebuild)
    local s = self.spec
    local list = self:List(p)
    local n = #list
    slot = math.max(0, math.min(slot or 0, n - 1))
    self.page = p
    s.show(list)
    for k = 0, s.per_page - 1 do
      pcall(funcLuaMenuCommand, TP.VISIBLE, s.layer, k, k < n)
      if k < n then
        s.icon(k, list[k + 1])
      end
    end
    pcall(s.bar, n)
    pcall(funcLuaMenuCommand, TP.FOCUS_COUNT, s.layer, n, 0, false)
    self.slot, self.turning, self.rebuilt = slot, true, false
    pcall(funcLuaMenuCommand, TP.FOCUS_SET, s.layer, slot, true)
    self.turning = false
    for k = 0, n - 1 do
      pcall(funcLuaMenuCommand, TP.PLAY_ANIME, s.layer, k, TP.ANIME_FOCUS, k == slot and 0 or 2, TP.ANIME_SET_BUTTON)
    end
    if rebuild and not self.rebuilt then
      s.changed()
    end
    self:Log("page", p, "of", self:Pages(), "slots", n, "focus", slot)
  end

  -- the bar's focus moved to `slot` (the screen's focus-change callback): a wrap turns the page
  function TP:Focus(slot)
    if self.turning then
      self.rebuilt = true
      self.slot = slot
      return false
    end
    local prev = self.slot
    self.slot = slot
    local pages = self:Pages()
    if pages <= 1 or type(slot) ~= "number" or type(prev) ~= "number" then
      return false
    end
    local n = #self:List(self.page)
    if n < 3 then
      return false
    end
    local ok, has = pcall(funcLuaMenuCommand, TP.HAS_FOCUS, self.spec.layer)
    if ok and has == false then
      return false
    end
    if prev == n - 1 and slot == 0 then
      self:Show(self.page % pages + 1, self.spec.pinned, true)
      return true
    elseif prev == 0 and slot == n - 1 then
      local p = (self.page - 2) % pages + 1
      self:Show(p, #self:List(p) - 1, true)
      return true
    end
    return false
  end

  VRFW_TabPager = TP
end
