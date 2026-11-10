-- Drawing only
CharacterReforged_PointsHyperGauge = CharacterReforged_PointsHyperGauge or {}
local G = CharacterReforged_PointsHyperGauge
G.MAX_ASKS = 600
G.asks = 0
G.answered = false
G.layers = {}                          -- the layer hashes to hide

local COMMAND_HIDDEN_LAYERS = @crc:CMND_CHARACTERREFORGED_POINTS_HUD_HIDDEN_LAYERS@
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_GET_CREATE_LAYER_NUM = @crc:CMND_GET_CREATE_LAYER_NUM@

-- asks the command until it answers (a busy script answers nothing for that frame)
local function AskHiddenLayers()
  if G.answered or G.asks >= G.MAX_ASKS or type(funcLuaCommand) ~= "function" then
    return
  end
  G.asks = G.asks + 1
  local result = table.pack(pcall(funcLuaCommand, COMMAND_HIDDEN_LAYERS))
  if not result[1] or result[2] == nil then
    return
  end
  G.answered = true
  if result[2] ~= true and result[2] ~= 1 then
    return
  end
  for i = 3, result.n do
    if type(result[i]) == "number" then
      G.layers[#G.layers + 1] = result[i]
    end
  end
end

function G.step()
  AskHiddenLayers()
  for _, layer in ipairs(G.layers) do
    local count = VRFW.host.menu_command(CMND_GET_CREATE_LAYER_NUM, layer)
    if type(count) ~= "number" or count < 1 then
      count = 2
    end
    for instance = 0, count - 1 do
      VRFW.host.menu_command(CMND_SET_LAYER_VISIBLE, layer, instance, false)
    end
  end
end

local previousUpdateOwnGauge = UpdateHyperdimensionalPowerGauge
function UpdateHyperdimensionalPowerGauge(...)
  local result = {n = 0}
  if type(previousUpdateOwnGauge) == "function" then
    result = table.pack(previousUpdateOwnGauge(...))
  end
  pcall(G.step)
  return table.unpack(result, 1, result.n)
end

local previousUpdateRivalGauge = UpdateEnemyHyperdimensionalPowerGauge
function UpdateEnemyHyperdimensionalPowerGauge(...)
  local result = {n = 0}
  if type(previousUpdateRivalGauge) == "function" then
    result = table.pack(previousUpdateRivalGauge(...))
  end
  pcall(G.step)
  return table.unpack(result, 1, result.n)
end
