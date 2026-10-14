# In-World Navigation on macOS: not done yet

The dylib builds and runs in the game: two automated in-game runs passed (hook INSTALLED, `Update` called, POI path arrows
spawned). Not checked yet: the quest path, a person driving a tracked route, and the plugin's own log file (it is not created on
macOS; the loader log has the plugin's lines). Addresses below are the ones the Mac hook and the field reads use.

## Stale field offsets upstream

Reported upstream. The six minimap fields in the Windows fork header are stale on game 2.3.1. The live slots (same numbers on the Windows 2.3.1 binary
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
`Update` can run twice for one path type. In game the paired call runs about 900 times a minute, and the arrows appear.

`0x24e6d80` is inside the same function (the function runs through `0x24e6ffc`) and is not a hook target.

## Registration and files

- `scripts->Add` is skipped. The cache builder compiles `Scripts/`.
- `IO/FileStream.cpp` and `Utils::ToWString` are not in the Mac target. Nothing in the plugin calls them.
- Old Windows install paths (`r6/scripts/in_world_navigation`, `archive/pc/mod/in_world_navigation.archive`) are not deleted.
- There is no input XML in v0.1.22, so there is no input-loader file.
- Effect resource paths in the scripts use backslashes. The Mac resource loader accepts them (the arrow effects spawn in game).
- Mod Settings is required for the settings properties (`RegisterListenerToClass`, `enabled:Bool = true`). This plugin does not
  change Mod Settings.

## Addresses that trap

`TTypedClass_IsEqual` (hash 1482886888, `0x58630EE8`) resolves: `CMakeLists.txt` injects Codeware's Mac SDK rows, which have it
(Mac `0x2197FE4`).

`Memory_Vault_Unk1` (434901863) and `Memory_PoolStorage_OOM` (3578730042) are the SDK allocator cold paths. They are not in the
address table either, so they trap the same way. They run only on an out-of-memory path.
