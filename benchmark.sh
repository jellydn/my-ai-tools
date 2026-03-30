#!/bin/bash
# Benchmark script for measuring future-proof optimization

set -e
cd "$(dirname "$0")"

echo "=== Shellcheck Analysis ==="

# Count issues by severity
all_issues=$(shellcheck -f json cli.sh generate.sh 2>/dev/null | jq length 2>/dev/null || echo "0")
warnings=$(shellcheck -f json cli.sh generate.sh 2>/dev/null | jq '[.[] | select(.level == "warning")] | length' 2>/dev/null || echo "0")
infos=$(shellcheck -f json cli.sh generate.sh 2>/dev/null | jq '[.[] | select(.level == "info")] | length' 2>/dev/null || echo "0")
styles=$(shellcheck -f json cli.sh generate.sh 2>/dev/null | jq '[.[] | select(.level == "style")] | length' 2>/dev/null || echo "0")

echo "Total issues: $all_issues"
echo "  Warnings: $warnings"
echo "  Info: $infos"
echo "  Style: $styles"

# Calculate quality score (penalize warnings most heavily)
# 100 - (warnings*5) - (info*1) - (style*0.5), minimum 0  
quality_score=$((100 - warnings * 5 - infos - styles / 2))
if [ "$quality_score" -lt 0 ]; then quality_score=0; fi

echo "METRIC quality_score=$quality_score"
echo "METRIC shellcheck_issues=$all_issues"
echo "METRIC warnings=$warnings"

# Count code patterns
echo "=== Code Analysis ==="

# Count duplicate patterns - the prompt_and_install is very repetitive
duplicate_patterns=$(grep -c "prompt_and_install()" cli.sh 2>/dev/null || echo "0")
echo "Duplicate pattern blocks: $duplicate_patterns"

# Count execute calls with potential quoting issues
execute_calls=$(grep -c "execute \"" cli.sh 2>/dev/null || echo "0")
echo "Execute calls with potential quoting issues: $execute_calls"

# Count hardcoded tool names (indicator of config inflexibility)
tool_funcs=$(grep -c "^install_[a-z]*()" cli.sh 2>/dev/null || echo "0")
echo "Tool-specific install functions: $tool_funcs"

echo "METRIC duplicate_patterns=$duplicate_patterns"
echo "METRIC tool_specific_funcs=$tool_funcs"
