-- Block appended to the retail chunk
do
  CharacterReforged_AuraCommands = CharacterReforged_AuraCommands or {}
  local M = CharacterReforged_AuraCommands
  M.ROW = 1580043721
  M.SKILL_INFO = @crc:CMND_GET_SOCCER_SKILL_INFO@        -- (skill, column)
  M.TEAM_SLOT = @crc:CMND_GET_TEAM_SET_INFO@         -- (team, sub, 15, slot) -> ok, chara, skill: a team aura command row
  M.CHARA_PARAM = 1131797651       -- (chara, 4) -> the card's param id
  M.PAIR_ROW = 418718599           -- (aura, param) -> ok, the aura's own pair row for that character
  M.FACE_KEY = 347353059           -- (param) -> face key (the retail miximax window's partner key)
  M.MESH = @crc:CMND_SET_MESH_VISIBLE@
  M.IS_OPEN = @crc:CMND_IS_OPEN_LAYER@           -- (layer, inst)
  M.LOADING = @crc:CMND_IS_LOADING_LAYER@           -- (layer)
  M.AREA = 2164615260
  M.AREA_SLOT = 566439826          -- icon_sp_area_dmy01 (its texture slot)
  M.SPRITE = 558735651             -- CMND_SWAP_SPRITE (layer, atlas, sprite, slot, 0, inst)
  M.ICON_ATLAS = 2320109963
  M.retail = M.retail or {}
  M.filled = M.filled or {}
  M.said = M.said or {}

  function M.log(...)
    M.logger = M.logger or VRFW.logger.new("CharacterReforged.aura_commands")
    M.logger(...)
  end

  local function hex(v)
    return string.format("%08X", (tonumber(v) or 0) % 4294967296)
  end

  local function info(skill, column)
    local okc, ok, v = pcall(funcLuaCommand, M.SKILL_INFO, skill, column)
    if okc and ok then
      return v
    end
    return nil
  end

  -- Calls f(...) with funcLuaCommand replaced by a version that asks answer(real, cmd, ...) first.
  function M.with_answers(answer, f, ...)
    local real = funcLuaCommand
    funcLuaCommand = function(cmd, ...)
      local r = answer(real, cmd, ...)
      if r ~= nil then
        return table.unpack(r, 1, r.n)
      end
      return real(cmd, ...)
    end
    local r = table.pack(pcall(f, ...))
    funcLuaCommand = real
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  function M.category_icon(skill, chara)
    local cat = info(skill, 9)
    if cat == nil or type(GetSkillCategoryIcon) ~= "function" then
      return 0
    end
    local ok, icon = pcall(GetSkillCategoryIcon, cat, skill, chara or 0)
    return (ok and type(icon) == "number") and icon or 0
  end

  local function badge(skill, chara)
    if (HissatsuReforged == nil or type(HissatsuReforged.move_icons) ~= "table") or type(HissatsuReforged.move_icons.mask) ~= "function" then
      return false
    end
    local okc, common = pcall(funcLuaCommand, HissatsuReforged.move_icons.COMMON, skill, chara or 0)
    local okm, mask = pcall(HissatsuReforged.move_icons.mask, skill)
    return not (okc and common == true) and okm and type(mask) == "number" and mask > 0
  end

  -- after the retail fill of slot `slot` (row = {ok, chara, skill} of that slot, nil = not read)
  function M.after_row(slot, row)
    local MP = type(VRFW.ui_plates) == "table" and VRFW.ui_plates.move_plate or nil
    if type(MP) ~= "table" or type(MP.kept) ~= "table" or type(MP.pending) ~= "table" then
      return
    end
    local key = tostring(M.ROW) .. ":" .. tostring(slot)
    local chara = row ~= nil and row.ok and row.chara or 0
    local skill = row ~= nil and row.ok and row.skill or 0
    if chara == nil or chara == 0 or skill == nil or skill == 0 then
      MP.kept[key] = nil
      MP.pending[key] = nil
      return
    end
    -- Keeps the placeholder off and shows the badge slot only when the skill has a badge.
    local armed = type(MP.armed) == "function" and MP.armed(skill) == true
    MP.kept[key] = {row = M.ROW, inst = slot, move = skill, armed = armed, sub = badge(skill, chara)}
    -- Sets the category icon (aura kind).
    local icon = M.category_icon(skill, chara)
    if icon ~= 0 then
      funcLuaMenuCommand(M.SPRITE, M.ROW, M.ICON_ATLAS, icon, M.AREA_SLOT, 0, slot)
    end
    funcLuaMenuCommand(M.MESH, M.ROW, M.AREA, icon ~= 0, slot)
    if not M.said["row" .. tostring(slot)] then
      M.said["row" .. tostring(slot)] = true
      M.log("row", tostring(slot), hex(chara), hex(skill), "icon", hex(icon), "armed", tostring(armed))
    end
    -- Fills the slot again when it is the first fill in this screen or its instance is not ready yet.
    local ready = funcLuaMenuCommand(M.IS_OPEN, M.ROW, slot) == true and funcLuaMenuCommand(M.LOADING, M.ROW) ~= true
    if not M.filled[slot] or not ready then
      M.filled[slot] = true
      MP.pending[key] = {fn = M.refill, row = M.ROW, inst = slot, chara = chara, move = skill, o = {},
        frame = MP.frame or 0, tries = 0}
    end
  end

  function M.refill(row, slot)
    if type(UpdateSkillSlot) == "function" then
      UpdateSkillSlot(slot)
    end
  end

  if M.retail.UpdateSkillSlot == nil then
    M.retail.UpdateSkillSlot = UpdateSkillSlot
  end
  if M.retail.UpdateSkillSlot ~= nil then
    function UpdateSkillSlot(slot, ...)
      local seen = nil
      local r = table.pack(M.with_answers(function(real, cmd, a1, a2, a3, a4, ...)
        if cmd == M.TEAM_SLOT and a3 == 15 and a4 == slot then
          local res = table.pack(real(cmd, a1, a2, a3, a4, ...))
          seen = {ok = res[1] == true, chara = res[2], skill = res[3]}
          return res
        end
        return nil
      end, M.retail.UpdateSkillSlot, slot, ...))
      local ok, err = pcall(M.after_row, slot, seen)
      if not ok and not M.said.row then
        M.said.row = true
        M.log("row state failed", tostring(slot), tostring(err))
      end
      return table.unpack(r, 1, r.n)
    end
  end

  if M.retail.OnInit == nil then
    M.retail.OnInit = OnInit
  end
  if M.retail.OnInit ~= nil then
    function OnInit(...)
      M.filled = {}
      M.card = nil
      return M.retail.OnInit(...)
    end
  end

  if M.retail.Step == nil then
    M.retail.Step = Step
  end
  if M.retail.Step ~= nil then
    function Step(...)
      local r = table.pack(M.retail.Step(...))
      local MP = type(VRFW.ui_plates) == "table" and VRFW.ui_plates.move_plate or nil
      if type(MP) == "table" and type(MP.pump) == "function" then
        pcall(MP.pump, true)
      end
      return table.unpack(r, 1, r.n)
    end
  end

  local function ask_fusion(chara)
    local okp, pexists, ppartner, pm1 = pcall(funcLuaCommand, CALC_CRC("CMND_CHARACTERREFORGED_MIXIMAX_FUSION_GET"), chara)
    if okp and pexists == true then
      return ppartner, pm1
    end
    return nil
  end

  -- Returns whether the skill is a Mix-Max carrier.
  function M.is_carrier(skill, chara)
    local okr, restricted = pcall(funcLuaCommand, CALC_CRC("CMND_VRFW_MIXIMAX_ITEM_ALLOWED"), skill, chara)
    if okr and type(restricted) == "boolean" then
      return restricted == false
    end
    local okp, param = pcall(funcLuaCommand, M.CHARA_PARAM, chara, 4)
    if not okp or type(param) ~= "number" or param == 0 then
      return false
    end
    local okv, has, own = pcall(funcLuaCommand, M.PAIR_ROW, skill, param)
    return not (okv and has == true and own ~= nil and own ~= 0 and own ~= skill)
  end

  function M.fusion_card(skill, chara)
    if type(skill) ~= "number" or skill == 0 or type(chara) ~= "number" or chara == 0 then
      return nil
    end
    if not M.is_carrier(skill, chara) then
      return nil
    end
    local partner, move = ask_fusion(chara)
    if type(partner) ~= "number" or partner == 0 then
      return nil
    end
    local okk, face = pcall(funcLuaCommand, M.FACE_KEY, partner)
    if not okk or type(face) ~= "number" or face == 0 then
      return nil
    end
    return {partner = partner, move = type(move) == "number" and move or 0, face = face}
  end

  if M.retail.UpdateMixiMaxDetailInfo == nil then
    M.retail.UpdateMixiMaxDetailInfo = UpdateMixiMaxDetailInfo
  end
  if M.retail.UpdateMixiMaxDetailInfo ~= nil then
    function UpdateMixiMaxDetailInfo(layer, skill, chara, ...)
      local okf, f = pcall(M.fusion_card, skill, chara)
      if not okf or f == nil then
        return M.retail.UpdateMixiMaxDetailInfo(layer, skill, chara, ...)
      end
      pcall(funcLuaCommand, CALC_CRC("CMND_VRFW_APPEARANCE"), "skill_panel", f.face)
      local shown = hex(chara) .. ":" .. hex(skill) .. ":" .. hex(f.partner) .. ":" .. hex(f.move)
      if M.card ~= shown then
        M.card = shown
        M.log("mix card", hex(chara), hex(skill), "partner", hex(f.partner), "move", hex(f.move))
      end
      -- Lets retail draw the card.
      return M.with_answers(function(real, cmd, a1, a2, ...)
        if a1 ~= skill then
          return nil
        end
        if cmd == M.PAIR_ROW then
          -- Returns no pair row for the carrier itself.
          return table.pack(false)
        end
        if cmd ~= M.SKILL_INFO then
          return nil
        end
        if a2 == 19 then
          return table.pack(true, f.partner)
        elseif a2 == 17 then
          return table.pack(true, f.face)
        elseif a2 == 16 and f.move ~= 0 then
          return table.pack(true, f.move)
        end
        return nil
      end, M.retail.UpdateMixiMaxDetailInfo, layer, skill, chara, ...)
    end
  end
end
