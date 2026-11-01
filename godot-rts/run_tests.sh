#!/usr/bin/env bash
# Runs the headless smoke test. Usage: GODOT=/path/to/godot ./run_tests.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")"
"$GODOT" --headless --path . --import >/dev/null 2>&1
LOG=$(mktemp)
"$GODOT" --headless --fixed-fps 60 --path . res://tests/smoke_test.tscn 2>&1 | tee "$LOG"
CODE=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|^ERROR" "$LOG"; then
	echo "Engine/script errors detected in output"
	CODE=1
fi
rm -f "$LOG"
exit $CODE
