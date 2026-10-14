# In-World Navigation for macOS (Apple Silicon)

A port of [jackhumbert/in_world_navigation](https://github.com/jackhumbert/in_world_navigation) v0.1.22 to the native macOS build of
Cyberpunk 2077 (2.3.1, Steam, Apple Silicon). Port by codeman101 (skyman3215). MIT, like upstream.

Everything macOS-specific is in this folder and in `#ifdef __APPLE__` blocks in `src/red4ext`. The Windows build is meant to be
unchanged: `WINDOWS_CHECK.md` is the `unifdef -U__APPLE__` comparison against tag v0.1.22. What is not done yet: `NOT_YET.md`.

## Status

The dylib builds for arm64 and loads in the game. Two automated in-game runs (a save with a tracked destination) passed: the hook
logs INSTALLED, `InWorldNavigation.Update` runs about 900 times a minute, the POI path had 9 points and 4 arrow effects spawned.
Only the POI path was exercised; the quest path and a person driving a route have not been checked yet.

The live hook is `0x24e6b34` (hash 1661347149), `void(this)`. It is on the minimap controller vtables and calls `UpdateFromPoints`
for the quest path (`this+0x228`) and then the POI path (`this+0x250`). After the original returns, if the type is
`gameuiMinimapContainerController`, the plugin runs `InWorldNavigation.Update` for Int32 0 and then Int32 1.

Hash 3770693656 (Mac `0x24e6714`) is the four-argument thunk the Windows build hooks. It has no callers on macOS, so it is not hooked.
The row is in `IwnSdkRows.inc` so the hash still resolves.

## What you need to run it

- Cyberpunk 2077 2.3.1, the native macOS build (Steam), on Apple Silicon.
- A RED4ext loader for macOS that installs the plugin's hook (`macos/hook-offsets.txt`, offset `0x24e6b34`) and calls
  `iwn_registerNatives` after every plugin has loaded (at script initialisation). The port was developed against the same loader
  setup as the macOS ports of TweakXL, ArchiveXL, Codeware and Mod Settings.
- ArchiveXL for macOS. The archive is installed at `archive/Mac/mod/in_world_navigation.archive`, which ArchiveXL mounts at startup.
- Mod Settings for macOS. The scripts call `ModSettings.RegisterListenerToClass`.

There is no input XML in v0.1.22. No input loader file is shipped.

## Build

```
cmake -S macos -B macos/build -DCMAKE_BUILD_TYPE=Release
cmake --build macos/build -j8
```

Needs the Xcode command line tools, CMake 3.21+, and Homebrew `fmt` and `spdlog`. The macOS RED4ext SDK is
`../../RED4ext.SDK-macos` (override with `-DRED4EXT_SDK_DIR=`).

After the link, `fix-install-names.sh` points fmt and spdlog at `@loader_path` and signs ad hoc. `check-undefined.sh` checks the
exports (`Main`, `Query`, `Supports`, `iwn_registerNatives`) and that no symbol is left for dynamic lookup.

## Install layout

`red4ext/plugins/in_world_navigation/`: `in_world_navigation.dylib`, `libfmt.12.dylib`, `libspdlog.1.17.dylib`, `license.md`,
and `Scripts/` (`Module.reds` plus the four redscript sources). The archive is not left in that folder at runtime: it goes to
`archive/Mac/mod/in_world_navigation.archive`.

- The scripts are compiled into the script cache by the loader setup. On macOS they are not added through RED4ext (`scripts->Add` is skipped).
- When that archive file is already present, `RegisterArchive` is skipped.

## How the macOS build differs

- **SDK.** `CMakeLists.txt` writes `build/sdk-overlay`: the macOS SDK address table plus `IwnSdkRows.inc`. An unknown hash resolves
  to `iwn_mac_trap_for_hash` (`MacShims.cpp`), which logs once and returns a stub. The stub logs its first call and returns 0.
  RedLib headers are copied at configure time. The overlay adds `RunPending`, forces clang to keep the class registrar, and
  fixes the scoped-enum scan clang rejects. The submodule is not edited.
- **Fields.** The macOS SDK class does not declare the six minimap fields. `macos/IwnFields.hpp` holds the live offsets
  (`0x218`, `0x228`, `0x238`, `0x240`, `0x250`, `0x260`). `GetQuestMappin` / `GetPOIMappin` and the four `CProperty::Create` calls
  use those numbers. The Windows view still uses `offsetof` on the fork header.
- **Natives.** The game does not run RTTI register callbacks. `iwn_registerNatives` runs the RedLib queue (`RunPending` in the
  Registrar overlay) and then `PostRegisterTypes`. A pool self-test runs first (`MacVault.cpp`).
- **Hook.** One attempt through the loader API. The log line says INSTALLED, or SKIPPED when the attach does not take (no API,
  refused, or the offset is not on the allowlist). There is no retry.
- **Left out of the Mac target.** `IO/FileStream.cpp` and `Utils::ToWString`. Old-file deletes (`r6/scripts/in_world_navigation`,
  `archive/pc/mod/in_world_navigation.archive`) are not done.
