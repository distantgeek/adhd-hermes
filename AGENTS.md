# adhd-hermes
## Agent Context Document

> **First time with this project?** Read the [First Run Checklist](#first-run-checklist)
> before doing anything else.

---

## Project Identity

**What this is:** `adhd-hermes` — a Fedora 43 bootc appliance image that
runs [Hermes Agent](https://github.com/NousResearch/hermes-agent) via rootless
Podman Quadlets. Designed for deployment on a ThinkCentre M910q bare metal machine.

**Owner:** distantgeek
**Primary registry:** `ghcr.io/distantgeek/adhd-hermes-os`
**Upstream agent:** `docker.io/nousresearch/hermes-agent`
**Target runtime:** ThinkCentre M910q (i5-7500T, 8GB RAM, bare metal), homelab (`distantgeek.net`)
**License:** Apache 2.0 (OS image); Hermes Agent is MIT

**Related active projects (all private repos):**

| Repo | Description |
|------|-------------|
| `fedora-claude-devbox` | Fedora bootc AI devbox |
| `adhd-hermes` | **This project** — Hermes Agent appliance |
| `soc-deploy` | Fedora Server SOC stack |
| `nagging-bot` | Original ADHD nudge concept (superseded by Hermes) |
| `llm-selective-memory` | Obsidian vault privacy-tiered LLM context injection |
| `ogoa-character-builder` | Tauri/React OGoA character sheet desktop app |
| `harrmony` | Music request manager for Arr ecosystem |
| `homelab-jumpbox` | SSH jump box with SOCKS5 |

---

## Deployed System — Current State

| Property | Value |
|----------|-------|
| Hardware | ThinkCentre M910q (i5-6500T, 4C, 8GB RAM, 463GB NVMe, bare metal) |
| Hostname | `kevbotmini` |
| IP | Set via `VM_HOST` Makefile variable |
| SSH alias | Set in `~/.ssh/config` on build machine |
| SSH user | `kevbot` |
| SSH key | Set via `SSH_KEY` Makefile variable (default: `~/.ssh/id_ed25519`) |
| bootc image | `ghcr.io/distantgeek/adhd-hermes-os:latest` (public registry) |
| Previous image | `ghcr.io/distantgeek/adhd-claw-os:latest` (cleaned up, ready for switch) |
| Container runtime | Rootless Podman via systemd Quadlets |
| SELinux | Enforcing |
| Pre-switch status | Old OpenClaw + Ollama containers stopped, disabled, and removed. Data cleared. |
| Status | Deployed — gateway and dashboard running |

### ThinkCentre Hardware Notes

- i5-6500T (4 cores, no HT), not i5-7500T as originally documented
- Supports x86-64-v3 (verified — Fedora 43 bootc compatible)
- No swap configured
- 7.6GB RAM available (~985MB used at idle)

---

## First Run Checklist

When first opening this project, complete these steps before any other work:

- [ ] **Verify SSH access to target.** Run `make test-connection VM_HOST=<ip>` — if it fails,
      check `~/.ssh/config` and the `SSH_KEY` Makefile variable.
- [ ] **Verify GHCR package is public.** Run `podman pull ghcr.io/distantgeek/adhd-hermes-os:latest`
      to confirm the registry image is accessible.
- [ ] **Check git remote** is set correctly. Run `git remote -v`.
- [ ] **Review Project Roadmap** at the bottom of this file — do not start roadmap items
      without explicit instruction.

---

## Homelab Infrastructure

### System Inventory

| System | Role | OS | Notes |
|--------|------|----|-------|
| Proxmox host | Primary hypervisor | Proxmox VE | Hosts devbox VM and other VMs |
| TrueNAS | NAS + Docker stacks | TrueNAS Scale | Dockge, NPM, Arr stack, Jellyfin |
| Fedora Server | SOC stack | Fedora Server 43 | soc-deploy |
| ThinkCentre | ADHD assistant | Fedora 43 (bootc) | **adhd-hermes target**, i5-6500T, 8GB, bare metal |
| FX-8 / GTX 1060 6GB | Auxiliary inference | Fedora | faster-whisper STT |
| Aurora-nvidia | Daily driver desktop | Aurora (Universal Blue) | NVIDIA GPU |
| Laptop | Mobile dev | (varies) | SSH client |
| This VM | AI devbox | Fedora bootc | Build environment |

### Network Topology

- **Domain:** `distantgeek.net` (Cloudflare DNS)
- **Reverse proxy:** NPM on TrueNAS — proxies `hermes.distantgeek.net` → ThinkCentre:9119
- **LAN range:** `192.168.x.x`
- **Dashboard access:** HTTPS via NPM reverse proxy; firewalld restricts port 9119 to LAN

### Username Conventions

| System | Username | Notes |
|--------|----------|-------|
| All homelab systems | `kevbot` | Primary operator user |
| Hermes container | `hermes` (UID 10000) | Remapped to host UID via HERMES_UID |
| Proxmox API | `claude@pam` | Proxmox service account |

---

## Container Architecture

### Overview

```
┌──────────────────────────────────────────────────┐
│            adhd-hermes-os (bootc)                │
│                                                  │
│  ┌──────────────────────┐  ┌──────────────────┐ │
│  │ adhd-hermes-gateway   │  │ adhd-hermes-     │ │
│  │ Messaging, cron,      │  │ dashboard        │ │
│  │ agent loop            │  │ Web UI :9119     │ │
│  │ Network=host          │  │ Network=host     │ │
│  │ Volume: ~/.hermes     │  │ Volume: ~/.hermes│ │
│  └──────────────────────┘  └──────────────────┘ │
└──────────────────────────────────────────────────┘
```

### Gateway Service (`adhd-hermes-gateway.container`)

- **Image:** `docker.io/nousresearch/hermes-agent:latest`
- **Network:** Host mode (required for Telegram, Discord, Signal gateways)
- **Data:** `/var/home/kevbot/.hermes` → `/opt/data` (bootc uses `/var/home/`, not `/home/`)
- **Entrypoint:** `/opt/hermes/docker/entrypoint.sh` (image's built-in entrypoint)
- **Command:** `gateway run --accept-hooks --replace -v`
- **API Server:** Enabled on port 8642 for cross-container health checks
- **Notes:** The image entrypoint handles UID/GID remapping and privilege dropping
  from root to the `hermes` user. Hermes v0.13.0+ refuses to run as root.
- **Terminal backend:** `local` (not `docker`). The `docker` backend requires
  mounting the Podman socket, which fails under rootless Podman due to SELinux
  and uid mapping. With `local`, Hermes executes commands directly inside the
  gateway container. Configured via `hermes config set terminal.backend local`.

### Dashboard Service (`adhd-hermes-dashboard.container`)

- **Image:** `docker.io/nousresearch/hermes-agent:latest`
- **Network:** Host mode
- **Data:** `/var/home/kevbot/.hermes` → `/opt/data`
- **Entrypoint:** Shell wrapper that fixes TUI build permissions, then execs
  the image entrypoint with `dashboard --host 0.0.0.0 --no-open --insecure --tui`
- **Port:** 9119 (firewalld restricted to LAN)
- **Restart:** `on-failure` with 10s delay
- **Scope:** User-level Quadlet (rootless Podman)
- **SELinux:** Volume mounted with `:z` (shared label for multi-container access)
- **Gateway health:** `GATEWAY_HEALTH_URL=http://localhost:8642/health` — bypasses
  lock file/PID namespace isolation so the dashboard can detect gateway status

### Hermes Lab SSH Access

Hermes can SSH into the devbox VM for running commands via the OpenCode skill:

- **SSH key:** `/opt/data/home/.ssh/id_ed25519` inside the gateway container
  (persisted at `/var/home/kevbot/.hermes/home/.ssh/` on the host)
- **SSH config:** `/opt/data/home/.ssh/config` with `Host devbox` / `Host lab` alias
- **Target:** Build/devbox VM (set IP in config)
- **Generated by:** `podman exec adhd-hermes-gateway ssh-keygen`
- **Public key added to:** devbox `~/.ssh/authorized_keys`

### Accessing the Hermes TUI

An alias is configured on kevbotmini for quick terminal access:

```bash
hermes    # → podman exec -it adhd-hermes-gateway /opt/hermes/.venv/bin/hermes
```

This is set in `~/.bashrc` and deployed via the Ansible `configure.yml` playbook.

Both services run as **user-level Quadlets** (in `~/.config/containers/systemd/`),
not system-level. This means:

- Managed via `systemctl --user` (not `systemctl`)
- Volume paths must use `/var/home/kevbot/` (not `/home/kevbot/` or `%h`)
  — on bootc, `%h` resolves incorrectly to `/home/` but the actual data is
  under `/var/home/`
- `HERMES_UID` and `HERMES_GID` must be numeric (e.g., `1000`), not `%u`/`%g`
  which resolve to the username string and cause `usermod` failures
- `loginctl enable-linger kevbot` is required for services to survive logout
- Volume mounts bind to `/var/home/kevbot/.hermes/` directory with `:z` SELinux
  label for shared access between both containers

### Data Persistence

All Hermes data lives in `~/.hermes/` on the host, which is under `/var/home/kevbot/`
on the bootc filesystem. This directory persists across `bootc upgrade` and
`bootc switch` operations.

Key subdirectories (created by Hermes entrypoint on first run):

```
~/.hermes/
├── .env                # API keys and configuration
├── config.yaml         # Hermes configuration
├── SOUL.md             # Agent personality
├── memories/           # Persistent memory store
├── skills/             # Custom skills
├── sessions/           # Conversation history
├── logs/               # Session trajectories
├── cron/               # Scheduled automations
├── hooks/              # Agent hooks
├── plans/              # Execution plans
├── workspace/          # Working directory for agent
└── home/               # HOME for subprocesses (git, ssh, etc.)
```

---

## Dashboard Remote Access

| Method | Path | Notes |
|--------|------|-------|
| NPM reverse proxy | `https://hermes.distantgeek.net` → ThinkCentre:9119 | Primary access |
| SSH tunnel | `ssh -L 9119:localhost:9119 kevbot@<thinkcentre>` | Fallback |
| Direct LAN | `http://<thinkcentre-ip>:9119` | firewalld restricted to 192.168.0.0/16 |

Do **not** expose port 9119 to the internet without HTTPS and authentication.
NPM provides HTTPS termination; Hermes dashboard auth is configured in
`~/.hermes/config.yaml`.

---

## Security Model

### Network Boundaries

- Port 9119 (dashboard): firewalld allows `192.168.0.0/16` only
- Outbound connections: Telegram, Discord, Signal, Slack, WhatsApp APIs
- SSH: `kevbot` key-only auth

### Container Isolation

Both Hermes containers run rootless via Podman. The gateway has `Network=host`
because messaging platforms require outbound connections that don't work well
with Podman networking. The dashboard also uses `Network=host` so NPM on
TrueNAS can reach it.

### Sensitive Paths — Never Read, Write, or Expose

```
~/.hermes/.env                 Hermes API keys and secrets
~/.hermes/config.yaml          Hermes config (contains tokens)
~/.ssh/                        All SSH keys
~/.config/proxmox/token        Proxmox API credentials
*.key  *.pem  *.p12  *.pfx
*_rsa  *_ed25519  *_ecdsa
.env   .env.*
credentials  secrets
```

If any of the above appears in tool output, do not reproduce the content.
Note the security miss and continue.

---

## Container Paradigm

### Runtime: Podman Only

Never suggest `docker` or `docker-compose`. This environment is Podman exclusively.

| Concept | Convention |
|---------|-----------|
| Runtime | `podman` |
| Compose | `podman-compose` |
| Persistent services | Quadlet `.container` files |
| User services | `systemctl --user` + rootless Podman |
| System services | `systemctl` + rootful Podman |
| User Quadlet path | `~/.config/containers/systemd/` |
| System Quadlet path | `/etc/containers/systemd/` |

After any Quadlet change:
```bash
systemctl --user daemon-reload && systemctl --user start <unit>
```

### SELinux — Always Enforcing

Account for SELinux in every container and file operation.

**Never:** `setenforce 0` or `security_opt: label=disable` unless explicitly requested.

Volume mount labels:
- `:Z` — private relabel (default — single container)
- `:z` — shared relabel (multiple containers accessing same volume)

Both Hermes containers share `~/.hermes/`, so use `:z` (shared label) for the
volume mount if SELinux blocking occurs. The current Quadlets use the default
(single-container `:Z`) since Podman handles shared access for same-image containers.

---

## Build System

### Makefile Targets

| Target | What it does |
|--------|-------------|
| `make build-image [HERMES_USER=name]` | Build bootc image; defaults to `kevbot` user |
| `make push-image` | Push to GHCR |
| `make build-disk-image` | Convert to raw disk via bootc-image-builder for bare metal |
| `make deploy VM_HOST=<ip>` | Ansible configure.yml against target system |
| `make upgrade VM_HOST=<ip>` | `bootc upgrade` + reboot on target |
| `make rollback VM_HOST=<ip>` | `bootc rollback` + reboot on target |
| `make configure VM_HOST=<ip>` | Deploy Quadlets and configure services |
| `make test-connection VM_HOST=<ip>` | SSH test + bootc status |
| `make validate VM_HOST=<ip>` | Ansible validation playbook |
| `make clean` | Remove build artifacts |

### Personal build command:
```bash
make build-image HERMES_USER=kevbot && make push-image && make upgrade VM_HOST=<thinkcentre-ip>
```

### bootc Upgrade Path

- `bootc upgrade` pulls the latest `adhd-hermes-os:latest` and stages it
- Quadrants in `/etc/skel/.config/containers/systemd/` are refreshed on each image
- `~/.hermes/` data persists across upgrades
- Ansible configuration is idempotent — safe to re-run after upgrades
- Previous deployment is kept as a rollback target via `bootc rollback`

### Switching from adhd-claw-os

The ThinkCentre (kevbotmini) was previously running `adhd-claw-os` (CentOS Stream 10)
with OpenClaw and Ollama running as root-level system Quadlets. All old containers,
data, and Quadrants have been cleaned up. The switch procedure is:

```bash
# From devbox:
ssh <hostname> sudo bootc switch ghcr.io/distantgeek/adhd-hermes-os:latest
ssh <hostname> sudo reboot
# Wait ~30s for reboot, then:
make configure VM_HOST=<ip>
# Start Hermes services:
ssh <hostname> systemctl --user daemon-reload
ssh <hostname> systemctl --user start adhd-hermes-gateway adhd-hermes-dashboard
# Run setup wizard:
ssh <hostname> podman exec -it adhd-hermes-gateway /opt/hermes/.venv/bin/hermes setup
```

### Pre-switch cleanup already performed

The following were removed from kevbotmini before the bootc switch:

- OpenClaw container (stopped, disabled, removed)
- Ollama container (stopped, disabled, removed)
- `/etc/containers/systemd/openclaw.container` (removed)
- `/etc/containers/systemd/ollama.container` (removed)
- `/etc/containers/systemd/adhd-claw.network` (removed)
- `/var/lib/openclaw/` (removed — no data needed)
- `/var/lib/ollama/` (removed — Ollama not carried forward)
- `/etc/openclaw/env` (removed — secrets, not migrated)
- Container images for openclaw and ollama (removed, ~9GB freed)
- `adhd-claw` podman network (removed)

---

## Working Style

**Change discipline**
- Small, reviewable diffs over large atomic rewrites
- Always show `git diff` or file preview before committing or pushing
- Commit message format: `feat:`, `fix:`, `chore:`, `docs:`, `security:`

**Quadlets**
- Validate before applying — required fields: `[Unit]`, `[Container]`, `Image=`, `[Install]`
- Always include `Restart=on-failure` unless there is a specific reason not to

**Ansible**
- Idempotent modules over raw shell commands
- `lookup('env', 'VAR')` for credentials — never hardcode
- Tag all tasks to allow targeted runs

**Credentials**
- If a credential is needed and not in environment, ask the user to `export VAR=value`
- Never pass credentials as CLI arguments (visible in process list and shell history)
- Never store credentials in files not covered by `.gitignore`

**When uncertain**
- Ask before assuming network addresses, VM IDs, or storage pool names
- For destructive operations, show the command and ask for confirmation

---

## Project Roadmap

Items to know about but **do not start without explicit instruction:**

1. ~~**Ansible playbooks** — `configure.yml` has baseline content, `validate.yml` needs creation~~
2. **NPM proxy configuration** — `hermes.distantgeek.net` reverse proxy setup on TrueNAS
3. **Hermes Agent configuration** — `hermes setup` wizard, SOUL.md customization,
   Telegram/Discord/Signal integration
4. **Homebrew post-deploy** — Ansible task to install Homebrew into `~kevbot`
5. **Flatpak remote + apps** — Ansible task for Flathub remote and specific Flatpaks
6. **Custom Hermes skills** — ADHD-specific nudges, calendar monitoring, task tracking
7. **validate.yml playbook** — Ansible validation playbook for post-deploy health checks
8. **Ollama decision** — Consider re-adding Ollama as a rootless user Quadlet for local LLM inference
9. **DHCP reservation** — Set static/reserved IP for kevbotmini on router

### Completed

- [x] Image built and pushed to GHCR (public)
- [x] Pre-switch cleanup on kevbotmini (OpenClaw, Ollama, old Quadlets, data removed)
- [x] SSH access configured (id_ed25519_kevbotmini, ~/.ssh/config alias)
- [x] Hardware audit (i5-6500T, 8GB, 463GB NVMe, SELinux enforcing)
- [x] bootc switch executed — ThinkCentre now runs adhd-hermes-os:latest (Fedora 43)
- [x] Ansible configure.yml run — firewall, Hermes dirs, Quadlets deployed, linger enabled
- [x] Dashboard running on port 9119 (HTTP 200 confirmed)
- [x] Quadlets fixed: `%h` → `/var/home/kevbot/`, `%u/%g` → `1000`, `--insecure` flag for dashboard
- [x] Gateway running with image entrypoint (UID/GID remap + privilege drop)
- [x] Hermes setup completed (OpenCode Go provider, deepseek-v4-pro default)
- [x] SSH lab access configured (Hermes → devbox VM via generated SSH key)
- [x] Terminal backend switched from `docker` to `local` — Podman socket mount
  doesn't work for rootless containers (SELinux + uid mapping blocks socket connect)
- [x] `hermes` alias added to kevbotmini `~/.bashrc` for quick TUI access
- [x] Dashboard `--tui` flag enabled with permission fix wrapper
- [x] Cross-container gateway health via `GATEWAY_HEALTH_URL` (port 8642 API server)
- [x] Signal/WhatsApp disabled in `.env` and `platform_toolsets` (no services to connect)

### Known Issues

- **`NetworkManager-wait-online.service`** was not enabled by default in the bootc image;
  Ansible task added to enable it; fixed in next image build
- **`%h` specifier in Quadlets** resolves to `/home/kevbot` instead of `/var/home/kevbot`
  on bootc systems — hardcoded path required
- **`%u`/`%g` specifiers** resolve to username strings, not numeric UIDs — hardcoded `1000` required
- **Hermes terminal `docker` backend doesn't work with rootless Podman** — mounting the
  Podman socket into the container results in permission denied (SELinux + uid mapping).
  Use `terminal.backend: local` instead. Commands run directly inside the gateway container.
- **`hermes config set` changes file ownership to root** — must run `chown` on
  `~/.hermes/config.yaml` after using it, or the gateway/dashboard can't read it