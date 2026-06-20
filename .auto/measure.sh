#!/bin/bash
set -euo pipefail

# Autoresearch benchmark for Cursor Composer 2.5 AMP Plugin
# Validates structure, measures prompt quality, outputs METRIC lines

PLUGIN_FILE="configs/amp/plugins/cursor-composer-2.5.ts"
REFERENCE_FILE="configs/amp/plugins/glm-52-mode.ts"

# --- Fast pre-check: file exists ---
if [ ! -f "$PLUGIN_FILE" ]; then
	echo "METRIC prompt_score=0"
	echo "METRIC tool_count=0"
	echo "METRIC line_count=0"
	echo "METRIC file_size_bytes=0"
	echo "METRIC structure_score=0"
	echo "METRIC has_create_agent=0"
	echo "METRIC has_register_mode=0"
	echo "PLUGIN_FILE_NOT_FOUND=1"
	exit 0
fi

FILE_CONTENT=$(cat "$PLUGIN_FILE")
LINE_COUNT=$(wc -l < "$PLUGIN_FILE")
FILE_SIZE=$(wc -c < "$PLUGIN_FILE")

# --- Check 1: Structure (35 pts) ---

# Required imports/patterns
HAS_IMPORT=$(echo "$FILE_CONTENT" | grep -c 'import.*PluginAPI.*@ampcode/plugin' || true)
HAS_EXPORT_DEFAULT=$(echo "$FILE_CONTENT" | grep -c 'export default function' || true)
HAS_CREATE_AGENT=$(echo "$FILE_CONTENT" | grep -c 'createAgent' || true)
HAS_REGISTER_MODE=$(echo "$FILE_CONTENT" | grep -c 'registerAgentMode' || true)

# Required prompt sections
HAS_OPERATING_PRINCIPLES=$(echo "$FILE_CONTENT" | grep -c 'operating_principles' || true)
HAS_FRAME_TASK=$(echo "$FILE_CONTENT" | grep -c 'frame_the_task' || true)
HAS_PLAN_BEFORE=$(echo "$FILE_CONTENT" | grep -c 'plan_before_acting' || true)
HAS_CODEBASE_DISCOVERY=$(echo "$FILE_CONTENT" | grep -c 'codebase_discovery' || true)
HAS_TOOL_USE=$(echo "$FILE_CONTENT" | grep -c 'tool_use' || true)
HAS_IMPLEMENTATION=$(echo "$FILE_CONTENT" | grep -c 'implementation_style' || true)
HAS_VERIFICATION=$(echo "$FILE_CONTENT" | grep -c 'verification' || true)
HAS_COMMUNICATION=$(echo "$FILE_CONTENT" | grep -c 'communication' || true)
HAS_FRONTEND_TASTE=$(echo "$FILE_CONTENT" | grep -c 'frontend_taste' || true)

structure_score=0

# Import/export (15 pts if all present)
IMPORT_PATTERN_OK=$(( HAS_IMPORT > 0 ? 1 : 0 ))
EXPORT_OK=$(( HAS_EXPORT_DEFAULT > 0 ? 1 : 0 ))
AGENT_OK=$(( HAS_CREATE_AGENT > 0 ? 1 : 0 ))
REGISTER_OK=$(( HAS_REGISTER_MODE > 0 ? 1 : 0 ))
STRUCTURAL_COMPLETE=$(( IMPORT_PATTERN_OK + EXPORT_OK + AGENT_OK + REGISTER_OK ))

if [ "$STRUCTURAL_COMPLETE" -eq 4 ]; then
	structure_score=$(( structure_score + 15 ))
elif [ "$STRUCTURAL_COMPLETE" -eq 3 ]; then
	structure_score=$(( structure_score + 10 ))
elif [ "$STRUCTURAL_COMPLETE" -eq 2 ]; then
	structure_score=$(( structure_score + 5 ))
fi

# Prompt sections (20 pts, ~2.2 pts each)
SECTION_COUNT=$(( HAS_OPERATING_PRINCIPLES + HAS_FRAME_TASK + HAS_PLAN_BEFORE + HAS_CODEBASE_DISCOVERY + HAS_TOOL_USE + HAS_IMPLEMENTATION + HAS_VERIFICATION + HAS_COMMUNICATION + HAS_FRONTEND_TASTE ))
structure_score=$(( structure_score + (SECTION_COUNT * 20 / 9) ))
# Cap at 35
[ "$structure_score" -gt 35 ] && structure_score=35

# --- Check 2: Tool Selection (20 pts) ---

# Extract tool names from the const array — only strings inside the array brackets
# Find the line containing TOOL_NAMES/TOOLS = [ and extract until ] as const;
TOOL_RAW=$(echo "$FILE_CONTENT" | awk '
/const.*TOOL_NAMES|const.*TOOLS/ {in_arr=1; sub(/.*\[/,""); print}
in_arr && /\] as const/ {sub(/\].*/,""); print; in_arr=0}
in_arr {print}
' 2>/dev/null || echo "")
# Extract quoted strings from the array region only
TOOL_STRINGS=$(echo "$TOOL_RAW" | grep -o '"[^"]*"' || echo "")

# Count unique tool strings
TOTAL_TOOLS=$(echo "$TOOL_STRINGS" | sort -u | grep -c . || echo 0)

# Count matches against desired tools
DESIRED_TOOLS=("Read" "Bash" "edit_file" "create_file" "web_search" "search" "grep" "read_web_page" "skill" "oracle")
TOOL_MATCHES=0
for tool in "${DESIRED_TOOLS[@]}"; do
	if echo "$TOOL_STRINGS" | grep -q "\"$tool\""; then
		TOOL_MATCHES=$(( TOOL_MATCHES + 1 ))
	fi
done

# Score: 20 pts if 8+ desired tools found, proportional otherwise
if [ "$TOOL_MATCHES" -ge 8 ]; then
	tool_score=20
elif [ "$TOOL_MATCHES" -ge 5 ]; then
	tool_score=$(( TOOL_MATCHES * 20 / 8 ))
else
	tool_score=$(( TOOL_MATCHES * 2 ))
fi

# Penalize if too many tools (bloat > 14) or too few (< 3)
if [ "$TOTAL_TOOLS" -gt 14 ] || [ "$TOTAL_TOOLS" -lt 3 ]; then
	tool_score=$(( tool_score - 5 ))
fi
[ "$tool_score" -lt 0 ] && tool_score=0



# --- Check 3: Specificity to Cursor Composer 2.5 (25 pts) ---

CURSOR_REFS=$(echo "$FILE_CONTENT" | grep -ci 'cursor' || true)
# Check for Cursor-specific content
HAS_COMPOSER=$(echo "$FILE_CONTENT" | grep -ci 'composer' || true)
HAS_AGENT_MODE=$(echo "$FILE_CONTENT" | grep -ci 'agent' || true)
HAS_CODE_EDITING=$(echo "$FILE_CONTENT" | grep -ciE 'code.*edit|edit.*code|implement' || true)
HAS_IDE=$(echo "$FILE_CONTENT" | grep -ciE 'ide|cursor' || true)

specificity_score=0

# General code agent references
if [ "$HAS_CODE_EDITING" -gt 0 ]; then specificity_score=$((specificity_score + 5)); fi
if [ "$CURSOR_REFS" -gt 2 ]; then specificity_score=$((specificity_score + 10)); fi
if [ "$HAS_AGENT_MODE" -gt 2 ]; then specificity_score=$((specificity_score + 5)); fi
if [ "$HAS_COMPOSER" -gt 0 ]; then specificity_score=$((specificity_score + 5)); fi

[ "$specificity_score" -gt 25 ] && specificity_score=25

# --- Check 4: Conciseness (10 pts) ---

# Penalize very short or very long files
conciseness_score=10
if [ "$LINE_COUNT" -lt 50 ]; then
	conciseness_score=$(( conciseness_score - 5 ))
elif [ "$LINE_COUNT" -gt 500 ]; then
	conciseness_score=$(( conciseness_score - 3 ))
fi

# Check for bloated content
BLOAT_PATTERNS=$(echo "$FILE_CONTENT" | grep -ciE 'TODO|FIXME|placeholder|stub|PLACEHOLDER|todo:' || true)
if [ "$BLOAT_PATTERNS" -gt 0 ]; then
	conciseness_score=$(( conciseness_score - BLOAT_PATTERNS ))
fi
[ "$conciseness_score" -lt 0 ] && conciseness_score=0

# --- Check 5: Code Quality (10 pts) ---

code_quality_score=0

# Model reference
HAS_MODEL_REF=$(echo "$FILE_CONTENT" | grep -c 'model:' || true)
if [ "$HAS_MODEL_REF" -gt 0 ]; then code_quality_score=$((code_quality_score + 3)); fi

# Display config
HAS_DISPLAY=$(echo "$FILE_CONTENT" | grep -c 'display:' || true)
if [ "$HAS_DISPLAY" -gt 0 ]; then code_quality_score=$((code_quality_score + 2)); fi

# reasoningEffort
HAS_REASONING=$(echo "$FILE_CONTENT" | grep -c 'reasoningEffort' || true)
if [ "$HAS_REASONING" -gt 0 ]; then code_quality_score=$((code_quality_score + 2)); fi

# color in display config
HAS_COLOR=$(echo "$FILE_CONTENT" | grep -c 'color:' || true)
if [ "$HAS_COLOR" -gt 0 ]; then code_quality_score=$((code_quality_score + 1)); fi

# type annotation on tools
HAS_AS_CONST=$(echo "$FILE_CONTENT" | grep -c 'as const' || true)
if [ "$HAS_AS_CONST" -gt 0 ]; then code_quality_score=$((code_quality_score + 2)); fi

[ "$code_quality_score" -gt 10 ] && code_quality_score=10

# --- Composite score ---
PROMPT_SCORE=$(( structure_score + tool_score + specificity_score + conciseness_score + code_quality_score ))

# --- Output ---
echo "METRIC prompt_score=$PROMPT_SCORE"
echo "METRIC tool_count=$TOTAL_TOOLS"
echo "METRIC line_count=$LINE_COUNT"
echo "METRIC file_size_bytes=$FILE_SIZE"
echo "METRIC structure_score=$structure_score"
echo "METRIC tool_selection_score=$tool_score"
echo "METRIC specificity_score=$specificity_score"
echo "METRIC conciseness_score=$conciseness_score"
echo "METRIC code_quality_score=$code_quality_score"

# Debug info
echo "SECTIONS_FOUND=$SECTION_COUNT"
echo "STRUCTURAL_COMPLETE=$STRUCTURAL_COMPLETE"
echo "HAS_CREATE_AGENT=$HAS_CREATE_AGENT"
echo "HAS_REGISTER_MODE=$HAS_REGISTER_MODE"
echo "HAS_IMPORT=$HAS_IMPORT"
echo "HAS_EXPORT_DEFAULT=$HAS_EXPORT_DEFAULT"
