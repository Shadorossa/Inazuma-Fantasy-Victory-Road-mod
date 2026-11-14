-- menu_scene (VRFW): MENU PICK.
if VRFW.menu_pick == nil then
  local P = {
    PICK_LAYER = 2283875177,   -- param vrfw_menu_scene_pick_layer
    PICK_INDEX = 3968429426,   -- param vrfw_menu_scene_pick_index (entry + 1)
    PICK_OPTION = 2481379900,   -- param vrfw_menu_scene_pick_option (option + 1)
    PICK_RETURN = 1862198659,
    CONFIRM_OPEN = 2289627655,
    OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT,
    MENU_EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT,   -- CMND_IS_EXIST_MENU_OBJECT (menu) (menu command)
    BRIGHT_FADE = 609722083,
    SUBWIN_SELECTED = VRFW.commands.GET_SUB_WINDOW_RESULT, -- () -> the open sub-window's chosen row (-1 while none)
    CONFIRM_RESULT = 1523741473,
    CONFIRM_GONE = 682363669,
    LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM,    -- CMND_GET_CREATE_LAYER_NUM (layer)
    FOCUS_ACTIVE = VRFW.commands.IS_CTRL_FOCUS_ACTIVE,  -- (layer) -> the layer holds the control focus
    FOCUS_INDEX = 2603265800,  -- (layer) -> its focused instance
    FOCUS_MARK = 1778826357,   -- (layer, instance, true): the focus moves there
    WHITE_FADE = 4011714927,   -- (alpha, seconds): the full-screen white fade (the title's)
    READY_FRAMES = 15,
    RELEASE_FRAMES = 20,
    GIVE_UP_FRAMES = 600,
    ANSWER_FRAMES = 600,
  }
  local st = { layer = nil, row = nil, frames = 0, ready = 0, marked = false, co = nil, after = nil, option = -1,
    answering = false, hooked = false, back_to_title = false, opened = nil, opened_up = 0, confirm_skipped = false,
    back_co = nil }
  --- Internal: State of the menu pick: presses a list entry requested by another screen.
  VRFW.menu_pick = st

  local logger
  local function Log(...)
    logger = logger or VRFW.logger.new("menu_scene")
    logger("menu_pick", ...)
  end
  local function White(on)
    VRFW.host.command(P.WHITE_FADE, on and 1 or 0, on and 0 or 0.3)
  end

  local function Take()
    if not VRFW.param.has(P.PICK_LAYER) then return false end
    local layer = tonumber(VRFW.param.get(P.PICK_LAYER)) or 0
    if layer < 0 then layer = layer + 4294967296 end
    local n = VRFW.host.menu_command(P.LAYER_NUM, layer)
    if type(n) ~= "number" or n <= 0 then return false end     -- not this menu
    local row = (tonumber(VRFW.param.get(P.PICK_INDEX)) or 0) - 1
    --- Internal: option index requested, or -1.
    st.option = -1
    if VRFW.param.has(P.PICK_OPTION) then st.option = (tonumber(VRFW.param.get(P.PICK_OPTION)) or 0) - 1 end
    --- Internal: True when the pick was asked to return to the title.
    st.back_to_title = VRFW.param.has(P.PICK_RETURN)
    VRFW.param.clear(P.PICK_LAYER)
    VRFW.param.clear(P.PICK_INDEX)
    VRFW.param.clear(P.PICK_OPTION)
    if st.back_to_title then VRFW.param.clear(P.PICK_RETURN) end
    if row < 0 or row >= n then
      Log(string.format("layer 0x%08X: entry %d of %d: not picked", layer, row, n))
      return false
    end
    st.layer, st.row, st.frames, st.ready, st.marked = layer, row, 0, 0, false
    Log(string.format("layer 0x%08X entry %d asked by the menu scene", layer, row))
    return true
  end

  local function Pressed(nxt, h, ...)
    if st.answering then
      if h == P.SUBWIN_SELECTED then return st.option end
      if h == P.CONFIRM_RESULT then return 0, false end
      if h == P.CONFIRM_GONE and st.confirm_skipped and not st.confirm_reported then
        st.confirm_reported = true   -- the skipped window counts as up once, so VRFW.question reads its answer
        return false
      end
      if h == P.CONFIRM_OPEN and not st.confirm_skipped then
        st.confirm_skipped = true
        Log("the yes / no window skipped: the hotspot's choice is the confirmation")
        return true
      end
    end
    if h == P.OPEN_MENU and st.opened == nil then
      st.opened = ...
      Log(string.format("the press opens menu 0x%08X", (tonumber(st.opened) or 0) % 4294967296))
    end
    if h == P.BRIGHT_FADE and st.back_to_title and st.opened and (...) == 0 and VRFW.host.menu_command(P.MENU_EXISTS, st.opened) ~= true then
      Log("the fade back into this menu skipped: back to the title")
      return true
    end
    return nxt(h, ...)
  end

  local function Wrap(on)
    if on and not st.hooked then
      st.hooked = true
      VRFW.host.hook_command({ P.SUBWIN_SELECTED, P.CONFIRM_RESULT, P.CONFIRM_OPEN, P.CONFIRM_GONE, P.OPEN_MENU, P.BRIGHT_FADE }, Pressed,
        "VRFW.menu_pick")
    elseif not on and st.hooked then
      VRFW.host.unhook_command("VRFW.menu_pick")
      st.hooked = false
    end
  end

  local function Answer(on)
    if on and not st.answering then
      st.answering, st.answer_frames, st.confirm_skipped, st.confirm_reported = true, 0, false, false
      Log("option", st.option, "answered for the entry's own choice")
    elseif not on and st.answering then
      st.answering = false
    end
  end

  local function PickStep()
    if st.co ~= nil then
      if coroutine.status(st.co) ~= "dead" then
        local ok, err = coroutine.resume(st.co)
        if not ok then Log("press error:", tostring(err)) st.co = nil end
      else
        st.co = nil
      end
      -- the option's answers (and the white) end once the menu the press opened is up a moment, or the press ended
      if st.answering then
        st.answer_frames = (st.answer_frames or 0) + 1
        if st.opened and VRFW.host.menu_command(P.MENU_EXISTS, st.opened) == true then st.opened_up = st.opened_up + 1 end
        if st.co == nil or st.opened_up >= P.RELEASE_FRAMES or st.answer_frames > P.ANSWER_FRAMES then
          Answer(false)
          st.after = st.opened_up >= P.RELEASE_FRAMES and P.RELEASE_FRAMES or 0   -- the opened menu already waited
          Log("the option's answers off:", st.co == nil and "the press ended" or (st.opened_up > 0 and "the opened menu is up" or "time"))
        end
      end
      if st.co == nil then
        Wrap(false)
        -- Back from the opened menu came here: this menu's own Back to the title (return = "title")
        if st.back_to_title and st.opened and VRFW.host.menu_command(P.MENU_EXISTS, st.opened) ~= true then
          st.back_to_title = false
          if type(BackToTitle) == "function" then
            st.back_co = coroutine.create(BackToTitle)
            Log("back from the opened menu: this menu's BackToTitle")
          else
            Log("back from the opened menu: this menu has no BackToTitle (left to the player)")
          end
        end
      end
    end
    if st.back_co ~= nil then
      if coroutine.status(st.back_co) ~= "dead" then
        local ok, err = coroutine.resume(st.back_co)
        if not ok then Log("BackToTitle error:", tostring(err)) st.back_co = nil end
      else
        st.back_co = nil
      end
    end
    if st.after ~= nil and not st.answering then
      st.after = st.after + 1
      if st.after >= P.RELEASE_FRAMES then
        st.after = nil
        White(false)
        Log("white released")
      end
    end
    if st.layer == nil and not Take() then return end
    if st.layer == nil then return end
    White(true)
    --- Internal: frames waited for the pick.
    st.frames = st.frames + 1
    if st.frames > P.GIVE_UP_FRAMES then
      Log("entry", st.row, "not picked: the list never took the focus")
      st.layer = nil
      White(false)
      return
    end
    if VRFW.host.menu_command(P.FOCUS_ACTIVE, st.layer) ~= true then st.ready = 0 return end
    --- Internal: frames the list has held the focus.
    st.ready = st.ready + 1
    if st.ready < P.READY_FRAMES then return end
    if VRFW.host.menu_command(P.FOCUS_INDEX, st.layer) ~= st.row then
      if not st.marked then
        st.marked = true
        VRFW.host.menu_command(P.FOCUS_MARK, st.layer, st.row, true)
      end
      return
    end
    local layer, row = st.layer, st.row
    st.layer, st.after = nil, 0
    if type(OnDecideFocus) ~= "function" then
      Log("entry", row, "focused, no OnDecideFocus: left to the player")
      return
    end
    Log("entry", row, "pressed", st.option >= 0 and ("option " .. st.option) or "")
    st.opened, st.opened_up = nil, 0
    if st.option >= 0 or st.back_to_title then Wrap(true) end
    if st.option >= 0 then Answer(true) end
    --- Internal: coroutine pressing the entry.
    st.co = coroutine.create(function() OnDecideFocus(layer, row) end)
    local ok, err = coroutine.resume(st.co)
    if not ok then Log("press error:", tostring(err)) st.co = nil end
  end

  if type(Step) == "function" then
    local step_before = Step
    Step = function(...)
      local r = table.pack(step_before(...))
      local ok, err = pcall(PickStep)
      if not ok then Log("error:", tostring(err)) end
      return table.unpack(r, 1, r.n)
    end
  end
end
