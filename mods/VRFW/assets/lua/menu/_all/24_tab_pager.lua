-- lua_patch.scope: used
if VRFW.tab_pager == nil then
  local TP = {
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,   -- CMND_SET_LAYER_VISIBLE (layer, instance, on)
    FOCUS_COUNT = 3252599449,               -- (layer, count): the instances the focus may reach
    FOCUS_SET = 1778826357,                 -- (layer, instance, on): the focus moves there
    FOCUSED = 2603265800,                   -- (layer) -> the focused instance
    HAS_FOCUS = 102308320,                  -- (layer) -> the layer has the control focus
    PLAY_ANIME = VRFW.commands.PLAY_ANIME_TYPE,
    ANIME_FOCUS = 2734777837,               -- Focus: the tab's selected look
    ANIME_SET_BUTTON = 973515837,           -- button
  }
  --- Internal: metatable index of a tab pager object.
  TP.__index = TP

  --- Internal: A tab pager for spec, on page 1.
  function TP.new(spec)
    local p = setmetatable({spec = spec, page = 1, slot = nil, turning = false, rebuilt = false}, TP)
    spec.pinned = math.max(0, math.min(spec.pinned or 0, (spec.per_page or 1) - 1))
    return p
  end

  local logger
  --- Internal: Logs the arguments with this pager's tag.
  function TP:log(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    logger = logger or VRFW.logger.new("VRFW tab_pager")
    logger(tostring(self.spec.name) .. " " .. table.concat(parts, " "))
  end

  --- Internal: The number of pages.
  function TP:pages()
    local s = self.spec
    local total, per = #s.entries, s.per_page or 0
    if per <= 0 or total <= per then
      return 1
    end
    return 1 + math.ceil((total - per) / (per - s.pinned))
  end

  --- Internal: The tabs of page p in slot order.
  function TP:list(p)
    local s = self.spec
    local out = {}
    if p <= 1 or self:pages() <= 1 then
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

  --- Internal: Page 1 in the screen's table, without drawing (the screen opening).
  function TP:reset()
    self.page, self.slot = 1, nil
    self.spec.show(self:list(1))
  end

  --- Internal: Shows page p and focuses `slot`; `rebuild` asks the screen to rebuild its bar.
  function TP:show(p, slot, rebuild)
    local s = self.spec
    local list = self:list(p)
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
    self:log("page", p, "of", self:pages(), "slots", n, "focus", slot)
  end

  --- Advanced: Moves the focus to `slot`, turning the page at the edge slots; answers true when it turned.
  function TP:focus(slot)
    if self.turning then
      self.rebuilt = true
      self.slot = slot
      return false
    end
    local prev = self.slot
    self.slot = slot
    local pages = self:pages()
    if pages <= 1 or type(slot) ~= "number" or type(prev) ~= "number" then
      return false
    end
    local n = #self:list(self.page)
    if n < 3 then
      return false
    end
    local ok, has = pcall(funcLuaMenuCommand, TP.HAS_FOCUS, self.spec.layer)
    if ok and has == false then
      return false
    end
    if prev == n - 1 and slot == 0 then
      self:show(self.page % pages + 1, self.spec.pinned, true)
      return true
    elseif prev == 0 and slot == n - 1 then
      local p = (self.page - 2) % pages + 1
      self:show(p, #self:list(p) - 1, true)
      return true
    end
    return false
  end

  --- Advanced: Namespace of the tab pager: pages a long tab list into screens of tabs.
  VRFW.tab_pager = TP
end
