-- Room join notice (VRFW net service). A Steam invite is checked with
-- its host as soon as it is accepted; the outcome is the joiner's notice: CMND_VRFW_NET_NOTICE gives its number and a
-- menu_text key (the mod list does not match, the room is full, the room is closed or does not answer, another
-- network protocol version, the invite is ready) and, for a mod list that does not match, which mods and settings
-- differ (detail lines «kind<TAB>args», each shown with its text key vrfw_net_diff_<kind>). The first menu that opens after it shows it in the retail message
-- window, whatever menu it is.
--
-- Event-driven: the notice is read once per menu, at its OnInit (a VM without OnInit: its first Step). Only a VM that
-- found one waits, at most WAIT_STEPS frames, for the screen to be idle (no fade, no message window up), then takes it
-- (CMND_VRFW_NET_NOTICE_TAKE: one VM shows it) and opens the window. Never during a match. No engine call at load time.
do
  local NOTICE = VRFW_Cmd.VRFW_NET_NOTICE              -- -> number (0 = none), text key
  local TAKE = VRFW_Cmd.VRFW_NET_NOTICE_TAKE           -- (number) -> true for the one VM that shows it
  local TEXT_GET = VRFW_Cmd.TEXT_GET
  local LOG = VRFW_Cmd.EVT_LOG
  local IS_SOCCER = VRFW_Cmd.IS_SOCCER_MODE
  local MSG_OPEN, MSG_KIND, MSG_BUSY = 2289627655, 2351835063, 898725220   -- the retail message window
  local FALLBACK_TEXT = "vrfw_net_refused"
  local WAIT_STEPS = 600

  local script = type(EVT_PATCH) == "table" and EVT_PATCH.script or "?"
  local stem = type(script) == "string" and (script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "")) or "?"
  local checked = false
  local number, key, lines, waited = 0, "", "", 0

  local function log(...)
    pcall(funcLuaCommand, LOG, "VRFW net_join_notice", tostring(stem), ...)
  end

  local function text_of(id)
    local ok, t = pcall(funcLuaCommand, TEXT_GET, VRFW_Crc32(id))
    return (ok and type(t) == "string") and t or ""
  end

  local function check()
    if checked then
      return
    end
    checked = true
    local ok, n, k, d = pcall(funcLuaCommand, NOTICE)
    if not ok or type(n) ~= "number" or n <= 0 or type(k) ~= "string" or k == "" then
      return
    end
    local oks, soccer = pcall(funcLuaCommand, IS_SOCCER)
    if oks and soccer == true then
      return
    end
    number, key, lines, waited = n, k, type(d) == "string" and d or "", 0
  end

  -- one detail line «kind<TAB>a<TAB>b<TAB>c» in the game's language ({a} {b} {c} of its text row); no row = the raw args
  local function detail(line)
    local parts = {}
    for f in (line .. "\t"):gmatch("([^\t]*)\t") do
      parts[#parts + 1] = f
    end
    local kind = parts[1] or ""
    local t = text_of("vrfw_net_diff_" .. kind)
    if t == "" then
      return table.concat(parts, " ", 2)
    end
    local args = {a = parts[2] or "", b = parts[3] or "", c = parts[4] or ""}
    return (t:gsub("{(%a)}", function(x) return args[x] or "" end))
  end

  local function idle()
    if type(BrightIsFade) == "function" and BrightIsFade() then
      return false
    end
    if type(MenuIsFade) == "function" and MenuIsFade() then
      return false
    end
    local ok, busy = pcall(funcLuaCommand, MSG_BUSY)
    return not (ok and busy == true)
  end

  local function show()
    if number == 0 then
      return
    end
    waited = waited + 1
    if waited > WAIT_STEPS then
      log("notice " .. tostring(number) .. " left for the next menu: this one never got idle")
      number = 0
      return
    end
    if not idle() then
      return
    end
    local n, k, d = number, key, lines
    number = 0
    local ok, mine = pcall(funcLuaCommand, TAKE, n)
    if not ok or mine ~= true then
      return
    end
    local text = text_of(k)
    if text == "" then
      text = text_of(FALLBACK_TEXT)
    end
    if text == "" then
      log("notice " .. tostring(n) .. ": no text row for " .. k)
      return
    end
    -- a mod list that does not match: the compatibility result's summary and its first lines (VRFW_OnlineCompat)
    local compat = (k == "vrfw_net_refused_mod_set" and type(VRFW_OnlineCompat) == "table") and VRFW_OnlineCompat.Read() or nil
    if compat ~= nil then
      text = text .. "\n" .. VRFW_OnlineCompat.Text(compat)
    else
      for line in d:gmatch("[^\n]+") do
        text = text .. "\n" .. detail(line)
      end
    end
    log("notice " .. tostring(n) .. " shown: " .. k)
    funcLuaCommand(MSG_OPEN, text, 0, 0, 0, 0, 0, false)
    funcLuaCommand(MSG_KIND, 1, 0)
  end

  local init = OnInit
  if type(init) == "function" then
    OnInit = function(...)
      local r = table.pack(init(...))
      pcall(check)
      return table.unpack(r, 1, r.n)
    end
  end
  local step = Step
  if type(step) == "function" then
    Step = function(...)
      local r = table.pack(step(...))
      if not checked then
        pcall(check)
      end
      if number ~= 0 then
        local ok, err = pcall(show)
        if not ok then
          number = 0
          log("error " .. tostring(err))
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end
  local VH = VRFW_Host
  if stem ~= "?" and type(VH) == "table" and type(VH.on) == "function" then
    pcall(VH.on, stem, "OnInit", {id = "VRFW.net_join_notice", phase = "around", fn = function(nxt, ...)
      local r = table.pack(nxt(...))
      pcall(check)
      return table.unpack(r, 1, r.n)
    end})
  end
end
