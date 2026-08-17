---
name: macos-numbers
description: Use this skill when you need to read or edit Apple Numbers spreadsheets on macOS through AppleScript entrypoints that return JSON.
---

# macOS Numbers

Use this skill when the task is about Apple Numbers.app on macOS.

## Main Rule

Use only `scripts/commands`.
Do not call `scripts/applescripts` directly.

## Requirements

- macOS with Numbers.app
- Automation permissions for the terminal (System Settings → Privacy & Security → Automation).

## Public Interface

Run commands from `scripts/commands`:

- `scripts/commands/document/*`
- `scripts/commands/table/*`

Published commands:

- `document/create.sh`
- `document/read.sh`
- `document/structure.sh`
- `table/read.sh`
- `table/append.sh`
- `table/write.sh`

## Output Rules

- Commands return JSON by default.
- `--json`, `--plain`, and `--format=plain|json` are not supported.
- Errors are returned as `{"error":"..."}` (or `{"success":false,"error":"..."}` for argument/validation failures).

## Commands

All commands are run from the repo root. `<file-path>` is a POSIX path to a `.numbers` document. Table write coordinates are **0-based** (`row` and `col`).

### Document

Create a new document from a JSON spec (single sheet, single table max on Numbers 15.1):

```bash
scripts/commands/document/create.sh ~/Documents/CodexTest_Budget.numbers \
  '{"sheets":[{"name":"Summary","tables":[{"name":"Expenses","headers":["Item","Cost"],"rows":[["Rent","1200"]]}]}]}'
```

Expected output:

```json
{"success":true,"file":"/Users/me/Documents/CodexTest_Budget.numbers"}
```

Read a document's sheets, tables, headers, and data rows:

```bash
scripts/commands/document/read.sh ~/Documents/CodexTest_Budget.numbers
```

Expected output:

```json
{"file":"/Users/me/Documents/CodexTest_Budget.numbers","sheets":[{"name":"Summary","tables":[{"name":"Expenses","rowCount":2,"columnCount":2,"headerRowCount":1,"headerColumnCount":0,"headers":["Item","Cost"],"rows":[["Rent","1200"]]}]}]}
```

Read only the structure (sheet/table names and dimensions, no cell data):

```bash
scripts/commands/document/structure.sh ~/Documents/CodexTest_Budget.numbers
```

Expected output:

```json
{"file":"/Users/me/Documents/CodexTest_Budget.numbers","sheets":[{"name":"Summary","tables":[{"name":"Expenses","rowCount":2,"columnCount":2,"headerRowCount":1,"headerColumnCount":0}]}]}
```

### Table

Read a single table by sheet and table name:

```bash
scripts/commands/table/read.sh ~/Documents/CodexTest_Budget.numbers "Summary" "Expenses"
```

Expected output:

```json
{"file":"/Users/me/Documents/CodexTest_Budget.numbers","sheets":[{"name":"Summary","tables":[{"name":"Expenses","rowCount":2,"columnCount":2,"headerRowCount":1,"headerColumnCount":0,"headers":["Item","Cost"],"rows":[["Rent","1200"]]}]}]}
```

Append rows to a table (rows wider than the table are rejected):

```bash
scripts/commands/table/append.sh ~/Documents/CodexTest_Budget.numbers "Summary" "Expenses" '[["Coffee","5"]]'
```

Expected output:

```json
{"success":true,"rowsAppended":1,"cellsUpdated":2}
```

Write cells by 0-based `row`/`col` coordinates (single object or array of objects):

```bash
scripts/commands/table/write.sh ~/Documents/CodexTest_Budget.numbers "Summary" "Expenses" \
  '[{"row":0,"col":0,"value":"Rent"},{"row":0,"col":1,"value":"1200"}]'
```

Expected output:

```json
{"success":true,"cellsUpdated":2}
```

Out-of-range or missing arguments return a JSON error, for example:

```json
{"success":false,"error":"expected 4 arguments, got 3"}
```

## JSON Contract

Document read/structure object:

- `file` (string) — POSIX path of the document.
- `sheets` (array) — one object per sheet.

Sheet object:

- `name` (string)
- `tables` (array) — one object per table.

Table object (from `read`):

- `name` (string)
- `rowCount` (integer)
- `columnCount` (integer)
- `headerRowCount` (integer)
- `headerColumnCount` (integer)
- `headers` (array of strings) — empty when no header row.
- `rows` (array of arrays) — data rows, excluding the header row.

Table object (from `structure`):

- `name` (string)
- `rowCount` (integer)
- `columnCount` (integer)
- `headerRowCount` (integer)
- `headerColumnCount` (integer)

Write operation object (input to `table/write.sh`):

- `row` (integer, 0-based)
- `col` (integer, 0-based)
- `value` (string or number)

Scalar/result envelopes:

- create: `{"success":true,"file":"..."}`
- append: `{"success":true,"rowsAppended":N,"cellsUpdated":N}`
- write: `{"success":true,"cellsUpdated":N}`
- error: `{"error":"..."}`
- validation failure: `{"success":false,"error":"..."}`

## Safety Boundaries

- **Real user data**: spreadsheet contents are real user data. Never overwrite, delete, append, or export cells without an explicit user request.
- **Explicit writes**: `document/create.sh`, `table/append.sh`, and `table/write.sh` mutate and save the document to disk. Read commands (`document/read.sh`, `document/structure.sh`, `table/read.sh`) never save.
- **Document lifecycle**: read-only scripts close a document only when they opened it. Documents already open in Numbers are left untouched and open.
- **0-based coordinates**: `table/write.sh` uses 0-based `row` and `col`. Negative or out-of-range indices return a JSON error and write nothing.
- **Internal backend is not public**: `scripts/applescripts/**` is internal. Do not call AppleScript files directly from skill instructions; use `scripts/commands/**` only.
- **Test data**: use the `CodexTest_` prefix for any test documents and clean them up after runs. Do not leave temporary documents behind.

## Not Public

These Numbers features are not part of the public interface:

- Direct calls to `scripts/applescripts/**` entrypoints.
- Cell formatting, formulas, or styles beyond plain value writes.
- Creating more than one sheet or more than one table per sheet (AppleScript limit on Numbers `15.1`).
- `--json`, `--plain`, or `--format=plain|json` output flags.
- Bulk document export or conversion.