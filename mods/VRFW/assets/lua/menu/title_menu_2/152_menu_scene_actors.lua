-- menu_scene (VRFW, docs/framework/menu-scene.md "Scene actors"): a scene's people as scene characters.
do
  local A = {
    ID = "vrfw.menu_scene.actors",
    STATE = VRFW.commands.VRFW_MENU_SCENE_STATE,          -- CMND_VRFW_MENU_SCENE_STATE () -> state, key
    ACTORS = VRFW.commands.VRFW_MENU_SCENE_ACTORS,
    CREATE = VRFW.commands.CREATE_SCN_CHARA,
    KIT_CREATE = 3201418067,
                                 -- CMND_CREATE_SCN_CHARA arguments, the name's identity (14), ..., the uniform (18)
    LOOK_ID = 347353059,
    BUILDING = 72150831,         -- (handle) -> true while the character is still being built
    FADE = 2558183053,
    SHOW = 1890282463,           -- (handle, true)
    MOTION = 3429940381,
    FACE_HOLD = VRFW.commands.VRFW_SCN_CHARA_FACE_HOLD,
    EDGE = VRFW.commands.VRFW_SCN_CHARA_EDGE,
    EDGE_PIXEL = 4.0,            -- the selected actor's edge width (pixels)
    UNIFORM_KINDS = { field = 0, keeper = 10 }, -- an actor's uniform_kind -> argument 20 of the kit create
    POSE_START = 0.5,
    DELETE = 2054212170,         -- (handle)
    MOTION_PACK = VRFW.commands.VRFW_SCN_CHARA_MOTION_PACK,
    FACIAL = VRFW.commands.VRFW_SCN_CHARA_FACIAL_DEFAULT,
                                 -- again (CMND_SET_MOTION_FACIAL(chara, 0) by handle)
    FACE_PROBE = VRFW.commands.VRFW_SCN_CHARA_FACE_PROBE,
    PROBE_DELAY = 90,
    PROBE_MAX = 6,               -- face probes per title opening
    HANDLES = VRFW.commands.VRFW_MENU_SCENE_ACTOR_HANDLES,
                                 -- the framework ("handle=id|...") for a title that opens again over the same run
    IS_PLAYING = VRFW.commands.GET_IS_PLAY_MOTION,     -- CMND_GET_IS_PLAY_MOTION (object, clip) -> playing
    OBJECT_OF = 117654406,
    BUILD_FRAMES = 600,          -- an actor not built after these frames is made again
    RETRIES = 3,                 -- makes again of an actor whose create or build failed
    RETRY_GAP = 30,
    CHECK_AT = { 5, 20, 60 },
    SHOW_AFTER = 10,
    UNVEIL_FRAMES = 3,
                                 -- it fades in: a hidden character's face is not updated, so its first visible frame showed the clip's open mouth
    STAGGER = 37,
                                 -- people standing together do not move in sync
    GATE_FRAMES = 240,
  }
  local st = { key = nil, sig = nil, actors = {}, order = {}, leaving = {}, batch = {}, revealed = false, frames = 0, logged = 0,
    people = false, actor_type = 1, probe_in = nil, probe_why = nil, probes = 0 }

  local function F(...)
    local r = table.pack(pcall(funcLuaCommand, ...))
    if not r[1] then return nil, r[2] end
    return table.unpack(r, 2, r.n)
  end
  local capped_logger = VRFW.logger.new("menu_scene, title_menu_2, actors")
  local function Log(...)
    if st.logged < 300 then
      st.logged = st.logged + 1
      capped_logger(...)
    end
  end
  local function Hex(v) return VRFW.ids.hex_text(v) end

  local function Keep()
    if not st.key then return end
    local parts = {}
    for _, a in pairs(st.actors) do
      if a.handle then parts[#parts + 1] = string.format("%.0f=%s", a.handle, a.id) end
    end
    for _, a in pairs(st.leaving) do
      if a.handle then parts[#parts + 1] = string.format("%.0f=%s", a.handle, a.id) end
    end
    F(A.HANDLES, st.key, table.concat(parts, "|"))
  end

  -- a title opened again over the same run: the actors the last one made are taken over (shown ones stay shown)
  local function Adopt(r)
    local text = F(A.HANDLES, st.key)
    if type(text) ~= "string" or text == "" then return end
    local entries = {}
    for i = 1, tonumber(r.n) or 0 do
      local g = r[i]
      if g.id then entries[g.id] = { g = g, index = i } end
    end
    local adopted, dropped = 0, 0
    for h, id in text:gmatch("(%d+)=([^|]+)") do
      local e = entries[id]
      if e and not st.actors[id] then
        st.actors[id] = { id = id, g = e.g, index = e.index, tries = 1, handle = tonumber(h), phase = "shown", age = 0 }
        adopted = adopted + 1
      else
        F(A.DELETE, tonumber(h))
        dropped = dropped + 1
      end
    end
    if adopted > 0 then st.revealed = true end
    Log("taken over from the last title:", adopted, "actor(s),", dropped, "deleted")
  end

  local function Delete(a, why)
    if a.handle and a.handle ~= 0 then
      F(A.DELETE, a.handle)
      Log("deleted", a.handle, a.id, "(" .. why .. ")")
    end
    a.handle = nil
  end

  local function DeleteAll(why)
    for _, a in pairs(st.actors) do Delete(a, why) end
    for _, a in pairs(st.leaving) do Delete(a, why) end
    st.actors, st.order, st.leaving, st.sig, st.dirty, st.batch = {}, {}, {}, nil, true, {}
  end

  local function Create(g, index)
    -- the spot's facing is in degrees; the create takes radians
    local rot = math.rad(tonumber(g.rot) or 0)
    local kit = tonumber(g.uniform) or 0
    local h, how
    if tonumber(g.uniform) ~= nil then
      local identity = tonumber(g.slot) or index
      local kind = A.UNIFORM_KINDS[tostring(g.uniform_kind)] or A.UNIFORM_KINDS.field
      h = F(A.KIT_CREATE, g.base, st.actor_type, g.x, g.y, g.z, 0, rot, 0, 9, true, false, 0, false, identity, 6, false, 255, kit,
        0xFFFF, kind, false, 0, 0, false, false, true, false)
      how = "kit " .. Hex(kit)
    end
    if type(h) ~= "number" or h == 0 then
      local tries = { { "chara_base", g.base } }
      local look = F(A.LOOK_ID, g.base, false)
      if look ~= nil and look ~= g.base then tries[#tries + 1] = { "look id", look } end
      for _, t in ipairs(tries) do
        h = F(A.CREATE, t[2], st.actor_type, g.x, g.y, g.z, 0, rot, 0, 9, true, false, 0, false, 0, 6)
        how = t[1] .. (kit ~= 0 and " (the kit create gave nothing)" or "")
        if type(h) == "number" and h ~= 0 then break end
      end
    end
    if type(h) ~= "number" or h == 0 then return nil, how end
    F(A.FADE, h, 0, 0, true)
    local okp, why = F(A.MOTION_PACK, h, g.set)
    if okp ~= true then Log("motion pack", h, tostring(g.set), "not attached:", tostring(why)) end
    return h, how
  end

  local function Make(a)
    a.tries, st.dirty = a.tries + 1, true
    a.handle, a.how = Create(a.g, a.index)
    a.phase, a.age, a.built_at, a.posed, a.check, a.settled_at = "building", 0, nil, false, nil, nil
    a.object, a.replayed = nil, false
    Log("create", a.id, "try", a.tries, "->", tostring(a.handle), a.how or "")
    if not a.handle then a.phase, a.wait = "retry", A.RETRY_GAP end
    if not a.handle and a.tries > A.RETRIES then a.phase = "failed" end
  end

  local function Retry(a, why)
    Delete(a, why)
    if a.tries > A.RETRIES then
      a.phase = "failed"
      Log("gave up", a.id, "after", a.tries, "tries:", why)
    else
      a.phase, a.wait = "retry", A.RETRY_GAP
    end
  end

  local function Sync(r)
    local want, order = {}, {}
    for i = 1, tonumber(r.n) or 0 do
      local g = r[i]
      local id = g.id or string.format("%d:%.0f:%.0f", i, tonumber(g.base) or 0, tonumber(g.kit) or 0)
      want[id] = { g = g, index = i }
      order[#order + 1] = id
    end
    local kept, made, gone = 0, 0, 0
    for id, a in pairs(st.actors) do
      if not want[id] then
        gone = gone + 1
        st.actors[id] = nil
        if a.phase == "shown" and a.g.slot ~= nil then
          local old = st.leaving[a.g.slot]
          if old then Delete(old, "replaced twice") end
          st.leaving[a.g.slot] = a
        else
          Delete(a, "no longer in the list")
        end
      end
    end
    for _, id in ipairs(order) do
      if st.actors[id] then
        kept = kept + 1
      else
        local w = want[id]
        local a = { id = id, g = w.g, index = w.index, tries = 0 }
        st.actors[id] = a
        Make(a)
        made = made + 1
        st.batch[#st.batch + 1] = id
      end
    end
    local slots = {}
    for _, a in pairs(st.actors) do
      if a.g.slot ~= nil then slots[a.g.slot] = true end
    end
    for slot, a in pairs(st.leaving) do
      if not slots[slot] then
        Delete(a, "its spot is empty now")
        st.leaving[slot] = nil
      end
    end
    st.order, st.sig = order, r.sig
    Log("list:", #order, "actor(s):", kept, "kept,", made, "made,", gone, "gone")
  end

  -- one actor's steps: build, pose once, check, ready
  local function Advance(a)
    if a.phase == "retry" then
      a.wait = (a.wait or 0) - 1
      if a.wait <= 0 then Make(a) end
      return
    end
    if not a.handle or a.phase == "failed" then return end
    a.age = a.age + 1
    if a.phase == "building" then
      if F(A.BUILDING, a.handle) == true then
        if a.age >= A.BUILD_FRAMES then Retry(a, "not built after " .. a.age .. " frames") end
        return
      end
      a.phase, a.built_at = "posing", a.age
      return
    end
    if a.phase ~= "posing" then return end
    local since = a.age - a.built_at - (a.index * 13) % A.STAGGER
    local list = type(a.g.clip_list) == "table" and a.g.clip_list or { a.g.clip }
    local pose = list[1] or a.g.clip
    if not a.posed and since >= 1 then
      a.posed, a.check = true, 1
      F(A.MOTION, a.handle, pose, 0, 0, 0, 0, A.POSE_START)
    end
    local at = A.CHECK_AT[a.check or 1]
    if a.posed and not a.settled_at and at and since >= at then
      a.check = (a.check or 1) + 1
      if a.object == nil then
        local ok, object = F(A.OBJECT_OF, a.handle)
        a.object = (ok == true and type(object) == "number" and object ~= 0) and object or false
      end
      local playing = a.object and F(A.IS_PLAYING, a.object, pose) == true
      if playing then
        a.settled_at = a.age
        if a.g.face == "default" or a.g.hold_face == true then
          local lip, why, held, hwhy = nil, "not asked", nil, "not asked"
          if a.g.face == "default" then lip, why = F(A.FACIAL, a.handle) end
          if a.g.hold_face == true then held, hwhy = F(A.FACE_HOLD, a.handle, true) end
          Log("face", a.id, a.handle, "default ->", type(lip) == "number" and Hex(lip) or ("not set: " .. tostring(why)),
            held and "held" or ("not held: " .. tostring(hwhy)))
        end
      elseif not a.replayed then
        a.replayed = true
        F(A.MOTION, a.handle, pose, 0, 0, 0, 0, A.POSE_START)
        Log("pose", a.id, Hex(pose), "not playing at frame", since, "(object", tostring(a.object), "): played once more")
      elseif not A.CHECK_AT[a.check] then
        a.settled_at = a.age
        Log("pose", a.id, Hex(pose), "not confirmed after", since, "frames (object", tostring(a.object), "): kept")
      end
    end
    if a.settled_at and a.age - a.settled_at >= A.SHOW_AFTER then a.phase = "ready" end
  end

  local function Show(a)
    F(A.SHOW, a.handle, true)
    if a.g.face == "default" then F(A.FACIAL, a.handle) end
    a.phase, a.unveil_at = "unveiling", st.frames
  end

  local function Unveil()
    for _, id in ipairs(st.order) do
      local a = st.actors[id]
      if a and a.phase == "unveiling" and st.frames - a.unveil_at >= A.UNVEIL_FRAMES then
        F(A.FADE, a.handle, 1, 1, true)
        a.phase, st.dirty = "shown", true
        local old = a.g.slot ~= nil and st.leaving[a.g.slot]
        if old then
          Delete(old, "replaced by " .. a.id)
          st.leaving[a.g.slot] = nil
        end
      end
    end
  end

  local function Unveiling()
    for _, a in pairs(st.actors) do
      if a.phase == "unveiling" then return true end
    end
    return false
  end

  -- the face probe: one kit-created actor and one other, logged by the framework (shot changes and the reveal)
  local function Probe()
    local kit, other
    for _, id in ipairs(st.order) do
      local a = st.actors[id]
      if a and a.phase == "shown" and a.handle then
        if a.g.uniform ~= nil then kit = kit or a else other = other or a end
      end
    end
    for _, a in ipairs({ kit or false, other or false }) do
      if a then
        local text, why = F(A.FACE_PROBE, a.handle, st.probe_why)
        Log("face probe", st.probe_why, a.id, type(text) == "string" and "logged" or ("failed: " .. tostring(why)))
      end
    end
  end

  local function ArmProbe(why)
    if st.probes >= A.PROBE_MAX or not st.revealed then return end
    st.probes, st.probe_in, st.probe_why = st.probes + 1, A.PROBE_DELAY, why
  end

  local function Tick()
    local state, key = F(A.STATE)
    local live = (state == "up" or state == "switching") and type(key) == "string" and key ~= ""
    if not live or key ~= st.key then
      if next(st.actors) or next(st.leaving) then DeleteAll(live and "another scene" or "the scene is not up") end
      st.key, st.sig, st.revealed, st.frames, st.people = live and key or nil, nil, false, 0, false
      if not live then return end
    end
    local r = F(A.ACTORS, key)
    if type(r) ~= "table" then
      if next(st.actors) or next(st.leaving) then DeleteAll("no actor list") end
      st.people = false
      return
    end
    st.people = r.people == 1
    st.actor_type = r.actor_type == 2 and 2 or 1
    if r.sig ~= st.sig then
      if st.sig == nil and not next(st.actors) then Adopt(r) end
      Sync(r)
      st.dirty = true
    end
    st.frames = st.frames + 1
    if st.probe_in then
      st.probe_in = st.probe_in - 1
      if st.probe_in <= 0 then
        st.probe_in = nil
        Probe()
      end
    end
    for _, id in ipairs(st.order) do Advance(st.actors[id]) end
    Unveil()
    if st.revealed then
      if #st.batch == 0 then return end
      local ready, failed = {}, {}
      for _, id in ipairs(st.batch) do
        local a = st.actors[id]
        if a then
          if a.phase == "ready" then
            ready[#ready + 1] = a
          elseif a.phase == "failed" then
            failed[#failed + 1] = id
          else
            return
          end
        end
      end
      for _, a in ipairs(ready) do Show(a) end
      Log(string.format("change shown together: %d/%d", #ready, #st.batch),
        #failed > 0 and ("failed: " .. table.concat(failed, " ")) or "")
      st.batch = {}
      return
    end
    -- the first set: all together, once each is ready or given up (or the gate's time is over)
    local ready, failed, waiting = 0, {}, 0
    for _, id in ipairs(st.order) do
      local a = st.actors[id]
      if a.phase == "ready" then
        ready = ready + 1
      elseif a.phase == "failed" then
        failed[#failed + 1] = a.id
      else
        waiting = waiting + 1
      end
    end
    if waiting > 0 and st.frames <= A.GATE_FRAMES then return end
    for _, id in ipairs(st.order) do
      local a = st.actors[id]
      if a.phase == "ready" then Show(a) end
    end
    st.revealed, st.batch = true, {}
    ArmProbe("reveal")
    Log(string.format("shown: %d/%d after %d frames", ready, #st.order, st.frames),
      #failed > 0 and ("failed: " .. table.concat(failed, " ")) or "",
      waiting > 0 and (waiting .. " still loading (each shown when ready)") or "")
  end

  -- an actor by its spot slot, for the title's hotspots and the mods: the handle (nil = none shown), its edge, a clip
  local function ActorOf(slot)
    for _, a in pairs(st.actors) do
      if a.g and a.g.slot == slot and a.handle and a.phase == "shown" then return a end
    end
  end
  VRFW.menu_scene = VRFW.menu_scene or {}
  --- Internal: handle of the actor in slot; answers a handle or nil.
  function VRFW.menu_scene.actor_handle(slot)
    local a = ActorOf(slot)
    return a and a.handle or nil
  end
  -- Advanced: the actor's white edge on (the game's character outline: its CCharaEdgeProperty) or back to its own
  function VRFW.menu_scene.actor_edge(slot, on)
    local a = ActorOf(slot)
    if not a then return false end
    local text, why = F(A.EDGE, a.handle, on == true, 1, 1, 1, 1, A.EDGE_PIXEL)
    Log("edge", a.id, on and "on" or "off", tostring(text or why))
    return text ~= nil
  end
  --- Advanced: Deletes the actor of slot so the next step builds it again (slot); answers true, or false when no such actor.
  function VRFW.menu_scene.actor_rebuild(slot)
    local a = ActorOf(slot)
    if not a then return false end
    Delete(a, "rebuilt")
    st.actors[a.id] = nil
    st.sig = nil                                             -- the next step makes it again from the same list
    return true
  end
  -- Advanced: the actor hidden (on = false) or shown again
  function VRFW.menu_scene.actor_show(slot, on)
    local a = ActorOf(slot)
    if not a then return false end
    F(A.FADE, a.handle, on and 1 or 0, on and 1 or 0, true)
    return true
  end
  --- Advanced: Plays a motion on the actor of slot (slot, clip, next_clip, blend); answers true, or false when no such actor.
  function VRFW.menu_scene.actor_motion(slot, clip, next_clip, blend)
    local a = ActorOf(slot)
    if not a then return false end
    F(A.MOTION, a.handle, clip, next_clip or 0, blend or 0.2)
    return true
  end

  -- the scene's reveal waits for the first set of people actors (at most GATE_FRAMES)
  local can_reveal_before = VRFW.menu_scene.can_reveal
  VRFW.menu_scene.can_reveal = function(key)
    if type(can_reveal_before) == "function" and can_reveal_before(key) ~= true then return false end
    if st.people and st.key == key and (not st.revealed or Unveiling()) and st.frames <= A.GATE_FRAMES then return false end
    return true
  end

  -- a shot change (the framework's mode focus event) arms the face probe
  if VRFW.menu_scene and VRFW.menu_scene.on then
    VRFW.menu_scene.on("mode_focused", A.ID .. ".probe", function(index) ArmProbe("shot " .. tostring(index)) end)
  end

  if VRFW.host ~= nil then
    VRFW.host.on("title_menu_2", "OnInit", { id = A.ID .. ".init", phase = "after", fn = function() st.logged, st.probes = 0, 0 end })
    VRFW.host.on("title_menu_2", "Step", { id = A.ID, phase = "after", fn = function()
      local ok, why = pcall(Tick)
      if not ok then capped_logger("error", tostring(why)) end
      if st.dirty then
        st.dirty = false
        pcall(Keep)
      end
    end })
  end
end
