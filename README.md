# adhd-hermes

ADHD executive function assistant appliance — a Fedora 43 bootc image that
runs [Hermes Agent](https://github.com/NousResearch/hermes-agent) via rootless
Podman Quadlets on bare metal (ThinkCentre M910q).

## What This Is

A thin, immutable bootc OS layer that provides:

- **Podman + Quadlets** — runs Hermes Agent containers (gateway + dashboard) as
  systemd user services
- **Flatpak** — app runtime support for graphical applications if needed
- **ansible-core** — post-deploy configuration management
- **firewalld** — LAN-restricted access to the Hermes dashboard (port 9119)
- **qemu-guest-agent** — Proxmox integration

The Hermes Agent containers pull the upstream image
(`docker.io/nousresearch/hermes-agent:latest`) at runtime. This repo only builds
the OS layer that hosts them.

## Architecture

```
┌──────────────────────────────────────────────┐
│              adhd-hermes-os (bootc)          │
│  Fedora 43 + Podman + Flatpak + Ansible│
│                                              │
│  ┌─────────────────────┐ ┌────────────────┐ │
│  │ adhd-hermes-gateway  │ │ adhd-hermes-   │ │
│  │ (messaging, cron,   │ │ dashboard      │ │
│  │  agent loop)        │ │ (web UI :9119) │ │
│  │ Network=host        │ │ Network=host   │ │
│  │ Volume: ~/.hermes   │ │ Volume: ~/.hermes│ │
│  └─────────────────────┘ └────────────────┘ │
└──────────────────────────────────────────────┘
```

- **Gateway** — handles Telegram, Discord, Signal, WhatsApp, Slack, and cron
  scheduling. Uses `Network=host` for outbound messaging connections.
- **Dashboard** — web UI on port 9119. Bound to `0.0.0.0` inside the container;
  firewalld restricts external access to LAN IPs only. NPM on TrueNAS proxies
  `hermes.distantgeek.net` for HTTPS access.

## Quick Start

### Build the OS image

```bash
make build-image HERMES_USER=kevbot
```

### Push to registry

```bash
make push-image
```

### Build a raw disk image for Proxmox

```bash
make build-disk-image
```

### Deploy to a running VM

```bash
make deploy VM_HOST=192.168.2.x
```

### Upgrade a running VM (bootc)

```bash
make upgrade VM_HOST=192.168.2.x
```

### Switch an existing adhd-claw-os VM to adhd-hermes-os

```bash
ssh kevbot@<thinkcentre-ip>
sudo bootc switch ghcr.io/distantgeek/adhd-hermes-os:latest
sudo reboot
```

Post-reboot, run Ansible configuration:

```bash
make configure VM_HOST=192.168.2.x
```

### Start the Hermes services

```bash
systemctl --user daemon-reload
systemctl --user start adhd-hermes-gateway adhd-hermes-dashboard
```

Run the Hermes setup wizard on first start:

```bash
podman exec -it adhd-hermes-gateway hermes setup
```

Or migrate from OpenClaw:

```bash
podman exec -it adhd-hermes-gateway hermes claw migrate
```

## Repository Structure

```
adhd-hermes/
├── build/
│   └── Containerfile                 # bootc OS image definition
├── quadlets/
│   ├── adhd-hermes-gateway.container # main agent service
│   └── adhd-hermes-dashboard.container # web UI service
├── config/
│   ├── firewalld/
│   │   └── adhd-hermes.xml           # firewalld service (port 9119)
│   └── containers/
│       └── registries.conf            # rootless Podman registries config
├── ansible/
│   └── playbooks/
│       └── configure.yml              # post-deploy configuration
├── Makefile
├── CLAUDE.md                          # Claude Code context document
├── LICENSE
└── README.md
```

## Container Images

| Image | Registry | Purpose |
|-------|----------|---------|
| `adhd-hermes-os` | `ghcr.io/distantgeek/adhd-hermes-os` | Bootc OS layer (this repo) |
| `hermes-agent` | `docker.io/nousresearch/hermes-agent` | Hermes Agent (upstream) |

## Dashboard Remote Access

The Hermes dashboard binds to `0.0.0.0:9119` on the ThinkCentre. firewalld
restricts port 9119 to LAN IPs only (`192.168.0.0/16`). NPM on TrueNAS proxies
HTTPS access via `hermes.distantgeek.net`.

Do **not** expose port 9119 directly to the internet. Always use the reverse proxy.

## bootc Upgrade Notes

This system is designed for `bootc upgrade` and `bootc switch`:

- `/usr` is versioned and replaced atomically on upgrade
- `/etc` is a writable overlay — local changes persist across upgrades
- `/var` (including `~/.hermes`) persists across upgrades
- Quadlet files delivered by the image are refreshed on each upgrade
- Data volumes (`~/.hermes`) survive upgrades and switches

The Ansible `configure.yml` playbook handles host-specific configuration that
should not be baked into the image (API keys, firewall rules, SSH keys, etc.).

## License

Apache License 2.0 — see [LICENSE](LICENSE).

Hermes Agent is MIT licensed — see
[nousresearch/hermes-agent](https://github.com/NousResearch/hermes-agent).