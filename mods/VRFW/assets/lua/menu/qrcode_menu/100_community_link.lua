
local CL = {
  INFO = VRFW.commands.VRFW_COMMUNITY_INFO,
  OPEN = VRFW.commands.VRFW_COMMUNITY_OPEN,        -- CMND_VRFW_COMMUNITY_OPEN () -> started
  TEXT_GET = VRFW.commands.TEXT_GET,    -- CMND_TEXT_GET (id) -> string
  SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,    -- CMND_SET_MENU_TEXT_STRING (layer, node, string, idx)
  SE = VRFW.commands.SND_PLAY_SE,          -- play a system sound
  SE_OK = 3848881948,       -- sy0000
  SE_NG = 2086672038,       -- sy0003
  FN_OPEN = 1801650413,
  LAYER = 292844459,        -- general_win
  NODE = 1119493378,        -- _text_win04
}


-- the body in the game's language, or nil (no declaration, no body row)
local function CL_Body()
  local url, creator, title, _, body = VRFW.host.command(CL.INFO)
  if type(url) ~= "string" or url == "" or type(body) ~= "number" or body == 0 then
    return nil
  end
  local f = VRFW.host.command(CL.TEXT_GET, body)
  if type(f) ~= "string" or f == "" then
    return nil
  end
  local function lit(s)
    return (string.gsub(tostring(s or ""), "%%", "%%%%"))
  end
  f = string.gsub(f, "{url}", lit(url))
  f = string.gsub(f, "{creator}", lit(creator))
  f = string.gsub(f, "{title}", lit(title))
  return f
end

if VRFW.host ~= nil and type(OnOpenLayer) == "function" then
  VRFW.host.on("qrcode_menu", "OnOpenLayer", {
    id = "menu_engine.community_link", phase = "after",
    fn = function(r, a1, a2)
      if a1 == CL.LAYER then
        local s = CL_Body()
        if s ~= nil then
          funcLuaMenuCommand(CL.SET_TEXT, CL.LAYER, CL.NODE, s, a2 or 0)
        end
      end
    end,
  })
  VRFW.host.on("qrcode_menu", "OnFunction", {
    id = "menu_engine.community_link", phase = "around", create = true,
    fn = function(nxt, a1, ...)
      if a1 == CL.FN_OPEN then
        local ok = VRFW.host.command(CL.OPEN)
        VRFW.host.command(CL.SE, ok and CL.SE_OK or CL.SE_NG)
        return
      end
      return nxt(a1, ...)
    end,
  })
end
