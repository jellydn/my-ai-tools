# Amp orbs on Docker Sandboxes Cloud

The `docker-sbx` provider runs each Amp orb as a Docker Sandboxes Cloud sandbox (`sbx --cloud`).
The controller is a launchd service on the Mac. It runs the dispatcher from
[elianiva/amp-orbs](https://github.com/elianiva/amp-orbs) at commit `91793a1`, with the
[macOS patch](../configs/amp/docker-sbx/amp-orbs-91793a1.patch) from this repository.
It can run next to the [smolvm provider](amp-orbs.md) on the same Mac.

This setup offers one orb type: `small` (2 vCPU / 4 GiB).

## Install sbx and sign in

You need a Docker account with the Docker Sandboxes Cloud entitlement.

```bash
brew trust docker/tap
brew install docker/tap/sbx
sbx login
sbx --cloud diagnose
```

`sbx login` opens the browser. To use a personal access token instead, run
`sbx login --username <docker-id> --password-stdin` and send the token on stdin.
Continue only when `diagnose` passes all checks. The tested version is sbx v0.53.0.

## Get the provider source

Upstream `main` has moved to a published-image design that this patch does not support.
Use the tested commit:

```bash
git clone https://github.com/elianiva/amp-orbs "$HOME/Development/amp-orbs"
cd "$HOME/Development/amp-orbs"
git switch -c docker-sbx 91793a15b71a2ab759d1a9cb91f92965e2e3ff1a
curl -fsSL -o amp-orbs-91793a1.patch \
  https://raw.githubusercontent.com/jellydn/my-ai-tools/main/configs/amp/docker-sbx/amp-orbs-91793a1.patch
git apply amp-orbs-91793a1.patch
```

The patch is `configs/amp/docker-sbx/amp-orbs-91793a1.patch` in this repository, so the raw URL
tracks `main` and serves the file once this guide is merged. A reader who already has a
checkout of this repository can apply the file from disk instead of downloading it.

The patch makes two changes:

- `service/install-macos.sh` reads `AMP_ORB_PROVIDER_TOKEN`. When it is set, the installer
  sets the generated launchd plist to mode 600 and adds the token to the service environment.
- `service/com.elianiva.amp-orb-provider.plist` sets `AMP_ORBS_DEFAULT_TYPE` to `small`.

## Build the small template

Build only the `small` template in the `sbx` account:

```bash
BUILDER=amp-orb-builder-small CPUS=2 MEMORY=4g \
  ./base/build-template.sh melon-orb-base-x86_64-v3-small
sbx --cloud template inspect melon-orb-base-x86_64-v3-small --format json
```

The template must show amd64, 2 CPUs, and 4096 MiB. The other upstream templates are not
built. Do not add other orb types unless you build their templates first.

## Create the provider token

Do this once for each Amp account. If `docker-sbx` already exists, keep its token file and
do not create the provider again.

Amp keeps one saved provider token, in `~/.local/share/amp/secrets.json` under
`orb-provider-token@https://ampcode.com/`. `amp orb provider create` replaces that value.
Without the steps below, the next restart of the smolvm controller would connect with the
`docker-sbx` token. The command can also refresh the Amp login values in the same file.

The user runs these commands in a private terminal. Agents must not run them, read
`secrets.json` or the token file, or ask the user to paste the token.

```bash
umask 077
S="$HOME/.local/share/amp/secrets.json"
cp -p "$S" "$S.bak-before-docker-sbx"
amp orb provider create docker-sbx
mkdir -p "$HOME/.config/amp-orbs"
python3 -I - "$S" "$S.bak-before-docker-sbx" "$HOME/.config/amp-orbs/docker-sbx.token" <<'PY'
import json, os, sys

secrets_path, backup_path, token_path = sys.argv[1:]
key = "orb-provider-token@https://ampcode.com/"
with open(secrets_path) as f:
    secrets = json.load(f)
with open(backup_path) as f:
    backup = json.load(f)
token = secrets.get(key, "")
found = token.startswith("aop_live_") and token != backup.get(key)
try:
    if found:
        with open(token_path, "w") as f:
            f.write(token)
        os.chmod(token_path, 0o600)
finally:
    # Give the saved slot back to the earlier provider. Keep the refreshed login values.
    # This runs on every path, so the slot never keeps the docker-sbx token.
    if key in backup:
        secrets[key] = backup[key]
    else:
        secrets.pop(key, None)
    tmp_path = secrets_path + ".tmp"
    with open(tmp_path, "w") as f:
        json.dump(secrets, f, indent=2)
    os.chmod(tmp_path, 0o600)
    os.replace(tmp_path, secrets_path)

if not found:
    sys.exit(
        "no new provider token found; the saved slot holds the earlier token again. "
        "If `amp orb provider create` printed a token, copy it into " + token_path
        + " by hand, because the command shows it only once."
    )
PY
```

The new token is now in `~/.config/amp-orbs/docker-sbx.token` (mode 600), and the saved
slot has the earlier token again. The backup also contains credentials. Delete it after you
make sure that both providers work.

If the script exits with `no new provider token found`, the saved slot holds the earlier
provider's token again, so the other provider keeps working. The `docker-sbx` token is not
in the slot either: `amp orb provider create` shows it once, and the script only copies it
when it finds it. When the command printed a token, copy it into the token file by hand:

```bash
umask 077
printf '%s' 'aop_live_<the token the command printed>' > "$HOME/.config/amp-orbs/docker-sbx.token"
chmod 600 "$HOME/.config/amp-orbs/docker-sbx.token"
```

When the command printed nothing, it did not create the provider. Run it again and repeat
the steps above.

## Install the service

```bash
cd "$HOME/Development/amp-orbs"
AMP_ORB_PROVIDER_TOKEN="$(cat "$HOME/.config/amp-orbs/docker-sbx.token")" ./service/install.sh 2>&1 |
  sed -E 's/aop_live_[A-Za-z0-9_-]+/aop_live_<redacted>/g'
```

The installer writes `~/Library/LaunchAgents/com.elianiva.amp-orb-provider.plist` and starts
the `com.elianiva.amp-orb-provider` service. The plist contains the token, so it is mode 600.
The installer prints `launchctl print` output, which can include the service environment.
Keep the `sed` filter on every install.

Use the same command to reinstall after a change. Logs are in `logs/provider.err.log`.
Never commit or share the token file, the generated plist, or unfiltered `launchctl print`
output.

## Set the orb type in Amp Settings

The CLI cannot set orb types. In **Amp Settings → Orbs → docker-sbx → Edit**, add only
`small` under **Orb types** and make it the default.

Amp sends the selected type to the dispatcher, so `AMP_ORBS_DEFAULT_TYPE` is only a fallback.
Before this setting existed, `--orb-size small` failed with "Unknown orb type", and a thread
without `--orb-size` started a `medium` sandbox (4 vCPU / 8 GiB).

## Test a thread

```bash
amp -ox 'Run nproc and free -m in the orb shell. Report their output, then reply SMALL_OK.' \
  --orb-provider docker-sbx --orb-size small
sbx --cloud ls
sbx --cloud inspect amp-<thread-id> --format json
```

`amp -ox` prints the thread URL and returns before the turn runs, so the sandbox is still
starting when the command exits. Wait for it to appear in `sbx --cloud ls` before you read
its values.

The expected results are `cpus` 2 and `memory_mib` 4096 in `inspect`, `nproc` 2, and a
`free -m` total of about 3938 MiB in the orb.

`amp -ox` leaves the thread unarchived, so the orb keeps running. Archiving the thread is
what makes Amp send the `pause` job, and unarchiving it and sending a message sends
`spawn` again. That is the pause and resume path:

```bash
amp threads archive <thread-id>
amp threads archive --unarchive <thread-id>
amp threads continue <thread-id> -ox 'Report the orb shell output again.'
```

The archive sends `pause`, and the dispatcher stops the sandbox with its disk intact. The
next message sends `spawn`, and the dispatcher resumes the stopped sandbox.

Delete the test sandbox and its state mapping with the dispatcher:

```bash
ORB_OPERATION=delete ORB_ID=amp-<thread-id> ./dispatch.py
```

`sbx --cloud rm --force` removes the sandbox but leaves its file in `state/orbs/`.

## Caveats

- Keep exactly one controller for each provider token.
- The patched installer passes the token to `PlistBuddy` as an argument. Other local users can
  see it in `ps` while `PlistBuddy` runs.
- Only `melon-orb-base-x86_64-v3-small` exists. If Amp sends another type, the spawn fails.
