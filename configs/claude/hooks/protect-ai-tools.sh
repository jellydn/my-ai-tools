#!/usr/bin/env bash
# PreToolUse guard: refuse agent edits to the my-ai-tools managed layer.
#
# Protected: ~/.ai-tools/** (guidelines, memory stores), every
# ~/.claude/settings*.json snapshot and ~/.claude/hooks/** (the hook layer
# itself). Agents propose changes in the my-ai-tools repository and
# reinstall; hand-editing installed files silently drifts the fleet. This is
# the "agents loosened 7 of 58 CI checks" guard: the agent must not weaken
# its own rules.
#
# Read-only inspection (cat, ls, grep, jq, ...) stays allowed - workflows
# such as the retro skill read the managed memory stores. A shell command
# that touches a managed path must be recognisably read-only in EVERY
# segment: anything else fails closed with a denial. A writer in a later
# segment (after ; & | or a newline), a writer inside a command substitution
# ($(...) or `...`) or a process substitution, a redirect onto the managed
# path, and a diff --output/-o flag are all denials; uniq and sdiff are not
# on the allowlist because they can write an output-file operand, and sort
# (-o), sed (-i and its w command), yq (-i) and delegates like env and
# command stay off it too, because a first word alone does not prove a
# command is read-only. The file-tool denial is the reliable layer.
#
# Override for one shell command: begin the command with the exact token
# AI_TOOLS_EDIT_OK=1 (`AI_TOOLS_EDIT_OK=1 <command>`), or, in PowerShell,
# make the assignment $env:AI_TOOLS_EDIT_OK = '1' the first statement. The
# override covers the command it introduces only: `AI_TOOLS_EDIT_OK=1 true;
# <writer>` checks <writer> like any other command, and in PowerShell every
# statement after the assignment is checked too. Merely containing the token
# does not opt out. Exporting AI_TOOLS_EDIT_OK=1 for the session also allows
# file-tool edits.
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

NL=$'\n'
# One literal backslash, spelled in octal so the quoting pattern does
# not trip the SC1003 info check.
bs=$'\134'

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
	;;
*)
	exit 0
	;;
esac

[ -n "$target" ] || exit 0

# Normalize both sides to forward slashes, collapse doubled separators, and
# resolve . and .. path components textually: on Windows, Claude Code
# delivers file-tool paths with native backslashes even though hooks run
# under Git Bash, so escaped separators can arrive doubled, and HOME may be
# a drive-letter path (C:/Users/x) or an MSYS one (/c/Users/x) - both
# spellings of home are accepted as prefixes. The dot collapse closes the
# bypass $HOME/x/../.ai-tools/..., where the managed path hides behind a
# parent component a textual prefix match cannot see through.
squeeze() {
	printf '%s' "$1" | sed -E \
		-e ':dot' -e 's|/[.]/|/|g' -e 't dot' \
		-e ':up' -e 's|/[^/][^/]*/[.][.]/|/|g' -e 't up' \
		-e 's|/[.]$|/|' -e 's|/[.][.]$|/|' \
		-e 's|/{2,}|/|g' -e 's|/$||'
}
home=$(squeeze "${HOME:-$(cd ~ && pwd)}")
userprofile=$(squeeze "${USERPROFILE:-${userprofile:-}}")
home=${home//"$bs"//}
userprofile=${userprofile//"$bs"//}

# Additional home spelling for prefix matching: the MSYS form of a
# drive-letter home. The PowerShell env form stays literal, because the hook
# sees PowerShell text before the shell expands it; it is matched
# case-insensitively, because PowerShell environment-variable names are
# case-insensitive ($env:UserProfile and $env:USERPROFILE name one variable).
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
	# Strip the leading /<drive>/ - '${home#?/}' matches nothing here,
	# because its first pattern char would have to be the leading slash
	# followed by another slash, which an MSYS home never has.
	alt_home="$(printf '%s' "$drive" | tr '[:lower:]' '[:upper:]'):/${home#/[A-Za-z]/}"
	;;
esac

target=${target//"$bs"//}
target=$(squeeze "$target")

# Quote removal for shell commands: path DETECTION runs on the command with
# quotes stripped, so a quoted managed path cannot slip past the match.
# Classification splits segments first - quote-aware, because the shell
# treats a separator inside quotes as a literal character - and strips
# quotes per segment, so a quoted separator no longer fakes a boundary.
matchtext="$target"
case "$tool_name" in
Bash | PowerShell)
	matchtext=${matchtext//\"/}
	matchtext=${matchtext//\'/}
	;;
esac

# Escape a literal path for an extended regular expression.
esc_re() {
	printf '%s' "$1" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g'
}

# Detection: does the (quote-stripped) shell command name this protected
# path? The PowerShell env spelling is matched case-insensitively.
path_mentioned() {
	local p="$1"
	# shellcheck disable=SC2016  # the literal $env: prefix is matched on purpose
	case "$p" in
	'$env:'*)
		printf '%s' "$matchtext" | grep -Eiq -- "$(esc_re "$p")"
		return
		;;
	esac
	case "$matchtext" in
	*"$p"*) return 0 ;;
	esac
	return 1
}

# The settings*.json family for the shell path: settings.json,
# settings.local.json, settings.backup.json and any other snapshot sitting
# directly in .claude - but not a nested path such as
# .claude/settings-cache/report.json.
settings_regex() {
	printf '%s/[.]claude/settings[^/]*[.]json' "$(esc_re "$1")"
}
settings_mentioned() {
	local p="$1"
	# shellcheck disable=SC2016  # the literal $env: prefix is matched on purpose
	case "$p" in
	'$env:'*) printf '%s' "$matchtext" | grep -Eiq -- "$(settings_regex "$p")" ;;
	*) printf '%s' "$matchtext" | grep -Eq -- "$(settings_regex "$p")" ;;
	esac
}

# True when a command segment names the protected path $2: as a literal
# substring for a plain path, by (optionally case-insensitive) regex for the
# re:/rei: settings entries.
entry_present() {
	local seg="$1" entry="$2"
	case "$entry" in
	rei:*) printf '%s' "$seg" | grep -Eiq -- "${entry#rei:}" ;;
	re:*) printf '%s' "$seg" | grep -Eq -- "${entry#re:}" ;;
	*)
		case "$seg" in
		*"$entry"*) return 0 ;;
		esac
		return 1
		;;
	esac
}

# True when the segment redirects onto the protected path: > >> 2> 2>> &>
# &>> >| <>, with optional whitespace and quotes between the operator and
# the path. No boundary is required before the operator: `echo x> path` is
# a valid redirect. A `>` inside a quoted string can therefore cause a
# false denial, which errs on the safe side.
redirects_to() {
	local seg="$1" entry="$2" pat
	case "$entry" in
	rei:*)
		pat="${entry#rei:}"
		printf '%s' "$seg" | grep -Eiq -- "((&|[0-9]+)?>{1,2}|<>)[|]?[[:space:]\"]*$pat([[:space:]\"'/.]|$)"
		;;
	re:*)
		pat="${entry#re:}"
		printf '%s' "$seg" | grep -Eq -- "((&|[0-9]+)?>{1,2}|<>)[|]?[[:space:]\"]*$pat([[:space:]\"'/.]|$)"
		;;
	*)
		pat=$(esc_re "$entry")
		printf '%s' "$seg" | grep -Eq -- "((&|[0-9]+)?>{1,2}|<>)[|]?[[:space:]\"]*$pat([[:space:]\"'/.]|$)"
		;;
	esac
}

# Split a shell command into segments at ; & | and newline, quote-aware: a
# separator inside single or double quotes is a literal character, exactly
# as the shell will treat it. Quotes themselves are dropped; an unterminated
# quote ends the last segment.
split_segments() {
	local s="$1" out="" q="" c i
	for ((i = 0; i < ${#s}; i++)); do
		c=${s:i:1}
		if [ -n "$q" ]; then
			if [ "$c" = "$q" ]; then
				q=""
			else
				out+=$c
			fi
		elif [ "$c" = "'" ] || [ "$c" = '"' ]; then
			q=$c
		elif [ "$c" = ';' ] || [ "$c" = '&' ] || [ "$c" = '|' ] || [ "$c" = "$NL" ]; then
			printf '%s' "$out$NL"
			out=""
		else
			out+=$c
		fi
	done
	[ -n "$out" ] && printf '%s' "$out$NL"
	return 0
}

# True when this segment, on its own, requires a denial: it names one of the
# mentioned protected paths and is not recognisably read-only.
segment_denies() {
	local seg="$1" mentions="$2" entry word
	# A command substitution, backtick or process substitution cannot be
	# classified: a writer can hide inside it ($(touch ...), cat $(rm ...),
	# `rm ...`). If the segment also names a managed path, fail closed -
	# even when the substitution sits inside double quotes, where the shell
	# would expand it.
	# shellcheck disable=SC2016  # the literal $( and backtick probes are matched on purpose
	case "$seg" in
	*'$('* | *'`'* | *'<('*)
		while IFS= read -r entry; do
			[ -n "$entry" ] || continue
			if entry_present "$seg" "$entry"; then return 0; fi
		done <<<"$mentions"
		;;
	esac
	# Redirection onto a managed path denies, whatever the first word is.
	while IFS= read -r entry; do
		[ -n "$entry" ] || continue
		if redirects_to "$seg" "$entry"; then return 0; fi
	done <<<"$mentions"
	# Junk from splitting redirect decorations (2>&1 becomes a segment `1`,
	# &>file a segment `>file`): a first token made only of redirect
	# characters is not a command. Its target was already checked above.
	word=${seg%%[[:space:]]*}
	if printf '%s' "$word" | grep -Eq '^[&0-9<>]+$'; then
		case "$word" in
		*['<>']*)
			# A redirect operator consumes the token after it as its target.
			seg=${seg#"$word"}
			seg=${seg#"${seg%%[![:space:]]*}"}
			word=${seg%%[[:space:]]*}
			seg=${seg#"$word"}
			seg=${seg#"${seg%%[![:space:]]*}"}
			;;
		*)
			seg=${seg#"$word"}
			seg=${seg#"${seg%%[![:space:]]*}"}
			;;
		esac
	fi
	# Leading environment assignments are skipped, so
	# `FOO=1 grep x <managed>` classifies as read-only.
	word=${seg%%[[:space:]]*}
	while case $word in [A-Za-z_][A-Za-z_0-9]*=*) true ;; *) false ;; esac do
		seg=${seg#"$word"}
		seg=${seg#"${seg%%[![:space:]]*}"}
		word=${seg%%[[:space:]]*}
	done
	case "$word" in
	'') return 1 ;;
	esac
	# diff writes a file with --output=FILE or -o FILE.
	if [ "$word" = diff ]; then
		while IFS= read -r entry; do
			[ -n "$entry" ] || continue
			if printf '%s' "$seg" | grep -Eq -- '(^|[[:space:]])(-o([[:space:]]|$)|--output=?)' &&
				entry_present "$seg" "$entry"; then
				return 0
			fi
		done <<<"$mentions"
	fi
	# Every first word must be on the read-only allowlist; anything
	# unrecognised fails closed, which is what catches the writers (rm, tee,
	# sed -i, python -c, ...) without a per-writer list.
	case "$word" in
	cat | less | more | head | tail | grep | egrep | fgrep | rg | ripgrep | jq | ls | stat | file | wc | diff | cmp | md5sum | shasum | sha1sum | sha256sum | md5 | cksum | basename | dirname | realpath | readlink | tree | bat | du | df | type | which | printenv | pwd | echo | printf | test | seq | date | true | false | Get-Content | Get-Item | Get-ChildItem | Test-Path | Measure-Object | Select-String) return 1 ;;
	*) return 0 ;;
	esac
}

# True when the shell command needs a denial. Splits the command into
# segments and requires every segment to be recognisably read-only, with the
# one-command override honoured for the segment it introduces only.
classify_shell() {
	local raw="$1" mentions="$2" segs seg first=1 opted=0 val
	segs=$(split_segments "$raw")
	while IFS= read -r seg; do
		[ -n "$seg" ] || continue
		seg=${seg#"${seg%%[![:space:]]*}"}
		if [ "$first" -eq 1 ]; then
			first=0
			case "$seg" in
			# The Bash one-command override: the token begins the command.
			AI_TOOLS_EDIT_OK=1 | AI_TOOLS_EDIT_OK=1[[:space:]]*) continue ;;
			esac
			# The PowerShell one-command override: the assignment is the
			# first statement and opts out the statement that follows it.
			if printf '%s' "$seg" | grep -Eiq '^[$]env:AI_TOOLS_EDIT_OK[[:space:]]*='; then
				val=$(printf '%s' "${seg#*=}" | tr -cd '0-9')
				if [ "$val" = 1 ]; then
					opted=1
					continue
				fi
			fi
		fi
		if [ "$opted" -eq 1 ]; then
			opted=0
			continue
		fi
		if segment_denies "$seg" "$mentions"; then return 0; fi
	done <<<"$segs"
	return 1
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

DENY_REASON="$target is part of the my-ai-tools managed layer. Edit the my-ai-tools repository instead and reinstall (./cli.sh). For one shell command, begin it with AI_TOOLS_EDIT_OK=1 (Bash) or make the assignment \$env:AI_TOOLS_EDIT_OK = '1' the first statement (PowerShell). Exporting AI_TOOLS_EDIT_OK=1 for the session also allows file-tool edits."

# shellcheck disable=SC2016  # '$HOME' and the env spellings are matched literally on purpose
for prefix in "$home" "$alt_home" "$userprofile" '~' '$HOME' '$env:USERPROFILE'; do
	[ -n "$prefix" ] || continue
	case "$tool_name" in
	Bash | PowerShell) ;;
	*)
		# File tools: whole-value match. The plain paths must be the target
		# itself or sit directly under it; the settings*.json family uses
		# the same rule as the shell regex below - any snapshot directly
		# inside .claude, but not a nested path such as
		# .claude/settings-cache/report.json.
		for path in "$prefix/.ai-tools" "$prefix/.claude/hooks"; do
			case "$target" in
			"$path" | "$path"/*) deny "$DENY_REASON" ;;
			esac
		done
		case "$target" in
		"$prefix"/.claude/settings*)
			rest=${target#"$prefix"/.claude/settings}
			case "$rest" in
			*/*) ;;
			*.json) deny "$DENY_REASON" ;;
			esac
			;;
		esac
		;;
	esac
done

case "$tool_name" in
Bash | PowerShell) ;;
*) exit 0 ;;
esac

# Shell commands: collect the protected paths the command names, then
# require every segment to be recognisably read-only.
mentions=""
# shellcheck disable=SC2016  # '$HOME' and the env spelling are matched literally on purpose
for prefix in "$home" "$alt_home" "$userprofile" '~' '$HOME' '$env:USERPROFILE'; do
	[ -n "$prefix" ] || continue
	for path in "$prefix/.ai-tools" "$prefix/.claude/hooks"; do
		if path_mentioned "$path"; then
			mentions+="$path"$NL
		fi
	done
	if settings_mentioned "$prefix"; then
		case "$prefix" in
		'$env:'*) mentions+="rei:$(settings_regex "$prefix")"$NL ;;
		*) mentions+="re:$(settings_regex "$prefix")"$NL ;;
		esac
	fi
done

if [ -n "$mentions" ] && classify_shell "$target" "$mentions"; then
	deny "$DENY_REASON"
fi

exit 0
