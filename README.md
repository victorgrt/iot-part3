# Inception of Things

This project is part of 42's outer-circle curriculum, completed by hguo and vgoret.

A 42 school project exploring Kubernetes fundamentals. Vagrant manages
the virtual machines for Part 1, which creates a two-node K3s cluster.

```
p1/      hguo: 2 node K3s cluster
```

## Host prerequisites

VirtualBox and Vagrant are required. On a 42 school machine, sudo is
not available, so Vagrant has to be installed by hand as a portable
build. The commands below install Vagrant 2.4.9 under `~/.local` and
add it to the current user's shell path.

```bash
wget https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_linux_amd64.zip
unzip vagrant_2.4.9_linux_amd64.zip
chmod +x vagrant
./vagrant --appimage-extract
mkdir -p ~/.local
mv squashfs-root ~/.local/vagrant
echo 'export PATH="$HOME/.local/vagrant/usr/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

On Fedora 44, the system may not include `libcrypt.so.1`, which the
bundled Ruby needs. If Vagrant reports a missing `libcrypt.so.1`, the
following commands extract the compatible library locally and add a
small shell wrapper to load it:

```bash
dnf download libxcrypt-compat
mkdir -p ~/libxcrypt-extract
cd ~/libxcrypt-extract
rpm2cpio ../libxcrypt-compat-4.5.2-3.fc44.x86_64.rpm | cpio -idmv
mkdir -p ~/.local/vagrant-libs
cp usr/lib64/libcrypt.so.1 ~/.local/vagrant-libs/
echo 'vagrant() { LD_LIBRARY_PATH="$HOME/.local/vagrant-libs:$LD_LIBRARY_PATH" "$HOME/.local/vagrant/usr/bin/vagrant" "$@"; }' >> ~/.bashrc
source ~/.bashrc
vagrant --version
```

---

## Part 1 (hguo): K3s and Vagrant

This part creates two VMs and joins them to one cluster: `hguoS` is the
K3s server at `192.168.56.110`, and `hguoSW` is the K3s agent at
`192.168.56.111`. The server runs the Kubernetes control plane; the agent
joins it as a worker node. Both VMs use Ubuntu 22.04 and are configured by
their respective provisioning scripts.

```
p1/
├── Vagrantfile
└── scripts/
    ├── install_k3s_server.sh
    └── install_k3s_agent.sh
```

```bash
cd p1
vagrant up
```

Run the following from the host to enter each VM. The service checks run
inside the VM named in the preceding SSH command; run `exit` before opening
the other VM's SSH session.

```bash
vagrant ssh hguoS
sudo systemctl status k3s
kubectl get nodes -o wide
exit

vagrant ssh hguoSW
sudo systemctl status k3s-agent
exit
```

On `hguoS`, `kubectl get nodes` should list both nodes with `Ready` status:

```bash
vagrant ssh hguoS
kubectl get nodes
exit
```

Run Vagrant lifecycle commands from the host, in `p1/` (not inside a VM):

```bash
vagrant halt
```

To remove the VMs and their data, run this from the host in `p1/`:

```bash
vagrant destroy -f
```


