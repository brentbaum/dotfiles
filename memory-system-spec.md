# Claude Code Persistent Memory System — Technical Spec

**Date**: 2026-02-15
**Status**: Final — building
**Goal**: Claude Code automatically learns user preferences over time, persists them across sessions, and retrieves them when relevant — without the user ever saying "remember this."

---

## 1. Design Principles

1. **Implicit, not explicit.** The user never invokes a command to save a preference. Claude notices patterns and saves them automatically.
2. **File-first.** All memory is plain Markdown on disk. No databases, no daemons, no MCP servers, no skills.
3. **Non-blocking.** Memory operations never slow down the user's primary task.
4. **Transparent.** The user can read, edit, and delete any memory file. No opaque state.
5. **Incremental.** Memory accumulates session by session. No big-bang setup required.
6. **CLI-native.** Everything works with hooks, rules, CLAUDE.md, and shell scripts. No external services.
7. **Promotion-based.** Daily logs capture everything; stable patterns get promoted to long-lived files.

---

## 2. Architecture

### Core Mechanism: Promotion

The system has two tiers of memory with a **promotion** flow between them:

```
Session transcript
    ↓ (stop hook extracts)
Daily logs (ephemeral, per-day)
    ↓ (stop hook promotes stable patterns)
preferences.md / user-profile.md / learnings.md (long-lived)
    ↓ (@import into CLAUDE.md)
Always in context
```

**Why promotion?** Daily logs are noisy — they capture everything. But when Claude corrects itself three times about the same preference, that's a signal. The stop hook's job is to recognize stable patterns and promote them to long-lived files that are always in context via `@import`.

### File Layout

```
~/.claude/
├── CLAUDE.md                              # @imports + memory protocol instructions
├── settings.json                          # Hook configuration
├── rules/
│   └── memory-protocol.md                # Rules for when/how to update memory
├── memory/
│   ├── user-profile.md                   # Who the user is (name, tz, style)
│   ├── preferences.md                    # Learned preferences (tools, patterns, style)
│   ├── learnings.md                      # Corrections and discovered patterns
│   └── daily/
│       └── YYYY-MM-DD.md                # Daily session context (append-only)
└── hooks/
    ├── session-start.sh                  # Init daily log + load context
    └── test/
        ├── run-tests.sh
        └── test-session-start.sh
```

### How It Works (3 Mechanisms)

#### Mechanism 1: Always-in-Context via @import
**What**: `CLAUDE.md` uses `@import` to pull `preferences.md` and `user-profile.md` into every session.
**Why**: The most important memory is always available without any lookup cost.
**Fallback**: `CLAUDE.md` also instructs Claude to `grep ~/.claude/memory/` when it senses missing context about past decisions.

#### Mechanism 2: Session Start — Init & Load
**When**: Every session start (SessionStart hook, `command` type)
**What**:
  1. Create today's daily log file if it doesn't exist (with date header)
  2. Output today's daily log + yesterday's (truncated) into context
  3. Output recent learnings
**Why**: Claude starts each session with continuity from recent work.

#### Mechanism 3: Stop — Reflect, Extract, Promote
**When**: Every session end (Stop hook, `agent` type, async non-blocking)
**What**: An agent reads the session transcript and:
  1. **Extracts** daily context → appends to `daily/YYYY-MM-DD.md`
  2. **Extracts** corrections → appends to `learnings.md`
  3. **Promotes** stable preferences → updates `preferences.md` (deduped)
  4. **Promotes** user facts → updates `user-profile.md`
**Why**: This is the core learning loop. Every session teaches Claude something. Promotion ensures the most important learnings are always in context.

### How Memory Is Retrieved

1. **Always in context**: `preferences.md` and `user-profile.md` via `@import` in CLAUDE.md
2. **Loaded at session start**: Today + yesterday daily logs via session-start hook
3. **On-demand search**: Claude greps `~/.claude/memory/` when it needs older context (instructed via CLAUDE.md)

No semantic search needed for <10K lines of memory. grep on structured Markdown is sufficient.

---

## 3. Component Specifications

### 3.1 `CLAUDE.md`

**Purpose**: Always-loaded personality + memory protocol. Uses `@import` to keep preferences and profile in every context window.

**Contents**:
- `@import` of `~/.claude/memory/preferences.md`
- `@import` of `~/.claude/memory/user-profile.md`
- Memory protocol: instructions for when to proactively update memory files
- Fallback search instruction: "grep ~/.claude/memory/ when missing context"

**Verification Criteria**:
- [ ] Imports user-profile.md and preferences.md via `@` syntax
- [ ] Contains instruction to grep memory/ for older context
- [ ] Does NOT instruct Claude to ask before saving preferences
- [ ] Total size stays under 2000 tokens (avoid context bloat)

### 3.2 `session-start.sh`

**Type**: `command` hook on SessionStart
**Input**: JSON on stdin with `{ "session_id": "..." }`
**Output**: Stdout text injected into Claude's context
**Behavior**:
1. Determine today's date and yesterday's date
2. Create today's daily log if it doesn't exist (with `# YYYY-MM-DD` header)
3. Create `~/.claude/memory/daily/` directory if missing
4. Output today's daily log (if non-empty beyond header)
5. Output yesterday's daily log (truncated to 100 lines)
6. Output recent learnings (last 50 lines)
7. Cap total output at 4000 chars
8. Exit 0 always (never block session start)

**Verification Criteria**:
- [ ] Creates today's daily log file if missing
- [ ] Creates memory/daily/ directory if missing
- [ ] Outputs today's daily log when it exists
- [ ] Outputs yesterday's log (truncated to 100 lines)
- [ ] Outputs nothing meaningful when no memory files exist
- [ ] Caps total output at 4000 characters
- [ ] Runs in under 100ms
- [ ] Exits 0 on all paths (including errors)
- [ ] Correctly computes yesterday's date across month/year boundaries

### 3.3 Stop Hook (Agent)

**Type**: `agent` hook on Stop, async non-blocking
**Prompt**: Delivered via settings.json hook config

The agent hook prompt instructs Claude to:
1. Read the session transcript
2. Read existing memory files (to avoid duplicates)
3. Extract and categorize learnings:
   - Daily context → append to `daily/YYYY-MM-DD.md`
   - Corrections → append to `learnings.md` with date
   - Stable preferences → update `preferences.md` (deduped, categorized)
   - User facts → update `user-profile.md`
4. Write nothing if nothing was learned

**Verification Criteria**:
- [ ] Reads existing memory files before writing (no duplicates)
- [ ] Correctly categorizes extractions
- [ ] Appends (never overwrites) daily logs and learnings
- [ ] Creates files/directories if they don't exist
- [ ] Writes nothing when session had no learnable content
- [ ] Each entry includes a date stamp
- [ ] Entries are concise (under 200 chars each)

### 3.4 `rules/memory-protocol.md`

**Purpose**: Detailed rules for memory behavior, loaded every session as a rule file.

**Contents**:
- Memory file layout and purpose of each file
- When to write vs. when not to write
- Dedup behavior (read before write)
- Formatting conventions
- Prohibition on removing existing entries

### 3.5 Memory File Formats

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

## YYYY-MM-DD
- (corrections and discoveries from this day's sessions)
```

**`daily/YYYY-MM-DD.md`**:
```markdown
# YYYY-MM-DD

## Session 1
- (key context, decisions, work done)
```

---

## 4. Settings.json Configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "agent",
            "prompt": "You just finished a session. Reflect on the conversation and update memory files.\n\nIMPORTANT: Read existing memory files FIRST to avoid duplicates.\n\n1. DAILY CONTEXT: Key decisions, work done, important context for continuity.\n   → Append to ~/.claude/memory/daily/$(date +%Y-%m-%d).md\n   Create the file if it doesn't exist (start with '# YYYY-MM-DD' header).\n   Add a new '## Session' section. Keep entries to 1-2 lines each.\n\n2. CORRECTIONS: Anything the user corrected you on.\n   → Append to ~/.claude/memory/learnings.md under today's date header.\n\n3. STABLE PREFERENCES: Tool choices, style preferences, workflow patterns the user demonstrated or stated. Only save genuinely new preferences not already in preferences.md.\n   → Update ~/.claude/memory/preferences.md under the right category.\n\n4. USER PROFILE: Any new facts about who the user is (name, role, projects, timezone).\n   → Update ~/.claude/memory/user-profile.md\n\nRules:\n- Read each file before writing to it. Do NOT duplicate existing entries.\n- Keep entries concise (1-2 lines each).\n- Use consistent markdown formatting.\n- If nothing new was learned, write nothing. Not every session teaches something.\n- Never remove existing entries, only append or update.\n- Create ~/.claude/memory/daily/ directory if it doesn't exist.",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

---

## 5. Implementation Order

### Phase 1: Foundation (this PR)
1. Create memory directory structure with template files
2. Write `CLAUDE.md` with `@import` and memory instructions
3. Write `rules/memory-protocol.md`
4. Implement `session-start.sh` with tests
5. Configure `settings.json` with session-start + stop agent hook

### Phase 2: Tuning (after real-world use)
6. Tune the stop hook prompt based on quality of extractions
7. Add pre-compact agent hook if context loss is observed
8. Adjust output caps and truncation limits
9. Add memory cleanup/archival for old daily logs

### Phase 3: Advanced (if needed)
10. Semantic search via MCP server (when memory exceeds ~10K lines)
11. Memory consolidation automation (weekly summary of daily logs)

---

## 6. Success Criteria

1. **Zero-config learning**: After 5 sessions, preferences.md has ≥3 real preferences the user never explicitly asked Claude to save.
2. **Cross-session continuity**: Starting a new session, Claude knows what you worked on yesterday without being told.
3. **Correction stickiness**: A correction made in session N is respected in session N+1 without reminder.
4. **Non-intrusive**: The user never sees memory operations during normal work.
5. **All tests pass**: `run-tests.sh` exits 0.
6. **Performance**: Session start adds <200ms latency. Stop hook is fully async.

---

## 7. Out of Scope (v1)

- Semantic/vector search
- MCP memory server
- Skills (/remember, /recall, /reflect, /daily, /bootstrap)
- Heartbeat/proactive agent
- Pre-compact hook (add in Phase 2 if needed)
- Memory cleanup automation
- Cross-platform messaging
