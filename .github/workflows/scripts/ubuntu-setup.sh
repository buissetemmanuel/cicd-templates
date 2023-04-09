#!/bin/bash
set -euxo pipefail

# === INSTALL LIBVIRT, VAGRANT AND QEMU ===
sudo apt-get purge vagrant-libvirt
sudo apt-mark hold vagrant-libvirt
sudo apt-get update && \
    sudo apt-get install -y qemu libvirt-daemon-system ebtables libguestfs-tools \
        vagrant ruby-fog-libvirt

# === LIBVIRT SETUP ===
sudo systemctl enable --now libvirtd
sudo sed \
    -e 's!^[# ]*unix_sock_rw_perms = .*$!unix_sock_rw_perms = "0777"!g' \
    -e 's!^[# ]*auth_unix_rw = .*$!auth_unix_rw = "polkit"!g' -i /etc/libvirt/libvirtd.conf
# on fedora, looks like virbr0 iface stays there after a restart of libvirt but the network is not
# started back, leading to network failure when the script tries to start the network
if sudo virsh net-list --name | grep -qw default;  then
    sudo virsh net-destroy default
fi
sudo systemctl restart libvirtd
sudo usermod --append --groups libvirt "$(whoami)"
# on some dists, it's auto-started, on some others, it's not
if virsh -c qemu:///system net-list --name --inactive | grep -qw default;  then
    virsh -c qemu:///system net-start default
fi

# only info about the virtualisation is wanted, so no error please.
sudo virt-host-validate qemu || true

# === INSTALL PLUGINS ===
vagrant plugin install vagrant-libvirt
pip3 install molecule molecule-vagrant
