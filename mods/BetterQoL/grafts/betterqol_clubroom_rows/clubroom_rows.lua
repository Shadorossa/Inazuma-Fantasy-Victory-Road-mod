@UPV@
do
  local ROWS = {
    {KIND = 4, LABEL = 1451400137 --[[BetterQoL.ClubStats.Row]], LINE = 3641379591 --[[BetterQoL.ClubStats.RowHelp]],
      ICON = {369117424 --[[`icon_list_s07_on`]], 60904380 --[[icon_list_s07_off]]}, PAGE = "club_stats"},
    {KIND = 5, LABEL = 4006794419 --[[BetterQoL.Album.Row]], LINE = 3645827048 --[[BetterQoL.Album.RowHelp]],
      ICON = {3154739323 --[[`icon_list_s05_on`]], 2036400348 --[[icon_list_s05_off]]}, PAGE = "album"},
  }
  local C = {
    OWNERS = {"OnInit", "SetupListItemButton", "SetupListItemText", "SetupTextureListItem", "GetListButtonLayerIndex",
      "OnDecideFocus", "OnChangeFocus", "OnEnter", "OnSetupLayer"},
    LIST = 530619243,                    -- mainmenu90_12_list_item_small
    HELP = 0,
    FIRST_LABEL = 1172051184,
    FIRST_LINE = 1752451890,
    FIRST_ICON = 2573393831,             -- `t5[1][1]: icon_list_s03_on`
    LOG = 519897777,                    -- CMND_VRFW_LOG
    SOUND = 1917805374, SY_ERROR = 2086672038,
    found = nil, logged = false,
  }
  local BY_KIND = {}
  for _, r in ipairs(ROWS) do
    BY_KIND[r.KIND] = r
  end

  local function IsKinds(v)
    if v[0] ~= nil or #v < 4 or #v > 16 then
      return false
    end
    local seen = {}
    for _, k in ipairs(v) do
      if type(k) ~= "number" or k % 1 ~= 0 or k < 0 or k > 127 or seen[k] then
        return false
      end
      seen[k] = true
    end
    return seen[0] == true and seen[1] == true and seen[2] == true and seen[3] == true
  end

  -- Returns the four lists.
  local function Lists()
    if C.found == nil then
      local f = {}
      f.kinds = upvalue_find(C.OWNERS, IsKinds)
      f.labels = upvalue_find(C.OWNERS, function(v) return v[1] == C.FIRST_LABEL end)
      f.lines = upvalue_find(C.OWNERS, function(v) return v[1] == C.FIRST_LINE end)
      f.icons = upvalue_find(C.OWNERS, function(v)
        return type(v[1]) == "table" and v[1][1] == C.FIRST_ICON
      end)
      if f.kinds == nil or f.labels == nil or f.lines == nil or f.icons == nil then
        return nil
      end
      C.found = f
    end
    return C.found
  end

  local function Add()
    local f = Lists()
    if f == nil then
      return false
    end
    for _, r in ipairs(ROWS) do
      local k = r.KIND
      f.labels[k + 1], f.lines[k + 1], f.icons[k + 1] = r.LABEL, r.LINE, r.ICON
      local present = false
      for _, v in ipairs(f.kinds) do
        present = present or v == k
      end
      if not present then
        local n = #f.kinds
        if f.kinds[n] == C.HELP then
          table.insert(f.kinds, n, k)
        else
          f.kinds[n + 1] = k
        end
      end
    end
    return true
  end

  BetterQoL = BetterQoL or {}
  if BetterQoL.clubroom_rows_wrapped == nil then
    BetterQoL.clubroom_rows_wrapped = {}
  end

  local setup = _ENV.OnSetupLayer
  if type(setup) == "function" and not BetterQoL.clubroom_rows_wrapped[setup] then
    local w = function(a1, a2, ...)
      if a1 == C.LIST and a2 == 0 then
        local ok = Add()
        if not C.logged then
          C.logged = true
          pcall(funcLuaCommand, C.LOG, "BetterQoL clubroom rows",
            ok and string.format("added (%d rows)", #C.found.kinds) or "row lists not found (no VRFW.debug?): no row")
        end
      end
      return setup(a1, a2, ...)
    end
    BetterQoL.clubroom_rows_wrapped[w] = true
    _ENV.OnSetupLayer = w
  end

  local decide = _ENV.OnDecideFocus
  if type(decide) == "function" and not BetterQoL.clubroom_rows_wrapped[decide] then
    local w = function(a1, a2, ...)
      local f = C.found
      local r = a1 == C.LIST and f ~= nil and type(a2) == "number" and BY_KIND[f.kinds[a2 + 1]] or nil
      if r ~= nil then
        local P = type(BetterQoL) == "table" and BetterQoL[r.PAGE] or nil
        if type(P) == "table" and type(P.open) == "function" then
          local ok, err = pcall(P.open)
          if not ok then
            pcall(funcLuaCommand, C.LOG, "BetterQoL " .. r.PAGE .. " open failed", tostring(err))
          end
        else
          pcall(funcLuaCommand, C.SOUND, C.SY_ERROR)
        end
        return
      end
      return decide(a1, a2, ...)
    end
    BetterQoL.clubroom_rows_wrapped[w] = true
    _ENV.OnDecideFocus = w
  end
end
