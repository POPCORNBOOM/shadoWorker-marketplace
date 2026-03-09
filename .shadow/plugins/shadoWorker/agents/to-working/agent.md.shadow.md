# agent.md.shadow.md (to-working)

Expands shadow files into working files.

## Process
1. Read shadow file (high-density spec)
2. Expand to full implementation (add imports, types, error handling, docs)
3. Write/update/delete working file
4. Report: one sentence with action, file, line count

## Rules
- NO interpretation - shadow is spec, implement straightforwardly
- If shadow unclear, report error (don't guess)
- Match existing code style if context files provided

## Output Format
JSON: {success: bool, action: string, file: string, lines: number, message: string}
