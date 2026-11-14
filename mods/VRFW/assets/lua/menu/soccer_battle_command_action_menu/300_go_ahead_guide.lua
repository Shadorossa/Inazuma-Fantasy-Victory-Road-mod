--- Internal: namespace of the go-ahead guide wrappers.
VRFW.go_ahead_guide = VRFW.go_ahead_guide or {}
do
  local C = {
    FLAG_GET = VRFW.commands.VRFW_RULE_FLAG_GET,
    LOG = VRFW.commands.VRFW_LOG,         -- CMND_VRFW_LOG
  }
  local FLAG = "VRFW.hud.go_ahead_guide"
  local FLAG_GRAY = "VRFW.hud.go_ahead_guide.gray"
  local GUIDE = 4104611069          -- soccer08_17_go_ahead_guide
  local RETAIL_SPRITE = 3337459067
  local state = { shown = 0, active = false, logged = {} }

  local function flag(key)
    local v = VRFW.host.command(C.FLAG_GET, key)
    if type(v) == "number" then
      return v
    end
    return 0
  end

  -- put `sprite` (0 = the retail one) on the guide's word mesh, once per change
  local function show(sprite)
    if sprite == state.shown or type(SwapTextureAttachButtonGuide) ~= "function" then
      return
    end
    state.shown = sprite
    pcall(SwapTextureAttachButtonGuide, GUIDE, 0, sprite ~= 0 and sprite or RETAIL_SPRITE)
    if not state.logged[sprite] then
      state.logged[sprite] = true
      VRFW.host.command(C.LOG, "VRFW go_ahead_guide sprite", string.format("%.0f", sprite))
    end
  end

  local set = SetGoAheadButtonGuideStatus
  if type(set) == "function" and VRFW.go_ahead_guide.status ~= set then
    --- Internal: wraps the guide status; args visible, gray, area; answers the original result.
    VRFW.go_ahead_guide.status = function(visible, gray, area)
      local sprite = flag(FLAG)
      state.active = sprite ~= 0 and not visible and gray == true
      if state.active then
        show(sprite)
        return set(true, flag(FLAG_GRAY) ~= 0, area)
      end
      if visible then
        show(0)
      end
      return set(visible, gray, area)
    end
    SetGoAheadButtonGuideStatus = VRFW.go_ahead_guide.status
  end

  local gauge = UpdateGoAheadRecastGauge
  if type(gauge) == "function" and VRFW.go_ahead_guide.gauge ~= gauge then
    --- Internal: wraps the guide gauge; args visible, rate; answers the original result.
    VRFW.go_ahead_guide.gauge = function(visible, rate)
      if state.active then
        return gauge(false, 0)
      end
      return gauge(visible, rate)
    end
    UpdateGoAheadRecastGauge = VRFW.go_ahead_guide.gauge
  end

  local texture = UpdateTextureAttachButtonGuide
  if type(texture) == "function" and VRFW.go_ahead_guide.texture ~= texture then
    --- Internal: wraps the guide texture lookup; args layer and extra args; answers the original result.
    VRFW.go_ahead_guide.texture = function(layer, ...)
      local r = table.pack(texture(layer, ...))
      if layer == GUIDE then
        state.shown = 0
      end
      return table.unpack(r, 1, r.n)
    end
    UpdateTextureAttachButtonGuide = VRFW.go_ahead_guide.texture
  end
end
