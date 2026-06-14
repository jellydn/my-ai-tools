#!/bin/bash

# Re-exec under bash if invoked via sh/dash. lib/require_bash.sh is POSIX-compatible
# so sh can source it and trigger the re-exec before lib/common.sh is reached.
source "$(dirname "${BASH_SOURCE[0]}")/lib/require_bash.sh"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/install.sh"
# Parse command-line arguments first (only when executed, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
BACKUP_DIR="$HOME/ai-tools-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
BACKUP=false
PROMPT_BACKUP=true
YES_TO_ALL=false
VERBOSE=false

# Track whether Amp is installed (for backlog.md dependency)
AMP_INSTALLED=false
# Track whether --migrate-gemini flag was passed (standalone Gemini→Antigravity migration)
MIGRATE_GEMINI=false
for arg in "$@"; do
	case $arg in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	--backup)
		BACKUP=true
		PROMPT_BACKUP=false
		shift
		;;
	--no-backup)
		BACKUP=false
		PROMPT_BACKUP=false
		shift
		;;
	--yes | -y)
		YES_TO_ALL=true
		shift
		;;
	-v | --verbose)
		VERBOSE=true
		shift
		;;
	--migrate-gemini)
		MIGRATE_GEMINI=true
		shift
		;;
	--rollback)
		log_info "Rolling back last transaction..."
		rollback_transaction
		exit $?
		;;
	*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run] [--backup] [--no-backup] [--yes|-y] [-v|--verbose] [--migrate-gemini] [--rollback]"
		exit 1
		;;
	esac
done

# Auto-detect non-interactive mode AFTER parsing arguments
# This ensures DRY_RUN and other flags are set before any functions use them
if is_non_interactive; then
	YES_TO_ALL=true
	log_info "Non-interactive mode detected (CI or piped input)"
fi

fi

# Preflight check for required tools
preflight_check() {
	local missing_tools=()

	log_info "Running preflight checks..."

	local required_tools=("awk" "sed" "basename" "cat" "head" "tail" "grep" "date")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" &>/dev/null; then
			missing_tools+=("$tool")
		fi
	done

	if [ ${#missing_tools[@]} -gt 0 ]; then
		log_error "Missing required tools: ${missing_tools[*]}"
		log_info "Please install the missing tools and try again."
		exit 1
	fi

	log_success "All required tools available"
}

# Install MCP server with retry mechanism and better error handling
install_mcp_server() {
	local server_name="$1"
	local install_cmd="$2"
	local max_retries=3
	local retry_count=0
	local backoff=1
	local err_file
	err_file=$(make_temp_file "claude-mcp-${server_name}" "err")

	while [ $retry_count -lt $max_retries ]; do
		# Try installation
		if execute "$install_cmd" 2>"$err_file"; then
			log_success "${server_name} MCP server added (global)"
			rm -f "$err_file"
			return 0
		fi

		# Check if already installed (success case)
		if grep -qi "already" "$err_file" 2>/dev/null; then
			log_info "${server_name} already installed"
			rm -f "$err_file"
			return 0
		fi

		retry_count=$((retry_count + 1))

		# Check if retryable error and we have retries left
		if [ $retry_count -lt $max_retries ] && grep -qiE "(connection|timed?out|network|econnrefused|etimedout)" "$err_file" 2>/dev/null; then
			log_warning "${server_name} installation failed (attempt $retry_count/$max_retries) - retrying in ${backoff}s..."
			sleep "$backoff"
			backoff=$((backoff * 2))
		else
			# Not retryable or out of retries
			break
		fi
	done

	# All retries exhausted or non-retryable error
	log_error "${server_name} installation failed after ${retry_count} attempts"
	if [ -s "$err_file" ]; then
		log_error "Error details:"
		head -20 "$err_file" >&2
	fi
	log_info "You can try installing manually: $install_cmd"
	rm -f "$err_file"
	return 1
}

# Set up TMPDIR to avoid cross-device link errors
setup_tmpdir() {
	local tmp_dir="$HOME/.claude/tmp"
	mkdir -p "$tmp_dir" 2>/dev/null || true
	export TMPDIR="$tmp_dir"
}

check_prerequisites() {
	log_info "Checking prerequisites..."

	if ! command -v git &>/dev/null; then
		log_error "Git is not installed. Please install git first."
		exit 1
	fi
	log_success "Git found"

	if command -v bun &>/dev/null; then
		BUN_VERSION=$(bun --version)
		log_success "Bun found ($BUN_VERSION)"
	elif command -v node &>/dev/null; then
		NODE_VERSION=$(node --version)
		log_success "Node.js found ($NODE_VERSION)"
		handle_optional_bun_installation
	else
		log_error "Neither Bun nor Node.js is installed."
		handle_bun_installation
	fi

	handle_qmd_installation_if_needed
}


# Helper: Safely copy a directory, handling "Text file busy" errors
# Usage: safe_copy_dir "source_dir" "dest_dir"
safe_copy_dir() {
	local source_dir="$1"
	local dest_dir="$2"
	local skipped=0
	local errors=0

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would copy $source_dir to $dest_dir"
		return 0
	fi

	if ! mkdir -p "$(dirname "$dest_dir")" 2>/dev/null; then
		log_warning "Failed to create destination directory: $(dirname "$dest_dir")"
		return 1
	fi

	# Directories to exclude from copies
	local -a exclude_dirs=(
		"node_modules" "plugins" "projects" "debug" "sessions" "git"
		"cache" "extensions" "chats" "antigravity" "antigravity-browser-profile"
		"log" "logs" "tmp" "vendor_imports" "file-history" "ai-tracking"
	)

	# Prefer rsync when available
	if command -v rsync &>/dev/null; then
		local -a rsync_excludes=()
		for dir in "${exclude_dirs[@]}"; do
			rsync_excludes+=(--exclude "$dir" --exclude "$dir/**")
		done
		rsync_excludes+=(--exclude "*.sqlite" --exclude "*.sqlite-wal" --exclude "*.sqlite-shm")
		if rsync -a --ignore-errors "${rsync_excludes[@]}" "$source_dir/" "$dest_dir/" 2>/dev/null; then
			return 0
		fi
	fi

	# Fallback: manual copy
	local prune_expr=""
	for dir in "${exclude_dirs[@]}"; do
		prune_expr="$prune_expr -name $dir -o"
	done
	prune_expr="${prune_expr% -o}"

	mkdir -p "$dest_dir"
	# POSIX: use temp file instead of process substitution so the loop runs in the current shell
	local _find_list
	_find_list=$(make_temp_file "safe-copy-find" "list")
	find "$source_dir" -type d \( $prune_expr \) -prune -o -type f -print 2>/dev/null > "$_find_list"
	while IFS= read -r file; do
		case "$file" in *.sqlite | *.sqlite-wal | *.sqlite-shm) continue ;; esac
		local rel_path="${file#"$source_dir"/}"
		local dest_file="$dest_dir/$rel_path"
		mkdir -p "$(dirname "$dest_file")"
		if ! cp "$file" "$dest_file" 2>/dev/null; then
			((errors++))
			((skipped++))
			[ "$VERBOSE" = true ] && log_warning "Skipped busy file: $rel_path"
		fi
	done < "$_find_list"
	rm -f "$_find_list"

	[ "$VERBOSE" = true ] && [ $skipped -gt 0 ] && log_info "Skipped $skipped busy file(s)"
	return 0
}

# Helper: Copy a config directory if it exists in source and destination
# Usage: copy_config_dir "source_dir" "dest_parent" "dest_name"
copy_config_dir() {
	local source_dir="$1"
	local dest_parent="$2"
	local dest_name="$3"

	if [ -d "$source_dir" ]; then
		execute_quoted mkdir -p "$dest_parent"
		safe_copy_dir "$source_dir" "$dest_parent/$dest_name"
		log_success "Backed up $dest_name configs"
	fi
}

# Helper: Copy a config file if it exists in source
# If the destination already has a file with the same name, backs it up as .bak first.
# Usage: copy_config_file "source_file" "dest_dir"
copy_config_file() {
	local source_file="$1"
	local dest_dir="$2"

	if [ ! -f "$source_file" ]; then
		return 1
	fi

	execute_quoted mkdir -p "$dest_dir" || return 1

	local _filename
	_filename=$(basename "$source_file")

	# Backup existing file before overwriting
	if [ -f "$dest_dir/$_filename" ]; then
		execute_quoted cp "$dest_dir/$_filename" "$dest_dir/$_filename.bak" || true
		log_success "Backed up existing $_filename to $_filename.bak"
	fi

	execute_quoted cp -p "$source_file" "$dest_dir/" || return 1
	return 0
}

# Helper: Ensure a CLI tool is installed, prompting if interactive
# Usage: ensure_cli_tool "tool_name" "install_cmd" "version_cmd"

# Helper: Copy non-marketplace skills to universal directory only
# Usage: copy_non_marketplace_skills "source_dir"
copy_non_marketplace_skills() {
	local source_dir="$1"

	if [ ! -d "$source_dir" ] || [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		return 0
	fi

	# All modern AI tools support ~/.agents/skills/ as the universal location
	# We don't copy to tool-specific directories anymore to avoid conflicts
	log_info "Skills are managed in universal directory ~/.agents/skills/"
	return 0
}

backup_configs() {
	cleanup_old_backups 5

	if [ "$PROMPT_BACKUP" = true ]; then
		if [ "$YES_TO_ALL" = true ]; then
			log_info "Auto-accepting backup (--yes flag)"
			BACKUP=true
		elif [ -t 0 ]; then
			if prompt_yn "Do you want to backup existing configurations"; then
				BACKUP=true
			fi
		else
			log_info "Skipping backup prompt in non-interactive mode (use --backup to force backup)"
		fi
	fi

	if [ "$BACKUP" = true ]; then
		log_info "Creating backup at $BACKUP_DIR..."
		execute_quoted mkdir -p "$BACKUP_DIR"

		copy_config_dir "$HOME/.claude" "$BACKUP_DIR" "claude"
		copy_config_dir "$HOME/.config/opencode" "$BACKUP_DIR" "opencode"
		copy_config_dir "$HOME/.config/amp" "$BACKUP_DIR" "amp"
		copy_config_dir "$HOME/.codex" "$BACKUP_DIR" "codex"
		copy_config_dir "$HOME/.gemini" "$BACKUP_DIR" "gemini"
		copy_config_dir "$HOME/.config/kilo" "$BACKUP_DIR" "kilo"
		copy_config_dir "$HOME/.pi" "$BACKUP_DIR" "pi"
		copy_config_dir "$HOME/.cursor" "$BACKUP_DIR" "cursor"
		copy_config_dir "$HOME/.factory" "$BACKUP_DIR" "factory"
		copy_config_dir "$HOME/Library/Application Support/orca/agent-hooks" "$BACKUP_DIR/orca" "agent-hooks"
		copy_config_dir "$HOME/.cline" "$BACKUP_DIR" "cline"
		copy_config_dir "$HOME/.commandcode" "$BACKUP_DIR" "commandcode"
		copy_config_dir "$HOME/.grok" "$BACKUP_DIR" "grok"
		copy_config_dir "$HOME/.config/mimocode" "$BACKUP_DIR" "mimocode"
		copy_config_file "$HOME/.config/ai-launcher/config.json" "$BACKUP_DIR/ai-launcher" || true

		log_success "Backup completed: $BACKUP_DIR"
	fi
}

# Helper: Copy OpenCode commands, skipping my-ai-tools folder
# Usage: copy_opencode_commands "source_dir" "dest_dir"
copy_opencode_commands() {
	local source_dir="$1"
	local dest_dir="$2"

	if [ ! -d "$source_dir" ] || [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		return 0
	fi

	execute_quoted mkdir -p "$dest_dir"

	for item in "$source_dir"/*; do
		if [ -d "$item" ]; then
			local command_name
			command_name="$(basename "$item")"
			[ "$command_name" = "my-ai-tools" ] && continue
			safe_copy_dir "$item" "$dest_dir/$command_name"
		elif [ -f "$item" ]; then
			execute_quoted cp "$item" "$dest_dir/"
		fi
	done
}

# Helper: Install MCP server with interactive prompts
# Usage: install_mcp_interactive "name" "install_cmd" "description"
install_mcp_interactive() {
	local name="$1"
	local install_cmd="$2"
	local description="$3"

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting MCP server installation (--yes flag)"
		if execute "$install_cmd"; then
			log_success "$name MCP server added (global)"
		else
			log_warning "$name already installed or failed"
		fi
	elif [ -t 0 ]; then
		if prompt_yn "Install $name MCP server ($description)"; then
			if execute "$install_cmd"; then
				log_success "$name MCP server added (global)"
			else
				log_warning "$name already installed or failed"
			fi
		fi
	else
		install_mcp_server "$name" "$install_cmd"
	fi
}

copy_grok_configs() {
	local grok_status
	grok_status=$(detect_tool --detailed "grok" "$HOME/.grok") || grok_status="missing"
	if [ "$grok_status" = "missing" ]; then
		log_info "Grok CLI not detected - skipping Grok config installation"
		return 0
	fi

	log_info "Detected Grok CLI (via $grok_status)"
	execute_quoted mkdir -p "$HOME/.grok"

	copy_config_file "$SCRIPT_DIR/configs/grok/AGENTS.md" "$HOME/.grok/" || true

	copy_config_file "$SCRIPT_DIR/configs/grok/config.toml" "$HOME/.grok/" || true

	if [ -d "$SCRIPT_DIR/configs/grok/themes" ]; then
		execute_quoted mkdir -p "$HOME/.grok/themes"
		safe_copy_dir "$SCRIPT_DIR/configs/grok/themes" "$HOME/.grok/themes"
	fi

	log_success "Grok CLI configs copied"
}

copy_mimo_configs() {
	local mimo_status
	mimo_status=$(detect_tool --detailed "mimo" "$HOME/.config/mimocode") || mimo_status="missing"
	if [ "$mimo_status" = "missing" ]; then
		log_info "MiMo-Code not detected - skipping MiMo-Code config installation"
		return 0
	fi

	log_info "Detected MiMo-Code (via $mimo_status)"
	execute_quoted mkdir -p "$HOME/.config/mimocode"

	# Single config files (AGENTS.md, mimocode.jsonc, tui.json) are copied individually.
	# mimocode.jsonc gets a backup-before-overwrite since users may customize it.
	copy_config_file "$SCRIPT_DIR/configs/mimo/AGENTS.md" "$HOME/.config/mimocode/" || true

	copy_config_file "$SCRIPT_DIR/configs/mimo/mimocode.jsonc" "$HOME/.config/mimocode/" || true

	if [ -f "$SCRIPT_DIR/configs/mimo/tui.json" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/mimo/tui.json" "$HOME/.config/mimocode/"
	fi

	# Agent and command directories get full replacement (rm -rf + safe_copy_dir)
	# These are repo-owned and should always mirror the source exactly.
	# Any user-local additions would be lost, so don't add custom agents/commands here;
	# add them directly in ~/.config/mimocode/agent/ or ~/.config/mimocode/command/ instead.
	if [ -d "$SCRIPT_DIR/configs/mimo/agent" ]; then
		execute_quoted rm -rf "$HOME/.config/mimocode/agent"
		safe_copy_dir "$SCRIPT_DIR/configs/mimo/agent" "$HOME/.config/mimocode/agent"
	fi

	if [ -d "$SCRIPT_DIR/configs/mimo/command" ]; then
		execute_quoted rm -rf "$HOME/.config/mimocode/command"
		safe_copy_dir "$SCRIPT_DIR/configs/mimo/command" "$HOME/.config/mimocode/command"
	fi

	# Theme and plugin directories use additive copy (mkdir -p + safe_copy_dir)
	# Users may add custom themes or plugins locally that should be preserved.
	# safe_copy_dir copies repo files but does NOT remove files that already exist
	# in the destination — user additions survive the install.
	if [ -d "$SCRIPT_DIR/configs/mimo/themes" ]; then
		execute_quoted mkdir -p "$HOME/.config/mimocode/themes"
		safe_copy_dir "$SCRIPT_DIR/configs/mimo/themes" "$HOME/.config/mimocode/themes"
	fi

	if [ -d "$SCRIPT_DIR/configs/mimo/plugins" ]; then
		execute_quoted mkdir -p "$HOME/.config/mimocode/plugins"
		safe_copy_dir "$SCRIPT_DIR/configs/mimo/plugins" "$HOME/.config/mimocode/plugins"
	fi

	log_success "MiMo-Code configs copied"
}

copy_configurations() {
	log_info "Copying configurations..."

	validate_all_configs

	copy_claude_configs
	copy_opencode_configs
	copy_amp_configs
	copy_ai_launcher_configs
	copy_codex_configs
	copy_gemini_configs
	copy_antigravity_configs
	copy_kilo_configs
	copy_pi_configs
	copy_commandcode_configs
	copy_copilot_configs
	copy_cursor_configs
	copy_factory_configs
	copy_orca_configs
	copy_cline_configs
	copy_grok_configs
	copy_mimo_configs
	copy_best_practices
}

# Validate all config files
validate_all_configs() {
	log_info "Validating configuration files..."
	local config_validation_failed=false

	# Validate Claude Code configs
	if ! validate_config_with_schema "$SCRIPT_DIR/configs/claude/settings.json"; then
		log_error "Claude Code settings.json failed validation"
		config_validation_failed=true
	fi
	if ! validate_config "$SCRIPT_DIR/configs/claude/mcp-servers.json"; then
		log_error "Claude Code mcp-servers.json failed validation"
		config_validation_failed=true
	fi

	# Validate OpenCode config
	if [ -f "$SCRIPT_DIR/configs/opencode/opencode.json" ]; then
		if ! validate_config_with_schema "$SCRIPT_DIR/configs/opencode/opencode.json"; then
			log_error "OpenCode config failed validation"
			config_validation_failed=true
		fi
	fi

	# Validate other tool configs
	for config_file in "$SCRIPT_DIR/configs/amp/settings.json" \
		"$SCRIPT_DIR/configs/ai-launcher/config.json" \
		"$SCRIPT_DIR/configs/codex/config.json" \
		"$SCRIPT_DIR/configs/gemini/settings.json" \
		"$SCRIPT_DIR/configs/antigravity-cli/settings.json" \
		"$SCRIPT_DIR/configs/kilo/config.json" \
		"$SCRIPT_DIR/configs/pi/settings.json" \
		"$SCRIPT_DIR/configs/commandcode/settings.json" \
		"$SCRIPT_DIR/configs/commandcode/mcp.json" \
		"$SCRIPT_DIR/configs/factory/settings.json"; do
		if [ -f "$config_file" ] && ! validate_config "$config_file"; then
			log_error "Config validation failed: $config_file"
			config_validation_failed=true
		fi
	done

	for config_file in "$SCRIPT_DIR"/configs/antigravity-cli/plugins/*/plugin.json \
		"$SCRIPT_DIR"/configs/antigravity-cli/plugins/*/mcp_config.json; do
		if [ -f "$config_file" ] && ! validate_config "$config_file"; then
			log_error "Config validation failed: $config_file"
			config_validation_failed=true
		fi
	done

	if [ "$config_validation_failed" = true ]; then
		log_warning "Some configuration files failed validation"
		if [ "$YES_TO_ALL" = false ] && [ -t 0 ]; then
			if ! prompt_yn "Continue anyway"; then
				log_error "Installation aborted due to config validation failures"
				exit 1
			fi
		else
			log_info "Continuing despite validation failures (--yes or non-interactive mode)"
		fi
	else
		log_success "All configuration files validated successfully"
	fi
}

copy_claude_configs() {
	execute_quoted mkdir -p "$HOME/.claude"

	# Copy core configs
	execute_quoted cp "$SCRIPT_DIR/configs/claude/settings.json" "$HOME/.claude/settings.json"
	execute_quoted cp "$SCRIPT_DIR/configs/claude/mcp-servers.json" "$HOME/.claude/mcp-servers.json"
	execute_quoted cp "$SCRIPT_DIR/configs/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

	# Copy directories
	execute_quoted rm -rf "$HOME/.claude/commands"
	safe_copy_dir "$SCRIPT_DIR/configs/claude/commands" "$HOME/.claude/commands"

	if [ -d "$SCRIPT_DIR/configs/claude/agents" ]; then
		safe_copy_dir "$SCRIPT_DIR/configs/claude/agents" "$HOME/.claude/agents"
	fi

	if [ -d "$SCRIPT_DIR/configs/claude/hooks" ]; then
		execute_quoted mkdir -p "$HOME/.claude/hooks"
		safe_copy_dir "$SCRIPT_DIR/configs/claude/hooks" "$HOME/.claude/hooks"
		log_success "Claude Code hooks installed"
	fi

	# Add MCP servers
	setup_claude_mcp_servers

	log_success "Claude Code configs copied"
}

# Install MCP servers from central registry with interactive prompts
# Usage: install_mcp_servers_from_registry <tool_cmd> [registry_file]
install_mcp_servers_from_registry() {
	local tool_cmd="${1:-claude}"
	local registry_file="${2:-$SCRIPT_DIR/configs/mcp-registry.json}"
	local installed_count=0
	local skipped_count=0
	local failed_count=0

	if ! command -v jq &>/dev/null; then
		log_warning "jq not found. Cannot parse MCP registry. Install jq to use registry-based MCP installation."
		return 1
	fi

	if [ ! -f "$registry_file" ]; then
		log_warning "MCP registry not found: $registry_file"
		return 1
	fi

	local script_runner
	script_runner=$(_detect_script_runner)

	if [ -z "$script_runner" ]; then
		log_warning "No script runner found (bunx or npx). Cannot install registry MCP servers."
		return 1
	fi

	log_info "Loading MCP servers from registry (using $script_runner)..."

	local summary_lines=()

	# Extract all server data in a single jq call for efficiency
	# Fields: server_name, name, description, command, args_delimited, requires_delimited, category
	# Read from FD 3 so stdin stays attached to the terminal for prompt_yn.
	while IFS=$'\t' read -r server_name name description command args_delimited requires_delimited category <&3; do
		# Substitute {{SCRIPT_RUNNER}} placeholder (POSIX: use sed, not ${}//)
		command=$(printf '%s\n' "$command" | sed "s|{{SCRIPT_RUNNER}}|$script_runner|g")

		# Parse args into array (args are delimited by SOH character)
		local args_array=()
		if [ -n "$args_delimited" ]; then
			while IFS= read -r -d $'\x01' arg; do
				args_array+=("$arg")
			done <<<"$args_delimited"
		fi

		# Check prerequisites
		local prereqs_met=true
		local missing_prereqs=()

		if [ -n "$requires_delimited" ]; then
			local prereq
			while IFS= read -r -d $'\x01' prereq; do
				[ -z "$prereq" ] && continue

				if ! command -v "$prereq" &>/dev/null; then
					case "$prereq" in
					"fff-mcp")
						log_info "Auto-installing prerequisite: $prereq"
						install_fff_mcp_now && continue
						;;
					"logpilot")
						log_info "Auto-installing prerequisite: $prereq"
						install_logpilot_now && continue
						;;
					"sem-mcp")
						log_info "Auto-installing prerequisite: $prereq"
						install_sem_now && continue
						;;
					esac
					prereqs_met=false
					missing_prereqs+=("$prereq")
				fi
			done <<<"$requires_delimited"
		fi

		if [ "$prereqs_met" = false ]; then
			log_info "Skipping $name - requires: ${missing_prereqs[*]}"
			summary_lines+=("⏭️  $name (skipped - requires: ${missing_prereqs[*]})")
			skipped_count=$((skipped_count + 1))
			continue
		fi

		# Build install command
		local install_cmd="$tool_cmd mcp add --scope user --transport stdio $server_name --"
		install_cmd="$install_cmd $(printf '%q' "$command")"
		for arg in "${args_array[@]}"; do
			install_cmd="$install_cmd $(printf '%q' "$arg")"
		done

		local prompt_msg="Install $name MCP server"
		[ -n "$description" ] && prompt_msg="$prompt_msg ($description)"
		[ -n "$category" ] && prompt_msg="$prompt_msg [category: $category]"

		# Determine install mode
		local mode="skip"
		if [ "$YES_TO_ALL" = true ]; then
			mode="auto"
		elif [ -t 0 ]; then
			if prompt_yn "$prompt_msg"; then
				mode="install"
			else
				log_info "Skipped $name (user declined)"
				summary_lines+=("❌ $name (declined)")
				skipped_count=$((skipped_count + 1))
				continue
			fi
		fi

		if [ "$mode" = "skip" ]; then
			log_info "Skipping $name (non-interactive mode, use --yes to auto-install)"
			summary_lines+=("⏭️  $name (skipped - non-interactive)")
			skipped_count=$((skipped_count + 1))
			continue
		fi

		# Execute installation
		[ "$mode" = "auto" ] && log_info "Auto-installing $name (--yes flag)" || log_info "Installing $name..."

		local err_file
		err_file=$(make_temp_file "${tool_cmd}-mcp-${server_name}" "err")

		if execute "$install_cmd" 2>"$err_file"; then
			log_success "$name installed"
			summary_lines+=("✅ $name")
			installed_count=$((installed_count + 1))
		elif grep -qi "already" "$err_file" 2>/dev/null; then
			log_info "$name already installed"
			summary_lines+=("✅ $name (already installed)")
		else
			log_warning "$name installation failed"
			summary_lines+=("⚠️  $name (failed)")
			failed_count=$((failed_count + 1))
		fi
		rm -f "$err_file"
	done 3< <(jq -r '
		.mcpServers | to_entries[] |
		[
			.key,
			(.value.name // empty),
			(.value.description // empty),
			(.value.command // empty),
			(.value.args | join("")),
			(.value.requires | join("")),
			(.value.category // empty)
		] | @tsv
	' "$registry_file")

	log_info ""
	log_info "MCP Server Installation Summary:"
	log_info "────────────────────────────────"
	for line in "${summary_lines[@]}"; do
		log_info "  $line"
	done
	log_info "────────────────────────────────"
	log_info "Installed: $installed_count | Skipped: $skipped_count | Failed: $failed_count"

	return 0
}

setup_claude_mcp_servers() {
	if ! command -v claude &>/dev/null; then
		return 0
	fi

	log_info "Setting up Claude Code MCP servers (global scope)..."

	# Try registry-based installation first
	if install_mcp_servers_from_registry "claude"; then
		log_success "MCP server setup complete via registry"
	else
		# Fallback to legacy method if registry fails
		log_info "Falling back to legacy MCP installation method..."
		local script_runner
		script_runner=$(_detect_script_runner)
		if [ -z "$script_runner" ]; then
			log_warning "No script runner found (bunx or npx). Skipping legacy MCP installation."
		else
			install_mcp_interactive "context7" "claude mcp add --scope user --transport stdio context7 -- $script_runner -y @upstash/context7-mcp@latest" "documentation lookup"
			install_mcp_interactive "sequential-thinking" "claude mcp add --scope user --transport stdio sequential-thinking -- $script_runner -y @modelcontextprotocol/server-sequential-thinking" "multi-step reasoning"
		fi

		handle_qmd_installation_if_needed
		if command -v qmd &>/dev/null; then
			install_mcp_interactive "qmd" "claude mcp add --scope user --transport stdio qmd -- qmd mcp" "knowledge management"
		else
			log_warning "qmd not found. MCP setup skipped. Install with: bun install -g @tobilu/qmd"
		fi

		handle_fff_mcp_installation_if_needed
		if command -v fff-mcp &>/dev/null; then
			install_mcp_interactive "fff" "claude mcp add --scope user --transport stdio fff -- fff-mcp" "fast file search with memory"
		else
			log_warning "fff-mcp not found. MCP setup skipped. Install with: curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh | bash"
		fi

		handle_sem_installation_if_needed
		if command -v sem-mcp &>/dev/null; then
			install_mcp_interactive "sem" "claude mcp add --scope user --transport stdio sem -- sem-mcp" "semantic version control"
		else
			log_warning "sem-mcp not found. MCP setup skipped. Install with: cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp"
		fi

		handle_logpilot_installation_if_needed
		if command -v logpilot &>/dev/null; then
			install_mcp_interactive "logpilot" "claude mcp add --scope user --transport stdio logpilot -- logpilot mcp-server" "log analysis"
		else
			log_warning "logpilot not found. MCP setup skipped. Install with: cargo install logpilot"
		fi

		log_success "MCP server setup complete (legacy mode)"
	fi
}

setup_commandcode_mcp_servers() {
	if [ ! -d "$HOME/.commandcode" ]; then
		return 0
	fi

	log_info "Setting up Command Code MCP servers..."

	local mcp_file="$SCRIPT_DIR/configs/commandcode/mcp.json"
	if [ ! -f "$mcp_file" ]; then
		log_warning "Command Code MCP config not found: $mcp_file"
		return 1
	fi

	if ! validate_config "$mcp_file"; then
		log_error "Command Code mcp.json failed validation"
		return 1
	fi

	if ! jq -e '.mcpServers | type == "object"' "$mcp_file" >/dev/null 2>&1; then
		log_error "Command Code mcp.json must contain an object field: mcpServers"
		return 1
	fi

	# Ensure optional prerequisites are available
	handle_qmd_installation_if_needed
	handle_fff_mcp_installation_if_needed
	handle_logpilot_installation_if_needed
	handle_sem_installation_if_needed

	local dest_file="$HOME/.commandcode/mcp.json"

	# Merge with existing user config, warn if jq is missing, otherwise copy directly
	if [ -f "$dest_file" ]; then
		if command -v jq &>/dev/null; then
			log_info "Merging with existing Command Code MCP config..."
			local merged_file
			merged_file=$(make_temp_file "commandcode-mcp" "json")
			if jq -s '
				(.[0] // {}) as $existing |
				(.[1] // {}) as $repo |
				($existing * $repo)
				| .mcpServers = (($existing.mcpServers // {}) + ($repo.mcpServers // {}))
			' "$dest_file" "$mcp_file" >"$merged_file"; then
				execute_quoted cp -p "$merged_file" "$dest_file" || return 1
				rm -f "$merged_file"
				log_success "Command Code MCP servers configured (merged)"
			else
				rm -f "$merged_file"
				log_error "Failed to merge Command Code MCP config"
				return 1
			fi
		else
			log_warning "Existing mcp.json found but jq is not installed. Install jq to merge configs, or manually update $dest_file"
			return 1
		fi
	else
		if copy_config_file "$mcp_file" "$HOME/.commandcode/"; then
			log_success "Command Code MCP servers configured"
		else
			log_error "Failed to copy Command Code MCP config"
			return 1
		fi
	fi
}

copy_opencode_configs() {
	local opencode_status
	opencode_status=$(detect_tool --detailed "opencode" "$HOME/.config/opencode") || opencode_status="missing"
	if [ "$opencode_status" = "missing" ]; then
		log_info "OpenCode not detected - skipping OpenCode config installation"
		return 0
	fi

	log_info "Detected OpenCode (via $opencode_status)"
	execute_quoted mkdir -p "$HOME/.config/opencode"
	execute_quoted cp "$SCRIPT_DIR/configs/opencode/opencode.json" "$HOME/.config/opencode/"

	execute_quoted rm -rf "$HOME/.config/opencode/agent"
	safe_copy_dir "$SCRIPT_DIR/configs/opencode/agent" "$HOME/.config/opencode/agent"

	execute_quoted rm -rf "$HOME/.config/opencode/command"
	copy_opencode_commands "$SCRIPT_DIR/configs/opencode/command" "$HOME/.config/opencode/command"

	log_success "OpenCode configs copied"
}

copy_amp_configs() {
	local amp_status
	amp_status=$(detect_tool --detailed "amp" "$HOME/.config/amp") || amp_status="missing"
	if [ "$amp_status" = "missing" ]; then
		log_info "Amp not detected - skipping Amp config installation"
		return 0
	fi

	log_info "Detected Amp (via $amp_status)"
	execute_quoted mkdir -p "$HOME/.config/amp"
	execute_quoted cp "$SCRIPT_DIR/configs/amp/settings.json" "$HOME/.config/amp/"

	if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/amp/AGENTS.md" "$HOME/.config/amp/"
		copy_config_file "$SCRIPT_DIR/configs/amp/AGENTS.md" "$HOME/.config/"
	fi

	log_success "Amp configs copied"
}

copy_ai_launcher_configs() {
	local ai_launcher_status
	ai_launcher_status=$(detect_tool --detailed "ai-launcher" "$HOME/.config/ai-launcher" "$HOME/.config/ai-launcher/config.json") || ai_launcher_status="missing"
	if [ "$ai_launcher_status" = "missing" ]; then
		log_info "ai-launcher not detected - skipping ai-launcher config installation"
		return 0
	fi

	log_info "Detected ai-launcher (via $ai_launcher_status)"
	execute_quoted mkdir -p "$HOME/.config/ai-launcher"
	if copy_config_file "$SCRIPT_DIR/configs/ai-launcher/config.json" "$HOME/.config/ai-launcher"; then
		log_success "ai-launcher configs copied"
	else
		log_info "ai-launcher config not found in source, preserving existing"
	fi
}

copy_codex_configs() {
	local codex_status
	codex_status=$(detect_tool --detailed "codex" "$HOME/.codex") || codex_status="missing"
	if [ "$codex_status" = "missing" ]; then
		log_info "Codex CLI not detected - skipping Codex config installation"
		return 0
	fi

	log_info "Detected Codex CLI (via $codex_status)"
	execute_quoted mkdir -p "$HOME/.codex"

	copy_config_file "$SCRIPT_DIR/configs/codex/AGENTS.md" "$HOME/.codex/" || true
	copy_config_file "$SCRIPT_DIR/configs/codex/config.json" "$HOME/.codex/" || true

	copy_config_file "$SCRIPT_DIR/configs/codex/config.toml" "$HOME/.codex/" || true

	if [ -d "$SCRIPT_DIR/configs/codex/themes" ]; then
		execute_quoted mkdir -p "$HOME/.codex/themes"
		safe_copy_dir "$SCRIPT_DIR/configs/codex/themes" "$HOME/.codex/themes"
	fi

	log_success "Codex CLI configs copied"
}

copy_gemini_configs() {
	local gemini_status
	gemini_status=$(detect_tool --detailed "gemini" "$HOME/.gemini") || gemini_status="missing"
	if [ "$gemini_status" = "missing" ]; then
		log_info "Gemini CLI not detected - skipping Gemini config installation"
		return 0
	fi

	log_info "Detected Gemini CLI (via $gemini_status)"
	log_warning "⚠️  Gemini CLI deprecation: Google One / unpaid tiers stop working June 18, 2026"
	log_warning "    Migrate to Antigravity CLI: https://antigravity.google/product/antigravity-cli"
	log_warning "    Migration guide: https://goo.gle/gemini-cli-migration"
	log_info "Copying Gemini configs (retained for API-key users and migration compatibility)..."
	execute_quoted mkdir -p "$HOME/.gemini"

	copy_config_file "$SCRIPT_DIR/configs/gemini/AGENTS.md" "$HOME/.gemini/" || true
	copy_config_file "$SCRIPT_DIR/configs/gemini/GEMINI.md" "$HOME/.gemini/" || true
	copy_config_file "$SCRIPT_DIR/configs/gemini/settings.json" "$HOME/.gemini/" || true

	execute_quoted rm -rf "$HOME/.gemini/agents"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/agents" "$HOME/.gemini/agents"

	execute_quoted rm -rf "$HOME/.gemini/commands"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/commands" "$HOME/.gemini/commands"

	execute_quoted rm -rf "$HOME/.gemini/policies"
	execute_quoted mkdir -p "$HOME/.gemini/policies"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/policies" "$HOME/.gemini/policies"

	log_success "Gemini CLI configs copied"
}

copy_antigravity_configs() {
	local antigravity_home="$HOME/.gemini/antigravity-cli"
	local antigravity_status="missing"

	if command -v agy &>/dev/null; then
		antigravity_status="command"
	elif [ -d "$antigravity_home" ]; then
		antigravity_status="config-dir"
	elif [ -d "$HOME/.gemini" ] || command -v gemini &>/dev/null; then
		antigravity_status="gemini-migration"
	fi

	if [ "$antigravity_status" = "missing" ]; then
		log_info "Antigravity CLI not detected - skipping Antigravity config installation"
		return 0
	fi

	log_info "Detected Antigravity CLI setup path (via $antigravity_status)"
	execute_quoted mkdir -p "$antigravity_home"

	copy_config_file "$SCRIPT_DIR/configs/antigravity-cli/settings.json" "$antigravity_home/" || true
	copy_config_file "$SCRIPT_DIR/configs/antigravity-cli/keybindings.json" "$antigravity_home/" || true
	copy_config_file "$SCRIPT_DIR/configs/antigravity-cli/statusline.sh" "$antigravity_home/" || true
	execute_quoted chmod +x "$antigravity_home/statusline.sh"
	configure_antigravity_statusline "$antigravity_home"

	if [ -d "$SCRIPT_DIR/configs/antigravity-cli/plugins" ]; then
		execute_quoted mkdir -p "$antigravity_home/plugins"
		for plugin_dir in "$SCRIPT_DIR/configs/antigravity-cli/plugins"/*; do
			[ -d "$plugin_dir" ] || continue
			local plugin_name
			plugin_name="$(basename "$plugin_dir")"
			safe_copy_dir "$plugin_dir" "$antigravity_home/plugins/$plugin_name"
		done
	fi

	migrate_gemini_plugins_to_antigravity "$antigravity_home"
	normalize_antigravity_mcp_configs "$antigravity_home"

	log_success "Antigravity CLI configs copied"
}

configure_antigravity_statusline() {
	local antigravity_home="$1"
	local settings_file="$antigravity_home/settings.json"

	if ! command -v jq &>/dev/null; then
		log_warning "jq not found - skipping Antigravity status line setup"
		return 0
	fi

	if [ ! -f "$settings_file" ]; then
		execute_quoted mkdir -p "$antigravity_home"
		if [ "$DRY_RUN" = true ]; then
			log_info "[DRY RUN] Would create $settings_file"
		else
			printf '{}\n' >"$settings_file"
		fi
	fi

	local updated_file
	updated_file=$(make_temp_file "antigravity-settings" "json")
	if jq '.statusLine = {"type": "command", "command": "bash ~/.gemini/antigravity-cli/statusline.sh", "enabled": true}' "$settings_file" >"$updated_file"; then
		execute_quoted cp -p "$updated_file" "$settings_file"
		log_success "Antigravity status line configured"
	else
		log_warning "Failed to configure Antigravity status line"
	fi
	rm -f "$updated_file"
}

# Standalone Gemini CLI → Antigravity CLI migration
# Triggered by --migrate-gemini flag. Installs Antigravity, ensures jq,
# imports Gemini extensions, and copies Antigravity configs — all in one step.
migrate_gemini_to_antigravity() {
	echo "╔══════════════════════════════════════════════════════════════╗"
	echo "║        Gemini CLI → Antigravity CLI Migration                ║"
	echo "╚══════════════════════════════════════════════════════════════╝"
	echo

	log_info "Gemini CLI deprecation: Google One / unpaid tiers stop working June 18, 2026"
	log_info "Migration guide: https://goo.gle/gemini-cli-migration"
	echo

	# Step 1: Install Antigravity CLI (delegates to existing installer)
	log_info "Step 1/3: Installing Antigravity CLI..."
	install_antigravity
	echo

	# Step 2: Ensure jq is available (needed for config normalization)
	log_info "Step 2/3: Ensuring jq is installed..."
	install_jq_if_needed
	echo

	# Step 3: Copy Antigravity configs (includes Gemini extension import)
	log_info "Step 3/3: Copying Antigravity CLI configs and importing Gemini extensions..."
	copy_antigravity_configs
	echo

	log_success "Migration complete!"
	echo
	echo "Next steps:"
	echo "  1. Run 'agy' to start Antigravity CLI"
	echo "  2. Check imported plugins: /plugins  (inside agy)"
	echo "  3. Review settings: cat ~/.gemini/antigravity-cli/settings.json"
	echo "  4. Migration guide: https://goo.gle/gemini-cli-migration"
	echo
	echo "Your Gemini CLI configs at ~/.gemini/ are preserved for API-key workflows."
}

migrate_gemini_plugins_to_antigravity() {
	local antigravity_home="$1"

	if ! command -v agy &>/dev/null; then
		log_info "agy not found - skipping Gemini extension import"
		return 0
	fi

	if [ ! -d "$HOME/.gemini" ]; then
		return 0
	fi

	if [ -f "$antigravity_home/import_manifest.json" ]; then
		log_info "Antigravity Gemini import manifest already exists - skipping extension import"
		return 0
	fi

	log_info "Importing Gemini CLI extensions into Antigravity plugins..."
	if execute "agy plugin import gemini"; then
		log_success "Gemini CLI extensions imported into Antigravity plugins"
	else
		log_warning "Gemini extension import failed; source-controlled Antigravity plugin was still installed"
	fi
}

normalize_antigravity_mcp_configs() {
	local antigravity_home="$1"

	if ! command -v jq &>/dev/null; then
		log_warning "jq not found - skipping Antigravity MCP config normalization"
		return 0
	fi

	local config_files=()
	[ -f "$antigravity_home/mcp_config.json" ] && config_files+=("$antigravity_home/mcp_config.json")
	if [ -d "$antigravity_home/plugins" ]; then
		# POSIX: use temp file instead of process substitution
		local _mcp_list
		_mcp_list=$(make_temp_file "antigravity-mcp" "list")
		find "$antigravity_home/plugins" -mindepth 2 -maxdepth 2 -name mcp_config.json -type f 2>/dev/null > "$_mcp_list"
	while IFS= read -r config_file; do
		config_files+=("$config_file")
	done < "$_mcp_list"
	rm -f "$_mcp_list"
	fi

	for config_file in "${config_files[@]}"; do
		local normalized_file
		normalized_file=$(make_temp_file "antigravity-mcp" "json")
		if jq '
			.mcpServers = (
				(.mcpServers // {})
				| if type == "object" then
					with_entries(
						if ((.value | type) == "object" and .value.url? != null and .value.serverUrl? == null) then
							.value.serverUrl = .value.url | del(.value.url)
						else
							.
						end
					)
				else
					{}
				end
			)
		' "$config_file" >"$normalized_file"; then
			execute_quoted cp -p "$normalized_file" "$config_file"
		else
			log_warning "Failed to normalize Antigravity MCP config: $config_file"
		fi
		rm -f "$normalized_file"
	done
}

copy_kilo_configs() {
	local kilo_status
	kilo_status=$(detect_tool --detailed "kilo" "$HOME/.config/kilo") || kilo_status="missing"
	if [ "$kilo_status" = "missing" ]; then
		log_info "Kilo CLI not detected - skipping Kilo config installation"
		return 0
	fi

	log_info "Detected Kilo CLI (via $kilo_status)"
	execute_quoted mkdir -p "$HOME/.config/kilo"
	copy_config_file "$SCRIPT_DIR/configs/kilo/config.json" "$HOME/.config/kilo/" || true
	copy_config_file "$SCRIPT_DIR/configs/kilo/AGENTS.md" "$HOME/.config/kilo/" || true
	log_success "Kilo CLI configs copied"
}

copy_pi_configs() {
	local pi_status
	pi_status=$(detect_tool --detailed "pi" "$HOME/.pi") || pi_status="missing"
	if [ "$pi_status" = "missing" ]; then
		log_info "Pi not detected - skipping Pi config installation"
		return 0
	fi

	log_info "Detected Pi (via $pi_status)"
	execute_quoted mkdir -p "$HOME/.pi/agent"

	if [ ! -f "$HOME/.pi/agent/settings.json" ]; then
		copy_config_file "$SCRIPT_DIR/configs/pi/settings.json" "$HOME/.pi/agent/" || true
	else
		log_info "Pi settings.json already exists at ~/.pi/agent/, preserving existing config"
	fi

	if [ -d "$SCRIPT_DIR/configs/pi/themes" ]; then
		execute_quoted mkdir -p "$HOME/.pi/agent/themes"
		safe_copy_dir "$SCRIPT_DIR/configs/pi/themes" "$HOME/.pi/agent/themes"
	fi

	copy_config_file "$SCRIPT_DIR/configs/pi/AGENTS.md" "$HOME/.pi/agent/" || true

	copy_config_file "$SCRIPT_DIR/configs/pi/mcp.json" "$HOME/.pi/agent/" || true

	copy_config_file "$SCRIPT_DIR/configs/pi/models.json" "$HOME/.pi/agent/" || true

	log_success "Pi configs copied"
}

copy_commandcode_configs() {
	local cmd_status
	if is_commandcode_installed; then
		cmd_status="cli"
	elif [ -d "$HOME/.commandcode" ]; then
		cmd_status="config-dir"
	else
		cmd_status="missing"
	fi
	if [ "$cmd_status" = "missing" ]; then
		log_info "Command Code not detected - skipping Command Code config installation"
		return 0
	fi

	log_info "Detected Command Code (via $cmd_status)"
	execute_quoted mkdir -p "$HOME/.commandcode"

	copy_config_file "$SCRIPT_DIR/configs/commandcode/settings.json" "$HOME/.commandcode/" || true
	copy_config_file "$SCRIPT_DIR/configs/commandcode/AGENTS.md" "$HOME/.commandcode/" || true

	if [ -d "$SCRIPT_DIR/configs/commandcode/agents" ]; then
		execute_quoted mkdir -p "$HOME/.commandcode/agents"
		safe_copy_dir "$SCRIPT_DIR/configs/commandcode/agents" "$HOME/.commandcode/agents"
	fi

	if [ -d "$SCRIPT_DIR/configs/commandcode/commands" ]; then
		execute_quoted mkdir -p "$HOME/.commandcode/commands"
		safe_copy_dir "$SCRIPT_DIR/configs/commandcode/commands" "$HOME/.commandcode/commands"
	fi

	if [ -d "$SCRIPT_DIR/configs/commandcode/skills" ]; then
		execute_quoted mkdir -p "$HOME/.commandcode/skills"
		safe_copy_dir "$SCRIPT_DIR/configs/commandcode/skills" "$HOME/.commandcode/skills"
	fi

	if [ -d "$SCRIPT_DIR/configs/commandcode/hooks" ]; then
		execute_quoted mkdir -p "$HOME/.commandcode/hooks"
		safe_copy_dir "$SCRIPT_DIR/configs/commandcode/hooks" "$HOME/.commandcode/hooks"
	fi

	# Copy MCP servers config
	if ! setup_commandcode_mcp_servers; then
		log_warning "Command Code MCP setup failed; continuing with other configs"
	fi

	log_success "Command Code configs copied"
}

copy_copilot_configs() {
	if [ ! -f "$SCRIPT_DIR/configs/copilot/AGENTS.md" ] && [ ! -f "$SCRIPT_DIR/configs/copilot/mcp-config.json" ]; then
		return 0
	fi

	execute_quoted mkdir -p "$HOME/.copilot"

	if [ -f "$SCRIPT_DIR/configs/copilot/AGENTS.md" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/copilot/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"
		log_success "GitHub Copilot CLI configs copied"
	fi

	if [ -f "$SCRIPT_DIR/configs/copilot/mcp-config.json" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/copilot/mcp-config.json" "$HOME/.copilot/mcp-config.json"
		log_success "GitHub Copilot MCP config copied"
	fi
}

copy_cursor_configs() {
	local cursor_status
	cursor_status=$(detect_tool --detailed "agent" "$HOME/.cursor") || cursor_status="missing"
	if [ "$cursor_status" = "missing" ]; then
		log_info "Cursor not detected - skipping Cursor config installation"
		return 0
	fi

	log_info "Detected Cursor (via $cursor_status)"

	if [ -f "$SCRIPT_DIR/configs/cursor/AGENTS.md" ]; then
		execute_quoted mkdir -p "$HOME/.cursor/rules"
		execute_quoted cp "$SCRIPT_DIR/configs/cursor/AGENTS.md" "$HOME/.cursor/rules/general.mdc"
		log_success "Cursor Agent CLI configs copied"
	fi

	if [ -f "$SCRIPT_DIR/configs/cursor/mcp.json" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/cursor/mcp.json" "$HOME/.cursor/mcp.json"
		log_success "Cursor MCP config copied"
	fi

	if [ -d "$SCRIPT_DIR/configs/cursor/agents" ]; then
		execute_quoted rm -rf "$HOME/.cursor/agents"
		safe_copy_dir "$SCRIPT_DIR/configs/cursor/agents" "$HOME/.cursor/agents"
	fi

	execute_quoted rm -rf "$HOME/.cursor/commands"
	safe_copy_dir "$SCRIPT_DIR/configs/cursor/commands" "$HOME/.cursor/commands"

	log_success "Cursor configs copied"
}

copy_factory_configs() {
	local factory_status
	factory_status=$(detect_tool --detailed "droid" "$HOME/.factory") || factory_status="missing"
	if [ "$factory_status" = "missing" ]; then
		log_info "Factory Droid not detected - skipping Factory Droid config installation"
		return 0
	fi

	log_info "Detected Factory Droid (via $factory_status)"
	execute_quoted mkdir -p "$HOME/.factory/droids"

	copy_config_file "$SCRIPT_DIR/configs/factory/AGENTS.md" "$HOME/.factory/" || true
	copy_config_file "$SCRIPT_DIR/configs/factory/mcp.json" "$HOME/.factory/" || true
	copy_config_file "$SCRIPT_DIR/configs/factory/settings.json" "$HOME/.factory/" || true

	copy_config_file "$SCRIPT_DIR/configs/factory/config.json" "$HOME/.factory/" || true

	if [ -d "$SCRIPT_DIR/configs/factory/droids" ] && [ -n "$(ls -A "$SCRIPT_DIR/configs/factory/droids" 2>/dev/null)" ]; then
		safe_copy_dir "$SCRIPT_DIR/configs/factory/droids" "$HOME/.factory/droids"
	fi

	log_success "Factory Droid configs copied"
}

copy_orca_configs() {
	local orca_home="$HOME/Library/Application Support/orca"
	local source_hooks="$SCRIPT_DIR/configs/orca/agent-hooks"

	if [ ! -d "$source_hooks" ]; then
		return 0
	fi

	if [ ! -d "$orca_home" ]; then
		log_info "Orca config directory not found - skipping Orca hook installation"
		return 0
	fi

	log_info "Detected Orca config directory"
	execute_quoted mkdir -p "$orca_home/agent-hooks"
	safe_copy_dir "$source_hooks" "$orca_home/agent-hooks"
	for hook_file in "$orca_home/agent-hooks"/*.sh; do
		[ -f "$hook_file" ] || continue
		execute_quoted chmod +x "$hook_file"
	done

	log_success "Orca agent hooks copied"
}

copy_cline_configs() {
	local cline_status
	cline_status=$(detect_tool --detailed "cline" "$HOME/.cline") || cline_status="missing"
	if [ "$cline_status" = "missing" ]; then
		log_info "Cline not detected - skipping Cline config installation"
		return 0
	fi

	log_info "Detected Cline (via $cline_status)"
	execute_quoted mkdir -p "$HOME/.cline/data/settings"
	execute_quoted mkdir -p "$HOME/.cline/kanban"

	if [ -f "$SCRIPT_DIR/configs/cline/mcp-settings.json" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/cline/mcp-settings.json" "$HOME/.cline/data/settings/cline_mcp_settings.json"
		log_success "Cline MCP settings copied"
	fi

	copy_config_file "$SCRIPT_DIR/configs/cline/models.json" "$HOME/.cline/data/settings" || true
	copy_config_file "$SCRIPT_DIR/configs/cline/providers.json" "$HOME/.cline/data/settings" || true

	# Copy kanban file back as config.json (Cline expects this filename)
	if [ -f "$SCRIPT_DIR/configs/cline/kanban-config.json" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/cline/kanban-config.json" "$HOME/.cline/kanban/config.json"
		log_success "Cline kanban config copied"
	fi

	# Copy Cline-specific skills directly to ~/.cline/skills
	if [ -d "$SCRIPT_DIR/configs/cline/skills" ]; then
		execute_quoted mkdir -p "$HOME/.cline/skills"
		for skill_dir in "$SCRIPT_DIR/configs/cline/skills"/*; do
			if [ -d "$skill_dir" ]; then
				local skill_name
				skill_name=$(basename "$skill_dir")
				safe_copy_dir "$skill_dir" "$HOME/.cline/skills/$skill_name"
			fi
		done
		log_success "Cline-specific skills copied"
	fi

	log_success "Cline configs copied"
}

copy_best_practices() {
	execute_quoted mkdir -p "$HOME/.ai-tools"
	execute_quoted cp "$SCRIPT_DIR/configs/best-practices.md" "$HOME/.ai-tools/"
	log_success "Best practices copied to ~/.ai-tools/"
	execute_quoted cp "$SCRIPT_DIR/configs/git-guidelines.md" "$HOME/.ai-tools/"
	log_success "Git guidelines copied to ~/.ai-tools/"
	execute_quoted cp "$SCRIPT_DIR/configs/agent-memory-guidelines.md" "$HOME/.ai-tools/agent-memory.md"
	log_success "Agent memory guidelines copied to ~/.ai-tools/"

	if [ -f "$SCRIPT_DIR/MEMORY.md" ]; then
		execute_quoted cp "$SCRIPT_DIR/MEMORY.md" "$HOME/.ai-tools/"
		log_success "MEMORY.md copied to ~/.ai-tools/"
	fi
}

# Check if Claude CLI supports plugin marketplace functionality
check_marketplace_support() {
	if ! command -v claude &>/dev/null; then
		log_error "Claude Code CLI not found"
		return 1
	fi

	if ! claude plugin --help &>/dev/null; then
		log_warning "Claude CLI does not support plugin commands"
		return 1
	fi

	if ! claude plugin list &>/dev/null; then
		log_warning "Unable to list plugins. Plugin marketplace may not be available"
		return 1
	fi

	return 0
}

# Attempt to add marketplace repository and verify accessibility
try_add_marketplace_repo() {
	local marketplace_repo="$1"

	# Extract owner/repo format
	local owner_repo=""
	if [[ "$marketplace_repo" == *"/"* ]] && [[ "$marketplace_repo" != /* ]]; then
		owner_repo="$marketplace_repo"
	else
		return 0
	fi

	if claude plugin marketplace add "$owner_repo" 2>/dev/null; then
		return 0
	else
		log_warning "Marketplace repository '$owner_repo' may not be accessible"
		return 1
	fi
}

# Helper: Install remote skills using bunx/npx skills add
install_remote_skills() {
	log_info "Installing community skills from jellydn/my-ai-tools repository..."

	local script_runner
	script_runner=$(_detect_script_runner)

	if [ -z "$script_runner" ]; then
		log_error "No script runner found (bunx or npx). Please install Bun or Node.js to use remote skill installation."
		install_local_skills
		return 0
	fi

	log_info "Using script runner: $script_runner"

	if [ "${YES_TO_ALL:-false}" = "true" ] || [ ! -t 0 ]; then
		execute "$script_runner skills add jellydn/my-ai-tools --yes --global --agent claude-code"
	else
		execute "$script_runner skills add jellydn/my-ai-tools --global --agent claude-code"
	fi
	log_success "Remote skills installed successfully"
}

# Helper: Install recommended community skills from recommend-skills.json
install_recommended_skills() {
	log_info "Checking for recommended community skills..."

	local script_runner
	script_runner=$(_detect_script_runner)

	if [ -z "$script_runner" ]; then
		log_warning "No script runner found (bunx or npx), skipping recommended skills"
		return 0
	fi

	if [ ! -f "$SCRIPT_DIR/configs/recommend-skills.json" ]; then
		log_info "No recommended skills config found, skipping"
		return 0
	fi

	# Extract all skills in a single jq call for efficiency
	local skill_count=0
	local skills_data
	skills_data=$(jq -r '.recommended_skills[] | [.repo, .description, .skill // ""] | @tsv' "$SCRIPT_DIR/configs/recommend-skills.json" 2>/dev/null)

	if [ -z "$skills_data" ]; then
		log_info "No recommended skills found in config"
		return 0
	fi

	skill_count=$(jq '.recommended_skills | length' "$SCRIPT_DIR/configs/recommend-skills.json")
	log_info "Found $skill_count recommended skill(s)"

	# In interactive mode: prompt for all skills.
	# In -y mode: limit to top 3 to avoid installing too much by default.
	local max_installs="$skill_count"
	[ "$YES_TO_ALL" = true ] && max_installs=3

	local install_count=0
	# Use FD 3 to feed the loop so stdin stays attached to the terminal.
	# Otherwise interactive prompts inside the loop (prompt_yn, `skills add`
	# selection menu) would read from the heredoc instead of the user.
	while IFS=$'\t' read -r repo description skill <&3; do
		if [ "$install_count" -ge "$max_installs" ]; then
			[ "$YES_TO_ALL" = true ] && log_info "Reached maximum recommended skills for -y mode ($max_installs), skipping remaining"
			break
		fi

		local skill_suffix=""
		[ -n "$skill" ] && skill_suffix="/$skill"

		log_info "  - $repo${skill_suffix}: $description"
		install_single_recommended_skill "$repo" "$skill" "$skill_suffix"
		install_count=$((install_count + 1))
	done 3<<<"$skills_data"

	log_success "Recommended skills check complete"
}

install_single_recommended_skill() {
	local repo="$1"
	local skill="$2"
	local skill_suffix="$3"

	local script_runner
	script_runner=$(_detect_script_runner)

	if [ -z "$script_runner" ]; then
		log_warning "No script runner available for installing $repo${skill_suffix}"
		return 1
	fi

	if [ "$YES_TO_ALL" = true ] || [ ! -t 0 ]; then
		if [ -n "$skill" ]; then
			execute "$script_runner skills add '$repo' --skill '$skill' --yes --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo${skill_suffix}" || log_info "Skipped: $repo${skill_suffix}"
		else
			execute "$script_runner skills add '$repo' --yes --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo" || log_info "Skipped: $repo"
		fi
	elif [ -t 0 ]; then
		if prompt_yn "Install $repo${skill_suffix}"; then
			if [ -n "$skill" ]; then
				execute "$script_runner skills add '$repo' --skill '$skill' --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo${skill_suffix}" || log_warning "Failed to install: $repo${skill_suffix}"
			else
				execute "$script_runner skills add '$repo' --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo" || log_warning "Failed to install: $repo"
			fi
		else
			log_info "Skipped: $repo${skill_suffix}"
		fi
	fi
}

# Helper: Check if a skill is in the remote/universal skills list
is_remote_skill() {
	case "$1" in
	plannotator-setup-goal | prd | ralph | qmd-knowledge | codemap | adr | handoffs | pickup | pr-review | slop | tdd | commit-atomic | draft-pull-request)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

# Helper: Install CLI dependency for community plugins
install_cli_dependency() {
	local name="$1"

	case "$name" in
	plannotator | plannotator-copilot)
		if command -v plannotator &>/dev/null; then
			return 0
		fi
		log_info "Installing Plannotator CLI..."
		local plannotator_checksum
		plannotator_checksum=$(resolve_installer_checksum "plannotator")
		execute_installer "https://plannotator.ai/install.sh" "$plannotator_checksum" "Plannotator CLI" || log_warning "Plannotator installation failed"
		;;
	qmd-knowledge)
		handle_qmd_installation_if_needed
		;;
	worktrunk)
		if command -v wt &>/dev/null || ! command -v brew &>/dev/null; then
			return 0
		fi
		log_info "Installing Worktrunk CLI via Homebrew..."
		if execute "brew install worktrunk"; then
			execute "wt config shell install" || log_warning "Worktrunk shell config failed"
		else
			log_warning "Worktrunk installation failed"
		fi
		;;
	esac
}

enable_plugins() {
	log_info "Installing Claude Code plugins..."

	MARKETPLACE_AVAILABLE=false
	if check_marketplace_support; then
		MARKETPLACE_AVAILABLE=true
	else
		log_warning "Claude plugin marketplace is not available"
		log_info "Note: Skills can still be installed remotely using bunx/npx skills add command"
	fi

	# Determine skill installation source
	determine_skill_install_source

	# Define plugins
	official_plugins=(
		"typescript-lsp@claude-plugins-official"
		"pyright-lsp@claude-plugins-official"
		"context7@claude-plugins-official"
		"frontend-design@claude-plugins-official"
		"learning-output-style@claude-plugins-official"
		"swift-lsp@claude-plugins-official"
		"lua-lsp@claude-plugins-official"
		"code-simplifier@claude-plugins-official"
		"rust-analyzer-lsp@claude-plugins-official"
		"claude-md-management@claude-plugins-official"
	)

	# Community plugins: "name|plugin_spec|marketplace_repo|cli_tool"
	community_plugins=(
		"plannotator|plannotator@plannotator|backnotprop/plannotator|claude"
		"plannotator-copilot|plannotator-copilot@plannotator|backnotprop/plannotator|copilot"
		"plannotator-setup-goal|plannotator-setup-goal@my-ai-tools|$SCRIPT_DIR|claude"
		"prd|prd@my-ai-tools|$SCRIPT_DIR|claude"
		"ralph|ralph@my-ai-tools|$SCRIPT_DIR|claude"
		"qmd-knowledge|qmd-knowledge@my-ai-tools|$SCRIPT_DIR|claude"
		"codemap|codemap@my-ai-tools|$SCRIPT_DIR|claude"
		"commit-atomic|commit-atomic@my-ai-tools|$SCRIPT_DIR|claude"
		"draft-pull-request|draft-pull-request@my-ai-tools|$SCRIPT_DIR|claude"
		"claude-hud|claude-hud@claude-hud|jarrodwatts/claude-hud|claude"
		"worktrunk|worktrunk@worktrunk|max-sixty/worktrunk|claude"
		"openai-codex|codex@openai-codex|openai/codex-plugin-cc|claude"
	)

	if ! command -v claude &>/dev/null; then
		handle_no_claude_cli
		return 0
	fi

	install_plugins_if_marketplace_available

	install_recommended_skills
}

determine_skill_install_source() {
	if [ "${YES_TO_ALL:-false}" = "true" ]; then
		SKILL_INSTALL_SOURCE="local"
	elif [ -t 0 ]; then
		log_info "How would you like to install community skills?"
		printf "1) Local (from skills folder) 2) Remote (from jellydn/my-ai-tools using bunx/npx skills) [1/2]: "
		read -r REPLY
		echo
		case "$REPLY" in
		2) SKILL_INSTALL_SOURCE="remote" ;;
		*) SKILL_INSTALL_SOURCE="local" ;;
		esac
	else
		SKILL_INSTALL_SOURCE="local"
	fi
}

handle_no_claude_cli() {
	log_warning "Claude Code not installed - skipping official marketplace plugin installation"
	log_info "Note: Community skills can still be installed without Claude CLI"

	if [ "$SKILL_INSTALL_SOURCE" = "local" ]; then
		install_local_skills
	else
		install_remote_skills
	fi
	log_success "Community skills installation complete"
	install_recommended_skills
}

install_plugins_if_marketplace_available() {
	if [ "${MARKETPLACE_AVAILABLE:-false}" = "false" ]; then
		log_info "Skipping official marketplace plugins (claude plugin command unavailable)"
	else
		install_official_plugins
	fi

	install_community_skills

	log_success "Claude Code plugins/skills installation complete"
	log_info "IMPORTANT: Restart Claude Code for plugins to take effect"
}

install_official_plugins() {
	log_info "Adding official plugins marketplace..."
	if ! execute "claude plugin marketplace add 'anthropics/claude-plugins-official' 2>/dev/null"; then
		log_info "Official plugins marketplace may already be added"
	fi

	if ! try_add_marketplace_repo "anthropics/claude-plugins-official"; then
		log_warning "Official plugins marketplace may not be accessible"
		MARKETPLACE_AVAILABLE=false
		return 0
	fi

	if [ "${MARKETPLACE_AVAILABLE:-false}" = "false" ]; then
		return 0
	fi

	log_info "Installing official plugins..."
	if [ -t 0 ]; then
		for plugin in "${official_plugins[@]}"; do
			install_plugin "$plugin"
		done
	else
		install_official_plugins_parallel
	fi
}

install_official_plugins_parallel() {
	log_info "Installing plugins in parallel..."
	if [ "$DRY_RUN" = true ]; then
		for plugin in "${official_plugins[@]}"; do
			log_info "[DRY RUN] Would install $plugin"
		done
		return 0
	fi
	local pids=()

	for plugin in "${official_plugins[@]}"; do
		(
			setup_tmpdir
			if execute "claude plugin install '$plugin' 2>/dev/null"; then
				log_success "$plugin installed"
			else
				log_warning "$plugin may already be installed"
			fi
		) &
		pids+=($!)
	done

	for pid in "${pids[@]}"; do
		wait "$pid" 2>/dev/null || true
	done
	log_success "Official plugins installation complete"
}

install_plugin() {
	local plugin="$1"

	if [ "$YES_TO_ALL" = true ]; then
		setup_tmpdir
		execute "claude plugin install '$plugin' 2>/dev/null" || log_warning "$plugin install failed (may already be installed)"
	elif [ -t 0 ]; then
		if prompt_yn "Install $plugin"; then
			setup_tmpdir
			execute "claude plugin install '$plugin' && log_success '$plugin installed' || log_warning '$plugin install failed (may already be installed)'"
		fi
	else
		setup_tmpdir
		execute "claude plugin install '$plugin' 2>/dev/null" || log_warning "$plugin install failed (may already be installed)"
	fi
}

install_community_skills() {
	if [ "$SKILL_INSTALL_SOURCE" = "local" ]; then
		log_info "Installing community skills from local skills folder..."
		install_local_skills
		install_local_community_plugins
	else
		install_remote_skills
		install_local_community_plugins
	fi
}

install_local_community_plugins() {
	# Only install CLI-based plugins (non-remote skills) if Claude CLI is available
	if ! command -v claude &>/dev/null; then
		return 0
	fi

	for plugin_entry in "${community_plugins[@]}"; do
		local name plugin_spec marketplace_repo cli_tool
		name="${plugin_entry%%|*}"

		# Skip remote skills - they're installed from local skills folder or bunx/npx
		is_remote_skill "$name" && continue

		local rest="${plugin_entry#*|}"
		plugin_spec="${rest%%|*}"
		local rest2="${rest#*|}"
		marketplace_repo="${rest2%%|*}"
		cli_tool="${rest2##*|}"

		install_community_plugin "$name" "$plugin_spec" "$marketplace_repo" "$cli_tool"
	done
}

install_community_plugin() {
	local name="$1"
	local plugin_spec="$2"
	local marketplace_repo="$3"
	local cli_tool="${4:-claude}"

	if [ "$YES_TO_ALL" = true ] || [ ! -t 0 ]; then
		install_community_plugin_non_interactive "$name" "$plugin_spec" "$marketplace_repo" "$cli_tool"
	elif [ -t 0 ]; then
		install_community_plugin_interactive "$name" "$plugin_spec" "$marketplace_repo" "$cli_tool"
	fi
}

install_community_plugin_non_interactive() {
	local name="$1"
	local plugin_spec="$2"
	local marketplace_repo="$3"
	local cli_tool="$4"

	install_cli_dependency "$name"

	setup_tmpdir
	execute "$cli_tool plugin marketplace add '$marketplace_repo' 2>/dev/null || true"
	cleanup_plugin_cache "$cli_tool" "$name"
	if ! execute "$cli_tool plugin install '$plugin_spec' 2>/dev/null"; then
		log_warning "$name plugin install failed (may already be installed)"
	fi
}

install_community_plugin_interactive() {
	local name="$1"
	local plugin_spec="$2"
	local marketplace_repo="$3"
	local cli_tool="$4"

	if ! prompt_yn "Install $name"; then
		return 0
	fi

	install_cli_dependency "$name"

	setup_tmpdir
	if ! execute "$cli_tool plugin marketplace add '$marketplace_repo' 2>/dev/null"; then
		log_info "Marketplace $marketplace_repo may already be added"
	fi
	cleanup_plugin_cache "$cli_tool" "$name"
	if execute "$cli_tool plugin install '$plugin_spec' 2>/dev/null"; then
		log_success "$name installed"
	else
		log_warning "$name install failed (may already be installed)"
	fi
}

install_local_skills() {
	if [ ! -d "$SCRIPT_DIR/skills" ]; then
		log_info "skills folder not found, skipping local skills"
		return 0
	fi

	log_info "Installing skills to universal directory..."

	# Universal skills directory - used by all modern AI tools
	local UNIVERSAL_SKILLS_DIR="$HOME/.agents/skills"

	# Prepare and clean up managed skills
	prepare_universal_skills_dir "$UNIVERSAL_SKILLS_DIR"

	# Copy all skills to universal directory
	for skill_dir in "$SCRIPT_DIR/skills"/*; do
		if [ ! -d "$skill_dir" ]; then
			continue
		fi

		local skill_name
		skill_name=$(basename "$skill_dir")

		copy_skill_to_universal "$skill_name" "$skill_dir" "$UNIVERSAL_SKILLS_DIR"
	done

	log_success "Skills installed to universal directory: $UNIVERSAL_SKILLS_DIR"
	log_info "This directory is automatically used by: Claude, OpenCode, Amp, Codex, Gemini, Antigravity, Cursor, Pi, Command Code, Grok, MiMo-Code, and more"

	# Create symlinks from tool-specific directories to universal directory
	create_tool_skills_symlinks "$UNIVERSAL_SKILLS_DIR"
}

# Create symlinks from tool-specific skills directories to universal directory
create_tool_skills_symlinks() {
	local universal_dir="$1"

	# Define tool-specific skills directories that should symlink to universal
	local tool_dirs=(
		"$HOME/.claude/skills"
		"$HOME/.config/opencode/skills"
		"$HOME/.gemini/skills"
		"$HOME/.pi/skills"
		"$HOME/.cursor/skills"
		"$HOME/.config/amp/skills"
		"$HOME/.codex/skills"
		"$HOME/.commandcode/skills"
		"$HOME/.config/mimocode/skills"
	)

	for tool_dir in "${tool_dirs[@]}"; do
		# Skip if the parent directory doesn't exist (tool not installed)
		local parent_dir
		parent_dir=$(dirname "$tool_dir")
		if [ ! -d "$parent_dir" ]; then
			continue
		fi

		# Create parent directory if needed
		execute_quoted mkdir -p "$parent_dir"

		# Remove existing directory/symlink if it exists
		if [ -e "$tool_dir" ] || [ -L "$tool_dir" ]; then
			# Check if it's already correctly symlinked (handle trailing slash variations)
			if [ -L "$tool_dir" ]; then
				local link_target
				link_target=$(readlink "$tool_dir")
				# Normalize paths: remove trailing slashes for comparison
				local normalized_target="${link_target%/}"
				local normalized_universal="${universal_dir%/}"
				if [ "$normalized_target" = "$normalized_universal" ]; then
					continue
				fi
			fi
			# Back up existing non-symlink directory to central backup location
			# (outside tool config to avoid skill conflicts from duplicate scanning)
			if [ -d "$tool_dir" ] && [ ! -L "$tool_dir" ]; then
				local tool_name
				tool_name=$(basename "$(dirname "$tool_dir")")
				local backup_dir
				backup_dir="$HOME/.my-ai-tools-backups/skills/${tool_name}.skills.backup.$(date +%Y%m%d%H%M%S).$$"
				execute_quoted mkdir -p "$(dirname "$backup_dir")"
				execute_quoted mv "$tool_dir" "$backup_dir"
				log_info "Backed up existing skills directory to: $backup_dir"
			else
				execute_quoted rm -rf "$tool_dir"
			fi
		fi

		# Create symlink to universal directory
		execute_quoted ln -s "$universal_dir" "$tool_dir"
		log_success "Created skills symlink: $tool_dir -> ~/.agents/skills"
	done
}

# Prepare universal skills directory - cleans up managed skills
prepare_universal_skills_dir() {
	local dir="$1"
	local managed_marker=".my-ai-tools-managed"

	execute_quoted mkdir -p "$dir"

	# Clean up managed skills from universal directory
	if [ -d "$dir" ]; then
		for existing_skill in "$dir"/*; do
			[ -d "$existing_skill" ] || continue
			local existing_name
			existing_name=$(basename "$existing_skill")

			# Check if this is a managed skill (from our repo)
			if [ -f "$existing_skill/$managed_marker" ] || [ -d "$SCRIPT_DIR/skills/$existing_name" ]; then
				execute_quoted rm -rf "$existing_skill"
				log_info "Updated managed skill in universal directory: $existing_name"
			fi
		done
	fi
}

# Copy skill to universal directory
copy_skill_to_universal() {
	local skill_name="$1"
	local skill_dir="$2"
	local universal_dir="$3"
	local managed_marker=".my-ai-tools-managed"

	safe_copy_dir "$skill_dir" "$universal_dir/$skill_name"
	execute_quoted touch "$universal_dir/$skill_name/$managed_marker"
	log_success "Copied $skill_name to universal skills directory"
}

main() {
	# --migrate-gemini: lightweight migration-only path (no Node/Bun required)
	if [ "$MIGRATE_GEMINI" = true ]; then
		preflight_check
		echo
		install_jq_if_needed
		echo
		migrate_gemini_to_antigravity
		exit 0
	fi

	echo "╔══════════════════════════════════════════════════════════════════════╗"
	echo "║                        AI Tools Setup                                ║"
	echo "║  Claude • OpenCode • Amp • CCS • Codex • Gemini • Antigravity         ║"
	echo "║  Pi • Kilo • Copilot • Cursor • Factory Droid • Cline • Command Code  ║"
	echo "║  Grok • MiMo-Code                                                     ║"
	echo "╚══════════════════════════════════════════════════════════════════════╝"
	echo

	if [ "$DRY_RUN" = true ]; then
		log_warning "DRY RUN MODE - No changes will be made"
		echo
	fi

	preflight_check
	echo

	check_prerequisites
	echo

	backup_configs
	echo

	install_claude_code
	echo

	install_opencode
	echo

	install_amp
	echo

	install_global_tools
	echo

	install_ccs
	echo

	install_ai_switcher
	echo

	install_codex
	echo

	install_gemini
	echo

	install_antigravity
	echo

	install_kilo
	echo

	install_pi
	echo

	install_commandcode
	echo

	install_copilot
	echo

	install_cursor
	echo

	install_factory
	echo

	install_cline
	echo

	install_grok
	echo

	install_mimo
	echo

	install_open_code_review
	echo

	copy_configurations
	echo

	enable_plugins
	echo

	log_success "Setup complete!"
	echo
	echo "Next steps:"
	echo "  1. Restart your terminal"
	echo "  2. Run 'claude' to start Claude Code (or 'agy' for Antigravity CLI, 'cmd' for Command Code, 'grok' for Grok CLI, 'mimo' for MiMo-Code)"
	echo "  3. Enable plugins with 'claude plugin enable <plugin-name>'"
	echo "  4. Check out the README.md for more information"
	echo

	if [ "$BACKUP" = true ]; then
		echo "Your old configs have been backed up to: $BACKUP_DIR"
	fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
