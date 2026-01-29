#!/bin/bash

set -e

# Inline logging functions (needed before repo is cloned)
# Output to stderr to avoid interfering with command substitution
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
	echo -e "${BLUE}ℹ ${NC}$1" >&2
}

log_success() {
	echo -e "${GREEN}✓${NC} $1" >&2
}

log_warning() {
	echo -e "${YELLOW}⚠${NC} $1" >&2
}

log_error() {
	echo -e "${RED}✗${NC} $1" >&2
}

# Check prerequisites
check_prerequisites() {
	local missing_tools=()

	if ! command -v git &>/dev/null; then
		missing_tools+=("git")
	fi

	if ! command -v bash &>/dev/null; then
		missing_tools+=("bash")
	fi

	if [ ${#missing_tools[@]} -gt 0 ]; then
		log_error "Missing required tools: ${missing_tools[*]}"
		log_info "Please install the missing tools and try again"
		exit 1
	fi
}

main() {
	log_info "Starting my-ai-tools installation..."

	check_prerequisites

	# Set up TMPDIR to avoid cross-device link errors
	# Use a location within $HOME to ensure same filesystem
	local tmp_dir="$HOME/.claude/tmp"
	mkdir -p "$tmp_dir" 2>/dev/null || true
	export TMPDIR="$tmp_dir"

	# Create temporary directory
	TEMP_DIR=$(mktemp -d -p "$tmp_dir")
	trap 'rm -rf "$TEMP_DIR"' EXIT INT TERM

	log_info "Cloning repository to temporary directory..."
	if ! git clone --depth 1 https://github.com/jellydn/my-ai-tools.git "$TEMP_DIR"; then
		log_error "Failed to clone repository"
		log_info "Please check your internet connection and try again"
		log_info "If the problem persists, the repository URL may have changed"
		exit 1
	fi

	log_success "Repository cloned successfully"

	# Run the installation script with all arguments passed to this script
	# Add --yes flag if running in non-interactive mode (piped input)
	log_info "Running installation script..."
	cd "$TEMP_DIR"
	if [ -t 0 ]; then
		# Interactive mode
		bash cli.sh "$@"
	else
		# Non-interactive mode (piped) - auto-accept all prompts
		bash cli.sh --yes "$@"
	fi

	log_success "Installation complete!"
}

main "$@"
