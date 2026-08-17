#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

json_fail() { local msg="$1"; printf '{"success":false,"error":"%s"}\n' "$msg"; exit 1; }
json_ok() { local payload="${1:-{}}"; printf '{"success":true,"data":%s}\n' "$payload"; }
require_arg() { local v="${1:-}" l="$2"; [[ -z "$v" ]] && json_fail "missing ${l}"; }

backend_script() { local e="$1" a="$2"; printf '%s/scripts/applescripts/%s/%s.applescript' "$ROOT_DIR" "$e" "$a"; }

# Pass through backend JSON output unchanged; wrap non-JSON/empty output as a
# structured error so the public surface always emits JSON.
json_wrap() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || json_fail "empty output from backend"
  printf '%s\n' "$raw"
}

run_backend() {
  local e="$1" a="$2"; shift 2
  local sp; sp="$(backend_script "$e" "$a")"
  [[ -f "$sp" ]] || json_fail "backend script not found: ${sp}"
  local raw
  if ! raw="$(osascript "$sp" "$@" 2>&1)"; then
    json_fail "${raw:-backend command failed}"
  fi
  json_wrap "$raw"
}