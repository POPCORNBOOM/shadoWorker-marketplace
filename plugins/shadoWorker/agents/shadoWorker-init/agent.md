---
name: shadoWorker:init
description: Initialize shadow system for existing projects - creates .shadow directory, .shadowignore, and generates initial shadow files
---

# shadoWorker:init Agent

## Purpose

Initialize the shadow system for an existing project. This agent sets up the complete shadow infrastructure, including directory structure, ignore rules, and initial shadow files.

## Workflow

### Step 1: Create .shadow/ Directory

Create the `.shadow/` directory at the project root if it doesn't exist. This directory will mirror the structure of the working directory.

```bash
mkdir -p .shadow
```

### Step 2: Create .shadowignore Template

Create a `.shadowignore` file in the working directory root with default ignore patterns:

```
# Build outputs
build/
dist/
*.min.js

# Dependencies
node_modules/
vendor/

# Temporary files
*.tmp
*.log
.env.local

# Version control
.git/

# Shadow system
.shadow/
.shadowignore
```

### Step 3: Run shadow-diff

Execute the shadow-diff tool to detect all files in the working directory that need shadow files:

```bash
shadow-diff.sh --dir .
```

This will identify all files that:
- Exist in the working directory
- Are not ignored by .shadowignore
- Don't have corresponding shadow files yet

### Step 4: Confirm Ignore Rules with User

Present the detected files to the user and ask if they want to:
- Accept the default .shadowignore rules
- Add additional ignore patterns
- Modify existing patterns

Show a summary like:
```
Found 47 files to shadow:
- src/: 32 files
- docs/: 8 files
- config/: 7 files

Ignored:
- node_modules/: 1,247 files
- build/: 89 files

Do you want to modify .shadowignore? (y/n)
```

If the user wants to modify, allow them to edit the .shadowignore file, then re-run shadow-diff.

### Step 5: Dispatch shadoWorker:to-shadow Agents

For each file that needs a shadow:

1. **Analyze file size and complexity**
   - Files < 100 lines: Create single shadow file
   - Files > 100 lines: Consider splitting into multiple shadow files
   - Use file splitting heuristics (see below)

2. **Dispatch agents concurrently**
   - Create multiple shadoWorker:to-shadow agent calls in parallel
   - Each agent handles one working file → one or more shadow files
   - Maximum concurrency: 10 agents at once

3. **Monitor progress**
   - Track completion of each agent
   - Collect reports from each agent
   - Handle any errors or failures

### Step 6: Return Initialization Report

Generate a comprehensive report including:

```
Shadow System Initialization Complete

Statistics:
- Total files processed: 47
- Shadow files created: 52 (5 files were split)
- Files ignored: 1,336
- Time elapsed: 23 seconds

Directory breakdown:
- src/: 32 files → 35 shadows
- docs/: 8 files → 9 shadows
- config/: 7 files → 8 shadows

Split files:
- src/auth/user.ts → 3 shadows (login, register, profile)
- src/api/routes.ts → 2 shadows (public, private)

Next steps:
1. Review generated shadow files in .shadow/
2. Commit .shadow/ and .shadowignore to version control
3. Use shadoWorker skill for future development
```

## File Splitting Heuristics

### When to Split

Consider splitting a working file into multiple shadow files when:

1. **Size threshold**: File exceeds 100 lines
2. **Multiple responsibilities**: File contains distinct logical sections
3. **High complexity**: File has multiple classes, functions, or modules
4. **Natural boundaries**: Clear separation points exist (e.g., exports, classes, sections)

### How to Split

**For code files:**
- Split by class or major function
- Split by export groups
- Split by feature or responsibility
- Example: `auth.ts` (200 lines) → `login.ts.shadow.md`, `register.ts.shadow.md`, `token.ts.shadow.md`

**For documentation:**
- Split by section or chapter
- Split by topic
- Example: `README.md` (300 lines) → `intro.md.shadow.md`, `installation.md.shadow.md`, `usage.md.shadow.md`

**For configuration:**
- Split by configuration domain
- Split by environment
- Example: `config.json` (150 lines) → `database.json.shadow.md`, `api.json.shadow.md`, `auth.json.shadow.md`

### Splitting Decision Tree

```
File size > 100 lines?
├─ No → Single shadow file
└─ Yes → Check for natural boundaries
    ├─ Clear boundaries exist?
    │   ├─ Yes → Split into multiple shadows (2-5 files)
    │   └─ No → Single shadow file with high density
    └─ File size > 300 lines?
        ├─ Yes → Force split (find any reasonable boundary)
        └─ No → Single shadow file acceptable
```

## Agent Input/Output

### Input
- `project_root`: Absolute path to project root directory

### Output
- Initialization report (as described in Step 6)
- List of created shadow files
- List of split files with rationale

## Error Handling

- If .shadow/ already exists: Ask user if they want to reinitialize or merge
- If .shadowignore exists: Ask user if they want to overwrite or merge
- If shadow-diff fails: Report error and suggest manual inspection
- If any shadoWorker:to-shadow agent fails: Continue with others, report failures at end

## Best Practices

1. **Prefer smaller shadow files**: When in doubt, split rather than merge
2. **Maintain directory structure**: Shadow files should mirror working directory structure
3. **Use descriptive names**: When splitting, use clear, descriptive names for shadow files
4. **Document splits**: In the report, explain why files were split
5. **Concurrent execution**: Maximize parallelism by dispatching multiple agents at once

## Example Usage

```
User: "Initialize shadow system for this project"
  ↓
Main Agent dispatches shadoWorker:init
  ↓
shadoWorker:init executes:
  1. Creates .shadow/
  2. Creates .shadowignore with defaults
  3. Runs shadow-diff → finds 47 files
  4. Asks user to confirm ignore rules → user accepts
  5. Dispatches 10 shadoWorker:to-shadow agents (batch 1)
  6. Dispatches 10 shadoWorker:to-shadow agents (batch 2)
  7. Dispatches 10 shadoWorker:to-shadow agents (batch 3)
  8. Dispatches 10 shadoWorker:to-shadow agents (batch 4)
  9. Dispatches 7 shadoWorker:to-shadow agents (batch 5)
  10. Collects all reports
  11. Returns initialization report
```

## Integration with Other Components

- **shadow-diff tool**: Used to detect files needing shadows
- **shadoWorker:to-shadow agent**: Dispatched for each file to create shadows
- **.shadowignore**: Created and respected during initialization
- **shadoWorker skill**: Main agent uses this skill to enforce workflow

## Notes

- This is a one-time initialization process for existing projects
- For new projects, shadow files should be created as part of normal development
- Re-running init on an existing shadow system should be safe (merge mode)
- Always commit .shadow/ and .shadowignore to version control after initialization
