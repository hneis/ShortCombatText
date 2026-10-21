#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [addon-directory]\n' "$0" >&2
  exit 2
fi

if [[ $# -eq 1 ]]; then
  ADDON_ROOT=$(CDPATH='' cd -- "$1" && pwd)
else
  ADDON_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)
fi

ADDON_NAME=$(basename "$ADDON_ROOT")
TOC_FILE="$ADDON_ROOT/$ADDON_NAME.toc"

if [[ ! -f "$TOC_FILE" ]]; then
  printf 'Expected primary TOC: %s\n' "$TOC_FILE" >&2
  exit 1
fi

find_luac51() {
  local candidate local_root version

  if [[ -n "${LUAC5_1:-}" ]]; then
    candidate=$LUAC5_1
    if ! command -v "$candidate" >/dev/null 2>&1; then
      printf 'LUAC5_1 does not resolve to an executable: %s\n' "$candidate" >&2
      return 1
    fi
    version=$($candidate -v 2>&1 || true)
    if [[ "$version" != *'Lua 5.1'* ]]; then
      printf 'LUAC5_1 is not Lua 5.1: %s\n' "$version" >&2
      return 1
    fi
    printf '%s|\n' "$candidate"
    return 0
  fi

  for local_root in "$SCRIPT_DIR/../.local/lua51" "$SCRIPT_DIR/../../.local/lua51"; do
    candidate="$local_root/usr/bin/luac5.1"
    if [[ ! -x "$candidate" ]]; then
      continue
    fi
    version=$(env LD_LIBRARY_PATH="$local_root/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      "$candidate" -v 2>&1 || true)
    if [[ "$version" == *'Lua 5.1'* ]]; then
      printf '%s|%s\n' "$candidate" "$local_root/usr/lib"
      return 0
    fi
  done

  for candidate in luac5.1 luac-5.1 luac; do
    if ! command -v "$candidate" >/dev/null 2>&1; then
      continue
    fi
    version=$($candidate -v 2>&1 || true)
    if [[ "$version" == *'Lua 5.1'* ]]; then
      printf '%s|\n' "$candidate"
      return 0
    fi
  done

  printf 'Lua 5.1 compiler not found. Install lua5.1 or set LUAC5_1.\n' >&2
  return 1
}

LUAC_SPEC=$(find_luac51)
LUAC=${LUAC_SPEC%%|*}
LUAC_LIBRARY_PATH=${LUAC_SPEC#*|}

run_luac() {
  if [[ -n "$LUAC_LIBRARY_PATH" ]]; then
    env LD_LIBRARY_PATH="$LUAC_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      "$LUAC" "$@"
  else
    "$LUAC" "$@"
  fi
}

interface=''
version=''
runtime_count=0
missing_count=0

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  line=${raw_line%$'\r'}
  case "$line" in
    '## Interface:'*)
      interface=${line#'## Interface:'}
      interface=${interface//[[:space:]]/}
      ;;
    '## Version:'*)
      version=${line#'## Version:'}
      version=${version#"${version%%[![:space:]]*}"}
      version=${version%"${version##*[![:space:]]}"}
      ;;
    '' | '#'*) ;;
    *)
      runtime_path=$line
      runtime_path=${runtime_path#"${runtime_path%%[![:space:]]*}"}
      runtime_path=${runtime_path%"${runtime_path##*[![:space:]]}"}
      runtime_path=${runtime_path//\\//}
      if [[ -z "$runtime_path" ]]; then
        continue
      fi
      if [[ "$runtime_path" == /* || "$runtime_path" == ../* || "$runtime_path" == *'/../'* ]]; then
        printf 'Unsafe TOC path: %s\n' "$line" >&2
        missing_count=$((missing_count + 1))
        continue
      fi
      runtime_count=$((runtime_count + 1))
      if [[ ! -f "$ADDON_ROOT/$runtime_path" ]]; then
        printf 'Missing TOC file or case mismatch: %s\n' "$runtime_path" >&2
        missing_count=$((missing_count + 1))
      fi
      ;;
  esac
done <"$TOC_FILE"

if [[ "$interface" != '16001' ]]; then
  printf 'Expected Interface 16001 in %s, got: %s\n' "$TOC_FILE" "${interface:-missing}" >&2
  exit 1
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$ ]]; then
  printf 'Expected a semantic Version in %s, got: %s\n' "$TOC_FILE" "${version:-missing}" >&2
  exit 1
fi

if [[ $runtime_count -eq 0 ]]; then
  printf 'TOC does not list any runtime files: %s\n' "$TOC_FILE" >&2
  exit 1
fi

if [[ $missing_count -ne 0 ]]; then
  exit 1
fi

lua_count=0
while IFS= read -r -d '' lua_file; do
  run_luac -p "$lua_file"
  lua_count=$((lua_count + 1))
done < <(find "$ADDON_ROOT" -type f -name '*.lua' -not -path '*/.git/*' -print0)

if [[ $lua_count -eq 0 ]]; then
  printf 'No Lua files found in %s\n' "$ADDON_ROOT" >&2
  exit 1
fi

if [[ -d "$ADDON_ROOT/.git" ]] \
  && [[ -n "$(git -C "$ADDON_ROOT" ls-files '*.zip')" ]]; then
  printf 'Release ZIP files must not be tracked in the addon repository.\n' >&2
  exit 1
fi

printf 'Validated %s: Interface 16001, version %s, %d TOC files, %d Lua files (%s).\n' \
  "$ADDON_NAME" "$version" "$runtime_count" "$lua_count" "$LUAC"
