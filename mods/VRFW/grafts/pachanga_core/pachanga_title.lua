-- ===== EVT pachanga title BEGIN =====
do
  local init = OnInit
  function OnInit(...)
    local r = table.pack(init(...))
    pcall(function()
      local P = VRFW.friendly_match
      local st = P.state()
      if not (st.phase >= 1 and st.phase <= 3) then
        return
      end
      P.back(1)
    end)
    return table.unpack(r, 1, r.n)
  end
end
-- ===== EVT pachanga title END =====
