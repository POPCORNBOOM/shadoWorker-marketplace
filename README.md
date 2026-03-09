# Shadoworker Plugin

A shadow-driven development system for Claude Code that enables efficient work on large-scale projects through high-density information compression.

## What is Shadoworker?

Shadoworker is a development pattern that maintains a parallel "shadow directory" containing compressed, high-density representations of your working files. These shadow files contain 10x the information density of regular files, allowing AI agents to maintain global context without overwhelming their working memory.

**Key Benefits:**
- Work efficiently on large codebases without losing context
- Maintain strategic oversight while delegating tactical execution
- Keep AI agents focused on architecture rather than implementation details
- Scale to projects with thousands of files

**Use Cases:**
- Large codebase development (Vibe Coding at scale)
- Novel writing and long-form content creation
- Comprehensive documentation projects
- Any work requiring massive context management

## Core Concepts

### The Three Iron Rules

1. **Main agent never touches working files** - Only operates on shadow files
2. **Shadow drives working** - Shadow files are the single source of truth
3. **All working file changes go through subagents** - Strategy and execution are strictly separated

### Information Density

Shadow files compress information by 10x using clear, concise natural language. They're free-form and adapt to content type, focusing on intent and architecture rather than implementation details.

### Granularity Principle

**Prefer many small shadow files over few large ones.**

Why?
- More precise change control
- Higher concurrency (more parallel subagents)
- Clearer separation of concerns
- Lower context consumption

Example:
```
❌ Bad: One large file
.shadow/src/auth.ts.shadow.md  (login, register, tokens, permissions)

✅ Good: Multiple focused files
.shadow/src/auth/login.ts.shadow.md
.shadow/src/auth/register.ts.shadow.md
.shadow/src/auth/token.ts.shadow.md
.shadow/src/auth/permissions.ts.shadow.md
```

## Installation

### For Claude Code CLI

1. Copy the `shadoWorker` directory to your Claude Code plugins directory:
   ```bash
   # Unix/Linux/macOS
   cp -r shadoWorker ~/.claude/plugins/

   # Windows
   xcopy shadoWorker %USERPROFILE%\.claude\plugins\shadoWorker\ /E /I
   ```

2. Restart Claude Code or reload plugins

3. Verify installation:
   ```
   You: "Load shadoWorker skill"
   ```

### Manual Installation

Place the `shadoWorker` directory in your Claude Code plugins directory:
- Unix/Linux/macOS: `~/.claude/plugins/shadoWorker/`
- Windows: `%USERPROFILE%\.claude\plugins\shadoWorker\`

The plugin includes:
- Skills: `shadoWorker`
- Agents: `shadoWorker:init`, `shadoWorker:to-working`, `shadoWorker:to-shadow`
- Tools: `shadow-diff.sh`, `shadow-diff.ps1`

## Quick Start

### Initialize an Existing Project

```
You: "Initialize shadow system for this project"
```

The shadoWorker:init agent will:
1. Create `.shadow/` directory structure
2. Generate `.shadowignore` template
3. Scan your project and create initial shadow files
4. Provide initialization report

### Daily Workflow

```
You: "Add user authentication feature"
```

The main agent (using shadoWorker skill) will:
1. Read shadow directory to understand project structure
2. Plan changes in shadow files (creating multiple small files)
3. Dispatch parallel shadoWorker:to-working subagents
4. Collect reports and verify results

### Check Sync Status

```
You: "Check shadow sync status"
```

The agent will run shadow-diff to identify:
- Shadow files missing working counterparts
- Working files missing shadow counterparts
- Suggest sync actions

## Components

### shadoWorker Skill

The main skill that guides agent behavior. It:
- Enforces the three iron rules
- Encourages small, focused shadow files
- Defines best practices for shadow-driven development
- Coordinates subagent dispatch

### shadoWorker:init Agent

Initializes shadow system for existing projects.

**Input:** Project root directory path

**Output:** Initialization report with file counts

**Behavior:**
- Creates directory structure
- Generates `.shadowignore` from template
- Scans working directory
- Creates initial shadow files (prefers splitting large files)

### shadoWorker:to-working Agent

Materializes shadow changes into working files.

**Input:**
- Shadow file path and content
- Target working file path
- Operation type (create/update/delete)

**Output:**
- Operation result (success/failure)
- Brief report (1-3 sentences)

**Behavior:**
- Operates on one file at a time
- Translates high-density shadow into full implementation
- Reports errors honestly for main agent to fix

### shadoWorker:to-shadow Agent

Compresses working files into shadow files.

**Input:**
- Working file path and content

**Output:**
- Generated shadow content
- Brief report

**Behavior:**
- Achieves 10x information density
- Suggests splitting if working file is too large
- Used for initialization and reverse sync

### shadow-diff Tool

Compares shadow and working directory structures.

**Usage:**
```bash
shadow-diff.sh [OPTIONS]

OPTIONS:
  --max-display <N>     Max files to show per directory (default: 16)
  --dir <PATH>          Directory to compare (auto-detects shadow/working)
  --no-collapse         Show all differences without folding
  --help                Show help
```

**Output Example:**
```
=== Shadow → Working ===
src/auth/login.ts.shadow.md → src/auth/login.ts [MISSING]
src/auth/register.ts.shadow.md → src/auth/register.ts [MISSING]

=== Working → Shadow ===
src/config.ts → src/config.ts.shadow.md [MISSING]
node_modules/ [1247 files omitted, exceeds limit of 16]

Total: 2 shadow missing, 1248 working missing (1247 collapsed)
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Main Agent                          │
│                   (Shadow Layer)                        │
│                                                         │
│  • Reads only .shadow/ directory                       │
│  • Plans architecture and changes                      │
│  • Dispatches subagents                                │
│  • Never touches working files                         │
└────────────┬────────────────────────────┬───────────────┘
             │                            │
             │ Dispatch                   │ Dispatch
             ▼                            ▼
    ┌────────────────┐          ┌────────────────┐
    │  to-working    │          │  to-shadow     │
    │   Subagent     │          │   Subagent     │
    │                │          │                │
    │ • Materializes │          │ • Compresses   │
    │   shadow into  │          │   working into │
    │   working      │          │   shadow       │
    └────────┬───────┘          └────────┬───────┘
             │                            │
             │ Writes                     │ Reads
             ▼                            ▼
    ┌─────────────────────────────────────────────┐
    │           Working Directory                 │
    │         (Implementation Layer)              │
    │                                             │
    │  • Actual source code                      │
    │  • Full implementation details             │
    │  • Subagents operate here                  │
    └─────────────────────────────────────────────┘

         ┌──────────────────────────────┐
         │      shadow-diff Tool        │
         │                              │
         │  Compares both layers and    │
         │  reports sync status         │
         └──────────────────────────────┘
```

## Directory Structure

```
project/
├── src/                          # Working directory
│   ├── auth/
│   │   ├── login.ts
│   │   ├── register.ts
│   │   └── token.ts
│   └── .shadowignore             # Ignore rules
├── .shadow/                      # Shadow directory
│   └── src/
│       └── auth/
│           ├── login.ts.shadow.md
│           ├── register.ts.shadow.md
│           └── token.ts.shadow.md
└── docs/
    └── plans/
```

## Examples

### Example 1: Initializing a Project

```
You: "Initialize shadow system"

Agent: [Dispatches shadoWorker:init]

shadoWorker:init:
  1. Creates .shadow/ directory
  2. Creates .shadowignore with defaults
  3. Runs shadow-diff to scan project
  4. Asks: "Found 247 files. Ignore node_modules/, dist/, .git/?"
  5. You: "Yes"
  6. Dispatches 247 shadoWorker:to-shadow agents in parallel
  7. Reports: "Initialized shadow system. Created 247 shadow files."
```

### Example 2: Adding a Feature

```
You: "Add user authentication with login and registration"

Agent: [Loads shadoWorker skill]
  1. Reads .shadow/src/ to understand project structure
  2. Plans in shadow layer:
     - Creates .shadow/src/auth/login.ts.shadow.md
     - Creates .shadow/src/auth/register.ts.shadow.md
     - Creates .shadow/src/auth/token.ts.shadow.md
     - Updates .shadow/src/user.ts.shadow.md
  3. Dispatches 4 shadoWorker:to-working agents in parallel:
     - Agent 1: Creates src/auth/login.ts
     - Agent 2: Creates src/auth/register.ts
     - Agent 3: Creates src/auth/token.ts
     - Agent 4: Updates src/user.ts
  4. Collects reports from all agents
  5. Reports: "Authentication system implemented. Created 3 new modules, updated user module."
```

### Example 3: Checking Sync Status

```
You: "Check if shadow and working are in sync"

Agent: [Runs shadow-diff]

Output:
=== Shadow → Working ===
All shadow files have working counterparts ✓

=== Working → Shadow ===
src/config.ts → src/config.ts.shadow.md [MISSING]
src/utils/helper.ts → src/utils/helper.ts.shadow.md [MISSING]

Agent: "Found 2 working files without shadows. Should I create shadow files for them?"
You: "Yes"
Agent: [Dispatches 2 shadoWorker:to-shadow agents]
```

## Shadow File Format

Shadow files are free-form markdown with 10x information density. They focus on intent, architecture, and key decisions rather than implementation details.

### Code File Example

```markdown
# login.ts.shadow.md

User login functionality.

Receives username and password, queries database for validation, generates JWT token on success.
Error handling: 404 for user not found, 401 for wrong password, 500 for database errors.

Public interface: login(username, password) → Promise<{token, user}>
Dependencies: database module, token module
```

### Novel Scene Example

```markdown
# chapter-03-scene-01.md.shadow.md

Chapter 3, Scene 1: Library Discovery

Protagonist finds ancient map hidden in old book while browsing restricted section.
Map marks forbidden zone entrance. Protagonist decides to investigate.
Emotional arc: curiosity → excitement → determination
Foreshadowing: mysterious symbols on map edge
```

## Best Practices

### When to Split Shadow Files

Split when:
- Shadow file exceeds 20 lines
- Contains multiple independent concepts
- Changes typically affect only part of the file
- Concurrent modifications cause conflicts

### When to Merge Shadow Files

Merge only when:
- Files are always modified together
- Content is highly coupled and can't be understood independently
- Splitting increases cognitive overhead

### Granularity Guidelines

**Code Projects:**
- Each function/class over 100 lines → separate shadow file
- Each module split by feature → multiple shadow files
- Config files split by section → multiple shadow files

**Novel Projects:**
- Each scene → separate shadow file
- Each character profile → separate shadow file
- Each worldbuilding element → separate shadow file

**Documentation Projects:**
- Each chapter → separate shadow file
- Each topic → separate shadow file

## Version Control

Shadow files should be committed to version control:
- Commit `.shadow/` directory
- Commit `.shadowignore` file
- Shadow files track architectural decisions and intent
- Enables code review at the strategic level

## Learn More

For detailed design rationale and technical specifications, see:
- [Shadow-Driven Development Design Document](../docs/plans/2026-03-09-shadow-driven-development-design.md)

## License

Part of the Alephant project.
