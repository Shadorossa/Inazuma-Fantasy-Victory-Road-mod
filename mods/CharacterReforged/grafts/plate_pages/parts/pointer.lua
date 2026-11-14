-- Player page block (plate_pages.lua)
  --@lib vrfw_menu_kit.lua#Pointer
  G.PTR_DOT = {x0 = 1321, dx = 28, y = 895, h = 50}
  G.PTR_Q, G.PTR_E = {1258, 893, 62, 54}, {1551, 893, 56, 54}
  G.PTR_R3 = {1708, 893, 44, 54}
  G.PTR_FORM = {1706, 893, 214, 54}     -- the hint on the dots row from x 1713 (layout)
  G.BANKS = {@crc:chara_bank_menu_for_search@, @crc:chara_bank_menu@}
  function G.ptr_go(target, dir)
    local Lc = VRFW.host.command
    if type(target) == "number" then
      G.gotoT = 3                          -- the plate's own step too (a bank in its list view steps the plate)
      if VRFW.player_pages ~= nil then
        VRFW.player_pages.go_to(target)
      end
    end
    for pass = 1, 2 do
      for _, m in ipairs(pass == 1 and G.BANKS or G.PARENTS) do
        if Lc(@crc:CMND_IS_EXIST_MENU@, m) == true then
          Lc(830228314, m, "CharacterReforgedPlayerPagePointerPage", target, dir, pass == 1)
          Lc(C.LOG, "PlayerPage pointer page", string.format("%08X", m), tostring(target), dir)
          return
        end
      end
    end
    pcall(dir > 0 and SetPersonalPlateNextPage or SetPersonalPlatePrevPage)
  end
  function G.ptr_form()
    G.form_press("click")                  -- the page's one form handler (parts/forms.lua)
  end
  function G.pointer()
    if G.gotoT ~= nil then
      G.gotoT = G.gotoT - 1
      if G.gotoT <= 0 then
        G.gotoT = nil
        if VRFW.player_pages ~= nil then
          VRFW.player_pages.go_to(nil)
        end
      end
    end
    local up = On() and G.ptype ~= nil and Exists(G.STATUS) and Cmd(C.IS_VIS, G.STATUS, 0) == true
      and not (type(BetterQoL) == "table" and type(BetterQoL.passive_config_plate) == "table" and BetterQoL.passive_config_plate.co ~= nil)
    if not up then
      G.ptrUp = false
      return
    end
    G.ptr = G.ptr or VRFW.pointer.new()
    local P = G.ptr
    if not G.ptrUp then
      G.ptrUp = true
      P.reset()
    end
    P.begin()
    local D = G.PTR_DOT
    local pages = G.slot_pages()
    for s = 1, G.DOTS_MAX do
      if pages[s] ~= nil then
        P.rect(D.x0 + D.dx * (s - 1) + 2, D.y, D.dx, D.h, s)
      end
    end
    P.rect(G.PTR_Q[1], G.PTR_Q[2], G.PTR_Q[3], G.PTR_Q[4], "q")
    P.rect(G.PTR_E[1], G.PTR_E[2], G.PTR_E[3], G.PTR_E[4], "e")
    local psub = G.ptype == 2 and not G.in_office()
    if psub then
      for k = 2, 1 + G.PSUB_N do
        P.rect(G.PSUB_DOT_X[k] + 2, D.y, D.dx, D.h, "p" .. (k - 2))
      end
      P.rect(G.PTR_R3[1], G.PTR_R3[2], G.PTR_R3[3], G.PTR_R3[4], "r3")
    end
    if G.ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE and not G.in_office() and G.view_offered() then
      P.rect(G.PTR_FORM[1], G.PTR_FORM[2], G.PTR_FORM[3], G.PTR_FORM[4], "form")
    elseif G.fbBox ~= nil then
      local b = G.fbBox
      P.rect(b[1], b[2], b[3], b[4], "form")     -- the form badge (tiles + RS key), on every form page
    end
    local ev = P.poll()
    local c = ev.click
    if c == nil then
      return
    end
    if type(c) == "number" then
      local cur = G.slot(G.ptype)
      local target = pages[c]
      if cur ~= nil and c ~= cur and target ~= nil then
        G.ptr_go(target, c > cur and 1 or -1)
      end
    elseif c == "q" or c == "e" then
      G.ptr_go(nil, c == "e" and 1 or -1)
    elseif c == "r3" or string.sub(c, 1, 1) == "p" then
      local n = c == "r3" and G.next_passive_sub_page() or tonumber(string.sub(c, 2))
      if n ~= nil and n ~= G.psub then
        G.show_passive_sub_page(n)
      end
    elseif c == "form" then
      G.ptr_form()
    end
  end
