-- VRFW focus_hud_cutin, soccer_focus_battle_menu
VRFW.focus_hud_cutin = {
  COMMAND = @crc:CMND_VRFW_FOCUS_HOLD@,
  LAYERS = {
    3070268158 --[[soccer08_23_focus_count_down]],
    2665077583 --[[soccer08_57_command_select_guide]],
    594553331 --[[soccer08_25_focus_passout_limit]],
    1752673562 --[[soccer08_01_focus_battle_self_status_attach_locator]],
    723368858 --[[soccer08_02_focus_battle_join_chara_status_self]],
    1068385939 --[[soccer08_02_focus_battle_join_chara_status_enemy]],
    832596189 --[[soccer08_24_focus_cover_line_num_self]],
    3607900019 --[[soccer08_24_focus_cover_line_num_enemy]],
    3125263524 --[[focus chara face balloon (self)]],
    4267573567 --[[focus chara face balloon (enemy)]],
    4213651200 --[[soccer02_24_focus_skill_self_exec_balloon]],
    1282905914 --[[soccer02_24_focus_skill_enemy_exec_balloon]],
    2406002192 --[[soccer02_24_focus_action_thinking_balloon]],
    3386444557 --[[soccer04_07_time_limit_bar]],
    1221690783 --[[soccer08_36_focus_auto]],
    1551114178 --[[soccer08_35l_focus_auto_button_left]],
    2636706917 --[[soccer08_35r_focus_auto_button_right]],
  },
  CMND_IS_OPEN = @crc:CMND_IS_OPEN_LAYER@,
  CMND_IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@,
  CMND_SET_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@,
  CMND_INSTANCE_COUNT = @crc:CMND_GET_CREATE_LAYER_NUM@,
  MAX_INSTANCES = 4,
  hidden = {},
  hiding = false,
}

-- true while the hold's cut-in plays (false without the command)
function VRFW.focus_hud_cutin.cutin_playing()
  local held, cutin = VRFW.host.command(VRFW.focus_hud_cutin.COMMAND)
  return held == true and cutin == true
end

-- Hide every visible instance of the HUD layers.
function VRFW.focus_hud_cutin.hide()
  local F = VRFW.focus_hud_cutin
  for _, layer in ipairs(F.LAYERS) do
    if funcLuaMenuCommand(F.CMND_IS_OPEN, layer) == true then
      local count = funcLuaMenuCommand(F.CMND_INSTANCE_COUNT, layer)
      if type(count) ~= "number" or count <= 0 then
        count = 1
      end
      count = math.min(count, F.MAX_INSTANCES)
      for index = 0, count - 1 do
        if funcLuaMenuCommand(F.CMND_IS_VISIBLE, layer, index) == true then
          funcLuaMenuCommand(F.CMND_SET_VISIBLE, layer, index, false)
          local key = layer .. ":" .. index
          if F.hidden[key] == nil then
            F.hidden[key] = {layer, index}
          end
        end
      end
    end
  end
end

-- show again the remembered instances whose layer is still open
function VRFW.focus_hud_cutin.restore()
  local F = VRFW.focus_hud_cutin
  local list = F.hidden
  F.hidden = {}
  for _, entry in pairs(list) do
    if funcLuaMenuCommand(F.CMND_IS_OPEN, entry[1]) == true then
      funcLuaMenuCommand(F.CMND_SET_VISIBLE, entry[1], entry[2], true)
    end
  end
end

function VRFW.focus_hud_cutin.step()
  local F = VRFW.focus_hud_cutin
  if F.cutin_playing() then
    F.hiding = true
    F.hide()
  elseif F.hiding then
    F.hiding = false
    F.restore()
  end
end

local function focus_hud_cutin_pack(...)
  return {n = select("#", ...), ...}
end

do
  local previousPostStep = rawget(_ENV, "PostStep")
  rawset(_ENV, "PostStep", function(...)
    local result = {n = 0}
    if type(previousPostStep) == "function" then
      result = focus_hud_cutin_pack(previousPostStep(...))
    end
    pcall(VRFW.focus_hud_cutin.step)
    return table.unpack(result, 1, result.n)
  end)
end
