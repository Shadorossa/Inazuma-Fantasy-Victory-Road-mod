do
  BetterQoL = BetterQoL or {}
  BetterQoL.passive_config_formation = BetterQoL.passive_config_formation or {}
  BetterQoL.passive_config_formation.CMD_OFF = 3087534512
  BetterQoL.passive_config_formation.GUIDE = 3159119257
  BetterQoL.passive_config_formation.MENU = 2049316981               -- soccer_formation_menu
  BetterQoL.passive_config_formation.wrapped = BetterQoL.passive_config_formation.wrapped or {}

  function BetterQoL.passive_config_formation.off_now()
    local ok, off = pcall(funcLuaCommand, BetterQoL.passive_config_formation.CMD_OFF)
    BetterQoL.passive_config_formation.off = ok and off == true
    return BetterQoL.passive_config_formation.off
  end

  function BetterQoL.passive_config_formation.hide_guide()
    if funcLuaMenuCommand(262659071 --[[CMND_IS_EXIST_LAYER?]], BetterQoL.passive_config_formation.GUIDE) == true
        and funcLuaMenuCommand(2640875187 --[[CMND_IS_OPEN_LAYER]], BetterQoL.passive_config_formation.GUIDE, 0) == true then
      funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], BetterQoL.passive_config_formation.GUIDE, 0, false, BetterQoL.passive_config_formation.MENU)
    end
  end

  function BetterQoL.passive_config_formation.wrap(name, make, create)
    local cur = _ENV[name]
    if BetterQoL.passive_config_formation.wrapped[name] == cur and cur ~= nil then
      return
    end
    if cur == nil and not create then
      return
    end
    local w = make(cur)
    _ENV[name] = w
    BetterQoL.passive_config_formation.wrapped[name] = w
  end

  -- wraps `name` (created when missing) to run fn after the previous definition, keeping its results
  local function After(name, fn)
    BetterQoL.passive_config_formation.wrap(name, function(prev)
      return function(...)
        local r = table.pack(true)
        if prev then
          r = table.pack(prev(...))
        end
        fn()
        if prev then
          return table.unpack(r, 1, r.n)
        end
      end
    end, true)
  end

  After("OnInit", function()
    BetterQoL.passive_config_formation.off_now()
  end)

  After("PostStep", function()
    if BetterQoL.passive_config_formation.off == nil then
      BetterQoL.passive_config_formation.off_now()
    end
    if BetterQoL.passive_config_formation.off then
      pcall(BetterQoL.passive_config_formation.hide_guide)
    end
  end)

  BetterQoL.passive_config_formation.wrap("OpenAndWaitTeamSkillParameterMenu", function(prev)
    return function(...)
      if BetterQoL.passive_config_formation.off_now() then
        return
      end
      return prev(...)
    end
  end)
end
