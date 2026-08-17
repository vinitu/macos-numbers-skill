# Repo Guide

This repo stores a Codex skill for macOS Numbers.app.

## Public interface and internal backend

- `scripts/commands/` is the only public command surface. Run commands from the repo root with paths like `scripts/commands/<entity>/<action>.sh`.
- `scripts/applescripts/` is the internal backend. Do not call AppleScript files directly from skill instructions.
- Only commands listed in `SKILL.md` are public. Other scripts may exist for internal use or legacy cleanup.

## Goal

- Keep the AppleScript command surface accurate to the live Numbers dictionary.
- Keep JSON I/O stable for agent integrations.
- Avoid breaking user document state when a file is already open in Numbers.

## Source Of Truth

- `make dictionary-numbers` dumps the live Numbers.app sdef (`sdef /Applications/Numbers.app`).
- `make dictionary-standard` dumps the shared CocoaStandard.sdef suite.
- Live checks with `osascript` against the real app.
- Raw dictionary commands live only in this file and in the `Makefile`.

The supported command surface lives in `SKILL.md`, this file, and the scripts in `scripts/`.

## Repo Layout

- `SKILL.md` is the main skill workflow and full command list.
- `README.md` is the repo overview for humans.
- `Makefile` stores dictionary, compile, and test commands.
- `scripts/commands/document/` stores the public file-level command wrappers.
- `scripts/commands/table/` stores the public table-level command wrappers.
- `scripts/commands/_lib/common.sh` stores shared shell helpers (JSON envelope, backend runner).
- `scripts/applescripts/document/` stores internal file-level AppleScript entrypoints.
- `scripts/applescripts/table/` stores internal table-level AppleScript entrypoints.
- `tests/` stores dictionary and live smoke checks for Numbers.app.

## Public vs Internal

- **Public**: `scripts/commands/<entity>/<action>.sh` — the only surface skill instructions may call. Run from the repo root.
- **Internal**: `scripts/applescripts/<entity>/<action>.applescript` — invoked only by the command wrappers via `osascript`. Never call these directly from skill instructions.
- Only commands listed in `SKILL.md` are public. Other scripts may exist for internal use or legacy cleanup.

## Pitfalls / Env Limits

- **TCC / Automation**: Numbers automation requires Automation permission (System Settings → Privacy & Security → Automation) for the terminal or parent process. A blocked live check must be documented, not silently swallowed.
- **Numbers must be running**: some AppleScript commands need Numbers.app to be running; `open` may still block on first launch.
- **Table coordinates are 0-based**: write operations use `row` and `col` indexed from `0`. The AppleScript layer converts to 1-based cell indices internally.
- **Single sheet / single table**: creating more than one sheet or more than one table per sheet is not supported by the current AppleScript implementation on Numbers `15.1`.
- **Document lifecycle**: read-only scripts (`read`, `structure`) close a document only when they opened it; documents already open in Numbers are left open.
- **Open document state**: avoid breaking user document state when a file is already open in Numbers.

## Safety Rules

- Treat spreadsheet data as real user data. Never overwrite, delete, or export cells without an explicit user request.
- File writes (create, append, write) are explicit and save the document to disk.
- Use the `CodexTest_` prefix for any test documents and clean them up after runs. Do not leave temporary documents behind.
- Keep JSON output machine-readable. Return structured errors like `{"error":"..."}`.

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
