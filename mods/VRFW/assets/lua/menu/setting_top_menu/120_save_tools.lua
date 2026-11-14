-- Internal: VRFW > save adjust (docs/framework/save-adjust.md) adds the save adjust row to Options and takes the menu input (through
-- CMND_CHANGE_MENU_INPUT_CTRL / MENU_ACTIVE). No engine call at load time. Log: «VRFW save_adjust …» lines (CMND_VRFW_LOG).

VRFW.save_tools = VRFW.save_tools or {}
local S = VRFW.save_tools

--- Internal: row type index used for the save tools row in the options list.
S.ROW_TYPE = 40                       -- t2[40]: an index no other entry uses (retail 0-4, mods 5-8)
--- Internal: row type index of the licenses entry.
S.LICENSES_TYPE = 3                   -- t2[3] "Licencias"
--- Internal: hash of the small list item layer.
S.SMALL_LIST = 530619243              -- mainmenu90_12_list_item_small
--- Internal: prefix of each listed line.
S.LINE_PREFIX = "· "
--- Internal: spacing text between list columns.
S.COLUMN_GAP = "      "
--- Internal: number of lines of the confirmation window.
S.WINDOW_LINES = 7
--- Internal: number of list lines of the confirmation window.
S.LIST_LINES = S.WINDOW_LINES - 2     -- the confirmation's header and footer lines take the rest
--- Internal: param key hash of the confirmation window.
S.WINDOW_PARAM = 401310444
--- Internal: frames to wait for the auto-save job, at most.
S.SAVE_WAIT_FRAMES = 600              -- the auto-save's job: 10 s at most
--- Internal: command hashes of the save tools (count, get, text and so on).
S.C = {
  COUNT = VRFW.commands.VRFW_SAVE_TOOLS_COUNT,                 -- CMND_VRFW_SAVE_TOOLS_COUNT () -> n
  GET = VRFW.commands.VRFW_SAVE_TOOLS_GET,
  REQUEST = VRFW.commands.VRFW_SAVE_TOOLS_REQUEST,
  RESULT = VRFW.commands.VRFW_SAVE_TOOLS_RESULT,
  RESULT_ITEM = VRFW.commands.VRFW_SAVE_TOOLS_RESULT_ITEM,
  CANCEL = VRFW.commands.VRFW_SAVE_TOOLS_CANCEL,                -- CMND_VRFW_SAVE_TOOLS_CANCEL ()
  SLOT_ACTIVE = VRFW.commands.VRFW_SLOT_ACTIVE,           -- CMND_VRFW_SLOT_ACTIVE () -> slot
  SLOT_RELOAD = VRFW.commands.VRFW_SLOT_RELOAD,            -- CMND_VRFW_SLOT_RELOAD (slot) -> ok
  SLOT_ABORT = VRFW.commands.VRFW_SLOT_ABORT,            -- CMND_VRFW_SLOT_ABORT ()
  TEXT_GET = VRFW.commands.TEXT_GET,              -- CMND_TEXT_GET (menu_text id) -> string
  AUTO_SAVE = VRFW.commands.SYSTEM_AUTO_SAVE,             -- CMND_SYSTEM_AUTO_SAVE
  SAVE_WORKING = 1979970074,          -- a save / load job is running
  SE = VRFW.commands.SND_PLAY_SE,
}
--- Internal: hash of the confirm sound effect.
S.SE_DECIDE = 3848881948              -- sy0000
--- Internal: hash of the error sound effect.
S.SE_ERROR = 2086672038               -- sy0003
--- Internal: text ids of the save tools rows and messages.
S.T = {
  ROW = 3361226603,                   -- vrfw_save_tools_row "Ajustar save"
  ROW_HELP = 1921294418,              -- vrfw_save_tools_row_help
  CONFIRM_ALL = 2566813849,
  CONFIRM = 3734088709,               -- vrfw_save_tools_confirm (%s = the action labels)
  DONE = 3674225646,                  -- vrfw_save_tools_done (%d)
  TO_TITLE = 562068050,               -- vrfw_save_tools_to_title
  NOTHING = 1936425366,               -- vrfw_save_tools_nothing
  BY_LOAD_RULES = 2962265954,         -- vrfw_save_tools_by_load_rules
  FAILED = 42260550,                  -- vrfw_save_tools_failed (%s)
  NONE = 3032341386,                  -- vrfw_save_tools_none
  UNAVAILABLE = 2660106037,           -- vrfw_save_tools_unavailable
  LOCKED = 1994240928,                -- vrfw_save_tools_locked
  RESERVED = 1277745355,              -- vrfw_save_tools_reserved
  BUSY = 79131335,                    -- vrfw_save_tools_busy
}
--- Internal: fallback English text per text id.
S.FALLBACK = {
  [S.T.CONFIRM_ALL] = "This will be applied to your current save:",
  [S.T.CONFIRM] = "%s\nA backup is made first, then you return to the title. Apply?",
  [S.T.DONE] = "Done: %d change(s).",
  [S.T.TO_TITLE] = "The game goes back to the title screen to load the adjusted save.",
  [S.T.NOTHING] = "There was nothing to change: the save stays as it was.",
  [S.T.BY_LOAD_RULES] = "Your mods' load rules had already adjusted this save when it was loaded again.",
  [S.T.FAILED] = "The save could not be adjusted (%s). The save stays as it was.",
  [S.T.NONE] = "None of your mods has adjustments for this save.",
  [S.T.UNAVAILABLE] = "This adjustment has nothing to do with your current mods.",
  [S.T.LOCKED] = "The original save is protected: duplicate it into another slot and adjust the copy.",
  [S.T.RESERVED] = "This save belongs to a mod's mode and cannot be adjusted here.",
  [S.T.BUSY] = "The save cannot be adjusted right now. Try again in a few seconds.",
}
-- Internal: CMND_VRFW_SAVE_TOOLS_REQUEST's refusals -> the message
S.REFUSAL_TEXT = {locked = S.T.LOCKED, reserved = S.T.RESERVED, unavailable = S.T.UNAVAILABLE}

--- Internal: logger of the save tools.
S.log = VRFW.logger.new("VRFW save_adjust")

--- Internal: text of a text id, or its fallback; answers a string.
function S.text(id)
  local s = VRFW.host.command(S.C.TEXT_GET, id)
  if type(s) == "string" and s ~= "" then
    return s
  end
  return S.FALLBACK[id] or ""
end

--- Internal: reads the save adjustment actions from the host; answers a list.
function S.actions()
  local n = VRFW.host.command(S.C.COUNT)
  local out = {}
  for i = 1, (type(n) == "number" and n or 0) do
    local key, label, description, available, mod, result = VRFW.host.command(S.C.GET, i)
    if type(key) == "string" and key ~= "" then
      out[#out + 1] = {key = key, label = label, description = description, available = available == true, mod = mod, result = result}
    end
  end
  return out
end

-- Internal: one result line per action that changed something (its own result text, %d = its count)
function S.summary_lines(items)
  local lines = {}
  for i = 1, (type(items) == "number" and items or 0) do
    local key, _, count, result = VRFW.host.command(S.C.RESULT_ITEM, i)
    if type(key) == "string" and type(count) == "number" and count > 0 then
      local line = S.text(type(result) == "number" and result ~= 0 and result or S.T.DONE)
      if line == "" then line = S.text(S.T.DONE) end
      local ok, text = pcall(string.format, line, count)
      lines[#lines + 1] = ok and text or line
    end
  end
  return lines
end

--- Internal: builds the confirmation question text for a list of actions.
function S.question(actions)
  local labels = {}
  for _, a in ipairs(actions) do
    labels[#labels + 1] = S.LINE_PREFIX .. S.text(a.label)
  end
  local lines = {S.text(S.T.CONFIRM_ALL)}
  if #labels <= S.LIST_LINES then
    for _, label in ipairs(labels) do
      lines[#lines + 1] = label
    end
  else
    for i = 1, #labels, 2 do
      lines[#lines + 1] = labels[i + 1] and (labels[i] .. S.COLUMN_GAP .. labels[i + 1]) or labels[i]
    end
  end
  if #lines + 1 < S.WINDOW_LINES then
    lines[#lines + 1] = ""
  end
  local ok, text = pcall(string.format, S.text(S.T.CONFIRM), table.concat(lines, "\n"))
  return ok and text or table.concat(lines, "\n")
end

-- Internal: the general window's left-aligned look off (only while the question is up)
function S.window_look_off()
  if VRFW.param.has(S.WINDOW_PARAM) then
    VRFW.param.clear(S.WINDOW_PARAM)
  end
end

-- Internal: every available action, after one confirmation
function S.run(actions)
  VRFW.param.set(S.WINDOW_PARAM, 1)
  local asked, yes = pcall(VRFW.question.ask, S.question(actions))
  S.window_look_off()
  if not asked then
    error(yes, 0)
  end
  if not yes then
    return
  end
  local ok, why = VRFW.host.command(S.C.REQUEST, "")
  if ok ~= true then
    S.log("request refused", tostring(why))
    funcLuaCommand(S.C.SE, S.SE_ERROR)
    VRFW.question.notice(S.text(S.REFUSAL_TEXT[why] or S.T.BUSY))
    return
  end
  local slot = VRFW.host.command(S.C.SLOT_ACTIVE)
  VRFW.host.command(S.C.AUTO_SAVE)
  local k = 0
  repeat
    k = k + 1
    coroutine.yield()
  until VRFW.host.command(S.C.SAVE_WORKING) ~= true or k >= S.SAVE_WAIT_FRAMES
  if VRFW.host.command(S.C.SAVE_WORKING) == true then
    S.log("the auto-save is still running after", k, "frames: not adjusted")
    VRFW.host.command(S.C.CANCEL)
    VRFW.question.notice(S.text(S.T.BUSY))
    return
  end
  S.log("saved in", k, "frames; reloading slot", tostring(slot))
  if type(slot) ~= "number" or VRFW.host.command(S.C.SLOT_RELOAD, slot) ~= true then
    S.log("reload of slot", tostring(slot), "refused: not adjusted")
    VRFW.host.command(S.C.CANCEL)
    VRFW.question.notice(S.text(S.T.BUSY))
    return
  end
  local state, count, written, _, text, by_load_rules, items = VRFW.host.command(S.C.RESULT)
  S.log("result", tostring(state), "count", tostring(count), "written", tostring(written), "load rules wrote",
    tostring(by_load_rules), "actions", tostring(items), tostring(text))
  if state == "done" and (written == true or by_load_rules == true) then
    funcLuaCommand(S.C.SE, S.SE_DECIDE)
    local lines = S.summary_lines(items)
    if by_load_rules == true then
      lines[#lines + 1] = S.text(S.T.BY_LOAD_RULES)
    end
    if #lines == 0 then
      local okf, done = pcall(string.format, S.text(S.T.DONE), type(count) == "number" and count or 0)
      lines[1] = okf and done or S.text(S.T.DONE)
    end
    lines[#lines + 1] = S.text(S.T.TO_TITLE)
    VRFW.question.notice(table.concat(lines, "\n"))
    S.log("back to the title: the title loads the adjusted slot", tostring(slot))
    BackToTitle()
    return
  end
  VRFW.host.command(S.C.SLOT_ABORT)
  VRFW.host.command(S.C.CANCEL)
  if state == "done" then
    VRFW.question.notice(S.text(S.T.NOTHING))
  else
    funcLuaCommand(S.C.SE, S.SE_ERROR)
    VRFW.question.notice(string.format(S.text(S.T.FAILED), tostring(text ~= nil and text ~= "" and text or state)))
  end
end

--- Internal: runs one save adjustment session over the available actions.
function S.session()
  local available = {}
  for _, a in ipairs(S.actions()) do
    if a.available then
      available[#available + 1] = a
    end
  end
  if #available == 0 then
    VRFW.question.notice(S.text(S.T.NONE))
    return
  end
  S.run(available)
end

if VRFW.host ~= nil then
  VRFW.host.on("setting_top_menu", "@edit", {
    id = "VRFW.save_adjust.row",
    fn = function(L)
      local t2 = L.t2
      if type(t2) ~= "table" then
        S.log("no locals of setting_top_menu (VRFW.debug off?): no «Ajustar save» row")
        return
      end
      t2[S.ROW_TYPE] = {
        buttonType = 1,
        buttonLayerName = S.SMALL_LIST,
        buttonTextName = S.T.ROW,
        explanationTextName = S.T.ROW_HELP,
        listItemOnTextureName = 0,
        listItemOffTextureName = 0,
        menuObjectName = 0,
      }
    end,
  })
  VRFW.host.on("setting_top_menu", "OnInit", {
    id = "VRFW.save_adjust.order",
    phase = "after",
    fn = function()
      local L = VRFW.host.hosts.setting_top_menu and VRFW.host.hosts.setting_top_menu.L
      local t, t2 = L and L.t, L and L.t2
      if type(t) ~= "table" or type(t2) ~= "table" or t2[S.ROW_TYPE] == nil or L.flag4 ~= true then
        return
      end
      local at = nil
      for i, v in ipairs(t) do
        if v == S.ROW_TYPE then return end
        if v == S.LICENSES_TYPE then at = i end
      end
      if at == nil then
        return
      end
      local n = VRFW.host.command(S.C.COUNT)
      if type(n) ~= "number" or n < 1 then
        return
      end
      table.insert(t, at + 1, S.ROW_TYPE)
      S.log("«Ajustar save» row added", n, "action(s)")
    end,
  })
  VRFW.host.on("setting_top_menu", "OnDecideFocus", {
    id = "VRFW.save_adjust.decide",
    fn = function(nxt, a1, a2, ...)
      if a1 == S.SMALL_LIST and type(GetLitItemType) == "function" and GetLitItemType(a1, a2) == S.ROW_TYPE then
        return S.session()
      end
      return nxt(a1, a2, ...)
    end,
  })

  -- Internal: Diagnostics: row list, list layer setup / open once per open, retail errors, and when Step gives the input.
  S.DIAG_LAYERS = {
    [716364754] = "middle list", [530619243] = "small list", [3214232292] = "PC list locator",
    [168421631] = "console list locator", [1630405233] = "background",
  }
  S.diag_seen, S.diag_input = {}, false

  local function diag_locals()
    local host = VRFW.host.hosts.setting_top_menu
    return host and host.L or {}
  end

  local function diag_rows(t)
    local out = {}
    for i, v in ipairs(type(t) == "table" and t or {}) do
      out[i] = tostring(v)
    end
    return table.concat(out, " ")
  end

  local function diag_hook(point)
    return function(nxt, a1, a2, ...)
      local name = S.DIAG_LAYERS[a1]
      if name == nil then
        return nxt(a1, a2, ...)
      end
      local r = table.pack(pcall(nxt, a1, a2, ...))
      if not r[1] then
        S.log("diag:", point, name, "item", a2, "retail error:", tostring(r[2]))
        error(r[2], 0)
      end
      local key = point .. ":" .. tostring(a1) .. ":" .. tostring(a2)
      if not S.diag_seen[key] then
        S.diag_seen[key] = true
        local L = diag_locals()
        S.log("diag:", point, name, "item", a2, "n", L.n, "n2", L.n2, "flag", L.flag, "answer", tostring(r[2]))
      end
      return table.unpack(r, 2, r.n)
    end
  end

  VRFW.host.on("setting_top_menu", "OnInit", {
    id = "VRFW.save_adjust.diag_init",
    phase = "after",
    fn = function()
      S.diag_seen, S.diag_input = {}, false
      local L = diag_locals()
      S.log("diag: OnInit done, PC list", L.flag4, "rows", diag_rows(L.t))
    end,
  })
  for _, point in ipairs({"OnSetupLayer", "OnOpenLayer", "OnOpenEndLayer"}) do
    VRFW.host.on("setting_top_menu", point, {id = "VRFW.save_adjust.diag_" .. point, fn = diag_hook(point)})
  end
  VRFW.host.on("setting_top_menu", "Step", {
    id = "VRFW.save_adjust.diag_step",
    phase = "after",
    fn = function()
      if not S.diag_input and diag_locals().flag3 == true then
        S.diag_input = true
        S.log("diag: the retail Step gave Options its input")
      end
    end,
  })
end
