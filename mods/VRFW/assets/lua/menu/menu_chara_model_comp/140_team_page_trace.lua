-- menu_engine: a 3D model view (menu_chara_model_comp) while a team page or foreign team dock is open (the team
-- editor's cross-menu param VRFW_team_editor_foreign, read here without the team editor library): its setup, camera
-- registration, first model and end logged once each per component, so the log shows how many model views are up and
-- which one takes the menu camera. Wrappers by assignment (the script has
-- no VRFW_Host host); no engine call at load.
if VRFW_TeamPageModelTrace == nil and type(Setup) == "function" and type(End) == "function" then
  local T = { LOG = VRFW_Cmd.EVT_LOG, logged = {}, id = tostring({}):match("%x+$") or "?" }
  VRFW_TeamPageModelTrace = T

  local function team_page()
    T.foreign = T.foreign or VRFW_Crc32("VRFW_team_editor_foreign")
    return VRFW_Param.Has(T.foreign)
  end

  local function log_once(step, ...)
    if T.logged[step] or not team_page() then return end
    T.logged[step] = true
    local parts = { "model view", T.id .. ":", step }
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    pcall(funcLuaCommand, T.LOG, "VRFW team editor", table.concat(parts, " "))
  end

  local setup = Setup
  Setup = function(...)
    log_once("setup")
    return setup(...)
  end

  if type(RegistCameraInfo) == "function" then
    local regist = RegistCameraInfo
    RegistCameraInfo = function(camera, ...)
      log_once("camera registered", camera)
      return regist(camera, ...)
    end
  end

  if type(ChangeCharaModel) == "function" then
    local change = ChangeCharaModel
    ChangeCharaModel = function(...)
      log_once("first model asked")
      return change(...)
    end
  end

  local finish = End
  End = function(...)
    log_once("end")
    return finish(...)
  end
end
