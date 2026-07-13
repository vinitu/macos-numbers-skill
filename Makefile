.PHONY: dictionary dictionary-numbers dictionary-standard compile check test test-dictionary test-smoke

dictionary:
	@printf '### Numbers.app\n'
	@sdef /Applications/Numbers.app 2>/dev/null || true
	@printf '\n### CocoaStandard.sdef\n'
	@cat /System/Library/ScriptingDefinitions/CocoaStandard.sdef

dictionary-numbers:
	@sdef /Applications/Numbers.app 2>/dev/null || true

dictionary-standard:
	@cat /System/Library/ScriptingDefinitions/CocoaStandard.sdef

compile:
	@set -euo pipefail; \
	find scripts/applescripts -name '*.applescript' -print | while IFS= read -r file; do \
		osacompile -o /tmp/$$(echo "$$file" | tr '/' '_' | sed 's/\.applescript$$/.scpt/') "$$file" || echo "warning: osacompile failed for $$file"; \
	done; \
	find tests scripts/commands -name '*.sh' -print | while IFS= read -r file; do \
		bash -n "$$file" || exit 1; \
	done

check:
	@osascript -e 'tell application "Numbers" to get name' >/dev/null || { echo "check: Numbers not available"; exit 1; }
	@echo "Numbers is available"

test: test-dictionary test-smoke

test-dictionary:
	@bash tests/dictionary_contract.sh

test-smoke:
	@bash tests/smoke_numbers.sh
