PL.L_BTN_ROLE = 2399949423
PL.L_ROLE_OPT = 4004028432       -- 3 badge tiles (layer with no focus; input read here)
PL.ROW_ICON_ROLE = 11
-- coach / manager badge items (the shared set writer owns the ids)
PL.ROLE_ITEM = setmetatable({}, {__index = function(_, k) return CharacterReforged.player_sets.ROLE_ITEM[k] end})
function PL.tx_table()
  return {
  ASK_DEL = 1851311630, -- character_reforged_pl_ask_del
  ASK_NAME = 2040755810, -- character_reforged_pl_ask_name
  ASK_OVER = 2474421053, -- character_reforged_pl_ask_over
  BTN_BACK = 430212020, -- retail
  BTN_DELETE = 4075726136, -- character_reforged_pl_btn_delete
  BTN_LOAD = 425936039, -- character_reforged_pl_btn_load
  BTN_REMOVE = 3961481199, -- retail
  BTN_RENAME = 291606001, -- character_reforged_pl_btn_rename
  BTN_RESET = 108624977, -- retail
  BTN_SAVE = 2306442081, -- retail
  BTN_SELECT = 2563379934, -- retail
  EXPORT_DESC = 1866733486, -- character_reforged_pl_export_desc
  EXPORT_DONE = 1960598353, -- character_reforged_pl_export_done
  EXPORT_EMPTY = 902551421, -- character_reforged_pl_export_empty
  EXPORT_FAIL = 3805712563, -- character_reforged_pl_export_fail
  IMPORT_BAD = 3830703186, -- character_reforged_pl_import_bad
  IMPORT_DESC = 2765737925, -- character_reforged_pl_import_desc
  IMPORT_DONE = 3208741690, -- character_reforged_pl_import_done
  IMPORT_GUIDE = 1295583364, -- character_reforged_pl_import_guide
  IMPORT_NONE = 3506201438, -- character_reforged_pl_import_none
  IMPORT_OTHER = 1593834129, -- character_reforged_pl_import_other
  IMPORT_SKIP = 1461335788, -- character_reforged_pl_import_skip
  IMPORT_SUM = 2932163300, -- character_reforged_pl_import_sum
  KB_FAIL = 1902013684, -- character_reforged_pl_kb_fail
  KB_TITLE = 2651967005, -- character_reforged_pl_kb_title
  LOADED_SKIP = 1707515948, -- character_reforged_pl_loaded_skip
  LOADER = 4168068627, -- character_reforged_pl_loader
  PASSIVE = 498819128, -- retail
  PV_SLOT = 2800349027, -- character_reforged_pl_pv_slot
  PV_TITLE = 743529405, -- character_reforged_pl_pv_title
  ROLE_0 = 2405466583, -- character_reforged_pl_role_0
  ROLE_1 = 4167545153, -- character_reforged_pl_role_1
  ROLE_2 = 1634656507, -- character_reforged_pl_role_2
  ROLE_DESC_0 = 3002233678, -- character_reforged_pl_role_desc_0
  ROLE_DESC_1 = 3321185240, -- character_reforged_pl_role_desc_1
  ROLE_DESC_2 = 1560023650, -- character_reforged_pl_role_desc_2
  ROLE_EFF_0 = 3688166492, -- character_reforged_pl_role_eff_0
  ROLE_EFF_1 = 2899559626, -- character_reforged_pl_role_eff_1
  ROLE_EFF_2 = 903517552, -- character_reforged_pl_role_eff_2
  ROLE_FAIL = 1340423822, -- character_reforged_pl_role_fail
  ROLE_GUIDE = 3478606387, -- character_reforged_pl_role_guide
  ROLE_NOREC = 501768028, -- character_reforged_pl_role_norec
  ROLE_NOW = 1597631932, -- character_reforged_pl_role_now
  ROLE_STORY = 4003434814, -- character_reforged_pl_role_story
  ROLE_TITLE = 788524397, -- character_reforged_pl_role_title
  SET_BTN = 276599986, -- character_reforged_pl_set_btn
  SET_BTN_GUIDE = 250455123, -- character_reforged_pl_set_btn_guide
  SET_EMPTY = 2336990961, -- character_reforged_pl_set_empty
  SET_EXPORT_ROW = 1925882483, -- character_reforged_pl_set_export_row
  SET_GUIDE = 689069056, -- character_reforged_pl_set_guide
  SET_HINT_1 = 1944809485, -- character_reforged_pl_set_hint_1
  SET_HINT_2 = 3940688311, -- character_reforged_pl_set_hint_2
  SET_IMPORT_ROW = 2392933827, -- character_reforged_pl_set_import_row
  SET_N = 1055571349, -- character_reforged_pl_set_n
  SET_OLD = 2053797542, -- character_reforged_pl_set_old
  SKIP_FAIL = 3723991224, -- character_reforged_pl_skip_fail
  SKIP_IDOL = 3573935491, -- character_reforged_pl_skip_idol
  SKIP_INUSE = 686318961, -- character_reforged_pl_skip_inuse
  SKIP_LOCKED = 3038617995, -- character_reforged_pl_skip_locked
  SKIP_NOTOWN = 2855493303, -- character_reforged_pl_skip_notown
  SKIP_PRIME = 2661948782, -- character_reforged_pl_skip_prime
  SKIP_ROW = 2318211684, -- character_reforged_pl_skip_row
  SIG_GUIDE = 680251164, -- character_reforged_pl_sig_guide
  SIG_NONE = 3538042118, -- character_reforged_pl_sig_none
  SS_BTN_EQUIPPED = 2314237851, -- character_reforged_pl_ss_btn_equipped
  SS_BTN_GUIDE = 491689945, -- character_reforged_pl_ss_btn_guide
  SS_GUIDE = 290376871, -- character_reforged_pl_ss_guide
  SS_NONE = 340935909, -- character_reforged_pl_ss_none
  SS_QUIT = 677942207, -- character_reforged_pl_ss_quit
  SUM_EQUIP = 2667753651, -- character_reforged_pl_sum_equip
  SUM_HIPER = 3058689977, -- character_reforged_pl_sum_hiper
  SUM_MIX = 2126445994, -- character_reforged_pl_sum_mix
  SUM_MOVES = 676231985, -- character_reforged_pl_sum_moves
  SUM_PASSIVE = 2496586747, -- character_reforged_pl_sum_passive
  }
end
PL.TX = PL.tx_table()
PL.ROLE_TX = {[0] = PL.TX.ROLE_0, [1] = PL.TX.ROLE_1, [2] = PL.TX.ROLE_2}
PL.ROLE_DESC_TX = {[0] = PL.TX.ROLE_DESC_0, [1] = PL.TX.ROLE_DESC_1, [2] = PL.TX.ROLE_DESC_2}
PL.ROLE_EFF_TX = {[0] = PL.TX.ROLE_EFF_0, [1] = PL.TX.ROLE_EFF_1, [2] = PL.TX.ROLE_EFF_2}

-- Returns a menu_text row (CMND_TEXT_GET) with <VALUE> replaced.
function PL.txt(id, value)
  local ok, s = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@, id)
  if not ok or type(s) ~= "string" then
    s = ""
  end
  if type(value) == "table" then
    for tag, v in pairs(value) do
      local text = tostring(v)
      s = string.gsub(s, "<" .. tag .. ">", function()
        return text
      end)
    end
  elseif value ~= nil then
    local v = tostring(value)
    s = string.gsub(s, "<VALUE>", function()
      return v
    end)
  end
  return s
end

function PL.role_name(r)
  return PL.txt(PL.ROLE_TX[r] or PL.TX.ROLE_0)
end
PL.TEX_BADGE = 1461205148
PL.BADGE_SPR = {[0] = 1212007845, [1] = 2386695893, [2] = 2633480507}
PL.BTN_SLOTS = {0x68DA0494, 0x060694A0}         -- cmn03_07 base quads (off / on + add): texture-slot hashes
PL.ICON_NODE = 3165767436       -- mesh of the row-layer icon
PL.ICON_TEX = 3234721532                        -- icon_teambuff_dmy01 (texture slot of that mesh)
PL.SUBWIN_TEXT = 2315959435                     -- 0x8A0ABC8B (row 0.., string)
PL.SUBWIN_POS = 63483614
PL.ADD_ITEM = @crc:CMND_ADD_ITEM_ONLY@                        -- (item, count, flag)
PL.DEL_ITEM = @crc:CMND_DELETE_ITEM@                         -- (item, count)
PL.ITEM_NUM = @crc:CMND_GET_ITEM_NUM@                        -- (item)
PL.EQUIPPED_NUM = 556568075                     -- (invHdl) -> copies equipped (retail equip list)
PL.REMOVE_EQUIP = @crc:CMND_REMOVE_EQUIP@                     -- (chara, type)
PL.EQUIP_ITEM = @crc:CMND_EQUIP_ITEM@                       -- (chara, invHdl, type)
PL.SIX_MENU = 3858305496        -- retail "Pasiva personalizada" equip menu (menu registry row)
function PL.pager_def()
  return {
  PAGES = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_PAGES@,
  WORD = 80343219,
  K_PREV = 3966226594,        -- CMD_FUNCL1
  K_NEXT = 942075773,         -- CMD_FUNCR1
  }
end
PL.PAGER = PL.pager_def()
PL.set_page = 1
PL.role_frames = 0
PL.role_shown = nil
PL.role_open = false

function PL.role()
  local ok, r, _, _, native, lock = pcall(funcLuaCommand, @crc:CMND_CHARACTERREFORGED_GET_ROLE@, n)
  if not ok or type(r) ~= "number" then
    return -1, 0, 0
  end
  return r, type(native) == "number" and native or 0, type(lock) == "number" and lock or 0
end

-- Returns the reason of a refusal, so every refusal names its reason.
function PL.role_why(r, lock)
  if r == -1 then
    return PL.txt(PL.TX.LOADER)
  elseif lock == 1 then
    return PL.txt(PL.TX.ROLE_STORY)
  elseif r < 0 then
    return PL.txt(PL.TX.ROLE_NOREC)
  end
  return nil
end

-- Returns the badge icon on the role button.
function PL.role_icon()
  local k = PL.ROW_ICON_ROLE
  local r = PL.role()
  -- slot plate on _teambuff_base01 + the badge item's medal on the icon node (as the board's badge piece)
  ButtonIcon(k, PL.TEX_ITEM01, PL.ROLE_ITEM[r] or PL.ROLE_ITEM[1])
  funcLuaMenuCommand(C.MESH_VISIBLE, L_PV_ROW, 3877027080, true, k)
  funcLuaMenuCommand(C.SPRITE, L_PV_ROW, PL.TEX_BADGE, PL.BADGE_SPR[r] or PL.BADGE_SPR[0], PL.PLATE_SLOT, 0, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_PV_ROW, PL.ICON_NODE, PL.ROLE_ITEM[r] ~= nil, k)
  funcLuaMenuCommand(C.TEXT, PL.L_BTN_ROLE, 950238781 --[[_text_btn01]], "", 0)
  funcLuaMenuCommand(C.TEXT, PL.L_BTN_ROLE, 625330766 --[[_text_cmd01]], "", 0)
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_PV_ROW, k, not character_reforged_pv_open and not PL.role_open)
  return r
end

function PL.guide(t)
  funcLuaMenuCommand(C.TEXT, 3078308064 --[[mainmenu90_05_content_guide_line01]], 378156699 --[[_text_guide01]], t, 0)
end

function PL.role_guide()
  local r, _, lock = PL.role()
  PL.guide(PL.role_why(r, lock) or PL.txt(PL.TX.ROLE_NOW, PL.role_name(r)))
end

function PL.pick(rows, init)
  return PL.list("", rows, init)
end

PL.LIST_ROWS = 9
function PL.list_show(show, title, rows, first, sel)
  for k = 0, BG_COUNT - 1 do
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_BLACKBG, k, show)
    if show then
      funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, L_BLACKBG, k, 3371859161, 0, 753088835 --[[Default]])
    end
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_PV_PANEL, 0, show)
  for k = 0, PL.LIST_ROWS - 1 do
    local i = first + k
    local t = show and rows[i + 1] or nil
    if t ~= nil then
      local L = L_PV_ROW
      RowReset(k)
      funcLuaMenuCommand(C.SPRITE, L, TEXTURE_SOCCER11_20, 1729678359 --[[passive_base01]], 1729678359, 0, k)
      funcLuaMenuCommand(C.TEXT, L, 1868134834 --[[_text_passive01]], (i == sel and "▶  " or "     ") .. t, k)
      pcall(funcLuaMenuCommand, C.TEXT_ALPHA, L, k, 1868134834, i == sel and 1 or 0.55)
    end
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_PV_ROW, k, t ~= nil)
  end
  if show then
    local more = #rows > PL.LIST_ROWS and "   " .. PL.txt(2544447647 --[[skill_table_list_range]],
      {FIRST = first + 1, LAST = math.min(#rows, first + PL.LIST_ROWS), TOTAL = #rows}) or ""
    funcLuaMenuCommand(C.TEXT, L_PV_PANEL, 760999068 --[[_text_page01]], title .. more, 0)
  end
end

function PL.list(title, rows, init)
  local sel = math.max(0, math.min(#rows - 1, init or 0))
  local first = math.max(0, math.min(sel, #rows - PL.LIST_ROWS))
  character_reforged_pv_open = true
  PL.list_show(true, title, rows, first, sel)
  coroutine.yield()
  local function key(k)
    return funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, MENU_CTRL, k)
      or funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]], k)
  end
  local result = -1
  local P = PL.ptr_start()
  while true do
    coroutine.yield()
    local pact, pfirst, psel, owns = PL.ptr_step(P, L_PV_ROW, PL.LIST_ROWS, PL.PTR_PV, first, sel, #rows)
    if key(COMMAND_BACK) then
      funcLuaCommand(C.SE, SE_BACK)
      break
    elseif pact == "pick" or (not owns and (key(COMMAND_ENTER) or key(1651523701 --[[CMD_ENTER_CLICK]]))) then
      funcLuaCommand(C.SE, SE_DECIDE)
      result = pact == "pick" and psel or sel
      break
    elseif key(COMMAND_DOWN) and sel < #rows - 1 then
      sel = sel + 1
      if sel >= first + PL.LIST_ROWS then
        first = first + 1
      end
      funcLuaCommand(C.SE, 2500047763 --[[sy0005 cursor]])
      PL.list_show(true, title, rows, first, sel)
    elseif key(COMMAND_UP) and sel > 0 then
      sel = sel - 1
      if sel < first then
        first = first - 1
      end
      funcLuaCommand(C.SE, 2500047763)
      PL.list_show(true, title, rows, first, sel)
    elseif pact == "moved" then
      first, sel = pfirst, psel
      funcLuaCommand(C.SE, 2500047763)
      PL.list_show(true, title, rows, first, sel)
    end
  end
  PL.list_show(false, title, rows, first, sel)
  character_reforged_pv_open = false
  coroutine.yield()                              -- the closing input must not reach the mod's menu
  RefreshRows()
  character_reforged_icon_frames = math.max(character_reforged_icon_frames, 3)
  PL.role_frames = math.max(PL.role_frames, 3)
  return result
end

PL.L_BADGE = 2320345331
PL.TEX_ITEM01 = 2868599811                      -- #/menu/200_icon/02_icon_item/icon_item01.g4tx
PL.PLATE_SLOT = 2597149412                      -- teambuff_base01 (texture slot of _teambuff_base01)
PL.SLOT_AREA = 566439826                        -- icon_sp_area_dmy01 (texture slot; list row 50 px, panel 170 px)
PL.SLOT_SIXTH = 669321680
PL.MESH_AREA = 2164615260
PL.MESH_SIXTH = 2384755812
PL.BAND_ROLE = {[0] = 6, [1] = 5, [2] = 5}               -- PL.BAND index: grey for none, purple (no element motif) for staff
PL.K_ENTER = 1981080283
PL.K_BACK = 3011112225
PL.K_FUNC1 = 637335895
PL.K_FUNC3 = 3421673595
PL.K_FUNC4 = 1435897304
PL.K_FUNC2 = 3170216173                          -- CMD_FUNC2
PL.I_ENTER = 2750714971                         -- <CMD_ENTER>
PL.I_BACK = 1582778933                          -- <CMD_BACK>
PL.I_FUNC1 = 203473330                          -- <CMD_FUNC1>
PL.I_FUNC3 = 3794706590                         -- <CMD_FUNC3>
PL.I_FUNC4 = 2085238077                         -- <CMD_FUNC4>
PL.I_FUNC2 = 2387151820                         -- <CMD_FUNC2>

function PL.guide_keys(keys)
  local list = {}
  for k, e in ipairs(keys) do
    list[k] = {text = e.text, icon = e.icon, command = e.cmd, offset = k == 1 and 0 or 18}
  end
  VRFW.footer_prompts.set("vrfw_skill_slot_menu", n12, list, 1138543975 --[[mainmenu01_06_base_button_guide]])
end

function PL.key(k)
  return funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, MENU_CTRL, k)
    or funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]], k)
end

-- Draws the integrated panel without the move parts.
function PL.panel_plain(band, name, desc, icon)
  if not funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, L_DETAIL) then
    return
  end
  PL.detail_hide_all()
  for _, pos in ipairs(PL.DETAIL_MOVE_POS) do
    funcLuaMenuCommand(2158717427 --[[locator visible]], L_DETAIL, pos, false, 0)
  end
  for _, mesh in ipairs(PL.DETAIL_MOVE_MESH) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, mesh, false, 0)
  end
  for _, t in ipairs(PL.DETAIL_MOVE_TEXT) do
    funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, t, false, 0)
  end
  for _, pr in ipairs(PL.DETAIL_MOVE_PRIM) do
    funcLuaMenuCommand(1233047821 --[[number visible]], L_DETAIL, 0, pr, false)
  end
  for i = 1, 10 do
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, CALC_CRC(string.format("_tension_on%02d", i)), false, 0)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 1125548721 --[[_sp_base01]], true, 0)
  funcLuaMenuCommand(C.SPRITE, L_DETAIL, PL.PARTS_TEX, PL.BAND[band] or PL.BAND[5], 243934124 --[[sp_base01]], 0, 0)
  if not string.find(desc, "\n", 1, true) then
    desc = PL.wrap_balanced(desc, PL.PLAIN.line_units, PL.PLAIN.lines)
  end
  funcLuaMenuCommand(C.TEXT, L_DETAIL, 1704438437 --[[_text_name01]], name, 0)
  funcLuaMenuCommand(C.TEXT, L_DETAIL, 691026122 --[[_text_flavor01]], desc, 0)
  if icon ~= nil and pcall(icon, L_DETAIL) then
    funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, PL.MESH_AREA, true, 0)
  end
  funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, 1704438437 --[[_text_name01]], true, 0)
  funcLuaMenuCommand(2735666188 --[[text visible]], L_DETAIL, 691026122 --[[_text_flavor01]], desc ~= "", 0)
  -- the retail window base and its quote bar stay off
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, 3303013605 --[[_sp_win_base01]], false, 0)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_DETAIL, PL.PLAIN.quote_line, false, 0)
  pcall(PL.set_detail_layout, "plain")
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_DETAIL, 0, true)
  character_reforged_detail_on = true
end

-- A list in the retail window with guide keys
function PL.page_text(page, pages)
  local word = PL.txt(PL.PAGER.WORD)
  local n = tostring(page) .. "/" .. tostring(pages)
  if word ~= "" then
    n = word .. " " .. n
  end
  return "<CMD_FUNCL1>   " .. n .. "   <CMD_FUNCR1>"
end

-- L1 / R1 of a paged list mode
function PL.page_key()
  if PL.key(PL.PAGER.K_PREV) then
    return -1
  elseif PL.key(PL.PAGER.K_NEXT) then
    return 1
  end
  return nil
end

function PL.list_layers(mode)
  mode = mode or {}
  return mode.list_layer or PL.L_SSLIST, mode.row_layer or PL.L_SSROW, mode.rows or PL.SSROWS, mode.ptr or PL.PTR_SS
end

-- Returns the row that Up or Down goes to (nil means none).
function PL.list_vert(mode, list, sel, dir)
  if mode ~= nil and mode.vert ~= nil then
    local to = mode.vert(list, sel, dir)
    if to == false then
      return nil
    elseif type(to) == "number" then
      return to
    end
  end
  local to = sel + dir
  if to < 0 or to > #list - 1 then
    return nil
  end
  return to
end

function PL.pop_list(list, init, mode)
  local _, RL, NR, PR = PL.list_layers(mode)
  local sel = math.max(0, math.min(#list - 1, init or 0))
  local first = math.max(0, math.min(sel, #list - NR))
  local keys = {}
  local function show()
    PL.list_mode = mode
    PL.ss_list_show(true, list, first, sel)
    keys = mode.keys(list[sel + 1]) or {}
    pcall(PL.guide_keys, keys)
  end
  show()
  coroutine.yield()
  local result, act = -1, nil
  local P = PL.ptr_start()
  while true do
    coroutine.yield()
    local pact, pfirst, psel, owns = PL.ptr_step(P, RL, NR, PR, first, sel, #list)
    if pact == "pick" and (psel ~= sel or PL.ptr_resync) then
      PL.ptr_resync = nil
      first, sel = pfirst, psel                    -- the clicked row first (its keys / act)
      show()
    end
    if mode.tick ~= nil then
      pcall(mode.tick)                             -- per-frame upkeep (the split set row's geometry)
    end
    local hit = nil
    for _, kk in ipairs(keys) do
      local enter = kk.cmd == PL.K_ENTER
      if kk.act ~= nil and ((enter and pact == "pick")
          or (not (enter and owns) and (PL.key(kk.cmd) or (enter and PL.key(1651523701 --[[CMD_ENTER_CLICK]]))))) then
        hit = kk
        break
      end
    end
    local side = nil
    if hit == nil and mode.side ~= nil then
      side = mode.side(list, sel)                  -- left / right between two entries of one row
    end
    if PL.key(COMMAND_BACK) then
      funcLuaCommand(C.SE, SE_BACK)
      break
    elseif side ~= nil then
      sel = side
      first = math.max(0, math.min(first, sel))
      if sel >= first + NR then
        first = sel - NR + 1
      end
      funcLuaCommand(C.SE, 2500047763 --[[sy0005 cursor]])
      show()
    elseif hit ~= nil then
      local r = mode.act(hit.act, list[sel + 1], sel)
      if r == "close" then
        result, act = sel, hit.act
        break
      end
      if mode.refresh ~= nil then
        list = mode.refresh()
      end
      show()
    elseif mode.turn ~= nil and PL.page_key() ~= nil and mode.turn(PL.page_key()) then
      list = mode.refresh()
      sel = math.max(0, math.min(sel, #list - 1))
      first = math.max(0, math.min(first, sel))
      funcLuaCommand(C.SE, 2500047763)
      show()
    elseif mode.step ~= nil and mode.step(list[sel + 1]) then
    elseif PL.key(COMMAND_DOWN) and PL.list_vert(mode, list, sel, 1) ~= nil then
      sel = PL.list_vert(mode, list, sel, 1)
      if sel >= first + NR then
        first = sel - NR + 1
      end
      funcLuaCommand(C.SE, 2500047763 --[[sy0005 cursor]])
      show()
    elseif PL.key(COMMAND_UP) and PL.list_vert(mode, list, sel, -1) ~= nil then
      sel = PL.list_vert(mode, list, sel, -1)
      if sel < first then
        first = sel
      end
      funcLuaCommand(C.SE, 2500047763)
      show()
    elseif pact == "moved" then
      first, sel = pfirst, psel
      funcLuaCommand(C.SE, 2500047763)
      show()
    end
  end
  PL.ss_list_show(false, list, first, sel)
  PL.list_mode = nil
  coroutine.yield()                              -- the closing input must not reach the mod's menu
  RefreshRows()
  pcall(UpdateEquipItemInfo)                     -- the screen's own button guide and panel again
  character_reforged_icon_frames = math.max(character_reforged_icon_frames, 3)
  PL.role_frames = math.max(PL.role_frames, 3)
  return result, act
end

function PL.role_row(k, e, selected)
  local L = PL.L_SSROW
  PL.mx_row_base(L, k, {name = e.name, check = e.current}, selected)
  -- The small quad (_icon_sixth_dmy01) stays hidden in this list; release a miniface that another list bound to it.
  pcall(funcLuaMenuCommand, 4176779611 --[[ResetFaceIcon]], L, k, PL.SLOT_AREA)
  local medal = PL.ROLE_ITEM[e.role]
  if medal ~= nil then
    funcLuaMenuCommand(C.SPRITE, L, PL.TEX_ITEM01, medal, PL.SLOT_AREA, 0, k)
  else
    funcLuaMenuCommand(C.SPRITE, L, PL.TEX_BADGE, PL.BADGE_SPR[0], PL.SLOT_AREA, 0, k)
  end
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.MESH_AREA, true, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.MESH_SIXTH, false, k)
end

-- the width of a text in wrap units (a letter 1, a CJK / kana glyph 2)
function PL.text_units(text)
  local w = 0
  for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    w = w + (#ch >= 3 and 2 or 1)
  end
  return w
end

-- Wraps text in the fewest lines of at most `units` (up to `lines`), the lines as even as the words allow.
function PL.wrap_balanced(text, units, lines)
  local total = PL.text_units(text)
  local n = math.max(1, math.min(lines, math.ceil(total / units)))
  for w = math.ceil(total / n), units do
    local s = PL.wrap_text(text, w)
    local _, breaks = s:gsub("\n", "")
    if breaks + 1 <= n then
      return s
    end
  end
  return PL.wrap_text(text, units)
end

function PL.wrap_text(text, units)
  local out = {}
  for para in (text .. "\n"):gmatch("(.-)\n") do
    local line, width = "", 0
    local function flush()
      if line ~= "" then
        out[#out + 1] = (line:gsub("%s+$", ""))
      end
      line, width = "", 0
    end
    for word, space in para:gmatch("(%S+)(%s*)") do
      local w = 0
      for ch in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        w = w + (#ch >= 3 and 2 or 1)
      end
      if width > 0 and width + w > units then
        flush()
      end
      line, width = line .. word .. space, width + w + (space ~= "" and 1 or 0)
    end
    flush()
  end
  return table.concat(out, "\n")
end

function PL.role_focus(e)
  local desc, eff = PL.txt(PL.ROLE_DESC_TX[e.role]), PL.txt(PL.ROLE_EFF_TX[e.role])
  PL.panel_plain(PL.BAND_ROLE[e.role], e.name, (desc ~= "" and eff ~= "") and (desc .. " " .. eff) or (desc .. eff),
    function(L)
      local medal = PL.ROLE_ITEM[e.role]
      if medal ~= nil then
        funcLuaMenuCommand(C.SPRITE, L, PL.TEX_ITEM01, medal, PL.SLOT_AREA, 0, 0)
      else
        funcLuaMenuCommand(C.SPRITE, L, PL.TEX_BADGE, PL.BADGE_SPR[0], PL.SLOT_AREA, 0, 0)
      end
    end)
end

function PL.model_visible(visible)
  local h = funcLuaMenuCommand(3895705890 --[[model of a layer]], 2917320188 --[[soccer11_05_equip_status_base]], 0, 0)
  if type(h) == "number" and h ~= 0 then
    funcLuaCommand(1890282463 --[[chara model visible]], h, visible)
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, 858725131 --[[mainmenu01_08_chara_3d_shadow]], 0, visible)
end

function PL.role_coroutine()
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  local cur, native, lock = PL.role()
  local why = PL.role_why(cur, lock)
  if why ~= nil then
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(why)
    funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  local list = {}
  for r = 0, 2 do
    list[#list + 1] = {role = r, name = PL.role_name(r), current = r == cur}
  end
  PL.role_open = true
  -- Shows only "Select" in the guide (the corner return guide mainmenu01_10 already shows Esc), hides the 3D model under the list and titles the header.
  local keys = {{text = PL.TX.BTN_SELECT, icon = PL.I_ENTER, cmd = PL.K_ENTER, act = "pick"}}
  pcall(PL.model_visible, false)
  PL.header_title(PL.txt(PL.TX.ROLE_TITLE))
  local okp, pick = pcall(PL.pop_list, list, math.max(0, math.min(2, cur)), {
    row = PL.role_row, focus = PL.role_focus, guide = PL.txt(PL.TX.ROLE_GUIDE),
    keys = function()
      return keys
    end,
    act = function()
      funcLuaCommand(C.SE, SE_DECIDE)
      return "close"
    end})
  PL.role_open = false
  PL.header_title(nil)
  pcall(PL.model_visible, true)
  if not okp then
    error(pick, 0)
  end
  if pick >= 0 and (pick ~= cur or (pick == 0 and native ~= 0)) then
    if pick ~= 0 then
      funcLuaCommand(PL.ADD_ITEM, PL.ROLE_ITEM[pick], 1, false)   -- a free copy for the equip (retail shares stacks)
    end
    local st, now = Call(@crc:CMND_CHARACTERREFORGED_SET_ROLE@, n, pick)
    Log("role", n, cur, "->", pick, "native", native, "status", st, "now", now)
    if st == 1 then
      funcLuaCommand(C.SE, SE_DECIDE)
    else
      funcLuaCommand(C.SE, SE_NG)
      -- Never a silent refusal: story copy -9, not a saved player -5, else the status code; -10 means below the role medal match count and the free copy goes back.
      if st == -10 and pick ~= 0 then
        funcLuaCommand(PL.DEL_ITEM, PL.ROLE_ITEM[pick], 1)
      end
      local msg = (st == -9 and PL.role_why(0, 1)) or (st == -5 and PL.role_why(-5, 0))
        or (st == -10 and PL.txt(3953080041 --[[betterqol_role_need_matches]], now)) or PL.txt(PL.TX.ROLE_FAIL, st)
      VRFW.question.notice(msg)
    end
  end
  PL.role_icon()
  PL.role_guide()
  UpdateCharaStatus()
  coroutine.yield()                              -- the confirming input must not reach the mod's menu
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end

PL.SS_ITEMS = {3910925277, 1880271463, 118856433, 2574323538, 4000726980, 2004840062,
  7888616, 2428978041, 3888149487, 2265446922, 4026583708, 1762237222, 504277936,
  2154446355, 4151119493, 1852071743, 425947049, 2312925752, 4275782318, 2888477129,
  3677198687, 1109706981, 891549811, 2873585104, 3695205702, 1162415356, 843988074,
  2733711867, 3589673325, 3039926408, 3258361886, 1530919332, 741919026, 2992397457,
  3311102983, 1548893629, 726994219}

function PL.equip_ids()
  return CharacterReforged.player_sets.equip_ids(n)
end

function PL.set_get(i)
  return CharacterReforged.player_sets.read(n, i)
end

-- the player's current build in the set format (rows that cannot take a move count as empty)
function PL.set_current()
  local cur = {moves = {}, equip = PL.equip_ids()}
  for r = 0, ROW_NUM - 1 do
    local s = (r == 0 or not CharacterReforged.skill_table_is_locked(r)) and Skill(r) or 0
    if r == 0 then
      cur.hiper = to_u32(s or 0)
    else
      cur.moves[r] = to_u32(s or 0)
    end
  end
  local _, ss = SkillSlotGet()
  cur.sixsense = to_u32(ss or 0)
  -- the kit (uniformId) of the team this screen edits, kept with a saved set for its row's miniface
  local okk, has, kit = pcall(funcLuaCommand, @crc:CMND_GET_TEAM_SET_INFO@, n3, n17, 7)
  cur.kit = (okk and has and type(kit) == "number") and to_u32(kit) or 0
  local okm, mix = pcall(PL.hs_mix)                  -- the mix slot (0 = empty or no mix store)
  cur.mix = (okm and type(mix) == "number") and mix or 0
  return cur
end

function PL.set_same(p, cur)
  if p == nil then
    return false
  end
  for k = 1, 6 do
    if (p.moves[k] or 0) ~= (cur.moves[k] or 0) then
      return false
    end
  end
  for k = 1, 5 do
    if (p.equip[k] or 0) ~= (cur.equip[k] or 0) then
      return false
    end
  end
  if (p.mix or 0) ~= 0 and p.mix ~= (cur.mix or 0) then
    return false
  end
  return p.hiper == cur.hiper and p.sixsense == cur.sixsense
end

function PL.item_name(id)
  local nm = funcLuaCommand(@crc:CMND_GET_ITEM_PARAM@, id, 0)
  return type(nm) == "string" and nm or string.format("%08X", id)
end

-- Reads the sets per page and pages (config [player_sets]).
function PL.read_set_pages()
  if PL.set_pages == nil then
    local ok, per, pages = pcall(funcLuaCommand, PL.PAGER.PAGES)
    per = ok and tonumber(per) or nil
    pages = ok and tonumber(pages) or nil
    if per == nil or pages == nil then
      Log("player sets pages missing", tostring(per), tostring(pages))
      per, pages = PL.FILE_BTN.SLOT, 1
    end
    PL.set_pages = {per = math.max(1, math.min(math.floor(per), PL.FILE_BTN.SLOT)), pages = math.max(1, math.floor(pages))}
  end
  return PL.set_pages.per, PL.set_pages.pages
end

-- Returns the page holding the set equal to the player's current build (1 when none).
function PL.set_current_page()
  local per, pages = PL.read_set_pages()
  local cur = PL.set_current()
  for i = 0, per * pages - 1 do
    if PL.set_same(PL.set_get(i), cur) then
      return math.floor(i / per) + 1
    end
  end
  return 1
end

function PL.set_turn(dir)
  local _, pages = PL.read_set_pages()
  if pages <= 1 then
    return false
  end
  PL.set_page = (PL.set_page - 1 + dir) % pages + 1
  return true
end

function PL.set_guide()
  local _, pages = PL.read_set_pages()
  local g = PL.txt(PL.TX.SET_GUIDE)
  if pages > 1 then
    g = g .. "     " .. PL.page_text(PL.set_page, pages)
  end
  return g
end

function PL.build_set_list()
  local cur = PL.set_current()
  local list = {}
  local per, pages = PL.read_set_pages()
  PL.set_page = math.max(1, math.min(PL.set_page or 1, pages))
  for i = (PL.set_page - 1) * per, PL.set_page * per - 1 do
    local p = PL.set_get(i)
    local e = {i = i, p = p, first = 0, current = PL.set_same(p, cur)}
    local title = PL.txt(PL.TX.SET_N, i + 1)
    if p == nil then
      e.name = title .. " · " .. PL.txt(PL.TX.SET_EMPTY)
    else
      for k = 1, 6 do
        if e.first == 0 and p.moves[k] ~= 0 then
          e.first = p.moves[k]
        end
      end
      e.name = p.name ~= "" and (title .. " · " .. p.name) or title
      local action = PL.set_action(e)
      local state = action ~= nil and PL.set_action_call(action, "row_text") or nil
      if type(state) == "string" and state ~= "" then
        e.name = e.name .. "  " .. state
      end
    end
    list[#list + 1] = e
  end
  list[#list + 1] = {kind = "vrm", name = PL.txt(PL.TX.SET_EXPORT_ROW),
    names = {PL.txt(PL.TX.SET_EXPORT_ROW), PL.txt(PL.TX.SET_IMPORT_ROW)}}
  PL.set_list = list
  return list
end

function PL.set_face(L, k, kit)
  local param = funcLuaCommand(C.CHARA_GET, n, 4) or 0
  local key = funcLuaCommand(C.CHARA_GET, n, 1) or 0
  local okk, keeper = pcall(MENU_DEF.IsKeeper, param)
  VRFW.face_icon.request(L, k, {handle = n, kind = 255, chara = key}, PL.MESH_AREA, PL.SLOT_AREA,
    {kit = kit or 0, keeper = okk and keeper == true})
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.MESH_AREA, true, k)
end

function PL.set_row_draw(k, e, selected)
  if e.kind == "vrm" then
    PL.vrm_row(k, e, selected)
    return
  end
  local L = PL.L_SSROW
  PL.mx_row_base(L, k, {name = e.name, grey = e.p == nil, check = e.current}, selected)
  pcall(funcLuaMenuCommand, 4176779611 --[[ResetFaceIcon]], L, k, PL.SLOT_AREA)
  if e.p ~= nil then
    pcall(PL.set_face, L, k, e.p.kit)
  end
end

function PL.set_summary(p)
  local mv = {}
  for k = 1, 6 do
    if p.moves[k] ~= 0 then
      mv[#mv + 1] = Name(p.moves[k])
    end
  end
  local lines = {PL.txt(PL.TX.SUM_MOVES, #mv > 0 and table.concat(mv, ", ") or "-")}
  if p.hiper ~= 0 then
    lines[#lines + 1] = PL.txt(PL.TX.SUM_HIPER, Name(p.hiper))
  end
  if (p.mix or 0) ~= 0 then
    lines[#lines + 1] = PL.txt(PL.TX.SUM_MIX, Name(p.mix))
  end
  local eq = 0
  for k = 1, 5 do
    if p.equip[k] ~= 0 then
      eq = eq + 1
    end
  end
  local tail = PL.txt(PL.TX.SUM_EQUIP, eq)
  if p.sixsense ~= 0 then
    tail = tail .. "  ·  " .. PL.txt(PL.TX.SUM_PASSIVE, PL.item_name(p.sixsense))
  end
  lines[#lines + 1] = tail
  return table.concat(lines, "\n")
end

function PL.set_focus(e)
  if e.kind ~= nil then
    local exp = PL.set_kind(e) == "export"
    PL.panel_plain(6, e.names[exp and 1 or 2], PL.txt(exp and PL.TX.EXPORT_DESC or PL.TX.IMPORT_DESC, (PL.set_sel or 0) + 1))
    return
  end
  PL.set_sel = e.i
  if e.p == nil then
    PL.panel_plain(6, e.name, PL.txt(PL.TX.SET_BTN_GUIDE))
    return
  end
  PL.panel_plain(5, e.name, PL.set_summary(e.p), e.first ~= 0 and function(L)
    SetupCommandActionSkillInfoCategoryIcon(L, 0, e.first)
  end or nil)
end

function PL.set_keys(e)
  if e ~= nil and e.kind ~= nil then
    local kind = PL.set_kind(e)
    local tx = kind == "export" and PL.TX.SET_EXPORT_ROW or PL.TX.SET_IMPORT_ROW
    return {{text = tx, icon = PL.I_ENTER, cmd = PL.K_ENTER, act = kind}}
  end
  if e == nil or e.p == nil then
    return {{text = PL.TX.BTN_SAVE, icon = PL.I_ENTER, cmd = PL.K_ENTER, act = "save"}}
  end
  local keys = {{text = PL.TX.BTN_LOAD, icon = PL.I_ENTER, cmd = PL.K_ENTER, act = "load"},
    {text = PL.TX.BTN_SAVE, icon = PL.I_FUNC4, cmd = PL.K_FUNC4, act = "save"},
    {text = PL.TX.BTN_RENAME, icon = PL.I_FUNC1, cmd = PL.K_FUNC1, act = "rename"},
    {text = PL.TX.BTN_DELETE, icon = PL.I_FUNC3, cmd = PL.K_FUNC3, act = "delete"}}
  local action = PL.set_action(e)
  if action ~= nil then
    local text = PL.set_action_call(action, "text")
    text = type(text) == "number" and text or CharacterReforged.skill_table.text_id(action.entry.text)
    if text ~= 0 then
      keys[#keys + 1] = {text = text, icon = PL.I_FUNC2, cmd = PL.K_FUNC2, act = "row_action"}
    end
  end
  return keys
end

-- The set rows' declared action (host CharacterReforged.player_sets.row_action, key CMD_FUNC2): the first entry
-- whose `available` phase answers true for the row; nil without one. Phases: available, text, row_text, press.
PL.SET_ACTION_HOST = "CharacterReforged.player_sets.row_action"
function PL.set_action(e)
  local host = CharacterReforged.skill_table
  if e == nil or e.i == nil or type(host) ~= "table" or type(host.host_entries) ~= "function" then
    return nil
  end
  for _, entry in ipairs(host.host_entries(PL.SET_ACTION_HOST)) do
    local ctx = {key = entry.key, chara = n, set = e.i, filled = e.p ~= nil}
    if host.call(entry, "available", ctx) == true then
      return {entry = entry, ctx = ctx}
    end
  end
  return nil
end

function PL.set_action_call(action, phase)
  return CharacterReforged.skill_table.call(action.entry, phase, action.ctx)
end

function PL.set_write(i, p, name)
  if p == nil then
    local cur = PL.set_current()
    local first = 0
    for r = 1, 6 do
      if first == 0 and cur.moves[r] ~= 0 then
        first = cur.moves[r]
      end
    end
    p = cur
    name = name or (first ~= 0 and Name(first) or PL.txt(PL.TX.SET_N, i + 1))
  end
  local m, e = p.moves, p.equip
  local ok = Call(@crc:CMND_CHARACTERREFORGED_PLAYER_SET_SAVE@, n, i, Cut(name or "", 26), m[1], m[2],
    m[3], m[4], m[5], m[6], p.hiper,
    e[1], e[2], e[3], e[4], e[5], p.sixsense or 0)
  Log("player set save", i, name, ok)
  return ok
end

function PL.set_default_name(i)
  local cur = PL.set_current()
  for r = 1, 6 do
    if cur.moves[r] ~= 0 then
      return Name(cur.moves[r])
    end
  end
  return PL.txt(PL.TX.SET_N, i + 1)
end

-- Opens the game keyboard (PL.ask_name, the save-slot rename's arguments) prefilled with the default.
function PL.set_save(i)
  local name = PL.set_default_name(i)
  local nm = PL.ask_name(name)
  if type(nm) == "string" and nm ~= "" then
    name = nm
  end
  local ok = PL.set_write(i, nil, name)
  funcLuaCommand(C.SE, ok and SE_DECIDE or SE_NG)
end

-- Arguments of the game keyboard (GENERAL_WINDOW.WaitAndSwkbWindowCoroutine, as the save-slot screen's rename).
PL.KB = {OPEN = 962493425, ACTIVE = 422535539, TEXT = 1487869455, CANCELLED = 1447363287, FORCE_END = 3351189333,
  STR_SPACES = 2431241294, MAX = 20}
function PL.ask_name(initial)
  if funcLuaCommand(PL.KB.ACTIVE) then
    funcLuaCommand(PL.KB.FORCE_END, "")
    coroutine.yield()
  end
  local opened = false
  for _ = 1, 2 do
    funcLuaCommand(PL.KB.OPEN, 0, initial or "", PL.TX.KB_TITLE, 0, PL.KB.MAX, 0, 0, 0, 0, 0, 0, true, true, 2,
      PL.txt(PL.TX.KB_TITLE), 0, false, false)
    for _ = 1, 10 do
      if funcLuaCommand(PL.KB.ACTIVE) == true then
        opened = true
        break
      end
      coroutine.yield()
    end
    if opened then
      break
    end
  end
  if not opened then
    return false
  end
  local live = ""
  while funcLuaCommand(PL.KB.ACTIVE) do
    local t = funcLuaCommand(PL.KB.TEXT)        -- live buffer (the final text / cancel flag are not reliable)
    if type(t) == "string" and t ~= "" then
      live = t
    end
    coroutine.yield()
  end
  local text = funcLuaCommand(PL.KB.TEXT)
  local cancelled = funcLuaCommand(PL.KB.CANCELLED) == true
  Log("player set keyboard", "cancelled", tostring(cancelled), "text", tostring(text), "live", live)
  if (type(text) ~= "string" or text == "") and live ~= "" then
    return VRFW.question.ask(PL.txt(PL.TX.ASK_NAME, live)) and live or nil
  end
  if cancelled or type(text) ~= "string" or text == "" or funcLuaCommand(PL.KB.STR_SPACES, text) == true then
    return nil
  end
  return text
end

function PL.set_act(act, e, row)
  local i = e ~= nil and e.i or row                 -- the set's own index (the list shows one page)
  if act == "export" then
    PL.set_export(PL.set_sel or 0)
    return "stay"
  elseif act == "import" then
    PL.set_import(PL.set_sel or 0)
    return "stay"
  elseif act == "load" then
    funcLuaCommand(C.SE, SE_DECIDE)
    return "close"
  elseif act == "row_action" then
    local action = PL.set_action(e)
    local done = action ~= nil and PL.set_action_call(action, "press") == true
    funcLuaCommand(C.SE, done and SE_DECIDE or SE_NG)
  elseif act == "save" then
    if e.p ~= nil and not VRFW.question.ask(PL.txt(PL.TX.ASK_OVER, i + 1)) then
      funcLuaCommand(C.SE, SE_BACK)
      return "stay"
    end
    PL.set_save(i)
  elseif act == "rename" then
    funcLuaCommand(C.SE, SE_DECIDE)
    local nm = PL.ask_name(e.p.name)
    if nm == false then
      funcLuaCommand(C.SE, SE_NG)
      VRFW.question.notice(PL.txt(PL.TX.KB_FAIL))
    elseif nm ~= nil then
      local ok = PL.set_write(i, e.p, nm)
      funcLuaCommand(C.SE, ok and SE_DECIDE or SE_NG)
    end
  elseif act == "delete" then
    if VRFW.question.ask(PL.txt(PL.TX.ASK_DEL, i + 1)) then
      local ok = Call(@crc:CMND_CHARACTERREFORGED_PLAYER_SET_DELETE@, n, i)
      funcLuaCommand(C.SE, ok and SE_REMOVE or SE_NG)
    else
      funcLuaCommand(C.SE, SE_BACK)
    end
  end
  return "stay"
end

-- Returns the invHdl of an owned item with a free copy (moves, equipment and six sense share this).
function PL.free_handle(item)
  local h, why = CharacterReforged.player_sets.free_handle(item)
  local tx = ({["not owned"] = PL.TX.SKIP_NOTOWN, ["no item"] = PL.TX.SKIP_FAIL,
    ["every copy in use"] = PL.TX.SKIP_INUSE})[why]
  return h, why, tx
end

-- The text of one piece the shared set writer left out (its reason, kind and value).
PL.SKIP_TX = {prime = "SKIP_PRIME", row = "SKIP_ROW", idol = "SKIP_IDOL", notown = "SKIP_NOTOWN", inuse = "SKIP_INUSE",
  fail = "SKIP_FAIL", locked = "SKIP_LOCKED"}
function PL.skip_text(reason, kind, value)
  local tx = PL.TX[PL.SKIP_TX[reason] or "SKIP_FAIL"]
  local label = nil
  if kind == "move" then
    label = Name(value)
  elseif kind == "item" then
    label = PL.item_name(value)
  elseif kind == "passive" then
    label = PL.txt(PL.TX.PASSIVE)
  elseif kind == "role" then
    label = PL.role_name(value)
  elseif kind == "pv_slot" then
    label = PL.txt(PL.TX.PV_SLOT, value)
  end
  return PL.txt(tx, label)
end

-- Applies set p.
function PL.set_load(p)
  local skipped = {}
  local ctx = PL.set_ctx()
  ctx.skip = function(reason, kind, value)
    skipped[#skipped + 1] = PL.skip_text(reason, kind, value)
  end
  local ok, err = pcall(CharacterReforged.player_sets.apply, n, p, ctx)
  ctx.skip = nil
  if not ok then
    Log("player set load failed", tostring(err))
  end
  CharacterReforged.skill_table_after_change()
  SkillSlotButtonRefresh()
  UpdateCharaStatus()
  if #skipped > 0 then
    VRFW.question.notice(PL.txt(PL.TX.LOADED_SKIP, table.concat(skipped, ", ")))
  else
    funcLuaCommand(C.SE, SE_DECIDE)
  end
end

function PL.sets_coroutine()
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  if not PL.has_service("player_sets") then
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.LOADER))
    funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  PL.set_page = PL.set_current_page()
  local list = PL.build_set_list()
  local init = 0
  for k, e in ipairs(list) do
    if e.current then
      init = k - 1
    end
  end
  PL.set_sel = list[init + 1] ~= nil and list[init + 1].i or 0
  PL.vrm_half = 0
  local mode = {row = PL.set_row_draw, focus = PL.set_focus, guide = PL.set_guide(), keys = PL.set_keys, act = PL.set_act,
    refresh = PL.build_set_list, side = PL.set_side, vert = PL.set_vert}
  mode.turn = function(dir)
    if not PL.set_turn(dir) then
      return false
    end
    mode.guide = PL.set_guide()
    return true
  end
  local pick, act = PL.pop_list(list, init, mode)
  local picked = PL.set_list ~= nil and PL.set_list[pick + 1] or nil
  if pick >= 0 and act == "load" and picked ~= nil and picked.i ~= nil then
    local p = PL.set_get(picked.i)
    if p ~= nil then
      PL.set_load(p)
    end
  end
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end

function PL.vrm_def()
  return {
  -- The retail header clouds (icon_header_sub_upload01 and download01).
  TEX = 2320109963,           -- #/menu/200_icon/15_icon_common/icon_common.g4tx
  UP = {[true] = 877508820 --[[cr_vrm_up_white]], [false] = 1162370491 --[[cr_vrm_up_dark]]},
  DOWN = {[true] = 2701589519 --[[cr_vrm_down_white]], [false] = 2974155891 --[[cr_vrm_down_dark]]},
  EXPORT = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_EXPORT@,
  LIST = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_IMPORT_LIST@,
  ENTRY = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_IMPORT_ENTRY@,
  READ = @crc:CMND_CHARACTERREFORGED_PLAYER_SET_IMPORT_READ@,
  K_LEFT = 2765147006,        -- CMD_LEFT
  K_RIGHT = 2075023265,       -- CMD_RIGHT
  }
end
PL.VRM = PL.vrm_def()

-- One list entry under #5 (kind "vrm")
function PL.file_btn_def()
  return {
  L = 3904223246 --[[character_reforged_pset_file_btn]],
  SLOT = 5,
  PLATE_X = -98, HALF = 417, GAP = 11,   -- plates 417 wide, the right one at 428 (skill_table.toml)
  }
end
PL.FILE_BTN = PL.file_btn_def()
PL.row_split = {}
PL.vrm_half = 0
PL.file_btn_shown = false

-- a row instance not drawn as the export / import row
function PL.row_full(L, k)
  if L == PL.L_SSROW then
    PL.row_split[k] = nil
  end
end

-- the two export / import buttons off (the set list closed or another list drawn)
function PL.file_btn_hide()
  if not PL.file_btn_shown then
    return
  end
  PL.file_btn_shown = false
  local F = PL.FILE_BTN
  for h = 0, 1 do
    funcLuaMenuCommand(C.LAYER_VISIBLE, F.L, h, false)
  end
  pcall(funcLuaMenuCommand, C.CURSOR_LOC, F.L, 3313461902 --[[cursor]], 2, 2)
end

-- Draws one button.
function PL.file_btn_draw(h, text, on)
  local F = PL.FILE_BTN
  PL.open(F.L, h)
  funcLuaMenuCommand(C.LAYER_VISIBLE, F.L, h, true)
  PL.mx_row_base(F.L, h, {name = text}, on)
  local spr = h == 0 and PL.VRM.UP[on] or PL.VRM.DOWN[on]
  funcLuaMenuCommand(C.SPRITE, F.L, PL.VRM.TEX, spr, PL.SLOT_AREA, 0, h)
  funcLuaMenuCommand(C.MESH_VISIBLE, F.L, PL.MESH_AREA, true, h)
end

function PL.vrm_row(k, e, selected)
  local L, F = PL.L_SSROW, PL.FILE_BTN
  if k ~= F.SLOT then
    -- The layer sits over one row slot only.
    PL.mx_row_base(L, k, {name = e.names[1] .. "  |  " .. e.names[2]}, selected)
    return
  end
  -- The list row under the buttons stays empty.
  PL.mx_row_base(L, k, {name = ""}, false)
  PL.row_split[k] = true
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.SSROW_BASE_ON, false, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.SSROW_BASE_OFF, false, k)
  funcLuaMenuCommand(2735666188 --[[text visible]], L, PL.SSROW_TEXT_ON, false, k)
  funcLuaMenuCommand(2735666188 --[[text visible]], L, PL.SSROW_TEXT_OFF, false, k)
  pcall(funcLuaMenuCommand, 4176779611 --[[ResetFaceIcon]], L, k, PL.SLOT_AREA)
  PL.file_btn_shown = true
  PL.file_btn_draw(0, e.names[1], selected == true and PL.vrm_half == 0)
  PL.file_btn_draw(1, e.names[2], selected == true and PL.vrm_half == 1)
end

-- the list cursor on the focused button while the export / import row has the focus (PL.ss_list_show)
function PL.file_btn_cursor(RL, NR)
  local F = PL.FILE_BTN
  pcall(funcLuaMenuCommand, C.CURSOR_LOC, RL, 3313461902 --[[cursor]], NR, NR)
  pcall(funcLuaMenuCommand, C.CURSOR_LOC, F.L, 3313461902 --[[cursor]], PL.vrm_half == 1 and 1 or 0, 2)
end

-- Declares the pointer zones of the export and import row.
function PL.set_ptr_split(k)
  if PL.row_split[k] then
    local F = PL.FILE_BTN
    return {{F.PLATE_X, F.HALF, PL.PTR_SS[3]}, {F.PLATE_X + F.HALF + F.GAP, F.HALF, PL.PTR_SS[3]}}
  end
  return nil
end
PL.ptr_split = PL.set_ptr_split

-- Returns the entry's action.
function PL.set_kind(e)
  if e ~= nil and e.kind == "vrm" then
    return PL.vrm_half == 1 and "import" or "export"
  end
  return e and e.kind
end

-- Up and Down: Down from #5 lands on "Export set" (left half), Down on the split row stays, Up from it goes back to the last set row.
function PL.set_vert(list, sel, dir)
  local e = list[sel + 1]
  if e == nil then
    return nil
  end
  if e.kind == nil then
    local nx = list[sel + 2]
    if dir > 0 and nx ~= nil and nx.kind == "vrm" then
      PL.vrm_half = 0
    end
    return nil
  end
  if dir > 0 then
    return false
  end
  for k = sel, 1, -1 do
    if list[k] ~= nil and list[k].kind == nil then
      return k - 1
    end
  end
  return false
end

-- Left / Right on the split row
function PL.set_side(list, sel)
  local e = list[sel + 1]
  if e == nil or e.kind ~= "vrm" then
    return nil
  end
  if PL.vrm_half == 0 and PL.key(PL.VRM.K_RIGHT) then
    PL.vrm_half = 1
    return sel
  elseif PL.vrm_half == 1 and PL.key(PL.VRM.K_LEFT) then
    PL.vrm_half = 0
    return sel
  end
  return nil
end

function PL.set_export(i)
  local p = PL.set_get(i)
  if p == nil then
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.EXPORT_EMPTY, i + 1))
    return
  end
  local m, e = p.moves, p.equip
  local pv, cf = p.passives or {}, p.pcfg or {}
  local name = PL.mx_chara_name(funcLuaCommand(C.CHARA_GET, n, 4))
  local level = funcLuaCommand(C.CHARA_GET, n, 0) or 0
  local r = {pcall(funcLuaCommand, PL.VRM.EXPORT, n, name, level, m[1] or 0, m[2] or 0, m[3] or 0, m[4] or 0,
    m[5] or 0, m[6] or 0, p.hiper or 0, e[1] or 0, e[2] or 0, e[3] or 0, e[4] or 0, e[5] or 0, p.sixsense or 0,
    p.role or -1, p.name or "", pv[1] or 0, pv[2] or 0, pv[3] or 0, pv[4] or 0, pv[5] or 0,
    cf[1] or 0, cf[2] or 0, cf[3] or 0, cf[4] or 0, cf[5] or 0, p.kit or 0, p.mix or 0)}
  Log("player set export", i, tostring(r[1]), tostring(r[2]), tostring(r[3]), tostring(r[4]))
  if r[1] and r[2] == true and type(r[3]) == "string" then
    funcLuaCommand(C.SE, SE_DECIDE)
    VRFW.question.notice(PL.txt(PL.TX.EXPORT_DONE, "modloader_exports/" .. tostring(r[4] or "") .. "/" .. r[3]))
  else
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.EXPORT_FAIL))
  end
end

function PL.import_row(k, e, selected)
  local L = PL.L_SSROW
  PL.mx_row_base(L, k, {name = e.name}, selected)
  pcall(funcLuaMenuCommand, 4176779611 --[[ResetFaceIcon]], L, k, PL.SLOT_AREA)
  funcLuaMenuCommand(C.SPRITE, L, PL.VRM.TEX, PL.VRM.DOWN[selected == true], PL.SLOT_AREA, 0, k)
  funcLuaMenuCommand(C.MESH_VISIBLE, L, PL.MESH_AREA, true, k)
end

-- Imports a move of the file, checked against this install and this player.
function PL.import_move(id, hiper, other)
  if id == 0 then
    return 0, true
  end
  local ok, nameId = funcLuaCommand(C.SKILL_INFO, id, 4)
  if not ok or nameId == nil then
    return 0, false
  end
  if IsSpecial(id) ~= hiper then
    return 0, false
  end
  if hiper and other then
    local own = Active(id)
    for b = 0, 8 do
      own = own or BoardSkill(b) == id
    end
    if not own then
      return 0, false
    end
  end
  return id, true
end

function PL.import_item(id)
  if id == 0 then
    return 0, true
  end
  local nm = funcLuaCommand(@crc:CMND_GET_ITEM_PARAM@, id, 0)
  if type(nm) ~= "string" or nm == "" then
    return 0, false
  end
  return id, true
end

function PL.set_import(i)
  local okc, count, area = pcall(funcLuaCommand, PL.VRM.LIST)
  if not okc or type(count) ~= "number" or count <= 0 then
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.IMPORT_NONE, "modloader_exports/" .. tostring(area or "")))
    return
  end
  local files = {}
  for k = 0, count - 1 do
    local oke, file, label = pcall(funcLuaCommand, PL.VRM.ENTRY, k)
    if oke and type(file) == "string" then
      files[#files + 1] = {idx = k, file = file, name = type(label) == "string" and label or file}
    end
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  local pick = PL.pop_list(files, 0, {row = PL.import_row, guide = PL.txt(PL.TX.IMPORT_GUIDE),
    focus = function(f)
      PL.panel_plain(6, f.name, f.file)
    end,
    keys = function()
      return {{text = PL.TX.SET_IMPORT_ROW, icon = PL.I_ENTER, cmd = PL.K_ENTER, act = "pick"}}
    end,
    act = function()
      return "close"
    end})
  if pick < 0 or files[pick + 1] == nil then
    return
  end
  local r = {pcall(funcLuaCommand, PL.VRM.READ, files[pick + 1].idx, n)}
  Log("player set import read", files[pick + 1].file, tostring(r[1]), tostring(r[2]), tostring(r[3]))
  if not r[1] or r[2] ~= true then
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.IMPORT_BAD))
    return
  end
  -- Reads the file fields: ok, set name, chara_param of the file, checksum ok, missing ids (text), m1..m6, hiper, e1..e5, six sense.
  local v = {}
  for k = 7, 37 do
    v[k - 6] = tonumber(r[k]) or 0
  end
  local setname, fparam, sumok, missing = r[3], to_u32(tonumber(r[4]) or 0), r[5] == true, r[6]
  if not sumok and not VRFW.question.ask(PL.txt(PL.TX.IMPORT_SUM)) then
    funcLuaCommand(C.SE, SE_BACK)
    return
  end
  local mine = to_u32(funcLuaCommand(C.CHARA_GET, n, 4) or 0)
  local other = fparam ~= 0 and fparam ~= mine
  local skipped = {}
  if type(missing) == "string" and missing ~= "" then
    skipped[#skipped + 1] = missing
  end
  local p = {name = type(setname) == "string" and setname or "", moves = {}, equip = {}}
  local bad = false
  for k = 1, 6 do
    local id, ok = PL.import_move(to_u32(v[k]), false, other)
    p.moves[k] = id
    if not ok then
      bad = true
      skipped[#skipped + 1] = Name(to_u32(v[k]))
    end
  end
  local hid, hok = PL.import_move(to_u32(v[7]), true, other)
  p.hiper = hid
  if not hok then
    bad = true
    skipped[#skipped + 1] = Name(to_u32(v[7]))
  end
  if other and bad then
    -- Handles another player's set.
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.IMPORT_OTHER))
    return
  end
  for t = 1, 5 do
    local id, ok = PL.import_item(to_u32(v[7 + t]))
    p.equip[t] = id
    if not ok then
      skipped[#skipped + 1] = string.format("%08X", to_u32(v[7 + t]))
    end
  end
  local six, sok = PL.import_item(to_u32(v[13]))
  p.sixsense = six
  if not sok then
    skipped[#skipped + 1] = PL.txt(PL.TX.PASSIVE)
  end
  if v[14] >= 0 and v[14] <= 2 then
    p.role = v[14]
  end
  if v[15] >= 0 then
    p.passives, p.pcfg = {}, {}
    for k = 1, 5 do
      p.passives[k] = to_u32(v[14 + k])
      p.pcfg[k] = to_u32(v[19 + k])
    end
  end
  p.kit = to_u32(v[25])
  local mix, mix_ok = PL.import_move(to_u32(v[26]), true, other)
  p.mix = mix
  if not mix_ok then
    skipped[#skipped + 1] = Name(to_u32(v[26]))
  end
  if PL.set_get(i) ~= nil and not VRFW.question.ask(PL.txt(PL.TX.ASK_OVER, i + 1)) then
    funcLuaCommand(C.SE, SE_BACK)
    return
  end
  local name = p.name ~= "" and p.name or PL.txt(PL.TX.SET_N, i + 1)
  local ok = PL.set_write(i, p, name)
  Log("player set import", i, name, "ok", tostring(ok), "other", tostring(other), "skipped", #skipped)
  if not ok then
    funcLuaCommand(C.SE, SE_NG)
    VRFW.question.notice(PL.txt(PL.TX.IMPORT_BAD))
  elseif #skipped > 0 then
    funcLuaCommand(C.SE, SE_DECIDE)
    VRFW.question.notice(PL.txt(PL.TX.IMPORT_SKIP, table.concat(skipped, ", ")))
  else
    funcLuaCommand(C.SE, SE_DECIDE)
    VRFW.question.notice(PL.txt(PL.TX.IMPORT_DONE, i + 1))
  end
end

function CharacterReforgedSkillTableOpenOriginalBoard()
  if vrfw_co ~= nil then
    return
  end
  vrfw_co = coroutine.create(function()
    PL.sets_coroutine()
  end)
end

PL.prev_init2 = OnInit
function OnInit()
  if VRFW.param.has(813466851) then       -- formation id (team dock; kept for the six-sense menu)
    PL.formation = VRFW.param.get(813466851)
  end
  PL.prev_init2()
end

function PL.clear_alt_glyph()
  funcLuaMenuCommand(C.TEXT, L_BTN, 950238781 --[[_text_btn01 key glyph]], "", 0)
  funcLuaMenuCommand(C.TEXT, L_BTN, 625330766 --[[_text_cmd01 label: the button is an icon]], "", 0)
end

-- Returns the player-sets button definition.
function PL.save_button_def()
  return {
  ICON = ROW_ICON_PREVIEW,     -- row-layer instance attached at the button (_pos_btn_ico02)
  TEX = 2320109963,           -- #/menu/200_icon/15_icon_common/icon_common.g4tx
  SPRITE = 4128237245,
  PRIORITY = 560,
  IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@,    -- CMND_IS_LAYER_VISIBLE (layer, idx)
  CURSOR = 3313461902,        -- the button's cursor attach (off, as on the other square buttons)
  }
end
PL.SAVE_BUTTON = PL.save_button_def()

function PL.save_icon()
  local B = PL.SAVE_BUTTON
  ButtonIcon(B.ICON, B.TEX, B.SPRITE)
  B.shown = nil                                    -- PL.save_icon_follow sets the visibility on the next frame
end

function PL.save_icon_follow()
  local B = PL.SAVE_BUTTON
  local ok, visible = pcall(funcLuaMenuCommand, B.IS_VISIBLE, L_BTN, 0)
  local show = ok and visible ~= false and not character_reforged_pv_open
  if show ~= B.shown then
    B.shown = show
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_PV_ROW, B.ICON, show)
  end
end

PL.ROLE_SHIFT_X = -80
PL.prev_setup_layer = OnSetupLayer
function OnSetupLayer(a1, a2)
  if a1 == PL.L_BTN_ROLE then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, a1, PL.ROLE_SHIFT_X, 0, 0, a2)
    funcLuaMenuCommand(C.TEXT, a1, 625330766 --[[_text_cmd01]], "", a2)
    funcLuaMenuCommand(C.TEXT, a1, 950238781 --[[_text_btn01]], "", a2)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, a1, a2, 3313461902 --[[cursor]], false)
    return
  elseif a1 == PL.L_BADGE then
    funcLuaMenuCommand(Priority, a1, a2, 906, true)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == PL.L_ROLE_OPT then
    funcLuaMenuCommand(Priority, a1, a2, 895, true)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, a1, a2, 3313461902 --[[cursor]], false)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == L_PV_ROW and a2 == PL.ROW_ICON_ROLE then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, a1, PL.ROLE_SHIFT_X, 0, 0, a2)
    funcLuaMenuCommand(Priority, a1, a2, 560, true)
    pcall(PL.role_icon)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, true)
    return
  elseif a1 == L_PV_ROW and a2 == PL.SAVE_BUTTON.ICON then
    funcLuaMenuCommand(Priority, a1, a2, PL.SAVE_BUTTON.PRIORITY, true)
    pcall(PL.save_icon)
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, true)
    return
  end
  PL.prev_setup_layer(a1, a2)
  if a1 == L_BTN then
    PL.clear_alt_glyph()                               -- no key glyph and no label: the button is an icon
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, a1, a2, PL.SAVE_BUTTON.CURSOR, false)
  end
end

PL.prev_open_layer = OnOpenLayer
function OnOpenLayer(a1, a2)
  if a1 == PL.L_BTN_ROLE then
    funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, a1, a2, 2734777837 --[[Focus]], 2, 973515837 --[[button]])
    return
  elseif a1 == PL.L_ROLE_OPT then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    return
  elseif a1 == PL.L_BADGE then
    funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, PL.role_open)
    return
  elseif a1 == L_PV_ROW and (a2 == PL.ROW_ICON_ROLE or a2 == PL.SAVE_BUTTON.ICON) then
    PL.role_frames = 10                            -- the open restores mesh visibility: re-apply the icons
    return
  end
  PL.prev_open_layer(a1, a2)
  if a1 == L_BTN then
    PL.clear_alt_glyph()
  end
end

PL.prev_change_focus = OnChangeFocus
function OnChangeFocus(a1, a2)
  if a1 == PL.L_BTN_ROLE then
    n14 = L_BTN
    UpdateEquipItemInfo()
    pcall(PL.role_guide)
    return
  end
  PL.prev_change_focus(a1, a2)
  if a1 == L_BTN then
    PL.guide(PL.txt(PL.TX.SET_BTN_GUIDE))
  end
end

PL.prev_decide = OnDecideFocus
function OnDecideFocus(a1, a2)
  if a1 == PL.L_BTN_ROLE then
    if vrfw_co == nil then
      vrfw_co = coroutine.create(function()
        PL.role_coroutine()
      end)
    end
    return
  end
  PL.prev_decide(a1, a2)
end

PL.prev_function = OnFunction
function OnFunction(a1, a2)
  if a1 == 3918588344 then                       -- CMD_FUNC1 (Alt): free (it opened the original board)
    return
  end
  PL.prev_function(a1, a2)
end

PL.prev_step = Step
function Step()
  PL.prev_step()
  if n ~= nil and n ~= PL.role_shown and vrfw_co == nil then
    PL.role_shown = n
    PL.role_frames = math.max(PL.role_frames, 3)
  end
  if PL.role_frames > 0 and vrfw_co == nil and not character_reforged_pv_open then
    PL.role_frames = PL.role_frames - 1
    pcall(PL.role_icon)
    pcall(PL.save_icon)
    pcall(PL.clear_alt_glyph)
  end
  pcall(PL.save_icon_follow)
end
