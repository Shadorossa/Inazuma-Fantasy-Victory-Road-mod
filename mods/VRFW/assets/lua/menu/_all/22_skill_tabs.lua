-- lua_patch.scope: used
if VRFW.skill_tabs == nil then
  local ST = {
    CMD_TABS = VRFW.commands.VRFW_SKILL_TABS,
    CMD_WINDOW = VRFW.commands.VRFW_SKILL_TAB_WINDOW,
    CMD_INFO = VRFW.commands.VRFW_SKILL_TAB_INFO,
                               -- text id, text, filter, filter group
    TEXT_GET = VRFW.commands.TEXT_GET,     -- CMND_TEXT_GET(text id) -> the text in the game's language
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,     -- CMND_SET_MENU_TEXT_STRING
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,       -- CMND_SET_LAYER_VISIBLE
    SET_SPRITE = 558735651,
    COLLISION = 855005857,     -- a layer instance's click zone on / off
    HOVER = VRFW.commands.SET_ON_CHANGE_FOCUS_MOUSE,        -- a layer instance's hover focus on / off
    TAB_ITEM = 4044286600,     -- cmn06_20_list_tab_item (one plate instance per tab)
    TAB_NEW = 2834115499,
    TAB_BAR = 1887158505,      -- the tab bar layer (its title text)
    TAB_TEXT = 3029561990,     -- _text_list_tab01
    DMY_ON = 3229351341,       -- `icon_list_tab_dmy01_on`
    DMY_OFF = 380437824,       -- icon_list_tab_dmy01_off
    MARK = 1448280064,
    on = false,
    count = 0,                 -- tabs shown
    looks = {},
    wrapped = false,
    logs = 0,
  }

  local logger
  --- Internal: Logs through the skill-tabs logger, at most 20 lines.
  function ST.log(...)
    if ST.logs >= 20 then
      return
    end
    --- Internal: count of log lines written by the skill tabs.
    ST.logs = ST.logs + 1
    logger = logger or VRFW.logger.new("VRFW skill_tabs")
    logger(...)
  end

  local function number_or(v, default)
    if type(v) == "number" then
      return v
    end
    return default
  end

  --- Internal: The engine's skill tabs, or nil when it has none.
  function ST.native_tabs()
    local r = table.pack(pcall(funcLuaCommand, ST.CMD_TABS))
    if not r[1] or type(r[2]) ~= "number" or r[2] <= 0 then
      return nil
    end
    local all = {}
    for i = 1, r[2] do
      all[#all + 1] = r[2 + i]
    end
    local ok, start, count = pcall(funcLuaCommand, ST.CMD_WINDOW)
    if not ok or type(start) ~= "number" or type(count) ~= "number" or count <= 0 or start + count > #all then
      start, count = 0, #all
    end
    local out = {}
    for i = start + 1, start + count do
      out[#out + 1] = all[i]
    end
    return out
  end

  --- Internal: Rebuild the screen's three tab tables in place (the functions of the script hold them as upvalues).
  function ST.apply(t, t4, t5)
    if ST.on or type(t) ~= "table" or type(t4) ~= "table" or type(t5) ~= "table" then
      return
    end
    local cats = ST.native_tabs()
    if cats == nil then
      return
    end
    local game_icon, game_filter, game_group = {}, {}, {}
    for i = 1, #t do
      game_icon[i], game_filter[i], game_group[i] = t[i], t4[i], t5[i]
    end
    local function kind_index(category)
      if category >= 100 and #t >= 5 then
        return 5
      end
      return 1
    end
    local nt, n4, n5, shown = {}, {}, {}, {}
    for _, category in ipairs(cats) do
      local r = table.pack(pcall(funcLuaCommand, ST.CMD_INFO, category))
      local gi = r[1] and number_or(r[2], 0) or 0
      local icon, atlas, sprite = number_or(r[3], 0), number_or(r[4], 0), number_or(r[5], 0)
      local sprite_off, text_id, text = number_or(r[6], 0), number_or(r[7], 0), r[8]
      local filter, group = number_or(r[9], 0), number_or(r[10], 0)
      local base = (gi > 0 and gi <= #game_icon) and gi or kind_index(category)
      local icon_type = game_icon[base]
      if gi == 0 or icon ~= 0 or sprite ~= 0 or text_id ~= 0 then
        icon_type = ST.MARK + category
        ST.looks[icon_type] = {
          icon = icon ~= 0 and icon or game_icon[base], atlas = atlas, sprite = sprite,
          sprite_off = sprite_off ~= 0 and sprite_off or sprite, text_id = text_id,
          text = type(text) == "string" and text or "", category = category,
        }
      end
      nt[#nt + 1] = icon_type
      n4[#n4 + 1] = filter ~= 0 and filter or game_filter[base]
      n5[#n5 + 1] = group ~= 0 and group or game_group[base]
      shown[#shown + 1] = tostring(category)
    end
    for i = math.max(#t, #t4, #t5), 1, -1 do
      t[i], t4[i], t5[i] = nil, nil, nil
    end
    for i = 1, #nt do
      t[i], t4[i], t5[i] = nt[i], n4[i], n5[i]
    end
    ST.on, ST.count = true, #nt
    ST.log("tabs", #nt, table.concat(shown, " "))
  end

  --- Internal: Wraps the retail list-view icons for the skill tabs, once.
  function ST.wrap()
    if ST.wrapped or type(LISTVIEW) ~= "table" then
      return
    end
    --- Internal: true once LISTVIEW.SetupTabIcon is wrapped for the skill tabs.
    ST.wrapped = true
    local setup_icon = LISTVIEW.SetupTabIcon
    if type(setup_icon) == "function" then
      LISTVIEW.SetupTabIcon = function(layer, instance, icon_type, ...)
        local look = ST.looks[icon_type]
        if look == nil then
          return setup_icon(layer, instance, icon_type, ...)
        end
        local r = table.pack(setup_icon(layer, instance, look.icon, ...))
        if look.atlas ~= 0 and look.sprite ~= 0 then
          local target = layer or ST.TAB_ITEM
          pcall(funcLuaMenuCommand, ST.SET_SPRITE, target, look.atlas, look.sprite, ST.DMY_ON, 0, instance)
          pcall(funcLuaMenuCommand, ST.SET_SPRITE, target, look.atlas, look.sprite_off, ST.DMY_OFF, 0, instance)
        end
        return table.unpack(r, 1, r.n)
      end
    end
    local setup_text = LISTVIEW.SetupTabText
    if type(setup_text) == "function" then
      LISTVIEW.SetupTabText = function(icon_type, layer, ...)
        local look = ST.looks[icon_type]
        if look == nil then
          return setup_text(icon_type, layer, ...)
        end
        local name = nil
        if look.text_id ~= 0 then
          local ok, s = pcall(funcLuaCommand, ST.TEXT_GET, look.text_id)
          if ok and type(s) == "string" and s ~= "" then
            name = s
          end
        end
        if name == nil and look.text ~= "" then
          name = look.text
        end
        if name ~= nil then
          funcLuaMenuCommand(ST.SET_TEXT, layer or ST.TAB_BAR, ST.TAB_TEXT, name)
          return
        end
        return setup_text(look.icon, layer, ...)
      end
    end
  end

  --- Internal: Hides a spare tab instance of the skill bar; answers true when it did.
  function ST.hide_spare(layer, instance)
    if not ST.on or (layer ~= ST.TAB_ITEM and layer ~= ST.TAB_NEW) or type(instance) ~= "number"
        or instance < ST.count then
      return false
    end
    funcLuaMenuCommand(ST.VISIBLE, layer, instance, false)
    if layer == ST.TAB_ITEM then
      pcall(funcLuaMenuCommand, ST.COLLISION, layer, instance, false)
      pcall(funcLuaMenuCommand, ST.HOVER, layer, instance, false)
    end
    return true
  end

  --- Internal: Installs the skill tabs on menu `stem` through VRFW.host.
  function ST.attach(stem)
    if VRFW.host == nil then
      return
    end
    local id = "menu_engine.skill_tabs"
    VRFW.host.on(stem, "@edit", {
      id = id,
      fn = function(L)
        local ok, t, t4, t5 = pcall(function() return L.t, L.t4, L.t5 end)
        if not ok then
          ST.log(stem, "tab tables not readable:", t)
          return
        end
        ST.apply(t, t4, t5)
        if ST.on then
          ST.wrap()
        end
      end,
    })
    VRFW.host.on(stem, "OnSetupLayer", {
      id = id, phase = "around",
      fn = function(nxt, layer, instance, ...)
        if ST.hide_spare(layer, instance) then
          return
        end
        return nxt(layer, instance, ...)
      end,
    })
    VRFW.host.on(stem, "OnOpenLayer", {
      id = id, phase = "after",
      fn = function(r, layer, instance)
        ST.hide_spare(layer, instance)
      end,
    })
    VRFW.host.on(stem, "UpdateTabNewIcon", {
      id = id, phase = "around",
      fn = function(nxt, index, lit, ...)
        if ST.on and type(index) == "number" and index >= ST.count then
          lit = false
        end
        return nxt(index, lit, ...)
      end,
    })
  end

  --- Internal: Namespace of the skill tabs: extra tab icons and labels added to the skill list views.
  VRFW.skill_tabs = ST
end
