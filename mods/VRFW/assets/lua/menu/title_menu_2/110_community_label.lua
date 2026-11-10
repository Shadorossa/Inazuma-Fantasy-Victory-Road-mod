
local CLB = {
  LAYER = 399128006,        -- title00_10_inazuma_post
  NODE = 2199506815,        -- _text_inazumapost01
  INFO = VRFW.commands.VRFW_COMMUNITY_INFO,
  TEXT_GET = VRFW.commands.TEXT_GET,    -- CMND_TEXT_GET (id) -> string
  SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,    -- CMND_SET_MENU_TEXT_STRING (layer, node, string, idx)
  TEXT_PLATE = VRFW.commands.UPDATE_TEXT_PLATE,  -- refit the text plate (layer, idx, node)
}


local function CLB_Label()
  local url, creator, title, label = VRFW.host.command(CLB.INFO)
  if type(url) ~= "string" or url == "" or type(label) ~= "number" or label == 0 then
    return nil
  end
  local f = VRFW.host.command(CLB.TEXT_GET, label)
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
  VRFW.host.on("title_menu_2", "OnOpenLayer", {
    id = "menu_engine.community_label", phase = "after",
    fn = function(r, a1, a2)
      if a1 == CLB.LAYER then
        local s = CLB_Label()
        if s ~= nil then
          VRFW.host.menu_command(CLB.SET_TEXT, CLB.LAYER, CLB.NODE, s, a2 or 0)
          VRFW.host.menu_command(CLB.TEXT_PLATE, CLB.LAYER, a2 or 0, CLB.NODE)
        end
      end
    end,
  })
end
