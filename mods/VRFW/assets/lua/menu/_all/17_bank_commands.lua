-- menu_engine: VRFW_BankCommands, what mods declare for the character bank's command popup (docs/framework/
-- bank-commands.md). The mod that draws the popup asks here at call time; other mods declare the skill screen
-- «Tabla de habilidades» opens and the rules that change the popup for one player. Definitions only; no engine call
-- at load.
--   VRFW_BankCommands.SetSkillTable(owner, spec)  spec = {Menu = menu id, Params = "equip" | "board", Clear = {keys}}
--                                                 or a function returning such a table or nil (asked at call time)
--   VRFW_BankCommands.SkillTable()     -> the first declared spec that answers, else nil (the popup's own default)
--   VRFW_BankCommands.AddRule(name, rule)          rule = {Retail = function(h) end, Lock = function(h) end}
--   VRFW_BankCommands.Rules()          -> name -> rule, every declared rule
if VRFW_BankCommands == nil then
  local B = { skill_tables = {}, rules = {} }
  VRFW_BankCommands = B

  function B.SetSkillTable(owner, spec)
    for _, e in ipairs(B.skill_tables) do
      if e.owner == owner then
        e.spec = spec
        return
      end
    end
    B.skill_tables[#B.skill_tables + 1] = { owner = owner, spec = spec }
  end

  local function answer(spec)
    if type(spec) == "function" then
      local ok, r = pcall(spec)
      spec = ok and r or nil
    end
    return type(spec) == "table" and spec or nil
  end

  function B.SkillTable()
    for _, e in ipairs(B.skill_tables) do
      local s = answer(e.spec)
      if s ~= nil then
        return s
      end
    end
    return nil
  end

  function B.AddRule(name, rule)
    B.rules[name] = rule
  end

  function B.Rules()
    local all = {}
    for name, rule in pairs(B.rules) do
      all[name] = rule
    end
    return all
  end
end
