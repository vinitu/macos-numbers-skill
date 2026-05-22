#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
json_fail() { local msg="$1"; printf '{"success":false,"error":"%s"}\n' "$msg"; exit 1; }
json_ok() { local payload="${1:-{}}"; printf '{"success":true,"data":%s}\n' "$payload"; }
require_arg() { local v="${1:-}" l="$2"; [[ -z "$v" ]] && json_fail "missing ${l}"; }
backend_script() { local e="$1" a="$2"; printf '%s/scripts/applescripts/%s/%s.applescript' "$ROOT_DIR" "$e" "$a"; }
run_backend() {
  local e="$1" a="$2"; shift 2
  local sp; sp="$(backend_script "$e" "$a")"
  [[ -f "$sp" ]] || json_fail "backend script not found: ${sp}"
  osascript "$sp" "$@"
}
