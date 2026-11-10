CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if type(rawget(_ENV, "UpdateCharaStatusPlateInfoByCharaStHdl")) == "function" and CharacterReforged.header == nil then
  local H = {}
  CharacterReforged.header = H
  H.HOST = "CharacterReforged.header"
  -- header layers (crc32 of soccer11_04_formation_chara_status, soccer11_04_chara_status), swapped for character_reforged_soccer11_04pp_pp
  H.LAYERS = {[1844915256] = true, [607716004] = true}
  H.SLOT = {x = 1570, x_end = 1682, top = -163, height = 64}
  H.GAP = 8                              -- between two pieces
  H.DORSAL = {icon_right = 1856, parent_x = 1920, digit = 24 * 0.85, gap = 4}
  H.DORSAL_NUMBER = 1766833194           -- _num_back01 (the dorsal's number primitive and node)
  H.SET_NUMBER = 3609943765              -- the game's "set number" (layer, instance, primitive, value)
  H.NODE_POS = 2575768773
  H.dorsal = {}                          -- "layer:inst" -> the dorsal set by the plate's last fill
  H.dorsalDigits = {}
  H.dorsalUnseen = false                 -- logged once: a header fill without a dorsal number
  H.items = nil
  H.BAND_HOST = "CharacterReforged.header_band"
  H.bandItems = nil
  H.STATUS_TEXTURE = 348706892           -- #/menu/00_soccer/soccer11/soccer11_04/<LG>/soccer11_04.g4tx
  H.STATUS_BAND_SLOT = 1621728801        -- status_chr_base01_s01
  H.CHARA = 1131797651                   -- CMND_GET_CHARA (hdl, 12) = the card's rarity
  H.SWAP_SPRITE = 558735651              -- (layer, texture, sprite, slot, 0, inst)
  H.ctx = {}                             -- per piece key: the ctx of its last fill
  H.RARITY_HOST = "CharacterReforged.header_rarity"
  H.rarityItems = nil
  H.RARITY_MESH = 1052197874             -- _player_rarity01 (the row's rarity title)
  H.MESH_VISIBLE = 3405944500            -- CMND_SET_MESH_VISIBLE (layer, mesh, on, inst)
  H.RARITY_NODE = 1457835367
  H.NODE_VISIBLE = 2158717427            -- the node visibility command (layer, node, on, inst)
  H.rarityOff = {}
  H.TITLE_REQUEST = 2881088748
  H.SHOW_WHEN_LOADED_ARGUMENT = 6
  H.HIDE_ON_REDRAW_ARGUMENT = 7
  H.TITLE_RARITY_ARGUMENT = 5            -- its argument "rarity" (the sprite is rarity + 1)
  H.LOADING = 1277042906                 -- the plate instance's icon "loading" flag (layer, inst)
  H.TITLE_SETTLE_STEPS = 3
  H.TITLE_WAIT_LIMIT = 90
  H.titleRarity = {}
  H.titlePending = {}

  local function Pack(...)
    return {n = select("#", ...), ...}
  end

  -- the [[entry]] functions of a host in its order (VRFW.menu.entries)
  local function HostItems(host)
    local out = {}
    local M = rawget(VRFW, "menu")
    if type(M) == "table" and type(M.entries) == "function" then
      local ok, list = pcall(M.entries, host)
      if ok and type(list) == "table" then
        for _, e in ipairs(list) do
          if e.kind == "lua" and type(e.value) == "string" and e.value ~= "" then
            out[#out + 1] = {key = e.key or e.value, path = e.value}
          end
        end
      end
    end
    return out
  end

  -- the declared pieces, in the host's order
  function H.read_items()
    if H.items == nil then
      H.items = HostItems(H.HOST)
    end
    return H.items
  end

  -- the declared band colours, in the host's order
  function H.band_items()
    if H.bandItems == nil then
      H.bandItems = HostItems(H.BAND_HOST)
    end
    return H.bandItems
  end

  -- the declared rarity title rules, in the host's order
  function H.rarity_items()
    if H.rarityItems == nil then
      H.rarityItems = HostItems(H.RARITY_HOST)
    end
    return H.rarityItems
  end

  -- a global function by its path "A.B.C"
  local function Resolve(path)
    local v = _ENV
    for part in string.gmatch(path, "[^%.]+") do
      if type(v) ~= "table" then
        return nil
      end
      v = rawget(v, part)
    end
    return type(v) == "function" and v or nil
  end

  -- the card's rarity (the retail GetCharaStatusRarity when the VM has it)
  local function CardRarity(hdl)
    local f = rawget(_ENV, "GetCharaStatusRarity")
    if type(f) == "function" then
      local ok, r = pcall(f, hdl)
      if ok and type(r) == "number" then
        return r
      end
    end
    local r = VRFW.host.command(H.CHARA, hdl, 12)
    return type(r) == "number" and r or nil
  end

  -- the retail rarity look on a band (a soccer11_04 status plate copy filled with hdl)
  function H.rarity_band(layer, inst, hdl)
    local crc = rawget(_ENV, "CRC32")
    local rarity = type(hdl) == "number" and hdl ~= 0 and CardRarity(hdl) or nil
    if type(crc) ~= "function" or rarity == nil or rarity < 0 then
      return false
    end
    local number = rarity == 8 and 10 or rarity + 1
    local sprite = crc(string.format("status_chr_base01_s%02u", number))
    return (pcall(funcLuaMenuCommand, H.SWAP_SPRITE, layer, H.STATUS_TEXTURE, sprite, H.STATUS_BAND_SLOT, 0, inst or 0))
  end

  function H.band_colour(layer, inst, hdl)
    for _, it in ipairs(H.band_items()) do
      local f = Resolve(it.path)
      if f ~= nil then
        local ok, painted = pcall(f, layer, inst or 0, hdl)
        if ok and painted then
          return true
        end
      end
    end
    return H.rarity_band(layer, inst, hdl)
  end

  function H.shows_rarity(hdl)
    for _, it in ipairs(H.rarity_items()) do
      local f = Resolve(it.path)
      if f ~= nil then
        local ok, shows = pcall(f, hdl)
        if ok and shows == false then
          return false
        end
      end
    end
    return true
  end

  local function TitleOff(layer, inst)
    VRFW.host.menu_command(H.MESH_VISIBLE, layer, H.RARITY_MESH, false, inst)
    VRFW.host.menu_command(H.NODE_VISIBLE, layer, H.RARITY_NODE, false, inst)
  end

  local function RarityTitle(layer, inst, shows)
    local key = tostring(layer) .. ":" .. tostring(inst)
    if shows then
      H.rarityOff[key] = nil
      VRFW.host.menu_command(H.NODE_VISIBLE, layer, H.RARITY_NODE, true, inst)
      return
    end
    H.rarityOff[key] = {layer, inst}
    TitleOff(layer, inst)
  end

  function H.opened(layer, inst)
    if not H.LAYERS[layer] then
      return
    end
    inst = inst or 0
    local key = tostring(layer) .. ":" .. tostring(inst)
    H.rarityOff[key] = {layer, inst}
    H.titleRarity[key] = nil
    H.titlePending[key] = nil
    H.dorsal[key] = nil
    H.dorsalDigits[key] = nil
    TitleOff(layer, inst)
  end

  -- the dorsal's number node placed for the digits of the number the fill set (only when the count changes)
  local function PlaceDorsal(layer, inst)
    local key = tostring(layer) .. ":" .. tostring(inst)
    local value = H.dorsal[key]
    if type(value) ~= "number" then
      if not H.dorsalUnseen then
        H.dorsalUnseen = true
        VRFW.host.command(VRFW.commands.VRFW_LOG, "CharacterReforged.header", "no dorsal number in the plate fill")
      end
      return
    end
    local digits, rest = 1, math.floor(math.abs(value))
    while rest >= 10 do
      rest = math.floor(rest / 10)
      digits = digits + 1
    end
    if H.dorsalDigits[key] == digits then
      return
    end
    H.dorsalDigits[key] = digits
    local D = H.DORSAL
    VRFW.host.menu_command(H.NODE_POS, layer, inst, H.DORSAL_NUMBER, 0,
      D.icon_right + D.gap + digits * D.digit - D.parent_x)
  end

  local function ShowSettledTitles()
    for key, plate in pairs(H.titlePending) do
      plate.steps = plate.steps + 1
      local loading = VRFW.host.menu_command(H.LOADING, plate.layer, plate.inst)
      if loading == false then
        plate.settled = plate.settled + 1
      else
        plate.settled = 0
      end
      if plate.settled >= H.TITLE_SETTLE_STEPS or plate.steps >= H.TITLE_WAIT_LIMIT then
        H.titlePending[key] = nil
        VRFW.host.menu_command(H.NODE_VISIBLE, plate.layer, H.RARITY_NODE, true, plate.inst)
        VRFW.host.menu_command(H.MESH_VISIBLE, plate.layer, H.RARITY_MESH, true, plate.inst)
      end
    end
  end

  function H.fill(layer, inst, hdl, shows)
    if not H.LAYERS[layer] then
      return
    end
    if shows == nil then
      shows = H.shows_rarity(hdl)
    end
    RarityTitle(layer, inst or 0, shows)
    PlaceDorsal(layer, inst or 0)
    local x = H.SLOT.x
    for _, it in ipairs(H.read_items()) do
      local f = Resolve(it.path)
      if f ~= nil then
        local c = H.ctx[it.key] or {}
        H.ctx[it.key] = c
        c.key, c.layer, c.inst, c.hdl = it.key, layer, inst or 0, hdl
        c.x, c.top, c.height, c.room = x, H.SLOT.top, H.SLOT.height, H.SLOT.x_end - x
        local ok, w = pcall(f, "fill", c)
        if ok and type(w) == "number" and w > 0 then
          x = x + w + H.GAP
        end
      end
    end
  end

  function H.step()
    for _, plate in pairs(H.rarityOff) do
      TitleOff(plate[1], plate[2])
    end
    ShowSettledTitles()
    if H.items == nil then
      return
    end
    for _, it in ipairs(H.items) do
      local c = H.ctx[it.key]
      if c ~= nil then
        local f = Resolve(it.path)
        if f ~= nil then
          pcall(f, "step", c)
        end
      end
    end
  end

  local function HeaderFillCommand(command, layer, inst, shows)
    local key = tostring(layer) .. ":" .. tostring(inst)
    return function(id, ...)
      if id == H.TITLE_REQUEST and select(3, ...) == H.RARITY_MESH then
        local args = Pack(...)
        local rarity = args[H.TITLE_RARITY_ARGUMENT]
        local changed = H.titleRarity[key] == nil or H.titleRarity[key] ~= rarity
        H.titleRarity[key] = rarity
        if not shows then
          H.titlePending[key] = nil
        elseif changed or H.titlePending[key] ~= nil then
          H.titlePending[key] = {layer = layer, inst = inst, steps = 0, settled = 0}
        else
          return command(id, ...)
        end
        if args.n < H.HIDE_ON_REDRAW_ARGUMENT then
          args.n = H.HIDE_ON_REDRAW_ARGUMENT
        end
        if args[H.HIDE_ON_REDRAW_ARGUMENT] == nil then
          args[H.HIDE_ON_REDRAW_ARGUMENT] = true
        end
        args[H.SHOW_WHEN_LOADED_ARGUMENT] = false
        return command(id, table.unpack(args, 1, args.n))
      end
      if id == H.MESH_VISIBLE and select(2, ...) == H.RARITY_MESH and select(3, ...) == true
          and H.titlePending[key] ~= nil then
        return nil
      end
      if id == H.SET_NUMBER and select(3, ...) == H.DORSAL_NUMBER then
        H.dorsal[key] = select(4, ...)
      end
      return command(id, ...)
    end
  end

  local function HeaderTitleDecision(layer, hdl)
    if not H.LAYERS[layer] then
      return nil
    end
    return H.shows_rarity(hdl)
  end

  H.prevPlate = UpdateCharaStatusPlateInfoByCharaStHdl
  function UpdateCharaStatusPlateInfoByCharaStHdl(a1, a2, a3, ...)
    local okDecision, shows = pcall(HeaderTitleDecision, a1 or 0, a3)
    if not okDecision then
      shows = nil
    end
    local command, filtered = nil, nil
    if shows ~= nil and type(rawget(_ENV, "funcLuaMenuCommand")) == "function" then
      command = funcLuaMenuCommand
      filtered = HeaderFillCommand(command, a1 or 0, a2 or 0, shows)
      funcLuaMenuCommand = filtered
    end
    local r = Pack(pcall(H.prevPlate, a1, a2, a3, ...))
    if filtered ~= nil and rawget(_ENV, "funcLuaMenuCommand") == filtered then
      funcLuaMenuCommand = command
    end
    if not r[1] then
      error(r[2], 0)
    end
    pcall(H.fill, a1 or 0, a2 or 0, a3, shows)
    return table.unpack(r, 2, r.n)
  end
  for _, point in ipairs({"OnSetupLayer", "OnOpenLayer"}) do
    local original = rawget(_ENV, point)
    if type(original) == "function" then
      _ENV[point] = function(layer, inst, ...)
        pcall(H.opened, layer, inst)
        return original(layer, inst, ...)
      end
    end
  end
  local host = rawget(VRFW, "host")
  local patch = rawget(VRFW, "patch")
  local script = type(patch) == "table" and patch.script or nil
  local stem = type(script) == "string" and script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "") or nil
  if type(stem) == "string" and type(host) == "table" and type(host.on) == "function" then
    for _, point in ipairs({"OnSetupLayer", "OnOpenLayer"}) do
      pcall(host.on, stem, point, {id = "CharacterReforged.header_title_" .. point, phase = "before",
        fn = function(layer, inst)
          pcall(H.opened, layer, inst)
        end})
    end
  end

  local hasStep = type(rawget(_ENV, "Step")) == "function"
  H.prevPostStep = rawget(_ENV, "PostStep") or false
  if type(H.prevPostStep) == "function" or not hasStep then
    function PostStep(...)
      local r = {n = 0}
      if type(H.prevPostStep) == "function" then
        r = Pack(H.prevPostStep(...))
      end
      pcall(H.step)
      return table.unpack(r, 1, r.n)
    end
  end
  if hasStep then
    H.prevStep = Step
    function Step(...)
      local r = Pack(H.prevStep(...))
      pcall(H.step)
      return table.unpack(r, 1, r.n)
    end
  end
end
