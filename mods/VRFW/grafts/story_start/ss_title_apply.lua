-- ===== EVT story_start apply BEGIN =====
VRFW.story_start = VRFW.story_start or {}
local SS_DATA = nil
local story_start = {
  GET = @crc:CMND_VRFW_STORY_START_GET@, SET = @crc:CMND_VRFW_STORY_START_SET@,                                           -- CMND_VRFW_STORY_START_GET / _SET
  BEGIN = 1747233685, END_ = 3152219982, PHASE = @crc:CMND_VRFW_STORY_SET_PHASE@,
  GET_SLOT = @crc:CMND_VRFW_SLOT_ACTIVE@, BUSY = 1127104486,                   -- CMND_VRFW_LOG, CMND_VRFW_SLOT_ACTIVE / _BUSY
  SET_BIT = @crc:CMND_SET_GLOBAL_BIT_FLAG@, GET_BIT = @crc:CMND_GET_GLOBAL_BIT_FLAG@, SET_BYTE = @crc:CMND_SET_GLOBAL_BYTE_FLAG@,
  HELP_GET = 745587751, HELP_OPEN = 1732256399, HELP_SET = 1970131568,          -- prog_common SetHelpOpenFlg
  QUEST = 4210058210, WORD = 4104840918, TEAM_INFO = 3889634838, TEAM_SET = @crc:CMND_SET_TEAM_SET_INFO@,
  ADD_PARTY = @crc:CMND_ADD_PARTY@, TEMP_CHARA = 2006191428, CLEAR_CAT = 4174939534,
  SCOUT_IDX = 2964628019, SCOUT_JOIN = 3675870860,                             -- (base, 7) -> ok, idx ; (idx, 6)
  GAME_CLEAR = @crc:CMND_SET_SOCCER_GAME_CLEAR_BIT_FLAG@, TROPHY = 4020813944, ITEM_CAN = 765340069, ITEM_ADD = @crc:CMND_ADD_ITEM_ONLY@,
  STORY_END = 823922180, UPDATE_PARTY = 2983896291, AUTO_SAVE = @crc:CMND_SYSTEM_AUTO_SAVE@,
  FLAG_AVATAR = 2113473044, FLAG_STORY_CLEAR = 750283301,
  OWNED = 1052152255,                                                           -- (card, 0) -> ok, n / n: saved copies of that card
}
local story_start_ran = false        -- once per VM (the OnInit chain may be wrapped twice)

local story_start_logger
local function story_start_log(...)
  story_start_logger = story_start_logger or VRFW.logger.new("story_start")
  story_start_logger(...)
end

-- Saved copies of one card (story and normal bank).
local function story_start_card_copies(card)
  local a, b = VRFW.host.command(story_start.OWNED, card, 0)
  local n = type(a) == "number" and a or b
  if type(n) ~= "number" then
    return 0
  end
  return n
end

local function story_start_character_owned(card, granted)
  local character = SS_DATA.CHARACTER_OF[card] or card
  if granted[character] then
    return true, character
  end
  for _, other in ipairs(SS_DATA.CHARACTER_CARDS[character] or {card}) do
    if story_start_card_copies(other) > 0 then
      return true, character
    end
  end
  return false, character
end

-- Calls give() for card unless its character is owned already
local function story_start_grant(card, granted, skipped, give)
  local owned, character = story_start_character_owned(card, granted)
  if owned then
    skipped[#skipped + 1] = string.format("%08X", card)
    return false
  end
  give()
  granted[character] = true
  return true
end

local function story_start_log_skipped(section, skipped)
  if #skipped > 0 then
    story_start_log(section, "skipped", #skipped, "card(s): character already owned", table.concat(skipped, " "))
  end
end

local function story_start_section(name, fn)
  local ok, n = pcall(fn)
  if not ok then
    story_start_log("section FAILED", name, tostring(n))
    return 0
  end
  story_start_log("section", name, tostring(n))
  return n or 0
end

local function story_start_apply()
  local D = SS_DATA
  local F = funcLuaCommand
  local granted = {}                 -- characters given by this apply
  story_start_section("flags", function()
    local n = 0
    for i = 1, #D.BITS - 1 do        -- the last entry (b0:1 story clear) is set at the very end
      F(story_start.SET_BIT, D.BITS[i], true)
      n = n + 1
    end
    for _, h in ipairs(D.BITS_OFF) do
      F(story_start.SET_BIT, h, false)
    end
    for _, b in ipairs(D.BYTES) do
      F(story_start.SET_BYTE, b[1], b[2])
      n = n + 1
    end
    return n
  end)
  story_start_section("help/quests/words", function()
    local n = 0
    for _, h in ipairs(D.HELP) do
      if F(story_start.HELP_GET, h) == false then
        F(story_start.HELP_OPEN, h)
      end
      F(story_start.HELP_SET, h)
      n = n + 1
    end
    for _, q in ipairs(D.QUESTS) do
      F(story_start.QUEST, q[1], q[2])
      n = n + 1
    end
    for _, w in ipairs(D.WORDS) do
      F(story_start.WORD, w)
      n = n + 1
    end
    return n
  end)
  story_start_section("team set + kit", function()
    local n = 0
    for _, t in ipairs(D.TEAM_INFO) do
      F(story_start.TEAM_INFO, t[1], t[2], t[3])
      n = n + 1
    end
    for _, it in ipairs(D.ITEMS) do         -- the story kit (SET_TEAM_SET_INFO kind 5 needs the owned uniform)
      if F(story_start.ITEM_CAN, it[1], it[2]) then
        F(story_start.ITEM_ADD, it[1], it[2])
        n = n + 1
      end
    end
    return n
  end)
  story_start_section("story roster", function()
    local n, skipped = 0, {}
    for _, a in ipairs(D.ADDS) do
      if story_start_grant(a[1], granted, skipped, function()
        F(story_start.ADD_PARTY, a[1], D.LEVEL, a[2], a[3], 0, 0, a[4], a[5], a[6], a[7], a[8], a[9], 0, false, false, a[10], 0, false, a[11])
      end) then
        n = n + 1
      end
    end
    story_start_log_skipped("story roster", skipped)
    return n
  end)
  story_start_section("scouts", function()
    local n, skipped = 0, {}
    for _, s in ipairs(D.SCOUTS) do
      -- The retail join (rpg_select_scout_chara_menu ConfirmCharaExec + the recipe's DbgPhCmd_4_90).
      story_start_grant(s[1], granted, skipped, function()
        local tmp = F(story_start.TEMP_CHARA, s[1], D.LEVEL)
        if type(tmp) ~= "number" then
          tmp = 0
        end
        F(story_start.ADD_PARTY, s[1], D.LEVEL, false, false, 0, tmp, true, false, false, s[4], 255, 255, 0, false, false, false, 2)
        F(story_start.CLEAR_CAT, 8)
      end)
      F(story_start.SET_BIT, s[3], true)
      local ok, idx = F(story_start.SCOUT_IDX, s[2], 7)
      if ok and type(idx) == "number" then
        F(story_start.SCOUT_JOIN, idx, 6)
      end
      n = n + 1
    end
    story_start_log_skipped("scouts", skipped)
    return n
  end)
  story_start_section("team set info", function()
    local n = 0
    for _, t in ipairs(D.TEAM_SET) do
      F(story_start.TEAM_SET, table.unpack(t))
      n = n + 1
    end
    return n
  end)
  story_start_section("normal copies", function()
    local n, skipped = 0, {}
    for _, p in ipairs(D.NORMAL) do
      if story_start_grant(p, granted, skipped, function()
        F(story_start.ADD_PARTY, p, D.NORMAL_LEVEL, false, false, 0, 0, false, false, false, 16, 255, 255, 0, false, false, false, 0, false, false)
      end) then
        n = n + 1
      end
    end
    story_start_log_skipped("normal copies", skipped)
    return n
  end)
  story_start_section("story matches", function()
    for _, g in ipairs(D.GAMES) do
      F(story_start.GAME_CLEAR, g, 1, true)
    end
    return #D.GAMES
  end)
  story_start_section("trophies", function()
    for _, t in ipairs(D.TROPHIES) do
      F(story_start.TROPHY, t[1], t[2], false)
    end
    return #D.TROPHIES
  end)
  story_start_section("story end", function()
    F(story_start.STORY_END)
    F(story_start.UPDATE_PARTY)
    return 2
  end)
  local old, new = VRFW.host.command(story_start.PHASE, D.PHASE[1], D.PHASE[2])
  story_start_log("phase", tostring(old), "->", tostring(new))
  F(story_start.SET_BIT, D.BITS[#D.BITS], true)      -- b0:1 story clear, last
end

function VRFW.story_start.on_title()
  if story_start_ran or rawget(_G, "StartTitleMenu2_Coroutine") == nil then
    return                           -- once per VM; only in title_menu_2 (not the press-start title_menu)
  end
  story_start_ran = true
  local state, phase, _, live = VRFW.host.command(story_start.GET)
  if type(state) ~= "number" then
    return                           -- no save part with the story-complete start
  end
  if state ~= 1 then
    return
  end
  local slot = VRFW.host.command(story_start.GET_SLOT)
  if type(slot) ~= "number" or slot < 1 then
    return
  end
  if VRFW.host.command(story_start.GET_BIT, story_start.FLAG_AVATAR) ~= true then
    story_start_log("pending on slot", slot, "but the avatar is not created yet: later")
    return
  end
  if type(phase) ~= "number" then
    return
  end
  for _ = 1, 3 do                    -- the script answers nothing while another thread runs a script
    SS_DATA = VRFW.story ~= nil and VRFW.story.data() or nil
    if SS_DATA ~= nil then
      break
    end
  end
  if SS_DATA == nil then
    story_start_ran = false             -- the marker stays pending: the next title_menu_2 OnInit tries again
    story_start_log("pending on slot", slot, "but the story data did not answer (CMND_VRFW_STORY_START_DATA): later")
    return
  end
  local target = SS_DATA.PHASE[1] * 10000 + SS_DATA.PHASE[2]
  local clear = VRFW.host.command(story_start.GET_BIT, story_start.FLAG_STORY_CLEAR) == true
  -- The four cases (story_start::title_action).
  local mode
  if not clear and phase == 0 then
    mode = "apply"
  elseif clear and phase == 0 then
    mode = "repair"
  elseif clear and phase == target then
    story_start_log("pending on slot", slot, "already applied in memory (phase", tostring(phase), "live", tostring(live),
                "): waiting for the save")
    if VRFW.host.command(story_start.BUSY) ~= true then
      VRFW.host.command(story_start.AUTO_SAVE)
      story_start_log("autosave requested")
    end
    return
  else
    story_start_log("pending on slot", slot, "but the story phase is", tostring(phase), "clear", tostring(clear),
                ": marker cleared, nothing applied")
    VRFW.host.command(story_start.SET, slot, 0)
    return
  end
  if VRFW.host.command(story_start.BEGIN) ~= true then
    story_start_log("BEGIN refused: nothing applied")
    return
  end
  local ok, err
  if mode == "apply" then
    story_start_log("APPLY slot", slot, "data version", SS_DATA.VERSION, "flags", #SS_DATA.BITS, "roster", #SS_DATA.ADDS + #SS_DATA.SCOUTS,
                "normal", #SS_DATA.NORMAL, "trophies", #SS_DATA.TROPHIES)
    ok, err = pcall(story_start_apply)
  else
    story_start_log("REPAIR slot", slot, ": story clear set but the saved phase is 0 (live", tostring(live),
                "): phase only, nothing else re-applied")
    local old, new = VRFW.host.command(story_start.PHASE, SS_DATA.PHASE[1], SS_DATA.PHASE[2])
    story_start_log("phase", tostring(old), "->", tostring(new))
    ok = new == target
    err = ok and nil or "phase write refused"
  end
  local blocked = VRFW.host.command(story_start.END_)
  story_start_log(mode == "apply" and "APPLY done" or "REPAIR done", ok and "ok" or ("ERROR " .. tostring(err)),
              "Steam requests dropped", tostring(blocked))
  if VRFW.host.command(story_start.BUSY) ~= true then
    VRFW.host.command(story_start.AUTO_SAVE)            -- CMND_SYSTEM_AUTO_SAVE; the marker turns "done" once it is on disk
    story_start_log("autosave requested")
  else
    story_start_log("save job busy: the post-story state is saved with the next autosave")
  end
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
        if (VRFW.save_slots ~= nil and type(VRFW.save_slots.commit_pending) == "function") then
          pcall(VRFW.save_slots.commit_pending)
        end
        pcall(VRFW.story_start.on_title)
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
-- ===== EVT story_start apply END =====
