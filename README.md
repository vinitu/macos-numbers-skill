# macOS Numbers Skill

This repo stores an AI agent skill for Apple Numbers.app on macOS.

The public interface is `scripts/commands`.
`scripts/applescripts` stores internal AppleScript backends and dictionary-aligned coverage.

## Installation

```bash
npx skills add vinitu/macos-numbers-skill
```

Or with [skills.sh](https://skills.sh):

```bash
skills.sh add vinitu/macos-numbers-skill
```

The installed global skill directory is usually `~/.agents/skills/macos-numbers`.

### Installed dir vs package name

The workspace repo name, install directory, and `skills` package name can differ:

| Workspace repo | Install dir | Upstream package |
|---|---|---|
| `macos-numbers-skill/` | `~/.agents/skills/macos-numbers` | `vinitu/macos-numbers-skill` |

`skills check` and `skills update` may refer to this skill by the upstream package name `vinitu/macos-numbers-skill`.

## Prerequisites

- macOS with Numbers.app
- Automation permission granted to your terminal app (System Settings → Privacy & Security → Automation)

## Public Interface

Run skill actions with:

```bash
scripts/commands/<entity>/<action>.sh [args...]
```

Output rules:

- Commands return JSON by default unless noted otherwise.
- `--json`, `--plain`, and `--format=plain|json` are not supported.
- Errors are returned as `{"error":"..."}` (or `{"success":false,"error":"..."}` for argument/validation failures).

## Backend Map

- `scripts/commands/document/*` → AppleScript in `scripts/applescripts/document/*`
- `scripts/commands/table/*` → AppleScript in `scripts/applescripts/table/*`

`scripts/applescripts` is internal. Do not call it directly from the skill instructions.

## Command Surface

Document:

- `scripts/commands/document/create.sh`
- `scripts/commands/document/read.sh`
- `scripts/commands/document/structure.sh`

Table:

- `scripts/commands/table/read.sh`
- `scripts/commands/table/append.sh`
- `scripts/commands/table/write.sh`

## Examples

Create a document from a JSON spec (single sheet, single table max on Numbers 15.1):

```bash
scripts/commands/document/create.sh ~/Documents/CodexTest_Budget.numbers \
  '{"sheets":[{"name":"Summary","tables":[{"name":"Expenses","headers":["Item","Cost"],"rows":[["Rent","1200"]]}]}]}'
# {"success":true,"file":"/Users/me/Documents/CodexTest_Budget.numbers"}
```

Read a document's sheets, tables, headers, and data rows:

```bash
scripts/commands/document/read.sh ~/Documents/CodexTest_Budget.numbers
# {"file":"/Users/me/Documents/CodexTest_Budget.numbers","sheets":[{"name":"Summary","tables":[{"name":"Expenses","rowCount":2,"columnCount":2,"headerRowCount":1,"headerColumnCount":0,"headers":["Item","Cost"],"rows":[["Rent","1200"]]}]}]}
```

Read only the structure (no cell data):

```bash
scripts/commands/document/structure.sh ~/Documents/CodexTest_Budget.numbers
# {"file":"/Users/me/Documents/CodexTest_Budget.numbers","sheets":[{"name":"Summary","tables":[{"name":"Expenses","rowCount":2,"columnCount":2,"headerRowCount":1,"headerColumnCount":0}]}]}
```

Read a single table:

```bash
scripts/commands/table/read.sh ~/Documents/CodexTest_Budget.numbers "Summary" "Expenses"
# {"file":"/Users/me/Documents/CodexTest_Budget.numbers","sheets":[{"name":"Summary","tables":[{"name":"Expenses","rowCount":2,"columnCount":2,"headerRowCount":1,"headerColumnCount":0,"headers":["Item","Cost"],"rows":[["Rent","1200"]]}]}]}
```

Append rows to a table:

```bash
scripts/commands/table/append.sh ~/Documents/CodexTest_Budget.numbers "Summary" "Expenses" '[["Coffee","5"]]'
# {"success":true,"rowsAppended":1,"cellsUpdated":2}
```

Write cells by 0-based `row`/`col`:

```bash
scripts/commands/table/write.sh ~/Documents/CodexTest_Budget.numbers "Summary" "Expenses" \
  '[{"row":0,"col":0,"value":"Rent"},{"row":0,"col":1,"value":"1200"}]'
# {"success":true,"cellsUpdated":2}
```

Missing arguments return a JSON error:

```bash
scripts/commands/table/read.sh ~/Documents/CodexTest_Budget.numbers "Summary"
# {"success":false,"error":"expected 3 arguments, got 2"}
```

## Validation

```bash
make compile
make test
```

`make test` runs live checks against Numbers.app and expects Numbers to be available with Automation permission granted. `make compile` runs `osacompile` on every AppleScript and `bash -n` on every shell script.

## Known Limits

- Numbers must be running for some commands to work; `open` may block on first launch.
- TCC permissions (Automation) must be granted to the terminal or parent process (System Settings → Privacy & Security → Automation).
- Table write coordinates are **0-based** (`row` and `col`). Negative or out-of-range indices return a JSON error.
- Creating more than one sheet or more than one table per sheet is not supported by the current AppleScript implementation on Numbers `15.1`.
- Read-only scripts (`document/read.sh`, `document/structure.sh`, `table/read.sh`) close a document only when they opened it; documents already open in Numbers are left open.
- Append rows wider than the table are rejected; the table is not modified.
- Cell formatting, formulas, styles, bulk export, and conversion are not part of the public interface.
- Use the `CodexTest_` prefix for test documents and clean them up after runs.