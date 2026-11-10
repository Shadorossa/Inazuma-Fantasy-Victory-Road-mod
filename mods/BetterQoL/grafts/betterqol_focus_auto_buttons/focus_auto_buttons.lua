BetterQoL = BetterQoL or {}
BetterQoL.focus_auto_buttons_hidden = true

do
  local prevVisible = rawget(_ENV, "SetAutoButtonVisible")
  if type(prevVisible) == "function" then
    rawset(_ENV, "SetAutoButtonVisible", function(show, ...)
      if BetterQoL.focus_auto_buttons_hidden then
        show = false
      end
      return prevVisible(show, ...)
    end)
  end
  local prevSelect = rawget(_ENV, "SelectAutoButton")
  if type(prevSelect) == "function" then
    rawset(_ENV, "SelectAutoButton", function(...)
      if BetterQoL.focus_auto_buttons_hidden then
        return
      end
      return prevSelect(...)
    end)
  end
end
