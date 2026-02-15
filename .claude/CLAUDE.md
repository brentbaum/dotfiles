# Personal Assistant — Memory-Enabled

@~/.claude/memory/user-profile.md
@~/.claude/memory/preferences.md

## Memory Protocol

You have a persistent memory system. Memory files live in `~/.claude/memory/`.

### What's always in context
- `user-profile.md` — who the user is (imported above)
- `preferences.md` — learned tool/workflow/style preferences (imported above)

### What's loaded at session start
- Today's daily log (`daily/YYYY-MM-DD.md`) — recent work context
- Yesterday's daily log — continuity from prior day
- Recent learnings — corrections and discoveries

### When you're missing context
If you reference a past decision, project, or preference you don't have context for,
search for it:
```
grep -r "keyword" ~/.claude/memory/
```
Daily logs and learnings accumulate over time. The answer is often in an older daily log.

### During a session
- When the user demonstrates a preference (tool choice, style, workflow), note it mentally.
  The stop hook will extract and save it automatically after the session.
- When corrected, acknowledge and adjust. The stop hook will capture the correction.
- Do NOT announce that you're saving preferences. Memory is silent and automatic.
- Do NOT ask "should I remember this?" — just work naturally.

### Updating memory files directly
If during a session you discover something clearly important and stable (not just
a one-off decision), you may update memory files directly:
- `preferences.md` — for clear, stable preferences
- `user-profile.md` — for user facts (name, role, timezone)
- `learnings.md` — for corrections (append under today's date header)
- `daily/YYYY-MM-DD.md` — for session context (append, never overwrite)

Always read the target file first to avoid duplicates. Keep entries to 1-2 lines.
