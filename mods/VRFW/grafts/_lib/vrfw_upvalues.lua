-- EVT upvalue helpers for lua_patch files (docs/game/engine/lua-patches.md "Locales del chunk retail").
local debug_library = VRFW.debug

--- Finds, through the upvalues of the named functions (4 levels deep), a table accepted by pred; answers table, function, upvalue index, or nil.
local function upvalue_find(names, pred)
  if debug_library == nil then
    return nil
  end
  local seen = {}
  local function scan(f, depth)
    if type(f) ~= "function" or seen[f] or depth > 4 then
      return nil
    end
    seen[f] = true
    local i = 1
    while true do
      local n, v = debug_library.getupvalue(f, i)
      if n == nil then
        return nil
      end
      if type(v) == "table" and pred(v) then
        return v, f, i
      end
      if type(v) == "function" then
        local t, o, k = scan(v, depth + 1)
        if t ~= nil then
          return t, o, k
        end
      end
      i = i + 1
    end
  end
  for _, name in ipairs(names) do
    local t, o, k = scan(rawget(_ENV, name), 0)
    if t ~= nil then
      return t, o, k
    end
  end
  return nil
end

--- Joins every upvalue of newf to the same upvalue of oldf; answers their count, or false, why.
local function upvalue_join(newf, oldf)
  if debug_library == nil or type(newf) ~= "function" or type(oldf) ~= "function" then
    return false, "no VRFW.debug, or newf and oldf are not functions"
  end
  local n = 0
  while debug_library.getupvalue(newf, n + 1) ~= nil do
    n = n + 1
  end
  local m = 0
  while debug_library.getupvalue(oldf, m + 1) ~= nil do
    m = m + 1
  end
  if n ~= m then
    return false, string.format("upvalue_join: %d upvalue(s) against %d in the retail function", n, m)
  end
  for i = 1, n do
    debug_library.upvaluejoin(newf, i, oldf, i)
  end
  return n
end
