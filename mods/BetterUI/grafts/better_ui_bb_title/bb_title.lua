BetterUI = type(BetterUI) == "table" and BetterUI or {}
do
  local BB_TITLE = {
    HEADER = @crc:mainmenu90_01_header@,                         -- mainmenu90_01_header
    TITLE = @crc:_text_sub_title02@,
    CMD_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@, -- (layer, text, string, idx)
  }

  if BetterUI.bb_title_wrapped == nil then
    BetterUI.bb_title_wrapped = true
    local step = Step
    if type(step) ~= "function" then
      step = function() end
    end
    function Step(...)
      local r = table.pack(step(...))
      if type(funcLuaMenuCommand) == "function" then
        pcall(funcLuaMenuCommand, BB_TITLE.CMD_TEXT, BB_TITLE.HEADER, BB_TITLE.TITLE, "", 0)
      end
      return table.unpack(r, 1, r.n)
    end
  end
end
