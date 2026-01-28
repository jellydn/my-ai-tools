#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

# Detect OS (Windows vs Unix-like)
IS_WINDOWS=false
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "$MSYSTEM" ]]; then
    IS_WINDOWS=true
fi

for arg in "$@"; do
	case $arg in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run]"
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

skill_exists_in_plugins() {
	local skill_name="$1"
	if [ -d "$SCRIPT_DIR/.claude-plugin/plugins/$skill_name" ]; then
		return 0  # exists
	fi
	return 1  # doesn't exist
}

copy_single() {
	local src="$1"
	local dest="$2"
	if [ -f "$src" ]; then
		execute "mkdir -p $(dirname '$dest')"
		execute "cp '$src' '$dest'"
		log_success "Copied: $src → $dest"
	else
		log_warning "Skipped (not found): $src"
	fi
}

copy_directory() {
	local src="$1"
	local dest="$2"
	if [ -d "$src" ]; then
		execute "mkdir -p '$dest'"
		execute "cp -r '$src'/* '$dest'/ 2>/dev/null || true"
		log_success "Copied directory: $src → $dest"
	else
		log_warning "Skipped (not found): $src"
	fi
}

generate_claude_configs() {
	log_info "Generating Claude Code configs..."

	# Copy from ~/.claude/ → configs/claude/
	if [ -d "$HOME/.claude" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/claude"
		copy_single "$HOME/.claude/mcp-servers.json" "$SCRIPT_DIR/configs/claude/mcp-servers.json"
		copy_single "$HOME/.claude/CLAUDE.md" "$SCRIPT_DIR/configs/claude/CLAUDE.md"

		if [ -d "$HOME/.claude/commands" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/claude/commands"
			execute "cp -r '$HOME/.claude/commands'/* '$SCRIPT_DIR/configs/claude/commands'/ 2>/dev/null || true"
			log_success "Copied commands directory"
		fi

		if [ -d "$HOME/.claude/agents" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/claude/agents"
			if [ "$(ls -A "$HOME/.claude/agents" 2>/dev/null)" ]; then
				if execute "cp -r '$HOME/.claude/agents'/* '$SCRIPT_DIR/configs/claude/agents'/ 2>/dev/null"; then
					log_success "Copied agents directory"
				else
					log_warning "Failed to copy agents directory"
				fi
			else
				log_warning "Claude agents directory is empty"
			fi
		fi

		if [ -d "$HOME/.claude/skills" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/claude/skills"
			# Check if skills directory has content
			if [ "$(ls -A "$HOME/.claude/skills" 2>/dev/null)" ]; then
				# Copy all skills except marketplace plugins (prd, ralph, qmd-knowledge)
				for skill_dir in "$HOME/.claude/skills"/*; do
					skill_name="$(basename "$skill_dir")"
					case "$skill_name" in
						prd|ralph|qmd-knowledge)
							# Skip marketplace plugins - managed separately
							;;
						*)
							# Check if skill already exists in .claude-plugin/plugins
							if skill_exists_in_plugins "$skill_name"; then
								log_info "Skipping $skill_name (exists in .claude-plugin/plugins)"
							elif execute "cp -r '$skill_dir' '$SCRIPT_DIR/configs/claude/skills'/ 2>/dev/null"; then
								log_success "Copied skill: $skill_name"
							fi
							;;
					esac
				done
			else
				log_warning "Claude skills directory is empty"
			fi
		fi
	fi

	# Copy settings.json from appropriate location based on OS
	if [ "$IS_WINDOWS" = true ]; then
		# Windows: Claude Code uses ~/.claude directly
		copy_single "$HOME/.claude/settings.json" "$SCRIPT_DIR/configs/claude/settings.json"
	else
		# Mac/Linux: Use ~/.claude/settings.json (canonical location)
		if [ -f "$HOME/.claude/settings.json" ]; then
			copy_single "$HOME/.claude/settings.json" "$SCRIPT_DIR/configs/claude/settings.json"
		# Fallback to XDG path for older configurations
		elif [ -d "$HOME/.config/claude" ]; then
			copy_single "$HOME/.config/claude/settings.json" "$SCRIPT_DIR/configs/claude/settings.json"
		fi
	fi

	log_success "Claude Code configs generated"
}

generate_opencode_configs() {
	log_info "Generating OpenCode configs..."

	if [ -d "$HOME/.config/opencode" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/opencode"
		copy_single "$HOME/.config/opencode/opencode.json" "$SCRIPT_DIR/configs/opencode/opencode.json"

		# Handle skill directory with plugin filtering
		if [ -d "$HOME/.config/opencode/skill" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/opencode/skill"
			if [ "$(ls -A "$HOME/.config/opencode/skill" 2>/dev/null)" ]; then
				for skill_dir in "$HOME/.config/opencode/skill"/*; do
					skill_name="$(basename "$skill_dir")"
					case "$skill_name" in
						prd|ralph|qmd-knowledge|codemap)
							# Skip marketplace plugins - managed separately
							;;
						*)
							# Check if skill already exists in .claude-plugin/plugins
							if skill_exists_in_plugins "$skill_name"; then
								log_info "Skipping $skill_name (exists in .claude-plugin/plugins)"
							elif execute "cp -r '$skill_dir' '$SCRIPT_DIR/configs/opencode/skill'/ 2>/dev/null"; then
								log_success "Copied skill: $skill_name"
							fi
							;;
					esac
				done
			fi
		fi

		# Copy other subdirectories (agent, command, configs)
		for subdir in agent command configs; do
			if [ -d "$HOME/.config/opencode/$subdir" ]; then
				execute "mkdir -p $SCRIPT_DIR/configs/opencode/$subdir"
				if [ "$(ls -A "$HOME/.config/opencode/$subdir" 2>/dev/null)" ]; then
					if execute "cp -r '$HOME/.config/opencode/$subdir'/* '$SCRIPT_DIR/configs/opencode/$subdir'/ 2>/dev/null"; then
						log_success "Copied $subdir directory"
					else
						log_warning "Failed to copy $subdir directory"
					fi
				fi
			fi
		done
		log_success "OpenCode configs generated"
	else
		log_warning "OpenCode config directory not found: $HOME/.config/opencode"
	fi
}

generate_amp_configs() {
	log_info "Generating Amp configs..."

	if [ -d "$HOME/.config/amp" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/amp"
		copy_single "$HOME/.config/amp/settings.json" "$SCRIPT_DIR/configs/amp/settings.json"

		# Copy AGENTS.md from amp config directory (preferred)
		if [ -f "$HOME/.config/amp/AGENTS.md" ]; then
			copy_single "$HOME/.config/amp/AGENTS.md" "$SCRIPT_DIR/configs/amp/AGENTS.md"
		# Fallback to global AGENTS.md if amp-specific doesn't exist
		elif [ -f "$HOME/.config/AGENTS.md" ]; then
			copy_single "$HOME/.config/AGENTS.md" "$SCRIPT_DIR/configs/amp/AGENTS.md"
		fi

		if [ -d "$HOME/.config/amp/skills" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/amp/skills"
			# Check if skills directory has content
			if [ "$(ls -A "$HOME/.config/amp/skills" 2>/dev/null)" ]; then
				# Copy all skills except marketplace plugins (prd, ralph, qmd-knowledge)
				for skill_dir in "$HOME/.config/amp/skills"/*; do
					skill_name="$(basename "$skill_dir")"
					case "$skill_name" in
						prd|ralph|qmd-knowledge)
							# Skip marketplace plugins - managed separately
							;;
						*)
							# Check if skill already exists in .claude-plugin/plugins
							if skill_exists_in_plugins "$skill_name"; then
								log_info "Skipping $skill_name (exists in .claude-plugin/plugins)"
							elif execute "cp -r '$skill_dir' '$SCRIPT_DIR/configs/amp/skills'/ 2>/dev/null"; then
								log_success "Copied skill: $skill_name"
							fi
							;;
					esac
				done
			else
				log_warning "Amp skills directory is empty"
			fi
		fi

		log_success "Amp configs generated"
	else
		log_warning "Amp config directory not found: $HOME/.config/amp"
	fi
}

generate_ccs_configs() {
	log_info "Generating CCS configs..."

	if [ -d "$HOME/.ccs" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/ccs"

		# Copy YAML config files (but skip settings.json with API keys unless explicitly requested)
		for file in "$HOME/.ccs"/*.yaml; do
			if [ -f "$file" ] && [[ ! $(basename "$file") =~ settings\.json$ ]]; then
				copy_single "$file" "$SCRIPT_DIR/configs/ccs/"
			fi
		done

		# Copy JSON config files (but skip settings.json with API keys)
		for file in "$HOME/.ccs"/*.json; do
			if [ -f "$file" ] && [[ ! $(basename "$file") =~ settings\.json$ ]]; then
				copy_single "$file" "$SCRIPT_DIR/configs/ccs/"
			fi
		done

		# Copy cliproxy directory
		if [ -d "$HOME/.ccs/cliproxy" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/ccs/cliproxy"
			if [ "$(ls -A "$HOME/.ccs/cliproxy" 2>/dev/null)" ]; then
				if execute "cp -r '$HOME/.ccs/cliproxy'/* '$SCRIPT_DIR/configs/ccs/cliproxy'/ 2>/dev/null"; then
					log_success "Copied cliproxy directory"
				else
					log_warning "Failed to copy cliproxy directory"
				fi
			fi
		fi

		# Copy hooks directory
		if [ -d "$HOME/.ccs/hooks" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/ccs/hooks"
			if [ "$(ls -A "$HOME/.ccs/hooks" 2>/dev/null)" ]; then
				if execute "cp -r '$HOME/.ccs/hooks'/* '$SCRIPT_DIR/configs/ccs/hooks'/ 2>/dev/null"; then
					log_success "Copied hooks directory"
				else
					log_warning "Failed to copy hooks directory"
				fi
			fi
		fi

		log_success "CCS configs generated (excluding sensitive settings files)"
	else
		log_warning "CCS config directory not found: $HOME/.ccs"
	fi
}

generate_best_practices() {
	log_info "Generating best-practices.md..."

	copy_single "$HOME/.ai-tools/best-practices.md" "$SCRIPT_DIR/configs/best-practices.md"
}

generate_memory_md() {
	log_info "Generating MEMORY.md..."

	# Copy from ~/.ai-tools/MEMORY.md if it exists, otherwise from current directory
	if [ -f "$HOME/.ai-tools/MEMORY.md" ]; then
		copy_single "$HOME/.ai-tools/MEMORY.md" "$SCRIPT_DIR/MEMORY.md"
	elif [ -f "$SCRIPT_DIR/MEMORY.md" ]; then
		log_success "MEMORY.md already exists in repository (skipping)"
	else
		log_warning "MEMORY.md not found in ~/.ai-tools/ or repository root"
	fi
}

generate_ai_switcher_configs() {
	log_info "Generating ai-switcher configs..."

	if [ -f "$HOME/.config/ai-switcher/config.json" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/ai-switcher"
		copy_single "$HOME/.config/ai-switcher/config.json" "$SCRIPT_DIR/configs/ai-switcher/config.json"
		log_success "ai-switcher configs generated"
	else
		log_warning "ai-switcher config not found: $HOME/.config/ai-switcher/config.json"
	fi
}

main() {
	echo "╔══════════════════════════════════════════════════════════╗"
	echo "║         Config Generator                                 ║"
	echo "║   Copy user configs TO this repository                   ║"
	echo "╚══════════════════════════════════════════════════════════╝"
	echo

	if [ "$DRY_RUN" = true ]; then
		log_warning "DRY RUN MODE - No changes will be made"
		echo
	fi

	log_info "Generating configs from user directories..."
	echo

	generate_claude_configs
	echo

	generate_opencode_configs
	echo

	generate_amp_configs
	echo

	generate_ccs_configs
	echo

	generate_best_practices
	echo

	generate_memory_md
	echo

	generate_ai_switcher_configs
	echo

	log_success "Config generation complete!"
	echo
	echo "Review changes with: git diff"
	echo "Commit changes with: git add . && git commit -m 'Update configs'"
}

main
