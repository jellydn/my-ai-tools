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
# Only the portable bot roster is managed; see configs/openmausbot/README.md.
install_openmausbot() {
	# The headless CLI and the desktop app are independent: a desktop-app user
	# still wants the CLI, and the CLI on PATH does not mean the app is
	# installed. So each is checked on its own.
	if command -v openmausbot >/dev/null 2>&1; then
		log_success "OpenMausBot CLI already installed"
	else
		# The npm package provides the headless CLI. The chat app itself is a
		# desktop download from the releases page.
		install_npm_tool "OpenMausBot CLI" "openmausbot" "openmausbot" \
			"npm install -g openmausbot" \
			"openmausbot --help 2>/dev/null | head -1 || true"
	fi

	log_info "Desktop chat app: download from https://github.com/milind-soni/OpenMausBot/releases/latest"
}
