-- Inazuma Fantasy, the «Rival del día» row: a match reserved from this menu plays the day's team
-- (assets\lua\_all\280_daily_legendary_rival.lua). No engine call at load time.
if VRFW_Host ~= nil and InazumaFantasyDailyRival ~= nil then
  InazumaFantasyDailyRival.PlayOnReserve()
end
