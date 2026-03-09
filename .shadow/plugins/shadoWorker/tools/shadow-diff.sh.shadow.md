# shadow-diff.sh.shadow.md

Bash script comparing shadow and working directory structures.

## Purpose
Detects structural differences: files in shadow missing from working, files in working missing from shadow.

## Usage
shadow-diff.sh [--max-display N] [--dir PATH] [--no-collapse] [--help]

## Options
- --max-display: max files per directory (default 16)
- --dir: directory to compare (auto-detects shadow/working)
- --no-collapse: show all differences without folding

## Behavior
1. Detects paths: if input contains .shadow, treats as shadow dir; else finds project root with .shadow/
2. Reads .shadowignore patterns
3. Scans both directories (respects ignore rules)
4. Maps shadow files to working files (removes .shadow.md extension)
5. Identifies missing files in each direction
6. Formats output with collapsing (groups by directory, collapses if >max-display)
7. Shows summary with counts

## Hardcoded Ignores
.shadowignore, .shadow, .git

## Output Format
=== Shadow → Working === (shadow files without working counterparts)
=== Working → Shadow === (working files without shadow counterparts)
Total: X shadow missing, Y working missing (Z collapsed)

Exit code 1 if differences found, 0 if in sync.
