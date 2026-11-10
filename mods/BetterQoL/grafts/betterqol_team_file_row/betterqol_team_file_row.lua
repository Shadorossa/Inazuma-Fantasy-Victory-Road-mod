--@lib vrfw_menu_kit.lua#Pointer
-- Team dock: the last list row holds the two half-width cells «Exportar» | «Importar» of the team file.
do
  local ACTION = { EXPORT = "export", IMPORT = "import" }
  local TEXT = {
    EXPORT_ROW = @crc:better_qol_team_file_export_row@,
    IMPORT_ROW = @crc:better_qol_team_file_import_row@,
    EXPORT_HELP = @crc:better_qol_team_file_export_help@,
    IMPORT_HELP = @crc:better_qol_team_file_import_help@,
  }
  local logger

  local function log(...)
    logger = logger or VRFW.logger.new("BetterQoL team file, dock row")
    logger(...)
  end

  -- Runs the accepted cell inside the dock's decide coroutine; the team file functions show their own windows and may wait.
  local function decide(cell)
    local team_file = type(BetterQoL) == "table" and BetterQoL.team_file or nil
    local action = type(team_file) == "table" and team_file[cell.value] or nil
    if type(action) ~= "function" then
      log("BetterQoL.team_file." .. cell.value .. " is not loaded: nothing done")
      return
    end
    local ok, changed = pcall(action)
    if not ok then
      log(cell.value, "failed:", tostring(changed))
      return
    end
    log(cell.value, "returned", tostring(changed))
    if cell.value == ACTION.IMPORT and changed == true then
      BetterQoL.team_templates.redraw_shown()
    end
  end

  VRFW.team_dock.half_rows.add({
    id = "BetterQoL.team_file",
    place = "end",
    pair = true,
    cells = {
      { value = ACTION.EXPORT, name = TEXT.EXPORT_ROW, help = TEXT.EXPORT_HELP },
      { value = ACTION.IMPORT, name = TEXT.IMPORT_ROW, help = TEXT.IMPORT_HELP },
    },
    when = function()
      return BetterQoL.team_templates.ready()
    end,
    decide = decide,
  })
end
