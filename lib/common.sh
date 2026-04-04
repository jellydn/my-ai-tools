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
# Improved detection for cross-platform compatibility
IS_WINDOWS=false
_detect_os() {
	case "$OSTYPE" in
	msys*|mingw*|cygwin*|win*)
		return 0
		;;
	*)
		# Also check for MSYSTEM environment variable (common in MSYS2/Git Bash)
		if [ -n "$MSYSTEM" ]; then
			case "$MSYSTEM" in
			MINGW*|MSYS*|CLANG*)
				return 0
				;;
			esac
		fi
		return 1
		;;
	esac
}
_detect_os && IS_WINDOWS=true

# Path helper functions for cross-platform compatibility

# Normalize path to use forward slashes (Unix-style)
# Handles Windows backslash conversion and removes duplicate slashes
# Usage: normalize_path "path/with\\slashes"
normalize_path() {
	local path="$1"
	# Replace backslashes with forward slashes (for Windows paths)
	path="${path//\\//}"
	# Remove duplicate slashes (but not for /// in file:// URLs)
	path="${path//\/\//\//}"
	# Remove trailing slashes (except for root paths like / or C:/)
	path="${path%/}"
	echo "$path"
}

# Get platform-specific temp directory
# Usage: get_temp_dir
get_temp_dir() {
	if [ "$IS_WINDOWS" = true ]; then
		# On Windows, use TEMP or TMPDIR environment variables
		if [ -n "$TEMP" ]; then
			echo "$TEMP"
		elif [ -n "$TMPDIR" ]; then
			echo "$TMPDIR"
		else
			# Fallback to /tmp (works in MSYS2)
			echo "/tmp"
		fi
	else
		# On Unix-like systems
		if [ -n "$TMPDIR" ]; then
			echo "$TMPDIR"
		else
			echo "/tmp"
		fi
	fi
}

# Quote a path if it contains spaces or special characters
# Usage: quote_path "path with spaces"
quote_path() {
	local path="$1"
	# Only quote if path contains spaces or special shell characters
	case "$path" in
	*[\ \'\"]*)
		# Escape any existing quotes and wrap in quotes
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
	# Expand tilde to HOME
	if [ "${path:0:1}" = "~" ]; then
		path="$HOME${path:1}"
	fi
	normalize_path "$path"
}

# Convert Windows path to Unix-style path (for MSYS/Cygwin)
# Handles conversion using cygpath if available, otherwise uses normalize_path
# Usage: to_unix_path "C:\Users\name" -> "/c/Users/name"
to_unix_path() {
	local path="$1"
	# If cygpath is available (Cygwin/MSYS2), use it for proper conversion
	if command -v cygpath &>/dev/null; then
		cygpath -u "$path" 2>/dev/null || normalize_path "$path"
	else
		# Fallback: just normalize slashes
		normalize_path "$path"
	fi
}

# Convert Unix path to Windows-style path (for MSYS/Cygwin)
# Handles conversion using cygpath if available
# Usage: to_windows_path "/c/Users/name" -> "C:/Users/name"
to_windows_path() {
	local path="$1"
	# If cygpath is available (Cygwin/MSYS2), use it for proper conversion
	if command -v cygpath &>/dev/null; then
		cygpath -w "$path" 2>/dev/null || echo "$path"
	else
		# Fallback: just return the path as-is
		echo "$path"
	fi
}

# Safe basename extraction that handles edge cases
# Usage: safe_basename "/path/to/file.txt" -> "file.txt"
safe_basename() {
	local path="$1"
	if [ -z "$path" ]; then
		echo ""
		return 1
	fi
	# Use command basename instead of shell expansion for better safety
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
	# Use command dirname instead of shell expansion for better safety
	dirname "$path" 2>/dev/null || echo "${path%/*}"
}

# Detect tool installation with priority-based detection
# Returns: 0 if tool is detected, 1 otherwise
# Usage: detect_tool "claude" ".claude" "~/.config/claude"
# Detection order: 1) command availability, 2) config directory, 3) config file
detect_tool() {
	local tool_name="$1"
	local config_dir="${2:-}"
	local alt_config_dir="${3:-}"

	# Priority 1: Check if command is available
	if command -v "$tool_name" &>/dev/null; then
		return 0
	fi

	# Priority 2: Check config directories
	local dirs_to_check=()
	if [ -n "$config_dir" ]; then
		dirs_to_check+=("$config_dir")
	fi
	if [ -n "$alt_config_dir" ]; then
		dirs_to_check+=("$alt_config_dir")
	fi

	for dir in "${dirs_to_check[@]}"; do
		local expanded_dir
		expanded_dir=$(expand_path "$dir")
		if [ -d "$expanded_dir" ]; then
			return 0
		fi
	done

	return 1
}

# Detect tool with detailed status output
# Outputs: "command", "directory", "missing" based on detection method
# Usage: detect_tool_detailed "claude" "~/.claude" -> "command"
detect_tool_detailed() {
	local tool_name="$1"
	local config_dir="${2:-}"
	local alt_config_dir="${3:-}"

	# Priority 1: Check if command is available
	if command -v "$tool_name" &>/dev/null; then
		echo "command"
		return 0
	fi

	# Priority 2: Check config directories
	local dirs_to_check=()
	if [ -n "$config_dir" ]; then
		dirs_to_check+=("$config_dir")
	fi
	if [ -n "$alt_config_dir" ]; then
		dirs_to_check+=("$alt_config_dir")
	fi

	for dir in "${dirs_to_check[@]}"; do
		local expanded_dir
		expanded_dir=$(expand_path "$dir")
		if [ -d "$expanded_dir" ]; then
			echo "directory"
			return 0
		fi
	done

	echo "missing"
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
# This is a convenience wrapper that ensures all arguments are properly quoted
# and executes them safely without using eval()
execute_quoted() {
	if [ "$DRY_RUN" = true ]; then
		# Build display string for logging
		local cmd_str=""
		for arg in "$@"; do
			case "$arg" in
			*[\ \'\"]*)
				# Escape quotes for display
				local display_arg="${arg//\"/\\\"}"
				cmd_str="$cmd_str \"$display_arg\""
				;;
			*)
				cmd_str="$cmd_str $arg"
				;;
			esac
		done
		log_info "[DRY RUN]$cmd_str"
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

	# Use platform-specific temp directory for cross-platform support
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
	# Use HOME/.claude/tmp to keep it in the same filesystem (handles cross-platform)
	local tmp_dir="${HOME}/.claude/tmp"
	if ! mkdir -p "$tmp_dir" 2>/dev/null; then
		# Fall back to platform-specific temp directory
		tmp_dir=$(get_temp_dir)
		if ! mkdir -p "$tmp_dir" 2>/dev/null; then
			log_warning "Could not create temp directory, using /tmp"
			tmp_dir="/tmp"
		fi
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
	local backup_pattern="$HOME/ai-tools-backup-"

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would clean up backups (keep $max_backups most recent)"
		return 0
	fi

	# Find all backup directories and sort by modification time (newest first)
	local old_backups
	old_backups=$(find "$HOME" -maxdepth 1 -type d -name "${backup_pattern##*/}*" -printf "%T@ %p\n" 2>/dev/null | sort -rn | tail -n +$((max_backups + 1)) | cut -d' ' -f2-)

	if [ -n "$old_backups" ]; then
		for backup_dir in $old_backups; do
			if [ -d "$backup_dir" ]; then
				rm -rf "$backup_dir"
				log_info "Cleaned up old backup: $backup_dir"
			fi
		done
	fi
}

# Helper: Validate file exists and run validator command
# Usage: _validate_with_tool "filepath" "tool_check_cmd" "validator_cmd" "error_type"
# Returns: 0 if valid, 1 if invalid
_validate_with_tool() {
	local filepath="$1"
	local tool_check_cmd="$2"
	local validator_cmd="$3"
	local error_type="$4"

	if [ ! -f "$filepath" ]; then
		log_error "File not found: $filepath"
		return 1
	fi

	if eval "$tool_check_cmd" &>/dev/null; then
		if eval "$validator_cmd" 2>/dev/null; then
			return 0
		else
			log_error "Invalid $error_type in: $filepath"
			return 1
		fi
	else
		log_warning "Validator not available, skipping $error_type validation for: $filepath"
		return 0
	fi
}

# Validate JSON file syntax
# Usage: validate_json "filepath"
# Returns: 0 if valid, 1 if invalid
validate_json() {
	_validate_with_tool "$1" "command -v jq" "jq empty '$filepath'" "JSON"
}

# Validate YAML file syntax with detailed error reporting
# Usage: validate_yaml "filepath"
# Returns: 0 if valid, 1 if invalid
validate_yaml() {
	local filepath="$1"

	if [ ! -f "$filepath" ]; then
		log_error "File not found: $filepath"
		return 1
	fi

	local validation_failed=false
	local validator_used=""

	# Try Python with PyYAML first (best error messages)
	if command -v python3 &>/dev/null; then
		if python3 -c "import yaml; yaml.safe_load(open('$filepath'))" 2>/dev/null; then
			log_success "YAML validated: $filepath (Python/PyYAML)"
			return 0
		else
			validation_failed=true
			validator_used="Python/PyYAML"
		fi
	fi

	# Try yq if available (better for YAML-specific validation)
	if command -v yq &>/dev/null; then
		if yq '.' "$filepath" &>/dev/null; then
			log_success "YAML validated: $filepath (yq)"
			return 0
		else
			validation_failed=true
			validator_used="yq"
		fi
	fi

	# Fallback to Ruby
	if command -v ruby &>/dev/null; then
		if ruby -ryaml -e "YAML.safe_load(File.read('$filepath'))" 2>/dev/null; then
			log_success "YAML validated: $filepath (Ruby)"
			return 0
		else
			validation_failed=true
			validator_used="Ruby"
		fi
	fi

	if [ "$validation_failed" = true ]; then
		log_error "Invalid YAML in: $filepath (checked with $validator_used)"
		log_info "Install a YAML validator for better error messages:"
		log_info "  - Python: pip install pyyaml"
		log_info "  - yq: brew install yq (macOS) or download from https://github.com/mikefarah/yq"
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
		yaml|yml)
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
# Usage: run_parallel "cmd1" "cmd2" "cmd3" ... [max_jobs]
run_parallel() {
	local max_jobs="${1:-4}"
	shift

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would run parallel commands: $*"
		return 0
	fi

	local jobs=("$@")
	local running=0
	local completed=0

	for cmd in "${jobs[@]}"; do
		if [ -z "$cmd" ]; then
			continue
		fi

		(
			eval "$cmd"
		) &
		running=$((running + 1))

		if [ "$running" -ge "$max_jobs" ]; then
			wait -n
			running=$((running - 1))
			completed=$((completed + 1))
		fi
	done

	# Wait for remaining jobs
	while [ $running -gt 0 ]; do
		wait -n
		running=$((running - 1))
		completed=$((completed + 1))
	done
}

# Install plugin in background (for parallel execution)
# Usage: install_plugin_bg "plugin_name"
install_plugin_bg() {
	local plugin="$1"
	local log_file="/tmp/plugin-install-${plugin//\//-}-$$.log"

	if execute "claude plugin install '$plugin' &>$log_file" 2>/dev/null; then
		log_success "$plugin installed"
	else
		if grep -qi "already" "$log_file" 2>/dev/null; then
			log_info "$plugin already installed"
		else
			log_warning "$plugin install failed (check $log_file for details)"
		fi
	fi
	rm -f "$log_file"
}

# Generic interactive installer helper
# Handles auto-install (--yes), interactive prompts, and non-interactive modes
# Usage: run_installer "tool_name" "install_command" "check_command" "version_command"
run_installer() {
	local tool_name="$1"
	local install_cmd="$2"
	local check_cmd="${3:-}"
	local version_cmd="${4:-}"

	_log_install() {
		log_info "Installing $tool_name..."
	}

	_install() {
		_log_install
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
		read -rp "Do you want to install $tool_name? (y/n) " -n 1
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			_install
		else
			log_warning "Skipping $tool_name installation"
		fi
	else
		log_info "Installing $tool_name (non-interactive mode)..."
		_install
	fi
}

# Install community plugin in background (for parallel execution)
# Usage: install_community_plugin_bg "name" "plugin_spec" "marketplace_repo"
install_community_plugin_bg() {
	local name="$1"
	local plugin_spec="$2"
	local marketplace_repo="$3"
	local log_file="/tmp/community-plugin-${name}-$$.log"

	# Add marketplace and install in background
	(
		setup_tmpdir
		claude plugin marketplace add "$marketplace_repo" 2>/dev/null || true
		cleanup_plugin_cache "claude" "$name"
		claude plugin install "$plugin_spec" 2>/dev/null
	) &>"$log_file"

	if grep -qi "already\|success" "$log_file" 2>/dev/null; then
		log_success "$name installed"
	else
		log_warning "$name install failed (check $log_file for details)"
	fi
	rm -f "$log_file"
}

# Transaction tracking for rollback support
TRANSACTION_LOG="/tmp/ai-tools-transaction-$$.log"
TRANSACTION_ACTIVE=false

# Start a transaction (records actions for potential rollback)
start_transaction() {
	TRANSACTION_ACTIVE=true
	: > "$TRANSACTION_LOG"
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
		echo "$action_type|$target|$backup_cmd|$restore_cmd" >> "$TRANSACTION_LOG"
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
# Note: This function logs warnings but doesn't fail - cleanup is best-effort
cleanup_plugin_cache() {
	local cli_tool="$1"
	local plugin_name="$2"
	local cache_dir="$HOME/.${cli_tool}/plugins/cache/${plugin_name}"

	if [ ! -d "$cache_dir" ]; then
		# Directory doesn't exist - this is fine, no cleanup needed
		return 0
	fi

	# Attempt removal and capture any error output
	local err_output
	err_output=$(rm -rf "$cache_dir" 2>&1)
	local exit_code=$?

	if [ $exit_code -ne 0 ]; then
		# Check for specific error types
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
# Checks multiple indicators to avoid false positives from simple stdin piping
is_non_interactive() {
	# Check standard indicators
	if [ -n "${CI:-}" ]; then
		# CI environment variable set - definitely non-interactive
		return 0
	fi

	if [ ! -t 0 ] && [ ! -t 1 ]; then
		# Neither stdin nor stdout is a terminal - likely non-interactive
		return 0
	fi

	if [ -p /dev/stdin ] && [ ! -t 0 ]; then
		# Stdin is a pipe and not a terminal
		return 0
	fi

	return 1
}

# Validate JSON file against schema if $schema field is present
# Usage: validate_json_schema "filepath"
# Returns: 0 if valid or schema validation skipped, 1 if invalid
# This performs install-time validation for configs with $schema fields
validate_json_schema() {
	local filepath="$1"

	if [ ! -f "$filepath" ]; then
		log_error "File not found: $filepath"
		return 1
	fi

	# Basic JSON syntax validation first
	if ! validate_json "$filepath"; then
		return 1
	fi

	# Check if file has a $schema field
	local schema_url
	schema_url=$(jq -r '.["$schema"] // empty' "$filepath" 2>/dev/null)

	if [ -z "$schema_url" ]; then
		# No schema defined, skip schema validation
		return 0
	fi

	log_info "Found schema reference: $schema_url"

	# Try to validate with available tools
	# Priority: check-jsonschema > ajv-cli > python jsonschema

	if command -v check-jsonschema &>/dev/null; then
		if check-jsonschema --schemafile "$schema_url" "$filepath" 2>/dev/null; then
			log_success "Schema validation passed: $filepath (check-jsonschema)"
			return 0
		else
			log_warning "Schema validation issues in: $filepath (may be non-critical)"
			return 0
		fi
	fi

	if command -v ajv &>/dev/null; then
		# Download schema temporarily for ajv
		local temp_schema
		temp_schema=$(make_temp_file "schema" "json")
		if curl -fsSL "$schema_url" -o "$temp_schema" 2>/dev/null; then
			if ajv validate -s "$temp_schema" -d "$filepath" 2>/dev/null; then
				log_success "Schema validation passed: $filepath (ajv)"
				rm -f "$temp_schema"
				return 0
			else
				log_warning "Schema validation issues in: $filepath (may be non-critical)"
				rm -f "$temp_schema"
				return 0
			fi
		else
			log_warning "Could not download schema: $schema_url"
			rm -f "$temp_schema"
			return 0
		fi
	fi

	if command -v python3 &>/dev/null; then
		# Try python with jsonschema if available
		if python3 -c "import jsonschema" 2>/dev/null; then
			local temp_schema
			temp_schema=$(make_temp_file "schema" "json")
			if curl -fsSL "$schema_url" -o "$temp_schema" 2>/dev/null; then
				if python3 -c "
import json
import jsonschema
with open('$temp_schema') as s:
    schema = json.load(s)
with open('$filepath') as f:
    data = json.load(f)
jsonschema.validate(data, schema)
" 2>/dev/null; then
					log_success "Schema validation passed: $filepath (python-jsonschema)"
					rm -f "$temp_schema"
					return 0
				else
					log_warning "Schema validation issues in: $filepath (may be non-critical)"
					rm -f "$temp_schema"
					return 0
				fi
			else
				log_warning "Could not download schema: $schema_url"
				rm -f "$temp_schema"
				return 0
			fi
		fi
	fi

	log_info "No schema validator available (install check-jsonschema, ajv-cli, or python-jsonschema)"
	log_info "Skipping schema validation for: $filepath"
	return 0
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

	# Then perform schema validation if applicable (for JSON files)
	local extension="${filepath##*.}"
	if [ "$extension" = "json" ]; then
		validate_json_schema "$filepath"
		return $?
	fi

	return 0
}
