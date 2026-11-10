
local OPTION = "camera"
local BLOB = "camera.json"

local function take_over()
  if VRFW.options.values()[OPTION] ~= nil then
    return
  end
  local bytes = VRFW.save.doc.read_text(BLOB, "global")
  if bytes == nil then
    return
  end
  local s = VRFW.json.decode(bytes)
  local side = type(s) == "table" and s.side_view == true
  local ok, why = VRFW.options.store({ [OPTION] = side and 1 or 0 })
  if ok then
    VRFW.log("«Cámara del partido» = " .. (side and 1 or 0) .. " taken over from BetterQoL's camera.json blob (kept there too)")
  else
    VRFW.warn("cannot take over the old camera setting (" .. tostring(why) .. "): «Cámara del partido» starts at Original")
  end
end

local ok, err = pcall(take_over)
if not ok then
  VRFW.warn("camera setting take-over: " .. tostring(err))
end
