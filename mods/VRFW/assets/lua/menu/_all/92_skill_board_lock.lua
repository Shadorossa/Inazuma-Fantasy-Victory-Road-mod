-- lua_patch.scope: used
-- menu_engine: the skill board lock, VRFW.skill_board_lock.
if VRFW.skill_board_lock == nil then
  local K = {
    LOCK = VRFW.commands.VRFW_SKILL_BOARD_LOCK,   -- CMND_VRFW_SKILL_BOARD_LOCK () -> locked, text id, dock only
    LOG = VRFW.commands.VRFW_LOG,                   -- CMND_VRFW_LOG
    SOUND = 1917805374,                       -- play a system sound effect
    SE_NO = 2086672038,                       -- sy0003 (the retail "cannot" sound)
    GUIDE_COLUMNS = 2209673388,
    GREY = 0.5,                               -- the retail "not available" row factor
  }
  local Lock = { is_locked = false, text = 0 }
  --- Advanced: Lock state of the skill board with its message text.
  VRFW.skill_board_lock = Lock

  --- Advanced: Reads the skill-board lock; answers locked, text.
  function Lock.read()
    local ok, locked, text, dock_only = pcall(funcLuaCommand, K.LOCK)
    locked = ok and locked == true
    if locked and dock_only == true then
      local okf, foreign = pcall(function() return VRFW.team_editor ~= nil and VRFW.team_editor.foreign() end)
      locked = okf and foreign ~= nil and foreign ~= false
    end
    local was = Lock.is_locked
    Lock.is_locked, Lock.text = locked, locked and (tonumber(text) or 0) or 0
    if locked ~= was then
      pcall(funcLuaCommand, K.LOG, "VRFW skill board lock", locked and "on" or "off")
    end
    return Lock.is_locked, Lock.text
  end

  --- Internal: The last read lock: locked, text.
  function Lock.locked()
    return Lock.is_locked, Lock.text
  end

  --- Internal: Plays the refused sound.
  function Lock.refuse()
    pcall(funcLuaCommand, K.SOUND, K.SE_NO)
  end

  local function lock_guide_text(enter_text)
    return function(nxt, cmd, menu, guide, texts, ...)
      if Lock.is_locked and Lock.text ~= 0 and type(texts) == "table" then
        local copy = {}
        for i, t in ipairs(texts) do
          copy[i] = t == enter_text and Lock.text or t
        end
        texts = copy
      end
      return nxt(cmd, menu, guide, texts, ...)
    end
  end

  --- Advanced: Guards a list's actions while the skill board is locked.
  function Lock.guard_list(spec)
    spec = type(spec) == "table" and spec or {}
    local mine = {}
    local function wrap(name, make)
      local cur = _ENV[name]
      if type(cur) ~= "function" or cur == mine[name] then
        return
      end
      mine[name] = make(cur)
      _ENV[name] = mine[name]
    end
    local function on_list(a1)
      return Lock.is_locked and (a1 == spec.list_layer or a1 == spec.item_layer)
    end
    local function wrap_all()
      wrap("OnEnter", function(previous)
        return function(a1, ...)
          if on_list(a1) then
            Lock.refuse()
            return
          end
          return previous(a1, ...)
        end
      end)
      wrap("OnDecideFocus", function(previous)
        return function(a1, ...)
          if on_list(a1) then
            Lock.refuse()
            return
          end
          return previous(a1, ...)
        end
      end)
      wrap("UpdateListItem", function(previous)
        return function(a1, a2, ...)
          local r = table.pack(previous(a1, a2, ...))
          if Lock.is_locked and a1 == spec.item_layer and type(SetupGrayout) == "function" then
            pcall(SetupGrayout, a1, a2, K.GREY)
          end
          return table.unpack(r, 1, r.n)
        end
      end)
      if spec.enter_text ~= nil and type(VRFW.host) == "table" and type(VRFW.host.with_commands) == "function" then
        local guide_text = lock_guide_text(spec.enter_text)
        wrap("UpdateButtonGuide", function(previous)
          return function(...)
            if not Lock.is_locked then
              return previous(...)
            end
            return VRFW.host.with_commands({ menu = { [K.GUIDE_COLUMNS] = guide_text } }, previous, ...)
          end
        end)
      end
    end
    local previous_init = _ENV.OnInit
    if type(previous_init) ~= "function" then
      return false
    end
    _ENV.OnInit = function(...)
      Lock.read()
      wrap_all()
      return previous_init(...)
    end
    return true
  end
end
