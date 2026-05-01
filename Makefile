# adhd-hermes Makefile
# Usage: make <target> [VM_HOST=192.168.x.x] [VM_USER=kevbot] [TAG=latest]

REGISTRY       ?= ghcr.io/distantgeek
IMAGE_NAME     ?= adhd-hermes-os
TAG            ?= latest
FULL_IMAGE     ?= $(REGISTRY)/$(IMAGE_NAME):$(TAG)
VM_HOST        ?= $(error VM_HOST is required for this target)
VM_USER        ?= kevbot
SSH_KEY        ?= ~/.ssh/id_ed25519_kevbotmini
ANSIBLE_OPTS   ?=
HERMES_USER    ?= kevbot

.PHONY: help build-image push-image deploy upgrade rollback configure \
        test-connection validate switch clean

help:
	@echo ""
	@echo "adhd-hermes — build and deployment targets"
	@echo ""
	@echo "Image targets:"
	@echo "  make build-image                  Build bootc container image"
	@echo "  make push-image                   Push image to registry"
	@echo "  make build-disk-image             Convert to raw disk for Proxmox"
	@echo ""
	@echo "VM targets (require VM_HOST=<ip>):"
	@echo "  make deploy VM_HOST=<ip>          Run Ansible config against VM"
	@echo "  make upgrade VM_HOST=<ip>          bootc upgrade + reboot target VM"
	@echo "  make rollback VM_HOST=<ip>         bootc rollback + reboot target VM"
	@echo "  make switch VM_HOST=<ip>           bootc switch to adhd-hermes-os + reboot"
	@echo "  make configure VM_HOST=<ip>        Deploy Quadlets + configure services"
	@echo "  make validate VM_HOST=<ip>         Verify deployment health"
	@echo "  make test-connection VM_HOST=<ip> Test SSH connectivity"
	@echo ""
	@echo "Options:"
	@echo "  VM_HOST         Target VM IP address"
	@echo "  VM_USER         SSH user (default: kevbot)"
	@echo "  SSH_KEY         SSH private key (default: ~/.ssh/id_ed25519)"
	@echo "  TAG             Image tag (default: latest)"
	@echo "  REGISTRY        Image registry (default: ghcr.io/distantgeek)"
	@echo "  HERMES_USER     Primary user (default: kevbot)"
	@echo ""

# ---------------------------------------------------------------------------
# Image build
# ---------------------------------------------------------------------------

build-image:
	@echo ">>> Building $(FULL_IMAGE) (HERMES_USER=$(HERMES_USER))"
	podman build \
		--tag $(FULL_IMAGE) \
		--tag $(REGISTRY)/$(IMAGE_NAME):$$(git rev-parse --short HEAD) \
		--build-arg HERMES_USER=$(HERMES_USER) \
		-f build/Containerfile \
		.

push-image:
	@echo ">>> Pushing $(FULL_IMAGE)"
	podman push $(FULL_IMAGE)
	podman push $(REGISTRY)/$(IMAGE_NAME):$$(git rev-parse --short HEAD)

# ---------------------------------------------------------------------------
# VM deployment
# ---------------------------------------------------------------------------

deploy:
	@echo ">>> Configuring $(VM_USER)@$(VM_HOST)"
	ansible-playbook ansible/playbooks/configure.yml \
		-i $(VM_HOST), \
		-u $(VM_USER) \
		--private-key $(SSH_KEY) \
		-e "vm_host=$(VM_HOST) vm_user=$(VM_USER)" \
		$(ANSIBLE_OPTS)

upgrade:
	@echo ">>> Upgrading adhd-hermes at $(VM_HOST)"
	ssh -i $(SSH_KEY) $(VM_USER)@$(VM_HOST) \
		"sudo bootc upgrade && sudo reboot" || true
	@echo ">>> VM rebooting. Reconnect in ~30 seconds."

rollback:
	@echo ">>> Rolling back adhd-hermes at $(VM_HOST)"
	ssh -i $(SSH_KEY) $(VM_USER)@$(VM_HOST) \
		"sudo bootc rollback && sudo reboot" || true
	@echo ">>> VM rebooting. Reconnect in ~30 seconds."

switch:
	@echo ">>> Switching $(VM_HOST) to adhd-hermes-os"
	ssh -i $(SSH_KEY) $(VM_USER)@$(VM_HOST) \
		"sudo bootc switch $(FULL_IMAGE) && sudo reboot" || true
	@echo ">>> VM rebooting into adhd-hermes-os. Reconnect in ~30 seconds."

configure:
	@echo ">>> Deploying Quadlets and configuring services on $(VM_HOST)"
	rsync -avz \
		-e "ssh -i $(SSH_KEY)" \
		quadlets/ \
		$(VM_USER)@$(VM_HOST):.config/containers/systemd/
	ssh -i $(SSH_KEY) $(VM_USER)@$(VM_HOST) \
		"systemctl --user daemon-reload && systemctl --user start adhd-hermes-gateway adhd-hermes-dashboard"
	@echo ">>> Quadlets deployed and services started."

# ---------------------------------------------------------------------------
# Validation and utilities
# ---------------------------------------------------------------------------

test-connection:
	@echo ">>> Testing SSH to $(VM_USER)@$(VM_HOST)"
	ssh -i $(SSH_KEY) -o ConnectTimeout=5 $(VM_USER)@$(VM_HOST) \
		"echo 'Connection OK' && uname -a && bootc status 2>/dev/null | head -5"

validate:
	@echo ">>> Validating deployment on $(VM_HOST)"
	ansible-playbook ansible/playbooks/configure.yml \
		-i $(VM_HOST), \
		-u $(VM_USER) \
		--private-key $(SSH_KEY) \
		--check \
		$(ANSIBLE_OPTS)

clean:
	@echo ">>> Cleaning build artifacts"
	rm -f output/disk.raw
	podman rmi $(FULL_IMAGE) 2>/dev/null || true
	@echo ">>> Done."

# ---------------------------------------------------------------------------
# bootc-image-builder — convert to raw disk for Proxmox import
# ---------------------------------------------------------------------------

build-disk-image:
	@echo ">>> Pulling $(FULL_IMAGE) into root storage for bootc-image-builder"
	sudo podman pull --authfile /run/user/$$(id -u)/containers/auth.json $(FULL_IMAGE)
	@echo ">>> Converting $(FULL_IMAGE) to raw disk image for Proxmox"
	mkdir -p output
	sudo podman run --rm -i \
		--privileged \
		--pull=newer \
		-v $$(pwd)/output:/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type raw \
		--local \
		$(FULL_IMAGE)
	@echo ">>> Raw disk image at output/image/disk.raw"
	@echo ">>> Write to bare metal disk:"
	@echo "    sudo dd if=output/image/disk.raw of=/dev/sdX bs=4M status=progress"
	@echo "    Or: sudo bootc install to-disk --image $(FULL_IMAGE) /dev/sdX"