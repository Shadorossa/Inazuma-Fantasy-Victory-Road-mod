-- Header shifts: every active mod's content/header_shift/*.toml (`VRFW.header_shift/1`).

HeaderShift = HeaderShift or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("header_shift")

local BY_STEM = nil            -- stem crc -> { { layer, dy, scale, x, y, node } … }

local function load()
  BY_STEM = {}
  local schema, why = D.schema("header_shift")
  if not schema then
    warn(tostring(why))
    return
  end
  local count = 0
  for _, d in ipairs(D.load(schema, warn)) do
    -- dy is a number, or the key of the declaring mod's config.toml that holds it.
    local dy = d.v.dy
    if type(dy) == "string" then
      local ok, value = pcall(VRFW.files.config, dy, d.mod)
      dy = ok and value or nil
    end
    if type(dy) ~= "number" or dy < 0 then
      warn(tostring(d.key) .. ": dy is not a number >= 0 nor a config key holding one: left out")
    elseif d.entry == "HeaderShift" and type(d.v.stem) == "string" and d.v.stem ~= "" then
      local stem = VRFW.crc32(d.v.stem)
      local list = BY_STEM[stem] or {}
      BY_STEM[stem] = list
      local seen = {}
      for _, l in ipairs(list) do seen[l.layer] = true end
      local function put(layer, scale, x, y, node)
        if layer == nil then
          warn(d.key .. ": a layer is not a name or an id")
        elseif seen[layer] then
          warn(d.key .. ": layer " .. tostring(layer) .. " already shifted in " .. d.v.stem .. " (kept)")
        else
          seen[layer] = true
          list[#list + 1] = { layer = layer, dy = dy, scale = scale, x = x, y = y, node = node or 0 }
          count = count + 1
        end
      end
      for _, s in ipairs(d.v.stretch or {}) do
        if type(s.scale) == "number" and type(s.x) == "number" and type(s.y) == "number" then
          put(D.id_of(s.layer), s.scale, s.x, s.y)
        else
          warn(d.key .. ": a stretch needs layer, scale, x and y")
        end
      end
      for _, s in ipairs(d.v.lists or {}) do
        local node = D.id_of(s.node)
        if node ~= nil and node ~= 0 then
          put(D.id_of(s.layer), 0, 0, 0, node)
        else
          warn(d.key .. ": a list needs layer and node")
        end
      end
      for _, layer in ipairs(d.v.layers or {}) do
        put(layer, 0, 0, 0)
      end
    end
  end
  if count > 0 then
    info("header shifts: " .. count .. " layer(s)")
  end
end

function HeaderShift.Cmd(stem, i)
  if BY_STEM == nil then
    local ok, e = pcall(load)
    if not ok then warn("declarations: " .. tostring(e)) end
  end
  local list = BY_STEM and BY_STEM[math.floor(tonumber(stem) or 0) % 4294967296]
  local l = list and list[math.floor(tonumber(i) or 0)]
  if l == nil then
    return 0, 0, 0, 0, 0, 0
  end
  return l.layer, l.dy, l.scale, l.x, l.y, l.node
end
