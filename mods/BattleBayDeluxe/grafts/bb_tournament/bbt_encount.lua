-- Loading telop path row (fade_menu_encount)
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.tournament_loading_path = {
  TELOP = 1108953785 --[[vs11_02_next_enemy_telop_on_loading]],
  NODE = 106197494 --[[vs01_43_enjoy_team_select_emblem_icon]],
  NODE_POS = 2575768773,
  -- Backdrop sprite of the 7 retail hexagons
  BACKDROP = { @crc:_campaign_list_base01@, @crc:_campaign_list_base02@ },
  -- Retail joint layout.
  STEP = 100, ZIG = 55, MID = 300, RETAIL = 7,
  ROW_MAX = 1400,
  k = nil, joints = nil,
}

-- The logger is created on first use.
function BattleBayDeluxe.tournament_encount_log(...)
  BattleBayDeluxe.tournament_loading_path.logger = BattleBayDeluxe.tournament_loading_path.logger or VRFW.logger.new("BattleBayDeluxe.tournament_path")
  BattleBayDeluxe.tournament_loading_path.logger(...)
end

-- Node count for this opening
function BattleBayDeluxe.tournament_encount_count()
  local E = BattleBayDeluxe.tournament_loading_path
  if E.k ~= nil then
    return E.k
  end
  local n
  local handled, v = VRFW.host.command(BattleBayDeluxe.tournament.CI, 4, 0)
  if handled == true and type(v) == "number" and v > 0 then
    n = v
  elseif type(BattleBayDeluxe.tournament_last_info) == "table" and type(BattleBayDeluxe.tournament_last_info.path) == "number" and BattleBayDeluxe.tournament_last_info.path > 0 then
    n = BattleBayDeluxe.tournament_last_info.path
  else
    n = E.RETAIL
  end
  local cap = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, E.NODE) or E.RETAIL
  if n > cap then
    BattleBayDeluxe.tournament_encount_log("path of", n, "nodes, the menu has", cap)
    n = cap
  end
  E.k = n
  BattleBayDeluxe.tournament_encount_log("path nodes", n)
  return n
end

-- spacing and node scale for k nodes
function BattleBayDeluxe.tournament_encount_spacing(k)
  local E = BattleBayDeluxe.tournament_loading_path
  local step = E.STEP
  if k > 1 and step * (k - 1) > E.ROW_MAX then
    step = E.ROW_MAX / (k - 1)
  end
  return step, step / E.STEP
end

function BattleBayDeluxe.tournament_encount_place(i)
  local E = BattleBayDeluxe.tournament_loading_path
  local k = BattleBayDeluxe.tournament_encount_count()
  if E.joints == nil then
    E.joints = {}
    for j = 1, funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, E.NODE) or E.RETAIL do
      E.joints[j] = BattleBayDeluxe.tournament_crc(string.format("_atc_list%02d", j))
    end
  end
  local step, s = BattleBayDeluxe.tournament_encount_spacing(k)
  for j = 1, k do
    local x = E.MID + (j - 1 - (k - 1) / 2) * step
    local y = (j % 2 == 0) and -E.ZIG * s or 0
    VRFW.host.menu_command(E.NODE_POS, E.TELOP, i or 0, E.joints[j], 0, x)
    VRFW.host.menu_command(E.NODE_POS, E.TELOP, i or 0, E.joints[j], 1, y)
  end
  for _, m in ipairs(E.BACKDROP) do
    VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, E.TELOP, m, k == E.RETAIL, i or 0)
  end
  -- Joints past the count go off screen.
  for j = k + 1, #E.joints do
    VRFW.host.menu_command(E.NODE_POS, E.TELOP, i or 0, E.joints[j], 0, -10000)
    VRFW.host.menu_command(E.NODE_POS, E.TELOP, i or 0, E.joints[j], 1, 0)
  end
end

do
  local setup_param = SetupParam
  if type(setup_param) == "function" then
    function SetupParam(...)
      BattleBayDeluxe.tournament_loading_path.k = nil
      return setup_param(...)
    end
  end
  local setup = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local r = table.pack(setup(a1, a2, ...))
    if a1 == BattleBayDeluxe.tournament_loading_path.TELOP then
      local ok, err = pcall(BattleBayDeluxe.tournament_encount_place, a2)
      if not ok then
        BattleBayDeluxe.tournament_encount_log("error", tostring(err))
      end
    elseif a1 == BattleBayDeluxe.tournament_loading_path.NODE then
      local ok, err = pcall(function()
        local k = BattleBayDeluxe.tournament_encount_count()
        if (a2 or 0) >= k then
          funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2 or 0, false)
          return
        end
        local _, s = BattleBayDeluxe.tournament_encount_spacing(k)
        if s < 1 then
          funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, a1, s, s, 1, a2 or 0)
        end
        BattleBayDeluxe.tournament_encount_place(0)
      end)
      if not ok then
        BattleBayDeluxe.tournament_encount_log("error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end
end
