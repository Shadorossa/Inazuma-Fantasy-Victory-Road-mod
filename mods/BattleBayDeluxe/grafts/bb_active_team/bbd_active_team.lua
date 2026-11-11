-- name
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.active_team = BattleBayDeluxe.active_team or {}
do
  local B = BattleBayDeluxe.active_team
  B.LEFT = 3003299608 --[[team00_01_chara_card_left]]
  B.RIGHT = 3825623416 --[[team00_01_chara_card_right]]
  B.FORMATION_LEFT = 1324325467
  B.FORMATION_RIGHT = 187604095
  B.TACTICS_LEFT = 2312417854
  B.TACTICS_RIGHT = 909193856
  B.CREST_LEFT = 2813867952
  B.CREST_RIGHT = 2785921709
  B.NAME_LEFT, B.NAME_RIGHT = 2945114490, 2708277675
  B.NAME_TEXT_LEFT, B.NAME_TEXT_RIGHT = 3778687894 --[[_text_team_name01]], 2016633388
  B.CARDS = 11
  B.TEAM_INFO = 2151743654
  B.MEMBER_INFO = 34355761
  B.FORMATION_INFO = @crc:CMND_GET_SOCCER_FORMATION_INFO@
  B.CARD_SETUP = 2339877830
  B.VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
  B.MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
  B.LAYER_NUM = @crc:CMND_GET_CREATE_LAYER_NUM@
  B.ICON_REQUEST = 3190452549
  B.TEXT = @crc:CMND_SET_MENU_TEXT_STRING@
  B.PAGE_REPEAT = @crc:CMND_VRFW_BB_PAGE_REPEAT@
  B.PAGE_PEEK = @crc:CMND_VRFW_BB_PAGE_PEEK@
  -- the pager's category key is "<mod>.<layout Id>" (bb_category.rs), as PAGE_PEEK answers it
  B.SECTION = "BattleBayDeluxe.personal"
  B.PAGE_SLOT = @crc:CMND_VRFW_BB_PAGE_SLOT@
  B.GRID = 106197494 --[[vs01_43_enjoy_team_select_emblem_icon]]
end

-- Mirrors the templates of the page a turn lands on, before the turn builds it; a page with no template shown is passed over.
function BattleBayDeluxe.personal_before_turn(d, mode)
  local B = BattleBayDeluxe.active_team
  if (B.pages or 1) <= 1 or VRFW.battle_bay_pages.p1slot >= 0 then
    return d
  end
  local step = d
  for _ = 1, B.pages do
    local key, page, kept = funcLuaCommand(B.PAGE_PEEK, step, mode)
    if key ~= B.SECTION or kept == true or type(page) ~= "number" then
      return step
    end
    if page ~= B.page then
      B.page = page
      if BattleBayDeluxe.personal_docks_sync("page turned", true) > 0 then
        return step
      end
    else
      return step
    end
    step = step + (d < 0 and -1 or 1)
  end
  return d
end

-- Opens the section on page 1 with one page per tile count of offered templates (one page while a saved run plays a tile).
function BattleBayDeluxe.personal_pages_open()
  local B = BattleBayDeluxe.active_team
  BattleBayDeluxe.personal_run_hold("grid opened")
  B.page = 0
  local tiles = BattleBayDeluxe.personal_docks_sync("grid opened")
  local count = B.offered ~= nil and #B.offered or nil
  B.pages = (count ~= nil and B.run == nil and B.docks ~= nil and #B.docks > 0) and math.max(1, math.ceil(count / #B.docks)) or 1
  if B.pages > 1 then
    VRFW.battle_bay_pages.set_before_turn(BattleBayDeluxe.personal_before_turn)
  end
  funcLuaCommand(B.PAGE_REPEAT, B.SECTION, B.pages)
  BattleBayDeluxe.active_team_log("personal section: " .. tostring(count) .. " templates offered, " .. B.pages .. " page(s), " ..
    tostring(tiles) .. " tiles on page 1")
end

if OnInit ~= nil then
  local init = OnInit
  function OnInit(...)
    local ok, err = pcall(BattleBayDeluxe.personal_pages_open)
    if not ok then
      BattleBayDeluxe.active_team_log("personal templates error", tostring(err))
    end
    return init(...)
  end
end

-- A picked Personal Teams tile plays its template; a template that cannot be lined up is not selectable.
if OnDecideFocus ~= nil then
  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    local B = BattleBayDeluxe.active_team
    if a1 == B.GRID and B.tile_template ~= nil then
      local okt, team = pcall(funcLuaCommand, B.PAGE_SLOT, a2)
      if okt and type(team) == "number" and B.dock_data ~= nil and B.dock_data[team] ~= nil then
        local ok, picked = pcall(BattleBayDeluxe.personal_pick, team)
        if not ok then
          BattleBayDeluxe.active_team_log("pick error", tostring(picked))
          return
        end
        if picked ~= true then
          return
        end
      end
    end
    return decide(a1, a2, ...)
  end
end

-- Hides the cards on the panel side that shows the tile (true or nil means the left side, the player's).
function BattleBayDeluxe.active_team_hide_cards(left)
  local B = BattleBayDeluxe.active_team
  local layer = left and B.LEFT or B.RIGHT
  for i = 0, B.CARDS - 1 do
    funcLuaMenuCommand(B.VISIBLE, layer, i, false)
  end
end

-- Returns whether the Draft screen holds the panel (graft bb_draft).
function BattleBayDeluxe.active_team_draft_holds()
  return type(BattleBayDeluxe.draft) == "table" and BattleBayDeluxe.draft.mode ~= nil
end

-- the team is the tile and this graft draws it
function BattleBayDeluxe.active_team_draws_tile(team)
  local B = BattleBayDeluxe.active_team
  return (team == B.TEAM or (B.dock_data ~= nil and B.dock_data[team] ~= nil)) and not BattleBayDeluxe.active_team_draft_holds()
end

-- the active team's data for the panel (mirrored onto the tile first), nil when it cannot be read
function BattleBayDeluxe.active_team_panel(team)
  local B = BattleBayDeluxe.active_team
  if team ~= B.TEAM and B.dock_data ~= nil and B.dock_data[team] ~= nil then
    return B.dock_data[team]
  end
  local ok, d = pcall(BattleBayDeluxe.active_team_sync, "panel")
  if ok then
    return d
  end
  BattleBayDeluxe.active_team_log("panel error", tostring(d))
  return nil
end

-- Draws the formation of the active team on the tile through the retail UpdateFormation.
function BattleBayDeluxe.active_team_draw_formation(team, left, d)
  local B = BattleBayDeluxe.active_team
  local l1 = left and B.LEFT or B.RIGHT
  local l2 = left and B.FORMATION_LEFT or B.FORMATION_RIGHT
  local _, level = funcLuaCommand(B.TEAM_INFO, team, 4)
  level = level or 0
  funcLuaMenuCommand(B.VISIBLE, l2, 0, true)
  for i = 0, B.CARDS - 1 do
    funcLuaMenuCommand(B.VISIBLE, l1, i, false)
  end
  local shown = 0
  for i = 0, 15 do
    local ok, chara, pos, n4, flag = GetTeamMemberInfo(team, i)
    if ok and type(pos) == "number" and type(chara) == "number" and pos < B.CARDS and d.lineup[pos] ~= nil
      and d.lineup[pos] == VRFW.ids.unsigned(chara) then
      local okb, bits = funcLuaCommand(B.FORMATION_INFO, 6, d.formation, pos)
      bits = okb and bits or 0
      local _, extra = funcLuaCommand(B.MEMBER_INFO, team, pos, 12)
      local drawn = funcLuaMenuCommand(B.CARD_SETUP, l1, pos, chara, false, false, bits, 0, n4, flag, false, extra, level)
      funcLuaMenuCommand(B.VISIBLE, l1, pos, drawn)
      if drawn then
        shown = shown + 1
        funcLuaMenuCommand(B.MESH_VISIBLE, l1, 69091055 --[[_icon_card02]], false, pos)
        funcLuaMenuCommand(B.MESH_VISIBLE, l1, 2843821468 --[[_icon_lock02]], false, pos)
        SetupFormationIconPosition(l1, pos, d.formation, l2, 0.8)
      end
    end
  end
  if B.logged_panel ~= d.text then
    B.logged_panel = d.text
    BattleBayDeluxe.active_team_log(string.format("panel: team set %d, formation %s, %d of 11 starters drawn, captain %s",
      d.set, VRFW.ids.hex_text(d.formation), shown, VRFW.ids.hex_text(d.captain)))
  end
end

-- The panel data of a tile the graft draws (the Active team tile's last read, or its first).
function BattleBayDeluxe.active_team_tile(team)
  local B = BattleBayDeluxe.active_team
  if team == B.TEAM and B.data ~= nil then
    return B.data
  end
  return BattleBayDeluxe.active_team_panel(team)
end

if UpdateFormation ~= nil then
  local formation = UpdateFormation
  function UpdateFormation(a1, a2, ...)
    if not BattleBayDeluxe.active_team_draws_tile(a1) then
      return formation(a1, a2, ...)
    end
    local d = BattleBayDeluxe.active_team_panel(a1)
    if d ~= nil and d.formation ~= nil then
      local ok, err = pcall(BattleBayDeluxe.active_team_draw_formation, a1, a2, d)
      if ok then
        return
      end
      BattleBayDeluxe.active_team_log("panel error", tostring(err))
    end
    -- Handles the case where there is no active team to show.
    local r = table.pack(formation(a1, a2, ...))
    local ok, err = pcall(BattleBayDeluxe.active_team_hide_cards, a2 ~= false)
    if not ok then
      BattleBayDeluxe.active_team_log("panel error", tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end
end

if UpdateTacticsLayer ~= nil then
  local tactics = UpdateTacticsLayer
  function UpdateTacticsLayer(a1, a2, ...)
    local B = BattleBayDeluxe.active_team
    if not BattleBayDeluxe.active_team_draws_tile(a1) then
      return tactics(a1, a2, ...)
    end
    local d = BattleBayDeluxe.active_team_tile(a1)
    if d == nil then
      return tactics(a1, a2, ...)
    end
    local ok, err = pcall(function()
      local l1 = a2 and B.TACTICS_LEFT or B.TACTICS_RIGHT
      local n = funcLuaMenuCommand(B.LAYER_NUM, l1) or 0
      for i = 0, n - 1 do
        funcLuaMenuCommand(B.VISIBLE, l1, i, true)
        UpdateTacticsCmdLayerInfo(l1, i, d.tactics[i] or 0)
      end
    end)
    if not ok then
      BattleBayDeluxe.active_team_log("tactics error", tostring(err))
      return tactics(a1, a2, ...)
    end
  end
end

if UpdateBackgroundIcon ~= nil then
  local crest = UpdateBackgroundIcon
  function UpdateBackgroundIcon(a1, a2, ...)
    local B = BattleBayDeluxe.active_team
    if not BattleBayDeluxe.active_team_draws_tile(a1) then
      return crest(a1, a2, ...)
    end
    local d = BattleBayDeluxe.active_team_tile(a1)
    if d == nil or d.emblem == nil then
      return crest(a1, a2, ...)
    end
    local l1 = a2 and B.CREST_LEFT or B.CREST_RIGHT
    local ok, err = pcall(funcLuaMenuCommand, B.ICON_REQUEST, l1, 0, 3275681157, 3208823925, d.emblem, 1)
    if not ok then
      BattleBayDeluxe.active_team_log("crest error", tostring(err))
      return crest(a1, a2, ...)
    end
  end
end

if UpdateTeamNameText ~= nil then
  local teamName = UpdateTeamNameText
  function UpdateTeamNameText(a1, a2, ...)
    local B = BattleBayDeluxe.active_team
    local r = table.pack(teamName(a1, a2, ...))
    if BattleBayDeluxe.active_team_draws_tile(a1) then
      local d = BattleBayDeluxe.active_team_tile(a1)
      if d ~= nil and d.name ~= "" then
        VRFW.host.menu_command(B.TEXT, a2 and B.NAME_LEFT or B.NAME_RIGHT,
          a2 and B.NAME_TEXT_LEFT or B.NAME_TEXT_RIGHT, d.name)
      end
    end
    return table.unpack(r, 1, r.n)
  end
end

if SetupEmblemIcon ~= nil then
  local icon = SetupEmblemIcon
  function SetupEmblemIcon(a1, a2, ...)
    if a2 == BattleBayDeluxe.active_team.TEAM and BattleBayDeluxe.active_team_draws_tile(a2) then
      local ok, err = pcall(BattleBayDeluxe.active_team_sync, "crest")
      if not ok then
        BattleBayDeluxe.active_team_log("crest sync error", tostring(err))
      end
    end
    return icon(a1, a2, ...)
  end
end
