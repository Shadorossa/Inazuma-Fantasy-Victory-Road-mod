-- Number fits: every active mod's content/number_fit/*.toml (`VRFW.number_fit/1`).

NumberFit = NumberFit or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("number_fit")

local FITS = {}               -- { key, layer, digits, both }

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
      if layer == nil then
        warn(d.key .. ": no layer")
      elseif shrink ~= "width" and shrink ~= "both" then
        warn(d.key .. ": shrink must be \"width\" or \"both\", got " .. tostring(shrink))
      elseif seen[layer] then
        warn(d.key .. ": layer " .. tostring(d.v.layer) .. " already declared by " .. seen[layer] .. " (kept)")
      else
        seen[layer] = d.key
        FITS[#FITS + 1] = { key = d.key, layer = layer, digits = d.v.digits or 3, both = shrink == "both" }
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
    return 0, 0, false
  end
  return f.layer, f.digits, f.both
end

do
  local ok, e = pcall(load)
  if not ok then warn("declarations: " .. tostring(e)) end
end
