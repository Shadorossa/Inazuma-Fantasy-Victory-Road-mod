-- Internal: mod_options (VRFW): option hook "title_opening".
-- Nothing runs at chunk load but the handler registration (every engine call is inside it).

VRFW.title_opening = VRFW.title_opening or {}
--- Internal: command id of the title opening option hook.
VRFW.title_opening.COMMAND = VRFW.commands.VRFW_OPTION_HOOK
--- Internal: command id that reads movie info.
VRFW.title_opening.INFO = VRFW.commands.GET_MOVIE_INFO
--- Internal: command id that reads the language code.
VRFW.title_opening.LANG = VRFW.commands.GET_LANGUAGE_CODE

-- Internal: The movie id chosen by the option row, or nil (no row / "as the game" / unknown movie).
function VRFW.title_opening.choice()
  local lang = VRFW.host.command(VRFW.title_opening.LANG)
  if type(lang) ~= "number" then
    lang = nil
  end
  local v = VRFW.host.command(VRFW.title_opening.COMMAND, "title_opening", lang)
  if type(v) ~= "number" or v == 0 then
    return nil
  end
  local info = VRFW.host.command(VRFW.title_opening.INFO, v)
  if info == false or info == nil then
    return nil
  end
  return v
end

if VRFW.host ~= nil then
  VRFW.host.on("title_main", "GetPlayOpeningEventId", {
    id = "mod_options.title_opening", phase = "around",
    fn = function(nxt, ...)
      local v = VRFW.title_opening.choice()
      if v ~= nil then
        return v
      end
      return nxt(...)
    end,
  })
end
