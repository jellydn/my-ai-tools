#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
	echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
	echo -e "${GREEN}✔${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
	echo -e "${RED}✖${NC} $1"
}

# Check prerequisites
check_prerequisites() {
	if ! command -v git &>/dev/null; then
		log_error "Git is not installed. Please install Git first."
		exit 1
	fi
}

main() {
	log_info "Starting my-ai-tools installation..."

	check_prerequisites

	# Create temporary directory
	TEMP_DIR=$(mktemp -d)
	trap 'rm -rf "$TEMP_DIR"' EXIT

	log_info "Cloning repository to temporary directory..."
	if ! git clone --depth 1 https://github.com/jellydn/my-ai-tools.git "$TEMP_DIR" &>/dev/null; then
		log_error "Failed to clone repository"
		exit 1
	fi

	log_success "Repository cloned successfully"

	# Run the installation script with all arguments passed to this script
	log_info "Running installation script..."
	cd "$TEMP_DIR"
	bash cli.sh "$@"

	log_success "Installation complete!"
	log_info "Temporary files have been cleaned up"
}

main "$@"
