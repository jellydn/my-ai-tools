#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
BACKUP_DIR="$HOME/ai-tools-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
BACKUP=false
PROMPT_BACKUP=true
YES_TO_ALL=false
VERBOSE=false

# Track whether Amp is installed (for backlog.md dependency)
AMP_INSTALLED=false

# Parse command-line arguments first
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
	--rollback)
		log_info "Rolling back last transaction..."
		rollback_transaction
		exit $?
		;;
	*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run] [--backup] [--no-backup] [--yes|-y] [-v|--verbose] [--rollback]"
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

handle_optional_bun_installation() {
	if command -v bun &>/dev/null; then
		return 0
	fi

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing Bun (--yes flag)..."
		install_bun_now
	elif [ -t 0 ]; then
		if prompt_yn "Bun is not installed. Install it now"; then
			install_bun_now
		else
			log_warning "Continuing with Node.js only. Some scripts prefer Bun."
		fi
	else
		log_warning "Bun is not installed. Continuing with Node.js only."
	fi
}

handle_bun_installation() {
	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing Bun (--yes flag)..."
		install_bun_now
	elif [ -t 0 ]; then
		if prompt_yn "Would you like to install Bun now"; then
			install_bun_now
		else
			log_error "Please install Bun or Node.js first."
			exit 1
		fi
	else
		log_error "Please install Bun or Node.js first."
		exit 1
	fi
}

handle_qmd_installation_if_needed() {
	if command -v qmd &>/dev/null; then
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd found ($qmd_version)"
		return 0
	fi

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing qmd (--yes flag)..."
		if ! install_qmd_now; then
			log_warning "Continuing without qmd. Knowledge features will remain unavailable until qmd is installed."
		fi
	elif [ -t 0 ]; then
		if prompt_yn "qmd is not installed. Install it now"; then
			if ! install_qmd_now; then
				log_warning "Continuing without qmd. Knowledge features will remain unavailable until qmd is installed."
			fi
		else
			log_warning "qmd not installed. Knowledge features will be unavailable until you install it."
		fi
	else
		log_warning "qmd not installed. Knowledge features will be unavailable until you install it."
	fi
}

install_qmd_now() {
	if command -v qmd &>/dev/null; then
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd already installed ($qmd_version)"
		return 0
	fi

	if ! command -v bun &>/dev/null; then
		log_info "qmd requires Bun. Installing Bun first..."
		handle_bun_installation
	fi

	if ! command -v bun &>/dev/null; then
		log_error "Cannot install qmd because Bun is still unavailable"
		return 1
	fi

	log_info "Installing qmd CLI via bun..."
	if execute "bun install -g @tobilu/qmd"; then
		# Ensure bun's global bin directory is in PATH for the current session
		local bun_global_bin
		bun_global_bin="$(bun pm bin -g 2>/dev/null)"
		if [ -n "$bun_global_bin" ] && [[ ":$PATH:" != *":$bun_global_bin:"* ]]; then
			export PATH="$bun_global_bin:$PATH"
		fi
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd installed successfully ($qmd_version)"
		return 0
	fi

	if command -v npm &>/dev/null; then
		log_warning "Bun failed to install qmd. Retrying with npm..."
		if execute "npm install -g @tobilu/qmd"; then
			local qmd_version
			qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
			log_success "qmd installed successfully ($qmd_version)"
			return 0
		fi
	fi

	log_error "Failed to install qmd"
	return 1
}

resolve_installer_checksum() {
	local installer="$1"
	local checksum_url=""

	case "$installer" in
	bun)
		checksum_url="${BUN_INSTALL_SHA256_URL:-}"
		;;
	rust)
		checksum_url="${RUSTUP_INIT_SHA256_URL:-}"
		;;
	plannotator)
		checksum_url="${PLANNOTATOR_INSTALL_SHA256_URL:-}"
		;;
	esac

	if [ -z "$checksum_url" ]; then
		log_warning "No checksum URL configured for ${installer} installer"
		echo ""
		return 0
	fi

	local checksum
	checksum=$(curl -fsSL "$checksum_url" 2>/dev/null | head -n1 | awk '{print $1}')

	if [ -z "$checksum" ]; then
		log_warning "Could not fetch checksum for ${installer} installer"
	fi

	echo "$checksum"
}

install_bun_now() {
	log_info "Installing Bun..."

	local bun_checksum
	bun_checksum=$(resolve_installer_checksum "bun")
	if execute_installer "https://bun.sh/install" "$bun_checksum" "Bun"; then
		# Source shell profiles to get Bun environment
		[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
		[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" 2>/dev/null || true

		# Fallback to default Bun location
		if [ -z "$BUN_INSTALL" ]; then
			export BUN_INSTALL="$HOME/.bun"
		fi
		export PATH="$BUN_INSTALL/bin:$PATH"

		if command -v bun &>/dev/null; then
			BUN_VERSION=$(bun --version)
			log_success "Bun installed successfully ($BUN_VERSION)"
		else
			log_error "Bun installation completed but 'bun' command not found in PATH"
			exit 1
		fi
	else
		log_error "Failed to install Bun"
		exit 1
	fi
}

install_global_tools() {
	log_info "Checking global tools for PostToolUse hooks..."

	install_jq_if_needed
	install_biome_if_needed
	check_gofmt
	install_ruff_if_needed
	install_rustfmt_if_needed
	install_shfmt_if_needed
	install_stylua_if_needed
	install_backlog_if_needed

	log_success "Global tools check complete"
}

install_jq_if_needed() {
	if command -v jq &>/dev/null; then
		log_success "jq found"
		return 0
	fi

	log_warning "jq not found. Installing jq..."
	local jq_installed=false

	if [ "$IS_WINDOWS" = true ]; then
		if command -v choco &>/dev/null; then
			execute "choco install jq -y" && jq_installed=true
		elif command -v winget &>/dev/null; then
			# Use correct package ID with exact match flag
			execute "winget install -e --id jqlang.jq --accept-package-agreements --accept-source-agreements" && jq_installed=true
		fi

		# After winget install, refresh PATH in current session
		if [ "$jq_installed" = true ]; then
			# winget adds to PATH but current shell doesn't know about it
			# Try common jq installation locations
			local jq_path=""
			if [ -f "$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe/jq.exe" ]; then
				jq_path="$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe"
			elif [ -f "$PROGRAMFILES/jq/jq.exe" ]; then
				jq_path="$PROGRAMFILES/jq"
			elif [ -f "$PROGRAMFILES/WinGet/Links/jq.exe" ]; then
				jq_path="$PROGRAMFILES/WinGet/Links"
			fi

			if [ -n "$jq_path" ]; then
				export PATH="$jq_path:$PATH"
				log_info "Added jq to PATH: $jq_path"
			fi

			# Verify jq is now available
			if ! command -v jq &>/dev/null; then
				log_warning "jq installed but not found in PATH. Please restart your terminal."
				jq_installed=false
			fi
		fi
	else
		if command -v brew &>/dev/null; then
			execute "brew install jq" && jq_installed=true
		elif command -v apt-get &>/dev/null; then
			if ([ "$YES_TO_ALL" = true ] && sudo -n true 2>/dev/null) || ([ "$YES_TO_ALL" = false ] && [ -t 0 ]); then
				execute "sudo apt-get install -y jq" && jq_installed=true
			else
				log_warning "Cannot install jq non-interactively (requires sudo with password)"
			fi
		fi
	fi

	if [ "$jq_installed" = false ]; then
		log_warning "Please install jq manually: https://jqlang.github.io/jq/download/"
		if [ "$IS_WINDOWS" = true ]; then
			log_info "Windows installation options:"
			log_info "  - winget: winget install -e --id jqlang.jq"
			log_info "  - chocolatey: choco install jq"
			log_info "  - Scoop: scoop install jq"
			log_info "  - GitHub: https://github.com/jqlang/jq/releases"
		fi
	fi
}

install_biome_if_needed() {
	if command -v biome &>/dev/null; then
		log_success "biome found"
		return 0
	fi

	log_warning "biome not found. Installing biome globally..."
	if execute "npm install -g @biomejs/biome"; then
		log_success "biome installed"
	else
		log_warning "Failed to install biome"
	fi
}

check_gofmt() {
	if command -v gofmt &>/dev/null; then
		log_success "gofmt found"
		return 0
	fi

	log_warning "gofmt not found. Go is not installed."
	if [ "$IS_WINDOWS" = true ]; then
		if command -v choco &>/dev/null; then
			log_info "Install Go with: choco install golang -y"
		elif command -v winget &>/dev/null; then
			log_info "Install Go with: winget install GoLang.Go"
		else
			log_info "Please install Go manually: https://golang.org/dl/"
		fi
	else
		if command -v brew &>/dev/null; then
			log_info "Install Go with: brew install go"
		elif command -v apt-get &>/dev/null; then
			log_info "Install Go with: sudo apt-get install -y golang"
		else
			log_info "Please install Go manually: https://golang.org/dl/"
		fi
	fi
}

install_ruff_if_needed() {
	if command -v ruff &>/dev/null; then
		log_success "ruff found"
		return 0
	fi

	log_warning "ruff not found. Installing ruff..."
	if command -v mise &>/dev/null; then
		execute "mise use -g ruff@latest"
	elif command -v pipx &>/dev/null; then
		execute "pipx install ruff"
	elif command -v pip3 &>/dev/null; then
		execute "pip3 install ruff"
	elif command -v pip &>/dev/null; then
		execute "pip install ruff"
	else
		log_warning "No Python package manager found. Install ruff manually: https://docs.astral.sh/ruff/installation/"
	fi
}

install_rustfmt_if_needed() {
	if command -v rustfmt &>/dev/null; then
		log_success "rustfmt found"
		return 0
	fi

	log_warning "rustfmt not found. Installing Rust..."
	if command -v mise &>/dev/null; then
		execute "mise use -g rust@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install rust"
	else
		local rust_checksum
		rust_checksum=$(resolve_installer_checksum "rust")
		execute_installer "https://sh.rustup.rs" "$rust_checksum" "Rust" "-y"
	fi
}

install_shfmt_if_needed() {
	if command -v shfmt &>/dev/null; then
		log_success "shfmt found"
		return 0
	fi

	log_warning "shfmt not found. Installing shfmt..."
	if command -v mise &>/dev/null; then
		execute "mise use -g shfmt@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install shfmt"
	elif command -v go &>/dev/null; then
		execute "go install mvdan.cc/sh/v3/cmd/shfmt@latest"
	else
		log_warning "No package manager found for shfmt. Install manually: https://github.com/mvdan/sh"
	fi
}

install_stylua_if_needed() {
	if command -v stylua &>/dev/null; then
		log_success "stylua found"
		return 0
	fi

	log_warning "stylua not found. Installing stylua..."
	if command -v mise &>/dev/null; then
		execute "mise use -g stylua@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install stylua"
	elif command -v cargo &>/dev/null; then
		execute "cargo install stylua"
	else
		log_warning "No package manager found for stylua. Install manually: https://github.com/JohnnyMorganz/StyLua"
	fi
}

install_backlog_if_needed() {
	if [ "$AMP_INSTALLED" = false ]; then
		return 0
	fi

	if command -v backlog &>/dev/null; then
		log_success "backlog.md found"
	else
		log_info "Installing backlog.md for Amp integration..."
		execute "npm install -g backlog.md"
	fi
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
	done < <(find "$source_dir" -type d \( $prune_expr \) -prune -o -type f -print 2>/dev/null)

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
# Usage: copy_config_file "source_file" "dest_dir"
copy_config_file() {
	local source_file="$1"
	local dest_dir="$2"

	if [ -f "$source_file" ]; then
		execute_quoted mkdir -p "$dest_dir"
		execute_quoted cp "$source_file" "$dest_dir/"
		return 0
	fi
	return 1
}

# Helper: Ensure a CLI tool is installed, prompting if interactive
# Usage: ensure_cli_tool "tool_name" "install_cmd" "version_cmd"
ensure_cli_tool() {
	local name="$1"
	local install_cmd="$2"
	local version_cmd="${3:-}"

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
		copy_config_file "$HOME/.config/ai-launcher/config.json" "$BACKUP_DIR/ai-launcher" || true

		log_success "Backup completed: $BACKUP_DIR"
	fi
}

install_claude_code() {
	log_info "Installing Claude Code..."

	if ! command -v claude &>/dev/null; then
		if execute "npm install -g @anthropic-ai/claude-code"; then
			log_success "Claude Code installed"
		else
			log_error "Failed to install Claude Code"
		fi
		return
	fi

	log_warning "Claude Code is already installed ($(claude --version))"

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-skipping reinstall (--yes flag)"
		return
	elif [ -t 0 ]; then
		if ! prompt_yn "Do you want to reinstall"; then
			return
		fi
	else
		log_info "Skipping reinstall in non-interactive mode"
		return
	fi

	if execute "npm install -g @anthropic-ai/claude-code"; then
		log_success "Claude Code reinstalled"
	else
		log_error "Failed to reinstall Claude Code"
	fi
}

install_opencode() {
	_run_opencode_install() {
		if command -v opencode &>/dev/null; then
			log_warning "OpenCode is already installed"
		else
			execute_installer "https://opencode.ai/install" "" "OpenCode"
			log_success "OpenCode installed"
		fi
	}
	run_installer "OpenCode" "_run_opencode_install" "command -v opencode" ""
}

install_amp() {
	_run_amp_install() {
		if command -v amp &>/dev/null; then
			log_warning "Amp is already installed"
		else
			execute_installer "https://ampcode.com/install.sh" "" "Amp"
		fi
		AMP_INSTALLED=true
		log_success "Amp installed"
	}
	run_installer "Amp" "_run_amp_install" "command -v amp" ""
}

install_ccs() {
	_run_ccs_install() {
		if command -v ccs &>/dev/null; then
			log_warning "CCS is already installed ($(ccs --version))"
		else
			execute "npm install -g @kaitranntt/ccs"
			log_success "CCS installed"
		fi
	}
	run_installer "CCS" "_run_ccs_install" "command -v ccs" "ccs --version"
}

install_ai_switcher() {
	_run_ai_switcher_install() {
		if command -v ai &>/dev/null; then
			log_warning "AI Launcher is already installed"
		else
			execute_installer "https://raw.githubusercontent.com/jellydn/ai-launcher/main/install.sh" "" "AI Launcher"
			log_success "AI Launcher installed"
		fi
	}
	run_installer "AI Launcher" "_run_ai_switcher_install" "command -v ai" "ai --version"
}

install_codex() {
	_run_codex_install() {
		if command -v codex &>/dev/null; then
			log_warning "Codex CLI is already installed"
		else
			execute "npm install -g @openai/codex"
			log_success "Codex CLI installed"
		fi
	}
	run_installer "OpenAI Codex CLI" "_run_codex_install" "command -v codex" ""
}

install_gemini() {
	_run_gemini_install() {
		if command -v gemini &>/dev/null; then
			log_warning "Gemini CLI is already installed"
		else
			execute "npm install -g @google/gemini-cli"
			log_success "Gemini CLI installed"
		fi
	}
	run_installer "Google Gemini CLI" "_run_gemini_install" "command -v gemini" ""
}

install_kilo() {
	_run_kilo_install() {
		if command -v kilo &>/dev/null; then
			log_warning "Kilo CLI is already installed"
		else
			execute "npm install -g @kilocode/cli"
			log_success "Kilo CLI installed"
		fi
	}
	run_installer "Kilo CLI" "_run_kilo_install" "command -v kilo" ""
}

install_pi() {
	_run_pi_install() {
		if command -v pi &>/dev/null; then
			log_warning "Pi is already installed"
		else
			execute "npm install -g @mariozechner/pi-coding-agent"
			log_success "Pi installed"
		fi
	}
	run_installer "Pi" "_run_pi_install" "command -v pi" ""
}

install_copilot() {
	prompt_and_install() {
		log_info "Installing GitHub Copilot CLI..."
		if command -v copilot &>/dev/null; then
			log_warning "GitHub Copilot CLI is already installed"
		else
			execute "npm install -g @github/copilot"
			log_success "GitHub Copilot CLI installed"
		fi
	}

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting GitHub Copilot CLI installation (--yes flag)"
		prompt_and_install
	elif [ -t 0 ]; then
		if prompt_yn "Do you want to install GitHub Copilot CLI"; then
			prompt_and_install
		else
			log_warning "Skipping GitHub Copilot CLI installation"
		fi
	else
		log_info "Installing GitHub Copilot CLI (non-interactive mode)..."
		prompt_and_install
	fi
}

install_cursor() {
	log_info "Checking Cursor CLI..."
	if command -v agent &>/dev/null; then
		local agent_version
		agent_version=$(agent --version 2>/dev/null || echo 'version unknown')
		log_success "Cursor Agent CLI found ($agent_version)"
	else
		log_warning "Cursor Agent CLI is not installed"
		if [ "$YES_TO_ALL" = true ]; then
			log_info "Auto-installing Cursor Agent CLI (--yes flag)..."
			if execute "curl https://cursor.com/install -fsS | bash"; then
				log_success "Cursor Agent CLI installed"
			else
				log_warning "Cursor Agent CLI installation failed"
			fi
		elif [ -t 0 ]; then
			if prompt_yn "Install Cursor Agent CLI"; then
				if execute "curl https://cursor.com/install -fsS | bash"; then
					log_success "Cursor Agent CLI installed"
				else
					log_warning "Cursor Agent CLI installation failed"
				fi
			else
				log_info "Skipping Cursor Agent CLI installation"
			fi
		else
			log_info "Skipping Cursor Agent CLI installation (non-interactive mode, use --yes to auto-install)"
		fi
	fi
}

install_factory() {
	_run_factory_install() {
		execute "npm install -g @factory/cli"
		log_success "Factory Droid CLI installed"
	}
	run_installer "Factory Droid" "_run_factory_install" "command -v droid" ""
}

# Helper: Copy non-marketplace skills from source to destination
# Usage: copy_non_marketplace_skills "source_dir" "dest_dir"
copy_non_marketplace_skills() {
	local source_dir="$1"
	local dest_dir="$2"

	if [ ! -d "$source_dir" ] || [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		return 0
	fi

	execute_quoted rm -rf "$dest_dir"
	execute_quoted mkdir -p "$dest_dir"

	for skill_dir in "$source_dir"/*; do
		if [ ! -d "$skill_dir" ]; then
			continue
		fi

		local skill_name
		skill_name="$(basename "$skill_dir")"

		case "$skill_name" in
		prd | ralph | qmd-knowledge | codemap)
			# Skip marketplace plugins
			;;
		*)
			safe_copy_dir "$skill_dir" "$dest_dir/$skill_name"
			;;
		esac
	done
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

copy_configurations() {
	log_info "Copying configurations..."

	validate_all_configs

	copy_claude_configs
	copy_opencode_configs
	copy_amp_configs
	copy_ai_launcher_configs
	copy_codex_configs
	copy_gemini_configs
	copy_kilo_configs
	copy_pi_configs
	copy_copilot_configs
	copy_cursor_configs
	copy_factory_configs
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
		"$SCRIPT_DIR/configs/kilo/config.json" \
		"$SCRIPT_DIR/configs/pi/settings.json" \
		"$SCRIPT_DIR/configs/factory/settings.json"; do
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

setup_claude_mcp_servers() {
	if ! command -v claude &>/dev/null; then
		return 0
	fi

	log_info "Setting up Claude Code MCP servers (global scope)..."
	install_mcp_interactive "context7" "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest" "documentation lookup"
	install_mcp_interactive "sequential-thinking" "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking" "multi-step reasoning"

	handle_qmd_installation_if_needed
	if command -v qmd &>/dev/null; then
		install_mcp_interactive "qmd" "claude mcp add --scope user --transport stdio qmd -- qmd mcp" "knowledge management"
	else
		log_warning "qmd not found. MCP setup skipped. Install with: bun install -g @tobilu/qmd"
	fi

	log_success "MCP server setup complete (global scope)"
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

	execute_quoted rm -rf "$HOME/.config/opencode/skills"
	copy_non_marketplace_skills "$SCRIPT_DIR/skills" "$HOME/.config/opencode/skills"

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

	copy_non_marketplace_skills "$SCRIPT_DIR/configs/amp/skills" "$HOME/.config/amp/skills"

	if [ -f "$SCRIPT_DIR/configs/amp/AGENTS.md" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/amp/AGENTS.md" "$HOME/.config/amp/"
		if [ -f "$HOME/.config/AGENTS.md" ]; then
			execute_quoted cp "$HOME/.config/AGENTS.md" "$HOME/.config/AGENTS.md.bak"
			log_warning "Backed up existing AGENTS.md to .bak"
		fi
		execute_quoted cp "$SCRIPT_DIR/configs/amp/AGENTS.md" "$HOME/.config/AGENTS.md"
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

	if [ -f "$SCRIPT_DIR/configs/codex/config.toml" ]; then
		if [ -f "$HOME/.codex/config.toml" ]; then
			execute_quoted cp "$HOME/.codex/config.toml" "$HOME/.codex/config.toml.bak"
			log_success "Backed up existing config.toml to config.toml.bak"
		fi
		execute_quoted cp "$SCRIPT_DIR/configs/codex/config.toml" "$HOME/.codex/"
	fi

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
	execute_quoted mkdir -p "$HOME/.gemini"

	copy_config_file "$SCRIPT_DIR/configs/gemini/AGENTS.md" "$HOME/.gemini/" || true
	copy_config_file "$SCRIPT_DIR/configs/gemini/GEMINI.md" "$HOME/.gemini/" || true
	copy_config_file "$SCRIPT_DIR/configs/gemini/settings.json" "$HOME/.gemini/" || true

	execute_quoted rm -rf "$HOME/.gemini/agents"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/agents" "$HOME/.gemini/agents"

	execute_quoted rm -rf "$HOME/.gemini/commands"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/commands" "$HOME/.gemini/commands"

	execute_quoted rm -rf "$HOME/.gemini/skills"
	copy_non_marketplace_skills "$SCRIPT_DIR/configs/gemini/skills" "$HOME/.gemini/skills"

	log_success "Gemini CLI configs copied"
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

	copy_non_marketplace_skills "$SCRIPT_DIR/configs/pi/skills" "$HOME/.pi/agent/skills"

	log_success "Pi configs copied"
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

	execute_quoted rm -rf "$HOME/.cursor/skills"
	copy_non_marketplace_skills "$SCRIPT_DIR/configs/cursor/skills" "$HOME/.cursor/skills"

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

	if [ -d "$SCRIPT_DIR/configs/factory/droids" ] && [ -n "$(ls -A "$SCRIPT_DIR/configs/factory/droids" 2>/dev/null)" ]; then
		safe_copy_dir "$SCRIPT_DIR/configs/factory/droids" "$HOME/.factory/droids"
	fi

	log_success "Factory Droid configs copied"
}

copy_best_practices() {
	execute_quoted mkdir -p "$HOME/.ai-tools"
	execute_quoted cp "$SCRIPT_DIR/configs/best-practices.md" "$HOME/.ai-tools/"
	log_success "Best practices copied to ~/.ai-tools/"
	execute_quoted cp "$SCRIPT_DIR/configs/git-guidelines.md" "$HOME/.ai-tools/"
	log_success "Git guidelines copied to ~/.ai-tools/"

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

# Helper: Install remote skills using npx skills add
install_remote_skills() {
	log_info "Installing community skills from jellydn/my-ai-tools repository..."

	if ! command -v npx &>/dev/null; then
		log_error "npx not found. Please install Node.js to use remote skill installation."
		install_local_skills
		return 0
	fi

	if [ "${YES_TO_ALL:-false}" = "true" ] || [ ! -t 0 ]; then
		execute "npx skills add jellydn/my-ai-tools --yes --global --agent claude-code"
	else
		execute "npx skills add jellydn/my-ai-tools --global --agent claude-code"
	fi
	log_success "Remote skills installed successfully"
}

# Helper: Install recommended community skills from recommend-skills.json
install_recommended_skills() {
	log_info "Checking for recommended community skills..."

	if ! command -v npx &>/dev/null; then
		log_warning "npx not found, skipping recommended skills"
		return 0
	fi

	if [ ! -f "$SCRIPT_DIR/configs/recommend-skills.json" ]; then
		log_info "No recommended skills config found, skipping"
		return 0
	fi

	local skills_json
	skills_json=$(cat "$SCRIPT_DIR/configs/recommend-skills.json")
	local skill_count
	skill_count=$(echo "$skills_json" | jq '.recommended_skills | length')

	if [ "$skill_count" -eq 0 ] || [ "$skill_count" = "null" ]; then
		log_info "No recommended skills found in config"
		return 0
	fi

	log_info "Found $skill_count recommended skill(s)"

	for i in $(seq 0 $((skill_count - 1))); do
		local repo description skill skill_suffix
		repo=$(echo "$skills_json" | jq -r ".recommended_skills[$i].repo")
		description=$(echo "$skills_json" | jq -r ".recommended_skills[$i].description")
		skill=$(echo "$skills_json" | jq -r ".recommended_skills[$i].skill // empty")
		skill_suffix=""
		[ -n "$skill" ] && skill_suffix="/$skill"

		log_info "  - $repo${skill_suffix}: $description"
		install_single_recommended_skill "$repo" "$skill" "$skill_suffix"
	done

	log_success "Recommended skills check complete"
}

install_single_recommended_skill() {
	local repo="$1"
	local skill="$2"
	local skill_suffix="$3"

	if [ "$YES_TO_ALL" = true ] || [ ! -t 0 ]; then
		if [ -n "$skill" ]; then
			execute "npx skills add '$repo' --skill '$skill' --yes --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo${skill_suffix}" || log_info "Skipped: $repo${skill_suffix}"
		else
			execute "npx skills add '$repo' --yes --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo" || log_info "Skipped: $repo"
		fi
	elif [ -t 0 ]; then
		if prompt_yn "Install $repo${skill_suffix}"; then
			if [ -n "$skill" ]; then
				execute "npx skills add '$repo' --skill '$skill' --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo${skill_suffix}" || log_warning "Failed to install: $repo${skill_suffix}"
			else
				execute "npx skills add '$repo' --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo" || log_warning "Failed to install: $repo"
			fi
		else
			log_info "Skipped: $repo${skill_suffix}"
		fi
	fi
}

# Helper: Remove skills from tool-specific directories that already exist in global ~/.agents/skills
cleanup_duplicate_skills() {
	local global_skills_dir="$HOME/.agents/skills"

	if [ ! -d "$global_skills_dir" ]; then
		return 0
	fi

	log_info "Cleaning up duplicate skills from tool-specific directories..."

	local -a target_dirs=(
		"$CLAUDE_SKILLS_DIR"
		"$OPENCODE_SKILL_DIR"
		"$AMP_SKILLS_DIR"
		"$CODEX_SKILLS_DIR"
		"$GEMINI_SKILLS_DIR"
		"$CURSOR_SKILLS_DIR"
	)

	for target_dir in "${target_dirs[@]}"; do
		if [ ! -d "$target_dir" ]; then
			continue
		fi
		for skill_dir in "$target_dir"/*; do
			if [ ! -d "$skill_dir" ]; then
				continue
			fi
			local skill_name
			skill_name=$(basename "$skill_dir")
			if [ -d "$global_skills_dir/$skill_name" ]; then
				execute_quoted rm -rf "$skill_dir"
				log_info "Removed duplicate skill $skill_name from $target_dir/"
			fi
		done
	done
}

# Helper: Check if a skill is in the remote skills list
is_remote_skill() {
	case "$1" in
	prd | ralph | qmd-knowledge | codemap | adr | handoffs | pickup | pr-review | slop | tdd)
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
		log_info "Note: Skills can still be installed remotely using the npx skills add command"
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
		"prd|prd@my-ai-tools|$SCRIPT_DIR|claude"
		"ralph|ralph@my-ai-tools|$SCRIPT_DIR|claude"
		"qmd-knowledge|qmd-knowledge@my-ai-tools|$SCRIPT_DIR|claude"
		"codemap|codemap@my-ai-tools|$SCRIPT_DIR|claude"
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
		printf "1) Local (from skills folder) 2) Remote (from jellydn/my-ai-tools using npx skills) [1/2]: "
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
	cleanup_duplicate_skills
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

		# Skip remote skills - they're installed from local skills folder or npx
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

# Extract compatibility field from SKILL.md
skill_is_compatible_with() {
	local skill_dir="$1"
	local platform="$2"
	local skill_md="$skill_dir/SKILL.md"

	if [ ! -f "$skill_md" ]; then
		return 0
	fi

	local compat_line
	compat_line=$(awk '/^compatibility:/ {print; exit}' "$skill_md" 2>/dev/null)
	[ -z "$compat_line" ] && return 0

	echo "$compat_line" | grep -qi "\\b$platform\\b"
}

install_local_skills() {
	if [ ! -d "$SCRIPT_DIR/skills" ]; then
		log_info "skills folder not found, skipping local skills"
		return 0
	fi

	log_info "Installing skills from local skills folder..."

	# Define target directories
	CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
	OPENCODE_SKILL_DIR="$HOME/.config/opencode/skills"
	AMP_SKILLS_DIR="$HOME/.config/amp/skills"
	CODEX_SKILLS_DIR="$HOME/.codex/skills"
	GEMINI_SKILLS_DIR="$HOME/.gemini/skills"
	CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
	PI_SKILLS_DIR="$HOME/.pi/agent/skills"

	# Prepare target directories
	prepare_skills_dir "$CLAUDE_SKILLS_DIR"
	prepare_skills_dir "$OPENCODE_SKILL_DIR"
	prepare_skills_dir "$AMP_SKILLS_DIR"
	prepare_skills_dir "$CODEX_SKILLS_DIR"
	prepare_skills_dir "$GEMINI_SKILLS_DIR"
	prepare_skills_dir "$CURSOR_SKILLS_DIR"
	prepare_skills_dir "$PI_SKILLS_DIR"

	# Copy all skills from skills folder to targets
	for skill_dir in "$SCRIPT_DIR/skills"/*; do
		if [ ! -d "$skill_dir" ]; then
			continue
		fi

		local skill_name
		skill_name=$(basename "$skill_dir")

		# Skip if skill already exists in global skills directory
		if [ -d "$HOME/.agents/skills/$skill_name" ]; then
			log_info "Skipped $skill_name (already exists in ~/.agents/skills/)"
			continue
		fi

		copy_skill_to_targets "$skill_name" "$skill_dir"
	done
}

prepare_skills_dir() {
	local dir="$1"
	local manifest_file="$dir/.my-ai-tools-managed-skills"
	local managed_marker=".my-ai-tools-managed"
	local previous_managed_skill_names=()
	local managed_skill_names=()
	local repo_skill_dir=""

	for repo_skill_dir in "$SCRIPT_DIR/skills"/*; do
		[ -d "$repo_skill_dir" ] || continue
		managed_skill_names+=("$(basename "$repo_skill_dir")")
	done

	if [ -f "$manifest_file" ]; then
		while IFS= read -r managed_name; do
			[ -n "$managed_name" ] || continue
			previous_managed_skill_names+=("$managed_name")
		done <"$manifest_file"
	fi

	if [ -d "$dir" ]; then
		for existing_skill in "$dir"/*; do
			[ -d "$existing_skill" ] || continue
			local existing_name
			existing_name=$(basename "$existing_skill")
			local managed=false
			local managed_name=""
			for managed_name in "${managed_skill_names[@]}"; do
				if [ "$existing_name" = "$managed_name" ]; then
					managed=true
					break
				fi
			done
			if [ "$managed" = false ] && [ -f "$existing_skill/$managed_marker" ]; then
				managed=true
			fi
			if [ "$managed" = false ]; then
				for managed_name in "${previous_managed_skill_names[@]}"; do
					if [ "$existing_name" = "$managed_name" ]; then
						managed=true
						break
					fi
				done
			fi
			if [ "$managed" = true ]; then
				execute_quoted rm -rf "$existing_skill"
			else
				log_info "Preserving user-managed skill: $existing_skill"
			fi
		done
	fi
	execute_quoted mkdir -p "$dir"

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would update managed skills manifest: $manifest_file"
	else
		: >"$manifest_file"
		local managed_name=""
		for managed_name in "${managed_skill_names[@]}"; do
			printf '%s\n' "$managed_name" >>"$manifest_file"
		done
	fi
}

copy_skill_to_targets() {
	local skill_name="$1"
	local skill_dir="$2"
	local managed_marker=".my-ai-tools-managed"

	if skill_is_compatible_with "$skill_dir" "claude"; then
		safe_copy_dir "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name"
		execute_quoted touch "$CLAUDE_SKILLS_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to Claude Code"
	else
		log_info "Skipped $skill_name for Claude Code (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "opencode"; then
		safe_copy_dir "$skill_dir" "$OPENCODE_SKILL_DIR/$skill_name"
		execute_quoted touch "$OPENCODE_SKILL_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to OpenCode"
	else
		log_info "Skipped $skill_name for OpenCode (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "amp"; then
		safe_copy_dir "$skill_dir" "$AMP_SKILLS_DIR/$skill_name"
		execute_quoted touch "$AMP_SKILLS_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to Amp"
	else
		log_info "Skipped $skill_name for Amp (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "codex"; then
		safe_copy_dir "$skill_dir" "$CODEX_SKILLS_DIR/$skill_name"
		execute_quoted touch "$CODEX_SKILLS_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to Codex CLI"
	else
		log_info "Skipped $skill_name for Codex CLI (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "gemini"; then
		safe_copy_dir "$skill_dir" "$GEMINI_SKILLS_DIR/$skill_name"
		execute_quoted touch "$GEMINI_SKILLS_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to Gemini CLI"
	else
		log_info "Skipped $skill_name for Gemini CLI (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "cursor"; then
		safe_copy_dir "$skill_dir" "$CURSOR_SKILLS_DIR/$skill_name"
		execute_quoted touch "$CURSOR_SKILLS_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to Cursor"
	else
		log_info "Skipped $skill_name for Cursor (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "pi"; then
		safe_copy_dir "$skill_dir" "$PI_SKILLS_DIR/$skill_name"
		execute_quoted touch "$PI_SKILLS_DIR/$skill_name/$managed_marker"
		log_success "Copied $skill_name to Pi"
	else
		log_info "Skipped $skill_name for Pi (not compatible)"
	fi
}

main() {
	echo "╔══════════════════════════════════════════════════════════════════════╗"
	echo "║                        AI Tools Setup                                ║"
	echo "║  Claude • OpenCode • Amp • CCS • Codex • Gemini • Pi • Kilo          ║"
	echo "║  Copilot • Cursor • Factory Droid                                    ║"
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

	install_kilo
	echo

	install_pi
	echo

	install_copilot
	echo

	install_cursor
	echo

	install_factory
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
