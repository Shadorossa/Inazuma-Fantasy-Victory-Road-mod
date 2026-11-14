-- lua_patch.scope: used
-- menu_engine: VRFW.screen_art, the art of the framework's own screens (VRFW 2.4.51, docs/framework/screen-art.md).
if VRFW.screen_art == nil then
  local A = {
    CMD = VRFW.commands.VRFW_SCREEN_ART,
    PLAIN = "#/menu/220_img/vrfw_plain/vrfw_plain.g4tx",
    art = {},                    -- screen -> role -> { atlas, sprite, tex, crc }
  }
  --- Advanced: Namespace: the screen art helpers of the menu VM.
  VRFW.screen_art = A

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("vrfw.ScreenArt")
    logger(...)
  end

  --- Advanced: The declared roles of a screen (read once per VM): role -> { atlas, sprite, tex = crc32(atlas), crc = crc32(sprite) }.
  function A.get(screen)
    local t = A.art[screen]
    if t ~= nil then
      return t
    end
    t = {}
    A.art[screen] = t
    local ok, got = pcall(funcLuaCommand, A.CMD, screen)
    local n = 0
    if ok and type(got) == "table" then
      for role, a in pairs(got) do
        if type(a) == "table" and type(a.atlas) == "string" and type(a.sprite) == "string" then
          t[role] = { atlas = a.atlas, sprite = a.sprite, tex = CRC32(a.atlas), crc = CRC32(a.sprite) }
          n = n + 1
        end
      end
    end
    if n == 0 then
      log(screen, "no mod declares its art: plain fallback (vrfw_plain)")
    else
      log(screen, n, "declared role(s)")
    end
    return t
  end

  --- Advanced: One declared role of a screen (nil = none: draw the fallback).
  function A.role(screen, role)
    return A.get(screen)[role]
  end

  --- Advanced: The atlases a screen's declared art uses (each once): the screen asks them with CMND_LOAD_TEX.
  function A.atlases(screen)
    local seen, out = {}, {}
    for _, a in pairs(A.get(screen)) do
      if not seen[a.atlas] then
        seen[a.atlas] = true
        out[#out + 1] = a.atlas
      end
    end
    return out
  end

  --- Advanced: The texture and sprite hashes of the plain fallback quad of `shape`.
  function A.plain(shape)
    return CRC32(A.PLAIN), CRC32("vrfw_plain_" .. shape)
  end
end
