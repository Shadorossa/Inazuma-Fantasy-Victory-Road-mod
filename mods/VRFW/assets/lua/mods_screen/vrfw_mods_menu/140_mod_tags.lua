-- mods_menu (VRFW): the "Mods" screen, the mod tags the mods declare and the keys of a list page (PageKey).
local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Call, Draw, FN, G, Int = Screen.C, Screen.CE, Screen.call, Screen.draw, Screen.FN, Screen.G, Screen.int
local M, SE_MOVE, SE_NG, Str, Text = Screen.M, Screen.SE_MOVE, Screen.SE_NG, Screen.str, Screen.text
local TextIdKey, mouse, ui = Screen.text_id_key, Screen.mouse, Screen.ui

-- the lines of a "\n"-joined answer
function CE.lines(s)
  local out = {}
  for l in string.gmatch(s or "", "[^\n]+") do
    out[#out + 1] = l
  end
  return out
end

-- {defs in order}, {id -> def}; def = {id, text}
function CE.read_tag_defs()
  local text_ids = Screen.text_ids()
  if CE.tag_src ~= text_ids then
    CE.tag_src, CE.tag_defs, CE.tag_by = text_ids, {}, {}
    for i = 0, Int(Call(M.TAG_DEFS)) - 1 do
      local id, text = Call(M.TAG_DEF, i)
      if Str(id) ~= "" then
        local t = {id = Str(id), text = Str(text)}
        CE.tag_defs[#CE.tag_defs + 1] = t
        CE.tag_by[t.id] = t
      end
    end
  end
  return CE.tag_defs, CE.tag_by
end

-- a text key of a mod's text rows in the game's language (menu_text), "" when the game has none
function CE.key_text(key)
  local id = (key or "") ~= "" and TextIdKey(key) or nil
  return id ~= nil and Str(Call(C.TEXT_GET, id)) or ""
end

-- a tag's label in the game's language (its text key in menu_text), else its id
function CE.tag_label(t)
  if t.label == nil then
    local s = CE.key_text(t.text)
    t.label = s ~= "" and s or t.id
  end
  return t.label
end

-- "Tags" of a mod: the tags of its mod.toml (`tags`) and its mod tags (CMND_VRFW_MM_MOD_TAGS), in words
function CE.mod_tags(m)
  if m.tag_list == nil then
    local out = CE.lines(Text(m, 8))
    local _, by = CE.read_tag_defs()
    for _, id in ipairs(CE.lines(Str(Call(M.MOD_TAGS, m.id)))) do
      if by[id] ~= nil then
        out[#out + 1] = CE.tag_label(by[id])
      end
    end
    m.tag_list = out
  end
  return m.tag_list
end

-- the scrollbar held by the mouse: its page follows the pointer's y (DrawScrollbar's `set`)
function CE.drag_to(y)
  local d = mouse.drag
  if d == nil or type(y) ~= "number" then
    return
  end
  local f = math.max(0, math.min(1, (y - d.y0 - d.th / 2) / math.max(1, d.h - d.th)))
  d.set(math.floor(f * d.n + 0.5))
  Draw()
end

-- keys inside a list page
local function PageKey(id)
  local p = ui.page
  if (id == FN.UP or id == FN.DOWN) and p.zone == "list" then
    -- rows marked `head` (group titles) are skipped
    local d = id == FN.UP and -1 or 1
    local n = p.sel + d
    while p.items[n] ~= nil and p.items[n].head do
      n = n + d
    end
    if p.items[n] ~= nil then
      p.sel = n
      funcLuaCommand(C.SE, SE_MOVE)
      Draw()
      return true
    end
    if id == FN.DOWN or p.search == nil then
      funcLuaCommand(C.SE, SE_NG)
      return true
    end
  end
  if id == FN.UP then
    if p.zone == "list" and p.sel <= 1 and p.search ~= nil then
      p.zone = "search"
    elseif p.zone == "list" then
      p.sel = math.max(1, p.sel - 1)
    end
  elseif id == FN.DOWN then
    if p.zone == "search" then
      p.zone = "list"
    else
      p.sel = math.min(#p.items, p.sel + 1)
    end
  elseif id == FN.LEFT then
    p.sel = math.max(1, p.sel - G.LIST_ROWS)
  elseif id == FN.RIGHT then
    p.sel = math.min(#p.items, p.sel + G.LIST_ROWS)
  elseif id == FN.SEARCH and p.search ~= nil then
    p.act = "search"
  else
    return false
  end
  funcLuaCommand(C.SE, SE_MOVE)
  Draw()
  return true
end

-- for 100_mods_screen.lua and the files after this one
Screen.page_key = PageKey
