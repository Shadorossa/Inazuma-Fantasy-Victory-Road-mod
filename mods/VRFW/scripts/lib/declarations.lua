--- Advanced: Library: reads and validates mod declaration files against their schemas.

local M = {}

local Id = VRFW.ids

--- Internal: "0x…" / decimal text / a number -> the id; any other text -> its crc32 (a game key name); rules: Id.parse
function M.id_of(v)
  return Id.parse(v, { hash_names = true })
end

--- Internal: the schema file of a service type (content\types\<type>.toml of the framework mod)
function M.schema(type_name)
  local t, err = VRFW.files.toml("content/types/" .. type_name .. ".toml")
  if type(t) ~= "table" then
    return nil, "content/types/" .. type_name .. ".toml: " .. tostring(err)
  end
  if t.schema ~= "VRFW.decl_schema/1" or type(t.kind) ~= "string" or type(t.folder) ~= "string" or type(t.entry) ~= "table" then
    return nil, "content/types/" .. type_name .. ".toml: not a VRFW.decl_schema/1 file (kind, folder, [entry.<Name>])"
  end
  return t
end

local function is_int(v) return type(v) == "number" and v == math.floor(v) end

local FILE_GATE_KEYS = { if_mod = true, if_not_mod = true }

--- Internal: where an entry is written: { table = "VRFW.X" / "talent" (nil for file_root), single, file_root }
function M.place(schema, entry)
  local spec = schema.entry[entry] or {}
  if spec.file_root == true then return { file_root = true, single = true } end
  local prefix = schema.kind:match("^([^.]+)") or "VRFW"
  local t = type(spec.entry_table) == "string" and spec.entry_table ~= "" and spec.entry_table or (prefix .. "." .. entry)
  return { table = t, single = spec.single == true }
end

-- the value at a dotted path of a file's table
local function value_at(data, path)
  local cur = data
  for part in path:gmatch("[^.]+") do
    if type(cur) ~= "table" then return nil end
    cur = cur[part]
  end
  return cur
end

local COND_KEYS = { config = true, option = true, default = true, equals = true, ["not"] = true, above = true, below = true }

local function check_when(v)
  local list = v
  if type(v) == "table" and (v.config ~= nil or v.option ~= nil) then list = { v } end
  if type(list) ~= "table" then return nil, "a condition { config = \"a.b\" or option = \"<mod>.<row>\", default = …, equals / not / above / below = … } or a list of them" end
  for i, c in ipairs(list) do
    if type(c) ~= "table" then return nil, string.format("condition #%d: not a table", i) end
    local by_config = type(c.config) == "string" and c.config ~= ""
    local by_option = type(c.option) == "string" and c.option ~= ""
    if by_config == by_option then
      return nil, string.format("condition #%d: one of config = \"<dotted path of the mod's config>\" or option = \"<mod>.<row>\" is required", i)
    end
    for k in pairs(c) do
      if not COND_KEYS[k] then return nil, string.format("condition #%d: unknown key `%s` (config, option, default, equals, not, above, below)", i, tostring(k)) end
    end
    if (c.above ~= nil and type(c.above) ~= "number") or (c.below ~= nil and type(c.below) ~= "number") then
      return nil, string.format("condition #%d: above / below take a number", i)
    end
  end
  return list
end

local function is_listed(spec, word)
  if type(spec.values) ~= "table" then return true end
  for _, w in ipairs(spec.values) do
    if w == word then return true end
  end
  return false
end

local function one_of(spec)
  return "one of " .. table.concat(spec.values, ", ")
end

-- one value against its field spec: the value to keep, or nil + why (exported as M.check_value)
-- spec.values: the texts allowed; spec.allow_empty: "" is valid for a text with `values`
local function check_value(spec, v)
  local t = spec.type
  if t == "int" then
    if not is_int(v) then return nil, "a whole number" end
    if (spec.min and v < spec.min) or (spec.max and v > spec.max) then
      return nil, string.format("%s..%s", tostring(spec.min or "-"), tostring(spec.max or "-"))
    end
    return v
  elseif t == "number" then
    if type(v) ~= "number" or v ~= v then return nil, "a number" end
    if (spec.min and v < spec.min) or (spec.max and v > spec.max) then
      return nil, string.format("%s..%s", tostring(spec.min or "-"), tostring(spec.max or "-"))
    end
    return v
  elseif t == "bool" then
    if type(v) ~= "boolean" then return nil, "true / false" end
    return v
  elseif t == "string" then
    if type(v) ~= "string" then return nil, "a text" end
    if not (v == "" and spec.allow_empty) and not is_listed(spec, v) then return nil, one_of(spec) end
    return v
  elseif t == "name" then
    if type(v) ~= "string" or not v:match("^[a-z0-9_]+$") then return nil, "a name (a-z 0-9 _)" end
    if not is_listed(spec, v) then return nil, one_of(spec) end
    return v
  elseif t == "ints" then
    if type(v) ~= "table" then return nil, "a list of whole numbers" end
    local out = {}
    for i, x in ipairs(v) do
      if not is_int(x) or (spec.min and x < spec.min) or (spec.max and x > spec.max) then
        return nil, string.format("item %d: a whole number %s..%s", i, tostring(spec.min or "-"), tostring(spec.max or "-"))
      end
      out[#out + 1] = x
    end
    return out
  elseif t == "numbers" then
    if type(v) ~= "table" then return nil, "a list of numbers" end
    local out = {}
    for i, x in ipairs(v) do
      if type(x) ~= "number" or x ~= x or (spec.min and x < spec.min) or (spec.max and x > spec.max) then
        return nil, string.format("item %d: a number %s..%s", i, tostring(spec.min or "-"), tostring(spec.max or "-"))
      end
      out[#out + 1] = x
    end
    return out
  elseif t == "strings" then
    if type(v) ~= "table" then return nil, "a list of texts" end
    local out = {}
    for i, x in ipairs(v) do
      if type(x) ~= "string" or x == "" or not is_listed(spec, x) then
        return nil, string.format("item %d: %s", i, spec.values and one_of(spec) or "a text")
      end
      out[#out + 1] = x
    end
    return out
  elseif t == "ids" then
    if type(v) ~= "table" then return nil, "a list of names or ids" end
    local out = {}
    for i, x in ipairs(v) do
      local id = M.id_of(x)
      if not id then return nil, string.format("item %d: a name or an id (0x…)", i) end
      out[#out + 1] = id
    end
    return out
  elseif t == "when" then
    return check_when(v)
  elseif t == "table" then
    if type(v) ~= "table" then return nil, "a table { key = value, … }" end
    return v
  elseif t == "lists" then
    if type(v) ~= "table" then return nil, "a list of lists" end
    for i, inner in ipairs(v) do
      if type(inner) ~= "table" then return nil, string.format("item %d: a list of whole numbers", i) end
      for _, x in ipairs(inner) do
        if not is_int(x) or (spec.min and x < spec.min) or (spec.max and x > spec.max) then return nil, string.format("item %d: a list of whole numbers", i) end
      end
    end
    return v
  elseif t == "records" then
    if type(v) ~= "table" then return nil, "a list of tables" end
    for i, rec in ipairs(v) do
      if type(rec) ~= "table" then return nil, string.format("item %d: a table", i) end
      if type(spec.fields) == "table" then
        for k, x in pairs(rec) do
          local fs = spec.fields[k]
          if type(fs) ~= "table" then return nil, string.format("item %d: unknown key `%s`", i, tostring(k)) end
          local ok, why = check_value(fs, x)
          if ok == nil then return nil, string.format("item %d: %s: %s", i, tostring(k), why) end
        end
      end
    end
    return v
  elseif t == "any" then
    return v
  end
  return nil, "the schema's type `" .. tostring(t) .. "` is unknown"
end

-- the current value of a mod option row (`<mod>.<row>`); a key naming a former id falls back to `mod`'s own row
local function option_value(key, mod)
  local ok, v = pcall(VRFW.option, key)
  if (not ok or v == nil) and mod ~= nil then
    ok, v = pcall(VRFW.option, tostring(mod) .. "." .. (key:match("([^.]+)$") or key))
  end
  if not ok then return nil end
  return v
end

--- Internal: True when `mod` meets `conds`.
function M.holds(mod, conds)
  for _, c in ipairs(conds or {}) do
    local v
    if c.option ~= nil then
      v = option_value(c.option, mod)
    else
      local ok, value = pcall(VRFW.files.config, c.config, mod)
      if ok then v = value end
    end
    if v == nil then v = c.default end
    if c.equals ~= nil then
      if v ~= c.equals then return false end
    elseif c["not"] ~= nil then
      if v == c["not"] then return false end
    elseif c.above ~= nil or c.below ~= nil then
      local n = tonumber(v)
      if not n then return false end
      if c.above ~= nil and not (n > c.above) then return false end
      if c.below ~= nil and not (n < c.below) then return false end
    elseif v == nil or v == false or v == 0 then
      return false
    end
  end
  return true
end

--- Internal: Every declaration of `schema` from the active mods.
function M.load(schema, warn)
  local out, skipped = {}, 0
  local ok, files = pcall(VRFW.files.declarations, schema.folder)
  if not ok or type(files) ~= "table" then return out, skipped end
  for _, f in ipairs(files) do
    local data = f.data or {}
    local where = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    if data.schema ~= nil and data.schema ~= schema.kind then
      warn(string.format("%s: schema %q is not %s: file left out", where, tostring(data.schema), schema.kind))
    else
      -- the file's top-level keys the entries' tables use; the rest belong to a file_root entry, else are unknown
      local heads, root_entry = {}, nil
      for entry in pairs(schema.entry) do
        local pl = M.place(schema, entry)
        if pl.file_root then root_entry = entry else heads[pl.table:match("^([^.]+)")] = true end
      end
      local root = {}
      for k, x in pairs(data) do
        if k ~= "schema" and not FILE_GATE_KEYS[k] and not heads[k] then
          if root_entry then root[k] = x else warn(string.format("%s: unknown key `%s` (only schema, if_mod, if_not_mod and the entries' tables)", where, tostring(k))) end
        end
      end
      for entry, spec in pairs(schema.entry) do
        local pl = M.place(schema, entry)
        local arr
        if pl.file_root then
          if next(root) ~= nil then arr = { root } end
        else
          local got = value_at(data, pl.table)
          if got ~= nil then
            if type(got) ~= "table" then
              warn(string.format("%s: %s is not a table: left out", where, pl.table))
            elseif pl.single then
              arr = { got }
            else
              arr = got
            end
          end
        end
        if type(arr) == "table" then
          for i, raw in ipairs(arr) do
            local w = pl.file_root and (where .. ": file") or pl.single and string.format("%s: [%s]", where, pl.table) or string.format("%s: [[%s]] #%d", where, pl.table, i)
            local v, given, bad = {}, {}, nil
            for k, x in pairs(raw) do
              local fs = spec[k]
              if type(fs) ~= "table" then
                bad = "unknown key `" .. tostring(k) .. "`"
                break
              end
              local val, why = check_value(fs, x)
              if val == nil then
                bad = string.format("%s: %s", tostring(k), why)
                break
              end
              v[k], given[k] = val, true
            end
            if not bad then
              for k, fs in pairs(spec) do
                if type(fs) == "table" and v[k] == nil then
                  if fs.required then
                    bad = tostring(k) .. " is required"
                    break
                  end
                  v[k] = fs.default
                end
              end
            end
            if bad then
              warn(w .. ": " .. bad .. ": left out")
            elseif v.when and not M.holds(f.mod, v.when) then
              skipped = skipped + 1
            else
              out[#out + 1] = { mod = f.mod, file = f.file, entry = entry, index = i, where = w, v = v, given = given,
                key = v.name and (tostring(f.mod) .. "." .. v.name) or nil }
            end
          end
        end
      end
      -- a table that only holds entry lists (`VRFW` of [[VRFW.X]]): another list below it is no declaration of this kind
      local prefix = schema.kind:match("^([^.]+)") or "VRFW"
      if type(data[prefix]) == "table" and not schema.entry[prefix] then
        for entry in pairs(data[prefix]) do
          local known = false
          for e in pairs(schema.entry) do
            local pl = M.place(schema, e)
            if pl.table == prefix .. "." .. tostring(entry) then known = true break end
          end
          if not known then warn(string.format("%s: [[%s.%s]] is not a declaration of %s: left out", where, prefix, tostring(entry), schema.kind)) end
        end
      end
    end
  end
  -- (the kinds of one file come in no fixed order; each kind keeps load order, file order and declaration order)
  return out, skipped
end

--- Advanced: Checks one value against a field spec; answers the value to keep, or nil and the reason.
M.check_value = check_value

return M
