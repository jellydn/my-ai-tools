#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
BACKUP_DIR="$HOME/ai-tools-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
BACKUP=false
PROMPT_BACKUP=true
YES_TO_ALL=false

# Detect OS (Windows vs Unix-like)
IS_WINDOWS=false
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "$MSYSTEM" ]]; then
    IS_WINDOWS=true
fi

# Track whether Amp is installed (for backlog.md dependency)
AMP_INSTALLED=false

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
	--yes|-y)
		YES_TO_ALL=true
		shift
		;;
	--rollback)
		log_info "Rolling back last transaction..."
		rollback_transaction
		exit $?
		;;
	*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run] [--backup] [--no-backup] [--yes|-y] [--rollback]"
		exit 1
		;;
	esac
done

# Preflight check for required tools
preflight_check() {
	local missing_tools=()

	log_info "Running preflight checks..."

	# Core utilities required by the script
	local required_tools=("jq" "awk" "sed" "basename" "cat" "head" "tail" "grep" "date")

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

# Install MCP server with better error handling
install_mcp_server() {
	local server_name="$1"
	local install_cmd="$2"

	# Capture stderr to temp file for error analysis
	local err_file="/tmp/claude-mcp-${server_name}.err"

	if execute "$install_cmd" 2>"$err_file"; then
		log_success "${server_name} MCP server added (global)"
		rm -f "$err_file"
		return 0
	else
		# Check if it's an "already exists" error (expected)
		if grep -qi "already" "$err_file" 2>/dev/null; then
			log_info "${server_name} already installed"
		else
			# Actual error - provide details for debugging
			log_warning "${server_name} installation failed - check $err_file for details"
		fi
		rm -f "$err_file"
		return 1
	fi
}

# Set up TMPDIR to avoid cross-device link errors
# Uses a temp directory within $HOME to ensure same filesystem
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
		log_warning "Some scripts (e.g., context-check) prefer Bun. Install with: brew install oven-sh/bun/bun"
	else
		log_error "Neither Bun nor Node.js is installed. Please install one of them first."
		exit 1
	fi
}

install_global_tools() {
	log_info "Checking global tools for hooks..."

	# Check/install jq (required for JSON parsing in hooks)
	if ! command -v jq &>/dev/null; then
		log_warning "jq not found. Installing jq..."
		if [ "$IS_WINDOWS" = true ]; then
			# Windows: use choco or winget, or download binary
			if command -v choco &>/dev/null; then
				execute "choco install jq -y"
			elif command -v winget &>/dev/null; then
				execute "winget install jq"
			else
				log_warning "Please install jq manually: https://stedolan.github.io/jq/download/"
			fi
		else
			# Mac/Linux: use brew or apt
			if command -v brew &>/dev/null; then
				execute "brew install jq"
			elif command -v apt-get &>/dev/null; then
				execute "sudo apt-get install -y jq"
			else
				log_warning "Please install jq manually: https://stedolan.github.io/jq/download/"
			fi
		fi
	else
		log_success "jq found"
	fi

	# Check/install biome (required for JS/TS formatting)
	if ! command -v biome &>/dev/null; then
		log_warning "biome not found. Installing biome globally..."
		execute "npm install -g @biomejs/biome"
	else
		log_success "biome found"
	fi

	# Check/install backlog.md (only if Amp is installed)
	if [ "$AMP_INSTALLED" = true ]; then
		if ! command -v backlog &>/dev/null; then
			log_info "Installing backlog.md for Amp integration..."
			execute "npm install -g backlog.md"
		else
			log_success "backlog.md found"
		fi
	fi

	log_success "Global tools check complete"
}

# Helper: Safely copy a directory, handling "Text file busy" errors
# Usage: safe_copy_dir "source_dir" "dest_dir"
safe_copy_dir() {
	local source_dir="$1"
	local dest_dir="$2"
	
	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would copy $source_dir to $dest_dir"
		return 0
	fi
	
	# Ensure destination parent exists
	mkdir -p "$(dirname "$dest_dir")" 2>/dev/null || true
	
	# Try regular copy first
	if cp -r "$source_dir" "$dest_dir" 2>/dev/null; then
		return 0
	fi
	
	# If copy failed, try with rsync to handle busy files
	if command -v rsync &>/dev/null; then
		# Use rsync to copy, matching cp -r behavior
		rsync -a --ignore-errors "$source_dir" "$(dirname "$dest_dir")/" 2>/dev/null || true
	else
		# Fallback: copy non-binary files, skip busy binaries
		mkdir -p "$dest_dir"
		find "$source_dir" -type f 2>/dev/null | while read -r file; do
			rel_path="${file#$source_dir/}"
			dest_file="$dest_dir/$rel_path"
			mkdir -p "$(dirname "$dest_file")"
			cp "$file" "$dest_file" 2>/dev/null || log_warning "Skipped busy file: $rel_path"
		done
	fi
}

# Helper: Copy a config directory if it exists in source and destination
# Usage: copy_config_dir "source_dir" "dest_parent" "dest_name"
copy_config_dir() {
	local source_dir="$1"
	local dest_parent="$2"
	local dest_name="$3"

	if [ -d "$source_dir" ]; then
		execute "mkdir -p $dest_parent"
		execute "cp -r $source_dir $dest_parent/$dest_name"
		log_success "Backed up $dest_name configs"
	fi
}

# Helper: Copy a config file if it exists in source
# Usage: copy_config_file "source_file" "dest_dir"
copy_config_file() {
	local source_file="$1"
	local dest_dir="$2"

	if [ -f "$source_file" ]; then
		execute "mkdir -p $dest_dir"
		execute "cp $source_file $dest_dir/"
		return 0
	fi
	return 1
}

# Helper: Ensure a CLI tool is installed, prompting if interactive
# Usage: ensure_cli_tool "tool_name" "install_check_cmd" "install_cmd" "version_cmd"
ensure_cli_tool() {
	local name="$1"
	local check_cmd="$2"
	local install_cmd="$3"
	local version_cmd="$4"

	if command -v "$name" &>/dev/null; then
		if [ -n "$version_cmd" ]; then
			local version
			version=$($version_cmd 2>/dev/null)
			log_success "$name found ($version)"
		else
			log_success "$name found"
		fi
		return 0
	fi

	log_warning "$name not found. Installing..."
	$install_cmd
}

backup_configs() {
	# Clean up old backups first (keep last 5)
	cleanup_old_backups 5

	if [ "$PROMPT_BACKUP" = true ]; then
		if [ "$YES_TO_ALL" = true ]; then
			log_info "Auto-accepting backup (--yes flag)"
			BACKUP=true
		elif [ -t 0 ]; then
			read -p "Do you want to backup existing configurations? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				BACKUP=true
			fi
		else
			log_info "Skipping backup prompt in non-interactive mode (use --backup to force backup)"
		fi
	fi

	if [ "$BACKUP" = true ]; then
		log_info "Creating backup at $BACKUP_DIR..."
		execute "mkdir -p $BACKUP_DIR"

		copy_config_dir "$HOME/.claude" "$BACKUP_DIR" "claude"
		copy_config_dir "$HOME/.config/claude" "$BACKUP_DIR" "config-claude"
		copy_config_dir "$HOME/.config/opencode" "$BACKUP_DIR" "opencode"
		copy_config_dir "$HOME/.config/amp" "$BACKUP_DIR" "amp"
		copy_config_dir "$HOME/.ccs" "$BACKUP_DIR" "ccs"
		copy_config_dir "$HOME/.codex" "$BACKUP_DIR" "codex"
		copy_config_file "$HOME/.config/ai-switcher/config.json" "$BACKUP_DIR/ai-switcher"

		log_success "Backup completed: $BACKUP_DIR"
	fi
}

install_claude_code() {
	log_info "Installing Claude Code..."

	if command -v claude &>/dev/null; then
		log_warning "Claude Code is already installed ($(claude --version))"
		if [ "$YES_TO_ALL" = true ]; then
			log_info "Auto-skipping reinstall (--yes flag)"
			return
		elif [ -t 0 ]; then
			read -p "Do you want to reinstall? (y/n) " -n 1 -r
			echo
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				return
			fi
		else
			log_info "Skipping reinstall in non-interactive mode"
			return
		fi
	fi

	execute "npm install -g @anthropic-ai/claude-code"
	log_success "Claude Code installed"
}

install_opencode() {
	prompt_and_install() {
		log_info "Installing OpenCode..."
		if command -v opencode &>/dev/null; then
			log_warning "OpenCode is already installed"
		else
			execute_installer "https://opencode.ai/install" "" "OpenCode"
			log_success "OpenCode installed"
		fi
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting OpenCode installation (--yes flag)"
		prompt_and_install
	elif [ -t 0 ]; then
		read -p "Do you want to install OpenCode? (y/n) " -n 1 -r
		echo
		[[ $REPLY =~ ^[Yy]$ ]] && prompt_and_install || log_warning "Skipping OpenCode installation"
	else
		log_info "Installing OpenCode (non-interactive mode)..."
		prompt_and_install
	fi
}

install_amp() {
	prompt_and_install() {
		log_info "Installing Amp..."
		if command -v amp &>/dev/null; then
			log_warning "Amp is already installed"
		else
			execute_installer "https://ampcode.com/install.sh" "" "Amp"
		fi
		AMP_INSTALLED=true
		log_success "Amp installed"
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting Amp installation (--yes flag)"
		prompt_and_install
	elif [ -t 0 ]; then
		read -p "Do you want to install Amp? (y/n) " -n 1 -r
		echo
		[[ $REPLY =~ ^[Yy]$ ]] && prompt_and_install || log_warning "Skipping Amp installation"
	else
		log_info "Installing Amp (non-interactive mode)..."
		prompt_and_install
	fi
}

install_ccs() {
	prompt_and_install() {
		log_info "Installing CCS..."
		if command -v ccs &>/dev/null; then
			log_warning "CCS is already installed ($(ccs --version))"
		else
			execute "npm install -g @kaitranntt/ccs"
			log_success "CCS installed"
		fi
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting CCS installation (--yes flag)"
		prompt_and_install
	elif [ -t 0 ]; then
		read -p "Do you want to install CCS (Claude Code Switch)? (y/n) " -n 1 -r
		echo
		[[ $REPLY =~ ^[Yy]$ ]] && prompt_and_install || log_warning "Skipping CCS installation"
	else
		log_info "Installing CCS (non-interactive mode)..."
		prompt_and_install
	fi
}

install_ai_switcher() {
	prompt_and_install() {
		log_info "Installing ai-switcher..."
		if command -v ai-switcher &>/dev/null; then
			log_warning "ai-switcher is already installed"
		else
			execute_installer "https://raw.githubusercontent.com/jellydn/ai-cli-switcher/main/install.sh" "" "ai-switcher"
			log_success "ai-switcher installed"
		fi
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting ai-switcher installation (--yes flag)"
		prompt_and_install
	elif [ -t 0 ]; then
		read -p "Do you want to install ai-switcher? (y/n) " -n 1 -r
		echo
		[[ $REPLY =~ ^[Yy]$ ]] && prompt_and_install || log_warning "Skipping ai-switcher installation"
	else
		log_info "Installing ai-switcher (non-interactive mode)..."
		prompt_and_install
	fi
}

install_codex() {
	prompt_and_install() {
		log_info "Installing Codex CLI..."
		if command -v codex &>/dev/null; then
			log_warning "Codex CLI is already installed"
		else
			execute "npm install -g @openai/codex-cli"
			log_success "Codex CLI installed"
		fi
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting Codex installation (--yes flag)"
		prompt_and_install
	elif [ -t 0 ]; then
		read -p "Do you want to install OpenAI Codex CLI? (y/n) " -n 1 -r
		echo
		[[ $REPLY =~ ^[Yy]$ ]] && prompt_and_install || log_warning "Skipping Codex CLI installation"
	else
		log_info "Installing Codex CLI (non-interactive mode)..."
		prompt_and_install
	fi
}

# Helper: Copy non-marketplace skills from source to destination
# Usage: copy_non_marketplace_skills "source_dir" "dest_dir"
copy_non_marketplace_skills() {
	local source_dir="$1"
	local dest_dir="$2"

	if [ -d "$source_dir" ] && [ "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		execute "rm -rf $dest_dir"
		execute "mkdir -p $dest_dir"
		for skill_dir in "$source_dir"/*; do
			if [ -d "$skill_dir" ]; then
				skill_name="$(basename "$skill_dir")"
				case "$skill_name" in
					prd|ralph|qmd-knowledge|codemap)
						# Skip marketplace plugins
						;;
					*)
						execute "cp -r \"$skill_dir\" \"$dest_dir/\""
						;;
				esac
			fi
		done
	fi
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
		read -p "Install $name MCP server ($description)? (y/n) " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
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

copy_configurations() {
	log_info "Copying configurations..."

	# Create ~/.claude directory
	execute "mkdir -p $HOME/.claude"

	# Copy Claude Code configs
	execute "cp $SCRIPT_DIR/configs/claude/settings.json $HOME/.claude/settings.json"
	execute "cp $SCRIPT_DIR/configs/claude/mcp-servers.json $HOME/.claude/mcp-servers.json"
	execute "cp $SCRIPT_DIR/configs/claude/CLAUDE.md $HOME/.claude/CLAUDE.md"
	execute "rm -rf $HOME/.claude/commands"
	execute "cp -r $SCRIPT_DIR/configs/claude/commands $HOME/.claude/"
	if [ -d "$SCRIPT_DIR/configs/claude/agents" ]; then
		execute "mkdir -p $HOME/.claude/agents"
		execute "cp $SCRIPT_DIR/configs/claude/agents/* $HOME/.claude/agents/"
	fi

	# Add MCP servers using Claude Code CLI (globally, available in all projects)
	if command -v claude &>/dev/null; then
		log_info "Setting up Claude Code MCP servers (global scope)..."
		install_mcp_interactive "context7" "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest" "documentation lookup"
		install_mcp_interactive "sequential-thinking" "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking" "multi-step reasoning"
		if command -v qmd &>/dev/null; then
			install_mcp_interactive "qmd" "claude mcp add --scope user --transport stdio qmd -- qmd mcp" "knowledge management"
		else
			log_warning "qmd not found. MCP setup skipped. Install with: bun install -g https://github.com/tobi/qmd"
		fi
		log_success "MCP server setup complete (global scope)"
	fi

	log_success "Claude Code configs copied"

	# Copy OpenCode configs
	if [ -d "$HOME/.config/opencode" ] || command -v opencode &>/dev/null; then
		execute "mkdir -p $HOME/.config/opencode"
		execute "cp $SCRIPT_DIR/configs/opencode/opencode.json $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/agent"
		execute "cp -r $SCRIPT_DIR/configs/opencode/agent $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/command"
		execute "cp -r $SCRIPT_DIR/configs/opencode/command $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/skill"
		copy_non_marketplace_skills "$SCRIPT_DIR/configs/opencode/skill" "$HOME/.config/opencode/skill"
		log_success "OpenCode configs copied"
	fi

	# Copy Amp configs
	if [ -d "$HOME/.config/amp" ] || command -v amp &>/dev/null; then
		execute "mkdir -p $HOME/.config/amp"
		execute "cp $SCRIPT_DIR/configs/amp/settings.json $HOME/.config/amp/"
		copy_non_marketplace_skills "$SCRIPT_DIR/configs/amp/skills" "$HOME/.config/amp/skills"
		if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
			execute "cp $SCRIPT_DIR/configs/amp/AGENTS.md $HOME/.config/amp/"
			if [ -f "$HOME/.config/AGENTS.md" ]; then
				cp "$HOME/.config/AGENTS.md" "$HOME/.config/AGENTS.md.bak"
				log_warning "Backed up existing AGENTS.md to .bak"
			fi
			execute "cp $SCRIPT_DIR/configs/amp/AGENTS.md $HOME/.config/AGENTS.md"
		fi
		log_success "Amp configs copied"
	fi

	# Copy CCS configs
	if [ -d "$HOME/.ccs" ] || command -v ccs &>/dev/null; then
		execute "mkdir -p $HOME/.ccs"
		execute "cp $SCRIPT_DIR/configs/ccs/*.yaml $HOME/.ccs/ 2>/dev/null || true"
		execute "cp $SCRIPT_DIR/configs/ccs/*.json $HOME/.ccs/ 2>/dev/null || true"
		execute "cp $SCRIPT_DIR/configs/ccs/*.settings.json $HOME/.ccs/ 2>/dev/null || true"
		
		# Safely copy cliproxy (may contain running binaries)
		if [ -d "$SCRIPT_DIR/configs/ccs/cliproxy" ]; then
			safe_copy_dir "$SCRIPT_DIR/configs/ccs/cliproxy" "$HOME/.ccs/cliproxy"
		fi
		
		[ -d "$SCRIPT_DIR/configs/ccs/hooks" ] && execute "cp -r $SCRIPT_DIR/configs/ccs/hooks $HOME/.ccs/"
		log_success "CCS configs copied"
	fi

	# Copy ai-switcher configs
	if [ -d "$HOME/.config/ai-switcher" ] || [ -f "$HOME/.config/ai-switcher/config.json" ]; then
		if copy_config_file "$SCRIPT_DIR/configs/ai-switcher/config.json" "$HOME/.config/ai-switcher"; then
			log_success "ai-switcher configs copied"
		else
			log_info "ai-switcher config not found in source, preserving existing"
		fi
	fi

	# Copy Codex CLI configs
	if [ -d "$HOME/.codex" ] || command -v codex &>/dev/null; then
		execute "mkdir -p $HOME/.codex"
		copy_config_file "$SCRIPT_DIR/configs/codex/AGENTS.md" "$HOME/.codex/"
		copy_config_file "$SCRIPT_DIR/configs/codex/config.json" "$HOME/.codex/"
		if [ -f "$SCRIPT_DIR/configs/codex/config.toml" ]; then
			if [ -f "$HOME/.codex/config.toml" ]; then
				# Backup existing config before overwriting
				execute "cp $HOME/.codex/config.toml $HOME/.codex/config.toml.bak"
				log_success "Backed up existing config.toml to config.toml.bak"
			fi
			# Copy new config (whether or not there was an old one)
			execute "cp $SCRIPT_DIR/configs/codex/config.toml $HOME/.codex/"
			log_success "Copied Codex config.toml"
		fi
		log_success "Codex CLI configs copied (skills invoked via \$, prompts no longer needed)"
	fi

	# Copy best practices and MEMORY.md
	execute "mkdir -p $HOME/.ai-tools"
	execute "cp $SCRIPT_DIR/configs/best-practices.md $HOME/.ai-tools/"
	log_success "Best practices copied to ~/.ai-tools/"
	[ -f "$SCRIPT_DIR/MEMORY.md" ] && execute "cp $SCRIPT_DIR/MEMORY.md $HOME/.ai-tools/" && log_success "MEMORY.md copied to ~/.ai-tools/ (reference copy)"
}

enable_plugins() {
	log_info "Installing Claude Code plugins..."

	# Ask for skill installation source
	if [ -t 0 ]; then
		log_info "How would you like to install community skills?"
		printf "1) Local (from .claude-plugin folder) 2) Remote (from jellydn/my-ai-tools marketplace) [1/2]: "
		read REPLY
		echo
		case "$REPLY" in
			2) SKILL_INSTALL_SOURCE="remote" ;;
			*) SKILL_INSTALL_SOURCE="local" ;;
		esac
	else
		SKILL_INSTALL_SOURCE="local"
	fi

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

	# Community plugins (name, plugin_spec, marketplace_repo)
	# Format: "name|plugin_spec|marketplace_repo"
	community_plugins=(
		"plannotator|plannotator@plannotator|backnotprop/plannotator"
		"prd|prd@my-ai-tools|$SCRIPT_DIR"
		"ralph|ralph@my-ai-tools|$SCRIPT_DIR"
		"qmd-knowledge|qmd-knowledge@my-ai-tools|$SCRIPT_DIR"
		"codemap|codemap@my-ai-tools|$SCRIPT_DIR"
		"claude-hud|claude-hud@claude-hud|jarrodwatts/claude-hud"
		"worktrunk|worktrunk@worktrunk|max-sixty/worktrunk"
	)

	install_plugin() {
		local plugin="$1"
		if [ "$YES_TO_ALL" = true ]; then
			setup_tmpdir
			if ! execute "claude plugin install '$plugin' 2>/dev/null"; then
				log_warning "$plugin install failed (may already be installed)"
			fi
		elif [ -t 0 ]; then
			read -p "Install $plugin? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				setup_tmpdir
				execute "claude plugin install '$plugin' && log_success '$plugin installed' || log_warning '$plugin install failed (may already be installed)'"
			fi
		else
			setup_tmpdir
			if ! execute "claude plugin install '$plugin' 2>/dev/null"; then
				log_warning "$plugin install failed (may already be installed)"
			fi
		fi
	}

	install_community_plugin() {
		local name="$1"
		local plugin_spec="$2"
		local marketplace_repo="$3"

		if [ "$YES_TO_ALL" = true ] || [ ! -t 0 ]; then
			# Non-interactive or auto-install mode - install CLI tools if needed
			case "$name" in
				plannotator)
					if ! command -v plannotator &>/dev/null; then
						log_info "Installing Plannator CLI..."
						execute_installer "https://plannotator.ai/install.sh" "" "Plannator CLI" || log_warning "Plannator installation failed"
					fi
					;;
				qmd-knowledge)
					if ! command -v qmd &>/dev/null && command -v bun &>/dev/null; then
						log_info "Installing qmd CLI via bun..."
						bun install -g https://github.com/tobi/qmd 2>&1 || log_warning "qmd installation failed"
					fi
					;;
				worktrunk)
					if ! command -v wt &>/dev/null && command -v brew &>/dev/null; then
						log_info "Installing Worktrunk CLI via Homebrew..."
						brew install worktrunk 2>&1 && wt config shell install 2>&1 || log_warning "Worktrunk installation failed"
					fi
					;;
			esac
			# Add marketplace and install plugin
			setup_tmpdir
			execute "claude plugin marketplace add '$marketplace_repo' 2>/dev/null || true"
			# Clear any stale plugin cache that might cause cross-device link errors
			execute "rm -rf '$HOME/.claude/plugins/cache/$name' 2>/dev/null || true"
			if ! execute "claude plugin install '$plugin_spec' 2>/dev/null"; then
				log_warning "$name plugin install failed (may already be installed)"
			fi
		elif [ -t 0 ]; then
			read -p "Install $name? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				# Install CLI tool if needed
				case "$name" in
					plannotator)
						if ! command -v plannotator &>/dev/null; then
							log_info "Installing Plannator CLI (this may take a moment)..."
							if execute_installer "https://plannotator.ai/install.sh" "" "Plannator CLI"; then
								log_success "Plannator CLI installed"
							else
								log_warning "Plannator installation failed or was cancelled"
							fi
						else
							log_info "Plannator CLI already installed"
						fi
						;;
					qmd-knowledge)
						if ! command -v qmd &>/dev/null; then
							if command -v bun &>/dev/null; then
								log_info "Installing qmd CLI via bun..."
								if bun install -g https://github.com/tobi/qmd 2>&1; then
									log_success "qmd CLI installed"
								else
									log_warning "qmd installation failed"
								fi
							else
								log_warning "bun is required for qmd. Install from https://bun.sh"
							fi
						else
							log_info "qmd CLI already installed"
						fi
						;;
					worktrunk)
						if ! command -v wt &>/dev/null; then
							if command -v brew &>/dev/null; then
								log_info "Installing Worktrunk CLI via Homebrew (this may take a moment)..."
								if brew install worktrunk 2>&1 && wt config shell install 2>&1; then
									log_success "Worktrunk CLI installed"
								else
									log_warning "Worktrunk installation failed"
								fi
							else
								log_warning "Homebrew is required for worktrunk. Install from https://brew.sh"
							fi
						else
							log_info "Worktrunk CLI already installed"
						fi
						;;
				esac

				# Add marketplace first
				setup_tmpdir
				if ! execute "claude plugin marketplace add '$marketplace_repo' 2>/dev/null"; then
					log_info "Marketplace $marketplace_repo may already be added"
				fi
				# Clear any stale plugin cache that might cause cross-device link errors
				execute "rm -rf '$HOME/.claude/plugins/cache/$name' 2>/dev/null || true"
				# Install plugin
				if execute "claude plugin install '$plugin_spec'"; then
					log_success "$name installed"
				else
					log_warning "$name install failed (may already be installed)"
				fi
			fi
		fi
	}

	# Extract compatibility field from SKILL.md
	# Returns 0 (true) if skill is compatible with platform, 1 (false) otherwise
	skill_is_compatible_with() {
		local skill_dir="$1"
		local platform="$2"
		local skill_md="$skill_dir/SKILL.md"

		if [ ! -f "$skill_md" ]; then
			# No SKILL.md means assume compatible with all
			return 0
		fi

		# Extract compatibility line from frontmatter
		local compat_line=$(awk '/^compatibility:/ {print; exit}' "$skill_md" 2>/dev/null)

		if [ -z "$compat_line" ]; then
			# No compatibility field means assume compatible with all
			return 0
		fi

		# Check if platform is in the compatibility list
		# Compatibility format: "compatibility: claude, opencode, amp, codex"
		if echo "$compat_line" | grep -qi "\\b$platform\\b"; then
			return 0
		else
			return 1
		fi
	}

	install_local_skills() {
		if [ ! -d "$SCRIPT_DIR/.claude-plugin/plugins" ]; then
			log_info ".claude-plugin/plugins folder not found, skipping local skills"
			return
		fi

		log_info "Installing skills from local .claude-plugin/plugins folder..."

		# Define target directories
		CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
		OPENCODE_SKILL_DIR="$HOME/.config/opencode/skill"
		OPENCODE_COMMAND_DIR="$HOME/.config/opencode/command/ai"
		AMP_SKILLS_DIR="$HOME/.config/amp/skills"
		CODEX_SKILLS_DIR="$HOME/.codex/skills"

		# Copy to Claude Code (~/.claude/skills/)
		if [ -d "$CLAUDE_SKILLS_DIR" ]; then
			# Remove existing skills safely using rm with quoted path
			for existing_skill in "$CLAUDE_SKILLS_DIR"/*; do
				[ -d "$existing_skill" ] && rm -rf "$existing_skill"
			done
		fi
		mkdir -p "$CLAUDE_SKILLS_DIR"

		# Copy to OpenCode (~/.config/opencode/skill/)
		if [ -d "$OPENCODE_SKILL_DIR" ]; then
			for existing_skill in "$OPENCODE_SKILL_DIR"/*; do
				[ -d "$existing_skill" ] && rm -rf "$existing_skill"
			done
		fi
		mkdir -p "$OPENCODE_SKILL_DIR"

		# Create OpenCode commands directory
		mkdir -p "$OPENCODE_COMMAND_DIR"

		# Copy to Amp (~/.config/amp/skills/)
		if [ -d "$AMP_SKILLS_DIR" ]; then
			for existing_skill in "$AMP_SKILLS_DIR"/*; do
				[ -d "$existing_skill" ] && rm -rf "$existing_skill"
			done
		fi
		mkdir -p "$AMP_SKILLS_DIR"

		# Copy to Codex CLI (~/.codex/skills/)
		if [ -d "$CODEX_SKILLS_DIR" ]; then
			for existing_skill in "$CODEX_SKILLS_DIR"/*; do
				[ -d "$existing_skill" ] && rm -rf "$existing_skill"
			done
		fi
		mkdir -p "$CODEX_SKILLS_DIR"

		# Copy all skills from plugins folder to targets
		for skill_dir in "$SCRIPT_DIR/.claude-plugin/plugins"/*; do
			if [ -d "$skill_dir" ]; then
				skill_name=$(basename "$skill_dir")

				# Check compatibility and copy to each platform
				if skill_is_compatible_with "$skill_dir" "claude"; then
					cp -r "$skill_dir" "$CLAUDE_SKILLS_DIR/"
					log_success "Copied $skill_name to Claude Code"
				else
					log_info "Skipped $skill_name for Claude Code (not compatible)"
				fi

				if skill_is_compatible_with "$skill_dir" "opencode"; then
					cp -r "$skill_dir" "$OPENCODE_SKILL_DIR/"
					log_success "Copied $skill_name to OpenCode"
				else
					log_info "Skipped $skill_name for OpenCode (not compatible)"
				fi

				if skill_is_compatible_with "$skill_dir" "amp"; then
					cp -r "$skill_dir" "$AMP_SKILLS_DIR/"
					log_success "Copied $skill_name to Amp"
				else
					log_info "Skipped $skill_name for Amp (not compatible)"
				fi

				if skill_is_compatible_with "$skill_dir" "codex"; then
					cp -r "$skill_dir" "$CODEX_SKILLS_DIR/"
					log_success "Copied $skill_name to Codex CLI"
				else
					log_info "Skipped $skill_name for Codex CLI (not compatible)"
				fi

				# Generate OpenCode command from skill (only if compatible)
				if skill_is_compatible_with "$skill_dir" "opencode"; then
					generate_opencode_command "$skill_dir" "$OPENCODE_COMMAND_DIR"
				fi
			fi
		done
	}

	# Generate OpenCode command file from skill SKILL.md
	generate_opencode_command() {
		local skill_dir="$1"
		local command_dir="$2"
		local skill_name=$(basename "$skill_dir")
		local skill_md="$skill_dir/SKILL.md"

		if [ ! -f "$skill_md" ]; then
			log_warning "No SKILL.md found for $skill_name, skipping command generation"
			return
		fi

		# Description for command - simple and consistent
		local description="Trigger $skill_name skill"


		# Extract content after frontmatter for objective
		local objective_content=""
		objective_content=$(awk 'BEGIN{p=0} /^---$/{p++;next} p>=2' "$skill_md" 2>/dev/null | head -50)

		# Create command file
		local command_file="$command_dir/$skill_name.md"

		# Add path allowances for codemap (writes to .planning/codebase/)
		local path_allowance=""
		if [ "$skill_name" = "codemap" ]; then
			path_allowance="

**Allowed paths:**
- Write: .planning/codebase/"
		fi

		if [ "$DRY_RUN" = true ]; then
			log_info "[DRY RUN] Would generate command: $command_file"
			return
		fi

		cat > "$command_file" << EOF
---
name: ai:$skill_name
description: "$description"
argument-hint: "[optional: arguments for $skill_name]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Task
---

<objective>
$objective_content$path_allowance
</objective>
EOF

		log_success "Generated command: $command_file"
	}

	if command -v claude &>/dev/null; then
		# Add official plugins marketplace first
		log_info "Adding official plugins marketplace..."
		if ! execute "claude plugin marketplace add 'anthropics/claude-plugins-official' 2>/dev/null"; then
			log_info "Official plugins marketplace may already be added"
		fi

		log_info "Installing official plugins..."
		if [ -t 0 ]; then
			# Interactive mode: install sequentially with prompts
			for plugin in "${official_plugins[@]}"; do
				install_plugin "$plugin"
			done
		else
			# Non-interactive mode: install in parallel for faster execution
			log_info "Installing plugins in parallel..."
			local pids=()
			for plugin in "${official_plugins[@]}"; do
				(
					setup_tmpdir
					if claude plugin install "$plugin" 2>/dev/null; then
						log_success "$plugin installed"
					else
						log_warning "$plugin may already be installed"
					fi
				) &
				pids+=($!)
			done

			# Wait for all installations to complete
			for pid in "${pids[@]}"; do
				wait "$pid" 2>/dev/null || true
			done
			log_success "Official plugins installation complete"
		fi

		if [ "$SKILL_INSTALL_SOURCE" = "local" ]; then
			log_info "Installing community skills from local .claude-plugin folder..."
			install_local_skills
			# Only install CLI-based plugins (plannotator, claude-hud, worktrunk)
			for plugin_entry in "${community_plugins[@]}"; do
				local name="${plugin_entry%%|*}"
				case "$name" in
					prd|ralph|qmd-knowledge|codemap)
						# Skip marketplace plugins - will be installed from local .claude-plugin
						;;
					*)
						local rest="${plugin_entry#*|}"
						local plugin_spec="${rest%%|*}"
						local marketplace_repo="${rest##*|}"
						install_community_plugin "$name" "$plugin_spec" "$marketplace_repo"
						;;
				esac
			done
		else
			log_info "Installing community plugins from marketplace..."
			for plugin_entry in "${community_plugins[@]}"; do
				# Parse the pipe-separated entry
				local name="${plugin_entry%%|*}"
				local rest="${plugin_entry#*|}"
				local plugin_spec="${rest%%|*}"
				local marketplace_repo="${rest##*|}"
				install_community_plugin "$name" "$plugin_spec" "$marketplace_repo"
			done
		fi

		log_success "Claude Code plugins installation complete"
		log_info "IMPORTANT: Restart Claude Code for plugins to take effect"
	else
		log_warning "Claude Code not installed - skipping plugin installation"
	fi
}

main() {
	echo "╔══════════════════════════════════════════════════════════╗"
	echo "║         AI Tools Setup                                   ║"
	echo "║   Claude • OpenCode • Amp • CCS • Codex • AI Switcher    ║"
	echo "╚══════════════════════════════════════════════════════════╝"
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

	copy_configurations
	echo

	enable_plugins
	echo

	log_success "Setup complete!"
	echo
	echo "Next steps:"
	echo "  1. Restart your terminal"
	echo "  2. Run 'claude' to start Claude Code"
	echo "  3. Enable plugins with 'claude plugin enable <plugin-name>'"
	echo "  4. Check out the README.md for more information"
	echo

	if [ "$BACKUP" = true ]; then
		echo "Your old configs have been backed up to: $BACKUP_DIR"
	fi
}

main
