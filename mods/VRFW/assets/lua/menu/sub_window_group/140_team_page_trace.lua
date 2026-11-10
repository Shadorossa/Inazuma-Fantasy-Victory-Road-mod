if VRFW.team_page_sub_window_trace == nil and type(SetupWindowParams) == "function" and type(OnOpenLayer) == "function" then
  local T = { logged = {} }
  VRFW.team_page_sub_window_trace = T

  local function team_page()
    local editor = VRFW.team_editor
    return type(editor) == "table" and type(editor.foreign) == "function" and editor.foreign() ~= nil
  end

  local log = VRFW.logger.new("VRFW team editor")
  local function log_once(step, ...)
    if T.logged[step] or not team_page() then return end
    T.logged[step] = true
    log("sub window:", step, ...)
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
