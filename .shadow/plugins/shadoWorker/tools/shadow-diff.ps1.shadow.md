# shadow-diff.ps1.shadow.md

PowerShell script comparing shadow and working directory structures.

## Purpose
Windows equivalent of shadow-diff.sh. Detects structural differences between shadow and working directories.

## Parameters
- MaxDisplay: max files per directory (default 16)
- Dir: directory to compare (default ".")
- NoCollapse: switch to disable collapsing

## Behavior
Identical to shadow-diff.sh:
1. Detect paths (auto-detect shadow/working)
2. Read .shadowignore patterns
3. Scan directories with ignore rules
4. Map shadow to working files
5. Find missing files
6. Format output with collapsing
7. Display summary

## Functions
- Detect-Paths: finds shadow/working directories
- Should-Ignore: checks ignore patterns
- Read-ShadowIgnore: parses .shadowignore
- Scan-Directory: collects files recursively
- Format-Output: displays results with collapsing

## Hardcoded Ignores
.shadowignore, .shadow, .git

## Output
Same format as bash version. Groups files by directory, collapses if count exceeds MaxDisplay.
