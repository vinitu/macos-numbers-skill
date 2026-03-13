# macOS Numbers AppleScript Skill

This repo stores a Codex skill for macOS Numbers.app.

It provides JSON-first AppleScript entrypoints for document and table automation.

## Installation

```bash
npx skills add vinitu/macos-numbers-skill
```

Or with [skills.sh](https://skills.sh):

```bash
skills.sh add vinitu/macos-numbers-skill
```

## Scope

- Create a new `.numbers` document from a JSON spec.
- Read document structure and table data as JSON.
- Update cells with explicit `row` and `col` coordinates.
- Append one row or many rows to an existing table.
- Reuse an already open document without closing the user's window.

## Tested Base

- macOS `26.3.1`
- Numbers `15.1`

## Repo Layout

- `AGENTS.md` - repo rules for future agents.
- `SKILL.md` - the full skill workflow and examples.
- `Makefile` - helper commands for dictionary dump, compile, and tests.
- `scripts/document/` - file-level AppleScript entrypoints.
- `scripts/table/` - table-level AppleScript entrypoints.
- `tests/` - dictionary and live smoke checks for Numbers.app.

## Command Surface

Document commands:

- `scripts/document/create.applescript`
- `scripts/document/read.applescript`
- `scripts/document/structure.applescript`

Table commands:

- `scripts/table/read.applescript`
- `scripts/table/write.applescript`
- `scripts/table/append.applescript`

## How To Use

Create a new spreadsheet:

```bash
osascript scripts/document/create.applescript "/path/to/file.numbers" '{"sheets":[{"name":"Data","tables":[{"name":"Table 1","headers":["Ticker","Name"],"rows":[["AAPL","Apple"]]}]}]}'
```

Read a document:

```bash
osascript scripts/document/read.applescript "/path/to/file.numbers"
```

Read document structure:

```bash
osascript scripts/document/structure.applescript "/path/to/file.numbers"
```

Read one table:

```bash
osascript scripts/table/read.applescript "/path/to/file.numbers" "Data" "Table 1"
```

Write cells:

```bash
osascript scripts/table/write.applescript "/path/to/file.numbers" "Data" "Table 1" '[{"row":0,"col":0,"value":"Symbol"},{"row":1,"col":1,"value":"Apple Inc."}]'
```

Append rows:

```bash
osascript scripts/table/append.applescript "/path/to/file.numbers" "Data" "Table 1" '[["MSFT","Microsoft"],["NVDA","NVIDIA"]]'
```

For the full command set and examples, use `SKILL.md`.

## Important Limits

- Numbers is a GUI app. Automation may depend on macOS Automation permissions and app state.
- Password-protected `.numbers` files are not supported.
- `scripts/document/create.applescript` keeps the JSON spec shape from the earlier JXA version, but current AppleScript support in Numbers `15.1` can only create one sheet and one table in that sheet. Larger specs return a structured error.
- `row` and `col` in table write commands are 0-based.
- Table-level commands require explicit `sheet` and `table` names.
- Read-only commands close the document only when they opened it themselves.
