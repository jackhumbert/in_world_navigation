# History

Decisions and findings, newest first. One entry per finding: what was decided, why, the numbers
that showed it, what was tried and dropped, and the commits. Code comments point here instead of
carrying dates and measurements.

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
