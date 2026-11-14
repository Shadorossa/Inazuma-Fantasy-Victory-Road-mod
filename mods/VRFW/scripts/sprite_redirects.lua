-- Sprite redirect.

SpriteRedirects = SpriteRedirects or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("sprite_redirects")

local TABLE = "VRFW.SpriteRedirect"
local LAYER_TABLE = "VRFW.SpriteRedirect.Layer"   -- key: layer name crc, atlas id, sprite crc
local HOOK = "SpriteRedirects.SetLayerSprite"
local ATLASES = {}   -- own atlas paths, declaration order
local GAME_IDS = {}
local handed_out = false
local holder_on = false

local crc = VRFW.crc32

local function atlas_path(s)
  if type(s) ~= "string" then return nil end
  local p = VRFW.strings.trim(s)
  if not p:match("^#/.+%.g4tx$") then return nil end
  return p
end

local function other_spelling(p)
  local without = p:gsub("/<LG>/", "/", 1)
  if without ~= p then return without end
  local dir, file = p:match("^(.*)/([^/]+)$")
  if not dir then return nil end
  return dir .. "/<LG>/" .. file
end

local function start()
  local schema, why = D.schema("sprite_redirect")
  if not schema then
    warn(why .. ": no sprite is redirected")
    return
  end
  local pairs_out, seen_atlas, parts, also, layer_rows = {}, {}, {}, {}, {}
  for _, d in ipairs(D.load(schema, warn)) do
    local game, own = atlas_path(d.v.atlas), atlas_path(d.v.own_atlas)
    if not game or not own then
      warn(string.format("%s: atlas / own_atlas must be #/…/<name>.g4tx: left out", d.key))
    elseif game == own then
      warn(string.format("%s: own_atlas is the game atlas: left out", d.key))
    else
      local g, o = crc(game), crc(own)
      local ids = GAME_IDS[own]
      if ids == nil then
        ids = {}
        GAME_IDS[own] = ids
      end
      local alt_game = other_spelling(game)
      for _, id in ipairs({ g, alt_game and crc(alt_game) or nil }) do
        local known = false
        for _, v in ipairs(ids) do
          if v == id then known = true end
        end
        if not known then ids[#ids + 1] = id end
      end
      local layers = d.v.layers
      local limited = layers ~= nil and #layers > 0
      if limited then
        -- only on the named layers: another layer asking the same sprite keeps the game atlas's
        for _, layer in ipairs(layers) do
          for _, s in ipairs(d.v.sprites) do
            layer_rows[#layer_rows + 1] = { crc(layer), g, crc(s), o }
            if alt_game then layer_rows[#layer_rows + 1] = { crc(layer), crc(alt_game), crc(s), o } end
          end
        end
      end
      for _, s in ipairs(limited and {} or d.v.sprites) do
        local key = g .. " " .. crc(s)
        local cur = pairs_out[key]
        if cur and cur.own ~= o then
          warn(string.format("%s: sprite %s of %s was redirected by %s: the later declaration wins", d.key, s, game, cur.by))
        end
        pairs_out[key] = { atlas = g, sprite = crc(s), own = o, by = d.key }
        local alt = other_spelling(game)
        if alt then
          also[#also + 1] = { atlas = crc(alt), sprite = crc(s), own = o, by = d.key }
        end
      end
      if not seen_atlas[own] then
        seen_atlas[own] = true
        ATLASES[#ATLASES + 1] = own
      end
      parts[#parts + 1] = string.format("%s (%d sprite(s) of %s -> %s)", d.key, #d.v.sprites, game, own)
    end
  end
  -- the same sprites asked under the atlas's other spelling; a declaration naming that spelling itself wins
  for _, p in ipairs(also) do
    local key = p.atlas .. " " .. p.sprite
    if pairs_out[key] == nil then pairs_out[key] = p end
  end
  if next(pairs_out) == nil and #layer_rows == 0 then
    info("off: no mod redirects a sprite")
    return
  end
  local ok, done, e = pcall(VRFW.hook.apply, HOOK)
  if not (ok and done == true) then
    ATLASES = {}
    GAME_IDS = {}
    warn(string.format("detour %s not installed (%s): no sprite is redirected", HOOK, tostring(ok and e or done)))
    return
  end
  pcall(VRFW.native.table_clear, TABLE)
  for _, p in pairs(pairs_out) do VRFW.native.table_set(TABLE, { p.atlas, p.sprite }, p.own) end
  pcall(VRFW.native.table_clear, LAYER_TABLE)
  for _, r in ipairs(layer_rows) do VRFW.native.table_set(LAYER_TABLE, { r[1], r[2], r[3] }, r[4]) end
  info(string.format("on: %d sprite redirect rule(s)", #parts))
  VRFW.debug("sprite_redirects: on: " .. table.concat(parts, ", "))
end

function SpriteRedirects.Atlases(i, k)
  i = math.floor(tonumber(i) or 0)
  if i == -1 then
    -- (-1, 1): a resident holder menu loaded every own atlas this game session; (-1, 0) -> true once one did
    if math.floor(tonumber(k) or 0) == 1 and not holder_on then
      holder_on = true
      info("own atlases held by a resident menu until the game reset")
    end
    return holder_on
  end
  if i <= 0 then
    if not handed_out and #ATLASES > 0 then
      handed_out = true
      info(string.format("%d own atlas(es), each loaded by a menu script while a game atlas it serves is loaded: %s",
        #ATLASES, table.concat(ATLASES, ", ")))
    end
    return #ATLASES
  end
  k = math.floor(tonumber(k) or 0)
  local ids = ATLASES[i] and GAME_IDS[ATLASES[i]] or {}
  if k < 0 then
    return #ids
  elseif k == 0 then
    return ATLASES[i]
  end
  return ids[k]
end

-- the holder menus are made again after a reset: until one loads the own atlases, every menu loads its own
VRFW.on("game:reset", function()
  holder_on = false
end)

start()
