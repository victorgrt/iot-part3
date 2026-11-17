#!/usr/bin/env bash
set -euo pipefail

# This Ubuntu box enables DNSSEC by default, but DNSSEC validation fails on
# this network and prevents resolving the K3s download host. Disable it so
# the installer can reach and download K3s.
sed -i 's/^DNSSEC=.*/DNSSEC=no/' /etc/systemd/resolved.conf
systemctl restart systemd-resolved

# This VM can have multiple NICs: NAT for internet access and a private NIC
# for communication with the server. Find the private NIC assigned NODE_IP,
# then make Flannel use it for cluster traffic.
IFACE=$(ip -4 -o addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2; exit}')

# Download and run the official K3s installer, configuring this machine as an
# agent that joins the server at K3S_URL using the shared K3S_TOKEN. Pin the
# same K3s version as the server so both nodes run compatible releases.
curl -sSfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="$K3S_TOKEN" \
	INSTALL_K3S_VERSION="v1.36.3+k3s1" \
	INSTALL_K3S_EXEC="agent \
		--node-ip=${NODE_IP} \
		--flannel-iface=${IFACE}" \
	sh -
