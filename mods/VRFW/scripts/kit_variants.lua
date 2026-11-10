-- Kit variants: the pairs of team kits mods declare (content\kit_variants) and the choice per kit kept in the save.

KitVariants = KitVariants or {}

local D = VRFW.declarations
local u32 = VRFW.ids.unsigned
local hex = VRFW.ids.hex_text

local info, warn = VRFW.logger("kit_variants")

-- the save document of the choices: { version, chosen = { [base kit hex] = true } }
local BLOB = "vrfw_kit_variants.json"
local FILE_VERSION = 1

-- kit id (base or variant) -> { base, variant, label, variant_label }; read on first use
local by_kit = nil

local STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  pretty = true,
  log = "kit variants",
  default = function() return { version = FILE_VERSION, chosen = {} } end,
  decode = function(f)
    f.chosen = type(f.chosen) == "table" and f.chosen or {}
    f.version = FILE_VERSION
    return f
  end,
})

local function read_pairs()
  local out, count = {}, 0
  local schema, why = D.schema("kit_variant")
  if not schema then
    warn(tostring(why))
    return out
  end
  for _, d in ipairs((D.load(schema, warn))) do
    local v = d.v
    if #v.kits ~= #v.variants then
      warn(string.format("%s: %d kits and %d variants: left out", d.where, #v.kits, #v.variants))
    else
      for i = 1, #v.kits do
        local base, variant = u32(v.kits[i]), u32(v.variants[i])
        if base == 0 or variant == 0 or base == variant then
          warn(string.format("%s: pair %d (%s, %s) is no pair: left out", d.where, i, hex(base), hex(variant)))
        elseif out[base] or out[variant] then
          warn(string.format("%s: pair %d: %s or %s is already in a pair: left out", d.where, i, hex(base), hex(variant)))
        else
          local e = { base = base, variant = variant, label = v.label, variant_label = v.variant_label }
          out[base], out[variant] = e, e
          count = count + 1
        end
      end
    end
  end
  info(string.format("%d kit variant pair(s)", count))
  return out
end

local function pair_of(kit)
  if by_kit == nil then by_kit = read_pairs() end
  return by_kit[u32(kit)]
end

--- kit -> base kit, variant kit, text key of the base's prompt, text key of the variant's prompt (0, 0, "", "": no pair).
function KitVariants.Pair(kit)
  local e = type(kit) == "number" and pair_of(kit) or nil
  if not e then return 0, 0, "", "" end
  return e.base, e.variant, e.label, e.variant_label
end

--- kit[, on] -> true when the variant of the kit's pair is chosen; with `on` the choice is set and saved first.
function KitVariants.Choice(kit, on)
  local e = type(kit) == "number" and pair_of(kit) or nil
  if not e then return false end
  local f = STORE:get()
  if type(f) ~= "table" then return false end
  local key = hex(e.base)
  if on ~= nil then
    local want = on == true or on == 1
    if (f.chosen[key] == true) ~= want then
      f.chosen[key] = want or nil
      local ok, where = STORE:put(f, nil, true)
      if ok then
        info(string.format("kit %s: variant %s -> %s", key, tostring(want), tostring(where)))
      else
        warn(string.format("kit %s: choice not saved (%s)", key, tostring(where)))
      end
    end
  end
  return f.chosen[key] == true
end
