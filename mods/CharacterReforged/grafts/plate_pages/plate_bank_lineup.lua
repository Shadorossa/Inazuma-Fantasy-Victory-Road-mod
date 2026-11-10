-- ===== EVT plate_pages bank BEGIN =====
CharacterReforged.page_bank = CharacterReforged.page_bank or {hid = {}, on = false}
do
  local B = CharacterReforged.page_bank
  B.PLATE_MENU = 1427722143                         -- personal_plate_menu
  B.PAGE = 878737202                                -- team11_01_personal_plate (in personal_plate_menu)
  B.LAYERS = {@crc:team14_03_formation_frame@, @crc:team00_01_chara_card_for_soccer@,
    @crc:team00_01_chara_card_for_leader@, @crc:team00_01_chara_card_for_move@, @crc:team00_01_p1_chara_card_blank@,
    @crc:team00_01_p1_chara_card_blank_for_leader@, @crc:soccer11_12_formation_button@,
    @crc:soccer11_19_formation_team_build_button@, @crc:team14_04_team_dock_change_guide@,
    @crc:team14_06_active_ui_change_guide@, @crc:cmn01_10_new_icon@, @crc:cmn01_10_new_icon_leader@,
    @crc:cmn01_10_new_icon_move@, @crc:soccer11_40_synergy_attachment_button_pillar@,
    @crc:soccer11_40_synergy_attachment_button_flag@, @crc:vroad02_03_seasonal_cap_plate_small@,
    @crc:vroad01_51_tournament_team_icon@}
  B.MAX_INST = 32

  local L = VRFW.host.menu_command
  local Log = VRFW.logger.new("PageBank")

  local function Want()
    if CharacterReforged.PAGE_BANK_OFF == true then
      return false
    end
    local ok, v = pcall(funcLuaCommand, @crc:CMND_IS_EXIST_MENU@, B.PLATE_MENU)
    if not (ok and v == true) then
      return false, "no plate menu"
    end
    local okv, vis = pcall(funcLuaMenuCommand, @crc:CMND_IS_LAYER_VISIBLE@, B.PAGE, 0, B.PLATE_MENU)
    if not (okv and vis == true) then
      return false, "stats hidden"
    end
    return true, "stats shown"
  end

  function B.restore(why)
    local n = 0
    for key, rec in pairs(B.hid) do
      if L(@crc:CMND_IS_EXIST_LAYER@, rec[1]) == true and L(@crc:CMND_IS_OPEN_LAYER@, rec[1], rec[2]) == true then
        L(@crc:CMND_SET_LAYER_VISIBLE@, rec[1], rec[2], true)
        L(855005857, rec[1], rec[2], true)
      end
      B.hid[key] = nil
      n = n + 1
    end
    if n > 0 or B.on then
      Log("restore", n, tostring(why))
    end
    B.on = false
  end

  function B.step()
    -- the formation-side rule first (B.ui_sync below)
    if B.ui_sync ~= nil then
      pcall(B.ui_sync)
    end
    local want, why = Want()
    if not want then
      if B.on or next(B.hid) ~= nil then
        B.restore(why)
      end
      return
    end
    B.on = true
    local n = 0
    for _, l in ipairs(B.LAYERS) do
      if L(@crc:CMND_IS_EXIST_LAYER@, l) == true then                                -- CMND_IS_EXIST_LAYER
        for i = 0, B.MAX_INST - 1 do
          if L(@crc:CMND_IS_OPEN_LAYER@, l, i) ~= true then                        -- IS_OPEN: the instances end here
            break
          end
          if L(@crc:CMND_IS_LAYER_VISIBLE@, l, i) == true then                        -- IS_VISIBLE: hide it and remember it
            L(@crc:CMND_SET_LAYER_VISIBLE@, l, i, false)
            -- a hidden card's mouse zone is off too (it would take the engine focus on hover)
            L(855005857, l, i, false)
            B.hid[l * 64 + i] = {l, i}
            n = n + 1
          end
        end
      end
    end
    if n > 0 then
      Log("hide", n, why)
    end
  end


  B.ui = 0
  B.open = false
  B.late = false
  B.formSusp = false
  B.leftOpen = false

  local function PageShown()
    return L(@crc:CMND_IS_LAYER_VISIBLE@, B.PAGE, 0, B.PLATE_MENU) == true        -- CMND_IS_LAYER_VISIBLE in personal_plate_menu
  end

  function B.ui_sync()
    if CharacterReforged.PAGE_BANK_FORMATION_HIDE == false then
      return
    end
    if B.ui == 1 then
      if B.open and PageShown() then
        L(1129326309, B.PLATE_MENU)                                -- suspend (the retail ClosePersonalPlate command)
        if not B.formSusp then
          Log("formation suspend")
        end
        B.formSusp = true
      end
    elseif B.formSusp then
      B.formSusp = false
      local ok, ex = pcall(funcLuaCommand, @crc:CMND_IS_EXIST_MENU@, B.PLATE_MENU)   -- CMND_IS_EXIST_MENU
      if B.open and ok and ex == true then
        L(1453710531, B.PLATE_MENU)                                -- resume (the retail OpenPersonalPlate command)
        if B.leftOpen then
          pcall(funcLuaCommand, 830228314, B.PLATE_MENU, "PlayOffsetAnimCharaBankPersonalPlate", true)
          B.leftOpen = false
        end
        Log("formation resume")
      end
    end
  end


  -- B.install sets every wrapper
  function B.install()
    for _, fname in ipairs({"PostStep", "Step"}) do
      if type(_ENV[fname]) == "function" then
        VRFW.host.wrap(fname, function(orig)
          return function(...)
            B.inStep = true
            local r = table.pack(orig(...))        -- the original first; ours after it
            B.inStep = false
            pcall(B.step)
            return table.unpack(r, 1, r.n)
          end
        end)
        break
      end
    end
    for _, fname in ipairs({"FinalizeMenu", "OnCloseLayer"}) do
      VRFW.host.wrap(fname, function(orig)
        return function(...)
          local r = table.pack(orig(...))
          if next(B.hid) ~= nil and (fname == "FinalizeMenu" or not Want()) then
            pcall(B.restore, fname)
          end
          return table.unpack(r, 1, r.n)
        end
      end)
    end
    VRFW.host.wrap("ChangeActiveUI", function(orig)
      return function(a1, ...)
        local r = table.pack(orig(a1, ...))     -- the original first
        if type(a1) == "number" and a1 ~= B.ui then
          B.ui = a1
          Log("ui", a1)
        end
        pcall(B.ui_sync)
        return table.unpack(r, 1, r.n)
      end
    end)
    VRFW.host.wrap("OpenPersonalPlate", function(orig)
      return function(...)
        local r = table.pack(orig(...))
        B.open = true
        B.leftOpen = B.ui == 1
        pcall(B.ui_sync)
        return table.unpack(r, 1, r.n)
      end
    end)
    VRFW.host.wrap("ClosePersonalPlate", function(orig)
      return function(...)
        B.open = false
        B.formSusp = false
        B.leftOpen = false
        return orig(...)
      end
    end)
    VRFW.host.wrap("SetNameSearchInputEnabled", function(orig)
      return function(a1, ...)
        local keep = a1 == true and CharacterReforged.PAGE_BANK_KEEP_ON_SEARCH ~= false and B.ui ~= 1 and PageShown()
        local r = table.pack(orig(a1, ...))
        if keep then
          L(1453710531, B.PLATE_MENU)                                -- the retail suspend undone: the page stays
          Log("search keep")
        end
        return table.unpack(r, 1, r.n)
      end
    end)
  end

  -- The bank's engine command entry is set after every patch ran
  B.POINTER_MOVED = { [3272825600] = true, [879171363] = true }   -- the pointer-moved command ids (two game builds)
  B.cmdWrapped = B.cmdWrapped or {}
  local function WrapMenuCommand(f)
    if type(f) ~= "function" or B.cmdWrapped[f] then
      return f
    end
    local w = function(id, ...)
      if not B.late then
        B.late = true
        local ok, err = pcall(B.install)
        Log("install late", tostring(ok), tostring(err))
      end
      if B.POINTER_MOVED[id] and B.inStep and B.ui == 0 and CharacterReforged.PAGE_BANK_POINTER_KEEP ~= false then
        local moved = f(id, ...)
        if moved and Want() then
          -- Runs the retail test that follows.
          local okx, x = pcall(f, 558229292, 10)
          local okw, w = pcall(funcLuaCommand, 4207852906, 2)
          if okx and okw and type(x) == "number" and type(w) == "number" and x - w / 2 >= 0 then
            return false                                             -- right half: no switch to the lineup
          end
        end
        return moved
      end
      return f(id, ...)
    end
    B.cmdWrapped[w] = true
    return w
  end
  local cur = rawget(_ENV, "funcLuaMenuCommand")
  if type(cur) == "function" then
    rawset(_ENV, "funcLuaMenuCommand", WrapMenuCommand(cur))
  else
    local mt = getmetatable(_ENV)
    if mt == nil then
      mt = {}
      setmetatable(_ENV, mt)
    end
    local prev = mt.__newindex
    mt.__newindex = function(t, k, v)
      if k == "funcLuaMenuCommand" then
        v = WrapMenuCommand(v)
      end
      if prev == nil then
        rawset(t, k, v)
      elseif type(prev) == "function" then
        prev(t, k, v)
      else
        prev[k] = v
      end
    end
  end
  B.install()
end
-- ===== EVT plate_pages bank END =====
