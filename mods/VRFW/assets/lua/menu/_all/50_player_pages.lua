-- lua_patch.scope: used
-- menu_engine: the player page's page registry, VRFW.PlayerPages (VRFW base feature).
if VRFW.player_pages == nil then
  local P = {
    SND = VRFW.commands.SND_PLAY_SE,            -- CMND_SND_PLAY_SE (the retail page step sound)
    SE_STEP = 2629173176,        -- sy0009
    ANIME = VRFW.commands.PLAY_ANIME_TYPE,          -- CMND_PLAY_ANIME_TYPE
    L_STATUS = 730911947,        -- soccer11_05_formation_status_base
    ANIM_NEXT = 3183130249,      -- the retail page-step animations of the status base
    ANIM_PREV = 1203080170,
    ANIM_GROUP = 3627544126,
    K_LEFT = 2053629800,
    K_RIGHT = 3033167124,
    RETAIL = {
      {name = "vrfw.Moves", index = 0, type = 1},
      {name = "vrfw.Equipment", index = 1, type = 0},
      {name = "vrfw.TeamPassives", index = 2, type = 2, foreign = false},
      {name = "vrfw.SixthSense", index = 3, type = 3, foreign = false},
    },
    decls = {},                  -- name -> declaration
    conditions = {},
    step_listeners = {},         -- P.on_step functions
    list = nil,                 -- resolved order (declarations), nil = resolve at the next use
    by_index = nil,
    wrapped = {},
  }
  VRFW.player_pages = P

  local logger
  --- Logs through the player-pages logger.
  function P.log(...)
    logger = logger or VRFW.logger.new("vrfw.PlayerPages")
    logger(...)
  end

  --- a mod's page (see the header); a second add with the same name replaces the first; answers true, or false, why.
  function P.add(d)
    if type(d) ~= "table" or type(d.name) ~= "string" or type(d.index) ~= "number" or type(d.type) ~= "number" then
      return false, "a page needs a name, an index and a type"
    end
    P.decls[d.name] = d
    P.list = nil
    return true
  end

  --- Sets the function that decides when page `name` shows; answers true, or false, why.
  function P.show_when(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then
      return false, "a page name and a function expected"
    end
    local list = P.conditions[name] or {}
    list[#list + 1] = fn
    P.conditions[name] = list
    return true
  end

  --- The resolved page list (built once).
  function P.resolve()
    if P.list ~= nil then
      return P.list
    end
    local list, byIndex = {}, {}
    for _, r in ipairs(P.RETAIL) do
      list[#list + 1] = r
    end
    local pend, last = {}, {}
    for _, d in pairs(P.decls) do
      if d.last then
        last[#last + 1] = d
      else
        pend[#pend + 1] = d
      end
    end
    local byName = function(a, b) return a.name < b.name end
    table.sort(pend, byName)
    table.sort(last, byName)
    local function pos(name)
      for i, e in ipairs(list) do
        if e.name == name then
          return i
        end
      end
      return nil
    end
    local firsts = 0
    local moved = true
    while moved and #pend > 0 do
      moved = false
      local rest = {}
      for _, d in ipairs(pend) do
        local a, b = d.after ~= nil and pos(d.after) or nil, d.before ~= nil and pos(d.before) or nil
        if d.first then
          firsts = firsts + 1
          table.insert(list, firsts, d)
          moved = true
        elseif a ~= nil then
          table.insert(list, a + 1, d)
          moved = true
        elseif b ~= nil then
          table.insert(list, b, d)
          moved = true
        else
          rest[#rest + 1] = d
        end
      end
      pend = rest
    end
    for _, d in ipairs(pend) do
      P.log("page " .. d.name .. ": anchor " .. tostring(d.after or d.before) .. " not declared: placed at the end")
      list[#list + 1] = d
    end
    for _, d in ipairs(last) do
      list[#list + 1] = d
    end
    local out = {}
    for _, d in ipairs(list) do
      if byIndex[d.index] == nil then
        byIndex[d.index] = d
        out[#out + 1] = d
      else
        P.log("page " .. d.name .. ": index " .. d.index .. " already taken by " .. byIndex[d.index].name .. ": left out")
      end
    end
    P.list, P.by_index = out, byIndex
    return out
  end

  --- The team editor shows a team that is not one of the player's (lua\_all\81_team_editor.lua).
  function P.foreign_team()
    local editor = VRFW.team_editor
    if type(editor) ~= "table" or type(editor.foreign) ~= "function" then
      return false
    end
    local ok, v = pcall(editor.foreign)
    return ok and v ~= nil
  end

  --- True when page d is removed on this screen.
  function P.removed(d)
    if d.foreign == false and P.foreign_team() then
      return true
    end
    for _, fn in ipairs(P.conditions[d.name] or {}) do
      local ok, v = pcall(fn)
      if ok and v == false then
        return true
      end
    end
    return false
  end

  --- True when page d is shown.
  function P.on(d)
    if type(d.enabled) == "function" then
      local ok, v = pcall(d.enabled)
      if ok and v == false then
        return false
      end
    end
    return not P.removed(d)
  end

  --- The shown pages' indices in order; `count` = only indices below it (a screen whose page table has `count` rows).
  function P.order(count)
    local o = {}
    for _, d in ipairs(P.resolve()) do
      if (count == nil or d.index < count) and P.on(d) then
        o[#o + 1] = d.index
      end
    end
    return o
  end

  --- Page index -> page type (nil = no such page).
  function P.type(index)
    P.resolve()
    local d = P.by_index[index]
    return d ~= nil and d.type or nil
  end

  --- The slot of each page, by index.
  function P.slots()
    local m, slot = {}, 0
    for _, d in ipairs(P.resolve()) do
      if not P.removed(d) then
        slot = slot + 1
        if P.on(d) then
          m[slot] = d.index
        end
      end
    end
    return m
  end
  --- The slot of the first page of type t; nil when there is none.
  function P.slot_of_type(t)
    local slot = 0
    for _, d in ipairs(P.resolve()) do
      if not P.removed(d) then
        slot = slot + 1
        if d.type == t then
          return slot
        end
      end
    end
    return nil
  end

  --- a pointer click: the next Step answers `index` once (nil = clear).
  function P.go_to(index)
    P.target = index
  end

  --- Marks the page dots of this plate as drawn by the mod `owner`, so the framework leaves them alone.
  function P.set_dots_owner(owner)
    P.dots_owner = owner
  end

  --- Marks the page_change of every declaration as chained by the plate of the mod `owner`, so a page does not wrap the page change itself.
  function P.set_page_change_owner(owner)
    P.page_change_owner = owner
  end

  --- a mod's `fn(next, order)`, run after every step with the page it lands on and the shown order; answers true, or false, why.
  function P.on_step(fn)
    if type(fn) ~= "function" then
      return false, "a function expected"
    end
    P.step_listeners[#P.step_listeners + 1] = fn
    return true
  end

  --- The page after `cur` in direction dir (+1 E / -1 Q), wrapping; `count` as in Order.
  function P.step(cur, dir, count)
    local o = P.order(count)
    local nxt = P.next_page(cur, dir, o)
    for _, fn in ipairs(P.step_listeners) do
      pcall(fn, nxt, o)
    end
    return nxt
  end

  --- The page after `cur` in direction dir within the order `o`.
  function P.next_page(cur, dir, o)
    local t = P.target
    P.target = nil
    if type(t) == "number" then
      for _, v in ipairs(o) do
        if v == t then
          return t
        end
      end
    end
    if #o == 0 then
      return cur or 0
    end
    local k = 0
    for i, v in ipairs(o) do
      if v == cur then
        k = i
      end
    end
    if k == 0 then
      k = dir < 0 and #o or 1
    else
      k = k + dir
    end
    if k > #o then
      k = 1
    elseif k < 1 then
      k = #o
    end
    return o[k]
  end

  local function Wrap(name, make)
    local cur = _ENV[name]
    if type(cur) ~= "function" or P.wrapped[cur] then
      return false
    end
    local w = make(cur)
    P.wrapped[w] = true
    _ENV[name] = w
    return true
  end

  --- Wraps the retail plate page functions so the added pages work.
  function P.attach()
    Wrap("GetPersonalPlatePageType", function(orig)
      return function(a1, ...)
        local t = type(a1) == "number" and a1 > 3 and P.type(a1) or nil
        if t ~= nil then
          return t
        end
        return orig(a1, ...)
      end
    end)
    Wrap("ChangePageInfo", function(orig)
      return function(a1, ...)
        if P.force ~= nil then
          a1 = P.force
          P.force = nil
        end
        return orig(a1, ...)
      end
    end)
    Wrap("OnFunctionCommonLeftAndRight", function(orig)
      return function(a1, a2, a3, ...)
        if a1 ~= P.K_LEFT and a1 ~= P.K_RIGHT then
          return orig(a1, a2, a3, ...)
        end
        local cur = a3
        if type(cur) ~= "number" then
          cur = type(GetNowPageIdx) == "function" and GetNowPageIdx() or 0
        end
        P.force = P.step(cur, a1 == P.K_RIGHT and 1 or -1)
        local inrange = cur
        if inrange < 0 or inrange > 3 then
          inrange = 0
        end
        local ok, r = pcall(orig, a1, a2, inrange, ...)
        P.force = nil
        if not ok then
          error(r, 0)
        end
        return r
      end
    end)
    -- the plate's own next / previous page (retail: +-1 over 0..3), with the retail guards, sound and animation
    local function Shift(dir)
      if type(IsChangeMemberMode) == "function" and IsChangeMemberMode() then
        return
      end
      if type(IsShownDetailInfo) == "function" and IsShownDetailInfo() then
        return
      end
      funcLuaCommand(P.SND, P.SE_STEP)
      local nxt = P.step(GetNowPageIdx(), dir)
      ChangePersonalPlatePageByCharaHdl(GetTargetCharacterStatusHandle(), GetPersonalPlatePageType(nxt))
      SetNowPageIdx(nxt)
      funcLuaMenuCommand(P.ANIME, P.L_STATUS, 0, dir > 0 and P.ANIM_NEXT or P.ANIM_PREV, 0, P.ANIM_GROUP)
    end
    if type(ChangePersonalPlatePageByCharaHdl) == "function" and type(SetNowPageIdx) == "function" then
      Wrap("SetPersonalPlateNextPage", function(orig)
        return function()
          return Shift(1)
        end
      end)
      Wrap("SetPersonalPlatePrevPage", function(orig)
        return function()
          return Shift(-1)
        end
      end)
    end
  end
end
