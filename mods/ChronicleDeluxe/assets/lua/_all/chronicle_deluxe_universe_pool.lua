ChronicleDeluxe = type(ChronicleDeluxe) == "table" and ChronicleDeluxe or {}

if ChronicleDeluxe.UniversePool == nil then
  local Pool = {}
  ChronicleDeluxe.UniversePool = Pool

  local SIGN_INFO = 1112436817             -- (4, sign) -> ok, cards of one pull
  local SIGN_CHARACTERS = 1308390374       -- (what, sign, ...) reads of a star sign's character rows
  local WHAT_BUCKET_ROWS = 1               -- (bucket) -> ok, rows
  local WHAT_ROW_WEIGHT = 9                -- (bucket, row) -> ok, default weight
  local WHAT_ROW_BOOST = 10                -- 10 to 13 (bucket, row) -> ok, extra weight of boost group 0 to 3
  local WHAT_ROW = 15                      -- (bucket, row) -> ok, card, bucket, rarity, enabled
  local WHAT_ROW_BY_INDEX = 16             -- (index) -> ok, card, bucket, rarity
  local WHAT_BUCKET_RATE = 18              -- (bucket) -> ok, rate
  local BOOST_ACTIVE = 3127020518          -- (group) -> ok, active
  local GRANT_CARD = 2807419770            -- (card, rarity) -> handle, 0 when not given
  local ROLL = VRFW.commands.CHRONICLEDELUXE_UNIVERSE_ROLL                   -- (upper) -> 1 to upper
  local BUCKETS = 3
  local BOOST_GROUPS = 4

  local function roll(upper)
    return funcLuaCommand(ROLL, upper)
  end

  -- True when pulls leave out the cards the save holds.
  function Pool.active()
    return type(CharacterReforged) == "table" and type(CharacterReforged.one_card_per_player) == "function"
      and CharacterReforged.one_card_per_player()
  end

  -- True when the club or the spirit box holds `card`; `known` keeps the answers of one walk.
  function Pool.held(card, known)
    local held = known[card]
    if held == nil then
      held = VRFW.recruit.owned(card) > 0 or VRFW.recruit.spirits(card) > 0
      known[card] = held
    end
    return held
  end

  local function active_boosts()
    local active = {}
    for group = 0, BOOST_GROUPS - 1 do
      local got, on = funcLuaCommand(BOOST_ACTIVE, group)
      active[group] = got and on
    end
    return active
  end

  local function row_weight(sign, bucket, row, boosts)
    local got, weight = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_ROW_WEIGHT, sign, bucket, row)
    weight = got and weight or 0
    for group = 0, BOOST_GROUPS - 1 do
      if boosts[group] then
        local has, extra = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_ROW_BOOST + group, sign, bucket, row)
        if has then
          weight = weight + extra
        end
      end
    end
    return weight
  end

  -- The rows of `sign` a pull can give, per bucket (1 to 3), and the rate of each bucket with rows.
  local function drawable(sign)
    local total = 0
    for bucket = 0, BUCKETS - 1 do
      local got, rows = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_BUCKET_ROWS, sign, bucket)
      if got then
        total = total + rows
      end
    end
    local boosts, known = active_boosts(), {}
    local rows_of, rates, next_row = { {}, {}, {} }, { 0, 0, 0 }, { 0, 0, 0 }
    for index = 0, total - 1 do
      local got, card, bucket, rarity = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_ROW_BY_INDEX, sign, index)
      if got then
        local place = bucket + 1
        local row = next_row[place]
        next_row[place] = row + 1
        local read, row_card, _, _, enabled = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_ROW, sign, bucket, row)
        if read and row_card == card and card ~= 0 and enabled and not Pool.held(card, known) then
          local weight = row_weight(sign, bucket, row, boosts)
          if weight > 0 then
            local rows = rows_of[place]
            rows[#rows + 1] = { card = card, rarity = rarity, index = index, weight = weight }
          end
        end
      end
    end
    for place = 1, BUCKETS do
      if #rows_of[place] > 0 then
        local got, rate = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_BUCKET_RATE, sign, place - 1)
        rates[place] = got and rate or 0
      end
    end
    return rows_of, rates
  end

  -- True when no pull of `sign` can give a card.
  function Pool.spent(sign)
    local rows_of, rates = drawable(sign)
    for place = 1, BUCKETS do
      if rates[place] > 0 and #rows_of[place] > 0 then
        return false
      end
    end
    return true
  end

  local rule_on = nil                      -- Pool.active, until Pool.forget
  local orb_spent_of = {}                  -- sign * 16 + star -> the orb has nothing left, until Pool.forget
  local held_for_orbs = {}                 -- card -> held, until Pool.forget

  -- True when a row of `sign` can still be given; stops at the first one.
  local function has_card_left(sign)
    local boosts = active_boosts()
    for bucket = 0, BUCKETS - 1 do
      local has_rate, rate = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_BUCKET_RATE, sign, bucket)
      local has_rows, rows = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_BUCKET_ROWS, sign, bucket)
      if has_rate and rate > 0 and has_rows then
        for row = 0, rows - 1 do
          local read, card, _, _, enabled = funcLuaMenuCommand(SIGN_CHARACTERS, WHAT_ROW, sign, bucket, row)
          if read and card ~= 0 and enabled and not Pool.held(card, held_for_orbs)
            and row_weight(sign, bucket, row, boosts) > 0 then
            return true
          end
        end
      end
    end
    return false
  end

  -- True when an orb can run out of cards: Pool.active, read once until Pool.forget.
  function Pool.orbs_run_out()
    if rule_on == nil then
      rule_on = Pool.active()
    end
    return rule_on
  end

  -- True when orb `star` of `sign` has nothing left;`drawn_sign(sign, star)` names the list it draws from.
  function Pool.orb_spent(sign, star, drawn_sign)
    if not Pool.orbs_run_out() then
      return false
    end
    local key = sign * 16 + star
    local spent = orb_spent_of[key]
    if spent == nil then
      local drawn = drawn_sign(sign, star)
      spent = not has_card_left(drawn ~= 0 and drawn or sign)
      orb_spent_of[key] = spent
    end
    return spent
  end

  -- Drops the orb answers: the map opened or a pull changed what the save holds.
  function Pool.forget()
    rule_on, orb_spent_of, held_for_orbs = nil, {}, {}
  end

  -- The bucket of the next card; the last star's first card skips bucket 1 while another has rows.
  local function pick_bucket(rows_of, rates, skip_common)
    local first = 1
    if skip_common and rates[2] + rates[3] > 0 then
      first = 2
    end
    local total = 0
    for place = first, BUCKETS do
      total = total + rates[place]
    end
    if total <= 0 then
      return nil
    end
    local left = roll(total)
    for place = first, BUCKETS do
      if rates[place] > 0 then
        if left <= rates[place] then
          return place
        end
        left = left - rates[place]
      end
    end
    return nil
  end

  local function pick_row(rows)
    local total = 0
    for _, row in ipairs(rows) do
      total = total + row.weight
    end
    local left = roll(total)
    for _, row in ipairs(rows) do
      if left <= row.weight then
        return row
      end
      left = left - row.weight
    end
    return rows[#rows]
  end

  local function remove_card(rows_of, rates, card)
    for place = 1, BUCKETS do
      local rows = rows_of[place]
      for i = #rows, 1, -1 do
        if rows[i].card == card then
          table.remove(rows, i)
        end
      end
      if #rows == 0 then
        rates[place] = 0
      end
    end
  end

  -- One pull without held cards or repeats, in the shape of LotteryStarSignCharacter: { card, bucket, rarity, index }.
  function Pool.draw(sign, is_last_star)
    local cards = {}
    local got, per_pull = funcLuaMenuCommand(SIGN_INFO, 4, sign)
    if not got then
      return cards
    end
    local rows_of, rates = drawable(sign)
    local skip_common = is_last_star
    for _ = 1, per_pull do
      local place = pick_bucket(rows_of, rates, skip_common)
      if place == nil then
        break
      end
      local row = pick_row(rows_of[place])
      remove_card(rows_of, rates, row.card)
      if funcLuaMenuCommand(GRANT_CARD, row.card, row.rarity) ~= 0 then
        skip_common = false
        cards[#cards + 1] = { row.card, place - 1, row.rarity, row.index }
      end
    end
    Pool.forget()
    return cards
  end
end
