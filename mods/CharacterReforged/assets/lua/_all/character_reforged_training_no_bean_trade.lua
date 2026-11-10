local BEANS_TRADE_TEXT = 193274065

local function nothing()
  return nil
end

if type(MENU_DEF) == "table" and type(MENU_DEF.OpenBeansTradeMenuCore) == "function" then
  MENU_DEF.OpenBeansTradeMenuCore = nothing
end
if type(OpenBeansTradeMenu) == "function" then
  OpenBeansTradeMenu = nothing
end
if type(OpenBeansTradeMenu_Coroutine) == "function" then
  OpenBeansTradeMenu_Coroutine = nothing
end

if VRFW.footer_prompts ~= nil and VRFW.footer_prompts.hide ~= nil then
  VRFW.footer_prompts.hide({name = "CharacterReforged.NoBeanTrade", text = BEANS_TRADE_TEXT})
end
