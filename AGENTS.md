# Repo Guide

This repo stores a Codex skill for macOS Numbers.app.

## Goal

- Keep the AppleScript command surface accurate to the live Numbers dictionary.
- Keep JSON I/O stable for agent integrations.
- Avoid breaking user document state when a file is already open in Numbers.

## Source Of Truth

- `make dictionary-numbers`
- `make dictionary-standard`
- Live checks with `osascript`

The supported command surface lives in `SKILL.md`, this file, and the scripts in `scripts/`.

## Repo Layout

- `SKILL.md` is the main skill workflow.
- `README.md` is the repo overview for humans.
- `Makefile` stores dictionary, compile, and test commands.
- `scripts/document/` stores file-level AppleScript entrypoints.
- `scripts/table/` stores table-level AppleScript entrypoints.
- `tests/` stores dictionary and live smoke checks for Numbers.app.

## Editing Rules

- Keep docs in simple English.
- Update `SKILL.md` when command coverage or CLI examples change.
- Do not claim support for a Numbers action unless it is in the dictionary or verified with `osascript`.
- Keep JSON output machine-readable. Return structured errors like `{"error":"..."}`.
- Keep table write coordinates explicit. `row` and `col` are 0-based.
- Preserve document lifecycle handling. Read-only scripts must close documents only when they opened them.
- Treat spreadsheet data as real user data.
- Call out AppleScript limits clearly. Creating more than one sheet or more than one table per sheet is not supported by the current AppleScript implementation on Numbers `15.1`.

## Validation

- Run `make compile`.
- Run `make test-dictionary`.
- Run `make test-smoke` when Numbers.app and Automation permissions are available.
- If a live check is blocked by TCC permissions or app state, document the block clearly.
