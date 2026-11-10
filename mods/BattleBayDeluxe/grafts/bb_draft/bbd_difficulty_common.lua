BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.difficulty = {
  OWNED = @crc:CMND_BATTLEBAYDELUXE_DIFFICULTY_OWNED@,
  START = @crc:CMND_BATTLEBAYDELUXE_DIFFICULTY_START@,
  GRID = 106197494 --[[vs01_43_enjoy_team_select_emblem_icon]],
  OPTIONS = 429081730 --[[the 1 vs 1's match settings list: row 0 difficulty, 1 stadium, 2 BGM, 3 commentator]],
  index = nil,
}

function BattleBayDeluxe.logger(owner, name)
  owner.logger = owner.logger or VRFW.logger.new(name)
  return owner.logger
end

function BattleBayDeluxe.difficulty_log(...)
  BattleBayDeluxe.logger(BattleBayDeluxe.difficulty, "BattleBayDeluxe.difficulty")(...)
end

-- the owned difficulty index, nil = the player picks it (or the scripts did not answer yet)
function BattleBayDeluxe.difficulty_owned()
  local D = BattleBayDeluxe.difficulty
  if D.index == nil then
    local ok, v = pcall(funcLuaCommand, D.OWNED)
    if ok and type(v) == "number" then
      if v >= 0 then
        D.index = v
        BattleBayDeluxe.difficulty_log("owned by a mod: index " .. tostring(v) .. ", no difficulty asked")
      else
        D.index = false
      end
    end
  end
  if D.index == false then
    return nil
  end
  return D.index
end

do
  local init = OnInit
  function OnInit(...)
    local r = table.pack(init(...))
    pcall(BattleBayDeluxe.difficulty_owned)
    return table.unpack(r, 1, r.n)
  end

  local getter = GetSelectDifficultyIdx
  function GetSelectDifficultyIdx(...)
    local ok, owned = pcall(BattleBayDeluxe.difficulty_owned)
    if ok and owned ~= nil then
      return owned
    end
    return getter(...)
  end
end
