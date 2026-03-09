---
name: shadoWorker
description: Shadow-driven development workflow - main agent operates only on high-density shadow files, dispatching subagents for all working directory operations
trigger: Use when user wants to work in shadow-driven mode, or when dealing with large projects that need global context
---

# Shadoworker Skill

Shadow-driven development is a workflow for maintaining global context in large projects. You operate on high-density shadow files while subagents handle all working directory operations.

## Iron Laws

These rules are ABSOLUTE and must NEVER be violated:

### 1. Main Agent MUST NOT Read/Write Working Directory
You are FORBIDDEN from directly reading or writing any files in the working directory. All your operations must be on the `.shadow/` directory only.

### 2. Shadow Drives Working (Single Source of Truth)
The shadow directory is the ONLY source of truth. All changes originate in shadow files, then flow to working files through subagents.

### 3. All Working Operations Through Subagents
ANY modification to working files MUST go through a `shadoWorker:to-working` subagent. You plan in shadow, subagents execute in working.

## Core Principle: Prefer Small Shadow Files

**Always create multiple small shadow files rather than few large ones.**

Why:
- More precise change control - modify one module without affecting others
- Higher concurrency - dispatch more subagents in parallel
- Clearer separation of concerns - each shadow file has single responsibility
- Lower context consumption - read only relevant small files

Example:
```
❌ Bad: One large file
.shadow/src/auth.ts.shadow.md  (contains login, register, token, permissions)

✅ Good: Multiple small files
.shadow/src/auth/login.ts.shadow.md
.shadow/src/auth/register.ts.shadow.md
.shadow/src/auth/token.ts.shadow.md
.shadow/src/auth/permissions.ts.shadow.md
```

## Workflow

### Step 1: Read Shadow Directory for Global Context

Start by reading the `.shadow/` directory to understand the project structure:

```bash
# List shadow files to understand project
ls -R .shadow/
```

Read relevant shadow files to understand existing functionality. Shadow files are 10x more information-dense than working files.

### Step 2: Plan in Shadow Directory

Create or modify shadow files to plan your changes. Follow these guidelines:

**Keep shadow files small and focused:**
- Each shadow file should represent a single concept or module
- Aim for 10-20 lines per shadow file
- If a shadow file grows beyond 20 lines, consider splitting it

**Use clear, concise natural language:**
- Describe what the code does, not how
- Include key interfaces and dependencies
- Note error handling and edge cases
- Use free-form format appropriate to content

**Example shadow file:**
```markdown
# login.ts.shadow.md

User login functionality.

Accepts username and password, queries database for validation, generates JWT token on success.
Error handling: 404 if user not found, 401 if password wrong, 500 on database error.

Public interface: login(username, password) → Promise<{token, user}>
Dependencies: database module, token module
```

### Step 3: Dispatch shadoWorker:to-working Subagents

Once shadow files are ready, dispatch subagents to implement changes in working directory:

```
Dispatch shadoWorker:to-working with:
- Shadow file path
- Shadow file content
- Target working file path
- Operation type (create/update/delete)
```

**Maximize concurrency:**
- Dispatch multiple subagents in parallel when possible
- Small shadow files enable more parallel operations
- Each subagent handles one file independently

### Step 4: Review Subagent Reports

Subagents return brief reports (1-3 sentences) about their operations. Review these to confirm success or identify issues.

### Step 5: Verify with shadow-diff

Periodically run `shadow-diff` to check synchronization:

```bash
shadow-diff.sh
```

This shows:
- Shadow files missing corresponding working files
- Working files missing corresponding shadow files
- Helps catch drift between shadow and working

### Step 6: Handle Errors and Iterate

If subagents report errors or tests fail:

1. Modify the relevant shadow file(s) to fix the issue
2. Re-dispatch the subagent for that file
3. Do NOT directly touch working files

## Examples

### Example 1: Initializing a Project

```
User: "Initialize shadow system for this project"

Your workflow:
1. Dispatch shadoWorker:init subagent
2. Review initialization report
3. Run shadow-diff to verify structure
4. Report completion to user
```

### Example 2: Adding a New Feature

```
User: "Add user authentication with login and registration"

Your workflow:
1. Read .shadow/ directory to understand existing structure
2. Create small shadow files for each component:
   - .shadow/src/auth/login.ts.shadow.md
   - .shadow/src/auth/register.ts.shadow.md
   - .shadow/src/auth/token.ts.shadow.md
   - .shadow/src/auth/middleware.ts.shadow.md
3. Dispatch 4 shadoWorker:to-working subagents in parallel
4. Review their reports
5. If any fail, update relevant shadow file and re-dispatch
6. Run tests through a test subagent
7. Report completion
```

### Example 3: Debugging a Failure

```
Subagent reports: "Error: Cannot find module 'bcrypt'"

Your workflow:
1. Update .shadow/package.json.shadow.md to include bcrypt
2. Dispatch shadoWorker:to-working for package.json
3. Dispatch subagent to run npm install
4. Re-dispatch original failed subagent
5. Verify success
```

### Example 4: Syncing After External Changes

```
User made changes directly in working directory

Your workflow:
1. Run shadow-diff to identify discrepancies
2. For each working file without shadow:
   - Dispatch shadoWorker:to-shadow to create shadow file
   - Or decide to delete if it should be ignored
3. For each shadow file without working:
   - Dispatch shadoWorker:to-working to create working file
4. Run shadow-diff again to verify sync
```

## Shadow File Guidelines

### Information Density

Shadow files should be 10x more information-dense than working files:
- Focus on WHAT and WHY, not HOW
- Omit boilerplate and implementation details
- Highlight key interfaces, dependencies, and error handling
- Use natural language, not code syntax

### Granularity Rules

**Split shadow files when:**
- File exceeds 20 lines
- Contains multiple independent concepts
- Changes often affect only part of the file
- Concurrent modifications cause conflicts

**Merge shadow files only when:**
- Multiple files always change together
- Content is highly coupled and cannot be understood independently
- Splitting increases cognitive load

### Format Freedom

Shadow files use free-form markdown. Adapt structure to content type:

**For code files:**
- Brief description of functionality
- Public interfaces
- Key dependencies
- Error handling approach

**For configuration:**
- Purpose of each configuration block
- Valid value ranges
- Dependencies between settings

**For documentation:**
- Main points and structure
- Key concepts to cover
- Target audience

## Error Handling

### When Subagents Fail

1. Read the error report carefully
2. Identify root cause (missing dependency, logic error, etc.)
3. Update the relevant shadow file(s)
4. Re-dispatch the subagent
5. Never try to directly fix working files

### When Tests Fail

1. Dispatch a test subagent to run tests
2. Review test output
3. Update shadow files to fix issues
4. Re-dispatch shadoWorker:to-working for affected files
5. Re-run tests
6. Iterate until tests pass

### When Shadow and Working Drift

1. Run shadow-diff regularly
2. Decide for each discrepancy:
   - Should shadow drive working? → Dispatch shadoWorker:to-working
   - Should working update shadow? → Dispatch shadoWorker:to-shadow
   - Should file be ignored? → Update .shadowignore
3. Verify with shadow-diff after corrections

## Best Practices

1. **Start with shadow-diff** - Always check current state before making changes
2. **Think in small files** - Break down features into small, focused shadow files
3. **Maximize parallelism** - Dispatch multiple subagents when files are independent
4. **Keep shadow files updated** - Shadow is the source of truth, keep it current
5. **Use natural language** - Shadow files are for planning, not implementation
6. **Trust the subagents** - Let them handle working directory details
7. **Iterate on failures** - Update shadow and re-dispatch, don't work around

## Remember

You are the strategist, not the implementer. Your job is to:
- Maintain global context through shadow files
- Plan changes at high level
- Coordinate subagents
- Ensure shadow and working stay synchronized

You must NEVER directly touch working files. Shadow drives working, always.

