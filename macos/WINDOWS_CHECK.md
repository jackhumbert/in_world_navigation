# Windows-view check: in_world_navigation

Base: `main` (`385cd85`, which is tag `v0.1.22` plus 8 commits). The first version of this check was made against `v0.1.22`; it was run
again against `main` on 2026-10-14, after the rebase, and the result below is from that run.

Method: for every shared file this branch changes outside `macos/` (`git diff --name-only main HEAD -- . ':!macos'`),

`diff -u <(git show main:<f> | unifdef -U__APPLE__ -t) <(git show HEAD:<f> | unifdef -U__APPLE__ -t)`

`unifdef -U__APPLE__` drops `#ifdef __APPLE__` bodies, keeps `#else` and `#ifndef __APPLE__` bodies, and removes the directives.

## Result

The Windows view of every changed shared file matches `main`. No hunk.

| file | result |
|---|---|
| `src/red4ext/Main.cpp` | match |
| `src/red4ext/Hooks/UpdateNavPath.cpp` | match |
| `src/red4ext/InWorldNavigation.hpp` | match |
| `src/red4ext/Utils.cpp` | match |
| `src/red4ext/Utils.hpp` | match |
| `src/red4ext/stdafx.hpp` | match |

`src/red4ext/InWorldNavigation.cpp` and `stdafx.cpp` are unchanged from `main`. The extra `#include`s in `InWorldNavigation.hpp` are inside
`#ifdef __APPLE__`.

The Windows `REGISTER_HOOK_HASH` of 3770693656 (`Hooks/UpdateNavPath.cpp:92`), the `offsetof` field lines (`Main.cpp:145-148`),
`RegisterInputs` (the Input Loader registration of the toggle-arrows key that `main` added, `Main.cpp:101-125`, called at `:233`),
`scripts->Add` (`:231-232`), `RegisterArchive` (`:234`), and `ModModuleFactory::Load` / `Unload` (`:235`, `:248`) are the `main` text.
`Main.cpp` keeps `LoadResRef.hpp`, `Registrar.hpp` and `CyberpunkMod.hpp` in `#ifndef __APPLE__`, so they stay in the Windows view.
`RegisterInputs` is in `#ifndef __APPLE__` too: it is compiled on Windows only, because Input Loader is a Windows plugin. The Mac hook, the live offsets, and
`iwn_registerNatives` are inside `#ifdef __APPLE__`.

Re-run the check:

```
for f in $(git diff --name-only main HEAD -- . ':!macos'); do
  diff -q <(git show main:$f 2>/dev/null | unifdef -U__APPLE__ -t) <(git show HEAD:$f | unifdef -U__APPLE__ -t) >/dev/null || echo "$f"
done
```

No output means every file matches.
