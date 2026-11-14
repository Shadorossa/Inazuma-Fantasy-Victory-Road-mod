-- Free-match settings list
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.difficulty.FIRST_ROW = 1 -- the first row shown: the stadium
BattleBayDeluxe.difficulty.CURSOR = @crc:cursor@ --[[cursor: the attach of the list rows]]

-- the focus (and the cursor) on row `row` of the settings list
function BattleBayDeluxe.difficulty_focus_row(row)
  local L = BattleBayDeluxe.difficulty.OPTIONS
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, L)
  if type(n) ~= "number" or row >= n then
    return
  end
  funcLuaMenuCommand(1778826357 --[[control focus (layer, idx, on)]], L, 0, false)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@ --[[focus look]], L, 0, @crc:Focus@, 2, @crc:button@)
  funcLuaMenuCommand(1778826357 --[[control focus (layer, idx, on)]], L, row, true)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@ --[[focus look]], L, row, @crc:Focus@, 0, @crc:button@)
  funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, L, BattleBayDeluxe.difficulty.CURSOR, row, n)
end

-- the difficulty row hidden, the focus on the first row shown
function BattleBayDeluxe.difficulty_hide_row()
  local L = BattleBayDeluxe.difficulty.OPTIONS
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, L, 0, false)
  funcLuaMenuCommand(@crc:CMND_END_BLY_DETAIL_TITLE@ --[[click zone]], L, 0, false)
  BattleBayDeluxe.difficulty_focus_row(BattleBayDeluxe.difficulty.FIRST_ROW)
  BattleBayDeluxe.difficulty_log("match settings: the difficulty row hidden")
end

do
  Wrap("BattleBayDeluxe.draft_difficulty_free", "OnOpenLayer", { around = function(open, a1, a2, ...)
    local r = table.pack(open(a1, a2, ...))
    if a1 == BattleBayDeluxe.difficulty.OPTIONS then
      local okn, n = pcall(funcLuaMenuCommand, @crc:CMND_GET_CREATE_LAYER_NUM@, a1)
      local ok, owned = pcall(BattleBayDeluxe.difficulty_owned)
      if okn and type(n) == "number" and a2 == n - 1 and ok and owned ~= nil then
        local okh, err = pcall(BattleBayDeluxe.difficulty_hide_row)
        if not okh then
          BattleBayDeluxe.difficulty_log("match settings error", tostring(err))
        end
      end
    end
    return table.unpack(r, 1, r.n)
  end })

  Wrap("BattleBayDeluxe.draft_difficulty_free", "OnChangeFocus", { around = function(change, a1, a2, ...)
    if a1 == BattleBayDeluxe.difficulty.OPTIONS then
      local ok, owned = pcall(BattleBayDeluxe.difficulty_owned)
      if ok and owned ~= nil and funcLuaMenuCommand(2603265800 --[[focus index]], a1) == 0 then
        pcall(BattleBayDeluxe.difficulty_focus_row, BattleBayDeluxe.difficulty.FIRST_ROW)
        return
      end
    end
    return change(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.draft_difficulty_free", "OnDecideFocus", { around = function(decide, a1, a2, ...)
    if a1 == BattleBayDeluxe.difficulty.OPTIONS and a2 == 0 then
      local ok, owned = pcall(BattleBayDeluxe.difficulty_owned)
      if ok and owned ~= nil then
        return
      end
    end
    return decide(a1, a2, ...)
  end })
end
