# Windows-view check: in_world_navigation

Base: tag `v0.1.22`.

Method: for every shared file this branch changes outside `macos/`,

`diff -u <(git show v0.1.22:<f> | unifdef -U__APPLE__) <(unifdef -U__APPLE__ <f>)`

`unifdef -U__APPLE__` drops `#ifdef __APPLE__` bodies, keeps `#else` and `#ifndef __APPLE__` bodies, and removes the directives.

## Result

The Windows view of every changed shared file matches v0.1.22. No hunk.

| file | result |
|---|---|
| `src/red4ext/Main.cpp` | match |
| `src/red4ext/Hooks/UpdateNavPath.cpp` | match |
| `src/red4ext/Utils.cpp` | match |
| `src/red4ext/Utils.hpp` | match |
| `src/red4ext/stdafx.hpp` | match |

`src/red4ext/InWorldNavigation.cpp`, `InWorldNavigation.hpp`, and `stdafx.cpp` are unchanged from the tag.

The Windows `REGISTER_HOOK_HASH` of 3770693656, the `offsetof` field lines, `scripts->Add`, `RegisterArchive`, and
`ModModuleFactory::Load` / `Unload` are the tag text. The Mac hook, the live offsets, and `iwn_registerNatives` are inside
`#ifdef __APPLE__`.
