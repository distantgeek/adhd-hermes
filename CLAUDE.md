# adhd-hermes
## Claude Code Context Document

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
| `fedora-claude-devbox` | Fedora bootc Claude Code devbox (this VM) |
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
| Hardware | ThinkCentre M910q (i5-7500T, 8GB RAM, bare metal) |
| Hostname | `adhd-hermes` |
| IP | TBD (DHCP reservation planned) |
| SSH user | `kevbot` |
| bootc image | `ghcr.io/distantgeek/adhd-hermes-os:latest` |
| Previous image | `ghcr.io/distantgeek/adhd-claw-os:latest` (switched via `bootc switch`) |
| Container runtime | Rootless Podman via systemd Quadlets |
| Status | Pending deployment — bare metal, not a VM |

---

## First Run Checklist

When Claude Code first opens this project, complete these steps before any other work:

- [ ] **Verify environment variables are loaded.** Run `echo $PROXMOX_HOST` — if empty,
      source `~/.config/proxmox/token`.
- [ ] **Confirm hook suite is wired** (if running from fedora-claude-devbox).
- [ ] **Check `~/.config/proxmox/token` exists** on the operator machine.
- [ ] **Test Proxmox API connectivity.**
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
| ThinkCentre | ADHD assistant | Fedora 43 (bootc) | **adhd-hermes target** |
| FX-8 / GTX 1060 6GB | Auxiliary inference | Fedora | faster-whisper STT |
| Aurora-nvidia | Daily driver desktop | Aurora (Universal Blue) | NVIDIA GPU |
| Laptop | Mobile dev | (varies) | SSH client |
| This VM | Claude Code devbox | Fedora bootc | Build environment |

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
| Proxmox API | `claude@pam` | Claude Code service account |

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
- **Data:** `~/.hermes` → `/opt/data`
- **Command:** `hermes gateway run` (default entrypoint)
- **Restart:** `on-failure` with 10s delay
- **Scope:** User-level Quadlet (rootless Podman)

### Dashboard Service (`adhd-hermes-dashboard.container`)

- **Image:** `docker.io/nousresearch/hermes-agent:latest`
- **Network:** Host mode
- **Data:** `~/.hermes` → `/opt/data`
- **Command:** `dashboard --host 0.0.0.0 --no-open`
- **Port:** 9119 (firewalld restricted to LAN)
- **Restart:** `on-failure` with 10s delay
- **Scope:** User-level Quadlet (rootless Podman)

### Important: Rootless Quadlets

Both services run as **user-level Quadlets** (in `~/.config/containers/systemd/`),
not system-level. This means:

- Managed via `systemctl --user` (not `systemctl`)
- `%h`, `%u`, `%g` specifiers resolve to the user's home, UID, GID
- `loginctl enable-linger kevbot` is required for services to survive logout
- Volume mounts bind to the user's `~/.hermes/` directory

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

If any of the above appears in tool output, treat it as a scrubber miss.
Do not reproduce the content. Note the miss and continue.

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

```bash
ssh kevbot@<thinkcentre-ip>
sudo systemctl stop openclaw    # stop old container
sudo bootc switch ghcr.io/distantgeek/adhd-hermes-os:latest
sudo reboot
# After reboot:
make configure VM_HOST=<ip>
systemctl --user daemon-reload
systemctl --user start adhd-hermes-gateway adhd-hermes-dashboard
# Migrate from OpenClaw:
podman exec -it adhd-hermes-gateway hermes claw migrate
```

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

Items Claude Code should know about but **not start without explicit instruction:**

1. **Ansible playbooks** — `configure.yml` and `validate.yml` need substantive content
2. **NPM proxy configuration** — `hermes.distantgeek.net` reverse proxy setup on TrueNAS
3. **Hermes Agent configuration** — `hermes setup` wizard, SOUL.md customization,
   Telegram/Discord/Signal integration
4. **Homebrew post-deploy** — Ansible task to install Homebrew into `~kevbot`
5. **Flatpak remote + apps** — Ansible task for Flathub remote and specific Flatpaks
6. **Custom Hermes skills** — ADHD-specific nudges, calendar monitoring, task tracking

Do not begin any of the above unless the user asks.