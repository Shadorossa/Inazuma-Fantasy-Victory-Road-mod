-- File picks: the system's save and open dialogs that the menu helper VRFW.file_pick asks for (docs/framework/file-pick.md).
FilePick = FilePick or {}

-- The flow the [files] picker value chooses: "dialog" (the system dialog, the game's own list when none can open) or "list".
local function dialog_on()
  return VRFW.files.config("files.picker") ~= "list"
end

-- CMND_VRFW_FILE_PICK_SAVE (area, file name, extension, title) answers a ticket, or nil and why when no dialog is shown.
function FilePick.Save(area, name, ext, title)
  if not dialog_on() then return nil, "the [files] picker is \"list\"" end
  return VRFW.files.pick_save({ area = area, name = name, ext = ext, title = title })
end

-- CMND_VRFW_FILE_PICK_OPEN (area, extension, title) answers a ticket, or nil and why when no dialog is shown.
function FilePick.Open(area, ext, title)
  if not dialog_on() then return nil, "the [files] picker is \"list\"" end
  return VRFW.files.pick_open({ area = area, ext = ext, title = title })
end

-- CMND_VRFW_FILE_PICK_STATE (ticket) answers "pending", "picked" and the file name, "cancelled", or "failed" and why.
function FilePick.State(ticket)
  return VRFW.files.pick_state(ticket)
end
