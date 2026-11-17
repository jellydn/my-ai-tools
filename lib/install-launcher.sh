#!/bin/bash
# AI Launcher installation, sourced by lib/install.sh after common.sh and install-deps.sh.

# Stage Windows releases so interrupted downloads cannot overwrite a working ai.exe.
# Only GET requests retry; no upstream installer or package lifecycle is repeated.
install_ai_launcher_windows() (
	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would download, verify, and install the Windows AI Launcher release"
		return 0
	fi
	local install_dir="${AI_INSTALL_DIR:-$HOME/.local/bin}" arch artifact stage metadata checksums binary checksum version
	case "$(uname -m)" in
	x86_64 | amd64) arch=x64 ;;
	aarch64 | arm64) arch=arm64 ;;
	*) log_error "Unsupported Windows architecture for AI Launcher"; return 1 ;;
	esac
	artifact="ai-windows-$arch.exe"
	execute_quoted mkdir -p "$install_dir" || return 1
	stage=$(execute_quoted mktemp -d "$install_dir/.ai-download.XXXXXX") || return 1
	trap 'execute_quoted rm -rf "$stage"' EXIT
	export TMPDIR="$stage"
	metadata=$(download_and_verify_file "https://api.github.com/repos/jellydn/ai-launcher/releases/latest" "" "AI Launcher release metadata") || return 1
	local binary_url checksum_url
	binary_url=$(jq -er --arg name "$artifact" 'first(.assets[] | select(.name == $name)).browser_download_url' "$metadata") || {
		log_error "AI Launcher release has no $artifact asset"; return 1
	}
	checksum_url=$(jq -er 'first(.assets[] | select(.name == "checksums.txt")).browser_download_url' "$metadata") || {
		log_error "AI Launcher release has no checksums.txt asset"; return 1
	}
	checksums=$(download_and_verify_file "$checksum_url" "" "AI Launcher checksums") || return 1
	checksum=$(awk -v name="$artifact" '$2 == name || $2 == "*" name { print $1; exit }' "$checksums")
	if [[ ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
		log_error "Missing or invalid AI Launcher checksum for $artifact"
		return 1
	fi
	binary=$(download_and_verify_file "$binary_url" "$checksum" "AI Launcher $artifact") || return 1
	execute_quoted mv "$binary" "$stage/ai.exe" || return 1
	execute_quoted chmod +x "$stage/ai.exe" || return 1
	if ! version=$("$stage/ai.exe" --version) || [ -z "$version" ]; then
		log_error "Downloaded AI Launcher failed its version check; existing binary preserved"
		return 1
	fi
	# Staging shares the destination filesystem; replace only a verified, working release.
	execute_quoted mv -f "$stage/ai.exe" "$install_dir/ai.exe"
)

install_ai_switcher() {
	_run_ai_switcher_install() {
		if [ "${IS_WINDOWS:-false}" = true ]; then
			install_ai_launcher_windows || return 1
		else
			execute_installer "https://raw.githubusercontent.com/jellydn/ai-launcher/main/install.sh" "" "AI Launcher" || return 1
		fi
		[ "$DRY_RUN" != true ] || return 0
		ensure_dir_on_path "${AI_INSTALL_DIR:-$HOME/.local/bin}"
		hash -r 2>/dev/null || true
		local version
		if ! version=$(ai --version) || [ -z "$version" ]; then
			log_error "AI Launcher installation completed but ai --version failed"
			return 1
		fi
	}
	run_installer "AI Launcher" "_run_ai_switcher_install" "false" "ai --version"
}
