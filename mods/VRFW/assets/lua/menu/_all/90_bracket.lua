-- lua_patch.scope: used
if VRFW.bracket == nil then
  local Bracket = {}

  local MENU = "vrfw_bracket_menu"
  local PARAM_PREFIX = "vrfw_bracket_"
  local TEXT_VALUE = 910683996       -- (text, tag, n, ...): the text with <tag> filled

  local S = { want = nil, opts = {} }

  local logger
  local function Log(...)
    logger = logger or VRFW.logger.new("VRFW.bracket")
    logger(...)
  end

  local function P(name)
    return VRFW.crc32(PARAM_PREFIX .. name)
  end

  local function param_set(name, n)
    VRFW.param.replace(P(name), n)
  end

  -- what the child reads besides the page and the host: the view command, the layout, the advance
  local function send()
    local o = S.opts
    VRFW.param.set_u32(PARAM_PREFIX .. "view", o.view or 0)
    param_set("top", math.floor(tonumber(o.top) or 0))
    param_set("lift", math.floor(tonumber(o.lift) or 0))
    if o.animate then
      param_set("busy", 1)
    end
  end

  -- the child menu's handshake (VRFW.child_menu, 89_child_menu.lua), made at the first call
  local child
  local function Child()
    child = child or VRFW.child_menu.host(MENU, { prefix = PARAM_PREFIX, label = "bracket menu", send = send,
      log = function(...) Log("bracket menu:", ...) end })
    return child
  end

  --- Shows the bracket on `page` with options.
  function Bracket.show(page, opts)
    S.want = page or -1
    S.opts = type(opts) == "table" and opts or {}
    VRFW.param.clear(P("skip"))
    if not S.opts.animate then
      VRFW.param.clear(P("busy"))
    end
    Child().show(S.want, S.opts.host, S.opts.animate == true)
  end

  --- Hides the bracket.
  function Bracket.hide(why)
    S.want = nil
    Child().hide(why or "the host left the bracket")
    VRFW.param.clear(P("busy"))
  end

  --- True while the bracket is busy.
  function Bracket.busy()
    if S.want == nil then
      return false
    end
    return VRFW.param.has(P("busy"))
  end

  --- Skips the bracket's animation.
  function Bracket.skip()
    VRFW.param.clear(P("busy"))
    param_set("skip", 1)
    Child().call("vrfw_bracket_skip")
  end

  --- True while the bracket is wanted.
  function Bracket.shown()
    return S.want ~= nil
  end

  --- One frame of the bracket child.
  function Bracket.step()
    Child().step()
  end

  --- Marks instance `fixed`, or the next free one of `layer`, as used in this draw (state: { used, taken }); returns it.
  function Bracket.take(state, layer, fixed)
    local i = fixed
    if i == nil then
      i = state.used[layer] or 0
      while state.taken[tostring(layer) .. ":" .. i] do
        i = i + 1
      end
      state.used[layer] = i + 1
    end
    state.taken[tostring(layer) .. ":" .. i] = true
    return i
  end

  --- Appends the digit sprites of number n to parts as { name, height }; wrap puts it in brackets. Sprites are <prefix><style>_<digit>.
  function Bracket.number_parts(prefix, parts, n, style, h, wrap)
    if wrap then
      parts[#parts + 1] = { prefix .. "lp", h }
    end
    for c in tostring(math.max(0, math.floor(tonumber(n) or 0))):gmatch("%d") do
      parts[#parts + 1] = { prefix .. style .. "_" .. c, h }
    end
    if wrap then
      parts[#parts + 1] = { prefix .. "rp", h }
    end
    return parts
  end

  --- `text` with <VALUE> filled with a, and <VALUE2> with b when b is given (the retail text value command, once per tag).
  function Bracket.text_value2(text, a, b)
    text = VRFW.host.command(TEXT_VALUE, text, "VALUE", a or 0, 0, 0, true) or text
    if b ~= nil then
      text = VRFW.host.command(TEXT_VALUE, text, "VALUE2", b, 0, 0, true) or text
    end
    return text
  end

  VRFW.bracket = Bracket
end
