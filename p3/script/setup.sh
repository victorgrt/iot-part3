#!/usr/bin/env bash
# exit immediately if a failure happens
set -euo pipefail

# install docker from docker's official apt repository.
install_docker() {
	# Docker is already there (e.g. we ran `make` before): nothing to do.
	if command -v docker >/dev/null 2>&1; then
		return
	fi

	# already having old docker stuff (from Ubuntu itself) can break this script so we have to clean
	sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1) || true

	# the next 2 parts are mandatory and is all in official doc
	# to be sure that we download the right package + safe
	sudo apt update
	sudo apt install -y ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# let apt know where to download the packages
	sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
	# without this apt doesn't see the new packages
	sudo apt update

	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo systemctl enable --now docker
}

# install the latest stable kubectl binary, after checking its checksum.
install_kubectl() {
	if command -v kubectl >/dev/null 2>&1; then
		return
	fi

	local version arch tmp
	arch=$(dpkg --print-architecture)
	version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
	tmp=$(mktemp -d)

	curl -fsSL -o "$tmp/kubectl" "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl"
	curl -fsSL -o "$tmp/kubectl.sha256" "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl.sha256"
	# checking the fingerprint to be sure it is the good one and safe. Fails if package was tampered with or an issue with the download. 
	echo "$(cat "$tmp/kubectl.sha256")  $tmp/kubectl" | sha256sum --check

	sudo install -o root -g root -m 0755 "$tmp/kubectl" /usr/local/bin/kubectl
	rm -rf "$tmp"
}

install_k3d() {
	if command -v k3d >/dev/null 2>&1; then
		return
	fi

	curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

# allow current user to run docker without sudo.
setup_docker_group() {
	if id -nG "$USER" | grep -qw docker; then
		return
	fi

	sudo usermod -aG docker "$USER"
	echo "Added $USER to the docker group. Log out and back in for it to take effect."
}

print_versions() {
	docker --version
	kubectl version --client
	k3d version
}

install_docker
install_kubectl
install_k3d
setup_docker_group
print_versions
