
local MO = {
  STATE = VRFW.commands.VRFW_MENU_SCENE_STATE,        -- CMND_VRFW_MENU_SCENE_STATE () -> state, key, …
  SCENE = VRFW.commands.VRFW_MENU_SCENE,        -- CMND_VRFW_MENU_SCENE (key) -> table | ""
  SET = VRFW.commands.VRFW_MENU_SCENE_SET,          -- CMND_VRFW_MENU_SCENE_SET (state, arg) -> 1 | 0, state
  PEOPLE = VRFW.commands.VRFW_MENU_SCENE_PEOPLE,
  AVATAR = VRFW.commands.VRFW_MENU_SCENE_AVATAR,
  MOTION_SET = VRFW.commands.VRFW_CHARA_MOTION_SET,
  FIELD_ENTER = VRFW.commands.VRFW_FIELD_ENTER,  -- CMND_VRFW_FIELD_ENTER (key, walker, map) -> ok, code
  FIELD_LEAVE = VRFW.commands.VRFW_FIELD_LEAVE,  -- CMND_VRFW_FIELD_LEAVE ()
  MAP_JUMP = VRFW.commands.RESERVE_MAP_JUMP,
  CLOSE = VRFW.commands.CLOSE_MENU_OBJECT,
  FIELD_START = 769636339,   -- (seconds) the field start of the Kizuna dock list
  CURSOR_RPG = VRFW.commands.START_ARRAY_CURSOR_RPG,    -- CMND_START_ARRAY_CURSOR_RPG (on)
  OPTIONS = 1432246941,      -- param vrfw_menu_scene_options
  HUD_OFF = 3499142076,
  NPCS = 1730437307,
  FADE = 609722083,          -- (1 to black | 0 in, seconds)
  FADE_DONE = 2259183189,
  MENU = 1936716961,         -- setting_top_menu
  BG = 1630405233,
  ID = "VRFW.menu_scene",
}

local mo = { ours = false, co = nil, bg_ready = false, bg_idx = 0, open_end = nil, entered = false }

local MO_Log = VRFW.logger.new("menu_scene, setting_top_menu")

-- a param cleared only when it is set (the retail way)
local function MO_Clear(k)
  if VRFW.param.has(k) then
    VRFW.param.clear(k)
  end
end

local function MO_Ask(cmd, ...)
  for _ = 1, 30 do
    local r = table.pack(VRFW.host.command(cmd, ...))
    if r.n > 0 and r[1] ~= nil then
      return table.unpack(r, 1, r.n)
    end
    coroutine.yield()
  end
  return nil
end

local function MO_Fail(why)
  MO_Log("FAILED:", why, "-> Options is shown (retail)")
  if mo.entered then
    VRFW.host.command(MO.FIELD_LEAVE)
    mo.entered = false
  end
  VRFW.host.command(MO.SET, "failed", "setting_top_menu: " .. tostring(why))
  MO_Clear(MO.HUD_OFF)
  mo.ours = false
  if mo.open_end ~= nil then
    pcall(mo.open_end, MO.BG, mo.bg_idx)
  else
    VRFW.host.command(MO.FADE, 0, 0.3)
  end
end

local function MO_Team()
  if type(VRFW.menu_scene_team) ~= "function" then return "", 0, "no team reader" end
  return VRFW.menu_scene_team()
end

local function MO_Jump(sc)
  local ok, r
  if type(sc.entry_point) == "number" and sc.entry_point ~= 0 then
    ok, r = pcall(funcLuaCommand, MO.MAP_JUMP, sc.map_id, sc.entry_point, false, true)
  else
    ok, r = pcall(funcLuaCommand, MO.MAP_JUMP, sc.map_id, sc.x, sc.y, sc.z, sc.rot, false, true, false, false, false, true)
  end
  return ok and r ~= false
end

local function MO_Enter()
  local k = 0
  while not mo.bg_ready and k < 180 do
    k = k + 1
    coroutine.yield()
  end
  local state, key = MO_Ask(MO.STATE)
  if state ~= "options" and state ~= "entering" then
    MO_Fail("the scene is at " .. tostring(state) .. ", not at options")
    return
  end
  if MO_Ask(MO.SET, "entering", "setting_top_menu opened for the scene (black, never shown)") ~= 1 then
    MO_Fail("the framework refused the step entering")
    return
  end
  local sc = MO_Ask(MO.SCENE, key)
  if type(sc) ~= "table" or type(sc.map_id) ~= "number" or type(sc.field_mode) ~= "string" then
    MO_Fail("no scene data for " .. tostring(key))
    return
  end
  local members, uniform, why = "", 0, "people none"
  if sc.people == "active_team" then
    members, uniform, why = MO_Team()
  elseif sc.people == "provided" then
    members, uniform, why = sc.provided_members or "", sc.provided_uniform or 0, "scene-provided people"
  end
  local avatar = ""
  if sc.people == "active_team" then
    local base = MO_Ask(MO.AVATAR)
    local mset = type(base) == "number" and base ~= 0 and VRFW.host.command(MO.MOTION_SET, base) or nil
    if type(mset) == "string" then
      avatar = string.format("%.0f:%s", base % 4294967296, mset)
    end
  end
  local placed, text = MO_Ask(MO.PEOPLE, key, members, string.format("%.0f", uniform), avatar)
  MO_Log("people:", why, "avatar", avatar ~= "" and avatar or "none", "->", tostring(placed), tostring(text))
  local ok, code = VRFW.host.command(MO.FIELD_ENTER, sc.field_mode, 0, sc.map_id)
  if ok ~= true then
    MO_Fail("field mode " .. sc.field_mode .. " not entered (code " .. tostring(code) .. ")")
    return
  end
  mo.entered = true
  MO_Log("field mode", sc.field_mode, "on; map", sc.map, string.format("0x%08X", sc.map_id), "entry",
    (type(sc.entry_point) == "number" and sc.entry_point ~= 0) and string.format("layout point 0x%08X", sc.entry_point) or
    string.format("(%s, %s, %s) rot %s", tostring(sc.x), tostring(sc.y), tostring(sc.z), tostring(sc.rot)))
  VRFW.host.command(MO.FADE, 1, 0)                 -- already black (the title's fade): no wait
  VRFW.param.set(MO.HUD_OFF, 1)
  if tonumber(placed) and tonumber(placed) > 0 then
    VRFW.param.set(MO.NPCS, 1)
  else
    MO_Clear(MO.NPCS)
  end
  if MO_Ask(MO.SET, "loading", "map " .. tostring(sc.map) .. " jump reserved") ~= 1 then
    MO_Fail("the framework refused the step loading")
    return
  end
  local r1 = MO_Jump(sc)
  if not r1 then
    MO_Fail("the map jump to " .. tostring(sc.map) .. " was refused")
    return
  end
  mo.ours = false
  VRFW.host.command(MO.CLOSE, MO.MENU, true)
  VRFW.host.command(MO.FIELD_START, 0)
  VRFW.host.command(MO.CURSOR_RPG, true)
  local r2 = MO_Jump(sc)
  MO_Log("map jump reserved (", tostring(r1), tostring(r2), "), Options closed, field started: the map", sc.map, "loads")
end

if VRFW.host ~= nil then
  VRFW.host.on("setting_top_menu", "OnInit", {
    id = MO.ID .. ".init",
    phase = "after",
    fn = function()
      mo.ours, mo.co, mo.bg_ready, mo.bg_idx, mo.open_end, mo.entered = false, nil, false, 0, nil, false
      local marked = VRFW.param.has(MO.OPTIONS)
      local status = VRFW.host.command(MO.STATE)
      if marked or status == "options" or status == nil then
        MO_Clear(MO.OPTIONS)
        mo.ours = true
        mo.co = coroutine.create(function()
          if not marked and status == nil then
            status = MO_Ask(MO.STATE)
            if status ~= "options" then
              mo.ours = false
              if mo.open_end ~= nil then pcall(mo.open_end, MO.BG, mo.bg_idx) end
              return
            end
          end
          MO_Enter()
        end)
        MO_Log("opened for a menu scene: kept black, the field mode and the map follow")
      end
    end,
  })
  VRFW.host.on("setting_top_menu", "OnOpenEndLayer", {
    id = MO.ID .. ".no_fade_in",
    phase = "around",
    fn = function(nxt, a1, a2, ...)
      if mo.ours and a1 == MO.BG then
        mo.bg_ready, mo.bg_idx, mo.open_end = true, a2 or 0, nxt
        return
      end
      return nxt(a1, a2, ...)
    end,
  })
  VRFW.host.on("setting_top_menu", "Step", {
    id = MO.ID .. ".step",
    phase = "after",
    fn = function()
      if mo.co == nil then
        return
      end
      local ok, err = coroutine.resume(mo.co)
      if not ok then
        mo.co = nil
        MO_Fail("error " .. tostring(err))
      elseif coroutine.status(mo.co) == "dead" then
        mo.co = nil
      end
    end,
  })
end
