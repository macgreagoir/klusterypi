#!/bin/bash
# https://www.shogan.co.uk/kubernetes/building-a-raspberry-pi-kubernetes-cluster-part-2-master-node
#
# Run only on the k8s master.
# This is idempotent and should be safe to rerun to enforce state.

set -e 

# We _don't_ want to be root/sudo, but we do assume the user has sudo (aye :-/).
# This is instead of requiring config variables for the user and/or assuming pi.
[[ $EUID -ne 0 ]] || {
  echo "This script should not be run as root or with sudo" 1>&2
  exit 1
}

ADMIN_CONF=/etc/kubernetes/admin.conf

[[ -f $ADMIN_CONF ]] || {
  echo "This machine is not ready for this script (no $ADMIN_CONF)"
  exit 1
}

sudo ls $ADMIN_CONF 1>&2 || {
  echo "This script needs to be run by a user with sudo, sorry!"
  exit 1
}

# $KLUSTERY is my parent dir.
KLUSTERY=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

# Assign the require vars.
source $KLUSTERY/secrets/config.sh || exit $?
: ${NETADDR?} ${MASTER_IP?} ${POD_NET_CIDR?}

[[ $(ip a) =~ inet\ ${NETADDR}.${MASTER_IP} ]] || {
  echo "This must be run on the k8s master, ${NETADDR}.${MASTER_IP}"
  exit 1
}

# Create this user's kube config file
[[ -f $HOME/.kube/config ]] || {
  mkdir -p $HOME/.kube
  sudo cp -i $ADMIN_CONF $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

# Install the CNI
# Weave's containers just CrashLoop-ed so I gave up on it and used Flannel.
kubectl -n kube-system get pods | grep kube-flannel || {
  curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml |
    kubectl apply -f -
}

kubectl -n kube-system get pods | grep kube-flannel

