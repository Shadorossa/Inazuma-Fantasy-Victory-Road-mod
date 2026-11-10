if VRFW.host ~= nil then
  local MCL = {
    LIST = 1107559438,        -- team05_03_soccer_cpu_opponent_list
    ITEM = 1074924810,        -- mainmenu90_19_vs_cpu_list_item
    FOCUS_DATA = 1666448199,  -- (0) -> ok, the focused row's game
    GUIDE = 3078308064,       -- mainmenu90_05_content_guide_line01
    GUIDE_MESH = 378156699,   -- _text_guide01
    GUIDE_RETAIL = 3822200449, -- the retail guide text
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,    -- CMND_SET_MENU_TEXT_STRING
    TEXT_GET = VRFW.commands.TEXT_GET,
    HEAD = 2317620035,
    shown = false,
  }

  local function focused_game()
    local okd, game = VRFW.host.menu_command(MCL.FOCUS_DATA, 0)
    if okd and type(game) == "number" and game ~= 0 then
      return game
    end
    return nil
  end

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnEnter", {
    id = "menu_engine.match_challenge", phase = "around",
    fn = function(nxt, a1, a2, ...)
      local r = table.pack(nxt(a1, a2, ...))
      if a1 ~= MCL.LIST or r[1] == 1 or VRFW.match_challenge == nil then
        return table.unpack(r, 1, r.n)
      end
      local game = focused_game()
      if game ~= nil and not VRFW.match_challenge.gate(game, 0) then
        return 1
      end
      return table.unpack(r, 1, r.n)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", {
    id = "menu_engine.match_challenge", phase = "after",
    fn = function(r, a1, ...)
      if a1 ~= MCL.ITEM or VRFW.match_challenge == nil then
        return
      end
      local game = focused_game()
      local title = game and VRFW.match_challenge.title_of(game)
      if title ~= nil then
        local head = VRFW.host.command(MCL.TEXT_GET, MCL.HEAD)
        local s = (type(head) == "string" and head ~= "") and string.format(head, title) or title
        funcLuaMenuCommand(MCL.SET_TEXT, MCL.GUIDE, MCL.GUIDE_MESH, s, 0)
        MCL.shown = true
      elseif MCL.shown then
        local s = VRFW.host.command(MCL.TEXT_GET, MCL.GUIDE_RETAIL)
        funcLuaMenuCommand(MCL.SET_TEXT, MCL.GUIDE, MCL.GUIDE_MESH, s or "", 0)
        MCL.shown = false
      end
    end,
  })
end
