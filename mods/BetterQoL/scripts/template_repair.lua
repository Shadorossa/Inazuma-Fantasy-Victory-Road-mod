-- Exports for save repair tools: the members of the stored templates of a slot, and a repair of their member handles.
local S = require "lib/template_store"
local B = VRFW.bytes

local BLOB = "team_templates.bin"

local function read(slot)
  local ok, data, why = pcall(VRFW.save.get_blob, slot, BLOB)
  if not ok then return nil, tostring(data) end
  if data == nil then
    if why then return nil, tostring(why) end
    return false
  end
  local st, bad = S.decode(data)
  if not st then return nil, BLOB .. " of slot " .. slot .. ": " .. tostring(bad) end
  return st
end

-- (slot) -> every member handle of the slot's stored templates, once each
function BetterQoL.TeamTemplatesMembers(slot)
  local st, why = read(slot)
  if st == nil then return nil, why end
  local out, seen = {}, {}
  if not st then return out end
  for _, tpl in ipairs(st.templates) do
    if tpl.content == "stored" then
      local w = B.read_words(tpl.set, 0, S.WPD)
      for t = 0, S.TEAMS - 1 do
        for k = 0, S.MEMBERS - 1 do
          local h = S.member_handle(w, 0, t, k)
          if h ~= 0 and not seen[h] then
            seen[h] = true
            out[#out + 1] = h
          end
        end
      end
    end
  end
  return out
end

local function docks_fp(sets)
  local p = {}
  for l = S.FIRST_DOCK, S.LAST_DOCK do
    local ph = VRFW.squads.physical_index(l)
    if ph == nil then return nil end
    local s = sets[ph] or sets[tostring(ph)]
    if type(s) ~= "string" then return nil end
    p[#p + 1] = B.from_hex_text(s)
  end
  return S.crc32(table.concat(p))
end

-- (slot, plan) -> what changed: released handles of the stored templates move to their kept card or are emptied
function BetterQoL.TeamTemplatesRepair(slot, plan)
  local st, why = read(slot)
  if st == nil then return nil, why end
  local res = { moved = 0, cleared = 0, changed = false, lines = {} }
  if not st then return res end
  local released, by_dup = {}, {}
  for _, h in ipairs(plan.released or {}) do released[h] = true end
  for _, m in ipairs(plan.merges or {}) do by_dup[m.dup] = m end
  for n, tpl in ipairs(st.templates) do
    if tpl.content == "stored" then
      local w = B.read_words(tpl.set, 0, S.WPD)
      local idents = B.read_words(tpl.idents, 0, S.IDENT_LEN / 4)
      local touched = false
      for t = 0, S.TEAMS - 1 do
        local present = {}
        for k = 0, S.MEMBERS - 1 do
          local h = S.member_handle(w, 0, t, k)
          if h ~= 0 and not released[h] then present[h] = true end
        end
        for k = 0, S.MEMBERS - 1 do
          local h = S.member_handle(w, 0, t, k)
          if h ~= 0 and released[h] then
            touched = true
            local id = t * S.MEMBERS + k
            local m = by_dup[h]
            if m and not present[m.kept] then
              present[m.kept] = true
              w[S.wi(0, S.member_off(t, k))] = m.kept
              if S.replace_team_field(w, 0, t, h, m.kept) then
                S.replace_team_field(w, 0, t, m.dup_param, m.kept_param)
              end
              idents[id * 2 + 1], idents[id * 2 + 2] = m.kept_param, m.kept_order
              res.moved = res.moved + 1
              res.lines[#res.lines + 1] = string.format("template %d team %d slot %d: 0x%08X -> kept 0x%08X", n, t, k, h, m.kept)
            else
              S.clear_member(w, 0, t, k)
              idents[id * 2 + 1], idents[id * 2 + 2] = 0, 0
              res.cleared = res.cleared + 1
              res.lines[#res.lines + 1] = string.format("template %d team %d slot %d: 0x%08X emptied%s", n, t, k, h,
                m and " (the kept card is already in that team)" or " (retail special card)")
            end
          end
        end
      end
      if touched then
        S.recount(w, 0)
        tpl.set = B.text_of_words(w)
        tpl.idents = B.text_of_words(idents)
      end
    end
  end
  res.changed = res.moved + res.cleared > 0
  if plan.docks_before and plan.docks_after then
    local was, now = docks_fp(plan.docks_before), docks_fp(plan.docks_after)
    if was and now and was ~= now and st.fingerprint == was then
      res.fp_was, res.fp_now = st.fingerprint, now
      st.fingerprint = now
      res.changed = true
    elseif not (was and now) then
      res.lines[#res.lines + 1] = "the docks' fingerprint was not followed (the game's team set table is not readable)"
    end
  end
  if res.changed then
    local ok, okw, where = pcall(VRFW.save.set_blob, slot, BLOB, S.encode(st, st.sha1, st.fingerprint))
    if not ok or not okw then return nil, BLOB .. " of slot " .. slot .. ": not written (" .. tostring(ok and where or okw) .. ")" end
    res.written = tostring(where)
  end
  return res
end
