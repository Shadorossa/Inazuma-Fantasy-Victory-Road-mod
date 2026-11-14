# Duel power counter (BetterUI)

During the cut-ins of a focus duel decided by a **special move**, a **Power Charge** or a **Power Block**, each side's
total shows on the same two plates as the shot zone's «TOTAL AT» / «PP»: left the player's side, right the rival's, the
total on its ribbon, the player's 3D bust at the plate's end. A side without a command
has no plate. Plain line duels show nothing.

## 1. Where the game decides the duel (nie.exe v7.2.1)

`FocusMgr::Update 0x15114A0`, sub-state `ctx+0xCFD`:

* 6..10: the two sides choose their commands (slots `ctx + 0xC44 + side x 0x30`).
* **0xB: `ResolveSkillClash 0x15056C0(ctx)`** computes both powers with `PowerCalc 0x14FC450` and posts the result with
  `0x1508FD0(ctx, block, 1)`, before the cut-ins.
* 0xC: kind `ctx+0xB08` (5 a special move won, 6 a power action won, 9 no clash). `ctx+0xAEF` = both sides have a command.
* 0xD: only with both commands: `HudLayerGroupsClose 0x112AC00(0x6D, 1)`, then `OpenAndSetupVSSkillTelop`. 0xF: coach mode:
  `SetupFieldSkillPopup`. Otherwise straight to 0x11.
* 0x11..0x13: the performance. 0x14: `ExecResult 0x150D3F0` (`duel_won` / `duel_lost`).

Result block (`rbp - 0x30` at the hook): `+0x00` winner side, `+0x28` winner power, `+0x48` loser power, `+0x68` kind. The
powers are the values the resolver compared (x 1e-4, truncated), with every modifier of `PowerCalc` (auras, Furor, stat
rules). A side without a command has power 0.

## 2. Display

* The zone's plates are retail (`soccer_zone_menu`, `SetATKPTelopTotalAT/KP`, engine `0x1543A60`) and stay as they are. The
  duel counter uses the same objects (`soccer10_25_breach_save_probability_telop` / `_enemy`) and BetterUI's layout.
* Screen `betterui_power_counter_menu`: a copy of `soccer_shoot_catch_info_menu` plus the crit-tag layer
  (`content\menus\duel_readout.toml`). `ShowCounter(plate rules, value)` is the one display function of both plates.
* `scripts\duel_readout.lua`: the hook keeps the result; each `cutin_start` until the result is applied opens the screen
  and its `cutin_end` closes it one tick later (a next cut-in in the same frame keeps it open). The clash banner shows
  nothing. A duel with no cut-in shows nothing. `duel_won` and `match_end` end the duel. The screen asks
  `CMND_BETTERUI_DUEL_READOUT` once per opening and closes itself after 15 s if no closing event came.
* Placeholder: the total's mesh (`_num_br_total_at01_dmy01` left, `_num_br_total_at02_dmy01` right) is a retail all-white
  16 x 16 sprite stretched to 51 x 51; `ShowCounter` hides it, as for every number with a placeholder.
* **Busts.** Each plate shows its player's live 3D capture on the retail portrait mesh (`_icon_br_chr_dmy01` / `02`), as
  the zone's banner: the same object (`soccer10_25_*`: `CMenuCharaModelComponent` with `m_isEnableCapture`, 2 models,
  camera 94068733) and the order of `soccer_zone_menu` `UpdateATKPTelopCharaIcon` (`SetupBust`). The handle comes from the
  command slot's `+0` through `CMND_BETTERUI_DUEL_READOUT`. Slot and turn are retail (left 0 / 30, right 1 / -30). The
  capture keys are this screen's (`crc32` of `betterui_duel_bust_left` / `_right`); a new key takes a new capture cell. The
  mesh stays hidden until `1583438030(layer, instance, slot)` answers true plus `bust_settle_frames`, checked in the
  screen's `Step` (an empty cell draws white). No handle, no plate or a failed setup (in a `pcall`, after the digits) =
  the mesh stays hidden and the readout stays. No `capture_bind`: it holds one key only.
* **Digits.** The game centres a total's digits on its node (`_num_total_at01` / `_at02`). Retail places that node 424 /
  358 px into the 664 px ribbon sprite, whose alpha is uneven (alpha centre 267 px from the left of
  `br_total_at_base01`, 395 of `br_total_at_base02`). `ShowCounter` writes the node's x on this screen's instance
  (`2575768773`), in the slide node's space: config.toml `[duel_counter]`: each total starts `digits_gap` px after its label (`left_label_end_x` / `right_label_end_x`) and grows outward,
  the same label-to-digits gap on both sides. No config = the retail place.
* **Critical tag.** The «critical» tag of a side that made a critical hit sits just right of that side's total, centred
  on its middle line (`digits_mid_y`), `tag_gap` px after the last digit, at `tag_scale` of its 180 px mesh. It is placed
  in layout px like the plates: the tag layer has no anchor, so its origin is the layout's top-left corner with y up, and
  the mesh centre (`tag_centre_x`, `tag_centre_y`) scales with the layer. The shot readout's tags assume
  `tag_default_digits` digits on the retail number nodes (`left_retail_number_x` / `right_retail_number_x`).
* **Plate places.** In every duel each plate's layer is moved with `CMND_SET_LAYER_LOCAL_POS` (layout px, y up, y 0)
  so that its inner content edge sits at minus / plus `half_distance` from the screen centre: the plates mirror each
  other on the retail line and a longer total grows outward. The left plate's inner edge is the rightmost of its
  ribbon's visible end (`left_ribbon_inner_x`), its total (`digit_width` per digit) and its «critical» tag; the right
  plate's is the leftmost of its label (`right_label_inner_x`) and its ribbon's visible start. The half distance never drops below the
  retail plates' outer edges (`left_plate_outer_x` / `right_plate_outer_x`) plus `plate_gap`, then drops so the
  wider plate fits in `layout_width` (never below the retail outer edges). The left plate shows the
  viewer's team, the right plate the rival (`duel_readout.lua`). Nothing is measured on screen: the former measure of
  a hidden layer returned stale or screen-px scales (install 721: one plate kept the probe offset, the other moved half
  the distance). The plates show no text under the total.
* **Only focus duels.** Shot against block / catch does not reach `Duel.SkillClashResult`: the shot readout is the retail
  zone plates.
* Switch: Mods options «Duel and AT / PP counters» (`BetterUI.duel_and_shot_counters`, read once per duel).

## 3. Log lines

`power counter shown: left … move … right … move …` per duel. Per opening: `BETTERUI_POWER_COUNTER opened: left chara
0x… bust set up, right chara 0x… bust set up`, then `bust left shown after N frames` / `bust right shown after N frames`.
A set-up line with no `shown` line = the model never completed: the plate has no bust and the digits stay.
