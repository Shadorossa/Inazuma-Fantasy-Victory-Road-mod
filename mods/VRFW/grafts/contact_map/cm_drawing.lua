local function HideAll()
  for i = 0, N.TILE - 1 do
    Kit.hide_off_screen(L_TILE, i)
  end
  for i = 0, N.TAG - 1 do
    Kit.hide_off_screen(L_TAG, i)
  end
  for i = 0, N.FACE - 1 do
    Kit.hide_off_screen(L_FACE, i)
  end
  for i = 0, N.BUST - 1 do
    HideBust(L_BUST, i)
  end
  for i = 0, N.LINE - 1 do
    Kit.hide_off_screen(L_LINE, i)
  end
  for i = 0, N.UI - 1 do
    Kit.hide_off_screen(L_UI, i)
  end
  for i = 0, N.TITLE - 1 do
    Kit.hide_off_screen(L_TITLE, i)
  end
  if mode ~= "grid" and CmPages.hide_lineup ~= nil then
    CmPages.hide_lineup()
  end
end

-- Art of a zone's own map (zones whose declaration names one).
local ZONEART = {DIM = {0.62, 0.62, 0.66}}

-- Fits a picture of w x h (a map's 1920 x 1080 background, a zone's own map) into AREA.
local function AreaFit(w, h)
  local k = math.min((AREA.X1 - AREA.X0) / w, (AREA.Y1 - AREA.Y0) / h)
  return k, AREA.CX - w * k / 2, AREA.CY - h * k / 2
end

-- Draws the map's own picture in AREA.
local function DrawZoneArt()
  if true then                      -- no map / zone pictures, the hub's own background shows
    Kit.hide_off_screen(L_ZONEART, 0)
    return
  end
  local z = MAP and MAP.zones[zone]
  local tex, sprite, w, h = nil, nil, 1920, 1080
  if mode == "grid" and z ~= nil and (z.tex or "") ~= "" and (z.aw or 0) > 0 and (z.ah or 0) > 0 then
    tex, sprite, w, h = z.tex, z.sprite, z.aw, z.ah
  elseif mode ~= "list" and mode ~= "shop" and MAP ~= nil and (MAP.tex or "") ~= "" then
    tex, sprite = MAP.tex, MAP.sprite
  end
  local tc = tex and Kit.texture(tex)
  if not tc then
    Kit.hide_off_screen(L_ZONEART, 0)              -- none / loading (Step redraws) / not there
    return
  end
  local k, x0, y0 = AreaFit(w, h)
  Kit.textured_quad(L_ZONEART, 0, tc, CRC32(sprite), x0 + w * k / 2, y0 + h * k / 2, w * k, h * k)
  Kit.tint(L_ZONEART, 0, mode == "grid" and ZONEART.DIM or COLOUR.WHITE)  -- dimmed under a grid: the faces stay readable
end

-- Draws the screen's background (whole screen) and the player panel's ground with its fade into the map over a hub.
local function DrawBack()
  local bg, shown, loading = art.background, false, false
  if bg ~= nil then
    local tc = Kit.texture(bg.atlas)
    loading = tc == false
    shown = tc and Kit.textured_quad(L_BACK, 0, tc, bg.crc, 960, 540, 1920, 1080) ~= false or false
  end
  if not shown then
    Kit.hide_off_screen(L_BACK, 0)
  end
  local hub = HUB.menu ~= nil
  if not hub then
    local ok, parent = pcall(function() return MENU_DEF.GetParentMenuID(MENU) end)
    hub = ok and type(parent) == "number" and parent ~= 0
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_RETAIL_BG, 0, not shown and not loading and not hub)
  local x0 = PANEL.X - PANEL.FADE
  Kit.art_quad(L_PANEL, 0, "panel_ground", (x0 + 1920) / 2, 540, 1920 - x0 + 2, 1080)
  Kit.hide_off_screen(L_PANEL, 1)
end

local function HideReqs()
  for k = 0, N.REQ - 1 do
    Kit.hide_off_screen(L_REQ, k)
    Kit.hide_off_screen(L_REQOK, k)
  end
  Kit.hide_off_screen(L_REQ, REQ.CHECK.BOX_IX)
  Kit.hide_off_screen(L_REQ, REQ.CHECK.MARK_IX)
  local P = INFO.PLATES
  for k = 0, 3 do
    Kit.hide_off_screen(P.L_PLATE, k)
    Kit.hide_off_screen(P.L_BAR, k)
    Kit.hide_off_screen(L_REQ, P.FILL_IX + k)
    Kit.hide_off_screen(L_CARDTXT, P.TXT_COUNT + k)
  end
  Kit.hide_off_screen(P.L_PLATE, P.CHIP_IX)
  Kit.hide_off_screen(L_CARDTXT, P.TXT_HEAD)
  Kit.hide_off_screen(L_CARDTXT, P.TXT_TALLY)
end

-- a requirement kind -> its art role
local REQ_ROLE = {team_level = "requirement_level", wins = "requirement_wins", goals = "requirement_goals",
                  item = "requirement_item", player = "requirement_player", cleared = "requirement_wins",
                  unlock = "requirement_wins", trial = "requirement_goals"}

-- a node whose own requirements are not all met (the tile's badge)
local function ReqsUnmet(node)
  return #VRFW.recruit.missing(node.reqs) > 0
end

function CmClip(s, n)
  if type(s) ~= "string" then
    return s
  end
  local out, k, i = {}, 0, 1
  while i <= #s do
    local tok = s:match("^%[%$[^%]]*%]", i) or s:match("^[%z\1-\127\194-\244][\128-\191]*", i)
    if tok == nil or tok == "" then
      break
    end
    k = k + 1
    if k > n then
      return table.concat(out) .. "…"
    end
    out[k] = tok
    i = i + #tok
  end
  return s
end

local STATUS = {card = nil}
-- Frees the player's temporary status (CMND_ADD_TEMP_CHARA, as the retail "Ficha" of a card nobody owns).
function HEADROW.free()
  if HEADROW.hdl ~= nil then
    if type(VRFW.ui_plates) == "table" then
      VRFW.ui_plates.header_row.noTitle[HEADROW.hdl] = nil
    end
    pcall(funcLuaCommand, HEADROW.TEMP_FREE, HEADROW.hdl)
    HEADROW.hdl = nil
  end
end

function HEADROW.hide()
  for _, l in ipairs({L_STATUS, L_PPROW, L_SLANT}) do
    funcLuaMenuCommand(C.LAYER_VISIBLE, l, 0, false)
  end
end

local function StatusPlate(card, level)
  if card == nil or type(UpdateCharaStatusPlateInfoByCharaParamId) ~= "function" or type(VRFW.ui_plates) ~= "table" then
    if STATUS.card ~= false then
      HEADROW.hide()
      HEADROW.free()
      STATUS.card = false
    end
    return false
  end
  local R = HEADROW
  if STATUS.card ~= card then
    HEADROW.free()
    -- the rarity he joins at (the set's JoinRarity), else his card's
    local rarity = (SET ~= nil and type(SET.join_rarity) == "number") and SET.join_rarity or 0
    if rarity == 0 and type(GetCharaParamRarity) == "function" then
      local ok, r = pcall(GetCharaParamRarity, card)
      rarity = (ok and type(r) == "number") and r or 0
    end
    local ok, hdl = pcall(funcLuaCommand, R.TEMP_ADD, card, math.max(1, Int(level)), rarity, 0, false, false, false,
      false, 0, false, 1)
    R.hdl = (ok and type(hdl) == "number" and hdl ~= 0) and hdl or nil
    local HR = VRFW.ui_plates.header_row
    if R.hdl ~= nil then
      HR.noTitle[R.hdl] = true
    end
    -- Draws the row.
    if R.hdl ~= nil and type(UpdateCharaStatusPlateInfoByCharaStHdl) == "function" then
      HR.without_title(UpdateCharaStatusPlateInfoByCharaStHdl, L_PPROW, 0, R.hdl, 0, -1, 0, nil, nil, 0, false, false, false, 0, true)
      HR.band_fill(L_SLANT, 0, R.hdl)
    else
      HR.without_title(UpdateCharaStatusPlateInfoByCharaParamId, L_PPROW, 0, card, 0, 6, nil, nil, false, nil, nil, -1, -1)
      HR.without_title(UpdateCharaStatusPlateInfoByCharaParamId, L_SLANT, 0, card, 0, 6, nil, nil, false, nil, nil, -1, -1)
      HR.band(L_SLANT, 0, {band = true})
    end
    HR.portrait_off(L_PPROW, 0)
    -- Shows the position badge (DC, MC, DF, POR) in the row, not the archetype glyph.
    local staff, icon = nil, nil
    if R.hdl ~= nil then
      staff, icon = HR.after_fill(L_PPROW, 0, R.hdl)
    end
    if staff == false and icon ~= nil then
      HR.badge(L_PPROW, 0, icon)
    else
      icon = nil
    end
    funcLuaMenuCommand(C.MESH_VISIBLE, L_PPROW, HR.POS, icon ~= nil, 0)
    Log("header row position", tostring(icon))
    funcLuaMenuCommand(C.MESH_VISIBLE, L_PPROW, HR.ROLE, false, 0)
    HR.bare(L_PPROW, 0)
    -- Draws the description.
    HR.without_title(UpdateCharaStatusPlateInfoByCharaParamId, L_STATUS, 0, card, 0, 6, nil, nil, false, nil, nil, -1, -1, nil, nil,
      true)
    pcall(funcLuaMenuCommand, @crc:CMND_PLAY_ANIME_TYPE@, L_STATUS, 0, 902337421 --[[offset01]], 0, 2892647586 --[[shop]])
    HR.band(L_STATUS, 0, {explain = true})
    -- Hides the rarity banner on the card.
    for _, l in ipairs({L_PPROW, L_SLANT, L_STATUS}) do
      HR.bare(l, 0)
    end
    Log("header row", card, "status", tostring(R.hdl), "level", tostring(level), "rarity", tostring(rarity))
    STATUS.card = card
  end
  funcLuaMenuCommand(C.SCALE, L_STATUS, STATUS_AT.S, STATUS_AT.S, 1, 0)       -- bottom right, as the office
  funcLuaMenuCommand(C.POS, L_STATUS, STATUS_AT.DX, -STATUS_AT.DY, 0, 0)
  local HR = VRFW.ui_plates.header_row
  local s, x, y = HR.variant("contact_map")
  HR.place(L_PPROW, 0, s, x, y)
  HR.place_band(L_SLANT, 0, s, x, y)
  -- Hides the blue glowing frame around the row.
  funcLuaMenuCommand(C.MESH_VISIBLE, L_PPROW, HR.FRAME, false, 0)
  for _, l in ipairs({L_STATUS, L_PPROW, L_SLANT}) do
    funcLuaMenuCommand(C.LAYER_VISIBLE, l, 0, true)
  end
  return true
end

-- Draws the panel.
function ReqRow(r)
  if r == nil then
    return INFO.BLANK, nil
  end
  local have = VRFW.recruit.have(r)
  local need = r.count or 1
  local ok = have >= need
  local count = need > 1 and ("  " .. tostring(math.min(have, need)) .. "/" .. tostring(need)) or ""
  -- Reads the third value.
  if r.kind == "player" then
    local name = (r.name or "") ~= "" and r.name or Kit.text(T.UNKNOWN)
    local ic = {bust = r.ids and r.ids[1], ok = ok, have = have, need = need}
    if (r.level or 0) > 1 then
      local l = Kit.format(T.REQ_PLAYER_LEVEL, CmClip(name, INFO.CLIP - 16), r.level)
      return l, ic, l
    end
    local l = Kit.format(T.REQ_SIGN, CmClip(name, INFO.CLIP - 10))
    return l, ic, l
  elseif r.kind == "item" then
    local title = (r.title ~= nil and r.title ~= 0) and Kit.text(r.title) or ItemTitle(r.id)
    local l = Kit.format(T.REQ_GET, CmClip(title, INFO.CLIP - 14))
    return l .. "  " .. tostring(math.min(have, need)) .. "/" .. tostring(need),
      {item = r.id, role = "requirement_item", ok = ok, have = have, need = need}, l
  end
  local role = REQ_ROLE[r.kind] or "requirement_item"
  if r.kind == "position" then
    role = "requirement_position_" .. tostring(r.position)
  end
  local text = ""
  if r.kind == "team_level" then
    text = Kit.format(T.REQ_TEAM_LEVEL, need, have)
  elseif r.kind == "element" then
    text = Kit.format(T.REQ_ELEM, Kit.text(T.ELEM[r.element] or T.UNKNOWN), need, have)
  elseif r.kind == "position" then
    text = Kit.format(T.REQ_ELEM, Kit.text(T.POS[r.position] or T.UNKNOWN), need, have)
  elseif r.kind == "wins" then
    text = Kit.format(T.REQ_WINS, need, have)
  elseif r.kind == "goals" then
    text = Kit.format(T.REQ_GOALS, need, have)
  elseif r.kind == "cleared" then
    text = Kit.format(T.REQ_BEAT, CmClip((r.name or "") ~= "" and r.name or Kit.text(T.UNKNOWN), INFO.CLIP - 10))
  elseif r.kind == "unlock" then
    text = Kit.format(T.REQ_BEAT_MORE, CmClip((r.name or "") ~= "" and r.name or Kit.text(T.UNKNOWN), INFO.CLIP - 16))
  elseif r.kind == "trial" then
    text = CmPages.trial_text(r)
  end
  local short = text
  local sid = T.REQ_SHORT[r.kind]
  if sid ~= nil then
    local what = r.kind == "element" and Kit.text(T.ELEM[r.element] or T.UNKNOWN)
      or (r.kind == "position" and Kit.text(T.POS[r.position] or T.UNKNOWN) or nil)
    short = what ~= nil and Kit.format(sid, what) or Kit.text(sid)
  end
  return text .. count, {role = role, ok = ok, have = have, need = need}, short
end

-- Draws a row's icon.
local function RowIcon(k, ic, y, x, sz)
  x, sz = x or INFO.ICON_X, sz or INFO.ICON
  if ic == nil then
    Kit.hide_off_screen(L_REQ, k)
    Kit.hide_off_screen(L_REQOK, k)
    if k < N.CARD_BUSTS then
      HideBust(L_BUST, N.BUST - N.CARD_BUSTS + k)
    end
    return
  end
  if ic.bust ~= nil and k < N.CARD_BUSTS then
    Kit.hide_off_screen(L_REQ, k)
    DrawBust(L_BUST, N.BUST - N.CARD_BUSTS + k, ic.bust, x, y, sz * 1.25)
  else
    if k < N.CARD_BUSTS then
      HideBust(L_BUST, N.BUST - N.CARD_BUSTS + k)
    end
    local position_icon = ic.position_card ~= nil and VRFW.chara_icons.position(ic.position_card) or nil
    local position_tc = position_icon ~= nil and Kit.texture(position_icon.tex) or nil
    local tc = ic.elem ~= nil and ELEM_ICON[ic.elem] ~= nil and Kit.texture(COMMON_TEX) or nil
    if position_tc then             -- the game's position icon (a price in position spirits)
      Kit.textured_quad(L_REQ, k, position_tc, position_icon.sprite, x, y, sz, sz)
    elseif tc then                  -- the game's element icon (a price in element spirits)
      Kit.textured_quad(L_REQ, k, tc, CRC32(ELEM_ICON[ic.elem]), x, y, sz, sz)
    else
      Kit.art_quad(L_REQ, k, ic.role or "requirement_item", x, y, sz, sz)
    end
    if ic.item ~= nil then          -- the item's own icon (the game's item icon composite on the quad)
      local ok, r = pcall(funcLuaMenuCommand, 3508889864 --[[item icon]], L_REQ, k, MESH_QUAD, NODE_QUAD, ic.item)
      if not INFO.logged then
        INFO.logged = true
        Log("card item icon", tostring(ic.item), tostring(ok), tostring(r))
      end
    end
  end
  if ic.ok ~= nil then
    Kit.art_quad(L_REQOK, k, ic.ok and "badge_met" or "badge_unmet",
      x + sz * 0.4, y + sz * 0.4, sz * 0.5, sz * 0.5)
  else
    Kit.hide_off_screen(L_REQOK, k)
  end
end

-- Draws the requirement card's header and its 4 plates.
function CmPages.req_plates(rows)
  local P = INFO.PLATES
  local met, all = 0, 0
  for k = 1, 4 do
    local i, y, r = k - 1, P.Y[k], rows[k]
    if r == nil then
      Kit.art_quad(P.L_PLATE, i, "requirement_plate_empty", P.X, y, P.W, P.H)
      RowIcon(i, nil, y)
      Kit.hide_off_screen(L_CARDTXT, i)
      Kit.hide_off_screen(P.L_BAR, i)
      Kit.hide_off_screen(L_REQ, P.FILL_IX + i)
      Kit.hide_off_screen(L_CARDTXT, P.TXT_COUNT + i)
    else
      local ic = r[2]
      local counted = ic ~= nil and ic.need ~= nil
      local ok = ic ~= nil and ic.ok == true
      if counted then
        all = all + 1
        met = met + (ok and 1 or 0)
      end
      if ok then
        Kit.art_quad(P.L_PLATE, i, "requirement_plate_met", P.X, y, P.W, P.H)
      else
        Kit.art_quad(P.L_PLATE, i, "requirement_plate_unmet", P.X, y, P.W, P.H)
      end
      RowIcon(i, ic, y, P.ICON_X, P.ICON)
      local x = ic ~= nil and P.TEXT_X or P.ICON_X - P.ICON / 2
      Line(L_CARDTXT, i, CmClip(r[1], counted and P.CLIP or P.NOTE_CLIP), x, y, P.TEXT_S)
      if counted then
        -- "have / need" right-aligned (have green when met, red when not), the bar left of it
        local plain = Kit.format(T.REQ_COUNT, tostring(ic.have), ic.need)
        local w = CmPages.text_width(L_CARDTXT, P.TXT_COUNT + i, plain) * P.TEXT_S
        Line(L_CARDTXT, P.TXT_COUNT + i, Kit.format(T.REQ_COUNT, (ok and P.MET or P.UNMET) .. tostring(ic.have) .. P.RESET,
          ic.need), P.COUNT_R - w, y, P.TEXT_S)
        local bx = P.COUNT_R - w - P.BAR_GAP - P.BAR_W / 2
        Kit.art_quad(P.L_BAR, i, "requirement_bar_base", bx, y, P.BAR_W, P.BAR_H)
        local inner = P.BAR_W - 2 * P.BAR_IN
        local fw = inner * math.max(0, math.min(1, ic.have / math.max(1, ic.need)))
        if fw >= 1 then
          Kit.art_quad(L_REQ, P.FILL_IX + i, ok and "requirement_bar_met" or "requirement_bar_unmet",
            bx - inner / 2 + fw / 2, y, fw, P.BAR_H - 2 * P.BAR_IN)
        else
          Kit.hide_off_screen(L_REQ, P.FILL_IX + i)
        end
      else
        Kit.hide_off_screen(P.L_BAR, i)
        Kit.hide_off_screen(L_REQ, P.FILL_IX + i)
        Kit.hide_off_screen(L_CARDTXT, P.TXT_COUNT + i)
      end
    end
  end
  -- Draws the header.
  local title = Kit.text(T.REQ_TITLE)
  Line(L_CARDTXT, P.TXT_HEAD, title, INFO.CX - CmPages.text_width(L_CARDTXT, P.TXT_HEAD, title) * P.HEAD_S / 2,
    P.HEAD_Y, P.HEAD_S)
  if all > 0 then
    Kit.art_quad(P.L_PLATE, P.CHIP_IX, "requirement_counter", P.CHIP_X, P.HEAD_Y, P.CHIP_W, P.CHIP_H)
    local plain = Kit.format(T.REQ_COUNT, tostring(met), all)
    local w = CmPages.text_width(L_CARDTXT, P.TXT_TALLY, plain) * P.TEXT_S
    Line(L_CARDTXT, P.TXT_TALLY, Kit.format(T.REQ_COUNT, (met == all and P.MET or P.UNMET) .. tostring(met) .. P.RESET, all),
      P.CHIP_X - w / 2, P.HEAD_Y, P.TEXT_S)
  else
    Kit.hide_off_screen(P.L_PLATE, P.CHIP_IX)
    Kit.hide_off_screen(L_CARDTXT, P.TXT_TALLY)
  end
end

-- Returns a player's price as the requirement card's first plate (nil without a price).
function CmPages.price_plate(n)
  local need = Price(n)
  if need <= 0 then
    return nil
  end
  local have = VRFW.recruit.wallet(CmPages.price_of(n)) or 0
  local ic = {role = "requirement_item", ok = have >= need, have = have, need = need}
  if (n.pay_position or 0) ~= 0 then
    ic.position_card = n.card
  elseif (n.pay_element or 0) ~= 0 then
    ic.elem = n.pay_element
  elseif (n.spirit or 0) == 0 and SET ~= nil and (SET.rc or 0) ~= 0 then
    ic.item = SET.rc
  end
  return {CmPages.pay_unit(n), ic}
end

-- Returns the requirement plates of a player.
function CmPages.plate_rows(n, reqs)
  local rows = {}
  local price = CmPages.price_plate(n)
  if price ~= nil then
    rows[1] = price
  end
  local left = 0
  if price == nil and #reqs == 0 then
    rows[1] = {Kit.text(T.NO_REQ), nil}   -- nothing to pay or meet: one note line, not four empty plates
  end
  for _, r in ipairs(reqs) do
    if #rows < 4 then
      local _, ic, l = ReqRow(r)
      rows[#rows + 1] = {l, ic}
    else
      left = left + 1
    end
  end
  if left > 0 then
    rows[4][1] = rows[4][1] .. " +" .. tostring(left)
  end
  return rows
end

-- Draws the card.
local function Card(lines, face, icon, icons, plates)
  HideReqs()
  HideBust(L_BUSTICON, 0)
  local card = type(face) == "table" and Int(face.card) or 0
  local model = card ~= 0 and PANEL.MODEL and Model ~= nil and Model.ok()
  if model then
    Model.show(card)
    Model.no_turn()
    Kit.hide_off_screen(L_ICON, 0)
    StatusPlate(card, face.level)
  else
    if Model ~= nil then
      Model.hide()
    end
    StatusPlate(nil)
    if icon ~= nil then
      Kit.art_quad(L_ICON, 0, icon, PANEL.ICON_X, PANEL.ICON_Y, PANEL.ICON, PANEL.ICON)
    else
      Kit.hide_off_screen(L_ICON, 0)
    end
  end
  local P = INFO.PLATES
  if plates ~= nil and (lines[5] or "") == "" and (lines[6] or "") == "" then
    Kit.art_quad(L_CARD, 0, "card_panel", INFO.CX, (P.TOP + P.BOTTOM) / 2, INFO.W, P.BOTTOM - P.TOP)
  else
    Kit.art_quad(L_CARD, 0, "card_panel", INFO.CX, INFO.CY, INFO.W, INFO.H)
  end
  Kit.tint(L_CARD, 0, INFO.TINT)        -- a darker blue than the panel: the rows stand out
  icons = icons or {}
  local first = 0
  if plates ~= nil then
    CmPages.req_plates(plates)
    first = 4
  end
  for i = first, 5 do
    local ic = icons[i + 1]
    local y = plates ~= nil and INFO.PLATES.LINE_Y[i - 3] or INFO.YS[i + 1]
    if i < N.REQ then
      RowIcon(i, ic, y)
    end
    local x = ic ~= nil and INFO.TEXT_X or INFO.ICON_X - INFO.ICON / 2
    Line(L_CARDTXT, i, CmClip(lines[i + 1], INFO.CLIP), x, y,
      (i == 0 and icons[1] == nil and lines[2] ~= nil and icon == nil and not model) and INFO.NAME_S or INFO.LINE_S)
  end
end

local function PlayerCard(i)
  local n = MAP.nodes[i]
  if n.kind == "ghost" then
    -- Handles a player of this team signed on another page.
    local lines = {Kit.format(T.SOLD_AT, (n.sold_at or "") ~= "" and n.sold_at or Kit.text(T.UNKNOWN))}
    if n.sold_map ~= nil and (n.sold_team or 0) ~= 0 then
      lines[2] = Kit.text(T.GO_HINT)
    end
    Card(lines, n, nil)
    return
  end
  local st = State(i)
  if st == "locked" then
    Card({Kit.text(T.UNKNOWN), Kit.text(T.STATE_LOCKED)}, nil, "icon_lock")
    return
  end
  -- 4 short requirement rows with their icons, the price with the currency's icon, the state
  local state = Kit.text(st == "done" and T.STATE_DONE or (st == "ready" and T.STATE_READY or T.STATE_MISSING))
  local lines, icons = {}, {}
  if n.story then
    -- Handles a player the game signs in story mode.
    local rows = {}
    for _, t in ipairs(n.notes or {}) do
      rows[#rows + 1] = {t, nil}
    end
    for _, r in ipairs(n.reqs or {}) do
      local _, ic, l = ReqRow(r)
      rows[#rows + 1] = {l, ic}
    end
    lines[5] = Kit.text(T.STORY_ONLY)
    lines[6] = st == "done" and state or ""
    Card(lines, n, nil, icons, {rows[1], rows[2], rows[3], rows[4]})
    return
  end
  if MAP.pitch then
    -- Handles a team page.
    local rows = {}
    for _, r in ipairs(n.reqs or {}) do
      rows[#rows + 1] = r
    end
    local tr = #rows < (Price(n) > 0 and 3 or 4) and CmPages.open_trial(n) or nil
    if tr ~= nil and tr ~= rows[1] then
      rows[#rows + 1] = tr
    end
    lines[5], lines[6] = "", ""
    Card(lines, n, nil, icons, CmPages.plate_rows(n, rows))
    return
  end
  -- the price is the first plate, the state under the plates
  lines[5], lines[6] = state, ""
  Card(lines, n, nil, icons, CmPages.plate_rows(n, n.reqs or {}))
end

local function TileCard(i)
  local n = MAP.nodes[i]
  if n.kind == "player" then
    PlayerCard(i)
  elseif n.kind == "start" then
    Card({Kit.text(T.START)}, nil, "icon_start")
  elseif n.kind == "open" then
    Card({Kit.text(T.OPEN_TILE)}, nil, "icon_check")
  elseif not opened[i] then
    Card({Kit.text(T.UNKNOWN), Kit.text(T.STATE_LOCKED)}, nil, "icon_lock")
  else
    local name = n.name ~= "" and n.name or Kit.text(T.UNKNOWN)
    local want = nil                -- the player the gate asks for (his model; no card: the padlock)
    for _, r in ipairs(n.reqs) do
      if r.kind == "player" and r.ids ~= nil and r.ids[1] ~= nil then
        want = {card = r.ids[1]}
        break
      end
    end
    Card({name, acquired[i] and Kit.text(T.GATE_DONE) or Kit.format(T.GATE, name)}, want, want == nil and "icon_lock" or nil)
  end
end

-- Draws a player's card.
local function Plate(idx, st, x, y, size)
  if st == "locked" then
    Kit.art_quad(L_TILE, idx, "tile_hidden", x, y, size, size)
  else
    Kit.art_quad(L_TILE, idx, "player_plate", x, y, size, size)
  end
  local c = st == "ready" and COLOUR.READY or (st == "done" and COLOUR.DONE or (st == "missing" and COLOUR.MISSING or COLOUR.LOCKED))
  Kit.tint(L_TILE, idx, c)
end

local function DrawCursor()
  local p = pos[focus[mode]]
  if p == nil or p.layer ~= nil then  -- a lineup card: the card's own selection (CmPages.focus_card)
    Kit.hide_off_screen(L_UI, 0)
    return
  end
  local r = math.max(p.hw, p.hh) * 2 * 1.22
  Kit.art_quad(L_UI, 0, "cursor", p.x, p.y, r, r)
end

-- Draws the list of maps (rows as the game's menu rows).
local function DrawList()
  local first = math.max(1, focus.list - LIST.ROWS + 1)
  local left = LIST.CX - LIST.W / 2
  for k = 0, LIST.ROWS - 1 do
    local i = first + k
    local m = SET.maps[i]
    if m == nil or k + LIST.ROWS >= N.TITLE then
      Kit.hide_off_screen(L_TITLE, k)
      Kit.hide_off_screen(L_TITLE, k + LIST.ROWS)
    else
      local y = LIST.TOP + k * LIST.ROW
      local on = i == focus.list
      -- Draws the map's name on the left.
      local s = CmPages.map_title(m)
      local c = tostring(m.signed or 0) .. " / " .. tostring(m.players)
      Line(L_TITLE, k, s, left + 40, y, 1)
      local kc = k + LIST.ROWS
      Line(L_TITLE, kc, c, left + LIST.W - LIST.COUNT_PAD - #c * LIST.COUNT_CH, y, 1)
      for _, t in ipairs({{k, s}, {kc, c}}) do
        funcLuaMenuCommand(C.TEXT, L_TITLE, TEXT_OFF, t[2], t[1])
        funcLuaMenuCommand(C.TEXT_VISIBLE, L_TITLE, TEXT_ON, on, t[1])
        funcLuaMenuCommand(C.TEXT_VISIBLE, L_TITLE, TEXT_OFF, not on, t[1])
      end
      ROW_PLATE.texts[kc] = true
      funcLuaMenuCommand(C.MESH_VISIBLE, L_TITLE, ROW_PLATE.ON, on, k)
      funcLuaMenuCommand(C.MESH_VISIBLE, L_TITLE, ROW_PLATE.OFF, not on, k)
      ROW_PLATE.used[k] = true
      pos[i] = {x = LIST.CX, y = y, hw = LIST.W / 2, hh = LIST.H / 2}
      if on then
        funcLuaMenuCommand(C.POS, L_CURSOR, left - 10, -y, 0, 0)
        funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, true)
      end
    end
  end
  local m = SET.maps[focus.list]
  Card({Kit.text(SET.title), CmPages.map_title(m), Kit.format(T.COUNT, m.signed or 0, m.players)}, nil, nil)
  Kit.hide_off_screen(L_UI, 0)
end

-- the list rows' plates off again (every other view uses the list items as plain text lines)
local function RowPlatesOff()
  for k in pairs(ROW_PLATE.used) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L_TITLE, ROW_PLATE.ON, false, k)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_TITLE, ROW_PLATE.OFF, false, k)
    funcLuaMenuCommand(C.TEXT_VISIBLE, L_TITLE, TEXT_OFF, false, k)
  end
  ROW_PLATE.used = {}
  for k in pairs(ROW_PLATE.texts) do
    funcLuaMenuCommand(C.TEXT_VISIBLE, L_TITLE, TEXT_OFF, false, k)
  end
  ROW_PLATE.texts = {}
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, false)
end

local function ZoneFace(z)
  local first = nil
  for _, i in ipairs(ZoneMembers(z)) do
    first = first or i
    if not IsSigned(i) then
      return MAP.nodes[i]
    end
  end
  return first and MAP.nodes[first] or ""
end

-- Draws the communities and zones of a map as a list.
local function DrawZones()
  local first = math.max(1, focus.zones - LIST.ROWS + 1)
  local left = LIST.CX - LIST.W / 2
  for k = 0, LIST.ROWS - 1 do
    local z = first + k
    local zz = MAP.zones[z]
    if zz == nil or k >= N.TITLE then
      Kit.hide_off_screen(L_TITLE, k)
    else
      local y = LIST.TOP + k * LIST.ROW
      local done = ZoneSigned(z)
      Kit.art_quad(L_TILE, k, "list_row", LIST.CX, y, LIST.W, LIST.H)
      Kit.tint(L_TILE, k, z == focus.zones and COLOUR.ROW_FOCUS or COLOUR.ROW)
      DrawFace(L_FACE, k, ZoneFace(z), left + 44, y, LIST.H - 6)
      Line(L_TITLE, k, CmPages.zone_title(zz) .. "   " .. Kit.format(T.COUNT, done, zz.count), left + 90, y, 1)
      pos[z] = {x = LIST.CX, y = y, hw = LIST.W / 2, hh = LIST.H / 2}
    end
  end
  local zz = MAP.zones[focus.zones]
  if zz ~= nil then
    Card({CmPages.zone_title(zz), Kit.format(T.COUNT, ZoneSigned(focus.zones), zz.count), Kit.text(T.ZONE_HINT)}, ZoneFace(focus.zones))
  end
  Kit.hide_off_screen(L_UI, 0)
end
