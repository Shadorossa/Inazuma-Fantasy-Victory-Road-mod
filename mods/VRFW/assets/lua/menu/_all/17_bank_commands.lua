-- lua_patch.scope: used
if VRFW.bank_commands == nil then
  local B = { skill_tables = {}, registered = {} }
  VRFW.bank_commands = B

  --- Sets the skill-table answer of `owner`, replacing its previous one.
  function B.set_skill_table(owner, spec)
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

  --- The first skill table an owner answers; nil when there is none.
  function B.skill_table()
    for _, e in ipairs(B.skill_tables) do
      local s = answer(e.spec)
      if s ~= nil then
        return s
      end
    end
    return nil
  end

  --- Registers a bank rule under `name`.
  function B.add_rule(name, rule)
    B.registered[name] = rule
  end

  --- A copy of the registered bank rules, by name.
  function B.rules()
    local all = {}
    for name, rule in pairs(B.registered) do
      all[name] = rule
    end
    return all
  end
end
