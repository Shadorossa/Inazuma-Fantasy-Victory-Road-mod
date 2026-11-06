-- Inazuma Fantasy › the level orbs: which items are level orbs and how many levels each gives (config.toml
-- [level_orbs.levels]). The item use menu asks once per opening (graft inazuma_fantasy_level_orbs).
--
-- | Command | Args -> answers |
-- |---|---|
-- | CMND_INAZUMAFANTASY_LEVEL_ORB_LEVELS | item id -> levels one orb gives (0 = not a level orb) |

require "VRFW/lib/basics"
local Id = require "VRFW/lib/ids"
local u32 = Id.u32

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
