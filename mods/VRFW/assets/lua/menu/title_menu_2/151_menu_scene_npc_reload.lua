-- menu_scene (VRFW, docs/framework/menu-scene.md §2.1): the people of a menu scene after the hand-over.
do
  local NpcReload = {
    ID = "vrfw.menu_scene.npc_reload",
    STATE = VRFW.commands.VRFW_MENU_SCENE_STATE,         -- CMND_VRFW_MENU_SCENE_STATE () -> state, key, …
    SCENE = VRFW.commands.VRFW_MENU_SCENE,         -- CMND_VRFW_MENU_SCENE (key) -> table | ""
    RELOAD_NPC = VRFW.commands.RELOAD_NPC,    -- CMND_RELOAD_NPC
    LOG = VRFW.commands.VRFW_LOG,
    ASK_AT_FRAMES = { 30, 120, 300 },   -- after the scene is up (60 a second)
    ASK_AGAIN_AT_FRAMES = { 2, 60, 240 },   -- after a menu over the title gave it back
    PEOPLE = VRFW.commands.VRFW_MENU_SCENE_PEOPLE,
    AVATAR = VRFW.commands.VRFW_MENU_SCENE_AVATAR,
    MOTION_SET = VRFW.commands.VRFW_CHARA_MOTION_SET,    -- CMND_VRFW_CHARA_MOTION_SET (chara_base) -> motion set
    NPC_READ = VRFW.commands.VRFW_MENU_SCENE_NPC_READ,
    NPC_ENTRIES = VRFW.commands.VRFW_MENU_SCENE_NPC_ENTRIES,     -- CMND_VRFW_MENU_SCENE_NPC_ENTRIES (why) -> text (logged)
  }
  local frames, scene_key, people = 0, nil, false
  local asks, reason = NpcReload.ASK_AT_FRAMES, "up"
  local team_sig, scene_kind, actors = nil, nil, false
  local FollowTeam, AskAgain             -- defined below (Tick calls them)

  local probe_at = {}
  local function Probe(why)
    VRFW.host.command(NpcReload.NPC_ENTRIES, why)
  end

  local function Tick()
    local state, key = VRFW.host.command(NpcReload.STATE)
    if state ~= "up" or type(key) ~= "string" or key == "" then
      frames, scene_key = 0, nil
      return
    end
    if key ~= scene_key then
      asks, reason = NpcReload.ASK_AT_FRAMES, "up"
      scene_key, frames = key, 0
      local s = VRFW.host.command(NpcReload.SCENE, key)
      people = type(s) == "table" and (tonumber(s.spots) or 0) > 0 and (s.people or "") ~= ""
      scene_kind = type(s) == "table" and s.people or nil
      actors = type(s) == "table" and s.people_as == "actors"
      team_sig = nil
      if people then FollowTeam(key, "the scene is up") end
    end
    if not people or actors then return end
    if VRFW.host.command(NpcReload.NPC_READ) == "read" then AskAgain("the people were read again") end
    frames = frames + 1
    for _, at in ipairs(asks) do
      if frames == at then
        local ok = VRFW.host.command(NpcReload.RELOAD_NPC)
        VRFW.host.command(NpcReload.LOG, "menu_scene", "title_menu_2", "NPC reload asked", frames, "frame(s) after " .. reason .. ":", tostring(ok))
        probe_at[frames + 60] = reason
      end
    end
    if probe_at[frames] then
      Probe(string.format("%d frame(s) after %s", frames, probe_at[frames]))
      probe_at[frames] = nil
    end
  end

  AskAgain = function(why)
    asks, reason, frames = NpcReload.ASK_AGAIN_AT_FRAMES, tostring(why or "a menu over the title"), 0
    VRFW.host.command(NpcReload.LOG, "menu_scene", "title_menu_2", "people asked again:", reason)
    if scene_key and people then FollowTeam(scene_key, reason) end
  end

  -- the active team against the placed people: served again when it changed
  FollowTeam = function(key, event)
    if scene_kind ~= "active_team" or type(VRFW.menu_scene_team) ~= "function" then return end
    local members, uniform, why = VRFW.menu_scene_team()
    local sig = tostring(members) .. "|" .. tostring(uniform)
    if team_sig == nil then
      team_sig = sig
      return
    end
    if sig == team_sig then return end
    team_sig = sig
    local avatar = ""
    local base = VRFW.host.command(NpcReload.AVATAR)
    local mset = type(base) == "number" and base ~= 0 and VRFW.host.command(NpcReload.MOTION_SET, base) or nil
    if type(mset) == "string" then avatar = string.format("%.0f:%s", base % 4294967296, mset) end
    local placed, text = VRFW.host.command(NpcReload.PEOPLE, key, members, string.format("%.0f", uniform), avatar)
    VRFW.host.command(NpcReload.LOG, "menu_scene", "title_menu_2", "people: the team changed (" .. tostring(event) .. "):", why, "->",
      tostring(placed), tostring(text), "members", members)
    if tonumber(placed) and not actors then
      asks, reason, frames = NpcReload.ASK_AGAIN_AT_FRAMES, "the team changed", 0
    end
  end
  VRFW.menu_scene_people_again = function(why) pcall(AskAgain, why) end

  if VRFW.host ~= nil then
    VRFW.host.on("title_menu_2", "OnInit", {
      id = NpcReload.ID .. ".init", phase = "after",
      fn = function()
        local state, key = VRFW.host.command(NpcReload.STATE)
        if state == "up" and type(key) == "string" and key ~= "" and key == scene_key then
          pcall(AskAgain, "the title opened again")
        end
      end,
    })
    VRFW.host.on("title_menu_2", "Step", {
      id = NpcReload.ID, phase = "after",
      fn = function()
        local ok, why = pcall(Tick)
        if not ok then VRFW.host.command(NpcReload.LOG, "menu_scene", "title_menu_2", "NPC reload error", tostring(why)) end
      end,
    })
  end
end
