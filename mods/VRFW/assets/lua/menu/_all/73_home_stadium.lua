-- lua_patch.scope: used
-- Defines functions only: no engine call at load time.
VRFW.home_stadium = VRFW.home_stadium or { providers = {} }
do
  local M = VRFW.home_stadium
  M.providers = type(M.providers) == "table" and M.providers or {}

  --- Registers a home-stadium provider; answers true, or false, why.
  function M.register(id, fn)
    if type(id) ~= "string" or type(fn) ~= "function" then
      return false, "an id and a function expected"
    end
    for _, e in ipairs(M.providers) do
      if e.id == id then
        e.fn = fn
        return true
      end
    end
    table.insert(M.providers, { id = id, fn = fn })
    return true
  end

  --- The home stadium of dock `set`: map, provider id; 0 when there is none.
  function M.of(set)
    if type(set) ~= "number" or set < 0 then
      return 0
    end
    for _, e in ipairs(M.providers) do
      local ok, map = pcall(e.fn, set)
      if ok and type(map) == "number" and map ~= 0 then
        return map % 4294967296, e.id
      end
    end
    return 0
  end
end
