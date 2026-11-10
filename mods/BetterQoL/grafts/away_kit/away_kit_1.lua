-- EVT away_kit BEGIN
do
BetterQoL = BetterQoL or {}
BetterQoL.away_kit = BetterQoL.away_kit or {}
BetterQoL.away_kit.KEY = 3114639549
BetterQoL.away_kit.CMD = @crc:CMND_BETTERQOL_TEAM_UNIFORM@
BetterQoL.away_kit.BTN_ICON = 3794706590
BetterQoL.away_kit.BTN_KEY = 3421673595
BetterQoL.away_kit.PAIR_CMD = @crc:CMND_BETTERQOL_AK_PAIR@
-- Home and away twin of a kit id from the plugin, cached.
BetterQoL.away_kit.PAIR_NONE = {}
BetterQoL.away_kit.PAIR = setmetatable({}, {__index = function(t, u)
  if type(u) ~= "number" or u == 0 or BetterQoL.away_kit.PAIR_NONE[u] then
    return nil
  end
  local ok, p = pcall(funcLuaCommand, BetterQoL.away_kit.PAIR_CMD, u)
  if ok and type(p) == "number" and p ~= 0 then
    rawset(t, u, p)
    return p
  end
  if ok then
    BetterQoL.away_kit.PAIR_NONE[u] = true
  end
  return nil
end})
BetterQoL.away_kit.ON = false
BetterQoL.away_kit.SWAP_FROM = nil
BetterQoL.away_kit.SWAP_TO = nil
BetterQoL.away_kit.PEND_INV = 0
BetterQoL.away_kit.PEND_AWAY = false
-- Text keys of the Y guide labels.
BetterQoL.away_kit.TXT = {
  ["away_kit.home"] = 2538732682,
  ["away_kit.away"] = 1087918731,
}
BetterQoL.away_kit.TXT_ID = {}
BetterQoL.away_kit.BTN_SHOWN = nil
-- X (CMD_FUNC4): a kit with a declared variant (CMND_VRFW_KIT_VARIANT) switches between the kit and its variant.
BetterQoL.away_kit.VAR_KEY = 4144554771
BetterQoL.away_kit.VAR_BTN_ICON = 2085238077
BetterQoL.away_kit.VAR_BTN_KEY = 1435897304
BetterQoL.away_kit.VAR_CMD = @crc:CMND_VRFW_KIT_VARIANT@
BetterQoL.away_kit.CHOICE_CMD = @crc:CMND_VRFW_KIT_VARIANT_CHOICE@
-- kit -> { base, variant, label, variant_label }, or false when it has no variant
BetterQoL.away_kit.VAR = {}
-- base kit -> true when its variant is chosen (read once per screen)
BetterQoL.away_kit.CHOICE = {}
BetterQoL.away_kit.VBTN_SHOWN = nil
function BetterQoL.away_kit.text_id(key)
  if BetterQoL.away_kit.TXT_ID[key] == nil then
    local ok, id = pcall(funcLuaCommand, @crc:CMND_VRFW_TEXT_ID@, key)
    BetterQoL.away_kit.TXT_ID[key] = (ok and type(id) == "number" and id ~= 0) and id or BetterQoL.away_kit.TXT[key]
  end
  return BetterQoL.away_kit.TXT_ID[key]
end
local function PlayDenySe()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
end
function BetterQoL.away_kit.check()
  BetterQoL.away_kit.ON = false
  local api, mods = funcLuaCommand(@crc:CMND_VRFW_LOADER_VERSION@)
  if api == false or api == nil or mods == nil or math.floor(mods / 524288) % 2 ~= 1 then
    return
  end
  BetterQoL.away_kit.ON = true
end
function BetterQoL.away_kit.log(a, b, c, d, e)
  if BetterQoL.away_kit.ON then
    BetterQoL.away_kit.logger = BetterQoL.away_kit.logger or VRFW.logger.new("BETTERQOL_AK")
    BetterQoL.away_kit.logger(tostring(a), tostring(b), tostring(c), tostring(d), tostring(e))
  end
end
function BetterQoL.away_kit.team_uniform()
  local ok, u = funcLuaCommand(@crc:CMND_GET_TEAM_SET_INFO@, n4, 0, 7)
  if not ok or u == nil then
    return 0
  end
  return u
end
function BetterQoL.away_kit.equipped_inv()
  local ok, h = funcLuaCommand(@crc:CMND_GET_TEAM_SET_INFO@, n4, 0, 12)
  if not ok or h == nil then
    return 0
  end
  return h
end
function BetterQoL.away_kit.item_uniform(inv)
  if inv == nil or inv == 0 then
    return 0
  end
  local id = funcLuaCommand(2662166687, inv, 0)
  if not id or id == 0 then
    return 0
  end
  local ok, u = funcLuaCommand(845816129, id)
  if not ok or u == nil then
    return 0
  end
  return u
end
function BetterQoL.away_kit.variant(u)
  if not BetterQoL.away_kit.ON or type(u) ~= "number" or u == 0 then
    return nil
  end
  local c = BetterQoL.away_kit.VAR[u]
  if c == nil then
    local ok, base, variant, label, variant_label = pcall(funcLuaCommand, BetterQoL.away_kit.VAR_CMD, u)
    c = false
    if ok and type(base) == "number" and base ~= 0 and type(variant) == "number" and variant ~= 0 then
      c = {base = base, variant = variant, label = label, variant_label = variant_label}
    end
    BetterQoL.away_kit.VAR[u] = c
  end
  return c or nil
end
-- The kit without its variant.
function BetterQoL.away_kit.plain(u)
  local v = BetterQoL.away_kit.variant(u)
  if v ~= nil and u == v.variant then
    return v.base
  end
  return u
end
function BetterQoL.away_kit.chosen(u)
  local c = BetterQoL.away_kit.CHOICE[u]
  if c == nil then
    local ok, on = pcall(funcLuaCommand, BetterQoL.away_kit.CHOICE_CMD, u)
    c = ok and on == true
    BetterQoL.away_kit.CHOICE[u] = c
  end
  return c
end
-- The kit of a row with a variant, nil for the other rows.
function BetterQoL.away_kit.variant_kit(inv)
  if not BetterQoL.away_kit.ON or inv == nil or inv == 0 then
    return nil
  end
  local u = BetterQoL.away_kit.item_uniform(inv)
  local v = BetterQoL.away_kit.variant(u)
  if v == nil or u ~= v.base then
    return nil
  end
  return u
end
function BetterQoL.away_kit.view_variant(inv)
  local u = BetterQoL.away_kit.variant_kit(inv)
  return u ~= nil and BetterQoL.away_kit.chosen(u)
end
-- The kit worn for kit u: its away twin when `away`, then the variant of that one when `var`.
function BetterQoL.away_kit.dressed(u, away, var)
  local t = u
  if away and BetterQoL.away_kit.PAIR[u] ~= nil then
    t = BetterQoL.away_kit.PAIR[u]
  end
  if var then
    local v = BetterQoL.away_kit.variant(t)
    if v ~= nil then
      t = v.variant
    end
  end
  return t
end
function BetterQoL.away_kit.is_away()
  if not BetterQoL.away_kit.ON then
    return false
  end
  local u = BetterQoL.away_kit.item_uniform(BetterQoL.away_kit.equipped_inv())
  local t = BetterQoL.away_kit.plain(BetterQoL.away_kit.team_uniform())
  -- the team wears a twin of its kit item (any candidate twin maps back to the kit)
  return u ~= 0 and t ~= 0 and t ~= u and BetterQoL.away_kit.PAIR[u] ~= nil and BetterQoL.away_kit.PAIR[t] == u
end
-- Returns the variant shown for a row.
function BetterQoL.away_kit.view_away(inv)
  if not BetterQoL.away_kit.ON or inv == nil or inv == 0 then
    return false
  end
  if BetterQoL.away_kit.PEND_INV == inv then
    return BetterQoL.away_kit.PEND_AWAY
  end
  return inv == BetterQoL.away_kit.equipped_inv() and BetterQoL.away_kit.is_away()
end
function BetterQoL.away_kit.focus_uniform(u)
  if BetterQoL.away_kit.ON and u ~= nil and u ~= 0 then
    u = BetterQoL.away_kit.plain(u)
    local k = BetterQoL.away_kit.item_uniform(BetterQoL.away_kit.equipped_inv())
    if k ~= 0 and k ~= u and BetterQoL.away_kit.PAIR[k] ~= nil and BetterQoL.away_kit.PAIR[u] == k then
      return k
    end
  end
  return u
end
function BetterQoL.away_kit.btn_text()
  local key = "away_kit.home"
  if BetterQoL.away_kit.view_away(n3) then
    key = "away_kit.away"
  end
  BetterQoL.away_kit.BTN_SHOWN = key
  return BetterQoL.away_kit.text_id(key)
end
-- Text key of the X prompt of a row, nil when its kit has no variant.
function BetterQoL.away_kit.variant_label(inv)
  local u = BetterQoL.away_kit.variant_kit(inv)
  if u == nil then
    return nil
  end
  local v = BetterQoL.away_kit.variant(u)
  return BetterQoL.away_kit.chosen(u) and v.variant_label or v.label
end
function BetterQoL.away_kit.variant_btn_text()
  local key = BetterQoL.away_kit.variant_label(n3)
  BetterQoL.away_kit.VBTN_SHOWN = key or ""
  if key == nil or key == "" then
    return nil
  end
  return BetterQoL.away_kit.text_id(key)
end
function BetterQoL.away_kit.refresh_guide()
  if not BetterQoL.away_kit.ON or BetterQoL.away_kit.BTN_SHOWN == nil then
    return
  end
  local key = BetterQoL.away_kit.view_away(n3) and "away_kit.away" or "away_kit.home"
  local vkey = BetterQoL.away_kit.variant_label(n3) or ""
  if key ~= BetterQoL.away_kit.BTN_SHOWN or vkey ~= BetterQoL.away_kit.VBTN_SHOWN then
    UpdateButtonGuide()
  end
end
function BetterQoL.away_kit.refresh_preview()
  local cur = n3
  if cur ~= nil and cur ~= 0 then
    n3 = 0
    UpdateItemEquipMenu(cur)
  end
end
function BetterQoL.away_kit.toggle()
  if not BetterQoL.away_kit.ON or n3 == nil or n3 == 0 then
    PlayDenySe()
    return
  end
  local u = BetterQoL.away_kit.item_uniform(n3)
  if u == 0 or BetterQoL.away_kit.PAIR[u] == nil then
    PlayDenySe()
    return
  end
  local away = not BetterQoL.away_kit.view_away(n3)
  BetterQoL.away_kit.PEND_INV, BetterQoL.away_kit.PEND_AWAY = n3, away
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3848881948 --[[sy0000]])
  BetterQoL.away_kit.log("preview", n3, u, away)
  BetterQoL.away_kit.refresh_preview()
  BetterQoL.away_kit.refresh_guide()
end
-- X: the focused kit switches to or from its variant (kept per kit); the team wears it at once when it is its kit.
function BetterQoL.away_kit.toggle_variant()
  local u = BetterQoL.away_kit.variant_kit(n3)
  if u == nil then
    return
  end
  local on = not BetterQoL.away_kit.chosen(u)
  local ok, now = pcall(funcLuaCommand, BetterQoL.away_kit.CHOICE_CMD, u, on)
  BetterQoL.away_kit.CHOICE[u] = ok and now == true
  if BetterQoL.away_kit.CHOICE[u] ~= on then
    PlayDenySe()
    return
  end
  if n3 == BetterQoL.away_kit.equipped_inv() then
    local worn = BetterQoL.away_kit.team_uniform()
    local want = BetterQoL.away_kit.dressed(BetterQoL.away_kit.plain(worn), false, on)
    if worn ~= 0 and want ~= worn then
      local wrote = funcLuaCommand(BetterQoL.away_kit.CMD, n4, 0, want)
      BetterQoL.away_kit.log("variant worn", n4, worn, want, wrote)
    end
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3848881948 --[[sy0000]])
  BetterQoL.away_kit.log("variant", n3, u, on)
  BetterQoL.away_kit.refresh_preview()
  BetterQoL.away_kit.refresh_guide()
end
local BETTERQOL_AK_OnInit_retail = OnInit
function OnInit()
  BETTERQOL_AK_OnInit_retail()
  BetterQoL.away_kit.CHOICE = {}
  BetterQoL.away_kit.check()
end
local BETTERQOL_AK_OnEnter_retail = OnEnter
function OnEnter(a1, a2)
  local inv = n3
  local away = BetterQoL.away_kit.view_away(inv)
  local var = BetterQoL.away_kit.view_variant(inv)
  BETTERQOL_AK_OnEnter_retail(a1, a2)
  if BetterQoL.away_kit.ON and inv ~= nil and inv ~= 0 then
    local u = BetterQoL.away_kit.item_uniform(inv)
    local t = BetterQoL.away_kit.dressed(u, away, var)
    if t ~= u then
      local ok = funcLuaCommand(BetterQoL.away_kit.CMD, n4, 0, t)
      if not ok then
        PlayDenySe()
      end
      BetterQoL.away_kit.log(away and "commit Visitante" or "commit Local", n4, u, t, ok)
    else
      BetterQoL.away_kit.log("commit Local", n4, u, BetterQoL.away_kit.team_uniform(), true)
    end
    BetterQoL.away_kit.PEND_INV, BetterQoL.away_kit.PEND_AWAY = 0, false
    BetterQoL.away_kit.refresh_preview()
  end
  BetterQoL.away_kit.refresh_guide()
end
local BETTERQOL_AK_OnFunction_retail = OnFunction
function OnFunction(a1, a2)
  if a1 == BetterQoL.away_kit.KEY then
    BetterQoL.away_kit.toggle()
    return
  end
  if a1 == BetterQoL.away_kit.VAR_KEY then
    BetterQoL.away_kit.toggle_variant()
    return
  end
  return BETTERQOL_AK_OnFunction_retail(a1, a2)
end
local BETTERQOL_AK_Check_retail = CheckTeamDockUniformEquip
function CheckTeamDockUniformEquip(a1, a2)
  if BETTERQOL_AK_Check_retail(a1, a2) then
    return true
  end
  if not BetterQoL.away_kit.ON or a2 == nil then
    return false
  end
  local worn = GetTeamDockUniformId(a1)
  if worn == nil then
    return false
  end
  local t = BetterQoL.away_kit.plain(worn)
  if t == a2 then
    return t ~= worn
  end
  return BetterQoL.away_kit.PAIR[a2] ~= nil and BetterQoL.away_kit.PAIR[t] == a2 and BetterQoL.away_kit.item_uniform(BetterQoL.away_kit.equipped_inv()) == a2
end
local BETTERQOL_AK_UpdateItemEquipMenu_retail = UpdateItemEquipMenu
function UpdateItemEquipMenu(a1)
  BetterQoL.away_kit.SWAP_FROM, BetterQoL.away_kit.SWAP_TO = nil, nil
  if BetterQoL.away_kit.PEND_INV ~= 0 and a1 ~= BetterQoL.away_kit.PEND_INV then
    BetterQoL.away_kit.PEND_INV, BetterQoL.away_kit.PEND_AWAY = 0, false
  end
  local u = BetterQoL.away_kit.item_uniform(a1)
  if u ~= 0 then
    local t = BetterQoL.away_kit.dressed(u, BetterQoL.away_kit.view_away(a1), BetterQoL.away_kit.view_variant(a1))
    if t ~= u then
      BetterQoL.away_kit.SWAP_FROM, BetterQoL.away_kit.SWAP_TO = u, t
    end
  end
  local r = table.pack(BETTERQOL_AK_UpdateItemEquipMenu_retail(a1))
  BetterQoL.away_kit.refresh_guide()
  return table.unpack(r, 1, r.n)
end
local BETTERQOL_AK_UpdateCharaModel_retail = UpdateCharaModel
function UpdateCharaModel(a1, a2, a3, ...)
  if BetterQoL.away_kit.SWAP_FROM ~= nil and a3 == BetterQoL.away_kit.SWAP_FROM then
    a3 = BetterQoL.away_kit.SWAP_TO
  end
  return BETTERQOL_AK_UpdateCharaModel_retail(a1, a2, a3, ...)
end
end
-- EVT away_kit END
