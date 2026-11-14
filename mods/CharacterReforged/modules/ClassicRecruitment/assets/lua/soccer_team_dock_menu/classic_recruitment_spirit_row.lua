-- Team dock: the option row spirit_section off takes the «Espíritu» row out of the list; the rows below move up.
if VRFW.team_dock ~= nil and VRFW.team_dock.half_rows ~= nil and type(ClassicRecruitment) == "table" then
  local SPIRIT_ROW_KIND = 1          -- The retail row kind of «Espíritu» in the dock's row kind list.

  -- The framework rebuilds the list from the retail kinds each time it is set up, so the row comes back when the option is off.
  VRFW.team_dock.half_rows.add({
    id = "ClassicRecruitment.spirit_section",
    remove = {SPIRIT_ROW_KIND},
    when = function()
      return ClassicRecruitment.holds(ClassicRecruitment.spirits_hidden)
    end,
  })
end
