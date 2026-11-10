-- menu_engine: HUB YIELD.
if vrfw_hub_yield == nil then
  local Y = {
    LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM, VISIBLE = VRFW.commands.SET_LAYER_VISIBLE, IS_VISIBLE = VRFW.commands.IS_LAYER_VISIBLE, LOG = VRFW.commands.VRFW_LOG,
    LAYERS = {
      575058101,    -- mainmenu90_01_header (title, mode icon, currency counters)
      1138543975,   -- mainmenu01_06_base_button_guide (the prompt row)
      9396745,      -- mainmenu01_07_button_guide
      2005383485,   -- mainmenu01_10_return_arrow_button_guide
      3078308064,   -- mainmenu90_05_content_guide_line01 (the help band)
      3347475721,   -- shop01_03_token_list (the Mercado's COLECCIONABLES panel)
      3286690296,   -- shop01_04d_token_item_5dig (its currency pills)
    },
    hidden = nil,   -- {{layer, idx}, ...} hidden by the last yield
  }
  VRFW.hub_yield = Y

  --- Hides or shows the hub's layers for `by`; answers how many changed.
  function vrfw_hub_yield(on, by, extra)
    if on then
      if Y.hidden ~= nil then
        return 0
      end
      Y.hidden = {}
      local layers = {}
      for _, layer in ipairs(Y.LAYERS) do layers[#layers + 1] = layer end
      for name in tostring(extra or ""):gmatch("[^,%s]+") do layers[#layers + 1] = VRFW.crc32(name) end
      for _, layer in ipairs(layers) do
        local ok, n = pcall(funcLuaMenuCommand, Y.LAYER_NUM, layer)
        if ok and type(n) == "number" then
          for idx = 0, n - 1 do
            local okv, v = pcall(funcLuaMenuCommand, Y.IS_VISIBLE, layer, idx)
            if okv and v == true then
              pcall(funcLuaMenuCommand, Y.VISIBLE, layer, idx, false)
              Y.hidden[#Y.hidden + 1] = {layer, idx}
            end
          end
        end
      end
      pcall(funcLuaCommand, Y.LOG, "vrfw.HubYield", "hidden", #Y.hidden, "for", tostring(by))
      return #Y.hidden
    end
    local list = Y.hidden or {}
    Y.hidden = nil
    for _, e in ipairs(list) do
      pcall(funcLuaMenuCommand, Y.VISIBLE, e[1], e[2], true)
    end
    pcall(funcLuaCommand, Y.LOG, "vrfw.HubYield", "shown", #list, "for", tostring(by))
    return #list
  end
end
