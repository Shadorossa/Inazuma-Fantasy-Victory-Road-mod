-- lua_patch.scope: used
-- Hero style selector, shared part (the menu VMs that use it): the styles of a card's rarity and the card's current style.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.HeroStyle == nil then
  local S = {
    CMD_RARITY_KEY = 3049791826,      -- CMND_CHARACTERREFORGED_HERO_STYLE_RARITY () -> the rarity key of config.toml [hero_style]
    CMD_REG_FIND = 2175579023,        -- CMND_VRFW_REG_FIND ("rarity", key) -> index in the rarity set (-1)
    CMD_RARITY_OF_CARD = 2739024233,  -- CMND_VRFW_RARITY_OF_CARD (card value, frame) -> index in the rarity set (-1)
    CMD_CHARA_INFO = 1131797651,      -- the game's character status getter (handle, field)
    RARITY_FIELD = 12,                -- its field of the card rarity (the game's avatar rarity window reads it)
    MAX_VALUE = 15,                   -- card rarity values 0..15 (VRFW.rarity/1)
  }
  CharacterReforged.HeroStyle = S

  local logger
  -- Logs through the hero style logger.
  function S.log(...)
    if logger == nil and VRFW ~= nil and VRFW.logger ~= nil then
      logger = VRFW.logger.new("CharacterReforged hero style")
    end
    if logger ~= nil then
      logger(...)
    end
  end

  -- The card values of the configured rarity, ascending (read once per VM; {} = feature off).
  function S.styles()
    if S.cached ~= nil then
      return S.cached
    end
    local out = {}
    local ok, key = pcall(funcLuaCommand, S.CMD_RARITY_KEY)
    if ok and type(key) == "string" and key ~= "" then
      local found, wanted = pcall(funcLuaCommand, S.CMD_REG_FIND, "rarity", key)
      if found and type(wanted) == "number" and wanted >= 0 then
        for value = 0, S.MAX_VALUE do
          local asked, index = pcall(funcLuaCommand, S.CMD_RARITY_OF_CARD, value, 0)
          if asked and index == wanted then
            out[#out + 1] = value
          end
        end
      end
    end
    S.cached = out
    S.log("styles of rarity", tostring(key), "card values", table.concat(out, ","))
    return out
  end

  -- The card rarity of a player handle (-1 when unknown).
  function S.rarity(handle)
    if type(handle) ~= "number" or handle == 0 then
      return -1
    end
    local ok, value = pcall(funcLuaCommand, S.CMD_CHARA_INFO, handle, S.RARITY_FIELD)
    return (ok and type(value) == "number") and value or -1
  end

  -- The 1-based style of a player's card, nil when his card is not one of at least two styles.
  function S.style_of(handle)
    local styles = S.styles()
    if #styles < 2 then
      return nil
    end
    local value = S.rarity(handle)
    for i, style in ipairs(styles) do
      if style == value then
        return i
      end
    end
    return nil
  end
end
