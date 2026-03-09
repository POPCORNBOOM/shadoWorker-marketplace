# agent.md.shadow.md (to-shadow)

Compresses working files into shadow files at 10x density.

## Process
1. Read working file
2. Extract semantics (what, not how)
3. Compress to natural language
4. Write shadow file
5. Report compression ratio

## Keep
Purpose, public interfaces, key behavior, error cases, dependencies

## Remove
Implementation details, syntax, boilerplate, variable names

## Splitting
- >100 lines: consider split
- >200 lines: strongly recommend split
- Suggest: file paths, line ranges, purposes

## Output Format
JSON: {success: bool, ratio: number, lines_before: number, lines_after: number, split_suggestions: array}
