
BetterUI = type(BetterUI) == "table" and BetterUI or {}

-- The menu chunk runs before the Lua patch files, so its BetterUI snippets queue their command hooks for VRFW.host here.
if type(BetterUI.command_hooks) == "table" and type(VRFW) == "table" and type(VRFW.host) == "table"
    and type(VRFW.host.hook_command) == "function" then
  local queued = BetterUI.command_hooks
  BetterUI.command_hooks = nil
  for _, register in ipairs(queued) do
    register(VRFW.host)
  end
end

local function global(name)
  if type(_G) == "table" then
    return rawget(_G, name)
  end
  return nil
end

local function own(name)
  return function(...)
    local f = BetterUI[name]
    if type(f) == "function" then
      return f(...)
    end
    return nil
  end
end

local function ownMember(name, key)
  return function(...)
    local t = BetterUI[name]
    if type(t) == "table" and type(t[key]) == "function" then
      return t[key](...)
    end
    return nil
  end
end

local function member(name, key)
  return function(...)
    local t = global(name)
    if type(t) == "table" and type(t[key]) == "function" then
      return t[key](...)
    end
    return nil
  end
end

BetterUI.top_bar_on = member("BetterQoL", "top_bar_on")

function BetterUI.shop_switching()
  return BetterUI.shop_leaving ~= nil
end

BetterUI.card_is_compact = own("player_card_is_compact")
BetterUI.card_hide_name = own("player_card_hide_name")
BetterUI.card_keep_name = own("player_card_keep_name")
BetterUI.card_hide_level = own("player_card_hide_level")

BetterUI.shirt_number_on = ownMember("shirt_number", "on")
BetterUI.shirt_number_arm = ownMember("shirt_number", "arm")

BetterUI.dock_buttons = type(BetterUI.dock_buttons) == "table" and BetterUI.dock_buttons or {}
function BetterUI.add_dock_button(spec)
  if type(spec) ~= "table" or type(spec.id) ~= "string" or type(spec.layer) ~= "number" then
    return false
  end
  for i, e in ipairs(BetterUI.dock_buttons) do
    if e.id == spec.id then
      BetterUI.dock_buttons[i] = spec
      return true
    end
  end
  table.insert(BetterUI.dock_buttons, spec)
  return true
end

local wrappers = {}
function BetterUI.wrap_global(env, owner, name, make)
  local own = wrappers[owner]
  if own == nil then
    own = {}
    wrappers[owner] = own
  end
  local cur = env[name]
  if type(cur) ~= "function" or own[cur] then
    return
  end
  local w = make(cur)
  own[w] = true
  env[name] = w
end

if type(ClassicCards) == "table" and type(ClassicCards.position_look_of_type) == "function"
    and ClassicCards.better_ui_position_looks == nil then
  local ownLook = ClassicCards.position_look_of_type
  local takes = nil
  ClassicCards.better_ui_position_looks = true
  ClassicCards.position_look_of_type = function(positionType)
    if takes == nil then
      takes = {}
      for t in pairs(ClassicCards.POSITION_LOOKS or {}) do
        local other = VRFW.host.command(VRFW.commands.BETTERUI_POSITION_LOOK, t)
        takes[t] = type(other) == "number" and ClassicCards.POSITION_LOOKS[other] ~= nil and other or t
      end
    end
    if positionType ~= nil and takes[positionType] ~= nil then
      positionType = takes[positionType]
    end
    return ownLook(positionType)
  end
end
