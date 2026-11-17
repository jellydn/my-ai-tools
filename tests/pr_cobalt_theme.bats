#!/usr/bin/env bats
# Tests for the Cobalt theme additions across tools

load helpers

ROOT="$REPO_ROOT/configs"

@test "pi cobalt theme exists and is valid JSON" {
	[ -f "$ROOT/pi/themes/cobalt.json" ]
	run jq -r '.name' "$ROOT/pi/themes/cobalt.json"
	[ "$output" = "cobalt" ]
}

@test "pi settings selects the cobalt theme" {
	run jq -r '.theme' "$ROOT/pi/settings.json"
	[ "$output" = "cobalt" ]
}

@test "codex cobalt tmTheme exists and is named cobalt" {
	[ -f "$ROOT/codex/themes/cobalt.tmTheme" ]
	run python3 -c "import plistlib,sys; print(plistlib.loads(open('$ROOT/codex/themes/cobalt.tmTheme','rb').read())['name'])"
	[ "$output" = "cobalt" ]
}

@test "codex config selects the cobalt theme" {
	run grep -F 'theme = "cobalt"' "$ROOT/codex/config.toml"
	[ "$status" -eq 0 ]
}

@test "amp selects the cobalt terminal theme" {
	run jq -r '."amp.terminal.theme"' "$ROOT/amp/settings.json"
	[ "$output" = "cobalt" ]
	run jq -r '."amp.terminal.customThemes" | has("cobalt")' "$ROOT/amp/settings.json"
	[ "$output" = "true" ]
}

@test "reasonix cobalt theme is staged as a custom theme" {
	[ -f "$ROOT/reasonix/themes/cobalt/theme.json" ]
	run jq -r '.id' "$ROOT/reasonix/themes/cobalt/theme.json"
	[ "$output" = "cobalt" ]
	run jq -r '.schemaVersion' "$ROOT/reasonix/themes/cobalt/theme.json"
	[ "$output" = "2" ]
	run jq -r '.tokens.dark.bg' "$ROOT/reasonix/themes/cobalt/theme.json"
	[ "$output" = "#193549" ]
}

@test "reasonix config selects cobalt in ui and desktop theme_style" {
	run awk '
		/^\[ui\]/ { in_ui = 1; next }
		/^\[desktop\]/ { in_ui = 0; in_desktop = 1; next }
		/^\[/ { in_ui = 0; in_desktop = 0; next }
		# Match only uncommented assignments (a "# theme_style" comment must not count).
		in_ui && /^[[:space:]]*theme_style[[:space:]]*=[[:space:]]*"cobalt"/ { ui_cobalt = 1 }
		in_desktop && /^[[:space:]]*theme_style[[:space:]]*=[[:space:]]*"cobalt"/ { desktop_cobalt = 1 }
		END { exit (ui_cobalt && desktop_cobalt) ? 0 : 1 }
	' "$ROOT/reasonix/config.toml"
	[ "$status" -eq 0 ]
}

@test "hunk config selects the cobalt custom theme" {
	run grep -F 'theme = "cobalt2"' "$ROOT/hunk/config.toml"
	[ "$status" -eq 0 ]
	run grep -F '[themes.cobalt2]' "$ROOT/hunk/config.toml"
	[ "$status" -eq 0 ]
	run grep -F '[themes.cobalt2.syntax_scopes]' "$ROOT/hunk/config.toml"
	[ "$status" -eq 0 ]
}
