-- lua_patch.scope: used
-- VRFW.field_hud: a field HUD menu kept hidden under a menu scene (docs/framework/menu-scene.md).
if VRFW.field_hud == nil then
  local KEY = 3499142076
  local MINIMAP = 1868910795       -- 0x6F6550CB: the field minimap shown / hidden
  local LAYER_CALLBACKS = { "OnSetupLayer", "OnOpenLayer", "OnOpenEndLayer" }
  local STEP_CALLBACKS = { "PostStep", "Step" }

  local F = {}

  --- Internal: Hides the field HUD while scene `tag` is up; answers whether it hides.
  function F.hide_under_menu_scene(tag, while_hidden)
    local log = VRFW.logger.new("menu_scene")
    local seen, logged = {}, false

    local function off()
      return VRFW.param.has(KEY)
    end

    local function hide(a1, a2)
      if a1 == nil or not off() then
        return
      end
      seen[a1 .. ":" .. tostring(a2 or 0)] = { a1, a2 or 0 }
      VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, a1, a2 or 0, false)
      if not logged then
        logged = true
        VRFW.host.command(MINIMAP, false)
        log(tag, "field HUD hidden under the menu scene (first layer", a1, ")")
      end
    end

    for _, name in ipairs(LAYER_CALLBACKS) do
      local f = _G[name]
      if type(f) == "function" then
        _G[name] = function(a1, a2, ...)
          local r = table.pack(f(a1, a2, ...))
          hide(a1, a2)
          return table.unpack(r, 1, r.n)
        end
      end
    end

    for _, name in ipairs(STEP_CALLBACKS) do
      local f = _G[name]
      if type(f) == "function" then
        _G[name] = function(...)
          local r = table.pack(f(...))
          if while_hidden ~= nil and off() then
            while_hidden()
          end
          if next(seen) ~= nil and off() then
            for _, l in pairs(seen) do
              VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, l[1], l[2], false)
            end
          end
          return table.unpack(r, 1, r.n)
        end
        break
      end
    end
  end

  --- Internal: Namespace: the field HUD helpers of the menu VM.
  VRFW.field_hud = F
end
