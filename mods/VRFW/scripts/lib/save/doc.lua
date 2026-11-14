-- Save documents: a text kept per save slot (or "global"), with backups. Call: in a handler (not while the script loads).
--- Library: save slot text documents and their stores.

local Doc = {}

local stores = {}

--- Internal: True when the save slots are ready.
function Doc.ready()
  local ok, r = pcall(VRFW.slots.ready)
  return ok and r == true
end

--- VRFW.save.doc.slot(): the active save slot (1 when none). Call: in a handler (not while the script loads).
function Doc.slot()
  local ok, s = pcall(VRFW.slots.active)
  s = ok and tonumber(s) or nil
  if not s or s == 0 then return 1 end
  return s
end

--- VRFW.save.doc.read_text(name[, scope]): the text kept under `name` (scope: a slot or "global"). Returns the text, nil when none, or nil and the error. Call: in a handler (not while the script loads).
function Doc.read_text(name, scope)
  local ok, text, why = pcall(VRFW.save.blob, name, scope)
  if not ok then return nil, tostring(text) end
  return text, why
end

--- VRFW.save.doc.write_text(name, text[, scope]): keeps text under `name`. Returns true and where it went, or false and the error. Needs the `save` permission. Call: in a handler (not while the script loads).
function Doc.write_text(name, text, scope)
  local ok, written, where = pcall(VRFW.save.blob_write, name, text, scope)
  if not ok then return false, tostring(written) end
  return written and true or false, where
end

--- VRFW.save.doc.set_aside(name[, scope]): takes a document and its backups out of use. Returns true, or false and the error. Call: in a handler (not while the script loads).
function Doc.set_aside(name, scope)
  local ok, done, where = pcall(VRFW.save.blob_aside, name, scope)
  if not ok then return false, tostring(done) end
  return done == true, where
end

local Store = {}
Store.__index = Store

local function scope_of(self, slot)
  if self.global then return "global" end
  return slot
end

--- Logs an error with the tag of this store.
function Store:log_error(...)
  VRFW.error(self.tag .. ":", ...)
end

--- Logs a warning with the tag of this store.
function Store:log_warn(...)
  VRFW.warn(self.tag .. ":", ...)
end

--- A new document for `slot`.
function Store:new_doc(slot)
  if self.opts.default then return self.opts.default(slot) end
  return { version = self.opts.version }
end

--- Sets the file aside and logs `why`; answers where it went, or why it stayed.
function Store:aside(why, slot)
  local _, note = Doc.set_aside(self.name, scope_of(self, slot))
  self:log_error(string.format("%s%s: %s; set aside: %s", self.global and "" or ("slot " .. tostring(slot) .. ": "),
    self.name, tostring(why), tostring(note)))
  return note
end

--- unusable: set aside (or left there with aside = false), a new document
function Store:reject(why, slot)
  if self.opts.aside == false then
    self:log_warn(string.format("%s%s: %s; left as it is, a new document used", self.global and "" or ("slot " .. tostring(slot) .. ": "),
      self.name, tostring(why)))
  else
    self:aside(why, slot)
  end
  return self:new_doc(slot), "bad"
end

--- Reads the document of `slot`: document, "ok" / "new" / "migrated" / "bad".
function Store:load(slot)
  if not self.global then slot = slot or Doc.slot() end
  local ok, text, why = pcall(VRFW.save.blob, self.name, scope_of(self, slot))
  if not ok then return self:reject(text, slot) end
  if text == nil and why ~= nil then return self:reject(why, slot) end
  if text == nil or text == "" then return self:new_doc(slot), "new" end
  if self.opts.text then
    local okd, d, derr = pcall(self.opts.decode, text, slot)
    if not okd then return self:reject(d, slot) end
    if d == nil then return self:reject(derr or "unusable", slot) end
    return d, "ok"
  end
  local okj, j, jerr = pcall(VRFW.json.decode, text)
  if not okj then return self:reject(j, slot) end
  if type(j) ~= "table" then return self:reject(j == nil and ("bad JSON: " .. tostring(jerr)) or "not an object", slot) end
  local state = "ok"
  local want = self.opts.version
  if want ~= nil and tonumber(j.version) ~= want then
    if not self.opts.migrate then return self:reject("version " .. tostring(j.version) .. " (expected " .. tostring(want) .. ")", slot) end
    local okm, m, merr = pcall(self.opts.migrate, j, slot)
    if not okm then return self:reject(m, slot) end
    if type(m) ~= "table" then return self:reject(merr or ("version " .. tostring(j.version) .. " cannot be migrated"), slot) end
    j, state = m, "migrated"
  end
  if self.opts.decode then
    local okd, d, derr = pcall(self.opts.decode, j, slot)
    if not okd then return self:reject(d, slot) end
    if d == nil then return self:reject(derr or "unusable", slot) end
    j = d
  end
  return j, state
end

--- The text form of `doc`.
function Store:text_of(doc, slot)
  local v = doc
  if self.opts.encode then v = self.opts.encode(doc, slot) end
  if type(v) == "string" then return v end
  return VRFW.json.encode(v, self.opts.pretty == true)
end

--- Writes `doc` to `slot` (staged unless `now`): true, where, staged; false, why.
function Store:write(doc, slot, now)
  if not self.global then slot = slot or Doc.slot() end
  -- the locked slot is the untouched original save: its mod data stays in memory, nothing goes to disk
  if not self.global and slot ~= nil then
    local okl, locked = pcall(VRFW.slots.locked)
    if okl and locked == slot then return true, "slot " .. tostring(slot) .. " is locked", false end
  end
  local ok, text = pcall(self.text_of, self, doc, slot)
  if not ok then return false, "cannot encode: " .. tostring(text) end
  if self.opts.stage and not now and not self.global and Doc.ready() then
    local oks, staged, where = pcall(VRFW.save.blob_stage, self.name, text, slot)
    if oks and staged then return true, where, true end
    self:log_warn("stage failed (" .. tostring(oks and where or staged) .. "): written now")
  end
  local okw, written, where = pcall(VRFW.save.blob_write, self.name, text, scope_of(self, slot))
  if not okw then return false, tostring(written) end
  return written == true, where, false
end

local event_seen = nil

local function check_events()
  local ok, seq = pcall(VRFW.slots.event_seq)
  if not ok or type(seq) ~= "number" then return end
  if event_seen == nil or seq == event_seen then
    event_seen = seq
    return
  end
  for n = math.max(event_seen + 1, seq - 63), seq do
    local okk, kind, a, b = pcall(VRFW.slots.event, n)
    local slot = nil
    if okk and (kind == "switched" or kind == "deleted" or kind == "new_game" or kind == "reset") then slot = a end
    if okk and kind == "copied" then slot = b end
    if slot ~= nil then
      for _, s in ipairs(stores) do
        if not s.global and s.key == slot then s:forget() end
      end
    end
  end
  event_seen = seq
end

--- The document of `slot`, read once: document, key.
function Store:get(slot)
  if not self.global then check_events() end
  local key = self.global and "global" or (slot or Doc.slot())
  if self.doc ~= nil and self.key == key then return self.doc, key end
  local doc, state = self:load(key ~= "global" and key or nil)
  self.doc, self.key, self.state = doc, key, state
  if self.opts.loaded then self.opts.loaded(doc, key, state) end
  return doc, key
end

--- Keeps `doc` as the document of `slot` and writes it.
function Store:put(doc, slot, now)
  local key = self.global and "global" or (slot or Doc.slot())
  self.doc, self.key = doc, key
  return self:write(doc, key ~= "global" and key or nil, now)
end

--- Drops the kept document.
function Store:forget()
  self.doc, self.key, self.state = nil, nil, nil
end

--- VRFW.save.doc.new(name, opts): a store for document `name`; opts gives its version, codec and scope. Call: at load or in a handler.
function Doc.new(name, opts)
  opts = opts or {}
  local self = setmetatable({ name = name, opts = opts, global = opts.scope == "global", tag = opts.log or name }, Store)
  stores[#stores + 1] = self
  return self
end

-- a slot the game loads from its file: the cached documents are read again (writes staged and not saved are gone)
local function forget_slot_documents()
  for _, s in ipairs(stores) do
    if not s.global then s:forget() end
  end
  return nil
end

pcall(VRFW.on, "save:slot_load", function(ev)
  if ev and ev.after_load then return nil end
  return forget_slot_documents()
end)

-- a game reset discards what was staged and not saved
pcall(VRFW.on, "game:reset", forget_slot_documents)

return Doc
