-- lua_patch.scope: used
if VRFW.card_filter == nil then
  local CF = {
    CMD_ENTER = VRFW.commands.VRFW_CARD_FILTER_ENTER,
    CMD_NEXT = VRFW.commands.VRFW_CARD_FILTER_NEXT,     -- CMND_VRFW_CARD_FILTER_NEXT(dir) -> value
    CMD_LABEL = VRFW.commands.VRFW_CARD_FILTER_LABEL,
    CMD_ALIVE = VRFW.commands.VRFW_CARD_FILTER_ALIVE,    -- CMND_VRFW_CARD_FILTER_ALIVE() -> rebuild?
    CMD_LEAVE = VRFW.commands.VRFW_CARD_FILTER_LEAVE,   -- CMND_VRFW_CARD_FILTER_LEAVE(stem) -> bank screens still open
    CMD_GET = VRFW.commands.VRFW_CARD_FILTER_GET,     -- CMND_VRFW_CARD_FILTER_GET() -> value chosen
    TX_ALL = 3288464882,      -- text row vrfw_card_filter_all (All)
    TX_HEADER = 2923353700,   -- text row vrfw_card_filter_header ("<L2> ‹ %s › <R2>")
    TX_TIER = 2410722143,     -- text row vrfw_card_filter_tier ("%d★ %s")
    TEXT_GET = VRFW.commands.TEXT_GET,    -- CMND_TEXT_GET
    SERIES_INFO = VRFW.commands.GET_CHARA_SERIES_INFO,  -- CMND_GET_CHARA_SERIES_INFO(1, id) -> ok, name
    LAYER = 1199683335,       -- team14_02_filter_guide (instance 1 = the header)
    NODE = 3538663351,        -- _text_filter01
    IDX = 1,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    TEXT_PLATE = VRFW.commands.UPDATE_TEXT_PLATE,
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    OPEN = VRFW.commands.OPEN_LAYER,
    IS_OPEN = VRFW.commands.IS_OPEN_LAYER,
    GET_POS = VRFW.commands.GET_LAYER_LOCAL_POS,     -- CMND_GET_LAYER_LOCAL_POS(layer, idx) -> x, y
    SET_POS = VRFW.commands.SET_LAYER_LOCAL_POS,
    SE_MOVE = 2500047763,     -- sy0005
    S = {},
  }
  --- Internal: State of the card filter extension.
  VRFW.card_filter = CF

  local function call(f, ...)
    local r = table.pack(pcall(f, ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
  end

  local function text(id, fallback)
    local s = call(funcLuaCommand, CF.TEXT_GET, id)
    if type(s) == "string" and s ~= "" then
      return s
    end
    return fallback
  end

  --- Internal: The text of filter i; the "all" text for filter 0.
  function CF.name(i)
    local name, kind, sid, tier = call(funcLuaCommand, CF.CMD_LABEL, i)
    if kind == nil or kind == "all" or i == 0 then
      return text(CF.TX_ALL, "Todas")
    end
    if (name == nil or name == "") and kind == "series" then
      local ok, nm = call(funcLuaMenuCommand, CF.SERIES_INFO, 1, sid)
      if ok and type(nm) == "string" then
        name = nm
      end
    end
    name = tostring(name or "")
    if type(tier) == "number" and tier > 0 then
      local f = text(CF.TX_TIER, "%d* %s")
      local ok, s = pcall(string.format, f, tier, name)
      if ok then
        name = s
      end
    end
    return name
  end

  --- Internal: True when the filter plate of `stem` is open.
  function CF.plate_open(stem)
    local h = VRFW.host ~= nil and VRFW.host.hosts ~= nil and VRFW.host.hosts[stem] or nil
    if h ~= nil and h.L ~= nil then
      local ok, v = pcall(function() return h.L.flag end)
      if ok and type(v) == "boolean" then
        return v
      end
    end
    return CF.S[stem] ~= nil and CF.S[stem].plate == true
  end

  --- Internal: True when the screen's idle check allows the filter on `stem`.
  function CF.idle(stem)
    local S = CF.S[stem]
    if S == nil or S.idle == nil or S.idle == "" then
      return true
    end
    local h = VRFW.host ~= nil and VRFW.host.hosts ~= nil and VRFW.host.hosts[stem] or nil
    if h == nil or h.L == nil then
      return true
    end
    local ok, v = pcall(function() return h.L[S.idle] end)
    return not ok or type(v) ~= "number" or v == 0
  end

  --- Internal: Draws the filter plate of `stem` with its current value.
  function CF.draw(stem)
    local S = CF.S[stem]
    if S == nil then
      return
    end
    local L, k = CF.LAYER, CF.IDX
    if not S.on or S.shown == false then
      call(funcLuaMenuCommand, CF.VISIBLE, L, k, false)
      return
    end
    if not call(funcLuaMenuCommand, CF.IS_OPEN, L, k) then
      call(funcLuaMenuCommand, CF.OPEN, L, k)
    end
    local x, y = call(funcLuaMenuCommand, CF.GET_POS, L, 0)
    if type(x) == "number" and type(y) == "number" then
      call(funcLuaMenuCommand, CF.SET_POS, L, x + S.dx, y + S.dy, 0, k)
    end
    local f = text(CF.TX_HEADER, "<CMD_FUNCL2> < %s > <CMD_FUNCR2>")
    local ok, s = pcall(string.format, f, CF.name(S.value))
    call(funcLuaMenuCommand, CF.SET_TEXT, L, CF.NODE, ok and s or CF.name(S.value), k)
    call(funcLuaMenuCommand, CF.TEXT_PLATE, L, k, CF.NODE)
    call(funcLuaMenuCommand, CF.VISIBLE, L, k, true)
  end

  --- Internal: Reads the filter state of `stem` from the engine.
  function CF.enter(stem)
    local on, v, dx, dy, fn, prev, nxt, idle = call(funcLuaCommand, CF.CMD_ENTER, stem)
    CF.S[stem] = {
      on = on == true, value = tonumber(v) or 0, dx = tonumber(dx) or 0, dy = tonumber(dy) or 0,
      fn = tonumber(fn) or 0, prev = tonumber(prev) or 0, next = tonumber(nxt) or 0,
      idle = type(idle) == "string" and idle or nil, plate = false, shown = true,
    }
  end

  --- Internal: Ends the filter on `stem` and forgets its state.
  function CF.leave(stem)
    call(funcLuaCommand, CF.CMD_LEAVE, stem)
    CF.S[stem] = nil
  end

  --- Internal: Asks the screen to redo its list, then redraws the plate.
  function CF.rebuild(stem)
    if type(OnListTabChanged) == "function" then
      pcall(OnListTabChanged)
    end
    CF.draw(stem)
  end

  --- Internal: Installs the card filter on menu `stem` through VRFW.host.
  function CF.attach(stem)
    if VRFW.host == nil then
      return
    end
    local id = "VRFW.card_filter"
    VRFW.host.on(stem, "OnInit", { id = id, phase = "before", fn = function()
      CF.enter(stem)
    end })
    -- instance 1 of the filter plate = the header (instance 0 stays the retail one)
    VRFW.host.on(stem, "OnOpenLayer", { id = id, phase = "after", fn = function(r, a1, a2)
      if a1 == CF.LAYER and a2 == CF.IDX then
        CF.draw(stem)
      end
    end })
    VRFW.host.on(stem, "SetFilterGuideVisible", { id = id, phase = "after", fn = function(r, a1)
      local S = CF.S[stem]
      if S ~= nil then
        S.shown = a1 == true
        CF.draw(stem)
      end
    end })
    VRFW.host.on(stem, "OpenPersonalPlate", { id = id, phase = "after", fn = function()
      if CF.S[stem] ~= nil then
        CF.S[stem].plate = true
      end
    end })
    for _, f in ipairs({"ClosePersonalPlate", "SuspendPersonalPlate"}) do
      if type(_ENV[f]) == "function" then
        VRFW.host.on(stem, f, { id = id, phase = "after", fn = function()
          if CF.S[stem] ~= nil then
            CF.S[stem].plate = false
          end
        end })
      end
    end
    VRFW.host.on(stem, "FinalizeMenu", { id = id, phase = "before", create = true, fn = function()
      CF.leave(stem)
    end })
    if type(_ENV.UpdateCharaCountInList) == "function" then
      VRFW.host.on(stem, "UpdateCharaCountInList", { id = id, phase = "around", fn = function(nxt, ...)
        local S = CF.S[stem]
        local M = CHARA_FILTER_MENU
        if S == nil or not S.on or S.value == 0 or type(M) ~= "table" or type(M.IsFilterEnabled) ~= "function" then
          return nxt(...)
        end
        local orig = M.IsFilterEnabled
        M.IsFilterEnabled = function() return true end
        local r = table.pack(pcall(nxt, ...))
        M.IsFilterEnabled = orig
        if not r[1] then
          error(r[2], 0)
        end
        return table.unpack(r, 2, r.n)
      end })
    end
    VRFW.host.on(stem, "OnFunction", { id = id, phase = "around", fn = function(nxt, a1, a2, ...)
      local S = CF.S[stem]
      if S == nil or not S.on or a1 ~= S.fn or (a2 ~= S.prev and a2 ~= S.next) or CF.plate_open(stem) or not CF.idle(stem) then
        return nxt(a1, a2, ...)
      end
      local v = call(funcLuaCommand, CF.CMD_NEXT, a2 == S.next and 1 or -1)
      if type(v) == "number" and v ~= S.value then
        S.value = v
        call(funcLuaCommand, VRFW.commands.SND_PLAY_SE, CF.SE_MOVE)
        CF.rebuild(stem)
      end
    end })
    VRFW.host.on(stem, "Step", { id = id, phase = "after", fn = function()
      local S = CF.S[stem]
      if S == nil or not S.on then
        return
      end
      local rebuild = call(funcLuaCommand, CF.CMD_ALIVE) == true
      local v = tonumber(call(funcLuaCommand, CF.CMD_GET)) or 0
      if v ~= S.value then
        S.value = v
        rebuild = true
      end
      if rebuild then
        CF.rebuild(stem)
      end
    end })
  end
end
