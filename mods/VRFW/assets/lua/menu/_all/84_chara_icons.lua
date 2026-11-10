-- lua_patch.scope: used
if VRFW.chara_icons == nil then
  local I = {
    CHARA_INFO = 4060384944,     -- CMND_GET_CHARA_INFO (card, field) -> ok, value
    LANG = 477234096,            -- CMND_GET_LANGUAGE_CODE -> the game's language table index
    LOG = VRFW.commands.VRFW_LOG,
    -- the game's language table index -> its folder of the per-language menu atlases
    LANG_DIR = {[0] = "ja", [1] = "en", [2] = "fr", [3] = "es", [4] = "pt", [6] = "de", [7] = "it", [16] = "zh_hant",
      [17] = "zh_hans"},
    POSITION_TEX = "#/menu/200_icon/15_icon_common2/%s/icon_common2.g4tx",
    POSITION_SPRITE = "icon_position0%d",
    ELEMENT_TEX = "#/menu/200_icon/15_icon_common/icon_common.g4tx",
    ELEMENT_SPRITE = "icon_cmd_type0%d",
    ICON_TYPE = {[1] = 0, [2] = 3, [3] = 2, [4] = 1},   -- card position -> position icon type
    positions = {},              -- card -> answer (false = none)
    elements = {},
    lang = nil,
    told = {},                   -- the missing game functions already logged
  }
  VRFW.chara_icons = I

  local function crc(s)
    if type(CRC32) == "function" then
      return CRC32(s)
    end
    return nil
  end

  local function info(card, field)
    local ok, v = VRFW.host.command(I.CHARA_INFO, card, field)
    if ok ~= false and type(v) == "number" then
      return v
    end
    return nil
  end

  local function tell(name)
    if I.told[name] then
      return
    end
    I.told[name] = true
    pcall(funcLuaCommand, I.LOG, "VRFW chara_icons " .. name .. " is not in this menu VM: the atlas sprite is used")
  end

  local function lang_dir()
    if I.lang == nil then
      local ok, code = pcall(funcLuaCommand, I.LANG)
      I.lang = ok and I.LANG_DIR[code] or "en"
      pcall(funcLuaCommand, I.LOG, "VRFW chara_icons language folder " .. I.lang)
    end
    return I.lang
  end

  --- The position icon of `card`; nil when unknown.
  function I.position(card)
    if type(card) ~= "number" or card == 0 then
      return nil
    end
    local v = I.positions[card]
    if v == nil then
      local t = I.ICON_TYPE[info(card, 11)]
      v = false
      if t ~= nil then
        local sprite
        if type(GetSoccerCharaPositionIconByPosIconType) == "function" then
          local ok, s = pcall(GetSoccerCharaPositionIconByPosIconType, t)
          if ok and type(s) == "number" and s ~= 0 then
            sprite = s
          end
        else
          tell("GetSoccerCharaPositionIconByPosIconType")
        end
        sprite = sprite or crc(string.format(I.POSITION_SPRITE, 4 - t))
        if sprite then
          v = {tex = string.format(I.POSITION_TEX, lang_dir()), sprite = sprite}
        end
      end
      I.positions[card] = v
    end
    return v or nil
  end

  --- The element icon of `card`; nil when unknown.
  function I.element(card)
    if type(card) ~= "number" or card == 0 then
      return nil
    end
    local v = I.elements[card]
    if v == nil then
      local el = info(card, 13)
      v = false
      if el ~= nil then
        local sprite
        if type(GetCharaElementIconNameByCharaParamId) == "function" then
          local ok, s = pcall(GetCharaElementIconNameByCharaParamId, card)
          if ok and type(s) == "string" and s ~= "" then
            sprite = crc(s)
          elseif ok and type(s) == "number" and s ~= 0 then
            sprite = s
          end
        else
          tell("GetCharaElementIconNameByCharaParamId")
        end
        if sprite == nil then
          sprite = crc(string.format(I.ELEMENT_SPRITE, (el >= 1 and el <= 4) and el or 0))
        end
        if sprite then
          v = {tex = I.ELEMENT_TEX, sprite = sprite}
        end
      end
      I.elements[card] = v
    end
    return v or nil
  end
end
