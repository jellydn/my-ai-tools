# Self-hosted Amp orbs with smolvm

The [dispatcher](../configs/amp/orb-dispatch.sh) runs one smolvm machine per orb.
No Amp skill or shell function is required. See the [Amp dispatch contract](https://ampcode.com/docs/orbs/self-hosted#dispatch-contract).
For cloud sandboxes instead of local VMs, see [Amp orbs on Docker Sandboxes Cloud](amp-orbs-docker-sbx.md).

## Set up the Mac

Install Amp, Bash, Python 3, and [smolvm](https://github.com/smol-machines/smolvm).
Make `amp`, `smolvm`, and `python3` available on the controller's PATH. With Homebrew:

```bash
brew install smol-machines/tap/smolvm
mkdir -p "$HOME/src/tries"
```

From this repository, preview the configuration install before running it:

```bash
./cli.sh --dry-run
./cli.sh
```

The installer copies the dispatcher to `~/.config/amp/orb-dispatch.sh`.
The copy keeps working after this checkout is removed, for example when the
one-line installer deletes its temporary download.
`./generate.sh --dry-run` previews export. The dispatcher is tracked source,
not user configuration, so the export keeps the tracked copy and restores it
only when the tracked file is missing.

If a provider is not configured, the user runs `amp orb provider create itman-vm`
in a private terminal. It prints a token once and saves it for the controller.
Agents must not run this command, capture its output, read credential files, or ask
the user to paste the token. Ask only whether provider creation succeeded.

Amp keeps one saved provider token, in `~/.local/share/amp/secrets.json`. Creating a
second provider replaces it, so the controller of the earlier provider connects with the
new token after its next restart. See
[Amp orbs on Docker Sandboxes Cloud](amp-orbs-docker-sbx.md) for the shared-slot caveat
and the steps that put the earlier token back.

## Start and check the controller

Run this on the Mac that hosts the VMs:

```bash
amp orb provider "$HOME/.config/amp/orb-dispatch.sh"
```

Keep exactly one controller per provider token. The dispatcher selects the ARM64
image on Apple Silicon; no fish setup or image export is needed. Keep the Mac awake.
The foreground controller stops when its process exits. Use a host service manager
for automatic restart after a crash or reboot, with the same PATH and credentials.

`READY` and `listening for jobs` indicate that the controller is connected.
Provider logs are under `~/.cache/amp/logs/orb-provider`. Use Ctrl-C to drain jobs
and stop the foreground controller before starting a replacement.
Select `itman-vm` in the new thread's self-hosted provider picker.

## Resources and lifecycle

| Setting | Default |
| --- | --- |
| Host mount (`AMP_ORB_WORKDIR`) | `$HOME/src/tries` |
| Guest mount | `/home/user/tries` |
| CPU (`ORB_CPUS`) | 4 |
| Memory (`ORB_MEMORY_MIB`) | 8192 MiB |
| Disk (`ORB_STORAGE_GIB`) | 40 GiB |
| Image (`ORB_IMAGE`) | Amp ARM64 image on Apple Silicon; Amp x64 image otherwise |
| Snapshots | `${XDG_STATE_HOME:-$HOME/.local/state}/amp-orbs/snapshots/` |

Set overrides in the controller's environment before starting it. `SMOLVM` can
select a different executable. Custom images are preserved. The guest bootstrap
runs as `user`. Amp normally checks out the project in `/home/user/workspace/repo`;
the shared mount is an additional directory, not the project checkout.

- **Spawn:** resume an existing machine, or create one from a local project
  checkpoint. If the checkpoint is unavailable, use the image, as Amp permits.
  Only fresh image creation checks that the host mount exists. If a machine is
  registered but cannot resume or start (for example, its checkpoint was lost
  to a crash, an interrupted pause, or a second controller's racing delete),
  the dispatcher retries it once, then discards and recreates it from the
  image or snapshot. It refuses to discard a machine when the replacement
  workspace or snapshot is missing, so the operator can restore the
  directory without losing the existing disk. The host mount and any saved
  snapshot survive.

A second controller for the same token is the common cause of these wedged
machines: both receive the same job, derive the same machine name, and their
pause/create/resume operations race. Keep exactly one controller per token.
- **Pause:** keep the VM's RAM and disk. If Amp requests a project snapshot, save
  a checkpoint with `--host-mounts` before pausing.
- **Delete:** remove the VM and its disk. Pause and delete do not require the host
  mount directory to exist. Archiving a thread pauses its orb; it does not delete it.

All VMs share the same writable host mount. Treat it as shared data, not isolated
thread storage. Checkpoints retain the mount mapping, not a private copy of its
host files. Keep thread work in its project checkout to avoid cross-thread edits.

After changing the dispatcher or smolvm version, smoke-test spawn → pause → resume
→ delete on the host. The Bats tests use a mock CLI; they do not verify real VM or
checkpoint behavior.
