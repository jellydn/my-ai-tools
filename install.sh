#!/bin/bash

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

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

	# Create temporary directory
	TEMP_DIR=$(mktemp -d)
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
	log_info "Running installation script..."
	cd "$TEMP_DIR"
	bash cli.sh "$@"

	log_success "Installation complete!"
}

main "$@"
