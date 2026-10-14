#!/bin/bash
# Point in_world_navigation.dylib at the copies of spdlog and fmt next to it, add @loader_path as an rpath,
# then re-sign ad hoc. A library that is not linked is not an error.
# Usage: fix-install-names.sh <path to in_world_navigation.dylib>
set -eu
DYLIB="$1"
for lib in libspdlog libfmt; do
  old=$(otool -L "$DYLIB" | awk -v pat="$lib" 'NR > 1 && index($1, pat) { print $1; exit }')
  if [[ -z "$old" ]]; then
    echo "fix-install-names: no $lib dependency found"
    continue
  fi
  case "$old" in
    @loader_path/*) echo "fix-install-names: $lib already $old" ;;
    *)
      new="@loader_path/$(basename "$old")"
      install_name_tool -change "$old" "$new" "$DYLIB"
      echo "fix-install-names: $old -> $new"
      ;;
  esac
done
if ! otool -l "$DYLIB" | grep -A2 LC_RPATH | grep -q '@loader_path'; then
  install_name_tool -add_rpath @loader_path "$DYLIB"
  echo "fix-install-names: rpath @loader_path added"
fi
codesign -f -s - "$DYLIB"
