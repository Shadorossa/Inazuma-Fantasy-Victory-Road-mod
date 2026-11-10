-- lua_patch.scope: used
-- Player sets linked to teams: the set list's «Link to this team» action and the write of the active team's linked sets.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.set_links == nil then
  local L = {}
  BetterQoL.set_links = L
  -- the menus that write linked sets (team dock, pre-match formation, the screens that lend bank pages) and the set list
  L.MENUS = {"vrfw_skill_slot_menu", "soccer_team_dock_menu", "soccer_battle_setting_flow_formation_menu",
    "enjoy_team_select_menu_campaign", "enjoy_team_select_menu_offline", "bb_stadium_top_menu", "soccer_top_menu"}
  L.C = {
    STATE = 888530006,            -- CMND_BETTERQOL_SET_LINK_STATE (charaStHdl, set, dock) -> linked
    TOGGLE = 3061068832,          -- CMND_BETTERQOL_SET_LINK_TOGGLE (charaStHdl, set, dock) -> linked now; nil = refused
    PLAN = 1773502038,            -- CMND_BETTERQOL_SET_LINK_PLAN (dock, why) -> count, handles, sets
    VS_TEAM = 3713813716,         -- CMND_GET_VS_USE_TEAM_SET -> the active dock
    TEXT_GET = 4074371074,        -- CMND_TEXT_GET (text id) -> string
    LOG = 519897777,              -- CMND_VRFW_LOG
  }
  L.TEXT = {
    LINK = 1376970206,            -- better_qol_set_link
    UNLINK = 2422789076,          -- better_qol_set_unlink
    LINKED = 3696722984,          -- better_qol_set_linked
  }

  function L.log(...)
    pcall(funcLuaCommand, L.C.LOG, "set links", ...)
  end

  --- The active dock (the team played with); nil when the game does not answer.
  function L.active_dock()
    local ok, dock = pcall(funcLuaCommand, L.C.VS_TEAM)
    return (ok and type(dock) == "number" and dock >= 0) and dock or nil
  end

  local function linked(ctx, dock)
    local ok, on = pcall(funcLuaCommand, L.C.STATE, ctx.chara, ctx.set, dock)
    return ok and on == true
  end

  --- The set list's row action (host CharacterReforged.player_sets.row_action): available, text, row_text, press.
  function L.row_action(phase, ctx)
    local dock = L.active_dock()
    if type(ctx) ~= "table" or ctx.filled ~= true or dock == nil then
      return phase == "available" and false or nil
    end
    if phase == "available" then
      return true
    elseif phase == "text" then
      return linked(ctx, dock) and L.TEXT.UNLINK or L.TEXT.LINK
    elseif phase == "row_text" then
      if not linked(ctx, dock) then
        return ""
      end
      local ok, text = pcall(funcLuaCommand, L.C.TEXT_GET, L.TEXT.LINKED)
      return (ok and type(text) == "string") and text or ""
    elseif phase == "press" then
      local ok, now = pcall(funcLuaCommand, L.C.TOGGLE, ctx.chara, ctx.set, dock)
      L.log("press", string.format("%08X", ctx.chara), "set", ctx.set + 1, "dock", dock, "linked", tostring(ok and now))
      return ok and now ~= nil
    end
    return nil
  end

  --- Writes each linked set of the active team's members with Character Reforged's set writer; members without a
  --- link keep what they have. `why` names the trigger in the log.
  function L.apply_active(why)
    if type(VRFW.team_dock) == "table" and VRFW.team_dock.online() then
      return
    end
    local dock = L.active_dock()
    if dock == nil then
      return
    end
    local ok, count, handles, sets = pcall(funcLuaCommand, L.C.PLAN, dock, why)
    if not ok or type(count) ~= "number" or count <= 0 or type(handles) ~= "table" or type(sets) ~= "table" then
      return
    end
    local writer = type(CharacterReforged) == "table" and CharacterReforged.player_sets or nil
    if type(writer) ~= "table" or type(writer.apply) ~= "function" then
      L.log(why, "dock", dock, count, "linked set(s) not written: Character Reforged's set writer is not loaded")
      return
    end
    local ctx = {dock = dock, kind = 0}
    for i = 1, count do
      local h, set = handles[i], sets[i]
      local okr, p = pcall(writer.read, h, set)
      if not okr or p == nil then
        L.log(why, string.format("%08X", h), "set", set + 1, "is empty or gone: not written")
      else
        ctx.skip = function(reason, kind, value)
          L.log(why, string.format("%08X", h), "set", set + 1, "left out:", reason, kind or "",
            type(value) == "number" and string.format("%08X", value) or "")
        end
        local oka, err = pcall(writer.apply, h, p, ctx)
        if not oka then
          L.log(why, string.format("%08X", h), "set", set + 1, "write failed:", tostring(err))
        end
      end
    end
    L.log(why, "dock", dock, "linked sets written for", count, "player(s)")
  end

  -- A bank page that is mounted, lent or given back holds another team, so its linked sets continue.
  local function wire(TD)
    TD.on("page_changed", "BetterQoL.set_links", function()
      L.apply_active("bank page")
    end)
    TD.on("saved_page_changed", "BetterQoL.set_links", function()
      L.apply_active("lent bank page")
    end)
  end
  if type(VRFW.team_dock) == "table" then
    wire(VRFW.team_dock)
  else
    VRFW.team_dock_queue = VRFW.team_dock_queue or {}
    table.insert(VRFW.team_dock_queue, wire)
  end
end
