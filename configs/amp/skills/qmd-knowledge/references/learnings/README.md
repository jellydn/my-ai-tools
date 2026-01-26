# Learnings

This directory contains project learnings and insights.

## Format

Files follow the naming convention: `YYYY-MM-DD-topic-slug.md`

Each learning should include:
- Context about when/how it was discovered
- The actual learning or insight
- How it can be applied in the future

## Example

```markdown
# Learning: qmd MCP Integration

**Date:** 2024-01-26 12:00:00

## Context

While implementing knowledge management, discovered qmd has built-in MCP server support.

## Learning

The qmd tool provides a native MCP server via `qmd mcp` command, allowing Claude to
autonomously search and query markdown knowledge bases.

## Application

Use qmd MCP server for project-specific knowledge bases instead of claude-mem to avoid
repository pollution and gain better search capabilities.
```
