#!/bin/bash
# Reasonix Setup Hook
# Initializes local environment, verifies directory structure, and validates configuration.

set -euo pipefail

REASONIX_DIR="${REASONIX_DIR:-$HOME/.reasonix}"

echo "[reasonix setup-hook] Initializing Reasonix configuration in $REASONIX_DIR..."

mkdir -p "$REASONIX_DIR/hooks"
mkdir -p "$REASONIX_DIR/themes"

if [ -f "$REASONIX_DIR/config.toml" ]; then
	echo "[reasonix setup-hook] Validating config.toml syntax..."
	if command -v python3 &>/dev/null; then
		if python3 -c 'import tomllib' &>/dev/null; then
			FILEPATH="$REASONIX_DIR/config.toml" python3 -c 'import os, tomllib; tomllib.loads(open(os.environ["FILEPATH"]).read())'
			echo "[reasonix setup-hook] config.toml is valid TOML"
		fi
	fi
fi

if [ -d "$REASONIX_DIR/hooks" ]; then
	for hook in "$REASONIX_DIR/hooks"/*.sh; do
		if [ -f "$hook" ]; then
			chmod +x "$hook"
		fi
	done
fi

if [ -f "$REASONIX_DIR/statusline.sh" ]; then
	chmod +x "$REASONIX_DIR/statusline.sh"
fi

echo "[reasonix setup-hook] Setup completed successfully."
