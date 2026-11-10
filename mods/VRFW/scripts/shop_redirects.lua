-- Shop redirect.

ShopRedirects = ShopRedirects or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("shop_redirects")

local PAIRS = {}  -- { from, to }: a number (shop id) or a text (shop key)
local SCREENS = {}

-- "0x…" -> the id; any other text stays a key (a mod's shop, resolved by the menu)
local function ref(s)
  if type(s) ~= "string" then return nil end
  if s:match("^%s*0[xX]%x+%s*$") then return D.id_of(s) end
  local t = VRFW.strings.trim(s)
  if t == "" then return nil end
  return t
end

local function start()
  local schema, why = D.schema("shop_redirect")
  if not schema then
    warn(why .. ": every menu opens its own shop")
    return
  end
  -- shop -> { kind = "shop" | "set", target, priority, key }: the higher `priority` wins, then the later declaration
  local win, parts = {}, {}
  local function claim(from, kind, target, d)
    local prio = math.floor(tonumber(d.v.priority) or 0)
    local cur = win[from]
    if cur ~= nil and (cur.kind ~= kind or cur.target ~= target) then
      if prio >= cur.priority then
        warn(string.format("%s: shop %s was redirected by %s: %s wins (priority %d >= %d)", d.key, tostring(from), cur.key,
          d.key, prio, cur.priority))
      else
        warn(string.format("%s: shop %s stays redirected by %s (priority %d > %d)", d.key, tostring(from), cur.key,
          cur.priority, prio))
        return
      end
    end
    win[from] = { kind = kind, target = target, priority = prio, key = d.key }
  end
  for _, d in ipairs(D.load(schema, warn)) do
    local to = ref(d.v.to)
    local set = type(d.v.contact_set) == "string" and VRFW.strings.trim(d.v.contact_set) or ""
    if to ~= nil and set ~= "" then
      warn(string.format("%s: both `to` and `contact_set`: left out", d.key))
    elseif set ~= "" then
      if not set:find(".", 1, true) then set = d.mod .. "." .. set end
      for _, f in ipairs(d.v.from) do
        local from = ref(f)
        if from ~= nil then claim(from, "set", set, d) end
      end
      parts[#parts + 1] = string.format("%s (%d shop(s) -> contact set %s)", d.key, #d.v.from, set)
    elseif to == nil then
      warn(string.format("%s: neither `to` nor `contact_set`: left out", d.key))
    else
      for _, f in ipairs(d.v.from) do
        local from = ref(f)
        if from ~= nil and from ~= to then claim(from, "shop", to, d) end
      end
      parts[#parts + 1] = string.format("%s (%d shop(s) -> %s)", d.key, #d.v.from, tostring(to))
    end
  end
  for from, w in pairs(win) do
    if w.kind == "shop" then
      PAIRS[#PAIRS + 1] = { from, w.target }
    else
      SCREENS[#SCREENS + 1] = { from, VRFW.crc32(w.target) }
    end
  end
  if #PAIRS == 0 and #SCREENS == 0 then
    info("off: no mod redirects a shop")
  else
    info("on: " .. table.concat(parts, ", "))
  end
end

-- CMND_VRFW_SHOP_REDIRECTS() -> n, from 1, to 1, …
function ShopRedirects.List()
  local out = {}
  for _, p in ipairs(PAIRS) do
    out[#out + 1] = p[1]
    out[#out + 1] = p[2]
  end
  return #PAIRS, table.unpack(out)
end

-- CMND_VRFW_SHOP_SCREENS() -> n, from 1, set 1, …
function ShopRedirects.Screens()
  local out = {}
  for _, p in ipairs(SCREENS) do
    out[#out + 1] = p[1]
    out[#out + 1] = p[2]
  end
  return #SCREENS, table.unpack(out)
end

start()
