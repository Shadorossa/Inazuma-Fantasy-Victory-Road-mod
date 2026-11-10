-- VRFW
VRFW.drop_list = VRFW.drop_list or {}
do
  local D = VRFW.drop_list
  D.ROW = @crc:CMND_VRFW_DROP_ROW@
  D.TEXT_AURAS = @crc:vrfw_drop_list_auras@          -- menu_text "AURAS"
  D.TEXT_GET = @crc:CMND_TEXT_GET@                            -- (textId) -> text
  D.SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@                            -- (layer, text node, string, instance)
  D.TEXT_VISIBLE = @crc:CMND_SET_MENU_TEXT_VISIBLE@                        -- (layer, text node, on, instance)
  D.TEXT_RECT = @crc:CMND_GET_MENU_TEXT_RECT_SIZE@                           -- (layer, instance, text node, string) -> w, h
  D.MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@                        -- (layer, mesh, on, instance)
  D.LOC_VISIBLE = 2158717427                         -- (layer, locator, on, instance)
  D.NODE_POS = 1856671416                            -- (layer, instance, node, x, y, z)
  D.NODE_SCALE = 2885415772                          -- (layer, instance, node, w, h)
  D.SET_TEX = 558735651                              -- (layer, atlas path, sprite, texture slot, 0, instance)
  D.LOAD_TEX = @crc:CMND_LOAD_MENU_RES_TEXTURE@                             -- (path)
  D.ALPHA = @crc:CMND_SET_LAYER_MODEL_ALPHA@                               -- (layer, instance, 1, alpha, mesh)
  D.FACE = 346643487                                 -- face icon (layer, instance, mesh, slot, charaId, 0, size, ...)
  D.SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@                          -- (item, n): 7 element, 13 aura type, 17 aura chara
  D.W38 = 2268931645                                 -- #/menu/10_win/win05/win05_38/<LG>/win05_38.g4tx
  D.T30_PATH = "#/menu/102_team/team00/team00_30/<LG>/team00_30.g4tx"
  D.T30 = 2815298114                                 -- crc of D.T30_PATH (the aura cards' atlas)
  D.HEADER = 3948576367 --[[vrfw_gtxt_auras01]]      -- VRFW image: the "AURAS" label in the "Items" style
  -- nodes and their retail layout {node, x, y, w, h}
  D.N = {
    name = {1704438437 --[[_text_name01]], 131, 27},
    pill = {802624838 --[[_gtxt_spirits01]], 0, 18, 104, 36},
    line = {1428028149 --[[_offer_partition_line01]], 113, 2, 630, 4},
    band = {2913709463 --[[_list_drop_chr_rarity01]], 8, 36, 516, 72},
    art = {3879379975 --[[_list_drop_chr_dmy01]], 10, 64, 128, 128},
    percent = {2780643282 --[[_pos_percent01]], 539, 0},
    icon = {1550177077 --[[_pos_icon_item01]], 69, 0}
  }
  D.BASE = 4248781227 --[[_list_drop_base01]]
  D.BOOST = 4108315022 --[[_pos_boost01]]
  D.RESET_FACE = 4176779611                          -- ResetFaceIcon (layer, instance, texture slot)
  D.HIDE_TABS = @crc:CMND_VRFW_DROP_HIDE_TABS@        -- () -> the tab types never shown ([VRFW.DropList] HideTabs)
  D.TAB_ITEM = 4044286600 --[[cmn06_20_list_tab_item]]
  D.ART_SIZE = {[0] = 8, [1] = 8, [2] = 12, [3] = 14, [4] = 8, [5] = 8, [6] = 12}
  D.PLATE = 837199438 --[[_item_base01]]
  D.CHR = 2336812131 --[[_pos_chr01]]
  D.SLOT_BAND = 94010567 --[[list_drop_chr_rarity01]]
  D.SLOT_ART = 2605092343 --[[list_drop_chr_dmy01]]
  -- The aura banner in the row.
  D.AURA = {band = {23, 35, 724, 69}, art = {629, 64, 128, 128}, percent = {469, 0}, icon = {57, 0}}
  -- The name's room on an aura row.
  D.NAME_ROOM = 320
  D.BANDS = {
    [0] = {@crc:fs_base01@, @crc:fs_base02@, @crc:fs_base03@, @crc:fs_base04@, @crc:fs_base05@},
    [1] = {@crc:fsa_base01@, @crc:fsa_base02@, @crc:fsa_base03@, @crc:fsa_base04@, @crc:fsa_base05@},
    [2] = {@crc:mixi_base01@, @crc:mixi_base02@, @crc:mixi_base03@, @crc:mixi_base04@, @crc:mixi_base05@},
    [3] = {@crc:soul_base01@, @crc:soul_base02@, @crc:soul_base03@, @crc:soul_base04@, @crc:soul_base05@},
    [4] = {@crc:kizuna_base01@, @crc:kizuna_base02@, @crc:kizuna_base03@, @crc:kizuna_base04@, @crc:kizuna_base05@},
    [5] = {@crc:power_base01@, @crc:power_base02@, @crc:power_base03@, @crc:power_base04@, @crc:power_base05@},
    [6] = {3293713115, 1566262113, 710702071, 3023627860, 3275740866}    -- mode_base01-05
  }
  D.styled = {}   -- instance -> "aura" / "header" (its nodes moved)
  D.ART_DELAY = 6
  D.art_t = {}
  D.forced = false

  function D.section()
    local s, kind, id, pic = VRFW.host.command(D.ROW)
    if s == nil then
      return -1
    end
    return s, kind, id, pic
  end

  local function pos(L, i, n, x, y)
    VRFW.host.menu_command(D.NODE_POS, L, i, n[1], x or n[2], y or n[3], 0)
  end

  local function size(L, i, n, w, h)
    VRFW.host.menu_command(D.NODE_SCALE, L, i, n[1], w or n[4], h or n[5])
  end

  -- the retail layout of an instance a section row changed
  function D.plain(L, i)
    if D.styled[i] == nil then
      return
    end
    local N = D.N
    pos(L, i, N.name)
    pos(L, i, N.pill)
    size(L, i, N.pill)
    pos(L, i, N.line)
    size(L, i, N.line)
    pos(L, i, N.band)
    size(L, i, N.band)
    pos(L, i, N.art)
    size(L, i, N.art)
    pos(L, i, N.percent)
    pos(L, i, N.icon)
    VRFW.host.menu_command(D.MESH_VISIBLE, L, D.BASE, true, i)
    VRFW.host.menu_command(D.MESH_VISIBLE, L, D.PLATE, true, i)
    D.styled[i] = nil
  end

  -- The "AURAS" header = the game's own header row (the "Items" pill, its size and place, the partition line).
  function D.header(L, i, pic)
    VRFW.host.menu_command(D.SET_TEX, L, D.W38, pic or D.HEADER, 4088285385 --[[gtxt_spirits01]], 0, i)
  end

--@lib vrfw_block_helpers.lua#DropAuraArt

  function D.specific_name(L, i, item, chara)
    local name = VRFW.host.command(@crc:CMND_GET_ITEM_PARAM@, item, 0)
    if type(name) ~= "string" then
      return
    end
    local tail = string.match(name, "[:：]%s*(.-)%s*$")
    if tail == nil or tail == "" then
      return
    end
    local w = VRFW.host.menu_command(D.TEXT_RECT, L, i, D.N.name[1], name)
    if type(w) == "number" and w <= D.NAME_ROOM then
      return
    end
    if string.find(tail, "<", 1, true) ~= nil and chara ~= 0 then
      local a, b = VRFW.host.command(@crc:CMND_GET_CHARA_INFO@, chara, 10)
      tail = (type(b) == "string" and b) or (type(a) == "string" and a) or nil
    end
    if tail ~= nil and tail ~= "" then
      VRFW.host.menu_command(D.SET_TEXT, L, D.N.name[1], tail, i)
    end
  end

  function D.aura(L, i, item)
    local N, A = D.N, D.AURA
    local okt, kind = VRFW.host.command(D.SKILL_INFO, item, 13)
    local oke, elem = VRFW.host.command(D.SKILL_INFO, item, 7)
    if not okt or type(kind) ~= "number" then
      kind = 0
    end
    local bands = D.BANDS[kind] or D.BANDS[0]
    if not oke or type(elem) ~= "number" or elem < 1 then
      elem = 1
    elseif elem > 5 then
      elem = 5
    end
    D.styled[i] = "aura"
    VRFW.host.menu_command(D.LOC_VISIBLE, L, D.CHR, true, i)
    -- The spirit rows' "POTENCIADOR" tag lives under the same locator.
    VRFW.host.menu_command(D.LOC_VISIBLE, L, D.BOOST, false, i)
    VRFW.host.menu_command(D.MESH_VISIBLE, L, D.BOOST, false, i)
    VRFW.host.menu_command(D.MESH_VISIBLE, L, D.BASE, false, i)
    VRFW.host.menu_command(D.MESH_VISIBLE, L, D.PLATE, false, i)
    VRFW.host.menu_command(D.SET_TEX, L, D.T30, bands[elem], D.SLOT_BAND, 0, i)
    VRFW.host.menu_command(D.MESH_VISIBLE, L, N.band[1], true, i)
    pos(L, i, N.band, A.band[1], A.band[2])
    size(L, i, N.band, A.band[3], A.band[4])
    pos(L, i, N.percent, A.percent[1], A.percent[2])
    pos(L, i, N.icon, A.icon[1], A.icon[2])
    local chara = DropAuraChara(item)
    if kind == 2 or kind == 6 then
      D.specific_name(L, i, item, chara)
    end
    local shown = false
    if chara ~= 0 then
      VRFW.host.menu_command(D.RESET_FACE, L, i, D.SLOT_ART)
      local okp, drawn = pcall(DropAuraPortrait, D, L, i, N.art[1], D.SLOT_ART, chara, kind)
      shown = okp and drawn == true
    end
    if shown then
      D.art_t[i] = D.ART_DELAY
      VRFW.host.menu_command(D.ALPHA, L, i, 1, 0, N.art[1])
      VRFW.host.menu_command(D.MESH_VISIBLE, L, N.art[1], true, i)
      pos(L, i, N.art, A.art[1], A.art[2])
      size(L, i, N.art, A.art[3], A.art[4])
    else
      VRFW.host.menu_command(D.MESH_VISIBLE, L, N.art[1], false, i)
    end
  end
end

-- A list whose match asks it (a gacha node's game, CMND_VRFW_GACHA_OF_GAME).
VRFW.drop_list.GAME_PARAM = 3946214491                 -- the list's game (the command menu's RegisterPropValue)
VRFW.drop_list.GACHA_OF_GAME = @crc:CMND_VRFW_GACHA_OF_GAME@
VRFW.drop_list.EXCLUDE_OWNED = @crc:CMND_VRFW_DROP_LIST_EXCLUDE_OWNED@
function VRFW.drop_list.exclude_owned_for(game)
  local D = VRFW.drop_list
  local pool = VRFW.host.command(D.GACHA_OF_GAME, game or 0)
  local on = type(pool) == "number" and pool > 0
  VRFW.host.command(D.EXCLUDE_OWNED, on and 1 or 0)
end

local vrfw_dl_init = OnInit
function OnInit(...)
  local game = 0
  if VRFW.param.has(VRFW.drop_list.GAME_PARAM) then
    local g = VRFW.param.get(VRFW.drop_list.GAME_PARAM)
    if type(g) == "number" then game = g end
  end
  VRFW.drop_list.exclude_owned_for(game)
  local r = {vrfw_dl_init(...)}
  VRFW.host.menu_command(VRFW.drop_list.LOAD_TEX, VRFW.drop_list.T30_PATH)
  VRFW.drop_list.styled = {}
  return table.unpack(r)
end

local vrfw_dl_tab = OnTabChanged
function OnTabChanged(a1, ...)
  VRFW.drop_list.forced = true -- the retail flag4: the focused row is redrawn once
  return vrfw_dl_tab(a1, ...)
end

local function vrfw_dl_dirty(a3, a4)
  local D = VRFW.drop_list
  if D.forced and a4 then
    D.forced = false
    return true
  end
  return a3
end

local vrfw_dl_item = UpdateListItem_DropItem
function UpdateListItem_DropItem(a1, a2, a3, a4, a5, a6, a7)
  local dirty = vrfw_dl_dirty(a3, a4)
  local r = {vrfw_dl_item(a1, a2, a3, a4, a5, a6, a7)}
  local D = VRFW.drop_list
  local s = D.section()
  if s == 2 then
    if dirty then
      pcall(D.aura, a1, a2, a5)
    end
    -- the retail call hides the portrait mesh of item rows every frame (UpdateListItem_IconMesh)
    local t = D.art_t[a2] or 0
    if t > 0 then
      D.art_t[a2] = t - 1
    end
    VRFW.host.menu_command(D.ALPHA, a1, a2, 1, t > 0 and 0 or 1, D.N.art[1])
  elseif dirty then
    pcall(D.plain, a1, a2)
  end
  return table.unpack(r)
end

local vrfw_dl_chara = UpdateListItem_DropChara
function UpdateListItem_DropChara(a1, a2, a3, a4, a5, a6, a7, a8)
  local dirty = vrfw_dl_dirty(a3, a4)
  if dirty then
    pcall(VRFW.drop_list.plain, a1, a2)
  end
  return vrfw_dl_chara(a1, a2, a3, a4, a5, a6, a7, a8)
end

local vrfw_dl_iline = UpdateListItem_ItemLine
function UpdateListItem_ItemLine(a1, a2, a3, ...)
  local r = {vrfw_dl_iline(a1, a2, a3, ...)}
  if a3 then
    local D = VRFW.drop_list
    local s, _, _, pic = D.section()
    if s == 1 then
      pcall(D.header, a1, a2)
    elseif s == 3 and type(pic) == "number" then
      -- A declared section ([[VRFW.DropList.Sections]]).
      pcall(D.header, a1, a2, pic)
    else
      pcall(D.plain, a1, a2)
    end
  end
  return table.unpack(r)
end

local vrfw_dl_cline = UpdateListItem_CharaLine
function UpdateListItem_CharaLine(a1, a2, a3, ...)
  if a3 then
    pcall(VRFW.drop_list.plain, a1, a2)
  end
  return vrfw_dl_cline(a1, a2, a3, ...)
end

local vrfw_dl_tabs = OnUpdateTabData
function OnUpdateTabData(a1, ...)
  local D = VRFW.drop_list
  local got = {VRFW.host.command(D.HIDE_TABS)}
  local hide = {}
  for k = 1, #got do
    if type(got[k]) == "number" then
      hide[got[k]] = true
    end
  end
  local left = 0
  if type(a1) == "table" and next(hide) ~= nil then
    for k = 1, #a1 do
      if hide[k - 1] then
        a1[k] = 0
      end
      if a1[k] == 1 then
        left = left + 1
      end
    end
  end
  local r = {vrfw_dl_tabs(a1, ...)}
  if left == 1 then
    local n = VRFW.host.menu_command(@crc:CMND_GET_CREATE_LAYER_NUM@, D.TAB_ITEM)
    for k = 0, ((type(n) == "number") and n or 1) - 1 do
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, D.TAB_ITEM, k, false)
    end
  end
  return table.unpack(r)
end

local vrfw_dl_final = FinalizeMenu
function FinalizeMenu(...)
  VRFW.host.command(VRFW.drop_list.EXCLUDE_OWNED, 0)
  if vrfw_dl_final ~= nil then
    return vrfw_dl_final(...)
  end
end
