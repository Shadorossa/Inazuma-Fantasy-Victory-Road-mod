do
  BetterQoL = BetterQoL or {}
  BetterQoL.career_page = BetterQoL.career_page or {}
  local S = BetterQoL.career_page
  S.TYPE = 6                          -- personal-plate page type (retail 0-4, 5 = Hiper page)
  S.PAGE = 5                          -- page index
  S.WRAPPED = S.WRAPPED or {}
  if VRFW.player_pages ~= nil then
    -- The page is hidden in the Battle Bay mode.
    VRFW.player_pages.add({name = "BetterQoL.Career", index = S.PAGE, type = S.TYPE, last = true, foreign = false,
      enabled = function()
        local ok, on = pcall(funcLuaCommand, 624411898, "battle_bay")
        return not (ok and on == true)
      end,
      page_change = function(fname, orig, a1, a2, ...)
        if type(S.page_change) == "function" then
          return S.page_change(fname, orig, a1, a2, ...)
        end
        return orig(a1, a2, ...)
      end,
      plate_step = function(on, geo)
        if type(S.own_layout) == "function" then
          S.own_layout(on, geo)
        end
      end,
      hide = function()
        if type(S.hide) == "function" then
          S.hide()
        end
      end})
  end

  function S.wrap(name, make, owner)
    owner = owner or _ENV
    local cur = owner[name]
    if type(cur) ~= "function" or S.WRAPPED[cur] then
      return false
    end
    local w = make(cur)
    S.WRAPPED[w] = true
    owner[name] = w
    return true
  end
end
