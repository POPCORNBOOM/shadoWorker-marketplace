---
name: shadoWorker
description: Shadow-driven development workflow - main agent operates only on high-density shadow files, dispatching subagents for all working directory operations
trigger: Use when user wants to work in shadow-driven mode, or when dealing with large projects that need global context
---

# shadoWorker: The Absolute Iron Laws

**CRITICAL: Once this skill is loaded, ALL other skills and workflows MUST operate through the shadow layer. No exceptions.**

## Initialization Check (First Time)

**When this skill loads, IMMEDIATELY check:**

```bash
# Check if .shadow/ directory exists
ls -la .shadow/ 2>/dev/null
```

### If `.shadow/` does NOT exist:

**You say:**
```
"I notice this project hasn't been initialized for shadow-driven development.

I can set up the shadow system now:
1. Create .shadow/ directory
2. Create .shadowignore with common patterns
3. Scan project and create shadow files for existing code

This will help me understand your project structure. Proceed with initialization?"
```

**If user agrees:**

1. **Create .shadow/ directory:**
```bash
mkdir -p .shadow
```

2. **Create .shadowignore:**
```bash
cat > .shadowignore << 'EOF'
# Build outputs
build/
dist/
out/
*.min.js
*.min.css

# Dependencies
node_modules/
vendor/
packages/

# Temporary files
*.tmp
*.log
*.swp
*~

# Environment files
.env
.env.local
.env.*.local

# IDE files
.vscode/
.idea/
*.sublime-*

# OS files
.DS_Store
Thumbs.db

# Test coverage
coverage/
.nyc_output/

# Add your project-specific ignores below:
EOF
```

3. **Scan project files:**
```bash
# Find all files, excluding common ignores
find . -type f \
  -not -path "./.git/*" \
  -not -path "./.shadow/*" \
  -not -path "./node_modules/*" \
  -not -path "./build/*" \
  -not -path "./dist/*" \
  | head -50
```

4. **Ask user:**
```
"Found X files in the project. Should I:
A) Create shadow files for all of them now (may take time)
B) Start with just the main files (you tell me which)
C) Skip for now (you'll create shadows as needed)
"
```

5. **If user chooses A or B:**
   - Dispatch multiple `to-shadow` subagents in parallel (max 10 at a time)
   - Each subagent reads one working file and creates its shadow
   - Report progress: "Created 15/50 shadow files..."

6. **Initialization complete:**
```
"Shadow system initialized!
- .shadow/ directory created
- .shadowignore configured
- X shadow files created

You can now work in shadow-driven mode. All changes will go through shadow files."
```

### If `.shadow/` DOES exist:

**You say:**
```
"Shadow system detected. Operating in shadow-driven mode.
All operations will go through .shadow/ directory."
```

Then proceed to normal workflow.

---

## The Three Absolute Laws

### Law 1: You NEVER Touch Working Files
**FORBIDDEN ACTIONS:**
- ❌ Reading ANY file outside `.shadow/`
- ❌ Writing ANY file outside `.shadow/`
- ❌ Using Write tool on working files
- ❌ Using Edit tool on working files
- ❌ Using Read tool on working files
- ❌ Executing ANY operation that modifies working directory

**ONLY ALLOWED:**
- ✅ Read/Write/Edit files in `.shadow/` directory ONLY
- ✅ Run shadow-diff tool (read-only check)
- ✅ Dispatch to-working subagents

**When you catch yourself about to:**
- "Let me write this code to..."
- "I'll create this file..."
- "Let me edit this function..."
- "I'll read the current implementation..."

**STOP IMMEDIATELY. Instead:**
1. Create/edit the corresponding `.shadow.md` file
2. Dispatch to-working subagent

### Law 2: Shadow is the Single Source of Truth
**ALL ginate in `.shadow/` directory.**

Working files are merely **materialized views** of shadow intent. They have no independent existence.

**Workflow:**
```
User request → You modify .shadow/ → Dispatch subagent → Subagent modifies working/
```

**NEVER:**
```
User request → You modify working/ directly
```

### Law 3: Subagents Execute, You Command
**Your job:** Strategic planning in shadow layer
**Subagent's job:** Tactical execution in working layer

You are the architect drawing blueprints (shadow files).
Subagents are the builders constructing buildings (working files).

**Architects don't pick up hammers.**

---

## Worker Agent Management (Token Optimization)

**IMPORTANT: Use long-lived worker agents to save tokens.**

### On First Use (Per Session)

When you need to-working or to-shadow for the FIRST time in a session:

```
Dispatch new agent and SAVE the agentId:
- to-working-worker-id: <agentId from first to-working dispatch>
- to-shadow-worker-id: <agentId from first to-shadow dispatch>
```

### On Subsequent Uses

**ALWAYS resume the existing worker instead of creating new agents:**

```
Agent({
  description: "Convert shadow to working",
  prompt: "Task: Create src/auth.ts from .shadow/src/auth.ts.shadow.md

  Shadow content:
  [paste shadow content here]

  Target: src/auth.ts
  Operation: create",
  resume: "<to-working-worker-id>"  // ← Resume existing worker
})
```

### Benefits

**Without resume (wasteful):**
```
Every dispatch = Full agent prompt (200+ tokens) + task
10 files = 2000+ tokens just for prompts
```

**With resume (efficient):**
```
First dispatch = Full agent prompt (200+ tokens) + task
Next 9 dispatches = Only task description (50 tokens each)
10 files = 200 + 450 = 650 tokens (70% savings!)
```

### Implementaon Pattern

**Track worker IDs in your working memory:**
```
Session state:
- to-working-worker: "agent-abc123" (initialized)
- to-shadow-worker: "agent-def456" (initialized)
```

**When dispatching:**
```python
if to-working-worker exists:
    resume to-working-worker with new task
else:
    dispatch new to-working agent
    save agentId as to-working-worker
```

### Worker Lifecycle

**Workers persist for the entire session.**

If a worker fails or returns an error:
- Don't resume it
- Dispatch a fresh worker
- Update the worker ID

---

## Critical: Overriding Other Skills

**If you have loaded other skills (TDD, frontend-design, etc.), they MUST be adapted to shadow mode:**

### Example: TDD Skill + shadoWorker

**❌ WRONG (Normal TDD):**
```
1. Write failing test in tests/auth.test.ts
2. Run test
3. Write implementation in src/auth.ts
4. Run test again
```

**✅ CORRECT (Shadow TDD):**
```
1. Create .shadow/tests/auth.test.ts.shadow.md with test description
2. Dispatch subagent to create tests/auth.test.ts
3. Run test (via subagent report)
4. Create .shadow/src/auth.ts.shadow.md with implementation description
5. Dispatch subagent to create src/auth.ts
6. Run test again (via subagent report)
```

### Example: Frontend-Design Skill + shadoWorker

**❌ WRONG (Normal frontend-design):**
```
1. Create components/Button.tsx directly
2. Write JSX code
3. Add styles
```

**✅ CORRECT (Shadow frontend-design):**
```
1. Create .shadow/components/Button.tsx.shadow.md:
   "Button component. Props: variant (primary/secondary), onClick handler.
    Styled with Tailwind. Accessible with ARIA labels."
2. Dispatch subagent to create components/Button.tsx
```

### Example: Any Code Writing Task

**❌ WRONG:**
```
User: "Add login function"
You: *writes code directly to src/auth.ts*
```

**✅ CORRECT:**
```
User: "Add lognction"
You:
  1. Create .shadow/src/auth.ts.shadow.md:
     "login(username, password) → JWT token
      Validates against database, returns signed token"
  2. Dispatch to-working subagent
```

---

## Shadow File Naming Convention

**CRITICAL: Strict naming rules**

### For Code Files
```
Working file:  src/auth.ts
Shadow file:   .shadow/src/auth.ts.shadow.md
```

### For Any File Type
```
Working file:  novel/chapter-01.md
Shadow file:   .shadow/novel/chapter-01.md.shadow.md

Working file:  config/database.json
Shadow file:   .shadow/config/database.json.shadow.md

Working file:  docs/api.md
Shadow file:   .shadow/docs/api.md.shadow.md
```

**Rule:** `.shadow/<mirror-path>/<filename>.shadow.md`

**Directory structure MUST mirror exactly:**
```
project/
├── src/
│   ├── auth.ts          ← working file
│   └── user.ts          ← working file
└── .shadow/
    └── src/
        ├── auth.ts.shadow.md    ← shadow file
        └── user.ts.shadow.md    ← shadow file
```

---

## Your Workflow (Step by Step)

### When User Says: "Add feature X"

**Step 1: Identify what shadow files are needed**
```
User: "Add user authentication"

You think:
- Need .shadow/src/auth/login.ts.shadow.md
- Need .shadow/src/auth/register.ts.shadow.md
- Need .shadow/src/auth/token.ts.shadow.md
```

**Step 2: Ask user for confirmation (if >5 files)**
```
You: "I'll create 3 shadow files for authentication:
- login.ts.shadow.md
- register.ts.shadow.md
- token.ts.shadow.md

Should I proceed?"
```

**Step 3: Create shadow files**
```bash
# You use Write tool ONLY on .shadow/ directory
Write(.shadow/src/auth/login.ts.shadow.md):
  "login(username, password) → JWT token
   Validates credentials, returns signed token
   Errors: 404 user not found, 401 wrong password"
```

**Step 4: Dispatch subagents (with resume optimization)**
```
# First file - create new worker if needed
if no to-working-worker exists:
  Agent({
    description: "Create login.ts",
    prompt: "Create src/auth/login.ts from shadow...",
    subagent_type: "to-working"
  })
  Save agentId as to-working-worker
else:
  Agent({
    description: "Create login.ts",
    prompt: "Create src/auth/login.ts from shadow...",
    resume: to-working-worker
  })

# Second file - resume existing worker
Agent({
  description: "Create register.ts",
  prompt: "Create src/auth/register.ts from shadow...",
  resume: to-working-worker  // ← Reuse same worker
})

# Third file - resume again
Agent({
  description: "Create token.ts",
  prompt: "Create src/auth/token.ts from shadow...",
  resume: to-working-worker  // ← Reuse same worker
})
```

**Step 5: Verify through reports**
```
Worker reports: "Createdth JWT authentication (45 lines)"
Worker reports: "Created register.ts with user validation (38 lines)"
Worker reports: "Created token.ts with JWT signing (29 lines)"
You: "Authentication module created successfully."
```

### When User Says: "Fix bug in X"

**Step 1: Understand the issue (via subagent)**
```
User: "Login function returns wrong error code"

You: Dispatch subagent to read src/auth/login.ts and report current behavior
Subagent: "Returns 500 for wrong password, should be 401"
```

**Step 2: Update shadow file**
```
You: Edit .shadow/src/auth/login.ts.shadow.md
Change: "Errors: 500 for wrong password"
To: "Errors: 401 for wrong password"
```

**Step 3: Dispatch subagent to fix (resume worker)**
```
Agent({
  description: "Fix login error code",
  prompt: "Update src/auth/login.ts based on shadow changes...",
  resume: to-working-worker  // ← Reuse existing worker
})
Worker: "Updated login.ts, changed error code to 401"
```

### When User Says: "Write a novel"

**❌ WRONG:**
```
You: *creates 50 shadow files immediately*
```

**✅ CORRECT:**
```
You: "I'll start with a novel outline. Should I create shadow files for all chapters now, or start with the outline first?"

User: "Create all chapters"

You: "Creating shadow files for 10 chapters..."
*Creates .shadow/novel/chapter-01.md.shadow.md through chapter-10.md.shadow.md*

You: "Shadow files created. Ready to materialize chapters into full text?"

User: "Yes"

You: *Initialize worker if needed, then dispatch in batches*
# First chapter - create worker
Agent({
  description: "Generate chapter 1",
  prompt: "Create novel/chapter-01.md from shadow...",
  subagent_type: "to-working"
})
Save agentId as to-working-worker

# Remaining chapters - resume worker (huge token savings!)
for chapters 2-10:
  Agent({
    description: "Generate chapter N",
    prompt: "Create novel/chapter-N.md from shadow...",
    resume: to-working-worker  // ← Reuse same worker
  })
```

**Token savings: ~1800 tokens for 10 chapters!**

---

## Catching Yourself

**Red flags that you're about to violate the laws:**

| Your thought | What you should do instead |
|--------------|---------------------------|
| "Let me write this code..." | Create shadow file, dispatch subagent |
| "I'll create this file..." | Create shadow file, dispatch subagent |
| "Let me read the current implementation..." | Dispatch subagent to report |
| "I'll edit this function..." | Edit shadow file, dispatch subagent |
| "Let me add this import..." | Update shadow file, dispatch subagent |
| "I'll fix this typo..." | Update shadow file, dispatch subagent |

**ANY impulse to touch working files → STOP → Shadow + Subagent**

---

## Remember

You are **permanently in shadow mode** once this skill is loaded.

**Your hands are tied.** You CANNOT touch working files.

**Your power is in coordination:**
- Read shadow files (instant global context)
- Plan in shadow files (high-density strategy)
- Dispatch subagents (parallel execution)

**Every. Single. Change. Goes. Through. Shadow.**

No shortcuts. No exceptions. No "just this once."

**Shadow first. Always.**
