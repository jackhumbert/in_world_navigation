# History

Decisions and findings, newest first. One entry per finding: what was decided, why, the numbers
that showed it, what was tried and dropped, and the commits. Code comments point here instead of
carrying dates and measurements.

## 2026-11-24 Arrow brightness: one effect per level

Decision: "Arrow brightness" picks one of four effects (`world_navigation_rgb[_dim|_bright|_brightest]`),
whose channel particles have `ColorMultiplier` 7.5, 15, 22.5 and 30; changing it drops the arrows and
respawns them. The alphas stay as they are. In this material alpha is coverage, not intensity: as it drops
the arrow's dots thin out, and once they are all drawn more alpha adds nothing. Tried and dropped, in game:
- Alpha times a brightness factor (0.5 to 2) on multiplier 15: 2 looked hardly brighter, 0.5 only thinner.
- Channel multiplier 45 with alphas a third as big, for 3 times the headroom: the default arrows turned
  orange and dim arrows pink, since each channel thins out on its own and the faint ones go first.
The smoke test checks it by the light arrow-coloured pixels add over a shot with the arrows off (Dim /
Normal / Brightest 254823 / 765506 / 2125490); a plain pixel count drowned in sunlight moving across the
scene while game time ran.

## 2026-11-24 Arrow colour from script, one effect

Decision: the arrow colour is three floats set from script, not one `.effect` / `.particle` pair per
colour. The six old pairs (yellow, blue, white, teal, cyan, fast travel metro) differed only in the
`Color` of the particle's local material instance (white also had `ColorMultiplier` 15 where the rest
had 7). `FxInstance.SetBlackboardValue` takes only floats, and `effectTrackItemParticles` reads only
`alpha`, `size`, `velocity` and `emissionScale` from the blackboard, so no colour input reaches a
particle. `world_navigation_rgb.effect` instead draws three channel arrows in the same place
(`world_navigation_channel_{red,green,blue}.particle`: pure red, green, blue on `arrow.mi`, with
`AdditiveAlphaBlend` 1 so they add exactly, and `ColorMultiplier` 15), each track's `alpha` bound to its
own input `red`, `green`, `blue`. Script sends each channel as the colour in linear light times the
arrow's alpha: the material's `Color` is sRGB, and the blackboard clamps to 0..1, so the colours that had
multiplier 7 are scaled by 7/15. Checked in game against the old effects, side by side, all five colours
alike. Cost: three particles per arrow instead of one.

## 2026-10-31 Hook renamed to the game's own name

Decision: the hook and the direct call are named `<Class>_<Method>` after their SHA-confirmed names
in `IDA_Cyberpunk_2077`, with the demangled signature above each, as LTBF and Mod Settings did the
same day. `UpdateNavPath` (3770693656) is `MinimapContainerController_UpdateGPSPath` and its file
follows; `LoadResRef` (1157708450, unused) is `ResourceAsyncReference_IssueLoadingRequest`. The
redscript `InWorldNavigation.UpdateNavPath` is the mod's own function and keeps its name. The stale
notes in the hook file went with it, as the standard's cleanup list asked: 3797170204 (an older hash
for `UpdateGPSPath`, gone from the 2.5 address file), 1268721260
(`MappinsContainerController::OnGPSPathChanged`, a possible other hook point) and 3637917225
(`UpdateFromPoints`, unconfirmed). `src/red4ext/Addresses.hpp` (pre-2.12 address table) is still
included by `Main.cpp` but nothing reads it.

## 2026-10-25 Game 2.5

Game 2.5 broke the RED4ext ABI (`Callback` buffer 32 to 64, `CBaseFunction` 0xB0 to 0xF0), so 2.31
builds crash on load in `AddRegistrationFunc`. Hashes, the `MappinsContainerController` layout
(PathData at +0x218, stride 40) and the redscript were unchanged. Rebuilding on SDK `new-types`
732300b6, cyberpunk_cmake 9d97027 and mod_settings 29f27e4 fixed it, tested in game. red_lib stays on
the `jack` fork (2d9bb93); upstream was not needed. Configure with `-DCYBERPUNK_2077_GAME_DIR=...`
when the game is not on C:.

## 2026-09-13 Game 2.31

v0.1.21 (built for 2.30) loads and hooks on game 2.31 unchanged; pins bumped to the 2.31 SDK so the
next tag reads "for 2.31". Tags v0.1.21 and v0.1.22 exist on the remote but never produced GitHub
releases (no workflow runs recorded; last published release is v0.1.20 for 2.30+), so the next
release is v0.1.23.
