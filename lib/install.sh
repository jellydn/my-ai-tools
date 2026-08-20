#!/bin/bash
# Tool installation functions for my-ai-tools
# Source this file AFTER lib/common.sh using:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/install.sh"
#
# Requires: lib/common.sh (for log_*, execute_*, prompt_yn, execute_installer)
# Requires: YES_TO_ALL, DRY_RUN, IS_WINDOWS, AMP_INSTALLED (set in cli.sh)

# Prerequisites (runtimes, formatters, MCP server binaries) live in their own module.
source "$(dirname "${BASH_SOURCE[0]}")/install-deps.sh"

# ─── Shared helpers ────────────────────────────────────────────────

# Prepend a directory to PATH for the current session if it isn't already present.
# Keeps PATH-guard conditionals consistent (and scannable) across installers.
ensure_dir_on_path() {
	local dir="${1:-}"
	[ -n "$dir" ] || return 0
	if case ":$PATH:" in *":$dir:"*) false ;; *) true ;; esac; then
		export PATH="$dir:$PATH"
	fi
}

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
	rtk)
		checksum_url="${RTK_INSTALL_SHA256_URL:-}"
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

install_fx() {
	_run_fx_install() {
		local fx_platform
		local fx_archive_sha256
		local fx_install_dir="${FX_INSTALL_DIR:-$HOME/.local/bin}"
		local fx_version="v0.0.4"

		if command -v fx &>/dev/null; then
			log_warning "fx is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			log_warning "fx supports macOS and Linux only."
			log_info "Install fx manually in a supported environment: https://fx.sh/docs/getting-started/installation"
			return 0
		fi

		case "$(uname -s):$(uname -m)" in
		Linux:x86_64 | Linux:amd64)
			fx_platform="linux-x86_64"
			fx_archive_sha256="be9428636afb1196cb662b48ed57bbed3b95e7c37f2bc7849e02c0960fae1f01"
			;;
		Linux:arm64 | Linux:aarch64)
			fx_platform="linux-aarch64"
			fx_archive_sha256="9905a51c213d1b7fe3b5079f00fd3e61f2dba5bde707397991e9535c4a700caf"
			;;
		Darwin:x86_64 | Darwin:amd64)
			fx_platform="macos-x86_64"
			fx_archive_sha256="41d3c2cd78bdb53aa9df16fbd5ae9415c8a2e3e8851ebe6423db0cc32128bf7c"
			;;
		Darwin:arm64 | Darwin:aarch64)
			fx_platform="macos-aarch64"
			fx_archive_sha256="395ac3832f6f6c231f6ba7a46ba6ec70eefaddb68662e6fd6c4fb8e0d6d72f59"
			;;
		*)
			log_error "Unsupported fx platform: $(uname -s) $(uname -m)"
			return 1
			;;
		esac

		if [ "$DRY_RUN" = true ]; then
			log_info "[DRY RUN] Would install fx $fx_version for $fx_platform to $fx_install_dir"
			return 0
		fi

		local fx_archive
		local fx_extract_dir
		fx_archive=$(download_and_verify_file "https://releases.fx.sh/$fx_version/fx-$fx_platform.tar.gz" "$fx_archive_sha256" "fx $fx_version ($fx_platform)") || return 1
		fx_extract_dir="$(get_temp_dir)/fx-$fx_version-$$"

		if ! execute_quoted mkdir -p "$fx_extract_dir" ||
			! execute_quoted tar -xzf "$fx_archive" -C "$fx_extract_dir" ||
			! execute_quoted mkdir -p "$fx_install_dir" ||
			! execute_quoted cp "$fx_extract_dir/fx" "$fx_install_dir/fx" ||
			! execute_quoted chmod +x "$fx_install_dir/fx"; then
			execute_quoted rm -rf "$fx_extract_dir" "$fx_archive"
			log_error "Failed to install fx"
			log_info "You can install manually: curl -fsSL https://fx.sh/setup.sh | bash"
			return 1
		fi

		execute_quoted rm -rf "$fx_extract_dir" "$fx_archive"
		ensure_dir_on_path "$fx_install_dir"
		log_success "fx installed"
	}
	run_installer "fx" "_run_fx_install" "command -v fx" "fx --version"
}

install_rtk() {
	if [ "${IS_WINDOWS:-false}" = true ]; then
		log_warning "RTK automatic installation is unavailable on native Windows"
		log_info "Use WSL for hook support or install the Windows release manually: https://github.com/rtk-ai/rtk/releases"
		return 0
	fi

	_run_rtk_install() {
		local rtk_checksum
		rtk_checksum=$(resolve_installer_checksum "rtk")
		execute_installer "https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh" "$rtk_checksum" "RTK"
		ensure_dir_on_path "$HOME/.local/bin"

		if [ "$DRY_RUN" = false ] && ! "$HOME/.local/bin/rtk" gain --help >/dev/null 2>&1; then
			log_error "RTK installation did not produce the expected binary at $HOME/.local/bin/rtk"
			return 1
		fi
	}

	local check_cmd='if [ -x "$HOME/.local/bin/rtk" ]; then "$HOME/.local/bin/rtk" gain --help; else command -v rtk >/dev/null 2>&1 && rtk gain --help; fi'
	local version_cmd='if [ -x "$HOME/.local/bin/rtk" ]; then "$HOME/.local/bin/rtk" --version; else rtk --version; fi'
	run_installer "RTK command-output compressor" "_run_rtk_install" "$check_cmd" "$version_cmd"
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

install_opencode2() {
	_run_opencode2_install() {
		if command -v opencode2 >/dev/null 2>&1; then
			log_warning "OpenCode 2 is already installed"
		else
			local package_manager
			if command -v bun >/dev/null 2>&1; then
				package_manager="bun"
			elif command -v npm >/dev/null 2>&1; then
				package_manager="npm"
			elif command -v pnpm >/dev/null 2>&1; then
				package_manager="pnpm"
			elif command -v yarn >/dev/null 2>&1; then
				package_manager="yarn"
			else
				log_error "No supported package manager found for OpenCode 2 (need Bun, npm, pnpm, or Yarn)"
				return 1
			fi

			if ! case "$package_manager" in
				bun) execute "bun install -g --trust @opencode-ai/cli@next" ;;
				npm) execute "npm install -g @opencode-ai/cli@next" ;;
				pnpm) execute "pnpm add -g --allow-build=@opencode-ai/cli @opencode-ai/cli@next" ;;
				yarn) execute "yarn global add @opencode-ai/cli@next" ;;
				esac
			then
				log_error "OpenCode 2 installation failed"
				return 1
			fi

			if [ "$DRY_RUN" = false ]; then
				local global_bin=""
				case "$package_manager" in
				bun)
					global_bin="$(bun pm bin -g 2>/dev/null)"
					[ -n "$global_bin" ] || global_bin="${BUN_INSTALL:-$HOME/.bun}/bin"
					;;
				npm) global_bin="$(npm prefix -g 2>/dev/null)/bin" ;;
				pnpm) global_bin="$(pnpm bin -g 2>/dev/null)" ;;
				yarn) global_bin="$(yarn global bin 2>/dev/null)" ;;
				esac
				ensure_dir_on_path "$global_bin"
				hash -r 2>/dev/null || true
			fi

			if [ "$DRY_RUN" = true ]; then
				log_info "[DRY RUN] Would install OpenCode 2 as opencode2"
			elif ! command -v opencode2 >/dev/null 2>&1; then
				log_error "OpenCode 2 installation completed but opencode2 is not on PATH"
				return 1
			else
				log_success "OpenCode 2 installed as opencode2"
			fi
		fi
	}
	run_installer "OpenCode 2 (beta)" "_run_opencode2_install" "command -v opencode2" ""
}

# Usage: install_opencode_cursor
# Cursor ACP bridge for OpenCode (https://github.com/Nomadcxx/opencode-cursor).
# Config lives in configs/opencode/opencode.json — do not run `open-cursor install`
# here; that CLI rewrites managed OpenCode config.
install_open_cursor() {
	install_npm_tool "open-cursor" "open-cursor" "@rama_nigg/open-cursor" \
		"npm install -g @rama_nigg/open-cursor" \
		"open-cursor --version"
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

install_reasonix() {
	install_npm_tool "Reasonix" "reasonix" "reasonix" \
		"npm install -g reasonix"
}

install_pi() {
	install_npm_tool "Pi" "pi" "@mariozechner/pi-coding-agent" \
		"npm install -g @mariozechner/pi-coding-agent"
}
install_omp() {
	install_npm_tool "Oh My Pi" "omp" "@oh-my-pi/pi-coding-agent" \
		"npm install -g @oh-my-pi/pi-coding-agent"
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

install_hunk() {
	_run_hunk_install() {
		if ! command -v node &>/dev/null; then
			log_error "Hunk's npm package requires Node.js 18 or newer."
			log_info "Install Node.js 18+ or install Hunk through Homebrew or mise."
			return 1
		fi

		local node_major
		node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null) || node_major=""
		if ! [[ "$node_major" =~ ^[0-9]+$ ]] || [ "$node_major" -lt 18 ]; then
			log_error "Hunk requires Node.js 18 or newer (found: $(node --version 2>/dev/null || echo unknown))."
			return 1
		fi

		local pkg_manager
		pkg_manager=$(_verify_package_manager "Hunk")
		if [ -z "$pkg_manager" ]; then
			log_error "No package manager found. Install npm or Bun to install Hunk."
			return 1
		fi

		log_info "Installing Hunk with $pkg_manager..."
		if ! execute "$pkg_manager install -g hunkdiff"; then
			log_error "Failed to install Hunk"
			log_info "You can install it manually: npm install --global hunkdiff"
			return 1
		fi

		if ! execute "hunk --version >/dev/null"; then
			log_error "Hunk was installed but could not start."
			return 1
		fi

		log_success "Hunk installed and verified"
	}

	run_installer "Hunk" "_run_hunk_install" "command -v hunk && hunk --version" "hunk --version"
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

# ─── delta installation ───────────────────────────────────────────

install_delta() {
	local delta_settings_dir
	delta_settings_dir=$(get_delta_settings_dir)
	if [ -d "$delta_settings_dir" ] || [ -d "/Applications/Delta.app" ] || [ -d "$HOME/.local/delta.app" ]; then
		log_warning "Delta is already installed"
		return 0
	fi

	# Delta is a beta with nightly, access-controlled builds. Its official docs
	# do not expose a stable archive URL that is safe to automate here. Do not
	# detect `command -v delta`: the unrelated git-delta pager uses that name too.
	log_info "Delta installation is currently manual: https://delta.dev/download"
	log_info "Follow the platform steps at https://delta.dev/docs/getting-started"
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

# ─── devin installation ───────────────────────────────────────────

install_devin() {
	_run_devin_install() {
		if command -v devin &>/dev/null; then
			log_warning "Devin CLI is already installed"
			return 0
		fi

		if [ "$IS_WINDOWS" = true ]; then
			if command -v powershell.exe &>/dev/null; then
				execute "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"irm https://static.devin.ai/cli/setup.ps1 | iex\""
			else
				log_error "PowerShell is required to install Devin CLI on Windows."
				log_info "Install manually: https://docs.devin.ai"
				return 1
			fi
		else
			execute_installer "https://cli.devin.ai/install.sh" "" "Devin CLI"
		fi

		log_success "Devin CLI installed"
	}
	run_installer "Devin CLI" "_run_devin_install" "command -v devin" "devin --version 2>/dev/null || true"
}
