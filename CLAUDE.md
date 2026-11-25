# In-World Navigation

Cyberpunk 2077 mod: renders the minimap's navigation path as holographic arrows in the world. RED4ext C++ plugin + redscript + a Wolvenkit archive, shipped under `red4ext/plugins/in_world_navigation/`. Settings UI comes from Mod Settings.

The rules for every mod (languages, native design, layout, build, release, comments, docs, tests) are in `../cp2077_tools/docs/mod_standard.md`; this file has only what is particular to In-World Navigation. Sibling repos: `../let_there_be_flight`, `../mod_settings`, `../input_loader`.

## Layout

- `src/red4ext/` - plugin. `Main.cpp` = entry. `Hooks/MinimapContainerController_UpdateGPSPath.cpp` = the one hooked game function (by RED4ext address hash, named `<Class>_<Method>` after it); `LoadResRef.hpp` = one hashed direct call. `FlightRoute.*` = Let There Be Flight's flight route (found through RTTI, optional), the minimap line redrawn along it with `MapFit.*` (pure, tested). `docs/history.md` = decisions and findings. `IO/` = file helpers.
- `src/redscript/in_world_navigation/` - arrows, colors, settings page; compiled against `deps/mod_settings/redscript` (see `.redscript-ide`).
- `tests/` - offline unit tests (`in_world_navigation_tests`, run by ctest and CI).
- `resources/` - Wolvenkit project; the built `resources/packed/archive/pc/mod/in_world_navigation.archive` is committed and only copied by CMake. `mappin_colors.json` at the root is reference data.
- `deps/` - submodules: `red4ext.sdk` (jackhumbert fork, `new-types`), `cyberpunk_cmake`, `red_lib` (fork, `jack`), `mod_settings` (for its redscript API), `archive_xl` (headers), `spdlog`, `detours`.
- `game_dir/`, `game_dir_debug/` build outputs zipped for release. `requirements.md` regenerated at configure.

## Build

Standard (section 6): `cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -G Ninja`, then `python ../cp2077_tools/game.py build "<title>"`; install only through `game.py run --install`.

## Updating for a game patch

1. `check_hashes.py` (shared game tools, see `CLAUDE.local.md`) - checks the 2 address hashes against the game's `bin/x64/cyberpunk2077_addresses.json`.
2. Bump `deps/red4ext.sdk` (fork commit that knows the patch) and `deps/cyberpunk_cmake` (requirement floors), as the standard's patch-day steps say.
3. Build, install, launch and run the smoke test, only through `../cp2077_tools` (the one way to test, see `E:\src\CLAUDE.md`):

   ```
   python ../cp2077_tools/game.py run "<title>" --purpose "in_world_navigation smoke" --install --launch --scripts ../cp2077_tools/mods/in_world_navigation --protect red4ext/plugins/mod_settings/user.ini -- python ../cp2077_tools/mods/in_world_navigation/smoke.py --out <dir>
   ```

   It checks the log, the instance, setting the display mode through Mod Settings (`--protect` puts Jack's
   `user.ini` back), and that tracking a quest objective in the save puts arrows along its path. It also
   checks that untracking clears them, with a screenshot. The newest save is used (or `--save`): it needs an
   active quest objective with a map pin. `GetQuestArrowCount` / `HasQuestMappin` in `InWorldNavigation.reds`
   exist for this test: the class is native, so a helper cannot `@addMethod` onto it.
4. Tag.

Past patch-day states are in `docs/history.md`. Configure with `-DCYBERPUNK_2077_GAME_DIR=...` when the game is not on C:.

## Releases

The standard release flow (section 5). Nexus mod 4583, file id 2601349.

## Conventions

- Don't commit Wolvenkit `custom_refs.txt` churn (with `.projectFiles`, standard section 9).
