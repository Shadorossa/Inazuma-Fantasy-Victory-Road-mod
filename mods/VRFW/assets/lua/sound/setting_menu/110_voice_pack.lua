-- Internal: audio_engine: row "Voice pack" / "Voice pack" of Options > "Mod options" (setting_menu).

VRFW.voice_pack = VRFW.voice_pack or {}
--- Internal: row key of the voice pack option in options.toml.
VRFW.voice_pack.KEY = "audio_engine.voice_pack"  -- row key of options.toml
--- Internal: text id of the no-voice-pack choice (value 0).
VRFW.voice_pack.NONE_ID = 581565135              -- crc32("audio_engine.voice_pack_none"): value 0
--- Internal: text id of the off choice.
VRFW.voice_pack.OFF_ID = 2052939705
--- Internal: 1 plus the number of installed voice-pack languages, refreshed by get.
VRFW.voice_pack.COUNT = 1                        -- 1 + installed voice-pack languages (refreshed by get)
-- Internal: {framework name, ModLoader name} of each command (crc32 of the names)
VRFW.voice_pack.GET = {VRFW.commands.VRFW_SOUND_VOICE_GET, VRFW.commands.VRFW_SOUND_VOICE_GET}
--- Internal: command pair of the voice name lookup.
VRFW.voice_pack.NAME = {VRFW.commands.VRFW_SOUND_VOICE_NAME, VRFW.commands.VRFW_SOUND_VOICE_NAME}
--- Internal: command pair of the voice set command.
VRFW.voice_pack.SET = {VRFW.commands.VRFW_SOUND_VOICE_SET, VRFW.commands.VRFW_SOUND_VOICE_SET}
--- Internal: which command of each pair answers (framework or ModLoader), nil until probed.
VRFW.voice_pack.SRC = nil

--- Internal: calls the framework command of a pair, else the ModLoader's; answers the command's results.
function VRFW.voice_pack.cmd(pair, ...)          -- the framework's command, else the ModLoader's
  if VRFW.voice_pack.SRC ~= nil then
    return VRFW.host.command(pair[VRFW.voice_pack.SRC], ...)
  end
  return VRFW.host.command(pair[1], ...)
end
--- Internal: text of a text id (id, fallback); answers a string, the fallback when empty.
function VRFW.voice_pack.text(id, fallback)
  local s = VRFW.host.command(VRFW.commands.TEXT_GET, id)
  if type(s) == "string" and s ~= "" then
    return s
  end
  return fallback
end
--- Internal: option row with get and set functions for the voice pack choice.
VRFW.voice_pack.ROW = {
  get = function()                     -- stored index, nil = loader / module off
    local i, n = VRFW.host.command(VRFW.voice_pack.GET[1])
    VRFW.voice_pack.SRC = 1
    if type(i) ~= "number" or type(n) ~= "number" then
      i, n = VRFW.host.command(VRFW.voice_pack.GET[2])
      VRFW.voice_pack.SRC = 2
    end
    if type(i) ~= "number" or type(n) ~= "number" then
      VRFW.voice_pack.SRC = nil
      return nil
    end
    VRFW.voice_pack.COUNT = n
    if i < 0 or i >= n then
      return 0
    end
    return i
  end,
  step = function(v, dir)
    local n = VRFW.voice_pack.COUNT or 1
    if n < 1 then
      n = 1
    end
    return (v + dir + n) % n
  end,
  fmt = function(v)
    if v == 0 then
      return VRFW.voice_pack.text(VRFW.voice_pack.NONE_ID, "None")
    end
    local name, code, text_id = VRFW.voice_pack.cmd(VRFW.voice_pack.NAME, v)
    if type(text_id) == "number" and text_id ~= 0 then
      local s = VRFW.voice_pack.text(text_id, nil)
      if s ~= nil then
        return s
      end
    end
    if type(name) == "string" and name ~= "" then
      return name
    end
    if type(code) == "string" and code ~= "" then
      return code
    end
    return "?"
  end,
  set = function(v)
    return VRFW.voice_pack.cmd(VRFW.voice_pack.SET, v) == true
  end,
  off = function()
    return VRFW.voice_pack.text(VRFW.voice_pack.OFF_ID, "Needs the VR ModLoader")
  end
}
if VRFW.host ~= nil then              -- the setting_menu host's list of rows
  VRFW.host.add("setting_menu", "option_rows", {id = VRFW.voice_pack.KEY, value = VRFW.voice_pack.ROW})
elseif (VRFW.mod_options ~= nil and VRFW.mod_options.register ~= nil) then
  VRFW.mod_options.register(VRFW.voice_pack.KEY, VRFW.voice_pack.ROW)
else
  VRFW.mod_options_queue = VRFW.mod_options_queue or {}
  VRFW.mod_options_queue[#VRFW.mod_options_queue + 1] = {key = VRFW.voice_pack.KEY, row = VRFW.voice_pack.ROW}
end
