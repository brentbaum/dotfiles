#!/bin/bash
# run-tests.sh — Run all memory system tests
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

echo "========================================"
echo " Claude Code Memory System — Test Suite"
echo "========================================"
echo ""

for test_file in "$SCRIPT_DIR"/test-*.sh; do
  if [ -f "$test_file" ]; then
    echo "Running $(basename "$test_file")..."
    echo ""
    if bash "$test_file"; then
      TOTAL_PASS=$((TOTAL_PASS + 1))
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
    echo ""
  fi
done

echo "========================================"
echo " Suite: $TOTAL_PASS suites passed, $TOTAL_FAIL failed"
echo "========================================"

[ "$TOTAL_FAIL" -eq 0 ] && exit 0 || exit 1
