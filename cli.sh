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

check_prerequisites() {
	log_info "Checking prerequisites..."

	if ! command -v git &>/dev/null; then
		log_error "Git is not installed. Please install git first."
		exit 1
	fi
	log_success "Git found"

	if command -v bun &>/dev/null; then
		log_success "Bun found ($(bun --version))"
	elif command -v node &>/dev/null; then
		log_success "Node.js found ($(node --version))"
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
		# Mac/Linux: Use XDG path for settings.json
		execute "mkdir -p $HOME/.config/claude"
		execute "cp $SCRIPT_DIR/configs/claude/settings.json $HOME/.config/claude/settings.json"
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
		execute "rm -rf $HOME/.claude/skills"
		execute "cp -r $SCRIPT_DIR/configs/claude/skills $HOME/.claude/"
	fi

	# Add MCP servers using Claude Code CLI (globally, available in all projects)
	if command -v claude &>/dev/null; then
		log_info "Setting up Claude Code MCP servers (global scope)..."

		# context7 MCP server
		if [ -t 1 ]; then
			read -p "Install context7 MCP server (documentation lookup)? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				execute "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null && log_success 'context7 MCP server added (global)' || log_warning 'context7 already installed or failed'"
			fi
		else
			execute "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null || true"
		fi

		# sequential-thinking MCP server
		if [ -t 1 ]; then
			read -p "Install sequential-thinking MCP server (multi-step reasoning)? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				execute "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking 2>/dev/null && log_success 'sequential-thinking MCP server added (global)' || log_warning 'sequential-thinking already installed or failed'"
			fi
		else
			execute "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking 2>/dev/null || true"
		fi

		# qmd MCP server
		if [ -t 1 ]; then
			read -p "Install qmd MCP server (knowledge management)? (y/n) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				execute "claude mcp add --scope user --transport stdio qmd -- qmd mcp 2>/dev/null && log_success 'qmd MCP server added (global)' || log_warning 'qmd already installed or failed'"
			fi
		else
			execute "claude mcp add --scope user --transport stdio qmd -- qmd mcp 2>/dev/null || true"
		fi

		log_success "MCP server setup complete (global scope)"
	fi

	log_success "Claude Code configs copied"

	if [ -d "$HOME/.config/opencode" ] || command -v opencode &>/dev/null; then
		execute "cp $SCRIPT_DIR/configs/opencode/opencode.json $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/agent"
		execute "cp -r $SCRIPT_DIR/configs/opencode/agent $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/command"
		execute "cp -r $SCRIPT_DIR/configs/opencode/command $HOME/.config/opencode/"
		execute "rm -rf $HOME/.config/opencode/skill"
		execute "cp -r $SCRIPT_DIR/configs/opencode/skill $HOME/.config/opencode/"
		log_success "OpenCode configs copied"
	fi

	if [ -d "$HOME/.config/amp" ] || command -v amp &>/dev/null; then
		execute "mkdir -p $HOME/.config/amp"
		execute "cp $SCRIPT_DIR/configs/amp/settings.json $HOME/.config/amp/"
		if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
			execute "cp $SCRIPT_DIR/configs/amp/AGENTS.md $HOME/.config/amp/"
		fi
		if [ -d "$SCRIPT_DIR/configs/amp/skills" ]; then
			execute "rm -rf $HOME/.config/amp/skills"
			execute "cp -r $SCRIPT_DIR/configs/amp/skills $HOME/.config/amp/"
		fi
		# Also copy AGENTS.md to global config location
		if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
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

	# Copy MEMORY.md to project root and .ai-tools for reference
	if [ -f "$SCRIPT_DIR/MEMORY.md" ]; then
		execute "cp $SCRIPT_DIR/MEMORY.md $HOME/.ai-tools/"
		log_success "MEMORY.md copied to ~/.ai-tools/ (reference copy)"
	fi
}

enable_plugins() {
	log_info "Claude Code plugins are configured in settings.json"
	log_info "Run 'claude plugin marketplace list' to see configured marketplaces"
	log_info "Run 'claude plugin install <plugin>' to install plugins from marketplaces"
	log_warning "You may need to manually install and enable some plugins"
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
