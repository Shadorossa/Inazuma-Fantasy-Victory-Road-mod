-- Aura Reworked › banner trace (diagnostics), menu side: while the window of scripts\banner_trace.lua is open (the
-- ~2 s after an aura command) this VM logs each distinct menu command it sends (layer opens, texts, textures, colours):
--   «AuraOverhaul.banner_trace <vm> #<window> <command name or 0xid> <arg1> <arg2> <arg3> <arg4>»
-- One line per distinct (command, arg1, arg2) per window, at most MAX lines per window and VM. The window is asked
-- every CHECK calls (CMND_AURAOVERHAUL_BANNER_TRACE). Definitions only: the hook goes on when the engine stores
-- funcLuaMenuCommand (VRFW.host).
if type(VRFW) == "table" and type(VRFW.host) == "table" and type(VRFW.host.hook_command) == "function" and AuraOverhaul_BannerTrace == nil then
  local T = { calls = 0, next = 0, open = false, n = -1, lines = 0, seen = {}, names = nil, vm = nil }
  AuraOverhaul_BannerTrace = T
  local MAX, CHECK_OPEN, CHECK_CLOSED = 60, 16, 96
  local WINDOW = VRFW.crc32("CMND_AURAOVERHAUL_BANNER_TRACE")
  local LOG = VRFW.crc32("CMND_VRFW_LOG")
  local NAMES = { "CMND_OPEN_LAYER", "CMND_CLOSE_LAYER", "CMND_IS_OPEN_LAYER", "CMND_SET_LAYER_VISIBLE",
    "CMND_SET_LAYER_DRAW_ENABLE", "CMND_SET_LAYER_LOCAL_POS", "CMND_SET_LAYER_LOCAL_SCALE", "CMND_START_LAYER_ANIM",
    "CMND_SET_MENU_TEXT_STRING", "CMND_SET_MENU_TEXT_VISIBLE", "CMND_SET_TEXT_INFO", "CMND_UPDATE_TEXT_PLATE",
    "CMND_SET_PRIM_COLOR", "CMND_LOAD_MENU_RES_TEXTURE", "CMND_REF_MATERIAL", "CMND_CHANGE_SOCCER_COMMAND_ICON",
    "CMND_SET_ATTACH_LOCATOR_TARGET", "CMND_SET_LAYER_ATTACH_LOCATOR_TRACE", "CMND_SET_ATTACH_TYPE",
    "CMND_UPDATE_SYNERGY_ICON", "CMND_TEXT_GET", "CMND_GET_CHARA_NAME_TEXT" }

  local function value(v)
    if type(v) == "number" then
      if v == math.floor(v) and (v > 65535 or v < -65535) then return string.format("0x%08X", v % 4294967296) end
      return tostring(v)
    end
    if type(v) == "string" then return "\"" .. v:sub(1, 40) .. "\"" end
    if v == nil then return "-" end
    return type(v)
  end

  local function check()
    local ok, left, n = pcall(VRFW.host.real_command, WINDOW)
    T.open = ok and type(left) == "number" and left > 0
    if T.open and n ~= T.n then
      T.n, T.lines, T.seen = n, 0, {}
    end
    T.next = T.calls + (T.open and CHECK_OPEN or CHECK_CLOSED)
  end

  local function log(id, a1, a2, a3, a4)
    if T.names == nil then
      T.names = {}
      for _, name in ipairs(NAMES) do T.names[VRFW.crc32(name)] = name:sub(6) end
      local p = type(VRFW.patch) == "table" and VRFW.patch.script or nil
      T.vm = type(p) == "string" and p or "?"
    end
    local key = tostring(id) .. ":" .. tostring(a1) .. ":" .. tostring(a2)
    if T.seen[key] then return end
    T.seen[key] = true
    T.lines = T.lines + 1
    pcall(VRFW.host.real_command, LOG, "AuraOverhaul.banner_trace", T.vm, "#" .. tostring(T.n),
      T.names[id] or value(id), value(a1), value(a2), value(a3), value(a4))
  end

  VRFW.host.hook_command("*", function(nxt, ...)
    T.calls = T.calls + 1
    if T.calls >= T.next then check() end
    if T.open and T.lines < MAX then
      local id, a1, a2, a3, a4 = ...
      pcall(log, id, a1, a2, a3, a4)
    end
    return nxt(...)
  end, "AuraOverhaul.banner_trace", { menu = true, priority = VRFW.host.INNERMOST })
end
