#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/ai-tools-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
BACKUP=false
PROMPT_BACKUP=true

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
	*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run] [--backup] [--no-backup]"
		exit 1
		;;
	esac
done

log_info() {
	echo -e "${BLUE}ℹ ${NC}$1"
}

log_success() {
	echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
	echo -e "${RED}✗${NC} $1"
}

execute() {
	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] $1"
	else
		eval "$1"
	fi
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

backup_configs() {
	if [ "$PROMPT_BACKUP" = true ]; then
		if [ -t 1 ]; then
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

		if [ -d "$HOME/.claude" ]; then
			execute "cp -r $HOME/.claude $BACKUP_DIR/claude"
			log_success "Backed up Claude Code configs"
		fi

		if [ -d "$HOME/.config/claude" ]; then
			execute "cp -r $HOME/.config/claude $BACKUP_DIR/config-claude"
			log_success "Backed up Claude Code XDG configs"
		fi

		if [ -d "$HOME/.config/opencode" ]; then
			execute "cp -r $HOME/.config/opencode $BACKUP_DIR/opencode"
			log_success "Backed up OpenCode configs"
		fi

		if [ -d "$HOME/.config/amp" ]; then
			execute "cp -r $HOME/.config/amp $BACKUP_DIR/amp"
			log_success "Backed up Amp configs"
		fi

		if [ -d "$HOME/.ccs" ]; then
			execute "cp -r $HOME/.ccs $BACKUP_DIR/ccs"
			log_success "Backed up CCS configs"
		fi

		if [ -f "$HOME/.config/ai-switcher/config.json" ]; then
			execute "mkdir -p $BACKUP_DIR/ai-switcher"
			execute "cp $HOME/.config/ai-switcher/config.json $BACKUP_DIR/ai-switcher/"
			log_success "Backed up ai-switcher configs"
		fi

		log_success "Backup completed: $BACKUP_DIR"
	fi
}

install_claude_code() {
	log_info "Installing Claude Code..."

	if command -v claude &>/dev/null; then
		log_warning "Claude Code is already installed ($(claude --version))"
		if [ -t 1 ]; then
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
	if [ -t 1 ]; then
		read -p "Do you want to install OpenCode? (y/n) " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_warning "Skipping OpenCode installation"
			return
		fi
	else
		log_info "Installing OpenCode (non-interactive mode)..."
	fi

	log_info "Installing OpenCode..."

	if command -v opencode &>/dev/null; then
		log_warning "OpenCode is already installed"
	else
		execute "curl -fsSL https://opencode.ai/install | bash"
		log_success "OpenCode installed"
	fi
}

install_amp() {
	if [ -t 1 ]; then
		read -p "Do you want to install Amp? (y/n) " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_warning "Skipping Amp installation"
			return
		fi
	else
		log_info "Installing Amp (non-interactive mode)..."
	fi

	log_info "Installing Amp..."

	if command -v amp &>/dev/null; then
		log_warning "Amp is already installed"
		AMP_INSTALLED=true
	else
		execute "curl -fsSL https://ampcode.com/install.sh | bash"
		log_success "Amp installed"
		AMP_INSTALLED=true
	fi
}

install_ccs() {
	if [ -t 1 ]; then
		read -p "Do you want to install CCS (Claude Code Switch)? (y/n) " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_warning "Skipping CCS installation"
			return
		fi
	else
		log_info "Installing CCS (non-interactive mode)..."
	fi

	log_info "Installing CCS..."

	if command -v ccs &>/dev/null; then
		log_warning "CCS is already installed ($(ccs --version))"
	else
		execute "npm install -g @kaitranntt/ccs"
		log_success "CCS installed"
	fi
}

install_ai_switcher() {
	if [ -t 1 ]; then
		read -p "Do you want to install ai-switcher? (y/n) " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_warning "Skipping ai-switcher installation"
			return
		fi
	else
		log_info "Installing ai-switcher (non-interactive mode)..."
	fi

	log_info "Installing ai-switcher..."

	if command -v ai-switcher &>/dev/null; then
		log_warning "ai-switcher is already installed"
	else
		execute "curl -fsSL https://raw.githubusercontent.com/jellydn/ai-cli-switcher/main/install.sh | sh"
		log_success "ai-switcher installed"
	fi
}

copy_configurations() {
	log_info "Copying configurations..."

	# Create ~/.claude directory (needed on all platforms)
	execute "mkdir -p $HOME/.claude"

	# Copy settings.json to appropriate location based on OS
	if [ "$IS_WINDOWS" = true ]; then
		# Windows: Claude Code uses ~/.claude directly
		execute "cp $SCRIPT_DIR/configs/claude/settings.json $HOME/.claude/settings.json"
	else
		# Mac/Linux: Use ~/.claude/settings.json (canonical location)
		execute "cp $SCRIPT_DIR/configs/claude/settings.json $HOME/.claude/settings.json"
	fi

	# Copy other configs to ~/.claude (all platforms)
	execute "cp $SCRIPT_DIR/configs/claude/mcp-servers.json $HOME/.claude/mcp-servers.json"
	execute "cp $SCRIPT_DIR/configs/claude/CLAUDE.md $HOME/.claude/CLAUDE.md"
	# Remove existing commands dir to avoid permission issues, then copy fresh
	execute "rm -rf $HOME/.claude/commands"
	execute "cp -r $SCRIPT_DIR/configs/claude/commands $HOME/.claude/"
	if [ -d "$SCRIPT_DIR/configs/claude/agents" ]; then
		execute "mkdir -p $HOME/.claude/agents"
		execute "cp $SCRIPT_DIR/configs/claude/agents/* $HOME/.claude/agents/"
	fi
	# Remove existing skills to avoid conflicts with directory/file name collisions
	if [ -d "$SCRIPT_DIR/configs/claude/skills" ]; then
		# Only copy if directory has content (not empty after excluding marketplace plugins)
		if [ "$(ls -A "$SCRIPT_DIR/configs/claude/skills" 2>/dev/null)" ]; then
			execute "rm -rf $HOME/.claude/skills"
			# Copy all skills except marketplace plugins (prd, ralph, qmd-knowledge, map-codebase)
			for skill_dir in "$SCRIPT_DIR/configs/claude/skills"/*; do
				skill_name="$(basename "$skill_dir")"
				case "$skill_name" in
					prd|ralph|qmd-knowledge|map-codebase)
						# Skip marketplace plugins - installed via cli.sh marketplace
						;;
					*)
						execute "cp -r \"$skill_dir\" \"$HOME/.claude/skills/\""
						;;
				esac
			done
		fi
	fi

	# Add MCP servers using Claude Code CLI (globally, available in all projects)
	if command -v claude &>/dev/null; then
		log_info "Setting up Claude Code MCP servers (global scope)..."

		# context7 MCP server
		if [ -t 1 ]; then
			read -p "Install context7 MCP server (documentation lookup)? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				if execute "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest"; then
					log_success "context7 MCP server added (global)"
				else
					log_warning "context7 already installed or failed"
				fi
			fi
		else
			install_mcp_server "context7" "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest"
		fi

		# sequential-thinking MCP server
		if [ -t 1 ]; then
			read -p "Install sequential-thinking MCP server (multi-step reasoning)? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				if execute "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking"; then
					log_success "sequential-thinking MCP server added (global)"
				else
					log_warning "sequential-thinking already installed or failed"
				fi
			fi
		else
			install_mcp_server "sequential-thinking" "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking"
		fi

		# qmd MCP server
		if [ -t 1 ]; then
			read -p "Install qmd MCP server (knowledge management)? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				if command -v qmd &>/dev/null; then
					if execute "claude mcp add --scope user --transport stdio qmd -- qmd mcp"; then
						log_success "qmd MCP server added (global)"
					else
						log_warning "qmd already installed or failed"
					fi
				else
					log_warning "qmd not found. Install with: bun install -g https://github.com/tobi/qmd"
				fi
			fi
		else
			if command -v qmd &>/dev/null; then
				install_mcp_server "qmd" "claude mcp add --scope user --transport stdio qmd -- qmd mcp"
			else
				log_warning "qmd not found. MCP setup skipped. Install with: bun install -g https://github.com/tobi/qmd"
			fi
		fi

		log_success "MCP server setup complete (global scope)"
	fi

	log_success "Claude Code configs copied"

	if [ -d "$HOME/.config/opencode" ] || command -v opencode &>/dev/null; then
		execute "mkdir -p $HOME/.config/opencode"
		execute "cp $SCRIPT_DIR/configs/opencode/opencode.json $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/agent"
		execute "cp -r $SCRIPT_DIR/configs/opencode/agent $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/command"
		execute "cp -r $SCRIPT_DIR/configs/opencode/command $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/skill"
		# Only copy if directory has content (not empty after excluding marketplace plugins)
		if [ -d "$SCRIPT_DIR/configs/opencode/skill" ] && [ "$(ls -A "$SCRIPT_DIR/configs/opencode/skill" 2>/dev/null)" ]; then
			# Copy all skills except marketplace plugins (prd, ralph, qmd-knowledge, map-codebase)
			for skill_dir in "$SCRIPT_DIR/configs/opencode/skill"/*; do
				skill_name="$(basename "$skill_dir")"
				case "$skill_name" in
					prd|ralph|qmd-knowledge|map-codebase)
						# Skip marketplace plugins - installed via cli.sh marketplace
						;;
					*)
						execute "cp -r \"$skill_dir\" \"$HOME/.config/opencode/skill/\""
						;;
				esac
			done
		fi
		log_success "OpenCode configs copied"
	fi

	if [ -d "$HOME/.config/amp" ] || command -v amp &>/dev/null; then
		execute "mkdir -p $HOME/.config/amp"
		execute "cp $SCRIPT_DIR/configs/amp/settings.json $HOME/.config/amp/"
		if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
			execute "cp $SCRIPT_DIR/configs/amp/AGENTS.md $HOME/.config/amp/"
		fi
		if [ -d "$SCRIPT_DIR/configs/amp/skills" ]; then
			# Only copy if directory has content (not empty after excluding marketplace plugins)
			if [ "$(ls -A "$SCRIPT_DIR/configs/amp/skills" 2>/dev/null)" ]; then
				execute "rm -rf $HOME/.config/amp/skills"
				# Copy all skills except marketplace plugins (prd, ralph, qmd-knowledge, map-codebase)
				for skill_dir in "$SCRIPT_DIR/configs/amp/skills"/*; do
					skill_name="$(basename "$skill_dir")"
					case "$skill_name" in
						prd|ralph|qmd-knowledge|map-codebase)
							# Skip marketplace plugins - installed via cli.sh marketplace
							;;
						*)
							execute "cp -r \"$skill_dir\" \"$HOME/.config/amp/skills/\""
							;;
					esac
				done
			fi
		fi
		# Also copy AGENTS.md to global config location
		if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
			if [ -f "$HOME/.config/AGENTS.md" ]; then
				cp "$HOME/.config/AGENTS.md" "$HOME/.config/AGENTS.md.bak"
				log_warning "Backed up existing AGENTS.md to .bak"
			fi
			execute "cp $SCRIPT_DIR/configs/amp/AGENTS.md $HOME/.config/AGENTS.md"
		fi
		log_success "Amp configs copied"
	fi

	if [ -d "$HOME/.ccs" ] || command -v ccs &>/dev/null; then
		execute "mkdir -p $HOME/.ccs"
		execute "cp $SCRIPT_DIR/configs/ccs/*.yaml $HOME/.ccs/ 2>/dev/null || true"
		execute "cp $SCRIPT_DIR/configs/ccs/*.json $HOME/.ccs/ 2>/dev/null || true"
		execute "cp $SCRIPT_DIR/configs/ccs/*.settings.json $HOME/.ccs/ 2>/dev/null || true"
		if [ -d "$SCRIPT_DIR/configs/ccs/cliproxy" ]; then
			execute "cp -r $SCRIPT_DIR/configs/ccs/cliproxy $HOME/.ccs/"
		fi
		if [ -d "$SCRIPT_DIR/configs/ccs/hooks" ]; then
			execute "cp -r $SCRIPT_DIR/configs/ccs/hooks $HOME/.ccs/"
		fi
		log_success "CCS configs copied"
	fi

	if [ -d "$HOME/.config/ai-switcher" ] || [ -f "$HOME/.config/ai-switcher/config.json" ]; then
		execute "mkdir -p $HOME/.config/ai-switcher"
		if [ -f "$SCRIPT_DIR/configs/ai-switcher/config.json" ]; then
			execute "cp $SCRIPT_DIR/configs/ai-switcher/config.json $HOME/.config/ai-switcher/"
			log_success "ai-switcher configs copied"
		else
			log_info "ai-switcher config not found in source, preserving existing"
		fi
	fi

	execute "mkdir -p $HOME/.ai-tools"
	execute "cp $SCRIPT_DIR/configs/best-practices.md $HOME/.ai-tools/"
	log_success "Best practices copied to ~/.ai-tools/"

	# Copy MEMORY.md to .ai-tools for reference
	if [ -f "$SCRIPT_DIR/MEMORY.md" ]; then
		execute "cp $SCRIPT_DIR/MEMORY.md $HOME/.ai-tools/"
		log_success "MEMORY.md copied to ~/.ai-tools/ (reference copy)"
	fi
}

enable_plugins() {
	log_info "Installing Claude Code plugins..."

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
		"map-codebase|map-codebase@my-ai-tools|$SCRIPT_DIR"
		"claude-hud|claude-hud@claude-hud|jarrodwatts/claude-hud"
		"worktrunk|worktrunk@worktrunk|max-sixty/worktrunk"
	)

	install_plugin() {
		local plugin="$1"
		if [ -t 1 ]; then
			read -p "Install $plugin? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				setup_tmpdir
				execute "claude plugin install '$plugin' && log_success '$plugin installed' || log_warning '$plugin install failed (may already be installed)'"
			fi
		else
			setup_tmpdir
			execute "claude plugin install '$plugin' 2>/dev/null || true"
		fi
	}

	install_community_plugin() {
		local name="$1"
		local plugin_spec="$2"
		local marketplace_repo="$3"

		if [ -t 1 ]; then
			read -p "Install $name? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				# Install CLI tool if needed
				case "$name" in
					plannotator)
						if ! command -v plannotator &>/dev/null; then
							log_info "Installing Plannator CLI (this may take a moment)..."
							if curl -fL https://plannotator.ai/install.sh | bash 2>&1; then
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
		else
			# Non-interactive mode - install CLI tools if needed
			case "$name" in
				plannotator)
					if ! command -v plannotator &>/dev/null; then
						log_info "Installing Plannator CLI..."
						curl -fL https://plannotator.ai/install.sh | bash 2>&1 || log_warning "Plannator installation failed"
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
			execute "claude plugin install '$plugin_spec' 2>/dev/null || true"
		fi
	}

	if command -v claude &>/dev/null; then
		# Add official plugins marketplace first
		log_info "Adding official plugins marketplace..."
		if ! execute "claude plugin marketplace add 'anthropics/claude-plugins-official' 2>/dev/null"; then
			log_info "Official plugins marketplace may already be added"
		fi

		log_info "Installing official plugins..."
		for plugin in "${official_plugins[@]}"; do
			install_plugin "$plugin"
		done

		log_info "Installing community plugins..."
		for plugin_entry in "${community_plugins[@]}"; do
			# Parse the pipe-separated entry
			local name="${plugin_entry%%|*}"
			local rest="${plugin_entry#*|}"
			local plugin_spec="${rest%%|*}"
			local marketplace_repo="${rest##*|}"
			install_community_plugin "$name" "$plugin_spec" "$marketplace_repo"
		done

		log_success "Claude Code plugins installation complete"
		log_info "⚠️  IMPORTANT: Restart Claude Code for plugins to take effect"
	else
		log_warning "Claude Code not installed - skipping plugin installation"
	fi
}

main() {
	echo "╔══════════════════════════════════════════════════════════╗"
	echo "║         AI Tools Setup                                   ║"
	echo "║   Claude Code • OpenCode • Amp • CCS • ai-switcher       ║"
	echo "╚══════════════════════════════════════════════════════════╝"
	echo

	if [ "$DRY_RUN" = true ]; then
		log_warning "DRY RUN MODE - No changes will be made"
		echo
	fi

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
