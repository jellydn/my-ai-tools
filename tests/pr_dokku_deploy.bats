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
			*"config:export ai-tools --format shell"*) echo "export OPENAI_EMBEDDING_MODEL='nvidia/previous-model'" ;;
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
		[ "$(wc -l <"$CALL_LOG")" -eq 3 ]
		head -1 "$CALL_LOG" | grep -F "ps:report ai-tools"
		sed -n 2p "$CALL_LOG" | grep -F "config:export ai-tools --format shell"
		tail -1 "$CALL_LOG" | grep -F "config:set ai-tools --encoded --no-restart"
		tail -1 "$CALL_LOG" | grep -F "OPENAI_API_KEY=$(printf sk-or-v1-fixture | base64 -w 0)"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"SHA256:fixture"* ]]
	[[ "$output" == *"app-state"* ]]
	[[ "$output" != *"fixture-public-key"* ]]
	[[ "$output" != *"sensitive-server-output"* ]]
}
@test "Dokku rollback restores the model only when the sync changed config" {
	run bash -c '
		set -e
		export HOME="$(mktemp -d)"
		trap '"'"'rm -rf "$HOME"'"'"' EXIT
		export DOKKU_SSH_PRIVATE_KEY=$'"'"'fixture\r\nkey'"'"'
		export DOKKU_HOST=example.invalid DOKKU_APP=ai-tools
		export RUNNER_TEMP="$HOME/rt"
		export CALL_LOG="$HOME/calls"
		rm -rf "$RUNNER_TEMP"; mkdir -p "$RUNNER_TEMP"
		ssh-keygen() {
			if [ "$1" = -y ]; then
				[ "$(cat "$HOME/.ssh/dokku_deploy")" = $'"'"'fixture\nkey'"'"' ] || return 19
				echo fixture-public-key
			else
				[ "$*" = "-lf -" ] && [ "$(cat)" = fixture-public-key ] || return 20
				echo "256 SHA256:fixture (ED25519)"
			fi
		}
		ssh-keyscan() { echo fixture-known-host; }
		ssh() { printf "%s\n" "$*" >>"$CALL_LOG"; return 0; }
		export -f ssh-keygen ssh-keyscan ssh
		awk '\''
			/- name: Restore previous embedding model on deploy failure/ { step=1; next }
			step && /        run: \|/ { body=1; next }
			body { sub(/^          /, ""); sub(/\r$/, ""); print }
		'\'' "$1/.github/workflows/dokku.yml" >"$HOME/restore.sh"

		# Case 1: no marker (config was never changed) -> rollback is a no-op.
		: > "$CALL_LOG"
		set +e
		bash -e -o pipefail "$HOME/restore.sh"; s1=$?
		set -e
		[ "$s1" -eq 0 ] || return 30
		[ ! -s "$CALL_LOG" ] || return 31

		# Case 2: marker holds a previous model -> restore it via encoded config:set.
		: > "$CALL_LOG"
		printf "%s" "nvidia/previous-model" > "$RUNNER_TEMP/previous_embedding_model"
		bash -e -o pipefail "$HOME/restore.sh"
		grep -F "config:set ai-tools --encoded --no-restart" "$CALL_LOG" >/dev/null || return 32
		grep -F "OPENAI_EMBEDDING_MODEL=$(printf nvidia/previous-model | base64 -w 0)" "$CALL_LOG" >/dev/null || return 33

		# Case 3: empty marker (previously unset) -> unset the model.
		: > "$CALL_LOG"
		: > "$RUNNER_TEMP/previous_embedding_model"
		bash -e -o pipefail "$HOME/restore.sh"
		grep -F "config:unset ai-tools --no-restart OPENAI_EMBEDDING_MODEL" "$CALL_LOG" >/dev/null || return 34
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}
@test "Dokku sync aborts without changing config when reading the model fails" {
	run bash -c '
		set -e
		export HOME="$(mktemp -d)"
		trap '"'"'rm -rf "$HOME"'"'"' EXIT
		export DOKKU_SSH_PRIVATE_KEY=$'"'"'fixture\r\nkey'"'"'
		export OPENROUTER_API_KEY=" sk-or-v1-fixture " OPENAI_API_KEY=""
		export DOKKU_HOST=example.invalid DOKKU_APP=ai-tools
		export RUNNER_TEMP="$HOME/rt"
		export CALL_LOG="$HOME/calls"
		rm -rf "$RUNNER_TEMP"; mkdir -p "$RUNNER_TEMP"
		ssh-keygen() {
			if [ "$1" = -y ]; then echo fixture-public-key; else echo "256 SHA256:fixture (ED25519)"; fi
		}
		ssh-keyscan() { echo fixture-known-host; }
		ssh() {
			printf "%s\n" "$*" >>"$CALL_LOG"
			case "$*" in
			*"config:export ai-tools --format shell"*) return 30 ;;
			*) return 0 ;;
			esac
		}
		export -f ssh-keygen ssh-keyscan ssh
		awk '\''
			/- name: Sync OpenRouter API key to Dokku/ { step=1; next }
			step && /        run: \|/ { body=1; next }
			body && /      - name:/ { exit }
			body { sub(/^          /, ""); sub(/\r$/, ""); print }
		'\'' "$1/.github/workflows/dokku.yml" >"$HOME/sync.sh"
		set +e
		bash -e -o pipefail "$HOME/sync.sh"; rc=$?
		set -e
		[ "$rc" -ne 0 ] || return 40
		grep -F "config:set ai-tools" "$CALL_LOG" >/dev/null && return 41 || true
		[ ! -e "$RUNNER_TEMP/previous_embedding_model" ] || return 42
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}
@test "Dokku sync proceeds when the embedding model was never configured" {
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
			*"config:export ai-tools --format shell"*) echo "export OPENAI_BASE_URL='https://openrouter.ai/api/v1'" ;;
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
		[ "$(wc -l <"$CALL_LOG")" -eq 3 ]
		head -1 "$CALL_LOG" | grep -F "ps:report ai-tools"
		sed -n 2p "$CALL_LOG" | grep -F "config:export ai-tools --format shell"
		tail -1 "$CALL_LOG" | grep -F "config:set ai-tools --encoded --no-restart"
		tail -1 "$CALL_LOG" | grep -F "OPENAI_API_KEY=$(printf sk-or-v1-fixture | base64 -w 0)"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"SHA256:fixture"* ]]
	[[ "$output" == *"app-state"* ]]
	[[ "$output" != *"fixture-public-key"* ]]
	[[ "$output" != *"sensitive-server-output"* ]]
}
