-- Miximax creation scene, one-model view
if rawget(_ENV, "AllMiximaxed_SceneModel") == nil then
  AllMiximaxed_SceneModel = {
    LAYER = 2255041871,                              -- rpg99_99_chara_model_only_view
    READY = 2565877806,                              -- character_reforged_miximax_scene_model_ready
    LOADED = 1583438030,                             -- (layer, inst, slot) -> the model is loaded
    watch = 0,
  }

  function CharacterReforged_MiximaxSceneModelBegin()
    local Model = AllMiximaxed_SceneModel
    VRFW.param.clear(Model.READY)
    pcall(funcLuaMenuCommand, 711242136 --[[CMND_SET_LAYER_VISIBLE]], Model.LAYER, 0, false)
    Model.watch = 0
    return true
  end

  function CharacterReforged_MiximaxSceneModelCmd(cmd, ...)
    local Model = AllMiximaxed_SceneModel
    local ok = pcall(funcLuaMenuCommand, cmd, Model.LAYER, 0, ...)
    pcall(funcLuaMenuCommand, 711242136 --[[CMND_SET_LAYER_VISIBLE]], Model.LAYER, 0, false)
    return ok
  end

  function CharacterReforged_MiximaxSceneModelWatch()
    AllMiximaxed_SceneModel.watch = 1
    return true
  end

  AllMiximaxed_SceneModel.previous_step = Step
  function Step(...)
    local Model = AllMiximaxed_SceneModel
    local r
    if Model.previous_step ~= nil then
      r = Model.previous_step(...)
    end
    if Model.watch ~= 0 then
      Model.watch = Model.watch + 1
      local ok, ready = pcall(funcLuaMenuCommand, Model.LOADED, Model.LAYER, 0, 0)
      if (ok and ready == true and Model.watch > 3) or Model.watch > 600 then
        VRFW.param.set(Model.READY, (ok and ready == true) and 1 or 2)
        Model.watch = 0
      end
    end
    return r
  end
end
