#!/usr/bin/env bats

load helpers

@test "Dokku sync reports only the key fingerprint and app state, then uses app-first encoded config" {
	run bash -c '
		set -e
		export HOME="$(mktemp -d)"
		trap '\''rm -rf "$HOME"'\'' EXIT
		export DOKKU_SSH_PRIVATE_KEY=$'\''fixture\r\nkey'\''
		export OPENROUTER_API_KEY=" sk-or-v1-fixture " OPENAI_API_KEY=""
		export DOKKU_HOST=example.invalid DOKKU_APP=ai-tools
		export CALL_LOG="$HOME/calls"
		ssh-keygen() {
			if [ "$1" = -y ]; then
				[ "$(cat "$HOME/.ssh/dokku_deploy")" = $'\''fixture\nkey'\'' ] || return 19
				echo fixture-public-key
			else
				[ "$*" = "-lf -" ] && [ "$(cat)" = fixture-public-key ] || return 20
				echo "256 SHA256:fixture (ED25519)"
			fi
		}
		ssh-keyscan() { echo fixture-known-host; }
		ssh() {
			printf "%s\n" "$*" >>"$CALL_LOG"
			case "$*" in
			*"ps:report ai-tools") echo app-state ;;
			*"config:set ai-tools --encoded --no-restart "*) echo sensitive-server-output ;;
			*) return 21 ;;
			esac
		}
		export -f ssh-keygen ssh-keyscan ssh
		awk '\''
			/- name: Sync OpenRouter API key to Dokku/ { step=1; next }
			step && /        run: \|/ { body=1; next }
			body && /      - name:/ { exit }
			body { sub(/^          /, ""); sub(/\r$/, ""); print }
		'\'' "$1/.github/workflows/dokku.yml" >"$HOME/sync.sh"
		bash -e -o pipefail "$HOME/sync.sh"
		[ "$(wc -l <"$CALL_LOG")" -eq 2 ]
		head -1 "$CALL_LOG" | grep -F "ps:report ai-tools"
		tail -1 "$CALL_LOG" | grep -F "config:set ai-tools --encoded --no-restart"
		tail -1 "$CALL_LOG" | grep -F "OPENAI_API_KEY=$(printf sk-or-v1-fixture | base64 -w 0)"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"SHA256:fixture"* ]]
	[[ "$output" == *"app-state"* ]]
	[[ "$output" != *"fixture-public-key"* ]]
	[[ "$output" != *"sensitive-server-output"* ]]
}
