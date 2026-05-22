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
- Automation permissions for the terminal.

## Public Interface

Run commands from `scripts/commands`:

- `scripts/commands/document/*`
- `scripts/commands/table/*`

## Output Rules

- Commands return JSON by default.
- `--json`, `--plain`, and `--format=plain|json` are not supported.

## Commands

### Document

```bash
scripts/commands/document/read.sh <path>
scripts/commands/document/create.sh <path> <json-structure>
scripts/commands/document/structure.sh <path>
```

### Table

```bash
scripts/commands/table/read.sh <path> <sheet-name> <table-name>
scripts/commands/table/append.sh <path> <sheet-name> <table-name> <json-rows>
scripts/commands/table/write.sh <path> <sheet-name> <table-name> <json-cells>
```

## Safety Boundaries

- File writes must be explicit.
- Internal AppleScript files are not public API.
