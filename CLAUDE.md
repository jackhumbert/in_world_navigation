# In-World Navigation

Cyberpunk 2077 mod: renders the minimap's navigation path as holographic arrows in the world. RED4ext C++ plugin + redscript + a Wolvenkit archive, shipped under `red4ext/plugins/in_world_navigation/`. Settings UI comes from Mod Settings.

Sibling repos with the same build/release shape: `../flight_control` (Let There Be Flight; its CLAUDE.md has the full build/update/release detail), `../mod_settings`, `../input_loader`.

## Layout

- `src/red4ext/` - plugin. `Main.cpp` = entry. `Hooks/UpdateNavPath.cpp` = the one hooked game function (by RED4ext address hash); `LoadResRef.hpp` = one hashed direct call. `IO/` = file helpers.
- `src/redscript/in_world_navigation/` - arrows, colors, settings page; compiled against `deps/mod_settings/redscript` (see `.redscript-ide`).
- `resources/` - Wolvenkit project; the built `resources/packed/archive/pc/mod/in_world_navigation.archive` is committed and only copied by CMake. `mappin_colors.json` at the root is reference data.
- `deps/` - submodules: `red4ext.sdk` (jackhumbert fork, `new-types`), `cyberpunk_cmake`, `red_lib` (fork, `jack`), `mod_settings` (for its redscript API), `archive_xl` (headers), `spdlog`, `detours`.
- `game_dir/`, `game_dir_debug/` build outputs zipped for release. `requirements.md` regenerated at configure.

## Build

MSVC 2022 + Ninja + CMake 3.24+ (VS dev shell):

```
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -G Ninja
cmake --build build
cmake --install build
```

## Updating for a game patch

1. `python tools/check_hashes.py` - checks the 2 address hashes against the game's `bin/x64/cyberpunk2077_addresses.json`.
2. Bump `deps/red4ext.sdk` (fork commit that knows the patch) and `deps/cyberpunk_cmake` (requirement floors); do that SDK work in `flight_control` first and reuse the commit.
3. Build, install, launch, check `red4ext/logs/in_world_navigation.log` for "Attaching UpdateNavPath" and drive a quest route.
4. Tag.

State on 2026-09-13: v0.1.21 (built for 2.30) loads and hooks on game 2.31 unchanged; pins bumped to the 2.31 SDK so the next tag reads "for 2.31". v0.1.22 is tagged but check whether it was ever released before cutting v0.1.23.

## Releases

Push a `vX.Y.Z` tag. `.github/workflows/release.yaml` builds, generates the changelog with git-cliff (`cliff.toml`, conventional commits: `feat:`/`fix:` appear, `chore:`/`ci:` skipped), publishes the GitHub release, then uploads to Nexus mod 4583 (file id 2601349) via `Nexus-Mods/upload-action`. Needs the repo secret `NEXUSMODS_API_KEY`; the v3 mod id is resolved from the site id in a prior step. Full-depth checkout is required for the changelog.

Push submodule commits to their own repos before tagging.

## Conventions

- No em-dashes anywhere.
- Don't commit `build/`, `game_dir*/`, `compile_commands.json`, or Wolvenkit `.projectFiles` / `custom_refs.txt` churn.
