if VRFW.team_page_model_trace == nil and type(Setup) == "function" and type(End) == "function" then
  local T = { id = tostring({}):match("%x+$") or "?" }
  VRFW.team_page_model_trace = T

  local function team_page()
    T.foreign = T.foreign or VRFW.crc32("VRFW_team_editor_foreign")
    return VRFW.param.has(T.foreign)
  end

  local log = VRFW.logger.new("VRFW team editor")
  local function log_once(step, ...)
    if not team_page() then return end
    log.once(step, "model view", T.id .. ":", step, ...)
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
