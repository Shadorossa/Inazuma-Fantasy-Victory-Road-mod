
ChronicleDeluxe = ChronicleDeluxe or {}

local info, warn = VRFW.logger("ChronicleDeluxe.UniverseDays")

local FOLDER = "content/universe_days"
local KIND = "ChronicleDeluxe.universe_day/1"

local GROUPS = nil

local function groups()
  if GROUPS ~= nil then
    return GROUPS
  end
  GROUPS = {}
  for _, file in ipairs(VRFW.files.declarations(FOLDER)) do
    local data = type(file.data) == "table" and file.data or {}
    if data.schema ~= KIND then
      warn(string.format("mods/%s/%s: schema %s is not %s: file left out", tostring(file.mod), tostring(file.file), tostring(data.schema), KIND))
    else
      local own = type(data.ChronicleDeluxe) == "table" and data.ChronicleDeluxe.UniverseDay or nil
      for _, group in ipairs(type(own) == "table" and own or {}) do
        if type(group.group) == "string" and type(group.flags) == "table" and #group.flags > 0 then
          local flags = {}
          for i, name in ipairs(group.flags) do
            flags[i] = VRFW.crc32(name)
          end
          local offset = VRFW.random("ChronicleDeluxe.universe_day", { group.group }):below(#flags)
          GROUPS[#GROUPS + 1] = { name = group.group, flags = flags, offset = offset }
        end
      end
    end
  end
  info(string.format("daily groups declared: %d", #GROUPS))
  return GROUPS
end

function ChronicleDeluxe.UniverseDay(day)
  local out = {}
  day = math.floor(tonumber(day) or 0)
  for _, group in ipairs(groups()) do
    local on = (day + group.offset) % #group.flags + 1
    for i, flag in ipairs(group.flags) do
      out[#out + 1] = flag
      out[#out + 1] = i == on and 1 or 0
    end
  end
  return out
end
