-- The Tournament: its parts in scripts\lib\tournament\ run in this order and share one context table (lib/tournament/context.lua).
local Shared = require "lib/tournament/context"
require "lib/tournament/setup"
require "lib/tournament/opponents"
require "lib/tournament/run_store"
require "lib/tournament/pools"
require "lib/tournament/start"
require "lib/tournament/match_events"
require "lib/tournament/scorers"
require "lib/tournament/commands"
require "lib/tournament/view"

return Shared.Tn
