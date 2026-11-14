-- EVT save slots (appended to title_menu_inc_1.04.32.00 by slot_build.py (old Inazuma Fantasy tool, removed 2026-11-12)).

VRFW.save_slots = VRFW.save_slots or {}
local save_slots_loader = {
  VERSION = @crc:CMND_VRFW_LOADER_VERSION@,
  GET_SLOT = @crc:CMND_VRFW_SLOT_ACTIVE@,        -- () -> active slot
  SLOT_INFO = 1195222835,      -- (n) -> exists, chapter, ...
  COMMIT = 4173545121,       -- () -> bool: fence off, slot remembered
  STATE = 3534676964,         -- () -> 0 idle, 1 switching (fenced), -1 error
  LOG = @crc:CMND_VRFW_LOG@,                  -- (...) -> true: vrfw_loader\loader.log
}
local save_slots_max_slot = 99
VRFW.save_slots_reserved_enter = VRFW.save_slots_reserved_enter or {}
local save_slots_menu = 2103230976
local save_slots_key_result = 2449975398
-- Returns a text.
function VRFW.save_slots.text(key, k)
  if type(VRFW.slots) ~= "table" then
    return "Could not switch to Slot " .. tostring(k) .. "."
  end
  return VRFW.slots.text(key, k)
end
-- retail commands
local VRFW_SS_G = {
  MENU_ACTIVE = 1558704558, FOCUS_ENABLE = @crc:CMND_SET_ENABLE_CTRL_FOCUS@, ANIME = @crc:CMND_PLAY_ANIME_TYPE@,
  OPEN_MENU = @crc:CMND_OPEN_MENU_OBJECT@, EXIST_MENU = @crc:CMND_IS_EXIST_MENU_OBJECT@,
  OPEN_LAYER = @crc:CMND_OPEN_LAYER@, CLOSE_LAYER = @crc:CMND_CLOSE_LAYER@,
}

local function save_slots_call(cmd, ...)
  local r = table.pack(pcall(funcLuaCommand, cmd, ...))
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2, r.n)
end

local function save_slots_log(...)
  save_slots_call(save_slots_loader.LOG, "save_slots", ...)
end

-- loader present, API >= 1, save_slots module enabled
function VRFW.save_slots.available()
  local api, mods = save_slots_call(save_slots_loader.VERSION)
  if type(api) ~= "number" or api < 1 or type(mods) ~= "number" then
    return false
  end
  return math.floor(mods / 2) % 2 == 1
end

-- Returns the layout (k is a player slot, the locked slot) and the reserved slots.
local function save_slots_layout(k)
  if type(VRFW.slots) ~= "table" then
    return k >= 1 and k <= 3, 1
  end
  return VRFW.slots.layout(k)
end

-- Returns whether slot k is a reserved slot of a mod: its owner, whether its mode lets it be entered, and the menu loading it opens as its menu scene's root (nil means its title).
local function save_slots_reserved(k)
  if type(VRFW.slots) ~= "table" then
    return nil, false, nil
  end
  return VRFW.slots.reserved(k)
end

-- After a switch the title is re-entered
function VRFW.save_slots.commit_pending()
  if not VRFW.save_slots.available() then
    return
  end
  if save_slots_call(save_slots_loader.STATE) == 1 then
    local ok = save_slots_call(save_slots_loader.COMMIT)
    save_slots_log("commit", ok == true)
  end
end

-- Switches to slot k (k differs from the active slot) with this title menu closed before the reset and the reserved slot's owner hook; the game resets into the slot's title, or straight into a reserved slot's root menu, and this never returns.
function VRFW.save_slots.switch(k, exists)
  if type(VRFW.slots) ~= "table" then
    save_slots_log("switch", k, "refused: VRFW.slots missing in this VM")
    return false, VRFW.save_slots.text("REFUSED", k)
  end
  return VRFW.slots.load(k, {
    exists = exists,
    close_menu = n,
    on_reserved = function(owner, slot)
      local hook = VRFW.save_slots_reserved_enter[owner]
      if type(hook) == "function" then
        hook(slot)
      end
    end,
    log = save_slots_log,
  })
end

-- Called by the patched StartItemSelectMenuCoroutine (inside that coroutine) after the EMPEZAR OK animation.
function VRFW.save_slots.before_game_start(gamestartLayer)
  if not VRFW.save_slots.available() then
    return true
  end
  local active = save_slots_call(save_slots_loader.GET_SLOT)
  if type(active) ~= "number" or active < 1 or active > save_slots_max_slot then
    return true
  end
  funcLuaMenuCommand(VRFW_SS_G.MENU_ACTIVE, n, false)
  -- Stops the attract and opening timer.
  funcLuaMenuCommand(VRFW_SS_G.CLOSE_LAYER, gamestartLayer)
  local function Reopen()
    funcLuaMenuCommand(VRFW_SS_G.OPEN_LAYER, gamestartLayer)
  end
  VRFW.param.clear(save_slots_key_result)
  funcLuaCommand(VRFW_SS_G.OPEN_MENU, save_slots_menu)
  coroutine.yield()
  while funcLuaMenuCommand(VRFW_SS_G.EXIST_MENU, save_slots_menu) do
    coroutine.yield()
  end
  local r = 0
  if VRFW.param.has(save_slots_key_result) then
    r = VRFW.param.get(save_slots_key_result) or 0
  end
  VRFW.param.clear(save_slots_key_result)
  r = math.floor(tonumber(r) or 0)
  -- The menu may have duplicated into or deleted the active slot.
  local a2 = save_slots_call(save_slots_loader.GET_SLOT)
  if type(a2) == "number" and a2 >= 1 and a2 <= save_slots_max_slot then
    active = a2
  end
  save_slots_log("slot menu result", r, "active", active)
  local isPlayer, locked = save_slots_layout(r)
  if r == locked then
    r = 0            -- the locked slot can never be continued or loaded with the mods
  end
  if r == active then
    Reopen()
    funcLuaMenuCommand(VRFW_SS_G.MENU_ACTIVE, n, true)
    return true
  end
  if r >= 1 and not isPlayer then
    local owner, enterable = save_slots_reserved(r)
    if owner == nil or not enterable then
      save_slots_log("slot menu result", r, "refused: not a reserved slot whose owner's mode is on")
      r = 0
    end
  end
  if r >= 1 and r <= save_slots_max_slot then
    local exists = save_slots_call(save_slots_loader.SLOT_INFO, r) == true
    local ok, why = VRFW.save_slots.switch(r, exists)   -- does not return on success
    if not ok then
      VRFW.question.notice(why)
    end
  end
  -- Reopens on cancel or failure.
  Reopen()
  funcLuaMenuCommand(VRFW_SS_G.MENU_ACTIVE, n, true)
  funcLuaMenuCommand(VRFW_SS_G.ANIME, gamestartLayer, 0, 71445658 --[[Open]], 0, 2675529103 --[[start]])
  funcLuaMenuCommand(VRFW_SS_G.FOCUS_ENABLE, gamestartLayer, true)
  return false
end

do
  local mt = getmetatable(_G)
  if mt == nil then
    mt = {}
    setmetatable(_G, mt)
  end
  local prev = mt.__newindex
  mt.__newindex = function(t, k, v)
    if k == "OnInit" and type(v) == "function" then
      local menuInit = v
      v = function(...)
        pcall(VRFW.save_slots.commit_pending)
        return menuInit(...)
      end
    end
    if prev == nil then
      rawset(t, k, v)
    elseif type(prev) == "function" then
      prev(t, k, v)
    else
      prev[k] = v
    end
  end
end
