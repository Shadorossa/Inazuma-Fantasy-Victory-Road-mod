
local ok, cfg = pcall(function()
  return VRFW.config("skill_board")
end)
if ok and type(cfg) == "table" and cfg.armour_without_item ~= nil then
  VRFW.log("skill_board: [skill_board] armour_without_item = " .. tostring(cfg.armour_without_item)
    .. " is ignored: the armour slot without the item belongs to the skill set's mod now")
end
