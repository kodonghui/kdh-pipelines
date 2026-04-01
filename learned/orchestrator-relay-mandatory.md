# Orchestrator Must Relay All Step Transitions

**Extracted:** 2026-03-23
**Context:** Team agents go idle after their turn and don't auto-wake on inbox messages

## Problem
Team agents (TeamCreate-based) stop after completing their current task. Even if another agent sends them a message via SendMessage, they remain idle until the orchestrator explicitly sends them a new message. This causes multi-hour stalls when writer sends [Fixes Applied] to critics but critics are already idle.

## Solution
The orchestrator MUST actively relay every step transition:
1. After writer sends [Review Request] → orchestrator sends "review this file" to each critic
2. After writer sends [Fixes Applied] → orchestrator sends "re-verify and score" to each critic
3. After all critics score → orchestrator sends "proceed to next step" to writer
4. Never rely on agent-to-agent direct messaging for step transitions

## Example
```
BAD:  writer → SendMessage → critic (critic is idle, never wakes)
GOOD: writer → SendMessage → critic + orchestrator → SendMessage → critic (orchestrator ensures wake-up)
```

## When to Use
Every time a team agent completes a task and the next agent needs to start. The 10-minute monitoring loop catches stalls, but proactive relay prevents them entirely.
