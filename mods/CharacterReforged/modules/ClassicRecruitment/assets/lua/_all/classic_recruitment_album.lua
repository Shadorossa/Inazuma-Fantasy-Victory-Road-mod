ClassicRecruitment = ClassicRecruitment or {}

if ClassicRecruitment.album == nil then
  local A = {
    TEXT = 4074371074,                       -- CMND_TEXT_GET
    LOG = 519897777,
    PRICE = 1166387904,
    PRICES = 3141642457,
    GUIDE = 435977137 --[[classic_recruitment_album_guide]], ASK = 287558800 --[[classic_recruitment_album_ask_price]],
    POOR = 2263643191 --[[classic_recruitment_album_not_enough]],
    OWNED = 3906400169 --[[classic_recruitment_album_owned]], FULL = 1412934599 --[[classic_recruitment_album_full]],
    FAILED = 1955432178 --[[classic_recruitment_album_failed]],
    RECRUIT_MARKED = 3631863893 --[[classic_recruitment_album_recruit_marked]],
    ASK_MANY = 597508430 --[[classic_recruitment_album_ask_many]],
    POOR_MANY = 350415659 --[[classic_recruitment_album_not_enough_many]],
    FULL_MANY = 271806453 --[[classic_recruitment_album_full_many]],
    FAILED_MANY = 1994879108 --[[classic_recruitment_album_failed_many]],
    PARTIAL = 926916990 --[[classic_recruitment_album_partial]],
  }
  ClassicRecruitment.album = A

  -- text `id` of the game's language with "%s" = name
  function ClassicRecruitment.say(id, name)
    local t = VRFW.host.command(A.TEXT, id)
    t = type(t) == "string" and t or ""
    local ok, s = pcall(string.format, t, name or "")
    return ok and s or t
  end

  -- text `id` of the game's language with "%s" = name, then "%d" = cost, "%d" = balance
  function ClassicRecruitment.say_price(id, name, cost, balance)
    local t = VRFW.host.command(A.TEXT, id)
    t = type(t) == "string" and t or ""
    local ok, s = pcall(string.format, t, name or "", math.floor(cost or 0), math.floor(balance or 0))
    return ok and s or t
  end

  -- text `id` of the game's language with its "%d" filled in order
  local function say_numbers(id, ...)
    local t = VRFW.host.command(A.TEXT, id)
    t = type(t) == "string" and t or ""
    local ok, s = pcall(string.format, t, ...)
    return ok and s or t
  end

  -- the "rarity:card" of a row, as CMND_CLASSICRECRUITMENT_ALBUM_PRICES reads it
  local function card_key(row)
    return string.format("%.0f:%.0f", tonumber(row.rarity) or 0, row.param)
  end

  -- the album's currency and its balance; nil when signing is free
  local function currency()
    local item = VRFW.host.command(A.PRICE, 0, VRFW.recruit.team_level(), 0)
    if type(item) ~= "number" then return nil end
    return item, VRFW.recruit.items(item)
  end

  A.action = {
    id = "ClassicRecruitment.Recruit",
    guide = A.GUIDE,
    multi_guide = A.RECRUIT_MARKED,
    On = function()
      return VRFW.recruit ~= nil and (ClassicRecruitment.applies == nil or ClassicRecruitment.applies())
    end,
    -- the price at the right edge of each row the club does not have, one command per page
    RowExtras = function(rows)
      local cards, row_of = {}, {}
      for k, row in ipairs(rows) do
        if row.owned ~= true and type(row.param) == "number" and row.param ~= 0 then
          local ok, card = pcall(card_key, row)
          if ok then
            cards[#cards + 1] = card
            row_of[#cards] = k
          end
        end
      end
      if #cards == 0 then return {} end
      local counts, atlas, sprite = VRFW.host.command(A.PRICES, VRFW.recruit.team_level(), table.concat(cards, ","))
      if type(counts) ~= "table" then return nil end
      local extras = {}
      for i, k in ipairs(row_of) do
        local count = tonumber(counts[i])
        if count ~= nil and count > 0 and type(atlas) == "string" and type(sprite) == "string" then
          extras[k] = {text = string.format("x%.0f", count), count = count, atlas = atlas, sprite = sprite}
        end
      end
      return extras
    end,
    Run = function(row, page)
      local R = VRFW.recruit
      local name = tostring(row.name or "")
      if R == nil or type(row.param) ~= "number" or row.param == 0 then return false end
      local can, why = R.can_sign(row.param)
      if row.owned == true or why == "owned" then
        R.refresh()
        local holders = {}
        for _, h in ipairs(R.holders({row.param})) do
          holders[#holders + 1] = string.format("%.0f:%.0f", h.handle, h.param)
        end
        VRFW.host.command(A.LOG, "ClassicRecruitment album refused owned", row.param, tostring(row.owned), tostring(why),
          R.owned(row.param), table.concat(holders, ","))
        VRFW.question.notice(ClassicRecruitment.say(A.OWNED, name))
        return false
      end
      if not can then
        VRFW.question.notice(ClassicRecruitment.say(A.FULL, name))
        return false
      end
      local level = type(R.team_level) == "function" and R.team_level() or 1
      -- price from config.toml [album] (scripts\album_price.lua)
      local item, cost = VRFW.host.command(A.PRICE, tonumber(row.rarity) or 0, level, row.param)
      local price = (type(item) == "number" and type(cost) == "number" and cost > 0) and {item = item, count = cost} or nil
      local balance = price and R.items(price.item) or 0
      if price and balance < price.count then
        VRFW.question.notice(ClassicRecruitment.say_price(A.POOR, name, price.count, balance))
        return false
      end
      if not VRFW.question.ask(ClassicRecruitment.say_price(A.ASK, name, price and price.count or 0, balance)) then
        return false
      end
      local ok, err = R.recruit{param = row.param, level = level, rarity = row.rarity, price = price}
      VRFW.host.command(A.LOG, "ClassicRecruitment album recruit", row.param, level, price and price.count or 0,
        ok == true and "joined" or tostring(err))
      if err == "price" then
        VRFW.question.notice(ClassicRecruitment.say_price(A.POOR, name, price and price.count or 0, R.items(price.item)))
        return false
      end
      if ok == true then
        local rarity = tonumber(row.rarity) or -1
        VRFW.summon_presentation.play({
          players = {{card = row.param, rarity = rarity >= 0 and rarity or R.card_rarity(row.param)}},
          before = page.before_presentation,
          after = page.after_presentation,
          restore_camera = true,
          fade_back = true,
        })
        return true
      end
      VRFW.question.notice(ClassicRecruitment.say(err == "bank_full" and A.FULL or A.FAILED, name))
      return false
    end,
    -- how many rows can be marked now: the bank's free places, at most what one presentation shows
    MarkLimit = function()
      local room, most = VRFW.recruit.bank_room(), VRFW.summon_presentation.MAX_PLAYERS
      return room ~= nil and math.min(room, most) or most
    end,
    Balance = function()
      local _, balance = currency()
      return balance or 0
    end,
    -- the marked rows signed together: one confirmation, one payment, one presentation; answers changed
    RunMany = function(rows, page)
      local R = VRFW.recruit
      if R == nil or #rows == 0 then return false end
      local level, keys, params, rarity_of, count_of, total = R.team_level(), {}, {}, {}, {}, 0
      for k, row in ipairs(rows) do
        keys[k], params[k], rarity_of[row.param] = card_key(row), row.param, row.rarity
      end
      local counts = VRFW.host.command(A.PRICES, level, table.concat(keys, ","))
      for k, row in ipairs(rows) do
        count_of[row.param] = type(counts) == "table" and tonumber(counts[k]) or 0
        total = total + count_of[row.param]
      end
      local item, balance = currency()
      local one = #rows == 1 and tostring(rows[1].name or "") or nil
      local room = R.bank_room()
      if room ~= nil and room < #rows then
        VRFW.question.notice(one and ClassicRecruitment.say(A.FULL, one) or say_numbers(A.FULL_MANY, #rows, room))
        return false
      end
      balance = balance or 0
      if item ~= nil and balance < total then
        VRFW.question.notice(one and ClassicRecruitment.say_price(A.POOR, one, total, balance)
          or say_numbers(A.POOR_MANY, #rows, total, balance))
        return false
      end
      if not VRFW.question.ask(one and ClassicRecruitment.say_price(A.ASK, one, total, balance)
          or say_numbers(A.ASK_MANY, #rows, total, balance, balance - total)) then
        return false
      end
      local signed, why = R.recruit_list{params = params, level = level, rarity_of = rarity_of, count_of = count_of,
        price_each = item ~= nil and {item = item} or nil}
      VRFW.host.command(A.LOG, "ClassicRecruitment album recruit marked", #rows, #signed, total, tostring(why))
      if #signed == 0 then
        if why == "price" then
          VRFW.question.notice(say_numbers(A.POOR_MANY, #rows, total, R.items(item)))
        elseif why == "bank_full" then
          VRFW.question.notice(say_numbers(A.FULL_MANY, #rows, R.bank_room() or 0))
        else
          VRFW.question.notice(say_numbers(A.FAILED_MANY))
        end
        return false
      end
      local players = {}
      for k, card in ipairs(signed) do
        local rarity = tonumber(rarity_of[card]) or -1
        players[k] = {card = card, rarity = rarity >= 0 and rarity or R.card_rarity(card)}
      end
      VRFW.summon_presentation.play({
        players = players,
        before = page.before_presentation,
        after = function() page.after_presentation(signed) end,
        restore_camera = true,
        fade_back = true,
      })
      if #signed < #rows then
        VRFW.question.notice(say_numbers(A.PARTIAL, #signed, #rows))
      end
      return true
    end,
  }

  if type(BetterQoL) == "table" then
    BetterQoL.album_actions = type(BetterQoL.album_actions) == "table" and BetterQoL.album_actions or {}
    local listed = false
    for _, a in ipairs(BetterQoL.album_actions) do
      if type(a) == "table" and a.id == A.action.id then listed = true end
    end
    if not listed then
      BetterQoL.album_actions[#BetterQoL.album_actions + 1] = A.action
    end
  end
end
