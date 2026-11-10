
local Id = VRFW.ids
local u32 = Id.unsigned

local LEVELS_BY_ITEM = nil   -- item id -> levels, read once

local function levels_by_item()
  if LEVELS_BY_ITEM == nil then
    LEVELS_BY_ITEM = {}
    for key, levels in pairs(VRFW.config("level_orbs.levels", {})) do
      if type(key) == "string" and type(levels) == "number" and levels >= 1 then
        LEVELS_BY_ITEM[u32(VRFW.crc32(key))] = math.floor(levels)
      end
    end
  end
  return LEVELS_BY_ITEM
end

InazumaFantasy = InazumaFantasy or {}

function InazumaFantasy.LevelOrbLevels(item)
  return levels_by_item()[u32(tonumber(item) or 0)] or 0
end
