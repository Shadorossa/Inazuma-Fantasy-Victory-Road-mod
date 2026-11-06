-- Player Training › no bean exchange («Canjear judías», beans_trade_menu). With the classic training the beans give
-- nothing and no bean is ever given (content\items\no_training_beans.toml, VR-Framework [[VRFW.MatchDropRemove]]
-- AllSources), so the exchange would take beans and give none: it is closed and its button guide is not drawn.
-- 1. The opener: MENU_DEF.OpenBeansTradeMenuCore (include menu_def: the item bag, the Mercado, the spirit list and the
--    rarity-up screen) opens nothing; the skill board's OpenBeansTradeMenu / OpenBeansTradeMenu_Coroutine (it opens the
--    menu itself) return at once.
-- 2. The button guide: the entry whose text is «Canjear judías» is hidden from every guide of every screen (the bag,
--    the Mercado, the spirit list, the rarity-up screen, the skill board) through VRFW_FooterPrompts.Hide (its text
--    and the same place of its keys).
-- Every menu VM; no engine call at chunk load; no retail function redefined.
local BEANS_TRADE_TEXT = 193274065           -- menu_text «Canjear judías»

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

if VRFW_FooterPrompts ~= nil and VRFW_FooterPrompts.Hide ~= nil then
  VRFW_FooterPrompts.Hide({Name = "ClassicTraining.NoBeanTrade", Text = BEANS_TRADE_TEXT})
end
