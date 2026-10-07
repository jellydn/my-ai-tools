---
name: portless-local
description: "Replace port numbers with stable named .localhost URLs for local development"
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when you want clean, named URLs for local development instead of remembering port numbers
user-invocable: true
disable-model-invocation: true
metadata:
  audience: all
  workflow: development
  source: vercel-labs/portless@7abf4df5d939fe3b527a120e20bc270c681c3536
  source_path: skills/portless/SKILL.md
---

# Portless - Named .localhost URLs

Replace port numbers with stable, named `.localhost` URLs for local development. For humans and agents.

> **Note:** The portless CLI enables HTTPS on port 443 by default (`https://myapp.localhost`). Pass `--no-tls` to `portless proxy start`, or set `PORTLESS_HTTPS=0`, for plain HTTP. Keep HTTPS when the app needs OAuth, secure cookies, or HTTP/2.

## Safety and Approval

Read existing proxy configuration before starting an app: auto-start reuses saved settings, including LAN mode. Outside LAN mode the proxy binds only to IPv4/IPv6 loopback; LAN mode binds all interfaces.

Ask for explicit approval before first-run sudo/elevation, CA trust-store changes, `/etc/hosts` writes, LAN exposure, Tailscale sharing, public Funnel/ngrok tunnels, startup-service installation/removal, or destructive cleanup. A request for local development does not authorize these actions. Use `PORTLESS_SYNC_HOSTS=0` when hosts writes are not approved. In non-interactive environments, first-run prompts fail rather than granting permission; pre-start only an approved proxy configuration.

`--force` kills the existing process and takes over its route. `prune` terminates orphaned process groups, and `prune --force` uses SIGKILL. Do not use them without checking ownership and approval. `clean` also removes startup services and trust entries; it is not routine project cleanup.

Never print or commit TLS private keys or ngrok tokens. Let the user configure authentication through the provider's private credential workflow. Do not disable TLS verification to resolve proxy errors.

## Why Portless?

Local dev with port numbers is fragile. Portless fixes that by giving each dev server a stable, named `.localhost` URL.

| Problem                    | With Ports                                              | With Portless                                   |
| -------------------------- | ------------------------------------------------------- | ----------------------------------------------- |
| **Port conflicts**         | Two projects on :3000 = EADDRINUSE                      | Auto-assigned ports, named URLs - no collisions |
| **Memorizing ports**       | "Was the API on 3001 or 8080?"                          | Always `https://api.localhost`                   |
| **Wrong app on refresh**   | Stop one server, start another on same port = confusion | Named URLs eliminate this                       |
| **Monorepo chaos**         | Every service needs a unique port                       | Distinct hostnames for each service             |
| **Agent confusion**        | AI agents guess/hardcode wrong ports                    | `https://myapp.localhost` is deterministic       |
| **Cookie/storage clashes** | Cookies bleed across ports on localhost                 | Each `.localhost` subdomain gets its own scope  |
| **Hardcoded config**       | CORS, OAuth, .env break when ports change               | URLs are stable across restarts                 |
| **Sharing URLs**           | "What port is that on?" in Slack                        | Everyone uses the same named URL                |
| **Browser history**        | `localhost:3000` history is a jumble                    | Named URLs keep things organized                |

## Installation

```bash
# Global (recommended)
npm install -g portless

# Or as a project dev dependency
npm install -D portless
```

Requires Node.js 24+ and OpenSSL for certificate generation. Install globally or as a project dependency; do not use a one-off `npx`/`pnpm dlx` download. A local package may be invoked through package scripts or `npx portless` without downloading it.

## Usage

Invoke via skill command or use CLI directly:

```bash
# Via skill command
/portless-local <NAME> <COMMAND> [OPTIONS]

# Or use CLI directly
portless <NAME> <COMMAND> [OPTIONS]
```

## Commands

### Run an App

```bash
portless run [--name <name>] <cmd> [args...]   # Infers name from package.json, git root, or directory
portless <name> <cmd> [args...]                # Explicit name, no inference
```

`portless run` infers the project name from package.json, git root, or directory name. Use `--name` to override the inferred name while still applying worktree prefixes.

| Flag                  | Description                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------------- |
| `--name <name>`       | Override the inferred base name (worktree prefix still applies). Only for `portless run`.           |
| `--app-port <number>` | Use a fixed port for the app instead of auto-assignment. Also configurable via `PORTLESS_APP_PORT`. |
| `--force`             | Kill the existing process and take over its route; requires ownership checks and approval           |

**Examples:**

```bash
portless run next dev                    # Infer name from project
portless run --name myapp next dev       # Override inferred name
portless myapp next dev                  # Explicit name
portless api pnpm start                  # API service
portless docs.myapp next dev             # Subdomain
```

### Get a Service URL

```bash
portless get <name>
```

Print the URL for a service. Useful for wiring services together in scripts or env vars:

```bash
BACKEND_URL=$(portless get backend)
```

Applies worktree prefix detection by default. Use `--no-worktree` to skip it.

### Alias (Static Routes)

```bash
portless alias <name> <port>              # Register a static route
portless alias <name> <port> --force     # Force override existing
portless alias --remove <name>            # Remove the alias
```

Register a route for a service not managed by portless (e.g. a Docker container). Aliases persist across stale-route cleanup.

```bash
portless alias my-postgres 5432     # -> https://my-postgres.localhost
portless alias redis 6379           # -> https://redis.localhost
portless alias --remove my-postgres # Remove the alias
```

### List Routes

```bash
portless list
```

Shows active routes and their assigned ports.

### Trust the CA

```bash
portless trust
```

Adds the portless certificate authority to your system trust store. Required once for HTTPS with auto-generated certs.

If you skipped the trust prompt on first run, run `portless trust` to add the CA later.

### HTTPS & HTTP/2

The CLI enables HTTPS on port 443 by default. That covers OAuth callbacks, secure cookies, and HTTP/2. Pass `--no-tls` or set `PORTLESS_HTTPS=0` only when the app should stay on plain HTTP.

When HTTPS stays on, the first run may generate a local CA and server certificates. Run `portless trust` if the host or browser must trust that certificate.

**Custom certificates:** Use your own certs (e.g., from mkcert):

```bash
portless proxy start --cert ./cert.pem --key ./key.pem
```

**Disable HTTPS:** HTTPS on port 443 is the CLI default. `portless proxy start --no-tls` or `PORTLESS_HTTPS=0` selects plain HTTP on port 80. Do not put `--no-tls` after the app command; portless forwards those arguments to the child process.

```bash
portless proxy start --no-tls
PORTLESS_HTTPS=0 portless myapp next dev
```

### Clean Up

```bash
portless clean
```

Stops the proxy, removes the CA from OS trust store, deletes allowlisted files under `~/.portless`, the system state directory, and removes the portless block from `/etc/hosts`. May prompt for elevated privileges.

### Proxy Control

#### Start Proxy

```bash
portless proxy start
```

| Flag                  | Description                                                                |
| --------------------- | -------------------------------------------------------------------------- |
| `-p, --port <number>` | Proxy port (default: 443, or 80 with `--no-tls`).              |
| `--no-tls`            | Disable HTTPS (plain HTTP on port 80).                         |
| `--https`             | Enable HTTPS (CLI default; kept for compatibility).            |
| `--lan`               | Enable LAN mode (mDNS `.local` domains for real device testing)            |
| `--ip <address>`      | Override auto-detected LAN IP (use with `--lan`)                           |
| `--tld <tld>`         | Use a custom TLD instead of `.localhost` (e.g. `.test`)                    |
| `--cert <path>`       | Custom TLS certificate                                                     |
| `--key <path>`        | Custom TLS private key                                                     |
| `--foreground`        | Run in foreground instead of daemon mode                                   |

#### Stop Proxy

```bash
portless proxy stop
```

### LAN Mode

Access services from phones and other devices on the same WiFi via mDNS (`.local` domains):

```bash
portless proxy start --lan
portless proxy start --lan --https
portless proxy start --lan --ip 192.168.1.42   # Manual IP override
```

Make it permanent by adding `export PORTLESS_LAN=1` to your shell profile. Portless also remembers LAN mode via `proxy.lan`, so a stopped LAN proxy starts in LAN mode again.

**Framework notes for LAN:**

- **Next.js:** Add `allowedDevOrigins: ['myapp.local', '*.myapp.local']` to `next.config.js`
- **Vite / React Router / SvelteKit / Astro:** Handled automatically via `__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS`
- **Expo / React Native:** Add `NSAllowsLocalNetworking` to `app.json` for iOS ATS

### Hosts

```bash
portless hosts sync     # Add current routes to /etc/hosts
portless hosts clean    # Remove portless entries from /etc/hosts
```

Auto-sync is on by default. Set `PORTLESS_SYNC_HOSTS=0` to disable.

### Bypass Portless

```bash
PORTLESS=0 pnpm dev
```

Runs the command directly without the proxy.

### Info

```bash
portless --help
portless --version
portless doctor    # Read-only diagnostics for proxy, DNS, trust, routes, and LAN prerequisites
```

### Sharing and Startup Services

Only run these after approval for the stated exposure or persistent system change:

```bash
portless myapp --tailscale next dev   # Tailnet; requires connected Tailscale CLI and HTTPS certificates
portless myapp --funnel next dev      # Public internet; requires Funnel enabled for tailnet and node
portless myapp --ngrok next dev       # Public internet; requires authenticated ngrok CLI
portless service status              # Inspect installed service configuration
portless service install             # Persist proxy at OS startup; may require administrator privileges
portless service uninstall           # Remove startup service
```

Tailscale and ngrok registrations are removed when the app exits. `PORTLESS_TAILSCALE`, `PORTLESS_FUNNEL`, and `PORTLESS_NGROK` can enable sharing by default; inspect them before starting an app. Startup services save their options in launchd, systemd, or Task Scheduler, and may run as root or SYSTEM.

## Common Use Cases

### 1. Basic Development Server

```bash
# Next.js
portless myapp next dev
# -> https://myapp.localhost

# Vite (auto-detected, --port injected)
portless myapp vite dev
# -> https://myapp.localhost

# Express
portless api node server.js
# -> https://api.localhost
```

### 2. Multiple Services with Subdomains

```bash
# API service
portless api.myapp pnpm start
# -> https://api.myapp.localhost

# Documentation
portless docs.myapp next dev
# -> https://docs.myapp.localhost

# Admin dashboard
portless admin.myapp npm run dev
# -> https://admin.myapp.localhost
```

### 3. Use in package.json

```json
{
	"scripts": {
		"dev": "portless myapp next dev",
		"dev:http": "PORTLESS_HTTPS=0 portless myapp next dev"
	}
}
```

### 4. Git Worktree Support

`portless run` auto-detects git worktrees. The branch name is prepended as a subdomain:

```bash
# Main worktree
portless run next dev
# -> https://myapp.localhost

# Linked worktree on branch "fix-ui"
portless run next dev
# -> https://fix-ui.myapp.localhost
```

Put `portless run` in your package.json once and it works everywhere - no collisions, no `--force`.

### 5. Custom TLD

```bash
# Use .test TLD instead of .localhost
portless proxy start --tld test
portless myapp next dev
# -> https://myapp.test
```

Recommended TLDs:

- `.localhost` - Default, auto-resolves to 127.0.0.1 in most browsers
- `.test` - IANA-reserved, no collision risk (recommended)
- **Avoid:** `.local` (conflicts with mDNS/Bonjour), `.dev` (Google-owned, forces HTTPS via HSTS)

### 6. Static Aliases for External Services

```bash
# Docker container running Postgres
portless alias my-postgres 5432
# -> https://my-postgres.localhost

# Redis server
portless alias redis 6379
# -> https://redis.localhost
```

### 7. Wire Services Together

```bash
# Get backend URL for frontend env
BACKEND_URL=$(portless get backend)
echo "VITE_API_URL=$BACKEND_URL" > .env.local
portless frontend vite dev
```

## How It Works

```
Browser (myapp.localhost) -> HTTPS Proxy (port 443) -> App (random port 4000-4999)
```

1. Portless runs an HTTPS reverse proxy on port 443 (or HTTP on port 80 with `--no-tls`)
2. Each app registers a route mapping hostname to assigned port
3. Requests to `https://<name>.localhost` are proxied to the app
4. Default HTTPS: auto-generates a local CA. Run `portless trust` when the host or browser must trust it
5. Auto-elevates with sudo on macOS/Linux for port binding

## Framework Support

Portless auto-detects and configures:

| Framework    | Support     | Notes                           |
| ------------ | ----------- | ------------------------------- |
| Next.js      | ✅ Native   | Respects PORT env var           |
| Express      | ✅ Native   | Respects PORT env var           |
| Nuxt         | ✅ Native   | Respects PORT env var           |
| Vite         | ✅ Injected | Auto-adds `--port` flag         |
| Astro        | ✅ Injected | Auto-adds `--port` flag         |
| React Router | ✅ Injected | Auto-adds `--port` flag         |
| Angular      | ✅ Injected | Auto-adds `--port` and `--host` |
| Expo         | ✅ Injected | Auto-adds `--port` and `--host` |
| React Native | ✅ Injected | Auto-adds `--port` and `--host` |

## Configuration

### Zero-config and Workspaces

Bare `portless` runs the package's `dev` script with an inferred name. An optional `portless.json` or package.json `portless` key can set `name`, `script`, `appPort`, and `proxy` (`false` for non-proxied tasks).

```json
{
  "apps": {
    "apps/web": { "name": "myapp" },
    "apps/api": { "name": "api.myapp" }
  }
}
```

From a workspace root, `portless` discovers packages in `pnpm-workspace.yaml` or package.json `workspaces` and starts their dev scripts. Unlisted packages use inferred names. Use `--script start` for a different script. Readable `turbo.json` or `turbo.jsonc` preserves Turbo task ordering; root `"turbo": false` selects direct spawning.

Precedence: CLI flags > package.json `portless` key > portless.json app entry > defaults. To avoid recursion when `dev` runs portless, put the real command in `dev:app` and configure `"portless": { "script": "dev:app" }`.

Strict routing is the default. `proxy start --wildcard` allows unregistered child subdomains to fall back to the most specific registered parent. Multiple `--tld` flags (or comma-separated `PORTLESS_TLD`) support single- and multi-segment domains. Review these routing changes before use.

### Environment Variables

| Variable              | Description                                                     | Default                 |
| --------------------- | --------------------------------------------------------------- | ----------------------- |
| `PORTLESS_PORT`       | Proxy port                                                      | 443; 80 with `--no-tls` |
| `PORTLESS_HTTPS`      | Set to `0` to disable HTTPS (same as `--no-tls`)                | on                      |
| `PORTLESS_LAN`        | Set to `1` to always enable LAN mode (mDNS `.local` domains)    | off                     |
| `PORTLESS_TLD`        | One or more comma-separated TLDs (e.g. `localhost,dev.example.com`) | localhost            |
| `PORTLESS_WILDCARD`   | Set to `1` for parent-route fallback                          | off                     |
| `PORTLESS_LAN_IP`     | Pin a LAN IP instead of auto-detection                        | auto-detected           |
| `PORTLESS_TAILSCALE`  | Share apps on the tailnet; requires approval                  | off                     |
| `PORTLESS_FUNNEL`     | Share apps publicly; requires approval                       | off                     |
| `PORTLESS_NGROK`      | Share apps publicly through ngrok; requires approval         | off                     |
| `PORTLESS_APP_PORT`   | Use a fixed port for the app (skip auto-assignment)             | random 4000-4999        |
| `PORTLESS_SYNC_HOSTS` | Set to `0` to disable auto-sync of `/etc/hosts`                 | on                      |
| `PORTLESS_STATE_DIR`  | Override the state directory                                    | see below               |
| `PORTLESS`            | Set to `0` to bypass the proxy                                  | enabled                 |

### State Directory

Portless stores state (routes, PID file, port file, TLS marker) in `~/.portless`. Under sudo, this remains the invoking user's home so apps and the proxy share registrations.

Override with `PORTLESS_STATE_DIR`.

### State Files

| File          | Purpose                                             |
| ------------- | --------------------------------------------------- |
| `routes.json` | Maps hostnames to ports                             |
| `routes.lock` | Prevents concurrent writes                          |
| `proxy.pid`   | PID of the running proxy                            |
| `proxy.port`  | Port the proxy is listening on                      |
| `proxy.log`   | Proxy daemon log output                             |
| `proxy.lan`   | Remembers LAN mode and stores the last known LAN IP |

### Port Assignment

Apps get a random port in the 4000-4999 range. Portless sets `PORT` and usually `HOST` before running your command. Most frameworks respect `PORT` automatically. For frameworks that ignore it (Vite, Astro, React Router, Angular, Expo, React Native), portless auto-injects the right `--port` flag and, when needed, a matching `--host` flag.

Injection applies to recognized server commands, including VitePlus, and can reach through simple package scripts. It skips build/test/check commands, compound shell commands, env prefixes, script delegation, option terminators, comments, and ambiguous runner flags. Those scripts must set their own port. Expo's `--localhost`, `--lan`, and `--tunnel` modes are preserved.

Portless sets `NODE_EXTRA_CA_CERTS` for child Node.js processes. For a separate process that must trust the local CA, use `NODE_EXTRA_CA_CERTS=~/.portless/ca.pem` rather than disabling certificate verification.

## Troubleshooting

### Port 443 permission denied

```bash
# Only after explicit approval for elevation:
sudo portless proxy start

# Or configure an approved unprivileged proxy before the app starts.
# Flags after the child command are forwarded to Next.js, which rejects --no-tls.
PORTLESS_HTTPS=0 PORTLESS_PORT=8080 portless myapp next dev
```

When sudo is unavailable, portless falls back to port 1355. Check the actual URL rather than assuming 443. Use `portless doctor` first for routing, DNS, or trust failures. For cross-app proxy loops, set `changeOrigin: true` in the forwarding proxy so the Host header matches the target route.

### Certificate warning

Trust the local CA on first run. Run `portless trust` if needed.

### Name collision

```bash
# Each worktree gets unique subdomain automatically
# Or use different names:
portless myapp-v2 next dev
```

## Comparison

| Tool         | Type          | URLs                              | Use Case             |
| ------------ | ------------- | --------------------------------- | -------------------- |
| **portless** | Local proxy   | `https://myapp.localhost`          | Clean local dev URLs |
| ngrok        | Public tunnel | `https://random.ngrok.io`         | Share with others    |
| cloudflared  | Public tunnel | `https://myapp.trycloudflare.com` | Share with others    |

## Related

- [portless.sh](https://portless.sh/) - Official documentation
- [vercel-labs/portless](https://github.com/vercel-labs/portless) - Official skill for Claude Code
