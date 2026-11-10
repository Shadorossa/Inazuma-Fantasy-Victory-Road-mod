if VRFW.host ~= nil and type(ClassicRecruitment) == "table" then
  local function applies()
    return ClassicRecruitment.holds(ClassicRecruitment.applies)
  end

  VRFW.host.on("vs_route_town_command_select_menu", "IsHeroDropControlActived", {
    id = "ClassicRecruitment.idol_toggle_key", phase = "around",
    fn = function(nxt, ...)
      if applies() then
        return false
      end
      return nxt(...)
    end,
  })

  VRFW.host.on("vs_route_town_command_select_menu", "SetupButtonGuide", {
    id = "ClassicRecruitment.idol_toggle_guide", phase = "around",
    fn = function(nxt, row, ...)
      if type(row) == "table" and row.heroDropControlEnabled and applies() then
        local copy = {}
        for key, value in pairs(row) do
          copy[key] = value
        end
        copy.heroDropControlEnabled = false
        return nxt(copy, ...)
      end
      return nxt(row, ...)
    end,
  })
end
