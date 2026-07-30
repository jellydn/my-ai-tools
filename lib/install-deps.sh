#!/bin/bash
# Prerequisite installers for my-ai-tools: language runtimes, formatters used by
# PostToolUse hooks, and the standalone MCP server binaries.
#
# Sourced by lib/install.sh, which owns the shared helpers used here
# (ensure_dir_on_path, _verify_package_manager, resolve_installer_checksum,
# handle_tool_installation) — do not source this file on its own.
#
# Requires: lib/common.sh (for log_*, execute_*, prompt_yn, execute_installer)
# Requires: YES_TO_ALL, DRY_RUN, IS_WINDOWS, AMP_INSTALLED (set in cli.sh)

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
		ensure_dir_on_path "$BUN_INSTALL/bin"

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
			ensure_dir_on_path "$(bun pm bin -g 2>/dev/null)"
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
		ensure_dir_on_path "$HOME/.local/bin"
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
		log_info "cargo not found. Installing Rust for logpilot..."
		install_rust_if_needed || {
			log_error "Cannot install logpilot without Rust/cargo"
			log_info "Install Rust first: https://rustup.rs/, then run: cargo install logpilot"
			return 1
		}
	fi

	log_info "Installing logpilot via cargo..."
	if execute "cargo install logpilot"; then
		ensure_dir_on_path "$(cargo_bin_dir)"
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
			log_info "cargo not found. Installing Rust for sem-mcp..."
			install_rust_if_needed || {
				log_error "Cannot install sem-mcp without Rust/cargo"
				log_info "Install Rust first: https://rustup.rs/, then run: cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp"
				return 1
			}
		fi

		log_info "Installing sem-mcp via cargo..."
		if execute "cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp"; then
			ensure_dir_on_path "$(cargo_bin_dir)"
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
				ensure_dir_on_path "$jq_path"
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

# Cargo's binary directory, honouring a custom CARGO_HOME.
cargo_bin_dir() {
	echo "${CARGO_HOME:-$HOME/.cargo}/bin"
}

# Ensure cargo (Rust) is available in PATH, installing Rust if necessary.
# Called by install_logpilot_now, install_sem_now, and install_rustfmt_if_needed.
install_rust_if_needed() {
	if command -v cargo &>/dev/null; then
		return 0
	fi

	local cargo_bin
	cargo_bin="$(cargo_bin_dir)"

	if [ -x "$cargo_bin/cargo" ]; then
		ensure_dir_on_path "$cargo_bin"
		command -v cargo &>/dev/null && return 0
	fi

	log_warning "cargo not found. Installing Rust..."
	if command -v mise &>/dev/null; then
		execute "mise use -g rust@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install rust"
	else
		local rust_checksum
		rust_checksum=$(resolve_installer_checksum "rust")
		execute_installer "https://sh.rustup.rs" "$rust_checksum" "Rust" "-y"
	fi

	if [ -x "$cargo_bin/cargo" ]; then
		ensure_dir_on_path "$cargo_bin"
	fi

	if command -v cargo &>/dev/null; then
		log_success "Rust/cargo installed successfully"
		return 0
	fi

	log_error "Failed to install Rust/cargo"
	log_info "Install manually: https://rustup.rs/"
	return 1
}

install_rustfmt_if_needed() {
	if command -v rustfmt &>/dev/null; then
		log_success "rustfmt found"
		return 0
	fi

	install_rust_if_needed || return 1

	if command -v rustfmt &>/dev/null; then
		log_success "rustfmt available"
	else
		log_warning "Rust installed but rustfmt not found"
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
