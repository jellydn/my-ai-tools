#!/bin/bash
set -eo pipefail

# Autoresearch benchmark for Cursor Composer 2.5 AMP Plugin
# Validates structure, measures prompt quality, outputs METRIC lines
# Score breakdown (max 100):
#   - Structure (30): correct imports/exports (10) + section depth (20)
#   - Tool Selection (20): relevant tools (15) + no bloat (5)
#   - Prompt Authenticity (25): originality vs copy (10) + Cursor-specific content (15)
#   - Section Quality (15): actual content per section, not just tags
#   - Code Quality (10): AMP API correctness, config quality

PLUGIN_FILE="configs/amp/plugins/cursor-composer-2.5.ts"

if [ ! -f "$PLUGIN_FILE" ]; then
	echo "METRIC prompt_score=0"
	exit 0
fi

FILE_CONTENT=$(cat "$PLUGIN_FILE")
LINE_COUNT=$(grep -c '' "$PLUGIN_FILE" || echo 0)
FILE_SIZE=$(stat -f%z "$PLUGIN_FILE" 2>/dev/null || wc -c < "$PLUGIN_FILE" | tr -d ' ')

# =============================================================================
# 1. STRUCTURE (30 pts)
# =============================================================================

# Import/export patterns (10 pts)
HAS_IMPORT=$(echo "$FILE_CONTENT" | grep -c 'import.*PluginAPI.*@ampcode/plugin' || true)
HAS_EXPORT_DEFAULT=$(echo "$FILE_CONTENT" | grep -c 'export default function' || true)
HAS_CREATE_AGENT=$(echo "$FILE_CONTENT" | grep -c 'createAgent' || true)
HAS_REGISTER_MODE=$(echo "$FILE_CONTENT" | grep -c 'registerAgentMode' || true)

IMPORT_OK=$(( HAS_IMPORT > 0 ? 1 : 0 ))
EXPORT_OK=$(( HAS_EXPORT_DEFAULT > 0 ? 1 : 0 ))
AGENT_OK=$(( HAS_CREATE_AGENT > 0 ? 1 : 0 ))
REGISTER_OK=$(( HAS_REGISTER_MODE > 0 ? 1 : 0 ))

STRUCTURAL_COMPLETE=$(( IMPORT_OK + EXPORT_OK + AGENT_OK + REGISTER_OK ))
structure_score=$(( STRUCTURAL_COMPLETE * 10 / 4 ))

# Prompt section depth (20 pts) - each section must have meaningful content (>3 lines)
PROMPT_PROTECTED=$(echo "$FILE_CONTENT" | grep -c '<frontend_taste>' || true)
SECTION_TAGS="operating_principles frame_the_task plan_before_acting codebase_discovery tool_use implementation_style verification communication frontend_taste"

section_depth_count=0
for tag in $SECTION_TAGS; do
	# Count lines in each section by extracting between XML tags
	section_lines=$(echo "$FILE_CONTENT" | awk -v tag="$tag" '
		/<'"$tag"'>/ {in_section=1; next}
		in_section && /<\/'"$tag"'>/ {in_section=0; exit}
		in_section {lines++}
		END {print lines+0}
	' 2>/dev/null || echo 0)
	if [ "$section_lines" -ge 15 ]; then
		section_depth_count=$(( section_depth_count + 2 ))
	elif [ "$section_lines" -ge 8 ]; then
		section_depth_count=$(( section_depth_count + 1 ))
	fi
done

section_depth_score=$(( section_depth_count * 20 / 18 ))  # 9 sections * 2 max each = 18
[ "$section_depth_score" -gt 20 ] && section_depth_score=20

structure_score=$(( structure_score + section_depth_score ))
[ "$structure_score" -gt 30 ] && structure_score=30

# =============================================================================
# 2. TOOL SELECTION (20 pts)
# =============================================================================

# Extract tool names from the const array
TOOL_RAW=$(echo "$FILE_CONTENT" | awk '
/const.*TOOL_NAMES|const.*TOOLS/ {in_arr=1; sub(/.*\[/,""); print}
in_arr && /\] as const/ {sub(/\].*/,""); print; in_arr=0}
in_arr {print}
' 2>/dev/null || echo "")
TOOL_STRINGS=$(echo "$TOOL_RAW" | grep -o '"[^"]*"' || echo "")

TOTAL_TOOLS=$(echo "$TOOL_STRINGS" | sort -u | grep -c . || echo 0)

# Relevant tools for a code-editing agent (15 pts max)
# Based on AMP built-in tools + GLM-5.2's known-working tool set
# Tier 1 (core): Read, Bash, edit_file, create_file — absolutely required
# Tier 2 (discovery): finder, find_thread — code & thread navigation
# Tier 3 (research): web_search, read_web_page — external knowledge
# Tier 4 (expert): skill, oracle, librarian — advanced capability
DESIRED_TOOLS=("Read" "Bash" "edit_file" "create_file" "finder" "find_thread" "web_search" "read_web_page" "skill" "oracle" "librarian")

TOOL_MATCHES=0
for tool in "${DESIRED_TOOLS[@]}"; do
	if echo "$TOOL_STRINGS" | grep -q "\"$tool\""; then
		TOOL_MATCHES=$(( TOOL_MATCHES + 1 ))
	fi
done
tool_score=$(( TOOL_MATCHES * 15 / 11 ))
[ "$tool_score" -gt 15 ] && tool_score=15

# Penalty for bloat or missing core tools (5 pts)
TOOL_PENALTY=0
if [ "$TOTAL_TOOLS" -gt 16 ]; then
	TOOL_PENALTY=$(( TOOL_PENALTY + 3 ))
elif [ "$TOTAL_TOOLS" -lt 4 ]; then
	TOOL_PENALTY=$(( TOOL_PENALTY + 3 ))
fi
# Check for core tools
for core in "Read" "Bash" "edit_file" "create_file"; do
	if ! echo "$TOOL_STRINGS" | grep -q "\"$core\""; then
		TOOL_PENALTY=$(( TOOL_PENALTY + 1 ))
	fi
done

# Extra penalty for non-code-editing tools
for extra in "view_media" "painter" "read_thread"; do
	if echo "$TOOL_STRINGS" | grep -q "\"$extra\""; then
		TOOL_PENALTY=$(( TOOL_PENALTY + 2 ))
	fi
done

tool_score=$(( tool_score - TOOL_PENALTY ))
[ "$tool_score" -lt 0 ] && tool_score=0

# =============================================================================
# 3. PROMPT AUTHENTICITY (25 pts)
# =============================================================================

# Originality vs copy from GLM-5.2 (10 pts)
# Check for sections that are clearly adapted (have Cursor-specific content)
# Count lines unique to this file vs generic agent prompt
REF_FILE="configs/amp/plugins/glm-52-mode.ts"
REF_CONTENT=$(cat "$REF_FILE" 2>/dev/null || echo "")

# Remove structural boilerplate and compare prompts
THIS_PROMPT=$(echo "$FILE_CONTENT" | sed -n '/^const.*PROMPT/,/^`;/p' 2>/dev/null || echo "")
REF_PROMPT=$(echo "$REF_CONTENT" | sed -n '/^const.*PROMPT/,/^`;/p' 2>/dev/null || echo "")

if [ -n "$THIS_PROMPT" ] && [ -n "$REF_PROMPT" ]; then
	# Count lines that differ between the two prompts
	THIS_LINES=$(echo "$THIS_PROMPT" | grep -c '' || echo 0)
	DIFF_LINES=$(diff <(echo "$REF_PROMPT") <(echo "$THIS_PROMPT") 2>/dev/null | grep -c '^>' || true)
	DIFF_LINES=${DIFF_LINES:-0}
	CHANGE_RATIO=0
	# Score based on percentage of new/changed lines
	if [ "$THIS_LINES" -gt 0 ] && [ "$DIFF_LINES" -gt 0 ]; then
		CHANGE_RATIO=$(( DIFF_LINES * 100 / THIS_LINES ))
		if [ "$CHANGE_RATIO" -ge 50 ]; then
			originality_score=10
		elif [ "$CHANGE_RATIO" -ge 30 ]; then
			originality_score=7
		elif [ "$CHANGE_RATIO" -ge 15 ]; then
			originality_score=5
		else
			originality_score=2
		fi
	else
		originality_score=0
	fi
else
	originality_score=0
fi

# Cursor-specific content (15 pts)
# Check for content that demonstrates understanding of Cursor as a tool
HAS_CURSOR_INTRODUCTION=$(echo "$FILE_CONTENT" | grep -ci 'cursor\|editor' || true)
HAS_COMPOSER_REF=$(echo "$FILE_CONTENT" | grep -ci 'composer\|compose' || true)
HAS_CURSOR_API_REF=$(echo "$FILE_CONTENT" | grep -ciE 'cursor.*agent|cursor.*cli|cursor.*sdk' || true)
HAS_TAB_COMPLETION=$(echo "$FILE_CONTENT" | grep -ci 'tab\|accept\|suggest' || true)
HAS_IDE_INTEGRATION=$(echo "$FILE_CONTENT" | grep -ciE 'ide.*integrat|inline.*edit|ai.*review' || true)
HAS_CURSOR_WORKFLOW=$(echo "$FILE_CONTENT" | grep -ciE 'composer.*mode|ask.*mode|edit.*mode|cursor.*mode' || true)

cursor_specificity=0
if [ "$HAS_CURSOR_INTRODUCTION" -ge 3 ]; then cursor_specificity=$((cursor_specificity + 3)); fi
if [ "$HAS_COMPOSER_REF" -gt 0 ]; then cursor_specificity=$((cursor_specificity + 3)); fi
if [ "$HAS_CURSOR_API_REF" -gt 0 ]; then cursor_specificity=$((cursor_specificity + 3)); fi
if [ "$HAS_TAB_COMPLETION" -gt 0 ]; then cursor_specificity=$((cursor_specificity + 2)); fi
if [ "$HAS_IDE_INTEGRATION" -gt 0 ]; then cursor_specificity=$((cursor_specificity + 2)); fi
if [ "$HAS_CURSOR_WORKFLOW" -gt 0 ]; then cursor_specificity=$((cursor_specificity + 2)); fi

[ "$cursor_specificity" -gt 15 ] && cursor_specificity=15

authenticity_score=$(( originality_score + cursor_specificity ))
[ "$authenticity_score" -gt 25 ] && authenticity_score=25

# =============================================================================
# 4. SECTION QUALITY (15 pts)
# =============================================================================

# Extract prompt body to analyze content quality
PROMPT_BODY=$(echo "$FILE_CONTENT" | sed -n '/^const.*PROMPT/,/^`;/p' 2>/dev/null || echo "")

if [ -n "$PROMPT_BODY" ]; then
	PROMPT_LINES=$(echo "$PROMPT_BODY" | wc -l || echo 0)
	# Penalize if prompt is too short (stub) or has placeholders
	# Check for actual placeholder content (not prose about avoiding them)
HAS_PLACEHOLDER=$(echo "$PROMPT_BODY" | grep -ci '// TODO\|// FIXME\|TODO:\|FIXME:\|PLACEHOLDER\|replace this entire' || true)

	# Check for complete sentences (at least some substantive text in each section)
	# Count sections that have actual XML tags with content between them
	COMPLETE_SECTIONS=0
	for tag in operating_principles frame_the_task plan_before_acting codebase_discovery tool_use implementation_style verification; do
		has_open=$(echo "$PROMPT_BODY" | grep -c "<$tag>" || true)
		has_close=$(echo "$PROMPT_BODY" | grep -c "</$tag>" || true)
		has_content=$(echo "$PROMPT_BODY" | awk -v tag="$tag" '
			/<'"$tag"'>/ {in_s=1; next}
			in_s && /<\/'"$tag"'>/ {in_s=0; exit}
			in_s {content=1}
			END {print content+0}
		' 2>/dev/null || echo 0)

		if [ "$has_open" -gt 0 ] && [ "$has_close" -gt 0 ] && [ "$has_content" -gt 0 ]; then
			COMPLETE_SECTIONS=$(( COMPLETE_SECTIONS + 1 ))
		fi
	done

	section_quality=$(( COMPLETE_SECTIONS * 10 / 7 ))  # 7 core sections

	# Penalize placeholders
	if [ "$HAS_PLACEHOLDER" -gt 0 ]; then
		section_quality=$(( section_quality - HAS_PLACEHOLDER ))
	fi

	# Bonus for code examples or specific patterns in the prompt
	HAS_CODE_EXAMPLE=$(echo "$PROMPT_BODY" | grep -ci 'code\|example\|pattern\|function\|component' || true)
	if [ "$HAS_CODE_EXAMPLE" -ge 10 ]; then
		section_quality=$(( section_quality + 5 ))
	elif [ "$HAS_CODE_EXAMPLE" -ge 5 ]; then
		section_quality=$(( section_quality + 3 ))
	fi

	[ "$section_quality" -gt 15 ] && section_quality=15
	[ "$section_quality" -lt 0 ] && section_quality=0
else
	section_quality=0
fi

# =============================================================================
# 5. CODE QUALITY (10 pts)
# =============================================================================

code_quality=0

# Model reference
if echo "$FILE_CONTENT" | grep -q 'model:'; then code_quality=$((code_quality + 2)); fi

# Display config
if echo "$FILE_CONTENT" | grep -q 'display:'; then code_quality=$((code_quality + 2)); fi

# reasoningEffort
if echo "$FILE_CONTENT" | grep -q 'reasoningEffort'; then code_quality=$((code_quality + 1)); fi

# color in display config with valid hex
if echo "$FILE_CONTENT" | grep -qE "color.*#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})"; then code_quality=$((code_quality + 1)); fi

# as const on tool array
if echo "$FILE_CONTENT" | grep -q 'as const'; then code_quality=$((code_quality + 1)); fi

# Plugin header comment
if echo "$FILE_CONTENT" | grep -qE '(//|#).*Cursor.*Composer'; then code_quality=$((code_quality + 1)); fi

# Experimental guard
if echo "$FILE_CONTENT" | grep -q 'amp.experimental'; then code_quality=$((code_quality + 1)); fi

# Agent mode key matches name
AGENT_KEY=$(echo "$FILE_CONTENT" | grep -oE 'key:.*"[^"]+"' | grep -oE '"[^"]+"' | tr -d '"' || echo "")
AGENT_NAME=$(echo "$FILE_CONTENT" | grep -oE 'name:.*"[^"]+"' | head -1 | grep -oE '"[^"]+"' | tr -d '"' || echo "")
if [ -n "$AGENT_KEY" ] && [ -n "$AGENT_NAME" ] && [ "$AGENT_KEY" = "$AGENT_NAME" ]; then
	code_quality=$((code_quality + 1))
fi

# Penalty for unescaped backticks inside template literal (would break at runtime)
# Only check the prompt CONTENT (after opening backtick, before closing backtick)
PROMPT_CONTENT=$(echo "$PROMPT_BODY" | sed '1d' | sed '$d' 2>/dev/null || echo "")
BACKTICK_BUGS=$(echo "$PROMPT_CONTENT" | grep -c '\x60' 2>/dev/null || echo 0)
if [ "$BACKTICK_BUGS" -gt 0 ]; then
	code_quality=$(( code_quality - (BACKTICK_BUGS * 3) ))
fi

[ "$code_quality" -gt 10 ] && code_quality=10
[ "$code_quality" -lt 0 ] && code_quality=0

# =============================================================================
# COMPOSITE SCORE
# =============================================================================

PROMPT_SCORE=$(( structure_score + tool_score + authenticity_score + section_quality + code_quality ))

# === OUTPUT ===
echo "METRIC prompt_score=$PROMPT_SCORE"
echo "METRIC tool_count=$TOTAL_TOOLS"
echo "METRIC line_count=$LINE_COUNT"
echo "METRIC file_size_bytes=$FILE_SIZE"
echo "METRIC structure_score=$structure_score"
echo "METRIC tool_selection_score=$tool_score"
echo "METRIC authenticity_score=$authenticity_score"
echo "METRIC section_quality=$section_quality"
echo "METRIC code_quality=$code_quality"

# Debug - component breakdown
echo "SECTION_DEPTH_COUNT=$section_depth_count"
echo "ORIGINALITY_SCORE=$originality_score"
echo "CURSOR_SPECIFICITY=$cursor_specificity"
echo "COMPLETE_SECTIONS=$COMPLETE_SECTIONS"
echo "TOOL_MATCHES=$TOOL_MATCHES"
echo "TOTAL_TOOLS=$TOTAL_TOOLS"
echo "STRUCTURAL_COMPLETE=$STRUCTURAL_COMPLETE"
