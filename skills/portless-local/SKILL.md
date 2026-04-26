---
name: portless-local
description: Named .localhost URLs for local development - replaces port numbers with stable, readable URLs
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when you want clean, named URLs for local development instead of remembering port numbers
user-invocable: true
metadata:
  audience: all
  workflow: development
---

# Portless - Named .localhost URLs

Replace port numbers with stable, named `.localhost` URLs for local development. For humans and agents.

> **Note:** By default, use HTTP (`http://myapp.localhost`). Only enable HTTPS (`--https` or `PORTLESS_HTTPS=1`) if the user specifically requests it (e.g., for OAuth, secure cookies, or HTTPS-only features).

## Why Portless?

Local dev with port numbers is fragile. Portless fixes that by giving each dev server a stable, named `.localhost` URL.

| Problem                    | With Ports                                              | With Portless                                   |
| -------------------------- | ------------------------------------------------------- | ----------------------------------------------- |
| **Port conflicts**         | Two projects on :3000 = EADDRINUSE                      | Auto-assigned ports, named URLs - no collisions |
| **Memorizing ports**       | "Was the API on 3001 or 8080?"                          | Always `http://api.localhost`                   |
| **Wrong app on refresh**   | Stop one server, start another on same port = confusion | Named URLs eliminate this                       |
| **Monorepo chaos**         | Every service needs a unique port                       | Distinct hostnames for each service             |
| **Agent confusion**        | AI agents guess/hardcode wrong ports                    | `http://myapp.localhost` is deterministic       |
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

> **Note:** portless is pre-1.0. When installed per-project, different contributors may run different versions.

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
| `--force`             | Override an existing route registered by another process                                            |

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
portless alias my-postgres 5432     # -> http://my-postgres.localhost
portless alias redis 6379           # -> http://redis.localhost
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

HTTP/2 + TLS is enabled by default for faster dev server page loads.

**Why HTTP/2 matters:** Browsers limit HTTP/1.1 to 6 connections per host, which bottlenecks dev servers serving many unbundled files. HTTP/2 multiplexes all requests over a single connection.

**First run:** Generates a local CA and server certs, then adds the CA to your system trust store. After that, no prompts, no browser warnings.

**Custom certificates:** Use your own certs (e.g., from mkcert):

```bash
portless proxy start --cert ./cert.pem --key ./key.pem
```

**Disable HTTPS:** Use `--no-tls` to run with plain HTTP on port 80:

```bash
portless proxy start --no-tls
portless myapp next dev --no-tls
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
| `-p, --port <number>` | Proxy port (default: 443, or 80 with `--no-tls`). Auto-elevates with sudo. |
| `--no-tls`            | Disable HTTPS (use plain HTTP on port 80)                                  |
| `--https`             | Enable HTTPS (default, accepted for compatibility)                         |
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
```

## Common Use Cases

### 1. Basic Development Server

```bash
# Next.js
portless myapp next dev
# -> http://myapp.localhost

# Vite (auto-detected, --port injected)
portless myapp vite dev
# -> http://myapp.localhost

# Express
portless api node server.js
# -> http://api.localhost
```

### 2. Multiple Services with Subdomains

```bash
# API service
portless api.myapp pnpm start
# -> http://api.myapp.localhost

# Documentation
portless docs.myapp next dev
# -> http://docs.myapp.localhost

# Admin dashboard
portless admin.myapp npm run dev
# -> http://admin.myapp.localhost
```

### 3. Use in package.json

```json
{
	"scripts": {
		"dev": "portless myapp next dev",
		"dev:http": "portless myapp next dev --no-tls"
	}
}
```

### 4. Git Worktree Support

`portless run` auto-detects git worktrees. The branch name is prepended as a subdomain:

```bash
# Main worktree
portless run next dev
# -> http://myapp.localhost

# Linked worktree on branch "fix-ui"
portless run next dev
# -> http://fix-ui.myapp.localhost
```

Put `portless run` in your package.json once and it works everywhere - no collisions, no `--force`.

### 5. Custom TLD

```bash
# Use .test TLD instead of .localhost
portless proxy start --tld test
portless myapp next dev
# -> http://myapp.test
```

Recommended TLDs:

- `.localhost` - Default, auto-resolves to 127.0.0.1 in most browsers
- `.test` - IANA-reserved, no collision risk (recommended)
- **Avoid:** `.local` (conflicts with mDNS/Bonjour), `.dev` (Google-owned, forces HTTPS via HSTS)

### 6. Static Aliases for External Services

```bash
# Docker container running Postgres
portless alias my-postgres 5432
# -> http://my-postgres.localhost

# Redis server
portless alias redis 6379
# -> http://redis.localhost
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
Browser (myapp.localhost) -> HTTP Proxy (port 80) -> App (random port 4000-4999)
```

1. Portless runs an HTTP reverse proxy on port 80 (or HTTPS on 443 if enabled)
2. Each app registers a route mapping hostname to assigned port
3. Requests to `http://<name>.localhost` are proxied to the app
4. Optional HTTPS: Auto-generates local CA and trusts it on first run
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

Portless is configured through environment variables. No config files needed.

### Environment Variables

| Variable              | Description                                                     | Default                 |
| --------------------- | --------------------------------------------------------------- | ----------------------- |
| `PORTLESS_PORT`       | Proxy port                                                      | 443 (HTTPS) / 80 (HTTP) |
| `PORTLESS_HTTPS`      | HTTPS on by default; set to `0` to disable (same as `--no-tls`) | on                      |
| `PORTLESS_LAN`        | Set to `1` to always enable LAN mode (mDNS `.local` domains)    | off                     |
| `PORTLESS_TLD`        | Use a custom TLD instead of `.localhost` (e.g. `test`)          | localhost               |
| `PORTLESS_APP_PORT`   | Use a fixed port for the app (skip auto-assignment)             | random 4000-4999        |
| `PORTLESS_SYNC_HOSTS` | Set to `0` to disable auto-sync of `/etc/hosts`                 | on                      |
| `PORTLESS_STATE_DIR`  | Override the state directory                                    | see below               |
| `PORTLESS`            | Set to `0` to bypass the proxy                                  | enabled                 |

### State Directory

Portless stores state (routes, PID file, port file, TLS marker) in a directory that depends on the proxy port:

| Condition                           | Path            |
| ----------------------------------- | --------------- |
| Port below 1024 (sudo, macOS/Linux) | `/tmp/portless` |
| Port 1024+ (no sudo)                | `~/.portless`   |
| Windows (any port)                  | `~/.portless`   |

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

## Troubleshooting

### Port 443 permission denied

```bash
# Portless auto-elevates with sudo, but if it fails:
sudo portless proxy start

# Or use HTTP mode on a different port
portless myapp next dev --no-tls -p 8080
```

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
| **portless** | Local proxy   | `http://myapp.localhost`          | Clean local dev URLs |
| ngrok        | Public tunnel | `https://random.ngrok.io`         | Share with others    |
| cloudflared  | Public tunnel | `https://myapp.trycloudflare.com` | Share with others    |

## Related

- [portless.sh](https://portless.sh/) - Official documentation
- [vercel-labs/portless](https://github.com/vercel-labs/portless) - Official skill for Claude Code
