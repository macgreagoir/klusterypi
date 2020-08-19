#!/bin/bash
# https://www.shogan.co.uk/kubernetes/building-a-raspberry-pi-kubernetes-cluster-part-2-master-node
#
# Run only on the k8s master.
# This is idempotent and should be safe to rerun to enforce state.

set -e 

[[ $EUID -eq 0 ]] || {
  echo "This script must be run as root" 1>&2
  exit 1
}

# $KLUSTERY is my parent dir.
KLUSTERY=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

# Assign the require vars.
source $KLUSTERY/secrets/config.sh || exit $?
: ${NETADDR?} ${MASTER_IP?}

[[ $(ip a) =~ inet\ ${NETADDR}.${MASTER_IP} ]] || {
  echo "This must be run on the k8s master, ${NETADDR}.${MASTER_IP}"
  exit 1
}

[[ -f /etc/kubernetes/admin.conf ]] || {
  kubeadm config images pull -v3
  # Flannel expects 10.244.0.0/16 so it's hard-coded here.
  kubeadm init --token-ttl=0 --apiserver-advertise-address=${NETADDR}.${MASTER_IP} \
    --pod-network-cidr=10.244.0.0/16 | tee $KLUSTERY/secrets/kubeadm_init.out
}

