-- While a VRFW.skill_board_lock holds, the skill table opens read-only (param character_reforged_ss_readonly) with the lock's guide text.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.skill_table_lock == nil and type(rawget(_ENV, "OnInit")) == "function" then
  local Lock = {
    KEY_READONLY = 156152477,          -- character_reforged_ss_readonly (the screen reads and clears it at OnInit)
    guide = nil,                       -- the screen's own read-only guide text id
  }
  CharacterReforged.skill_table_lock = Lock

  local function screen_locals()
    local table_host = CharacterReforged.skill_table
    local ok, pl = pcall(function() return table_host ~= nil and table_host.L ~= nil and table_host.L.PL or nil end)
    return ok and type(pl) == "table" and pl or nil
  end

  local previous = OnInit
  function OnInit(...)
    local locked, text = false, 0
    if type(VRFW.skill_board_lock) == "table" then
      locked, text = VRFW.skill_board_lock.read()
    end
    local pl = screen_locals()
    if pl ~= nil then
      Lock.guide = Lock.guide or pl.RO_GUIDE
      pl.RO_GUIDE = (locked and text ~= 0) and text or Lock.guide
      if not locked and not VRFW.param.has(Lock.KEY_READONLY) then
        pl.readonly = false
      end
    end
    if locked then
      VRFW.param.replace(Lock.KEY_READONLY, true, "plain")
    end
    return previous(...)
  end
end
