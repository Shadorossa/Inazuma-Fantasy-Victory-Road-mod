-- New Recruitment: no spirits to summon. With this
-- mod a player is one card, so a normal spirit is only the player himself: a spirit drop recruits that player straight
-- into the bank, and the spirit «!» notices are gone. Only while
-- ClassicRecruitment.Applies() holds (below: not in a reserved slot, a mode's own save such as INAROGUE's): there
-- everything stays the game's.
-- 1. Notices. Every «!» / egg notice of new spirits asks CMND_GET_SPIRIT_INFO (mode 0 new, 1 egg; the team docks'
--    «Espíritu» row, the spirit screen's era tabs, the main menus' «Equipo» entries and their mods' copies), and the
--    character cards' «new spirit» mark asks CMND_HAS_CHARA_SPIRIT: both answer «nothing new» (funcLuaCommand filtered
--    in every menu VM; every other command goes on as given).
-- 2. The «Espíritu» rows of the team docks stay: that screen turns Ídolo and Diamante cards into players (the Atrio's
--    retail Basara flow, assets\lua\soccer_summon_menu\new_recruitment_summon_special.lua refuses normal cards).
-- 3. A spirit drop = the player. The match result screen (soccer_result_menu_item, UpdateItem with a spirit row) lists
--    the spirits the match gives; the engine adds them to the bag only after that screen. Each spirit of a normal card
--    (spirit rarity 0-4, card type below 5) is kept as PENDING (loader UI flags, persistent: count PENDING_COUNT_KEY,
--    entries PENDING_KEY + 3 i .. + 3 i + 2 = card, rarity, slot; the key names are the ones No More Rarities used, so a
--    pending recruit noted before the split is still made). The first step of a menu of the loaded save outside the
--    match and the story (RECRUIT_MENUS) recruits each pending player of that slot through the VR-Framework's recruit
--    service (VRFW_Recruit.Sign: the game's CMND_ADD_PARTY, the summon screen's arguments) at RecruitRarity(spirit): No
--    More Rarities' normal card rarity when it is on and applies (ClassicCards.NormalCardRarity, 4), else the spirit's
--    own rarity; and takes his spirit back (CMND_ADD_ITEM_SPIRIT -1, only when the bag holds it and nothing else changed
--    the count: -1 on an empty stock wraps to 999), then one autosave. A player already in the club or a full bank: the
--    spirit stays as the game gave it (logged). One log line per recruit («ClassicRecruitment spirit recruit»). Since 1.0.1
--    no player spirit drops in a match at all (the VR-Framework's [VRFW.DropList.Spirits] ExcludeAll,
--    content\items\drop_list.toml), so this step only finishes the recruits noted before; it is kept harmless.
-- When it goes on: the engine registers funcLuaCommand AFTER every patch of the script ran,
--and a later merge-path patch may redefine the script's callbacks after every
-- _all file (in «Plantilla de equipo», soccer_team_dock_menu, Player Training's player_training_dock redefines
-- OnSetupLayer, Step...). So the notice filter is a VR-Framework command hook registered at load (VRFW_Host.HookCommand:
-- in place the moment the engine registers funcLuaCommand, right over the command), and the callback wrappers (the
-- result rows, the recruit step) are taken at the VM's first engine command, when
-- every patch of the script has run and before the first layer is set up.
-- Defines functions and wrappers only; engine calls only inside the game's callbacks; every call goes through pcall.
local RECRUIT_MENUS = {          -- menus of a loaded save where the pending players are recruited (first step)
  "vs_route_town_menu", "chronicle_mode_top_menu", "soccer_top_menu", "soccer_team_dock_menu", "chara_bank_menu",
  "team_dock_menu", "market_menu",
}

ClassicRecruitment = type(ClassicRecruitment) == "table" and ClassicRecruitment or {}

-- ClassicRecruitment.Applies(): whether this module's rules apply to the loaded save: every save but a RESERVED slot (a
-- mode's own save: INAROGUE's, or any mode that reserves one through the VR-Framework's slot service:
-- CMND_VRFW_SLOT_ACTIVE -> CMND_VRFW_SLOT_RESERVED(n) -> reserved). No framework answer = it applies.
if ClassicRecruitment.Applies == nil then
  local SLOT_ACTIVE = 4245285902       -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
  local SLOT_RESERVED = 1380583127     -- CMND_VRFW_SLOT_RESERVED (slot) -> reserved, owner mod, enterable

  function ClassicRecruitment.Applies()
    if type(funcLuaCommand) ~= "function" then
      return true
    end
    local okActive, active = pcall(funcLuaCommand, SLOT_ACTIVE)
    if not okActive or type(active) ~= "number" or active <= 0 then
      return true
    end
    local okReserved, reserved = pcall(funcLuaCommand, SLOT_RESERVED, active)
    return not (okReserved and reserved == true)
  end
end

if ClassicRecruitment.Spirits == nil then
  local S = {}
  ClassicRecruitment.Spirits = S
  local SPIRIT_INFO = 707505551          -- CMND_GET_SPIRIT_INFO (mode, series) -> ok, shown
  local HAS_CHARA_SPIRIT = 3002728759    -- (card) -> a spirit of this player is new
  local LOG = 3661580131                 -- CMND_EVT_LOG
  local CHARA_INFO = 4060384944          -- CMND_GET_CHARA_INFO (card, 8) -> the card type (chara_param col 41)
  local SPIRIT_NUM = 1883729669          -- CMND_GET_SPIRIT_NUM (card, rarity) -> ok, stock
  local ADD_SPIRIT = 2757645277          -- CMND_ADD_ITEM_SPIRIT (card, count, rarity, used)
  local AUTO_SAVE = 3673719958           -- CMND_SYSTEM_AUTO_SAVE
  local FLAG_GET = 100903117             -- CMND_EVT_UI_FLAG_GET (key) -> number
  local FLAG_SET = 489464673             -- CMND_EVT_UI_FLAG_SET (key, value)
  local FLAG_PERSIST = 3323775344        -- CMND_EVT_UI_FLAG_PERSIST (key, value): kept with the save
  local ACTIVE_SLOT = 4245285902         -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
  local IN_STORY = 424926145             -- true while the story's play mode runs (its roster is another bank)
  local LAST_NORMAL_RARITY = 4           -- spirit rarities 0-4: the normal cards
  local FIRST_SPECIAL_CARD_TYPE = 5      -- card types 5-7 Ídolo, 8 Diamante, 9+ season / mods' cards
  local RECRUIT_LEVEL = 1                -- the summon screen's level
  local SCOUTED = 2                      -- CMND_ADD_PARTY source: scouted
  local SPIRIT_STOCK_MAX = 999
  local PENDING_MAX = 64
  local ENTRY_SIZE = 3

  local function Crc(text)
    return VRFW_Id.Crc(text)
  end
  -- the flag keys, at the first use (this lua_early file runs before VRFW_Id exists)
  local function PendingCountKey()
    return Crc("no_more_rarities_spirit_pending_count")
  end
  local function PendingKey()
    return Crc("no_more_rarities_spirit_pending")
  end

  -- the engine command past every command hook (the game's own answers, not this file's notice filter)
  local function EngineCommand(...)
    return VRFW_Host.RealCommand(...)
  end

  local function Log(...)
    pcall(EngineCommand, LOG, "ClassicRecruitment spirit recruit", ...)
  end

  local function RemovalApplies()
    return ClassicRecruitment.Applies()
  end

  -- the rarity a pending spirit's player is recruited at: No More Rarities' normal card rarity while its removal
  -- applies, else the spirit's own rarity
  local function RecruitRarity(spirit_rarity)
    local rarities = rawget(_ENV, "ClassicCards")
    if type(rarities) == "table" and type(rarities.NormalCardRarity) == "function" then
      local ok, rarity = pcall(rarities.NormalCardRarity)
      if ok and type(rarity) == "number" then
        return rarity
      end
    end
    return spirit_rarity
  end

  -- 1. the notices (and the late wrappers, at the VM's first engine command) -----------------------------------------
  -- the VM's first engine command (either one): every patch of the script ran, the callbacks are the final ones
  local LATE_OWNER = "ClassicRecruitment.late_wrappers"
  local function LateOnce()
    if not S.late_done then
      S.late_done = true
      VRFW_Host.UnhookCommand(LATE_OWNER)
      VRFW_Host.UnhookCommand(LATE_OWNER, {menu = true})
      local ok, err = pcall(S.LateWrappers)
      if not ok then
        Log("late wrappers failed:", tostring(err))
      end
    end
  end

  local function NoticeFilter(nxt, ...)
    local id = ...
    if id == SPIRIT_INFO and RemovalApplies() then
      return true, false
    end
    if id == HAS_CHARA_SPIRIT and RemovalApplies() then
      return false
    end
    return nxt(...)
  end

  local function FirstCommand(nxt, ...)
    LateOnce()
    return nxt(...)
  end

  -- 3. a spirit drop = the player ------------------------------------------------------------------------------------
  local function FlagGet(key)
    local ok, value = pcall(EngineCommand, FLAG_GET, key)
    return (ok and type(value) == "number") and value or 0
  end

  local function FlagSet(key, value)
    local ok, done = pcall(EngineCommand, FLAG_PERSIST, key, value)
    if not ok or done == nil then
      pcall(EngineCommand, FLAG_SET, key, value)
    end
  end

  local function EntryKey(i, field)
    return (PendingKey() + ENTRY_SIZE * i + field) % 4294967296
  end

  local function ActiveSlot()
    local ok, slot = pcall(EngineCommand, ACTIVE_SLOT)
    return (ok and type(slot) == "number") and slot or 0
  end

  local function CardType(card)
    local ok, first, second = pcall(EngineCommand, CHARA_INFO, card, 8)
    if not ok or first == false then
      return nil
    end
    if type(second) == "number" then
      return second
    end
    return type(first) == "number" and first or nil
  end

  local function SpiritStock(card, rarity)
    local ok, found, stock = pcall(EngineCommand, SPIRIT_NUM, card, rarity)
    if not ok or found == false or type(stock) ~= "number" then
      return nil
    end
    return stock
  end

  local function ReadPending()
    local entries = {}
    local count = math.min(FlagGet(PendingCountKey()), PENDING_MAX)
    for i = 1, count do
      local card = FlagGet(EntryKey(i, 0))
      if card ~= 0 then
        entries[#entries + 1] = {card = card, rarity = FlagGet(EntryKey(i, 1)), slot = FlagGet(EntryKey(i, 2))}
      end
    end
    return entries, count
  end

  local function WritePending(entries, old_count)
    for i = 1, math.max(old_count, #entries) do
      local e = entries[i]
      FlagSet(EntryKey(i, 0), e and e.card or 0)
      FlagSet(EntryKey(i, 1), e and e.rarity or 0)
      FlagSet(EntryKey(i, 2), e and e.slot or 0)
    end
    FlagSet(PendingCountKey(), #entries)
  end

  -- a spirit row of the result screen: its player kept as pending (once per card, rarity and slot)
  function S.NotePending(card, rarity)
    if type(card) ~= "number" or card == 0 or type(rarity) ~= "number" or rarity < 0 or rarity > LAST_NORMAL_RARITY then
      return
    end
    if not RemovalApplies() then
      return
    end
    local card_type = CardType(card)
    if card_type == nil or card_type >= FIRST_SPECIAL_CARD_TYPE then
      return
    end
    local slot = ActiveSlot()
    local entries, count = ReadPending()
    for _, e in ipairs(entries) do
      if e.card == card and e.rarity == rarity and e.slot == slot then
        return
      end
    end
    if #entries >= PENDING_MAX then
      Log("pending list full: the spirit of card", card, "stays a spirit")
      return
    end
    entries[#entries + 1] = {card = card, rarity = rarity, slot = slot}
    WritePending(entries, count)
    Log("pending", card, "rarity", rarity, "slot", slot)
  end

  -- every pending player of the loaded slot recruited (the others kept); -> how many were recruited
  function S.RecruitPending(where)
    if not RemovalApplies() or type(VRFW_Recruit) ~= "table" or type(VRFW_Recruit.Sign) ~= "function" then
      return 0
    end
    local entries, count = ReadPending()
    if #entries == 0 then
      return 0
    end
    local ok_story, in_story = pcall(EngineCommand, IN_STORY)
    if ok_story and in_story == true then
      return 0                           -- the story's roster is not the bank: kept for a menu outside the story
    end
    local slot = ActiveSlot()
    local kept, recruited = {}, 0
    for _, e in ipairs(entries) do
      if e.slot ~= slot then
        kept[#kept + 1] = e
      else
        local before = SpiritStock(e.card, e.rarity)
        if before == nil or before < 1 then
          Log(where, "card", e.card, "rarity", e.rarity, ": no such spirit in the bag (used or not given): nothing done")
        else
          local rarity = RecruitRarity(e.rarity)
          local hdl, why = VRFW_Recruit.Sign(e.card, RECRUIT_LEVEL, rarity, SCOUTED)
          if hdl == nil then
            Log(where, "card", e.card, ": not recruited (" .. tostring(why) .. "): the spirit stays")
          else
            recruited = recruited + 1
            local now = SpiritStock(e.card, e.rarity)
            local taken = false
            if now == before and now >= 1 and now < SPIRIT_STOCK_MAX then
              pcall(EngineCommand, ADD_SPIRIT, e.card, -1, e.rarity, false)
              taken = SpiritStock(e.card, e.rarity) == before - 1
            end
            Log(where, "card", e.card, "recruited into the bank at rarity", rarity, "handle", hdl,
              taken and "spirit taken back" or ("spirit NOT taken back (stock " .. tostring(before) .. " -> " .. tostring(now) .. ")"))
          end
        end
      end
    end
    WritePending(kept, count)
    if recruited > 0 then
      pcall(EngineCommand, AUTO_SAVE)
    end
    return recruited
  end

  -- the result screen: its spirit rows (UpdateItem(layer, row, focused, count, card, ..., rarity, isSpirit, ...))
  local function ResultRows(retail_item)
    return function(a1, a2, a3, a4, card, a6, rarity, is_spirit, ...)
      if is_spirit == true then
        pcall(S.NotePending, card, rarity)
      end
      return retail_item(a1, a2, a3, a4, card, a6, rarity, is_spirit, ...)
    end
  end

  -- the menus of a loaded save: the pending players on their first step
  local patch = rawget(_ENV, "EVT_PATCH")
  local script = type(patch) == "table" and patch.script or nil
  local stem = type(script) == "string" and script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "") or nil
  local recruits_here = false
  for _, menu in ipairs(RECRUIT_MENUS) do
    recruits_here = recruits_here or menu == stem
  end
  local recruit_done = false
  local function RecruitStep(retail_step)
    return function(...)
      if not recruit_done then
        recruit_done = true
        local ok, err = pcall(S.RecruitPending, stem)
        if not ok then
          Log(stem, "failed:", tostring(err))
        end
      end
      return retail_step(...)
    end
  end

  -- the callback wrappers, on the script's final callbacks (once per function object: a global redefined since is
  -- wrapped again)
  local own_wrappers = {}
  local function WrapGlobal(name, make)
    local current = rawget(_ENV, name)
    if type(current) == "function" and not own_wrappers[current] then
      local wrapper = make(current)
      own_wrappers[wrapper] = true
      rawset(_ENV, name, wrapper)
    end
  end

  function S.LateWrappers()
    if type(rawget(_ENV, "UpdateSpiritItem")) == "function" then
      WrapGlobal("UpdateItem", ResultRows)
    end
    if recruits_here then
      WrapGlobal("Step", RecruitStep)
    end
  end

  if type(VRFW_Host) == "table" and type(VRFW_Host.HookCommand) == "function" then
    local innermost = {priority = VRFW_Host.INNERMOST}
    VRFW_Host.HookCommand({SPIRIT_INFO, HAS_CHARA_SPIRIT}, NoticeFilter, "ClassicRecruitment.spirit_notices", innermost)
    VRFW_Host.HookCommand("*", FirstCommand, LATE_OWNER, innermost)
    VRFW_Host.HookCommand("*", FirstCommand, LATE_OWNER, {menu = true, priority = VRFW_Host.INNERMOST})
  end
end
