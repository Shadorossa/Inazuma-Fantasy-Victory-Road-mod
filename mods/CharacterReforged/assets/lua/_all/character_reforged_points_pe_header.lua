if type(rawget(_ENV, "UpdateCharaStatusPlateInfoByCharaStHdl")) == "function" then
  CharacterReforged_PointsStamina = type(CharacterReforged_PointsStamina) == "table" and CharacterReforged_PointsStamina or {}
  if CharacterReforged_PointsStamina.plate == nil then
    local P = {}
    CharacterReforged_PointsStamina.plate = P
    P.ON = true                            -- false: no PE in the header
    P.CMD = 3773092675                      -- CMND_CHARACTERREFORGED_POINTS_STAMINA_MAX
    P.MX_GAINS = 3196510668
    P.BAR = 2311839887                     -- character_reforged_points_pe_plate_bar
    P.TAG = 4240300966                     -- character_reforged_points_pe_plate_tag
    P.NUM = 595051339                     -- character_reforged_points_pe_plate_num
    P.NUM2 = 4227355094                      -- character_reforged_points_pe_plate_num2
    P.NUM3 = 2365546816                    -- character_reforged_points_pe_plate_num3
    P.FILL = 3199757983                    -- character_reforged_points_pe_plate_fill
    P.CMD_CURRENT = 3933572936             -- CMND_CHARACTERREFORGED_POINTS_STAMINA
    P.TAG_DY, P.TAG_H = 20, 16                                 -- "PE" tag: top below the band's top, height (width 2 x)
    P.BAR_W, P.BAR_H = 112, 12                                 -- bar frame mesh size (retail frame 476 x 44); its
                                                               -- visible top touches the tag's bottom
    P.DIG_W, P.DIG_H = 11, 16
    P.NUM_INSET = 6
    P.FIS_INDEX = 18
    P.TAG_X, P.TAG_Y, P.BAR_X = 1453, -183, 1453               -- set from the slot at each fill

    -- retail names (crc32)
    local CMD_EXIST = 262659071            -- CMND_IS_EXIST_LAYER (layer)
    local CMD_OPEN = 629267548             -- CMND_OPEN_LAYER
    local CMD_IS_OPEN = 2640875187         -- CMND_IS_OPEN_LAYER
    local CMD_LOADING = 3057768039         -- CMND_IS_LOADING_LAYER
    local CMD_VISIBLE = 711242136          -- CMND_SET_LAYER_VISIBLE (layer, inst, on)
    local CMD_IS_VISIBLE = 1262717583      -- CMND_IS_LAYER_VISIBLE (layer, inst)
    local CMD_POS = 1389957207             -- CMND_SET_LAYER_LOCAL_POS (layer, x, y, z, inst)
    local CMD_SCALE = 3778714801           -- CMND_SET_LAYER_LOCAL_SCALE (layer, x, y, z, inst)
    local CMD_MESH = 3405944500            -- CMND_SET_MESH_VISIBLE (layer, mesh, on, inst)
    local CMD_TRACE = 1774843228           -- attach trace on / off
    local CMD_SWAP_TEX = 558735651
    local CMD_CHARA = 1131797651           -- chara status value (hdl, index, ...)
    local G_X, G_Y, G_W, G_H = 94, -816, 476, 44
    local MESH_LABEL = 1257514352          -- _gtxt_stamina01
    local MESH_EMPTY, MESH_FILL = 2609329121, 2043683848       -- _hp_empty01, _hp_bar02
    local ATLAS = 1191797350
    local OWN_ATLAS = 3908013348 -- #/menu/02_btl/character_reforged_points_hud/<LG>/character_reforged_points_hud.g4tx
    local TEX_TAG, TEX_FRAME = 823782039, 538967808           -- character_reforged_points_pe_tag01, hp_base01
    local TEX_FILL = 1460691304            -- hp_bar02
    local FILL_X, FILL_Y, FILL_W, FILL_H = 100, -820, 448, 24
    local G_VIS_TOP = 2                    -- the frame's visible rows are 2..29 of the 44-row mesh
    P.DIGITS = {[0] = 2791988324, 3513609458, 1214528840, 1063456222, 2701629565, 3590367467, 1326053713, 940493255,
      2830226518, 3753305280}
    P.digit = {}

    P.want = nil
    P.pending = false                      -- a draw waits for the layers to load
    P.shown = false
    P.ready = {}
    P.ABSENT = false                       -- the loader has no CMND_CHARACTERREFORGED_POINTS_STAMINA_MAX

    -- max PE of chara status handle hdl, nil = nothing to show (invalid handle, no command, mode "log")
    function P.max_of(hdl)
      if P.ABSENT or type(hdl) ~= "number" or hdl == 0 or type(funcLuaCommand) ~= "function" then
        return nil
      end
      if type(IsInvalidSoccerCharaHdl) == "function" then
        local ok, bad = pcall(IsInvalidSoccerCharaHdl, hdl)
        if ok and bad == true then
          return nil
        end
      end
      local fis = VRFW.host.command(CMD_CHARA, hdl, P.FIS_INDEX, true, false)
      if type(fis) ~= "number" or fis ~= fis then
        return nil
      end
      local has, max, on = VRFW.host.command(P.CMD, fis, hdl)
      if has == nil then
        return nil
      end
      if has ~= true or on ~= 1 or type(max) ~= "number" or max <= 0 then
        return nil
      end
      return math.floor(max + 0.5)
    end

    function P.rate_of(hdl)
      local has, cur, max = VRFW.host.command(P.CMD_CURRENT, hdl)
      if has ~= true or type(cur) ~= "number" or type(max) ~= "number" or max <= 0 then
        return 1, nil
      end
      return math.max(0, math.min(1, cur / max)), math.max(0, math.floor(cur + 0.5))
    end

    function P.mx_shown()
      local CR = rawget(_ENV, "CharacterReforged")
      local R = type(CR) == "table" and CR.stat_radar or nil
      if type(R) == "table" and R.mx == true then
        return true
      end
      local G = type(CR) == "table" and CR.player_page or nil
      if type(G) ~= "table" or type(G.mx_form) ~= "function" or type(G.cur_form) ~= "function" then
        return false
      end
      local okm, mf = pcall(G.mx_form)
      local okc, cf = pcall(G.cur_form)
      return okm and okc and mf ~= nil and cf == mf
    end

    function P.mx_gain(hdl)
      local r = {VRFW.host.command(P.MX_GAINS, hdl)}
      if r[1] ~= true then
        return 0
      end
      local g = tonumber(r[13]) or 0
      return g > 0 and math.floor(g) or 0
    end

    function P.bar_top()
      return P.TAG_Y - P.TAG_H + G_VIS_TOP * P.BAR_H / G_H
    end

    function P.bar_pos()
      local sx, sy = P.BAR_W / G_W, P.BAR_H / G_H
      return P.BAR_X - G_X * sx, P.bar_top() - G_Y * sy, sx, sy
    end

    function P.tag_pos()
      local sx, sy = 2 * P.TAG_H / G_W, P.TAG_H / G_H
      return P.TAG_X - G_X * sx, P.TAG_Y - G_Y * sy, sx, sy
    end

    function P.fill_pos(rate)
      local bx, by, bsx, bsy = P.bar_pos()
      local sx, sy = FILL_W * rate * bsx / G_W, FILL_H * bsy / G_H
      return bx + FILL_X * bsx - G_X * sx, by + FILL_Y * bsy - G_Y * sy, sx, sy
    end

    function P.num_pos(k)
      local sx, sy = P.DIG_W / G_W, P.DIG_H / G_H
      local x0 = P.BAR_X + P.BAR_W - P.NUM_INSET - k * P.DIG_W
      local top = P.TAG_Y - P.TAG_H + P.DIG_H
      return x0 - G_X * sx, top - G_Y * sy, sx, sy
    end

    local function Digits()
      return {P.NUM, P.NUM2, P.NUM3}
    end

    local function Layers()
      return {P.BAR, P.FILL, P.TAG, P.NUM, P.NUM2, P.NUM3}
    end

    local function HideAll()
      for _, l in ipairs(Layers()) do
        VRFW.host.menu_command(CMD_VISIBLE, l, 0, false)
      end
      P.shown = false
    end

    function P.hide()
      P.want, P.pending = nil, false
      if P.shown then
        HideAll()
      end
    end

    local function Ready(l)
      if VRFW.host.menu_command(CMD_IS_OPEN, l) ~= true then
        P.ready[l] = false
        P.digit[l] = nil
        VRFW.host.menu_command(CMD_OPEN, l)
        return false
      end
      return VRFW.host.menu_command(CMD_LOADING, l) ~= true
    end

    local function Setup(l)
      VRFW.host.menu_command(CMD_MESH, l, MESH_LABEL, false, 0)
      VRFW.host.menu_command(CMD_MESH, l, MESH_EMPTY, false, 0)
      VRFW.host.menu_command(CMD_MESH, l, MESH_FILL, false, 0)
      if l == P.TAG then
        VRFW.host.menu_command(CMD_SWAP_TEX, l, OWN_ATLAS, TEX_TAG, TEX_FRAME, 0, 0)
      elseif l == P.FILL then
        VRFW.host.menu_command(CMD_SWAP_TEX, l, ATLAS, TEX_FILL, TEX_FRAME, 0, 0)
      elseif l ~= P.BAR then
        P.digit[l] = nil
      end
    end

    function P.digits_of(n)
      n = math.max(0, math.min(999, math.floor(n)))
      local d = {n % 10}
      if n >= 10 then
        d[2] = math.floor(n / 10) % 10
      end
      if n >= 100 then
        d[3] = math.floor(n / 100)
      end
      return d
    end

    function P.draw()
      local w = P.want
      if w == nil then
        return true
      end
      local all = true
      for _, l in ipairs(Layers()) do
        if not Ready(l) then
          all = false
        end
      end
      if not all then
        P.pending = true
        return false
      end
      P.pending = false
      for _, l in ipairs(Layers()) do
        if not P.ready[l] then
          P.ready[l] = true
          Setup(l)
        end
        VRFW.host.menu_command(CMD_TRACE, w.plate, w.inst, l, true)
      end
      local x, y, sx, sy = P.bar_pos()
      VRFW.host.menu_command(CMD_SCALE, P.BAR, sx, sy, 1, 0)
      VRFW.host.menu_command(CMD_POS, P.BAR, x, y, 0, 0)
      local filled = w.rate > 0.001
      if filled then
        x, y, sx, sy = P.fill_pos(w.rate)
        VRFW.host.menu_command(CMD_SCALE, P.FILL, sx, sy, 1, 0)
        VRFW.host.menu_command(CMD_POS, P.FILL, x, y, 0, 0)
      end
      x, y, sx, sy = P.tag_pos()
      VRFW.host.menu_command(CMD_SCALE, P.TAG, sx, sy, 1, 0)
      VRFW.host.menu_command(CMD_POS, P.TAG, x, y, 0, 0)
      local dig = P.digits_of(w.max)
      for k, l in ipairs(Digits()) do
        local d = dig[k]
        if d ~= nil then
          x, y, sx, sy = P.num_pos(k)
          VRFW.host.menu_command(CMD_SCALE, l, sx, sy, 1, 0)
          VRFW.host.menu_command(CMD_POS, l, x, y, 0, 0)
          if P.digit[l] ~= d then
            P.digit[l] = d
            VRFW.host.menu_command(CMD_SWAP_TEX, l, OWN_ATLAS, P.DIGITS[d], TEX_FRAME, 0, 0)
          end
        end
      end
      VRFW.host.menu_command(CMD_VISIBLE, P.BAR, 0, true)
      VRFW.host.menu_command(CMD_VISIBLE, P.FILL, 0, filled)
      VRFW.host.menu_command(CMD_VISIBLE, P.TAG, 0, true)
      for k, l in ipairs(Digits()) do
        VRFW.host.menu_command(CMD_VISIBLE, l, 0, dig[k] ~= nil)
      end
      P.shown = true
      return true
    end

    function P.fill(ctx)
      if not P.ON then
        return 0
      end
      if VRFW.host.menu_command(CMD_EXIST, P.BAR) ~= true then
        return 0                           -- a screen without the PE layers
      end
      local max = P.max_of(ctx.hdl)
      if max == nil then
        P.hide()
        return 0
      end
      P.TAG_X, P.BAR_X = ctx.x, ctx.x
      P.TAG_Y = ctx.top - P.TAG_DY
      local mx = P.mx_shown()
      local rate, current = P.rate_of(ctx.hdl)
      P.want = {plate = ctx.layer, inst = ctx.inst or 0, base = max, hdl = ctx.hdl, mx = mx, rate = rate,
                live = current ~= nil, max = current or (max + (mx and P.mx_gain(ctx.hdl) or 0))}
      P.draw()
      return P.BAR_W
    end

    function P.step()
      if P.pending then
        P.draw()
        return
      end
      local w = P.want
      if w == nil then
        return
      end
      local mx = P.mx_shown()
      if mx ~= w.mx then
        w.mx = mx
        if not w.live then
          w.max = w.base + (mx and P.mx_gain(w.hdl) or 0)
        end
        if P.shown then
          P.draw()
          return
        end
      end
      local vis = VRFW.host.menu_command(CMD_IS_VISIBLE, w.plate, w.inst) == true
      if P.shown and not vis then
        HideAll()
      elseif not P.shown and vis then
        P.draw()
      end
    end

    function CharacterReforged_PointsStamina.plate_pe(phase, ctx)
      if phase == "fill" then
        return P.fill(ctx)
      elseif phase == "step" then
        P.step()
      end
      return 0
    end
  end
end
