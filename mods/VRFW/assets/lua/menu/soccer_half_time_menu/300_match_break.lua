do
  local C = {
    BREAK = VRFW.commands.VRFW_RULE_ENGINE_BREAK,      -- CMND_VRFW_RULE_ENGINE_BREAK
    TEXT = VRFW.commands.VRFW_TEXT_GET,        -- CMND_VRFW_TEXT_GET (id)
    TEXT_GAME = VRFW.commands.TEXT_GET,  -- CMND_TEXT_GET (the merged menu_text)
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,   -- CMND_SET_MENU_TEXT_STRING
    LOG = VRFW.commands.VRFW_LOG,        -- CMND_VRFW_LOG
  }
  local L_TITLE, M_TITLE = 1867151190, 1778263274   -- soccer22_03_result_title, _text_results01
  local L_BACK, M_BACK = 4198875882, 378327766       -- cmn03_01_cmd_back, _text_cmd_back01
  -- crc32("match_engine.<key>") of the break_* keys
  local TITLE = {
    extra_time = 1431712048,       -- break_title_extra_time
    extra_time_half = 3761565035,  -- break_title_extra_time_half
    golden_goal = 2316818337,      -- break_title_golden_goal
    penalties = 3600765255,        -- break_title_penalties
  }
  local BUTTON = {
    extra_time_1 = 3865677811,     -- break_btn_extra_time_1
    extra_time_2 = 2137054793,     -- break_btn_extra_time_2
    golden_goal = 2163511436,      -- break_btn_golden_goal
    penalties = 1553911247,        -- break_btn_penalties
  }

  local function text(id)
    if id == nil then return nil end
    local s = VRFW.host.command(C.TEXT, id)
    if type(s) ~= "string" or s == "" then
      s = VRFW.host.command(C.TEXT_GAME, id)
    end
    return type(s) == "string" and s ~= "" and s or nil
  end

  -- the next period's phase and number, nil out of the ruleset's end phases
  local function next_period()
    local phase, nth = VRFW.host.command(C.BREAK)
    if type(phase) ~= "string" or phase == "" then return nil end
    return phase, tonumber(nth) or 1
  end

  local function relabel(layer, idx)
    local phase, nth = next_period()
    if phase == nil then return end
    local id, mesh
    if layer == L_TITLE then
      mesh = M_TITLE
      id = (phase == "extra_time" and nth >= 2) and TITLE.extra_time_half or TITLE[phase]
    else
      mesh = M_BACK
      id = phase == "extra_time" and (nth >= 2 and BUTTON.extra_time_2 or BUTTON.extra_time_1) or BUTTON[phase]
    end
    local s = text(id)
    if s == nil then
      VRFW.host.command(C.LOG, "VRFW match_break", "no text", tostring(phase), tostring(nth), tostring(id))
      return
    end
    if layer == L_TITLE then
      funcLuaMenuCommand(C.SET_TEXT, layer, mesh, s)
    else
      funcLuaMenuCommand(C.SET_TEXT, layer, mesh, s, idx)
    end
    VRFW.host.command(C.LOG, "VRFW match_break", tostring(phase), tostring(nth), layer == L_TITLE and "title" or "button")
  end

  local prev = OnOpenLayer
  if type(prev) == "function" and VRFW.match_break_open ~= OnOpenLayer then
    --- Internal: wrapped OnOpenLayer that relabels the title and back layers of the half time menu.
    VRFW.match_break_open = function(a1, a2, ...)
      prev(a1, a2, ...)
      if a1 == L_TITLE or a1 == L_BACK then
        pcall(relabel, a1, a2)
      end
    end
    OnOpenLayer = VRFW.match_break_open
  end
end
