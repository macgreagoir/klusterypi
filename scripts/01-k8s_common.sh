#!/bin/bash
# https://www.shogan.co.uk/kubernetes/building-a-raspberry-pi-kubernetes-cluster-part-2-master-node
#
# Run on all k8s machines -- master and nodes.
# This is idempotent and should be safe to rerun to enforce state.

set -e 

[[ $EUID -eq 0 ]] || {
  echo "This script must be run as root" 1>&2
  exit 1
}

# If any step makes a change, flag to reboot. 0 means no reboot.
REBOOT=0

# Install Docker
# Debian repo doesn't support Raspian OS, so use the convenience script
# https://docs.docker.com/engine/install/debian/#install-using-the-convenience-script
which docker || {
  # TODO This script opens a root shell after installation, which we don't want to do.
  curl -sSL get.docker.com | sh && usermod pi -aG docker && newgrp docker

  REBOOT=1
}

# Disable swap
# Negative test here because `set -e` needs one side or || to be true
! systemctl is-active --quiet dphys-swapfile || {
  dphys-swapfile swapoff
  dphys-swapfile uninstall
  update-rc.d dphys-swapfile remove
  systemctl disable dphys-swapfile.service

  REBOOT=1
}

# Enable cgroups
grep \ *cgroup_enable /boot/cmdline.txt || {
  sed -i 's/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt

  REBOOT=1
}

# Install kubeadm et al
K8S_LIST=/etc/apt/sources.list.d/kubernetes.list
[[ -f $K8S_LIST ]] || {
  cat > /etc/apt/sources.list.d/kubernetes.list <<KLIST
deb http://apt.kubernetes.io/ kubernetes-xenial main
KLIST

  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
}

which kubeadm || {
  apt update
  apt install -y kubelet kubectl kubeadm kubernetes-cni

  REBOOT=1
}

# Use legacy iptables for the sake of flannel.1 <-> cni0 traffic.
[[ $(update-alternatives --query iptables | awk '/^Value/ {print $2}') = /usr/sbin/iptables-legacy ]] || {
  update-alternatives --set iptables /usr/sbin/iptables-legacy

  REBOOT=1
}


[[ $(sysctl -n net.bridge.bridge-nf-call-iptables 2&>1) -eq 1 ]] || {
  sysctl net.bridge.bridge-nf-call-iptables=1
}

[[ $REBOOT -eq 0 ]] || reboot

