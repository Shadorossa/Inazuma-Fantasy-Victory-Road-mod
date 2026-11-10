do
  CharacterReforged_TableCreate = CharacterReforged_TableCreate or {}
  local Create = CharacterReforged_TableCreate
  Create.ITEMS = 2820944175
  Create.ROW = 2827747337
  Create.NO_LEARNED_MOVE = -5
  Create.ONLY_GREY = -6
  Create.FADE = 609722083                            -- screen fade (1 out / 0 in, seconds)
  Create.MENU_HIDE = 1670867360                      -- (1, menu) the whole menu hidden (the retail full-screen movie hide)
  Create.MENU_SHOW = 3257327861                      -- (menu) shown again
  Create.MENU_CALL = 830228314                       -- (menu, function name, ...) a function of another menu (retail)
  Create.scene_row = false                           -- the picked system plays the creation scene after storing
  Create.CARRIER = 907079567
  Create.REFUSAL = 3947752921
  Create.LOG = 2743311895
  Create.MIX_SET = 242652959
  Create.ITEM_NUM = 2011560392                       -- CMND_GET_ITEM_NUM (item) -> copies owned
  Create.ADD_ITEM = 1897915498                       -- CMND_ADD_ITEM_ONLY (item, count, flag) -> inventory handle
  Create.DEL_ITEM = 425598937                        -- CMND_DELETE_ITEM (item, count)
  Create.EQUIPPED_NUM = 556568075                    -- (inventory handle) -> copies equipped
  Create.OPEN_MENU = 433545986                       -- CMND_OPEN_MENU_OBJECT
  Create.EXIST_MENU = 2231168902                     -- CMND_IS_EXIST_MENU_OBJECT
  Create.MENU_SUSPEND = 1129326309                   -- (menu) hidden while a child menu is open
  Create.MENU_RESUME = 1453710531                    -- (menu)
  Create.SCREEN = 2221030314                         -- vrfw_skill_slot_menu
  Create.BANK_MENU = 1981996040                      -- chara_bank_menu_for_search (the retail card picker)
  -- Keys of the bank's pick.
  Create.KEY_BASE = 2918576166
  Create.KEY_EARLY = 1743709088
  Create.KEY_ROW = 416963278                           -- character_reforged_create_row: the system's row
  Create.KEY_MOVES = {892911027, 2888952841}
  Create.TEMP_GET = 3185911119
  Create.TEMP_SET = 2565779025
  Create.BANK_RESULT = 2524660062
  Create.TEXT_GET = 4074371074                       -- CMND_TEXT_GET (text id) -> the text in the game's language
  Create.SOUND = 1917805374                          -- play a system sound
  Create.SOUND_DECIDE = 4235359837
  Create.SOUND_REFUSED = 2086672038
  Create.OPEN_WAIT = 90                              -- frames the bank may take to open

  function Create.log(step, ...)
    pcall(funcLuaCommand, Create.LOG, "table " .. tostring(step), ...)
  end

  -- the shown player (the screen's chunk local `n`, served by the skill table's extension point)
  function Create.player()
    local table_api = type(CharacterReforged) == "table" and CharacterReforged.skill_table or nil
    local get = type(table_api) == "table" and table_api.get or nil
    local hdl = type(get) == "table" and type(get.n) == "function" and get.n() or nil
    if type(hdl) == "number" and hdl ~= 0 then
      return hdl
    end
    return nil
  end

  function Create.wait(frames)
    for _ = 1, frames do
      coroutine.yield()
    end
  end

  function Create.before_picker()
    VRFW.param.clear(Create.KEY_EARLY)   -- a flag left by an earlier picker is never this one's
    local answer = table.pack(funcLuaCommand(Create.ITEMS))
    local count = answer[1]
    if type(count) ~= "number" or count <= 0 then
      return                                         -- no system declared, or Character Reforged's script is not running
    end
    for i = 1, count do
      local create = answer[i + 1]
      if type(create) == "number" and create ~= 0 then
        local owned = funcLuaCommand(Create.ITEM_NUM, create)
        local granted = false
        if type(owned) ~= "number" or owned <= 0 then
          funcLuaCommand(Create.ADD_ITEM, create, 1, false)
          granted = true
        else
          local handle = funcLuaCommand(Create.ADD_ITEM, create, 1, false)
          funcLuaCommand(Create.DEL_ITEM, create, 1)
          local used = (type(handle) == "number" and handle ~= 0) and funcLuaCommand(Create.EQUIPPED_NUM, handle) or 0
          if type(used) == "number" and used >= owned then
            funcLuaCommand(Create.ADD_ITEM, create, 1, false)
            granted = true
          end
        end
        Create.log("1 list", "row", i, "item", create, "owned", owned, "free copy granted", granted)
      end
    end
  end

  function Create.bank_keys(hdl, row)
    for _, key in ipairs(Create.KEY_MOVES) do
      VRFW.param.clear(key)
    end
    VRFW.param.clear(Create.KEY_BASE)
    VRFW.param.set(Create.KEY_BASE, hdl)
    VRFW.param.clear(Create.KEY_ROW)
    VRFW.param.set(Create.KEY_ROW, row)
  end

  -- Reads the moves after the bank closed.
  function Create.bank_moves()
    local moves = {}
    for i, key in ipairs(Create.KEY_MOVES) do
      local move = 0
      if VRFW.param.has(key) then
        move = VRFW.param.get(key)
      end
      moves[i] = type(move) == "number" and move or 0
      VRFW.param.clear(key)
    end
    VRFW.param.clear(Create.KEY_BASE)
    VRFW.param.clear(Create.KEY_ROW)
    return moves[1], moves[2]
  end

  -- Writes into the system's store.
  function Create.store(store, hdl, partner, move1, move2)
    if move1 ~= 0 then
      return funcLuaCommand(store, hdl, partner, move1, move2)
    end
    return funcLuaCommand(store, hdl, partner)
  end

  -- Returns the refusal for a row and code.
  function Create.refusal(row, code)
    local _, reason_id, label_s, reason_s = funcLuaCommand(Create.REFUSAL, row, code)
    local reason = type(reason_s) == "string" and reason_s or ""
    if reason == "" and type(reason_id) == "number" and reason_id ~= 0 then
      local ok, v = pcall(funcLuaCommand, Create.TEXT_GET, reason_id)
      if ok and type(v) == "string" then
        reason = v
      end
    end
    funcLuaCommand(Create.SOUND, Create.SOUND_REFUSED)
    Create.log("7 refusal", "row", row, "code", code, "label", type(label_s) == "string" and label_s or "", "reason", reason)
  end

  -- Picks the partner from the retail bank picker while the screen is hidden.
  function Create.bank_pick(row)
    -- Checks whether the picker already opened the bank (CreateCard.open_bank_early).
    local early = VRFW.param.has(Create.KEY_EARLY)
    VRFW.param.clear(Create.KEY_EARLY)
    -- Hides the screen and suspends it under the bank.
    funcLuaMenuCommand(Create.MENU_HIDE, 1, Create.SCREEN)
    funcLuaMenuCommand(Create.MENU_SUSPEND, Create.SCREEN)
    if not early then
      Create.bank_keys(Create.player() or 0, row)
      funcLuaCommand(Create.TEMP_SET, Create.BANK_RESULT, 0)
      funcLuaCommand(Create.OPEN_MENU, Create.BANK_MENU)
    end
    coroutine.yield()
    local frames = 0
    while not funcLuaMenuCommand(Create.EXIST_MENU, Create.BANK_MENU) and frames < Create.OPEN_WAIT do
      frames = frames + 1
      coroutine.yield()
    end
    local seen = funcLuaMenuCommand(Create.EXIST_MENU, Create.BANK_MENU) == true
    Create.log("3 bank open", "exists", seen, "after frames", frames, "opened by the picker", early)
    if seen and early then
      -- The resumed screen rewrote the shared button guide.
      pcall(funcLuaCommand, Create.MENU_CALL, Create.BANK_MENU, "UpdateButtonGuide")
    end
    while seen and funcLuaMenuCommand(Create.EXIST_MENU, Create.BANK_MENU) do
      coroutine.yield()
    end
    local picked = funcLuaCommand(Create.TEMP_GET, Create.BANK_RESULT)
    if Create.scene_row and type(picked) == "number" and picked ~= 0 then
      funcLuaCommand(Create.FADE, 1, 0)              -- the scene follows: the screen stays black under it
    end
    funcLuaMenuCommand(Create.MENU_SHOW, Create.SCREEN)
    funcLuaMenuCommand(Create.MENU_RESUME, Create.SCREEN)
    coroutine.yield()
    local partner = funcLuaCommand(Create.TEMP_GET, Create.BANK_RESULT)
    funcLuaCommand(Create.TEMP_SET, Create.BANK_RESULT, 0)
    local move1, move2 = Create.bank_moves()
    Create.log("4 bank closed", "temp int 2524660062 =", partner, "moves", move1, move2)
    if type(partner) ~= "number" then
      return 0, 0, 0
    end
    return partner, move1, move2
  end

  -- Plays the creation scene of the stored pair.
  function Create.play_scene(hdl)
    local table_api = type(CharacterReforged) == "table" and CharacterReforged.skill_table or nil
    local get = type(table_api) == "table" and table_api.get or nil
    local screen = type(get) == "table" and type(get.PL) == "function" and get.PL() or nil
    local played = false
    if type(screen) == "table" and type(screen.mx_scene_play) == "function" then
      local ok, r = pcall(screen.mx_scene_play)
      played = ok and r == true
      Create.log("8 scene", "player", hdl, "played", played, ok and "" or tostring(r))
    else
      Create.log("8 scene", "player", hdl, "no scene player on this screen")
    end
    if not played then
      funcLuaCommand(Create.FADE, 0, 0.2)
    end
  end

  function Create.picked(row, skill)
    if row ~= 0 or type(skill) ~= "number" or skill == 0 then
      return false
    end
    local system, store, scene, _, needs_learned_move = funcLuaCommand(Create.ROW, skill)
    Create.scene_row = scene == true
    if type(system) ~= "number" or system <= 0 or type(store) ~= "number" or store == 0 then
      return false
    end
    local hdl = Create.player()
    if hdl == nil then
      Create.log("2 picked", "row", system, "no shown player: not created")
      funcLuaCommand(Create.SOUND, Create.SOUND_REFUSED)
      return true
    end
    Create.log("2 picked", "row", system, "player", hdl, "store", store)
    local partner, move1, move2 = Create.bank_pick(system)
    if partner == 0 then
      Create.log("7 cancelled", "row", system)
      funcLuaCommand(Create.FADE, 0, 0.2)
      return true
    end
    if needs_learned_move == true then
      local learned, real = CharacterReforged.move_rows.learned_counts(funcLuaCommand, partner)
      if real == 0 then
        Create.log("5 store", "base", hdl, "partner", partner, "no learned move that is not grey: refused")
        Create.refusal(system, learned == 0 and Create.NO_LEARNED_MOVE or Create.ONLY_GREY)
        funcLuaCommand(Create.FADE, 0, 0.2)
        return true
      end
    end
    local stored, k = Create.store(store, hdl, partner, move1, move2)
    local code = type(stored) == "number" and stored or -3
    Create.log("5 store", "base", hdl, "partner", partner, "moves", move1, move2, "code", code, "k", k)
    if code == 0 then
      local carrier = funcLuaCommand(Create.CARRIER, system, k)
      local inv = 0
      if type(carrier) == "number" and carrier ~= 0 then
        inv = funcLuaCommand(Create.ADD_ITEM, carrier, 1, false) or 0
      end
      local ok, done = false, false
      if type(inv) == "number" and inv ~= 0 then
        ok, done = pcall(funcLuaCommand, Create.MIX_SET, hdl, carrier)
      end
      local placed = ok and done == true
      Create.log("6 carrier", "item", carrier, "inv", inv, "mix slot", placed)
      if placed then
        funcLuaCommand(Create.SOUND, Create.SOUND_DECIDE)
        if Create.scene_row then
          Create.play_scene(hdl)
        end
        return true
      end
      if type(inv) == "number" and inv ~= 0 then
        funcLuaCommand(Create.DEL_ITEM, carrier, 1)
      end
      code = -2                                      -- stored, the carrier not in the mix slot
    end
    if Create.scene_row then
      funcLuaCommand(Create.FADE, 0, 0.2)
    end
    Create.refusal(system, code)
    return true
  end

  function Create.wrap(owner, name, make)
    Create.wrappers = Create.wrappers or {}
    local current = owner[name]
    if current == nil or Create.wrappers[name] == current then
      return
    end
    local wrapper = make(current)
    Create.wrappers[name] = wrapper
    owner[name] = wrapper
  end

  Create.wrap(_ENV, "CharacterReforgedSkillTablePickCoroutine", function(previous)
    return function(row, ...)
      if row == 0 then
        local ok, err = pcall(Create.before_picker)
        if not ok then
          Create.log("1 list", "error", tostring(err))
        end
        return previous(row, ...)
      end
      return previous(row, ...)
    end
  end)

  Create.wrap(CharacterReforged, "skill_table_equip", function(previous)
    return function(row, skill, ...)
      local ok, handled = pcall(Create.picked, row, skill)
      if not ok then
        Create.log("2 picked", "error", tostring(handled))
        return false
      end
      if handled then
        return true
      end
      return previous(row, skill, ...)
    end
  end)
end
