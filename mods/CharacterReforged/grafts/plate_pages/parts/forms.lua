-- Player page block (plate_pages.lua)
  local function HidePoly()
    if not Exists(G.RADAR) then
      return
    end
    for k = 0, 1 do
      for _, m in ipairs(G.M_POLY) do
        Cmd(C.MESH, G.RADAR, m, false, k)
      end
    end
  end

  local function Decor(ptype)
    for _, m in ipairs(G.M_TITLES) do
      Cmd(C.MESH, G.STATUS, m, false, 0)
    end
    for _, m in ipairs(G.M_ARROWS) do
      Cmd(C.MESH, G.STATUS, m, false, 0)
    end
    for i, m in ipairs(G.M_SLOTS) do
      Cmd(C.MESH, G.STATUS, m, ptype == 1 and i <= 3, 0)   -- never the rpg copies (they stacked mid-page)
    end
  end

  -- The PERFIL form hint (header plate's grade text node, placed by the layout) shows while the player has more than one form.
  G.N_GRADE = 1006587362
  -- A text node is placed at setup only, so the layout places the hint box
  function G.form_count()
    local M = CharacterReforged.page_model
    if type(M) ~= "table" or type(M.forms) ~= "table" or M.fhdl == nil or M.fhdl ~= M.want then
      return 0
    end
    return #M.forms
  end
  G.VIEW_TEXT = 1638840503
  -- (content\menus\player_page_view_forms.toml), else R3 (CMD_FUNC6)
  function G.form_key_decl()
    local V = type(BetterQoL) == "table" and BetterQoL.view_forms or nil
    return type(V) == "table" and type(V.declared) == "function" and V.declared("personal_plate_menu") == true and V or nil
  end
  function G.form_glyph()
    local V = G.form_key_decl()
    return V ~= nil and type(V.GLYPH) == "string" and V.GLYPH or "<CMD_FUNC6>"
  end
  function G.view_offered()
    return type(CharacterReforged.page_model) == "table" and CharacterReforged.page_model.appearance ~= nil and type(CharacterReforged.page_model.open_view) == "function"
  end
  function G.view_hint()
    if G.viewHint == nil then
      local ok, t = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@, G.VIEW_TEXT)
      if ok and type(t) == "string" and t ~= "" then
        G.viewHint = G.form_glyph() .. " " .. t
      else
        return G.form_glyph()
      end
    end
    return G.viewHint
  end
  function G.hint()
    local view = On() and G.ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE and G.view_offered() and not G.in_office()
    local on = false
    local psub = On() and G.ptype == 2 and not G.in_office()
    if view then
      Cmd(C.SET_TEXT, G.PLATE, G.N_GRADE, G.view_hint(), 0)
      on = true
    elseif psub then
      Cmd(C.SET_TEXT, G.PLATE, G.N_GRADE, "<CMD_FUNC6>", 0)
      on = true
    end
    Cmd(C.TEXT_VIS, G.PLATE, G.N_GRADE, on, 0)
  end

  -- ATRIBUTOS shows the Miximax chart while the chosen form wears the miximax, only for a player whose mix slot
  G.MX_FORMS = {1, 3}
  function G.mx_hdl()
    local a = type(CharacterReforged.stat_radar) == "table" and CharacterReforged.stat_radar.args or nil
    return type(a) == "table" and a[3] or nil
  end
  function G.mx_avail()
    local h = G.mx_hdl()
    if h == nil or type(CharacterReforged.stat_radar.gains) ~= "function" then
      return false
    end
    if G.mxAvailFor ~= h then
      G.mxAvailFor = h
      local ok, g = pcall(CharacterReforged.stat_radar.gains, h)
      -- The Miximax view previews the mix slot's form: none while that slot is level-locked.
      G.mxAvail = ok and type(g) == "table" and not G.slot_form_locked(h, "mix")
      pcall(funcLuaCommand, C.LOG, "PlayerPage mx avail", tostring(h), tostring(G.mxAvail))
    end
    return G.mxAvail == true
  end
  -- Returns the miximax form among the shown player's forms (plate_model's list, once it is his).
  function G.first_form(list)
    local M = CharacterReforged.page_model
    if type(list) ~= "table" or type(M) ~= "table" or type(M.forms) ~= "table" or M.fhdl == nil or M.fhdl ~= M.want then
      return nil
    end
    for _, f in ipairs(list) do
      for _, x in ipairs(M.forms) do
        if x == f then
          return f
        end
      end
    end
    return nil
  end
  -- the gains of the Miximax view (with every graph refresh, after G.vals)
  function G.mx_gains(hdl)
    G.gains = nil
    if type(CharacterReforged.stat_radar) == "table" and CharacterReforged.stat_radar.mx == true and type(CharacterReforged.stat_radar.gains) == "function" then
      local ok, g = pcall(CharacterReforged.stat_radar.gains, hdl)
      if ok and type(g) == "table" then
        G.gains = g
      end
    end
  end
  -- the radar's last call again (numbers, values, gains), as plate_hiper's L3 does
  function G.mx_redraw()
    local a = type(CharacterReforged.stat_radar) == "table" and CharacterReforged.stat_radar.args or nil
    if type(a) == "table" and type(UpdateCharaParameterGraphByCharaStHdl) == "function" then
      pcall(UpdateCharaParameterGraphByCharaStHdl, a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8])
    end
  end
  function G.mx_set(on, why)
    if (CharacterReforged.stat_radar.mx == true) == on then
      return
    end
    CharacterReforged.stat_radar.mx = on
    pcall(funcLuaCommand, C.LOG, "PlayerPage mx view", tostring(why), tostring(on))
    G.mx_redraw()
  end
  -- ONE form state for the whole player page: plate_model's chosen form (CharacterReforged.page_model, M.fidx). The
  -- form key (R3 / BetterQoL's view-forms key) and a badge click cycle it on every page of G.FORM_PAGES; the model,
  -- the badge, ATRIBUTOS' Miximax chart and the Hiper page's shown slot follow it (G.form_follow), across page changes.
  G.FORM_PAGES = {[CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE] = true, [CharacterReforged.PLAYER_PAGE_STATS_TYPE] = true,
    [0] = true, [1] = true, [3] = true, [5] = true, [6] = true}   -- Pasivas (2) keeps the key for its sub-pages
  -- Returns true when form f wears the miximax (plate_model's FUSED_FORMS).
  function G.fused(f)
    local M = CharacterReforged.page_model
    return type(M) == "table" and type(M.FUSED_FORMS) == "table" and M.FUSED_FORMS[f] == true
  end
  -- Returns the shown player's chosen form, nil while his form list is not loaded.
  function G.shown_form()
    local M = CharacterReforged.page_model
    if type(M) ~= "table" or type(M.forms) ~= "table" or M.fhdl == nil or M.fhdl ~= M.want then
      return nil
    end
    return M.forms[M.fidx or 1] or 0
  end
  -- The form key is live while the page is up (G.pageUp: OnOpenLayer / OnCloseLayer of the page) on a form page.
  function G.form_key_set(why)
    local on = On() and G.H.pages and G.pageUp == true and G.ptype ~= nil and G.FORM_PAGES[G.ptype] == true
      and not G.in_office()
    if (CharacterReforged.PAGE_MODEL_FORM_KEY == true) ~= on then
      CharacterReforged.PAGE_MODEL_FORM_KEY = on
      pcall(funcLuaCommand, C.LOG, "PlayerPage form key", tostring(why), tostring(on), tostring(G.ptype))
    end
  end
  -- The press (key or badge click): the retail view on PERFIL where a rules menu offers it, else the next form.
  function G.form_press(why)
    local M = CharacterReforged.page_model
    if CharacterReforged.PAGE_MODEL_FORM_KEY ~= true or type(M) ~= "table" then
      return false
    end
    if G.ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE and G.view_offered() then
      return M.open_view(why)
    end
    return M.form_press(why)
  end
  -- Everything that shows the form follows the state (plate_model's form change, a page change, the page opening).
  function G.form_follow(why)
    if not On() or not G.H.pages then
      return
    end
    local f = G.shown_form() or 0
    if type(CharacterReforged.stat_radar) == "table" then
      local mx = G.fused(f) and G.mx_avail()
      if G.ptype == CharacterReforged.PLAYER_PAGE_STATS_TYPE and not G.in_office() then
        G.mx_set(mx, why)
      else
        CharacterReforged.stat_radar.mx = mx       -- drawn when ATRIBUTOS draws its chart
      end
    end
    G.hiperKey = nil                              -- the Hiper page reads the slot again (G.hiper_form_step)
    G.fbKey = nil                                 -- the badge is placed again with the new form
  end
  function CharacterReforged.page_form_changed(f, why)
    pcall(funcLuaCommand, C.LOG, "PlayerPage form", tostring(why), tostring(f))
    G.form_follow(why)
  end

  G.HIPER_TYPE = 5                        -- the Hiper page's type (plate_hiper, page index 4)
  G.SLOT_FORMS = {mix = G.MX_FORMS, aura = {2}}
  function G.hiper_chara()
    if type(GetPersonalPlateSelectCharaStHdlAuto) ~= "function" then
      return 0
    end
    local ok, v = pcall(GetPersonalPlateSelectCharaStHdlAuto)
    return ok and type(v) == "number" and v or 0
  end
  -- the form of the aura the page shows (nil = none) and its slot
  function G.hiper_target(c)
    if c == 0 or type(CharacterReforged.hyper_page_skill) ~= "function" or type(CharacterReforged.hyper_page_mix_of) ~= "function" then
      return nil
    end
    local okS, sk = pcall(CharacterReforged.hyper_page_skill, c)
    if not okS or type(sk) ~= "number" or sk == 0 then
      return nil
    end
    local okM, mix = pcall(CharacterReforged.hyper_page_mix_of, c)
    local slot = (okM and mix == sk) and "mix" or "aura"
    return G.first_form(G.SLOT_FORMS[slot]), slot
  end
  function G.hiper_double_set(view, c, why)
    if (CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW == true) ~= view then
      CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW = view
      if type(CharacterReforged.hyper_page_show) == "function" and c ~= 0 then
        pcall(CharacterReforged.hyper_page_show, c)
      end
    end
    G.hiperTgt, G.hiperSlot = G.hiper_target(c)
    pcall(funcLuaCommand, C.LOG, "PlayerPage hiper view", tostring(why), view and "mix" or "aura", tostring(G.hiperTgt))
  end
  -- Returns true when the player page's model may not show Hiper `slot`'s form of card `c` (a learn level he has not reached).
  function G.slot_form_locked(c, slot)
    local M = CharacterReforged.page_model
    return c ~= 0 and type(M) == "table" and type(M.slot_need) == "function" and M.slot_need(c, slot) > 0
  end
  -- The Hiper page's slot data (once per player / form list / shown slot); a double hyper shows the mix slot while the
  -- chosen form wears the miximax, else the aura slot.
  function G.hiper_form_step()
    if not On() or not G.H.pages or G.ptype ~= G.HIPER_TYPE or G.in_office() then
      G.hiperKey, G.hiperTgt, G.hiperDouble, G.hiperSlot = nil, nil, nil, nil
      return
    end
    local M = CharacterReforged.page_model
    local c = G.hiper_chara()
    local n = type(M) == "table" and type(M.forms) == "table" and #M.forms or 0
    local f = G.shown_form()
    local key = string.format("%s:%s:%d:%s:%s", tostring(c), tostring(type(M) == "table" and M.fhdl), n, tostring(f),
      tostring(CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW))
    if key == G.hiperKey then
      return
    end
    G.hiperKey = key
    local okc, can = false, false
    if type(CharacterReforged.hyper_page_can_switch) == "function" and c ~= 0 then
      okc, can = pcall(CharacterReforged.hyper_page_can_switch, c)
    end
    G.hiperDouble = okc and can == true
    if G.hiperDouble and f ~= nil then
      G.hiper_double_set(G.fused(f) and not G.slot_form_locked(c, "mix"), c, "form")
    else
      G.hiperTgt, G.hiperSlot = G.hiper_target(c)
    end
    pcall(funcLuaCommand, C.LOG, "PlayerPage hiper form", "slot", tostring(G.hiperSlot), tostring(G.hiperTgt),
      tostring(f), G.hiperDouble and "double" or "single")
  end

  -- Glyphs per slot, including the mode change.
  G.SLOT_GLYPH = {[0] = {@crc:cr_pp_fb_keshin@, @crc:cr_pp_fb_keshin_dim@},
    [1] = {@crc:cr_pp_fb_armour@, @crc:cr_pp_fb_armour_dim@},
    [2] = {@crc:cr_pp_fb_miximax@, @crc:cr_pp_fb_miximax_dim@},
    [3] = {@crc:cr_pp_fb_totem@, @crc:cr_pp_fb_totem_dim@},
    [6] = {@crc:cr_pp_fb_mode@, @crc:cr_pp_fb_mode_dim@}}
  function G.slot_glyph(skill, lit)
    local t = nil
    if type(CharacterReforged.hyper_card) == "table" and type(CharacterReforged.hyper_card.aura_type) == "function" and type(skill) == "number" and skill ~= 0 then
      local ok, v = pcall(CharacterReforged.hyper_card.aura_type, skill)
      t = ok and v or nil
    end
    local g = (t ~= nil and G.SLOT_GLYPH[t]) or G.SLOT_GLYPH[0]
    return g[lit and 1 or 2], t
  end
  -- Returns a double hyper's badge.
  function G.hiper_double_glyphs()
    local c = G.hiper_chara()
    if c == 0 or type(CharacterReforged.hyper_page_mix_of) ~= "function" or type(CharacterReforged.hyper_page_aura_of) ~= "function" then
      return nil
    end
    local okM, mix = pcall(CharacterReforged.hyper_page_mix_of, c)
    local okA, aura = pcall(CharacterReforged.hyper_page_aura_of, c)
    if not (okM and okA) then
      return nil
    end
    local mv = CharacterReforged.HYPER_PAGE_MIXIMAX_VIEW == true
    -- A slot whose form is level-locked keeps its dim glyph.
    local mix_locked, aura_locked = G.slot_form_locked(c, "mix"), G.slot_form_locked(c, "aura")
    local gm, tm = G.slot_glyph(mix, mv and not mix_locked)
    local ga, ta = G.slot_glyph(aura, not mv and not aura_locked)
    return {gm, ga}, string.format("d%s:%s:%s:%s:%s", mv and "m" or "a", tostring(tm), tostring(ta), tostring(mix_locked),
      tostring(aura_locked))
  end

  -- The form badge on PERFIL shows while the player has more than one form.
  G.FBADGE = @crc:cr_pp_fbadge@
  G.FB_TRACE = {[0] = @crc:cr_pp_fbadge0@, @crc:cr_pp_fbadge1@, @crc:cr_pp_fbadge2@}
  G.FB_KEY = 2                               -- the RS key's plate instance
  G.FB_PLATE = @crc:cr_pp_fb_key@          -- the key's light plate
  G.FORM_GLYPHS = {[0] = {@crc:cr_pp_fb_player@}, {@crc:cr_pp_fb_miximax@}, {@crc:cr_pp_fb_armour@},
    {@crc:cr_pp_fb_mxarmour@, @crc:cr_pp_fb_miximax@}, {@crc:cr_pp_fb_armour@, @crc:cr_pp_fb_miximax@}}
  G.FB_AT = {1700, 262}                      -- the badge row's centre (screen px)
  G.FB_S, G.FB_GAP = 40, 6                   -- tile / key plate size, gap between them (screen px)
  G.FB_KEY_K = 0.8                           -- the key text's scale
  G.FB_KEY_DX, G.FB_KEY_DY = 3, -4
  G.FLABEL = @crc:cr_pp_flabel@
  G.N_AREA_TEXT = 1899787537
  G.N_AREA_BASE = 3516146179
  function G.fb_hide()
    G.fbKey, G.fbBox, G.fbShown = nil, nil, nil
    for i = 0, 2 do
      if Exists(G.FBADGE) and Cmd(C.IS_OPEN, G.FBADGE, i) == true then
        Cmd(C.VIS, G.FBADGE, i, false)
      end
    end
    if Exists(G.FLABEL) and Cmd(C.IS_OPEN, G.FLABEL, 0) == true then
      Cmd(C.VIS, G.FLABEL, 0, false)
    end
  end
  -- Places one gauge copy as a tile.
  function G.fb_place(i, sprite, left, top, s)
    local L = G.FBADGE
    if not G.ready[L * 16 + i] then
      G.ready[L * 16 + i] = true
      Cmd(C.TRACE, G.PAGE, 0, G.FB_TRACE[i], true)
      for _, m in ipairs({G.N_TOP, G.N_SIDE, 2043683848}) do
        Cmd(C.MESH, L, m, false, i)
      end
    end
    local sx, sy = s / 476, s / 44
    Cmd(C.SPRITE, L, G.TX_OWN, sprite, G.SP_FRAME, 0, i)
    Cmd(C.SCALE, L, sx, sy, 1, i)
    Cmd(C.POS, L, left - 94 * sx, -top + 816 * sy, 0, i)
  end
  -- The badge shows the chosen form (G.shown_form) on every form page while the player has more than one form; a
  -- double hyper shows both slots there, the shown one lit. Hidden while the page is down (G.pageUp).
  function G.form_badge()
    local glyphs, f = nil, nil
    local up = On() and G.pageUp == true and G.ptype ~= nil and G.FORM_PAGES[G.ptype] == true and not G.in_office()
    if up and G.ptype == CharacterReforged.PLAYER_PAGE_DESCRIPTION_TYPE and G.view_offered() then
      glyphs = nil                             -- PERFIL offers the retail view: its hint instead
    elseif up and G.ptype == G.HIPER_TYPE and G.hiperDouble == true then
      glyphs, f = G.hiper_double_glyphs()
    elseif up and G.form_count() > 1 then
      f = G.shown_form() or 0
      glyphs = G.FORM_GLYPHS[f]
    end
    local L, T = G.FBADGE, G.FLABEL
    if glyphs == nil or not Exists(L) or not Exists(T) then
      -- an instance opened for a badge that never finished stays hidden (no raw gauge)
      G.fb_hide()
      return
    end
    local n = #glyphs
    for i = 0, n - 1 do
      if not Ready(L, i) then
        return
      end
    end
    if not Ready(L, G.FB_KEY) or not Ready(T, 0) then
      return
    end
    if not G.ready[T * 16] then
      G.ready[T * 16] = true
      G.fbKey = nil
      Cmd(C.TRACE, G.PAGE, 0, T, true)
      Cmd(C.MESH, T, G.N_AREA_BASE, false, 0)
      Cmd(C.SCALE, T, G.FB_KEY_K, G.FB_KEY_K, 1, 0)
      Cmd(C.SET_TEXT, T, G.N_AREA_TEXT, G.form_glyph(), 0)
      Cmd(2735666188 --[[text visible]], T, G.N_AREA_TEXT, true, 0)
    end
    for i = 0, n - 1 do
      if not G.ready[L * 16 + i] then
        G.fbKey = nil                          -- an instance (re)opened: place it again
      end
    end
    if not G.ready[L * 16 + G.FB_KEY] then
      G.fbKey = nil
    end
    local key = tostring(f) .. "/" .. n
    if G.fbKey ~= key then
      G.fbKey, G.fbShown = key, nil
      local s, gap = G.FB_S, G.FB_GAP
      local w = (n + 1) * s + n * gap
      local left, top = G.FB_AT[1] - w / 2, G.FB_AT[2] - s / 2
      for i = 0, n - 1 do
        G.fb_place(i, glyphs[i + 1], left + i * (s + gap), top, s)
      end
      for i = n, G.FB_KEY - 1 do               -- a tile the form does not use
        if Cmd(C.IS_OPEN, L, i) == true then
          Cmd(C.VIS, L, i, false)
        end
      end
      local kx = left + n * (s + gap)
      G.fb_place(G.FB_KEY, G.FB_PLATE, kx, top, s)
      Cmd(C.POS, T, kx + G.FB_KEY_DX + 165 * G.FB_KEY_K, -(G.FB_AT[2] + G.FB_KEY_DY), 0, 0)
      G.fbBox = {left, top, w, s}              -- the pointer zone (click = next form)
      pcall(funcLuaCommand, C.LOG, "PlayerPage form badge", tostring(f), n, string.format("%.0f", left))
    end
    if G.fbShown ~= key then                   -- shown once per placement, not every frame
      G.fbShown = key
      for i = 0, n - 1 do
        Cmd(C.VIS, L, i, true)
      end
      Cmd(C.VIS, L, G.FB_KEY, true)
      Cmd(C.VIS, T, 0, true)
    end
  end
