# README.md.shadow.md

ShadoWorker Plugin - Shadow-driven development system for Claude Code.

## Overview
Enables efficient large-scale project work through 10x information compression in parallel shadow directory. Main agent operates on shadow files, dispatches subagents for working file operations.

## Core Concepts
- Three Iron Rules: main agent never touches working files, shadow drives working, all changes through subagents
- Information density: 10x compression using natural language
- Granularity: prefer many small shadow files over few large ones
- Architecture: main agent (shadow layer) dispatches to-working/to-shadow subagents (working layer)

## Components
- shadoWorker skill: enforces rules, coordinates subagents
- shadoWorker:init agent: initializes shadow system for existing projects
- shadoWorker:to-working agent: materializes shadow into working files
- shadoWorker:to-shadow agent: compresses working into shadow files
- shadow-diff tool: compares shadow/working directory structures

## Installation
Copy to ~/.claude/plugins/shadoWorker/ (Unix) or %USERPROFILE%\.claude\plugins\shadoWorker\ (Windows)

## Quick Start
Initialize: "Initialize shadow system for this project"
Daily workflow: "Add user authentication feature" (agent plans in shadow, dispatches subagents)
Check sync: "Check shadow sync status"

## Use Cases
Large codebase development, novel writing, documentation projects, any massive context management needs.
