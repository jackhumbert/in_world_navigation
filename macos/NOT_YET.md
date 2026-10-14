# In-World Navigation on macOS: not done yet

The dylib builds. It has not been booted in the game. Addresses below are the ones the Mac hook and the field reads use.

## Tell jackhumbert

The six minimap fields in the Windows fork header are stale on game 2.3.1. The live slots (same numbers on the Windows 2.3.1 binary
and on the Mac binary) are:

| field | fork header | live |
|---|---|---|
| questMappin (WeakHandle) | 0x1E8 | 0x218 |
| questMappinPoints (DynArray of Vector4) | 0x1F8 | 0x228 |
| hasQuestMappin (Bool byte) | 0x208 | 0x238 |
| poiMappin (WeakHandle) | 0x210 | 0x240 |
| poiMappinPoints | 0x220 | 0x250 |
| hasPoiMappin (Bool byte) | 0x230 | 0x260 |

Slot stride is 0x28 from base 0x218. The Windows view of this port is left as upstream on purpose, so a Windows build of this tree
still reads the fork offsets. The Mac view uses the live numbers (`macos/IwnFields.hpp`).

The byte at slot+0x21 is not a plugin field. It was not identified.

A third slot exists (handle 0x268, points 0x278). The plugin does not expose it. The autodrive caller of `UpdateFromPoints`
(`this+0x1e0`) is not hooked.

## Hook

Windows hooks hash 3770693656, the four-argument `UpdateGPSPath` thunk. On macOS that thunk is `0x24e6714` and has no callers, so a
hook there never runs. The Mac hook is the caller, `0x24e6b34` (hash 1661347149, Windows RVA 0x1d29550): `void(this)`. One return
covers both GPS paths, so the hook calls `Update` for Int32 0 and then Int32 1. On Windows the thunk runs once per caller, so
`Update` can run twice for one path type. Whether one paired call per minimap update is the right rate is an in-game check.

`0x24e6d80` is inside the same function (the function runs through `0x24e6ffc`) and is not a hook target.

## Registration and files

- `scripts->Add` is skipped. The cache builder compiles `Scripts/`.
- `IO/FileStream.cpp` and `Utils::ToWString` are not in the Mac target. Nothing in the plugin calls them.
- Old Windows install paths (`r6/scripts/in_world_navigation`, `archive/pc/mod/in_world_navigation.archive`) are not deleted.
- There is no input XML in v0.1.22, so there is no input-loader file.
- Effect resource paths in the scripts use backslashes. Whether the Mac resource loader accepts them is an in-game check.
- Mod Settings is required for the settings properties (`RegisterListenerToClass`, `enabled:Bool = true`). This plugin does not
  change Mod Settings.

## Address that traps

`TTypedClass_IsEqual` in the Mac SDK is hash 1482951912 (`0x58630EE8`). That hash is not in the Mac address table. The compiled
`IsEqual` loads `0x58630EE8` and calls `UniversalRelocBase::Resolve`, so the call hits the fail-safe trap (log once, stub returns 0).
A different hash is used for that name in another port. It was not copied. `InWorldNavigation` does not forward `IsEqual`, so the
first equality test of an instance hits the trap.

`Memory_Vault_Unk1` (434901863) and `Memory_PoolStorage_OOM` (3578730042) are the SDK allocator cold paths. They are not in the
address table either, so they trap the same way. They run only on an out-of-memory path.
