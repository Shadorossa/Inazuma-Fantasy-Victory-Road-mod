local CHARA_BASE_OF = 347353059           -- (param) -> base id; (param, true) -> internal name
local MAX_LOG_LINES = 64

local log = type(VRFW.logger) == "table" and VRFW.logger.new("ChronicleDeluxe.UniverseFaces") or function() end
local logged = 0
local seen = {}

local retail_icon = OnListViewUniverseChara_UpdateCharaIcon
function OnListViewUniverseChara_UpdateCharaIcon(index, list_index, ...)
  retail_icon(index, list_index, ...)
  if logged >= MAX_LOG_LINES then
    return
  end
  local info = GetCharaInfo(list_index)
  local param = type(info) == "table" and info[1] or nil
  if param == nil or seen[param] then
    return
  end
  seen[param] = true
  local base = funcLuaCommand(CHARA_BASE_OF, param)
  local name = funcLuaCommand(CHARA_BASE_OF, param, true)
  if base == nil or base == 0 or name == nil or name == "" then
    logged = logged + 1
    log("no face: param", param, "base", base or 0, "name", tostring(name), "bucket", info[2] or -1)
  end
end
