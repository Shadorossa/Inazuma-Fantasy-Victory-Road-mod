do
  local MENU = VRFW.commands.VRFW_MODE_CURRENT_MENU

  local script = type(VRFW.patch) == "table" and VRFW.patch.script or nil
  local stem = type(script) == "string" and (script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "")) or nil

  local function report()
    if stem ~= nil then pcall(funcLuaCommand, MENU, stem) end
  end

  if stem ~= nil then
    local init = OnInit
    if type(init) == "function" then
      OnInit = function(...)
        local r = table.pack(init(...))
        report()
        return table.unpack(r, 1, r.n)
      end
    end
    local VH = VRFW.host
    if type(VH) == "table" and type(VH.on) == "function" then
      pcall(VH.on, stem, "OnInit", {id = "VRFW.mode_menus", phase = "after", fn = function(r, ...)
        report()
      end})
    end
  end
end
