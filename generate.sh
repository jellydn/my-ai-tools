#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
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

skill_exists_in_plugins() {
	local skill_name="$1"
	if [ -d "$SCRIPT_DIR/skills/$skill_name" ]; then
		return 0 # exists
	fi
	return 1 # doesn't exist
}

copy_single() {
	local src="$1"
	local dest="$2"
	if [ -f "$src" ]; then
		execute "mkdir -p $(dirname "$dest")"
		execute "cp \"$src\" \"$dest\""
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

		if [ -d "$HOME/.claude/hooks" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/claude/hooks"
			if [ "$(ls -A "$HOME/.claude/hooks" 2>/dev/null)" ]; then
				if execute "cp -r '$HOME/.claude/hooks'/* '$SCRIPT_DIR/configs/claude/hooks'/ 2>/dev/null"; then
					log_success "Copied hooks directory"
				else
					log_warning "Failed to copy hooks directory"
				fi
			else
				log_warning "Claude hooks directory is empty"
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
					prd | ralph | qmd-knowledge)
						# Skip marketplace plugins - managed separately
						;;
					*)
						# Check if skill already exists in skills
						if skill_exists_in_plugins "$skill_name"; then
							log_info "Skipping $skill_name (exists in skills)"
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
		# Mac/Linux: Check for settings.json in canonical location first
		local settings_source=""
		if [ -f "$HOME/.claude/settings.json" ]; then
			settings_source="$HOME/.claude/settings.json"
		elif [ -f "$HOME/.config/claude/settings.json" ]; then
			# Fallback to XDG path for older configurations
			settings_source="$HOME/.config/claude/settings.json"
			log_warning "Using XDG config path (older configuration detected)"
		else
			log_warning "settings.json not found in ~/.claude/ or ~/.config/claude/"
		fi

		if [ -n "$settings_source" ]; then
			copy_single "$settings_source" "$SCRIPT_DIR/configs/claude/settings.json"
		fi
	fi

	log_success "Claude Code configs generated"
}

generate_opencode_configs() {
	log_info "Generating OpenCode configs..."

	if [ -d "$HOME/.config/opencode" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/opencode"
		copy_single "$HOME/.config/opencode/opencode.json" "$SCRIPT_DIR/configs/opencode/opencode.json"

		# Handle skills directory with plugin filtering
		if [ -d "$HOME/.config/opencode/skills" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/opencode/skills"
			if [ "$(ls -A "$HOME/.config/opencode/skills" 2>/dev/null)" ]; then
				for skill_dir in "$HOME/.config/opencode/skills"/*; do
					skill_name="$(basename "$skill_dir")"
					case "$skill_name" in
					prd | ralph | qmd-knowledge | codemap)
						# Skip marketplace plugins - managed separately
						;;
					*)
						# Check if skill already exists in skills
						if skill_exists_in_plugins "$skill_name"; then
							log_info "Skipping $skill_name (exists in skills)"
						elif execute "cp -r '$skill_dir' '$SCRIPT_DIR/configs/opencode/skills'/ 2>/dev/null"; then
							log_success "Copied skill: $skill_name"
						fi
						;;
					esac
				done
			fi
		fi

		# Copy other subdirectories (agent, configs) - skip command/ai (generated locally)
		for subdir in agent configs; do
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

		# Handle command directory - skip ai/ subfolder (generated from local skills)
		if [ -d "$HOME/.config/opencode/command" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/opencode/command"
			if [ "$(ls -A "$HOME/.config/opencode/command" 2>/dev/null)" ]; then
				# Copy everything except ai/ folder
				for item in "$HOME/.config/opencode/command"/*; do
					item_name=$(basename "$item")
					if [ "$item_name" != "ai" ]; then
						if execute "cp -r '$item' '$SCRIPT_DIR/configs/opencode/command'/ 2>/dev/null"; then
							log_success "Copied command: $item_name"
						fi
					else
						log_info "Skipping ai/ command folder (generated from local skills)"
					fi
				done
			fi
		fi
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
					prd | ralph | qmd-knowledge)
						# Skip marketplace plugins - managed separately
						;;
					*)
						# Check if skill already exists in skills
						if skill_exists_in_plugins "$skill_name"; then
							log_info "Skipping $skill_name (exists in skills)"
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

generate_codex_configs() {
	log_info "Generating Codex CLI configs..."

	if [ -d "$HOME/.codex" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/codex"
		copy_single "$HOME/.codex/AGENTS.md" "$SCRIPT_DIR/configs/codex/AGENTS.md"
		copy_single "$HOME/.codex/config.json" "$SCRIPT_DIR/configs/codex/config.json"
		copy_single "$HOME/.codex/config.toml" "$SCRIPT_DIR/configs/codex/config.toml"

		# Note: Codex CLI reads skills directly from skills/ and invokes them via $
		# No need to copy skills or prompts

		log_success "Codex CLI configs generated"
	else
		log_warning "Codex CLI config directory not found: $HOME/.codex"
	fi
}

generate_gemini_configs() {
	log_info "Generating Gemini CLI configs..."

	if [ -d "$HOME/.gemini" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/gemini"
		copy_single "$HOME/.gemini/AGENTS.md" "$SCRIPT_DIR/configs/gemini/AGENTS.md"
		copy_single "$HOME/.gemini/settings.json" "$SCRIPT_DIR/configs/gemini/settings.json"
		copy_single "$HOME/.gemini/GEMINI.md" "$SCRIPT_DIR/configs/gemini/GEMINI.md"

		# Copy agents directory (check both 'agents' and 'agent' for backward compat)
		for src_dir in agents agent; do
			if [ -d "$HOME/.gemini/$src_dir" ]; then
				execute "mkdir -p $SCRIPT_DIR/configs/gemini/agents"
				if [ "$(ls -A "$HOME/.gemini/$src_dir" 2>/dev/null)" ]; then
					if execute "cp -r '$HOME/.gemini/$src_dir'/* '$SCRIPT_DIR/configs/gemini/agents'/ 2>/dev/null"; then
						log_success "Gemini agents copied"
					else
						log_warning "Failed to copy some Gemini agents files"
					fi
				fi
				break
			fi
		done

		# Copy commands directory (check both 'commands' and 'command' for backward compat)
		for src_dir in commands command; do
			if [ -d "$HOME/.gemini/$src_dir" ]; then
				execute "mkdir -p $SCRIPT_DIR/configs/gemini/commands"
				if [ "$(ls -A "$HOME/.gemini/$src_dir" 2>/dev/null)" ]; then
					if execute "cp -r '$HOME/.gemini/$src_dir'/* '$SCRIPT_DIR/configs/gemini/commands'/ 2>/dev/null"; then
						log_success "Gemini commands copied"
					else
						log_warning "Failed to copy some Gemini commands files"
					fi
				fi
				break
			fi
		done

		# Copy skills from ~/.claude/skills if it exists
		if [ -d "$HOME/.claude/skills" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/gemini/skills"
			if [ "$(ls -A "$HOME/.claude/skills" 2>/dev/null)" ]; then
				for skill_dir in "$HOME/.claude/skills"/*; do
					skill_name="$(basename "$skill_dir")"
					case "$skill_name" in
					prd | ralph | qmd-knowledge | codemap)
						# Skip marketplace plugins - managed separately
						;;
					*)
						# Check if skill already exists in skills
						if skill_exists_in_plugins "$skill_name"; then
							log_info "Skipping $skill_name (exists in skills)"
						elif execute "cp -r '$skill_dir' '$SCRIPT_DIR/configs/gemini/skills'/ 2>/dev/null"; then
							log_success "Copied skill: $skill_name"
						fi
						;;
					esac
				done
			fi
		fi

		log_success "Gemini CLI configs generated"
	else
		log_warning "Gemini CLI config directory not found: $HOME/.gemini"
	fi
}

generate_kilo_configs() {
	log_info "Generating Kilo CLI configs..."

	if [ -d "$HOME/.config/kilo" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/kilo"
		copy_single "$HOME/.config/kilo/config.json" "$SCRIPT_DIR/configs/kilo/config.json"
		log_success "Kilo CLI configs generated"
	else
		log_warning "Kilo CLI config directory not found: $HOME/.config/kilo"
	fi
}

generate_pi_configs() {
	log_info "Generating Pi configs..."

	if [ -f "$HOME/.pi/agent/settings.json" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/pi"
		copy_single "$HOME/.pi/agent/settings.json" "$SCRIPT_DIR/configs/pi/settings.json"
		log_success "Pi configs generated"
	else
		log_warning "Pi settings.json not found: $HOME/.pi/agent/settings.json"
	fi

	if [ -d "$HOME/.pi/agent/themes" ]; then
		copy_directory "$HOME/.pi/agent/themes" "$SCRIPT_DIR/configs/pi/themes"
		log_success "Pi themes generated"
	else
		log_warning "Pi themes directory not found: $HOME/.pi/agent/themes"
	fi
}

generate_copilot_configs() {
	log_info "Generating GitHub Copilot CLI configs..."

	if [ -f "$HOME/.copilot/copilot-instructions.md" ] || [ -f "$HOME/.copilot/mcp-config.json" ]; then
		execute "mkdir -p \"$SCRIPT_DIR/configs/copilot\""
		if [ -f "$HOME/.copilot/copilot-instructions.md" ]; then
			copy_single "$HOME/.copilot/copilot-instructions.md" "$SCRIPT_DIR/configs/copilot/AGENTS.md"
		else
			log_warning "GitHub Copilot CLI instructions not found: $HOME/.copilot/copilot-instructions.md"
		fi
		if [ -f "$HOME/.copilot/mcp-config.json" ]; then
			copy_single "$HOME/.copilot/mcp-config.json" "$SCRIPT_DIR/configs/copilot/mcp-config.json"
		else
			log_warning "GitHub Copilot MCP config not found: $HOME/.copilot/mcp-config.json"
		fi
		log_success "GitHub Copilot CLI configs generated"
	else
		log_warning "GitHub Copilot CLI configs not found in: $HOME/.copilot"
	fi
}

generate_cursor_configs() {
	log_info "Generating Cursor Agent CLI configs..."

	if [ -f "$HOME/.cursor/rules/general.mdc" ]; then
		execute "mkdir -p \"$SCRIPT_DIR/configs/cursor\""
		copy_single "$HOME/.cursor/rules/general.mdc" "$SCRIPT_DIR/configs/cursor/AGENTS.md"
		log_success "Cursor Agent CLI configs generated"
	else
		log_warning "Cursor Agent CLI rules not found: $HOME/.cursor/rules/general.mdc"
	fi

	# Copy mcp.json for Cursor MCP server configuration
	if [ -f "$HOME/.cursor/mcp.json" ]; then
		execute "mkdir -p \"$SCRIPT_DIR/configs/cursor\""
		copy_single "$HOME/.cursor/mcp.json" "$SCRIPT_DIR/configs/cursor/mcp.json"
		log_success "Cursor MCP config generated"
	else
		log_warning "Cursor MCP config not found: $HOME/.cursor/mcp.json"
	fi

	# Copy skills from ~/.cursor/skills if it exists
	if [ -d "$HOME/.cursor/skills" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/cursor/skills"
		if [ "$(ls -A "$HOME/.cursor/skills" 2>/dev/null)" ]; then
			for skill_dir in "$HOME/.cursor/skills"/*; do
				skill_name="$(basename "$skill_dir")"
				case "$skill_name" in
				prd | ralph | qmd-knowledge | codemap)
					# Skip marketplace plugins - managed separately
					;;
				*)
					# Check if skill already exists in skills
					if skill_exists_in_plugins "$skill_name"; then
						log_info "Skipping $skill_name (exists in skills)"
					elif execute "cp -r '$skill_dir' '$SCRIPT_DIR/configs/cursor/skills'/ 2>/dev/null"; then
						log_success "Copied skill: $skill_name"
					fi
					;;
				esac
			done
		fi
		log_success "Cursor skills generated"
	else
		log_warning "Cursor skills directory not found: $HOME/.cursor/skills"
	fi

	# Copy commands from ~/.cursor/commands if it exists
	if [ -d "$HOME/.cursor/commands" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/cursor/commands"
		if [ "$(ls -A "$HOME/.cursor/commands" 2>/dev/null)" ]; then
			if execute "cp -r '$HOME/.cursor/commands'/* '$SCRIPT_DIR/configs/cursor/commands'/ 2>/dev/null"; then
				log_success "Cursor commands generated"
			else
				log_warning "Failed to copy some Cursor commands"
			fi
		else
			log_warning "Cursor commands directory is empty"
		fi
	else
		log_warning "Cursor commands directory not found: $HOME/.cursor/commands"
	fi
}

generate_factory_configs() {
	log_info "Generating Factory Droid configs..."

	if [ -d "$HOME/.factory" ] || command -v droid &>/dev/null; then
		execute "mkdir -p \"$SCRIPT_DIR/configs/factory\""
		if [ -f "$HOME/.factory/AGENTS.md" ]; then
			copy_single "$HOME/.factory/AGENTS.md" "$SCRIPT_DIR/configs/factory/AGENTS.md"
		else
			log_warning "Factory Droid AGENTS.md not found: $HOME/.factory/AGENTS.md"
		fi
		if [ -d "$HOME/.factory/droids" ] && find "$HOME/.factory/droids" -maxdepth 1 -type f -name '*.md' | grep -q .; then
			execute "mkdir -p \"$SCRIPT_DIR/configs/factory/droids\""
			for droid_file in "$HOME/.factory/droids"/*.md; do
				if [ -f "$droid_file" ]; then
					droid_name="$(basename "$droid_file")"
					copy_single "$droid_file" "$SCRIPT_DIR/configs/factory/droids/$droid_name"
				fi
			done
		else
			log_warning "Factory Droid droids directory not found or empty: $HOME/.factory/droids"
		fi
		# Export mcp.json and settings.json
		if [ -f "$HOME/.factory/mcp.json" ]; then
			copy_single "$HOME/.factory/mcp.json" "$SCRIPT_DIR/configs/factory/mcp.json"
		fi
		if [ -f "$HOME/.factory/settings.json" ]; then
			copy_single "$HOME/.factory/settings.json" "$SCRIPT_DIR/configs/factory/settings.json"
		fi
		log_success "Factory Droid configs generated"
	else
		log_warning "Factory Droid not found (install with: npm install -g @factory/cli)"
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

generate_ai_launcher_configs() {
	log_info "Generating ai-launcher configs..."

	if [ -f "$HOME/.config/ai-launcher/config.json" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/ai-launcher"
		copy_single "$HOME/.config/ai-launcher/config.json" "$SCRIPT_DIR/configs/ai-launcher/config.json"
		log_success "ai-launcher configs generated"
	else
		log_warning "ai-launcher config not found: $HOME/.config/ai-launcher/config.json"
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

	generate_codex_configs
	echo

	generate_gemini_configs
	echo

	generate_kilo_configs
	echo

	generate_pi_configs
	echo

	generate_copilot_configs
	echo

	generate_cursor_configs
	echo

	generate_factory_configs
	echo

	generate_best_practices
	echo

	generate_memory_md
	echo

	generate_ai_launcher_configs
	echo

	log_success "Config generation complete!"
	echo
	echo "Review changes with: git diff"
	echo "Commit changes with: git add . && git commit -m 'Update configs'"
}

main
