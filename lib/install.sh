#!/bin/bash
# Tool installation functions for my-ai-tools
# Source this file AFTER lib/common.sh using:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/install.sh"
#
# Requires: lib/common.sh (for log_*, execute_*, prompt_yn, execute_installer)
# Requires: YES_TO_ALL, DRY_RUN, IS_WINDOWS, AMP_INSTALLED (set in cli.sh)

# ─── Shared helpers ────────────────────────────────────────────────

# Detect available package manager (bun preferred, fallback to npm)
# Outputs: package manager command or empty if none found
_detect_package_manager() {
	if command -v bun &>/dev/null; then
		echo "bun"
	elif command -v npm &>/dev/null; then
		echo "npm"
	else
		echo ""
	fi
}

# Verify and get a working package manager with fallback
# Outputs: package manager command or empty if none available
_verify_package_manager() {
	local tool_name="${1:-tool}"
	local pkg_manager
	pkg_manager=$(_detect_package_manager)

	[ -z "$pkg_manager" ] && return 1
	command -v "$pkg_manager" &>/dev/null && {
		echo "$pkg_manager"
		return 0
	}

	log_warning "$pkg_manager was detected but is not available in current shell PATH"

	if [ "$pkg_manager" = "bun" ] && command -v npm &>/dev/null; then
		log_info "Falling back to npm for $tool_name installation"
		echo "npm"
		return 0
	fi

	if [ "$pkg_manager" = "npm" ] && command -v bun &>/dev/null; then
		log_info "Falling back to bun for $tool_name installation"
		echo "bun"
		return 0
	fi

	return 1
}

# Detect available script runner (bunx preferred, fallback to npx)
# Outputs: script runner command or empty if none found
_detect_script_runner() {
	if command -v bunx &>/dev/null; then
		echo "bunx"
	elif command -v npx &>/dev/null; then
		echo "npx"
	else
		echo ""
	fi
}

# Resolve installer checksum URL for trusted installations
# Usage: resolve_installer_checksum "installer_name"
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
	sem)
		checksum_url="${SEM_INSTALL_SHA256_URL:-}"
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

# Generic tool installation handler
# Usage: handle_tool_installation "tool_name" "install_func" "check_cmd" "description" "feature_name"
handle_tool_installation() {
	local tool_name="$1"
	local install_func="$2"
	local check_cmd="${3:-command -v $tool_name}"
	local description="${4:-$tool_name}"
	local feature_name="${5:-$description}"

	if eval "$check_cmd" &>/dev/null; then
		log_success "$description found"
		return 0
	fi

	local warning_msg="Continuing without $description. $feature_name will be unavailable."

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing $description (--yes flag)..."
		$install_func || log_warning "$warning_msg"
	elif [ -t 0 ]; then
		if prompt_yn "$description is not installed. Install it now"; then
			$install_func || log_warning "$warning_msg"
		else
			log_warning "$warning_msg"
		fi
	else
		log_warning "$warning_msg"
	fi
}

# Ensure a CLI tool is installed, prompting if interactive
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

# Shared helper: Install an npm-based AI coding CLI tool with consistent pattern.
# Usage: install_npm_tool "display_name" "binary" "npm_pkg" "manual_url" [version_cmd]
install_npm_tool() {
	local display_name="$1"
	local binary="$2"
	local npm_pkg="$3"
	local manual_url="$4"
	local version_cmd="${5:-$binary --version 2>/dev/null || true}"

	_run_install_npm_body() {
		if command -v "$binary" &>/dev/null; then
			log_warning "$display_name is already installed"
			return 0
		fi

		local pkg_manager
		pkg_manager=$(_verify_package_manager "$display_name")

		if [ -z "$pkg_manager" ]; then
			log_error "No package manager found. Install Bun or Node.js/npm to install $display_name."
			return 1
		fi

		log_info "Installing $display_name with $pkg_manager..."
		if execute "$pkg_manager install -g $npm_pkg"; then
			log_success "$display_name installed"
		else
			log_error "Failed to install $display_name"
			log_info "You can install manually: $manual_url"
			return 1
		fi
	}

	run_installer "$display_name" "_run_install_npm_body" "command -v $binary" "$version_cmd"
}

# ─── Bun installation ──────────────────────────────────────────────

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

# ─── qmd installation ──────────────────────────────────────────────

install_qmd_now() {
	if command -v qmd &>/dev/null; then
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd already installed ($qmd_version)"
		return 0
	fi

	# Prefer Bun for qmd (install if missing)
	if ! command -v bun &>/dev/null; then
		log_info "qmd works best with Bun. Installing Bun first..."
		handle_bun_installation
	fi

	local pkg_manager
	pkg_manager=$(_verify_package_manager "qmd")

	if [ -z "$pkg_manager" ]; then
		log_error "No package manager found. Install Bun or Node.js/npm to install qmd."
		return 1
	fi

	log_info "Installing qmd CLI via $pkg_manager..."
	if execute "$pkg_manager install -g @tobilu/qmd"; then
		# Ensure bun's global bin directory is in PATH for the current session (if using bun)
		if command -v bun &>/dev/null; then
			local bun_global_bin
			bun_global_bin="$(bun pm bin -g 2>/dev/null)"
			if [ -n "$bun_global_bin" ] && case ":$PATH:" in *":$bun_global_bin:"*) false ;; *) true ;; esac; then
				export PATH="$bun_global_bin:$PATH"
			fi
		fi
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd installed successfully ($qmd_version)"
		return 0
	fi

	log_error "Failed to install qmd"
	return 1
}

handle_qmd_installation_if_needed() {
	handle_tool_installation "qmd" "install_qmd_now" "command -v qmd" "qmd" "Knowledge features"
}

# ─── fff-mcp installation ──────────────────────────────────────────

install_fff_mcp_now() {
	if command -v fff-mcp &>/dev/null; then
		log_success "fff-mcp already installed"
		return 0
	fi

	log_info "Installing fff-mcp via official installer..."
	if execute_installer "https://dmtrkovalenko.dev/install-fff-mcp.sh" "" "fff-mcp"; then
		# Ensure ~/.local/bin is in PATH for the current session
		local local_bin="$HOME/.local/bin"
		if case ":$PATH:" in *":$local_bin:"*) false ;; *) true ;; esac; then
			export PATH="$local_bin:$PATH"
		fi
		log_success "fff-mcp installed successfully"
		return 0
	fi

	log_error "Failed to install fff-mcp"
	log_info "You can install it manually: curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh | bash"
	return 1
}

handle_fff_mcp_installation_if_needed() {
	handle_tool_installation "fff-mcp" "install_fff_mcp_now" "command -v fff-mcp" "fff-mcp" "Fast file search MCP"
}

# ─── logpilot installation ─────────────────────────────────────────

install_logpilot_now() {
	if command -v logpilot &>/dev/null; then
		log_success "logpilot already installed"
		return 0
	fi

	if ! command -v cargo &>/dev/null; then
		log_error "cargo not found. Cannot install logpilot. Install Rust first: https://rustup.rs/"
		return 1
	fi

	log_info "Installing logpilot via cargo..."
	if execute "cargo install logpilot"; then
		# Ensure cargo bin is in PATH
		local cargo_bin="${CARGO_HOME:-$HOME/.cargo}/bin"
		if case ":$PATH:" in *":$cargo_bin:"*) false ;; *) true ;; esac; then
			export PATH="$cargo_bin:$PATH"
		fi
		log_success "logpilot installed successfully"
		return 0
	fi

	log_error "Failed to install logpilot"
	log_info "You can install it manually: cargo install logpilot"
	return 1
}

handle_logpilot_installation_if_needed() {
	handle_tool_installation "logpilot" "install_logpilot_now" "command -v logpilot" "logpilot" "Log monitoring MCP"
}

# ─── sem installation ──────────────────────────────────────────────

install_sem_now() {
	if command -v sem &>/dev/null && command -v sem-mcp &>/dev/null; then
		log_success "sem and sem-mcp already installed"
		return 0
	fi

	# Install sem CLI via official installer with checksum verification
	if ! command -v sem &>/dev/null; then
		log_info "Installing sem via official installer..."
		local sem_checksum
		sem_checksum=$(resolve_installer_checksum "sem")
		if execute_installer "https://raw.githubusercontent.com/Ataraxy-Labs/sem/main/install.sh" "$sem_checksum" "sem CLI"; then
			log_success "sem installed successfully"
		else
			log_error "Failed to install sem"
			log_info "You can install manually: curl -fsSL https://raw.githubusercontent.com/Ataraxy-Labs/sem/main/install.sh | sh"
			return 1
		fi
	fi

	# Install sem-mcp via cargo
	if ! command -v sem-mcp &>/dev/null; then
		if ! command -v cargo &>/dev/null; then
			log_error "cargo not found. sem-mcp requires Rust to build from source."
			log_info "Install Rust first: https://rustup.rs/, then run: cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp"
			return 1
		fi

		log_info "Installing sem-mcp via cargo..."
		if execute "cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp"; then
			local cargo_bin="${CARGO_HOME:-$HOME/.cargo}/bin"
			if case ":$PATH:" in *":$cargo_bin:"*) false ;; *) true ;; esac; then
				export PATH="$cargo_bin:$PATH"
			fi
			log_success "sem-mcp installed successfully"
		else
			log_error "Failed to install sem-mcp"
			log_info "You can install manually: cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp"
			return 1
		fi
	fi
}

handle_sem_installation_if_needed() {
	handle_tool_installation "sem" "install_sem_now" "command -v sem-mcp" "sem" "Semantic version control MCP"
}

# ─── Global tooling (jq, biome, gofmt, ruff, rustfmt, shfmt, stylua, backlog) ──

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
			execute "winget install -e --id jqlang.jq --accept-package-agreements --accept-source-agreements" && jq_installed=true
		fi

		if [ "$jq_installed" = true ]; then
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

	local pkg_manager
	pkg_manager=$(_verify_package_manager "biome")

	if [ -z "$pkg_manager" ]; then
		log_warning "biome not found. No package manager available to install. Install Bun or Node.js/npm."
		return 1
	fi

	log_warning "biome not found. Installing biome globally with $pkg_manager..."
	if execute "$pkg_manager install -g @biomejs/biome"; then
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
		return 0
	fi

	local pkg_manager
	pkg_manager=$(_verify_package_manager "backlog.md")

	if [ -z "$pkg_manager" ]; then
		log_warning "backlog.md not found. No package manager available. Install Bun or Node.js/npm."
		return 1
	fi

	log_info "Installing backlog.md for Amp integration with $pkg_manager..."
	execute "$pkg_manager install -g backlog.md"
}

# ─── AI coding tool installers ─────────────────────────────────────

install_claude_code() {
	log_info "Installing Claude Code..."

	local pkg_manager
	pkg_manager=$(_verify_package_manager "Claude Code")

	if [ -z "$pkg_manager" ]; then
		log_error "No package manager found. Install Bun (preferred) or Node.js/npm:"
		log_info "  Bun:    curl -fsSL https://bun.sh/install | bash"
		log_info "  Node:   https://nodejs.org/ (includes npm)"
		return 1
	fi

	log_info "Using package manager: $pkg_manager"

	if ! command -v claude &>/dev/null; then
		if execute "$pkg_manager install -g @anthropic-ai/claude-code"; then
			log_success "Claude Code installed"
		else
			log_error "Failed to install Claude Code"
			return 1
		fi
		return 0
	fi

	log_warning "Claude Code is already installed ($(claude --version))"

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-skipping reinstall (--yes flag)"
		return 0
	elif [ -t 0 ]; then
		if ! prompt_yn "Do you want to reinstall"; then
			return 0
		fi
	else
		log_info "Skipping reinstall in non-interactive mode"
		return 0
	fi

	if execute "$pkg_manager install -g @anthropic-ai/claude-code"; then
		log_success "Claude Code reinstalled"
	else
		log_error "Failed to reinstall Claude Code"
		return 1
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
	install_npm_tool "CCS" "ccs" "@kaitranntt/ccs" \
		"npm install -g @kaitranntt/ccs" \
		"ccs --version"
}

install_ai_switcher() {
	_run_ai_switcher_install() {
		if command -v ai &>/dev/null; then
			log_info "Upgrading AI Launcher from existing installation..."
		fi
		execute_installer "https://raw.githubusercontent.com/jellydn/ai-launcher/main/install.sh" "" "AI Launcher"
		log_success "AI Launcher installed/upgraded"
	}
	run_installer "AI Launcher" "_run_ai_switcher_install" "false" "ai --version"
}

install_codex() {
	install_npm_tool "OpenAI Codex CLI" "codex" "@openai/codex" \
		"npm install -g @openai/codex"
}

install_kimi_code() {
	_run_kimi_code_install() {
		if command -v kimi &>/dev/null; then
			log_warning "Kimi Code CLI is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				log_warning "WARNING: This will download and execute PowerShell code from code.kimi.com with ExecutionPolicy Bypass. Review the installer script before proceeding in security-sensitive environments."
				if [ "$YES_TO_ALL" = false ] && [ -t 0 ]; then
					if ! prompt_yn "Run Kimi Code official PowerShell installer from code.kimi.com"; then
						log_warning "Skipping Kimi Code CLI installation"
						return 0
					fi
				fi
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://code.kimi.com/kimi-code/install.ps1 | iex\""
			else
				log_error "PowerShell is required to install Kimi Code CLI on Windows."
				log_info "Install manually: https://www.kimi.com/code/en"
				return 1
			fi
		else
			execute_installer "https://code.kimi.com/kimi-code/install.sh" "" "Kimi Code CLI"
		fi

		log_success "Kimi Code CLI installed"
	}
	run_installer "Kimi Code CLI" "_run_kimi_code_install" "command -v kimi" "kimi --version 2>/dev/null || true"
}

install_gemini() {
	_run_gemini_install() {
		if command -v gemini &>/dev/null; then
			log_warning "Gemini CLI is already installed"
			_gemini_deprecation_warning
			return 0
		fi

		local pkg_manager
		pkg_manager=$(_verify_package_manager "Gemini CLI")

		if [ -z "$pkg_manager" ]; then
			log_error "No package manager found. Install Bun or Node.js/npm to install Gemini CLI."
			return 1
		fi

		log_info "Installing Gemini CLI with $pkg_manager..."
		if execute "$pkg_manager install -g @google/gemini-cli"; then
			log_success "Gemini CLI installed"
			_gemini_deprecation_warning
		else
			log_error "Failed to install Gemini CLI"
			return 1
		fi
	}
	run_installer "Google Gemini CLI" "_run_gemini_install" "command -v gemini" ""
}

_gemini_deprecation_warning() {
	echo ""
	log_warning "╔══════════════════════════════════════════════════════════════╗"
	log_warning "║  ⚠️  GEMINI CLI DEPRECATION NOTICE                          ║"
	log_warning "║                                                            ║"
	log_warning "║  Gemini CLI stops serving Google One / unpaid tiers on:     ║"
	log_warning "║  June 18, 2026                                             ║"
	log_warning "║                                                            ║"
	log_warning "║  API-key workflows are NOT affected.                        ║"
	log_warning "║                                                            ║"
	log_warning "║  Migrate to Antigravity CLI:                                ║"
	log_warning "║  https://antigravity.google/product/antigravity-cli         ║"
	log_warning "║  Migration guide: https://goo.gle/gemini-cli-migration      ║"
	log_warning "╚══════════════════════════════════════════════════════════════╝"
	echo ""

	if command -v agy &>/dev/null; then
		log_success "Antigravity CLI is already installed — you're all set!"
	elif [ "$YES_TO_ALL" = true ]; then
		log_info "Antigravity CLI will be installed in the next step (--yes mode)."
	elif [ -t 0 ]; then
		log_info "You'll be offered Antigravity CLI installation in the next step."
	else
		log_info "Run this script interactively or with --yes to install Antigravity CLI."
	fi
}

install_antigravity() {
	_run_antigravity_install() {
		if command -v agy &>/dev/null; then
			log_warning "Antigravity CLI is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://antigravity.google/cli/install.ps1 | iex\""
			else
				log_error "PowerShell is required to install Antigravity CLI on Windows."
				log_info "Install manually: https://antigravity.google/docs/cli-getting-started"
				return 1
			fi
		else
			execute_installer "https://antigravity.google/cli/install.sh" "" "Antigravity CLI"
		fi

		log_success "Antigravity CLI installed"
	}
	run_installer "Google Antigravity CLI" "_run_antigravity_install" "command -v agy" "agy --version"
}

install_kilo() {
	install_npm_tool "Kilo CLI" "kilo" "@kilocode/cli" \
		"npm install -g @kilocode/cli"
}

install_pi() {
	install_npm_tool "Pi" "pi" "@mariozechner/pi-coding-agent" \
		"npm install -g @mariozechner/pi-coding-agent"
}

is_commandcode_installed() {
	command -v cmd &>/dev/null
}

install_commandcode() {
	install_npm_tool "Command Code" "cmd" "command-code" \
		"npm install -g command-code" \
		"cmd --version 2>/dev/null || true"
}

install_copilot() {
	prompt_and_install() {
		log_info "Installing GitHub Copilot CLI..."
		if command -v copilot &>/dev/null; then
			log_warning "GitHub Copilot CLI is already installed"
			return 0
		fi

		local pkg_manager
		pkg_manager=$(_verify_package_manager "Copilot CLI")

		if [ -z "$pkg_manager" ]; then
			log_error "No package manager found. Install Bun or Node.js/npm to install Copilot CLI."
			return 1
		fi

		log_info "Installing GitHub Copilot CLI with $pkg_manager..."
		if execute "$pkg_manager install -g @github/copilot"; then
			log_success "GitHub Copilot CLI installed"
		else
			log_error "Failed to install GitHub Copilot CLI"
			return 1
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
	install_npm_tool "Factory Droid" "droid" "@factory/cli" \
		"npm install -g @factory/cli"
}

install_cline() {
	install_npm_tool "Cline" "cline" "cline" \
		"npm install -g cline"
}

install_grok() {
	install_npm_tool "xAI Grok CLI" "grok" "@xai-official/grok" \
		"curl -fsSL https://x.ai/cli/install.sh | bash" \
		"grok --version 2>/dev/null || grok version 2>/dev/null || true"
}

install_mimo() {
	install_npm_tool "Xiaomi MiMo-Code" "mimo" "@mimo-ai/cli" \
		"curl -fsSL https://mimo.xiaomi.com/install | bash"
}

install_open_code_review() {
	install_npm_tool "Alibaba Open Code Review" "ocr" "@alibaba-group/open-code-review" \
		"npm install -g @alibaba-group/open-code-review"
}

install_conductor() {
	if [ -d "/Applications/Conductor.app" ]; then
		log_success "Conductor is already installed"
	else
		log_info "Conductor is a macOS app - download from https://www.conductor.build"
		log_info "After installing, run this script again to configure Conductor"
	fi
}

# ─── herdr installation ────────────────────────────────────────────

install_herdr() {
	_run_herdr_install() {
		if command -v herdr &>/dev/null; then
			log_warning "herdr is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://herdr.dev/install.ps1 | iex\""
			else
				log_error "PowerShell is required to install herdr on Windows."
				log_info "Install manually: https://herdr.dev/docs/install/"
				return 1
			fi
		else
			execute_installer "https://herdr.dev/install.sh" "" "herdr"
		fi

		log_success "herdr installed"
	}
	run_installer "herdr" "_run_herdr_install" "command -v herdr" "herdr --version 2>/dev/null || true"
}

# ─── ctx installation ──────────────────────────────────────────────

install_ctx() {
	_run_ctx_install() {
		if command -v ctx &>/dev/null; then
			log_warning "ctx is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://ctx.rs/install.ps1 | iex\""
			else
				log_error "PowerShell is required to install ctx on Windows."
				log_info "Install manually: https://github.com/ctxrs/ctx"
				return 1
			fi
		else
			execute_installer "https://ctx.rs/install" "" "ctx"
		fi
	}
	run_installer "ctx" "_run_ctx_install" "command -v ctx" "ctx --version 2>/dev/null || true"
}

# ─── qodercli installation ────────────────────────────────────────────

install_qodercli() {
	_run_qodercli_install() {
		if command -v qodercli &>/dev/null; then
			log_warning "Qoder CLI is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://qoder.com/install.ps1 | iex\""
			else
				log_error "PowerShell is required to install Qoder CLI on Windows."
				log_info "Install manually: https://docs.qoder.com/en/cli/quick-start"
				return 1
			fi
		else
			execute_installer "https://qoder.com/install" "" "Qoder CLI"
		fi

		log_success "Qoder CLI installed"
	}
	run_installer "Qoder CLI" "_run_qodercli_install" "command -v qodercli" "qodercli --version 2>/dev/null || true"
}

# ─── kiro installation ────────────────────────────────────────────

install_kiro() {
	_run_kiro_install() {
		if command -v kiro-cli &>/dev/null || command -v kiro &>/dev/null; then
			log_warning "Kiro CLI is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				# -ExecutionPolicy Bypass is required because PowerShell's default
				# Restricted policy blocks unsigned remote scripts. Kiro's installer
				# PS1 is hosted at kiro.dev and fetched via irm (Invoke-RestMethod).
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://kiro.dev/install.ps1 | iex\""
			else
				log_error "PowerShell is required to install Kiro CLI on Windows."
				log_info "Install manually: https://kiro.dev/docs/cli/installation/"
				return 1
			fi
		else
			execute_installer "https://cli.kiro.dev/install" "" "Kiro CLI"
		fi
	}
	run_installer "Kiro CLI" "_run_kiro_install" "command -v kiro-cli || command -v kiro" "kiro-cli --version 2>/dev/null || true"
}

# ─── codiff installation ──────────────────────────────────────────

install_codiff() {
	_run_codiff_install() {
		if command -v codiff &>/dev/null; then
			log_warning "Codiff is already installed"
			return 0
		fi

		if [ "$IS_LINUX" = true ]; then
			log_info "Codiff: download from https://github.com/nkzw-tech/codiff/releases"
			log_info "Install manually, or on macOS: brew install --cask nkzw-tech/tap/codiff"
			return 1
		fi

		# macOS: Homebrew cask
		if ! command -v brew &>/dev/null; then
			log_error "Homebrew is required to install Codiff on macOS."
			log_info "Install Homebrew first: https://brew.sh"
			return 1
		fi

		# Tap and install
		if ! brew tap nkzw-tech/tap &>/dev/null; then
			log_error "Failed to tap nkzw-tech/tap"
			return 1
		fi

		execute "brew install --cask nkzw-tech/tap/codiff"
	}
	run_installer "Codiff" "_run_codiff_install" "command -v codiff" "codiff --version 2>/dev/null || true"
}
