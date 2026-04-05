#!/bin/bash
# Shared utilities for my-ai-tools scripts
# Source this file using: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect OS (Windows vs Unix-like)
IS_WINDOWS=false
_detect_os() {
	case "$OSTYPE" in
	msys* | mingw* | cygwin* | win*) return 0 ;;
	esac
	# Also check for MSYSTEM environment variable (common in MSYS2/Git Bash)
	if [ -n "$MSYSTEM" ]; then
		case "$MSYSTEM" in
		MINGW* | MSYS* | CLANG*) return 0 ;;
		esac
	fi
	return 1
}
_detect_os && IS_WINDOWS=true

# Path helper functions for cross-platform compatibility

# Normalize path to use forward slashes (Unix-style)
# Usage: normalize_path "path/with\\slashes"
normalize_path() {
	local path="$1"
	# Replace backslashes with forward slashes (for Windows paths)
	path="${path//\\//}"
	# Remove duplicate slashes, but skip URLs (://) and UNC paths (// at start)
	if [[ ! "$path" =~ :// ]] && [[ ! "$path" =~ ^// ]]; then
		# Replace all // with / (repeat until no more consecutive slashes)
		while [[ "$path" =~ // ]]; do
			path="${path//\/\///}"
		done
	fi
	# Remove trailing slashes (except for root paths like / or C:/)
	if [ "$path" != "/" ] && [[ ! "$path" =~ ^[A-Za-z]:/$ ]]; then
		path="${path%/}"
	fi
	echo "$path"
}

# Get platform-specific temp directory
# Usage: get_temp_dir
get_temp_dir() {
	local temp_dir=""

	if [ -n "$TMPDIR" ]; then
		temp_dir="$TMPDIR"
	elif [ "$IS_WINDOWS" = true ] && [ -n "$TEMP" ]; then
		if command -v cygpath &>/dev/null; then
			temp_dir=$(cygpath -u "$TEMP" 2>/dev/null || printf '%s' "$TEMP")
		else
			temp_dir=$(normalize_path "$TEMP")
			case "$temp_dir" in
			[A-Za-z]:/*) temp_dir="/tmp" ;;
			esac
		fi
	else
		temp_dir="/tmp"
	fi

	echo "$temp_dir"
}

# Quote a path if it contains spaces or special characters
# Usage: quote_path "path with spaces"
quote_path() {
	local path="$1"
	case "$path" in
	*[\ \'\"]*)
		path="${path//\"/\\\"}"
		echo "\"$path\""
		;;
	*)
		echo "$path"
		;;
	esac
}

# Expand and normalize a path (resolves ~ and normalizes slashes)
# Usage: expand_path "~/path" -> "/home/user/path"
expand_path() {
	local path="$1"
	if [ "${path:0:1}" = "~" ]; then
		path="$HOME${path:1}"
	fi
	normalize_path "$path"
}

# Convert path between Unix and Windows formats
# Usage: convert_path "unix|windows" "path"
convert_path() {
	local direction="$1"
	local path="$2"
	local cygpath_flag=""

	case "$direction" in
	unix) cygpath_flag="-u" ;;
	windows) cygpath_flag="-w" ;;
	*)
		echo "$path"
		return 1
		;;
	esac

	if command -v cygpath &>/dev/null; then
		cygpath "$cygpath_flag" "$path" 2>/dev/null || echo "$path"
	else
		echo "$path"
	fi
}

# Convert Windows path to Unix-style path (for MSYS/Cygwin)
to_unix_path() {
	convert_path "unix" "$1"
}

# Convert Unix path to Windows-style path (for MSYS/Cygwin)
to_windows_path() {
	convert_path "windows" "$1"
}

# Safe basename extraction that handles edge cases
# Usage: safe_basename "/path/to/file.txt" -> "file.txt"
safe_basename() {
	local path="$1"
	if [ -z "$path" ]; then
		echo ""
		return 1
	fi
	basename "$path" 2>/dev/null || echo "${path##*/}"
}

# Safe dirname extraction that handles edge cases
# Usage: safe_dirname "/path/to/file.txt" -> "/path/to"
safe_dirname() {
	local path="$1"
	if [ -z "$path" ]; then
		echo ""
		return 1
	fi
	dirname "$path" 2>/dev/null || echo "${path%/*}"
}

# Detect tool installation with optional detailed status output
# Usage: detect_tool [--detailed] "tool_name" "config_dir" "alt_config_dir"
# Returns: 0 if detected, 1 if missing
# Outputs: "command", "directory", or "missing" when --detailed is used
detect_tool() {
	local detailed=false
	if [ "$1" = "--detailed" ]; then
		detailed=true
		shift
	fi

	local tool_name="$1"
	local config_dir="${2:-}"
	local alt_config_dir="${3:-}"

	# Priority 1: Check if command is available
	if command -v "$tool_name" &>/dev/null; then
		if [ "$detailed" = true ]; then
			echo "command"
		fi
		return 0
	fi

	# Priority 2: Check config paths
	local dirs_to_check=()
	[ -n "$config_dir" ] && dirs_to_check+=("$config_dir")
	[ -n "$alt_config_dir" ] && dirs_to_check+=("$alt_config_dir")

	for dir in "${dirs_to_check[@]}"; do
		local expanded_dir
		expanded_dir=$(expand_path "$dir")
		if [ -d "$expanded_dir" ] || [ -f "$expanded_dir" ]; then
			if [ "$detailed" = true ]; then
				if [ -d "$expanded_dir" ]; then
					echo "directory"
				else
					echo "file"
				fi
			fi
			return 0
		fi
	done

	if [ "$detailed" = true ]; then
		echo "missing"
	fi
	return 1
}

# Get a safe temporary file path with unique name
# Usage: make_temp_file "prefix" "extension"
make_temp_file() {
	local prefix="${1:-ai-tools}"
	local ext="${2:-tmp}"
	local temp_dir
	temp_dir=$(get_temp_dir)
	echo "${temp_dir}/${prefix}-$(date +%s)-$$.$ext"
}

# Get a safe temporary directory path
# Usage: make_temp_dir "prefix"
make_temp_dir() {
	local prefix="${1:-ai-tools}"
	local temp_dir
	temp_dir=$(get_temp_dir)
	echo "${temp_dir}/${prefix}-$(date +%s)-$$"
}

# Logging functions
# Output to stderr to avoid interfering with command substitution
log_info() {
	echo -e "${BLUE}ℹ ${NC}$1" >&2
}

log_success() {
	echo -e "${GREEN}✓${NC} $1" >&2
}

log_warning() {
	echo -e "${YELLOW}⚠${NC} $1" >&2
}

log_error() {
	echo -e "${RED}✗${NC} $1" >&2
}

# Execute function (for dry-run support)
# SECURITY NOTE: Uses eval() - ensure all inputs are properly quoted
# For commands with paths (which may contain spaces), use execute_quoted() instead
# Usage: execute "simple-command-without-paths"
execute() {
	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] $1"
	else
		eval "$1"
	fi
}

# Execute function that quotes paths automatically
# Usage: execute_quoted mkdir -p "$dest_dir"
execute_quoted() {
	if [ "$DRY_RUN" = true ]; then
		# Build display string for logging
		local cmd_str=""
		for arg in "$@"; do
			case "$arg" in
			*[\"\'[:space:]]*)
				local display_arg="${arg//\"/\\\"}"
				cmd_str="$cmd_str \"$display_arg\""
				;;
			*)
				cmd_str="$cmd_str $arg"
				;;
			esac
		done
		log_info "[DRY RUN] $cmd_str"
	else
		# Execute directly without eval - much safer for paths with spaces
		"$@"
	fi
}

# Download and verify script with checksum (if available)
# Usage: download_and_verify_script "url" "expected_sha256" "description"
download_and_verify_script() {
	local url="$1"
	local expected_sha256="$2"
	local description="$3"

	local tmpdir
	tmpdir=$(get_temp_dir)
	local temp_script
	temp_script="${tmpdir}/install-$(date +%s)-$$"

	log_info "Downloading $description..."
	if ! curl -fsSL "$url" -o "$temp_script" 2>/dev/null; then
		log_error "Failed to download $description"
		return 1
	fi

	chmod +x "$temp_script"

	if [ -n "$expected_sha256" ]; then
		local actual_sha256
		actual_sha256=$(sha256sum "$temp_script" 2>/dev/null | cut -d' ' -f1)
		if [ "$actual_sha256" != "$expected_sha256" ]; then
			log_error "Checksum verification failed for $description"
			log_error "Expected: $expected_sha256"
			log_error "Actual: $actual_sha256"
			rm -f "$temp_script"
			return 1
		fi
		log_success "Checksum verified for $description"
	fi

	echo "$temp_script"
}

# Execute external installer script with verification
# Usage: execute_installer "url" "sha256" "description" "install_args..."
execute_installer() {
	local url="$1"
	local expected_sha256="$2"
	shift 2
	local description="$1"
	shift
	local args=("$@")

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would execute installer from: $url"
		return 0
	fi

	# Ensure TMPDIR is set to avoid cross-device link errors
	local tmp_dir="${HOME}/.claude/tmp"
	if ! mkdir -p "$tmp_dir" 2>/dev/null; then
		tmp_dir=$(get_temp_dir)
		mkdir -p "$tmp_dir" 2>/dev/null || tmp_dir="/tmp"
	fi
	export TMPDIR="$tmp_dir"

	local temp_script
	temp_script=$(download_and_verify_script "$url" "$expected_sha256" "$description")
	if [ -z "$temp_script" ]; then
		return 1
	fi

	"$temp_script" "${args[@]}"
	local result=$?
	rm -f "$temp_script"
	return $result
}

# Clean up old backup directories, keeping only the most recent N backups
# Usage: cleanup_old_backups [max_backups]
cleanup_old_backups() {
	local max_backups="${1:-5}"

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would clean up backups (keep $max_backups most recent)"
		return 0
	fi

	# Find all backup directories and sort by modification time (newest first)
	# Uses ls -t which is cross-platform (works on both GNU and BSD/macOS)
	local old_backups
	old_backups=$(ls -dt "$HOME"/ai-tools-backup-* 2>/dev/null | tail -n +$((max_backups + 1)))

	if [ -n "$old_backups" ]; then
		for backup_dir in $old_backups; do
			if [ -d "$backup_dir" ]; then
				rm -rf "$backup_dir"
				log_info "Cleaned up old backup: $backup_dir"
			fi
		done
	fi
}

# Validate JSON file syntax
# Usage: validate_json "filepath"
# Returns: 0 if valid, 1 if invalid
validate_json() {
	local filepath="$1"

	if [ ! -f "$filepath" ]; then
		log_error "File not found: $filepath"
		return 1
	fi

	if command -v jq &>/dev/null; then
		if jq empty "$filepath" 2>/dev/null; then
			return 0
		else
			log_error "Invalid JSON in: $filepath"
			return 1
		fi
	else
		log_warning "jq not available, skipping JSON validation for: $filepath"
		return 0
	fi
}

# Validate YAML file syntax with detailed error reporting
# Usage: validate_yaml "filepath"
# Returns: 0 if valid, 1 if invalid
validate_yaml() {
	local filepath="$1"
	local validator_found=false

	if [ ! -f "$filepath" ]; then
		log_error "File not found: $filepath"
		return 1
	fi

	# Try validators in order of preference
	if command -v python3 &>/dev/null; then
		if python3 -c 'import yaml' >/dev/null 2>&1; then
			validator_found=true
			if FILEPATH="$filepath" python3 -c 'import os, yaml; yaml.safe_load(open(os.environ["FILEPATH"]))' 2>/dev/null; then
				log_success "YAML validated: $filepath (Python/PyYAML)"
				return 0
			fi
		fi
	fi

	if command -v yq &>/dev/null; then
		validator_found=true
		if yq '.' "$filepath" 2>/dev/null; then
			log_success "YAML validated: $filepath (yq)"
			return 0
		fi
	fi

	if command -v ruby &>/dev/null; then
		validator_found=true
		if FILEPATH="$filepath" ruby -ryaml -e 'YAML.safe_load(File.read(ENV.fetch("FILEPATH")))' 2>/dev/null; then
			log_success "YAML validated: $filepath (Ruby)"
			return 0
		fi
	fi

	if [ "$validator_found" = true ]; then
		log_error "Invalid YAML in: $filepath"
		return 1
	fi

	log_warning "No YAML validator available (python3/pyyaml, yq, or ruby), skipping YAML validation for: $filepath"
	return 0
}

# Validate config file based on extension
# Usage: validate_config "filepath"
# Returns: 0 if valid or validation skipped, 1 if invalid
validate_config() {
	local filepath="$1"
	local extension="${filepath##*.}"

	case "$extension" in
	json)
		validate_json "$filepath"
		return $?
		;;
	yaml | yml)
		validate_yaml "$filepath"
		return $?
		;;
	*)
		log_info "Skipping validation for: $filepath (unsupported type: $extension)"
		return 0
		;;
	esac
}

# Run commands in parallel with controlled concurrency
# Usage: run_parallel "max_jobs" "cmd1" "cmd2" "cmd3" ...
run_parallel() {
	local max_jobs="${1:-4}"
	shift

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would run parallel commands: $*"
		return 0
	fi

	local jobs=("$@")
	local running=0
	local pids=()

	for cmd in "${jobs[@]}"; do
		[ -z "$cmd" ] && continue
		(eval "$cmd") &
		pids+=("$!")
		running=$((running + 1))

		if [ "$running" -ge "$max_jobs" ]; then
			# Wait for any job to complete (Bash 3.2 compatible)
			wait "${pids[0]}"
			pids=("${pids[@]:1}")
			running=$((running - 1))
		fi
	done

	# Wait for remaining jobs
	if [ "${#pids[@]}" -gt 0 ]; then
		wait "${pids[@]}"
	fi
}

# Generic interactive installer helper
# Handles auto-install (--yes), interactive prompts, and non-interactive modes
# Usage: run_installer "tool_name" "install_command" "check_command" "version_command"
run_installer() {
	local tool_name="$1"
	local install_cmd="$2"
	local check_cmd="${3:-}"
	local version_cmd="${4:-}"

	_install() {
		log_info "Installing $tool_name..."
		if eval "$check_cmd" &>/dev/null; then
			if [ -n "$version_cmd" ]; then
				log_warning "$tool_name is already installed ($($version_cmd 2>/dev/null))"
			else
				log_warning "$tool_name is already installed"
			fi
		else
			eval "$install_cmd"
			log_success "$tool_name installed"
		fi
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting $tool_name installation (--yes flag)"
		_install
	elif [ -t 0 ]; then
		if prompt_yn "Do you want to install $tool_name"; then
			_install
		else
			log_warning "Skipping $tool_name installation"
		fi
	else
		log_info "Installing $tool_name (non-interactive mode)..."
		_install
	fi
}

# Prompt user for y/n response with proper input handling
# Returns: 0 if user answered 'y' or 'Y', 1 otherwise (including empty/Enter)
# Usage: if prompt_yn "Your question?"; then ... fi
prompt_yn() {
	local prompt="$1"
	local response

	if [ ! -t 0 ]; then
		return 1
	fi

	read -rp "$prompt (y/n) " -n 1 response
	echo

	# Clear any remaining input (like the Enter key)
	while IFS= read -r -t 0 2>/dev/null; do
		IFS= read -r -t 0.1 || break
	done 2>/dev/null || true

	# Return 0 only if response is y or Y
	[[ "$response" =~ ^[Yy]$ ]]
}

# Transaction tracking for rollback support
TRANSACTION_LOG="/tmp/ai-tools-transaction-$$.log"
TRANSACTION_ACTIVE=false

# Start a transaction (records actions for potential rollback)
start_transaction() {
	TRANSACTION_ACTIVE=true
	: >"$TRANSACTION_LOG"
	log_info "Transaction started (actions logged to $TRANSACTION_LOG)"
}

# Record an action for potential rollback
# Usage: record_action "action_type" "target" "backup_command" "restore_command"
record_action() {
	local action_type="$1"
	local target="$2"
	local backup_cmd="$3"
	local restore_cmd="$4"

	if [ "$TRANSACTION_ACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
		echo "$action_type|$target|$backup_cmd|$restore_cmd" >>"$TRANSACTION_LOG"
	fi
}

# Rollback all actions in the transaction log
rollback_transaction() {
	if [ ! -f "$TRANSACTION_LOG" ] || [ ! -s "$TRANSACTION_LOG" ]; then
		log_info "No transaction to rollback"
		return 0
	fi

	log_warning "Rolling back transaction..."
	local count=0

	# Read actions in reverse order (LIFO)
	while IFS='|' read -r action_type target backup_cmd restore_cmd; do
		if [ -n "$action_type" ]; then
			log_info "Rolling back: $action_type on $target"
			eval "$restore_cmd" 2>/dev/null || true
			count=$((count + 1))
		fi
	done < <(tac "$TRANSACTION_LOG")

	log_success "Rolled back $count actions"
}

# End transaction (clears log on success)
end_transaction() {
	if [ "$TRANSACTION_ACTIVE" = true ]; then
		rm -f "$TRANSACTION_LOG"
		TRANSACTION_ACTIVE=false
		log_info "Transaction committed"
	fi
}

# Cleanup plugin cache with proper error handling
# Usage: cleanup_plugin_cache "cli_tool" "plugin_name"
# Returns: 0 on success or if directory doesn't exist, 1 on permission/other errors
cleanup_plugin_cache() {
	local cli_tool="$1"
	local plugin_name="$2"
	local cache_dir="$HOME/.${cli_tool}/plugins/cache/${plugin_name}"

	if [ ! -d "$cache_dir" ]; then
		return 0
	fi

	# Dry-run guard
	if [ "${DRY_RUN:-false}" = true ]; then
		log_info "[DRY RUN] Would clean up ${cli_tool} cache for ${plugin_name}"
		return 0
	fi

	# Perform deletion with proper error handling
	local err_output=""

	if ! err_output=$(rm -rf "$cache_dir" 2>&1); then
		if echo "$err_output" | grep -qi "permission denied"; then
			log_warning "Permission denied cleaning up ${cli_tool} cache for ${plugin_name}"
		elif echo "$err_output" | grep -qi "read-only"; then
			log_warning "Read-only filesystem: cannot clean up ${cli_tool} cache for ${plugin_name}"
		elif echo "$err_output" | grep -qi "busy"; then
			log_warning "Cache directory busy: ${plugin_name} (may be in use)"
		else
			log_warning "Failed to clean up ${cli_tool} cache for ${plugin_name}: $err_output"
		fi
		return 1
	fi

	return 0
}

# Detect if running in non-interactive mode
# Usage: is_non_interactive
# Returns: 0 if non-interactive, 1 if interactive
is_non_interactive() {
	if [ -n "${CI:-}" ]; then
		return 0
	fi

	if [ ! -t 0 ] && [ ! -t 1 ]; then
		return 0
	fi

	if [ -p /dev/stdin ] && [ ! -t 0 ]; then
		return 0
	fi

	return 1
}

# Validate config file with full schema validation if available
# Usage: validate_config_with_schema "filepath"
# Returns: 0 if valid or validation skipped, 1 if invalid
validate_config_with_schema() {
	local filepath="$1"

	# First perform basic syntax validation
	if ! validate_config "$filepath"; then
		return 1
	fi

	# Then perform schema validation if applicable (for JSON files with $schema field)
	local extension="${filepath##*.}"
	if [ "$extension" != "json" ]; then
		return 0
	fi

	# Check if file has a $schema field
	local schema_url
	schema_url=$(jq -r '.["$schema"] // empty' "$filepath" 2>/dev/null)
	[ -z "$schema_url" ] && return 0

	log_info "Found schema reference: $schema_url"
	_validate_with_json_schema "$filepath" "$schema_url"
}

# Internal: Validate JSON against schema URL using available tools
# Usage: _validate_with_json_schema "filepath" "schema_url"
_validate_with_json_schema() {
	local filepath="$1"
	local schema_url="$2"

	# Try check-jsonschema first
	local validation_output=""
	if command -v check-jsonschema &>/dev/null; then
		if validation_output=$(check-jsonschema --schemafile "$schema_url" "$filepath" 2>&1); then
			log_success "Schema validation passed: $filepath (check-jsonschema)"
			return 0
		fi
		log_error "Schema validation failed: $filepath"
		[ -n "$validation_output" ] && log_error "$validation_output"
		return 1
	fi

	# Try ajv-cli
	if command -v ajv &>/dev/null; then
		local temp_schema
		temp_schema=$(make_temp_file "schema" "json")
		if curl -fsSL "$schema_url" -o "$temp_schema" 2>/dev/null; then
			if validation_output=$(ajv validate -s "$temp_schema" -d "$filepath" 2>&1); then
				log_success "Schema validation passed: $filepath (ajv)"
				rm -f "$temp_schema"
				return 0
			fi
			log_error "Schema validation failed: $filepath"
			[ -n "$validation_output" ] && log_error "$validation_output"
			rm -f "$temp_schema"
			return 1
		fi
		log_warning "Could not download schema: $schema_url"
		rm -f "$temp_schema"
		return 0
	fi

	# Try python with jsonschema
	if command -v python3 &>/dev/null && python3 -c "import jsonschema" 2>/dev/null; then
		local temp_schema
		temp_schema=$(make_temp_file "schema" "json")
		if curl -fsSL "$schema_url" -o "$temp_schema" 2>/dev/null; then
			if validation_output=$(python3 -c "
import json
import jsonschema
with open('$temp_schema') as s:
    schema = json.load(s)
with open('$filepath') as f:
    data = json.load(f)
jsonschema.validate(data, schema)
" 2>&1); then
				log_success "Schema validation passed: $filepath (python-jsonschema)"
				rm -f "$temp_schema"
				return 0
			fi
			log_error "Schema validation failed: $filepath"
			[ -n "$validation_output" ] && log_error "$validation_output"
			rm -f "$temp_schema"
			return 1
		fi
		log_warning "Could not download schema: $schema_url"
		rm -f "$temp_schema"
		return 0
	fi

	log_info "No schema validator available (install check-jsonschema, ajv-cli, or python-jsonschema)"
	log_info "Skipping schema validation for: $filepath"
	return 0
}
