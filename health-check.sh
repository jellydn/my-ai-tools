#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

FAILURES=0
WARNINGS=0

record_failure() {
	log_error "$1"
	FAILURES=$((FAILURES + 1))
}

record_warning() {
	log_warning "$1"
	WARNINGS=$((WARNINGS + 1))
}

record_success() {
	log_success "$1"
}

check_command() {
	local command_name="$1"
	local description="$2"

	if command -v "$command_name" &>/dev/null; then
		record_success "$description"
	else
		record_failure "$description"
	fi
}

check_any_command() {
	local description="$1"
	shift

	local command_name
	for command_name in "$@"; do
		if command -v "$command_name" &>/dev/null; then
			record_success "$description ($command_name)"
			return 0
		fi
	done

	record_failure "$description"
}

check_file() {
	local file_path="$1"
	local description="$2"

	if [ -f "$file_path" ]; then
		record_success "$description"
	else
		record_failure "$description"
	fi
}

check_directory() {
	local dir_path="$1"
	local description="$2"

	if [ -d "$dir_path" ]; then
		record_success "$description"
	else
		record_failure "$description"
	fi
}

check_python_import() {
	local python_cmd="$1"
	local module_name="$2"
	local description="$3"

	if [ ! -x "$python_cmd" ]; then
		record_failure "$description"
		return 1
	fi

	if "$python_cmd" -c "import ${module_name}" >/dev/null 2>&1; then
		record_success "$description"
	else
		record_failure "$description"
	fi
}

check_text_in_file() {
	local file_path="$1"
	local expected_text="$2"
	local description="$3"

	if [ ! -f "$file_path" ]; then
		record_failure "$description"
		return 1
	fi

	if grep -Fq "$expected_text" "$file_path"; then
		record_success "$description"
	else
		record_failure "$description"
	fi
}

check_mempalace_launcher() {
	local python_cmd="$HOME/.local/share/my-ai-tools/venvs/mempalace/bin/python"
	local launcher_path="$HOME/.ai-tools/bin/mempalace-mcp-launcher.py"
	local output_file
	local exit_code=0

	check_file "$launcher_path" "MemPalace launcher installed at ~/.ai-tools/bin"
	check_python_import "$python_cmd" "mempalace" "MemPalace import works in dedicated venv"

	if [ ! -x "$python_cmd" ] || [ ! -f "$launcher_path" ]; then
		return 1
	fi

	if ! command -v timeout &>/dev/null; then
		record_warning "timeout command not found; skipping MemPalace launcher startup test"
		return 0
	fi

	output_file=$(make_temp_file "mempalace-health" "log")
	if ! timeout 5s "$python_cmd" "$launcher_path" >"$output_file" 2>&1; then
		exit_code=$?
	fi

	if grep -q "Traceback" "$output_file" || grep -q "mempalace MCP launcher failed" "$output_file"; then
		record_failure "MemPalace launcher starts cleanly"
		log_error "Launcher output:"
		cat "$output_file" >&2
		rm -f "$output_file"
		return 1
	fi

	if grep -q "MemPalace MCP Server starting" "$output_file"; then
		record_success "MemPalace launcher starts cleanly"
	elif [ $exit_code -eq 124 ]; then
		record_success "MemPalace launcher stayed running under timeout"
	elif [ $exit_code -eq 0 ]; then
		record_warning "MemPalace launcher exited without startup banner"
	else
		record_failure "MemPalace launcher starts cleanly"
		log_error "Launcher output:"
		cat "$output_file" >&2
		rm -f "$output_file"
		return 1
	fi

	rm -f "$output_file"
}

check_claude_mempalace_registration() {
	local claude_config="$HOME/.claude.json"
	local python_cmd="$HOME/.local/share/my-ai-tools/venvs/mempalace/bin/python"
	local launcher_path="$HOME/.ai-tools/bin/mempalace-mcp-launcher.py"

	if [ ! -f "$claude_config" ]; then
		record_failure "Claude user config exists at ~/.claude.json"
		return 1
	fi

	record_success "Claude user config exists at ~/.claude.json"

	check_text_in_file "$claude_config" "$python_cmd" "Claude MCP uses MemPalace venv python"
	check_text_in_file "$claude_config" "$launcher_path" "Claude MCP uses MemPalace launcher"

	if grep -Fq '"mempalace.mcp_server"' "$claude_config" && ! grep -Fq "$launcher_path" "$claude_config"; then
		record_failure "Claude MCP registration is still using direct mempalace.mcp_server"
	fi
}

check_amp_mempalace_registration() {
	local amp_settings_file="$HOME/.config/amp/settings.json"
	local python_cmd="$HOME/.local/share/my-ai-tools/venvs/mempalace/bin/python"
	local launcher_path="$HOME/.ai-tools/bin/mempalace-mcp-launcher.py"

	if [ ! -f "$amp_settings_file" ]; then
		record_warning "Amp settings not found at ~/.config/amp/settings.json"
		return 0
	fi

	record_success "Amp settings exist at ~/.config/amp/settings.json"
	check_text_in_file "$amp_settings_file" "$python_cmd" "Amp MCP uses MemPalace venv python"
	check_text_in_file "$amp_settings_file" "$launcher_path" "Amp MCP uses MemPalace launcher"

	if grep -Fq '"mempalace.mcp_server"' "$amp_settings_file" && ! grep -Fq "$launcher_path" "$amp_settings_file"; then
		record_failure "Amp MCP registration is still using direct mempalace.mcp_server"
	fi
}

check_codex_mempalace_registration() {
	local codex_config_file="$HOME/.codex/config.toml"
	local python_cmd="$HOME/.local/share/my-ai-tools/venvs/mempalace/bin/python"
	local launcher_path="$HOME/.ai-tools/bin/mempalace-mcp-launcher.py"

	if [ ! -f "$codex_config_file" ]; then
		record_warning "Codex config not found at ~/.codex/config.toml"
		return 0
	fi

	record_success "Codex config exists at ~/.codex/config.toml"
	check_text_in_file "$codex_config_file" "$python_cmd" "Codex MCP uses MemPalace venv python"
	check_text_in_file "$codex_config_file" "$launcher_path" "Codex MCP uses MemPalace launcher"

	if grep -Fq '"-m", "mempalace.mcp_server"' "$codex_config_file" || grep -Fq 'args = ["-m", "mempalace.mcp_server"]' "$codex_config_file"; then
		record_failure "Codex MCP registration is still using direct mempalace.mcp_server"
	fi
}

main() {
	log_info "Running my-ai-tools health check..."

	check_command "git" "Git is installed"
	check_any_command "Bun or Node.js is installed" "bun" "node"
	check_command "claude" "Claude Code is installed"

	check_directory "$HOME/.ai-tools" "~/.ai-tools directory exists"
	check_file "$HOME/.ai-tools/best-practices.md" "~/.ai-tools/best-practices.md is installed"
	check_file "$HOME/.ai-tools/git-guidelines.md" "~/.ai-tools/git-guidelines.md is installed"
	check_file "$HOME/.ai-tools/MEMORY.md" "~/.ai-tools/MEMORY.md is installed"

	check_directory "$HOME/.claude" "~/.claude directory exists"
	check_file "$HOME/.claude/settings.json" "~/.claude/settings.json exists"
	check_file "$HOME/.claude/mcp-servers.json" "~/.claude/mcp-servers.json exists"

	check_mempalace_launcher
	check_claude_mempalace_registration
	check_amp_mempalace_registration
	check_codex_mempalace_registration

	echo
	log_info "Health check summary: ${FAILURES} failure(s), ${WARNINGS} warning(s)"

	if [ "$FAILURES" -gt 0 ]; then
		exit 1
	fi
}

main "$@"
