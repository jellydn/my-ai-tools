#!/usr/bin/env bash
# PreToolUse guard: refuse agent edits to the my-ai-tools managed layer.
#
# Protected: ~/.ai-tools/** (guidelines, memory stores), ~/.claude/settings*.json
# and ~/.claude/hooks/** (the hook layer itself). Agents propose changes in the
# my-ai-tools repository and reinstall; hand-editing installed files silently
# drifts the fleet. This is the "agents loosened 7 of 58 CI checks" guard:
# the agent must not weaken its own rules.
#
# Read-only inspection (cat, ls, grep, jq, ...) stays allowed — workflows such
# as the retro skill read the managed memory stores. A shell command that
# touches a managed path must be recognisably read-only: anything else fails
# closed with a denial, including writers inside one interpreter (an inline
# python -c with open(..., 'w')). The file-tool denial is the reliable layer.
#
# Override for a single shell command: BEGIN the command with the exact token
# AI_TOOLS_EDIT_OK=1 (`AI_TOOLS_EDIT_OK=1 <command>`). Merely containing the
# token does not opt out. Exporting AI_TOOLS_EDIT_OK=1 for the session also
# allows file-tool edits.
#
# Reads one Claude Code hook-event JSON object on stdin; emits a deny
# decision on stdout. Fails open when jq is missing (the installer
# guarantees it).

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

if [ "${AI_TOOLS_EDIT_OK:-}" = "1" ]; then
	exit 0
fi

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')

target=""
case "$tool_name" in
Write | Edit | MultiEdit)
	target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
	;;
NotebookEdit)
	# NotebookEdit carries notebook_path, not file_path.
	target=$(printf '%s' "$input" | jq -r '.tool_input.notebook_path // empty')
	;;
Bash | PowerShell)
	target=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
	# An explicit opt-out is honoured only as the command's first token;
	# the token appearing elsewhere (in a comment, an argument, a message)
	# is not an opt-out.
	case "$target" in
	AI_TOOLS_EDIT_OK=1 | AI_TOOLS_EDIT_OK=1[[:space:]]*) exit 0 ;;
	esac
	;;
*)
	exit 0
	;;
esac

[ -n "$target" ] || exit 0

# Normalize both sides to forward slashes and collapse doubled separators: on
# Windows, Claude Code delivers file-tool paths with native backslashes even
# though hooks run under Git Bash, so escaped separators can arrive doubled,
# and HOME may be a drive-letter path (C:/Users/x) or an MSYS one (/c/Users/x)
# — both spellings of home are accepted as prefixes.
squeeze() {
	printf '%s' "$1" | sed -e 's|/\{2,\}|/|g' -e 's|/$||'
}
# One literal backslash, spelled in octal so the quoting pattern does
# not trip the SC1003 info check.
bs=$'\134'
home=$(squeeze "${HOME:-$(cd ~ && pwd)}")
userprofile=$(squeeze "${USERPROFILE:-${userprofile:-}}")
home=${home//"$bs"//}
userprofile=${userprofile//"$bs"//}

# Additional home spellings for prefix matching: the MSYS form of a
# drive-letter home, and the PowerShell env forms — literal, because the hook
# sees PowerShell text before the shell expands it, and as an environment
# variable for the Windows-native case.
alt_home=""
case "$home" in
[A-Za-z]:/*)
	drive=${home%%:*}
	rest=${home#*:}
	alt_home="/$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')${rest}"
	;;
/[A-Za-z]/*)
	drive=${home#/}
	drive=${drive%%/*}
	# Strip the leading /<drive>/ — '${home#?/}' matches nothing here,
	# because its first pattern char would have to be the leading slash
	# followed by another slash, which an MSYS home never has.
	alt_home="$(printf '%s' "$drive" | tr '[:lower:]' '[:upper:]'):/${home#/[A-Za-z]/}"
	;;
esac

target=${target//"$bs"//}
target=$(squeeze "$target")

# Quote removal for shell commands: a quoted managed path must not slip past
# the match, so matching runs on the command with quotes stripped. Path
# semantics are unchanged for the read/write intent patterns below.
matchtext="$target"
case "$tool_name" in
Bash | PowerShell)
	matchtext=${matchtext//\"/}
	matchtext=${matchtext//\'/}
	;;
esac

# The hook sees commands before the shell expands them, so the managed paths
# must match in every form the agent can write them in. File-tool paths are
# whole values; a shell command may contain the path anywhere.
# shellcheck disable=SC2016  # '$HOME' is matched literally on purpose
is_protected() {
	local p="$1"
	case "$tool_name" in
	Bash | PowerShell)
		case "$matchtext" in *"$p"*) return 0 ;; esac
		;;
	*)
		case "$target" in "$p" | "$p"/*) return 0 ;; esac
		;;
	esac
	return 1
}

# True when the command writes to the managed path $1 (which the caller has
# already established appears in the command).
bash_write_intent() {
	local p="$1" esc cmd
	esc=$(printf '%s' "$p" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g')
	# Redirection whose target is the managed path: > >> 2> 2>> &> &>> >| <>,
	# with optional whitespace and quotes between the operator and the path.
	# No boundary is required before the operator: `echo x> path` is a valid
	# redirect. A `>` inside a quoted string can therefore cause a false
	# denial, which errs on the safe side.
	if printf '%s' "$matchtext" | grep -Eq -- "((&|[0-9]+)?>{1,2}|<>)[|]?[[:space:]\"']*${esc}([[:space:]\"'/.]|$)"; then
		return 0
	fi
	# Commands that create, modify, move, link or remove their target.
	for cmd in rm mv cp tee touch truncate chmod chown ln rsync install dd; do
		if printf '%s' "$matchtext" | grep -Eq -- "(^|[;&|[:space:]])${cmd}[[:space:]]" &&
			printf '%s' "$matchtext" | grep -Eq -- "${esc}"; then
			return 0
		fi
	done
	# In-place editors: sed -i, perl -i/-pi.
	if printf '%s' "$matchtext" | grep -Eq -- "(^|[;&|[:space:]])(sed|perl)[[:space:]][^;&|]*-[a-zA-Z]*i" &&
		printf '%s' "$matchtext" | grep -Eq -- "${esc}"; then
		return 0
	fi
	return 1
}

# True when every command segment's first word is a read-only command. A
# managed path may appear only under such a command; anything unrecognised
# fails closed (the caller denies). Leading environment assignments are
# skipped, so `FOO=1 grep x <managed>` classifies as read-only.
readonly_command() {
	local rest="$1" seg word
	while [ -n "$rest" ]; do
		seg="${rest%%[;&|]*}"
		rest="${rest#"$seg"}"
		rest="${rest#[;&|]}"
		seg=${seg#"${seg%%[![:space:]]*}"}
		word=${seg%%[[:space:]]*}
		while case $word in [A-Za-z_]*=*) true ;; *) false ;; esac do
			seg=${seg#"$word"}
			seg=${seg#"${seg%%[![:space:]]*}"}
			word=${seg%%[[:space:]]*}
		done
		case $word in
		'') continue ;;
		# Allowlisted names write nothing themselves and delegate to
		# nothing: sort (-o), sed (w command), yq (-i) and delegates like
		# env/command are deliberately absent, because a first word alone
		# does not prove a command is read-only.
		cat | less | more | head | tail | grep | egrep | fgrep | rg | ripgrep | jq | ls | stat | file | wc | diff | cmp | sdiff | uniq | md5sum | shasum | sha1sum | sha256sum | md5 | cksum | basename | dirname | realpath | readlink | tree | bat | du | df | type | which | printenv | pwd | echo | printf | test | seq | date | true | false | Get-Content | Get-Item | Get-ChildItem | Test-Path | Measure-Object | Select-String) ;;
		*) return 1 ;;
		esac
	done
	return 0
}

deny() {
	jq -n \
		--arg reason "$1" \
		'{
			hookSpecificOutput: {
				hookEventName: "PreToolUse",
				permissionDecision: "deny",
				permissionDecisionReason: $reason
			}
		}'
	exit 0
}

DENY_REASON="$target is part of the my-ai-tools managed layer. Edit the my-ai-tools repository instead and reinstall (./cli.sh), or prefix a shell command with AI_TOOLS_EDIT_OK=1 for this one change."

mentioned=0
# shellcheck disable=SC2016  # '$HOME' is matched literally on purpose
for prefix in "$home" "$alt_home" "$userprofile" '~' '$HOME' '$env:USERPROFILE' '$env:userprofile'; do
	[ -n "$prefix" ] || continue
	for path in \
		"$prefix/.ai-tools" \
		"$prefix/.claude/settings.json" \
		"$prefix/.claude/settings.local.json" \
		"$prefix/.claude/hooks"; do
		if is_protected "$path"; then
			case "$tool_name" in
			Bash | PowerShell)
				mentioned=1
				if bash_write_intent "$path"; then
					deny "$DENY_REASON"
				fi
				;;
			*)
				deny "$DENY_REASON"
				;;
			esac
		fi
	done
	# File tools: cover the whole settings*.json family (snapshots such as
	# settings.backup.json) inside the protected .claude directory.
	case "$tool_name" in
	Bash | PowerShell) ;;
	*)
		# shellcheck disable=SC2254  # quoted prefix, glob on the filename
		case "$target" in
		"$prefix"/.claude/settings*.json) deny "$DENY_REASON" ;;
		esac
		;;
	esac
done

# Fail closed: a shell command that mentions a managed path but is not
# recognisably read-only is denied even when no specific write form matched.
case "$tool_name" in
Bash | PowerShell)
	if [ "$mentioned" = 1 ] && ! readonly_command "$matchtext"; then
		deny "$DENY_REASON"
	fi
	;;
esac

exit 0
