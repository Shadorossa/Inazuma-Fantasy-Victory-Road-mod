-- Campaign / tournament grid
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.difficulty.START_RETRY_FRAMES = 30 -- frames the start is asked again while the scripts are busy
BattleBayDeluxe.difficulty.DECIDE_HOLD_FRAMES = 120

do
  Wrap("BattleBayDeluxe.draft_difficulty_campaign", "OnDecideFocus", { around = function(decide, a1, a2, ...)
    local D = BattleBayDeluxe.difficulty
    if a1 == D.GRID then
      local ok, owned = pcall(BattleBayDeluxe.difficulty_owned)
      if ok and owned ~= nil then
        if D.pending ~= nil or (D.hold or 0) > 0 then
          return
        end
        D.pending = { args = table.pack(a1, a2, ...), tries = D.START_RETRY_FRAMES }
        BattleBayDeluxe.difficulty_log("team decided (tile " .. tostring(a2) .. "): no difficulty window, the start follows")
        return
      end
    end
    return decide(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.draft_difficulty_campaign", "Step", { around = function(step, ...)
    local r = table.pack(step(...))
    local D = BattleBayDeluxe.difficulty
    if (D.hold or 0) > 0 then
      D.hold = D.hold - 1
    end
    local p = D.pending
    if p ~= nil then
      local ok, done = pcall(funcLuaCommand, D.START)
      if ok and done == true then
        D.pending = nil
        D.hold = D.DECIDE_HOLD_FRAMES
        BattleBayDeluxe.difficulty_log("started without the difficulty window")
      elseif ok and done == nil and p.tries > 0 then
        p.tries = p.tries - 1 -- the scripts were busy: asked again next frame
      else
        D.pending = nil
        BattleBayDeluxe.difficulty_log("the start without the difficulty window failed (" .. tostring(done) ..
          "): the difficulty window opens")
        local okd, err = pcall(decide, table.unpack(p.args, 1, p.args.n))
        if not okd then
          BattleBayDeluxe.difficulty_log("difficulty window error", tostring(err))
        end
      end
    end
    return table.unpack(r, 1, r.n)
  end })
end
