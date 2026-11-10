-- character_reforged_training_menu
INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_MENU_DEF")
INCLUDE("LUA_PERSONAL_PLATE_INC")

local TR = {
  VERSION = @crc:CMND_VRFW_LOADER_VERSION@,  -- () -> api, modules
  INFO = @crc:CMND_CHARACTERREFORGED_TRAINING_INFO@,
                             -- Rule values (0 pairs, 1 pool, 2 trade).
  STAT = @crc:CMND_CHARACTERREFORGED_TRAINING_STAT@,
  SET = @crc:CMND_CHARACTERREFORGED_TRAINING_SET@,
  COMMIT = @crc:CMND_CHARACTERREFORGED_TRAINING_COMMIT@,  -- (hdl) -> ok, status
  CANCEL = @crc:CMND_CHARACTERREFORGED_TRAINING_CANCEL@,  -- (hdl or 0 = all) -> ok
  RESET = @crc:CMND_CHARACTERREFORGED_TRAINING_RESET@,    -- (hdl) -> ok, libAvail
}
local MOD_STAMINA = 256
local ERR_LOCKED = -9            -- TRAIN_* status of a Hero / Diamond / Prime card (training locked)

local TX = {
  TITLE = @crc:character_reforged_tr_title@, TITLE_NONAME = @crc:character_reforged_tr_title0@, POOL = @crc:character_reforged_tr_pool@, LIBERTAD = @crc:character_reforged_tr_lib@,
  LEVEL = @crc:character_reforged_tr_level@, PE = @crc:character_reforged_tr_pe@, PARTNER = @crc:character_reforged_tr_partner@, HELP = @crc:character_reforged_tr_help@,
  HELP10 = @crc:character_reforged_tr_help10@, EMPTY = @crc:character_reforged_tr_empty@, FLOOR = @crc:character_reforged_tr_floor@, CAP = @crc:character_reforged_tr_cap@,
  SAVE = 2306442081, NO_LOADER = @crc:character_reforged_tr_no_loader@, NO_DATA = @crc:character_reforged_tr_no_data@, LOCKED = @crc:character_reforged_tr_locked@,
  ASK_DISCARD = @crc:character_reforged_tr_ask_discard@, ASK_SAVE_SWITCH = @crc:character_reforged_tr_ask_switch@, ASK_RESET = @crc:character_reforged_tr_ask_reset@,
  SAVE_FAILED = @crc:character_reforged_tr_save_failed@, SAVED_HINT = @crc:character_reforged_tr_saved@,
  POS = {[1] = @crc:character_reforged_tr_pos_1@, [2] = @crc:character_reforged_tr_pos_2@, [3] = @crc:character_reforged_tr_pos_3@, [4] = @crc:character_reforged_tr_pos_4@},
  -- Stat ids in engine order.
  STATS = {493890773, 3206121007, 3492422219, 3740714941, 2851206955, 2895498128, 3773956166, @crc:character_reforged_tr_speed@,
           @crc:character_reforged_tr_luck@},
}

local HOLD_GAP = 14          -- frames between two Left/Right events that still count as holding
local HOLD_REPEATS = 6       -- after this many repeats a step is 10 points
local WIN_X, WIN_Y = 640, -60        -- window position (retail bean pop-up: 960, -281)
local GRAPH_X, GRAPH_Y = 1500, -470  -- radar position (retail: 1612, -471)
local DIM = 0.55
local DIM_POOL = 0.8                 -- alpha of the other rows (pool rule: every row can give points)
local PE_FALLBACK = 120

local MENU = 278813410
-- Maps 8 stats (7 retired).
local ROWS = 8
local MAP = {[0] = 0, 1, 2, 3, 4, 5, 6, 8}
local function RowOf(i)
  for k = 0, ROWS - 1 do
    if MAP[k] == i then
      return k
    end
  end
  return 0
end
local L_WIN = 3668985814          -- win06_06_beans_lump_use_window
local L_GAUGE = 3356371999        -- team13_16_beans_gauge (9 instances in the layout, 8 used)
local L_BTN = 790585329           -- cmn03_10_sub_window_button
local L_GRAPH_WIN = 1437851054    -- win05_42_parameter_graph_base
local L_GRAPH_BASE = 1572892955   -- soccer11_06_formation_status_graph_base
local L_GRAPH_NUM = 732343773     -- soccer11_06_p1_formation_status_graph_param_num
local L_GRAPH = 3868632847        -- soccer11_07_formation_status_graph
local N_TITLE = 1460905569
local N_HEAD1 = 3457873883
local N_HEAD2 = 3105736525
local N_HELP = 2996469894
local N_ROW = {4066919363, 1801523833, 476455663, 2181216076, 4110780378,
               1812780640, 453764854, 2343893863, 4239641585}
local N_POS_WIN2 = 715239914
local N_POS_BEANS = 1296624974
local MESH_ICON = 3653430537
local P_NUM_CUR, P_NUM_NEXT, P_NUM_MAX = 3484572139, 1455097937, 1533119290   -- gauge number primitives
local R_GAUGE, R_GAUGE_RED, G_BAR = 1200811757, 2611748497, 1996459178         -- gauge01, gauge01_red, "bar"
local F = {UP = 2899828843, DOWN = 4238056847, LEFT = 2583947996, RIGHT = 1128810052,
           PREV = 1552319969, NEXT = 3830128008, RESET = 2803862557, STEP = 2749232008}
local KEY_HDL = 4161869490        -- retail bean menu key: the character (set by the board)
local KEY_DOCK_OK = 638665151
local KEY_DOCK_NO = 946320615
local KEY_DOCK_TYPE = 2835528766
local C = {
  TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,          -- CMND_SET_MENU_TEXT_STRING (layer, node, string, idx)
  TEXT_GET = @crc:CMND_TEXT_GET@,      -- CMND_TEXT_GET (text id) -> string
  TEXT_ALPHA = @crc:CMND_SET_MENU_TEXT_ALPHA@,    -- (layer, idx, node, alpha)
  MODEL_ALPHA = @crc:CMND_SET_LAYER_MODEL_ALPHA@,   -- (layer, idx, 0, alpha)
  NODE_VISIBLE = 2158717427,  -- (layer, node, bool, idx)
  MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@,  -- (layer, mesh, bool, idx)
  SPRITE = 558735651,         -- (layer, textureCrc, spriteCrc, nodeCrc, 0, idx)
  LOCAL_POS = @crc:CMND_SET_LAYER_LOCAL_POS@,     -- CMND_SET_LAYER_LOCAL_POS (layer, x, y, z)
  PRIORITY = @crc:CMND_SET_DRAW_PRIORITY@,      -- CMND_SET_DRAW_PRIORITY (layer, idx, prio, bool)
  PRIM_INDEX = @crc:CMND_SEARCH_PRIM_INDEX@,    -- (layer, idx, primName) -> prim
  PRIM_VALUE = 3609943765,    -- (layer, idx, prim, value, true)
  PRIM_VISIBLE = 1233047821,  -- (layer, idx, primName, bool)
  GROUP_INDEX = @crc:CMND_GET_GROUP_INDEX@,    -- (layer, idx, group) -> group index
  RATE_BIND = 541357333,      -- (layer, rate, groupIndex, idx)
  RATE_SET = 1595998683,      -- (layer, rate, 0, ratio, idx, false, group)
  CHARA_GET = 1131797651,
  CHARA_NAME = @crc:CMND_GET_CHARA_NAME_TEXT@,    -- CMND_GET_CHARA_NAME_TEXT (hdl) -> string
  TEAM_INFO = @crc:CMND_GET_TEAM_SET_INFO@,     -- CMND_GET_TEAM_SET_INFO (dock, type, 0) -> ok, memberCount
  TEAM_MEMBER = 1720957768,
  SE = @crc:CMND_SND_PLAY_SE@,
  MENU_ACTIVE = 1558704558,   -- (menu, bool)
  CLOSE_MENU = @crc:CMND_CLOSE_MENU_OBJECT@,     -- CMND_CLOSE_MENU_OBJECT
}
local SE_MOVE, SE_OK, SE_DECIDE, SE_BACK, SE_NG = 541750771, 3848881948, 4235359837, 202039849, 2086672038
local ICON_TEX = 502529699        -- #/menu/200_icon/15_icon_common/<LG>/icon_common.g4tx
local ICON_NODE = 1677943612      -- icon_parameter_dmy01

local loader = false
local players = {}
local cur = 1                     -- index in players
local hdl = 0
local name = ""
local info = {ok = false}
local st = {}
local hint = nil                  -- one-shot help line after a refused step (pool empty / floor / cap)
local sel = 0                     -- selected row (engine index)
local step10 = false
local frame, lastDir, lastFrame, rep = 0, 0, -100, 0
local vrfw_co = nil
local closing = false
local saved_hint_shown = false
local gauges_ready = {}

--@lib vrfw_menu_kit.lua#Call

-- errors go to vrfw_loader\loader.log (CMND_VRFW_LOG) and the Lua console
local function Log(msg)
  pcall(funcLuaCommand, @crc:CMND_VRFW_LOG@, "character_reforged_training_menu", tostring(msg))
  pcall(print, "character_reforged_training_menu: " .. tostring(msg))
end

--@lib vrfw_menu_kit.lua#Int

local function Signed(v)
  if v > 0 then
    return "+" .. v
  end
  return tostring(v)
end

-- Returns the menu_text row `id` with <VALUE> and <A>..<D> replaced.
local function Fill(s, a, b, c, d)
  local map = {VALUE = a, A = a, B = b, C = c, D = d}
  return (string.gsub(s, "<(%u+)>", function(k)
    local v = map[k]
    if v == nil then
      return nil
    end
    return tostring(v)
  end))
end

local function RowText0(id)
  local ok, s = pcall(funcLuaCommand, C.TEXT_GET, id)
  if ok and type(s) == "string" and s ~= "" then
    return s
  end
  return ""
end

local function T(key, a, b, c, d)
  return Fill(RowText0(TX[key]), a, b, c, d)
end

local function StatName(i)
  return RowText0(TX.STATS[i + 1])
end

local function PosName(p)
  if TX.POS[p] == nil then
    return ""
  end
  return RowText0(TX.POS[p])
end

local function Param(key)
  if VRFW.param.has(key) then
    local v = VRFW.param.get(key)
    VRFW.param.clear(key)
    return v
  end
  return nil
end

local pe_on = false               -- module stamina reported by the loader

local function LoaderReady()
  local api, mods = Call(TR.VERSION)
  pe_on = type(mods) == "number" and math.floor(mods / MOD_STAMINA) % 2 == 1
  return type(api) == "number"
end

local function PeMax(fisico)
  -- The max PE is per player.
  local ok, max = Call(@crc:CMND_CHARACTERREFORGED_POINTS_STAMINA_MAX@, fisico, hdl)
  if ok == true and type(max) == "number" and max > 0 then
    return math.floor(max + 0.5)
  end
  return PE_FALLBACK
end

-- Returns the PE text, for example "   PE 120".
local function PeText()
  local f = st[4]
  if not pe_on or f == nil or f.value <= 0 then
    return ""
  end
  local now = PeMax(f.value)
  local saved = PeMax(f.value - (f.delta - f.committed))
  local t = "   " .. T("PE", now)
  if now ~= saved then
    t = t .. " (" .. Signed(now - saved) .. ")"
  end
  return t
end

local function Text(node, s)
  funcLuaMenuCommand(C.TEXT, L_WIN, node, s, 0)
end

local function ReadInfo()
  local ok, status, total, avail, level, pos, dirty, _, rule = Call(TR.INFO, hdl, 0)
  info = {ok = ok == true, status = Int(status), total = Int(total), avail = Int(avail), level = Int(level),
          pos = Int(pos), dirty = dirty == true, pool = Int(rule) == 1}
end

local function ReadStats()
  for i = 0, 8 do                  -- every stat slot (7 = retired Rapidez: never shown)
    local ok, v, b, bo, d, cd, mn, mx, p1, p2 = Call(TR.STAT, hdl, i)
    if ok == true then
      st[i] = {value = Int(v), base = Int(b), bonus = Int(bo), delta = Int(d), committed = Int(cd), min = Int(mn),
               max = Int(mx), p1 = Int(p1), p2 = Int(p2)}
    else
      st[i] = {value = 0, base = 0, bonus = 0, delta = 0, committed = 0, min = 0, max = 0, p1 = -1, p2 = -1}
    end
  end
end

-- Returns the value this menu shows and edits.
local function Ev(s)
  return s.base + s.delta
end

local function EvSaved(s)
  return s.base + s.committed
end

-- Computes the bar scale.
local scale = 100
local function UpdateScale(reset)
  local m = 0
  for i = 0, 8 do
    local s = st[i]
    if s then
      m = math.max(m, Ev(s), EvSaved(s))
    end
  end
  local want = math.max(100, math.ceil(m * 1.15 / 50) * 50)
  if reset or want > scale then
    scale = want
  end
end

local function IsPartner(i)
  if info.pool then
    return false                  -- pool rule: no pairs
  end
  local s = st[sel]
  return s ~= nil and (s.p1 == i or s.p2 == i)
end

local function RowAlpha(i)
  if i == sel or IsPartner(i) then
    return 1.0
  end
  return info.pool and DIM_POOL or DIM
end

-- Returns the row text, for example "> Potencia   +12  (+3)".
local function RowText(i)
  local s = st[i]
  local t = (i == sel and "> " or "   ") .. StatName(i)
  if s.delta ~= 0 then
    t = t .. "   " .. Signed(s.delta)
  end
  if s.delta ~= s.committed then
    t = t .. "  (" .. Signed(s.delta - s.committed) .. ")"
  end
  if i ~= sel and IsPartner(i) then
    t = t .. "  " .. T("PARTNER")
  end
  return t
end

local function SetPrim(i, prim, value, visible)
  local p = funcLuaMenuCommand(C.PRIM_INDEX, L_GAUGE, i, prim)
  if p ~= nil then
    funcLuaMenuCommand(C.PRIM_VALUE, L_GAUGE, i, p, value, true)
  end
  funcLuaMenuCommand(C.PRIM_VISIBLE, L_GAUGE, i, prim, visible)
end

local function DrawGauge(k)
  if not gauges_ready[k] then
    return
  end
  local i = MAP[k] or k
  local s = st[i]
  if s == nil then
    return
  end
  local v = Ev(s)                                  -- base stat with the working training
  local old = EvSaved(s)
  local top = s.base + s.max                       -- highest base value reachable from here
  SetPrim(k, P_NUM_CUR, math.max(0, v), v <= old)
  SetPrim(k, P_NUM_NEXT, math.max(0, v), v > old)
  SetPrim(k, P_NUM_MAX, math.max(0, top), true)
  local r = math.max(0, math.min(1, v / scale))
  local r_old = math.max(0, math.min(1, old / scale))
  funcLuaMenuCommand(C.RATE_SET, L_GAUGE, R_GAUGE, 0, r, k, false, G_BAR)
  funcLuaMenuCommand(C.RATE_SET, L_GAUGE, R_GAUGE_RED, 0, math.max(r, r_old), k, false, G_BAR)
  funcLuaMenuCommand(C.MODEL_ALPHA, L_GAUGE, k, 0, RowAlpha(i))
end

local function Title()
  if name ~= "" then
    return T("TITLE", name)
  end
  return T("TITLE_NONAME")
end

local function Head1()
  if not info.pool then
    return T("LIBERTAD", info.avail, info.total)
  end
  local up, down = 0, 0
  for i = 0, 8 do
    local s = st[i]
    if s ~= nil then
      if s.delta > 0 then
        up = up + s.delta
      else
        down = down - s.delta
      end
    end
  end
  return T("POOL", info.avail, info.total, up, down)
end

local function Head2()
  local t = T("LEVEL", info.level)
  if not info.pool then
    t = t .. " - " .. PosName(info.pos)  -- the pairs depend on the position
  end
  return t .. PeText()
end

local function DrawTexts()
  if not loader or not info.ok then
    Text(N_TITLE, loader and Title() or T("NO_LOADER"))
    Text(N_HEAD1, loader and (info.status == ERR_LOCKED and T("LOCKED") or T("NO_DATA")) or "")
    Text(N_HEAD2, "")
    Text(N_HELP, "")
    for k = 0, ROWS - 1 do
      Text(N_ROW[k + 1], "   " .. StatName(MAP[k]))
    end
    if N_ROW[ROWS + 1] then
      Text(N_ROW[ROWS + 1], "")
    end
    return
  end
  Text(N_TITLE, Title())
  Text(N_HEAD1, Head1())
  Text(N_HEAD2, Head2())
  Text(N_HELP, hint or (step10 and T("HELP10") or T("HELP")))
  for k = 0, ROWS - 1 do
    Text(N_ROW[k + 1], RowText(MAP[k]))
    funcLuaMenuCommand(C.TEXT_ALPHA, L_WIN, 0, N_ROW[k + 1], RowAlpha(MAP[k]))
  end
  if N_ROW[ROWS + 1] then
    Text(N_ROW[ROWS + 1], "")      -- the layout's 9th row (ex Rapidez)
  end
end

-- Draws the radar.
local function DrawGraph()
  if hdl == 0 or not info.ok or UpdateCharaParameterGraphNextBeansByCharaStHdl == nil then
    return
  end
  local a4, a5 = {}, {}
  for t = 0, 7 do
    local s = st[t] or {base = 0, delta = 0, committed = 0}
    if t < 7 then
      local nob = Int(funcLuaCommand(C.CHARA_GET, hdl, 14 + t, true, true))
      a4[t + 1] = EvSaved(s) - nob
      a5[t + 1] = Ev(s) - nob
    else
      a4[t + 1] = 0
      a5[t + 1] = 0
    end
  end
  local ok, err = pcall(UpdateCharaParameterGraphNextBeansByCharaStHdl, L_GRAPH, L_GRAPH_NUM, hdl, a4, a5, L_GRAPH_BASE)
  if not ok then
    Log("character_reforged_training_menu graph: " .. tostring(err))
  end
end

local function Redraw(reset_scale)
  UpdateScale(reset_scale)
  DrawTexts()
  for i = 0, ROWS - 1 do
    DrawGauge(i)
  end
  DrawGraph()
end

local function Refresh(reset_scale)
  ReadInfo()
  if info.ok then
    ReadStats()
  end
  Redraw(reset_scale)
end

local function LoadPlayer(h, fresh)
  hdl = h or 0
  name = ""
  if hdl ~= 0 then
    local n = Call(C.CHARA_NAME, hdl)
    if type(n) == "string" then
      name = n
    end
  end
  if loader and hdl ~= 0 then
    Call(TR.INFO, hdl, fresh and 1 or 0)
  end
  Refresh(true)
end

local function BuildPlayers(first)
  players = {}
  local seen = {}
  local function add(h)
    if type(h) == "number" and h ~= 0 and not seen[h] then
      seen[h] = true
      players[#players + 1] = h
    end
  end
  local dockOk = Param(KEY_DOCK_OK)
  local dockNo = Param(KEY_DOCK_NO)
  local dockType = Param(KEY_DOCK_TYPE)
  if dockOk == 1 and type(dockNo) == "number" and type(dockType) == "number" then
    local ok, count = Call(C.TEAM_INFO, dockNo, dockType, 0)
    if ok == true and type(count) == "number" then
      for i = 0, count - 1 do
        local ok2, h = Call(C.TEAM_MEMBER, dockNo, dockType, i, 0)
        if ok2 == true then
          add(h)
        end
      end
    end
  end
  if type(first) == "number" and first ~= 0 and not seen[first] then
    table.insert(players, 1, first)
    seen[first] = true
  end
  if #players == 0 then
    players[1] = 0
  end
  cur = 1
  for k, h in ipairs(players) do
    if h == first then
      cur = k
    end
  end
end

local function Ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  local yes = VRFW.question.ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  return yes
end

local function Say(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  VRFW.question.notice(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
end

local function Run(f, ...)
  if vrfw_co ~= nil or closing then
    return
  end
  vrfw_co = coroutine.create(f)
  local ok, err = coroutine.resume(vrfw_co, ...)
  if not ok then
    Log("character_reforged_training_menu: " .. tostring(err))
    vrfw_co = nil
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  elseif coroutine.status(vrfw_co) == "dead" then
    vrfw_co = nil
  end
end

local function Commit()
  if not info.ok or not info.dirty then
    return true
  end
  local ok, status = Call(TR.COMMIT, hdl)
  if ok ~= true then
    Say(T("SAVE_FAILED", Int(status)))
    return false
  end
  return true
end

local function Close()
  closing = true
  Call(TR.CANCEL, 0)             -- drop every working copy of this menu
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  funcLuaCommand(C.CLOSE_MENU, MENU)
end

local function DoSave()
  local dirty = info.ok and info.dirty
  if Commit() then
    funcLuaCommand(C.SE, SE_DECIDE)
    if dirty and not saved_hint_shown then
      saved_hint_shown = true
      Say(T("SAVED_HINT"))
    end
    Close()
  end
end

local function DoBack()
  if info.ok and info.dirty then
    funcLuaCommand(C.SE, SE_OK)
    if not Ask(T("ASK_DISCARD")) then
      return
    end
  end
  funcLuaCommand(C.SE, SE_BACK)
  Close()
end

local function DoSwitch(dir)
  if #players < 2 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if info.ok and info.dirty then
    if Ask(T("ASK_SAVE_SWITCH", name)) then
      if not Commit() then
        return
      end
    else
      Call(TR.CANCEL, hdl)
    end
  end
  cur = (cur - 1 + dir) % #players + 1
  funcLuaCommand(C.SE, SE_MOVE)
  LoadPlayer(players[cur], true)
end

local function DoReset()
  if not info.ok then
    return
  end
  if Ask(T("ASK_RESET", name)) then
    Call(TR.RESET, hdl)
    funcLuaCommand(C.SE, SE_OK)
    Refresh(false)
  end
end

local function StepRow(dir)
  hint = nil
  sel = MAP[(RowOf(sel) + dir) % ROWS]
  funcLuaCommand(C.SE, SE_MOVE)
  Redraw(false)
end

local function StepValue(dir)
  if not info.ok then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if dir == lastDir and frame - lastFrame <= HOLD_GAP then
    rep = rep + 1
  else
    rep = 0
  end
  lastDir, lastFrame = dir, frame
  local amount = (step10 or rep >= HOLD_REPEATS) and 10 or 1
  local s = st[sel]
  local ok, stop, reached = Call(TR.SET, hdl, sel, s.delta + dir * amount)
  if type(reached) ~= "number" or Int(reached) == s.delta then
    funcLuaCommand(C.SE, SE_NG)
  else
    funcLuaCommand(C.SE, SE_MOVE)
  end
  -- Records why it stopped (also after a partial 10-point step).
  hint = nil
  stop = Int(stop)
  if ok ~= true and stop == 1 and info.pool then
    hint = T("EMPTY")
  elseif ok ~= true and stop == 5 then
    hint = T("FLOOR", StatName(sel), s.base + s.min)
  elseif ok ~= true and stop == 2 then
    hint = T("CAP", StatName(sel), s.base + s.max)
  end
  Refresh(false)
end

function OnInit()
  SetGraphLayerNameAndIdx(L_GRAPH_BASE, 0, L_GRAPH, 0, L_GRAPH_NUM)
  loader = LoaderReady()
  local h = Param(KEY_HDL)
  BuildPlayers(type(h) == "number" and h or 0)
  if loader and players[cur] ~= 0 then
    LoadPlayer(players[cur], true)
  else
    hdl = players[cur] or 0
    info = {ok = false}
  end
end

function OnSetupLayer(a1, a2)
  if a1 == L_WIN then
    funcLuaMenuCommand(C.LOCAL_POS, a1, WIN_X, WIN_Y, 0)
    funcLuaMenuCommand(C.NODE_VISIBLE, a1, N_POS_WIN2, false, a2)
    funcLuaMenuCommand(C.NODE_VISIBLE, a1, N_POS_BEANS, false, a2)
    DrawTexts()
  elseif a1 == L_BTN then
    funcLuaMenuCommand(C.TEXT, a1, 2921358143 --[[_text_cmd_btn01]], funcLuaCommand(C.TEXT_GET, 2750714971), 0)
    funcLuaMenuCommand(C.TEXT, a1, 950238781 --[[_text_btn01]], T("SAVE"), 0)
  elseif a1 == L_GRAPH_BASE then
    funcLuaMenuCommand(C.PRIORITY, a1, a2, 846, true)
  elseif a1 == L_GRAPH_NUM or a1 == L_GRAPH then
    funcLuaMenuCommand(C.PRIORITY, a1, a2, 847, true)
  end
end

function OnOpenLayer(a1, a2)
  if a1 == L_GRAPH_WIN then
    funcLuaMenuCommand(C.LOCAL_POS, a1, GRAPH_X, GRAPH_Y, 0)
  elseif a1 == L_GAUGE then
    if a2 == nil or a2 < 0 or a2 >= ROWS then
      if a2 ~= nil and a2 >= ROWS then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)   -- the 9th gauge (ex Rapidez)
      end
      return
    end
    local icon = a2 < 7 and MENU_DEF.GetStatusParamIconName(a2) or 0
    if icon ~= 0 then
      funcLuaMenuCommand(C.SPRITE, a1, ICON_TEX, icon, ICON_NODE, 0, a2)
    else
      funcLuaMenuCommand(C.MESH_VISIBLE, a1, MESH_ICON, false, a2)   -- row 7 = Suerte: no retail icon
    end
    local g = funcLuaMenuCommand(C.GROUP_INDEX, a1, a2, G_BAR)
    funcLuaMenuCommand(C.RATE_BIND, a1, R_GAUGE, g, a2)
    funcLuaMenuCommand(C.RATE_BIND, a1, R_GAUGE_RED, g, a2)
    gauges_ready[a2] = true
    DrawGauge(a2)
  elseif a1 == L_GRAPH then
    DrawGraph()
  elseif a1 == L_WIN then
    DrawTexts()
  end
end

function OnDecideFocus(a1, a2)
  if a1 == L_BTN then
    Run(DoSave)
  end
end

function OnEnter(a1, a2)
  if a1 == L_BTN then
    Run(DoSave)
    return 1
  end
end

function OnBack(a1)
  Run(DoBack)
  return 1
end

function OnFunction(a1, a2)
  if vrfw_co ~= nil or closing then
    return
  end
  if a1 == F.UP then
    StepRow(-1)
  elseif a1 == F.DOWN then
    StepRow(1)
  elseif a1 == F.LEFT then
    StepValue(-1)
  elseif a1 == F.RIGHT then
    StepValue(1)
  elseif a1 == F.PREV then
    Run(DoSwitch, -1)
  elseif a1 == F.NEXT then
    Run(DoSwitch, 1)
  elseif a1 == F.RESET then
    Run(DoReset)
  elseif a1 == F.STEP then
    hint = nil
    step10 = not step10
    funcLuaCommand(C.SE, SE_OK)
    DrawTexts()
  end
end

function Step()
  frame = frame + 1
  if vrfw_co ~= nil then
    if coroutine.status(vrfw_co) == "dead" then
      vrfw_co = nil
    else
      local ok, err = coroutine.resume(vrfw_co)
      if not ok then
        Log("character_reforged_training_menu: " .. tostring(err))
        vrfw_co = nil
        funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
      elseif coroutine.status(vrfw_co) == "dead" then
        vrfw_co = nil
      end
    end
  end
end
