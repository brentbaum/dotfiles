# OpenClaw Memory Research → Claude Code Personal Assistant Plan

**Date**: 2026-02-15
**Goal**: Understand OpenClaw's memory and personality system, then design an equivalent for Claude Code that enables continuous learning of user preferences.

---

## Part 1: OpenClaw's Memory Implementation

### Overview

OpenClaw (formerly Clawdbot/Moltbot) is an open-source autonomous AI agent by Peter Steinberger. It uses a **file-first, Markdown-driven memory system** where plain Markdown files are the canonical source of truth. The agent only retains what gets written to disk.

### Two-Tier Memory Structure

**Tier 1: Daily Logs (Ephemeral Memory)**
- Location: `memory/YYYY-MM-DD.md` inside the workspace
- Append-only; a new file is created each day
- At session start, today's + yesterday's logs are loaded into context
- Captures running decisions, debugging sessions, temporary tasks

**Tier 2: Long-Term Memory (`MEMORY.md`)**
- Location: `MEMORY.md` at the workspace root
- Stores curated, stable information: user preferences, project conventions, critical decisions
- Only loaded in private sessions (never in group contexts)
- Optional (not auto-created)

### Workspace Directory Layout

```
~/.openclaw/workspace/
├── openclaw.json          # Main configuration
├── AGENTS.md              # Operating instructions & behavioral rules
├── SOUL.md                # Personality, tone, values, boundaries
├── USER.md                # User profile & preferences
├── IDENTITY.md            # Agent name, role, goals, emoji, avatar
├── TOOLS.md               # Local tool notes & environment config
├── HEARTBEAT.md           # Background periodic task checklist
├── BOOT.md                # Gateway restart checklist (optional)
├── BOOTSTRAP.md           # First-run interview script (deleted after)
├── MEMORY.md              # Long-term curated memory
└── memory/
    ├── 2026-02-14.md      # Yesterday's daily log
    └── 2026-02-15.md      # Today's daily log
```

### Semantic Search System

OpenClaw implements a sophisticated hybrid retrieval system:

| Component | Implementation | Weight |
|-----------|---------------|--------|
| Vector search | SQLite + sqlite-vec extension, cosine similarity | 70% default |
| BM25 full-text | SQLite FTS5 virtual table | 30% default |
| Embedding providers | OpenAI → Gemini → Voyage → Local (node-llama-cpp) → BM25-only fallback |
| Storage | `~/.openclaw/memory/{agentId}.sqlite` |
| Chunking | 400 tokens per chunk, 80 token overlap |
| Search defaults | maxResults: 6, minScore: 0.35 |

Two tools exposed to the agent:
- **`memory_search`** — semantic search with citations (`path#L{start}-L{end}`)
- **`memory_get`** — exact file content retrieval by path and line range

### Pre-Compaction Memory Flush

When a session approaches the context window limit, OpenClaw triggers a **silent agentic turn** that prompts the model to write durable memories to disk before context is compacted:

```
Trigger: contextWindow - reserveTokensFloor(20000) - softThresholdTokens(4000)
Runs: Once per compaction cycle (tracked in sessions.json)
Prompt: "Pre-compaction memory flush. Store durable memories now
         (use memory/YYYY-MM-DD.md). If nothing to store, reply NO_REPLY."
```

This turns a destructive context-truncation operation into a checkpoint.

### Heartbeat System (Proactive Operation)

A background daemon runs on a configurable interval (default: 30 minutes):

1. Timer fires → check active hours (timezone-aware)
2. Check if HEARTBEAT.md has actionable content (skip empty/comments)
3. Run agent with heartbeat prompt
4. If response is `HEARTBEAT_OK` (≤300 chars), drop silently
5. Otherwise, deliver message to configured target

Enables proactive behavior: reminders, status checks, monitoring.

### Continuous Learning Mechanisms

1. **Self-Improving Agent Skill** — captures errors, corrections, capability gaps in `.learnings/` directory
2. **Autonomous Skill Creation** — agent writes its own new skills in Markdown or TypeScript
3. **OpenClaw Foundry** — when a pattern reaches 5+ uses with 70%+ success rate, crystallizes it into a dedicated tool
4. **Third-Party Memory Plugins** — Mem0 (user-scoped long-term memory), Supermemory (semantic retrieval injection)

---

## Part 2: OpenClaw's Supplementary Markdown Files ("Programmable Soul")

All files are injected into the system prompt at session start:

| File | Purpose | Key Details |
|------|---------|-------------|
| **SOUL.md** | Personality, tone, values, behavioral philosophy | 8KB template. Core truths: "Be genuinely helpful, not performatively helpful." "Have opinions." "Be resourceful before asking." |
| **AGENTS.md** | Operating instructions, rules, priorities | 8KB. Session startup ritual, memory file layout, safety guidelines, group chat behavior, emoji reactions, memory maintenance |
| **USER.md** | Human profile: name, pronouns, timezone, communication style | 567B template. Built iteratively through conversation |
| **IDENTITY.md** | Agent's name, creature type, vibe, emoji, avatar | 728B. Filled during BOOTSTRAP.md first-run interview |
| **TOOLS.md** | Local tool notes (camera names, SSH hosts, TTS voices) | 989B. Agent's environment cheat sheet |
| **HEARTBEAT.md** | Periodic task checklist | 305B. Keep short to avoid token burn |
| **BOOT.md** | Gateway restart checklist | Optional. Requires hooks enabled |
| **BOOTSTRAP.md** | First-run onboarding interview | 1.6KB. Determines agent identity. Auto-deleted after setup |
| **MEMORY.md** | Long-lived persistent facts, compressed history | Optional. Only loaded in direct/private sessions |

**Resolution cascade**: Global → Agent → Workspace → Default (most specific wins).

---

## Part 3: What's OpenClaw-Specific vs. Portable to Claude Code

### Directly Portable (Claude Code has native equivalents)

| OpenClaw Feature | Claude Code Equivalent | Notes |
|------------------|----------------------|-------|
| SOUL.md (personality) | `~/.claude/CLAUDE.md` | User-level, loaded every session |
| AGENTS.md (instructions) | `.claude/CLAUDE.md` or `.claude/rules/*.md` | Project-level rules |
| USER.md (user profile) | `~/.claude/CLAUDE.md` sections | Can be a section in user CLAUDE.md |
| MEMORY.md (long-term) | `~/.claude/projects/<hash>/memory/MEMORY.md` | Auto memory, first 200 lines loaded |
| Skills system | `~/.claude/skills/<name>/SKILL.md` | Native skill system with frontmatter |
| First-run onboarding | SessionStart hook + skill | Can build an equivalent bootstrap flow |
| Daily context loading | SessionStart hook | `cat` memory files on startup |
| Tool notes | `.claude/rules/tools.md` | Modular rules files |

### Portable with Extra Work (requires hooks/MCP/skills)

| OpenClaw Feature | Claude Code Approach | Complexity |
|------------------|---------------------|------------|
| Daily logs (`memory/YYYY-MM-DD.md`) | SessionStart hook to create/load daily file + skill to append | Medium |
| Pre-compaction flush | PreCompact hook (type: "agent") that writes to memory files | Medium |
| Semantic memory search | MCP server with SQLite + embeddings | High |
| Self-improving agent | PostToolUse hook + skill to capture learnings | Medium |
| Session transcripts indexing | MCP server reading `~/.claude/projects/*/transcript.jsonl` | High |
| Hybrid BM25+vector search | MCP server implementing both search backends | High |

### NOT Portable (OpenClaw-specific architecture)

| OpenClaw Feature | Why Not Portable | Alternative |
|------------------|-----------------|-------------|
| **Heartbeat daemon** | Claude Code is CLI, not a persistent gateway/daemon | Cron job + `claude --print` for periodic checks |
| **Cross-platform messaging** (WhatsApp, Telegram, Discord) | Claude Code is terminal-only | N/A — different product category |
| **Group chat behavior** | No multi-user sessions in Claude Code | N/A |
| **Emoji reactions** | No chat platform integration | N/A |
| **Gateway restart hooks (BOOT.md)** | No persistent gateway process | SessionStart hook serves similar purpose |
| **OpenClaw Foundry** (auto-crystallize patterns into tools) | Would require custom external tooling | Could build a lightweight version via MCP |
| **QMD sidecar** (advanced search backend) | OpenClaw-specific binary | Use standard MCP server instead |
| **Active hours** (timezone-aware scheduling) | No daemon to enforce schedule | Cron-level scheduling if needed |

---

## Part 4: Claude Code Personal Assistant Design Plan

### Architecture Overview

```
~/.claude/
├── CLAUDE.md                          # SOUL + USER equivalent (personality + preferences)
├── settings.json                      # Hooks configuration
├── rules/
│   └── assistant.md                   # Operating instructions (AGENTS.md equivalent)
├── skills/
│   ├── remember/SKILL.md             # /remember — save a preference or learning
│   ├── recall/SKILL.md               # /recall — search memory
│   ├── daily/SKILL.md                # /daily — daily log management
│   ├── reflect/SKILL.md              # /reflect — session summary + memory update
│   └── bootstrap/SKILL.md           # /bootstrap — first-run onboarding
├── memory/
│   ├── soul.md                        # Personality, tone, values
│   ├── user-profile.md               # Who I am, preferences, constraints
│   ├── preferences.md                 # Tool/workflow preferences
│   ├── learnings.md                   # Captured learnings and corrections
│   ├── known-issues.md               # Project gotchas
│   └── daily/
│       ├── 2026-02-14.md             # Yesterday's log
│       └── 2026-02-15.md             # Today's log
└── hooks/
    ├── session-start.sh               # Load memory context on startup
    ├── pre-compact.sh                 # Flush important context before compaction
    └── track-learnings.sh            # Capture patterns from tool usage
```

### Implementation Components

#### 1. `~/.claude/CLAUDE.md` — Soul + User Profile (loaded every session)

Combines SOUL.md + USER.md + core operating instructions. This is the always-loaded personality layer.

```markdown
# Personal Assistant Configuration

## Who I Am (User Profile)
- Name: [filled during bootstrap]
- Timezone: [filled during bootstrap]
- Communication style: [learned over time]

## Assistant Personality
- Be genuinely helpful, not performatively helpful
- Have opinions — an assistant with no personality is just a search engine
- Be resourceful before asking — read files, check context, search first
- Keep responses direct and concise unless I ask for detail
- Remember context from our previous sessions via memory files

## Memory Protocol
- At session start, read today's daily log and yesterday's if it exists
- When I share a preference, tool choice, or workflow, save it to memory
- Before context compaction, flush important learnings to daily log
- When corrected, capture the learning in learnings.md

## Memory Files Location
All memory lives in ~/.claude/memory/ — read these to know me better:
- soul.md: your personality guidelines
- user-profile.md: who I am
- preferences.md: my tool and workflow preferences
- learnings.md: things you've learned working with me
- daily/YYYY-MM-DD.md: today's running context
```

#### 2. `~/.claude/rules/assistant.md` — Operating Instructions

```markdown
# Operating Instructions

## Session Startup
1. Read ~/.claude/memory/daily/$(date +%Y-%m-%d).md if it exists
2. Read ~/.claude/memory/daily/$(date -d yesterday +%Y-%m-%d).md if it exists
3. Read ~/.claude/memory/user-profile.md for user context
4. Read ~/.claude/memory/preferences.md for workflow preferences

## When to Update Memory
- User explicitly says "remember this" → use /remember skill
- User corrects you → append to learnings.md
- Session ending with important context → update daily log
- New preference discovered → update preferences.md

## File Layout
- Keep daily logs focused on today's work
- Keep preferences.md organized by category
- Keep learnings.md chronological with timestamps
```

#### 3. Skills

**`/remember`** — Save a preference, fact, or learning
```yaml
---
name: remember
description: Save important information to memory for future sessions
user-invocable: true
allowed-tools: Read, Write, Edit
---
```

**`/recall`** — Search through memory files
```yaml
---
name: recall
description: Search through memory files for previously saved information
user-invocable: true
allowed-tools: Read, Glob, Grep
---
```

**`/daily`** — Manage today's daily log
```yaml
---
name: daily
description: View or append to today's daily context log
user-invocable: true
allowed-tools: Read, Write, Edit, Bash
---
```

**`/reflect`** — End-of-session summary and memory consolidation
```yaml
---
name: reflect
description: Summarize session learnings and update long-term memory
user-invocable: true
allowed-tools: Read, Write, Edit
---
```

**`/bootstrap`** — First-run onboarding interview
```yaml
---
name: bootstrap
description: First-run setup to learn about the user and configure the assistant
user-invocable: true
allowed-tools: Read, Write, Edit
---
```

#### 4. Hooks Configuration (`~/.claude/settings.json`)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-compact.sh"
          }
        ]
      }
    ]
  }
}
```

**`session-start.sh`** — Load memory context:
```bash
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
MEMORY_DIR="$HOME/.claude/memory"

echo "=== Daily Context ==="
[ -f "$MEMORY_DIR/daily/$TODAY.md" ] && cat "$MEMORY_DIR/daily/$TODAY.md"
[ -f "$MEMORY_DIR/daily/$YESTERDAY.md" ] && echo "--- Yesterday ---" && cat "$MEMORY_DIR/daily/$YESTERDAY.md"
echo "=== User Profile ==="
[ -f "$MEMORY_DIR/user-profile.md" ] && cat "$MEMORY_DIR/user-profile.md"
echo "=== Preferences ==="
[ -f "$MEMORY_DIR/preferences.md" ] && cat "$MEMORY_DIR/preferences.md"
```

**`pre-compact.sh`** — Reminder to flush before compaction:
```bash
#!/bin/bash
echo "IMPORTANT: Context compaction is about to occur."
echo "If there are important learnings or decisions from this session,"
echo "use /reflect or /remember to save them before they are lost."
```

#### 5. Future Enhancement: MCP Memory Server

For semantic search (the one high-value OpenClaw feature that requires more than files):

```
claude mcp add --transport stdio memory-search -- python ~/.claude/memory-server.py
```

This would provide:
- `memory_search` tool — semantic search over all memory files
- `memory_index` tool — re-index memory files
- SQLite + embeddings backend (matching OpenClaw's architecture)
- BM25 + vector hybrid search

This is the highest-effort item but also the most impactful for a large memory corpus.

---

## Part 5: Implementation Priority

### Phase 1: Foundation (Immediate)
1. Create `~/.claude/memory/` directory structure
2. Write `~/.claude/CLAUDE.md` with soul + user profile
3. Write `~/.claude/rules/assistant.md` with operating instructions
4. Create `/bootstrap` skill for first-run onboarding
5. Create `/remember` skill
6. Create `/recall` skill (grep-based)
7. Configure SessionStart hook to load daily context

### Phase 2: Daily Workflow (Next)
8. Create `/daily` skill for daily log management
9. Create `/reflect` skill for session-end consolidation
10. Configure PreCompact hook for memory flush reminder
11. Build learning capture into hook pipeline

### Phase 3: Advanced (Later)
12. MCP memory server with SQLite + embeddings
13. Semantic search via `memory_search` tool
14. Periodic memory consolidation (daily → long-term promotion)
15. Lightweight "Foundry" equivalent — track repeated patterns

---

## Appendix: OpenClaw Source Paths Referenced

| Component | Path in OpenClaw repo |
|-----------|----------------------|
| Memory schema | `src/memory/memory-schema.ts` |
| Vector search | `src/memory/manager-search.ts` |
| Hybrid merge | `src/memory/hybrid.ts` |
| Embedding providers | `src/memory/embeddings.ts` |
| Memory flush | `src/auto-reply/reply/memory-flush.ts` |
| Memory tools | `src/agents/tools/memory-tool.ts` |
| Heartbeat | `src/infra/heartbeat-runner.ts` |
| Compaction | `src/agents/compaction.ts` |
| Skills workspace | `src/agents/skills/workspace.ts` |
| Session management | `src/config/sessions.ts` |
| Templates | `docs/reference/templates/` |
