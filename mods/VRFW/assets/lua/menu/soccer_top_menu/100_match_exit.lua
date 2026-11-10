do
  local X = VRFW.match_exit
  if type(X) == "table" and not X.hub_wrapped then
    X.hub_wrapped = true
    X.manual = true
    local BACKGROUND = 367379312

    for _, name in ipairs({ "MoveToVsCpuMenuCoroutine", "MoveToVsMydockMenuCoroutine", "OpenList", "RunManageCoroutine" }) do
      local f = rawget(_ENV, name)
      if type(f) == "function" then
        rawset(_ENV, name, function(...)
          if X.born and not X.done and not X.route then
            X.route = true
            if type(X.log) == "function" then X.log("routes on (" .. name .. "): the next menu lands") end
          end
          return f(...)
        end)
      end
    end

    local open_end = rawget(_ENV, "OnOpenEndLayer")
    if type(open_end) == "function" then
      rawset(_ENV, "OnOpenEndLayer", function(a1, ...)
        local r = table.pack(open_end(a1, ...))
        if a1 == BACKGROUND and not X.route and type(X.land) == "function" then
          pcall(X.land, "hub open")
        end
        return table.unpack(r, 1, r.n)
      end)
    end
  end
end
