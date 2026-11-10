do
  local change = ChangeCharaModel
  local reset = ResetCharaScale
  if type(change) == "function" and type(reset) == "function" then
    function ChangeCharaModel(...)
      local existing = select(9, ...)      -- an existing scene chara handle to rebuild
      if existing == nil or existing == 0 then
        reset()
      end
      return change(...)
    end
  end
end
