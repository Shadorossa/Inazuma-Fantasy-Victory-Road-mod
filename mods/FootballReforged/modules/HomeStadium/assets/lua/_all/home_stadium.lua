HomeStadium = type(HomeStadium) == "table" and HomeStadium or {}
do
  local H = HomeStadium
  H.CMD = {
    LIST = VRFW.commands.HOMESTADIUM_LIST,          -- CMND_HOMESTADIUM_LIST () -> { { map, item }, … }
    GET = VRFW.commands.HOMESTADIUM_GET,           -- CMND_HOMESTADIUM_GET (set) -> map
    SET = VRFW.commands.HOMESTADIUM_SET,           -- CMND_HOMESTADIUM_SET (set, map) -> ok
    ITEM_NUM = VRFW.commands.GET_ITEM_NUM,
    MAP_NAME = VRFW.commands.GET_MAP_NAME,      -- CMND_GET_MAP_NAME (map) -> name
    LOG = VRFW.commands.VRFW_LOG,           -- CMND_VRFW_LOG
  }

  function H.log(...)
    VRFW.host.command(H.CMD.LOG, "home_stadium", ...)
  end

  -- the team dock's home stadium (map crc), 0 = none
  function H.get(set)
    if type(set) ~= "number" or set < 0 then return 0 end
    local map = VRFW.host.command(H.CMD.GET, set)
    if type(map) == "number" then return map % 4294967296 end
    return 0
  end

  function H.set(set, map)
    local done = VRFW.host.command(H.CMD.SET, set, map or 0)
    return done == true
  end

  function H.owned()
    local out = {}
    local list = VRFW.host.command(H.CMD.LIST)
    if type(list) ~= "table" then
      H.log("no stadium list from the module's script")
      return out
    end
    for _, st in ipairs(list) do
      local map, item = tonumber(st.map), tonumber(st.item)
      local have = item == 0
      if item ~= nil and item > 0 then
        local n = VRFW.host.command(H.CMD.ITEM_NUM, item)
        have = type(n) == "number" and n > 0
      end
      if map ~= nil and map ~= 0 and have then
        local name = VRFW.host.command(H.CMD.MAP_NAME, map)
        out[#out + 1] = { map = map, name = (type(name) == "string") and name or "" }
      end
    end
    return out
  end

  if type(VRFW.home_stadium) == "table" and type(VRFW.home_stadium.register) == "function" then
    VRFW.home_stadium.register("HomeStadium.dock", function(set) return H.get(set) end)
  end
end
