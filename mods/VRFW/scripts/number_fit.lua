-- Number fits: every active mod's content/number_fit/*.toml (`VRFW.number_fit/1`).

NumberFit = NumberFit or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("number_fit")

local FITS = {}               -- { key, layer, digits, both, node, number }

local function load()
  local schema, why = D.schema("number_fit")
  if not schema then
    warn(tostring(why))
    return
  end
  local seen = {}
  for _, d in ipairs(D.load(schema, warn)) do
    if d.entry == "NumberFit" then
      local layer = D.id_of(d.v.layer)
      local shrink = d.v.shrink or "width"
      local node = d.v.node ~= nil and D.id_of(d.v.node) or 0
      local number = d.v.number ~= nil and D.id_of(d.v.number) or 0
      -- A layer has one rule for the whole layer, and one rule per number that names its own joint.
      local place = node ~= 0 and (tostring(layer) .. ":" .. tostring(number)) or layer
      if layer == nil then
        warn(d.key .. ": no layer")
      elseif shrink ~= "width" and shrink ~= "both" then
        warn(d.key .. ": shrink must be \"width\" or \"both\", got " .. tostring(shrink))
      elseif (node ~= 0) ~= (number ~= 0) then
        warn(d.key .. ": node and number go together (the joint to squeeze and the number that decides)")
      elseif seen[place] then
        warn(d.key .. ": layer " .. tostring(d.v.layer) .. " already declared by " .. seen[place] .. " (kept)")
      else
        seen[place] = d.key
        FITS[#FITS + 1] = { key = d.key, layer = layer, digits = d.v.digits or 3, both = shrink == "both", node = node,
          number = number }
      end
    end
  end
  if #FITS > 0 then
    local names = {}
    for _, f in ipairs(FITS) do names[#names + 1] = f.key .. " (" .. f.digits .. ")" end
    info("number fits: " .. table.concat(names, ", "))
  end
end

function NumberFit.Cmd(i)
  local f = FITS[tonumber(i) or 0]
  if f == nil then
    return 0, 0, false, 0, 0
  end
  return f.layer, f.digits, f.both, f.node, f.number
end

do
  local ok, e = pcall(load)
  if not ok then warn("declarations: " .. tostring(e)) end
end
