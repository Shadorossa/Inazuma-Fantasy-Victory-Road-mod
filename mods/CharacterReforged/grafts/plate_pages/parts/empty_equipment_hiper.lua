-- Player page block (plate_pages.lua)
  function G.empty()
    if not On() then
      return
    end
    local h = 0
    if type(GetPersonalPlateSelectCharaStHdlAuto) == "function" then
      local ok, v = pcall(GetPersonalPlateSelectCharaStHdlAuto)
      h = ok and type(v) == "number" and v or 0
    end
    local empty = h == 0
    if not empty and type(IsInvalidSoccerCharaHdl) == "function" then
      local ok, bad = pcall(IsInvalidSoccerCharaHdl, h)
      empty = ok and bad == true
    end
    if empty and not G.emptyHidden then
      G.emptyHidden = true
      for _, l in ipairs({G.PAGE, G.PLATE, G.STATUS, G.BAND, G.SLANT, G.TAG}) do
        if Exists(l) and Cmd(C.IS_OPEN, l, 0) == true then
          Cmd(C.VIS, l, 0, false)
        end
      end
      if type(G.bars_visible) == "function" then
        G.bars_visible(false)
      end
      for i = 0, 4 do
        G.tile(i, false)
      end
      if type(G.passive_rows_hide) == "function" then
        pcall(G.passive_rows_hide)
      end
      if type(CharacterReforged.hyper_page_hide) == "function" then
        pcall(CharacterReforged.hyper_page_hide)
      end
      pcall(G.mod_pages_hide)
      if type(SetVisiblePersonalPlateLayerAll) == "function" then
        pcall(SetVisiblePersonalPlateLayerAll, false)
      end
    elseif empty then
      if type(CharacterReforged.hyper_page) == "table" and type(CharacterReforged.hyper_page.hide_layer) == "function" then
        CharacterReforged.HYPER_PAGE_PENDING = nil
        pcall(CharacterReforged.hyper_page.hide_layer)
      end
    elseif not empty and G.emptyHidden then
      G.emptyHidden = false
      for _, l in ipairs({G.PAGE, G.PLATE, G.STATUS}) do
        if Exists(l) and Cmd(C.IS_OPEN, l, 0) == true then
          Cmd(C.VIS, l, 0, true)
        end
      end
      if type(UpdatePersonalPlatePage) == "function" then
        pcall(UpdatePersonalPlatePage)
      end
    end
  end

  function G.equip_grid(L, mine)
    for k = 0, 4 do
      if Cmd(C.IS_OPEN, L, k) == true then
        if k <= 3 then
          local sc = mine and G.EQUIP_SCALE or 1
          Cmd(C.SCALE, L, sc, sc, 1, k)
        elseif mine then
          Cmd(C.VIS, L, k, false)
        end
      end
    end
  end

  function G.equip()
    if not Exists(G.EQUIP) then
      return
    end
    G.equip_grid(G.EQUIP, On() and G.ptype == 0)
  end

  function G.hiper_l3()
    G.frame = G.frame + 1
    if not On() or CharacterReforged.HYPER_PAGE_PAGE == nil or GetNowPageIdx == nil or GetNowPageIdx() ~= CharacterReforged.HYPER_PAGE_PAGE
        or type(CharacterReforged.hyper_page_can_switch) ~= "function" or type(CharacterReforged.hyper_page_show) ~= "function" or type(funcLuaCommand) ~= "function" then
      return
    end
    local L = G.L3
    local okp, p1 = pcall(funcLuaCommand, L.CHECK, L.CTRL, L.CMD)
    local okq, p2 = pcall(funcLuaCommand, L.CHECK, L.CTRL_AN, L.CMD)
    if not ((okp and p1 == true) or (okq and p2 == true)) or G.frame - G.l3last < 8 then
      return
    end
    G.l3last = G.frame
    local chara = 0
    if type(GetPersonalPlateSelectCharaStHdlAuto) == "function" then
      local ok, v = pcall(GetPersonalPlateSelectCharaStHdlAuto)
      chara = ok and type(v) == "number" and v or 0
    end
    if chara == 0 then
      return
    end
    local okc, can = pcall(CharacterReforged.hyper_page_can_switch, chara)
    if not okc or can ~= true then
      return
    end
    CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW = not CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW
    pcall(funcLuaCommand, @crc:CMND_SND_PLAY_SE@, 2500047763)      -- the plate's cursor sound
    pcall(CharacterReforged.hyper_page_show, chara)
  end
