  -- VRFW vs small format
  VRFW.small_format = VRFW.small_format or {}
  VRFW.small_format.LOG = @crc:CMND_VRFW_LOG@                 -- (loader log; pcall: absent without the Lua bridge)
  VRFW.small_format.SLOTS = 19
  VRFW.small_format.COACH = 19
  VRFW.small_format.LEADER_BLANK = 2290394976        -- team00_01_p1_chara_card_blank_for_leader
  function VRFW.small_format.log(...)
    pcall(funcLuaCommand, VRFW.small_format.LOG, "vs small format:", ...)
  end
  local function hide(layer, i)
    if type(layer) == "number" and funcLuaMenuCommand(@crc:CMND_IS_EXIST_LAYER@, layer, i) == true then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
    end
  end
  function VRFW.small_format.apply(used, cards, blanks, leader, leader_blank, where)
    local field = 0
    for p = 0, 10 do
      if used[p] then
        field = field + 1
      end
    end
    if field == 0 or field >= 11 then
      return
    end
    local n = VRFW.small_format.SLOTS
    local made = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, blanks)
    if type(made) == "number" and made > n then
      n = made
    end
    local hidden = 0
    for i = 0, n - 1 do
      if not used[i] then
        hide(cards, i)
        hide(blanks, i)
        hidden = hidden + 1
      end
    end
    local coach = used[VRFW.small_format.COACH] == true
    if not coach then
      hide(leader, 0)
      hide(leader_blank or VRFW.small_format.LEADER_BLANK, 0)
    end
    VRFW.small_format.log(where, "field members", field, "empty slots hidden", hidden, "coach", coach and "shown" or "hidden")
  end
