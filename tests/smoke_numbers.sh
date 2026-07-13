#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
tmp_file="$tmp_dir/CodexTest_$(date +%s).numbers"

cleanup() {
  osascript <<APPLESCRIPT >/dev/null 2>&1 || true
set targetPath to "$tmp_file"
set canonicalTargetPath to POSIX path of (POSIX file targetPath as alias)
tell application "Numbers"
    repeat with docRef in every document
        try
            if (POSIX path of (file of contents of docRef as alias)) is canonicalTargetPath then
                close contents of docRef saving no
                exit repeat
            end if
        end try
    end repeat
end tell
APPLESCRIPT
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

assert_contains() {
  local haystack="$1"
  local pattern="$2"
  local message="$3"

  if command -v rg >/dev/null 2>&1; then
    if ! printf '%s' "$haystack" | rg -q -- "$pattern"; then
      printf 'smoke_numbers: %s\n' "$message" >&2
      exit 1
    fi
  elif ! printf '%s' "$haystack" | grep -q -- "$pattern"; then
    printf 'smoke_numbers: %s\n' "$message" >&2
    exit 1
  fi
}

is_target_open() {
  osascript <<APPLESCRIPT
set targetPath to "$tmp_file"
set canonicalTargetPath to POSIX path of (POSIX file targetPath as alias)
tell application "Numbers"
    set isOpen to false
    repeat with docRef in every document
        try
            if (POSIX path of (file of contents of docRef as alias)) is canonicalTargetPath then
                set isOpen to true
                exit repeat
            end if
        end try
    end repeat
end tell
return isOpen
APPLESCRIPT
}

osascript -e 'tell application "Numbers" to version' >/dev/null

create_out="$(bash "$repo_root/scripts/commands/document/create.sh" "$tmp_file" '{"sheets":[{"name":"Data","tables":[{"name":"Table 1","headers":["Ticker","Name"],"rows":[["AAPL","Apple"]]}]}]}')"
assert_contains "$create_out" '"success":true' "create failed: $create_out"

structure_out="$(bash "$repo_root/scripts/commands/document/structure.sh" "$tmp_file")"
assert_contains "$structure_out" '"name":"Data"' "structure did not include sheet name"
assert_contains "$structure_out" '"name":"Table 1"' "structure did not include table name"
assert_contains "$structure_out" '"rowCount":2' "structure did not include row count"

document_read_out="$(bash "$repo_root/scripts/commands/document/read.sh" "$tmp_file")"
assert_contains "$document_read_out" '"Ticker"' "document read did not include header value"
assert_contains "$document_read_out" '"AAPL"' "document read did not include data row"

table_read_out="$(bash "$repo_root/scripts/commands/table/read.sh" "$tmp_file" "Data" "Table 1")"
assert_contains "$table_read_out" '"Name"' "table read did not include table header"
assert_contains "$table_read_out" '"Apple"' "table read did not include cell data"

write_out="$(bash "$repo_root/scripts/commands/table/write.sh" "$tmp_file" "Data" "Table 1" '[{"row":0,"col":0,"value":"Symbol"},{"row":1,"col":1,"value":"Apple Inc."}]')"
assert_contains "$write_out" '"cellsUpdated":2' "write did not report two updated cells"

append_out="$(bash "$repo_root/scripts/commands/table/append.sh" "$tmp_file" "Data" "Table 1" '[["MSFT","Microsoft"],["NVDA","NVIDIA"]]')"
assert_contains "$append_out" '"rowsAppended":2' "append did not report appended rows"
assert_contains "$append_out" '"cellsUpdated":4' "append did not report updated cells"

final_read_out="$(bash "$repo_root/scripts/commands/document/read.sh" "$tmp_file")"
assert_contains "$final_read_out" '"Symbol"' "final read did not include overwritten header"
assert_contains "$final_read_out" '"Apple Inc."' "final read did not include overwritten value"
assert_contains "$final_read_out" '"MSFT"' "final read did not include appended row"
assert_contains "$final_read_out" '"NVIDIA"' "final read did not include appended row tail"

too_wide_out="$(bash "$repo_root/scripts/commands/table/append.sh" "$tmp_file" "Data" "Table 1" '[["A","B","C"]]' )"
assert_contains "$too_wide_out" '"error"' "wide row append should fail"

osascript <<APPLESCRIPT >/dev/null
tell application "Numbers"
    open POSIX file "$tmp_file"
    delay 0.5
end tell
APPLESCRIPT

open_before="$(is_target_open)"
if [[ "$open_before" != "true" ]]; then
  printf 'smoke_numbers: target document was not opened for reuse test\n' >&2
  exit 1
fi

reuse_read_out="$(bash "$repo_root/scripts/commands/document/read.sh" "$tmp_file")"
assert_contains "$reuse_read_out" '"Symbol"' "reuse read did not return target data"

open_after="$(is_target_open)"
if [[ "$open_after" != "true" ]]; then
  printf 'smoke_numbers: read script closed an already open document\n' >&2
  exit 1
fi

printf 'smoke_numbers: ok\n'
