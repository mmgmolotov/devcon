#!/usr/bin/env bash
# Runs the headless smoke test. Usage: GODOT=/path/to/godot ./run_tests.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")"
"$GODOT" --headless --path . --import >/dev/null 2>&1
LOG=$(mktemp)
CODE=0
for MODE in "" "--survival" "--menu" "--artpack"; do
	echo "=== smoke test ${MODE:-skirmish} ==="
	"$GODOT" --headless --fixed-fps 60 --path . res://tests/smoke_test.tscn -- $MODE 2>&1 | tee -a "$LOG"
	[ "${PIPESTATUS[0]}" -ne 0 ] && CODE=1
done
if grep -qE "SCRIPT ERROR|^ERROR" "$LOG"; then
	echo "Engine/script errors detected in output"
	CODE=1
fi
rm -f "$LOG"
exit $CODE
