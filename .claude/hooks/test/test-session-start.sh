#!/bin/bash
# test-session-start.sh — Tests for session-start.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../session-start.sh"

PASS=0; FAIL=0; TOTAL=0

assert_eq() {
  TOTAL=$((TOTAL + 1))
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"
    echo "    expected: $(echo "$expected" | head -c 200)"
    echo "    actual:   $(echo "$actual" | head -c 200)"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"
    echo "    expected to contain: $needle"
    echo "    output was: $(echo "$haystack" | head -c 200)"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  TOTAL=$((TOTAL + 1))
  local label="$1" needle="$2" haystack="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"
    echo "    expected NOT to contain: $needle"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  TOTAL=$((TOTAL + 1))
  local label="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"; echo "    file not found: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_dir_exists() {
  TOTAL=$((TOTAL + 1))
  local label="$1" path="$2"
  if [ -d "$path" ]; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"; echo "    directory not found: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  TOTAL=$((TOTAL + 1))
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"
    echo "    expected exit: $expected"
    echo "    actual exit:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_le() {
  TOTAL=$((TOTAL + 1))
  local label="$1" max="$2" actual="$3"
  if [ "$actual" -le "$max" ]; then
    echo "  PASS $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL $label"
    echo "    expected <= $max, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

# --- Setup / Teardown ---

setup() {
  export TEST_HOME=$(mktemp -d)
  export CLAUDE_MEMORY_DIR="$TEST_HOME/.claude/memory"
  # Don't pre-create — let the script handle it
}

teardown() {
  rm -rf "$TEST_HOME"
  unset CLAUDE_MEMORY_DIR
}

run_hook() {
  echo '{"session_id":"test-123"}' | bash "$HOOK_SCRIPT" 2>/dev/null
}

# --- Tests ---

echo "=== session-start.sh tests ==="
echo ""

# Test 1: Creates memory directory if missing
echo "-- creates memory/daily/ directory if missing"
setup
output=$(run_hook)
exit_code=$?
assert_exit_code "exits 0" "0" "$exit_code"
assert_dir_exists "creates daily directory" "$CLAUDE_MEMORY_DIR/daily"
teardown

# Test 2: Creates today's daily log if missing
echo "-- creates today's daily log if missing"
setup
run_hook >/dev/null
TODAY=$(date +%Y-%m-%d)
assert_file_exists "creates today's daily log" "$CLAUDE_MEMORY_DIR/daily/$TODAY.md"
content=$(cat "$CLAUDE_MEMORY_DIR/daily/$TODAY.md")
assert_contains "daily log has date header" "# $TODAY" "$content"
teardown

# Test 3: Outputs today's daily log when it has content
echo "-- outputs today's daily log when it has content"
setup
mkdir -p "$CLAUDE_MEMORY_DIR/daily"
TODAY=$(date +%Y-%m-%d)
printf "# %s\n\n## Session 1\n- worked on auth module\n" "$TODAY" > "$CLAUDE_MEMORY_DIR/daily/$TODAY.md"
output=$(run_hook)
assert_contains "output contains today header" "=== Today" "$output"
assert_contains "output contains today's content" "worked on auth module" "$output"
teardown

# Test 4: Does NOT output today's log when it only has the date header
echo "-- does not output today's log when only header exists"
setup
mkdir -p "$CLAUDE_MEMORY_DIR/daily"
TODAY=$(date +%Y-%m-%d)
echo "# $TODAY" > "$CLAUDE_MEMORY_DIR/daily/$TODAY.md"
output=$(run_hook)
assert_not_contains "no today section for header-only file" "=== Today" "$output"
teardown

# Test 5: Outputs yesterday's daily log
echo "-- outputs yesterday's daily log"
setup
mkdir -p "$CLAUDE_MEMORY_DIR/daily"
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
printf "# %s\n\n## Session 1\n- fixed database migration\n" "$YESTERDAY" > "$CLAUDE_MEMORY_DIR/daily/$YESTERDAY.md"
output=$(run_hook)
assert_contains "output contains yesterday header" "=== Yesterday" "$output"
assert_contains "output contains yesterday's content" "fixed database migration" "$output"
teardown

# Test 6: Yesterday's log truncated to 100 lines
echo "-- truncates yesterday's log to 100 lines"
setup
mkdir -p "$CLAUDE_MEMORY_DIR/daily"
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
# Generate 150 lines
{
  echo "# $YESTERDAY"
  for i in $(seq 1 149); do
    echo "- line $i of yesterday's log"
  done
} > "$CLAUDE_MEMORY_DIR/daily/$YESTERDAY.md"
output=$(run_hook)
assert_contains "has line 99" "line 99" "$output"
assert_not_contains "no line 101" "line 101" "$output"
teardown

# Test 7: Outputs learnings when they have content
echo "-- outputs learnings when they have content"
setup
mkdir -p "$CLAUDE_MEMORY_DIR"
printf "# Learnings & Corrections\n\n## 2026-02-15\n- Use pytest not unittest\n" > "$CLAUDE_MEMORY_DIR/learnings.md"
output=$(run_hook)
assert_contains "output contains learnings header" "=== Recent Learnings" "$output"
assert_contains "output contains learning content" "Use pytest not unittest" "$output"
teardown

# Test 8: Does NOT output learnings when file only has header
echo "-- does not output learnings when only header exists"
setup
mkdir -p "$CLAUDE_MEMORY_DIR"
echo "# Learnings & Corrections" > "$CLAUDE_MEMORY_DIR/learnings.md"
output=$(run_hook)
assert_not_contains "no learnings section for header-only" "=== Recent Learnings" "$output"
teardown

# Test 9: Outputs nothing when no memory files exist
echo "-- outputs empty when no memory files exist"
setup
output=$(run_hook)
exit_code=$?
assert_exit_code "exits 0" "0" "$exit_code"
# Output should be empty or near-empty (the script creates the daily log with just a header)
assert_not_contains "no today section" "=== Today" "$output"
assert_not_contains "no yesterday section" "=== Yesterday" "$output"
assert_not_contains "no learnings section" "=== Recent Learnings" "$output"
teardown

# Test 10: Caps total output at 4000 characters
echo "-- caps total output at 4000 characters"
setup
mkdir -p "$CLAUDE_MEMORY_DIR/daily"
TODAY=$(date +%Y-%m-%d)
# Generate a huge daily log (>5000 chars)
{
  echo "# $TODAY"
  echo ""
  echo "## Session 1"
  for i in $(seq 1 200); do
    echo "- This is a long line number $i with enough text to generate lots of characters in the output"
  done
} > "$CLAUDE_MEMORY_DIR/daily/$TODAY.md"
output=$(run_hook)
output_len=${#output}
assert_le "output <= 4000 chars" 4000 "$output_len"
teardown

# Test 11: Always exits 0, even with bad permissions
echo "-- always exits 0 even with errors"
setup
# Point at a non-writable directory
export CLAUDE_MEMORY_DIR="/proc/nonexistent/memory"
output=$(run_hook)
exit_code=$?
assert_exit_code "exits 0 with bad path" "0" "$exit_code"
export CLAUDE_MEMORY_DIR="$TEST_HOME/.claude/memory"
teardown

# Test 12: Handles both today and yesterday in one output
echo "-- combines today and yesterday in output"
setup
mkdir -p "$CLAUDE_MEMORY_DIR/daily"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
printf "# %s\n\n## Session 1\n- today's work\n" "$TODAY" > "$CLAUDE_MEMORY_DIR/daily/$TODAY.md"
printf "# %s\n\n## Session 1\n- yesterday's work\n" "$YESTERDAY" > "$CLAUDE_MEMORY_DIR/daily/$YESTERDAY.md"
output=$(run_hook)
assert_contains "has today section" "=== Today" "$output"
assert_contains "has yesterday section" "=== Yesterday" "$output"
assert_contains "has today content" "today's work" "$output"
assert_contains "has yesterday content" "yesterday's work" "$output"
teardown

# Test 13: Bootstraps user-profile.md if missing
echo "-- bootstraps user-profile.md if missing"
setup
run_hook >/dev/null
assert_file_exists "creates user-profile.md" "$CLAUDE_MEMORY_DIR/user-profile.md"
content=$(cat "$CLAUDE_MEMORY_DIR/user-profile.md")
assert_contains "user-profile has header" "# User Profile" "$content"
assert_contains "user-profile has Name field" "Name:" "$content"
teardown

# Test 14: Bootstraps preferences.md if missing
echo "-- bootstraps preferences.md if missing"
setup
run_hook >/dev/null
assert_file_exists "creates preferences.md" "$CLAUDE_MEMORY_DIR/preferences.md"
content=$(cat "$CLAUDE_MEMORY_DIR/preferences.md")
assert_contains "preferences has header" "# Preferences" "$content"
assert_contains "preferences has Code Style section" "## Code Style" "$content"
teardown

# Test 15: Bootstraps learnings.md if missing
echo "-- bootstraps learnings.md if missing"
setup
run_hook >/dev/null
assert_file_exists "creates learnings.md" "$CLAUDE_MEMORY_DIR/learnings.md"
content=$(cat "$CLAUDE_MEMORY_DIR/learnings.md")
assert_contains "learnings has header" "# Learnings & Corrections" "$content"
teardown

# Test 16: Does NOT overwrite existing memory files
echo "-- does not overwrite existing memory files"
setup
mkdir -p "$CLAUDE_MEMORY_DIR"
echo "# User Profile
- Name: Alice" > "$CLAUDE_MEMORY_DIR/user-profile.md"
echo "# Preferences
## Code Style
- Use tabs" > "$CLAUDE_MEMORY_DIR/preferences.md"
printf "# Learnings & Corrections\n\n## 2026-01-01\n- Always use ruff\n" > "$CLAUDE_MEMORY_DIR/learnings.md"
run_hook >/dev/null
up_content=$(cat "$CLAUDE_MEMORY_DIR/user-profile.md")
pref_content=$(cat "$CLAUDE_MEMORY_DIR/preferences.md")
learn_content=$(cat "$CLAUDE_MEMORY_DIR/learnings.md")
assert_contains "user-profile preserved" "Alice" "$up_content"
assert_contains "preferences preserved" "Use tabs" "$pref_content"
assert_contains "learnings preserved" "Always use ruff" "$learn_content"
teardown

# --- Report ---

echo ""
echo "=============================="
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
echo "=============================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
