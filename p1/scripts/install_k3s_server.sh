#!/usr/bin/env bash
# if fail, exit immediately
set -euo pipefail

# The generic/ubuntu2204 box ships with DNSSEC=yes in systemd-resolved, which
# fails validation on this network ("DNSSEC validation failed: missing-key"),
# so no hostname resolves and the k3s download fails. Turn DNSSEC off.
sed -i 's/^DNSSEC=.*/DNSSEC=no/' /etc/systemd/resolved.conf
systemctl restart systemd-resolved

# A VM can have multiple NICs: NAT for internet access and a private NIC for
# communication between the server and agent. Find the private NIC assigned
# NODE_IP, then make Flannel use it for cluster traffic.
IFACE=$(ip -4 -o addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2; exit}')

# Download and run the official K3s installer, configuring this machine as
# the cluster server (control plane). Pin the version so the installer does
# not need to look up the moving "stable" release channel, which can fail.
curl -sSfL https://get.k3s.io | K3S_TOKEN="$K3S_TOKEN" \
	INSTALL_K3S_VERSION="v1.36.3+k3s1" \
	INSTALL_K3S_EXEC="server \
		--node-ip=${NODE_IP} \
		--advertise-address=${NODE_IP} \
		--tls-san=${NODE_IP} \
		--flannel-iface=${IFACE} \
		--write-kubeconfig-mode=644" \
	sh -

# The K3s installer also makes `kubectl` available on this VM. By default,
# kubectl reads the cluster connection settings from this kubeconfig file.
{
	echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
	echo "alias k=kubectl"
} >>/home/vagrant/.bashrc
