---
name: macos-numbers
description: Use this skill when you need to read or edit Apple Numbers spreadsheets on macOS through AppleScript entrypoints that return JSON.
---

# macOS Numbers AppleScript

Use this skill when the task is about Apple Numbers.app on macOS and the repo already contains an AppleScript entrypoint for the action.

This guide only covers working with Numbers.

## Main Rule

Do not put inline AppleScript in the answer when this repo already has a script for the action.
Run the scripts in `scripts/document` and `scripts/table`.

## Script Layout

- `scripts/document/create.applescript`
- `scripts/document/read.applescript`
- `scripts/document/structure.applescript`
- `scripts/table/read.applescript`
- `scripts/table/write.applescript`
- `scripts/table/append.applescript`

## Document Commands

Create a new document from JSON:

```bash
osascript scripts/document/create.applescript "/path/to/file.numbers" '{"sheets":[{"name":"Data","tables":[{"name":"Table 1","headers":["Ticker","Name"],"rows":[["AAPL","Apple"]]}]}]}'
```

Read the whole document:

```bash
osascript scripts/document/read.applescript "/path/to/file.numbers"
```

Read only structure metadata:

```bash
osascript scripts/document/structure.applescript "/path/to/file.numbers"
```

## Table Commands

Read one table:

```bash
osascript scripts/table/read.applescript "/path/to/file.numbers" "Data" "Table 1"
```

Write one operation:

```bash
osascript scripts/table/write.applescript "/path/to/file.numbers" "Data" "Table 1" '{"row":0,"col":0,"value":"Symbol"}'
```

Write many operations:

```bash
osascript scripts/table/write.applescript "/path/to/file.numbers" "Data" "Table 1" '[{"row":0,"col":0,"value":"Symbol"},{"row":1,"col":1,"value":"Apple Inc."}]'
```

Append one row:

```bash
osascript scripts/table/append.applescript "/path/to/file.numbers" "Data" "Table 1" '["MSFT","Microsoft"]'
```

Append many rows:

```bash
osascript scripts/table/append.applescript "/path/to/file.numbers" "Data" "Table 1" '[["MSFT","Microsoft"],["NVDA","NVIDIA"]]'
```

## Behaviour Notes

- All commands return JSON.
- Table write coordinates use 0-based `row` and `col`.
- Table commands require explicit `sheet` and `table` names.
- Read-only commands reuse an already open document and do not close it afterwards.
- If a read-only command opens the document itself, it closes the document after the read completes.
- Append fails with a structured error when a row is wider than the target table.

## Important Limits

- Password-protected `.numbers` files are not supported.
- Automation may fail or block until macOS Automation permissions are granted.
- `scripts/document/create.applescript` supports the existing JSON spec shape, but current AppleScript support in Numbers `15.1` only lets this repo create one sheet and one table. A larger create spec returns a structured error.
