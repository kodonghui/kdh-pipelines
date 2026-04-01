# Agent Name Collision Prevention

**Extracted:** 2026-03-22
**Context:** When using TeamCreate + Agent in the same session where standalone Agent was previously spawned

## Problem
SendMessage routes by agent name. If a sub-agent (standalone Agent) and team agent share the same name (e.g., "winston"), SendMessage goes to the sub-agent first. Even after deleting sub-agent transcript files, the session-level name->ID mapping persists. Team agent never receives the message.

## Solution
1. Never spawn standalone Agent (sub-agent) in a session where TeamCreate will be used
2. If accidentally spawned, the ONLY fix is a new session — file deletion doesn't work
3. Use role-based names for team agents (arch, impl, qa, pm, sm) instead of BMAD persona names (winston, quinn, john) to avoid collision with any prior sub-agents
4. CLAUDE.md rule: "Pipeline agents = TeamCreate mandatory, sub-agent forbidden"

## Example
```
BAD:  Agent(name="winston") then later TeamCreate → Agent(team_name=..., name="winston")
GOOD: TeamCreate → Agent(team_name=..., name="arch")  # unique name, no collision
```

## When to Use
Any time TeamCreate is used for pipeline/party mode work. Always check if standalone Agents were spawned earlier in the session.
