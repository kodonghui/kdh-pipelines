# EARS Requirement Template

All board meeting requirements MUST be expressed using one of the 5 EARS patterns. No `must / may / should / needs to` constructs. Each clause stands on its own (atomic).

## 5 Patterns

| Pattern | Structure | Use |
|---------|-----------|-----|
| **Ubiquitous** | `THE SYSTEM SHALL <action>.` | Always-true behavior |
| **Event-driven** | `WHEN <trigger>, THE SYSTEM SHALL <action>.` | On event |
| **State-driven** | `WHILE <state>, THE SYSTEM SHALL <action>.` | During state |
| **Unwanted** | `IF <exception>, THEN THE SYSTEM SHALL <action>.` | Error / edge case |
| **Optional** | `WHERE <feature-enabled>, THE SYSTEM SHALL <action>.` | Optional feature |

## Template

```markdown
## BRD-XXX — <Title>

**Target state:** STABLE | PROPOSED | CONTESTED | QUARANTINED | SUPERSEDED  (BRD-016 enum)
**Supersedes:** <BRD-YYY or null>
**Proposer:** A | B | C

> <EARS clauses — one per atomic requirement>

**Signatures (per role):**
| Role | Verdict | Text | UTC |
|------|---------|------|-----|
| A    | AGREE / AGREE-WITH-AMENDMENT / DISSENT | ... | ... |
| B    | AGREE / AGREE-WITH-AMENDMENT / DISSENT | ... | ... |
| C    | AGREE / AGREE-WITH-AMENDMENT / DISSENT | ... | ... |
```

## Example (Ubiquitous + Event-driven + Unwanted)

```markdown
## BRD-XXX — Example

**Target state:** PROPOSED
**Proposer:** A

> `THE SYSTEM SHALL` log every board tool invocation to `events/board-events.jsonl`.
> `WHEN` a canonical file is modified, `THE SYSTEM SHALL` invalidate `READY_TO_SHIP.token`.
> `IF` the token invalidation fails, `THEN THE SYSTEM SHALL` emit a CRITICAL severity issue.
```

## Atomization Rule (BRD-018 AMEND)

Every EARS clause SHALL decompose into a single (trigger → behavior) pair. `IF` one clause combines multiple independent actions, `THEN` split into separate numbered clauses. Signatures attach per `CLAUSE_ID`, not per BRD block.

## Forbidden Constructs

- `MUST` / `MAY` / `AND SHALL` / `MAY NOT` → use `THE SYSTEM SHALL` / `THE SYSTEM SHALL NOT` instead
- `should` / `needs to` → use EARS patterns
- `can` (permissive intent) → use `WHERE ... SHALL`
- Compound clauses with `AND` connecting multiple actions → split

## Target State Enum (BRD-016)

| State | Meaning | Publish Effect |
|-------|---------|----------------|
| STABLE | Ratified, in force | Included in publish |
| PROPOSED | Drafted, not yet signed | Not in publish |
| CONTESTED | DISSENT present | Not in publish until extension-round resolves |
| QUARANTINED | Post-ratify defect; 2-of-3 signed out | Excluded immediately |
| SUPERSEDED | Replaced by a newer BRD | Ignored; replacement in effect |
