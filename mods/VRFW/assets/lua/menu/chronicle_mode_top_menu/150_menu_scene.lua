
local CHRONICLE_SKIP = {
  TAKE = VRFW.commands.VRFW_MENU_SCENE_TAKE,                   -- CMND_VRFW_MENU_SCENE_TAKE (action) -> 1 | 0
  RETURN = VRFW.commands.VRFW_MENU_SCENE_RETURN,                 -- CMND_VRFW_MENU_SCENE_RETURN (menu) -> "title" | ""
  MENU = "chronicle_mode_top_menu",
  BACK_FUNCTION = 1842266423,          -- the retail OnFunction id of the back key (BackToTitle)
  GLOBAL_BIT = VRFW.commands.GET_GLOBAL_BIT_FLAG,              -- CMND_GET_GLOBAL_BIT_FLAG (bit) -> set
  GLOBAL_BYTE = VRFW.commands.GET_GLOBAL_BYTE_FLAG,            -- CMND_GET_GLOBAL_BYTE_FLAG (byte) -> value
  TEMP_BIT = VRFW.commands.GET_TEMP_BIT_FLAG,               -- CMND_GET_TEMP_BIT_FLAG (bit) -> set
  TUTORIAL_ANSWERED_BIT = 1169930310,
  PLAYERS_UNIVERSE_EVENT_BIT = 774062760, -- a Players Universe event is reserved (the retail opens it)
  PLAYERS_UNIVERSE_BIT = 3914011134,   -- the retail goes to Players Universe at the open
  RETAIL_SKIP_BYTE = 3152001072,       -- = 2: the retail's own skip mode
  RETAIL_SKIP_VALUE = 2,
  TUTORIAL_FOCUS_PARAM = 2565779025,   -- (207055258, 0): the decision's tutorial focus cleared
  TUTORIAL_FOCUS_KEY = 207055258,
  TEMP_BYTE_SET = VRFW.commands.SET_TEMP_BYTE_FLAG,           -- CMND_SET_TEMP_BYTE_FLAG (2502072435, 0)
  TUTORIAL_TEMP_BYTE = 2502072435,
  FADE = 609722083,                    -- (1 to black | 0 in, seconds)
  VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,                 -- CMND_SET_LAYER_VISIBLE (layer, instance, on)
  BACKGROUND = 117665605,
  -- layers the retail itself shows or hides at its setup (left as the retail set them on a fallback)
  RETAIL_VISIBILITY = { [485095068] = true, [594583106] = true, [2279382105] = true },
  FALLBACK_FRAMES = 600,
}

local chronicle_skip = { on = false, started = false, frames = 0, hidden = {}, back = false, co = nil }

local ChronicleSkipLog = VRFW.logger.new("menu_scene, chronicle_mode_top_menu")

local function ChronicleSkipDecide()
  chronicle_skip.on, chronicle_skip.started, chronicle_skip.frames, chronicle_skip.hidden = false, false, 0, {}
  chronicle_skip.back, chronicle_skip.co = false, nil
  if VRFW.host.command(CHRONICLE_SKIP.TAKE, "chronicle_map") ~= 1 then
    if VRFW.host.command(CHRONICLE_SKIP.RETURN, CHRONICLE_SKIP.MENU) == "title" then
      if type(OnFunction) ~= "function" then
        ChronicleSkipLog("chronicle map: back to the title asked, no OnFunction: the top menu is shown")
        return
      end
      chronicle_skip.on, chronicle_skip.back = true, true
      ChronicleSkipLog("chronicle map: back from the map, straight to the title")
    end
    return
  end
  local why = nil
  if type(ChangeVsRouteTownScene) ~= "function" then
    why = "no ChangeVsRouteTownScene"
  elseif VRFW.host.command(CHRONICLE_SKIP.GLOBAL_BYTE, CHRONICLE_SKIP.RETAIL_SKIP_BYTE) == CHRONICLE_SKIP.RETAIL_SKIP_VALUE then
    why = "the retail skip mode runs"
  elseif VRFW.host.command(CHRONICLE_SKIP.GLOBAL_BIT, CHRONICLE_SKIP.TUTORIAL_ANSWERED_BIT) ~= true then
    why = "the tutorial question is not answered yet"
  elseif VRFW.host.command(CHRONICLE_SKIP.TEMP_BIT, CHRONICLE_SKIP.PLAYERS_UNIVERSE_EVENT_BIT) == true
      or VRFW.host.command(CHRONICLE_SKIP.TEMP_BIT, CHRONICLE_SKIP.PLAYERS_UNIVERSE_BIT) == true then
    why = "Players Universe is reserved"
  end
  if why then
    ChronicleSkipLog("chronicle map: the top menu is shown (", why, ")")
    return
  end
  chronicle_skip.on = true
  ChronicleSkipLog("chronicle map: the top menu is skipped")
end

local function ChronicleBackStart()
  chronicle_skip.started = true
  VRFW.host.command(CHRONICLE_SKIP.FADE, 1, 0)
  chronicle_skip.co = coroutine.create(function() OnFunction(CHRONICLE_SKIP.BACK_FUNCTION, 0) end)
  ChronicleSkipLog("chronicle map: the retail Back to the title started")
  return true
end

local function ChronicleBackStep()
  local co = chronicle_skip.co
  if not co or coroutine.status(co) == "dead" then return end
  local ok, err = coroutine.resume(co)
  if not ok then
    chronicle_skip.co = nil
    ChronicleSkipLog("chronicle map: Back to the title error:", tostring(err))
  end
end

local function ChronicleSkipStart()
  if chronicle_skip.back then return ChronicleBackStart() end
  chronicle_skip.started = true
  VRFW.host.command(CHRONICLE_SKIP.FADE, 1, 0)
  VRFW.host.command(CHRONICLE_SKIP.TUTORIAL_FOCUS_PARAM, CHRONICLE_SKIP.TUTORIAL_FOCUS_KEY, 0)
  VRFW.host.command(CHRONICLE_SKIP.TEMP_BYTE_SET, CHRONICLE_SKIP.TUTORIAL_TEMP_BYTE, 0)
  local ok, err = pcall(ChangeVsRouteTownScene)
  ChronicleSkipLog("chronicle map: «Cadena de Crónica» path started (", tostring(ok), ok and "" or tostring(err), ")")
  return ok
end

if type(OnInit) == "function" and type(OnOpenLayer) == "function" then
  local on_init_before = OnInit
  OnInit = function(...)
    local r = table.pack(on_init_before(...))
    local ok, err = pcall(ChronicleSkipDecide)
    if not ok then
      chronicle_skip.on = false
      ChronicleSkipLog("chronicle map error:", tostring(err), ": the top menu is shown")
    end
    return table.unpack(r, 1, r.n)
  end

  local open_layer_before = OnOpenLayer
  local fallback                       -- (defined below)
  OnOpenLayer = function(a1, a2, ...)
    if chronicle_skip.on and not chronicle_skip.started and a1 == CHRONICLE_SKIP.BACKGROUND then
      local ok, started = pcall(ChronicleSkipStart)
      if ok and started then return end
      fallback("the «Cadena de Crónica» path did not start")
      return
    end
    return open_layer_before(a1, a2, ...)
  end

  fallback = function(why)
    chronicle_skip.on, chronicle_skip.back, chronicle_skip.co = false, false, nil
    ChronicleSkipLog("chronicle map:", why, ": the top menu is shown")
    for _, layer in ipairs(chronicle_skip.hidden) do
      VRFW.host.menu_command(CHRONICLE_SKIP.VISIBLE, layer[1], layer[2], true)
    end
    chronicle_skip.hidden = {}
    local ok, err = pcall(open_layer_before, CHRONICLE_SKIP.BACKGROUND, 0)
    if not ok then ChronicleSkipLog("chronicle map: retail opening error:", tostring(err)) end
  end

  if type(OnSetupLayer) == "function" then
    local setup_layer_before = OnSetupLayer
    OnSetupLayer = function(a1, a2, ...)
      local r = table.pack(setup_layer_before(a1, a2, ...))
      if chronicle_skip.on and r[1] == nil and not CHRONICLE_SKIP.RETAIL_VISIBILITY[a1] then
        VRFW.host.menu_command(CHRONICLE_SKIP.VISIBLE, a1, a2 or 0, false)
        chronicle_skip.hidden[#chronicle_skip.hidden + 1] = { a1, a2 or 0 }
      end
      return table.unpack(r, 1, r.n)
    end
  end

  if type(Step) == "function" then
    local step_before = Step
    Step = function(...)
      local r = table.pack(step_before(...))
      if chronicle_skip.on and chronicle_skip.started then
        if chronicle_skip.back then
          local ok, err = pcall(ChronicleBackStep)
          if not ok then ChronicleSkipLog("chronicle map: Back step error:", tostring(err)) end
        end
        chronicle_skip.frames = chronicle_skip.frames + 1
        if chronicle_skip.frames > CHRONICLE_SKIP.FALLBACK_FRAMES then
          local ok, err = pcall(fallback, "still open " .. CHRONICLE_SKIP.FALLBACK_FRAMES .. " frames after the skip began")
          if not ok then ChronicleSkipLog("chronicle map fallback error:", tostring(err)) end
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end
end
