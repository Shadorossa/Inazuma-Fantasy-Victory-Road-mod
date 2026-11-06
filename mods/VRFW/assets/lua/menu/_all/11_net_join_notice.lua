-- Room join notice (VRFW net service). A Steam invite is checked with
-- its host as soon as it is accepted; the outcome is the joiner's notice: CMND_VRFW_NET_NOTICE gives its number and a
-- menu_text key (the mod list does not match, the room is full, the room is closed or does not answer, another
-- network protocol version, the invite is ready) and, for a mod list that does not match, which mods and settings
-- differ (detail lines «kind<TAB>args», each shown with its text key vrfw_net_diff_<kind>). The first menu that opens after it shows it in the retail message
-- window, whatever menu it is.
--
-- Event-driven: the notice is read once per menu, at its OnInit (a VM without OnInit: its first Step). Only a VM that
-- found one waits, at most WAIT_STEPS frames, for the screen to be idle (no fade, no message window up), then takes it
-- A welcomed invite whose mode declares `join_menu` (CMND_VRFW_NET_INVITE_TARGET) asks to go there and goes by the
-- straight reset (VRFW_Reset); that menu joins the room itself, so its own VM shows nothing here.
-- (CMND_VRFW_NET_NOTICE_TAKE: one VM shows it) and opens the window. Never during a match. No engine call at load time.
do
  local NOTICE = VRFW_Cmd.VRFW_NET_NOTICE              -- -> number (0 = none), text key
  local TAKE = VRFW_Cmd.VRFW_NET_NOTICE_TAKE           -- (number) -> true for the one VM that shows it
  local TEXT_GET = VRFW_Cmd.TEXT_GET
  local LOG = VRFW_Cmd.EVT_LOG
  local IS_SOCCER = VRFW_Cmd.IS_SOCCER_MODE
  local MSG_OPEN, MSG_KIND, MSG_BUSY = 2289627655, 2351835063, 898725220   -- the retail message window
  local MSG_RESULT, MSG_DONE = 1523741473, 682363669
  local INVITE_TARGET = VRFW_Cmd.VRFW_NET_INVITE_TARGET -- -> code, join_menu, join_title_mode (-1 none)
  local AUTO_SAVE = VRFW_Cmd.SYSTEM_AUTO_SAVE
  local FADE, FADE_DONE, BUSY = 609722083, 2259183189, 2736534827
  local READY_TEXT, GO_TEXT = "vrfw_net_invite_ready", "vrfw_net_invite_go"
  local TITLE = {title_menu_2 = true, title_main = true}
  local MSG_MAX = 7200                                  -- frames an unanswered question stays up
  local FALLBACK_TEXT = "vrfw_net_refused"
  local WAIT_STEPS = 600

  local script = type(EVT_PATCH) == "table" and EVT_PATCH.script or "?"
  local stem = type(script) == "string" and (script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "")) or "?"
  local checked = false
  local number, key, lines, waited = 0, "", "", 0
  local go_co = nil

  local function log(...)
    pcall(funcLuaCommand, LOG, "VRFW net_join_notice", tostring(stem), ...)
  end

  local function text_of(id)
    local ok, t = pcall(funcLuaCommand, TEXT_GET, VRFW_Crc32(id))
    return (ok and type(t) == "string") and t or ""
  end

  -- the mode's menu of a welcomed invite, or nil
  local function invite_target()
    local ok, code, menu, title_mode = pcall(funcLuaCommand, INVITE_TARGET)
    if not ok or type(code) ~= "string" or code == "" or type(menu) ~= "string" or menu == "" then
      return nil
    end
    return menu, (type(title_mode) == "number" and title_mode >= 0) and title_mode or nil
  end

  -- the question, then the straight reset into the mode's menu; the invite stays pending for that menu
  local function go_to_room(menu, title_mode)
    funcLuaCommand(MSG_OPEN, text_of(GO_TEXT), 0, 0, 0, 0, 0, false)
    funcLuaCommand(MSG_KIND, 2, 0)
    local choice, up = -1, false
    for _ = 1, MSG_MAX do
      coroutine.yield()
      local a, c = funcLuaCommand(MSG_RESULT)
      local gone = funcLuaCommand(MSG_DONE) == true
      local busy = funcLuaCommand(MSG_BUSY) == true
      up = up or not gone or busy
      if type(a) == "number" and a >= 0 then
        choice = a
        break
      end
      if up and (c == true or (gone and not busy)) then
        break
      end
    end
    log("invite: go to " .. menu .. "? answer " .. tostring(choice))
    if choice ~= 0 then
      return
    end
    if not TITLE[stem] then
      funcLuaCommand(AUTO_SAVE)
    end
    funcLuaCommand(FADE, 1, 0.3)
    while not funcLuaCommand(FADE_DONE) do coroutine.yield() end
    while funcLuaCommand(BUSY) do coroutine.yield() end
    -- a menu scene under the title (the 3D map) goes with the old rpg scene
    local okm, state = pcall(funcLuaCommand, VRFW_Cmd.VRFW_MENU_SCENE_STATE)
    if TITLE[stem] and okm and state == "up" then
      pcall(funcLuaCommand, VRFW_Cmd.VRFW_MENU_SCENE_SET, "leaving", "invite: " .. menu)
    end
    local how = VRFW_Reset.straight({ menu = menu, title_mode = title_mode, bgm_stop = true, need_carry = true,
      log = function(text) log("invite: " .. text) end })
    log("invite: reset into " .. menu .. ": " .. tostring(how))
    if how == "refused" then
      funcLuaCommand(FADE, 0, 0.3)
      funcLuaCommand(MSG_OPEN, text_of(READY_TEXT), 0, 0, 0, 0, 0, false)
      funcLuaCommand(MSG_KIND, 1, 0)
      return
    end
    for _ = 1, 900 do coroutine.yield() end
    log("invite: still here 900 frames after the reset")
    funcLuaCommand(FADE, 0, 0.3)
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
    if k == READY_TEXT and invite_target() == stem then
      log("notice " .. tostring(n) .. ": this menu joins the invite's room itself")
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
    if k == READY_TEXT then
      local menu, title_mode = invite_target()
      if menu ~= nil then
        log("notice " .. tostring(n) .. ": asking to go to " .. menu)
        go_co = coroutine.create(function() go_to_room(menu, title_mode) end)
        return
      end
      log("notice " .. tostring(n) .. ": the invite's mode declares no join_menu")
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
      if go_co ~= nil then
        local ok, err = coroutine.resume(go_co)
        if not ok then
          log("invite: error " .. tostring(err))
        end
        if not ok or coroutine.status(go_co) == "dead" then
          go_co = nil
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
