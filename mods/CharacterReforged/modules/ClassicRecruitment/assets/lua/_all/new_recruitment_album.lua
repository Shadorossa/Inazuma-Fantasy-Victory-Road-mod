-- Classic Recruitment › players are signed in BetterQoL's «Álbum de jugadores»: A on a player the club does not have
-- asks «¿Quieres fichar a X?» and he joins on «Sí». The pachangas of the Chronicle board are only matches and the
-- office's Mercado bar is gone (assets\lua\market_menu\new_recruitment_office_bar.lua).
-- * ClassicRecruitment.Ask(s) / Notice(s) / Say(id, name): the game's question / notice window (Sí / No, «%s» = the name),
--   used inside a coroutine (they yield until the window is answered and closed).
-- * The album action: one entry of BetterQoL.AlbumActions: offered while
--   ClassicRecruitment.Applies() (not a reserved slot); the signing is the VR-Framework's
--   recruit service (VRFW_Recruit.Recruit: one card per character, a free bank slot, the game's add path, autosave) at
--   the level of the team in use, the exact card and rarity of the row (an «Especiales» row is the special card itself).
-- Definitions only; no engine call at load time.
ClassicRecruitment = ClassicRecruitment or {}

if ClassicRecruitment.Album == nil then
  local A = {
    TEXT = 4074371074,                       -- CMND_TEXT_GET
    LOG = 3661580131,
    MSG_OPEN = 2289627655, MSG_KIND = 2351835063, MSG_RESULT = 1523741473, MSG_DONE = 682363669, MSG_BUSY = 898725220,
    -- text\rows\album_text.toml (menu_text rows) and the pachangas' «%s joined» line
    PRICE = 1166387904,                       -- CMND_CLASSICRECRUITMENT_ALBUM_PRICE (rarity, level, card) -> item id, count
    PRICES = 3141642457,                      -- CMND_CLASSICRECRUITMENT_ALBUM_PRICES (level, "rarity:card,...") -> { counts }, atlas, sprite
    GUIDE = 2414122637 --[[new_recruitment_album_guide]], ASK = 2442356306 --[[new_recruitment_album_ask_price]],
    POOR = 4077283073 --[[new_recruitment_album_not_enough]],
    OWNED = 2127430293 --[[new_recruitment_album_owned]], FULL = 1165105549 --[[new_recruitment_album_full]],
    FAILED = 1534386840 --[[new_recruitment_album_failed]], DONE = 290976732 --[[new_recruitment_pachangas_join_done]],
  }
  ClassicRecruitment.Album = A

  local function call(cmd, ...)
    local r = table.pack(pcall(funcLuaCommand, cmd, ...))
    if not r[1] then return nil end
    return table.unpack(r, 2, r.n)
  end

  -- a Sí / No question (the game's question window); true = «Sí». In a menu VM: the framework's question
  -- (VRFW_Question: waits for its own window, never an earlier answer)
  function ClassicRecruitment.Ask(s)
    if VRFW_Question ~= nil then
      return VRFW_Question.Ask(s)
    end
    call(A.MSG_OPEN, s, 0, 0, 0, 0, 0, false)
    call(A.MSG_KIND, 2, 0)
    coroutine.yield()
    local r = -1
    while r == nil or r < 0 do
      r = call(A.MSG_RESULT)
      coroutine.yield()
    end
    while call(A.MSG_DONE) ~= true do
      coroutine.yield()
    end
    return r == 0
  end

  function ClassicRecruitment.Notice(s)
    if VRFW_Question ~= nil then
      VRFW_Question.Notice(s)
      return
    end
    call(A.MSG_OPEN, s, 0, 0, 0, 0, 0, false)
    call(A.MSG_KIND, 1, 0)
    coroutine.yield()
    while call(A.MSG_BUSY) == true do
      coroutine.yield()
    end
    while call(A.MSG_DONE) ~= true do
      coroutine.yield()
    end
  end

  -- text `id` of the game's language with «%s» = name
  function ClassicRecruitment.Say(id, name)
    local t = call(A.TEXT, id)
    t = type(t) == "string" and t or ""
    local ok, s = pcall(string.format, t, name or "")
    return ok and s or t
  end

  -- text `id` of the game's language with «%s» = name, then «%d» = cost, «%d» = balance
  function ClassicRecruitment.SayPrice(id, name, cost, balance)
    local t = call(A.TEXT, id)
    t = type(t) == "string" and t or ""
    local ok, s = pcall(string.format, t, name or "", math.floor(cost or 0), math.floor(balance or 0))
    return ok and s or t
  end

  -- the album action (BetterQoL.AlbumActions): row = {base, param, name, owned, level, rarity}
  A.action = {
    id = "ClassicRecruitment.Recruit",
    guide = A.GUIDE,
    On = function()
      return VRFW_Recruit ~= nil and (ClassicRecruitment.Applies == nil or ClassicRecruitment.Applies())
    end,
    -- the price Run charges, at the right edge of each row the club does not have; one command per page load
    RowExtras = function(rows)
      local cards, row_of = {}, {}
      for k, row in ipairs(rows) do
        if row.owned ~= true and type(row.param) == "number" and row.param ~= 0 then
          -- %.0f: a card id is an unsigned 32-bit hash; %d of Lua 5.2 refuses one above 2^31
          local ok, card = pcall(string.format, "%.0f:%.0f", tonumber(row.rarity) or 0, row.param)
          if ok then
            cards[#cards + 1] = card
            row_of[#cards] = k
          end
        end
      end
      if #cards == 0 then return {} end
      local counts, atlas, sprite = call(A.PRICES, VRFW_Recruit.TeamLevel(), table.concat(cards, ","))
      if type(counts) ~= "table" then return nil end
      local extras = {}
      for i, k in ipairs(row_of) do
        local count = tonumber(counts[i])
        if count ~= nil and count > 0 and type(atlas) == "string" and type(sprite) == "string" then
          extras[k] = {text = string.format("x%.0f", count), atlas = atlas, sprite = sprite}
        end
      end
      return extras
    end,
    Run = function(row)
      local R = VRFW_Recruit
      local name = tostring(row.name or "")
      if R == nil or type(row.param) ~= "number" or row.param == 0 then return false end
      local can, why = R.CanSign(row.param)
      if row.owned == true or why == "owned" then
        ClassicRecruitment.Notice(ClassicRecruitment.Say(A.OWNED, name))
        return false
      end
      if not can then
        ClassicRecruitment.Notice(ClassicRecruitment.Say(A.FULL, name))
        return false
      end
      local level = type(R.TeamLevel) == "function" and R.TeamLevel() or 1
      -- the price (config.toml [album], scripts\album_price.lua) and what the player has of its currency
      local item, cost = call(A.PRICE, tonumber(row.rarity) or 0, level, row.param)
      local price = (type(item) == "number" and type(cost) == "number" and cost > 0) and {item = item, count = cost} or nil
      local balance = price and R.Items(price.item) or 0
      if price and balance < price.count then
        ClassicRecruitment.Notice(ClassicRecruitment.SayPrice(A.POOR, name, price.count, balance))
        return false
      end
      if not ClassicRecruitment.Ask(ClassicRecruitment.SayPrice(A.ASK, name, price and price.count or 0, balance)) then
        return false
      end
      local ok, err = R.Recruit{param = row.param, level = level, rarity = row.rarity, price = price}
      pcall(funcLuaCommand, A.LOG, "ClassicRecruitment album recruit", row.param, level, price and price.count or 0,
        ok == true and "joined" or tostring(err))
      if err == "price" then
        ClassicRecruitment.Notice(ClassicRecruitment.SayPrice(A.POOR, name, price and price.count or 0, R.Items(price.item)))
        return false
      end
      if ok == true then
        ClassicRecruitment.Notice(ClassicRecruitment.Say(A.DONE, name))
        return true
      end
      ClassicRecruitment.Notice(ClassicRecruitment.Say(err == "bank_full" and A.FULL or A.FAILED, name))
      return false
    end,
  }

  if type(BetterQoL) == "table" then
    BetterQoL.AlbumActions = type(BetterQoL.AlbumActions) == "table" and BetterQoL.AlbumActions or {}
    local listed = false
    for _, a in ipairs(BetterQoL.AlbumActions) do
      if type(a) == "table" and a.id == A.action.id then listed = true end
    end
    if not listed then
      BetterQoL.AlbumActions[#BetterQoL.AlbumActions + 1] = A.action
    end
  end
end
