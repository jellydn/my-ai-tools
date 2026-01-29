#!/bin/bash
# Shared utilities for my-ai-tools scripts
# Source this file using: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
# Note: Uses eval to properly handle quoted arguments and shell operators
execute() {
	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] $1"
	else
		eval "$1"
	fi
}

# Download and verify script with checksum (if available)
# Usage: download_and_verify_script "url" "expected_sha256" "description"
download_and_verify_script() {
	local url="$1"
	local expected_sha256="$2"
	local description="$3"
	
	# Use TMPDIR if set, otherwise use /tmp
	local tmpdir="${TMPDIR:-/tmp}"
	local temp_script="${tmpdir}/install-$(date +%s)-$$"

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
	mkdir -p "$tmp_dir" 2>/dev/null || true
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
	old_backups=$(find "$HOME" -maxdepth 1 -type d -name "ai-tools-backup-*" -printf "%T@ %p\n" 2>/dev/null | sort -rn | tail -n +$((max_backups + 1)) | cut -d' ' -f2-)

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

# Validate YAML file syntax
# Usage: validate_yaml "filepath"
# Returns: 0 if valid, 1 if invalid
validate_yaml() {
	if command -v python3 &>/dev/null; then
		_validate_with_tool "$1" "command -v python3" "python3 -c \"import yaml; yaml.safe_load(open('$filepath'))\"" "YAML"
	elif command -v ruby &>/dev/null; then
		_validate_with_tool "$1" "command -v ruby" "ruby -ryaml -e \"Yaml.safe_load(File.read('$filepath'))\"" "YAML"
	else
		local filepath="$1"
		if [ ! -f "$filepath" ]; then
			log_error "File not found: $filepath"
			return 1
		fi
		log_warning "No YAML validator available (python3/ruby), skipping YAML validation for: $filepath"
		return 0
	fi
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
		log_info "[DRY RUN] Would run parallel commands: $@"
		return 0
	fi

	local jobs=("$@")
	local running=0
	local completed=0
	local total=${#jobs[@]}

	for cmd in "${jobs[@]}"; do
		if [ -z "$cmd" ]; then
			continue
		fi

		(
			eval "$cmd"
		) &
		running=$((running + 1))

		if [ $running -ge $max_jobs ]; then
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
		rm -rf "$HOME/.claude/plugins/cache/$name" 2>/dev/null || true
		claude plugin install "$plugin_spec" 2>/dev/null
	) &>$log_file

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
