-- Menu engine file picks: VRFW.file_pick (docs/framework/file-pick.md).
-- The system's save and open dialogs for a menu coroutine: the dialog runs on its own thread and the coroutine waits for it frame by frame.
if VRFW.file_pick == nil then
  local P = {
    SAVE = VRFW.ids.crc32("CMND_VRFW_FILE_PICK_SAVE"),   -- Arguments: area, file name, extension, title; results: ticket, or nil and why.
    OPEN = VRFW.ids.crc32("CMND_VRFW_FILE_PICK_OPEN"),   -- Arguments: area, extension, title; results: ticket, or nil and why.
    STATE = VRFW.ids.crc32("CMND_VRFW_FILE_PICK_STATE"), -- Arguments: ticket; results: state, then the file name or why.
  }
  --- File windows for the player's files: open, save. Call only from OnInit, Step or another callback.
  VRFW.file_pick = P
  local log = VRFW.logger.new("VRFW file pick")

  -- Waits in the running coroutine until the dialog of `ticket` closes -> "picked", ticket, file | "cancelled" | "unavailable", why.
  local function wait(ticket)
    while true do
      local state, detail = VRFW.host.command(P.STATE, ticket)
      if state == "picked" then
        return "picked", ticket, detail
      elseif state == "cancelled" then
        return "cancelled"
      elseif state ~= "pending" then
        log("dialog", ticket, "failed:", tostring(detail))
        return "unavailable", tostring(detail)
      end
      coroutine.yield()
    end
  end

  -- VRFW.file_pick.save({area, name, ext, title}): asks where to save. Returns "picked", ticket, file, or "cancelled" / "unavailable". Write it with VRFW.files.picked_write. Call only from OnInit, Step or another callback.
  --- Asks where to save: opts = { area, name, ext, title } -> "picked", ticket, file | "cancelled" | "unavailable", why.
  -- A "picked" ticket is written once with VRFW.files.picked_write in a script; "unavailable" means the caller's own list flow runs.
  function P.save(opts)
    local ticket, why = VRFW.host.command(P.SAVE, opts.area, opts.name or "", opts.ext or "vrmod", opts.title or "")
    if type(ticket) ~= "number" then
      log("no save dialog:", tostring(why))
      return "unavailable", tostring(why)
    end
    return wait(ticket)
  end

  -- VRFW.file_pick.open({area, ext, title}): asks which file to open. Returns "picked", ticket, file, or "cancelled" / "unavailable". Read it with VRFW.files.picked_read. Call only from OnInit, Step or another callback.
  --- Asks which file to open: opts = { area, ext, title } -> "picked", ticket, file | "cancelled" | "unavailable", why.
  -- A "picked" ticket is read with VRFW.files.picked_read in a script; "unavailable" means the caller's own list flow runs.
  function P.open(opts)
    local ticket, why = VRFW.host.command(P.OPEN, opts.area, opts.ext or "vrmod", opts.title or "")
    if type(ticket) ~= "number" then
      log("no open dialog:", tostring(why))
      return "unavailable", tostring(why)
    end
    return wait(ticket)
  end
end
