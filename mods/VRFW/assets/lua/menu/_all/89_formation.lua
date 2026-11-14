-- lua_patch.scope: used
if VRFW.formation == nil then
  local F = { PLAYERS = VRFW.commands.VRFW_FORMATION_PLAYERS }  -- CMND_VRFW_FORMATION_PLAYERS (formation id) -> players
  local known = {}
  --- Advanced: Namespace: formation helpers (players of a formation, pitch layer of a view).
  VRFW.formation = F

  --- Advanced: The players of formation `id`; nil when unknown, 0 when id is no number.
  function F.players(id)
    if type(id) ~= "number" then
      return 0
    end
    id = VRFW.ids.unsigned(id)
    local players = known[id]
    if players == nil then
      players = VRFW.host.command(F.PLAYERS, id)
      if type(players) ~= "number" then
        return nil
      end
      known[id] = players
    end
    return players
  end

  --- Advanced: True for a 5-a-side formation; nil when unknown.
  function F.is_five_a_side(id)
    local players = F.players(id)
    if players == nil then
      return nil
    end
    return players == 5
  end

  -- The two drawing modes of soccer_formation_menu_inc, as its OnInitFormationCommon sets them: pitch layer, team kind,
  -- starters and pitch depth (the INCLUDE's upvalues n81, n80, n82 and n86).
  local VIEW = {
    eleven = { pitch = 3321884270, kind = 0, starters = 11, depth = 94 },   -- soccer11_02_formation_frame
    five = { pitch = 3518110933, kind = 1, starters = 5, depth = 40 },      -- mainmenu04_10_formation_base
  }
  --- Internal: table of the formation views ('eleven', 'five') with their pitch layers.
  F.VIEW = VIEW
  --- Internal: command hash that patches Lua upvalues (fn, expect, value, ...).
  F.UPVALUES = VRFW.ids.crc32("CMND_VRFW_LUA_UPVALUES")   -- (fn, expect, value, ...) -> upvalues changed

  --- Advanced: The pitch layer the formation INCLUDE draws on in view `name` ("eleven" or "five").
  function F.pitch(name)
    return VIEW[name] ~= nil and VIEW[name].pitch or nil
  end

  --- Advanced: Switches the formation INCLUDE of this menu to the 5-a-side drawing (`on`) or the 11-a-side one; answers true and
  --- whether the upvalues were rewritten, or false, why. The 11-a-side view already drawn touches nothing (retail state).
  function F.five_a_side_view(on)
    -- The INCLUDE keeps starters, depth and team kind as upvalues shared by its functions; this one holds all three.
    local holder = VRFW.host.retail_function("UpdateFormationReducedDrawingIconPos")
    if holder == nil then holder = UpdateFormationReducedDrawingIconPos end
    if type(holder) ~= "function" or type(SetFormationLayer) ~= "function" then
      return false, "this menu has no formation INCLUDE"
    end
    -- The view is read from the INCLUDE itself on every call: a menu opened again keeps its Lua state, and its retail
    -- OnSetupLayer puts the 11-a-side pitch back as the formation layer (SetFormationLayer), so no remembered view holds.
    local a, b = VIEW[on and "eleven" or "five"], VIEW[on and "five" or "eleven"]
    local same = funcLuaCommand(F.UPVALUES, holder, b.starters, b.starters, b.depth, b.depth, b.kind, b.kind)
    if same == 3 and not on then return true, false end
    if same ~= 3 then
      local changed = funcLuaCommand(F.UPVALUES, holder, a.starters, b.starters, a.depth, b.depth, a.kind, b.kind)
      if changed ~= 3 then
        return false, "the INCLUDE upvalues answered " .. tostring(same) .. " / " .. tostring(changed) .. " match(es), 3 expected"
      end
    end
    SetFormationLayer(b.pitch)
    return true, same ~= 3
  end
end
