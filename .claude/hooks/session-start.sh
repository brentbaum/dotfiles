#!/bin/bash
# session-start.sh — Claude Code SessionStart hook (command type)
#
# Creates today's daily log if missing, outputs recent context into Claude's
# context window. Always exits 0. Output capped at 4000 chars.

set -o pipefail

MEMORY_DIR="${CLAUDE_MEMORY_DIR:-$HOME/.claude/memory}"
MAX_OUTPUT=4000
YESTERDAY_MAX_LINES=100
LEARNINGS_MAX_LINES=50

# Compute dates (supports both GNU and BSD date)
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null || "")

# Ensure directories exist
mkdir -p "$MEMORY_DIR/daily" 2>/dev/null || true

# Create today's daily log if it doesn't exist
TODAY_FILE="$MEMORY_DIR/daily/$TODAY.md"
if [ ! -f "$TODAY_FILE" ]; then
  echo "# $TODAY" > "$TODAY_FILE" 2>/dev/null || true
fi

# Build output
output=""

# Today's daily log
if [ -f "$TODAY_FILE" ]; then
  today_content=$(cat "$TODAY_FILE" 2>/dev/null || true)
  # Only include if there's content beyond just the date header
  line_count=$(echo "$today_content" | wc -l | tr -d ' ')
  if [ "$line_count" -gt 1 ]; then
    output+="=== Today ($TODAY) ===
$today_content

"
  fi
fi

# Yesterday's daily log (truncated)
if [ -n "$YESTERDAY" ] && [ -f "$MEMORY_DIR/daily/$YESTERDAY.md" ]; then
  yesterday_content=$(head -n "$YESTERDAY_MAX_LINES" "$MEMORY_DIR/daily/$YESTERDAY.md" 2>/dev/null || true)
  if [ -n "$yesterday_content" ]; then
    output+="=== Yesterday ($YESTERDAY) ===
$yesterday_content

"
  fi
fi

# Recent learnings
if [ -f "$MEMORY_DIR/learnings.md" ]; then
  learnings_content=$(tail -n "$LEARNINGS_MAX_LINES" "$MEMORY_DIR/learnings.md" 2>/dev/null || true)
  # Only include if there's content beyond just the header
  if [ -n "$learnings_content" ] && [ "$(echo "$learnings_content" | wc -l | tr -d ' ')" -gt 1 ]; then
    output+="=== Recent Learnings ===
$learnings_content

"
  fi
fi

# Cap output at MAX_OUTPUT chars
if [ ${#output} -gt $MAX_OUTPUT ]; then
  output="${output:0:$MAX_OUTPUT}"
fi

# Output (may be empty — that's fine)
printf '%s' "$output"

exit 0
