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

@test "amp keeps the default theme and stages cobalt as an option" {
	run jq -r '."amp.terminal.theme"' "$ROOT/amp/settings.json"
	[ "$output" = "kanagawa" ]
	run jq -r '."amp.terminal.customThemes" | has("cobalt")' "$ROOT/amp/settings.json"
	[ "$output" = "true" ]
	run jq -r '."amp.terminal.customThemes" | has("kanagawa")' "$ROOT/amp/settings.json"
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

@test "reasonix config keeps theme_style disabled (staged only)" {
	run grep -F 'theme_style = "cobalt"' "$ROOT/reasonix/config.toml"
	[ "$status" -eq 1 ]
}

@test "hunk config selects the cobalt custom theme" {
	run grep -F 'theme = "cobalt2"' "$ROOT/hunk/config.toml"
	[ "$status" -eq 0 ]
	run grep -F '[themes.cobalt2]' "$ROOT/hunk/config.toml"
	[ "$status" -eq 0 ]
	run grep -F '[themes.cobalt2.syntax_scopes]' "$ROOT/hunk/config.toml"
	[ "$status" -eq 0 ]
}
