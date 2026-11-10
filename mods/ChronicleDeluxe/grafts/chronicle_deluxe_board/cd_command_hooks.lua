-- runs at load but the definitions and the registrations (no engine call).
ChronicleDeluxe = ChronicleDeluxe or {}
ChronicleDeluxe.command = ChronicleDeluxe.command or {}
@LINEUP@
local K = ChronicleDeluxe.command

-- Returns the rows for kind (1 is a gate piece).
function K.rows(rows, kind)
  local s = VRFW.match_difficulty ~= nil and VRFW.match_difficulty.set(kind == 1 and "gate" or "route") or nil
  if s == nil or rows == nil then
    return rows
  end
  local keep = {}
  for i = 1, #rows do
    if s[rows[i].difficultyType] then
      keep[#keep + 1] = rows[i]
    end
  end
  return keep
end

-- Panel layout per list layer kind (0 normal, 1 gate).
K.PANEL = {
  [0] = {node = 785322415 --[[_list_base01]], width = 700, height = 644, slots = 8},
  [1] = {node = 3083223061 --[[_list_base02]], width = 700, height = 472, slots = 5}
}
K.ROW_HEIGHT = 70
K.NODE_SCALE = 2885415772         -- (layer, instance, node, width, height): a quad's size in px

function K.fit_panel(layer, kind, rows, extra)
  local p = K.PANEL[kind]
  if p == nil or rows == nil or rows < 1 then
    return
  end
  funcLuaMenuCommand(K.NODE_SCALE, layer, 0, p.node, p.width, p.height - K.ROW_HEIGHT * (p.slots - rows) + (extra or 0))
end

function K.service_piece()
  return (VRFW.route_board_commands ~= nil and VRFW.route_board_commands.service_piece ~= nil) and VRFW.route_board_commands.service_piece()
end

function K.fits_panel(kind)
  return EVT_ChrFrameFit == nil and VRFW.match_difficulty ~= nil
    and (VRFW.match_difficulty.set(kind == 1 and "gate" or "route") ~= nil or K.service_piece())
end

-- Returns whether this mod's match panel (the team lineup band) owns the panel.
function K.owns_panel(kind)
  return K.fits_panel(kind) and not K.service_piece()
end

-- Autocomplete: Select on the Chronicle row asks the board (vs_route_town_menu) to record the win.
K.SELECT_FUNCTION = 692387310     -- the CMD_FUNCTION of CMD_FUNC2 in this menu's setting (Select, keyboard Tab)
K.SELECT_INPUT = 3170216173 --[[CMD_FUNC2]]
K.SELECT_GLYPH = 3401540579       -- the guide glyph retail pairs with CMD_FUNC2 on this menu
K.AUTOCOMPLETE_TEXT = 3847662389  -- crc32("chronicle_deluxe_autocomplete_prompt")
K.AUTOCOMPLETE_REQUEST = 1168198373 -- crc32("chronicle_deluxe_autocomplete_request"): read by the board
K.CHRONICLE = 1                   -- the Chronicle row's difficultyType
K.ROWS = 284009563                -- vsroute01_16_sub_list
K.MENU = 1193383590               -- vs_route_town_command_select_menu
K.GUIDE_LAYER = 1138543975        -- mainmenu01_06_base_button_guide
K.CMD = {
  GET_CLEAR = 4034518619,         -- CMND_GET_CHRONICLE_CLEAR_STATUS (slot, difficulty)
  GET_LOCK = 3394595467,          -- CMND_GET_CHRONICLE_LOCK_STATUS (slot, difficulty)
  FOCUSED_ROW = 2603265800,       -- (list layer) -> focused row, from 0
  GUIDE_EXTRA = 2190844859,       -- (parent menu, guide layer, 0, on): retail turns it on for a guide with two entries
  SOUND = 1917805374,
  SOUND_DECIDE = 3848881948,      -- sy0000
  CLOSE_MENU = 320421347,         -- CMND_CLOSE_MENU_OBJECT
}

-- Returns the focused battle row.
function K.focused_row()
  return VRFW.route_board_commands.L.t3[VRFW.host.menu_command(K.CMD.FOCUSED_ROW, K.ROWS) + 1]
end

-- Returns whether a row is an open, not yet beaten Chronicle battle.
function K.can_autocomplete(row)
  if row == nil or row.difficultyType ~= K.CHRONICLE or K.service_piece() then
    return false
  end
  local slot = VRFW.route_board_commands.L.n2
  return not funcLuaCommand(K.CMD.GET_LOCK, slot, K.CHRONICLE) and not funcLuaCommand(K.CMD.GET_CLEAR, slot, K.CHRONICLE)
end

-- Closes the menu with the board's request written (no retail result: the board goes back as after Back).
function K.request_autocomplete()
  local L = VRFW.route_board_commands.L
  funcLuaCommand(K.CMD.SOUND, K.CMD.SOUND_DECIDE)
  ChronicleDeluxe.lineup.hide()
  SetupButtonGuide()
  VRFW.param.replace(K.AUTOCOMPLETE_REQUEST, 1)
  funcLuaCommand(K.CMD.CLOSE_MENU, K.MENU)
  L.flag = true
end

if VRFW.host ~= nil then
  VRFW.host.on("vs_route_town_command_select_menu", "VRFW.route_board_commands.rows", {id = "ChronicleDeluxe.board", phase = "around",
    fn = function(nxt, rows, kind, slot)
      return nxt(K.rows(rows, kind), kind, slot)
    end})
  VRFW.host.on("vs_route_town_command_select_menu", "VRFW.route_board_commands.list_layer", {id = "ChronicleDeluxe.panel_fit",
    phase = "after", fn = function(r, layer, kind, rows)
      if K.fits_panel(kind) then
        K.fit_panel(layer, kind, rows, VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel.extra or 0)
      end
    end})
  VRFW.host.on("vs_route_town_command_select_menu", "VRFW.route_board_commands.panel_extra", {id = "ChronicleDeluxe.panel_band",
    phase = "after", fn = function(r, layer, kind, rows, extra)
      if layer ~= nil and K.fits_panel(kind) then
        K.fit_panel(layer, kind, rows, extra)
      end
    end})
  VRFW.host.on("vs_route_town_command_select_menu", "VRFW.route_board_commands.guide", {id = "ChronicleDeluxe.autocomplete",
    phase = "after", fn = function(r, item, icons, texts, commands)
      if K.can_autocomplete(item) then
        icons[#icons + 1], texts[#texts + 1], commands[#commands + 1] = K.SELECT_GLYPH, K.AUTOCOMPLETE_TEXT, K.SELECT_INPUT
        VRFW.host.menu_command(K.CMD.GUIDE_EXTRA, VRFW.route_board_commands.L.n12, K.GUIDE_LAYER, 0, true)
      end
    end})
  VRFW.host.on("vs_route_town_command_select_menu", "OnFunction", {id = "ChronicleDeluxe.autocomplete",
    phase = "before", fn = function(a1)
      local L = VRFW.route_board_commands.L
      if a1 ~= K.SELECT_FUNCTION or L.flag or L.flag2 or not K.can_autocomplete(K.focused_row()) then
        return
      end
      K.request_autocomplete()
      return VRFW.host.HALT
    end})
  ChronicleDeluxe.lineup.register("vs_route_town_command_select_menu", K.owns_panel)
end
