-- Computed values of the type `help_entry`.

local M = {}

-- The list icons the game shows by a help row's kind (help_menu UpdateListItem); 2 is the movie kind, never used here.
local ICONS = { question = 0, mouse = 1 }

-- The help row's kind for the written icon name.
function M.icon(entry)
  local kind = ICONS[entry.icon]
  if kind == nil then
    error(string.format("icon %q: use question or mouse", tostring(entry.icon)), 0)
  end
  return kind
end

return M
