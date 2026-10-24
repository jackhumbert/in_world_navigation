#!/bin/bash
# After the link: Main, Query, Supports and iwn_registerNatives are exported, and nothing is left for dynamic lookup.
# -undefined dynamic_lookup would also hide a function the plugin declares and never compiles in.
# Usage: check-undefined.sh <in_world_navigation.dylib>
set -eu
DYLIB="$1"
ALLOW="$(dirname "$0")/undefined-allowed.txt"
for sym in _Main _Query _Supports _iwn_registerNatives; do
  nm -gU "$DYLIB" | grep -q " T $sym\$" || { echo "check-undefined: FAILED. export $sym is missing" >&2; exit 1; }
done
BAD=$(nm -m -u "$DYLIB" | grep "dynamically looked up" | sed -E 's/^ +\(undefined\) external //; s/ \(dynamically looked up\)$//' || true)
if [[ -f "$ALLOW" && -n "$BAD" ]]; then
  BAD=$(echo "$BAD" | grep -vxFf <(grep -v '^#' "$ALLOW" | grep -v '^$') || true)
fi
if [[ -n "$BAD" ]]; then
  echo "check-undefined: FAILED. Symbols looked up dynamically at load (declared, not compiled in):" >&2
  echo "$BAD" | c++filt >&2
  exit 1
fi
echo "check-undefined: ok (Main, Query, Supports, iwn_registerNatives exported; no dynamically looked up symbols)"
