local RECRUIT_MENUS = {
  "vs_route_town_menu", "chronicle_mode_top_menu", "soccer_top_menu", "soccer_team_dock_menu", "chara_bank_menu",
  "team_dock_menu", "market_menu",
}

ClassicRecruitment = type(ClassicRecruitment) == "table" and ClassicRecruitment or {}

if ClassicRecruitment.spirits == nil then
  local S = {}
  ClassicRecruitment.spirits = S
  local SPIRIT_INFO = 707505551          -- CMND_GET_SPIRIT_INFO (mode, series) -> ok, shown
  local HAS_CHARA_SPIRIT = 3002728759    -- (card) -> a spirit of this player is new
  local LOG = 519897777                 -- CMND_VRFW_LOG
  local DROP_HIDE_TABS = 170971510       -- CMND_VRFW_DROP_HIDE_TABS () -> the drop list tab types never shown
  local FIRST_SPIRIT_TAB = 1             -- Drop list tab types 1 to 4 are the player spirit groups A to D.
  local LAST_SPIRIT_TAB = 4
  local CHARA_INFO = 4060384944
  local SPIRIT_NUM = 1883729669          -- CMND_GET_SPIRIT_NUM (card, rarity) -> ok, stock
  local ADD_SPIRIT = 2757645277          -- CMND_ADD_ITEM_SPIRIT (card, count, rarity, used)
  local AUTO_SAVE = 3673719958           -- CMND_SYSTEM_AUTO_SAVE
  local FLAG_GET = 347960022             -- CMND_VRFW_UI_FLAG_GET (key) -> number
  local FLAG_SET = 261257594             -- CMND_VRFW_UI_FLAG_SET (key, value)
  local FLAG_PERSIST = 1222990710        -- CMND_VRFW_UI_FLAG_PERSIST (key, value): kept with the save
  local ACTIVE_SLOT = 4245285902         -- CMND_VRFW_SLOT_ACTIVE -> the loaded save's slot (0 = none)
  local IN_STORY = 424926145
  local LAST_NORMAL_RARITY = 4           -- spirit rarities 0-4: the normal cards
  local FIRST_SPECIAL_CARD_TYPE = 5      -- card types 5-7 Ídolo, 8 Diamante, 9+ season / mods' cards
  local RECRUIT_LEVEL = 1                -- the summon screen's level
  local SCOUTED = 2                      -- CMND_ADD_PARTY source: scouted
  local SPIRIT_STOCK_MAX = 999
  local PENDING_MAX = 64
  local ENTRY_SIZE = 3
  local SPIRIT_CHRONICLE_DOCK_ROW = 60  -- rpg_team_dock_menu_inc row kind of «Espíritu» (the Chronicle team dock list)

  local function Crc(text)
    return VRFW.ids.crc32(text)
  end
  local function PendingCountKey()
    return Crc("no_more_rarities_spirit_pending_count")
  end
  local function PendingKey()
    return Crc("no_more_rarities_spirit_pending")
  end

  -- the engine command past every command hook
  local function EngineCommand(...)
    return VRFW.host.real_command(...)
  end

  local function Log(...)
    pcall(EngineCommand, LOG, "ClassicRecruitment spirit recruit", ...)
  end

  -- ClassicCards' normal card rarity when it answers, else the spirit's own rarity
  local function RecruitRarity(spirit_rarity)
    local rarities = rawget(_ENV, "ClassicCards")
    if type(rarities) == "table" and type(rarities.normal_card_rarity) == "function" then
      local ok, rarity = pcall(rarities.normal_card_rarity)
      if ok and type(rarity) == "number" then
        return rarity
      end
    end
    return spirit_rarity
  end

  -- the callback wrappers go on at the VM's first engine command, once every patch of the script has run
  local LATE_OWNER = "ClassicRecruitment.late_wrappers"
  local function LateOnce()
    if not S.late_done then
      S.late_done = true
      VRFW.host.unhook_command(LATE_OWNER)
      VRFW.host.unhook_command(LATE_OWNER, {menu = true})
      local ok, err = pcall(S.late_wrappers)
      if not ok then
        Log("late wrappers failed:", tostring(err))
      end
    end
  end

  -- No "new spirit" notices while the option spirit_section is off.
  local function NoticeFilter(nxt, ...)
    local id = ...
    if id == SPIRIT_INFO and ClassicRecruitment.spirits_hidden() then
      return true, false
    end
    if id == HAS_CHARA_SPIRIT and ClassicRecruitment.spirits_hidden() then
      return false
    end
    return nxt(...)
  end

  -- The drop list keeps its player spirit tabs while the option spirit_section is on.
  local function TabFilter(nxt, ...)
    local hidden = table.pack(nxt(...))
    if ClassicRecruitment.spirits_hidden() then
      return table.unpack(hidden, 1, hidden.n)
    end
    local kept = {}
    for i = 1, hidden.n do
      local tab = hidden[i]
      if type(tab) ~= "number" or tab < FIRST_SPIRIT_TAB or tab > LAST_SPIRIT_TAB then
        kept[#kept + 1] = tab
      end
    end
    return table.unpack(kept)
  end

  local function FirstCommand(nxt, ...)
    LateOnce()
    return nxt(...)
  end

  -- a spirit drop of a normal card is kept as a pending recruit (loader UI flags kept with the save)
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

  function S.note_pending(card, rarity)
    if type(card) ~= "number" or card == 0 or type(rarity) ~= "number" or rarity < 0 or rarity > LAST_NORMAL_RARITY then
      return
    end
    if not ClassicRecruitment.applies() then
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

  function S.recruit_pending(where)
    if not ClassicRecruitment.applies() or type(VRFW.recruit) ~= "table" or type(VRFW.recruit.sign) ~= "function" then
      return 0
    end
    local entries, count = ReadPending()
    if #entries == 0 then
      return 0
    end
    local ok_story, in_story = pcall(EngineCommand, IN_STORY)
    if ok_story and in_story == true then
      return 0                           -- the story's roster is not the bank
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
          local hdl, why = VRFW.recruit.sign(e.card, RECRUIT_LEVEL, rarity, SCOUTED)
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

  local function ResultRows(retail_item)
    return function(a1, a2, a3, a4, card, a6, rarity, is_spirit, ...)
      if is_spirit == true then
        pcall(S.note_pending, card, rarity)
      end
      return retail_item(a1, a2, a3, a4, card, a6, rarity, is_spirit, ...)
    end
  end

  local patch = rawget(VRFW, "patch")
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
        local ok, err = pcall(S.recruit_pending, stem)
        if not ok then
          Log(stem, "failed:", tostring(err))
        end
      end
      return retail_step(...)
    end
  end

  -- The Chronicle team dock lists its rows without «Espíritu» while the option spirit_section is off.
  local function ChronicleRows(retail_sort)
    return function(...)
      local list = retail_sort(...)
      if type(list) ~= "table" or not ClassicRecruitment.holds(ClassicRecruitment.spirits_hidden) then
        return list
      end
      local shown = {}
      for _, kind in ipairs(list) do
        if kind ~= SPIRIT_CHRONICLE_DOCK_ROW then
          shown[#shown + 1] = kind
        end
      end
      return shown
    end
  end

  -- wraps a global once per function object
  local own_wrappers = {}
  local function WrapGlobal(name, make)
    local current = rawget(_ENV, name)
    if type(current) == "function" and not own_wrappers[current] then
      local wrapper = make(current)
      own_wrappers[wrapper] = true
      rawset(_ENV, name, wrapper)
    end
  end

  function S.late_wrappers()
    if type(rawget(_ENV, "UpdateSpiritItem")) == "function" then
      WrapGlobal("UpdateItem", ResultRows)
    end
    if recruits_here then
      WrapGlobal("Step", RecruitStep)
    end
    WrapGlobal("GetSortOflistItems", ChronicleRows)
  end

  if type(VRFW.host) == "table" and type(VRFW.host.hook_command) == "function" then
    local innermost = {priority = VRFW.host.INNERMOST}
    VRFW.host.hook_command({SPIRIT_INFO, HAS_CHARA_SPIRIT}, NoticeFilter, "ClassicRecruitment.spirit_notices", innermost)
    VRFW.host.hook_command({DROP_HIDE_TABS}, TabFilter, "ClassicRecruitment.spirit_tabs", innermost)
    VRFW.host.hook_command("*", FirstCommand, LATE_OWNER, innermost)
    VRFW.host.hook_command("*", FirstCommand, LATE_OWNER, {menu = true, priority = VRFW.host.INNERMOST})
  end
end
