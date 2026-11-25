# History

Decisions and findings, newest first. One entry per finding: what was decided, why, the numbers
that showed it, what was tried and dropped, and the commits. Code comments point here instead of
carrying dates and measurements.

## 2026-11-24 Following Let There Be Flight's route while flying

Decision: with LTBF installed, while the player flies with something tracked, the arrows and the minimap's GPS line
follow LTBF's flight route (its `FlightGuidance`, LTBF `docs/design/guidance.md`) instead of the road route. LTBF plans
and owns the route; IWN only reads it. `FlightRoute.cpp` finds `FlightGuidance` through RTTI each frame, so IWN needs
nothing of LTBF to build or run. The route stands in for the GPS path whose destination is nearest its end (the quest's
when neither has one), and the other GPS path is hidden: both lead by road.
- Arrows: the route goes through the same `UpdateNavPath` as the GPS points. LTBF gives it V's end first, as the
  minimap's points are, so the incremental layout keeps working (only V's end moves).
- Minimap: the hooked `UpdateGPSPath` writes `questMappinPoints` itself (the probe of the earlier entry), so the points
  cannot be swapped in before it. After it, the line's vertices are rewritten along the route, with the world-to-widget
  mapping fitted that frame to the game's own points and vertices (`MapFit`: rotation, uniform scale, offset, mirrored
  or not; a straight route keeps the last choice). A probe with one point (on the loading screen) gave world
  (-412.3, 522.7) -> vertex (831.6, -656.1), so the vertices are absolute widget positions, not relative to V. In
  game the line has one vertex per point and the fit is exact (error 0.000, scale 1.591 widget units per metre,
  mirrored), and the rewritten vertices show with nothing else marking the widget dirty.
- A Mod Setting, "Follow flight route" (default on), turns it off: `FlightRoute.cpp` reads the field before taking
  LTBF's route, so off is the same as LTBF not installed (11/11 in game with it switched off and on while flying).
- Offline: `tests/map_fit_tests.cpp`, IWN's first unit tests (5), run by CI.
- In game: `cp2077_tools/mods/in_world_navigation/flight_check.py`, ManualSave-191 with a quest objective tracked, 9/9:
  flight on gave the quest path the flight route (260 arrows climbing over the overpass ahead), the minimap's line
  drawn along its 634 points, and flight off put the road route back. A llama-server holding 7 of the GPU's 8 GB made
  earlier runs crawl (a few fps, 4-minute loads, 3 of 4 runs); the passing runs loaded in under 2 minutes with it still
  there, so it slows the game at times rather than always.

## 2026-11-24 Arrows update incrementally

Prompted by a RedProfiler report on #48 (UpdateFxInstance at 177 calls per frame, UpdateNavPath 470 us a call).
Measured with the hook's own timer (`GetUpdateStats`, `cp2077_tools/mods/in_world_navigation/perf.py`) on the
standard save, a 396-point route, game unfocused:

| | Update mean / max per call, before | after |
|---|---|---|
| standing | 1.07 ms / 1.7 ms | 32 us / 0.14 ms |
| driving | 1.25 ms / 4.5 ms | 66 us / 1.4 ms |

Findings and what changed:
- The minimap calls `UpdateGPSPath` once per GPS target type every frame (0 the quest, found by which call
  changed `questPoints`; 1 the POI), and each call redrew both paths. Now each call updates its own path.
- The hook handed script the one-byte target type as an Int32 read from its address, three bytes of garbage
  included; script ignored it until now. It is widened first.
- `points[0]` is V and the last point the destination; arrow spacing is anchored at the destination, so V moving
  only changes the route near V. The route is kept destination first and laid out again only from the first
  changed segment; a route that has not moved (1 cm: the start jitters below that) costs two point compares.
- Each arrow keeps its slot (`k % max arrows`): before, V passing an arrow handed every effect the next arrow's
  place. Effects get a transform only when their arrow is new to the slot or gliding to a re-planned route, and
  colour only when it changed: after a colour or setting change, or within the fade distance of V.
- Settings are compared on every update: `OnModSettingsChange` did not fire for accepted changes in testing.
- Multilayer textures or a colour input were looked for first: no particle module or effect track in the game's
  4,382 effects takes a colour from an effect input (only `CParticleModificatorAlphaOverEffect` reads one, and
  material-parameter tracks take floats onto an attached entity's meshes), so the three channel arrows stay.

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
