#!/bin/bash
set -euo pipefail

LOG_FILE="setup.log"

log()   { printf '[%s] [INFO]  %s\n' "$(date +%T)" "$*"; }
error() { printf '[%s] [ERROR] %s\n' "$(date +%T)" "$*" >&2; }

exec > >(tee -a "$LOG_FILE") 2>&1
trap 'error "Failed at line $LINENO"' ERR

install_docker() {
	log "...launching docker installation..."
	if command -v docker >/dev/null 2>&1; then
		log "Docker already installed, skipping."
		return
	fi

	log "...Removing conflicting packages..."
	sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1) || true

	log "...Adding Docker's GPG key..."
	sudo apt update
	sudo apt install -y ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	log "...Adding Docker's apt repository..."
	sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

	log "...Installing Docker..."
	sudo apt update
	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	log "...Starting Docker..."
	sudo systemctl enable --now docker
	log "Docker installed."
}

install_kubectl() {
	if command -v kubectl >/dev/null 2>&1; then
		log "kubectl already installed, skipping."
		return
	fi

	local version arch tmp
	arch=$(dpkg --print-architecture)
	version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
	tmp=$(mktemp -d)

	log "Downloading kubectl ${version}..."
	curl -fsSL -o "$tmp/kubectl" "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl"
	curl -fsSL -o "$tmp/kubectl.sha256" "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl.sha256"

	log "Validating the binary..."
	echo "$(cat "$tmp/kubectl.sha256")  $tmp/kubectl" | sha256sum --check

	log "Installing kubectl..."
	sudo install -o root -g root -m 0755 "$tmp/kubectl" /usr/local/bin/kubectl
	rm -rf "$tmp"

	if ! command -v kubectl >/dev/null 2>&1; then
		error "kubectl installation failed."
		exit 1
	fi
	log "kubectl installed."
}

install_kubectl
