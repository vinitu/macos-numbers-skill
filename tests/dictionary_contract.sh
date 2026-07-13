#!/usr/bin/env bash
set -euo pipefail

tmp_numbers="$(mktemp)"
tmp_standard="$(mktemp)"
cleanup() {
  rm -f "$tmp_numbers" "$tmp_standard"
}
trap cleanup EXIT

make --no-print-directory dictionary-numbers >"$tmp_numbers" 2>/dev/null || true
make --no-print-directory dictionary-standard >"$tmp_standard"

has_pattern() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$file"
  else
    grep -q -- "$pattern" "$file"
  fi
}

if [ -s "$tmp_numbers" ]; then
  has_pattern '<class name="sheet"' "$tmp_numbers"
  has_pattern '<class name="table"' "$tmp_numbers"
  has_pattern '<class name="cell"' "$tmp_numbers"
  has_pattern '<property name="formatted value"' "$tmp_numbers"
  has_pattern '<property name="value" code="NMCv"' "$tmp_numbers"
  has_pattern '<property name="password protected"' "$tmp_numbers"
  has_pattern '<command name="set"' "$tmp_numbers"
fi

has_pattern '<command name="delete"' "$tmp_standard"
has_pattern '<command name="make"' "$tmp_standard"

printf 'dictionary_contract: ok\n'
