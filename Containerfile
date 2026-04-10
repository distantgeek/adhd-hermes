# Containerfile for ADHD-Claw OS
# Registry: ghcr.io/distantgeek/adhd-claw-os
# Build: podman build -t ghcr.io/distantgeek/adhd-claw-os:latest .
# Push: podman push ghcr.io/distantgeek/adhd-claw-os:latest
FROM quay.io/centos-bootc/centos-bootc:stream10

RUN mkdir -p /etc/openclaw \
             /var/lib/openclaw/config \
             /var/lib/openclaw/workspace && \
    chmod 700 /etc/openclaw

COPY quadlets/openclaw.container /etc/containers/systemd/openclaw.container
