-- host table of the shared player page (research/grafts/plate_pages)
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.PLAYER_PAGE_HOST = {name = "personal_plate_menu", plate = 1844915256, status = 730911947, graph = 1572892955,
  radar = 3868632847, pages = true,
  universe = true --[[its formation include defines IsUniverseCharaMode (the players-universe temp chara)]],
  menu = 1427722143 --[[personal_plate_menu: its close state stops the page's drawing]]}
