---
name: amp-orb
description: "Run Amp orbs on this Mac with smolvm. Use for provider itman-vm, ~/src/tries, and the amp-orb controller."
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when starting, checking, or explaining self-hosted Amp orbs on this Mac
user-invocable: true
metadata:
  audience: all
  workflow: terminal-automation
---

# Amp orbs on this Mac

This Mac hosts Amp orbs with [smolvm](https://github.com/smol-machines/smolvm). The provider name is `itman-vm`. One token serves that provider. The token is saved for `https://ampcode.com/`. Leave the token unprinted.

The host directory `~/src/tries` is the guest directory `/home/user/tries`.

## Controller

The controller runs in tmux session `amp-orb`.

```bash
tmux has-session -t amp-orb && tmux capture-pane -p -t amp-orb -S -30
```

`READY` and `listening for jobs` means the controller is up. Attach with `tmux attach -t amp-orb`. Ctrl-C drains running jobs. Logs are `~/.cache/amp/logs/orb-provider`.

Start a controller only when that session is absent:

```bash
tmux new-session -d -s amp-orb -c "$HOME/src/tries" \
  /opt/homebrew/bin/fish -C 'source ~/.config/fish/config.fish' -c 'amp-orb'
```

`amp-orb` is the fish function in the dotfiles. It changes to `~/src/tries`, selects the arm64 orb image on Apple Silicon, and runs:

```bash
amp orb provider "$HOME/.config/amp/orb-dispatch.sh"
```

The dispatch script is `configs/amp/orb-dispatch.sh` in this repository. `./cli.sh` links it to `~/.config/amp/orb-dispatch.sh`.

## Orb shape

| Item | Value |
| --- | --- |
| Image | `us-central1-docker.pkg.dev/amp-prod-0/amp-orb/amp-orb-arm64:latest` on Apple Silicon |
| CPU | 4 (`ORB_CPUS`) |
| Memory | 8192 MiB cap (`ORB_MEMORY_MIB`) |
| Disk | 40 GiB (`ORB_STORAGE_GIB`) |
| Network | on |
| Pause | `smolvm machine pause` saves RAM and disk |
| Delete | `smolvm machine delete --force` removes the machine |
| Snapshot | checkpoint under `${XDG_STATE_HOME:-~/.local/state}/amp-orbs/snapshots/`, with `--host-mounts` |

The first spawn downloads the arm64 image. Keep the Mac awake while orbs run. The guest process is the image user `user`.

## New Mac

```bash
brew install smol-machines/tap/smolvm
```

mise requests `brew:smol-machines/tap/smolvm` from `common/.config/mise/config.macos.toml`.

Create the provider only when `~/.local/share/amp/secrets.json` has no `orb-provider-token@https://ampcode.com/` entry:

```bash
amp orb provider create itman-vm
```

That command prints the token once. Keep that output private.

## Thread

Choose provider `itman-vm` for the orb thread. The guest working directory is `/home/user/tries`.
