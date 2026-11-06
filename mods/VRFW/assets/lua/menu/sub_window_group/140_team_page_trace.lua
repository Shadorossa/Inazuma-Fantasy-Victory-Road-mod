-- menu_engine: the sub window (sub_window_group) of a team page or foreign team dock (VRFW_TeamEditor.Foreign()): its
-- setup, its window layer's open, open end and close logged once each per window. Wrappers by assignment (the script
-- has no VRFW_Host host); no engine call at load.
if VRFW_TeamPageSubWindowTrace == nil and type(SetupWindowParams) == "function" and type(OnOpenLayer) == "function" then
  local T = { LOG = VRFW_Cmd.EVT_LOG, logged = {} }
  VRFW_TeamPageSubWindowTrace = T

  local function team_page()
    local editor = VRFW_TeamEditor
    return type(editor) == "table" and type(editor.Foreign) == "function" and editor.Foreign() ~= nil
  end

  local function log_once(step, ...)
    if T.logged[step] or not team_page() then return end
    T.logged[step] = true
    local parts = { "sub window:", step }
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    pcall(funcLuaCommand, T.LOG, "VRFW team editor", table.concat(parts, " "))
  end

  local function window_layer(layer)
    local ok, window = pcall(GetWindowLayerName)
    return ok and layer == window
  end

  local setup = SetupWindowParams
  SetupWindowParams = function(count, texts, size, ...)
    T.logged = {}
    log_once("setup", "entries", count, "size code", size)
    return setup(count, texts, size, ...)
  end

  local open_layer = OnOpenLayer
  OnOpenLayer = function(layer, idx, ...)
    local r = table.pack(open_layer(layer, idx, ...))
    if (idx or 0) == 0 and window_layer(layer) then log_once("window layer opened", layer) end
    return table.unpack(r, 1, r.n)
  end

  if type(OnOpenEndLayer) == "function" then
    local open_end = OnOpenEndLayer
    OnOpenEndLayer = function(layer, idx, ...)
      local r = table.pack(open_end(layer, idx, ...))
      if (idx or 0) == 0 and window_layer(layer) then log_once("window layer open end", layer) end
      return table.unpack(r, 1, r.n)
    end
  end

  if type(OnCloseLayer) == "function" then
    local close_layer = OnCloseLayer
    OnCloseLayer = function(layer, idx, ...)
      local r = table.pack(close_layer(layer, idx, ...))
      if (idx or 0) == 0 and window_layer(layer) then log_once("window layer closed", layer) end
      return table.unpack(r, 1, r.n)
    end
  end
end
