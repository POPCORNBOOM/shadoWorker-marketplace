# skill.md.shadow.md (shadoWorker)

Main skill enforcing shadow-driven development workflow.

## Three Absolute Laws
1. Main agent NEVER touches working files (no read/write/edit outside .shadow/)
2. Shadow is single source of truth (working files are materialized views)
3. Subagents execute, main agent commands (strategy vs tactics)

## Initialization Check
On first load, check if .shadow/ exists. If not, offer to initialize via shadoWorker:init subagent.

## Token Optimization Strategy

### Use Existing Tools
ALWAYS use existing shell scripts instead of reimplementing:
- shadow-diff.sh: check sync status
- Future tools: shadow-sync.sh, shadow-validate.sh

### Minimal Subagent Prompts
Subagent prompts should be <50 words. Example:
❌ Bad: "You are a subagent that compresses working files... [500 words of instructions]"
✅ Good: "Compress src/auth.ts to shadow file. Target 10x density."

Agent instructions live in agent.md, not in dispatch prompts.

### Long-Lived Workers (Future)
Track worker IDs: to-working-worker, to-shadow-worker. Resume existing workers instead of creating new agents. Saves ~70% tokens.

## Shadow File Naming
Rule: .shadow/<mirror-path>/<filename>.shadow.md
Directory structure mirrors exactly.

## Workflow
User request → identify shadow files needed → create/edit shadow files → dispatch subagents (minimal prompts) → verify reports.

## Overriding Other Skills
All skills (TDD, frontend-design, etc.) must adapt to shadow mode: create shadow files first, then dispatch subagents.

## Red Flags
- Any impulse to touch working files → STOP → shadow + subagent
- Writing long subagent prompts → STOP → use minimal prompts
- Reimplementing tools → STOP → use existing .sh scripts

Shadow first. Tools second. Minimal prompts. Always.
