-- The Draft: its parts in scripts\lib\draft\ run in this order and share one context table (lib/draft/context.lua).
local Shared = require "lib/draft/context"
require "lib/draft/setup"
require "lib/draft/pool"
require "lib/draft/rows"
require "lib/draft/picks"
require "lib/draft/session"
require "lib/draft/filters"
require "lib/draft/commands"
require "lib/draft/screen"

return Shared.D
