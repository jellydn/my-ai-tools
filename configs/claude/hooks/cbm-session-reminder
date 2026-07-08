#!/bin/bash
# SessionStart hook: remind agent to use codebase-memory-mcp tools.
# Installed by codebase-memory-mcp. Fires on startup/resume/clear/compact.
cat << 'REMINDER'
CRITICAL - Code Discovery Protocol:
1. ALWAYS use codebase-memory-mcp tools FIRST for ANY code exploration:
   - search_graph(name_pattern/label/qn_pattern) to find functions/classes/routes
   - trace_path(function_name, mode=calls|data_flow|cross_service) for call chains
   - get_code_snippet(qualified_name) for exact symbol source (precise ranges)
   - query_graph(query) for complex Cypher patterns
   - get_architecture(aspects) for project structure
   - search_code(pattern) for text search (graph-augmented grep)
2. Use Grep/Glob/Read freely for text, configs, non-code files, and
   always Read a file before editing it.
3. If a project is not indexed yet, run index_repository FIRST.
REMINDER
