# Pi Durable on a private VPS

This opt-in setup runs the **official experimental Pi Durable TUI**, pinned to
Pi 1.0.4, in a supervised terminal on a Linux VPS. Your Mac attaches through
ordinary OpenSSH over Tailscale. There is no HTTP server, public agent port,
Tailscale Funnel, or shared database mount. `cli.sh` does not install this setup.

```text
Mac terminal → Tailscale → VPS sshd → dedicated account → tmux → Durable TUI
                                                           → local SQLite
                                                           → model provider
```

## Scope and trust boundary

This extends [issue #419](https://github.com/jellydn/my-ai-tools/issues/419), which
originally excluded Durable installation. Keep normal Pi settings unchanged:
Codemode remains opt-in, `tuiMode` stays `regular`, and `lastChangelogVersion`
stays `1.0.3` so installation does not hide unread release notes. Durable is not
a `settings.json` package or setting. The experimental TUI does not support the
normal extension system or `/login`.

Use a dedicated, non-sudo Linux account on a non-production VPS. Do not give it
Docker access, SSH agent forwarding, production repositories, or unrelated
secrets. Pi's coding tools can execute commands and read files as that account.
`NoNewPrivileges` is not a filesystem or network sandbox. The account can read
its own provider credentials; use a low-limit, revocable provider credential.
For hostile repositories, use a separate disposable VM rather than this account.

## Phase 1: prepare access (administrator, on the actual hosts)

1. Confirm a working Mac SSH connection using the existing SSH configuration and
   key. Keep this connection and the VPS provider console available throughout
   network changes. Do not disable host-key verification or copy a private key
   to the VPS. Verify a new host fingerprint through the provider console.
2. Install Tailscale on the Mac and VPS using the
   [official installation instructions](https://tailscale.com/download).
   Authenticate through Tailscale's browser login on each host; do not place
   reusable auth keys in shell history, this repository, or chat.
3. In the tailnet policy, allow only the chosen Mac/user to the chosen VPS on
   TCP port 22. Replace the default allow-all rule if present: adding a narrow
   rule does not revoke an existing broad grant. Have the tailnet owner review
   the complete policy and its policy tests. Do not enable Tailscale SSH, exit
   node routing, subnet routing, Serve, or Funnel for this setup.
4. Test ordinary `ssh` to the VPS's Tailscale IP or MagicDNS name. In a Mac SSH
   alias, retain the existing `IdentityFile` and set `ForwardAgent no`,
   `IdentitiesOnly yes`, and `StrictHostKeyChecking yes`. Prefer the Tailscale
   address for all later connections. Do not commit host addresses or key paths.
5. Create a dedicated account (examples below assume its home belongs to that
   account). Provision only the intended public SSH key. Disable password login
   for that account using a reviewed `sshd` configuration. Validate with
   `sshd -t` before a reload. Confirm a fresh connection works before closing
   the original connection. Changes to public SSH/firewall policy need a
   separate lockout and console-recovery review; this setup does not make them.

Required on the VPS: systemd user services, tmux 3.3+, Node.js 22.19+ with npm,
curl, tar, and sha256sum. Use a maintained, fixed Node release from your host's
trusted installation process. Record `node --version`, `npm --version`, and
`tmux -V`; do not use an unpinned `npx` command at service startup.

A restricted Dokku SSH account is not a normal host login. `dokku run` or
`dokku enter` does not provide this host-level service or Tailscale setup.
Ask the administrator for a dedicated login account and prerequisite setup;
do not repurpose an existing app or try to escape a forced-command account.

## Phase 2: install a pinned source release (dedicated account)

Run the following from a reviewed checkout of this repository on the VPS.
These are manual, opt-in commands, not part of the general config installer.
Do not run them as root. Start with an unused `source` directory; upgrades use
the stop/backup procedure below, not an extraction over a running release.

```bash
(
set -eu
umask 077
mkdir -p "$HOME/.local/share/pi-durable" "$HOME/.local/state/pi-durable/agent" \
  "$HOME/.config/pi-durable" "$HOME/.config/systemd/user" "$HOME/.local/bin" \
  "$HOME/work/pi-durable"
chmod 700 "$HOME/.local/state/pi-durable" "$HOME/.local/state/pi-durable/agent" \
  "$HOME/work/pi-durable"
test ! -e "$HOME/.local/share/pi-durable/source"
curl --fail --location --proto '=https' --tlsv1.2 \
  https://github.com/earendil-works/pi/releases/download/v1.0.4/pi-1.0.4-source.tar.gz \
  -o "$HOME/.local/share/pi-durable/pi-1.0.4-source.tar.gz"
printf '%s  %s\n' \
  82407ae8e2446ec6d9d67eddf8dcf0cc813c688c19ab0948ce6c42d4a6001095 \
  "$HOME/.local/share/pi-durable/pi-1.0.4-source.tar.gz" | sha256sum -c -
mkdir "$HOME/.local/share/pi-durable/source"
tar -xzf "$HOME/.local/share/pi-durable/pi-1.0.4-source.tar.gz" \
  --strip-components=1 -C "$HOME/.local/share/pi-durable/source"
ln -s "$(command -v node)" "$HOME/.local/share/pi-durable/node"
(
  cd "$HOME/.local/share/pi-durable/source"
  npm ci --ignore-scripts --workspace @earendil-works/pi-coding-agent \
    --workspace @earendil-works/pi-durable --include-workspace-root
  npm run build:offline
  # Replace build dependencies with only the two runtime workspaces.
  npm ci --ignore-scripts --omit=dev --workspace @earendil-works/pi-coding-agent \
    --workspace @earendil-works/pi-durable
  npm audit --omit=dev --workspace @earendil-works/pi-coding-agent \
    --workspace @earendil-works/pi-durable
)
install -m 700 configs/pi/durable/pi-durable "$HOME/.local/bin/pi-durable"
install -m 600 configs/pi/durable/tmux.conf "$HOME/.config/pi-durable/tmux.conf"
install -m 600 configs/pi/durable/pi-durable.service "$HOME/.config/systemd/user/pi-durable.service"
)
```

Stop if any command fails. The release archive includes model data; a bare Git
checkout does not, and its offline build fails. The archive checksum and npm
lockfile pin source, model data, and dependencies. `npm ci` still requires
registry access. The final install excludes root build dependencies and example
extensions: these include vulnerable `shell-quote` and `node-forge` versions in
this release. The selected runtime install had zero audit findings when tested.
Do not skip the final install or audit, and do not start the service if a new
audit fails. Review an upstream update instead of using `npm audit fix --force`
to change this pinned experimental release. Build only trusted release inputs.
Record and review runtime/security updates separately. This is not a claim of
bit-for-bit builds across different Node versions or CPU architectures.

## Phase 3: authenticate and create the first session

Do not copy your whole Mac Pi directory or this repository's high-permission
Pi profile into the service account. Use the pinned normal CLI to run `/login`
interactively on the VPS, with the same private agent directory:

```bash
PI_CODING_AGENT_DIR="$HOME/.local/state/pi-durable/agent" \
  "$HOME/.local/share/pi-durable/node" \
  "$HOME/.local/share/pi-durable/source/packages/coding-agent/dist/cli.js"
```

Use `/login` and select a provider/model that works without third-party Pi
extensions. Enter secrets only into the CLI's private prompt or provider login
page, never into chat, command arguments, unit files, or Git. The CLI stores
credentials in `auth.json`; keep it mode 600. Never forward the Mac SSH agent.
If the provider needs an environment variable instead, use a private,
administrator-reviewed credential mechanism; do not add it to `tmux.conf`.

Run `~/.local/bin/pi-durable --new` once from an interactive SSH terminal. It
always uses `~/work/pi-durable` as its working directory. Confirm the model,
submit a harmless prompt, then exit with Ctrl+D. Without credentials, startup
can still be checked, but model generation cannot.

`--continue` fails if no session exists. It never silently creates a replacement
after a storage or lock error. Avoid creating another session after service
activation: continuation selects the newest session for this working directory.

## Phase 4: supervise and connect

An administrator can enable startup after reboot and logout with
`sudo loginctl enable-linger ACCOUNT`, substituting the dedicated account name.
This is a host change, not something the repository installer performs. Then,
as the dedicated account in its SSH login:

```bash
systemd-analyze --user verify "$HOME/.config/systemd/user/pi-durable.service"
systemctl --user daemon-reload
systemctl --user enable --now pi-durable.service
systemctl --user status pi-durable.service
```

On the Mac, use the SSH alias from Phase 1:

```bash
ssh -t YOUR_TAILSCALE_SSH_ALIAS 'tmux -S "$HOME/.local/state/pi-durable/tmux.sock" attach-session -t durable'
```

Detach with Ctrl+B then D; disconnecting SSH does not stop the agent. Ctrl+C or
Ctrl+D exits the TUI; the service restarts it after 15 seconds. For an intentional
stop, run `systemctl --user stop pi-durable.service`. Multiple attachments share
one screen and one account; they are not separate authorized users.

The foreground tmux server is supervised by systemd, and `exit-empty on` makes
it exit when the TUI exits. `Restart=always` then reopens the same session.
Three rapid failures trigger the unit's rate limit. Check the error before
`systemctl --user reset-failed pi-durable.service` and a new start.

### Health and recovery acceptance checks

```bash
systemctl --user is-active pi-durable.service
tmux -S "$HOME/.local/state/pi-durable/tmux.sock" has-session -t durable
tmux -S "$HOME/.local/state/pi-durable/tmux.sock" list-panes -t durable \
  -F '#{pane_dead} #{pane_current_command} #{pane_pid}'
journalctl --user -u pi-durable.service -n 30 --no-pager
df -h "$HOME/.local/state/pi-durable"
```

Expect `active`, a live pane (`0`) running Node, and sufficient disk space.
These are process checks, not proof that a model provider is reachable. Attach
to inspect startup errors; avoid logging or sharing pane contents, which can
contain prompts or secrets. The service exposes no health-check port.

Before relying on unattended work, test a harmless prompt, detach/reconnect,
then `systemctl --user restart pi-durable.service`. Verify the same transcript
returns. With a disposable session, kill only the Node pane PID with SIGKILL
and verify automatic recovery after the restart delay. Finally perform a
planned VPS reboot and verify recovery over Tailscale. Do not crash-test a
session performing writes to external systems.

State is in `~/.local/state/pi-durable/agent/experimental/durable-sessions/`,
grouped by the hash of the canonical working directory, then timestamp/UUID.
Keep both this directory and `~/work/pi-durable` on persistent local disk at
stable paths. The TUI locks the session; do not run a second independent TUI
against it. Only attach to tmux. A crash lock becomes stale after 10 seconds.

Upstream calls `harness.resume()` when it reopens storage. Interrupted model
requests can repeat and incur costs. Unsafe interrupted tools receive an
interrupted result rather than automatic replay; external effects still need
reconciliation. This does not guarantee exactly-once emails, deployments, or
payments. SQLite WAL uses `synchronous=NORMAL`; power loss can lose the newest
commits. Persistent state is not a substitute for backups.

### Backup, restore, upgrade, and removal

Stop the service and confirm no pane remains before taking a cold backup of
the **whole** private agent directory and work directory. Include SQLite WAL
and SHM files if present; do not copy only a live `session.sqlite`. Backups
include credentials, prompts, and tool output: encrypt them, restrict access,
keep an off-host copy, and set a retention policy. Never commit them.

Test restoration to the same canonical paths with the same pinned release and
private permissions while the service is stopped. Preserve the current data
before any restore. Do not start a second owner or restore over live files.

For an upgrade, stop, back up, stage a separately checked release, run its tests,
then switch source/runtime and resume. Experimental storage/API compatibility
is not guaranteed. Rollback may require both the previous source and its
matching pre-upgrade backup; do not downgrade against a migrated database.
To remove the service, disable it with `systemctl --user disable --now
pi-durable.service`, then remove only its unit/config after preserving data.
Revoke provider credentials and account access when retiring the host. Disable
lingering only if the account has no other user services.

## Sources and video review

- [Requested video](https://www.youtube.com/watch?v=BLRReTwV8Fc): reviewed its
  English captions. It demonstrates custom applications using SQLite/Node,
  shared state, recovery, and a Sentry-to-PR workflow. The presenter explicitly
  adds duplicate-event guards. This setup uses the official TUI, not that
  custom application; it adds no webhook, auto-merge, or Slack integration.
- [Pinned TUI instructions and limitations](https://github.com/earendil-works/pi/tree/v1.0.4/packages/coding-agent/src/experimental/durable)
- [Pinned Durable storage and recovery contract](https://github.com/earendil-works/pi/tree/v1.0.4/packages/durable)
- [Source release and checksums](https://github.com/earendil-works/pi/releases/tag/v1.0.4)
