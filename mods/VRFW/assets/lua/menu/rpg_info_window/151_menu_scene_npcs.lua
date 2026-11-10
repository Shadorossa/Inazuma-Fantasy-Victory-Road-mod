do
  local KEY = 1730437307 --[[crc32 vrfw_menu_scene_npcs]]
  local NPC = 3492492454 --[[crc32 NPC: the object kind of the field's NPCs]]
  local UPDATE = 183670132 --[[(kind) request the update of a kind of field object]]
  local UPDATING = 4179060571 --[[(kind) -> the objects of that kind are updating]]
  local LOAD = 2983896291 --[[the field's load step after an NPC update (NPCUpdate)]]
  local LOADING = 3451717529 --[[-> true while that load step is busy]]
  local REPORT = VRFW.commands.VRFW_MENU_SCENE_NPCS --[[CMND_VRFW_MENU_SCENE_NPCS (step, info)]]
  local STATE = VRFW.commands.VRFW_MENU_SCENE_STATE --[[CMND_VRFW_MENU_SCENE_STATE () -> …, 6th: 1 = the scene's map is up]]
  local co = nil
  local function run()
    VRFW.host.command(UPDATE, NPC)
    VRFW.host.command(REPORT, "asked", "NPC update requested")
    local f = 0
    while VRFW.host.command(UPDATING, NPC) == true and f < 600 do
      f = f + 1
      coroutine.yield()
    end
    local g = 0
    VRFW.host.command(LOAD)
    while VRFW.host.command(LOADING) == true and g < 600 do
      g = g + 1
      coroutine.yield()
    end
    VRFW.host.command(REPORT, "ready", string.format("%d frame(s) updating, %d frame(s) loading%s", f, g, (f >= 600 or g >= 600) and ", gave up" or ""))
  end
  local post = PostStep
  if type(post) == "function" then
    function PostStep(...)
      local r = table.pack(post(...))
      if co == nil then
        if VRFW.param.has(KEY) then
          local r = table.pack(VRFW.host.command(STATE))
          if r[6] == 1 then
            VRFW.param.clear(KEY)
            co = coroutine.create(run)
          end
        end
      end
      if co ~= nil and coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
          VRFW.host.command(VRFW.commands.VRFW_LOG, "menu_scene", "rpg_info_window", "NPC update error", tostring(err))
          VRFW.host.command(REPORT, "ready", "error " .. tostring(err))
        end
      end
      return table.unpack(r, 1, r.n)
    end
  end
end
