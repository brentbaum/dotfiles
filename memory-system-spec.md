# Claude Code Persistent Memory System — Technical Spec

**Date**: 2026-02-15
**Status**: Draft — awaiting review
**Goal**: Claude Code automatically learns user preferences over time, persists them across sessions, and retrieves them when relevant — without the user ever saying "remember this."

---

## 1. Design Principles

1. **Implicit, not explicit.** The user never invokes a command to save a preference. Claude notices patterns and saves them automatically.
2. **File-first.** All memory is plain Markdown on disk. No databases, no daemons, no MCP servers in v1.
3. **Non-blocking.** Memory operations never slow down the user's primary task.
4. **Transparent.** The user can read, edit, and delete any memory file. No opaque state.
5. **Incremental.** Memory accumulates session by session. No big-bang setup required.
6. **CLI-native.** Everything works with hooks, rules, CLAUDE.md, and shell scripts. No external services in v1.

---

## 2. Architecture

### File Layout

```
~/.claude/
├── CLAUDE.md                              # Personality + memory protocol instructions
├── settings.json                          # Hook configuration
├── rules/
│   └── memory-protocol.md                # Rules for when/how to update memory
├── memory/
│   ├── user-profile.md                   # Who the user is (name, tz, style)
│   ├── preferences.md                    # Learned preferences (tools, patterns, style)
│   ├── learnings.md                      # Corrections and discovered patterns
│   ├── projects.md                       # Cross-project knowledge
│   └── daily/
│       └── YYYY-MM-DD.md                # Daily session context (append-only)
└── hooks/
    ├── session-start.sh                  # Load memory into context
    ├── stop-reflect.sh                   # Trigger reflection after session
    ├── pre-compact-flush.sh              # Flush before context compaction
    └── test/                             # Test harness
        ├── run-tests.sh                  # Test runner
        ├── test-session-start.sh         # Tests for session-start hook
        ├── test-stop-reflect.sh          # Tests for stop-reflect hook
        ├── test-pre-compact-flush.sh     # Tests for pre-compact hook
        └── fixtures/                     # Test fixtures
            ├── sample-preferences.md
            ├── sample-daily-log.md
            └── sample-user-profile.md
```

### How Automatic Learning Works

The system has three automatic mechanisms — no user action required:

#### Mechanism 1: Session Start — Load Context
**When**: Every session start (SessionStart hook)
**What**: Inject today's daily log + yesterday's + user-profile + preferences into context
**Why**: Claude starts each session already knowing the user

#### Mechanism 2: Stop — Reflect and Extract
**When**: Every session end (Stop hook, async non-blocking)
**What**: An agent hook reads the session transcript and extracts:
  - New preferences observed (e.g., user chose tabs over spaces)
  - Corrections made (e.g., "no, use pytest not unittest")
  - Decisions made (e.g., "we're using PostgreSQL for this project")
  - Daily context worth preserving
**How**: A `type: "agent"` hook with a prompt that reads the transcript and appends to the appropriate memory files
**Why**: This is the core learning loop. Every session teaches Claude something.

#### Mechanism 3: Pre-Compaction Flush
**When**: Before context compaction (PreCompact hook)
**What**: An agent hook that writes any in-flight important context to today's daily log before it gets summarized away
**Why**: Long sessions lose detail during compaction. This preserves it.

### How Memory Is Retrieved

**No semantic search in v1.** Instead:
- `session-start.sh` loads the most relevant files directly into context (user-profile, preferences, today/yesterday daily logs)
- `~/.claude/CLAUDE.md` imports `@~/.claude/memory/preferences.md` and `@~/.claude/memory/user-profile.md` so they're always available
- For explicit lookups, Claude uses `Read` and `Grep` tools on `~/.claude/memory/` — it already knows where memory lives because the rules tell it

This is sufficient for <10K lines of memory. Semantic search (v2) adds chunked embedding search when the corpus grows.

---

## 3. Component Specifications

### 3.1 `session-start.sh`

**Input**: JSON on stdin with `{ "source": "startup|resume|clear|compact", "session_id": "...", "transcript_path": "..." }`
**Output**: Stdout text injected into Claude's context
**Behavior**:
1. Determine today's date and yesterday's date
2. If `source` is `startup` or `resume`:
   - Cat `~/.claude/memory/daily/$(today).md` if it exists
   - Cat `~/.claude/memory/daily/$(yesterday).md` if it exists (max 100 lines)
   - Cat `~/.claude/memory/learnings.md` if it exists (last 50 lines)
3. Output is prefixed with clear section headers
4. Exit 0 always (never block session start)
5. Total output capped at 4000 chars to avoid context bloat

**Verification Criteria**:
- [ ] Outputs today's daily log when it exists
- [ ] Outputs yesterday's log (truncated to 100 lines) when it exists
- [ ] Outputs nothing (empty string) when no memory files exist
- [ ] Handles missing `~/.claude/memory/` directory gracefully
- [ ] Caps total output at 4000 characters
- [ ] Runs in under 100ms
- [ ] Exits 0 on all paths (including errors)
- [ ] Correctly computes yesterday's date across month/year boundaries

### 3.2 `stop-reflect.sh` (Agent Hook)

**Trigger**: Stop hook, async (non-blocking)
**Type**: `agent` hook — Claude itself processes the transcript
**Prompt** (delivered via hook config):
```
You just finished a session. Read the transcript at $TRANSCRIPT_PATH.
Extract and save any of the following to the appropriate memory files:

1. USER PREFERENCES: Any tool choices, style preferences, workflow patterns,
   communication preferences the user demonstrated or stated.
   → Append to ~/.claude/memory/preferences.md under the right category.
   Only add genuinely new preferences, not duplicates.

2. CORRECTIONS: Anything the user corrected you on.
   → Append to ~/.claude/memory/learnings.md with today's date.

3. USER PROFILE: Any new facts about who the user is (name, role, projects,
   timezone, etc.)
   → Update ~/.claude/memory/user-profile.md

4. DAILY CONTEXT: Key decisions, work done, important context for tomorrow.
   → Append to ~/.claude/memory/daily/YYYY-MM-DD.md

Rules:
- Do NOT duplicate information already in the memory files. Read them first.
- Keep entries concise (1-2 lines each).
- Use consistent markdown formatting.
- If nothing new was learned, write nothing. Not every session teaches something.
- Never remove existing entries, only append or update.
```

**Verification Criteria**:
- [ ] Reads existing memory files before writing (no duplicates)
- [ ] Correctly categorizes: preferences → preferences.md, corrections → learnings.md, profile → user-profile.md, context → daily log
- [ ] Appends (never overwrites) existing content
- [ ] Creates memory files if they don't exist
- [ ] Creates daily/ directory if it doesn't exist
- [ ] Writes nothing when session had no learnable content
- [ ] Handles empty/missing transcript gracefully
- [ ] Each entry includes a date stamp
- [ ] Entries are concise (under 200 chars each)

### 3.3 `pre-compact-flush.sh` (Agent Hook)

**Trigger**: PreCompact hook (both `auto` and `manual`)
**Type**: `agent` hook
**Prompt**:
```
Context compaction is about to occur. Important details may be lost.
Review the current conversation and save any important context that
hasn't yet been written to memory:

- Key decisions made → ~/.claude/memory/daily/YYYY-MM-DD.md
- New preferences discovered → ~/.claude/memory/preferences.md
- Important technical context → ~/.claude/memory/daily/YYYY-MM-DD.md

Read the existing daily log first to avoid duplicates.
If nothing important needs saving, do nothing.
```

**Verification Criteria**:
- [ ] Fires on both `auto` and `manual` compaction
- [ ] Reads existing daily log before writing
- [ ] Only writes genuinely new information
- [ ] Creates daily log file if it doesn't exist
- [ ] Completes within timeout (60s default)

### 3.4 `~/.claude/CLAUDE.md` — Memory Protocol

**Purpose**: Always-loaded instructions that make Claude memory-aware.

**Verification Criteria**:
- [ ] Imports user-profile.md and preferences.md via `@` syntax
- [ ] Contains instructions for when to proactively update memory
- [ ] Instructs Claude to check memory files when context seems missing
- [ ] Does NOT instruct Claude to ask the user before saving preferences
- [ ] Personality section matches user's actual communication style (built over time)
- [ ] Total size stays under 2000 tokens (avoid context bloat)

### 3.5 `~/.claude/rules/memory-protocol.md` — Operating Rules

**Purpose**: Detailed rules for memory behavior, loaded every session.

**Verification Criteria**:
- [ ] Defines the memory file layout and purpose of each file
- [ ] Specifies when to write vs. when not to write
- [ ] Prohibits removing existing memory entries
- [ ] Instructs dedup behavior (read before write)
- [ ] Specifies formatting conventions (dates, categories, line length)

### 3.6 Memory File Formats

**`user-profile.md`**:
```markdown
# User Profile
- Name:
- Timezone:
- Role:

## Communication Style
- (learned over time)

## Current Projects
- (learned over time)
```

**`preferences.md`**:
```markdown
# Preferences

## Code Style
- (learned: e.g., "prefers functional style over OOP")

## Tools & Workflow
- (learned: e.g., "uses pytest, not unittest")

## Communication
- (learned: e.g., "prefers concise answers")

## Environment
- (learned: e.g., "runs on Arch Linux, uses kitty terminal")
```

**`learnings.md`**:
```markdown
# Learnings & Corrections

## 2026-02-15
- (corrections and discoveries from today's sessions)
```

**`daily/YYYY-MM-DD.md`**:
```markdown
# 2026-02-15

## Session 1
- (key context, decisions, work done)

## Session 2
- (continued work)
```

**Verification Criteria** (all memory files):
- [ ] Valid markdown that renders correctly
- [ ] Consistent heading structure
- [ ] Entries are append-only (daily, learnings) or update-in-place (profile, preferences)
- [ ] No entry exceeds 200 characters
- [ ] Categories in preferences.md are stable (don't proliferate endlessly)
- [ ] Daily logs are dated and session-numbered

---

## 4. Test Plan (Red/Green TDD)

All tests live in `~/.claude/hooks/test/` and are shell scripts that can be run independently.

### Test Structure

```bash
# Each test file follows this pattern:
#!/bin/bash
set -euo pipefail

PASS=0; FAIL=0; TOTAL=0

assert_eq() {
  TOTAL=$((TOTAL + 1))
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✓ $label"; PASS=$((PASS + 1))
  else
    echo "  ✗ $label"; echo "    expected: $expected"; echo "    actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  ✓ $label"; PASS=$((PASS + 1))
  else
    echo "  ✗ $label"; echo "    expected to contain: $needle"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  TOTAL=$((TOTAL + 1))
  local label="$1" needle="$2" haystack="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then
    echo "  ✓ $label"; PASS=$((PASS + 1))
  else
    echo "  ✗ $label"; echo "    expected NOT to contain: $needle"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  TOTAL=$((TOTAL + 1))
  local label="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  ✓ $label"; PASS=$((PASS + 1))
  else
    echo "  ✗ $label"; echo "    file not found: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  TOTAL=$((TOTAL + 1))
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✓ $label"; PASS=$((PASS + 1))
  else
    echo "  ✗ $label"; echo "    expected exit: $expected"; echo "    actual exit:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

# Setup: isolated temp directory as fake HOME
setup() {
  export TEST_HOME=$(mktemp -d)
  export MEMORY_DIR="$TEST_HOME/.claude/memory"
  mkdir -p "$MEMORY_DIR/daily"
}

# Teardown
teardown() {
  rm -rf "$TEST_HOME"
}

# Report
report() {
  echo ""
  echo "Results: $PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
}
```

### 4.1 Tests for `session-start.sh`

```
TEST: "outputs today's daily log when it exists"
  GIVEN: ~/.claude/memory/daily/2026-02-15.md contains "worked on auth module"
  WHEN:  session-start.sh runs with source=startup
  THEN:  stdout contains "worked on auth module"

TEST: "outputs yesterday's log truncated to 100 lines"
  GIVEN: ~/.claude/memory/daily/2026-02-14.md has 150 lines
  WHEN:  session-start.sh runs
  THEN:  output contains first 100 lines of yesterday
  AND:   output does NOT contain line 101+

TEST: "outputs nothing when no memory files exist"
  GIVEN: ~/.claude/memory/ directory is empty
  WHEN:  session-start.sh runs
  THEN:  stdout is empty or contains only headers

TEST: "handles missing memory directory"
  GIVEN: ~/.claude/memory/ does not exist
  WHEN:  session-start.sh runs
  THEN:  exits 0
  AND:   stdout is empty

TEST: "caps output at 4000 characters"
  GIVEN: daily log + yesterday + learnings = 10000 chars
  WHEN:  session-start.sh runs
  THEN:  total stdout ≤ 4000 chars

TEST: "correctly computes yesterday across month boundary"
  GIVEN: today is 2026-03-01
  WHEN:  session-start.sh computes yesterday
  THEN:  looks for 2026-02-28.md

TEST: "always exits 0 even on errors"
  GIVEN: memory directory has bad permissions (unreadable)
  WHEN:  session-start.sh runs
  THEN:  exits 0

TEST: "includes section headers in output"
  GIVEN: both today and yesterday logs exist
  WHEN:  session-start.sh runs
  THEN:  output contains "=== Today ===" and "=== Yesterday ==="

TEST: "includes recent learnings (last 50 lines)"
  GIVEN: learnings.md has 80 lines
  WHEN:  session-start.sh runs
  THEN:  output contains last 50 lines of learnings.md
```

### 4.2 Tests for `stop-reflect.sh` (Integration)

These are harder to unit test since they involve an agent hook. Test via:
1. Mock transcript files as fixtures
2. Run the hook's file-manipulation logic (the parts that are shell, not LLM)
3. Verify file creation/append behavior

```
TEST: "creates memory directory if missing"
  GIVEN: ~/.claude/memory/ does not exist
  WHEN:  stop-reflect runs (file creation portion)
  THEN:  ~/.claude/memory/ and ~/.claude/memory/daily/ exist

TEST: "creates preferences.md if missing"
  GIVEN: preferences.md does not exist
  WHEN:  a preference is extracted
  THEN:  preferences.md is created with correct header structure

TEST: "appends to existing preferences without duplication"
  GIVEN: preferences.md contains "prefers pytest"
  WHEN:  agent extracts "prefers pytest" again
  THEN:  preferences.md still has exactly one "prefers pytest" line

TEST: "creates daily log with correct date"
  GIVEN: today is 2026-02-15
  WHEN:  daily context is extracted
  THEN:  file is written to daily/2026-02-15.md

TEST: "appends to existing daily log (multiple sessions)"
  GIVEN: daily/2026-02-15.md has "## Session 1" content
  WHEN:  second session ends
  THEN:  "## Session 2" is appended, Session 1 content preserved

TEST: "learnings include date header"
  GIVEN: learnings.md exists
  WHEN:  a correction is logged
  THEN:  entry is under a "## 2026-02-15" header
```

### 4.3 Tests for `pre-compact-flush.sh` (Integration)

```
TEST: "creates daily log if missing during flush"
  GIVEN: no daily log for today
  WHEN:  pre-compact-flush runs
  THEN:  daily/2026-02-15.md is created

TEST: "does not duplicate content already in daily log"
  GIVEN: daily log contains "decided to use PostgreSQL"
  WHEN:  flush tries to save same decision
  THEN:  daily log has exactly one "decided to use PostgreSQL"
```

### 4.4 Tests for Memory File Formats

```
TEST: "user-profile.md has required sections"
  GIVEN: freshly created user-profile.md
  THEN:  contains "# User Profile"
  AND:   contains "## Communication Style"
  AND:   contains "## Current Projects"

TEST: "preferences.md has required categories"
  GIVEN: freshly created preferences.md
  THEN:  contains "# Preferences"
  AND:   contains "## Code Style"
  AND:   contains "## Tools & Workflow"
  AND:   contains "## Communication"
  AND:   contains "## Environment"

TEST: "learnings.md entries are dated"
  GIVEN: learnings.md with entries
  THEN:  every entry block is under a "## YYYY-MM-DD" header

TEST: "all memory files are valid markdown"
  GIVEN: any memory file
  THEN:  no broken markdown syntax (unclosed headers, etc.)
```

### 4.5 End-to-End Verification Scenarios

These verify the full loop and are run manually during development:

```
SCENARIO 1: "First session bootstraps memory"
  START:  No memory files exist
  ACTION: Start a Claude Code session, do some work, end session
  VERIFY: user-profile.md created (possibly empty sections)
          preferences.md created with any observed preferences
          daily/YYYY-MM-DD.md created with session context
          session-start loads cleanly next session

SCENARIO 2: "Preference is learned and recalled"
  START:  Clean memory
  ACTION: Session 1 — user writes Python code, corrects Claude to use
          f-strings instead of .format()
  ACTION: Session 2 — user asks Claude to write Python code
  VERIFY: Session 2 Claude uses f-strings without being told
          preferences.md contains f-string preference

SCENARIO 3: "Correction persists across sessions"
  START:  Clean memory
  ACTION: Session 1 — Claude suggests unittest, user says "use pytest"
  ACTION: Session 2 — user asks to write tests
  VERIFY: Session 2 Claude uses pytest
          learnings.md contains the correction

SCENARIO 4: "Daily context carries over"
  START:  Session 1 today at 10am — work on auth module
  ACTION: Session 2 today at 2pm — continue work
  VERIFY: Session 2 starts with context from Session 1 (loaded by session-start.sh)
          No context loss between sessions

SCENARIO 5: "Memory survives compaction"
  START:  Long session approaching context limit
  ACTION: PreCompact hook fires
  VERIFY: Important decisions written to daily log before compaction
          Post-compaction, daily log has the information

SCENARIO 6: "Old daily logs don't bloat context"
  START:  10 days of daily logs accumulated
  ACTION: Start new session
  VERIFY: Only today + yesterday loaded (not all 10 days)
          Old logs still exist on disk for grep
```

---

## 5. Implementation Order (TDD Red/Green)

### Phase 1: Test Harness + Session Start Hook

```
RED:   Write test-session-start.sh — all tests fail (script doesn't exist)
GREEN: Implement session-start.sh — make each test pass one at a time
       1. Empty dir → exits 0
       2. Today's log → outputs it
       3. Yesterday's log → outputs truncated
       4. Character cap → enforced
       5. Date boundary → handled
```

### Phase 2: Memory File Templates + CLAUDE.md

```
RED:   Write test-memory-formats.sh — tests for file structure fail
GREEN: Create template memory files with correct structure
       Write CLAUDE.md with @imports and memory protocol
       Write rules/memory-protocol.md
```

### Phase 3: Stop Reflect Hook

```
RED:   Write test-stop-reflect.sh — file creation/append tests fail
GREEN: Implement the shell scaffolding (directory creation, file append logic)
       Configure the agent hook in settings.json with the reflection prompt
       Run E2E scenario 2 and 3 to verify learning works
```

### Phase 4: Pre-Compact Flush Hook

```
RED:   Write test-pre-compact-flush.sh — tests fail
GREEN: Implement flush logic
       Configure PreCompact hook in settings.json
       Run E2E scenario 5
```

### Phase 5: Integration Testing

```
Run all E2E scenarios 1-6
Fix any issues discovered
Verify memory files accumulate correctly over multiple real sessions
```

---

## 6. Settings.json Configuration (Target State)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "... (stop-reflect prompt from 3.2) ...",
            "timeout": 120,
            "async": true
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "auto|manual",
        "hooks": [
          {
            "type": "agent",
            "prompt": "... (pre-compact prompt from 3.3) ...",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

---

## 7. Out of Scope (v1)

- Semantic/vector search (v2 — when memory exceeds ~10K lines)
- MCP memory server
- Heartbeat/proactive agent (requires daemon — not CLI-native)
- Cross-platform messaging
- Skill auto-creation (OpenClaw Foundry equivalent)
- Memory cleanup/garbage collection automation

---

## 8. Success Criteria

The system is working when:

1. **Zero-config learning**: After 5 sessions, preferences.md has ≥3 real preferences the user never explicitly asked Claude to save.
2. **Cross-session continuity**: Starting a new session, Claude knows what you worked on yesterday without being told.
3. **Correction stickiness**: A correction made in session N is respected in session N+1 without reminder.
4. **Non-intrusive**: The user never sees memory operations. No "I've saved your preference" messages unless debugging.
5. **All tests pass**: `run-tests.sh` exits 0.
6. **Performance**: Session start adds <200ms latency. Stop hook is fully async.
