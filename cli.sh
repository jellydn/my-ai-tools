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
	else
		execute "curl -fsSL https://ampcode.com/install.sh | bash"
		log_success "Amp installed"
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

copy_configurations() {
	log_info "Copying configurations..."

	execute "mkdir -p $HOME/.claude"
	execute "cp $SCRIPT_DIR/configs/claude/settings.json $HOME/.config/claude/settings.json"
	execute "cp $SCRIPT_DIR/configs/claude/mcp-servers.json $HOME/.claude/mcp-servers.json"
	execute "cp $SCRIPT_DIR/configs/claude/CLAUDE.md $HOME/.claude/CLAUDE.md"
	execute "cp -r $SCRIPT_DIR/configs/claude/commands $HOME/.claude/"
	log_success "Claude Code configs copied"

	if [ -d "$HOME/.config/opencode" ] || command -v opencode &>/dev/null; then
		execute "mkdir -p $HOME/.config/opencode/configs"
		execute "cp $SCRIPT_DIR/configs/opencode/opencode.json $HOME/.config/opencode/"
		execute "cp -r $SCRIPT_DIR/configs/opencode/agent $HOME/.config/opencode/"
		execute "cp -r $SCRIPT_DIR/configs/opencode/command $HOME/.config/opencode/"
		execute "cp -r $SCRIPT_DIR/configs/opencode/skill $HOME/.config/opencode/"
		execute "cp $SCRIPT_DIR/configs/best-practices.md $HOME/.config/opencode/configs/"
		log_success "OpenCode configs copied"
	fi

	if [ -d "$HOME/.config/amp" ] || command -v amp &>/dev/null; then
		execute "mkdir -p $HOME/.config/amp"
		execute "cp $SCRIPT_DIR/configs/amp/settings.json $HOME/.config/amp/"
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

	execute "mkdir -p $HOME/.ai-tools"
	execute "cp $SCRIPT_DIR/configs/best-practices.md $HOME/.ai-tools/"
	log_success "Best practices copied to ~/.ai-tools/"
}

install_mcp_servers() {
	log_info "Installing MCP servers..."

	execute "npx -y @upstash/context7-mcp@latest --version"
	log_success "context7 MCP server ready"

	execute "npx -y @modelcontextprotocol/server-sequential-thinking --version"
	log_success "sequential-thinking MCP server ready"
}

enable_plugins() {
	log_info "Claude Code plugins are configured in settings.json"
	log_info "Run 'claude plugin list' to see available plugins"
	log_warning "You may need to manually install and enable some plugins"
}

main() {
	echo "╔══════════════════════════════════════════════════════════╗"
	echo "║         AI Tools Setup                                   ║"
	echo "║   Claude Code • OpenCode • Amp • CCS                     ║"
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

	install_ccs
	echo

	copy_configurations
	echo

	install_mcp_servers
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
