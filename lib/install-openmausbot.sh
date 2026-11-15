#!/bin/bash
# OpenMausBot installation.
# Source this file from lib/install.sh AFTER the prerequisite and launcher modules.
#
# Requires: lib/common.sh, lib/install.sh (for install_npm_tool and run_installer)

# OpenMausBot (github.com/milind-soni/OpenMausBot) is a desktop chat app whose
# bots run local agent CLIs (Claude, Codex, Grok). It ships released builds
# (DMG / EXE / DEB / AppImage) plus an npm package for the headless server
# CLI (`openmausbot serve`, `openmausbot team apply`, `openmausbot run`).
# Application state lives in the data directory (upstream: OMB_DATA_DIR,
# otherwise ~/.openmausbot) and is live runtime data, so this repository never
# installs, exports, or commits its credentials, transcripts, or databases.
# generate.sh can export the portable bot roster on explicit opt-in; see
# configs/openmausbot/README.md.
install_openmausbot() {
	# The npm package is only the headless CLI; the chat app is a separate
	# desktop download.
	log_info "Desktop chat app: download from https://github.com/milind-soni/OpenMausBot/releases/latest"

	if command -v openmausbot >/dev/null 2>&1; then
		log_success "OpenMausBot CLI already installed"
		return 0
	fi

	# The npm package declares engines.node >=24. npm only warns on an engine
	# mismatch, so check first instead of installing a CLI that cannot start.
	local node_major
	node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null) || node_major=""
	if ! [[ "$node_major" =~ ^[0-9]+$ ]] || [ "$node_major" -lt 24 ]; then
		log_error "The OpenMausBot CLI requires Node.js 24 or newer (found: $(node --version 2>/dev/null || echo none))."
		return 1
	fi

	install_npm_tool "OpenMausBot CLI" "openmausbot" "openmausbot" \
		"npm install -g openmausbot" \
		"openmausbot --help 2>/dev/null | head -1 || true"
}
