# KlusteryPi

Deploy a Raspberry Pi 4B cluster with

 * a router hosting a wireless network for the cluster,
 * a k8s master machine, and
 * two k8s nodes


## Prerequisites

You need four Raspberry Pi installed with Raspberry Pi OS and SSH enabled.

_There is no need to limit to four, but this expected in this version._


## Install and Configure

0. Review and edit secrets

 * `cp secrets/example.sh secrets/config.sh`
 * Edit `secrets/config.sh` for your network, machines and credentials

1. Install and configure

 * You likely want to clone this repo and copy `secrets/config.sh` to each k8s machine
 * On the router, run `scripts/00-router.sh.sh`
 * On the three k8s machines (master and nodes), run `scripts/01-k8s_common.sh`
 * On the k8s master, run `scripts/02-k8s_master.sh`
 * On the k8s master, run `scripts/03-k8s_cni.sh` as your non-root user
 * On each of the non-master nodes, run the `kubectl join` command detailed in the `kube init` output saved to `secrets/kube_init.out` on the master (TODO could be automated)
