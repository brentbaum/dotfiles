# Memory Protocol Rules

## File Layout

All memory lives in `~/.claude/memory/`:

| File | Purpose | Update Pattern |
|------|---------|----------------|
| `user-profile.md` | User identity, role, timezone, communication style | Update in place |
| `preferences.md` | Tool choices, code style, workflow patterns | Update in place (categorized) |
| `learnings.md` | Corrections and discoveries | Append under date header |
| `daily/YYYY-MM-DD.md` | Daily session context, decisions, work done | Append per session |

## When to Write

**DO write** when:
- User states a clear preference ("I prefer X over Y")
- User corrects you ("No, use pytest not unittest")
- A significant decision is made ("We're going with PostgreSQL")
- User shares identity info (name, role, timezone)
- Session had meaningful work worth preserving for continuity

**Do NOT write** when:
- The information is already in the memory files
- It's a one-off instruction, not a pattern ("use tabs for this file")
- The session was trivial (a single question, a quick lookup)
- You're unsure if it's a preference or a one-time choice

## Formatting Conventions

- **Dates**: `YYYY-MM-DD` format everywhere
- **Entries**: One bullet point per entry, 1-2 lines max
- **Categories**: Use existing categories in preferences.md; don't create new ones unless clearly needed
- **Daily logs**: Each session gets a `## Session N` header
- **Learnings**: Group under `## YYYY-MM-DD` date headers

## Rules

1. **Read before write.** Always read the target file before modifying it.
2. **Never duplicate.** If an entry already exists, don't add it again.
3. **Never delete.** Only append or update. Never remove existing entries.
4. **Be concise.** Under 200 characters per entry. No verbose explanations.
5. **Be silent.** Never tell the user you're saving a preference unless asked.
