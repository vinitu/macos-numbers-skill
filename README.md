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

## Prerequisites

- macOS with Numbers.app
- Automation permission granted to your terminal app

## Public Interface

Run skill actions with:

```bash
scripts/commands/<entity>/<action>.sh [args...]
```

Output rules:

- Commands return JSON by default unless noted otherwise.
- `--json`, `--plain`, and `--format=plain|json` are not supported.

## Backend Map

- `scripts/commands/document/*` → AppleScript in `scripts/applescripts/document/*`
- `scripts/commands/table/*` → AppleScript in `scripts/applescripts/table/*`

`scripts/applescripts` is internal. Do not call it directly from the skill instructions.

## Command Surface

Document:

- `scripts/commands/document/read.sh`
- `scripts/commands/document/create.sh`
- `scripts/commands/document/structure.sh`

Table:

- `scripts/commands/table/read.sh`
- `scripts/commands/table/append.sh`
- `scripts/commands/table/write.sh`

## Validation

```bash
make compile
make test
```

`make test` runs live checks against Numbers.app and expects Numbers to be available.

## Known Limits

- Numbers must be running for some commands to work.
- TCC permissions (Automation) must be granted to the terminal or parent process.
