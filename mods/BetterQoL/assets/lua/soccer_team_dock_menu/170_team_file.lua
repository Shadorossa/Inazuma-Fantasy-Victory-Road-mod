-- Team dock: the windows of the «Exportar | Importar» row (BetterQoL.team_file.export / import, run by the row's decide).
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if VRFW.host ~= nil and BetterQoL.team_file == nil then
  local STEM = "soccer_team_dock_menu"
  local TEXT_GET = 4074371074        -- CMND_TEXT_GET (text id) -> text
  local F = {}
  BetterQoL.team_file = F

  local function log(...)
    F.log = F.log or VRFW.logger.new("BetterQoL team file")
    F.log(...)
  end

  -- The id of host command `name` of the team file script.
  local function command(name)
    return VRFW.ids.crc32("CMND_BETTERQOL_TEAM_FILE_" .. name)
  end

  -- The text of row `key` with each %s replaced by the next of the given values.
  local function text(key, ...)
    local values, used = { ... }, 0
    local row = VRFW.host.command(TEXT_GET, VRFW.ids.crc32("better_qol_team_file_" .. key))
    if type(row) ~= "string" then return key end
    row = row:gsub("%%s", function()
      used = used + 1
      return tostring(values[used] or "")
    end)
    return row
  end

  -- The team set the dock shows (the retail script's own local).
  local function shown_team_set()
    local host = VRFW.host.hosts ~= nil and VRFW.host.hosts[STEM] or nil
    return host ~= nil and host.L ~= nil and host.L.n5 or nil
  end

  --- Writes the shown team to a share file (where the player picks it in the save dialog) and tells the player where it went.
  function F.export()
    local set = shown_team_set()
    if VRFW.host.command(command("EMPTY"), set) == true then
      VRFW.question.notice(text("export_empty"))
      return false
    end
    local name, area = VRFW.host.command(command("NAME"), set)
    local result, ticket = VRFW.file_pick.save({ area = area, name = name, ext = "vrmod", title = text("export_title") })
    if result == "cancelled" then return false end
    local ok, file, written_area = VRFW.host.command(command("EXPORT"), set, result == "picked" and ticket or nil)
    if ok ~= true then
      log("export refused:", tostring(file))
      VRFW.question.notice(text("export_fail"))
      return false
    end
    local shown = written_area ~= nil and ("modloader_exports/" .. tostring(written_area) .. "/" .. tostring(file)) or tostring(file)
    VRFW.question.notice(text("export_done", shown))
    return true
  end

  -- The listed team file the player takes, offered newest first with one question each; nil when none is taken.
  local function chosen_from_list()
    local count, area = VRFW.host.command(command("LIST"))
    if type(count) ~= "number" or count < 1 then
      VRFW.question.notice(text("import_none", "modloader_exports/" .. tostring(area or "")))
      return nil
    end
    for index = 0, count - 1 do
      local _, label = VRFW.host.command(command("ENTRY"), index)
      if VRFW.question.ask(text("import_ask", index + 1, count, tostring(label or ""))) then
        return index
      end
    end
    return nil
  end

  --- Writes a team file into the shown team (picked in the open dialog, or from the game's list without one); true when the team changed.
  function F.import()
    local set = shown_team_set()
    local _, area = VRFW.host.command(command("NAME"), set)
    local result, ticket = VRFW.file_pick.open({ area = area, ext = "vrmod", title = text("import_title") })
    if result == "cancelled" then return false end
    local chosen = -1
    if result ~= "picked" then
      ticket = nil
      chosen = chosen_from_list()
      if chosen == nil then return false end
    end
    local readable, checksum_ok, missing_mods, team_name = VRFW.host.command(command("CHECK"), chosen, ticket)
    if readable ~= true then
      log("import refused:", tostring(checksum_ok))
      VRFW.question.notice(text("import_fail"))
      return false
    end
    if checksum_ok ~= true and not VRFW.question.ask(text("import_checksum")) then return false end
    if type(missing_mods) == "string" and missing_mods ~= "" then
      VRFW.question.notice(text("import_missing_mods", missing_mods))
    end
    if VRFW.host.command(command("EMPTY"), set) ~= true and not VRFW.question.ask(text("import_overwrite", tostring(team_name or ""))) then
      return false
    end
    local ok, placed, skipped, skipped_names, kept = VRFW.host.command(command("APPLY"), chosen, set, ticket)
    if ok ~= true then
      log("import failed:", tostring(placed))
      VRFW.question.notice(text("import_fail"))
      return false
    end
    VRFW.question.notice(text("import_done", placed))
    if type(skipped) == "number" and skipped > 0 then
      VRFW.question.notice(text("import_skipped", tostring(skipped_names)))
    end
    if type(kept) == "number" and kept > 0 then
      VRFW.question.notice(text("import_kept", kept))
    end
    return true
  end
end
