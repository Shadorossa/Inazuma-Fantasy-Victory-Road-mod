do
  local STEM = "team_dock_formation_menu"
  local FV = {
    LIST = 2188689660,         -- CMND_VRFW_FORM_LIST(hdl) -> n, form1..formN
    MODEL = 1264240712,
    CLEAR = 2038320023,
    DUMP = 2177911233,
    SET_CHARA = 59611540,      -- 0x038D9994 (layer, idx, charaId)
    SET_MODEL = 2464766630,
    LAYER = 189137238,         -- team02_01_attach_formation_frame
    READY = 1583438030,        -- model loaded? (layer, idx)
    POSE = 180466856, POSE_ANIM = 2263925137,
    POSE_UPD = 953552931, POSE_UPD_ARG = 3459069566,
    GUIDE = 1138543975,        -- mainmenu01_06_base_button_guide
    BTN_TEXT = 3848901683,
    BTN_ICON = 1674320485,
    BTN_KEY = 4039536666,
    HEAD_TEXT = 1638840503,
    TEXT_GET = 4074371074,     -- CMND_TEXT_GET
    NAMES = {[0] = 2628899404, [1] = 3954631386, [2] = 1925165920, [3] = 95978486, [4] = 2614892117},
    SE = 1917805374, SE_SWITCH = 2629173176, -- sy0009
    ARMOUR_FORMS = {[2] = true, [3] = true, [4] = true},
    WAIT = 120,
    TILES = 485291282,
    FORM_TILE = 0, KEY_TILE = 1,
    BADGE = 172924432,
    BADGE_GLYPH_NODE = 950238781,
    BADGE_TEXT_NODE = 378156699,
    BADGE_PLATE_MESH = 3491851413,
    -- The plate is right-anchored.
    TEXT_CX = 102,
    ATLAS = "#/menu/102_team/betterqol_view_forms/betterqol_view_forms.g4tx",
    ATLAS_CRC = 2957536024,
    QUAD_NODE = 1909474081,    -- icon_new01 (the cmn01_10 quad's node)
    QUAD_SIZE = 36,
    FORM_TILES = {[0] = 2588100819 --[[betterqol_vf_tile_normal]], [1] = 223029242 --[[betterqol_vf_tile_miximax]],
      [2] = 742052004 --[[betterqol_vf_tile_armour]], [3] = 3843139925 --[[betterqol_vf_tile_armour_miximax]],
      [4] = 3843139925 --[[betterqol_vf_tile_armour_miximax]]},
    KEY_TILE_SPRITE = 1747877075,
    LAYER_COUNT = 1175615627, IS_OPEN = 2640875187, OPEN_LAYER = 629267548, VISIBLE = 711242136,
    POSITION = 1389957207, SCALE = 3778714801, SET_TEXT = 1083631230, FIT_PLATE = 1172899594, PRIORITY = 1491630496,
    SPRITE = 558735651, MESH_VISIBLE = 3405944500, LOAD_TEXTURE = 839427544, TEXTURE_LOADING = 1506186496,
    CONFIG = 641711791,
    OPEN_WAIT = 30,
    TEXTURE_MIN = 10, TEXTURE_MAX = 600,
    -- defaults when the script does not answer (config.toml [view_forms] has the same values)
    BADGE_DEFAULTS = {badge_x = 1720, badge_y = 230, badge_scale = 1, badge_priority = 690, tile_size = 52,
      tile_gap = 6, key_scale = 0.9, key_dx = 0, key_dy = 0},
    hdl = 0, shown = 0, wait = 0, armour = false, entryModel = false, forms = {0}, idx = 1, dirty = false,
    labelled = false, sources = {"-"}, report = false, answered = false, guideDrawn = false,
    badgeOpenWait = 0, badgePlaced = false, badgeForm = nil, badgeConfig = nil,
    textureAsked = false, textureWait = 0, textureReady = false,
  }

  local function H()
    return VRFW.host
  end
  -- the screen's retail locals (nil without the host / VRFW.debug)
  local function HostL()
    local h = type(H()) == "table" and type(H().hosts) == "table" and H().hosts[STEM] or nil
    return h ~= nil and h.L or nil
  end
  local function Local(k)
    local L = HostL()
    if L == nil then
      return nil
    end
    local ok, v = pcall(function()
      return L[k]
    end)
    return ok and v or nil
  end
  local function SetLocal(k, v)
    local L = HostL()
    if L ~= nil then
      pcall(function()
        L[k] = v
      end)
    end
  end
  local function Viewing()
    return Local("flag2") == true
  end
  local function Log(...)
    FV.logger = FV.logger or VRFW.logger.new("BetterQoL view_forms appearance")
    FV.logger(...)
  end

  function FV.reset()
    FV.hdl, FV.forms, FV.idx, FV.dirty, FV.sources, FV.report = 0, {0}, 1, false, {"-"}, false
    FV.answered, FV.guideDrawn = false, false
  end

  function FV.load(hdl)
    FV.hdl, FV.idx = hdl, 1
    local V = type(BetterQoL) == "table" and BetterQoL.view_forms or nil
    local src, answered
    if type(V) == "table" and type(V.forms) == "function" then
      FV.forms, src, answered = V.forms(hdl)
    else
      FV.forms = {0}
    end
    FV.sources = type(src) == "table" and src or {}
    FV.answered = answered == true
    FV.report = true
  end

  -- Drops the entry model; otherwise the next player or Normal keeps the armour.
  function FV.dropEntryModel()
    if FV.entryModel then
      FV.entryModel = false
      funcLuaMenuCommand(FV.SET_MODEL, FV.LAYER, 0, 0)
    end
  end

  function FV.current()
    return FV.forms[FV.idx] or 0
  end

  function FV.modelOf(hdl, f)
    local ok, m = pcall(funcLuaCommand, FV.MODEL, hdl, f)
    if not ok or type(m) ~= "number" then
      return 0
    end
    return m
  end

  local function Text(id)
    local ok, t = pcall(funcLuaCommand, FV.TEXT_GET, id)
    return ok and type(t) == "string" and t or ""
  end

  function FV.header()
    local parent = 3902542018 --[[chronicle_mode_top_menu]]
    if g_parentMenuId ~= 0 and g_parentMenuId ~= nil then
      parent = g_parentMenuId
    end
    local text = Text(FV.HEAD_TEXT)
    if #FV.forms > 1 then
      local name = FV.NAMES[FV.current()] and Text(FV.NAMES[FV.current()]) or ""
      if name ~= "" then
        text = text .. " · " .. name
      end
      FV.labelled = true
    else
      FV.labelled = false
    end
    funcLuaCommand(830228314, parent, "SwapSoccerTopCommonHeaderTextByHeaderType", 5, text)
  end

  function FV.guide()
    if #FV.forms <= 1 then
      return false
    end
    local texts = {2948285224, 2492731275, FV.BTN_TEXT, 986889694}
    local icons = {3891651141, 3705319142, FV.BTN_ICON, 0}
    local offs = {0, 18, 18, -36}
    local keys = {0, 0, FV.BTN_KEY, 0}
    local ok = pcall(funcLuaMenuCommand, 2209673388, g_parentMenuId, FV.GUIDE, texts, icons, offs)
    pcall(funcLuaMenuCommand, 452337289, g_parentMenuId, FV.GUIDE, keys)
    return ok
  end

  -- Reads the indicator's place and size.
  function FV.badgeSettings()
    if FV.badgeConfig == nil then
      local c = {}
      for k, v in pairs(FV.BADGE_DEFAULTS) do
        c[k] = v
      end
      local ok, answer = pcall(funcLuaCommand, FV.CONFIG)
      if ok and type(answer) == "table" then
        for k in pairs(FV.BADGE_DEFAULTS) do
          if type(answer[k]) == "number" then
            c[k] = answer[k]
          end
        end
        c.from = "config"
      else
        c.from = "defaults (CMND_BETTERQOL_VIEW_FORMS_CFG unanswered)"
      end
      FV.badgeConfig = c
    end
    return FV.badgeConfig
  end

  -- Returns the indicator's three instances.
  function FV.badgeParts()
    return {{FV.TILES, FV.FORM_TILE}, {FV.TILES, FV.KEY_TILE}, {FV.BADGE, 0}}
  end

  function FV.hideBadge()
    if FV.badgeForm ~= nil then
      FV.badgeForm = nil
      for _, part in ipairs(FV.badgeParts()) do
        pcall(funcLuaMenuCommand, FV.VISIBLE, part[1], part[2], false)
      end
    end
  end

  function FV.textureLoaded()
    if FV.textureReady then
      return true
    end
    if not FV.textureAsked then
      FV.textureAsked, FV.textureWait = true, 0
      pcall(funcLuaMenuCommand, FV.LOAD_TEXTURE, FV.ATLAS)
    end
    FV.textureWait = FV.textureWait + 1
    local ok, loading = pcall(funcLuaCommand, FV.TEXTURE_LOADING, FV.ATLAS_CRC)
    local busy = ok and loading == true
    if (not busy and FV.textureWait >= FV.TEXTURE_MIN) or FV.textureWait >= FV.TEXTURE_MAX then
      FV.textureReady = true
    end
    return FV.textureReady
  end

  -- Lays out the two tiles and the key glyph from the config.
  function FV.placeBadge(c)
    local scale = c.badge_scale
    local size, gap = c.tile_size * scale, c.tile_gap * scale
    local centreY = c.badge_y
    local keyX = c.badge_x - size / 2
    local formX = keyX - size - gap
    local quad = size / FV.QUAD_SIZE
    for _, tile in ipairs({{FV.FORM_TILE, formX}, {FV.KEY_TILE, keyX}}) do
      pcall(funcLuaMenuCommand, FV.SCALE, FV.TILES, quad, quad, 1, tile[1])
      pcall(funcLuaMenuCommand, FV.POSITION, FV.TILES, tile[2], -centreY, 0, tile[1])
      pcall(funcLuaMenuCommand, FV.PRIORITY, FV.TILES, tile[1], c.badge_priority, true)
    end
    pcall(funcLuaMenuCommand, FV.SPRITE, FV.TILES, FV.ATLAS_CRC, FV.KEY_TILE_SPRITE, FV.QUAD_NODE, 0, FV.KEY_TILE)
    -- Reads the key's glyph.
    local glyph = Text(FV.BTN_ICON)
    if glyph == "" then
      glyph = "<CMD_BETTERQOL_VIEW_FORMS>"
    end
    local k = c.key_scale * scale
    pcall(funcLuaMenuCommand, FV.SCALE, FV.BADGE, k, k, 1, 0)
    pcall(funcLuaMenuCommand, FV.POSITION, FV.BADGE, keyX + c.key_dx * scale + FV.TEXT_CX * k,
      -(centreY + c.key_dy * scale), 0, 0)
    pcall(funcLuaMenuCommand, FV.PRIORITY, FV.BADGE, 0, c.badge_priority + 1, true)
    pcall(funcLuaMenuCommand, FV.SET_TEXT, FV.BADGE, FV.BADGE_GLYPH_NODE, "", 0)
    pcall(funcLuaMenuCommand, FV.SET_TEXT, FV.BADGE, FV.BADGE_TEXT_NODE, glyph, 0)
    pcall(funcLuaMenuCommand, FV.FIT_PLATE, FV.BADGE, 0, FV.BADGE_TEXT_NODE)
    pcall(funcLuaMenuCommand, FV.MESH_VISIBLE, FV.BADGE, FV.BADGE_PLATE_MESH, false, 0)
  end

  -- Draws the form tile and the key tile at the top right of the shown character.
  function FV.badge()
    if #FV.forms <= 1 then
      FV.hideBadge()
      return false, FV.answered and "only Normal" or "no form viewer (CMND_VRFW_FORM_LIST unanswered)", true
    end
    for _, layer in ipairs({FV.TILES, FV.BADGE}) do
      local okc, count = pcall(funcLuaMenuCommand, FV.LAYER_COUNT, layer)
      if not okc or type(count) ~= "number" or count <= 0 then
        return false, "no layer " .. (layer == FV.TILES and "betterqol_vf_tile" or "betterqol_vf_badge")
          .. " in this menu (content/menus/view_forms.toml not applied)", true
      end
    end
    local closed = {}
    for _, part in ipairs(FV.badgeParts()) do
      local oko, open = pcall(funcLuaMenuCommand, FV.IS_OPEN, part[1], part[2])
      if not (oko and open == true) then
        closed[#closed + 1] = part
      end
    end
    if #closed > 0 then
      if FV.badgeOpenWait == 0 then
        FV.badgePlaced, FV.badgeForm = false, nil   -- (re)opened: placed and filled again
        for _, part in ipairs(closed) do
          pcall(funcLuaMenuCommand, FV.OPEN_LAYER, part[1], part[2])
        end
      end
      FV.badgeOpenWait = FV.badgeOpenWait + 1
      if FV.badgeOpenWait < FV.OPEN_WAIT then
        return false, "opening", false
      end
    else
      FV.badgeOpenWait = 0
    end
    if not FV.textureLoaded() then
      return false, "loading", false
    end
    local c = FV.badgeSettings()
    if not FV.badgePlaced then
      FV.badgePlaced = true
      FV.placeBadge(c)
    end
    local form = FV.current()
    if FV.badgeForm ~= form then
      local sprite = FV.FORM_TILES[form] or FV.FORM_TILES[0]
      pcall(funcLuaMenuCommand, FV.SPRITE, FV.TILES, FV.ATLAS_CRC, sprite, FV.QUAD_NODE, 0, FV.FORM_TILE)
      for _, part in ipairs(FV.badgeParts()) do
        pcall(funcLuaMenuCommand, FV.VISIBLE, part[1], part[2], true)
      end
      FV.badgeForm = form
    end
    return true, "at " .. tostring(c.badge_x) .. "," .. tostring(c.badge_y) .. " from " .. tostring(c.from), true
  end

  -- Logs one line per opened player.
  function FV.logOpen(guideDrawn, badgeDrawn, why)
    local parts = {}
    for i, f in ipairs(FV.forms) do
      parts[#parts + 1] = tostring(f) .. "=" .. tostring(FV.sources[i] or "?")
    end
    Log("open", STEM, FV.hdl, "forms " .. table.concat(parts, "; "), "viewer " .. (FV.answered and "yes" or "no"),
      "guide " .. (guideDrawn and "yes" or "no"), "indicator " .. (badgeDrawn and "yes" or "no") .. " (" .. tostring(why) .. ")")
  end

  local function On(point, phase, fn)
    local h = H()
    if type(h) == "table" and type(h.on) == "function" then
      h.on(STEM, point, {id = "BetterQoL.view_forms_appearance", phase = phase, fn = fn})
    end
  end

  -- Wraps the retail builder, which always uses the retail chara path.
  On("UpdateViewChara3DModel", "around", function(nxt, a1, a2, a3)
    if not FV.noLocals and type(Local("n")) ~= "number" then
      FV.noLocals = true
      Log("no host locals (VRFW.host map / VRFW.debug): «Ver apariencia» not detected", STEM)
    end
    if not Viewing() or a1 == nil or a1 == 0 then
      FV.dropEntryModel()
      if FV.hdl ~= 0 or FV.shown ~= 0 then
        pcall(funcLuaCommand, FV.CLEAR)
      end
      -- a model still built in a form is ended first, so the retail build outside the view is Normal again
      if a1 ~= nil and a1 ~= 0 and (FV.shown ~= 0 or FV.leftFormModel) then
        pcall(EndViewChara3DModel)
        SetLocal("n3", 0)
        Log("form reset", a1, "outside the view")
      end
      FV.leftFormModel = false
      FV.reset()
      FV.shown = 0
      return nxt(a1, a2, a3)
    end
    if a1 ~= FV.hdl then
      FV.load(a1)
    end
    FV.dirty = true
    local f = FV.current()
    local m = FV.modelOf(a1, f)   -- arms (or clears) the framework's pick for this player
    if FV.shown ~= 0 or f ~= 0 or FV.leftFormModel then
      FV.leftFormModel = false
      FV.dropEntryModel()
      EndViewChara3DModel()
      SetLocal("n3", 0)
    end
    FV.shown = f
    FV.wait = FV.WAIT
    FV.armour = false
    if m == 0 or FV.ARMOUR_FORMS[f] ~= true then
      return nxt(a1, a2, a3)
    end
    -- Handles armour forms.
    FV.armour = true
    local real = funcLuaMenuCommand
    local chara = 0
    funcLuaMenuCommand = function(id, layer, idx, v, ...)
      if id == FV.SET_CHARA and layer == FV.LAYER and v ~= 0 then
        chara = v
        real(FV.SET_MODEL, layer, idx, m)
        FV.entryModel = true
      end
      return real(id, layer, idx, v, ...)
    end
    local ok, err = pcall(nxt, a1, a2, a3)
    funcLuaMenuCommand = real
    Log("armour build", chara, m)
    if not ok then
      error(err, 0)
    end
  end)

  BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
  BetterQoL.view_forms = type(BetterQoL.view_forms) == "table" and BetterQoL.view_forms or {}
  function BetterQoL.view_forms.appearance()
    if not Viewing() or FV.hdl == 0 or #FV.forms <= 1 then
      return false
    end
    FV.idx = FV.idx % #FV.forms + 1
    funcLuaCommand(FV.SE, FV.SE_SWITCH)
    Log("form", FV.hdl, FV.current())
    local leader = type(IsSelectLeaderCard) == "function" and IsSelectLeaderCard() or false
    UpdateViewChara3DModel(FV.hdl, Local("n") or 0, leader)
    return true
  end

  On("PostStep", "after", function()
    -- Waits until the model is ready.
    local viewing = Viewing()
    if FV.wait > 0 then
      FV.wait = FV.wait - 1
      if not viewing or #FV.forms <= 1 then
        FV.wait = 0
      elseif funcLuaMenuCommand(FV.READY, FV.LAYER, 0) == true then
        FV.wait = 0
        if FV.armour then
          funcLuaMenuCommand(FV.POSE, FV.LAYER, 0, FV.POSE_ANIM, 0, 0)
          funcLuaMenuCommand(FV.POSE_UPD, FV.LAYER, 0, FV.POSE_UPD_ARG)
          Log("pose", FV.hdl, FV.current())
        end
        pcall(funcLuaCommand, FV.DUMP, FV.hdl, FV.current())
      elseif FV.wait == 0 then
        Log("notready", FV.hdl, FV.current())
      end
    end
    if not viewing then
      FV.labelled = false
      FV.hideBadge()
      return
    end
    if FV.dirty then
      FV.dirty = false
      if #FV.forms > 1 or FV.labelled then
        FV.header()
      end
      FV.guideDrawn = FV.guide()
    end
    local badgeDrawn, why, final = FV.badge()
    if FV.report and final then
      FV.report = false
      FV.logOpen(FV.guideDrawn, badgeDrawn, why)
    end
  end)

  On("OnFunction", "around", function(nxt, a1, a2, ...)
    if Viewing() and a1 == 318865860 --[[close]] then
      FV.dropEntryModel()
    end
    local r = table.pack(nxt(a1, a2, ...))
    if not Viewing() then
      FV.dropEntryModel()
      if FV.hdl ~= 0 or FV.shown ~= 0 then
        pcall(funcLuaCommand, FV.CLEAR)
        FV.leftFormModel = FV.leftFormModel or FV.shown ~= 0
        FV.reset()
        FV.shown = 0
        FV.labelled = false
      end
    end
    return table.unpack(r, 1, r.n)
  end)
end
